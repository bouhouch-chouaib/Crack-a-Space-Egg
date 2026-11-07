-- Carte v2, préparée au démarrage du serveur (docs/Mecaniques.md §2).
-- Le vaisseau (Workspace.Ship : bases, boutique, magasin de vente, machine à fusion, quai) est construit dans Studio :
-- on y ajoute seulement les invites d'interaction. Le reste est généré par code dans Workspace.World :
-- la planète, le couloir balisé (sans plateformes), les relais de pression et le décor des 7 anneaux.
-- Les astéroïdes qui défilent sont gérés par BeltService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local M = Config.Map
local rng = Random.new(20261211) -- graine fixe : la même carte à chaque serveur

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

-- Pièce de décor : ni collision, ni requête, ni contact
local function decor(props): Part
	local p = part(props)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- MODÈLES FAITS DANS STUDIO (ReplicatedStorage.Assets) ----------------------------
-- S'il manque un modèle, on garde la forme grise générée par code.

-- Si « name » est un dossier de variantes (ex. Assets.Asteroids.Ring1 et ses 5 formes),
-- on en tire une au hasard
local pickRng = Random.new()
local function asset(folder: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local f = assets and assets:FindFirstChild(folder)
	local m = f and f:FindFirstChild(name)
	if m and m:IsA("Folder") then
		local variants = {}
		for _, v in ipairs(m:GetChildren()) do
			if v:IsA("Model") and v.PrimaryPart then
				table.insert(variants, v)
			end
		end
		m = if #variants > 0 then variants[pickRng:NextInteger(1, #variants)] else nil
	end
	return if m and m:IsA("Model") and m.PrimaryPart then m:Clone() else nil
end
WorldBuilder.Asset = asset

-- Demi-hauteur d'une pièce, quelle que soit sa rotation
local function halfHeight(p: BasePart): number
	local cf, s = p.CFrame, p.Size
	return (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
end

-- Pose un modèle centré en (x, z), le dessus de sa PrimaryPart à la hauteur topY
local function placeTop(model: Model, x: number, topY: number, z: number)
	model:PivotTo(CFrame.new(x, 0, z))
	local pp = model.PrimaryPart :: BasePart
	local top = pp.Position.Y + halfHeight(pp)
	model:PivotTo(model:GetPivot() + Vector3.new(0, topY - top, 0))
end

-- Largeur d'un modèle d'astéroïde (pour le mettre à l'échelle voulue)
function WorldBuilder.Width(model: Model): number
	local size = model:GetExtentsSize()
	return math.max(size.X, size.Z)
end

-- Rend tout un modèle décoratif (ni collision, ni requête, ni contact)
local function ghost(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.KeyboardKeyCode = key
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

-- VAISSEAU (construit dans Studio) ---------------------------------------------

-- Repère -> texte de l'invite (action, objet)
local SERVICES = {
	StorePoint = { "Shop", "Robux Store" },
	ShopPoint = { "Shop", "Item Shop" },
	SellPoint = { "Sell", "Trading Post" },
	FusionPoint = { "Fuse", "Fusion Machine" },
}

local function prepareShip(): ({ Model }, { BasePart })
	local ship = workspace:FindFirstChild("Ship")
	if not ship then
		error("[WorldBuilder] Workspace.Ship est introuvable : le vaisseau doit être dans la place")
	end
	local dockEnd = ship:FindFirstChild("DockEnd", true) :: BasePart?
	if dockEnd and math.abs(dockEnd.Position.Z - M.FrontZ) > 1 then
		warn(string.format("[WorldBuilder] DockEnd est en z = %.1f, Config.Map.FrontZ vaut %d", dockEnd.Position.Z, M.FrontZ))
	end

	-- Bases : Base1, Base2… dans l'ordre ; chacune reçoit son numéro et l'invite de casse
	local bases = {}
	local folder = ship:FindFirstChild("Bases")
	while folder do
		local base = folder:FindFirstChild("Base" .. (#bases + 1)) :: Model?
		if not base then
			break
		end
		base:SetAttribute("Index", #bases + 1)
		-- Les bases sont vides au départ (clôture + sol) : la machine à casser viendra plus tard
		local crack = base:FindFirstChild("CrackPoint", true)
		if crack then
			prompt(crack, "Crack eggs", "Cracking Machine", Enum.KeyCode.E)
		end
		table.insert(bases, base)
	end

	-- Points de service sur le pont : boutique, magasin de vente, machine à fusion
	local points = {}
	for name, info in pairs(SERVICES) do
		local point = ship:FindFirstChild(name, true) :: BasePart?
		if point then
			prompt(point, info[1], info[2], Enum.KeyCode.F)
			table.insert(points, point)
		end
	end
	return bases, points
end

-- PLANÈTE -------------------------------------------------------------------
-- La planète géante est peinte dans le ciel (Lighting.PlanetSky, faces faites par
-- tools/sky/render_sky.py) : le brouillard cache toute pièce au-delà de quelques centaines de
-- studs, alors que le ciel reste toujours visible.

-- COULOIR ------------------------------------------------------------------
-- Les distances sont mesurées depuis le quai (z = FrontZ)

local function relay(z: number, index: number, parent: Instance)
	local model = asset("Corridor", "Relay")
	if model then
		placeTop(model, 0, 0, M.FrontZ + z)
	else
		model = Instance.new("Model")
		local floor = part({
			Name = "Floor",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, M.RelaySize - 6, M.RelaySize - 6),
			CFrame = CFrame.new(0, -1, M.FrontZ + z) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.DiamondPlate,
			Color = Color3.fromRGB(80, 90, 110),
			Parent = model,
		})
		model.PrimaryPart = floor
		decor({
			Name = "Bubble",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * M.RelaySize,
			CFrame = CFrame.new(0, 4, M.FrontZ + z),
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(120, 220, 255),
			Transparency = 0.5,
			Parent = model,
		})
	end
	local m = model :: Model
	m.Name = "Relay" .. index
	m:SetAttribute("Radius", M.RelaySize / 2)
	m.Parent = parent
end

local function buildCorridor(world: Folder)
	local corridor = Instance.new("Folder")
	corridor.Name = "Corridor"
	local relays = Instance.new("Folder")
	relays.Name = "Relays"
	relays.Parent = corridor

	local n = #Config.Rings
	local last = Config.RingDistance(n) + Config.RingWidth(n) / 2

	-- Un relais au milieu de chaque vide assez large entre deux anneaux
	for i = 1, n - 1 do
		local gap = Config.RingGapAfter(i)
		if gap >= M.RelayMinGap then
			local edge = Config.RingDistance(i) + Config.RingWidth(i) / 2
			relay(edge + gap / 2, i, relays)
		end
	end

	-- Bouées lumineuses sur les deux bords : la combinaison est protégée entre elles
	local buoys = Instance.new("Folder")
	buoys.Name = "Buoys"
	buoys.Parent = corridor
	local z = 0
	while z <= last do
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * M.CorridorWidth / 2, 0, M.FrontZ + z)
			local model = asset("Corridor", "Buoy")
			if model then
				model:PivotTo(cf)
				ghost(model)
				model.Name = "Buoy"
				model.Parent = buoys
			else
				decor({
					Name = "Buoy",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(2.5, 2.5, 2.5),
					CFrame = cf,
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(90, 220, 255),
					Parent = buoys,
				})
			end
		end
		z += M.BuoySpacing
	end

	corridor:SetAttribute("Length", last)
	corridor.Parent = world
end

local function buildRingDecor(world: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "RingDecor"
	for i, ring in ipairs(Config.Rings) do
		local radius = Config.RingRadius(i)
		local width = Config.RingWidth(i)
		local field = Config.FieldHeight(i)
		-- Le tapis occupe ±SpawnArc autour du couloir ; le décor prolonge le champ de chaque côté,
		-- sur toute l'épaisseur et la hauteur, jusqu'à DecorArc (la brume cache la suite)
		local from = (Config.Belt.SpawnArc + 10) / radius
		local to = (Config.Belt.SpawnArc + M.DecorArc) / radius
		local count = math.min(M.DecorMax, math.floor(2 * M.DecorArc * width * M.DecorDensity))
		local ringFolder = Instance.new("Folder")
		ringFolder.Name = "Ring" .. i
		ringFolder.Parent = folder
		for _ = 1, count do
			local side = if rng:NextNumber() < 0.5 then -1 else 1
			local angle = side * rng:NextNumber(from, to)
			local r = radius + rng:NextNumber(-width / 2, width / 2)
			-- Les roches lointaines sont plus grosses : le champ reste lisible de loin
			local far = (math.abs(angle) - from) / (to - from)
			local size = rng:NextNumber(8, 14 + width * 0.12) * (1 + far * 0.6)
			local pos = Config.OrbitPosition(r, angle, rng:NextNumber(-field * 1.3, field * 1.3))
			local template = asset("Asteroids", "Ring" .. i)
			if template then
				template:ScaleTo(size / WorldBuilder.Width(template))
				-- Légère inclinaison au hasard : le champ ne ressemble pas à une rangée de copies
				local tilt = CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.5, 0.5))
				template:PivotTo(CFrame.new(pos) * tilt)
				ghost(template)
				template.Name = "Rock"
				template.Parent = ringFolder
			else
				decor({
					Name = "Rock",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * size,
					CFrame = CFrame.new(pos),
					Material = Enum.Material.Slate,
					Color = ring.Color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.3)),
					Parent = ringFolder,
				})
			end
		end
	end
	folder.Parent = world
end

-- NUAGES DES BIOMES ----------------------------------------------------------------
-- De grands nuages très légers, de la couleur du biome, flottent dans le champ de chaque anneau
-- (autour du couloir et sur les côtés visibles) : chaque anneau a sa couleur sans voiler le ciel.

local function buildRingClouds(world: Folder)
	local C = Config.BiomeClouds
	local folder = Instance.new("Folder")
	folder.Name = "RingClouds"
	for i, biome in ipairs(Config.Biomes) do
		local radius = Config.RingRadius(i)
		local width = Config.RingWidth(i)
		local field = Config.FieldHeight(i)
		local scale = width / Config.RingWidth(1)
		local arc = (Config.Belt.SpawnArc + M.DecorArc) / radius
		for k = 1, C.PerRing do
			-- Réparti régulièrement le long de l'arc, avec un peu de hasard
			local u = ((k - 0.5) / C.PerRing) * 2 - 1 + rng:NextNumber(-0.3, 0.3) / C.PerRing
			local angle = math.sign(u) * math.abs(u) ^ C.Gather * arc
			local r = radius + rng:NextNumber(-width * 0.35, width * 0.35)
			local pos = Config.OrbitPosition(r, angle, rng:NextNumber(-field * 0.5, field * 0.5))
			local box = decor({
				Name = "Cloud",
				Size = Vector3.new(width * 0.8, field * 1.4, width * 0.6),
				CFrame = CFrame.new(pos),
				Transparency = 1,
				Parent = folder,
			})
			local e = Instance.new("ParticleEmitter")
			e.Texture = C.Texture
			e.Color = ColorSequence.new(biome.Clouds[1], biome.Clouds[2])
			e.Size = NumberSequence.new(C.Size[1] * scale, C.Size[2] * scale)
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, C.Transparency),
				NumberSequenceKeypoint.new(0.7, C.Transparency),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Lifetime = NumberRange.new(C.Life[1], C.Life[2])
			e.Rate = C.Rate
			e.Speed = NumberRange.new(0.5, 1.5)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-4, 4)
			e.LightEmission = 0.4
			e.LightInfluence = 0
			e.Shape = Enum.ParticleEmitterShape.Box
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.Parent = box
		end
	end
	folder.Parent = world
