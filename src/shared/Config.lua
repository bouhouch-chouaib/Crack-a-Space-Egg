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

-- CRÉATURES (docs/Mecaniques.md §9) ----------------------------------------------
-- 6 espèces par anneau, une par rareté (fenêtre glissante) : anneaux 1 à 4 de Common à Mythic,
-- anneaux 5 à 7 de Uncommon à Cosmic. Une espèce = (anneau, rareté), clé « anneau:rareté ».
-- Size = échelle min/max, Weight = kg min/max (tirés au hasard à l'obtention).
-- Art = portrait de l'index ("" tant qu'il n'est pas dessiné : l'index montre un œuf mystère).
local function creature(name, look, size, weight, art)
	return { Name = name, Look = look, Size = size, Weight = weight, Art = art or "" }
end
Config.Creatures = {
	{ -- 1. Dust Belt
		creature("Pebblepup", "a round grey rock puppy with pebble spots", { 0.8, 1.3 }, { 2, 6 }, "rbxassetid://90741116767916"),
		creature("Dust Bunny", "a fluffy beige space-dust bunny with tiny stars in its fur", { 0.8, 1.3 }, { 1, 4 }, "rbxassetid://94023738417136"),
		creature("Craterhog", "a hedgehog whose quills are purple amethyst crystals", { 0.8, 1.4 }, { 3, 8 }, "rbxassetid://112305469629457"),
		creature("Orbitoad", "a chubby blue toad with two tiny moons orbiting its head", { 0.8, 1.4 }, { 4, 10 }, "rbxassetid://125220581470065"),
		creature("Meteor Fox", "an orange fox with a flaming meteor tail", { 0.9, 1.5 }, { 6, 14 }, "rbxassetid://87457434529699"),
		creature("Stardust Dragon", "a small sparkly pink and gold dragon made of stardust", { 0.9, 1.6 }, { 10, 25 }, "rbxassetid://92504307265377"),
	},
	{ -- 2. Ice Ring
		creature("Frostling", "a baby penguin with an ice crystal crown", { 0.8, 1.3 }, { 3, 7 }, "rbxassetid://95514930331993"),
		creature("Snow Moth", "a fluffy white moth with snowflake wings", { 0.8, 1.3 }, { 1, 3 }, "rbxassetid://102968738400324"),
		creature("Glacier Otter", "a light blue otter holding an ice shard", { 0.8, 1.4 }, { 5, 11 }, "rbxassetid://120720165056024"),
		creature("Comet Seal", "a white seal with a glowing comet trail", { 0.9, 1.4 }, { 15, 40 }, "rbxassetid://122615777392569"),
		creature("Aurora Owl", "an owl with green and violet aurora feathers", { 0.9, 1.5 }, { 3, 8 }, "rbxassetid://102347659893942"),
		creature("Crystal Yeti", "a cute yeti covered in blue ice crystals", { 1, 1.7 }, { 60, 150 }, "rbxassetid://84298675238705"),
	},
	{ -- 3. Magma Field
		creature("Cinder Slug", "a little dark slug with glowing lava spots", { 0.8, 1.3 }, { 1, 4 }),
		creature("Lava Crab", "a red crab with a volcano-shaped shell", { 0.8, 1.4 }, { 3, 9 }),
		creature("Blaze Newt", "an orange salamander with flame frills", { 0.8, 1.4 }, { 2, 6 }),
		creature("Obsidian Rhino", "a baby rhino of black obsidian with a fiery horn", { 0.9, 1.5 }, { 80, 200 }),
		creature("Solar Phoenix", "a golden phoenix chick with sun-flare wings", { 0.9, 1.5 }, { 4, 10 }),
		creature("Magma Wyrm", "a coiled dragon of cooled lava with glowing cracks", { 1, 1.7 }, { 50, 140 }),
	},
	{ -- 4. Nebula
		creature("Nebula Jelly", "a pink and violet floating jellyfish full of stars", { 0.8, 1.3 }, { 1, 3 }),
		creature("Haze Kitten", "a misty lavender kitten with a cloud tail", { 0.8, 1.3 }, { 2, 5 }),
		creature("Dreamfin", "a small sky-blue whale swimming in nebula clouds", { 0.9, 1.4 }, { 20, 60 }),
		creature("Prism Ray", "a manta ray with rainbow prism wings", { 0.9, 1.5 }, { 10, 30 }),
		creature("Nova Lion", "a lion cub with a mane of glowing star light", { 0.9, 1.5 }, { 20, 50 }),
		creature("Galaxy Unicorn", "a unicorn with a swirling galaxy mane and horn", { 1, 1.7 }, { 40, 110 }),
	},
	{ -- 5. Devourer Belt
		creature("Fang Beetle", "a dark green beetle with big friendly fangs", { 0.8, 1.3 }, { 1, 4 }),
		creature("Gloom Bat", "a round purple bat with glowing yellow eyes", { 0.8, 1.4 }, { 1, 3 }),
		creature("Void Shark", "a small black shark with a starry belly", { 0.9, 1.5 }, { 30, 90 }),
		creature("Hunger Hound", "a shadowy hound with a glowing teal collar", { 0.9, 1.5 }, { 20, 55 }),
		creature("Abyss Serpent", "a coiled deep-purple serpent with glowing runes", { 1, 1.6 }, { 30, 80 }),
		creature("Eclipse Devourer", "a majestic creature with an eclipse halo and cosmic mouth", { 1, 1.8 }, { 120, 300 }),
	},
	{ -- 6. The Rift
		creature("Chrono Snail", "a snail with a clock-spiral shell", { 0.8, 1.3 }, { 1, 3 }),
		creature("Glitch Cat", "a cat with pixel glitch stripes in cyan and magenta", { 0.8, 1.4 }, { 3, 7 }),
		creature("Paradox Panda", "a panda with swapped black and white patches and a time swirl", { 0.9, 1.5 }, { 40, 100 }),
		creature("Hourglass Tortoise", "a tortoise carrying a golden hourglass shell", { 0.9, 1.5 }, { 30, 90 }),
		creature("Rift Griffin", "a griffin with wings torn into glowing space rifts", { 1, 1.6 }, { 60, 150 }),
		creature("Quasar Kraken", "a small kraken whose head shines like a quasar", { 1, 1.8 }, { 100, 260 }),
	},
	{ -- 7. The Nest
		creature("Hatchling", "a tiny chick still wearing half of its cosmic egg shell", { 0.8, 1.3 }, { 1, 3 }),
		creature("Yolk Slime", "a golden yolk slime with a happy face", { 0.8, 1.4 }, { 2, 6 }),
		creature("Brood Raptor", "a baby raptor with amber egg-shell armor", { 0.9, 1.5 }, { 15, 40 }),
		creature("Nest Drake", "a drake that carries a nest of glowing eggs on its back", { 1, 1.6 }, { 50, 130 }),
		creature("Hive Queen", "a regal space bee queen with a crystal crown", { 1, 1.6 }, { 10, 30 }),
		creature("Cosmic Mother", "the cosmic mother of all eggs, a winged creature made of galaxies", { 1.1, 1.9 }, { 200, 500 }),
	},
}

-- Rareté de la n-ième espèce d'un anneau (fenêtre glissante)
function Config.CreatureRarity(ring: number, slot: number): number
	return if ring >= Config.CosmicMinRing then slot + 1 else slot
end

-- Récompense quand on a trouvé les 6 espèces d'un anneau : chance permanente et $
Config.IndexReward = {
	Luck = 0.1, -- +10 % de chance par anneau complété (cumulable)
	Money = 2500, -- × multiplicateur de valeur de l'anneau
}

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
