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
	RelayMinGap = 30, -- pas de relais dans un vide plus étroit
	BuoySpacing = 60,
	-- Champ de décor : roches du biome de chaque côté du tapis, sur toute l'épaisseur et la hauteur
	DecorArc = 750, -- studs d'arc couverts de chaque côté du couloir (au-delà, la brume cache tout)
	DecorDensity = 1 / 2600, -- roches par stud² de champ
	DecorMax = 70, -- plafond par anneau (lisibilité et performances)
	FallY = -150, -- sous cette hauteur, le joueur est perdu dans le Vide
}

-- GEL HORS DU COULOIR (ColdService, ColdFx.client) ---------------------------------------------
-- Hors du couloir (entre les bouées) et hors du vaisseau, il n'y a plus d'oxygène et le froid gagne :
-- après quelques secondes de répit, le gel monte ; trop loin, il monte tout de suite et 2× plus vite.
-- À 100 %, le joueur est pris dans un bloc de glace puis renvoyé à sa base (il perd ses œufs).
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

-- Vitesse au sol et en vol : elle monte avec le NIVEAU DU JETPACK (Config.Jetpack), qu'on farme dans
-- les souffleries du vaisseau (l'équivalent des tapis de course) et en volant pendant les missions.
Config.Movement = {
	Walk = 16, -- vitesse au sol au niveau 1 (studs/s)
	Air = 30, -- vitesse horizontale en vol au niveau 1
	Climb = 32, -- vitesse de montée maximale quand on pousse
	PerLevel = 0.03, -- +3 % de vitesse par niveau de jetpack
	AirAccel = 5, -- réactivité en vol (plus haut = virages plus secs)
	ClimbAccel = 90, -- accélération verticale de la poussée (studs/s²)
	FallBrake = 0.35, -- en vol plané (Saut relâché), la chute est freinée de ce facteur
}

-- Événements (docs/Mecaniques.md §14) ---------------------------------------
Config.Events = {
	MeteorShower = {
		Name = "Meteor Shower",
		Icon = "Comet",
		Every = 20 * 60, -- secondes entre deux pluies
		Duration = 3 * 60,
		SpawnMult = 1.5, -- le défilement accélère
		EggMult = 1.5, -- +50 % d'œufs par astéroïde
	},
}

-- Tapis d'astéroïdes : ils naissent avant le couloir, le traversent et disparaissent après
Config.Belt = {
	MaxActive = 230, -- environ 160 en temps normal, plus pendant une pluie de météores
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
-- Prix de déblocage (UnlockCost) calés sur les revenus des créatures (Config.Hatch) : avec une base
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
	drill("Rusty Drill", 14, 5000, 25, Color3.fromRGB(196, 120, 70)),
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

-- Jetpack (côté client) : carburant en secondes de poussée, rechargé au sol
Config.JetpackFuelBase = 2 -- secondes de poussée au niveau 1 (de quoi rejoindre l'anneau 1)
Config.JetpackFuelPerLevel = 0.05 -- secondes de plus par niveau de jetpack

-- NIVEAU DU JETPACK -------------------------------------------------------------------
-- On gagne de l'XP de jetpack en restant dans une soufflerie (même AFK) et en volant en mission.
-- XP pour passer du niveau L au niveau L+1 = XPBase × XPGrowth^(L-1).
Config.Jetpack = {
	XPBase = 20,
	XPGrowth = 1.12,
	MaxLevel = 150,
	FlightXP = 1, -- XP par seconde de vol réel (poussée ou plané, hors soufflerie)
	-- Soufflerie personnelle : chaque joueur a la sienne devant sa base. On l'achète (Breeze Tunnel),
	-- puis on l'améliore palier par palier ; XP gagnée par seconde dans le courant d'air, même AFK.
	-- Prix calés sur les revenus (entre les prix des anneaux).
	TunnelRadius = 4.5,
	TunnelHeight = 20,
	TunnelOffset = Vector3.new(11, 0, 24), -- position dans le repère du sol de la base (devant l'entrée, sur le côté)
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
	return Config.Movement.Air * Config.Speed(level)
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
		Event = 1846096405, -- pluie de météores : « Action And Tension »
	},
	-- Sons joués à une position : on les entend jusqu'à cette distance (studs)
	Range = 160,
	Sfx = {
		Click = { Id = 106984966606682, Volume = 0.35, Pitch = 1.3 },
		Open = { Id = 80984744279155, Volume = 0.3 },
		Error = { Id = 91501650514390, Volume = 0.35 },
		Coin = { Id = 130378474223829, Volume = 0.45 },
		Buy = { Id = 90531793028786, Volume = 0.5 },
		Pop = { Id = 106984966606682, Volume = 0.6 },
		RockHit = { Id = 9118588165, Volume = 0.35 },
		RockBreak = { Id = 9125869504, Volume = 0.8 },
		Derock = { Id = 9125869138, Volume = 0.7 },
		Riser = { Id = 94077390731779, Volume = 0.35 },
		Hatch = { Id = 9043151109, Volume = 0.5 }, -- éclosion commune à rare
		HatchRare = { Id = 9038916885, Volume = 0.6 }, -- épique et au-delà
		LevelUp = { Id = 1839881844, Volume = 0.5 },
		Reward = { Id = 9038916885, Volume = 0.6 },
		Warning = { Id = 80890994815283, Volume = 0.4 },
		Freeze = { Id = 9125611419, Volume = 0.8 },
		Thaw = { Id = 96795857757261, Volume = 0.4, Pitch = 1.4 },
		MeteorStart = { Id = 9126102564, Volume = 0.45 },
	},
	-- Boucles (volume au maximum de l'effet)
	Loops = {
		Jetpack = { Id = 9125742262, Volume = 0.35 },
		Drill = { Id = 199754867, Volume = 0.3 },
		Machine = { Id = 199754867, Volume = 0.35, Pitch = 0.8 },
		Tunnel = { Id = 9119462099, Volume = 0.45 },
		Void = { Id = 6544555787, Volume = 0.5 }, -- vent glacé hors du couloir
		Heart = { Id = 132163421525060, Volume = 0.5 }, -- battements quand le gel approche
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
	Money = 2500, -- × revenu de base de l'anneau (Config.Hatch.RingIncome) : 12,5 K$ (anneau 1) à 25 000 Md$ (anneau 7)
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
		PackBase = 45000, -- comme le 3e paquet d'argent
		Id = 3729245985,
		Price = 99,
		Was = 249, -- prix barré
	},
	-- Passes (achat définitif). Effets appliqués par BoostService.
	Passes = {
		{ Key = "JetXP2x", Name = "x2 Jetpack XP", Text = "Train your jetpack twice as fast", Art = "PassTraining2x", Id = 2075661369, Price = 149 },
		{ Key = "TurboJetpack", Name = "Turbo Jetpack", Text = "x2 jetpack fuel", Art = "PassTurboJetpack", Id = 2075607386, Price = 99 },
		{ Key = "FastHatch", Name = "Fast Hatch", Text = "Eggs hatch 2x faster", Art = "PassAutoCrack", Id = 2076051409, Price = 199, Ribbon = "BEST SELLER!" },
		{ Key = "Money2x", Name = "x2 Money", Text = "Creatures earn double, forever", Art = "PassMoney2x", Id = 2074467451, Price = 299, Ribbon = "BEST VALUE!" },
		{ Key = "BaseSlots", Name = "+5 Base Slots", Text = "Room for 5 more eggs and creatures", Art = "PassPetSlot", Id = 2074281420, Price = 249 },
		{ Key = "VIP", Name = "VIP", Text = "VIP chat tag, +10% money", Art = "PassVIP", Id = 2074857407, Price = 399 },
	},
	PassEffects = {
		JetXP2x = 2, -- × XP de jetpack
		TurboJetpack = 2, -- × carburant
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
		{ Key = "Meteor", Name = "Meteor Shower", Text = "For the whole server!", Art = "PotionMeteor", Id = 3729245971, Price = 99 },
	},
	-- Boost gratuit contre une pub récompensée
	FreeBoost = { Name = "Free x2 Boost", Minutes = 5, Art = "FreeBoost" },
	-- Paquets d'argent : montant = Base × Config.Hatch.RingIncome de l'anneau le plus loin débloqué
	-- (environ 4 min à 35 min de revenus), pour qu'un paquet reste intéressant à toutes les étapes du jeu
	MoneyPacks = {
		{ Art = "Money1", Base = 6000, Id = 3729246128, Price = 19 },
		{ Art = "Money2", Base = 20000, Id = 3729246160, Price = 49 },
		{ Art = "Money3", Base = 45000, Id = 3729246196, Price = 99, Ribbon = "POPULAR!" },
		{ Art = "Money4", Base = 120000, Id = 3729246217, Price = 249 },
		{ Art = "Money5", Base = 260000, Id = 3729246247, Price = 499, Ribbon = "BEST VALUE!" },
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
	-- Place occupée par un œuf posé puis par sa créature (rayon en studs, selon la rareté) :
	-- deux objets posés ne se touchent pas, et les créatures rares, plus grandes, prennent plus de place
	-- Les Mythic et Cosmic sont immenses : elles prennent une grande partie de la base
	Footprint = { 2.2, 2.4, 2.8, 3.4, 4.6, 6.4, 8.6 },
	Margin = 2.0, -- marge le long des murs (en plus de la moitié de la place occupée)
	-- Zones interdites autour de la machine et du point d'apparition (rayon en studs)
	KeepOut = { DerockMachine = 8.5, Spawn = 4 },
	-- Revenu d'une créature en $/s = RarityIncome[rareté] × RingIncome[anneau] × taille tirée (0,8 à 1,9).
	-- De ~5 $/s (Common de l'anneau 1) à ~1 Qa/s = 10^15 (Cosmic de l'anneau 7).
	-- Exemples (taille 1) : anneau 1 = 5 / 15 / 60 / 300 / 2,5K / 30K ; anneau 4 Mythic ≈ 1,3B ;
	-- anneau 7 = 30B (Uncommon), 120B, 600B, 5T, 60T (Mythic), 1Qa (Cosmic).
	RarityIncome = { 1, 3, 12, 60, 500, 6000, 100000 },
	RingIncome = { 5, 178, 6300, 224000, 7.9e6, 2.8e8, 1e10 },
	-- Secondes entre l'appui sur « Hatch » et l'éclatement (l'œuf tremble et se fissure)
	Burst = 1.6,
	-- Œuf tenu dans les mains en sortant de la machine : hauteur selon la rareté (studs),
	-- et délai avant qu'il apparaisse (le temps que l'œuf révélé vole jusqu'au joueur)
	HeldHeight = { 1.7, 1.85, 2.0, 2.15, 2.35, 2.55, 2.8 },
	HandDelay = 1.4,
	-- Hauteur d'une créature dans la base (studs) selon la rareté, multipliée par sa taille tirée.
	-- Les rares sont nettement plus grandes (et plus impressionnantes) : la récompense se voit.
	PetHeight = { 2.6, 3.0, 3.7, 4.8, 7.0, 10.5, 15.0 },
	-- Promenade autour de son socle : rayon (studs) et durée d'un aller (secondes)
	WanderRadius = 2.2,
	-- Au-delà de cette hauteur (studs), une créature se promène moins loin (les géantes piétinent sur place)
	WanderFullHeight = 4,
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
	["Magma Wyrm"] = motion("slither", "roar", 0.6),
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

-- Nom affiché (« Elder Pyrolynx ») et revenu d'une créature, stade compris
function Config.PetName(item): string
	local st = Config.PetRules.Stages[item.stage or 1]
	return if st and st.Name ~= "" then st.Name .. " " .. (item.name or "?") else (item.name or "?")
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
	local v = r * ring * (size or 1)
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

return Config
