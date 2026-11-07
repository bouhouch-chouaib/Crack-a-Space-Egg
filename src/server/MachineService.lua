-- Machine à dérocher de chaque base (docs/Mecaniques.md §7).
-- Le propriétaire déclenche la machine à la console : elle prend les œufs de sa soute un par un,
-- retire la roche (durée selon la rareté), puis range l'œuf dégagé dans « ready » (à couver ensuite).
-- Le serveur pose l'état du travail en cours en attributs sur le modèle de la machine ;
-- chaque client anime la machine à partir de ces attributs (Derock.client).
--   JobStart / JobEnd : temps serveur du travail en cours (absents = machine au repos)
--   EggRing / EggRarity : l'œuf en cours ; Queue : œufs restants après lui ; Owner : UserId

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
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
		local duration = Config.Derock.Time + Config.Derock.PerRarity * (rarity - 1)
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
			local size = pickSize()
			local shiny = rng:NextNumber() < Config.ShinyChance
			local gem = {
				ring = ring,
				rarity = rarity,
				size = size.Name,
				mult = size.Mult,
				shiny = shiny,
				value = Config.GemValue(ring, rarity, size.Mult, shiny),
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
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = point
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
end

return MachineService
