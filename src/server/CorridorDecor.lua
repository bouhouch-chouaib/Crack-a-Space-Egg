-- Murs et décors du couloir, biome par biome (27 nov., shared/CorridorThemes).
-- Pour chaque anneau, de son entrée au milieu du vide qui le sépare du suivant :
--   - une paroi teintée, légèrement opaque, avec des picots de sa couleur ;
--   - des délimitations : un rail en haut, un rail en bas, un pilier à lanterne à chaque pas ;
--   - un portail à l'entrée (deux tours et une arche, avec l'emblème du biome au sommet) ;
--   - des décors à thème : sur le haut du mur et sur de petites îles qui flottent juste derrière.
-- Tout grandit d'anneau en anneau (hauteur du mur, piliers, décors, portail) : chaque biome est plus
-- impressionnant que le précédent. Rien ne bloque (on peut tout tenter à ses risques) : ni collision,
-- ni requête, ni contact. Les petites créatures volantes sont faites chez le client (Critters.client).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Themes = require(ReplicatedStorage.Shared.CorridorThemes)

local CorridorDecor = {}

local M = Config.Map
local STUDS = "rbxassetid://99589690361139"
local GLOW = "rbxassetid://103844906730878"
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(26, 24, 34)
local rgb = Color3.fromRGB
local FACES = Enum.NormalId:GetEnumItems()
local UP = CFrame.Angles(0, 0, math.pi / 2) -- cylindre debout

-- KIT DE CONSTRUCTION ----------------------------------------------------------------------------
-- Pièces posées dans le repère « origin » (y = 0 au pied, +Z vers le centre du couloir), à l'échelle s.

type Kit = {
	block: (number, number, number, number, number, number, Color3, CFrame?) -> Part,
	wedge: (number, number, number, number, number, number, Color3, CFrame?) -> Part,
	cyl: (number, number, number, number, number, Color3, CFrame?) -> Part,
	ball: (number, number, number, number, Color3) -> Part,
	glow: (Part) -> Part,
	origin: CFrame,
	s: number,
	parent: Instance,
}

local function studs(p: BasePart, tile: number)
	for _, face in ipairs(FACES) do
		local t = Instance.new("Texture")
		t.Name = "Studs"
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = tile
		t.StudsPerTileV = tile
		t.ZIndex = 2
		t.Parent = p
	end
end

local function base(shape: Enum.PartType?, size: Vector3, cf: CFrame, color: Color3, parent: Instance, class: string?): Part
	local p = Instance.new(class or "Part") :: Part
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	-- picots sur les pièces assez grandes (les petits détails restent lisses)
	if math.min(size.X, size.Y, size.Z) >= 1.5 then
		studs(p, 2)
	end
	p.Parent = parent
	return p
end

local function kit(parent: Instance, origin: CFrame, s: number): Kit
	local k = {} :: any
	k.origin, k.s, k.parent = origin, s, parent
	function k.block(sx, sy, sz, x, y, z, color, rot)
		return base(nil, Vector3.new(sx, sy, sz) * s, origin * CFrame.new(x * s, y * s, z * s) * (rot or CFrame.identity), color, parent)
	end
	function k.wedge(sx, sy, sz, x, y, z, color, rot)
		return base(nil, Vector3.new(sx, sy, sz) * s, origin * CFrame.new(x * s, y * s, z * s) * (rot or CFrame.identity), color, parent, "WedgePart")
	end
	-- cylindre debout (d = diamètre, h = hauteur) ; rot le couche ou l'incline
	function k.cyl(d, h, x, y, z, color, rot)
		return base(Enum.PartType.Cylinder, Vector3.new(h, d, d) * s, origin * CFrame.new(x * s, y * s, z * s) * (rot or CFrame.identity) * UP, color, parent)
	end
	function k.ball(d, x, y, z, color)
		return base(Enum.PartType.Ball, Vector3.one * d * s, origin * CFrame.new(x * s, y * s, z * s), color, parent)
	end
	-- petite touche lumineuse (le néon reste réservé aux détails)
	function k.glow(p: Part)
		p.Material = Enum.Material.Neon
		for _, t in ipairs(p:GetChildren()) do
			if t:IsA("Texture") then
				t:Destroy()
			end
		end
		return p
	end
	return k
end

