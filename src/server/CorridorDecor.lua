-- Murs et décors du couloir, biome par biome (27 nov., shared/CorridorThemes).
-- Pour chaque anneau, de son entrée au milieu du vide qui le sépare du suivant :
--   - une paroi teintée, légèrement opaque, avec des picots de sa couleur ;
--   - des délimitations : un rail en haut, un rail en bas, un pilier à lanterne à chaque pas ;
--   - un portail à l'entrée (deux tours et une arche, avec l'emblème du biome au sommet) ;
--   - des décors à thème : sur le haut du mur et sur de petites îles qui flottent juste derrière.
-- Tout grandit d'anneau en anneau (hauteur du mur, piliers, décors, portail) : chaque biome est plus
-- impressionnant que le précédent. Rien ne bloque (on peut tout tenter à ses risques) : ni collision,
-- ni requête, ni contact. Les petites créatures volantes sont faites chez le client (Critters.client).
--
-- Depuis le 28 nov., décors, piliers, arches et îles sont de vrais modèles low-poly (Blender :
-- tools/blender/corridor_kit*.py, rangés par tools/build-corridor-kit.lua dans Assets.CorridorKit) :
--   Props  : un modèle par décor, texture peinte au pixel avec ses picots ; il est cloné, mis à l'échelle
--            et tourné vers le couloir. Son sous-modèle « Spin » tourne chez le client (« DecorSpin »).
--   Struct : pièces unies (Trim / Dark / Glow) reteintes aux couleurs du biome, picots Roblox par-dessus.
-- Seuls la paroi et les rails restent de simples blocs.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Themes = require(ReplicatedStorage.Shared.CorridorThemes)

local CorridorDecor = {}

local M = Config.Map
local STUDS = "rbxassetid://99589690361139"
local GLOW = "rbxassetid://103844906730878"
local WHITE = Color3.new(1, 1, 1)
local rgb = Color3.fromRGB
local FACES = Enum.NormalId:GetEnumItems()
local SIDES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local FLIP_DOWN = CFrame.Angles(math.pi, 0, 0)

local KIT = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CorridorKit")
local PROPS, STRUCT = KIT:WaitForChild("Props"), KIT:WaitForChild("Struct")

-- PIÈCES ---------------------------------------------------------------------------------------------

local function studs(p: BasePart, tile: number, faces: { Enum.NormalId }?)
	for _, face in ipairs(faces or FACES) do
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

