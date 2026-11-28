-- Toutes les valeurs d'équilibrage du jeu (fiche de game design, section Progression).
-- Les textes affichés sont en anglais : l'audience Roblox est mondiale.

local Config = {}

-- 15 nov. 2026 : tout le monde repart de zéro après la phase de test (Player_v1 garde les anciennes
-- parties, plus lues). Ne changer qu'exprès pour tout remettre à zéro : le schéma est versionné dans DataService.
-- 15 nov. 2026 : Player_v3, nouvelle économie (prix, niveaux sans plafond, plus de Supernova ni de géodes) :
-- les parties Player_v2 restent stockées, plus lues.
Config.SaveKey = "Player_v3"

-- MODE TESTEUR (server/Testers.lua) : chaque joueur reçoit tout au niveau maximum à son arrivée.
-- Les parties vont alors dans une sauvegarde à part (SaveKey) et les classements ne sont pas écrits.
-- À METTRE À false AVANT D'OUVRIR LE JEU AU PUBLIC.
Config.Testers = {
	Everyone = false, -- coupé le 15 nov. 2026 (tout le monde repart de zéro)
	SaveKey = "Player_test_v1",
	Money = 1e15,
	Shields = 5,
}
Config.AutosaveSeconds = 60
-- SESSION (server/DataService) : une partie n'est ouverte que sur un serveur à la fois.
Config.Session = {
	LockSeconds = 120, -- un verrou sans nouvelles depuis ce temps vient d'un serveur mort (2 sauvegardes automatiques)
	WaitSeconds = 30, -- à l'arrivée : temps laissé à l'ancien serveur pour finir sa sauvegarde, avant de renvoyer le joueur
	RetrySeconds = 4, -- entre deux essais pendant cette attente
	CloseSeconds = 25, -- fermeture du serveur : temps laissé aux dernières sauvegardes (Roblox coupe à 30)
	Receipts = 60, -- achats Robux gardés en mémoire dans la partie pour ne jamais en donner un deux fois
}

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
-- Messages serveur (AnnounceService) : niveau d'une trouvaille selon sa mutation et sa taille (nil = pas
-- de message). Depuis le 15 nov., l'espèce dépend du type d'astéroïde foré : ce qui est rare, c'est la mutation.
-- 1 Rare : Ruby, ou Emerald Large ; 2 Épique : Rainbow, ou Ruby Large ; 3 Légendaire (tous les serveurs) : Rainbow Large.
-- giant : la créature a la plus grande mutation de taille (Large depuis le 29 nov., Giant avant).
function Config.AnnounceLevel(mutation: string?, giant: boolean): number?
	if mutation == "Rainbow" then
		return if giant then 3 else 2
	elseif mutation == "Ruby" then
		return if giant then 2 else 1
	elseif mutation == "Emerald" and giant then
		return 1
	end
	return nil
end