local function emitter(p: BasePart, color: Color3, size: number, rate: number, speed: number, life: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = GLOW
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(1, size) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(life * 0.7, life)
	e.Rate = rate
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(18, 18)
	e.EmissionDirection = Enum.NormalId.Top
	e.LightEmission = 0.6
	e.LightInfluence = 0
	e.Parent = p
	return e
end

-- Sous-modèle qui tourne sur lui-même chez le client (Critters.client, étiquette « DecorSpin ») :
-- son repère est le centre de rotation, il tourne autour de son axe Z (face au couloir)
local function spinner(k: Kit, x: number, y: number, z: number, speed: number): Kit
	local m = Instance.new("Model")
	m.Name = "Spin"
	local center = k.origin * CFrame.new(x * k.s, y * k.s, z * k.s)
	m.WorldPivot = center
	m:SetAttribute("Speed", speed)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- il arrive entier chez le client, qui le fait tourner d'un bloc
	m.Parent = k.parent
	CollectionService:AddTag(m, "DecorSpin")
	return kit(m, center, k.s)
end

-- DÉCORS -----------------------------------------------------------------------------------------
-- Chaque constructeur reçoit le kit, le thème et le hasard ; il construit un décor d'environ 12 de haut.

local PROPS: { [string]: (Kit, any, Random) -> () } = {}

function PROPS.Spire(k, T, rng)
	local tilt = CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 3), rng:NextNumber(-0.12, 0.12))
	k.block(6, 5, 6, 0, 2.5, 0, T.Dark, tilt)
	k.block(4.6, 5, 4.6, 0.3, 7, 0, T.Trim, tilt * CFrame.Angles(0, 0.5, 0))
	k.block(3.2, 4.5, 3.2, 0.5, 11.4, 0.2, T.Dark, tilt * CFrame.Angles(0, 1, 0))
	k.block(1.8, 3.2, 1.8, 0.7, 15, 0.3, T.Trim, tilt)
	k.ball(2.2, 4, 1.2, 1.5, T.Trim)
	k.glow(k.ball(0.9, 0.7, 17.2, 0.3, T.Accent))
end

function PROPS.Pebbles(k, T, rng)
	for i = 1, 5 do
		k.ball(rng:NextNumber(1.6, 3.6), rng:NextNumber(-4, 4), 1.5 + i * 2.2, rng:NextNumber(-2, 2), if i % 2 == 0 then T.Trim else T.Dark)
	end
	k.glow(k.ball(0.8, 0, 13.5, 0, T.Accent))
end

function PROPS.Crystal(k, T, rng)
	local ice = rgb(196, 238, 255)
	for i = 1, 5 do
		local h = rng:NextNumber(7, 14)
		local w = rng:NextNumber(1.6, 2.8)
		local rot = CFrame.Angles(rng:NextNumber(-0.45, 0.45), rng:NextNumber(0, 3), rng:NextNumber(-0.45, 0.45))
		local p = k.block(w, h, w, rng:NextNumber(-2, 2), h * 0.42, rng:NextNumber(-1.5, 1.5), if i % 2 == 0 then ice else T.Wall, rot * CFrame.Angles(0, math.pi / 4, 0))
		p.Reflectance = 0.25
		p.Transparency = 0.12
	end
	k.block(7, 1.6, 6, 0, 0.8, 0, T.Trim)
end

function PROPS.Snow(k, T)
	-- bonhomme de neige
	k.ball(6, 0, 3, 0, WHITE)
	k.ball(4.4, 0, 7.4, 0, WHITE)
	k.ball(3.2, 0, 10.6, 0, WHITE)
	k.ball(0.6, -0.6, 11, 1.4, BLACK)
	k.ball(0.6, 0.6, 11, 1.4, BLACK)
	k.block(0.5, 0.5, 1.6, 0, 10.4, 1.9, rgb(255, 150, 50))
	k.cyl(2.6, 0.4, 0, 12.1, 0, T.Dark)
	k.cyl(1.7, 1.6, 0, 13, 0, T.Dark)
end

function PROPS.Volcano(k, T)
	k.cyl(12, 3, 0, 1.5, 0, T.Dark)
	k.cyl(9.2, 3, 0, 4.5, 0, T.Trim)
	k.cyl(6.6, 3, 0, 7.5, 0, T.Dark)
	k.cyl(4.4, 2.2, 0, 10.1, 0, T.Trim)
	local lava = k.glow(k.cyl(3.2, 0.6, 0, 11.3, 0, T.Accent))
	emitter(lava, T.Wall, 3 * k.s, 5, 9 * k.s, 1.6)
	-- coulées de lave
	k.glow(k.block(1, 5, 0.5, 1.2, 8.6, 2.6, T.Wall, CFrame.Angles(0.35, 0, 0)))
	k.glow(k.block(0.8, 4, 0.5, -1.8, 5.4, 4.1, T.Accent, CFrame.Angles(0.35, 0, 0)))
end

function PROPS.LavaRock(k, T, rng)
	local rot = CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3))
	k.block(7, 6, 6, 0, 3.4, 0, T.Dark, rot)
	k.block(4.5, 4.5, 4.5, 1.5, 8, 0.5, T.Trim, rot * CFrame.Angles(0.4, 0.6, 0))
	k.glow(k.block(0.5, 4.5, 0.4, 0.5, 3.6, 3.1, T.Accent, CFrame.Angles(0, 0, 0.5)))
	k.glow(k.block(0.5, 3, 0.4, -1.4, 4.5, 3.1, T.Wall, CFrame.Angles(0, 0, -0.6)))
