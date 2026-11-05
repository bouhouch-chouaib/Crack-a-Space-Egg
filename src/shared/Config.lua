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
-- Le vaisseau (Workspace.Ship, construit dans Studio) a son centre en (0, 0, 0) et son quai en
-- z = FrontZ ; le couloir part du quai vers +Z.
-- Les anneaux sont des cercles horizontaux autour d'un axe vertical placé derrière le vaisseau.
Config.Map = {
	FrontZ = 64, -- position du repère Ship.Deck.Dock.DockEnd (bout du quai, début du couloir)
	PlanetRadius = 500, -- au centre des anneaux, derrière le vaisseau ; le dessous du vaisseau reste du ciel
	PlanetDrop = 150, -- centre un peu sous le plan des anneaux : ils tournent autour d'elle comme ceux de Saturne
	AxisDistance = 1200, -- distance entre l'axe de rotation des anneaux et le bout du quai
	CorridorWidth = 90,
	FirstRingGap = 12, -- vide entre le bout du quai et le bord de l'anneau 1
	RingWidth = 28, -- épaisseur de l'anneau 1
	RingGap = 16, -- vide entre les anneaux 1 et 2 (bord à bord)
	RingGrowth = 1.35, -- épaisseur et vide grandissent de 35 % à chaque anneau
	RelaySize = 30, -- relais de pression, au milieu des vides assez larges entre deux anneaux
	RelayMinGap = 38, -- pas de relais dans un vide plus étroit
	BuoySpacing = 60,
	DecorPerRing = 30, -- astéroïdes de décor sur le reste de chaque anneau
	FallY = -150, -- sous cette hauteur, le joueur est perdu dans le Vide
}

-- Oxygène (docs/Mecaniques.md §12) : la statistique qu'on entraîne dans les caissons de pression,
-- l'équivalent de la vitesse des jeux d'œufs. Affichée en secondes dans le HUD.
Config.Oxygen = {
	Start = 15, -- secondes d'oxygène au départ
}

-- Événements (docs/Mecaniques.md §14) ---------------------------------------
Config.Events = {
	MeteorShower = {
		Name = "Meteor Shower",
		Icon = "☄️",
		Every = 20 * 60, -- secondes entre deux pluies
		Duration = 3 * 60,
		SpawnMult = 1.5, -- le défilement accélère
		EggMult = 1.5, -- +50 % d'œufs par astéroïde
	},
}

-- Tapis d'astéroïdes : ils naissent avant le couloir, le traversent et disparaissent après
Config.Belt = {
	MaxActive = 90, -- 60 en temps normal, plus pendant une pluie de météores
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
	newRing("Dust Belt", 4.5, 6, 8, 1, 1.0, 0, 0, Color3.fromRGB(120, 108, 98), {
		"Grey Quartz", "Calcite", "Amethyst", "Topaz", "Stellar Opal", "Pluto Diamond", "",
	}),
	newRing("Ice Ring", 4.1, 6, 40, 4, 1.3, 340, 5, Color3.fromRGB(150, 200, 230), {
		"Frostite", "Snow Crystal", "Aquamarine", "Boreal Sapphire", "Comet Tear", "Aurora Heart", "",
	}),
	newRing("Magma Field", 3.7, 7, 180, 16, 1.8, 11000, 13, Color3.fromRGB(110, 50, 40), {
		"Obsidian", "Red Basalt", "Garnet", "Volcanic Ruby", "Phoenix Eye", "Sun Blood", "",
	}),
	newRing("Nebula", 3.3, 8, 800, 64, 2.4, 350000, 21, Color3.fromRGB(120, 80, 170), {
		"Haze Quartz", "Mist Pearl", "Violet Flux", "Dreamstone", "Nova Shard", "Nebula Heart", "",
	}),
	newRing("Devourer Belt", 2.9, 9, 3600, 256, 3.2, 11000000, 30, Color3.fromRGB(70, 60, 60), {
		"Bone Flint", "Fang Stone", "Maw Garnet", "Hunger Opal", "Devourer Eye", "Abyss Crown", "Void Pearl",
	}),
	newRing("The Rift", 2.6, 11, 16000, 1024, 4.2, 350000000, 39, Color3.fromRGB(60, 90, 120), {
		"Rift Shale", "Split Jade", "Fracture Gem", "Warp Sapphire", "Paradox Prism", "Time Shard", "Rift Singularity",
	}),
	newRing("The Nest", 2.25, 13, 70000, 4096, 5.5, 11000000000, 48, Color3.fromRGB(150, 120, 80), {
		"Shell Quartz", "Nest Amber", "Brood Ruby", "Mother Opal", "Hatchling Star", "Queen's Tear", "Cosmic Yolk",
	}),
}
Config.CosmicMinRing = 5