-- CARTE V2 (docs/Mecaniques.md §2) ---------------------------------------------
-- Le point de départ (Workspace.Ship, construit dans Studio par tools/build-yard.lua : depuis le 26 nov.
-- c'est une cour en herbe, plus un vaisseau, mais le conteneur garde son nom) a son centre en (0, 0, 0)
-- et sa sortie (ligne rouge) en z = FrontZ ; le couloir part de là vers +Z.
-- Les anneaux sont des cercles horizontaux autour d'un axe vertical placé derrière le vaisseau,
-- là où la planète géante est peinte dans le ciel (tools/sky/render_sky.py).
Config.Map = {
	FrontZ = 64, -- position du repère Ship.Yard.DockEnd (ligne rouge de la sortie, début du couloir)
	AxisDistance = 1200, -- distance entre l'axe de rotation des anneaux et le bout du quai
	CorridorWidth = 120, -- = largeur de la sortie de la cour (tools/build-yard.lua, GATE), à garder identiques
	FirstRingGap = 12, -- vide entre le bout du quai et le bord de l'anneau 1
	RingWidth = 64, -- épaisseur de l'anneau 1 : un vrai champ, pas une ligne
	RingGap = 55, -- vide entre les anneaux 1 et 2 (bord à bord) : chaque biome bien séparé
	RingGrowth = 1.22, -- épaisseur et vide grandissent de 22 % à chaque anneau
	RelaySize = 30, -- relais de pression, au milieu des vides assez larges entre deux anneaux
	RelayMinGap = math.huge, -- relais retirés (7 nov.) : c'est le carburant du jetpack qui décide quels vides on traverse
	BuoySpacing = 60,
	-- (27 nov. : les murs du couloir, leurs piliers et leurs décors sont réglés par biome dans
	-- shared/CorridorThemes et construits par server/CorridorDecor ; BuoySpacing = pas entre deux piliers)
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
-- MONSTRES (un par anneau, docs/Mecaniques.md §13 et §0) -------------------------------------
-- Un seul monstre par anneau, de plus en plus grand et impressionnant : deux petits pour commencer
-- (28 nov. : un scarabée de roche qu'on sème toujours à l'anneau 1, un serpent de glace à l'anneau 2),
-- puis les grands à partir du 3e. Chacun a sa démarche (client/MonsterGaits). Il est toujours
-- là (20 nov.) : il se promène dans le couloir de son anneau (Patrol, Config.MonsterPatrol). Dès qu'un
-- joueur sort un œuf d'un astéroïde de son anneau, il fonce droit sur lui (plus de jauge de bruit ni
-- d'astéroïdes gardés) et le poursuit jusqu'à la ligne rouge de la cour (29 nov.) ; il ne la passe pas :
-- il s'écrase contre la barrière qui s'allume en travers de la sortie et retourne dans son anneau.
-- Need = vitesse du jetpack (Speed, l'XP totale du jetpack) qu'il faut pour le semer (18 nov.) :
-- avec assez de Speed, il va un peu moins vite que le joueur (Speed du monstre : 0,82 à 0,98 depuis le
-- 29 nov., pour plus de pression ; 0,6 à 0,95 avant) ; en dessous, il
-- va d'autant plus vite que le joueur en manque (jusqu'à MaxFactor fois la vitesse du joueur).
-- S'il l'attrape : le joueur est projeté au loin et sa roche retombe sur l'astéroïde le plus proche ;
-- il a DropTime secondes pour aller la reprendre, sinon elle s'enfonce dans l'astéroïde (œuf perdu).
Config.Monsters = {
	Kinds = {
		-- les deux premiers apprennent la poursuite sans faire mal, dès le premier œuf : petits, lents
		-- (Need = 0 : toujours semable)
		[1] = { Name = "Dust Skitter", Model = "DustSkitter", Speed = 0.82, Size = 9, Need = 0, Color = Color3.fromRGB(255, 200, 90), Move = "Walk", Foot = 0.27 },
		[2] = { Name = "Frost Slink", Model = "FrostSlink", Speed = 0.88, Size = 12, Need = 4e3, Color = Color3.fromRGB(120, 230, 255), Move = "Crawl" },
		[3] = { Name = "Cinder Maw", Model = "CinderMaw", Speed = 0.92, Size = 16, Need = 50e3, Color = Color3.fromRGB(255, 120, 40), Move = "Crawl" },
		[4] = { Name = "Nebula Stalker", Model = "NebulaStalker", Speed = 0.92, Size = 20, Need = 500e3, Color = Color3.fromRGB(190, 110, 255), Move = "Float" },
		[5] = { Name = "Devourer", Model = "Devourer", Speed = 0.92, Size = 26, Need = 7e6, Color = Color3.fromRGB(150, 255, 90), Move = "Crawl" },
		[6] = { Name = "Rift Watcher", Model = "Watcher", Speed = 0.95, Size = 30, Need = 100e6, Color = Color3.fromRGB(90, 230, 255), Move = "Float" },
		[7] = { Name = "Nest Queen", Model = "Queen", Speed = 0.95, Size = 34, Need = 1.5e9, Color = Color3.fromRGB(255, 170, 60), Move = "Float" },
		[8] = { Name = "Abyss Angler", Model = "AbyssAngler", Speed = 0.95, Size = 38, Need = 8e9, Color = Color3.fromRGB(60, 230, 210), Move = "Float" },
		[9] = { Name = "Storm Hydra", Model = "StormHydra", Speed = 0.95, Size = 42, Need = 70e9, Color = Color3.fromRGB(255, 230, 90), Move = "Walk", Foot = 0.4 },
		[10] = { Name = "Gear Spider", Model = "GearSpider", Speed = 0.96, Size = 46, Need = 700e9, Color = Color3.fromRGB(240, 170, 80), Move = "Walk", Foot = 0.45 },
		[11] = { Name = "Sour Worm", Model = "SourWorm", Speed = 0.96, Size = 50, Need = 9e12, Color = Color3.fromRGB(255, 110, 190), Move = "Crawl" },
		[12] = { Name = "Spore Behemoth", Model = "SporeBehemoth", Speed = 0.96, Size = 54, Need = 150e12, Color = Color3.fromRGB(110, 240, 210), Move = "Walk", Foot = 0.5 },
		[13] = { Name = "Temple Colossus", Model = "TempleColossus", Speed = 0.98, Size = 58, Need = 3.5e15, Color = Color3.fromRGB(255, 200, 80), Move = "Walk", Foot = 0.5 },
		[14] = { Name = "Phantom King", Model = "PhantomKing", Speed = 0.98, Size = 64, Need = 40e15, Color = Color3.fromRGB(120, 240, 220), Move = "Float" },
	},
	-- Vitesse du monstre quand le joueur manque de Speed : Speed du monstre + (MaxFactor - Speed) × part,
	-- part = log10(Need / Speed du joueur) / Decades (1 dès qu'il lui manque Decades puissances de 10)
	MaxFactor = 1.75,
	Decades = 2,
	-- Alarme du joueur pris en chasse : Count coups de klaxon, un toutes les Gap secondes, chacun coupé net
	-- au bout de Length secondes (la note enregistrée dure 0,8 s)
	Alarm = { Count = 2, Gap = 0.5, Length = 0.38 },
	-- En poursuite, tous ses gestes vont plus vite (ailes, queue, mâchoires, ondulation) : x ChaseAnim à pleine
	-- ardeur (client/MonsterRig). Les pas suivent déjà la distance, donc sa vitesse.
	ChaseAnim = 1.8,
	-- Prise : le joueur est projeté (studs/s) et sa roche retombe sur l'astéroïde le plus proche
	Knock = 70,
	KnockUp = 35,
	DropTime = 30, -- secondes pour reprendre sa roche
	DropSearch = 500, -- studs : astéroïde le plus proche cherché dans ce rayon (sinon la roche est perdue)
	PickRadius = 9, -- studs : on reprend sa roche en la touchant (en plus de sa taille)
	-- Façon de se promener (Kinds[].Move, shared/MonsterPath) : Float flotte librement (Patrol ci-dessous) ;
	-- Walk se tient sur les astéroïdes, les traverse à pied et saute de l'un à l'autre (Foot = distance du
	-- centre du monstre à ses pieds, en part de sa taille) ; Crawl rampe à plat autour d'eux.
	Route = {
		Side = 0.42, -- part de la largeur du couloir où il choisit ses astéroïdes, de chaque côté du centre
		Reach = 170, -- studs : il ne vise pas un astéroïde plus loin
		WalkSpeed = { 6, 0.3 }, -- marche sur la roche : studs/s = base + part × taille du monstre
		HopSpeed = { 26, 0.5 }, -- bond d'une roche à l'autre
		CrawlSpeed = { 16, 0.35 }, -- reptation
		Stay = { 2.5, 6 }, -- secondes sur un astéroïde (marcheur)
		Turn = { 2.4, 4.6 }, -- radians de tour autour d'un astéroïde (rampeur)
		Keep = 2, -- studs de préférence par seconde que l'astéroïde passera encore dans le couloir
		Big = 1.2, -- préférence pour les gros astéroïdes, d'autant plus forte que le monstre est grand
		Jitter = 30, -- hasard (studs) : il ne prend pas toujours le plus proche
	},
	-- Promenade dans le couloir : vitesse (studs/s au plus), part de la largeur du couloir et de
	-- l'épaisseur de l'anneau parcourues de chaque côté du centre, hauteur moyenne au-dessus du pont
	Patrol = { Speed = 14, Side = 0.38, Depth = 0.3, Height = 12 },
	MaxChase = 180, -- secondes : sécurité si le joueur reste coincé quelque part (il rentre alors chez lui)
	-- (29 nov. : on est à l'abri dès la ligne rouge de la cour, plus seulement dans sa base)
	Recoil = 10, -- studs : il rebondit sur la barrière de la cour
	ReturnPause = 0.8, -- secondes de rage avant de rentrer
	ReturnSpeed = 90, -- studs/s pour retourner dans son anneau
	ReturnTime = 20, -- secondes au plus pour y retourner, puis il reprend sa promenade où elle en est
	LungeDistance = 22, -- studs (en plus de son rayon) : il bondit en claquant des mâchoires (effet seul)
	Emerge = 1.1, -- secondes où il se tourne vers le voleur et rugit avant de foncer (on a le temps de fuir)
	CatchRadius = 6, -- en plus de son rayon
	MinSpeed = 24, -- studs/s au minimum dans l'espace (sinon vitesse en vol du joueur × Speed) ;
	-- sur le vaisseau : vitesse à pied du joueur × Speed
	Cooldown = 12, -- secondes de répit après une poursuite
	StunGap = 4, -- secondes après un coup de batte où le monstre ne peut plus être assommé
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
	Time = { 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110 },
	Low = 0.3, -- part restante sous laquelle l'alerte rouge commence
	-- studs ajoutés à la boîte du vaisseau pour « de retour à bord » : négatif = un peu à l'intérieur du bord,
	-- car les roches de l'anneau 1 frôlent le vaisseau (sinon le compte à rebours ne partirait pas)
	ShipMargin = -6,
}

-- Vitesse au sol et en vol : elle monte avec le NIVEAU DU JETPACK (Config.Jetpack), qu'on farme dans
-- les souffleries du vaisseau (l'équivalent des tapis de course) et en volant pendant les missions.
Config.Movement = {
	Walk = 16, -- vitesse au sol au niveau 1 (studs/s)
	-- Les vitesses suivent l'avancée dans les paliers de jetpack (Config.JetProgress : 1 au palier 1,
	-- 2 au palier 2..., 9 au niveau TopLevel), pas le niveau brut : il n'a plus de plafond (15 nov.)
	PerTier = 0.1, -- +10 % de vitesse au sol par palier de jetpack (+80 % tout en haut)
	Air = 20, -- vitesse horizontale en vol au niveau 1
	AirPerTier = 2.8, -- + studs/s en vol par palier (42 tout en haut)
	Climb = 32, -- vitesse de montée maximale quand on pousse
	Gravity = 70, -- = Workspace.Gravity (sert au calcul de la portée d'un vol)
	AirAccel = 5, -- réactivité en vol (plus haut = virages plus secs)
	ClimbAccel = 90, -- accélération verticale de la poussée (studs/s²)
	FallBrake = 0.35, -- en vol plané (Saut relâché), la chute est freinée de ce facteur
}

-- Tapis d'astéroïdes : ils naissent avant le couloir, le traversent et disparaissent après
Config.Belt = {
	MaxActive = 470, -- environ 350 en temps normal avec 14 anneaux
	SpawnArc = 180, -- studs d'arc entre le point de naissance et le centre du couloir (idem après)
	-- Hauteur : les astéroïdes s'étalent sur plusieurs étages, plus haut dans les grands anneaux
	HeightBase = 10, -- ± studs au minimum
	HeightPerWidth = 0.15, -- + 15 % de l'épaisseur de l'anneau
	HeightMax = 36,
	Spacing = 0.9, -- deux astéroïdes ne naissent pas plus près que 90 % de leurs rayons cumulés
	-- Couche de marche : une partie des astéroïdes passe à la hauteur du pont, du côté intérieur de
	-- l'anneau. On peut forer depuis le quai (ou un relais) et sauter de roche en roche.
	WalkShare = 0.8, -- part des astéroïdes tendres (type 1, côté vaisseau) dans la couche de marche
	WalkHeight = { -9, 0 }, -- hauteur de leur centre (le pont est à 0)
	WalkDepth = 0.3, -- ils restent dans les 30 % intérieurs de l'épaisseur de l'anneau (près du quai / du relais)
}

-- Demi-hauteur du champ de l'anneau i (les astéroïdes vont de -h à +h)
function Config.FieldHeight(i: number): number
	local b = Config.Belt
	return math.min(b.HeightBase + Config.RingWidth(i) * b.HeightPerWidth, b.HeightMax)
end

-- TYPES D'ASTÉROÏDES (15 nov., sur le modèle des zones de Throw Food) ---------------------------------
-- Chaque anneau a 3 types d'astéroïdes, rangés par profondeur : les plus tendres du côté du vaisseau, les
-- plus durs au fond. Le type décide de ce qu'on trouve dedans : le joueur sait à peu près ce qu'il va
-- avoir (seules la taille et la mutation restent du hasard).
--   Share  : part des astéroïdes de l'anneau
--   Depth  : bande de l'épaisseur de l'anneau où ils passent (0 = bord côté vaisseau, 1 = bord du fond)
--   Min, Max : diamètre (studs) ; Eggs = { min, max } : stock d'œufs, qui sortent un par un
--   HP     : × EggHP de l'anneau (vie de chaque œuf)
--   Shape  : forme (ReplicatedStorage.Assets.Asteroids.Ring<n>.<Shape>)
--   Color, Reflect : matière du type (shared/RockLook), pour le reconnaître de loin sans rien lire : la roche
--            de l'anneau telle quelle, une roche d'argent, une roche d'or. Seulement pour les anciens modèles :
--            ceux peints pour leur zone (attribut Painted, anneau 1 depuis le 25 nov.) gardent leurs couleurs.
--   Slots  : chances (sur 100) des 6 créatures de l'anneau, de la 1re à la 6e. Le type 1 donne surtout
--            les deux premières, le type 2 les deux suivantes, le type 3 les deux dernières (pas à 100 %).
Config.RockTypes = {
	{ Key = "Soft", Name = "Soft Rock", Share = 0.5, Depth = { 0, 0.36 }, Min = 10, Max = 14, Eggs = { 2, 3 }, HP = 1, Shape = "V1", Slots = { 62, 30, 6, 2, 0, 0 } },
	{ Key = "Hard", Name = "Silver Rock", Share = 0.32, Depth = { 0.36, 0.7 }, Min = 16, Max = 21, Eggs = { 3, 5 }, HP = 2, Shape = "V2", Color = Color3.fromRGB(235, 240, 250), Reflect = 0.3, Slots = { 10, 14, 46, 24, 5, 1 } },
	{ Key = "Core", Name = "Gold Rock", Share = 0.18, Depth = { 0.7, 1 }, Min = 24, Max = 32, Eggs = { 5, 8 }, HP = 4, Shape = "V3", Color = Color3.fromRGB(250, 190, 45), Reflect = 0.22, Slots = { 0, 4, 12, 16, 44, 24 } },
}
-- Type d'un astéroïde (1 à 3) ; les œufs des anciennes parties, sans type, comptent comme le premier
function Config.RockType(index: number?)
	return Config.RockTypes[math.clamp(index or 1, 1, #Config.RockTypes)]
end
-- Fissures : de nouvelles fissures apparaissent quand la vie passe sous ces fractions
Config.CrackStages = { 0.75, 0.5, 0.25 }

-- Les 7 anneaux. Speed = vitesse de défilement (studs/s) : les anneaux intérieurs vont plus vite.
-- Active = astéroïdes visibles en même temps. EggHP = dégâts de forage pour détacher un œuf
-- (la barre de vie d'un œuf ; triplée le 7 nov. pour que la soute se remplisse moins vite).
local function newRing(name, speed, active, eggHP, valueMult, depth, unlockCost, color)
	return {
		Name = name,
		Speed = speed,
		Active = active,
		EggHP = eggHP,
		ValueMult = valueMult,
		Depth = depth,
		UnlockCost = unlockCost,
		Color = color,
	}
end
-- UnlockCost : plus utilisé depuis le 7 nov. (tous les anneaux sont ouverts, on y va à ses risques ;
-- c'est la portée du jetpack qui décide). Ancien calcul : prix calés sur les revenus (Config.Hatch), avec une base
-- pleine de créatures plutôt communes de l'anneau précédent, il faut environ 10 min (anneau 2),
-- 15 min (3), 20 min (4), 30 min (5), 45 min (6) et 1 h (7).
Config.Rings = {
	newRing("Dust Belt", 3.4, 20, 24, 1, 1.0, 0, Color3.fromRGB(120, 108, 98)),
	newRing("Ice Ring", 3.1, 18, 120, 4, 1.3, 75000, Color3.fromRGB(150, 200, 230)),
	newRing("Magma Field", 2.8, 20, 540, 16, 1.8, 4e6, Color3.fromRGB(110, 50, 40)),
	newRing("Nebula", 2.5, 22, 2400, 64, 2.4, 2e8, Color3.fromRGB(120, 80, 170)),
	newRing("Devourer Belt", 2.2, 24, 10800, 256, 3.2, 1e10, Color3.fromRGB(70, 60, 60)),
	newRing("The Rift", 1.95, 28, 48000, 1024, 4.2, 5.5e11, Color3.fromRGB(60, 90, 120)),
	newRing("The Nest", 1.7, 32, 210000, 4096, 5.5, 2.6e13, Color3.fromRGB(150, 120, 80)),
	-- 8e anneau (15 nov.) : un récif de corail dans l'espace. Pas encore de monstre.
	newRing("Star Reef", 1.5, 34, 945000, 16384, 7.0, 0, Color3.fromRGB(40, 170, 170)),
	-- 9e anneau (15 nov.) : un anneau d'orages violets traversé d'éclairs. Pas de monstre.
	newRing("Storm Halo", 1.35, 36, 4.25e6, 65536, 8.5, 0, Color3.fromRGB(110, 90, 200)),
	-- 10e anneau (16 nov.) : une ceinture de rouages en laiton, d'horloges et de vapeur. Pas de monstre.
	newRing("Clockwork Belt", 1.2, 38, 1.9e7, 262144, 10.0, 0, Color3.fromRGB(200, 140, 70)),
	-- 11e anneau (16 nov.) : une comète de bonbons, de guimauve et de sucre glace. Pas de monstre.
	newRing("Candy Comet", 1.05, 40, 8.55e7, 1048576, 11.5, 0, Color3.fromRGB(230, 120, 170)),
	-- 12e anneau (16 nov.) : une lune couverte de champignons lumineux, de mousse et de spores. Pas de monstre.
	newRing("Mushroom Moon", 0.95, 42, 3.85e8, 4194304, 13.0, 0, Color3.fromRGB(120, 90, 170)),
	-- 13e anneau (16 nov.) : les ruines d'un temple antique de jade et d'or qui flottent dans l'espace. Pas de monstre.
	newRing("Jade Temple", 0.85, 44, 1.73e9, 16777216, 14.5, 0, Color3.fromRGB(80, 170, 120)),
	-- 14e anneau (17 nov.) : une brume hantée mais mignonne, avec fantômes, citrouilles et lanternes bleues. Pas de monstre.
	newRing("Phantom Mist", 0.75, 46, 7.8e9, 67108864, 16.0, 0, Color3.fromRGB(90, 200, 190)),
}
Config.CosmicMinRing = 5

-- Image du monde de chaque anneau dans l'Index (25 nov., comme Throw Food) : rendu Blender de la scène
-- (ses astéroïdes, des créatures de l'anneau et un œuf), 384 x 1024, fichiers dans tools/ui-icons/world_r<n>.png.
-- Sans image, l'Index montre les trois astéroïdes de l'anneau qui tournent. Script : tools/blender/index_world.py.
Config.WorldArt = {
	[1] = "rbxassetid://118105006686666",
	[2] = "rbxassetid://119946400240335",
	[3] = "rbxassetid://90860235777093",
	[4] = "rbxassetid://105962939242313",
	[5] = "rbxassetid://118060375962513",
	[6] = "rbxassetid://130295940764120",
	[7] = "rbxassetid://125127615570014",
	[8] = "rbxassetid://119375145149130",
	[9] = "rbxassetid://102181585976973",
	[10] = "rbxassetid://136497902036928",
	[11] = "rbxassetid://112991885674391",
	[12] = "rbxassetid://122855081305918",
	[13] = "rbxassetid://70547902406512",
	[14] = "rbxassetid://104354183544956",
}

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

-- Promenade du monstre de cet anneau à l'instant t (heure serveur) : position et direction. Le même
-- calcul tourne sur le serveur et chez les clients, donc rien à envoyer tant qu'il se promène. Il va
-- et vient en travers du couloir, s'enfonce et revient dans l'épaisseur de l'anneau, monte et descend.
function Config.MonsterPatrol(ring: number, t: number): (Vector3, Vector3)
	local P = Config.Monsters.Patrol
	local function at(time: number): Vector3
		local half = Config.Map.CorridorWidth * P.Side
		local x = half * math.sin(time * P.Speed / half + ring * 1.7)
		local r = Config.RingRadius(ring) + Config.RingWidth(ring) * P.Depth * math.sin(time * 0.11 + ring)
		local y = P.Height + Config.FieldHeight(ring) * 0.4 * math.sin(time * 0.17 + ring * 2.3)
		return Config.OrbitPosition(r, x / r, y)
	end
	local p = at(t)
	local d = at(t + 0.5) - p
	return p, if d.Magnitude > 0.01 then d.Unit else Vector3.zAxis
end

-- Améliorations : coût du niveau n = Base × Growth^n × Config.PriceWobble (voir Config.StepCost)
Config.Upgrades = {
	Scanner = { Name = "Scanner", Base = 4000, Growth = 3.5, Max = 20 },
}
-- Prix irréguliers (15 nov.) : d'un niveau au suivant, l'écart n'est jamais le même. Tantôt deux prix
-- proches (deux achats coup sur coup), tantôt un grand saut (un vrai objectif). Le motif se répète
-- tous les 6 niveaux ; chaque amélioration le prend à un endroit différent (Shift) pour que deux
-- objets n'aient jamais le même rythme.
Config.PriceWobble = { 1, 0.7, 1.7, 1, 0.55, 2 }
-- Prix arrondi à 2 chiffres significatifs (4 200, 13 000, 1,7 M...)
function Config.StepCost(base: number, growth: number, level: number, shift: number?): number
	local w = Config.PriceWobble
	local v = base * growth ^ level * w[(level + (shift or 0)) % #w + 1]
	local p = 10 ^ (math.floor(math.log10(v)) - 1)
	return math.floor(v / p + 0.5) * p
end
Config.UpgradeOrder = { "Scanner" }

-- MACHINE À DÉROCHER (docs/Mecaniques.md §7) ---------------------------------------
-- Les œufs sortent des astéroïdes encore pris dans la roche ; la machine de la base la retire.
-- Durée pour un œuf = Time + PerRarity × (rareté - 1) secondes ; Gap = pause entre deux œufs
-- (le temps que l'œuf révélé vole jusqu'au joueur).
Config.Derock = {
	-- Secondes pour dégager un œuf, de Common à Cosmic (avant les améliorations de la machine).
	-- Pendant ce temps le joueur est libre : il peut repartir forer.
	-- (raccourcis le 15 nov. : les œufs des deux derniers rangs d'un anneau sont maintenant courants)
	Times = { 4, 7, 12, 20, 30, 45, 60 },
	Tutorial = 4, -- durée pendant le tutoriel, quelle que soit la rareté
	Gap = 1.6,
	-- Finir tout de suite contre des Robux : un produit de développeur par rareté (créés le 9 nov.)
	Skip = {
		{ Price = 5, ProductId = 3729852711 },
		{ Price = 9, ProductId = 3729852818 },
		{ Price = 15, ProductId = 3729852834 },
		{ Price = 25, ProductId = 3729852849 },
		{ Price = 45, ProductId = 3729852872 },
		{ Price = 79, ProductId = 3729852889 },
		{ Price = 129, ProductId = 3729852911 },
	},
}

-- FOREUSES ------------------------------------------------------------------------
-- Une foreuse de départ, puis 10 à acheter une par une (comme les pioches des jeux d'œufs),
-- en $ ou en Robux. Toutes marchent sur tous les anneaux : une petite foreuse est juste lente.
-- Power = dégâts par seconde de forage (un œuf sort quand on a fait EggHP de dégâts).
-- ProductId = produit Robux de cette foreuse (0 tant qu'il n'est pas créé).
local function drill(name, power, cost, robux, color)
	return { Name = name, Power = power, Cost = cost, Robux = robux, ProductId = 0, Color = color }
end
-- Prix en $ réglés avec tools/eco-sim.luau (15 nov.) : deux foreuses par anneau, écarts irréguliers
-- (tantôt ×8 à ×16, tantôt ×33 ou ×75), de plus en plus longues à payer d'un anneau à l'autre.
-- Joueur qui passe 40 % de son temps en soufflerie : foreuse 2 vers 4 min, 3 vers 16 min, 5 vers 1 h,
-- 7 vers 2 h 30, 9 vers 6 h, 11 vers 15 h.
Config.Drills = {
	drill("Starter Drill", 5, 0, 0, Color3.fromRGB(170, 176, 190)),
	drill("Rusty Drill", 14, 12000, 25, Color3.fromRGB(196, 120, 70)), -- fin du tutoriel
	drill("Steel Drill", 40, 400000, 49, Color3.fromRGB(150, 170, 200)),
	drill("Turbo Drill", 110, 4e6, 79, Color3.fromRGB(80, 170, 255)),
	drill("Laser Drill", 320, 3e8, 129, Color3.fromRGB(90, 230, 120)),
	drill("Plasma Drill", 900, 3e9, 199, Color3.fromRGB(190, 100, 255)),
	drill("Golden Drill", 2600, 3e10, 299, Color3.fromRGB(255, 200, 50)),
	drill("Crystal Drill", 7500, 2.5e11, 449, Color3.fromRGB(120, 240, 255)),
	drill("Nova Drill", 21000, 4e12, 699, Color3.fromRGB(255, 120, 80)),
	drill("Galaxy Drill", 60000, 4e13, 999, Color3.fromRGB(255, 110, 210)),
	drill("Cosmic Drill", 170000, 2e15, 1499, Color3.fromRGB(130, 255, 240)),
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
	skin("Bubblegum", "Bubblegum", 2, 125000, col(255, 150, 205), col(255, 236, 246), col(205, 80, 150), col(255, 255, 255), col(255, 170, 225)),
	skin("Mint", "Mint", 2, 300000, col(140, 240, 190), col(240, 255, 248), col(40, 140, 110), col(220, 255, 240), col(150, 255, 215)),
	skin("Midnight", "Midnight", 3, 2.5e6, col(45, 55, 115), col(90, 200, 255), col(22, 24, 52), col(175, 220, 255), col(90, 200, 255)),
	skin("Lava", "Lava", 3, 2.5e7, col(55, 42, 42), col(255, 125, 40), col(30, 24, 24), col(255, 195, 95), col(255, 115, 30)),
	skin("Toxic", "Toxic", 4, 2.5e8, col(135, 240, 60), col(150, 65, 205), col(60, 40, 85), col(225, 255, 150), col(175, 255, 80)),
	skin("Frost", "Frost", 4, 2.5e9, col(205, 236, 255), col(255, 255, 255), col(90, 140, 195), col(232, 250, 255), col(160, 230, 255), "Sparkle"),
	skin("Gold", "Gold", 5, 2.5e10, col(255, 200, 50), col(255, 245, 190), col(170, 110, 20), col(255, 235, 150), col(255, 222, 90), "Sparkle"),
	skin("Diamond", "Diamond", 6, 2.5e11, col(135, 240, 255), col(255, 255, 255), col(60, 150, 220), col(232, 255, 255), col(175, 250, 255), "Sparkle"),
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

-- RELIQUES DES EXPLORATEURS PERDUS (RelicService, RelicUI.client, onglet RELICS de l'Index).
-- Une par anneau. Chance = 1 sur N, à chaque œuf foré dans cet anneau (sans bonus de chance), tant qu'on
-- ne l'a pas. On ne la vend pas (15 nov.) : trouvée, elle donne un bonus pour toujours.
-- Bonus.Kind : "Money" (revenus des créatures) ou "XP" (XP du jetpack) ; Value : 0.05 = +5 %.
local function relic(key, name, ring, chance, kind, color, story)
	return { Key = key, Name = name, Ring = ring, Chance = chance, Bonus = { Kind = kind, Value = 0.05 }, Color = color, Story = story }
end
Config.RelicReveal = 14 -- secondes de la révélation : le froid et l'oxygène attendent pendant ce temps
Config.Relics = {
	relic("Compass", "Lost Compass", 1, 300, "Money", col(90, 225, 210), "It still points home, wherever home was."),
	relic("Logbook", "Frozen Logbook", 2, 500, "XP", col(150, 220, 255), "Last entry: it is so cold, but the eggs are warm."),
	relic("Visor", "Melted Visor", 3, 800, "Money", col(255, 140, 60), "Someone flew too close to the magma, and kept going."),
	relic("Medal", "Explorer's Medal", 4, 1200, "XP", col(190, 120, 255), "Given to the first crew to cross the Nebula. None came back."),
	relic("Helmet", "Chewed Helmet", 5, 1800, "Money", col(140, 240, 90), "Those are teeth marks. Do not ask."),
	relic("Map", "Torn Star Map", 6, 2400, "XP", col(90, 225, 245), "It shows a way past the Rift. Half of it is missing."),
	relic("Flag", "The First Flag", 7, 3000, "Money", col(255, 205, 80), "Planted by the first explorer to reach the Nest. Nobody knows their name."),
	relic("Bell", "Diver's Bell", 8, 4000, "XP", col(90, 230, 200), "It still rings when something huge swims past the reef."),
	relic("Rod", "Bent Lightning Rod", 9, 5000, "Money", col(255, 225, 90), "Struck a thousand times. It still hums before every storm."),
	relic("Watch", "Backwards Pocket Watch", 10, 6000, "XP", col(240, 180, 90), "It ticks backwards when nobody is looking."),
	relic("Spoon", "Golden Sugar Spoon", 11, 7000, "Money", col(255, 150, 200), "Someone stirred a whole comet with it."),
	relic("Jar", "Whispering Spore Jar", 12, 8000, "XP", col(140, 255, 210), "The spores inside are still whispering to each other."),
	relic("Mask", "Cracked Golden Mask", 13, 9000, "Money", col(255, 205, 80), "Its jade eyes follow whoever holds it."),
	relic("Lantern", "Flickering Ghost Lantern", 14, 10000, "XP", col(140, 255, 220), "Its flame burns blue and never goes out."),
}
-- Texte court du bonus d'une relique (« +5% money »)
function Config.RelicBonusText(r): string
	return ("+%d%% %s"):format(math.floor(r.Bonus.Value * 100 + 0.5), if r.Bonus.Kind == "XP" then "jetpack XP" else "money")
end
-- Multiplicateur donné par les reliques trouvées (found : ["clé"] = true) pour ce genre de bonus
function Config.RelicMult(found: { [string]: boolean }?, kind: string): number
	local m = 1
	for _, r in ipairs(Config.Relics) do
		if found and found[r.Key] and r.Bonus.Kind == kind then
			m += r.Bonus.Value
		end
	end
	return m
end
function Config.Relic(key: string)
	for _, r in ipairs(Config.Relics) do
		if r.Key == key then
			return r
		end
	end
	return nil
end
function Config.RelicOfRing(ring: number)
	for _, r in ipairs(Config.Relics) do
		if r.Ring == ring then
			return r
		end
	end
	return nil
end

-- OBJETS (GearService, GearBar.client, onglet GEAR du stand ITEMS).
-- Battes : en $, une par une. Stun = secondes où un monstre est assommé, Push = force sur les joueurs.
local function bat(name, art, cost, stun, push, bands, color, grip, accent)
	return { Name = name, Art = art, Cost = cost, Stun = stun, Push = push, Bands = bands, Color = color, Grip = grip, Accent = accent }
end
Config.Bats = {
	bat("Wooden Bat", "BatWood", 60000, 2, 70, 1, col(176, 120, 70), col(60, 44, 34), col(230, 205, 160)),
	bat("Steel Bat", "BatSteel", 4e6, 3, 110, 2, col(190, 200, 215), col(50, 90, 190), col(90, 110, 140)),
	bat("Plasma Bat", "BatPlasma", 4e8, 5, 150, 3, col(90, 235, 255), col(60, 40, 110), col(170, 90, 240)),
}
Config.Gear = {
	BatCooldown = 1.2, -- secondes entre deux coups
	BatRange = 14, -- studs (contre un monstre : en plus de son rayon d'attrape)
	BatHip = CFrame.new(-1.15, -0.1, 0) * CFrame.Angles(0, 0, math.rad(72)), -- batte portée à la hanche
	BatHand = CFrame.new(0, -0.3, 0) * CFrame.Angles(0, math.rad(90), 0), -- batte tenue dans la main droite
	PushUp = 30, -- poussée vers le haut du joueur repoussé
	PushImmune = 4, -- secondes où un joueur repoussé ne peut plus l'être
	PassOrder = { "Carpet", "Boots", "Hook" }, -- passes de l'onglet GEAR (Config.Shop.Passes)
	Carpet = { Speed = 1.35, Below = -3.2, Width = 5, Length = 8, Color = col(96, 46, 160), Accent = col(245, 195, 70) },
	Boots = { Color = col(235, 240, 250), Sole = col(90, 225, 245), Strap = col(60, 110, 220) },
	Hook = { Range = 110, Speed = 130, Cooldown = 6, Cone = 0.8, Arrive = 9 }, -- Cone : écart maximal avec le regard (cosinus)
	Shield = { Name = "Monster Shield", Art = "Shield", Robux = 25, ProductId = 3729999814 }, -- consommé quand un monstre attrape le joueur
}

-- COMBINAISONS (SuitService, ColdService) : achetées une par une, en $ ou en Robux.
-- Grace + FreezeTime = temps avant de geler hors du couloir ; Oxygen = bonus sur l'oxygène de l'œuf (0.1 = +10 %).
-- Color, Accent, Visor : couleurs du casque et du plastron portés sur l'avatar.
local function suit(name, art, grace, freeze, oxygen, cost, robux, color, accent, visor)
	return { Name = name, Art = art, Grace = grace, FreezeTime = freeze, Oxygen = oxygen, Cost = cost, Robux = robux, ProductId = 0, Color = color, Accent = accent, Visor = visor }
end
Config.Suits = {
	suit("Flight Suit", "Suit", Config.Cold.Grace, Config.Cold.FreezeTime, 0, 0, 0, col(205, 208, 220), col(120, 126, 145), col(90, 220, 240)),
	suit("Padded Suit", "SuitPadded", 4, 10, 0.10, 25000, 29, col(240, 130, 50), col(255, 232, 196), col(90, 225, 245)),
	suit("Thermal Suit", "SuitThermal", 6, 14, 0.20, 750000, 59, col(214, 56, 50), col(255, 205, 60), col(245, 190, 60)),
	suit("Arctic Suit", "SuitArctic", 8, 20, 0.35, 5e8, 99, col(226, 240, 255), col(70, 150, 240), col(110, 200, 255)),
	suit("Titan Suit", "SuitTitan", 11, 27, 0.50, 4e10, 149, col(78, 86, 106), col(240, 130, 40), col(245, 150, 50)),
	suit("Stellar Suit", "SuitStellar", 15, 35, 0.70, 6e12, 249, col(118, 66, 205), col(245, 195, 70), col(245, 200, 80)),
	suit("Void Suit", "SuitVoid", 20, 45, 1.00, 1e15, 399, col(34, 32, 52), col(80, 240, 230), col(70, 235, 225)),
}
-- Produits Robux des combinaisons (créés le 9 nov. sur Roblox, palier 2 à 7)
for tier, id in pairs({ [2] = 3729865909, [3] = 3729865920, [4] = 3729865929, [5] = 3729865939, [6] = 3729865950, [7] = 3729865968 }) do
	Config.Suits[tier].ProductId = id
end
function Config.Suit(tier: number?)
	return Config.Suits[math.clamp(tier or 1, 1, #Config.Suits)]
end

-- Skins de base (BaseSkinService, BaseSkinUI.client) : purement esthétiques.
-- Ring = anneau le plus lointain à avoir atteint pour le débloquer (1 = dès le départ) ; Robux / PassId = vendu comme passe.
-- Floor, Main (murets et annexe), Trim, Glass : couleurs ; sans couleur = celles d'origine de la base.
local function baseSkin(key, rarity, floor, main, trim, glass)
	return { Key = key, Name = key, Rarity = rarity, Floor = floor, Main = main, Trim = trim, Glass = glass }
end
Config.BaseSkins = {
	baseSkin("Station", 1),
	baseSkin("Nebula", 2, col(92, 62, 160), col(196, 168, 255), col(130, 84, 230), col(200, 150, 255)),
	baseSkin("Ocean", 3, col(44, 128, 186), col(196, 236, 255), col(24, 150, 216), col(130, 225, 255)),
	baseSkin("Jungle", 4, col(86, 158, 76), col(230, 242, 196), col(58, 128, 66), col(176, 240, 136)),
	baseSkin("Magma", 5, col(70, 44, 44), col(255, 156, 76), col(210, 66, 34), col(255, 150, 70)),
	baseSkin("Frost", 6, col(196, 232, 250), col(246, 252, 255), col(116, 194, 242), col(196, 242, 255)),
	baseSkin("Galaxy", 6, col(30, 24, 82), col(128, 76, 216), col(255, 124, 222), col(190, 130, 255)),
	baseSkin("Gold", 5, col(232, 180, 56), col(255, 238, 176), col(196, 134, 32), col(255, 226, 140)),
	baseSkin("Rainbow", 7, col(255, 110, 150), col(255, 236, 190), col(120, 230, 90), col(120, 220, 255)),
}
for i, n in ipairs({ 1, 2, 3, 4, 5, 6 }) do
	Config.BaseSkins[i].Ring = n
end
Config.BaseSkins[7].Robux, Config.BaseSkins[7].PassId = 199, 2074384534
Config.BaseSkins[8].Robux, Config.BaseSkins[8].PassId = 299, 2075536455
Config.BaseSkins[9].Robux, Config.BaseSkins[9].PassId = 399, 2074612468
Config.BaseSkins[9].Rainbow = true
Config.BaseSkinRainbowSpeed = 0.06 -- tours de la roue des couleurs par seconde
function Config.BaseSkin(key: string?)
	for _, s in ipairs(Config.BaseSkins) do
		if s.Key == key then
			return s
		end
	end
	return Config.BaseSkins[1]
end

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
-- Pas de plafond de niveau (15 nov., comme les jeux de référence : on progresse toujours un peu).
-- XP pour passer du niveau L au niveau L+1 : XPBase au niveau 1, puis + XPStep à chaque niveau ; tous les
-- XPEvery niveaux, ce pas est multiplié par XPStepGrowth. Avec 20 / 5 / 10 / 1,4 : 65 XP au niveau 10,
-- 3,4 K au niveau 100, 100 K au niveau 200, 2,9 M au niveau 300, 2,5 Md au niveau 500.
Config.Jetpack = {
	XPBase = 20,
	XPStep = 5,
	XPEvery = 10,
	XPStepGrowth = 1.4,
	FlightXP = 1, -- XP par seconde de vol réel (poussée ou plané, hors soufflerie)
	-- Paliers de jetpack : un modèle de plus en plus impressionnant (Assets.Jetpacks.<Model>) et une
	-- jauge de carburant de plus en plus stylée (Hud). Reach = portée d'un vol à ce niveau (studs, d'un
	-- bord à l'autre, en poussant tout le carburant) ; entre deux paliers elle monte petit à petit.
	-- Le vide entre l'anneau k-1 et l'anneau k fait 55 × 1,22^(k-2) studs : le palier k le franchit
	-- avec 15 % de marge (le palier 1 ne quitte pas l'anneau 1).
	-- Level : réglé avec tools/eco-sim.luau. Joueur qui passe 40 % de son temps en soufflerie : anneau 2
	-- vers 12 min, 3 vers 40 min, 4 vers 2 h, 5 vers 5 h, 6 vers 12 h, 7 vers 30 h (on franchit un vide
	-- un peu avant le niveau du palier, la portée montant entre deux paliers).
	Tiers = {
		{ Level = 1, Name = "Rusty Starter", Model = "Jet1", Reach = 44, Color = Color3.fromRGB(205, 130, 80) },
		{ Level = 18, Name = "Scout Booster", Model = "Jet2", Reach = 63, Color = Color3.fromRGB(90, 190, 255) },
		{ Level = 65, Name = "Comet Pack", Model = "Jet3", Reach = 77, Color = Color3.fromRGB(150, 235, 255) },
		{ Level = 120, Name = "Blaze Thruster", Model = "Jet4", Reach = 94, Color = Color3.fromRGB(255, 120, 40) },
		{ Level = 195, Name = "Nebula Wings", Model = "Jet5", Reach = 115, Color = Color3.fromRGB(190, 100, 255) },
		{ Level = 270, Name = "Rift Striker", Model = "Jet6", Reach = 140, Color = Color3.fromRGB(60, 240, 230) },
		{ Level = 362, Name = "Nova Titan", Model = "Jet7", Reach = 171, Color = Color3.fromRGB(255, 200, 60) },
		{ Level = 412, Name = "Supernova X", Model = "Jet8", Reach = 200, Color = Color3.fromRGB(255, 120, 220) },
		{ Level = 470, Name = "Storm Breaker", Model = "Jet9", Reach = 255, Color = Color3.fromRGB(255, 225, 90) },
		{ Level = 540, Name = "Gear Titan", Model = "Jet10", Reach = 310, Color = Color3.fromRGB(240, 170, 80) },
		{ Level = 610, Name = "Sugar Rush", Model = "Jet11", Reach = 380, Color = Color3.fromRGB(255, 130, 200) },
		{ Level = 690, Name = "Spore Drifter", Model = "Jet12", Reach = 460, Color = Color3.fromRGB(120, 240, 210) },
		{ Level = 780, Name = "Sun Idol", Model = "Jet13", Reach = 560, Color = Color3.fromRGB(255, 200, 80) },
		{ Level = 880, Name = "Wisp Rider", Model = "Jet14", Reach = 680, Color = Color3.fromRGB(120, 240, 220) },
	},
	TopLevel = 910, -- niveau où la portée et les vitesses cessent de monter (les niveaux, eux, continuent)
	MaxReach = 720, -- portée au niveau TopLevel
	-- Bonus à attraper dans la soufflerie (WindTunnelService, WindTunnel.client), revu le 19 nov. : toutes
	-- les Every secondes d'entraînement, un gros bouton rond (un doigt et « x2 XP ») apparaît pendant
	-- Offer secondes et traverse l'écran (il rebondit sur les bords, à Speed fois la hauteur d'écran par
	-- seconde) ; touché à temps, le prochain gain d'XP de la soufflerie (un par seconde) est multiplié
	-- par Mult, et le joueur brille en violet le temps de ce gain.
	-- Rester devant l'écran rapporte donc un peu plus que l'AFK pur (+20 % en les attrapant tous).
	Boost = { Every = 5, Offer = 3, Mult = 2, Speed = 0.28 },
	-- Soufflerie personnelle : chaque joueur a la sienne devant sa base. On l'achète (Breeze Tunnel),
	-- puis on l'améliore palier par palier ; XP gagnée par seconde dans le courant d'air, même AFK.
	-- Prix réglés avec tools/eco-sim.luau : la soufflerie n se paie à l'arrivée dans l'anneau n (trop chère
	-- avec les revenus de l'anneau d'avant, vite payée avec ceux du nouveau).
	TunnelRadius = 4.5,
	-- Caméra d'entraînement (WindTunnel.client, 30 nov.) : dès que le joueur flotte dans sa soufflerie, la caméra
	-- se rapproche un peu de lui et tourne lentement autour du tube, comme une petite cinématique. Un bouton
	-- EXIT (touche X, B à la manette) le repose devant le tube, là d'où il est entré ; marcher hors du courant
	-- marche toujours. Delay = secondes dans le courant avant qu'elle parte, Blend = secondes pour y glisser,
	-- Dist = distance à l'axe du tube (studs ; elle se rapproche si un mur gêne), Height = au-dessus du joueur,
	-- Speed = tour (radians/s : un tour en 26 s), Bob = léger va-et-vient vertical, ExitGap = studs devant le tube.
	TunnelCam = { Delay = 0.5, Blend = 1.1, Dist = 13, Height = 3, Speed = 0.24, Bob = 0.5, ExitGap = 5 },
	TunnelHeight = 20,
	TunnelOffset = Vector3.new(12, 0, 26), -- dans le repère du sol de la base : devant l'entrée ; le signe de x vient de l'attribut TunnelSide de la base (côté opposé à la machine)
	Tunnels = {
		{ Name = "Breeze Tunnel", Cost = 5000, XP = 2, Color = Color3.fromRGB(150, 235, 255) },
		{ Name = "Gale Tunnel", Cost = 150000, XP = 8, Color = Color3.fromRGB(90, 200, 255) },
		{ Name = "Storm Tunnel", Cost = 2e7, XP = 30, Color = Color3.fromRGB(255, 140, 60) },
		{ Name = "Cyclone Tunnel", Cost = 2e10, XP = 150, Color = Color3.fromRGB(190, 120, 255) },
		{ Name = "Hurricane Tunnel", Cost = 1.5e12, XP = 800, Color = Color3.fromRGB(255, 80, 120) },
		{ Name = "Tempest Tunnel", Cost = 4e14, XP = 5000, Color = Color3.fromRGB(60, 255, 220) },
		{ Name = "Supernova Vortex", Cost = 6e16, XP = 30000, Color = Color3.fromRGB(255, 220, 80) },
		{ Name = "Thunder Vortex", Cost = 1e20, XP = 200000, Color = Color3.fromRGB(190, 140, 255) }, -- anneau 9
		{ Name = "Clockwork Vortex", Cost = 6e21, XP = 1500000, Color = Color3.fromRGB(240, 170, 80) }, -- anneau 10
		{ Name = "Candy Vortex", Cost = 1.5e23, XP = 10000000, Color = Color3.fromRGB(255, 130, 200) }, -- anneau 11
		{ Name = "Spore Vortex", Cost = 3e24, XP = 70000000, Color = Color3.fromRGB(120, 240, 210) }, -- anneau 12
		{ Name = "Temple Vortex", Cost = 3e25, XP = 800000000, Color = Color3.fromRGB(255, 200, 80) }, -- anneau 13
		{ Name = "Phantom Vortex", Cost = 2.5e26, XP = 12000000000, Color = Color3.fromRGB(120, 240, 220) }, -- fin de partie (anneau 14)
	},
}

-- Table de la courbe d'XP, remplie au fur et à mesure : xpNeed[L] = XP du niveau L au niveau L+1,
-- xpTotal[L] = XP totale pour arriver au niveau L (xpTotal[1] = 0)
local xpNeed: { number } = {}
local xpTotal: { number } = { 0 }
local function fillXP(level: number)
	local j = Config.Jetpack
	for l = #xpNeed + 1, level do
		local step = j.XPStep * j.XPStepGrowth ^ ((l - 2) // j.XPEvery)
		xpNeed[l] = if l == 1 then j.XPBase else math.floor(xpNeed[l - 1] + step + 0.5)
		xpTotal[l + 1] = xpTotal[l] + xpNeed[l]
	end
end

-- XP pour passer au niveau suivant
function Config.JetpackXPNeed(level: number): number
	level = math.max(1, math.floor(level))
	fillXP(level)
	return xpNeed[level]
end

-- XP totale pour arriver à ce niveau
function Config.JetpackXPTotal(level: number): number
	level = math.max(1, math.floor(level))
	fillXP(level)
	return xpTotal[level]
end

-- Niveau atteint avec cette XP totale, XP déjà faite dans ce niveau, XP du niveau
function Config.JetpackLevel(totalXP: number): (number, number, number)
	-- la table grandit jusqu'à dépasser l'XP du joueur, puis recherche par dichotomie
	totalXP = math.clamp(totalXP, 0, 1e300)
	while xpTotal[#xpTotal] <= totalXP do
		fillXP(#xpNeed + 50)
	end
	local lo, hi = 1, #xpTotal
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if xpTotal[mid] <= totalXP then
			lo = mid
		else
			hi = mid
		end
	end
	return lo, totalXP - xpTotal[lo], xpNeed[lo]
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

-- La roche que le joueur rapporte à sa base, tenue à deux mains (CarryService)
Config.CarriedRock = {
	Size = 3, -- plus grande dimension, en studs
	HandDelay = 0.9, -- secondes après le forage, le temps que l'œuf arrive jusqu'au joueur
	StudTile = 1, -- taille d'une tuile de picots sur la roche, en studs
}

-- Taille d'une tuile de picots sur les astéroïdes à forer, en studs (comme sur le vaisseau)
Config.AsteroidStudTile = 2

function Config.DrillPower(tier: number): number
	local d = Config.Drills[math.clamp(tier, 1, #Config.Drills)]
	return d.Power
end

-- Un seul œuf par voyage : on fore un œuf, on le ramène à sa base, on repart (pas d'amélioration de soute)
Config.CargoMax = 1
function Config.CargoSlots(_level: number?): number
	return Config.CargoMax
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

-- Avancée dans les paliers : 1 au palier 1, 2,5 à mi-chemin entre les paliers 2 et 3..., nombre de
-- paliers + 1 au niveau TopLevel et au-delà. Les vitesses et la portée en découlent.
function Config.JetProgress(level: number): number
	local tiers = Config.Jetpack.Tiers
	local i, t = Config.JetpackTier(level)
	local nextLevel = if tiers[i + 1] then tiers[i + 1].Level else Config.Jetpack.TopLevel
	return i + math.clamp(((level or 1) - t.Level) / math.max(1, nextLevel - t.Level), 0, 1)
end

-- Multiplicateur de vitesse selon le niveau du jetpack (niveau 1 = ×1), et vitesses qui en découlent
function Config.Speed(level: number): number
	return 1 + Config.Movement.PerTier * (Config.JetProgress(level) - 1)
end
function Config.GroundSpeed(level: number): number
	return Config.Movement.Walk * Config.Speed(level)
end
function Config.AirSpeed(level: number): number
	return Config.Movement.Air + Config.Movement.AirPerTier * (Config.JetProgress(level) - 1)
end

-- Portée d'un vol à ce niveau : elle monte en ligne droite d'un palier à l'autre
function Config.JetpackReach(level: number): number
	local tiers = Config.Jetpack.Tiers
	local i, t = Config.JetpackTier(level)
	local nextReach = if tiers[i + 1] then tiers[i + 1].Reach else Config.Jetpack.MaxReach
	return t.Reach + (nextReach - t.Reach) * (Config.JetProgress(level) - i)
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
	return Config.StepCost(u.Base, u.Growth, level, 0)
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
	ChaseFade = 0.35, -- la musique de poursuite arrive d'un coup
	ChaseRush = 0.1, -- elle accélère jusqu'à +10 % quand le monstre est tout près (attribut MonsterNear)
	Music = {
		-- cour et bases : « Gymnopedie No. 1 » de Satie, piano seul, calme (2 min 32, en boucle) ; avant le
		-- 28 nov. : « Explore », électro (1842185080). Autres enregistrements de la même pièce : 1837474061, 1842971981
		Base = 9045766377,
		Belt = 1840200807, -- anneaux et couloir : « Futureworld », science-fiction
		Chase = 100817604765534, -- poursuite par un monstre : « Dangerous Pursuit »
	},
	-- Niveau propre à une musique (x MusicVolume) : le piano est enregistré deux fois plus doucement que
	-- les autres (niveau efficace mesuré : 0,04 contre 0,085 à 0,12)
	MusicGain = { Base = 1.6 },
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
		-- 19 nov. : sons courts et plus doux (mesurés à l'AudioAnalyzer). Avant : une fanfare de 6,5 s pour
		-- chaque créature rare et chaque annonce, et un jingle de 2,9 s à chaque niveau de jetpack.
		HatchRare = { Id = 2609981431, Volume = 0.8 }, -- épique et au-delà, annonces, relique : scintillement de 0,9 s
		-- explosions de l'éclatement (Pro Sound Effects, mesurées à l'AudioAnalyzer), posées en couches selon la
		-- rareté de l'œuf : voir HatchBoom plus bas
		Boom = { Id = 9114224354, Volume = 0.55 }, -- explosion sourde qui gronde 7 s (niveau efficace 0,24 au début)
		Blast = { Id = 9126102254, Volume = 0.28 }, -- déflagration avec une traîne qui chante 5,7 s (niveau 0,5)
		-- nouveau modèle de jetpack, mutation : petit air montant de 0,7 s (les niveaux ne sonnent plus)
		LevelUp = { Id = 105193542038988, Volume = 0.3 },
		-- cadeau, quête ou achat réclamé : un petit « réussi » de 0,7 s (15 nov. : avant, la même fanfare de
		-- 8 s que l'éclosion rare, pénible à chaque réclamation). Volume réglé à l'oreille restant à faire.
		Reward = { Id = 91735091370012, Volume = 0.5 },
		-- jetpack
		JetStart = { Id = 104612149748953, Volume = 0.3 }, -- allumage
		JetStop = { Id = 87598090301048, Volume = 0.12 }, -- extinction
		-- gel et événements
		Warning = { Id = 80890994815283, Volume = 0.3 },
		Freeze = { Id = 9125611419, Volume = 0.6 },
		Thaw = { Id = 96795857757261, Volume = 0.3, Pitch = 1.4 },
		-- monstres
		MonsterRoar = { Id = 9113980319, Volume = 1.8 }, -- réveil
		-- alarme du joueur poursuivi : une note de klaxon de science-fiction (Pro Sound Effects), jouée deux fois
		-- coup sur coup (« Wang ! Wang ! », Config.Monsters.Alarm). Niveau efficace de l'enregistrement : 0,09.
		ChaseAlarm = { Id = 9118805665, Volume = 2.2 },
		MonsterWarn = { Id = 9118805486, Volume = 1.5 }, -- trop de bruit : il remue
		MonsterCatch = { Id = 9118612665, Volume = 1, Pitch = 0.7 }, -- il t'attrape
		Escape = { Id = 71587723216424, Volume = 0.6 }, -- il abandonne : petit « réussi » de 0,9 s
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
	-- Explosion à l'éclatement de l'œuf, par rareté (Audio.client), en plus du son d'éclosion. Plus l'œuf est
	-- rare, plus elle est spectaculaire SANS être plus forte : elle devient plus grave (Pitch plus bas), dure plus
	-- longtemps (Cut plus tard), gagne une déflagration (Blast) puis des échos qui roulent derrière elle (Delay).
	-- Une Commune n'a que son petit « pop ». Chaque couche : Sfx = le son, Delay = secondes après l'éclatement,
	-- Pitch, Volume (× celui du son), Cut = secondes avant de la couper en fondu (BoomFade).
	HatchBoom = {
		[1] = {},
		[2] = { { Sfx = "Boom", Pitch = 1.6, Volume = 0.55, Cut = 0.45 } },
		[3] = { { Sfx = "Boom", Pitch = 1.35, Volume = 0.7, Cut = 0.8 } },
		[4] = { { Sfx = "Boom", Pitch = 1.15, Volume = 0.8, Cut = 1.3 } },
		[5] = {
			{ Sfx = "Boom", Pitch = 1, Volume = 0.85, Cut = 2 },
			{ Sfx = "Blast", Pitch = 1.25, Volume = 0.6, Cut = 0.9 },
		},
		[6] = {
			{ Sfx = "Boom", Pitch = 0.85, Volume = 0.9, Cut = 3 },
			{ Sfx = "Blast", Pitch = 1, Volume = 0.8, Cut = 1.8 },
			{ Sfx = "Boom", Delay = 0.45, Pitch = 0.65, Volume = 0.4, Cut = 1.6 },
		},
		[7] = {
			{ Sfx = "Boom", Pitch = 0.7, Volume = 0.9, Cut = 4.5 },
			{ Sfx = "Blast", Pitch = 0.8, Volume = 0.9, Cut = 3.2 },
			{ Sfx = "Boom", Delay = 0.4, Pitch = 0.55, Volume = 0.45, Cut = 2 },
			{ Sfx = "Boom", Delay = 0.95, Pitch = 0.45, Volume = 0.3, Cut = 2.2 },
		},
	},
	BoomFade = 0.5,
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
	{ -- 8. Star Reef : bulles qui montent et plancton lumineux
		Title = "STAR REEF",
		Icon = "Star",
		Fog = rgb(12, 46, 58), -- couleur du brouillard lointain
		Clouds = { rgb(110, 240, 225), rgb(255, 140, 130) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(205, 245, 240),
		Saturation = 0.25,
		Outdoor = rgb(120, 190, 190),
		Particles = {
			layer("Glow", rgb(210, 255, 250), rgb(140, 235, 230), { 0.35, 0.5 }, 45, { 5, 8 }, { 0.6, 1.4 }, Vector3.new(0, 0.9, 0), { 0.25, 1 }, 0.6),
			layer("Sparkle", rgb(120, 255, 235), rgb(255, 150, 140), { 0.5, 0.3 }, 14, { 3, 5 }, { 0.1, 0.5 }, Vector3.zero, { 0, 1 }, 1, 40),
			layer("Glow", rgb(90, 230, 220), rgb(255, 140, 130), { 7, 11 }, 4, { 6, 9 }, { 0.1, 0.4 }, Vector3.zero, { 0.88, 1 }, 0.8),
		},
	},
	{ -- 9. Storm Halo : étincelles électriques et éclairs dans des nuages violets
		Title = "STORM HALO",
		Icon = "Lightning",
		Fog = rgb(36, 24, 70), -- couleur du brouillard lointain
		Clouds = { rgb(150, 110, 255), rgb(255, 225, 90) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(230, 220, 255),
		Saturation = 0.25,
		Outdoor = rgb(150, 130, 210),
		Particles = {
			layer("Shard", rgb(255, 240, 120), rgb(255, 255, 255), { 0.45, 0.2 }, 30, { 0.3, 0.8 }, { 0.5, 2 }, Vector3.zero, { 0, 1 }, 1, 120),
			layer("Sparkle", rgb(190, 160, 255), rgb(255, 235, 120), { 0.5, 0.25 }, 18, { 2, 4 }, { 0.2, 0.8 }, Vector3.zero, { 0, 1 }, 1, 60),
			layer("Glow", rgb(150, 110, 255), rgb(255, 220, 100), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.9),
		},
	},
	{ -- 10. Clockwork Belt : étincelles de laiton et bouffées de vapeur turquoise
		Title = "CLOCKWORK BELT",
		Icon = "Gear",
		Fog = rgb(20, 40, 44), -- couleur du brouillard lointain
		Clouds = { rgb(90, 220, 200), rgb(240, 170, 80) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(245, 235, 215),
		Saturation = 0.2,
		Outdoor = rgb(170, 160, 140),
		Particles = {
			layer("Shard", rgb(255, 200, 100), rgb(255, 245, 210), { 0.35, 0.15 }, 22, { 0.4, 0.9 }, { 1, 3 }, Vector3.new(0, -1.5, 0), { 0, 1 }, 1, 200),
			layer("Glow", rgb(200, 255, 245), rgb(110, 230, 210), { 1.2, 2.4 }, 14, { 3, 5 }, { 0.3, 0.8 }, Vector3.new(0, 0.6, 0), { 0.55, 1 }, 0.5),
			layer("Glow", rgb(90, 220, 200), rgb(240, 170, 80), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.8),
		},
	},
	{ -- 11. Candy Comet : pluie de vermicelles colorés et poudre de sucre rose et menthe
		Title = "CANDY COMET",
		Icon = "Comet",
		Fog = rgb(52, 26, 50), -- couleur du brouillard lointain
		Clouds = { rgb(255, 140, 200), rgb(140, 235, 220) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(255, 238, 246),
		Saturation = 0.25,
		Outdoor = rgb(190, 160, 175),
		Particles = {
			layer("Shard", rgb(255, 120, 190), rgb(130, 230, 255), { 0.35, 0.15 }, 22, { 0.4, 0.9 }, { 1, 3 }, Vector3.new(0, -1.5, 0), { 0, 1 }, 1, 200),
			layer("Glow", rgb(255, 245, 250), rgb(255, 170, 215), { 1.2, 2.4 }, 14, { 3, 5 }, { 0.3, 0.8 }, Vector3.new(0, 0.6, 0), { 0.55, 1 }, 0.5),
			layer("Glow", rgb(255, 140, 200), rgb(140, 235, 220), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.8),
		},
	},
	{ -- 12. Mushroom Moon : spores lumineuses qui montent doucement, lueurs turquoise et orangées
		Title = "MUSHROOM MOON",
		Icon = "Sparkles",
		Fog = rgb(24, 20, 44), -- couleur du brouillard lointain
		Clouds = { rgb(110, 240, 210), rgb(190, 120, 255) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(235, 240, 255),
		Saturation = 0.25,
		Outdoor = rgb(150, 150, 180),
		Particles = {
			layer("Glow", rgb(140, 255, 220), rgb(255, 200, 120), { 0.5, 0.2 }, 22, { 3, 6 }, { 0.3, 0.8 }, Vector3.new(0, 0.8, 0), { 0.2, 1 }, 1, 200),
			layer("Glow", rgb(200, 150, 255), rgb(120, 240, 210), { 1.2, 2.4 }, 14, { 3, 5 }, { 0.3, 0.8 }, Vector3.new(0, 0.6, 0), { 0.55, 1 }, 0.5),
			layer("Glow", rgb(110, 240, 210), rgb(190, 120, 255), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.8),
		},
	},
	{ -- 13. Jade Temple : poussière d'or qui tombe, éclats de jade et lueurs de soleil couchant
		Title = "JADE TEMPLE",
		Icon = "Supernova",
		Fog = rgb(30, 36, 24), -- couleur du brouillard lointain
		Clouds = { rgb(90, 220, 150), rgb(255, 200, 90) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(255, 245, 225),
		Saturation = 0.2,
		Outdoor = rgb(170, 160, 130),
		Particles = {
			layer("Shard", rgb(255, 215, 110), rgb(255, 245, 200), { 0.35, 0.15 }, 22, { 0.4, 0.9 }, { 1, 3 }, Vector3.new(0, -1.5, 0), { 0, 1 }, 1, 200),
			layer("Glow", rgb(120, 240, 170), rgb(60, 190, 130), { 1.2, 2.4 }, 14, { 3, 5 }, { 0.3, 0.8 }, Vector3.new(0, 0.6, 0), { 0.55, 1 }, 0.5),
			layer("Glow", rgb(90, 220, 150), rgb(255, 200, 90), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.8),
		},
	},
	{ -- 14. Phantom Mist : feux follets turquoise qui montent, brume pâle et lueurs orangées de citrouille
		Title = "PHANTOM MIST",
		Icon = "Star",
		Fog = rgb(18, 30, 36), -- couleur du brouillard lointain
		Clouds = { rgb(110, 240, 220), rgb(255, 150, 60) }, -- nuages du champ (WorldBuilder)
		Tint = rgb(225, 245, 245),
		Saturation = 0.15,
		Outdoor = rgb(140, 160, 170),
		Particles = {
			layer("Glow", rgb(140, 255, 230), rgb(200, 255, 245), { 0.5, 0.2 }, 22, { 3, 6 }, { 0.3, 0.8 }, Vector3.new(0, 0.8, 0), { 0.2, 1 }, 1, 200),
			layer("Glow", rgb(220, 240, 255), rgb(150, 220, 230), { 1.6, 3 }, 14, { 3, 5 }, { 0.2, 0.6 }, Vector3.new(0, 0.3, 0), { 0.6, 1 }, 0.5),
			layer("Glow", rgb(110, 240, 220), rgb(255, 150, 60), { 8, 12 }, 5, { 5, 8 }, { 0.1, 0.4 }, Vector3.zero, { 0.86, 1 }, 0.8),
		},
	},
}

-- CRÉATURES (docs/Mecaniques.md §9) ----------------------------------------------
-- 6 espèces par anneau, une par rareté (fenêtre glissante) : anneaux 1 à 4 de Common à Mythic,
-- anneaux 5 à 7 de Uncommon à Cosmic. Une espèce = (anneau, rareté), clé « anneau:rareté ».
-- Size = échelle min/max, Weight = kg min/max (tirés au hasard à l'obtention).
-- Art = portrait de l'index ("" tant qu'il n'est pas dessiné : l'index montre un œuf mystère).
-- Portraits de l'anneau 8 (rendus Blender, à remplir quand ils sont envoyés sur Roblox)
-- Portraits de l'anneau 9 (même chose)
-- Portraits de l'anneau 10 (même chose)
-- Portraits de l'anneau 11 (même chose)
-- Portraits de l'anneau 12 (même chose)
-- Portraits de l'anneau 13 (même chose)
-- Portraits de l'anneau 14 (même chose)
local ART_R14 = { "rbxassetid://132047384144913", "rbxassetid://90219882408102", "rbxassetid://92902962109031", "rbxassetid://120495110930838", "rbxassetid://85303059683915", "rbxassetid://128885510147851" }
local ART_R13 = { "rbxassetid://95943150463525", "rbxassetid://116359762015268", "rbxassetid://134577077562821", "rbxassetid://108681301498276", "rbxassetid://76004535046896", "rbxassetid://90753684144093" }
local ART_R12 = { "rbxassetid://75101977686374", "rbxassetid://107715632682468", "rbxassetid://121739539800181", "rbxassetid://125011502377456", "rbxassetid://87095633395322", "rbxassetid://101907040751364" }
local ART_R11 = { "rbxassetid://98744207573098", "rbxassetid://80681366208457", "rbxassetid://136343022081611", "rbxassetid://113757907420787", "rbxassetid://87566965179068", "rbxassetid://89869124643776" }
local ART_R10 = { "rbxassetid://84790821701420", "rbxassetid://130309759486439", "rbxassetid://130770536551612", "rbxassetid://125348312363442", "rbxassetid://117725953165161", "rbxassetid://90256677842445" }
local ART_R9 = { "rbxassetid://72182875240147", "rbxassetid://111568020541594", "rbxassetid://72532651453041", "rbxassetid://102020727143175", "rbxassetid://136462327382734", "rbxassetid://132837422445999" }
local ART_R8 = { "rbxassetid://92057898992099", "rbxassetid://75232846627348", "rbxassetid://109346830247682", "rbxassetid://113502786478445", "rbxassetid://105924569565355", "rbxassetid://130244536757928" }
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
	{ -- 8. Star Reef
		creature("Bubble Guppy", "a chubby turquoise baby fish that carries a big bubble", { 0.8, 1.3 }, { 1, 3 }, ART_R8[1]),
		creature("Coral Crab", "a pink crab with a coral garden growing on its shell", { 0.8, 1.4 }, { 3, 8 }, ART_R8[2]),
		creature("Lantern Jelly", "a glowing jellyfish with a lantern light inside its dome", { 0.9, 1.5 }, { 4, 10 }, ART_R8[3]),
		creature("Tide Seahorse", "a majestic seahorse in golden armor with coral antlers", { 1, 1.6 }, { 20, 60 }, ART_R8[4]),
		creature("Abyss Shark", "a deep-sea shark with glowing eyes and crystal fins", { 1, 1.7 }, { 80, 200 }, ART_R8[5]),
		creature("Star Leviathan", "a colossal sea serpent queen with a coral crown and fins full of stars", { 1.1, 1.9 }, { 250, 600 }, ART_R8[6]),
	},
	{ -- 9. Storm Halo
		creature("Zap Pup", "a fluffy yellow puppy with a lightning-bolt tail and purple ears", { 0.8, 1.3 }, { 2, 6 }, ART_R9[1]),
		creature("Volt Beetle", "a beetle whose shell is a glowing battery with lightning marks", { 0.8, 1.4 }, { 1, 4 }, ART_R9[2]),
		creature("Thunder Owl", "an owl with storm-cloud wings and glowing yellow eyes", { 0.9, 1.5 }, { 3, 8 }, ART_R9[3]),
		creature("Storm Ram", "a mighty ram with thundercloud wool and lightning horns", { 1, 1.6 }, { 60, 150 }, ART_R9[4]),
		creature("Plasma Tiger", "a powerful tiger with glowing plasma stripes and electric claws", { 1, 1.7 }, { 120, 300 }, ART_R9[5]),
		creature("Tempest Dragon", "a colossal storm dragon with lightning wings and a crown of thunderclouds", { 1.1, 1.9 }, { 300, 700 }, ART_R9[6]),
	},
	{ -- 10. Clockwork Belt
		creature("Cog Mouse", "a tiny brass mouse with gear ears and a wind-up key on its back", { 0.8, 1.3 }, { 1, 3 }, ART_R10[1]),
		creature("Wind-Up Penguin", "a round tin penguin with a big wind-up key and copper rivets", { 0.8, 1.4 }, { 2, 6 }, ART_R10[2]),
		creature("Clockwork Fox", "a sleek copper fox with a clock face on its chest and gear tail", { 0.9, 1.5 }, { 3, 8 }, ART_R10[3]),
		creature("Steam Rhino", "a mighty iron rhino with a piston horn and steam chimneys", { 1, 1.6 }, { 150, 400 }, ART_R10[4]),
		creature("Mecha Raptor", "a fierce chrome raptor with glowing turquoise joints and gear claws", { 1, 1.7 }, { 80, 200 }, ART_R10[5]),
		creature("Brass Sky Whale", "a colossal clockwork whale with gear fins, a brass shell and steam chimneys", { 1.1, 1.9 }, { 400, 900 }, ART_R10[6]),
	},
	{ -- 11. Candy Comet
		creature("Gummy Cub", "a tiny bouncy red gummy bear cub with a sugar-crystal tummy", { 0.8, 1.3 }, { 1, 3 }, ART_R11[1]),
		creature("Marshmallow Bunny", "a fluffy marshmallow bunny with pink candy ears and a gumdrop nose", { 0.8, 1.4 }, { 2, 6 }, ART_R11[2]),
		creature("Lollipop Snail", "a happy snail carrying a giant swirl lollipop as its shell", { 0.9, 1.5 }, { 3, 8 }, ART_R11[3]),
		creature("Donut Turtle", "a sturdy turtle whose shell is a frosted donut covered in sprinkles", { 1, 1.6 }, { 150, 400 }, ART_R11[4]),
		creature("Licorice Panther", "a sleek black licorice panther with candy-cane claws and mint eyes", { 1, 1.7 }, { 80, 200 }, ART_R11[5]),
		creature("Cotton Candy Unicorn", "a colossal winged unicorn with a cotton-candy mane and a candy-cane horn", { 1.1, 1.9 }, { 400, 900 }, ART_R11[6]),
	},
	{ -- 12. Mushroom Moon
		creature("Mushroom Hedgehog", "a tiny round hedgehog whose spikes are little glowing mushrooms", { 0.8, 1.3 }, { 1, 3 }, ART_R12[1]),
		creature("Toadstool Frog", "a chubby green frog wearing a big red spotted toadstool cap", { 0.8, 1.4 }, { 2, 6 }, ART_R12[2]),
		creature("Glowcap Moth", "a fluffy moth with glowing mushroom-patterned wings and feathery antennae", { 0.9, 1.5 }, { 3, 8 }, ART_R12[3]),
		creature("Moss Bear", "a huge gentle bear covered in moss with mushrooms growing on its back", { 1, 1.6 }, { 150, 400 }, ART_R12[4]),
		creature("Fungal Stag", "a majestic stag whose great antlers are made of glowing mushrooms", { 1, 1.7 }, { 80, 200 }, ART_R12[5]),
		creature("Mushroom Mammoth", "a colossal mammoth carrying a glowing mushroom forest on its back", { 1.1, 1.9 }, { 400, 900 }, ART_R12[6]),
	},
	{ -- 13. Jade Temple
		creature("Jade Monkey", "a tiny playful monkey carved from green jade with golden bracelets", { 0.8, 1.3 }, { 1, 3 }, ART_R13[1]),
		creature("Golden Scarab", "a round scarab beetle with a shiny gold shell and turquoise gems", { 0.8, 1.4 }, { 2, 6 }, ART_R13[2]),
		creature("Sphinx Cat", "an elegant cat wearing a striped golden headdress and a jade collar", { 0.9, 1.5 }, { 3, 8 }, ART_R13[3]),
		creature("Temple Lion", "a mighty stone guardian lion with a golden mane and jade eyes", { 1, 1.6 }, { 150, 400 }, ART_R13[4]),
		creature("Feathered Serpent", "a long jade serpent with a crown of colorful feathers and golden wings", { 1, 1.7 }, { 80, 200 }, ART_R13[5]),
		creature("Sun Condor", "a colossal golden condor with a blazing sun crown and jade-tipped wings", { 1.1, 1.9 }, { 400, 900 }, ART_R13[6]),
	},
	{ -- 14. Phantom Mist
		creature("Boo Pup", "a tiny floaty ghost puppy with a wispy tail and a happy tongue", { 0.8, 1.3 }, { 1, 3 }, ART_R14[1]),
		creature("Pumpkin Kitty", "a little black cat curled up inside a smiling carved pumpkin", { 0.8, 1.4 }, { 2, 6 }, ART_R14[2]),
		creature("Lantern Squid", "a friendly ghostly squid carrying little glowing lanterns on its tentacles", { 0.9, 1.5 }, { 3, 8 }, ART_R14[3]),
		creature("Phantom Stallion", "a proud ghost horse with a flowing turquoise spirit-flame mane", { 1, 1.6 }, { 150, 400 }, ART_R14[4]),
		creature("Spirit Wolf", "a great glowing spirit wolf made of mist with lantern-light eyes", { 1, 1.7 }, { 80, 200 }, ART_R14[5]),
		creature("Lantern Wyvern", "a colossal ghostly wyvern with tattered misty wings and lanterns hanging from its horns", { 1.1, 1.9 }, { 400, 900 }, ART_R14[6]),
	},
}

-- Rareté de la n-ième espèce d'un anneau (fenêtre glissante), et l'inverse : rang (1 à 6) d'une rareté
function Config.CreatureRarity(ring: number, slot: number): number
	return if ring >= Config.CosmicMinRing then slot + 1 else slot
end
function Config.CreatureSlot(ring: number, rarity: number): number
	return if ring >= Config.CosmicMinRing then rarity - 1 else rarity
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
	-- Images de la boutique (25 nov., tools/store-icons/v2 ; sources dans references/boutique) : fond et cadre
	-- doré du bandeau vedette, emblème du Starter Pack, médaillon rond de chaque passe (clé = Key du passe)
	Art = {
		FeaturedBg = "rbxassetid://103058098460246",
		FrameCorner = "rbxassetid://99626669275357",
		FrameBar = "rbxassetid://106664825296818",
		StarterEmblem = "rbxassetid://101777622688291",
		JetXP2x = "rbxassetid://88022049620737",
		TurboJetpack = "rbxassetid://113304576331884",
		FastHatch = "rbxassetid://77144823768178",
		Money2x = "rbxassetid://108125342318757",
		BaseSlots = "rbxassetid://106620438572120",
		VIP = "rbxassetid://87389795029281",
	},
	Featured = {
		Name = "Starter Pack",
		Text = "Big money pack + x2 Luck + x2 Money potions",
		Art = "Money4",
		PackBase = 225000, -- comme le 3e paquet d'argent
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
		{ Key = "Carpet", Name = "Flying Carpet", Text = "Fly free and fast in the corridor", Art = "Carpet", Id = 2074924627, Price = 399 },
		{ Key = "Boots", Name = "Space Boots", Text = "Walk on empty space in the corridor", Art = "Boots", Id = 2074858611, Price = 299 },
		{ Key = "Hook", Name = "Grappling Hook", Text = "Pull yourself to an asteroid", Art = "Hook", Id = 2075482605, Price = 199 },
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
	-- Paquets d'argent : montant = Base × Config.Hatch.RingIncome de l'anneau le plus loin débloqué,
	-- pour qu'un paquet reste intéressant à toutes les étapes du jeu. × 5 le 15 nov., comme les prix en $ :
	-- un paquet achète la même chose qu'avant.
	MoneyPacks = {
		-- Name : nom affiché sur la carte ; Tag, TagColor : ruban penché (les trois plus gros paquets)
		{ Name = "Small Pack", Art = "Money1", Base = 30000, Id = 3729246128, Price = 19 },
		{ Name = "Medium Pack", Art = "Money2", Base = 100000, Id = 3729246160, Price = 49 },
		{ Name = "Large Pack", Art = "Money3", Base = 225000, Id = 3729246196, Price = 99, Tag = "GOOD VALUE", TagColor = "Blue" },
		{ Name = "Huge Pack", Art = "Money4", Base = 600000, Id = 3729246217, Price = 249, Tag = "GREAT VALUE", TagColor = "Orange" },
		{ Name = "Mega Pack", Art = "Money5", Base = 1300000, Id = 3729246247, Price = 499, Tag = "BEST VALUE!", TagColor = "Red" },
	},
}

function Config.MoneyPackAmount(base: number, ring: number): number
	local incomes = Config.Hatch.RingIncome
	return base * incomes[math.clamp(ring, 1, #incomes)]
end

-- ŒUFS ------------------------------------------------------------------------
-- Chaque anneau a 6 œufs, indexés par rareté (anneaux 1-4 : Common -> Mythic ; anneaux 5-7 :
-- Uncommon -> Cosmic). Modèles : ReplicatedStorage.Assets.Eggs.R<anneau>_T<rareté>.
-- Ce qui sort d'un astéroïde dépend de son type (Config.RockTypes, Config.RockChances) : il n'y a plus
-- de chance par œuf (15 nov.).
local function egg(name: string)
	return { Name = name }
end
Config.Eggs = {
	{ -- 1. Dust Belt
		[1] = egg("Dusty"),
		[2] = egg("Pebble"),
		[3] = egg("Geode"),
		[4] = egg("Sandstorm"),
		[5] = egg("Desert King"),
		[6] = egg("Stardust"),
	},
	{ -- 2. Ice Ring
		[1] = egg("Frost"),
		[2] = egg("Snowball"),
		[3] = egg("Glacier"),
		[4] = egg("Blizzard"),
		[5] = egg("Frost King"),
		[6] = egg("Aurora"),
	},
	{ -- 3. Magma Field
		[1] = egg("Ember"),
		[2] = egg("Cinder"),
		[3] = egg("Magma"),
		[4] = egg("Inferno"),
		[5] = egg("Phoenix"),
		[6] = egg("Dragonheart"),
	},
	{ -- 4. Nebula
		[1] = egg("Haze"),
		[2] = egg("Moon"),
		[3] = egg("Ringed"),
		[4] = egg("Nova"),
		[5] = egg("Galaxy"),
		[6] = egg("Supernova"),
	},
	{ -- 5. Devourer Belt
		[2] = egg("Maw"),
		[3] = egg("Tentacle"),
		[4] = egg("Eye"),
		[5] = egg("Void Fang"),
		[6] = egg("Abyss"),
		[7] = egg("Devourer"),
	},
	{ -- 6. The Rift
		[2] = egg("Shard"),
		[3] = egg("Portal"),
		[4] = egg("Prism"),
		[5] = egg("Rift Warden"),
		[6] = egg("Paradox"),
		[7] = egg("Singularity"),
	},
	{ -- 7. The Nest
		[2] = egg("Twig"),
		[3] = egg("Feather"),
		[4] = egg("Golden"),
		[5] = egg("Mother"),
		[6] = egg("Celestial"),
		[7] = egg("Cosmic"),
	},
	{ -- 8. Star Reef
		[2] = egg("Bubble"),
		[3] = egg("Shell"),
		[4] = egg("Pearl"),
		[5] = egg("Tide"),
		[6] = egg("Abyss"),
		[7] = egg("Leviathan"),
	},
	{ -- 9. Storm Halo
		[2] = egg("Spark"),
		[3] = egg("Static"),
		[4] = egg("Volt"),
		[5] = egg("Thunder"),
		[6] = egg("Plasma"),
		[7] = egg("Tempest"),
	},
	{ -- 10. Clockwork Belt
		[2] = egg("Cog"),
		[3] = egg("Spring"),
		[4] = egg("Bolt"),
		[5] = egg("Piston"),
		[6] = egg("Steam"),
		[7] = egg("Titan"),
	},
	{ -- 11. Candy Comet
		[2] = egg("Gummy"),
		[3] = egg("Sprinkle"),
		[4] = egg("Swirl"),
		[5] = egg("Frosted"),
		[6] = egg("Cocoa"),
		[7] = egg("Sugarplum"),
	},
	{ -- 12. Mushroom Moon
		[2] = egg("Spore"),
		[3] = egg("Moss"),
		[4] = egg("Toadstool"),
		[5] = egg("Glowcap"),
		[6] = egg("Mycelium"),
		[7] = egg("Moonshroom"),
	},
	{ -- 13. Jade Temple
		[2] = egg("Jade"),
		[3] = egg("Idol"),
		[4] = egg("Scarab"),
		[5] = egg("Sunstone"),
		[6] = egg("Serpent"),
		[7] = egg("Temple"),
	},
	{ -- 14. Phantom Mist
		[2] = egg("Boo"),
		[3] = egg("Candle"),
		[4] = egg("Lantern"),
		[5] = egg("Pumpkin"),
		[6] = egg("Wisp"),
		[7] = egg("Phantom"),
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
	-- (raccourcis le 15 nov. : les œufs des deux derniers rangs d'un anneau sont maintenant courants)
	Time = { 20, 40, 75, 120, 200, 300, 480 },
	-- Œufs en incubation + créatures posées en même temps dans une base
	Slots = 10,
	-- Hauteur du corps de l'œuf posé (studs) selon la rareté : les rares sont plus gros
	EggHeight = { 2.4, 2.7, 3.0, 3.4, 3.9, 4.5, 5.2 },
	-- Tutoriel : le premier œuf éclot en 6 s, créature de taille normale
	FirstTime = 6,
	FirstSize = 1,
	-- Place occupée par un œuf posé puis par sa créature (rayon en studs, selon la rareté) :
	-- deux objets posés ne se touchent pas, et les créatures rares, plus grandes, prennent plus de place
	-- Depuis le 8 nov., seuls les œufs se gênent : les créatures, immenses, peuvent se chevaucher et
	-- dépasser de la base (c'est le genre : petite base, créatures géantes). Rayon ≈ la largeur de l'œuf.
	Footprint = { 1.6, 1.7, 1.8, 2.0, 2.3, 2.6, 3.0 },
	Margin = 2.0, -- marge le long des murs (en plus de la moitié de la place occupée)
	-- Zone interdite autour du point d'apparition (rayon en studs) ; la machine est hors de la base
	KeepOut = { Spawn = 4, PenButton = 3.5 }, -- PenButton : bouton d'agrandissement de l'enclos
	-- Revenu d'une créature en $/s = SlotIncome[rang dans l'anneau] × RingIncome[anneau] × taille²
	-- (Config.PetSizes : de ×1 pour une taille normale à ×9 pour la plus grosse Large) × mutation (Config.Mutations)
	-- × stade de fusion. Les 6 créatures d'un anneau se tiennent (×12 entre la 1re et la 6e) : la 6e d'un
	-- anneau rapporte 3 fois moins que la 1re de l'anneau suivant. Avant le 15 nov., l'écart dans un
	-- anneau était de ×6 000 et tout reposait sur un tirage.
	-- Exemples (taille 1, sans mutation) : anneau 1 = 10 / 16 / 30 / 45 / 80 / 120 $/s ; anneau 2 = 356 à 4,3K ;
	-- anneau 7 = 20 Md à 240 Md.
	SlotIncome = { 2, 3.2, 6, 9, 16, 24 },
	RingIncome = { 5, 178, 6300, 224000, 7.9e6, 2.8e8, 1e10, 3.55e11, 1.26e13, 4.47e14, 1.58e16, 5.6e17, 1.98e19, 7e20 },
	-- Secondes entre l'appui sur « Hatch » et l'éclatement, selon la rareté : l'œuf se charge (tremble,
	-- brille, se fissure de rayons, s'élève...) de plus en plus longtemps et fort (HatchFx)
	-- 30 nov. : nettement plus long pour les plus rares (avant : 1,6 à 6,8 s), et une mutation ou une grande
	-- taille rallonge encore l'attente (BurstMutation, BurstSize : secondes en plus, BurstMax au plus). Le
	-- compteur de chance défile pendant 90 % de ce temps : plus la créature est rare, plus il monte longtemps.
	-- Voir Config.HatchBurst.
	Burst = { 1.6, 2.2, 3, 4.2, 5.8, 8, 10.5 },
	BurstMutation = { Silver = 0.5, Gold = 1, Emerald = 1.6, Ruby = 2.4, Rainbow = 3.2 },
	BurstSize = { Big = 0.8, Large = 1.8 },
	BurstMax = 14,
	-- Pendant la charge, l'œuf grossit jusqu'à Grow × la hauteur de la créature à naître (au moins MinGrow ×
	-- sa taille) : plus elle est immense, plus il gonfle
	Grow = 0.85,
	MinGrow = 1.15,
	-- Aperçu de la créature qui vient d'éclore (bannière « YOU HATCHED », Hatchery.client) : secondes à l'écran
	-- avant qu'elle se referme (0,3 s de plus pour disparaître : 2 s en tout au plus, 30 nov. ; avant : 3,2 s,
	-- et 4,6 s pour la créature rare du tutoriel)
	BannerTime = 1.7,
	-- Cinématique des œufs les plus rares (client/HatchCinema), pour leur propriétaire seulement : l'écran passe
	-- au noir, puis on retrouve l'œuf seul dans une salle noire, sous une lampe. Il se charge et éclate là, la
	-- créature apparaît sous la lumière, puis on revient à la base où elle attend. Les autres joueurs voient
	-- l'éclosion normale dans la base. Elle dure le temps de la charge (Burst) + Reveal : rien n'est rallongé.
	Cinema = {
		From = 6, -- rareté à partir de laquelle l'éclosion se joue dans la salle noire (Mythic et Cosmic)
		At = { 0, 2400, -900 }, -- où la salle est construite chez le joueur (loin de tout, fermée)
		Room = { 170, 80 }, -- côté et hauteur de la salle (studs)
		FadeIn = 0.25, -- fondu au noir à l'entrée
		FadeOut = 0.3, -- fondu au noir à la sortie
		Open = 0.45, -- l'image revient
		Bars = 0.1, -- bandes noires en haut et en bas (part de la hauteur de l'écran)
		Fov = 50,
		MaxGrow = 2.2, -- l'œuf gonfle moins que dans la base : le cadrage reste le même pour toutes les créatures
		Dist = { 3.7, 2.4 }, -- distance de la caméra (× hauteur finale de l'œuf) au début et à la fin de la charge
		Arc = { -0.6, 0.15 }, -- angle de la caméra autour de l'œuf (radians) au début et à la fin de la charge
		Tilt = 0.24, -- hauteur de la caméra au-dessus de ce qu'elle regarde (× sa distance)
		Reveal = 2, -- secondes passées sur la créature avant de revenir à la base
		Turn = 0.35, -- angle que la caméra parcourt encore pendant ce temps
		PetHeight = 13, -- hauteur de la créature montrée (studs), un peu plus pour une Big ou une Large
		PetDist = 2.5, -- distance de la caméra (× cette hauteur)
		Pop = 0.55, -- secondes pour que la créature jaillisse à sa taille
		PopDelay = 0.12,
		Lamp = { Height = 40, Angle = 44, Brightness = 3.2, Reveal = 5.5 }, -- la lampe au-dessus de l'œuf
		Ambient = Color3.fromRGB(12, 12, 20), -- lumière ambiante pendant la cinématique (remise ensuite)
		Floor = Color3.fromRGB(34, 34, 46),
	},
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
	-- 8. Star Reef
	["Bubble Guppy"] = motion("swim", "spin", 1.1, { Hover = 0.3 }),
	["Coral Crab"] = motion("scuttle", "sit", 1.2, { Sideways = true }),
	["Lantern Jelly"] = motion("float", "pulse", 0.6, { Hover = 0.35 }),
	["Tide Seahorse"] = motion("swim", "spin", 0.9, { Hover = 0.3 }),
	["Abyss Shark"] = motion("swim", "charge", 1.2, { Hover = 0.3 }),
	["Star Leviathan"] = motion("swim", "roar", 0.7, { Hover = 0.3 }),
	-- 9. Storm Halo
	["Zap Pup"] = motion("trot", "spin", 1.5),
	["Volt Beetle"] = motion("scuttle", "flip", 1.2),
	["Thunder Owl"] = motion("fly", "dive", 1.0, { Hover = 0.5 }),
	["Storm Ram"] = motion("stomp", "charge", 0.9),
	["Plasma Tiger"] = motion("trot", "pounce", 1.3),
	["Tempest Dragon"] = motion("fly", "roar", 0.8, { Hover = 0.4 }),
	-- 10. Clockwork Belt
	["Cog Mouse"] = motion("scuttle", "spin", 1.5),
	["Wind-Up Penguin"] = motion("waddle", "spin", 1.0),
	["Clockwork Fox"] = motion("trot", "pounce", 1.4),
	["Steam Rhino"] = motion("stomp", "charge", 0.9),
	["Mecha Raptor"] = motion("trot", "pounce", 1.4),
	["Brass Sky Whale"] = motion("swim", "roar", 0.6, { Hover = 0.4 }),
	-- 11. Candy Comet
	["Gummy Cub"] = motion("hop", "spin", 1.3),
	["Marshmallow Bunny"] = motion("hop", "flip", 1.4),
	["Lollipop Snail"] = motion("slither", "pulse", 0.7),
	["Donut Turtle"] = motion("stomp", "sit", 0.8),
	["Licorice Panther"] = motion("trot", "pounce", 1.4),
	["Cotton Candy Unicorn"] = motion("fly", "flip", 0.7, { Hover = 0.4 }),
	-- 12. Mushroom Moon
	["Mushroom Hedgehog"] = motion("scuttle", "spin", 1.4),
	["Toadstool Frog"] = motion("hop", "flip", 1.3),
	["Glowcap Moth"] = motion("fly", "spin", 1.1, { Hover = 0.4 }),
	["Moss Bear"] = motion("stomp", "roar", 0.9),
	["Fungal Stag"] = motion("trot", "roar", 1.2),
	["Mushroom Mammoth"] = motion("stomp", "charge", 0.7),
	-- 13. Jade Temple
	["Jade Monkey"] = motion("hop", "flip", 1.4),
	["Golden Scarab"] = motion("scuttle", "spin", 1.3),
	["Sphinx Cat"] = motion("trot", "sit", 1.2),
	["Temple Lion"] = motion("stomp", "roar", 0.9),
	["Feathered Serpent"] = motion("slither", "strike", 1.0),
	["Sun Condor"] = motion("fly", "dive", 0.6, { Hover = 0.4 }),
	-- 14. Phantom Mist
	["Boo Pup"] = motion("float", "spin", 1.2, { Hover = 0.35 }),
	["Pumpkin Kitty"] = motion("hop", "spin", 1.3),
	["Lantern Squid"] = motion("swim", "spin", 0.9, { Hover = 0.5 }),
	["Phantom Stallion"] = motion("trot", "roar", 1.1),
	["Spirit Wolf"] = motion("trot", "roar", 1.3),
	["Lantern Wyvern"] = motion("fly", "roar", 0.6, { Hover = 0.4 }),
}

-- Aura de chaque espèce (Creatures.client, effets en 4 calques de LayeredFx) : Kind = forme qui tourne
-- autour d'elle (Flame, Wisp, Electric, Bubbles, Spores, Hearts, Stardust, Glitch, Shards), Rim et Mid =
-- couleurs de la silhouette et du milieu (le cœur est presque blanc). Plus la rareté est haute, plus l'aura
-- est grande et franche. (Ground, le cercle à plat sous les plus rares, n'est plus affiché depuis le 29 nov. :
-- ces grands anneaux surchargeaient l'écran ; la valeur reste là si on veut le remettre.)
local function aura(kind: string, rim: Color3, mid: Color3, ground: string?)
	return { Kind = kind, Rim = rim, Mid = mid, Ground = ground }
end
Config.CreatureAura = {
	-- 1. Dust Belt
	["Pebblepup"] = aura("Spores", rgb(150, 135, 120), rgb(235, 225, 205)),
	["Dust Bunny"] = aura("Stardust", rgb(225, 180, 110), rgb(255, 240, 200)),
	["Craterhog"] = aura("Shards", rgb(150, 70, 230), rgb(220, 175, 255)),
	["Orbitoad"] = aura("Stardust", rgb(60, 120, 255), rgb(175, 215, 255)),
	["Meteor Fox"] = aura("Flame", rgb(255, 90, 20), rgb(255, 195, 60)),
	["Stardust Dragon"] = aura("Stardust", rgb(255, 80, 170), rgb(255, 222, 120), "Pulse"),
	-- 2. Ice Ring
	["Frostling"] = aura("Shards", rgb(70, 160, 255), rgb(195, 235, 255)),
	["Snow Moth"] = aura("Spores", rgb(140, 195, 255), rgb(235, 245, 255)),
	["Glacier Otter"] = aura("Bubbles", rgb(60, 180, 230), rgb(195, 240, 255)),
	["Comet Seal"] = aura("Stardust", rgb(60, 200, 255), rgb(210, 250, 255)),
	["Aurora Owl"] = aura("Wisp", rgb(140, 80, 255), rgb(110, 255, 185)),
	["Crystal Yeti"] = aura("Shards", rgb(40, 120, 255), rgb(165, 230, 255), "Pulse"),
	-- 3. Magma Field
	["Cinder Slug"] = aura("Spores", rgb(255, 80, 20), rgb(255, 200, 80)),
	["Lava Crab"] = aura("Bubbles", rgb(255, 70, 10), rgb(255, 175, 40)),
	["Blaze Newt"] = aura("Flame", rgb(255, 110, 20), rgb(255, 222, 80)),
	["Obsidian Rhino"] = aura("Flame", rgb(200, 30, 20), rgb(255, 135, 40), "Pulse"),
	["Solar Phoenix"] = aura("Flame", rgb(255, 150, 0), rgb(255, 240, 125), "Pulse"),
	["Magma Wyrm"] = aura("Flame", rgb(230, 40, 10), rgb(255, 155, 30), "Pulse"),
	-- 4. Nebula
	["Nebula Jelly"] = aura("Bubbles", rgb(230, 80, 220), rgb(255, 195, 250)),
	["Haze Kitten"] = aura("Wisp", rgb(170, 130, 255), rgb(232, 212, 255)),
	["Dreamfin"] = aura("Bubbles", rgb(70, 150, 255), rgb(195, 228, 255)),
	["Prism Ray"] = aura("Shards", rgb(255, 90, 200), rgb(125, 240, 255)),
	["Nova Lion"] = aura("Flame", rgb(255, 170, 40), rgb(255, 250, 195), "Pulse"),
	["Galaxy Unicorn"] = aura("Stardust", rgb(160, 70, 255), rgb(255, 155, 240), "Rune"),
	-- 5. Devourer Belt
	["Fang Beetle"] = aura("Spores", rgb(60, 170, 60), rgb(195, 255, 135)),
	["Gloom Bat"] = aura("Wisp", rgb(110, 40, 170), rgb(205, 145, 255)),
	["Void Shark"] = aura("Wisp", rgb(50, 35, 110), rgb(125, 95, 225), "Pulse"),
	["Hunger Hound"] = aura("Wisp", rgb(20, 140, 140), rgb(95, 255, 230), "Pulse"),
	["Abyss Serpent"] = aura("Wisp", rgb(90, 30, 160), rgb(205, 115, 255), "Rune"),
	["Eclipse Devourer"] = aura("Flame", rgb(90, 20, 140), rgb(255, 115, 60), "Rune"),
	-- 6. The Rift
	["Chrono Snail"] = aura("Stardust", rgb(220, 160, 40), rgb(255, 235, 155)),
	["Glitch Cat"] = aura("Glitch", rgb(255, 40, 220), rgb(65, 255, 255)),
	["Paradox Panda"] = aura("Wisp", rgb(60, 60, 85), rgb(240, 240, 255), "Rune"),
	["Hourglass Tortoise"] = aura("Spores", rgb(220, 160, 50), rgb(255, 232, 155), "Rune"),
	["Rift Griffin"] = aura("Electric", rgb(150, 60, 255), rgb(95, 230, 255), "Pulse"),
	["Quasar Kraken"] = aura("Electric", rgb(60, 90, 255), rgb(205, 240, 255), "Rune"),
	-- 7. The Nest
	["Hatchling"] = aura("Spores", rgb(255, 190, 60), rgb(255, 245, 195)),
	["Yolk Slime"] = aura("Bubbles", rgb(255, 170, 30), rgb(255, 235, 145)),
	["Brood Raptor"] = aura("Flame", rgb(230, 120, 20), rgb(255, 212, 115)),
	["Nest Drake"] = aura("Stardust", rgb(110, 210, 255), rgb(232, 250, 255), "Pulse"),
	["Hive Queen"] = aura("Shards", rgb(255, 180, 20), rgb(255, 240, 155), "Rune"),
	["Cosmic Mother"] = aura("Stardust", rgb(200, 60, 255), rgb(255, 195, 125), "Rune"),
	-- 8. Star Reef
	["Bubble Guppy"] = aura("Bubbles", rgb(30, 190, 200), rgb(175, 250, 250)),
	["Coral Crab"] = aura("Bubbles", rgb(255, 90, 130), rgb(255, 205, 215)),
	["Lantern Jelly"] = aura("Spores", rgb(60, 220, 200), rgb(222, 255, 205)),
	["Tide Seahorse"] = aura("Bubbles", rgb(230, 170, 40), rgb(255, 240, 175), "Pulse"),
	["Abyss Shark"] = aura("Shards", rgb(40, 120, 220), rgb(155, 240, 255), "Pulse"),
	["Star Leviathan"] = aura("Stardust", rgb(40, 160, 230), rgb(255, 232, 155), "Rune"),
	-- 9. Storm Halo
	["Zap Pup"] = aura("Electric", rgb(255, 190, 0), rgb(255, 250, 175)),
	["Volt Beetle"] = aura("Electric", rgb(130, 220, 30), rgb(240, 255, 165)),
	["Thunder Owl"] = aura("Electric", rgb(120, 90, 255), rgb(255, 240, 125)),
	["Storm Ram"] = aura("Electric", rgb(60, 110, 255), rgb(205, 232, 255), "Pulse"),
	["Plasma Tiger"] = aura("Electric", rgb(220, 50, 255), rgb(155, 240, 255), "Pulse"),
	["Tempest Dragon"] = aura("Electric", rgb(80, 60, 255), rgb(255, 250, 185), "Rune"),
	-- 10. Clockwork Belt (engrenage au sol pour toutes)
	["Cog Mouse"] = aura("Spores", rgb(200, 140, 50), rgb(255, 222, 145), "Gear"),
	["Wind-Up Penguin"] = aura("Spores", rgb(190, 110, 60), rgb(255, 210, 160), "Gear"),
	["Clockwork Fox"] = aura("Spores", rgb(220, 120, 40), rgb(255, 215, 140), "Gear"),
	["Steam Rhino"] = aura("Wisp", rgb(160, 170, 185), rgb(245, 250, 255), "Gear"),
	["Mecha Raptor"] = aura("Electric", rgb(20, 180, 180), rgb(165, 255, 240), "Gear"),
	["Brass Sky Whale"] = aura("Wisp", rgb(200, 150, 70), rgb(250, 245, 230), "Gear"),
	-- 11. Candy Comet
	["Gummy Cub"] = aura("Hearts", rgb(230, 40, 60), rgb(255, 165, 175)),
	["Marshmallow Bunny"] = aura("Hearts", rgb(255, 110, 180), rgb(255, 222, 240)),
	["Lollipop Snail"] = aura("Stardust", rgb(255, 60, 160), rgb(125, 230, 255)),
	["Donut Turtle"] = aura("Spores", rgb(255, 100, 180), rgb(255, 240, 165), "Pulse"),
	["Licorice Panther"] = aura("Wisp", rgb(35, 35, 50), rgb(115, 255, 205), "Pulse"),
	["Cotton Candy Unicorn"] = aura("Hearts", rgb(255, 120, 220), rgb(155, 222, 255), "Rune"),
	-- 12. Mushroom Moon
	["Mushroom Hedgehog"] = aura("Spores", rgb(40, 200, 220), rgb(205, 255, 240)),
	["Toadstool Frog"] = aura("Spores", rgb(230, 50, 40), rgb(255, 222, 205)),
	["Glowcap Moth"] = aura("Spores", rgb(120, 220, 60), rgb(240, 255, 175)),
	["Moss Bear"] = aura("Spores", rgb(60, 160, 60), rgb(205, 255, 155), "Pulse"),
	["Fungal Stag"] = aura("Spores", rgb(50, 120, 255), rgb(185, 240, 255), "Rune"),
	["Mushroom Mammoth"] = aura("Spores", rgb(150, 60, 255), rgb(222, 205, 255), "Rune"),
	-- 13. Jade Temple
	["Jade Monkey"] = aura("Spores", rgb(30, 170, 100), rgb(185, 255, 205)),
	["Golden Scarab"] = aura("Shards", rgb(230, 160, 20), rgb(255, 240, 155)),
	["Sphinx Cat"] = aura("Stardust", rgb(30, 170, 180), rgb(255, 222, 105), "Rune"),
	["Temple Lion"] = aura("Flame", rgb(220, 150, 20), rgb(255, 240, 155), "Rune"),
	["Feathered Serpent"] = aura("Wisp", rgb(20, 160, 110), rgb(255, 212, 95), "Rune"),
	["Sun Condor"] = aura("Flame", rgb(255, 130, 0), rgb(255, 245, 175), "Rune"),
	-- 14. Phantom Mist
	["Boo Pup"] = aura("Wisp", rgb(120, 200, 255), rgb(235, 250, 255)),
	["Pumpkin Kitty"] = aura("Flame", rgb(255, 110, 10), rgb(255, 212, 95)),
	["Lantern Squid"] = aura("Spores", rgb(255, 170, 40), rgb(255, 240, 185)),
	["Phantom Stallion"] = aura("Flame", rgb(20, 190, 190), rgb(185, 255, 245), "Pulse"),
	["Spirit Wolf"] = aura("Wisp", rgb(60, 170, 230), rgb(222, 245, 255), "Pulse"),
	["Lantern Wyvern"] = aura("Wisp", rgb(90, 220, 190), rgb(255, 222, 125), "Rune"),
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

-- TAILLES DES CRÉATURES (8 nov., revues le 29 nov.) ----------------------------------------------
-- La taille (item.size) multiplie la hauteur d'une créature et son revenu x taille² (Config.SizeIncomePower).
-- Depuis le 29 nov. :
--   - la taille tirée au hasard est faible : une créature normale fait de x1 à x1,08, juste de quoi ne pas
--     avoir deux fois la même (avant, les paliers Big / Huge / Giant sortaient une fois sur trois) ;
--   - deux MUTATIONS DE TAILLE, rares, donnent un très gros bond : Big (environ x1,8) et Large (environ x2,8,
--     la plus grande). Elles ont leur nom (« Large Pebblepup ») et leur couleur affichés partout, et leur
--     étiquette à l'éclosion.
-- Une mutation de taille se cumule avec la mutation de matière (Config.Mutations) : « Gold Large Pebblepup ».
-- Comme les autres mutations, la chance du joueur (scanner, potion, Index, groupe) et le Mutation Ray de la
-- machine multiplient leurs chances (Config.SizeChances), sans dépasser SizeMutationMax à elles deux.
-- Chance = probabilité de base à l'éclosion ; Min / Max = taille tirée dans ce palier.
Config.PetSizes = {
	{ Name = "", Chance = 0.90, Min = 1.0, Max = 1.08, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Big", Chance = 0.08, Min = 1.7, Max = 1.9, Color = Color3.fromRGB(120, 245, 80), Mutation = true },
	{ Name = "Large", Chance = 0.02, Min = 2.6, Max = 3.0, Color = Color3.fromRGB(255, 70, 90), Mutation = true },
}
Config.SizeIncomePower = 2
Config.SizeMutationMax = 0.4

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

-- Chance de chaque palier de taille (même ordre que Config.PetSizes) avec cette chance du joueur : les
-- mutations de taille en profitent, la taille normale prend le reste
function Config.SizeChances(luck: number?): { number }
	local tiers = Config.PetSizes
	local total = 0
	for _, t in ipairs(tiers) do
		if t.Mutation then
			total += t.Chance * (luck or 1)
		end
	end
	local k = if total > Config.SizeMutationMax then Config.SizeMutationMax / total else 1
	local p = {}
	local rest = 1
	for i, t in ipairs(tiers) do
		if t.Mutation then
			p[i] = t.Chance * (luck or 1) * k
			rest -= p[i]
		end
	end
	for i, t in ipairs(tiers) do
		if not t.Mutation then
			p[i] = rest
			rest = 0
		end
	end
	return p
end

-- Taille tirée à l'éclosion (luck : chance du joueur, pour les mutations de taille), les plus rares d'abord
function Config.RollPetSize(r: Random, luck: number?): number
	local p = Config.SizeChances(luck)
	local x = r:NextNumber()
	local tier = Config.PetSizes[1]
	for i = #p, 1, -1 do
		x -= p[i]
		if x < 0 then
			tier = Config.PetSizes[i]
			break
		end
	end
	return math.floor(r:NextNumber(tier.Min, tier.Max) * 100 + 0.5) / 100
end

-- Multiplicateur de revenu d'une taille
function Config.SizeIncomeMult(size: number?): number
	return (size or 1) ^ Config.SizeIncomePower
end

-- Nom affiché (« Gold Giant Elder Pyrolynx ») et revenu d'une créature, mutation, taille et stade compris
function Config.PetName(item): string
	local st = Config.PetRules.Stages[item.stage or 1]
	local name = if st and st.Name ~= "" then st.Name .. " " .. (item.name or "?") else (item.name or "?")
	local tier = Config.PetSize(item.size)
	name = if tier.Name ~= "" then tier.Name .. " " .. name else name
	local mut = Config.Mutation(item.mut)
	return if mut then mut.Name .. " " .. name else name
end
function Config.PetIncome(item): number
	local st = Config.PetRules.Stages[item.stage or 1] or Config.PetRules.Stages[1]
	return Config.CreatureIncome(item.ring, item.rarity, (item.size or 1), item.mut) * st.Mult
end
function Config.PetPrice(item): number
	return math.floor((item.income or Config.PetIncome(item)) * Config.PetRules.SellSeconds)
end

function Config.CreatureIncome(ringIndex: number, rarity: number, size: number, mutation: string?): number
	local h = Config.Hatch
	local r = h.SlotIncome[math.clamp(Config.CreatureSlot(ringIndex, rarity), 1, #h.SlotIncome)]
	local ring = h.RingIncome[math.clamp(ringIndex, 1, #h.RingIncome)]
	local mut = Config.Mutation(mutation)
	local v = r * ring * Config.SizeIncomeMult(size) * (if mut then mut.Mult else 1)
	-- arrondi lisible : entier sous 1000, sinon 3 chiffres significatifs
	if v < 1000 then
		return math.max(1, math.floor(v + 0.5))
	end
	local p = 10 ^ (math.floor(math.log10(v)) - 2)
	return math.floor(v / p + 0.5) * p
end

-- Chances de chaque rareté (index 1..7, 0 si l'anneau n'a pas cet œuf) pour un œuf sorti de ce type
-- d'astéroïde. La chance du joueur n'y change rien : elle joue sur les mutations.
function Config.RockChances(ringIndex: number, rockType: number?): { number }
	local slots = Config.RockType(rockType).Slots
	local total = 0
	for _, w in ipairs(slots) do
		total += w
	end
	local p = table.create(#Config.Rarities, 0)
	for slot, w in ipairs(slots) do
		p[Config.CreatureRarity(ringIndex, slot)] = w / total
	end
	return p
end

-- MUTATIONS (15 nov.) --------------------------------------------------------------------------------
-- À l'éclosion, une créature peut sortir mutée : elle change de matière et de couleur (shared/Mutation)
-- et rapporte Mult fois plus. Une seule mutation par créature ; elle se cumule avec la taille et le stade
-- de fusion. Chance = probabilité de base ; la chance du joueur (scanner, potion, Index, groupe) et
-- l'amélioration « Mutation Ray » de la machine les multiplient toutes, sans dépasser MutationMax au total.
-- Metal = vrai : matière métal (ou Material = nom d'une matière) ; Reflect : reflet (0 à 1) ; Dark : couleur
-- des membres (pattes, bras, oreilles, queue, ailes...), en métal ; Rainbow : couleurs qui défilent.
Config.Mutations = {
	-- Glow = lumière douce autour de la créature (luminosité), qui pulse (MutationFx.client). Depuis le 29 nov.
	-- il n'y a plus d'étincelles ni d'éclats en étoile autour d'elle : l'effet est sur sa peau (shared/Mutation).
	-- Silver (29 nov.) : feuille d'argent froissée sur le corps et la tête, acier plus sombre sur les membres
	-- (Material, Dark). Le blanc nacré uni d'avant, avec son fort reflet du ciel noir, faisait croire à un
	-- modèle sans texture, à moitié transparent : plus de reflet, et deux tons pour qu'on lise les formes.
	{ Key = "Silver", Name = "Silver", Chance = 0.12, Mult = 1.5, Color = Color3.fromRGB(212, 218, 230), Material = "Foil", Dark = Color3.fromRGB(128, 138, 162), Reflect = 0, Glow = 1.4, GlowColor = Color3.fromRGB(190, 225, 255) },
	{ Key = "Gold", Name = "Gold", Chance = 0.04, Mult = 3, Color = Color3.fromRGB(255, 196, 40), Metal = true, Reflect = 0.3, Glow = 1.6 },
	{ Key = "Emerald", Name = "Emerald", Chance = 0.02, Mult = 5, Color = Color3.fromRGB(50, 215, 120), Reflect = 0.35, Glow = 1.8 },
	{ Key = "Ruby", Name = "Ruby", Chance = 0.01, Mult = 10, Color = Color3.fromRGB(235, 45, 80), Reflect = 0.35, Glow = 2.1 },
	{ Key = "Rainbow", Name = "Rainbow", Chance = 0.005, Mult = 20, Color = Color3.fromRGB(255, 120, 220), Reflect = 0.15, Rainbow = true, Glow = 2.5 },
}
Config.MutationMax = 0.75
function Config.Mutation(key: string?)
	if key then
		for _, m in ipairs(Config.Mutations) do
			if m.Key == key then
				return m
			end
		end
	end
	return nil
end
-- Chance de chaque mutation (même ordre que Config.Mutations) avec cette chance du joueur
function Config.MutationChances(luck: number): { number }
	local total = 0
	for _, m in ipairs(Config.Mutations) do
		total += m.Chance * luck
	end
	local k = if total > Config.MutationMax then Config.MutationMax / total else 1
	local p = {}
	for i, m in ipairs(Config.Mutations) do
		p[i] = m.Chance * luck * k
	end
	return p
end
-- Mutation tirée à l'éclosion (ou nil), les plus rares d'abord
function Config.RollMutation(r: Random, luck: number): string?
	local p = Config.MutationChances(luck)
	local x = r:NextNumber()
	for i = #p, 1, -1 do
		x -= p[i]
		if x < 0 then
			return Config.Mutations[i].Key
		end
	end
	return nil
end
-- Chance (0 à 1) d'obtenir exactement cette créature : cette espèce dans ce type d'astéroïde, ce palier
-- de taille, cette mutation (ou aucune). C'est le « 1 in X » montré à l'éclosion (HatchFx).
function Config.HatchOdds(ringIndex: number, rarity: number, rockType: number?, size: number?, mutation: string?, luck: number): number
	local p = Config.RockChances(ringIndex, rockType)[rarity] or 0
	local tier = Config.PetSize(size)
	p *= Config.SizeChances(luck)[table.find(Config.PetSizes, tier) or 1]
	local chances = Config.MutationChances(luck)
	local none = 1
	local mine: number? = nil
	for i, m in ipairs(Config.Mutations) do
		none -= chances[i]
		if m.Key == mutation then
			mine = chances[i]
		end
	end
	return p * (mine or none)
end

-- Secondes de charge avant l'éclatement de l'œuf (HatchService) : selon la rareté, plus un supplément pour une
-- mutation et pour une grande taille. Plus la créature est rare, plus l'éclosion et son compteur durent.
function Config.HatchBurst(rarity: number, size: number?, mutation: string?): number
	local h = Config.Hatch
	local t = h.Burst[rarity] or 2
	if mutation then
		t += h.BurstMutation[mutation] or 0
	end
	t += h.BurstSize[Config.PetSize(size).Name] or 0
	return math.min(h.BurstMax, t)
end

-- Chance AFFICHÉE à l'éclosion (compteur au trèfle et bannière, 19 nov.) : un nombre de spectacle, pas
-- la vraie probabilité (qui reste dans l'Index). Il part de la vraie chance (odds = 1 sur N, sinon
-- 2^rareté), donc une créature plus rare, plus grande ou mutée affiche toujours plus ; il est gonflé
-- par Base et par PerRing à chaque anneau pour qu'on ait toujours l'impression de sortir quelque chose
-- d'énorme. Exemples : Commun de l'anneau 1 ≈ x500 ; Cosmique de l'anneau 9 ≈ x1.4Qa.
Config.LuckShow = { Base = 250, PerRing = 12 }
function Config.LuckShown(ring: number, rarity: number, odds: number?): number
	local o = math.max(2, odds or 2 ^ rarity)
	return math.floor(o * Config.LuckShow.Base * Config.LuckShow.PerRing ^ (math.max(1, ring) - 1))
end

-- GUIDE DES PREMIÈRES MINUTES (Guide.client) ------------------------------------------
-- Fait pour qu'un enfant suive sans lire : bulles de 3 à 5 mots, grosses icônes, flèche au sol,
-- main qui montre le geste, petite fête à chaque réussite. Il accompagne le joueur pendant toute la
-- première boucle : forer, rapporter, poser, faire éclore, puis s'entraîner et s'équiper.
-- Pas d'étape « va à l'anneau 2 » : le joueur ira de lui-même.
-- Étapes enregistrées (d.guide) = nombre d'étapes franchies (15 nov. : plus de géode à vendre) :
--   0 voler jusqu'à une roche et forer   1 rapporter la roche à la machine   2 poser l'œuf dans sa base
--   3 le faire éclore (« ta créature rapporte des $ »)   4 acheter sa soufflerie
--   5 s'y entraîner jusqu'au niveau JetLevel du jetpack   6 acheter la foreuse n° Drill   7 (= Steps) terminé
Config.Guide = {
	Steps = 7,
	Drill = 2,
	JetLevel = 5, -- niveau du jetpack à atteindre dans sa soufflerie (étape 5)
	TunnelTime = 5, -- secondes à passer dans le courant d'air pour valider l'étape 5, même si le niveau est déjà là
	FirstRarity = 4, -- rareté du tout premier œuf (Épique, la plus haute qu'un astéroïde tendre peut donner) : un vrai « wow », et de quoi payer la soufflerie
	Reward = { Money = 1000, Luck = 15, MoneyBoost = 15 }, -- fin du tutoriel : $ (× revenu de base de l'anneau 1) et potions x2 de 15 min
	Arrow = "rbxassetid://111578532993258", -- chevrons blancs à contour sombre (poutre au sol)
	-- (Tips : « machine » = panneau de première fois des améliorations)
	MachineNear = 18, -- studs : assez près de la machine pour appuyer sur E
	PetCheer = 5, -- secondes de « ta créature rapporte des $ »
	-- Nom de chaque étape dans l'entonnoir Onboarding (Tracking) ; l'étape 1 de l'entonnoir est « Join »
	Names = {
		"Egg drilled", "Machine used", "Egg placed", "Pet hatched",
		"Wind tunnel bought", "Jetpack trained", "New drill bought",
	},
	-- Tutoriels au bon moment : une seule fois par joueur, quand il en a besoin (Guide.client)
	Tips = { basefull = true, rewards = true, fuse = true, monsters = true, scanner = true, starter = true, machine = true },
	TipMax = 40, -- secondes avant qu'un tip non suivi s'efface tout seul
	TipShort = 12, -- idem pour un tip sans endroit où aller
	TipGap = 25, -- secondes de calme entre deux tips d'information (récompenses, fusion, monstres...)
}

-- ENCLOS (PenService, shared/PenBuilder, PenUI.client) ----------------------------------------------
-- La base du joueur s'agrandit par niveaux achetés en $ (bouton rouge dans l'enclos). Règles de Chouaib
-- (26 nov.) : 10 améliorations avant le maximum, +1 place à chaque amélioration, et un prix qui double à
-- chaque fois.
-- Prix d'une amélioration = CostBase × 2^(n - 1) × RingIncome de l'anneau le plus loin débloqué (comme les
-- paquets d'argent, Config.MoneyPackAmount). Un prix fixe ne pouvait pas marcher : il ne fait que ×512 entre
-- la première et la dernière amélioration, alors que les revenus font ×35 à chaque anneau.
-- CostBase = 3 000 : la 1re amélioration vaut 125 s du revenu de la créature la plus rare de son anneau
-- (24 × RingIncome par seconde), soit une à deux minutes avec une base pleine ; la 10e en vaut 64 000 s
-- (près de 18 heures de cette créature) : bien au-dessus de ce qu'elle rapporte, quelques heures de jeu.
-- Levels[n] : Size = sol (largeur, profondeur), de 36 x 36 à 48 x 60 dans la place réservée par
-- tools/build-yard.lua (il grandit vers le fond et vers le côté libre) ; Slots = places en plus pour les
-- œufs et les créatures (en plus de Config.Hatch.Slots et du passe +5).
Config.Pen = {
	Upgrades = 10,
	First = Vector2.new(36, 36),
	Last = Vector2.new(48, 60),
	CostBase = 3000,
	CostGrowth = 2,
	Levels = {},
	-- bouton rouge dans l'enclos, repère de départ de la base : coin avant, côté atelier (x multiplié par -TunnelSide)
	Button = Vector3.new(13, 0, 13),
}
for n = 0, Config.Pen.Upgrades do
	local k = n / Config.Pen.Upgrades
	local size = Config.Pen.First:Lerp(Config.Pen.Last, k)
	Config.Pen.Levels[n + 1] = { Size = Vector2.new(math.floor(size.X + 0.5), math.floor(size.Y + 0.5)), Slots = n }
end
function Config.PenLevel(level: number?)
	return Config.Pen.Levels[math.clamp(math.floor(level or 1), 1, #Config.Pen.Levels)]
end
-- Prix pour passer au niveau « level » (2 = première amélioration) quand on a débloqué l'anneau « ring »
function Config.PenCost(level: number, ring: number?): number
	local incomes = Config.Hatch.RingIncome
	local income = incomes[math.clamp(math.floor(ring or 1), 1, #incomes)]
	return math.floor(Config.Pen.CostBase * Config.Pen.CostGrowth ^ (level - 2) * income + 0.5)
end

-- INTERFACE (UIKit) ---------------------------------------------------------------------------------
-- Studs : où l'interface porte des picots (« l'effet lego »).
--   "All"    : partout, comme jusqu'au 15 nov. (panneaux, cartes, barre d'objets, bandeaux, boutons)
--   "Titles" : seulement sur les bandeaux de titre et les boutons ; panneaux, cartes et barre d'objets sont lisses
--              (choisi par Chouaib le 15 nov. après comparaison des deux)
--   "None"   : nulle part
-- Pour comparer en jeu sans republier : dans la barre de commande de Studio, côté client,
--   game.Players.LocalPlayer:SetAttribute("StudsMode", "Titles")
-- Les picots du monde en 3D ne sont pas concernés.
Config.UI = {
	Studs = "Titles",
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
-- (Config.Hatch.RingIncome) : 600 = 3K $ dans l'anneau 1, 107K $ dans l'anneau 2... Elle reste
-- intéressante à toutes les étapes. Les journées changent à minuit UTC.
Config.Rewards = {
	Daily = {
		{ Money = 600 },
		{ Luck = 10 },
		{ Money = 1200 },
		{ MoneyBoost = 10 },
		{ Money = 2400 },
		{ JetXP = 15 },
		{ Money = 6000, Luck = 15, MoneyBoost = 15 }, -- jour 7 : le gros cadeau
	},
	Playtime = {
		{ Minutes = 5, Reward = { Money = 300 } },
		{ Minutes = 15, Reward = { Luck = 5 } },
		{ Minutes = 30, Reward = { Money = 1200 } },
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
	QuestReward = { Money = 600 }, -- 3K $ dans l'anneau 1
	AllQuestsReward = { Luck = 15 }, -- en plus, à la 3e quête réclamée
	-- Groupe Roblox : 0 = le groupe propriétaire du jeu (s'il appartient à un groupe)
	GroupId = 0,
	GroupLuck = 0.1, -- +10 % de chance tant qu'on est membre
	GroupReward = { Money = 1500 }, -- une fois, au premier « Claim »
	-- Boost gratuit contre une pub récompensée (AdService) : la récompense passe par le produit de la
	-- potion x2 Luck (canal AdReward), on donne alors ces potions-ci au lieu de l'achat normal
	AdBoost = { Luck = 5, MoneyBoost = 5 },
	AdCooldown = 600, -- secondes entre deux pubs
}
-- Codes promo (en majuscules) : une fois par joueur
Config.Codes = {
	WELCOME = { Money = 1500, Luck = 10 },
	SPACEEGG = { Money = 3000 },
	DRILLTIME = { JetXP = 15, MoneyBoost = 10 },
}

-- AMÉLIORATIONS DE LA MACHINE À DÉROCHER (MachineService, MachineUI.client) -------------------------
-- Trois améliorations à 20 niveaux, payées en $. Coût du niveau n = Base × Growth^n.
-- Le total des niveaux donne à la machine une couleur de plus en plus rare (Tiers).
Config.Machine = {
	Max = 20,
	MinTime = 1.8, -- secondes : en dessous, l'animation de la machine n'a plus le temps de se jouer
	Order = { "Speed", "Luck", "Mutation" },
	Tracks = {
		Speed = { Name = "Turbo Motor", Text = "Less waiting at the machine", Art = "MachineSpeed", Base = 7500, Growth = 3.3, Shift = 2, PerLevel = 0.93, Color = Color3.fromRGB(255, 165, 50) },
		Luck = { Name = "Lucky Core", Text = "Chance of +1 rarity", Art = "MachineLuck", Base = 20000, Growth = 3.7, Shift = 4, PerLevel = 0.01, Color = Color3.fromRGB(110, 230, 80) },
		Mutation = { Name = "Mutation Ray", Text = "More mutated pets", Art = "MachinePolish", Base = 30000, Growth = 3.4, Shift = 1, PerLevel = 0.05, Color = Color3.fromRGB(255, 120, 220) },
	},
	Tiers = {
		{ Min = 0, Name = "Standard", Accent = Color3.fromRGB(255, 208, 110), Glow = Color3.fromRGB(255, 176, 60) },
		{ Min = 10, Name = "Emerald", Accent = Color3.fromRGB(120, 235, 120), Glow = Color3.fromRGB(70, 230, 110) },
		{ Min = 25, Name = "Sapphire", Accent = Color3.fromRGB(100, 185, 255), Glow = Color3.fromRGB(60, 150, 255) },
		{ Min = 40, Name = "Amethyst", Accent = Color3.fromRGB(205, 130, 255), Glow = Color3.fromRGB(180, 90, 255) },
		{ Min = 52, Name = "Ruby", Accent = Color3.fromRGB(255, 105, 125), Glow = Color3.fromRGB(255, 60, 90) },
		{ Min = 60, Name = "Legendary Gold", Accent = Color3.fromRGB(255, 225, 90), Glow = Color3.fromRGB(255, 200, 40) },
	},
}

function Config.MachineCost(key: string, level: number): number
	local t = Config.Machine.Tracks[key]
	return Config.StepCost(t.Base, t.Growth, level, t.Shift)
end

-- Secondes pour dégager un œuf de cette rareté
function Config.MachineTime(rarity: number, speedLevel: number): number
	local base = Config.Derock.Times[math.clamp(rarity, 1, #Config.Derock.Times)]
	local time = base * Config.Machine.Tracks.Speed.PerLevel ^ speedLevel
	return math.max(Config.Machine.MinTime, time)
end

-- Chance (0 à 1) de monter d'une rareté, et multiplicateur de la chance de mutation
function Config.MachineLuck(level: number): number
	return Config.Machine.Tracks.Luck.PerLevel * level
end
function Config.MachineMutation(level: number): number
	return 1 + Config.Machine.Tracks.Mutation.PerLevel * level
end

-- Texte court de l'effet à ce niveau (fenêtre)
function Config.MachineEffect(key: string, level: number): string
	if key == "Speed" then
		return ("-%d%%"):format(math.floor((1 - Config.Machine.Tracks.Speed.PerLevel ^ level) * 100 + 0.5))
	elseif key == "Mutation" then
		return ("x%.2f"):format(Config.MachineMutation(level))
	end
	return ("%d%%"):format(math.floor(Config.MachineLuck(level) * 100 + 0.5))
end

-- Palier de couleur selon le total des niveaux : palier actuel, palier suivant (ou nil)
function Config.MachineTier(total: number): (any, any?)
	local tiers = Config.Machine.Tiers
	local index = 1
	for i, t in ipairs(tiers) do
		if total >= t.Min then
			index = i
		end
	end
	return tiers[index], tiers[index + 1]
end

-- RETOUR À LA BASE AVEC UN ŒUF (client/HomeFx) : petit zoom avant de la caméra et éclat de lumière
Config.HomeFx = {
	Zoom = 14, -- degrés de champ de vision en moins au plus fort du zoom
	ZoomIn = 0.22, -- secondes pour zoomer
	ZoomOut = 0.6, -- secondes pour revenir
	Cooldown = 4, -- secondes entre deux effets (on ne le rejoue pas en piétinant le bord de l'enclos)
}

-- REVENU HORS LIGNE (HatchService, Offers.client) --------------------------------------------------
-- Les créatures de la base continuent de rapporter quand le joueur est parti : Rate × leur revenu
-- (passes et reliques compris, pas les potions), pendant au plus MaxHours heures. Rester en jeu rapporte
-- donc toujours plus que partir (revenu complet, et la soufflerie qui tourne).
Config.Offline = {
	Rate = 0.4, -- part du revenu en ligne (le revenu d'une heure ÷ 2,5)
	MaxHours = 6,
	MinSeconds = 120, -- en dessous, rien (une simple reconnexion)
}

return Config