end

function PROPS.Puff(k, T)
	local pale = T.Wall:Lerp(WHITE, 0.55)
	k.ball(7, 0, 5, 0, pale)
	k.ball(5.6, 3.6, 4.2, 0.5, T.Wall:Lerp(WHITE, 0.3))
	k.ball(5, -3.6, 4, -0.4, pale)
	k.ball(4.6, 1, 7.6, 0, WHITE)
	-- étoile
	k.glow(k.block(0.8, 4.4, 0.8, 4.4, 11, 0.5, T.Accent, CFrame.Angles(0, 0, 0.3)))
	k.glow(k.block(4.4, 0.8, 0.8, 4.4, 11, 0.5, T.Accent, CFrame.Angles(0, 0, 0.3)))
end

function PROPS.Planet(k, T)
	k.ball(7.5, 0, 6, 0, T.Trim)
	k.cyl(13, 0.5, 0, 6, 0, T.Accent, CFrame.Angles(0.5, 0, 0.3))
	k.ball(2.2, 6.5, 10, 0, T.Wall:Lerp(WHITE, 0.4))
	k.ball(1, -6, 2.5, 1, WHITE)
end

function PROPS.Fang(k)
	local bone = rgb(246, 240, 224)
	k.block(8, 2.4, 6, 0, 1.2, 0, rgb(160, 60, 100))
	-- croc recourbé vers le couloir
	for i = 0, 4 do
		local w = 4.4 - i * 0.8
		k.block(w, 3.4, w, 0, 3.6 + i * 2.9, i * i * 0.36, bone, CFrame.Angles(i * 0.16, 0, 0))
	end
	k.block(2.4, 4, 2.4, -3.2, 4.2, 0.4, bone, CFrame.Angles(0.15, 0, 0.2))
	k.block(2.4, 4, 2.4, 3.2, 4.2, 0.4, bone, CFrame.Angles(0.15, 0, -0.2))
end

function PROPS.Eye(k, T)
	k.cyl(2.4, 4, 0, 2, 0, T.Dark)
	k.ball(7.5, 0, 7, 0, WHITE)
	k.ball(4.4, 0, 7, 2.2, T.Accent)
	k.ball(2.2, 0, 7, 3.6, BLACK)
	k.block(8.4, 1.6, 6, 0, 10.6, 0.4, T.Trim, CFrame.Angles(0.25, 0, 0)) -- paupière
end

function PROPS.Hourglass(k, T)
	local gold = rgb(240, 200, 92)
	k.cyl(8, 0.9, 0, 0.45, 0, gold)
	local steps = { { 6, 1.9 }, { 4.4, 3.6 }, { 2.8, 5.2 }, { 1.4, 6.6 }, { 2.8, 8 }, { 4.4, 9.6 }, { 6, 11.3 } }
	for i, st in ipairs(steps) do
		local p = k.cyl(st[1], 1.7, 0, st[2], 0, if i <= 3 then T.Accent else T.Wall)
		p.Transparency = 0.25
	end
	k.cyl(8, 0.9, 0, 12.7, 0, gold)
	for _, a in ipairs({ 0, 2.1, 4.2 }) do
		k.cyl(0.6, 12, math.cos(a) * 3.6, 6.5, math.sin(a) * 3.6, gold)
	end
end

function PROPS.Glitch(k, T, rng)
	for i = 1, 8 do
		local sz = rng:NextNumber(1.3, 3.6)
		local p = k.block(sz, sz, sz, rng:NextNumber(-4.5, 4.5), rng:NextNumber(1.5, 13), rng:NextNumber(-2.5, 2.5), if i % 3 == 0 then T.Accent elseif i % 3 == 1 then T.Wall else T.Dark)
		if i % 4 == 0 then
			k.glow(p)
		end
	end
end

function PROPS.Nest(k, T)
	k.cyl(11.5, 1.8, 0, 0.9, 0, T.Dark)
	k.cyl(12.6, 1.2, 0, 2.2, 0, T.Trim)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		k.block(4.6, 0.8, 0.8, math.cos(a) * 5.8, 3, math.sin(a) * 5.8, if i % 2 == 0 then T.Dark else T.Trim, CFrame.Angles(0, -a + 1.3, 0.3))
	end
	local cream = rgb(255, 244, 220)
	k.ball(4.4, -2.2, 4.4, 0.8, cream)
	k.ball(4.4, 2.4, 4.4, 0.4, T.Accent)
	k.ball(4, 0, 4.6, -2.6, cream)
end

