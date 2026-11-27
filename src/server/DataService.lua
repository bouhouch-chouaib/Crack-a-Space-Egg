-- Sauvegarde et session des joueurs : DataStore avec réessais, schéma versionné, jamais d'écrasement silencieux.
--
-- SESSION (Config.Session) : une partie n'est ouverte que sur un serveur à la fois.
--   - À l'arrivée, le serveur pose son verrou dans la sauvegarde (d.session = { job, at }) dans la même
--     écriture que la lecture (UpdateAsync). Si un autre serveur la tient encore (le joueur vient de le
--     quitter et sa sauvegarde n'est pas finie), on réessaie quelques secondes ; s'il la tient toujours, le
--     joueur est renvoyé avec un message : mieux vaut attendre une minute que charger une vieille partie.
--   - Chaque sauvegarde automatique rafraîchit le verrou ; un verrou resté sans nouvelles plus de
--     LockSeconds vient d'un serveur mort, le suivant le reprend.
--   - Au départ, la dernière sauvegarde retire le verrou : le joueur peut entrer ailleurs tout de suite.
--   - Si une sauvegarde découvre le verrou d'un autre serveur (le nôtre a expiré), elle n'écrit rien et
--     renvoie le joueur : c'est l'autre serveur qui a la partie à jour.
-- CHARGEMENT RATÉ : dans le vrai jeu, le joueur est renvoyé avec un message (rien n'est perdu) plutôt que
-- de jouer une heure sans que rien ne soit gardé. Dans Studio sans accès aux API, on joue sans sauvegarde.
-- Les sauvegardes d'un même joueur passent une par une ; la fermeture du serveur attend qu'elles soient finies.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Testers = require(script.Parent.Testers)

local DataService = {}

local VERSION = 5 -- v2 : soute { ring, rarity } ; v3 : foreuses une par une ; v4 : œufs et créatures dans la base ; v5 : économie du 15 nov. (Player_v3)
local store: DataStore? = nil
local ok, err = pcall(function()
	-- mode testeur : sauvegarde à part, les vraies parties restent intactes
	store = DataStoreService:GetDataStore(if Testers.Enabled() then Config.Testers.SaveKey else Config.SaveKey)
end)
if not ok then
	warn("[Data] DataStore indisponible (activer l'accès API dans Studio ?)", err)
end

local S = Config.Session
local JOB = if game.JobId ~= "" then game.JobId else "studio" -- identité de ce serveur dans le verrou
local STUDIO = RunService:IsStudio()

local profiles: { [Player]: any } = {}
local canSave: { [Player]: boolean } = {}
local busy: { [Player]: boolean } = {} -- une sauvegarde de ce joueur est en cours
local started: { [Player]: number } = {} -- os.clock() du début de la session
local counted: { [Player]: number } = {} -- os.clock() jusqu'où le temps de jeu est déjà compté
local loadedSignal = Instance.new("BindableEvent")
DataService.Loaded = loadedSignal.Event

local function default()
	return {
		v = VERSION,
		credits = 0,
		drill = 1, -- foreuse équipée (index dans Config.Drills ; on les achète dans l'ordre)
		levels = { Thruster = 0, Scanner = 0 }, -- (l'ancien niveau Cargo des vieilles sauvegardes est ignoré)
		ring = 1, -- plus haut anneau débloqué
		cargo = {}, -- un œuf par entrée : { ring = anneau d'origine, rarity = rareté, rock = type d'astéroïde } (encore pris dans la roche)
		ready = {}, -- œufs dérochés par la machine, prêts à couver : { ring, rarity, rock }
		jetXP = 0, -- XP totale du jetpack (niveau : Config.JetpackLevel)
		tunnel = 0, -- palier de la soufflerie personnelle (0 = pas encore achetée)
		boosts = {}, -- potions actives : [clé] = os.time() de fin (BoostService)
		inventory = {}, -- sac de créatures (CreatureService), 100 places
		seen = {}, -- ["anneau:rareté"] = true : créature déjà eue dans la base (Index)
		indexClaimed = {}, -- ["anneau"] = true : récompense d'anneau de l'Index réclamée
		skins = {}, -- ["clé"] = true : skins de foreuse achetés en $ (SkinService)
		skin = "Classic", -- skin de foreuse équipé
		baseSkin = "Station", -- skin de base choisi (BaseSkinService)
		firstJoin = 0, -- os.time() de la première partie (fenêtre du Starter Pack)
		guide = -1, -- étape du guide de la première minute atteinte (Guide.client) ; -1 = pas encore décidé
		starterBought = false, -- Starter Pack déjà acheté (un seul par joueur)
		rewards = {}, -- connexion quotidienne, temps de jeu, quêtes, codes, pub (RewardService)
		groupClaimed = false, -- récompense « Join the group » déjà réclamée
		inGroup = false, -- membre du groupe du jeu (revérifié à chaque arrivée) : +10 % de chance
		-- Base : œufs en incubation et créatures posées. Position (x, z) dans le repère du sol de la base.
		--   œuf      : { kind = "egg", ring, rarity, x, z, hatchAt = os.time() de fin }
		--   créature : { kind = "pet", ring, rarity, x, z, name, size, weight, income, mut = mutation ou nil, odds = « 1 sur N » à l'éclosion }
		base = {},
		index = {}, -- ["anneau:rareté"] = nombre trouvé
		derocking = nil, -- l'œuf dans la machine (rendu à la soute si le joueur part avant la fin)
		machine = { Speed = 0, Luck = 0, Mutation = 0 }, -- niveaux de la machine à dérocher (MachineService)
		guideRewarded = false, -- récompense de fin de tutoriel déjà donnée
		tips = {}, -- ["clé"] = true : tutoriels au bon moment déjà montrés (Config.Guide.Tips)
		feedback = { day = 0, count = 0 }, -- retours envoyés aujourd'hui (FeedbackService)
		pen = 1, -- niveau de l'enclos (Config.Pen, PenService) : taille de la base et places en plus
		suit = 1, -- palier de combinaison (Config.Suits)
		bat = 0, -- palier de batte (Config.Bats, 0 = aucune)
		shields = 0, -- boucliers anti-monstre en réserve (produit Robux)
		relicsFound = {}, -- ["clé"] = true : reliques trouvées (RelicService) : chacune donne son bonus pour toujours
		lastSeen = 0, -- os.time() de la dernière sauvegarde : sert au revenu hors ligne (HatchService)
		offlineDue = 0, -- secondes hors ligne pas encore payées (créditées quelques secondes après l'arrivée)
		stats = { hatched = 0, best = 0, sessions = 0, seconds = 0 }, -- sessions : parties jouées ; seconds : temps de jeu total
		receipts = {}, -- derniers achats Robux déjà donnés (PurchaseId) : jamais deux fois le même (MonetizationService)
		session = nil, -- verrou du serveur qui tient la partie : { job = JobId, at = os.time() } (voir l'en-tête)
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
	for k, v in pairs(base.stats) do
		if data.stats[k] == nil then
			data.stats[k] = v
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
		if
			string.find(message, "StudioAccessToApisNotAllowed", 1, true)
			or string.find(message, "Studio access to APIs is not allowed", 1, true)
			or string.find(message, "from studio if API access is not enabled", 1, true) -- le message d'une écriture
		then
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

-- Vrai dans Studio quand la partie ne sera jamais écrite (pas d'accès aux API) : les achats de test
-- passent quand même (MonetizationService)
function DataService.Sandbox(player: Player): boolean
	return STUDIO and canSave[player] == false
end

-- Secondes écoulées depuis l'arrivée du joueur sur ce serveur
function DataService.SessionSeconds(player: Player): number
	return if started[player] then os.clock() - started[player] else 0
end

-- Vrai si la sauvegarde appartient encore à un autre serveur vivant
local function heldElsewhere(old: any, now: number): boolean
	local lock = type(old) == "table" and old.session
	return type(lock) == "table" and lock.job ~= JOB and now - (lock.at or 0) < S.LockSeconds
end

-- Le joueur est reparti pendant le chargement : on rend le verrou qu'on venait de poser
local function unlock(key: string)
	if not store then
		return
	end
	pcall(function()
		(store :: DataStore):UpdateAsync(key, function(old)
			if type(old) == "table" and type(old.session) == "table" and old.session.job == JOB then
				old.session = nil
				return old
			end
			return nil
		end)
	end)
end

function DataService.Load(player: Player)
	local key = "u_" .. player.UserId
	local data = nil
	local success = false
	local locked = false
	if store then
		local deadline = os.clock() + S.WaitSeconds
		repeat
			locked = false
			success, data = withRetries(function()
				-- lecture et pose du verrou dans la même écriture : deux serveurs ne peuvent pas l'avoir tous les deux
				return (store :: DataStore):UpdateAsync(key, function(old)
					local now = os.time()
					if heldElsewhere(old, now) then
						locked = true
						return nil -- rien n'est écrit
					end
					locked = false
					local d = if type(old) == "table" then old else default()
					d.session = { job = JOB, at = now }
					return d
				end)
			end, "chargement " .. player.Name)
			if success and locked and player.Parent then
				task.wait(S.RetrySeconds)
			end
		until not success or not locked or os.clock() > deadline or not player.Parent
	end
	if not player.Parent then
		if success and not locked then
			unlock(key)
		end
		return
	end
	if success and locked then
		warn("[Data] Partie de " .. player.Name .. " encore ouverte sur un autre serveur")
		player:Kick("Your save is still closing on another server. Please join again in a minute!")
		return
	end
	if success then
		canSave[player] = true
		profiles[player] = if type(data) == "table" then migrate(data) else default()
	elseif not STUDIO then
		warn("[Data] Partie non chargée pour " .. player.Name .. " : joueur renvoyé")
		player:Kick("Roblox could not load your save. Nothing is lost! Please join again in a moment.")
		return
	else
		canSave[player] = false
		profiles[player] = default()
		warn("[Data] Partie non chargée pour " .. player.Name .. " : rien ne sera sauvegardé cette session")
	end
	if Testers.Enabled() then
		Testers.Grant(profiles[player])
	end
	started[player] = os.clock()
	counted[player] = os.clock()
	profiles[player].stats.sessions += 1
	loadedSignal:Fire(player, profiles[player])
end

-- Écrit la partie. final = dernière sauvegarde de la session : elle retire le verrou.
-- Renvoie true si la partie est bien écrite.
function DataService.Save(player: Player, final: boolean?): boolean
	-- une sauvegarde à la fois par joueur : la dernière (celle qui retire le verrou) passe forcément après les autres
	while busy[player] do
		task.wait(0.1)
	end
	local data = profiles[player]
	if not data or not canSave[player] or not store then
		return false
	end
	busy[player] = true
	local key = "u_" .. player.UserId
	local now = os.clock()
	data.stats.seconds += math.floor(now - (counted[player] or now))
	counted[player] = now
	data.lastSeen = os.time()
	local stolen, newer = false, false
	local success = withRetries(function()
		(store :: DataStore):UpdateAsync(key, function(old)
			-- Ne jamais remplacer une sauvegarde d'une version plus récente du jeu
			if type(old) == "table" and (old.v or 0) > VERSION then
				newer = true
				return nil
			end
			-- Ni celle qu'un autre serveur a reprise entre-temps
			if heldElsewhere(old, os.time()) then
				stolen = true
				return nil
			end
			stolen = false
			data.session = if final then nil else { job = JOB, at = os.time() }
			return data
		end)
	end, "sauvegarde " .. player.Name)
	busy[player] = nil
	if stolen then
		canSave[player] = false
		warn("[Data] Partie de " .. player.Name .. " reprise par un autre serveur : plus rien n'est écrit ici")
		if player.Parent then
			player:Kick("Your game was opened on another server. Your progress is safe there!")
		end
		return false
	end
	return success and not newer
end

function DataService.Release(player: Player)
	DataService.Save(player, true)
	profiles[player] = nil
	canSave[player] = nil
	started[player] = nil
	counted[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(DataService.Load)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.Load, p)
	end
	Players.PlayerRemoving:Connect(DataService.Release)
	-- Fermeture du serveur : on attend que toutes les parties soient écrites (Roblox laisse 30 secondes)
	game:BindToClose(function()
		local pending = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if profiles[p] then
				pending += 1
				task.spawn(function()
					DataService.Release(p)
					pending -= 1
				end)
			end
		end
		local limit = os.clock() + S.CloseSeconds
		while (pending > 0 or next(busy) ~= nil) and os.clock() < limit do
			task.wait(0.2)
		end
	end)
	-- Studio seulement : ServerStorage.DataDebug:Invoke() dit où en est la session du premier joueur
	if STUDIO then
		local bf = Instance.new("BindableFunction")
		bf.Name = "DataDebug"
		bf.OnInvoke = function()
			local p = Players:GetPlayers()[1]
			local d = p and profiles[p]
			if not d then
				return "pas de partie chargée"
			end
			return ("canSave=%s sandbox=%s sessions=%d seconds=%d session=%.0fs save=%s"):format(
				tostring(canSave[p]), tostring(DataService.Sandbox(p)), d.stats.sessions, d.stats.seconds, DataService.SessionSeconds(p), tostring(DataService.Save(p)))
		end
		bf.Parent = game:GetService("ServerStorage")
	end
	-- Sauvegarde automatique : chaque joueur toutes les AutosaveSeconds, étalées pour ne pas tout écrire d'un coup
	task.spawn(function()
		while true do
			local list = Players:GetPlayers()
			if #list == 0 then
				task.wait(5)
			end
			for _, p in ipairs(list) do
				task.spawn(DataService.Save, p)
				task.wait(Config.AutosaveSeconds / #list)
			end
		end
	end)
end

return DataService
