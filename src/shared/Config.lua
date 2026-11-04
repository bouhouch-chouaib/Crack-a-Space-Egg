-- Toutes les valeurs d'équilibrage du jeu (fiche de game design, section Progression).
-- Les textes affichés sont en anglais : l'audience Roblox est mondiale.

local Config = {}

Config.SaveKey = "Player_v1" -- ne pas changer : le schéma est versionné dans DataService
Config.AutosaveSeconds = 60

-- Raretés : nom affiché, chance de base, valeur de base (crédits à l'anneau 1), couleur
Config.Rarities = {
	{ Id = "Common", Name = "Common", Chance = 0.58, Value = 2, Color = Color3.fromRGB(170, 176, 190) },
	{ Id = "Uncommon", Name = "Uncommon", Chance = 0.27, Value = 5, Color = Color3.fromRGB(80, 200, 110) },
	{ Id = "Rare", Name = "Rare", Chance = 0.11, Value = 14, Color = Color3.fromRGB(70, 140, 255) },
	{ Id = "Epic", Name = "Epic", Chance = 0.0375, Value = 50, Color = Color3.fromRGB(170, 90, 255) },
	{ Id = "Legendary", Name = "Legendary", Chance = 0.0025, Value = 400, Color = Color3.fromRGB(255, 196, 40) },
	{ Id = "Mythic", Name = "Mythic", Chance = 0.00025, Value = 5000, Color = Color3.fromRGB(255, 70, 160) },
	{ Id = "Cosmic", Name = "Cosmic", Chance = 0.00001, Value = 150000, Color = Color3.fromRGB(120, 255, 240) },
}
-- Index (1..7) à partir duquel la chance est multipliée par le bonus de profondeur
Config.DepthBonusFrom = 5
-- Index à partir duquel le scanner augmente la chance
Config.LuckFrom = 3
-- Une annonce serveur à partir de cette rareté
Config.AnnounceFrom = 6
-- Compteur de veine : Légendaire garanti après N géodes sans Légendaire ou mieux
Config.PityLegendary = 1000

-- CARTE V2 (docs/Mecaniques.md §2) ---------------------------------------------
-- Le vaisseau est à l'origine, son avant en z = 0 ; le couloir part vers +Z.
-- Les anneaux sont des cercles horizontaux autour d'un axe vertical placé derrière le vaisseau.
Config.Map = {
	PlanetRadius = 1200,
	PlanetDrop = 750, -- le centre de la planète est sous le plan des anneaux : elle paraît sous le vaisseau
	AxisDistance = 1200, -- distance entre l'axe de rotation des anneaux et l'avant du vaisseau
	ShipSize = Vector3.new(240, 4, 140),
	BubbleSize = 400, -- bulle de pression autour du vaisseau et des bases
	BaseSize = Vector3.new(36, 2, 28),
	DockLength = 20, -- quai de départ, à l'avant du vaisseau
	CorridorWidth = 90,
	FirstRingDistance = 220, -- distance entre l'avant du vaisseau et le centre de l'anneau 1
	RingGap = 150, -- écart entre les centres des anneaux 1 et 2
	RingWidth = 60, -- épaisseur de l'anneau 1
	RingGrowth = 1.35, -- écart et épaisseur grandissent de 35 % à chaque anneau
	PadSpacing = 32, -- plateformes du couloir entre deux anneaux (saut + jetpack)
	PadSize = Vector3.new(12, 1.5, 12),
	RelaySize = 30, -- relais de pression, au milieu de chaque espace entre deux anneaux
	BuoySpacing = 60,
	DecorPerRing = 30, -- astéroïdes de décor sur le reste de chaque anneau
	FallY = -150, -- sous cette hauteur, le joueur est perdu dans le Vide
}

-- Tapis d'astéroïdes : ils naissent avant le couloir, le traversent et disparaissent après
Config.Belt = {
	MaxActive = 60,
	SpawnArc = 160, -- studs d'arc entre le point de naissance et le centre du couloir (idem après)
	HeightJitter = 8,
}

-- Tailles d'astéroïdes : stock d'œufs, qui sortent un par un pendant le forage
Config.AsteroidSizes = {
	{ Name = "Small", Min = 10, Max = 13, Eggs = 3, Chance = 0.5 },
	{ Name = "Medium", Min = 15, Max = 19, Eggs = 5, Chance = 0.35 },
	{ Name = "Large", Min = 22, Max = 28, Eggs = 8, Chance = 0.15 },
}

-- Les 7 anneaux. Speed = vitesse de défilement (studs/s) : les anneaux intérieurs vont plus vite.
-- Active = astéroïdes visibles en même temps. EggHP = dégâts de forage pour détacher un œuf.
local function newRing(name, speed, active, eggHP, valueMult, depth, unlockCost, drillLevel, color, crystals)
	return {
		Name = name,
		Speed = speed,
		Active = active,
		EggHP = eggHP,
		ValueMult = valueMult,
		Depth = depth,
		UnlockCost = unlockCost,
		DrillLevel = drillLevel,
		Color = color,
		Crystals = crystals,
	}
end
Config.Rings = {
	newRing("Dust Belt", 4.5, 9, 8, 1, 1.0, 0, 0, Color3.fromRGB(120, 108, 98), {
		"Grey Quartz", "Calcite", "Amethyst", "Topaz", "Stellar Opal", "Pluto Diamond", "",
	}),
	newRing("Ice Ring", 4.1, 9, 40, 4, 1.3, 340, 5, Color3.fromRGB(150, 200, 230), {
		"Frostite", "Snow Crystal", "Aquamarine", "Boreal Sapphire", "Comet Tear", "Aurora Heart", "",
	}),
	newRing("Magma Field", 3.7, 9, 180, 16, 1.8, 11000, 13, Color3.fromRGB(110, 50, 40), {
		"Obsidian", "Red Basalt", "Garnet", "Volcanic Ruby", "Phoenix Eye", "Sun Blood", "",
	}),
	newRing("Nebula", 3.3, 8, 800, 64, 2.4, 350000, 21, Color3.fromRGB(120, 80, 170), {
		"Haze Quartz", "Mist Pearl", "Violet Flux", "Dreamstone", "Nova Shard", "Nebula Heart", "",
	}),
	newRing("Devourer Belt", 2.9, 8, 3600, 256, 3.2, 11000000, 30, Color3.fromRGB(70, 60, 60), {
		"Bone Flint", "Fang Stone", "Maw Garnet", "Hunger Opal", "Devourer Eye", "Abyss Crown", "Void Pearl",
	}),
	newRing("The Rift", 2.6, 8, 16000, 1024, 4.2, 350000000, 39, Color3.fromRGB(60, 90, 120), {
		"Rift Shale", "Split Jade", "Fracture Gem", "Warp Sapphire", "Paradox Prism", "Time Shard", "Rift Singularity",
	}),
	newRing("The Nest", 2.25, 8, 70000, 4096, 5.5, 11000000000, 48, Color3.fromRGB(150, 120, 80), {
		"Shell Quartz", "Nest Amber", "Brood Ruby", "Mother Opal", "Hatchling Star", "Queen's Tear", "Cosmic Yolk",
	}),
}
Config.CosmicMinRing = 5

-- Distance entre l'avant du vaisseau et le centre de l'anneau i
function Config.RingDistance(i: number): number
	local m = Config.Map
	local d = m.FirstRingDistance
	for k = 1, i - 1 do
		d += m.RingGap * m.RingGrowth ^ (k - 1)
	end
	return d
end

-- Épaisseur de l'anneau i
function Config.RingWidth(i: number): number
	return Config.Map.RingWidth * Config.Map.RingGrowth ^ (i - 1)
end

-- Rayon de l'anneau i, mesuré depuis l'axe de rotation
function Config.RingRadius(i: number): number
	return Config.Map.AxisDistance + Config.RingDistance(i)
end

-- Position d'un point d'orbite : angle 0 = centre du couloir, angle positif = déjà passé
function Config.OrbitPosition(radius: number, angle: number, height: number): Vector3
	return Vector3.new(radius * math.sin(angle), height, radius * math.cos(angle) - Config.Map.AxisDistance)
end

-- Améliorations : coût = Base * Growth^niveau
Config.Upgrades = {
	Drill = { Name = "Drill", Base = 12, Growth = 1.36, Max = 60 },
	Cargo = { Name = "Cargo", Base = 40, Growth = 1.5, Max = 30 },
	Thruster = { Name = "Thruster", Base = 30, Growth = 1.7, Max = 25 },
	Scanner = { Name = "Scanner", Base = 90, Growth = 2.05, Max = 20 },
}
Config.UpgradeOrder = { "Drill", "Cargo", "Thruster", "Scanner" }

-- Mutations
Config.Sizes = {
	{ Name = "Small", Chance = 0.30, Mult = 0.7 },
	{ Name = "", Chance = 0.55, Mult = 1 },
	{ Name = "Large", Chance = 0.13, Mult = 1.6 },
	{ Name = "Colossal", Chance = 0.02, Mult = 4 },
}
Config.ShinyChance = 1 / 40
Config.ShinyMult = 3

-- Forage
Config.DrillRange = 22 -- studs entre le joueur et la surface de l'astéroïde
Config.DrillTick = 0.25 -- secondes entre deux coups envoyés au serveur
Config.DrillSlack = 10 -- marge de portée côté serveur (latence + défilement)

-- Jetpack (côté client)
Config.JetpackFuelBase = 2.5 -- secondes de poussée
Config.JetpackFuelPerLevel = 0.12
Config.JetpackThrust = 55 -- vitesse verticale visée
Config.JetpackRefill = 1.6 -- secondes de carburant regagnées par seconde au sol

-- Statistiques dérivées des niveaux
function Config.DrillPower(level: number): number
	return 5 * 1.18 ^ level
end

function Config.CargoSlots(level: number): number
	return 4 + level
end

function Config.Speed(level: number): number
	return 1 + 0.08 * level
end

function Config.Luck(level: number): number
	return 1 + 0.05 * level
end

function Config.UpgradeCost(id: string, level: number): number
	local u = Config.Upgrades[id]
	return math.floor(u.Base * u.Growth ^ level + 0.5)
end

-- Probabilités d'une géode selon l'anneau et la chance du joueur
function Config.Probabilities(ringIndex: number, luck: number): { number }
	local ring = Config.Rings[ringIndex]
	local p = {}
	local others = 0
	for i, r in ipairs(Config.Rarities) do
		local c = r.Chance
		if i >= Config.LuckFrom then
			c *= luck
		end
		if i >= Config.DepthBonusFrom then
			c *= ring.Depth
		end
		if i == 7 and ringIndex < Config.CosmicMinRing then
			c = 0
		end
		p[i] = c
		if i > 1 then
			others += c
		end
	end
	p[1] = 1 - others
	return p
end

return Config