function PROPS.BigEgg(k, T)
	local cream = rgb(255, 244, 220)
	k.cyl(8, 1.4, 0, 0.7, 0, T.Dark)
	k.ball(8.4, 0, 5.2, 0, cream)
	k.ball(7, 0, 8.4, 0, cream)
	k.ball(5, 0, 10.8, 0, cream)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k.ball(1.5, math.cos(a) * 3.9, 5.6 + (i % 2) * 2.2, math.sin(a) * 3.9, T.Trim)
	end
	k.glow(k.block(0.4, 2.6, 0.3, 0.3, 9.6, 3.2, T.Accent, CFrame.Angles(0, 0, 0.6)))
	k.glow(k.block(0.4, 2.2, 0.3, -0.7, 8.2, 3.6, T.Accent, CFrame.Angles(0, 0, -0.6)))
end

function PROPS.Coral(k, T, rng)
	local colors = { T.Trim, rgb(255, 170, 90), rgb(190, 120, 255) }
	for c = 1, 2 do
		local col = colors[c + rng:NextInteger(0, 1)]
		local ox = if c == 1 then -1.8 else 2.4
		local h = if c == 1 then 7 else 5
		k.cyl(1.8, h, ox, h / 2, 0, col)
		for i = 1, 3 do
			local side = if i % 2 == 0 then 1 else -1
			local y = h * (0.45 + i * 0.2)
			k.cyl(1.3, 4, ox + side * 1.5, y + 1, 0, col, CFrame.Angles(0, 0, -side * 0.7))
			k.ball(1.9, ox + side * 2.9, y + 2.7, 0, T.Accent)
		end
		k.ball(2, ox, h + 0.6, 0, T.Accent)
	end
	k.cyl(9, 1.2, 0, 0.6, 0, T.Dark)
end

function PROPS.Bubbles(k, _T, rng)
	for i = 1, 6 do
		local p = k.ball(rng:NextNumber(1.6, 4.4), rng:NextNumber(-3.5, 3.5), 1.5 + i * 2, rng:NextNumber(-2, 2), rgb(200, 250, 255))
		p.Transparency = 0.55
		p.Reflectance = 0.25
	end
end

function PROPS.StormCloud(k, T)
	local dark = T.Trim
	k.ball(7.5, 0, 10, 0, dark)
	k.ball(6, 3.8, 9.4, 0.5, T.Dark)
	k.ball(5.6, -3.8, 9.2, -0.4, dark)
	k.ball(5, 1, 12.6, 0, T.Dark)
	-- éclair en zigzag
	k.glow(k.block(1, 3.6, 0.8, 0.6, 5.8, 1, T.Accent, CFrame.Angles(0, 0, 0.5)))
	k.glow(k.block(1, 3.4, 0.8, -0.3, 3.4, 1, T.Accent, CFrame.Angles(0, 0, -0.6)))
	k.glow(k.block(0.9, 3, 0.8, 0.5, 1.2, 1, T.Accent, CFrame.Angles(0, 0, 0.45)))
end

function PROPS.Rod(k, T)
	k.block(4, 1.4, 4, 0, 0.7, 0, T.Dark)
	k.cyl(1.3, 12, 0, 7.4, 0, T.Trim)
	for i = 1, 3 do
		k.cyl(3.6 - i * 0.5, 0.6, 0, 3 + i * 2.8, 0, T.Dark)
	end
	local tip = k.glow(k.ball(2.2, 0, 14.4, 0, T.Accent))
	emitter(tip, T.Accent, 2.4 * k.s, 3, 5 * k.s, 0.7).SpreadAngle = Vector2.new(180, 180)
end

function PROPS.Gear(k, T)
	k.block(1.8, 7, 1.8, 0, 3.5, -1.2, T.Dark)
	k.block(5, 1.2, 4, 0, 0.6, -1, T.Dark)
	local g = spinner(k, 0, 8, 0, 0.5)
	g.cyl(9, 1.6, 0, 0, 0, T.Trim, CFrame.Angles(math.pi / 2, 0, 0))
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		g.block(1.9, 2.2, 1.6, math.cos(a) * 5.2, math.sin(a) * 5.2, 0, T.Trim, CFrame.Angles(0, 0, a - math.pi / 2))
	end
	g.cyl(3.2, 2.2, 0, 0, 0, T.Dark, CFrame.Angles(math.pi / 2, 0, 0))
	g.glow(g.cyl(1.2, 2.5, 0, 0, 0, T.Accent, CFrame.Angles(math.pi / 2, 0, 0)))
	-- petit rouage qui tourne dans l'autre sens
	local g2 = spinner(k, 5.6, 3.4, 0.2, -0.9)
	g2.cyl(4.6, 1.4, 0, 0, 0, T.Wall, CFrame.Angles(math.pi / 2, 0, 0))
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		g2.block(1.3, 1.5, 1.4, math.cos(a) * 2.8, math.sin(a) * 2.8, 0, T.Wall, CFrame.Angles(0, 0, a - math.pi / 2))
	end
end

