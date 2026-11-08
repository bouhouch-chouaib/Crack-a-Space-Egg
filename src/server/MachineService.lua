-- Machine à dérocher de chaque base (docs/Mecaniques.md §7) et ses améliorations (Config.Machine).
-- Remotes.Machine (RemoteFunction) : ("buy", clé) -> { ok, error? }. Niveaux publiés en attributs Mach_<clé>.
-- Le propriétaire déclenche la machine à la console : elle prend les œufs de sa soute un par un,
-- retire la roche (durée selon la rareté), puis range l'œuf dégagé dans « ready » (à couver ensuite).
-- Le serveur pose l'état du travail en cours en attributs sur le modèle de la machine ;
-- chaque client anime la machine à partir de ces attributs (Derock.client).
--   JobStart / JobEnd : temps serveur du travail en cours (absents = machine au repos)
--   EggRing / EggRarity : l'œuf en cours ; Queue : œufs restants après lui ; Owner : UserId

local MarketplaceService = game:GetService("MarketplaceService")
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
local skipped: { [Model]: boolean } = {} -- « Finish now » payé : le travail en cours se termine tout de suite
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

-- Dégage l'œuf de la soute. Il quitte la soute dès le début : le joueur peut repartir forer pendant ce temps
local function run(player: Player, base: Model, machine: Model)
	busy[machine] = true
	while player.Parent and Bases.OwnerOf(base) == player do
		local d = DataService.Get(player)
		if not d or #d.cargo == 0 then
			break
		end
		-- s'il quitte le jeu avant la fin, d.derocking est rendu à la soute à son retour (rien n'est perdu)
		local egg = table.remove(d.cargo, 1)
		d.derocking = egg
		GameService.Sync(player)
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
		local duration = if (d.guide or 0) < Config.Guide.Steps then Config.Derock.Tutorial else Config.MachineTime(rarity, levels.Speed or 0)
		local now = workspace:GetServerTimeNow()
		local geode = type(egg) == "table" and egg.kind == "geode"
		machine:SetAttribute("EggRing", ring)
		machine:SetAttribute("EggRarity", rarity)
		machine:SetAttribute("EggKind", if geode then "geode" else "egg")
		machine:SetAttribute("Queue", 0)
		machine:SetAttribute("Owner", player.UserId)
		machine:SetAttribute("JobStart", now)
		machine:SetAttribute("JobEnd", now + duration)
		local derock = machine:FindFirstChild("DerockPrompt", true) :: ProximityPrompt?
		if derock and Config.Derock.Skip[rarity] and duration > 2 then
			derock.ActionText = "Finish now"
			derock.ObjectText = "R$ " .. Config.Derock.Skip[rarity].Price
		end
		local ends = now + duration
		while workspace:GetServerTimeNow() < ends and player.Parent do
			if skipped[machine] then
				skipped[machine] = nil
				ends = workspace:GetServerTimeNow() + 1
				machine:SetAttribute("JobEnd", ends)
				GameService.Notice(player, "{Lightning} Machine boosted!", "good")
			end
			task.wait(0.1)
		end
		if derock then
			derock.ActionText = "Derock"
			derock.ObjectText = "Derock Machine"
		end
		if not player.Parent then
			break
		end
		d = DataService.Get(player)
		if not d or d.derocking ~= egg then
			break
		end
		d.derocking = nil
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
			if duration >= 10 then
				GameService.Notice(player, ("{Egg} Your %s egg is out of the rock!"):format(Config.Rarities[rarity].Name), "good")
			end
		end
		task.wait(Config.Derock.Gap)
		break
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
	prompt.Triggered:Connect(function(player)
		if Bases.OwnerOf(base) ~= player then
			GameService.Notice(player, "This is not your base", "warn")
			return
		end
		-- la machine travaille : ce même bouton sert à la finir tout de suite
		if busy[machine] then
			local job = machine:GetAttribute("JobEnd") :: number?
			local skip = Config.Derock.Skip[(machine:GetAttribute("EggRarity") or 1) :: number]
			if job and skip and job - workspace:GetServerTimeNow() > 2 then
				if skip.ProductId == 0 then
					GameService.Notice(player, "Coming soon!", "info")
				else
					MarketplaceService:PromptProductPurchase(player, skip.ProductId)
				end
			end
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

-- « Finish now » payé (MonetizationService) ; false si la machine ne travaille pas (Roblox redemandera plus tard)
function MachineService.FinishNow(player: Player): boolean
	local machine = machineOf(player)
	if not machine or machine:GetAttribute("Owner") ~= player.UserId or not machine:GetAttribute("JobEnd") then
		return false
	end
	skipped[machine] = true
	return true
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
		local d = DataService.Get(player)
		if d and d.derocking then
			table.insert(d.cargo, 1, d.derocking)
			d.derocking = nil
		end
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
			elseif cmd == "finish" then
				return tostring(MachineService.FinishNow(player))
			elseif cmd == "cargo" then -- ("cargo", anneau, rareté) : un œuf dans la soute
				table.insert(d.cargo, { ring = key, rarity = level, kind = "egg" })
				GameService.Sync(player)
			end
			return ("Speed %d Luck %d Polish %d, $%s"):format(d.machine.Speed, d.machine.Luck, d.machine.Polish, Format.Short(d.credits))
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return MachineService
