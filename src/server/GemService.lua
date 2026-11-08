-- Sac de minerais (géodes ouvertes par la machine, Config.Geodes) et leur vente au stand SELL.
-- Remotes.Gems (RemoteFunction) :
--   ("list")                -> { ok, gems }
--   ("sell", { index... })  -> vend ces minerais (il faut être près du stand SELL)
--   ("sellAll")             -> vend tout le sac
-- Le serveur décide du prix (gem.value, fixé à l'ouverture de la géode).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Tracking = require(script.Parent.Tracking)

local Remotes = ReplicatedStorage.Remotes
local GemService = {}

local function nearSell(player: Player): boolean
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	for _, point in ipairs(WorldBuilder.ShopPoints) do
		if point.Name == "SellPoint" and (point.Position - hrp.Position).Magnitude <= Config.PetRules.StandRange then
			return true
		end
	end
	return false
end

local function sell(player: Player, d, which: { number }?): (number, number)
	local total, count = 0, 0
	local keep = {}
	local chosen = {}
	for _, i in ipairs(which or {}) do
		if type(i) == "number" then
			chosen[i] = true
		end
	end
	for i, g in ipairs(d.gems) do
		if which == nil or chosen[i] then
			total += g.value
			count += 1
		else
			table.insert(keep, g)
		end
	end
	d.gems = keep
	d.credits += total
	GameService.Sync(player)
	return total, count
end

local function onInvoke(player: Player, action: any, arg: any)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	d.gems = d.gems or {}
	if action == "list" then
		return { ok = true, gems = d.gems }
	end
	if action ~= "sell" and action ~= "sellAll" then
		return { ok = false, error = "Unknown action" }
	end
	if not nearSell(player) then
		return { ok = false, error = "Go to the SELL stand to sell your gems", gems = d.gems }
	end
	if #d.gems == 0 then
		return { ok = false, error = "No gems to sell. Drill geodes!", gems = d.gems }
	end
	local total, count = sell(player, d, if action == "sell" and type(arg) == "table" then arg else nil)
	if count == 0 then
		return { ok = false, error = "Pick a gem to sell", gems = d.gems }
	end
	Tracking.Funnel(player, "Gems", 3, "Gem sold")
	GameService.Notice(player, ("{Cash} Sold %d gem%s for $%s!"):format(count, if count > 1 then "s" else "", Format.Short(total)), "good")
	return { ok = true, total = total, count = count, gems = d.gems }
end

function GemService.Start()
	Remotes.Gems.OnServerInvoke = onInvoke
end

return GemService