function PROPS.Pipe(k, T)
	k.cyl(4.4, 1, 0, 0.5, 0, T.Dark)
	k.cyl(3, 10, 0, 6, 0, T.Trim)
	k.cyl(3.8, 0.8, 0, 4, 0, T.Dark)
	k.cyl(3.8, 0.8, 0, 8.4, 0, T.Dark)
	k.ball(3.6, 0, 11.4, 0, T.Trim)
	k.cyl(3, 4, 0, 11.4, 2.2, T.Trim, CFrame.Angles(math.pi / 2, 0, 0))
	local mouth = k.cyl(3.8, 0.8, 0, 11.4, 4.4, T.Dark, CFrame.Angles(math.pi / 2, 0, 0))
	local steam = emitter(mouth, rgb(240, 246, 255), 4 * k.s, 4, 6 * k.s, 1.8)
	steam.EmissionDirection = Enum.NormalId.Right
	steam.LightEmission = 0.1
end

function PROPS.Lollipop(k, T, rng)
	local candy = ({ T.Dark, rgb(120, 220, 255), rgb(170, 110, 255), rgb(255, 190, 60) })[rng:NextInteger(1, 4)]
	k.cyl(1, 9, 0, 4.5, 0, WHITE)
	local d = spinner(k, 0, 11.5, 0, 0.35)
	d.cyl(7.5, 1.4, 0, 0, 0, candy, CFrame.Angles(math.pi / 2, 0, 0))
	d.cyl(5, 1.7, 0, 0, 0, WHITE, CFrame.Angles(math.pi / 2, 0, 0))
	d.cyl(2.6, 2, 0, 0, 0, candy, CFrame.Angles(math.pi / 2, 0, 0))
	d.block(1.2, 1.2, 2.1, 2.6, 2.6, 0, T.Accent)
	d.block(1.2, 1.2, 2.1, -2.6, -2.6, 0, T.Accent)
end

function PROPS.CandyCane(k)
	local red = rgb(235, 50, 70)
	for i = 0, 6 do
		k.block(1.8, 1.7, 1.8, 0, 0.85 + i * 1.7, 0, if i % 2 == 0 then red else WHITE)
	end
	-- crosse
	for i = 1, 4 do
		local a = i * 0.6
		k.block(1.8, 1.7, 1.8, 1.9 - math.cos(a) * 1.9, 11.5 + math.sin(a) * 1.9, 0, if i % 2 == 0 then WHITE else red, CFrame.Angles(0, 0, -a))
	end
end

function PROPS.Gumdrop(k, T, rng)
	local col = ({ rgb(120, 230, 120), rgb(180, 120, 255), rgb(255, 170, 60), T.Accent })[rng:NextInteger(1, 4)]
	k.cyl(7, 2.2, 0, 1.1, 0, col)
	k.cyl(5.8, 1.8, 0, 3.1, 0, col)
	k.cyl(4, 1.4, 0, 4.7, 0, col)
	k.cyl(2, 0.8, 0, 5.8, 0, col:Lerp(WHITE, 0.5))
	k.ball(2.4, 5, 1.2, 1, T.Dark)
	k.ball(1.8, -4.6, 0.9, -1, WHITE)
end

function PROPS.Mushroom(k, T, rng)
	local cap = ({ rgb(232, 70, 80), T.Trim, rgb(70, 190, 240) })[rng:NextInteger(1, 3)]
	local cream = rgb(250, 240, 222)
	k.cyl(2.8, 7, 0, 3.5, 0, cream)
	k.glow(k.cyl(7, 0.35, 0, 7.1, 0, T.Accent))
	k.cyl(11, 1.7, 0, 8.1, 0, cap)
	k.cyl(8.6, 1.6, 0, 9.7, 0, cap)
	k.cyl(5.4, 1.4, 0, 11.1, 0, cap)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		k.cyl(1.7, 0.3, math.cos(a) * 4, 9.05, math.sin(a) * 4, WHITE)
	end
	k.cyl(1.9, 0.3, 0, 11.9, 0, WHITE)
	-- petit champignon à côté
	k.cyl(1.2, 2.6, 4.6, 1.3, 1.6, cream)
	k.cyl(4, 1.1, 4.6, 3.1, 1.6, cap)
	k.cyl(2.4, 0.9, 4.6, 4, 1.6, cap)
end

function PROPS.Spores(k, T, rng)
	for i = 1, 7 do
		k.glow(k.ball(rng:NextNumber(0.7, 1.5), rng:NextNumber(-4, 4), 1 + i * 1.8, rng:NextNumber(-2.5, 2.5), T.Accent))
	end
	local src = k.ball(2.4, 0, 1.4, 0, T.Trim)
	local e = emitter(src, T.Accent, 1.4 * k.s, 3, 3 * k.s, 4)
	e.SpreadAngle = Vector2.new(60, 60)
end

