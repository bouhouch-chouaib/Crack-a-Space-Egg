-- Petites créatures extraterrestres qui volent le long du couloir (27 nov., shared/CorridorThemes).
-- Chaque biome a la sienne : boules de poussière, lutins de glace, chauves-souris de braise, méduses
-- d'étoiles, croqueurs, cubes qui clignotent, poussins en coquille, poissons, étincelles, drones à clé,
-- soucoupes en bonbon, fées champignon, dragons de jade, fantômes à lanterne. Plus on avance, plus elles
-- sont nombreuses et grandes ; à partir de l'anneau 5, une géante croise au-dessus du couloir.
-- Tout est local au joueur (rien sur le serveur, rien à envoyer) : elles sont construites pour le biome
-- où il se trouve et ses deux voisins, et suivent un trajet calculé (les mêmes à chaque visite).
-- Purement décoratives : ni collision, ni requête (la foreuse et le grappin passent au travers).
-- Depuis le 28 nov., ce sont de vrais modèles low-poly (Assets.CorridorKit.Critters, faits dans Blender :
-- tools/blender/corridor_kit_4.py, rangés par tools/build-corridor-kit.lua). Chaque pièce mobile (aile,
-- hélice, queue, mâchoire) porte sa charnière (PivotOffset, elle tourne autour de son axe Z) et ses réglages
-- (attributs Anim = swing / spin / open, Speed, Amp, Phase) : ce script n'a rien à savoir de chaque créature.
-- Il fait aussi tourner les décors étiquetés « DecorSpin » (rouages, sucettes : CorridorDecor).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Themes = require(ReplicatedStorage.Shared:WaitForChild("CorridorThemes"))

local camera = workspace.CurrentCamera
local M = Config.Map
local C = Themes.Critters
local N = #Config.Rings
local KIT = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CorridorKit"):WaitForChild("Critters")
local STUDS = "rbxassetid://99589690361139"
local SPARKLE = "rbxassetid://138922153683020"
local WHITE = Color3.new(1, 1, 1)
local TAU = math.pi * 2
local FLIP = CFrame.Angles(0, math.pi, 0) -- l'avant des modèles est +Z, CFrame.lookAt regarde vers -Z
local BODY = 3 -- largeur du corps des modèles (studs) : Themes.Critters.Size donne la taille voulue en jeu
-- Corps en plusieurs tronçons qui suivent le trajet avec un peu de retard : { modèle, nombre, nombre pour la géante }
local TRAILS = { Dragon = { "DragonSeg", 9, 26 }, Ghost = { "GhostSeg", 3, 7 } }

-- CONSTRUCTION ---------------------------------------------------------------------------------------

type Anim = { weld: Weld, base: CFrame, kind: string, speed: number, amp: number, phase: number }
type Critter = {
	root: BasePart,
	anims: { Anim },
	tail: { BasePart }, -- tronçons qui suivent le trajet avec un peu de retard (dragon, fantôme)
	gap: number, -- secondes de retard entre deux tronçons
	center: Vector3,
	radius: Vector3,
	speed: number,
	phase: number,
	bob: number,
}

