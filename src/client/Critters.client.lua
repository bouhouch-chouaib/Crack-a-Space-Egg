-- Petites créatures extraterrestres qui volent le long du couloir (27 nov., shared/CorridorThemes).
-- Chaque biome a la sienne : boules de poussière, lutins de glace, chauves-souris de braise, méduses
-- d'étoiles, croqueurs, cubes qui clignotent, poussins en coquille, poissons, étincelles, drones à clé,
-- soucoupes en bonbon, fées champignon, dragons de jade, fantômes à lanterne. Plus on avance, plus elles
-- sont nombreuses et grandes ; à partir de l'anneau 5, une géante croise au-dessus du couloir.
-- Tout est local au joueur (rien sur le serveur, rien à envoyer) : elles sont construites pour le biome
-- où il se trouve et ses deux voisins, et suivent un trajet calculé (les mêmes à chaque visite).
-- Purement décoratives : ni collision, ni requête (la foreuse et le grappin passent au travers).
-- Ce script fait aussi tourner les décors étiquetés « DecorSpin » (rouages, sucettes : CorridorDecor).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Themes = require(ReplicatedStorage.Shared:WaitForChild("CorridorThemes"))

local camera = workspace.CurrentCamera
local M = Config.Map
local C = Themes.Critters
local N = #Config.Rings
local STUDS = "rbxassetid://99589690361139"
local SPARKLE = "rbxassetid://138922153683020"
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(24, 22, 32)
local TAU = math.pi * 2
local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis

-- CONSTRUCTION ---------------------------------------------------------------------------------------

type Anim = { weld: Weld, base: CFrame, axis: Vector3, speed: number, amp: number, spin: boolean, phase: number }
type Critter = {
	root: Part,
	anims: { Anim },
	tail: { Part }, -- segments qui suivent le trajet avec un peu de retard (dragon, fantôme)
	gap: number, -- secondes de retard entre deux segments
	center: Vector3,
	radius: Vector3,
	speed: number,
	phase: number,
	bob: number,
}
type Maker = {
	add: (shape: string, size: Vector3, cf: CFrame, color: Color3, hinge: CFrame?) -> (Part, Weld),
	anim: (weld: Weld, axis: Vector3, speed: number, amp: number, spin: boolean?, phase: number?) -> (),
	glow: (p: Part) -> Part,
	seg: (d: number, color: Color3) -> Part,
}

local function newPart(shape: string, size: Vector3, color: Color3, parent: Instance): Part
	local p = Instance.new(if shape == "Wedge" then "WedgePart" else "Part") :: Part
	if shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "Cyl" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	-- picots sur les pièces assez grandes (les géantes)
	if math.min(size.X, size.Y, size.Z) >= 3 then
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local t = Instance.new("Texture")
			t.Name = "Studs"
			t.Texture = STUDS
			t.Face = face
			t.StudsPerTileU = 2
			t.StudsPerTileV = 2
			t.ZIndex = 2
			t.Parent = p
		end
	end
	p.Parent = parent
	return p
end

local function maker(model: Model, root: Part, anims: { Anim }, tail: { Part }): Maker
	local mk = {} :: any
	-- pièce soudée à la racine ; hinge = charnière autour de laquelle elle peut tourner (repère de la racine)
	function mk.add(shape, size, cf, color, hinge)
		local p = newPart(shape, size, color, model)
		local w = Instance.new("Weld")
		w.Part0 = root
		w.Part1 = p
		if hinge then
			w.C0 = hinge
			w.C1 = cf:Inverse() * hinge
		else
			w.C0 = cf
		end
		w.Parent = p
		return p, w
	end
	function mk.anim(weld, axis, speed, amp, spin, phase)
		table.insert(anims, { weld = weld, base = weld.C0, axis = axis, speed = speed, amp = amp, spin = spin == true, phase = phase or 0 })
	end
	function mk.glow(p)
		p.Material = Enum.Material.Neon
		for _, t in ipairs(p:GetChildren()) do
			if t:IsA("Texture") then
				t:Destroy()
			end
		end
		return p
	end
	-- segment de queue : pièce libre, posée à chaque image sur le trajet
	function mk.seg(d, color)
		local p = newPart("Ball", Vector3.one * d, color, model)
		p.Anchored = true
		table.insert(tail, p)
		return p
	end
	return mk