function PROPS.Pillar(k, T, rng)
	local h = rng:NextNumber(7, 11.5)
	k.block(5.4, 1.5, 5.4, 0, 0.75, 0, T.Trim)
	k.cyl(3.6, h, 0, 1.5 + h / 2, 0, T.Dark)
	k.cyl(4.2, 0.7, 0, 1.5 + h * 0.3, 0, T.Trim)
	k.cyl(4.2, 0.7, 0, 1.5 + h * 0.7, 0, T.Trim)
	k.block(5.4, 1.5, 5.4, 0, 2.25 + h, 0, T.Trim)
	k.glow(k.ball(1.6, 0, 3.9 + h, 0, T.Accent))
end

function PROPS.Torii(k, T)
	k.cyl(2, 11, -5, 5.5, 0, T.Dark)
	k.cyl(2, 11, 5, 5.5, 0, T.Dark)
	k.block(13, 1.2, 1.6, 0, 8.8, 0, T.Dark)
	k.block(16, 1.5, 2.2, 0, 11.4, 0, T.Trim)
	k.block(18.5, 0.9, 2.8, 0, 12.7, 0, T.Trim)
	k.block(3.4, 1.2, 3.4, -5, 0.6, 0, T.Trim)
	k.block(3.4, 1.2, 3.4, 5, 0.6, 0, T.Trim)
	k.glow(k.block(1.4, 1.4, 0.4, 0, 10.1, 1, T.Accent))
end

function PROPS.Idol(k, T)
	k.block(6, 1.6, 6, 0, 0.8, 0, T.Dark)
	k.ball(6, 0, 4.4, 0, T.Trim)
	k.ball(4.2, 0, 8.4, 0.2, T.Trim)
	k.ball(0.7, -0.9, 8.8, 2.1, BLACK)
	k.ball(0.7, 0.9, 8.8, 2.1, BLACK)
	k.glow(k.ball(0.8, 0, 9.8, 2, T.Wall))
	k.ball(1.8, -2.4, 9.8, 0, T.Trim)
	k.ball(1.8, 2.4, 9.8, 0, T.Trim)
end

function PROPS.Lantern(k, T)
	k.block(2.6, 1, 2.6, 0, 0.5, 0, T.Dark)
	k.cyl(0.9, 10, 0, 5.5, 0, T.Trim)
	k.block(0.7, 0.7, 4, 0, 10.2, 1.8, T.Trim)
	k.block(2.2, 0.5, 2.2, 0, 9.3, 3.4, T.Dark)
	local lamp = k.glow(k.block(1.8, 2.4, 1.8, 0, 7.9, 3.4, T.Accent))
	k.block(2.2, 0.5, 2.2, 0, 6.5, 3.4, T.Dark)
	local light = Instance.new("PointLight")
	light.Color = T.Accent
	light.Range = 16 * k.s
	light.Brightness = 0.8
	light.Shadows = false
	light.Parent = lamp
end

function PROPS.Pumpkin(k, T)
	local orange = rgb(255, 140, 40)
	k.ball(6, 0, 3, 0, orange)
	k.ball(5.2, -1.9, 3, 0, orange:Lerp(BLACK, 0.12))
	k.ball(5.2, 1.9, 3, 0, orange:Lerp(BLACK, 0.12))
	k.block(1, 1.6, 1, 0, 6.3, 0, rgb(90, 160, 70), CFrame.Angles(0, 0, 0.25))
	-- visage qui brille
	k.glow(k.block(1, 1, 0.4, -1.2, 3.8, 2.9, T.Accent, CFrame.Angles(0, 0, math.pi / 4)))
	k.glow(k.block(1, 1, 0.4, 1.2, 3.8, 2.9, T.Accent, CFrame.Angles(0, 0, math.pi / 4)))
	k.glow(k.block(2.8, 0.6, 0.4, 0, 2.2, 2.95, T.Accent))
end

function PROPS.Tomb(k, T)
	-- petit fantôme de pierre
	k.cyl(5.2, 5, 0, 2.5, 0, WHITE)
	k.ball(5.2, 0, 5.4, 0, WHITE)
	k.ball(0.9, -1, 5.9, 2.2, BLACK)
	k.ball(0.9, 1, 5.9, 2.2, BLACK)
	k.ball(1.6, -3, 3.6, 0.6, WHITE)
	k.ball(1.6, 3, 3.6, 0.6, WHITE)
	k.glow(k.ball(0.9, 0, 9.6, 0, T.Accent))
end

local function prop(parent: Instance, name: string, origin: CFrame, s: number, T: any, rng: Random)
	local build = PROPS[name]
	if not build then
		return
	end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	build(kit(m, origin, s), T, rng)
end

-- MURS, RAILS, PILIERS -----------------------------------------------------------------------------

-- Début et fin (distance depuis la sortie de la cour) de la zone de chaque anneau
function CorridorDecor.Zones(): { { from: number, to: number } }
	local zones = {}
	local n = #Config.Rings
	local from = 4 -- juste après le mur de la cour
	for i = 1, n do
		local edge = Config.RingDistance(i) + Config.RingWidth(i) / 2
		local to = if i < n then edge + Config.RingGapAfter(i) / 2 else edge
		zones[i] = { from = from, to = to }
		from = to
	end
	return zones