end

-- RIDEAUX DE BRUME ------------------------------------------------------------------
-- Dans chaque vide entre deux anneaux, une rangée de nuages plus épais, aux couleurs des deux
-- biomes : on devine l'anneau suivant à travers, sans le voir nettement.

local function buildFogCurtains(world: Folder)
	local F = Config.FogCurtains
	local folder = Instance.new("Folder")
	folder.Name = "FogCurtains"
	for i = 1, #Config.Rings - 1 do
		local gap = Config.RingGapAfter(i)
		local radius = M.AxisDistance + Config.RingDistance(i) + Config.RingWidth(i) / 2 + gap / 2
		local field = math.max(Config.FieldHeight(i), Config.FieldHeight(i + 1))
		local arc = F.Arc / radius
		local from, to = Config.Biomes[i].Clouds[1], Config.Biomes[i + 1].Clouds[1]
		for k = 1, F.PerGap do
			local u = ((k - 0.5) / F.PerGap) * 2 - 1
			local angle = math.sign(u) * math.abs(u) ^ F.Gather * arc
			local pos = Config.OrbitPosition(radius + rng:NextNumber(-gap * 0.15, gap * 0.15), angle, rng:NextNumber(-field * 0.3, field * 0.3))
			local box = decor({
				Name = "Curtain",
				Size = Vector3.new(F.Arc * 2 / F.PerGap, field * 2, gap * 0.6),
				CFrame = CFrame.lookAt(pos, pos + Vector3.new(pos.X, 0, pos.Z + M.AxisDistance - M.FrontZ)),
				Transparency = 1,
				Parent = folder,
			})
			local e = Instance.new("ParticleEmitter")
			e.Texture = Config.BiomeClouds.Texture
			e.Color = ColorSequence.new(from, to)
			e.Size = NumberSequence.new(F.Size[1], F.Size[2])
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, F.Transparency),
				NumberSequenceKeypoint.new(0.7, F.Transparency),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.Lifetime = NumberRange.new(F.Life[1], F.Life[2])
			e.Rate = F.Rate
			e.Speed = NumberRange.new(0.3, 1)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-3, 3)
			e.LightEmission = 0.3
			e.LightInfluence = 0
			e.Shape = Enum.ParticleEmitterShape.Box
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.Parent = box
		end
	end
	folder.Parent = world
end

function WorldBuilder.Build(): Folder
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "World"

	WorldBuilder.Bases, WorldBuilder.ShopPoints = prepareShip()
	buildCorridor(world)
	buildRingDecor(world)
	buildRingClouds(world)
	buildFogCurtains(world)

	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	world.Parent = workspace
	return world
end

WorldBuilder.Bases = {} :: { Model }
WorldBuilder.ShopPoints = {} :: { BasePart } -- repères ShopPoint, SellPoint, FusionPoint

return WorldBuilder