end

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- Yeux mignons : deux gros yeux blancs à pupille noire, sur l'avant (−Z)
local function eyes(mk: Maker, S: number, y: number, z: number, spread: number?)
	local dx = (spread or 0.24) * S
	for _, side in ipairs({ -1, 1 }) do
		mk.add("Ball", Vector3.one * 0.36 * S, CFrame.new(side * dx, y * S, z * S), WHITE)
		mk.add("Ball", Vector3.one * 0.19 * S, CFrame.new(side * dx, y * S, (z - 0.13) * S), BLACK)
	end
end

-- Paire d'ailes qui battent
local function wings(mk: Maker, S: number, color: Color3, w: number, d: number, y: number, speed: number, transparency: number?)
	for _, side in ipairs({ -1, 1 }) do
		local hinge = CFrame.new(side * 0.42 * S, y * S, 0)
		local p, weld = mk.add("Block", v(w * S, 0.07 * S, d * S), CFrame.new(side * (0.42 + w / 2) * S, y * S, 0), color, hinge)
		p.Transparency = transparency or 0
		mk.anim(weld, Z, speed, side * 0.75, false, 0)
	end
end

-- Hélice sur le dessus
local function propeller(mk: Maker, S: number, y: number, color: Color3)
	mk.add("Cyl", v(0.5 * S, 0.1 * S, 0.1 * S), CFrame.new(0, (y - 0.2) * S, 0) * CFrame.Angles(0, 0, math.pi / 2), BLACK)
	local _, weld = mk.add("Block", v(1.5 * S, 0.06 * S, 0.24 * S), CFrame.new(0, y * S, 0), color)
	mk.anim(weld, Y, 22, 0, true)
end

local KINDS: { [string]: (Maker, number, any, boolean) -> () } = {}

