-- Bonus achetés en Robux : passes (définitifs) et potions (15 min, cumulables dans le temps).
-- Les autres services demandent ici leurs multiplicateurs ; rien n'est vendu qui donne des œufs
-- ou des créatures.
-- Publié sur le joueur (pour l'affichage) :
--   Pass_<Clé> = true            passe possédé (Config.Shop.Passes)
--   Boost_<Clé> = os.time() fin  potion active (Config.Shop.Potions, sauf Meteor)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local SHOP = Config.Shop
local FX = SHOP.PassEffects

local BoostService = {}

local owned: { [Player]: { [string]: boolean } } = {}

-- PASSES ------------------------------------------------------------------------------

function BoostService.HasPass(player: Player, key: string): boolean
	local o = owned[player]
	return o ~= nil and o[key] == true
end

local function setPass(player: Player, key: string)
	owned[player] = owned[player] or {}
	owned[player][key] = true
	player:SetAttribute("Pass_" .. key, true)
	if key == "BaseSlots" then
		player:SetAttribute("BaseSlots", BoostService.BaseSlots(player))
	end
end

local function loadPasses(player: Player)
	owned[player] = owned[player] or {}
	for _, pass in ipairs(SHOP.Passes) do
		if pass.Id ~= 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and has then
				setPass(player, pass.Key)
			end
		end
	end
end

-- POTIONS -----------------------------------------------------------------------------

local function boostEnd(player: Player, key: string): number
	local d = DataService.Get(player)
	return if d and d.boosts then (d.boosts[key] or 0) else 0
end

function BoostService.Active(player: Player, key: string): boolean
	return boostEnd(player, key) > os.time()
end

-- Ajoute des minutes à une potion (si elle est déjà active, le temps s'ajoute à la fin)
function BoostService.Add(player: Player, key: string, minutes: number): boolean
	local d = DataService.Get(player)
	if not d then
		return false
	end
	d.boosts = d.boosts or {}
	local from = math.max(os.time(), d.boosts[key] or 0)
	d.boosts[key] = from + minutes * 60
	player:SetAttribute("Boost_" .. key, d.boosts[key])
	return true
end

local function publishBoosts(player: Player)
	local d = DataService.Get(player)
	if not d or not d.boosts then
		return
	end
	local now = os.time()
	for key, t in pairs(d.boosts) do
		if t > now then
			player:SetAttribute("Boost_" .. key, t)
		else
			d.boosts[key] = nil
			player:SetAttribute("Boost_" .. key, nil)
		end
	end
end

-- MULTIPLICATEURS ---------------------------------------------------------------------

-- Revenus des créatures
function BoostService.IncomeMult(player: Player): number
	local m = 1
	if BoostService.HasPass(player, "Money2x") then
		m *= FX.Money2x
	end
	if BoostService.HasPass(player, "VIP") then
		m *= FX.VIP
	end
	if BoostService.Active(player, "Money") then
		m *= 2
	end
	return m
end

-- Chance des œufs rares (multiplie celle du scanner), à partir de la sauvegarde du joueur
function BoostService.LuckMult(d): number
	local t = d and d.boosts and d.boosts.Luck
	local m = if t and t > os.time() then 2 else 1
	-- récompenses de l'Index : +10 % de chance par anneau complété
	local claimed = 0
	for _ in pairs(d and d.indexClaimed or {}) do
		claimed += 1
	end
	return m * (1 + Config.IndexReward.Luck * claimed)
end

-- XP du jetpack (soufflerie et vol)
function BoostService.JetXPMult(player: Player): number
	local m = 1
	if BoostService.HasPass(player, "JetXP2x") then
		m *= FX.JetXP2x
	end
	if BoostService.Active(player, "JetXP") then
		m *= 2
	end
	return m
end

-- Durée d'éclosion
function BoostService.HatchTimeMult(player: Player): number
	return if BoostService.HasPass(player, "FastHatch") then FX.FastHatch else 1
end

-- Emplacements de la base
function BoostService.BaseSlots(player: Player): number
	return Config.Hatch.Slots + (if BoostService.HasPass(player, "BaseSlots") then FX.BaseSlots else 0)
end

function BoostService.Start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPasses, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
	DataService.Loaded:Connect(function(player: Player)
		publishBoosts(player)
	end)
	-- achat d'un passe pendant la partie
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in ipairs(SHOP.Passes) do
			if pass.Id == passId then
				setPass(player, pass.Key)
			end
		end
	end)
	-- Studio seulement : point d'accès de test (donner une potion ou un passe, lire l'état)
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "BoostDebug"
		bf.OnInvoke = function(cmd: string, player: Player, key: string?)
			if cmd == "potion" and key then
				BoostService.Add(player, key, Config.Shop.PotionMinutes)
			elseif cmd == "pass" and key then
				setPass(player, key)
			end
			return ("income x%.2f luck x%d jetXP x%d hatch x%.1f slots %d"):format(
				BoostService.IncomeMult(player), BoostService.LuckMult(DataService.Get(player)),
				BoostService.JetXPMult(player), BoostService.HatchTimeMult(player), BoostService.BaseSlots(player))
		end
		bf.Parent = ServerStorage
	end
	-- les potions expirent : on retire l'attribut
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do
				publishBoosts(player)
			end
		end
	end)
end

return BoostService
