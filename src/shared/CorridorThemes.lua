-- Thème de chaque biome le long du couloir (27 nov.) : murs, rails, piliers, portail d'entrée, décors et
-- petites créatures volantes. Sert au serveur (CorridorDecor : ce qui est construit) et au client
-- (Critters.client : les créatures et ce qui bouge).
--   Wall   : teinte de la paroi (légèrement opaque)          Trim : rails et piliers
--   Dark   : pièces sombres (socles, contours)               Accent : petites touches lumineuses
--   Props  : décors posés le long des murs (noms des constructeurs de CorridorDecor)
--   Critter: petite créature volante du biome (Critters.client). Kind = allure, Body / Belly / Glow =
--            couleurs ; plus on avance, plus elles sont nombreuses et grandes (Config ci-dessous).
-- Chaque biome doit être plus impressionnant que le précédent : tout grandit avec le numéro de l'anneau.

local rgb = Color3.fromRGB

local Themes = {}

Themes.List = {
	{ -- 1. Dust Belt : roche et poussière dorée
		Wall = rgb(214, 170, 120), Trim = rgb(146, 112, 84), Dark = rgb(92, 70, 56), Accent = rgb(255, 214, 120),
		Props = { "Spire", "Pebbles" },
		Critter = { Kind = "Puff", Body = rgb(226, 190, 140), Belly = rgb(255, 236, 200), Glow = rgb(255, 220, 130) },
	},
	{ -- 2. Ice Ring : glace et neige
		Wall = rgb(150, 215, 255), Trim = rgb(232, 246, 255), Dark = rgb(90, 150, 210), Accent = rgb(170, 240, 255),
		Props = { "Crystal", "Snow" },
		Critter = { Kind = "Sprite", Body = rgb(170, 225, 255), Belly = rgb(245, 252, 255), Glow = rgb(150, 235, 255) },
	},
	{ -- 3. Magma Field : volcans et lave
		Wall = rgb(255, 120, 60), Trim = rgb(70, 52, 54), Dark = rgb(44, 34, 38), Accent = rgb(255, 170, 50),
		Props = { "Volcano", "LavaRock" },
		Critter = { Kind = "Bat", Body = rgb(96, 44, 44), Belly = rgb(255, 150, 60), Glow = rgb(255, 180, 60) },
	},
	{ -- 4. Nebula : nuages roses et étoiles
		Wall = rgb(230, 130, 235), Trim = rgb(150, 100, 220), Dark = rgb(84, 56, 150), Accent = rgb(255, 232, 130),
		Props = { "Puff", "Planet" },
		Critter = { Kind = "Jelly", Body = rgb(255, 150, 225), Belly = rgb(255, 215, 245), Glow = rgb(255, 240, 150) },
	},
	{ -- 5. Devourer Belt : crocs et yeux
		Wall = rgb(110, 200, 110), Trim = rgb(74, 66, 78), Dark = rgb(46, 40, 52), Accent = rgb(170, 255, 90),
		Props = { "Fang", "Eye" },
		Critter = { Kind = "Chomper", Body = rgb(90, 180, 90), Belly = rgb(200, 250, 150), Glow = rgb(190, 255, 100) },
	},
	{ -- 6. The Rift : temps cassé, pixels cyan et magenta
		Wall = rgb(110, 215, 255), Trim = rgb(70, 96, 140), Dark = rgb(38, 46, 82), Accent = rgb(255, 80, 230),
		Props = { "Hourglass", "Glitch" },
		Critter = { Kind = "Cube", Body = rgb(70, 220, 255), Belly = rgb(255, 90, 230), Glow = rgb(120, 255, 255) },
	},
	{ -- 7. The Nest : nids et œufs géants
		Wall = rgb(255, 214, 140), Trim = rgb(170, 122, 72), Dark = rgb(112, 78, 50), Accent = rgb(255, 236, 150),
		Props = { "Nest", "BigEgg" },
		Critter = { Kind = "Chick", Body = rgb(255, 222, 90), Belly = rgb(255, 246, 200), Glow = rgb(255, 235, 130) },
	},
	{ -- 8. Star Reef : coraux et bulles
		Wall = rgb(90, 230, 220), Trim = rgb(255, 130, 150), Dark = rgb(36, 110, 130), Accent = rgb(255, 232, 140),
		Props = { "Coral", "Bubbles" },
		Critter = { Kind = "Fish", Body = rgb(255, 150, 80), Belly = rgb(255, 240, 220), Glow = rgb(120, 255, 240) },
	},
	{ -- 9. Storm Halo : nuages d'orage et éclairs
		Wall = rgb(150, 120, 255), Trim = rgb(86, 80, 130), Dark = rgb(48, 44, 84), Accent = rgb(255, 236, 90),
		Props = { "StormCloud", "Rod" },
		Critter = { Kind = "Spark", Body = rgb(255, 228, 80), Belly = rgb(255, 250, 200), Glow = rgb(255, 245, 130) },
	},
	{ -- 10. Clockwork Belt : rouages de laiton et vapeur
		Wall = rgb(240, 180, 100), Trim = rgb(196, 140, 60), Dark = rgb(96, 70, 48), Accent = rgb(90, 230, 210),
		Props = { "Gear", "Pipe" },
		Critter = { Kind = "Drone", Body = rgb(214, 160, 70), Belly = rgb(255, 226, 150), Glow = rgb(100, 240, 220) },
	},
	{ -- 11. Candy Comet : sucettes et sucres d'orge
		Wall = rgb(255, 150, 200), Trim = rgb(255, 246, 250), Dark = rgb(220, 70, 120), Accent = rgb(130, 232, 255),
		Props = { "Lollipop", "CandyCane", "Gumdrop" },
		Critter = { Kind = "Saucer", Body = rgb(255, 120, 180), Belly = rgb(255, 246, 180), Glow = rgb(140, 235, 255) },
	},
	{ -- 12. Mushroom Moon : champignons lumineux
		Wall = rgb(120, 235, 210), Trim = rgb(150, 110, 200), Dark = rgb(70, 50, 110), Accent = rgb(140, 255, 220),
		Props = { "Mushroom", "Spores" },
		Critter = { Kind = "Fairy", Body = rgb(230, 80, 90), Belly = rgb(250, 240, 225), Glow = rgb(150, 255, 225) },
	},
	{ -- 13. Jade Temple : colonnes de jade et or
		Wall = rgb(90, 220, 150), Trim = rgb(236, 190, 70), Dark = rgb(34, 110, 80), Accent = rgb(255, 226, 110),
		Props = { "Pillar", "Torii", "Idol" },
		Critter = { Kind = "Dragon", Body = rgb(60, 190, 130), Belly = rgb(255, 214, 90), Glow = rgb(255, 232, 130) },
	},
	{ -- 14. Phantom Mist : lanternes, citrouilles et fantômes
		Wall = rgb(110, 235, 220), Trim = rgb(70, 76, 110), Dark = rgb(40, 42, 70), Accent = rgb(120, 255, 235),
		Props = { "Lantern", "Pumpkin", "Tomb" },
		Critter = { Kind = "Ghost", Body = rgb(240, 252, 255), Belly = rgb(190, 240, 240), Glow = rgb(120, 255, 235) },
	},
}

