-- Boîte à retours (boîte aux lettres du vaisseau, FeedbackUI.client, Config.Feedback).
-- Remotes.Feedback (RemoteFunction) : ("send", catégorie, texte) -> { ok, error? }
-- Chaque retour est ajouté à une clé par jour du DataStore Config.Feedback.Store ; à lire avec
-- tools/read-feedback.lua. Les textes ne sont montrés à aucun autre joueur.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local Tracking = require(script.Parent.Tracking)

local F = Config.Feedback
local Remotes = ReplicatedStorage.Remotes
local FeedbackService = {}

local lastSent: { [Player]: number } = {}

local function validCategory(category: any): boolean
	for _, c in ipairs(F.Categories) do
		if c.Key == category then
			return true
		end
	end
	return false
end

-- Enlève les espaces autour et coupe au maximum, sans casser un caractère accentué
local function clean(text: any): string?
	if type(text) ~= "string" or utf8.len(text) == nil then
		return nil
	end
	local trimmed = string.match(text, "^%s*(.-)%s*$") or ""
	if (utf8.len(trimmed) :: number) > F.MaxChars then
		trimmed = string.sub(trimmed, 1, (utf8.offset(trimmed, F.MaxChars + 1) :: number) - 1)
	end
	return trimmed
end

local function save(entry): boolean
	local key = "d_" .. os.date("!%Y%m%d")
	local ok, err = pcall(function()
		local store = DataStoreService:GetDataStore(F.Store)
		store:UpdateAsync(key, function(list)
			list = if type(list) == "table" then list else {}
			if #list < F.MaxPerDay then
				table.insert(list, entry)
			end
			return list
		end)
	end)
	if not ok then
		warn("[Feedback]", err)
	end
	return ok
end

local function send(player: Player, category: any, rawText: any)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	local text = clean(rawText)
	if not validCategory(category) or text == nil then
		return { ok = false, error = "Pick what you want to tell us" }
	end
	local now = os.clock()
	if lastSent[player] and now - lastSent[player] < F.Cooldown then
		return { ok = false, error = "Thanks! Wait a little before sending another" }
	end
	local day = math.floor(os.time() / 86400)
	d.feedback = d.feedback or { day = 0, count = 0 }
	if d.feedback.day ~= day then
		d.feedback = { day = day, count = 0 }
	end
	if d.feedback.count >= F.PerDay then
		return { ok = false, error = "That's enough for today, thank you!" }
	end
	local entry = {
		t = os.time(),
		u = player.UserId,
		c = category,
		x = text,
		ring = d.ring,
		xp = d.jetXP,
		sn = d.supernovas or 0,
	}
	lastSent[player] = now
	if not save(entry) then
		-- Studio sans accès aux API : on affiche le retour pour pouvoir tester la fenêtre
		if RunService:IsStudio() then
			print("[Feedback] Studio :", category, text)
		else
			lastSent[player] = nil
			return { ok = false, error = "Couldn't send it. Try again later" }
		end
	end
	d.feedback.count += 1
	Tracking.Event(player, "Feedback_" .. category)
	return { ok = true }
end

function FeedbackService.Start()
	Remotes.Feedback.OnServerInvoke = function(player: Player, action: any, category: any, text: any)
		if action == "send" then
			return send(player, category, text)
		end
		return { ok = false, error = "Unknown action" }
	end
	Players.PlayerRemoving:Connect(function(player)
		lastSent[player] = nil
	end)
end

return FeedbackService
