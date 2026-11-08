-- Toutes les valeurs d'équilibrage du jeu (fiche de game design, section Progression).
-- Les textes affichés sont en anglais : l'audience Roblox est mondiale.

local Config = {}

Config.SaveKey = "Player_v1" -- ne pas changer : le schéma est versionné dans DataService
Config.AutosaveSeconds = 60

-- Raretés : nom affiché, valeur de base (crédits à l'anneau 1), couleur.
-- Les chances sont par œuf et par anneau : voir Config.Eggs plus bas.
Config.Rarities = {
	{ Id = "Common", Name = "Common", Value = 2, Color = Color3.fromRGB(170, 176, 190) },
	{ Id = "Uncommon", Name = "Uncommon", Value = 5, Color = Color3.fromRGB(80, 200, 110) },
	{ Id = "Rare", Name = "Rare", Value = 14, Color = Color3.fromRGB(70, 140, 255) },
	{ Id = "Epic", Name = "Epic", Value = 50, Color = Color3.fromRGB(170, 90, 255) },
	{ Id = "Legendary", Name = "Legendary", Value = 400, Color = Color3.fromRGB(255, 196, 40) },
	{ Id = "Mythic", Name = "Mythic", Value = 5000, Color = Color3.fromRGB(255, 70, 160) },
	{ Id = "Cosmic", Name = "Cosmic", Value = 150000, Color = Color3.fromRGB(120, 255, 240) },
}
-- Index à partir duquel le scanner augmente la chance
Config.LuckFrom = 3
-- Une annonce serveur à partir de cette rareté
Config.AnnounceFrom = 6
-- Compteur de veine : Légendaire garanti après N géodes sans Légendaire ou mieux
Config.PityLegendary = 1000

-- CARTE V2 (docs/Mecaniques.md §2) ---------------------------------------------
-- Le vaisseau (Workspace.Ship, construit dans Studio) a son centre en (0, 0, 0) et son quai en
-- z = FrontZ ; le couloir part du quai vers +Z.
-- Les anneaux sont des cercles horizontaux autour d'un axe vertical placé derrière le vaisseau,
-- là où la planète géante est peinte dans le ciel (tools/sky/render_sky.py).
Config.Map = {
	FrontZ = 64, -- position du repère Ship.Deck.Dock.DockEnd (bout du quai, début du couloir)
	AxisDistance = 1200, -- distance entre l'axe de rotation des anneaux et le bout du quai
	CorridorWidth = 120, -- = largeur du quai (Ship.Deck.Dock), à garder identiques
	FirstRingGap = 12, -- vide entre le bout du quai et le bord de l'anneau 1
	RingWidth = 64, -- épaisseur de l'anneau 1 : un vrai champ, pas une ligne
	RingGap = 55, -- vide entre les anneaux 1 et 2 (bord à bord) : chaque biome bien séparé
	RingGrowth = 1.22, -- épaisseur et vide grandissent de 22 % à chaque anneau
	RelaySize = 30, -- relais de pression, au milieu des vides assez larges entre deux anneaux
	RelayMinGap = math.huge, -- relais retirés (7 nov.) : c'est le carburant du jetpack qui décide quels vides on traverse
	BuoySpacing = 60,
	-- Champ de décor : roches du biome de chaque côté du tapis, sur toute l'épaisseur et la hauteur
	DecorArc = 750, -- studs d'arc couverts de chaque côté du couloir (au-delà, la brume cache tout)
	DecorDensity = 1 / 2600, -- roches par stud² de champ
	DecorMax = 70, -- plafond par anneau (lisibilité et performances)
	FallY = -85, -- sous cette hauteur, le joueur est perdu dans le Vide (sous les roches les plus basses)
	RespawnTime = 1.5, -- secondes avant de réapparaître à sa base après une mort
}

-- GEL HORS DU COULOIR (ColdService, ColdFx.client) ---------------------------------------------
-- Hors du couloir (entre les bouées) et hors du vaisseau, il n'y a plus d'oxygène et le froid gagne :
-- après quelques secondes de répit, le gel monte ; trop loin, il monte tout de suite et 2× plus vite.
-- À 100 %, le joueur est pris dans un bloc de glace puis renvoyé à sa base (il perd ses œufs).
-- MONSTRES (anneaux 5 à 7, docs/Mecaniques.md §13) ---------------------------------------
-- Un monstre par anneau, chacun repère le joueur à sa façon :
--   Noise : la jauge de bruit (forer, pousser au jetpack) ; à 1, il se réveille
--   Guard : forer un astéroïde gardé (lueur et œil au-dessus) le réveille aussitôt
--   Both  : les deux
-- Il poursuit le joueur un temps qui dépend de la rareté de l'œuf qu'il porte (ChaseTime), puis
-- abandonne. S'il l'attrape : l'œuf est perdu et le joueur revient à sa base. Le vaisseau protège.
Config.Monsters = {
	Kinds = {
		[5] = { Name = "Devourer", Model = "Devourer", Sense = "Noise", Speed = 0.85, Size = 30, Color = Color3.fromRGB(150, 255, 90) },
		[6] = { Name = "Rift Watcher", Model = "Watcher", Sense = "Guard", Speed = 0.9, Size = 20, Color = Color3.fromRGB(90, 230, 255) },
		[7] = { Name = "Nest Queen", Model = "Queen", Sense = "Both", Speed = 0.95, Size = 34, Color = Color3.fromRGB(255, 170, 60) },
	},
	-- Bruit (par seconde) : forer, pousser au jetpack ; il retombe quand on reste discret
	Noise = { Drill = 0.09, Jet = 0.06, Decay = 0.18, QuietDelay = 1, Warn = 0.7 },
	-- Astéroïdes gardés (anneaux Guard et Both) : part, œufs en plus, rareté tirée deux fois (la meilleure)
	GuardShare = 0.22,
	GuardEggs = 1.5,
	-- Durée de la poursuite (s) selon la rareté de l'œuf porté (1 = Commun … 7 = Cosmique), sans œuf : NoEgg
	ChaseTime = { 8, 10, 13, 16, 20, 25, 30 },
	NoEgg = 5,
	Emerge = 1.4, -- secondes où il sort (on a le temps de fuir)
	CatchRadius = 6, -- en plus de son rayon
	MinSpeed = 18, -- studs/s au minimum (sinon vitesse en vol du joueur × Speed)
	Cooldown = 12, -- secondes de répit après une poursuite
	RingMargin = 30, -- studs autour de l'épaisseur de l'anneau où il règne
}

Config.Cold = {
	Margin = 6, -- studs de tolérance au-delà des bouées et du bord du vaisseau
	Grace = 3, -- secondes hors zone avant que le gel commence
	FreezeTime = 7, -- secondes pour geler complètement (après le répit)
	FarDistance = 40, -- studs hors zone : au-delà, pas de répit et gel 2× plus rapide
	Thaw = 0.6, -- dégel par seconde une fois revenu dans la zone
	FrozenTime = 2.2, -- secondes dans le bloc de glace avant le retour à la base
	SlowDown = 0.45, -- part de la vitesse perdue quand on est presque gelé
	Art = {
		FrostLight = "rbxassetid://104990694834643",
		FrostHeavy = "rbxassetid://125100708027197",
		Cracks = "rbxassetid://73942140990042",
		Vignette = "rbxassetid://114352063755780",
		Arrow = "rbxassetid://113480192157946",
	},
}

-- Oxygène de l'œuf (ColdService) : dès qu'on a sorti un œuf de la roche, on a ce nombre de secondes
-- (selon l'anneau où on l'a foré) pour le ramener au vaisseau. À zéro : plus d'air, on meurt et l'œuf
-- est perdu. Le temps s'arrête et se recharge dès qu'on est de retour sur le vaisseau.
-- Un peu plus de temps pour les anneaux lointains, mais bien moins que la distance en plus : plus on va
-- loin, plus il faut un bon jetpack pour revenir à temps.
Config.Oxygen = {
	Time = { 45, 50, 55, 60, 65, 70, 75 },
	Low = 0.3, -- part restante sous laquelle l'alerte rouge commence
	-- studs ajoutés à la boîte du vaisseau pour « de retour à bord » : négatif = un peu à l'intérieur du bord,
	-- car les roches de l'anneau 1 frôlent le vaisseau (sinon le compte à rebours ne partirait pas)
	ShipMargin = -6,
}

-- Vitesse au sol et en vol : elle monte avec le NIVEAU DU JETPACK (Config.Jetpack), qu'on farme dans
-- les souffleries du vaisseau (l'équivalent des tapis de course) et en volant pendant les missions.
Config.Movement = {
	Walk = 16, -- vitesse au sol au niveau 1 (studs/s)
	PerLevel = 0.005, -- +0,5 % de vitesse au sol par niveau de jetpack
	Air = 20, -- vitesse horizontale en vol au niveau 1
	AirPerLevel = 0.15, -- + studs/s en vol par niveau (42 au niveau 150)
	Climb = 32, -- vitesse de montée maximale quand on pousse
	Gravity = 70, -- = Workspace.Gravity (sert au calcul de la portée d'un vol)
	AirAccel = 5, -- réactivité en vol (plus haut = virages plus secs)
	ClimbAccel = 90, -- accélération verticale de la poussée (studs/s²)
	FallBrake = 0.35, -- en vol plané (Saut relâché), la chute est freinée de ce facteur
}

-- Tapis d'astéroïdes : ils naissent avant le couloir, le traversent et disparaissent après
Config.Belt = {
	MaxActive = 230, -- environ 160 en temps normal
	SpawnArc = 180, -- studs d'arc entre le point de naissance et le centre du couloir (idem après)
	-- Hauteur : les astéroïdes s'étalent sur plusieurs étages, plus haut dans les grands anneaux
	HeightBase = 10, -- ± studs au minimum
	HeightPerWidth = 0.15, -- + 15 % de l'épaisseur de l'anneau
	HeightMax = 36,
	Spacing = 0.9, -- deux astéroïdes ne naissent pas plus près que 90 % de leurs rayons cumulés
	-- Couche de marche : une partie des astéroïdes passe à la hauteur du pont, du côté intérieur de
	-- l'anneau. On peut forer depuis le quai (ou un relais) et sauter de roche en roche.
	WalkShare = 0.6, -- part des astéroïdes dans la couche de marche
	WalkHeight = { -9, 0 }, -- hauteur de leur centre (le pont est à 0)
	WalkDepth = 0.3, -- ils restent dans les 30 % intérieurs de l'épaisseur de l'anneau (près du quai / du relais)
}

-- Demi-hauteur du champ de l'anneau i (les astéroïdes vont de -h à +h)
function Config.FieldHeight(i: number): number
	local b = Config.Belt
	return math.min(b.HeightBase + Config.RingWidth(i) * b.HeightPerWidth, b.HeightMax)
end

-- Tailles d'astéroïdes : stock d'œufs, qui sortent un par un pendant le forage
-- Eggs = { min, max } : nombre d'œufs tiré au hasard, selon la taille. Vie = œufs × EggHP de l'anneau.
Config.AsteroidSizes = {
	{ Name = "Small", Min = 10, Max = 13, Eggs = { 2, 3 }, Chance = 0.46 },
	{ Name = "Medium", Min = 15, Max = 19, Eggs = { 4, 5 }, Chance = 0.34 },
	{ Name = "Large", Min = 22, Max = 28, Eggs = { 6, 8 }, Chance = 0.16 },
	{ Name = "Colossal", Min = 34, Max = 42, Eggs = { 10, 12 }, Chance = 0.04 },
}
-- Fissures : de nouvelles fissures apparaissent quand la vie passe sous ces fractions
Config.CrackStages = { 0.75, 0.5, 0.25 }

-- Les 7 anneaux. Speed = vitesse de défilement (studs/s) : les anneaux intérieurs vont plus vite.
-- Active = astéroïdes visibles en même temps. EggHP = dégâts de forage pour détacher un œuf
-- (la barre de vie d'un œuf ; triplée le 7 nov. pour que la soute se remplisse moins vite).
local function newRing(name, speed, active, eggHP, valueMult, depth, unlockCost, color, crystals)
	return {
		Name = name,
		Speed = speed,
		Active = active,
		EggHP = eggHP,
		ValueMult = valueMult,
		Depth = depth,
		UnlockCost = unlockCost,
		Color = color,
		Crystals = crystals,
	}
end
-- UnlockCost : plus utilisé depuis le 7 nov. (tous les anneaux sont ouverts, on y va à ses risques ;
-- c'est la portée du jetpack qui décide). Ancien calcul : prix calés sur les revenus (Config.Hatch), avec une base
-- pleine de créatures plutôt communes de l'anneau précédent, il faut environ 10 min (anneau 2),
-- 15 min (3), 20 min (4), 30 min (5), 45 min (6) et 1 h (7).
Config.Rings = {
	newRing("Dust Belt", 3.4, 20, 24, 1, 1.0, 0, Color3.fromRGB(120, 108, 98), {
		"Grey Quartz", "Calcite", "Amethyst", "Topaz", "Stellar Opal", "Pluto Diamond", "",
	}),
	newRing("Ice Ring", 3.1, 18, 120, 4, 1.3, 75000, Color3.fromRGB(150, 200, 230), {
		"Frostite", "Snow Crystal", "Aquamarine", "Boreal Sapphire", "Comet Tear", "Aurora Heart", "",
	}),
	newRing("Magma Field", 2.8, 20, 540, 16, 1.8, 4e6, Color3.fromRGB(110, 50, 40), {
		"Obsidian", "Red Basalt", "Garnet", "Volcanic Ruby", "Phoenix Eye", "Sun Blood", "",
	}),
	newRing("Nebula", 2.5, 22, 2400, 64, 2.4, 2e8, Color3.fromRGB(120, 80, 170), {
		"Haze Quartz", "Mist Pearl", "Violet Flux", "Dreamstone", "Nova Shard", "Nebula Heart", "",
	}),
	newRing("Devourer Belt", 2.2, 24, 10800, 256, 3.2, 1e10, Color3.fromRGB(70, 60, 60), {
		"Bone Flint", "Fang Stone", "Maw Garnet", "Hunger Opal", "Devourer Eye", "Abyss Crown", "Void Pearl",
	}),
	newRing("The Rift", 1.95, 28, 48000, 1024, 4.2, 5.5e11, Color3.fromRGB(60, 90, 120), {
		"Rift Shale", "Split Jade", "Fracture Gem", "Warp Sapphire", "Paradox Prism", "Time Shard", "Rift Singularity",
	}),
	newRing("The Nest", 1.7, 32, 210000, 4096, 5.5, 2.6e13, Color3.fromRGB(150, 120, 80), {
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
	-- Coût du niveau n = Base × Growth^n (de quelques centaines de $ aux milliers de milliards)
	Scanner = { Name = "Scanner", Base = 800, Growth = 3.1, Max = 20 },
}
Config.UpgradeOrder = { "Scanner" }

-- MACHINE À DÉROCHER (docs/Mecaniques.md §7) ---------------------------------------
-- Les œufs sortent des astéroïdes encore pris dans la roche ; la machine de la base la retire.
-- Durée pour un œuf = Time + PerRarity × (rareté - 1) secondes ; Gap = pause entre deux œufs
-- (le temps que l'œuf révélé vole jusqu'au joueur).
Config.Derock = {
	Time = 4,
	PerRarity = 0.5,
	Gap = 1.6,
}

-- FOREUSES ------------------------------------------------------------------------
-- Une foreuse de départ, puis 10 à acheter une par une (comme les pioches des jeux d'œufs),
-- en $ ou en Robux. Toutes marchent sur tous les anneaux : une petite foreuse est juste lente.
-- Power = dégâts par seconde de forage (un œuf sort quand on a fait EggHP de dégâts).
-- ProductId = produit Robux de cette foreuse (0 tant qu'il n'est pas créé).
local function drill(name, power, cost, robux, color)
	return { Name = name, Power = power, Cost = cost, Robux = robux, ProductId = 0, Color = color }
end
-- Prix en $ calés sur les revenus des créatures : chaque foreuse vaut à peu près le déblocage d'un demi-anneau
Config.Drills = {
	drill("Starter Drill", 5, 0, 0, Color3.fromRGB(170, 176, 190)),
	drill("Rusty Drill", 14, 2000, 25, Color3.fromRGB(196, 120, 70)), -- 2K (retour de test du 7 nov. : 5K trop cher)
	drill("Steel Drill", 40, 65000, 49, Color3.fromRGB(150, 170, 200)),
	drill("Turbo Drill", 110, 850000, 79, Color3.fromRGB(80, 170, 255)),
	drill("Laser Drill", 320, 1.1e7, 129, Color3.fromRGB(90, 230, 120)),
	drill("Plasma Drill", 900, 1.4e8, 199, Color3.fromRGB(190, 100, 255)),
	drill("Golden Drill", 2600, 1.8e9, 299, Color3.fromRGB(255, 200, 50)),
	drill("Crystal Drill", 7500, 2.3e10, 449, Color3.fromRGB(120, 240, 255)),
	drill("Nova Drill", 21000, 3e11, 699, Color3.fromRGB(255, 120, 80)),
	drill("Galaxy Drill", 60000, 4e12, 999, Color3.fromRGB(255, 110, 210)),
	drill("Cosmic Drill", 170000, 5e13, 1499, Color3.fromRGB(130, 255, 240)),
}
-- Produits Robux des foreuses (créés le 7 nov. sur Roblox, palier 2 à 11)
for tier, id in pairs({
	[2] = 3729246395, [3] = 3729246424, [4] = 3729246438, [5] = 3729246452, [6] = 3729246472,
	[7] = 3729246638, [8] = 3729246665, [9] = 3729246690, [10] = 3729246706, [11] = 3729246737,
}) do
	Config.Drills[tier].ProductId = id
end

-- SKINS DE FOREUSE (atelier des foreuses, onglet SKINS) ---------------------------------
-- Ils ne changent que l'apparence (couleurs des pièces Body, Trim, Dark, Bit, Glow) et se gardent
-- quand on change de foreuse. Price en $ ; Robux = skin vendu comme passe (PassId sur Roblox).
-- Rarity : couleur du cadre (Config.Rarities). Accent : couleur du rayon de forage.
-- Effect : "Sparkle" (étincelles), "Rainbow" (couleurs qui défilent), "Flames" (flammes).
local function skin(key, name, rarity, price, body, trim, dark, bit, glow, effect)
	return { Key = key, Name = name, Rarity = rarity, Price = price, Body = body, Trim = trim, Dark = dark, Bit = bit, Glow = glow, Accent = glow, Effect = effect }
end
local col = Color3.fromRGB
Config.DrillSkins = {
	{ Key = "Classic", Name = "Classic", Rarity = 1, Price = 0 }, -- couleurs d'origine de chaque foreuse
	skin("Bubblegum", "Bubblegum", 2, 25000, col(255, 150, 205), col(255, 236, 246), col(205, 80, 150), col(255, 255, 255), col(255, 170, 225)),
	skin("Mint", "Mint", 2, 60000, col(140, 240, 190), col(240, 255, 248), col(40, 140, 110), col(220, 255, 240), col(150, 255, 215)),
	skin("Midnight", "Midnight", 3, 500000, col(45, 55, 115), col(90, 200, 255), col(22, 24, 52), col(175, 220, 255), col(90, 200, 255)),
	skin("Lava", "Lava", 3, 5e6, col(55, 42, 42), col(255, 125, 40), col(30, 24, 24), col(255, 195, 95), col(255, 115, 30)),
	skin("Toxic", "Toxic", 4, 5e7, col(135, 240, 60), col(150, 65, 205), col(60, 40, 85), col(225, 255, 150), col(175, 255, 80)),
	skin("Frost", "Frost", 4, 5e8, col(205, 236, 255), col(255, 255, 255), col(90, 140, 195), col(232, 250, 255), col(160, 230, 255), "Sparkle"),
	skin("Gold", "Gold", 5, 5e9, col(255, 200, 50), col(255, 245, 190), col(170, 110, 20), col(255, 235, 150), col(255, 222, 90), "Sparkle"),
	skin("Diamond", "Diamond", 6, 5e10, col(135, 240, 255), col(255, 255, 255), col(60, 150, 220), col(232, 255, 255), col(175, 250, 255), "Sparkle"),
	-- skins premium (Robux)
	skin("Galaxy", "Galaxy", 6, 0, col(110, 60, 200), col(255, 140, 230), col(30, 20, 70), col(205, 185, 255), col(255, 140, 240), "Sparkle"),
	skin("Rainbow", "Rainbow", 7, 0, col(255, 90, 90), col(255, 255, 255), col(60, 50, 90), col(255, 255, 255), col(255, 255, 255), "Rainbow"),
	skin("Supernova", "Supernova", 7, 0, col(255, 200, 60), col(255, 90, 180), col(90, 30, 80), col(255, 240, 200), col(255, 140, 60), "Flames"),
}
-- Skins vendus en Robux (passes) : prix indicatif (le vrai prix est lu sur Roblox) et identifiant du passe
Config.DrillSkins[10].Robux, Config.DrillSkins[10].PassId = 149, 2074575666
Config.DrillSkins[11].Robux, Config.DrillSkins[11].PassId = 199, 2075043675
Config.DrillSkins[12].Robux, Config.DrillSkins[12].PassId = 249, 2074203684
Config.DrillSkinArt = {
	Sparkle = "rbxassetid://138922153683020",
	Glow = "rbxassetid://103844906730878",
}
function Config.DrillSkin(key: string?)
	for _, s in ipairs(Config.DrillSkins) do
		if s.Key == key then
			return s
		end
	end
	return Config.DrillSkins[1]
end

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
Config.DrillRange = 32 -- studs entre le joueur et la surface de l'astéroïde
Config.DrillTick = 0.25 -- secondes entre deux coups envoyés au serveur
Config.DrillSlack = 12 -- marge de portée côté serveur (latence + défilement)
-- Sauvetage : si la roche sous le joueur casse ou disparaît, il a ce temps pour se rattraper ;
-- s'il tombe quand même dans le Vide, il est ramené au bout du quai SANS perdre ses œufs
Config.RescueTime = 6

-- Jetpack (côté client) : carburant en secondes de poussée, rechargé au sol. Le vol plané (chute
-- freinée, Saut relâché) ne consomme rien, mais il faut qu'il reste du carburant (7 nov.). Le carburant de chaque niveau est calculé
-- pour atteindre la PORTÉE voulue (Config.Jetpack.Tiers) : au départ on ne dépasse pas l'anneau 1 ;
-- chaque palier de jetpack permet de franchir le vide jusqu'à l'anneau suivant. Tomber = mourir.
-- NIVEAU DU JETPACK -------------------------------------------------------------------
-- On gagne de l'XP de jetpack en restant dans une soufflerie (même AFK) et en volant en mission.
-- XP pour passer du niveau L au niveau L+1 = XPBase × XPGrowth^(L-1).
Config.Jetpack = {
	XPBase = 20,
	XPGrowth = 1.12,
	MaxLevel = 150,
	FlightXP = 1, -- XP par seconde de vol réel (poussée ou plané, hors soufflerie)
	-- Paliers de jetpack : un modèle de plus en plus impressionnant (Assets.Jetpacks.<Model>) et une
	-- jauge de carburant de plus en plus stylée (Hud). Reach = portée d'un vol à ce niveau (studs, d'un
	-- bord à l'autre, en poussant tout le carburant) ; entre deux paliers elle monte petit à petit.
	-- Le vide entre l'anneau k-1 et l'anneau k fait 55 × 1,22^(k-2) studs : le palier k le franchit
	-- avec 15 % de marge (le palier 1 ne quitte pas l'anneau 1).
	Tiers = {
		{ Level = 1, Name = "Rusty Starter", Model = "Jet1", Reach = 44, Color = Color3.fromRGB(205, 130, 80) },
		{ Level = 10, Name = "Scout Booster", Model = "Jet2", Reach = 63, Color = Color3.fromRGB(90, 190, 255) },
		{ Level = 25, Name = "Comet Pack", Model = "Jet3", Reach = 77, Color = Color3.fromRGB(150, 235, 255) },
		{ Level = 45, Name = "Blaze Thruster", Model = "Jet4", Reach = 94, Color = Color3.fromRGB(255, 120, 40) },
		{ Level = 65, Name = "Nebula Wings", Model = "Jet5", Reach = 115, Color = Color3.fromRGB(190, 100, 255) },
		{ Level = 90, Name = "Rift Striker", Model = "Jet6", Reach = 140, Color = Color3.fromRGB(60, 240, 230) },
		{ Level = 115, Name = "Nova Titan", Model = "Jet7", Reach = 171, Color = Color3.fromRGB(255, 200, 60) },
		{ Level = 140, Name = "Supernova X", Model = "Jet8", Reach = 200, Color = Color3.fromRGB(255, 120, 220) },
	},
	MaxReach = 215, -- portée au niveau 150
	-- Soufflerie personnelle : chaque joueur a la sienne devant sa base. On l'achète (Breeze Tunnel),
	-- puis on l'améliore palier par palier ; XP gagnée par seconde dans le courant d'air, même AFK.
	-- Prix calés sur les revenus (entre les prix des anneaux).
	TunnelRadius = 4.5,
	TunnelHeight = 20,
	TunnelOffset = Vector3.new(12, 0, 26), -- position dans le repère du sol de la base (devant l'entrée, sur le côté ; bases de 36 studs)
	Tunnels = {
		{ Name = "Breeze Tunnel", Cost = 1000, XP = 2, Color = Color3.fromRGB(150, 235, 255) },
		{ Name = "Gale Tunnel", Cost = 30000, XP = 8, Color = Color3.fromRGB(90, 200, 255) },
		{ Name = "Storm Tunnel", Cost = 1.5e6, XP = 30, Color = Color3.fromRGB(255, 140, 60) },
		{ Name = "Cyclone Tunnel", Cost = 8e7, XP = 150, Color = Color3.fromRGB(190, 120, 255) },
		{ Name = "Hurricane Tunnel", Cost = 4e9, XP = 800, Color = Color3.fromRGB(255, 80, 120) },
		{ Name = "Tempest Tunnel", Cost = 2.2e11, XP = 5000, Color = Color3.fromRGB(60, 255, 220) },
		{ Name = "Supernova Vortex", Cost = 1.1e13, XP = 30000, Color = Color3.fromRGB(255, 220, 80) },
	},
}

-- XP pour passer au niveau suivant
function Config.JetpackXPNeed(level: number): number
	local j = Config.Jetpack
	return math.floor(j.XPBase * j.XPGrowth ^ (level - 1) + 0.5)
end

-- Niveau atteint avec cette XP totale, XP déjà faite dans ce niveau, XP du niveau
function Config.JetpackLevel(totalXP: number): (number, number, number)
	local level, rest = 1, totalXP
	while level < Config.Jetpack.MaxLevel do
		local need = Config.JetpackXPNeed(level)
		if rest < need then
			return level, rest, need
		end
		rest -= need
		level += 1
	end
	return level, 0, 0
end
Config.JetpackRefill = 2.5 -- secondes de carburant regagnées par seconde au sol

-- Statistiques dérivées des niveaux
-- Foreuse tenue par le personnage (modèles : ReplicatedStorage.Assets.Drills.DrillN)
-- Carry = position du guidon par rapport au torse quand on ne fore pas (sur le dos, en biais)
Config.DrillHold = {
	Scale = 0.85,
	-- Au repos, la foreuse est accrochée sur le côté (le jetpack occupe le dos)
	Carry = CFrame.new(1.35, -0.55, 0.45) * CFrame.Angles(math.rad(-10), 0, math.rad(-12)),
}

function Config.DrillPower(tier: number): number
	local d = Config.Drills[math.clamp(tier, 1, #Config.Drills)]
	return d.Power
end

-- Un seul œuf par voyage : on fore un œuf, on le ramène à sa base, on repart (pas d'amélioration de soute)
Config.CargoMax = 1
function Config.CargoSlots(_level: number?): number
	return Config.CargoMax
end

-- Multiplicateur de vitesse selon le niveau du jetpack (niveau 1 = ×1), et vitesses qui en découlent
function Config.Speed(level: number): number
	return 1 + Config.Movement.PerLevel * math.max(0, (level or 1) - 1)
end
function Config.GroundSpeed(level: number): number
	return Config.Movement.Walk * Config.Speed(level)
end
function Config.AirSpeed(level: number): number
	return Config.Movement.Air + Config.Movement.AirPerLevel * math.max(0, (level or 1) - 1)
end

-- Palier de jetpack d'un niveau (index dans Config.Jetpack.Tiers, et le palier)
function Config.JetpackTier(level: number)
	local tiers = Config.Jetpack.Tiers
	local index = 1
	for i, t in ipairs(tiers) do
		if (level or 1) >= t.Level then
			index = i
		end
	end
	return index, tiers[index]
end

-- Portée d'un vol à ce niveau : elle monte en ligne droite d'un palier à l'autre
function Config.JetpackReach(level: number): number
	local tiers = Config.Jetpack.Tiers
	local i, t = Config.JetpackTier(level)
	local nextLevel = if tiers[i + 1] then tiers[i + 1].Level else Config.Jetpack.MaxLevel
	local nextReach = if tiers[i + 1] then tiers[i + 1].Reach else Config.Jetpack.MaxReach
	local k = math.clamp(((level or 1) - t.Level) / math.max(1, nextLevel - t.Level), 0, 1)
	return t.Reach + (nextReach - t.Reach) * k
end

-- Carburant (secondes de poussée) qui donne cette portée : on monte à Climb studs/s pendant F s
-- en avançant à la vitesse de vol, puis on retombe à la hauteur de départ. Temps en l'air :
-- T(F) = F + c/g + sqrt(2(cF + c²/2g)/g) ; on cherche F tel que vitesse × T(F) = portée.
function Config.JetpackFuel(level: number): number
	local mv = Config.Movement
	local c, g = mv.Climb, mv.Gravity
	local want = Config.JetpackReach(level) / Config.AirSpeed(level)
	local function airtime(f: number): number
		return f + c / g + math.sqrt(2 * (c * f + c * c / (2 * g)) / g)
	end
	local lo, hi = 0, 20
	for _ = 1, 30 do
		local mid = (lo + hi) / 2
		if airtime(mid) < want then
			lo = mid
		else
			hi = mid
		end
	end
	return math.max(0.3, (lo + hi) / 2)
end

function Config.Luck(level: number): number
	return 1 + 0.05 * level
end

function Config.UpgradeCost(id: string, level: number): number
	local u = Config.Upgrades[id]
	return math.floor(u.Base * u.Growth ^ level + 0.5)
end

-- BIOMES : chaque anneau a sa lumière, sa brume, sa teinte et ses particules ---------
-- Appliqués par Biomes.client quand le joueur entre dans l'anneau (le vaisseau garde
-- l'éclairage réglé dans Studio). Particules : 3 couches par biome, autour du joueur.
-- Texture : Glow, Sparkle, Snow, Shard, Shell (voir Biomes.client).
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
-- Couche de particules : texture, couleurs, taille (début, fin), nombre par seconde,
-- durée de vie, vitesse, accélération (dérive), transparence (début, fin), lueur, rotation
local function layer(texture, c1, c2, size, rate, life, speed, drift, transparency, light, spin)
	return {
		Texture = texture,
		Colors = { c1, c2 },
		Size = size,
		Rate = rate,
		Life = life,
		Speed = speed,
		Drift = drift,
		Transparency = transparency,
		Light = light,
		Spin = spin or 0,
	}
end
Config.BiomeFade = 2 -- secondes de transition entre deux biomes
-- Brouillard : on ne voit que son biome et la moitié du suivant (depuis la base : l'anneau 1
-- et la moitié de l'anneau 2). La suite se devine dans la brume et donne envie d'avancer.
Config.Fog = {
	ShipColor = rgb(34, 24, 52), -- sur le vaisseau
	ShipEnd = 300, -- studs : depuis le pont, la moitié de l'anneau 2
	MinEnd = 260,
	Margin = 80, -- au-delà du milieu de l'anneau suivant
	StartRatio = 0.45, -- le brouillard commence à 45 % de sa distance de fin
}
-- Fondu des objets lointains (FarFade.client, Belt.client) : au-delà de la fin du brouillard, un
-- objet prend la couleur du brouillard et fait une silhouette sombre devant le ciel clair (planète,
-- nébuleuses). Il devient transparent entre Start et Finish × FogEnd (distance à la caméra).
Config.FarFade = {
	Start = 0.72,
	Finish = 0.97,
}

-- SONS (Sfx.lua, Audio.client) : sons gratuits du Creator Store (APM Music, Pro Sound Effects,
-- Daily Sounds). Pour en changer un, remplacer son Id ; Volume et Pitch règlent le niveau et la hauteur.
Config.Sounds = {
	MusicVolume = 0.3,
	MusicFade = 1.6, -- secondes de fondu entre deux musiques
	Music = {
		Base = 1842185080, -- vaisseau et bases : « Explore », aventure électro pour enfants
		Belt = 1840200807, -- anneaux et couloir : « Futureworld », science-fiction
		Chase = 100817604765534, -- poursuite par un monstre : « Dangerous Pursuit »
	},
	-- Sons joués à une position : on les entend jusqu'à cette distance (studs)
	Range = 160,
	-- Volumes réglés sur une mesure (AudioAnalyzer, Studio, 7 nov.) : niveau efficace visé
	-- ~0,15 pour les sons importants, ~0,09 pour l'interface. Un son très faible au départ
	-- (enregistrement pro) a donc un volume au-dessus de 1.
	Sfx = {
		Click = { Id = 106984966606682, Volume = 0.5, Pitch = 1.3 },
		Open = { Id = 80984744279155, Volume = 0.35 },
		Error = { Id = 91501650514390, Volume = 0.25 },
		Coin = { Id = 130378474223829, Volume = 0.35 },
		Buy = { Id = 90531793028786, Volume = 1.2 },
		Pop = { Id = 106984966606682, Volume = 0.9 },
		-- foreuse du joueur et astéroïdes
		RockHit = { Id = 9118588165, Volume = 1.1 },
		RockBreak = { Id = 9118612665, Volume = 0.8 }, -- gros impact croquant
		RockCrumble = { Id = 103615926684206, Volume = 0.35 }, -- éboulis par-dessus
		-- machine à dérocher
		Clamp = { Id = 9116888605, Volume = 0.3 }, -- les pinces se ferment
		Crack = { Id = 9113959343, Volume = 2 }, -- la roche se fend pendant le forage
		Riser = { Id = 94077390731779, Volume = 0.45 }, -- montée avant l'éclatement
		EggFly = { Id = 80984744279155, Volume = 0.5 },
		-- éclosion et récompenses
		Hatch = { Id = 9043151109, Volume = 0.5 }, -- commune à rare
		HatchRare = { Id = 9038916885, Volume = 0.6 }, -- épique et au-delà
		LevelUp = { Id = 1839881844, Volume = 0.45 },
		Reward = { Id = 9038916885, Volume = 0.6 },
		-- jetpack
		JetStart = { Id = 104612149748953, Volume = 0.3 }, -- allumage
		JetStop = { Id = 87598090301048, Volume = 0.12 }, -- extinction
		-- gel et événements
		Warning = { Id = 80890994815283, Volume = 0.3 },
		Freeze = { Id = 9125611419, Volume = 0.6 },
		Thaw = { Id = 96795857757261, Volume = 0.3, Pitch = 1.4 },
		-- monstres
		MonsterRoar = { Id = 9113980319, Volume = 1.8 }, -- réveil
		MonsterWarn = { Id = 9118805486, Volume = 1.5 }, -- trop de bruit : il remue
		MonsterCatch = { Id = 9118612665, Volume = 1, Pitch = 0.7 }, -- il t'attrape
		Escape = { Id = 1839881844, Volume = 0.45 }, -- il abandonne
	},
	-- Boucles (volume au maximum de l'effet). Region = partie régulière d'un long enregistrement,
	-- jouée en boucle (secondes).
	Loops = {
		JetBody = { Id = 87588244098894, Volume = 0.17, Soft = true }, -- souffle grave du réacteur (discret, aigus adoucis)
		JetFlame = { Id = 90423293726333, Volume = 0.08, Soft = true }, -- flamme du brûleur, juste en fond
		DrillMotor = { Id = 199754867, Volume = 0.27 },
		DrillGrind = { Id = 9125450647, Volume = 0.95, Region = { 20, 100 } }, -- grosse foreuse dans la pierre
		MachineGrind = { Id = 9125450647, Volume = 1.8, Region = { 20, 100 } },
		MachineMotor = { Id = 199754867, Volume = 0.4, Pitch = 0.8 },
		Tunnel = { Id = 9119462099, Volume = 2.5 },
		Void = { Id = 6544555787, Volume = 0.2 }, -- vent glacé hors du couloir
		Heart = { Id = 132163421525060, Volume = 0.4 }, -- battements quand le gel approche
		MonsterGrowl = { Id = 9113985466, Volume = 0.5, Region = { 2, 36 } }, -- grondement du monstre (placé sur lui)
	},
	RareFrom = 4, -- rareté à partir de laquelle l'éclosion joue la fanfare
}
-- Rideaux de brume dans les vides entre deux anneaux (WorldBuilder)
Config.FogCurtains = {
	PerGap = 16,
	Gather = 1.5, -- resserrés autour du couloir
	Arc = 450, -- studs d'arc de chaque côté du couloir
	Size = { 50, 75 },
	Transparency = 0.78,
	Rate = 0.8,
	Life = { 10, 14 },
}

-- Distance de fin du brouillard quand on est dans l'anneau « zone » (0 = vaisseau)
function Config.FogEnd(zone: number): number
	local f = Config.Fog
	if zone <= 0 then
		return f.ShipEnd
	end
	local n = #Config.Rings
	local nextHalf = if zone < n then Config.RingGapAfter(zone) + Config.RingWidth(zone + 1) / 2 else Config.RingWidth(zone) / 2
	return math.max(f.MinEnd, Config.RingWidth(zone) / 2 + nextHalf + f.Margin)
end
-- Nuages colorés posés dans le champ de chaque anneau : ils donnent sa couleur au biome
-- sans voiler le ciel (une brume globale peindrait tout le bas du ciel d'une couleur unie)
Config.BiomeClouds = {
	Texture = "rbxassetid://103844906730878", -- halo doux (même image que UIKit.Art.FxGlow)
	PerRing = 20, -- émetteurs de nuages par anneau, plus serrés autour du couloir
	Gather = 1.4, -- > 1 : les nuages se resserrent vers le couloir (là où joue le joueur)
	Size = { 30, 46 }, -- taille des nuages (studs), × la largeur relative de l'anneau
	Transparency = 0.9, -- très légers : on voit à travers
	Rate = 0.7,
	Life = { 10, 14 },
}
Config.Biomes = {
	{ -- 1. Dust Belt : poussière dorée
		Title = "DUST BELT",
		Icon = "Sparkles",
		Fog = rgb(60, 42, 30), -- couleur du brouillard lointain
		Clouds = { rgb(230, 170, 110), rgb(200, 130, 80) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(255, 230, 195),
		Saturation = 0.15,
		Outdoor = rgb(190, 165, 130),
		Particles = {
			layer("Glow", rgb(255, 220, 140), rgb(255, 190, 110), { 0.35, 0.15 }, 70, { 6, 9 }, { 0.5, 1.5 }, Vector3.new(0.3, 0.2, 0), { 0.2, 1 }, 1),
			layer("Glow", rgb(255, 210, 150), rgb(255, 170, 90), { 4, 6 }, 5, { 6, 9 }, { 0.2, 0.6 }, Vector3.zero, { 0.86, 1 }, 0.6),
			layer("Sparkle", rgb(255, 245, 190), rgb(255, 220, 120), { 0.7, 0 }, 12, { 0.8, 1.4 }, { 0, 0.3 }, Vector3.zero, { 0, 1 }, 1, 90),
		},
	},
	{ -- 2. Ice Ring : neige bleutée
		Title = "ICE RING",
		Icon = "Snowflake",
		Fog = rgb(30, 42, 66), -- couleur du brouillard lointain
		Clouds = { rgb(170, 205, 245), rgb(120, 165, 230) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(212, 232, 255),
		Saturation = 0.1,
		Outdoor = rgb(160, 185, 220),
		Particles = {
			layer("Snow", rgb(255, 255, 255), rgb(210, 235, 255), { 0.6, 0.45 }, 55, { 7, 10 }, { 0.3, 1 }, Vector3.new(0.4, -1.2, 0), { 0.1, 1 }, 0.4, 45),
			layer("Sparkle", rgb(200, 245, 255), rgb(150, 220, 255), { 0.6, 0 }, 16, { 0.7, 1.2 }, { 0, 0.2 }, Vector3.zero, { 0, 1 }, 1, 120),
			layer("Glow", rgb(170, 220, 255), rgb(120, 180, 255), { 5, 7 }, 4, { 6, 9 }, { 0.2, 0.5 }, Vector3.zero, { 0.88, 1 }, 0.7),
		},
	},
	{ -- 3. Magma Field : braises qui montent et fumée rouge
		Title = "MAGMA FIELD",
		Icon = "Fire",
		Fog = rgb(58, 22, 20), -- couleur du brouillard lointain
		Clouds = { rgb(200, 90, 60), rgb(90, 40, 40) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(255, 212, 190),
		Saturation = 0.2,
		Outdoor = rgb(200, 130, 100),
		Particles = {
			layer("Glow", rgb(255, 200, 80), rgb(255, 80, 30), { 0.4, 0.1 }, 80, { 3, 5 }, { 0.5, 2 }, Vector3.new(0, 3, 0), { 0, 1 }, 1),
			layer("Glow", rgb(90, 40, 40), rgb(50, 25, 25), { 6, 10 }, 6, { 6, 9 }, { 0.3, 0.8 }, Vector3.new(0, 0.8, 0), { 0.8, 1 }, 0),
			layer("Sparkle", rgb(255, 240, 150), rgb(255, 150, 60), { 0.5, 0 }, 14, { 0.4, 0.8 }, { 1, 3 }, Vector3.new(0, 4, 0), { 0, 1 }, 1, 180),
		},
	},
	{ -- 4. Nebula : nuages roses et étincelles
		Title = "NEBULA",
		Icon = "Galaxy",
		Fog = rgb(52, 28, 70), -- couleur du brouillard lointain
		Clouds = { rgb(255, 140, 220), rgb(160, 110, 255) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(248, 220, 255),
		Saturation = 0.3,
		Outdoor = rgb(190, 150, 220),
		Particles = {
			layer("Sparkle", rgb(255, 190, 250), rgb(190, 150, 255), { 0.8, 0 }, 30, { 0.8, 1.6 }, { 0, 0.4 }, Vector3.zero, { 0, 1 }, 1, 90),
			layer("Glow", rgb(255, 140, 220), rgb(150, 110, 255), { 9, 14 }, 4, { 7, 10 }, { 0.2, 0.5 }, Vector3.zero, { 0.88, 1 }, 0.8),
			layer("Glow", rgb(255, 255, 255), rgb(220, 200, 255), { 0.2, 0.2 }, 50, { 6, 9 }, { 0.1, 0.4 }, Vector3.zero, { 0.1, 1 }, 1),
		},
	},
	{ -- 5. Devourer Belt : brume verte sombre et spores
		Title = "DEVOURER BELT",
		Icon = "Eye",
		Fog = rgb(16, 30, 22), -- couleur du brouillard lointain
		Clouds = { rgb(90, 160, 100), rgb(30, 60, 40) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(205, 235, 208),
		Saturation = -0.05,
		Brightness = -0.04,
		Outdoor = rgb(110, 140, 115),
		Particles = {
			layer("Glow", rgb(150, 255, 120), rgb(60, 200, 90), { 0.35, 0.2 }, 45, { 6, 9 }, { 0.2, 0.8 }, Vector3.new(0, 0.6, 0), { 0.1, 1 }, 1),
			layer("Glow", rgb(40, 30, 50), rgb(20, 20, 30), { 1.2, 0.8 }, 30, { 6, 9 }, { 0.3, 1 }, Vector3.new(0, -0.3, 0), { 0.4, 1 }, 0),
			layer("Glow", rgb(90, 255, 150), rgb(30, 120, 60), { 8, 12 }, 3, { 5, 8 }, { 0.1, 0.3 }, Vector3.zero, { 0.88, 1 }, 0.9),
		},
	},
	{ -- 6. The Rift : éclats cyan et magenta qui clignotent
		Title = "THE RIFT",
		Icon = "Rift",
		Fog = rgb(24, 28, 62), -- couleur du brouillard lointain
		Clouds = { rgb(120, 220, 255), rgb(220, 90, 255) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(222, 232, 255),
		Saturation = 0.2,
		Outdoor = rgb(150, 160, 210),
		Particles = {
			layer("Shard", rgb(80, 240, 255), rgb(80, 240, 255), { 0.5, 0.5 }, 35, { 0.4, 1.2 }, { 0, 0.5 }, Vector3.zero, { 0, 1 }, 1),
			layer("Shard", rgb(255, 80, 230), rgb(255, 80, 230), { 0.35, 0.35 }, 30, { 0.4, 1.2 }, { 0, 0.5 }, Vector3.zero, { 0, 1 }, 1),
			layer("Glow", rgb(170, 120, 255), rgb(80, 200, 255), { 8, 12 }, 4, { 6, 9 }, { 0.1, 0.4 }, Vector3.zero, { 0.88, 1 }, 0.8),
		},
	},
	{ -- 7. The Nest : pollen ambré et coquilles d'œufs qui flottent
		Title = "THE NEST",
		Icon = "Egg",
		Fog = rgb(62, 44, 22), -- couleur du brouillard lointain
		Clouds = { rgb(255, 220, 150), rgb(255, 180, 90) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(255, 232, 195),
		Saturation = 0.2,
		Outdoor = rgb(200, 175, 130),
		Particles = {
			layer("Glow", rgb(255, 230, 130), rgb(255, 200, 90), { 0.3, 0.2 }, 60, { 6, 9 }, { 0.2, 0.8 }, Vector3.new(0.2, 0.3, 0), { 0.1, 1 }, 1),
			layer("Shell", rgb(255, 248, 230), rgb(250, 225, 180), { 0.9, 0.8 }, 10, { 7, 10 }, { 0.3, 0.8 }, Vector3.new(0, -0.4, 0), { 0, 1 }, 0.2, 60),
			layer("Glow", rgb(255, 200, 120), rgb(255, 160, 80), { 7, 10 }, 4, { 6, 9 }, { 0.1, 0.4 }, Vector3.zero, { 0.88, 1 }, 0.8),
		},
	},
}

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
		creature("Pebblepup", "a round grey rock puppy with pebble spots", { 0.8, 1.3 }, { 2, 6 }, "rbxassetid://86395310676998"),
		creature("Dust Bunny", "a fluffy beige space-dust bunny with tiny stars in its fur", { 0.8, 1.3 }, { 1, 4 }, "rbxassetid://90899078636377"),
		creature("Craterhog", "a hedgehog whose quills are purple amethyst crystals", { 0.8, 1.4 }, { 3, 8 }, "rbxassetid://89984459531543"),
		creature("Orbitoad", "a chubby blue toad with two tiny moons orbiting its head", { 0.8, 1.4 }, { 4, 10 }, "rbxassetid://89683269715201"),
		creature("Meteor Fox", "an orange fox with a flaming meteor tail", { 0.9, 1.5 }, { 6, 14 }, "rbxassetid://89979866412184"),
		creature("Stardust Dragon", "a small sparkly pink and gold dragon made of stardust", { 0.9, 1.6 }, { 10, 25 }, "rbxassetid://92929737667019"),
	},
	{ -- 2. Ice Ring
		creature("Frostling", "a baby penguin with an ice crystal crown", { 0.8, 1.3 }, { 3, 7 }, "rbxassetid://119458919933613"),
		creature("Snow Moth", "a fluffy white moth with snowflake wings", { 0.8, 1.3 }, { 1, 3 }, "rbxassetid://80885563517564"),
		creature("Glacier Otter", "a light blue otter holding an ice shard", { 0.8, 1.4 }, { 5, 11 }, "rbxassetid://98026570861784"),
		creature("Comet Seal", "a white seal with a glowing comet trail", { 0.9, 1.4 }, { 15, 40 }, "rbxassetid://127471856481707"),
		creature("Aurora Owl", "an owl with green and violet aurora feathers", { 0.9, 1.5 }, { 3, 8 }, "rbxassetid://98346699659181"),
		creature("Crystal Yeti", "a cute yeti covered in blue ice crystals", { 1, 1.7 }, { 60, 150 }, "rbxassetid://84958810890834"),
	},
	{ -- 3. Magma Field
		creature("Cinder Slug", "a little dark slug with glowing lava spots", { 0.8, 1.3 }, { 1, 4 }, "rbxassetid://137432198493660"),
		creature("Lava Crab", "a red crab with a volcano-shaped shell", { 0.8, 1.4 }, { 3, 9 }, "rbxassetid://97029354226380"),
		creature("Blaze Newt", "an orange salamander with flame frills", { 0.8, 1.4 }, { 2, 6 }, "rbxassetid://80609534802068"),
		creature("Obsidian Rhino", "a baby rhino of black obsidian with a fiery horn", { 0.9, 1.5 }, { 80, 200 }, "rbxassetid://73273327531441"),
		creature("Solar Phoenix", "a majestic golden phoenix with glowing sun-flare wings", { 0.9, 1.5 }, { 4, 10 }, "rbxassetid://82841561173402"),
		creature("Magma Wyrm", "a fearsome wingless lava dragon with black lava armor and glowing magma cracks", { 1, 1.7 }, { 50, 140 }, "rbxassetid://131852410257990"),
	},
	{ -- 4. Nebula
		creature("Nebula Jelly", "a pink and violet floating jellyfish full of stars", { 0.8, 1.3 }, { 1, 3 }, "rbxassetid://128537417532942"),
		creature("Haze Kitten", "a misty lavender kitten with a cloud tail", { 0.8, 1.3 }, { 2, 5 }, "rbxassetid://125257233921134"),
		creature("Dreamfin", "a small sky-blue whale swimming in nebula clouds", { 0.9, 1.4 }, { 20, 60 }, "rbxassetid://94828445655287"),
		creature("Prism Ray", "a manta ray with rainbow prism wings", { 0.9, 1.5 }, { 10, 30 }, "rbxassetid://91824384772647"),
		creature("Nova Lion", "a lion cub with a mane of glowing star light", { 0.9, 1.5 }, { 20, 50 }, "rbxassetid://98014549695838"),
		creature("Galaxy Unicorn", "a unicorn with a swirling galaxy mane and horn", { 1, 1.7 }, { 40, 110 }, "rbxassetid://89943286874690"),
	},
	{ -- 5. Devourer Belt
		creature("Fang Beetle", "a dark green beetle with big friendly fangs", { 0.8, 1.3 }, { 1, 4 }, "rbxassetid://97386395229147"),
		creature("Gloom Bat", "a round purple bat with glowing yellow eyes", { 0.8, 1.4 }, { 1, 3 }, "rbxassetid://116778639781229"),
		creature("Void Shark", "a small black shark with a starry belly", { 0.9, 1.5 }, { 30, 90 }, "rbxassetid://136239190831225"),
		creature("Hunger Hound", "a shadowy hound with a glowing teal collar", { 0.9, 1.5 }, { 20, 55 }, "rbxassetid://130664205072983"),
		creature("Abyss Serpent", "a coiled deep-purple serpent with glowing runes", { 1, 1.6 }, { 30, 80 }, "rbxassetid://87131592880787"),
		creature("Eclipse Devourer", "a colossal kaiju with an eclipse halo and a glowing cosmic maw", { 1, 1.8 }, { 120, 300 }, "rbxassetid://132746913273755"),
	},
	{ -- 6. The Rift
		creature("Chrono Snail", "a snail with a clock-spiral shell", { 0.8, 1.3 }, { 1, 3 }, "rbxassetid://134972365597902"),
		creature("Glitch Cat", "a cat with pixel glitch stripes in cyan and magenta", { 0.8, 1.4 }, { 3, 7 }, "rbxassetid://118989827735487"),
		creature("Paradox Panda", "a panda with swapped black and white patches and a time swirl", { 0.9, 1.5 }, { 40, 100 }, "rbxassetid://126390512305710"),
		creature("Hourglass Tortoise", "a tortoise carrying a golden hourglass shell", { 0.9, 1.5 }, { 30, 90 }, "rbxassetid://78958273430820"),
		creature("Rift Griffin", "a griffin with wings torn into glowing space rifts", { 1, 1.6 }, { 60, 150 }, "rbxassetid://81332160224286"),
		creature("Quasar Kraken", "a colossal kraken with a quasar shining in its forehead", { 1, 1.8 }, { 100, 260 }, "rbxassetid://107814205120704"),
	},
	{ -- 7. The Nest
		creature("Hatchling", "a tiny chick still wearing half of its cosmic egg shell", { 0.8, 1.3 }, { 1, 3 }, "rbxassetid://117608240919513"),
		creature("Yolk Slime", "a golden yolk slime with a happy face", { 0.8, 1.4 }, { 2, 6 }, "rbxassetid://81322098015607"),
		creature("Brood Raptor", "a baby raptor with amber egg-shell armor", { 0.9, 1.5 }, { 15, 40 }, "rbxassetid://89244382676013"),
		creature("Nest Drake", "a drake that carries a nest of glowing eggs on its back", { 1, 1.6 }, { 50, 130 }, "rbxassetid://96247134569670"),
		creature("Hive Queen", "a regal space bee queen with a crystal crown", { 1, 1.6 }, { 10, 30 }, "rbxassetid://138833453961916"),
		creature("Cosmic Mother", "the cosmic mother of all eggs, a colossal galaxy dragon queen with a crystal crown", { 1.1, 1.9 }, { 200, 500 }, "rbxassetid://97121495935864"),
	},
}

-- Rareté de la n-ième espèce d'un anneau (fenêtre glissante)
function Config.CreatureRarity(ring: number, slot: number): number
	return if ring >= Config.CosmicMinRing then slot + 1 else slot
end

-- Récompense quand on a trouvé les 6 espèces d'un anneau : chance permanente et $
Config.IndexReward = {
	Luck = 0.1, -- +10 % de chance par anneau complété (cumulable)
	Money = 2500, -- × revenu de base de l'anneau (Config.Hatch.RingIncome) : 12,5 K$ (anneau 1) à 25 000 Md$ (anneau 7)
	-- chaque NOUVELLE espèce (HatchService) : NewSeconds secondes de ses revenus, au moins NewMin $
	NewSeconds = 60,
	NewMin = 250,
}

-- BOUTIQUE (docs/Interfaces.md §9) ---------------------------------------------
-- Id = identifiant du passe ou du produit Robux sur Roblox : 0 tant qu'il n'est pas créé
-- (le bouton affiche alors « Coming soon! »). Price = prix affiché en Robux.
-- Jamais d'œufs ni de créatures contre des Robux.
Config.Shop = {
	-- Starter Pack : offre de bienvenue, visible pendant Duration secondes après la première partie,
	-- achetable une seule fois (guide Roblox « Starter pack design »). Le prix est lu sur Roblox.
	Featured = {
		Name = "Starter Pack",
		Text = "Big money pack + x2 Luck + x2 Money potions",
		Art = "Money4",
		PackBase = 45000, -- comme le 3e paquet d'argent
		Id = 3729245985,
		Price = 99,
		Duration = 3 * 86400,
	},
	-- Passes (achat définitif). Effets appliqués par BoostService.
	Passes = {
		{ Key = "JetXP2x", Name = "x2 Jetpack XP", Text = "Train your jetpack twice as fast", Art = "PassTraining2x", Id = 2075661369, Price = 149 },
		{ Key = "TurboJetpack", Name = "Turbo Jetpack", Text = "+25% jetpack fuel", Art = "PassTurboJetpack", Id = 2075607386, Price = 99 },
		{ Key = "FastHatch", Name = "Fast Hatch", Text = "Eggs hatch 2x faster", Art = "PassAutoCrack", Id = 2076051409, Price = 199 },
		{ Key = "Money2x", Name = "x2 Money", Text = "Creatures earn double, forever", Art = "PassMoney2x", Id = 2074467451, Price = 299 },
		{ Key = "BaseSlots", Name = "+5 Base Slots", Text = "Room for 5 more eggs and creatures", Art = "PassPetSlot", Id = 2074281420, Price = 249 },
		{ Key = "VIP", Name = "VIP", Text = "VIP chat tag, +10% money", Art = "PassVIP", Id = 2074857407, Price = 399 },
	},
	PassEffects = {
		JetXP2x = 2, -- × XP de jetpack
		TurboJetpack = 1.25, -- × carburant (pas plus : au niveau 1 on reste sous les 55 studs du premier vide)
		FastHatch = 0.5, -- × temps d'éclosion
		Money2x = 2, -- × revenus des créatures
		BaseSlots = 5, -- emplacements en plus dans la base
		VIP = 1.1, -- × revenus
	},
	-- Potions de 15 minutes (produits Robux), cumulables dans le temps
	PotionMinutes = 15,
	Potions = {
		{ Key = "Luck", Name = "x2 Luck", Art = "PotionLuck", Id = 3729245893, Price = 39 },
		{ Key = "Money", Name = "x2 Money", Art = "PotionMoney", Id = 3729245927, Price = 39 },
		{ Key = "JetXP", Name = "x2 Jetpack XP", Art = "PotionSuit", Id = 3729245953, Price = 25 },
	},
	-- Boost gratuit contre une pub récompensée
	FreeBoost = { Name = "Free x2 Boost", Minutes = 5, Art = "FreeBoost" },
	-- Paquets d'argent : montant = Base × Config.Hatch.RingIncome de l'anneau le plus loin débloqué
	-- (environ 4 min à 35 min de revenus), pour qu'un paquet reste intéressant à toutes les étapes du jeu
	MoneyPacks = {
		{ Art = "Money1", Base = 6000, Id = 3729246128, Price = 19 },
		{ Art = "Money2", Base = 20000, Id = 3729246160, Price = 49 },
		{ Art = "Money3", Base = 45000, Id = 3729246196, Price = 99 },
		{ Art = "Money4", Base = 120000, Id = 3729246217, Price = 249 },
		{ Art = "Money5", Base = 260000, Id = 3729246247, Price = 499 },
	},
}

function Config.MoneyPackAmount(base: number, ring: number): number
	local incomes = Config.Hatch.RingIncome
	return base * incomes[math.clamp(ring, 1, #incomes)]
end

-- ŒUFS ------------------------------------------------------------------------
-- Chaque anneau a 6 œufs, indexés par rareté (anneaux 1-4 : Common -> Mythic ; anneaux 5-7 :
-- Uncommon -> Cosmic). Modèles : ReplicatedStorage.Assets.Eggs.R<anneau>_T<rareté>.
-- Chance = probabilité de tirer cet œuf à chaque œuf foré (total 1 par anneau).
-- Le hasard décide beaucoup : l'œuf le plus rare d'un anneau sort environ 1 fois sur 500 à 1 000.
-- Le scanner multiplie les chances à partir de Config.LuckFrom ; l'œuf le plus courant prend le reste.
local function egg(name: string, chance: number)
	return { Name = name, Chance = chance }
end
Config.Eggs = {
	{ -- 1. Dust Belt
		[1] = egg("Dusty", 0.60), --          1 sur 1,7
		[2] = egg("Pebble", 0.26), --         1 sur 4
		[3] = egg("Geode", 0.10), --          1 sur 10
		[4] = egg("Sandstorm", 0.033), --     1 sur 30
		[5] = egg("Desert King", 0.006), --   1 sur 167
		[6] = egg("Stardust", 0.001), --      1 sur 1 000
	},
	{ -- 2. Ice Ring
		[1] = egg("Frost", 0.58),
		[2] = egg("Snowball", 0.27),
		[3] = egg("Glacier", 0.105),
		[4] = egg("Blizzard", 0.036),
		[5] = egg("Frost King", 0.0075), --   1 sur 133
		[6] = egg("Aurora", 0.0015), --       1 sur 667
	},
	{ -- 3. Magma Field
		[1] = egg("Ember", 0.56),
		[2] = egg("Cinder", 0.28),
		[3] = egg("Magma", 0.11),
		[4] = egg("Inferno", 0.04),
		[5] = egg("Phoenix", 0.0082), --      1 sur 122
		[6] = egg("Dragonheart", 0.0018), --  1 sur 556
	},
	{ -- 4. Nebula
		[1] = egg("Haze", 0.55),
		[2] = egg("Moon", 0.28),
		[3] = egg("Ringed", 0.115),
		[4] = egg("Nova", 0.044),
		[5] = egg("Galaxy", 0.009), --        1 sur 111
		[6] = egg("Supernova", 0.002), --     1 sur 500
	},
	{ -- 5. Devourer Belt
		[2] = egg("Maw", 0.60),
		[3] = egg("Tentacle", 0.26),
		[4] = egg("Eye", 0.10),
		[5] = egg("Void Fang", 0.033),
		[6] = egg("Abyss", 0.0062), --        1 sur 161
		[7] = egg("Devourer", 0.0008), --     1 sur 1 250
	},
	{ -- 6. The Rift
		[2] = egg("Shard", 0.58),
		[3] = egg("Portal", 0.27),
		[4] = egg("Prism", 0.105),
		[5] = egg("Rift Warden", 0.037),
		[6] = egg("Paradox", 0.007), --       1 sur 143
		[7] = egg("Singularity", 0.001), --   1 sur 1 000
	},
	{ -- 7. The Nest
		[2] = egg("Twig", 0.56),
		[3] = egg("Feather", 0.28),
		[4] = egg("Golden", 0.11),
		[5] = egg("Mother", 0.04),
		[6] = egg("Celestial", 0.0085), --    1 sur 118
		[7] = egg("Cosmic", 0.0015), --       1 sur 667
	},
}

-- Nom affiché d'un œuf (« Desert King Egg »)
function Config.EggName(ringIndex: number, rarity: number): string
	local ring = Config.Eggs[ringIndex]
	local e = ring and ring[rarity]
	return (if e then e.Name else Config.Rarities[rarity].Name) .. " Egg"
end

-- ÉCLOSION (docs/Mecaniques.md §7) ---------------------------------------------
-- Le joueur pose ses œufs dérochés où il veut dans sa base ; ils éclosent au bout d'un temps
-- qui dépend de la rareté (le temps passe aussi hors ligne). La créature née reste dans la base
-- et rapporte des $ chaque seconde, d'autant plus qu'elle est rare et grande.
Config.Hatch = {
	-- Secondes d'incubation par rareté (Common -> Cosmic)
	Time = { 20, 45, 90, 180, 420, 900, 1800 },
	-- Œufs en incubation + créatures posées en même temps dans une base
	Slots = 10,
	-- Hauteur du corps de l'œuf posé (studs) selon la rareté : les rares sont plus gros
	EggHeight = { 2.4, 2.7, 3.0, 3.4, 3.9, 4.5, 5.2 },
	-- Tutoriel : premier œuf en 6 s, chien de taille normale ; œuf Épique en 12 s
	FirstTime = 6,
	FirstSize = 1,
	SecondTime = 12,
	-- Place occupée par un œuf posé puis par sa créature (rayon en studs, selon la rareté) :
	-- deux objets posés ne se touchent pas, et les créatures rares, plus grandes, prennent plus de place
	-- Depuis le 8 nov., seuls les œufs se gênent : les créatures, immenses, peuvent se chevaucher et
	-- dépasser de la base (c'est le genre : petite base, créatures géantes). Rayon ≈ la largeur de l'œuf.
	Footprint = { 1.6, 1.7, 1.8, 2.0, 2.3, 2.6, 3.0 },
	Margin = 2.0, -- marge le long des murs (en plus de la moitié de la place occupée)
	-- Zones interdites autour de la machine et du point d'apparition (rayon en studs)
	KeepOut = { DerockMachine = 8.5, Spawn = 4 },
	-- Revenu d'une créature en $/s = RarityIncome[rareté] × RingIncome[anneau] × taille² (Config.PetSizes :
	-- de ×0,4 pour une Tiny à ×5,8 pour la plus grosse Giant).
	-- De ~5 $/s (Common de l'anneau 1) à ~1 Qa/s = 10^15 (Cosmic de l'anneau 7).
	-- Exemples (taille 1) : anneau 1 = 5 / 15 / 60 / 300 / 2,5K / 30K ; anneau 4 Mythic ≈ 1,3B ;
	-- anneau 7 = 30B (Uncommon), 120B, 600B, 5T, 60T (Mythic), 1Qa (Cosmic).
	RarityIncome = { 1, 3, 12, 60, 500, 6000, 100000 },
	RingIncome = { 5, 178, 6300, 224000, 7.9e6, 2.8e8, 1e10 },
	-- Secondes entre l'appui sur « Hatch » et l'éclatement, selon la rareté : l'œuf se charge (tremble,
	-- brille, se fissure de rayons, s'élève...) de plus en plus longtemps et fort (HatchFx)
	Burst = { 1.6, 2.1, 2.7, 3.4, 4.3, 5.4, 6.8 },
	-- Pendant la charge, l'œuf grossit jusqu'à Grow × la hauteur de la créature à naître (au moins MinGrow ×
	-- sa taille) : plus elle est immense, plus il gonfle
	Grow = 0.85,
	MinGrow = 1.15,
	-- Œuf tenu dans les mains en sortant de la machine : hauteur selon la rareté (studs),
	-- et délai avant qu'il apparaisse (le temps que l'œuf révélé vole jusqu'au joueur)
	HeldHeight = { 1.7, 1.85, 2.0, 2.15, 2.35, 2.55, 2.8 },
	HandDelay = 1.4,
	-- Hauteur d'une créature dans la base (studs) selon la rareté, multipliée par sa taille tirée.
	-- Les rares sont nettement plus grandes (et plus impressionnantes) : la récompense se voit.
	-- (doublées le 8 nov. : 5,2 studs pour une Commune, 30 pour une Cosmique)
	PetHeight = { 5.2, 6.0, 7.4, 9.6, 14.0, 21.0, 30.0 },
	-- Promenade autour de son socle : rayon (studs) et durée d'un aller (secondes)
	WanderRadius = 3,
	-- Au-delà de cette hauteur (studs), une créature se promène moins loin (les géantes piétinent sur place)
	WanderFullHeight = 8,
	WanderPeriod = 6,
	-- Faire éclore tout de suite contre des Robux (du temps, jamais des œufs ni des créatures).
	-- Un produit de développeur par rareté (créés le 7 nov. sur Roblox).
	Skip = {
		{ Price = 9, ProductId = 3729247130 }, -- Common
		{ Price = 15, ProductId = 3729247160 }, -- Uncommon
		{ Price = 25, ProductId = 3729247194 }, -- Rare
		{ Price = 45, ProductId = 3729247244 }, -- Epic
		{ Price = 79, ProductId = 3729247270 }, -- Legendary
		{ Price = 129, ProductId = 3729247308 }, -- Mythic
		{ Price = 199, ProductId = 3729247356 }, -- Cosmic
	},
}

-- MOUVEMENTS DES CRÉATURES (Creatures.client) ----------------------------------------
-- Chaque créature a sa façon de se déplacer (Style) et une figure qu'elle fait de temps en temps (Trick).
-- Styles : trot (quadrupède), hop (bonds), waddle (se dandine), slither (rampe en ondulant),
--   scuttle (trottine vite, Sideways = de côté comme un crabe), stomp (pas lourds), fly (vole),
--   swim (nage dans l'air), float (flotte en pulsant), flop (avance par à-coups comme un phoque).
-- Figures : spin, flip, roar, pounce, charge, sit, pulse, glitch, flame, dive, strike, slide, stomp.
-- Speed : multiplie la vitesse (1 = normal) ; Hover : hauteur de vol en fraction de la taille.
local function motion(style: string, trick: string, speed: number?, extra: { [string]: any }?)
	local m = { Style = style, Trick = trick, Speed = speed or 1 }
	for k, v in pairs(extra or {}) do
		m[k] = v
	end
	return m
end
Config.CreatureMotion = {
	-- 1. Dust Belt
	["Pebblepup"] = motion("trot", "sit", 1.1),
	["Dust Bunny"] = motion("hop", "flip", 1.2),
	["Craterhog"] = motion("scuttle", "spin", 0.9),
	["Orbitoad"] = motion("hop", "stomp", 0.8, { HopHeight = 0.5 }),
	["Meteor Fox"] = motion("trot", "pounce", 1.5),
	["Stardust Dragon"] = motion("fly", "roar", 1.0, { Hover = 0.45 }),
	-- 2. Ice Ring
	["Frostling"] = motion("waddle", "slide", 0.8),
	["Snow Moth"] = motion("fly", "spin", 1.3, { Hover = 0.6, Flutter = true }),
	["Glacier Otter"] = motion("waddle", "spin", 1.0),
	["Comet Seal"] = motion("flop", "roar", 0.8),
	["Aurora Owl"] = motion("fly", "dive", 1.0, { Hover = 0.5 }),
	["Crystal Yeti"] = motion("stomp", "roar", 0.7),
	-- 3. Magma Field
	["Cinder Slug"] = motion("slither", "pulse", 0.5),
	["Lava Crab"] = motion("scuttle", "spin", 1.3, { Sideways = true }),
	["Blaze Newt"] = motion("scuttle", "flame", 1.4),
	["Obsidian Rhino"] = motion("stomp", "charge", 0.8),
	["Solar Phoenix"] = motion("fly", "flame", 1.1, { Hover = 0.55 }),
	["Magma Wyrm"] = motion("stomp", "roar", 0.6),
	-- 4. Nebula
	["Nebula Jelly"] = motion("float", "pulse", 0.6, { Hover = 0.35 }),
	["Haze Kitten"] = motion("trot", "pounce", 1.3),
	["Dreamfin"] = motion("swim", "flip", 0.8, { Hover = 0.4 }),
	["Prism Ray"] = motion("swim", "spin", 1.1, { Hover = 0.5 }),
	["Nova Lion"] = motion("trot", "roar", 1.1),
	["Galaxy Unicorn"] = motion("fly", "roar", 1.0, { Hover = 0.35 }),
	-- 5. Devourer Belt
	["Fang Beetle"] = motion("scuttle", "spin", 1.2),
	["Gloom Bat"] = motion("fly", "flip", 1.4, { Hover = 0.7, Flutter = true }),
	["Void Shark"] = motion("swim", "charge", 1.2, { Hover = 0.35 }),
	["Hunger Hound"] = motion("trot", "roar", 1.4),
	["Abyss Serpent"] = motion("slither", "strike", 0.7),
	["Eclipse Devourer"] = motion("stomp", "roar", 0.6),
	-- 6. The Rift
	["Chrono Snail"] = motion("slither", "glitch", 0.4),
	["Glitch Cat"] = motion("trot", "glitch", 1.3),
	["Paradox Panda"] = motion("stomp", "sit", 0.8),
	["Hourglass Tortoise"] = motion("stomp", "spin", 0.4),
	["Rift Griffin"] = motion("fly", "dive", 1.1, { Hover = 0.4 }),
	["Quasar Kraken"] = motion("float", "pulse", 0.5, { Hover = 0.2 }),
	-- 7. The Nest
	["Hatchling"] = motion("hop", "spin", 1.0, { HopHeight = 0.25 }),
	["Yolk Slime"] = motion("hop", "pulse", 0.8, { HopHeight = 0.3, Squash = 1.8 }),
	["Brood Raptor"] = motion("trot", "roar", 1.6),
	["Nest Drake"] = motion("trot", "roar", 0.9),
	["Hive Queen"] = motion("fly", "spin", 1.0, { Hover = 0.35, Flutter = true }),
	["Cosmic Mother"] = motion("fly", "roar", 0.8, { Hover = 0.35 }),
}

-- Créature qui sort d'un œuf (anneau, rareté) : celle de l'anneau qui a cette rareté
function Config.CreatureFor(ringIndex: number, rarity: number): any
	local list = Config.Creatures[ringIndex]
	local slot = if ringIndex >= Config.CosmicMinRing then rarity - 1 else rarity
	return list and list[math.clamp(slot, 1, #list)]
end

-- Revenu d'une créature en $/s
-- CRÉATURES : sac, vente, fusion (CreatureService, CreaturesUI.client) ------------------------
-- (Config.Creatures est la liste des espèces par anneau ; ici, les règles)
Config.PetRules = {
	InventoryMax = 100, -- places dans le sac
	-- Stades : 3 créatures identiques du même stade fusionnent en une du stade suivant
	Stages = {
		{ Name = "", Mult = 1, Scale = 1 },
		{ Name = "Adult", Mult = 3.5, Scale = 1.25 },
		{ Name = "Elder", Mult = 12, Scale = 1.5 },
	},
	SellSeconds = 300, -- prix de vente = revenu par seconde × 5 min
	ConfirmFrom = 4, -- confirmation avant de vendre à partir d'Épique
	StandRange = 26, -- studs : il faut être près du stand pour vendre ou fusionner
}

-- TAILLES DES CRÉATURES (8 nov.) -----------------------------------------------------------------
-- Une même créature sort de l'œuf plus ou moins grande : la taille (item.size) multiplie sa hauteur
-- et son revenu ×taille² (plus elle est grande, plus elle rapporte, et nettement). Elle a un nom
-- (« Giant Pebblepup ») et une couleur affichés partout. Chance = probabilité à l'éclosion ;
-- Min / Max = taille tirée dans ce palier.
Config.PetSizes = {
	{ Name = "Tiny", Chance = 0.20, Min = 0.65, Max = 0.8, Color = Color3.fromRGB(170, 205, 255) },
	{ Name = "", Chance = 0.50, Min = 0.85, Max = 1.1, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Big", Chance = 0.20, Min = 1.2, Max = 1.45, Color = Color3.fromRGB(120, 245, 80) },
	{ Name = "Huge", Chance = 0.08, Min = 1.55, Max = 1.85, Color = Color3.fromRGB(255, 170, 40) },
	{ Name = "Giant", Chance = 0.02, Min = 2.0, Max = 2.4, Color = Color3.fromRGB(255, 70, 90) },
}
Config.SizeIncomePower = 2

-- Palier d'une taille (la limite entre deux paliers est à mi-chemin ; marche aussi pour les vieilles
-- sauvegardes et les créatures fusionnées, dont la taille est la moyenne des trois)
function Config.PetSize(size: number?): any
	local tiers = Config.PetSizes
	local s = size or 1
	for i = #tiers, 2, -1 do
		if s >= (tiers[i].Min + tiers[i - 1].Max) / 2 then
			return tiers[i]
		end
	end
	return tiers[1]
end

-- Taille tirée à l'éclosion
function Config.RollPetSize(r: Random): number
	local x = r:NextNumber()
	local tier = Config.PetSizes[#Config.PetSizes]
	for _, t in ipairs(Config.PetSizes) do
		x -= t.Chance
		if x <= 0 then
			tier = t
			break
		end
	end
	return math.floor(r:NextNumber(tier.Min, tier.Max) * 100 + 0.5) / 100
end

-- Multiplicateur de revenu d'une taille
function Config.SizeIncomeMult(size: number?): number
	return (size or 1) ^ Config.SizeIncomePower
end

-- Nom affiché (« Giant Elder Pyrolynx ») et revenu d'une créature, taille et stade compris
function Config.PetName(item): string
	local st = Config.PetRules.Stages[item.stage or 1]
	local name = if st and st.Name ~= "" then st.Name .. " " .. (item.name or "?") else (item.name or "?")
	local tier = Config.PetSize(item.size)
	return if tier.Name ~= "" then tier.Name .. " " .. name else name
end
function Config.PetIncome(item): number
	local st = Config.PetRules.Stages[item.stage or 1] or Config.PetRules.Stages[1]
	return Config.CreatureIncome(item.ring, item.rarity, (item.size or 1)) * st.Mult
end
function Config.PetPrice(item): number
	return math.floor((item.income or Config.PetIncome(item)) * Config.PetRules.SellSeconds)
end

function Config.CreatureIncome(ringIndex: number, rarity: number, size: number): number
	local h = Config.Hatch
	local r = h.RarityIncome[math.clamp(rarity, 1, #h.RarityIncome)]
	local ring = h.RingIncome[math.clamp(ringIndex, 1, #h.RingIncome)]
	local v = r * ring * Config.SizeIncomeMult(size)
	-- arrondi lisible : entier sous 1000, sinon 3 chiffres significatifs
	if v < 1000 then
		return math.max(1, math.floor(v + 0.5))
	end
	local p = 10 ^ (math.floor(math.log10(v)) - 2)
	return math.floor(v / p + 0.5) * p
end

-- Probabilités de chaque rareté (index 1..7, 0 si l'anneau n'a pas cet œuf) selon la chance du joueur
function Config.Probabilities(ringIndex: number, luck: number): { number }
	local eggs = Config.Eggs[ringIndex]
	local p = {}
	local first: number? = nil
	for i = 1, #Config.Rarities do
		local e = eggs[i]
		local c = 0
		if e then
			first = first or i
			c = e.Chance
			if i >= Config.LuckFrom then
				c *= luck
			end
		end
		p[i] = c
	end
	local base = first or 1
	local others = 0
	for i = base + 1, #p do
		others += p[i]
	end
	p[base] = math.max(0, 1 - others)
	return p
end

-- GUIDE DE LA PREMIÈRE MINUTE (Guide.client) ------------------------------------------
-- Fait pour qu'un enfant suive sans lire : bulles de 3 à 5 mots, grosses icônes, flèche au sol,
-- main qui montre le geste, petite fête à chaque réussite. Il accompagne le joueur pendant toute la
-- première boucle (et ses détours). Pas d'étape « va à l'anneau 2 » : le joueur ira de lui-même.
-- Étapes enregistrées (d.guide) :
--   0 voler jusqu'à une roche et forer   1 rapporter l'œuf à la machine   2 poser l'œuf
--   3 faire éclore (et aller chercher un 2e œuf pendant l'incubation)   4 « ta créature rapporte des $ »
--   5 avoir Pets créatures   6 acheter sa soufflerie   7 jetpack au niveau JetLevel
--   8 acheter la foreuse n° Drill   9 acheter un niveau de Scanner (la chance)   10 (= Steps) terminé
-- (ordre et niveaux revus après un test du 7 nov. : soufflerie avant la foreuse, niveau 3 suffit)
Config.Guide = {
	-- Tutoriel : chien commun guidé de A à Z, puis créature Épique avec peu d'aide, géode à vendre,
	-- soufflerie, nouvelle foreuse, récompense.
	Steps = 9,
	Drill = 2,
	SecondRarity = 4, -- rareté forcée du deuxième œuf (Épique)
	GeodeRarity = 2, -- minerai forcé de la géode du tutoriel : 15 x 60 x 1,6 = 1 440 $, de quoi payer la soufflerie
	GeodeSize = "Large",
	HoldUntil = 7, -- la créature Épique rapporte à partir de cette étape (minerai vendu), sinon la géode ne sert à rien
	Reward = { Money = 1000, Luck = 15, MoneyBoost = 15 }, -- fin du tutoriel : 5 000 $ et potions x2 de 15 min
	Arrow = "rbxassetid://111578532993258", -- chevrons blancs à contour sombre (poutre au sol)
	MachineNear = 14, -- studs : assez près de la machine pour appuyer sur E
	PetCheer = 5, -- secondes de « ta créature rapporte des $ »
	-- Nom de chaque étape dans l'entonnoir Onboarding (Tracking) ; l'étape 1 de l'entonnoir est « Join »
	Names = {
		"First egg drilled", "Machine used", "Egg placed", "First pet", "Pet money seen",
		"Rare pet hatched", "Gem sold", "Wind tunnel bought", "New drill bought",
	},
	-- Tutoriels au bon moment : une seule fois par joueur, quand il en a besoin (Guide.client)
	Tips = { geode = true, gem = true, basefull = true, supernova = true, rewards = true, fuse = true, monsters = true, mailbox = true, scanner = true, starter = true },
	TipMax = 40, -- secondes avant qu'un tip non suivi s'efface tout seul
	TipShort = 12, -- idem pour un tip sans endroit où aller
	TipGap = 25, -- secondes de calme entre deux tips d'information (récompenses, fusion, monstres...)
}

-- Boîte à retours (boîte aux lettres du vaisseau, FeedbackService)
Config.Feedback = {
	Store = "Feedback_v1",
	MaxChars = 300,
	Cooldown = 45, -- secondes entre deux envois
	PerDay = 5, -- envois par joueur et par jour
	MaxPerDay = 800, -- retours gardés par jour
	Categories = {
		{ Key = "Bug", Label = "Bug", Art = "Warning", Color = "Red" },
		{ Key = "Idea", Label = "Idea", Art = "Sparkles", Color = "Blue" },
		{ Key = "TooHard", Label = "Too hard", Art = "Fire", Color = "Orange" },
		{ Key = "Love", Label = "I love it", Art = "Star", Color = "Green" },
	},
}


-- Téléphones et tablettes (Mobile.client) : part des particules gardée en mode allégé
Config.Mobile = {
	ParticleScale = 0.5,
}

-- RÉCOMPENSES (RewardService, RewardsUI.client) ---------------------------------------
-- Ce qui fait revenir : connexion quotidienne (7 jours qui reprennent au début ; un jour manqué =
-- retour au jour 1), cadeaux de temps de jeu (cumulé sur la journée), 3 quêtes du jour, codes,
-- bonus du groupe Roblox, boost gratuit contre une pub. Jamais d'œufs ni de créatures.
-- Une récompense : { Money = unités, Luck / MoneyBoost / JetXP = minutes de potion }.
-- Money est en « secondes de revenu de base » de l'anneau le plus lointain atteint
-- (Config.Hatch.RingIncome) : 200 = 1K $ dans l'anneau 1, 35,6K $ dans l'anneau 2... Elle reste
-- intéressante à toutes les étapes. Les journées changent à minuit UTC.
Config.Rewards = {
	Daily = {
		{ Money = 200 },
		{ Luck = 10 },
		{ Money = 400 },
		{ MoneyBoost = 10 },
		{ Money = 800 },
		{ JetXP = 15 },
		{ Money = 2000, Luck = 15, MoneyBoost = 15 }, -- jour 7 : le gros cadeau
	},
	Playtime = {
		{ Minutes = 5, Reward = { Money = 100 } },
		{ Minutes = 15, Reward = { Luck = 5 } },
		{ Minutes = 30, Reward = { Money = 400 } },
		{ Minutes = 60, Reward = { MoneyBoost = 15, JetXP = 15 } },
	},
	-- Quêtes : 3 tirées chaque jour dans cette liste (les mêmes pour un joueur toute la journée).
	-- Goal = nombre à atteindre, ou { min, max } ; IncomeGoal = secondes de revenu de base (quête $).
	Quests = {
		{ Kind = "drill", Text = "Drill %d eggs", Goal = { 4, 6 }, Art = "Egg" },
		{ Kind = "hatch", Text = "Hatch %d eggs", Goal = { 2, 3 }, Art = "Hatch" },
		{ Kind = "break", Text = "Break %d asteroids", Goal = { 2, 3 }, Art = "Lightning" },
		{ Kind = "place", Text = "Put %d eggs in your base", Goal = { 2, 4 }, Art = "Home" },
		{ Kind = "tunnel", Text = "Train %d s in your wind tunnel", Goal = { 90, 150 }, Art = "WindTunnel" },
		{ Kind = "income", Text = "Earn %s from your pets", IncomeGoal = 600, Art = "Cash" },
	},
	QuestReward = { Money = 200 }, -- 1K $ dans l'anneau 1
	AllQuestsReward = { Luck = 15 }, -- en plus, à la 3e quête réclamée
	-- Groupe Roblox : 0 = le groupe propriétaire du jeu (s'il appartient à un groupe)
	GroupId = 0,
	GroupLuck = 0.1, -- +10 % de chance tant qu'on est membre
	GroupReward = { Money = 500 }, -- une fois, au premier « Claim »
	-- Boost gratuit contre une pub récompensée (AdService) : la récompense passe par le produit de la
	-- potion x2 Luck (canal AdReward), on donne alors ces potions-ci au lieu de l'achat normal
	AdBoost = { Luck = 5, MoneyBoost = 5 },
	AdCooldown = 600, -- secondes entre deux pubs
}
-- Codes promo (en majuscules) : une fois par joueur
Config.Codes = {
	WELCOME = { Money = 500, Luck = 10 },
	SPACEEGG = { Money = 1000 },
	DRILLTIME = { JetXP = 15, MoneyBoost = 10 },
}

-- GÉODES (GameService, MachineService, GemService) -------------------------------------
-- Quand on fore, une fois sur 3 c'est une géode au lieu d'un œuf (même rareté tirée, même chance du
-- scanner). On la ramène au vaisseau comme un œuf (oxygène compris) ; la machine de la base la fend
-- et révèle un minerai de l'anneau (Config.Rings[anneau].Crystals[rareté]) qui va dans le sac de
-- minerais. On le vend au stand SELL.
-- Prix = revenu d'une créature de même anneau et même rareté (Config.CreatureIncome) × SellSeconds
-- × taille (Config.Sizes) × ShinyMult s'il est brillant (Config.ShinyChance).
Config.Geodes = {
	Chance = 1 / 3,
	SellSeconds = 60,
	BagMax = 200, -- minerais gardés au plus ; au-delà, le nouveau est vendu tout de suite
}

-- SUPERNOVA (renaissance, docs/Interfaces.md §11) ------------------------------------------
-- On repart de zéro : $, foreuse (sauf celle payée en Robux), scanner, niveau du jetpack, soufflerie
-- et œuf porté. On garde : créatures (base et sac), œufs, Index, minerais, skins, passes et potions.
-- En échange : +50 % de revenus des créatures pour toujours, cumulable (x1,5, x2, x2,5…).
-- La première coûte 5 M$, chaque suivante coûte Growth fois plus. Le bouton SUPERNOVA n'apparaît
-- qu'à partir du niveau Level du jetpack (25 = Comet Pack, celui de l'anneau 3), et il disparaît
-- après chaque Supernova jusqu'à ce qu'on y revienne.
Config.Supernova = {
	Base = 5e6,
	Growth = 8,
	MoneyBonus = 0.5, -- par Supernova, en plus (additif)
	Level = 25, -- niveau du jetpack à atteindre pour voir le bouton et pouvoir exploser
	Delay = 1.6, -- secondes d'explosion à l'écran avant le retour à la base
}

-- Prix de la prochaine Supernova quand on en a déjà fait n
function Config.SupernovaCost(n: number): number
	return Config.Supernova.Base * Config.Supernova.Growth ^ n
end

-- Multiplicateur de revenus après n Supernovas
function Config.SupernovaMult(n: number): number
	return 1 + Config.Supernova.MoneyBonus * n
end

-- Nom du minerai d'un anneau et d'une rareté
function Config.GemName(ringIndex: number, rarity: number): string
	local ring = Config.Rings[math.clamp(ringIndex, 1, #Config.Rings)]
	local name = ring.Crystals[rarity]
	if not name or name == "" then
		name = ring.Crystals[#ring.Crystals - 1] or "Gem"
	end
	return name
end

-- Valeur d'un minerai en $
function Config.GemValue(ringIndex: number, rarity: number, sizeMult: number, shiny: boolean): number
	local v = Config.CreatureIncome(ringIndex, rarity, 1) * Config.Geodes.SellSeconds * sizeMult * (if shiny then Config.ShinyMult else 1)
	return math.max(1, math.floor(v + 0.5))
end

return Config