-- Ce qui grandit avec l'anneau (k = 0 à l'anneau 1, 1 au dernier)
Themes.Wall = {
	Height = { 46, 72 }, -- hauteur de la paroi
	Transparency = { 0.76, 0.66 }, -- légèrement opaque (0.9 avant le 27 nov.) : on voit encore le décor à travers
	StudTransparency = 0.45,
	Thickness = 0.5,
	Rail = { 1.8, 3 }, -- épaisseur des rails du haut et du bas
	Post = { 3.5, 6 }, -- largeur des piliers (un à chaque pas de Config.Map.BuoySpacing)
	PropScale = { 1, 2.6 }, -- taille des décors
	PropEvery = { 44, 62 }, -- studs entre deux décors, de chaque côté
	Gate = { 14, 44 }, -- hauteur de l'arche du portail au-dessus du mur
}
Themes.Critters = {
	Count = { 7, 18 }, -- créatures par biome
	Size = { 2.2, 4 }, -- taille du corps
	BigFrom = 5, -- à partir de cet anneau : une géante qui croise au-dessus du couloir
	BigScale = { 3.5, 7 },
	Range = 420, -- studs : au-delà de la caméra, elles ne sont pas animées
}

function Themes.Get(i: number)
	return Themes.List[math.clamp(i, 1, #Themes.List)]
end

-- Mélange selon l'anneau (1 à n)
function Themes.Lerp(range: { number }, i: number, n: number): number
	local k = if n > 1 then (i - 1) / (n - 1) else 0
	return range[1] + (range[2] - range[1]) * k
end

return Themes
