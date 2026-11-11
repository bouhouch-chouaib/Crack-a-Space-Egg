-- Skins de base (Config.BaseSkins) : débloqués par les Supernovas ou par un passe Robux, purement esthétiques.
-- Le serveur décide et colore la base, que tout le serveur voit. Sauvegardé dans d.baseSkin.
-- Remotes.BaseSkin (RemoteFunction) : ("state") -> { ok, owned, skin } ; ("equip", clé) -> idem
-- Publié : BaseSkin sur le joueur, Skin sur sa base (lu par BaseSkinUI.client pour l'arc-en-ciel).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local BaseSkin = require(ReplicatedStorage.Shared.BaseSkin)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Bases = require(script.Parent.Bases)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Remotes = ReplicatedStorage.Remotes
local BaseSkinService = {}
local DEFAULT = Config.BaseSkins[1].Key

-- Passes possédés, vérifiés à l'arrivée : { [Player]: { [clé]: true } }
local passOwned: { [Player]: { [string]: boolean } } = {}

local function owns(player: Player, d, key: string): boolean
	local s = Config.BaseSkin(key)
	if s.Key ~= key then
		return false
	end
	if s.Robux then
		return passOwned[player] ~= nil and passOwned[player][key] == true
	end
	return (d.supernovas or 0) >= (s.Supernovas or 0)
end

local function ownedList(player: Player, d): { [string]: boolean }
	local list = {}
	for _, s in ipairs(Config.BaseSkins) do
		if owns(player, d, s.Key) then
			list[s.Key] = true
		end
	end
	return list
end

local function paint(base: Model, key: string)
	BaseSkin.Apply(base, key)
	base:SetAttribute("Skin", key)
end

-- Affiche le skin choisi. S'il n'est pas (ou plus) vérifié, on montre celui de départ sans effacer le choix :
-- une vérification de passe ratée ne doit pas faire perdre son skin au joueur.
local function show(player: Player, d)
	local base = Bases.Get(player)
	if not base then
		return
	end
	local key = d.baseSkin or DEFAULT
	if not owns(player, d, key) then
		key = DEFAULT
	end
	paint(base, key)
	player:SetAttribute("BaseSkin", key)
end

local function checkPasses(player: Player)
	local found = {}
	for _, s in ipairs(Config.BaseSkins) do
		if s.PassId and s.PassId ~= 0 then
			-- mode testeur : tous les passes comptent comme achetés
			local ok, has = true, Config.Testers.Everyone
			if not has then
				ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, s.PassId)
			end
			if ok and has then
				found[s.Key] = true
			end
		end
	end
	if player.Parent then
		passOwned[player] = passOwned[player] or {}
		for key in pairs(found) do
			passOwned[player][key] = true
		end
	end
end

local function grant(player: Player, key: string)
	passOwned[player] = passOwned[player] or {}
	passOwned[player][key] = true
	local d = DataService.Get(player)
	if d then
		d.baseSkin = key
		show(player, d)
	end
end

local function onInvoke(player: Player, action: unknown, key: unknown)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	if action == "state" then
		return { ok = true, owned = ownedList(player, d), skin = player:GetAttribute("BaseSkin") or DEFAULT }
	end
	if action ~= "equip" or type(key) ~= "string" then
		return { ok = false, error = "Unknown action" }
	end
	if not owns(player, d, key) then
		return { ok = false, error = "You don't own this skin" }
	end
	d.baseSkin = key
	show(player, d)
	return { ok = true, owned = ownedList(player, d), skin = key }
end

local function arrive(player: Player)
	checkPasses(player)
	local d = DataService.Get(player)
	if d and player.Parent then
		show(player, d)
	end
end

function BaseSkinService.Start()
	for _, base in ipairs(WorldBuilder.Bases) do
		BaseSkin.Prepare(base)
		base:SetAttribute("Skin", DEFAULT)
	end
	Remotes.BaseSkin.OnServerInvoke = onInvoke
	DataService.Loaded:Connect(function(player: Player)
		task.spawn(arrive, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if DataService.Get(player) then
			task.spawn(arrive, player)
		end
	end
	-- la base libérée reprend son apparence d'origine
	Players.PlayerRemoving:Connect(function(player)
		passOwned[player] = nil
		local base = Bases.Get(player)
		if base then
			paint(base, DEFAULT)
		end
	end)
	-- passe acheté pendant la partie : on l'équipe tout de suite
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased or passId == 0 then
			return
		end
		for _, s in ipairs(Config.BaseSkins) do
			if s.PassId == passId then
				grant(player, s.Key)
				GameService.Notice(player, ("{Sparkles} %s base skin unlocked!"):format(s.Name), "good")
			end
		end
	end)
	-- Studio seulement : (joueur, clé) donne un skin vendu en Robux ; (joueur, clé, true) le reprend,
	-- pour voir ce que voit un joueur sans le passe (le créateur du jeu possède tous ses passes)
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "BaseSkinDebug"
		bf.OnInvoke = function(player: Player, key: string, remove: boolean?)
			if not remove then
				grant(player, key)
				return
			end
			if passOwned[player] then
				passOwned[player][key] = nil
			end
			local d = DataService.Get(player)
			if d then
				show(player, d)
			end
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return BaseSkinService
