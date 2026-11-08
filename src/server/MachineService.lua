-- Machine à dérocher de chaque base (docs/Mecaniques.md §7) et ses améliorations (Config.Machine).
-- Remotes.Machine (RemoteFunction) : ("buy", clé) -> { ok, error? }. Niveaux publiés en attributs Mach_<clé>.
-- Le propriétaire déclenche la machine à la console : elle prend les œufs de sa soute un par un,
-- retire la roche (durée selon la rareté), puis range l'œuf dégagé dans « ready » (à couver ensuite).
-- Le serveur pose l'état du travail en cours en attributs sur le modèle de la machine ;
-- chaque client anime la machine à partir de ces attributs (Derock.client).
--   JobStart / JobEnd : temps serveur du travail en cours (absents = machine au repos)
--   EggRing / EggRarity : l'œuf en cours ; Queue : œufs restants après lui ; Owner : UserId

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local Tracking = require(script.Parent.Tracking)
local GameService = require(script.Parent.GameService)
local Bases = require(script.Parent.Bases)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Remotes = ReplicatedStorage.Remotes

local MachineService = {}

local busy: { [Model]: boolean } = {}
local rng = Random.new()

-- Taille d'un minerai (Config.Sizes, pondérée par Chance)
local function pickSize()
	local total = 0
	for _, s in ipairs(Config.Sizes) do
		total += s.Chance
	end
	local x = rng:NextNumber() * total
	for _, s in ipairs(Config.Sizes) do
		x -= s.Chance
		if x <= 0 then
			return s
		end
	end
	return Config.Sizes[1]
end

-- APPARENCE : les pièces orange et jaunes prennent la couleur du palier, chez tous les joueurs
local ACCENTS = { Static_Orange = "Accent", Static_Yellow = "Accent", ClampL_Orange = "Accent", ClampR_Orange = "Accent", Static_Glow = "Glow", Drill_Glow = "Glow" }

local function machineOf(player: Player): Model?
	local base = Bases.Get(player)
	return base and base:FindFirstChild("DerockMachine") :: Model?
end

local function paint(machine: Model, tier: any)
	for _, d in ipairs(machine:GetDescendants()) do
		local role = d:IsA("BasePart") and ACCENTS[d.Name]
		if role then
			(d :: BasePart).Color = tier[role]
		end
	end
end

local function totalLevels(d): number
	local n = 0
	for _, level in pairs(d.machine or {}) do
		n += level
	end
	return n
end

-- Remet la machine du joueur à la couleur de ses niveaux, et publie ces niveaux
function MachineService.Refresh(player: Player)
	local d = DataService.Get(player)
	local machine = machineOf(player)
	if not d or not machine then
		return
	end
	paint(machine, (Config.MachineTier(totalLevels(d))))
	GameService.Sync(player)
end

local function buy(player: Player, key: any)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	local track = type(key) == "string" and Config.Machine.Tracks[key]
	if not track then
		return { ok = false, error = "Unknown upgrade" }
	end
	d.machine = d.machine or { Speed = 0, Luck = 0, Polish = 0 }
	local level = d.machine[key] or 0
	if level >= Config.Machine.Max then
		return { ok = false, error = "Already maxed!" }
	end
	local cost = Config.MachineCost(key, level)
	if d.credits < cost then
		return { ok = false, error = ("You need $%s"):format(Format.Short(cost)) }
	end
	local before = Config.MachineTier(totalLevels(d))
	d.credits -= cost
	d.machine[key] = level + 1
	Tracking.Funnel(player, "Machine" .. key, level + 1, ("%s %d"):format(key, level + 1))
	MachineService.Refresh(player)
	local after = Config.MachineTier(totalLevels(d))
	if after ~= before then
		GameService.Notice(player, ("{MachineUp} Your machine is now %s!"):format(after.Name), "good")
	end
	return { ok = true }
end

local function clearJob(machine: Model)
	for _, k in ipairs({ "JobStart", "JobEnd", "EggRing", "EggRarity", "EggKind", "Owner" }) do
		machine:SetAttribute(k, nil)
	end
	machine:SetAttribute("Queue", 0)
end