function KINDS.Puff(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.add("Ball", Vector3.one * 0.62 * S, CFrame.new(0, -0.16 * S, -0.2 * S), T.Belly)
	eyes(mk, S, 0.12, -0.4)
	wings(mk, S, T.Belly, 0.6, 0.42, 0.1, 16)
	mk.add("Cyl", v(0.4 * S, 0.05 * S, 0.05 * S), CFrame.new(0, 0.62 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), T.Body)
	mk.glow((mk.add("Ball", Vector3.one * 0.18 * S, CFrame.new(0, 0.86 * S, 0), T.Glow)))
end

function KINDS.Sprite(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.add("Ball", Vector3.one * 0.6 * S, CFrame.new(0, -0.18 * S, -0.2 * S), T.Belly)
	eyes(mk, S, 0.1, -0.4)
	wings(mk, S, T.Glow, 0.75, 0.5, 0.15, 20, 0.35)
	-- couronne de glace
	for i = -1, 1 do
		local p = mk.add("Block", v(0.16 * S, (0.5 - math.abs(i) * 0.14) * S, 0.16 * S), CFrame.new(i * 0.22 * S, 0.62 * S, 0) * CFrame.Angles(0, math.pi / 4, i * -0.3), T.Belly)
		p.Reflectance = 0.3
	end
end

function KINDS.Bat(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.glow((mk.add("Ball", Vector3.one * 0.42 * S, CFrame.new(0, -0.2 * S, -0.3 * S), T.Belly)))
	eyes(mk, S, 0.14, -0.4)
	wings(mk, S, T.Belly, 1.1, 0.7, 0.05, 11)
	for _, side in ipairs({ -1, 1 }) do
		mk.add("Wedge", v(0.14 * S, 0.42 * S, 0.24 * S), CFrame.new(side * 0.28 * S, 0.58 * S, 0), T.Body)
	end
end

function KINDS.Jelly(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.new(0, 0.1 * S, 0), T.Body).Transparency = 0.15
	mk.add("Cyl", v(0.22 * S, 0.94 * S, 0.94 * S), CFrame.new(0, -0.22 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), T.Belly)
	eyes(mk, S, 0.14, -0.38)
	mk.glow((mk.add("Ball", Vector3.one * 0.3 * S, CFrame.new(0, 0.2 * S, 0.05 * S), T.Glow)))
	-- tentacules qui ondulent
	for i = 1, 5 do
		local a = i / 5 * TAU
		local hinge = CFrame.new(math.cos(a) * 0.3 * S, -0.32 * S, math.sin(a) * 0.3 * S)
		local _, weld = mk.add("Block", v(0.1 * S, 0.9 * S, 0.1 * S), hinge * CFrame.new(0, -0.45 * S, 0), if i % 2 == 0 then T.Body else T.Belly, hinge)
		mk.anim(weld, X, 3, 0.35, false, i)
	end
end

function KINDS.Chomper(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	eyes(mk, S, 0.26, -0.34, 0.2)
	-- grande bouche et dents
	mk.add("Block", v(0.62 * S, 0.2 * S, 0.2 * S), CFrame.new(0, -0.14 * S, -0.42 * S), BLACK)
	for i = -1, 1 do
		mk.add("Wedge", v(0.14 * S, 0.16 * S, 0.12 * S), CFrame.new(i * 0.2 * S, -0.1 * S, -0.5 * S) * CFrame.Angles(math.pi, 0, 0), WHITE)
	end
	for _, i in ipairs({ -0.5, 0.5 }) do
		mk.add("Wedge", v(0.14 * S, 0.16 * S, 0.12 * S), CFrame.new(i * 0.2 * S, -0.2 * S, -0.5 * S), WHITE)
	end
	wings(mk, S, T.Belly, 0.5, 0.36, 0.2, 24)
	mk.glow((mk.add("Ball", Vector3.one * 0.16 * S, CFrame.new(0, 0.6 * S, 0), T.Glow)))
end

function KINDS.Cube(mk, S, T)
	mk.add("Block", Vector3.one * 0.86 * S, CFrame.identity, T.Body)
	mk.add("Block", v(0.9 * S, 0.16 * S, 0.9 * S), CFrame.new(0, -0.2 * S, 0), T.Belly)
	eyes(mk, S, 0.12, -0.42, 0.2)
	-- petits cubes en orbite
	for i = 1, 3 do
		local hinge = CFrame.Angles(0, i / 3 * TAU, 0.3 * i)
		local p, weld = mk.add("Block", Vector3.one * 0.2 * S, hinge * CFrame.new(0.95 * S, 0, 0), if i % 2 == 0 then T.Belly else T.Glow, hinge)
		mk.glow(p)
		mk.anim(weld, Y, 2.4 + i * 0.5, 0, true)
	end
end

function KINDS.Chick(mk, S, T)
	local cream = Color3.fromRGB(255, 246, 224)
	mk.add("Cyl", v(0.5 * S, 1.02 * S, 1.02 * S), CFrame.new(0, -0.3 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), cream)
	mk.add("Ball", Vector3.one * 0.9 * S, CFrame.new(0, 0.1 * S, 0), T.Body)
	eyes(mk, S, 0.22, -0.34, 0.2)
	mk.add("Wedge", v(0.2 * S, 0.14 * S, 0.24 * S), CFrame.new(0, 0.06 * S, -0.5 * S) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(255, 150, 50))
	propeller(mk, S, 0.86, T.Glow)
	wings(mk, S, T.Body, 0.34, 0.3, 0.06, 18)
end

function KINDS.Fish(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.add("Ball", Vector3.one * 0.8 * S, CFrame.new(0, 0, 0.36 * S), T.Body)
	mk.add("Ball", Vector3.one * 0.6 * S, CFrame.new(0, -0.14 * S, -0.16 * S), T.Belly)
	eyes(mk, S, 0.12, -0.38, 0.3)
	-- nageoire de queue qui bat
	local hinge = CFrame.new(0, 0, 0.72 * S)
	local _, weld = mk.add("Wedge", v(0.08 * S, 0.8 * S, 0.5 * S), hinge * CFrame.new(0, 0, 0.26 * S), T.Glow, hinge)
	mk.anim(weld, Y, 9, 0.6)
	mk.add("Wedge", v(0.07 * S, 0.34 * S, 0.5 * S), CFrame.new(0, 0.58 * S, 0.1 * S), T.Glow)
	for _, side in ipairs({ -1, 1 }) do
		local h2 = CFrame.new(side * 0.45 * S, -0.1 * S, 0)
		local _, w2 = mk.add("Block", v(0.36 * S, 0.05 * S, 0.26 * S), h2 * CFrame.new(side * 0.18 * S, 0, 0), T.Glow, h2)
		mk.anim(w2, Z, 7, side * 0.5)
	end
end

function KINDS.Spark(mk, S, T)
	local body = mk.glow((mk.add("Ball", Vector3.one * 0.9 * S, CFrame.identity, T.Body)))
	mk.add("Ball", Vector3.one * 0.7 * S, CFrame.new(0, 0, -0.14 * S), T.Belly)
	eyes(mk, S, 0.08, -0.4, 0.2)
	-- antennes en éclair
	for _, side in ipairs({ -1, 1 }) do
		mk.glow((mk.add("Block", v(0.1 * S, 0.4 * S, 0.1 * S), CFrame.new(side * 0.24 * S, 0.62 * S, 0) * CFrame.Angles(0, 0, side * 0.5), T.Glow)))
		mk.glow((mk.add("Block", v(0.1 * S, 0.36 * S, 0.1 * S), CFrame.new(side * 0.3 * S, 0.92 * S, 0) * CFrame.Angles(0, 0, side * -0.6), T.Glow)))
	end
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.Color = ColorSequence.new(WHITE, T.Glow)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * S), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Rate = 10
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Parent = body
end

function KINDS.Drone(mk, S, T)
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.add("Cyl", v(0.2 * S, 1.06 * S, 1.06 * S), CFrame.Angles(0, 0, math.pi / 2), T.Belly)
	-- gros œil de verre
	mk.add("Ball", Vector3.one * 0.5 * S, CFrame.new(0, 0.1 * S, -0.34 * S), WHITE)
	mk.glow((mk.add("Ball", Vector3.one * 0.28 * S, CFrame.new(0, 0.1 * S, -0.5 * S), T.Glow)))
	propeller(mk, S, 0.82, T.Belly)
	-- clé qui tourne dans le dos
	local hinge = CFrame.new(0, 0, 0.5 * S)
	mk.add("Cyl", v(0.4 * S, 0.1 * S, 0.1 * S), CFrame.new(0, 0, 0.66 * S) * CFrame.Angles(0, math.pi / 2, 0), BLACK)
	local _, weld = mk.add("Block", v(0.12 * S, 0.7 * S, 0.1 * S), hinge * CFrame.new(0, 0, 0.4 * S), T.Belly, hinge)
	mk.anim(weld, Z, 4, 0, true)
end

function KINDS.Saucer(mk, S, T)
	local _, weld = mk.add("Cyl", v(0.26 * S, 1.8 * S, 1.8 * S), CFrame.Angles(0, 0, math.pi / 2), T.Body)
	mk.anim(weld, X, 1.5, 0, true) -- le disque tourne sur lui-même (l'axe du cylindre est son X)
	mk.add("Cyl", v(0.14 * S, 1.3 * S, 1.3 * S), CFrame.new(0, -0.16 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), T.Belly)
	local dome = mk.add("Ball", Vector3.one * 0.9 * S, CFrame.new(0, 0.2 * S, 0), T.Glow)
	dome.Transparency = 0.35
	mk.add("Ball", Vector3.one * 0.5 * S, CFrame.new(0, 0.2 * S, 0), T.Belly)
	eyes(mk, S, 0.26, -0.2, 0.12)
	-- bonbons sur le bord
	for i = 1, 6 do
		local a = i / 6 * TAU
		mk.glow((mk.add("Ball", Vector3.one * 0.2 * S, CFrame.new(math.cos(a) * 0.74 * S, 0.14 * S, math.sin(a) * 0.74 * S), if i % 2 == 0 then T.Glow else WHITE)))
	end
end

function KINDS.Fairy(mk, S, T)
	mk.add("Ball", Vector3.one * 0.82 * S, CFrame.identity, T.Belly)
	eyes(mk, S, 0.06, -0.34, 0.2)
	-- chapeau de champignon
	mk.add("Cyl", v(0.22 * S, 1.3 * S, 1.3 * S), CFrame.new(0, 0.4 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), T.Body)
	mk.add("Cyl", v(0.22 * S, 0.9 * S, 0.9 * S), CFrame.new(0, 0.6 * S, 0) * CFrame.Angles(0, 0, math.pi / 2), T.Body)
	for i = 1, 4 do
		local a = i / 4 * TAU + 0.5
		mk.add("Ball", Vector3.one * 0.2 * S, CFrame.new(math.cos(a) * 0.42 * S, 0.52 * S, math.sin(a) * 0.42 * S), WHITE)
	end
	local body = mk.add("Ball", Vector3.one * 0.2 * S, CFrame.new(0, -0.5 * S, 0), T.Glow)
	mk.glow(body)
	wings(mk, S, T.Glow, 0.8, 0.5, 0, 22, 0.3)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.Color = ColorSequence.new(T.Glow)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * S), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Rate = 6
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Parent = body
end

function KINDS.Dragon(mk, S, T, big)
	-- tête
	mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	mk.add("Block", v(0.6 * S, 0.4 * S, 0.5 * S), CFrame.new(0, -0.1 * S, -0.5 * S), T.Body)
	eyes(mk, S, 0.2, -0.36, 0.24)
	for _, side in ipairs({ -1, 1 }) do
		-- cornes et moustaches dorées
		mk.add("Wedge", v(0.12 * S, 0.5 * S, 0.2 * S), CFrame.new(side * 0.26 * S, 0.62 * S, 0.1 * S), T.Belly)
		local hinge = CFrame.new(side * 0.3 * S, -0.12 * S, -0.66 * S)
		local p, weld = mk.add("Block", v(0.06 * S, 0.06 * S, 0.8 * S), hinge * CFrame.new(side * 0.1 * S, 0, 0.4 * S), T.Belly, hinge)
		mk.glow(p)
		mk.anim(weld, Y, 2.5, side * 0.35, false, side)
	end
	-- long corps qui serpente
	local count = if big then 26 else 9
	for i = 1, count do
		local k = 1 - i / (count + 2)
		mk.seg((0.5 + 0.45 * k) * S, if i % 3 == 0 then T.Belly else T.Body)
	end
end

function KINDS.Ghost(mk, S, T, big)
	local head = mk.add("Ball", Vector3.one * S, CFrame.identity, T.Body)
	head.Transparency = 0.1
	eyes(mk, S, 0.08, -0.4, 0.22)
	mk.add("Ball", Vector3.one * 0.16 * S, CFrame.new(0, -0.18 * S, -0.46 * S), BLACK)
	-- petits bras qui flottent et lanterne
	for _, side in ipairs({ -1, 1 }) do
		local hinge = CFrame.new(side * 0.45 * S, -0.1 * S, 0)
		local _, weld = mk.add("Ball", Vector3.one * 0.3 * S, hinge * CFrame.new(side * 0.2 * S, 0, -0.1 * S), T.Body, hinge)
		mk.anim(weld, Z, 3, side * 0.5)
	end
	mk.add("Block", v(0.05 * S, 0.5 * S, 0.05 * S), CFrame.new(0.66 * S, -0.4 * S, -0.1 * S), BLACK)
	local lamp = mk.glow((mk.add("Block", v(0.3 * S, 0.36 * S, 0.3 * S), CFrame.new(0.66 * S, -0.76 * S, -0.1 * S), T.Glow)))
	local light = Instance.new("PointLight")
	light.Color = T.Glow
	light.Range = 6 * S
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = lamp
	-- traîne
	for i = 1, if big then 7 else 3 do
		local p = mk.seg((0.9 - i * (if big then 0.1 else 0.22)) * S, if i % 2 == 0 then T.Belly else T.Body)
		p.Transparency = 0.1 + i * 0.08
	end
end

-- TRAJETS ----------------------------------------------------------------------------------------------

local folder = Instance.new("Folder")
folder.Name = "Critters"

-- Début et fin (distance depuis la sortie de la cour) de la zone de chaque anneau (comme CorridorDecor.Zones)
local zones: { { from: number, to: number } } = {}
do
	local from = 4
	for i = 1, N do
		local edge = Config.RingDistance(i) + Config.RingWidth(i) / 2
		local to = if i < N then edge + Config.RingGapAfter(i) / 2 else edge
		zones[i] = { from = from, to = to }
		from = to
	end
end

local function position(c: Critter, t: number): Vector3
	local a = t * c.speed + c.phase
	return c.center + Vector3.new(math.sin(a) * c.radius.X, math.sin(a * 1.7 + c.phase) * c.radius.Y + math.sin(t * 2.2 + c.phase) * c.bob, math.cos(a) * c.radius.Z)
end

local function build(ring: number, index: number, big: boolean, parent: Instance): Critter
	local T = Themes.Get(ring).Critter
	local rng = Random.new(ring * 1000 + index + (if big then 500 else 0))
	local zone = zones[ring]
	local H = Themes.Lerp(Themes.Wall.Height, ring, N)
	local half = M.CorridorWidth / 2
	local S = Themes.Lerp(C.Size, ring, N) * rng:NextNumber(0.8, 1.25)
	local c: Critter
	local model = Instance.new("Model")
	model.Name = T.Kind
	local root = newPart("Block", Vector3.one, WHITE, model)
	root.Name = "Root"
	root.Transparency = 1
	root.Anchored = true
	local anims, tail = {}, {}
	if big then
		-- la géante : une grande boucle au-dessus du couloir, d'un mur à l'autre
		S *= Themes.Lerp(C.BigScale, ring, N)
		local mid = M.FrontZ + (zone.from + zone.to) / 2
		c = {
			root = root, anims = anims, tail = tail, gap = 0,
			center = Vector3.new(0, H / 2 + 14 + S * 1.5, mid),
			radius = Vector3.new(half + 30, 6, math.max(40, (zone.to - zone.from) * 0.38)),
			speed = rng:NextNumber(0.07, 0.11) * (if rng:NextNumber() < 0.5 then -1 else 1),
			phase = rng:NextNumber(0, TAU),
			bob = 2,
		}
	else
		-- les petites : de petites boucles près des murs, au-dessus d'eux ou juste derrière
		local side = if index % 2 == 0 then 1 else -1
		local rx = rng:NextNumber(6, 18)
		c = {
			root = root, anims = anims, tail = tail, gap = 0,
			center = Vector3.new(side * (half + rng:NextNumber(-10, 26)), rng:NextNumber(-H * 0.25, H / 2 + 16), M.FrontZ + rng:NextNumber(zone.from + 10, zone.to - 10)),
			radius = Vector3.new(rx, rng:NextNumber(2, 6), rng:NextNumber(10, 34)),
			speed = rng:NextNumber(0.3, 0.6) * (if rng:NextNumber() < 0.5 then -1 else 1),
			phase = rng:NextNumber(0, TAU),
			bob = rng:NextNumber(0.4, 1.2),
		}
	end
	local make = KINDS[T.Kind] or KINDS.Puff
	make(maker(model, root, anims, tail), S, T, big)
	-- retard entre deux segments : la longueur d'un segment à la vitesse du trajet
	local pace = math.abs(c.speed) * math.max(c.radius.X, c.radius.Z)
	c.gap = (S * 0.62) / math.max(pace, 0.5)
	model.Parent = parent
	return c
end

-- BIOMES CHARGÉS : celui du joueur et ses deux voisins ----------------------------------------------------

local loaded: { [number]: { folder: Folder, list: { Critter } } } = {}

local function load(ring: number)
	if loaded[ring] or ring < 1 or ring > N then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "Ring" .. ring
	local list = {}
	local count = math.floor(Themes.Lerp(C.Count, ring, N) + 0.5)
	for i = 1, count do
		table.insert(list, build(ring, i, false, f))
	end
	if ring >= C.BigFrom then
		table.insert(list, build(ring, 1, true, f))
	end
	f.Parent = folder
	loaded[ring] = { folder = f, list = list }
end

local function unload(ring: number)
	local l = loaded[ring]
	if l then
		l.folder:Destroy()
		loaded[ring] = nil
	end
end

local function zoneAt(pos: Vector3): number
	local d = pos.Z - M.FrontZ
	for i = 1, N do
		if d < zones[i].to then
			return i
		end
	end
	return N
end

-- DÉCORS QUI TOURNENT (rouages, sucettes) ---------------------------------------------------------------

local spinners: { [Model]: CFrame } = {}
local function addSpin(m: Instance)
	if m:IsA("Model") then
		spinners[m] = m:GetPivot()
	end
end
CollectionService:GetInstanceAddedSignal("DecorSpin"):Connect(addSpin)
CollectionService:GetInstanceRemovedSignal("DecorSpin"):Connect(function(m)
	spinners[m :: Model] = nil
end)
for _, m in ipairs(CollectionService:GetTagged("DecorSpin")) do
	addSpin(m)
end

-- BOUCLE -----------------------------------------------------------------------------------------------

task.spawn(function()
	-- dans le dossier du couloir : FarFade.client fond ainsi les créatures lointaines dans le ciel
	local corridor = workspace:WaitForChild("World"):WaitForChild("Corridor", 60)
	folder.Parent = corridor or workspace
end)

local current = 0
RunService.RenderStepped:Connect(function()
	local cam = camera.CFrame.Position
	local ring = zoneAt(cam)
	if ring ~= current then
		current = ring
		for r in pairs(loaded) do
			if math.abs(r - ring) > 1 then
				unload(r)
			end
		end
		for r = ring - 1, ring + 1 do
			load(r)
		end
	end
	local t = workspace:GetServerTimeNow()
	local range = C.Range
	for _, l in pairs(loaded) do
		for _, c in ipairs(l.list) do
			local pos = position(c, t)
			if (pos - cam).Magnitude < range + c.radius.Z then
				local ahead = position(c, t + 0.05)
				local dir = ahead - pos
				if dir.Magnitude > 1e-4 then
					c.root.CFrame = CFrame.lookAt(pos, pos + dir)
				end
				for _, a in ipairs(c.anims) do
					local angle = if a.spin then t * a.speed else math.sin(t * a.speed + a.phase) * a.amp
					a.weld.C0 = a.base * CFrame.fromAxisAngle(a.axis, angle)
				end
				for i, seg in ipairs(c.tail) do
					seg.Position = position(c, t - i * c.gap)
				end
			end
		end
	end
	for m, pivot in pairs(spinners) do
		if m.Parent and (pivot.Position - cam).Magnitude < 320 then
			m:PivotTo(pivot * CFrame.Angles(0, 0, t * ((m:GetAttribute("Speed") or 0.5) :: number)))
		end
	end
end)
