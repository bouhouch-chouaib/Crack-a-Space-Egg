-- Toutes les valeurs d'équilibrage du jeu (fiche de game design, section Progression).
-- Les textes affichés sont en anglais : l'audience Roblox est mondiale.

local Config = {}

Config.SaveKey = "Player_v1"
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

-- Anneaux de la version de Noël (MVP : 1 à 3). Distance = rayon du centre de l'anneau depuis la station.
Config.Rings = {
	{
		Name = "Dust Belt",
		Radius = 140,
		Width = 70,
		Asteroids = 40,
		HP = 10,
		GeodesPerAsteroid = 1,
		ValueMult = 1,
		Depth = 1.0,
		UnlockCost = 0,
		DrillLevel = 0,
		Color = Color3.fromRGB(120, 108, 98),
		Crystals = { "Grey Quartz", "Calcite", "Amethyst", "Topaz", "Stellar Opal", "Pluto Diamond", "" },
	},
	{
		Name = "Ice Ring",
		Radius = 260,
		Width = 70,
		Asteroids = 60,
		HP = 60,
		GeodesPerAsteroid = 1,
		ValueMult = 4,
		Depth = 1.3,
		UnlockCost = 340,
		DrillLevel = 5,
		Color = Color3.fromRGB(150, 200, 230),
		Crystals = { "Frostite", "Snow Crystal", "Aquamarine", "Boreal Sapphire", "Comet Tear", "Aurora Heart", "" },
	},
	{
		Name = "Magma Field",
		Radius = 380,
		Width = 70,
		Asteroids = 80,
		HP = 400,
		GeodesPerAsteroid = 2,
		ValueMult = 16,
		Depth = 1.8,
		UnlockCost = 11000,
		DrillLevel = 13,
		Color = Color3.fromRGB(110, 50, 40),
		Crystals = { "Obsidian", "Red Basalt", "Garnet", "Volcanic Ruby", "Phoenix Eye", "Sun Blood", "" },
	},
}
Config.CosmicMinRing = 5 -- n'existe pas encore dans le MVP

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
Config.AsteroidRespawn = 25

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