local function quiet(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
end

local function sparkles(parent: Instance, color: ColorSequence, size: number, rate: number, life: NumberRange, speed: NumberRange)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.Color = color
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = life
	e.Rate = rate
	e.Speed = speed
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Parent = parent
end

-- Clone le modèle d'une créature à la taille S (largeur du corps), soude ses pièces au corps par leur
-- charnière et note celles qui bougent. Rend le corps (ancré : c'est lui qu'on déplace).
local function assemble(kind: string, S: number, T: any, big: boolean, parent: Instance, anims: { Anim }, tail: { BasePart }): BasePart
	local src = KIT:FindFirstChild(kind) or KIT:WaitForChild("Puff")
	local scale = S / BODY
	local model = src:Clone() :: Model
	model:ScaleTo(scale)
	local body = model.PrimaryPart :: BasePart
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then
			quiet(p)
			p.Anchored = p == body
			if p ~= body then
				local w = Instance.new("Weld")
				w.Part0 = body
				w.Part1 = p
				w.C0 = body.CFrame:ToObjectSpace(p.CFrame * p.PivotOffset)
				w.C1 = p.PivotOffset
				w.Parent = p
				local anim = p:GetAttribute("Anim")
				if anim then
					table.insert(anims, {
						weld = w, base = w.C0, kind = anim :: string,
						speed = (p:GetAttribute("Speed") or 4) :: number,
						amp = (p:GetAttribute("Amp") or 0.5) :: number,
						phase = (p:GetAttribute("Phase") or 0) :: number,
					})
				end
			end
		end
	end
	-- picots sur le corps des géantes (les petites restent lisses, comme les créatures du jeu)
	if big then
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local t = Instance.new("Texture")
			t.Name = "Studs"
			t.Texture = STUDS
			t.Face = face
			t.StudsPerTileU = 2
			t.StudsPerTileV = 2
			t.Transparency = 0.35
			t.Parent = body
		end
	end
	local glow = model:FindFirstChild("Glow")
	if kind == "Spark" then
		sparkles(body, ColorSequence.new(WHITE, T.Glow), 0.5 * S, 10, NumberRange.new(0.4, 0.7), NumberRange.new(1, 3))
	elseif kind == "Fairy" and glow then
		sparkles(glow, ColorSequence.new(T.Glow), 0.35 * S, 6, NumberRange.new(0.8, 1.4), NumberRange.new(0.5, 1.5))
	elseif kind == "Ghost" and glow then
		local light = Instance.new("PointLight")
		light.Color = T.Glow
		light.Range = 6 * S
		light.Brightness = 0.9
		light.Shadows = false
		light.Parent = glow
	end
	-- long corps du dragon, traîne du fantôme : des tronçons libres, de plus en plus petits
	local trail = TRAILS[kind]
	local segSrc = trail and KIT:FindFirstChild(trail[1])
	if trail and segSrc then
		local count = if big then trail[3] else trail[2]
		for i = 1, count do
			local seg = segSrc:Clone() :: Model
			seg:ScaleTo(scale * (0.45 + 0.55 * (1 - i / (count + 1))))
			local p = seg.PrimaryPart :: BasePart
			quiet(p)
			p.Anchored = true
			if kind == "Ghost" then
				p.Transparency = math.min(0.8, 0.1 + i * (if big then 0.08 else 0.18))
			end
			p.Parent = model
			seg:Destroy()
			table.insert(tail, p)
		end
	end
	model.Parent = parent
	return body
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
	local anims, tail = {}, {}
	if big then
		-- la géante : une grande boucle au-dessus du couloir, d'un mur à l'autre
		S *= Themes.Lerp(C.BigScale, ring, N)
		local mid = M.FrontZ + (zone.from + zone.to) / 2
		c = {
			root = nil :: any, anims = anims, tail = tail, gap = 0,
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
			root = nil :: any, anims = anims, tail = tail, gap = 0,
			center = Vector3.new(side * (half + rng:NextNumber(-10, 26)), rng:NextNumber(-H * 0.25, H / 2 + 16), M.FrontZ + rng:NextNumber(zone.from + 10, zone.to - 10)),
			radius = Vector3.new(rx, rng:NextNumber(2, 6), rng:NextNumber(10, 34)),
			speed = rng:NextNumber(0.3, 0.6) * (if rng:NextNumber() < 0.5 then -1 else 1),
			phase = rng:NextNumber(0, TAU),
			bob = rng:NextNumber(0.4, 1.2),
		}
	end
	c.root = assemble(T.Kind, S, T, big, parent, anims, tail)
	-- retard entre deux tronçons : la longueur d'un tronçon à la vitesse du trajet
	local pace = math.abs(c.speed) * math.max(c.radius.X, c.radius.Z)
	c.gap = (S * 0.7) / math.max(pace, 0.5)
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
					c.root.CFrame = CFrame.lookAt(pos, pos + dir) * FLIP
				end
				for _, a in ipairs(c.anims) do
					local angle
					if a.kind == "spin" then
						angle = t * a.speed
					elseif a.kind == "open" then
						angle = (0.5 + 0.5 * math.sin(t * a.speed + a.phase)) * a.amp
					else
						angle = math.sin(t * a.speed + a.phase) * a.amp
					end
					a.weld.C0 = a.base * CFrame.Angles(0, 0, angle)
				end
				-- chaque tronçon regarde celui qui le précède
				local before = pos
				for i, seg in ipairs(c.tail) do
					local at = position(c, t - i * c.gap)
					if (before - at).Magnitude > 1e-3 then
						seg.CFrame = CFrame.lookAt(at, before) * FLIP
					end
					before = at
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