-- Simple bloc (paroi, rails)
local function base(size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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

-- Repère posé en « at » dont l'avant des modèles (+Z) regarde dans la direction « dir »
local function facing(at: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(at, at - dir)
end

-- Couleurs du biome sur une pièce de structure : Trim, Dark, et Glow en petite touche lumineuse
local function tint(p: BasePart, T: any, swap: boolean?)
	if p.Name == "Glow" then
		p.Color = T.Accent
	elseif (p.Name == "Dark") ~= (swap == true) then
		p.Color = T.Dark
	else
		p.Color = T.Trim
	end
end

-- Pièce de structure entière (chapiteau, lanterne, île) : clonée, mise à l'échelle, posée et teintée
local function piece(parent: Instance, name: string, cf: CFrame, scale: number, T: any, studded: string?): Model
	local m = STRUCT[name]:Clone()
	m:ScaleTo(scale)
	m:PivotTo(cf)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			tint(p, T)
			if p.Name == studded then
				studs(p, 2)
			end
		end
	end
	m.Parent = parent
	return m
end

-- Pièce de structure étirée (fût de pilier, claveau d'arche) : chaque partie prend sa taille à part
local function stretched(parent: Instance, name: string, cf: CFrame, factor: Vector3, T: any, swap: boolean?, faces: { Enum.NormalId }?, noGlow: boolean?)
	for _, src in ipairs(STRUCT[name]:GetChildren()) do
		if src:IsA("BasePart") and not (noGlow and src.Name == "Glow") then
			local p = src:Clone()
			p.Size = src.Size * factor
			p.CFrame = cf
			tint(p, T, swap)
			if p.Name == "Trim" then
				studs(p, 2, faces)
			end
			p.Parent = parent
		end
	end
end

local function emitter(p: Instance, color: Color3, size: number, rate: number, speed: number, life: number): ParticleEmitter
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

-- DÉCORS -----------------------------------------------------------------------------------------
-- Les modèles font environ 12 de haut à l'échelle 1, le pivot au pied. Quelques-uns fument ou éclairent :
-- { couleur (clé du thème ou couleur), taille, débit, vitesse, durée, tout autour ? }
local SMOKE: { [string]: { any } } = {
	Volcano = { "Wall", 3, 5, 9, 1.6 },
	Rod = { "Accent", 2.4, 3, 5, 0.7, true },
	Pipe = { rgb(240, 246, 255), 4, 4, 6, 1.8 },
	Spores = { "Accent", 1.4, 3, 3, 4, true },
	Clam = { rgb(220, 250, 255), 1.6, 2, 4, 3 },
}
local LIT = { Lantern = true, Pumpkin = true }

local function prop(parent: Instance, name: string, origin: CFrame, s: number, T: any)
	local src = PROPS:FindFirstChild(name)
	if not src then
		return
	end
	local m = src:Clone()
	m:ScaleTo(s)
	m:PivotTo(origin)
	for _, sub in ipairs(m:GetChildren()) do
		if sub:IsA("Model") then
			-- ce qui tourne (rouages, sucettes, volants) : animé chez le client autour de l'axe Z de son pivot
			CollectionService:AddTag(sub, "DecorSpin")
		end
	end
	local smoke = SMOKE[name]
	local body = m:FindFirstChild("Body")
	if smoke and body then
		local cf, size = m:GetBoundingBox()
		local a = Instance.new("Attachment")
		a.Name = "Smoke"
		a.Parent = body
		a.WorldCFrame = CFrame.new(Vector3.new(origin.Position.X, cf.Position.Y + size.Y / 2, origin.Position.Z))
		local color = if typeof(smoke[1]) == "string" then T[smoke[1]] else smoke[1]
		local e = emitter(a, color, smoke[2] * s, smoke[3], smoke[4] * s, smoke[5])
		if smoke[6] then
			e.SpreadAngle = Vector2.new(180, 180)
		end
	end
	local glow = m:FindFirstChild("Glow")
	if LIT[name] and glow then
		local light = Instance.new("PointLight")
		light.Color = (glow :: BasePart).Color
		light.Range = 12 * s
		light.Brightness = 0.9
		light.Shadows = false
		light.Parent = glow
	end
	m.Parent = parent
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
	local wall = base(Vector3.new(W.Thickness, H, len), CFrame.new(x, 0, zc), T.Wall, parent)
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
		local r = base(Vector3.new(rail * 1.3, rail, len), CFrame.new(x, top * (H / 2 + rail / 2), zc), T.Trim, parent)
		r.Name = "Rail"
		local line = base(Vector3.new(rail * 1.3 + 0.2, 0.35, len), CFrame.new(x, top * (H / 2 - 0.4), zc), T.Accent, parent)
		line.Name = "RailLine"
		line.Material = Enum.Material.Neon
	end
end

-- Pilier : fût à huit pans étiré du bas (y0) au haut (y1), chapiteau à griffes en haut, le même retourné en
-- bas, et une lanterne accrochée côté couloir (elle remplace les anciennes bouées)
local function pillar(parent: Instance, T: any, x: number, zc: number, y0: number, y1: number, w: number, name: string, tip: boolean): Model
	local m = Instance.new("Model")
	m.Name = name
	local k = w / 4 -- les pièces sont modelées pour un pilier de 4 de large
	local h = y1 - y0
	stretched(m, "PostShaft", CFrame.new(x, (y0 + y1) / 2, zc), Vector3.new(k, h / 10, k), T, false, SIDES)
	local top = piece(m, "PostCap", CFrame.new(x, y1, zc), k, T, "Dark")
	local bottom = piece(m, "PostCap", CFrame.new(x, y0, zc) * FLIP_DOWN, k, T, "Dark")
	bottom.Glow:Destroy()
	if not tip then
		top.Glow:Destroy()
	end
	local side = if x > 0 then 1 else -1
	local lampAt = Vector3.new(x - side * w * 0.48, (y0 + y1) / 2 + h * 0.12, zc)
	piece(m, "PostLamp", facing(lampAt, Vector3.new(-side, 0, 0)), k, T)
	m.Parent = parent
	return m
end

local function post(parent: Instance, T: any, side: number, z: number, H: number, rail: number, w: number)
	local full = H + rail * 2
	pillar(parent, T, side * M.CorridorWidth / 2, M.FrontZ + z, -full / 2, full / 2, w, "Post", true)
end

-- PORTAIL D'ENTRÉE D'UN BIOME --------------------------------------------------------------------------
-- Deux tours de part et d'autre du couloir, une arche de claveaux par-dessus et l'emblème du biome au sommet.
local function gate(parent: Instance, T: any, z: number, H: number, rail: number, w: number, rise: number, scale: number)
	local m = Instance.new("Model")
	m.Name = "Gate"
	m.Parent = parent
	local half = M.CorridorWidth / 2
	local zc = M.FrontZ + z
	local tw = w * 2
	local topY = H / 2 + rail + 6 * scale
	local capH = 4.3 * tw / 4 -- hauteur du chapiteau sans sa pointe
	for _, side in ipairs({ -1, 1 }) do
		local x = side * half
		pillar(m, T, x, zc, -H / 2 - rail, topY, tw, "Tower", false)
		-- décor du biome au sommet de chaque tour, tourné vers le couloir
		prop(m, T.Props[2] or T.Props[1], facing(Vector3.new(x, topY + capH, zc), Vector3.new(-side, 0, 0)), scale * 0.9, T)
	end
	-- arche : une demi-ellipse de tour à tour, en claveaux qui alternent les deux teintes du biome
	local th = tw * 0.7
	local segments = 16
	local function point(i: number): Vector3
		local a = i / segments * math.pi
		return Vector3.new(-math.cos(a) * half, topY + capH * 0.5 + math.sin(a) * rise, zc)
	end
	local arch = Instance.new("Model")
	arch.Name = "Arch"
	for i = 0, segments - 1 do
		local a, b = point(i), point(i + 1)
		local len = (b - a).Magnitude + 0.6
		stretched(arch, "ArchBlock", CFrame.lookAt((a + b) / 2, b), Vector3.new(th * 1.2 / 4, th / 3.4, len / 12), T, i % 2 == 1, nil, i % 2 == 1)
	end
	arch.Parent = m
	-- emblème : le grand décor du biome, debout sur le sommet de l'arche, tourné vers ceux qui arrivent
	local apex = Vector3.new(0, topY + capH * 0.5 + rise + th / 2, zc)
	prop(m, T.Props[1], facing(apex, -Vector3.zAxis), scale * 1.9, T)
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
			gate(propsFolder, T, zone.from, H, rail, w, Themes.Lerp(W.Gate, i, n), scale)
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
				local inward = Vector3.new(-side, 0, 0)
				if (c + (if side > 0 then 1 else 0)) % 2 == 0 then
					-- sur le haut du mur
					prop(propsFolder, name, facing(Vector3.new(side * half, H / 2 + rail, zc), inward), sc, T)
				else
					-- île flottante derrière le mur, à une hauteur au hasard
					local at = Vector3.new(side * (half + rng:NextNumber(9, 20) * scale), rng:NextNumber(-H * 0.45, H * 0.3), zc)
					local origin = facing(at, inward) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
					local island = piece(propsFolder, "Island", origin * CFrame.Angles(0, rng:NextNumber(0, 6), 0), sc, T, "Trim")
					prop(island, name, origin, sc, T)
				end
			end
		end
	end
end

return CorridorDecor
