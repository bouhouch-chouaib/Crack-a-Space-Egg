-- Sauvegarde des joueurs : DataStore avec réessais, schéma versionné, jamais d'écrasement silencieux.
-- Si la sauvegarde n'a pas pu être chargée, le joueur joue mais on n'écrit rien (sinon on effacerait sa partie).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local DataService = {}

local VERSION = 4 -- v2 : soute { ring, rarity } ; v3 : foreuses une par une ; v4 : œufs et créatures dans la base
local store: DataStore? = nil
local ok, err = pcall(function()
	store = DataStoreService:GetDataStore(Config.SaveKey)
end)
if not ok then
	warn("[Data] DataStore indisponible (activer l'accès API dans Studio ?)", err)
end

local profiles: { [Player]: any } = {}
local canSave: { [Player]: boolean } = {}
local loadedSignal = Instance.new("BindableEvent")
DataService.Loaded = loadedSignal.Event

local function default()
	return {
		v = VERSION,
		credits = 0,
		drill = 1, -- foreuse équipée (index dans Config.Drills ; on les achète dans l'ordre)
		levels = { Thruster = 0, Scanner = 0 }, -- (l'ancien niveau Cargo des vieilles sauvegardes est ignoré)
		ring = 1, -- plus haut anneau débloqué
		cargo = {}, -- un œuf par entrée : { ring = anneau d'origine, rarity = rareté } (encore pris dans la roche)
		ready = {}, -- œufs dérochés par la machine, prêts à couver : { ring, rarity }
		jetXP = 0, -- XP totale du jetpack (niveau : Config.JetpackLevel)
		tunnel = 0, -- palier de la soufflerie personnelle (0 = pas encore achetée)
		boosts = {}, -- potions actives : [clé] = os.time() de fin (BoostService)
		inventory = {}, -- sac de créatures (CreatureService), 100 places
		seen = {}, -- ["anneau:rareté"] = true : créature déjà eue dans la base (Index)
		indexClaimed = {}, -- ["anneau"] = true : récompense d'anneau de l'Index réclamée
		skins = {}, -- ["clé"] = true : skins de foreuse achetés en $ (SkinService)
		skin = "Classic", -- skin de foreuse équipé
		firstJoin = 0, -- os.time() de la première partie (fenêtre du Starter Pack)
		guide = -1, -- étape du guide de la première minute atteinte (Guide.client) ; -1 = pas encore décidé
		starterBought = false, -- Starter Pack déjà acheté (un seul par joueur)
		-- Base : œufs en incubation et créatures posées. Position (x, z) dans le repère du sol de la base.
		--   œuf      : { kind = "egg", ring, rarity, x, z, hatchAt = os.time() de fin }
		--   créature : { kind = "pet", ring, rarity, x, z, name, size, weight, income }
		base = {},
		index = {}, -- ["anneau:rareté"] = nombre trouvé
		pity = 0,
		stats = { geodes = 0, best = 0 },
	}
end

-- Complète une vieille sauvegarde avec les champs ajoutés depuis
local function migrate(data)
	local base = default()
	for k, v in pairs(base) do
		if data[k] == nil then
			data[k] = v
		end
	end
	for k, v in pairs(base.levels) do
		if data.levels[k] == nil then
			data.levels[k] = v
		end
	end
	-- v1 -> v2 : la soute ne gardait que l'anneau ; la rareté sera tirée à la casse
	for i, egg in ipairs(data.cargo) do
		if type(egg) == "number" then
			data.cargo[i] = { ring = egg }
		end
	end
	-- v2 -> v3 : l'ancien niveau de foreuse (0 à 60) devient la foreuse du palier correspondant
	if data.levels.Drill ~= nil then
		data.drill = math.clamp(1 + math.floor(data.levels.Drill / 6), 1, #Config.Drills)
		data.levels.Drill = nil
	end
	data.v = VERSION
	return data
end

local function withRetries(fn: () -> any, label: string)
	for attempt = 1, 5 do
		local success, result = pcall(fn)
		if success then
			return true, result
		end
		warn(string.format("[Data] %s échec %d/5 : %s", label, attempt, tostring(result)))
		-- Studio sans accès aux API : ça ne marchera jamais, on joue tout de suite sans sauvegarde
		local message = tostring(result)
		if string.find(message, "StudioAccessToApisNotAllowed", 1, true) or string.find(message, "Studio access to APIs is not allowed", 1, true) then
			return false, nil
		end
		task.wait(attempt * 1.5)
	end
	return false, nil
end

function DataService.Get(player: Player)
	return profiles[player]
end

-- Vrai si la partie a bien été chargée (on peut donc l'écrire, et la classer)
function DataService.CanSave(player: Player): boolean
	return canSave[player] == true
end

function DataService.Load(player: Player)
	local key = "u_" .. player.UserId
	local data = nil
	local success = false
	if store then
		success, data = withRetries(function()
			return (store :: DataStore):GetAsync(key)
		end, "chargement " .. player.Name)
	end
	if not player.Parent then
		return
	end
	if success then
		canSave[player] = true
		profiles[player] = if type(data) == "table" then migrate(data) else default()
	else
		canSave[player] = false
		profiles[player] = default()
		warn("[Data] Partie non chargée pour " .. player.Name .. " : rien ne sera sauvegardé cette session")
	end
	loadedSignal:Fire(player, profiles[player])
end

function DataService.Save(player: Player)
	local data = profiles[player]
	if not data or not canSave[player] or not store then
		return
	end
	local key = "u_" .. player.UserId
	withRetries(function()
		(store :: DataStore):UpdateAsync(key, function(old)
			-- Ne jamais remplacer une sauvegarde d'une version plus récente du jeu
			if type(old) == "table" and (old.v or 0) > VERSION then
				return nil
			end
			return data
		end)
	end, "sauvegarde " .. player.Name)
end

function DataService.Release(player: Player)
	DataService.Save(player)
	profiles[player] = nil
	canSave[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(DataService.Load)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.Load, p)
	end
	Players.PlayerRemoving:Connect(DataService.Release)
	game:BindToClose(function()
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(DataService.Save, p)
		end
		task.wait(3)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for _, p in ipairs(Players:GetPlayers()) do
				task.spawn(DataService.Save, p)
			end
		end
	end)
end

return DataService