-- Passe les œufs de la soute un par un ; s'arrête si la soute est vide ou si le joueur part
local function run(player: Player, base: Model, machine: Model)
	busy[machine] = true
	while player.Parent and Bases.OwnerOf(base) == player do
		local d = DataService.Get(player)
		if not d or #d.cargo == 0 then
			break
		end
		-- L'œuf reste dans la soute tant qu'il n'est pas dégagé (rien n'est perdu si le joueur part)
		local egg = d.cargo[1]
		local ring = if type(egg) == "table" then egg.ring or 1 else egg
		local rarity = if type(egg) == "table" and egg.rarity then egg.rarity else GameService.RollRarity(d, ring)
		if type(egg) == "table" then
			egg.rarity = rarity
		end
		-- Cœur chanceux : parfois une rareté de plus (si l'anneau en a une au-dessus)
		local levels = d.machine or {}
		if type(egg) == "table" and Config.Eggs[ring][rarity + 1] and rng:NextNumber() < Config.MachineLuck(levels.Luck or 0) then
			rarity += 1
			egg.rarity = rarity
			GameService.Notice(player, ("{MachineLuck} Lucky Core! Upgraded to %s!"):format(Config.Rarities[rarity].Name), "good")
			GameService.Sync(player)
		end
		local duration = Config.MachineTime(rarity, levels.Speed or 0)
		local now = workspace:GetServerTimeNow()
		local geode = type(egg) == "table" and egg.kind == "geode"
		machine:SetAttribute("EggRing", ring)
		machine:SetAttribute("EggRarity", rarity)
		machine:SetAttribute("EggKind", if geode then "geode" else "egg")
		machine:SetAttribute("Queue", #d.cargo - 1)
		machine:SetAttribute("Owner", player.UserId)
		machine:SetAttribute("JobStart", now)
		machine:SetAttribute("JobEnd", now + duration)
		task.wait(duration)
		if not player.Parent then
			break
		end
		d = DataService.Get(player)
		if not d or d.cargo[1] ~= egg then
			break
		end
		table.remove(d.cargo, 1)
		if geode then
			-- la géode s'ouvre : un minerai de l'anneau, d'une taille tirée au hasard, parfois brillant
			-- la géode du tutoriel a sa taille imposée
			local size = pickSize()
			for _, s in ipairs(Config.Sizes) do
				if type(egg) == "table" and s.Name == egg.size then
					size = s
				end
			end
			local shiny = rng:NextNumber() < Config.ShinyChance
			local gem = {
				ring = ring,
				rarity = rarity,
				size = size.Name,
				mult = size.Mult,
				shiny = shiny,
				value = math.floor(Config.GemValue(ring, rarity, size.Mult, shiny) * Config.MachinePolish(levels.Polish or 0) + 0.5),
			}
			d.gems = d.gems or {}
			if #d.gems >= Config.Geodes.BagMax then
				d.credits += gem.value
				GameService.Notice(player, "{Cash} Gem bag full! Sold for $" .. Format.Short(gem.value), "info")
			else
				table.insert(d.gems, gem)
			end
			d.stats.best = math.max(d.stats.best, rarity)
			GameService.Sync(player)
			Tracking.Funnel(player, "Gems", 2, "Geode opened")
			Remotes.EggRevealed:FireClient(player, ring, rarity, "geode", gem)
			if rarity >= Config.AnnounceFrom then
				Remotes.Announcement:FireAllClients(player.DisplayName, Config.GemName(ring, rarity), rarity)
			end
		else
			table.insert(d.ready, { ring = ring, rarity = rarity })
			GameService.Sync(player)
			Remotes.EggRevealed:FireClient(player, ring, rarity)
		end
		task.wait(Config.Derock.Gap)
	end
	clearJob(machine)
	busy[machine] = nil
end

local function bind(base: Model)
	local machine = base:FindFirstChild("DerockMachine") :: Model?
	local primary = machine and machine.PrimaryPart
	local point = primary and primary:FindFirstChild("PromptPoint")
	if not machine or not point then
		return
	end
	clearJob(machine)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DerockPrompt"
	prompt.ActionText = "Derock"
	prompt.ObjectText = "Derock Machine"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 18 -- on l'active depuis la place, sans monter sur l'annexe
	prompt.RequiresLineOfSight = false
	prompt.Parent = point
	-- Deuxième invite : les améliorations, au-dessus de la première
	local upgrade = Instance.new("ProximityPrompt")
	upgrade.Name = "UpgradePrompt"
	upgrade.ActionText = "Upgrade"
	upgrade.ObjectText = "Machine"
	upgrade.KeyboardKeyCode = Enum.KeyCode.Q
	upgrade.GamepadKeyCode = Enum.KeyCode.ButtonL1
	upgrade.HoldDuration = 0
	upgrade.MaxActivationDistance = 18
	upgrade.RequiresLineOfSight = false
	upgrade.UIOffset = Vector2.new(0, -100)
	upgrade.Parent = point
	upgrade.Triggered:Connect(function(player)
		if Bases.OwnerOf(base) ~= player then
			GameService.Notice(player, "This is not your base", "warn")
			return
		end
		Remotes.OpenShop:FireClient(player, "MachineUp")
	end)
	prompt.Triggered:Connect(function(player)
		if Bases.OwnerOf(base) ~= player then
			GameService.Notice(player, "This is not your base", "warn")
			return
		end
		if busy[machine] then
			GameService.Notice(player, "The machine is already working!", "info")
			return
		end
		local d = DataService.Get(player)
		if not d or #d.cargo == 0 then
			GameService.Notice(player, "Nothing to derock. Drill asteroids out there!", "warn")
			return
		end
		task.spawn(run, player, base, machine)
	end)
end

function MachineService.Start()
	-- La boucle run() s'arrête d'elle-même quand le joueur quitte le jeu
	for _, base in ipairs(WorldBuilder.Bases) do
		bind(base)
	end
	Remotes.Machine.OnServerInvoke = function(player: Player, action: any, key: any)
		if action == "buy" then
			return buy(player, key)
		end
		return { ok = false, error = "Unknown action" }
	end
	DataService.Loaded:Connect(function(player: Player)
		MachineService.Refresh(player)
	end)
	-- le joueur part : sa machine reprend la couleur de départ pour le suivant
	Players.PlayerRemoving:Connect(function(player: Player)
		local machine = machineOf(player)
		if machine then
			paint(machine, Config.Machine.Tiers[1])
		end
	end)
	-- Studio seulement : ("set", clé, niveau) ; renvoie les niveaux
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "MachineDebug"
		bf.OnInvoke = function(cmd: string, key: string, level: number)
			local player = Players:GetPlayers()[1]
			local d = player and DataService.Get(player)
			if not d then
				return "pas de partie"
			end
			if cmd == "set" then
				d.machine[key] = level
				MachineService.Refresh(player)
			end
			return ("Speed %d Luck %d Polish %d, $%s"):format(d.machine.Speed, d.machine.Luck, d.machine.Polish, Format.Short(d.credits))
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return MachineService