end

local function wallSpan(parent: Instance, T: any, side: number, z0: number, z1: number, H: number, rail: number, transparency: number)
	local x = side * M.CorridorWidth / 2
	local len = z1 - z0
	local zc = M.FrontZ + (z0 + z1) / 2
	local W = Themes.Wall
	local wall = base(nil, Vector3.new(W.Thickness, H, len), CFrame.new(x, 0, zc), T.Wall, parent)
	wall.Name = "Wall"
	wall.Transparency = transparency
	for _, t in ipairs(wall:GetChildren()) do
		t:Destroy()
	end
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local t = Instance.new("Texture")
		t.Name = "Studs"
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = 4
		t.StudsPerTileV = 4
		t.Color3 = T.Wall:Lerp(WHITE, 0.45)
		t.Transparency = W.StudTransparency
		t.Parent = wall
	end
	-- délimitations : rail du haut et rail du bas, avec un filet lumineux
	for _, top in ipairs({ 1, -1 }) do
		local r = base(nil, Vector3.new(rail * 1.3, rail, len), CFrame.new(x, top * (H / 2 + rail / 2), zc), T.Trim, parent)
		r.Name = "Rail"
		local line = base(nil, Vector3.new(rail * 1.3 + 0.2, 0.35, len), CFrame.new(x, top * (H / 2 - 0.4), zc), T.Accent, parent)
		line.Name = "RailLine"
		line.Material = Enum.Material.Neon
	end
end

local function post(parent: Instance, T: any, side: number, z: number, H: number, rail: number, w: number)
	local x = side * M.CorridorWidth / 2
	local zc = M.FrontZ + z
	local full = H + rail * 2
	local m = Instance.new("Model")
	m.Name = "Post"
	m.Parent = parent
	base(nil, Vector3.new(w, full, w), CFrame.new(x, 0, zc), T.Trim, m)
	for _, top in ipairs({ 1, -1 }) do
		base(nil, Vector3.new(w * 1.5, rail * 1.2, w * 1.5), CFrame.new(x, top * (full / 2 + rail * 0.6), zc), T.Dark, m)
	end
	-- lanterne au milieu du pilier (elle remplace les anciennes bouées) et pointe lumineuse au sommet
	local lamp = base(Enum.PartType.Ball, Vector3.one * w * 0.95, CFrame.new(x - side * w * 0.45, 0, zc), T.Accent, m)
	lamp.Material = Enum.Material.Neon
	for _, t in ipairs(lamp:GetChildren()) do
		t:Destroy()
	end
	local tip = base(Enum.PartType.Ball, Vector3.one * w * 0.7, CFrame.new(x, full / 2 + rail * 1.2 + w * 0.35, zc), T.Accent, m)
	tip.Material = Enum.Material.Neon
	for _, t in ipairs(tip:GetChildren()) do
		t:Destroy()
	end
end

-- PORTAIL D'ENTRÉE D'UN BIOME --------------------------------------------------------------------------
-- Deux tours de part et d'autre du couloir, une arche par-dessus et l'emblème du biome au sommet.
local function gate(parent: Instance, T: any, z: number, H: number, rail: number, w: number, rise: number, scale: number, rng: Random)
	local m = Instance.new("Model")
	m.Name = "Gate"
	m.Parent = parent
	local half = M.CorridorWidth / 2
	local zc = M.FrontZ + z
	local tw = w * 2
	local topY = H / 2 + rail + 6 * scale
	for _, side in ipairs({ -1, 1 }) do
		local x = side * half
		base(nil, Vector3.new(tw, H / 2 + topY, tw), CFrame.new(x, (topY - H / 2) / 2, zc), T.Trim, m)
		base(nil, Vector3.new(tw * 1.35, rail * 1.5, tw * 1.35), CFrame.new(x, topY + rail * 0.75, zc), T.Dark, m)
		base(nil, Vector3.new(tw * 1.35, rail * 1.5, tw * 1.35), CFrame.new(x, -H / 2 - rail * 0.75, zc), T.Dark, m)
		-- bandes de couleur sur la tour
		for i = 1, 3 do
			local band = base(nil, Vector3.new(tw + 0.3, 0.6, tw + 0.3), CFrame.new(x, -H / 2 + (H / 2 + topY) * i / 4, zc), T.Accent, m)
			band.Material = Enum.Material.Neon
		end
		-- décor du biome au sommet de chaque tour, tourné vers le couloir
		local face = CFrame.lookAt(Vector3.new(x, topY + rail * 1.5, zc), Vector3.new(0, topY + rail * 1.5, zc))
		prop(m, T.Props[2] or T.Props[1], face, scale * 0.9, T, rng)
	end
	-- arche : une demi-ellipse de tour à tour
	local th = tw * 0.7
	local segments = 16
	local function point(i: number): Vector3
		local a = i / segments * math.pi
		return Vector3.new(-math.cos(a) * half, topY + math.sin(a) * rise, zc)
	end
	for i = 0, segments - 1 do
		local a, b = point(i), point(i + 1)
		local mid = (a + b) / 2
		local seg = base(nil, Vector3.new(th * 1.2, th, (b - a).Magnitude + 0.6), CFrame.lookAt(mid, b), if i % 2 == 0 then T.Trim else T.Dark, m)
		seg.Name = "Arch"
		if i % 4 == 1 then
			local gem = base(Enum.PartType.Ball, Vector3.one * th * 0.7, CFrame.new(mid - Vector3.new(0, th * 0.6, 0)), T.Accent, m)
			gem.Material = Enum.Material.Neon
			for _, t in ipairs(gem:GetChildren()) do
				t:Destroy()
			end
		end
	end
	-- emblème : le grand décor du biome, debout sur le sommet de l'arche, tourné vers ceux qui arrivent
	local apex = Vector3.new(0, topY + rise + th / 2, zc)
	prop(m, T.Props[1], CFrame.lookAt(apex, apex - Vector3.zAxis), scale * 1.9, T, rng)
