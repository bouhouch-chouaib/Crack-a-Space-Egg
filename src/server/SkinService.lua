-- Skins de foreuse (atelier des foreuses, onglet SKINS). Le serveur décide : achat en $, passes
-- Robux pour les skins premium, skin équipé (sauvegardé dans d.skin, d.skins).
-- Remotes.DrillShop (RemoteFunction) : ("state") -> { owned, skin } ; ("buy", clé) ; ("equip", clé)
-- Publié sur le joueur : DrillSkin (clé du skin équipé)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local Remotes = ReplicatedStorage.Remotes
local SkinService = {}

-- Skins premium possédés (passes Robux), vérifiés à l'arrivée : { [Player]: { [clé]: true } }
local passOwned: { [Player]: { [string]: boolean } } = {}

local function owns(player: Player, d, key: string): boolean
	local s = Config.DrillSkin(key)
	if s.Key ~= key then
		return false
	end
	if s.Key == "Classic" or (d.skins and d.skins[key]) then
		return true
	end
	return passOwned[player] ~= nil and passOwned[player][key] == true
end

local function ownedList(player: Player, d): { [string]: boolean }
	local list = {}
	for _, s in ipairs(Config.DrillSkins) do
		if owns(player, d, s.Key) then
			list[s.Key] = true
		end
	end
	return list
end

local function equip(player: Player, d, key: string)
	d.skin = key
	player:SetAttribute("DrillSkin", key)
	GameService.EquipDrill(player)
end

local function checkPasses(player: Player)
	passOwned[player] = passOwned[player] or {}
	for _, s in ipairs(Config.DrillSkins) do
		if s.PassId and s.PassId ~= 0 then
			-- mode testeur : tous les passes comptent comme achetés
			local ok, has = true, Config.Testers.Everyone
			if not has then
				ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, s.PassId)
			end
			if ok and has then
				passOwned[player][s.Key] = true
			end
		end
	end
end

local function onInvoke(player: Player, action: unknown, key: unknown)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	d.skins = d.skins or {}
	if action == "state" then
		return { ok = true, owned = ownedList(player, d), skin = d.skin or "Classic" }
	end
	if type(key) ~= "string" then
		return { ok = false, error = "Unknown skin" }
	end
	local s = Config.DrillSkin(key)
	if s.Key ~= key then
		return { ok = false, error = "Unknown skin" }
	end
	if action == "buy" then
		if owns(player, d, key) then
			return { ok = false, error = "Already owned" }
		end
		if s.Robux then
			return { ok = false, error = "This skin is sold for Robux" }
		end
		if d.credits < s.Price then
			return { ok = false, error = "Not enough $" }
		end
		d.credits -= s.Price
		d.skins[key] = true
		GameService.Sync(player)
		equip(player, d, key)
		return { ok = true, owned = ownedList(player, d), skin = d.skin }
	elseif action == "equip" then
		if not owns(player, d, key) then
			return { ok = false, error = "You don't own this skin" }
		end
		equip(player, d, key)
		return { ok = true, owned = ownedList(player, d), skin = d.skin }
	end
	return { ok = false, error = "Unknown action" }
end

function SkinService.Start()
	Remotes.DrillShop.OnServerInvoke = onInvoke
	DataService.Loaded:Connect(function(player: Player)
		local d = DataService.Get(player)
		if d then
			player:SetAttribute("DrillSkin", d.skin or "Classic")
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(checkPasses, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(checkPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		passOwned[player] = nil
	end)
	-- Passe de skin acheté pendant la partie : il est à lui, on l'équipe tout de suite
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, s in ipairs(Config.DrillSkins) do
			if s.PassId == passId and passId ~= 0 then
				passOwned[player] = passOwned[player] or {}
				passOwned[player][s.Key] = true
				local d = DataService.Get(player)
				if d then
					equip(player, d, s.Key)
					GameService.Notice(player, ("{Sparkles} %s skin unlocked!"):format(s.Name), "good")
				end
			end
		end
	end)
end

return SkinService