-- Épaisseur de l'anneau i
function Config.RingWidth(i: number): number
	return Config.Map.RingWidth * Config.Map.RingGrowth ^ (i - 1)
end

-- Vide (bord à bord) entre l'anneau i et l'anneau i + 1
function Config.RingGapAfter(i: number): number
	return Config.Map.RingGap * Config.Map.RingGrowth ^ (i - 1)
end

-- Distance entre le bout du quai et le centre de l'anneau i
function Config.RingDistance(i: number): number
	local d = Config.Map.FirstRingGap
	for k = 1, i - 1 do
		d += Config.RingWidth(k) + Config.RingGapAfter(k)
	end
	return d + Config.RingWidth(i) / 2
end

-- Rayon de l'anneau i, mesuré depuis l'axe de rotation
function Config.RingRadius(i: number): number
	return Config.Map.AxisDistance + Config.RingDistance(i)
end

-- Position d'un point d'orbite : angle 0 = centre du couloir, angle positif = déjà passé
function Config.OrbitPosition(radius: number, angle: number, height: number): Vector3
	local m = Config.Map
	return Vector3.new(radius * math.sin(angle), height, radius * math.cos(angle) - m.AxisDistance + m.FrontZ)
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

-- BOUTIQUE (docs/Interfaces.md §9) ---------------------------------------------
-- Id = identifiant du passe ou du produit Robux sur Roblox : 0 tant qu'il n'est pas créé
-- (le bouton affiche alors « Coming soon! »). Price = prix affiché en Robux.
-- Jamais d'œufs ni de créatures contre des Robux.
Config.Shop = {
	-- Offre du moment, renouvelée chaque jour à minuit UTC (compte à rebours affiché)
	Featured = {
		Name = "Starter Pack",
		Text = "Big money pack + x2 Luck + x2 Money potions",
		Art = "Money4",
		Id = 0,
		Price = 99,
		Was = 249, -- prix barré
	},
	Passes = {
		{ Key = "CargoXL", Name = "Cargo XL", Text = "+50% cargo slots", Art = "PassCargoXL", Id = 0, Price = 149 },
		{ Key = "TurboJetpack", Name = "Turbo Jetpack", Text = "x2 fuel, faster flight", Art = "PassTurboJetpack", Id = 0, Price = 99 },
		{ Key = "AutoCrack", Name = "Auto Crack", Text = "Eggs crack by themselves", Art = "PassAutoCrack", Id = 0, Price = 199, Ribbon = "BEST SELLER!" },
		{ Key = "Money2x", Name = "x2 Money", Text = "Double money forever", Art = "PassMoney2x", Id = 0, Price = 299, Ribbon = "BEST VALUE!" },
		{ Key = "Training2x", Name = "x2 Training", Text = "Train oxygen twice as fast", Art = "PassTraining2x", Id = 0, Price = 149 },
		{ Key = "PetSlot", Name = "+1 Creature", Text = "Equip one more creature", Art = "PassPetSlot", Id = 0, Price = 249 },
		{ Key = "VIP", Name = "VIP", Text = "VIP tag, +10% money, chat color", Art = "PassVIP", Id = 0, Price = 399 },
	},
	-- Potions de 15 minutes (produits Robux)
	PotionMinutes = 15,
	Potions = {
		{ Key = "Luck", Name = "x2 Luck", Art = "PotionLuck", Id = 0, Price = 39 },
		{ Key = "Money", Name = "x2 Money", Art = "PotionMoney", Id = 0, Price = 39 },
		{ Key = "Suit", Name = "Suit Refill", Art = "PotionSuit", Id = 0, Price = 25 },
		{ Key = "Meteor", Name = "Meteor Shower", Text = "For the whole server!", Art = "PotionMeteor", Id = 0, Price = 99 },
	},
	-- Boost gratuit contre une pub récompensée
	FreeBoost = { Name = "Free x2 Boost", Minutes = 5, Art = "FreeBoost" },
	-- Paquets d'argent : montant = Base × multiplicateur de valeur de l'anneau le plus loin débloqué,
	-- pour qu'un paquet reste intéressant à toutes les étapes du jeu
	MoneyPacks = {
		{ Art = "Money1", Base = 500, Id = 0, Price = 19 },
		{ Art = "Money2", Base = 1800, Id = 0, Price = 49 },
		{ Art = "Money3", Base = 4000, Id = 0, Price = 99, Ribbon = "POPULAR!" },
		{ Art = "Money4", Base = 11000, Id = 0, Price = 249 },
		{ Art = "Money5", Base = 25000, Id = 0, Price = 499, Ribbon = "BEST VALUE!" },
	},
}

function Config.MoneyPackAmount(base: number, ring: number): number
	local r = Config.Rings[math.clamp(ring, 1, #Config.Rings)]
	return base * r.ValueMult
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