end

-- CONSTRUCTION -----------------------------------------------------------------------------------------

function CorridorDecor.Build(corridor: Instance)
	local rng = Random.new(20261127) -- graine fixe : le même décor à chaque serveur
	local n = #Config.Rings
	local W = Themes.Wall
	local walls = Instance.new("Folder")
	walls.Name = "Edges"
	walls.Parent = corridor
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decor"
	decorFolder.Parent = corridor
	local half = M.CorridorWidth / 2
	for i, zone in ipairs(CorridorDecor.Zones()) do
		local T = Themes.Get(i)
		local H = Themes.Lerp(W.Height, i, n)
		local rail = Themes.Lerp(W.Rail, i, n)
		local w = Themes.Lerp(W.Post, i, n)
		local scale = Themes.Lerp(W.PropScale, i, n)
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Ring" .. i
		zoneFolder.Parent = walls
		local propsFolder = Instance.new("Folder")
		propsFolder.Name = "Ring" .. i
		propsFolder.Parent = decorFolder
		local len = zone.to - zone.from
		local spans = math.max(1, math.ceil(len / M.BuoySpacing))
		local step = len / spans
		for s = 0, spans - 1 do
			local z0 = zone.from + s * step
			for _, side in ipairs({ -1, 1 }) do
				wallSpan(zoneFolder, T, side, z0, z0 + step, H, rail, Themes.Lerp(W.Transparency, i, n))
				-- le premier pilier d'une zone est la tour du portail (sauf à la sortie de la cour : pas d'arche)
				if s > 0 or i == 1 then
					post(zoneFolder, T, side, z0, H, rail, w)
				end
			end
		end
		if i == n then
			for _, side in ipairs({ -1, 1 }) do
				post(zoneFolder, T, side, zone.to, H, rail, w)
			end
		end
		if i > 1 then
			gate(propsFolder, T, zone.from, H, rail, w, Themes.Lerp(W.Gate, i, n), scale, rng)
		end
		-- décors : en alternance sur le haut du mur et sur une petite île qui flotte juste derrière
		local every = Themes.Lerp(W.PropEvery, i, n)
		local count = math.max(2, math.floor(len / every))
		for _, side in ipairs({ -1, 1 }) do
			for c = 1, count do
				local z = zone.from + (c - 0.5 + rng:NextNumber(-0.25, 0.25)) * len / count
				local name = T.Props[rng:NextInteger(1, #T.Props)]
				local sc = scale * rng:NextNumber(0.85, 1.2)
				local zc = M.FrontZ + z
				if (c + (if side > 0 then 1 else 0)) % 2 == 0 then
					-- sur le haut du mur
					local at = Vector3.new(side * half, H / 2 + rail, zc)
					prop(propsFolder, name, CFrame.lookAt(at, Vector3.new(0, at.Y, zc)), sc, T, rng)
				else
					-- île flottante derrière le mur, à une hauteur au hasard
					local x = side * (half + rng:NextNumber(9, 20) * scale)
					local y = rng:NextNumber(-H * 0.45, H * 0.3)
					local at = Vector3.new(x, y, zc)
					local origin = CFrame.lookAt(at, Vector3.new(0, y, zc))
					local island = Instance.new("Model")
					island.Name = "Island"
					island.Parent = propsFolder
					local k = kit(island, origin, sc)
					k.cyl(12, 1.6, 0, -0.8, 0, T.Trim)
					k.cyl(8.5, 2, 0, -2.6, 0, T.Dark)
					k.cyl(4.5, 2, 0, -4.6, 0, T.Dark)
					prop(island, name, origin, sc, T, rng)
				end
			end
		end
	end
end

return CorridorDecor
