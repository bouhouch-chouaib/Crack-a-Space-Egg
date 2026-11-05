-- Carte v2, préparée au démarrage du serveur (docs/Mecaniques.md §2).
-- Le vaisseau (Workspace.Ship, 7 bases, boutique, ateliers, quai) est construit dans Studio :
-- on y ajoute seulement les invites d'interaction. Le reste est généré par code dans Workspace.World :
-- la planète, le couloir balisé, les relais de pression et le décor des 7 anneaux.
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

local function asset(folder: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local f = assets and assets:FindFirstChild(folder)
	local m = f and f:FindFirstChild(name)
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
		local crack = base:FindFirstChild("CrackPoint", true)
		if crack then
			prompt(crack, "Crack eggs", "Cracking Machine", Enum.KeyCode.E)
		else
			warn("[WorldBuilder] CrackPoint manquant dans " .. base.Name)
		end
		table.insert(bases, base)
	end

	-- Ateliers : une invite par atelier, qui ouvre ses améliorations
	local points = {}
	local workshops = ship:FindFirstChild("Workshops")
	for _, w in ipairs(workshops and workshops:GetChildren() or {}) do
		local point = w:FindFirstChild("Point") :: BasePart?
		if point then
			point:SetAttribute("Upgrade", Config.Workshops[w.Name])
			local label = w.Name:gsub("Workshop$", "")
			prompt(point, "Upgrade", label, Enum.KeyCode.F)
			table.insert(points, point)
		end
	end
	local shopPoint = ship:FindFirstChild("ShopPoint", true)
	if shopPoint then
		prompt(shopPoint, "Shop", "Space Shop", Enum.KeyCode.F)
		table.insert(points, shopPoint :: BasePart)
	end
	return bases, points
end

-- PLANÈTE -------------------------------------------------------------------

local function buildPlanet(world: Folder)
	local model = Instance.new("Model")
	model.Name = "Planet"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- toujours visible, même de loin
	-- Une pièce ne dépasse pas 2 048 studs : la sphère est agrandie par un maillage
	local ball = decor({
		Name = "Globe",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2048, 2048, 2048),
		CFrame = CFrame.new(0, -M.PlanetDrop, M.FrontZ - M.AxisDistance),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(196, 120, 82),
		Parent = model,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.one * (M.PlanetRadius * 2 / 2048)
	mesh.Parent = ball
	model.PrimaryPart = ball
	model.Parent = world
end

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

-- Plateformes régulières de a à b, sur l'axe du couloir avec un léger décalage
local function padsBetween(a: number, b: number, parent: Instance)
	local length = b - a
	local count = math.max(1, math.ceil(length / M.PadSpacing) - 1)
	for s = 1, count do
		local z = M.FrontZ + a + length * s / (count + 1)
		local x = rng:NextNumber(-12, 12)
		local topY = -2 + M.PadSize.Y / 2
		local model = asset("Corridor", "Pad")
		if model then
			placeTop(model, x, topY, z)
			model.Name = "Pad"
			model.Parent = parent
		else
			part({
				Name = "Pad",
				Size = M.PadSize,
				CFrame = CFrame.new(x, -2, z),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(90, 100, 125),
				Parent = parent,
			})
		end
	end
end

local function buildCorridor(world: Folder)
	local corridor = Instance.new("Folder")
	corridor.Name = "Corridor"
	local pads = Instance.new("Folder")
	pads.Name = "Pads"
	pads.Parent = corridor
	local relays = Instance.new("Folder")
	relays.Name = "Relays"
	relays.Parent = corridor

	local n = #Config.Rings
	local last = Config.RingDistance(n) + Config.RingWidth(n) / 2

	-- Du quai au premier anneau, puis entre deux anneaux (avec un relais au milieu)
	padsBetween(0, Config.RingDistance(1) - Config.RingWidth(1) / 2, pads)
	for i = 1, n - 1 do
		local a = Config.RingDistance(i) + Config.RingWidth(i) / 2
		local b = Config.RingDistance(i + 1) - Config.RingWidth(i + 1) / 2
		local mid = (a + b) / 2
		local r = M.RelaySize / 2
		padsBetween(a, mid - r, pads)
		relay(mid, i, relays)
		padsBetween(mid + r, b, pads)
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

-- DÉCOR DES ANNEAUX ---------------------------------------------------------

local function buildRingDecor(world: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "RingDecor"
	for i, ring in ipairs(Config.Rings) do
		local radius = Config.RingRadius(i)
		local width = Config.RingWidth(i)
		-- On laisse libre la zone où passe le tapis (couloir + naissance et disparition)
		local keepOut = (Config.Belt.SpawnArc + 60) / radius
		for _ = 1, M.DecorPerRing do
			local angle = rng:NextNumber(keepOut, math.pi * 2 - keepOut)
			local r = radius + rng:NextNumber(-width / 2, width / 2)
			local size = rng:NextNumber(8, 26)
			local pos = Config.OrbitPosition(r, angle, rng:NextNumber(-12, 12))
			local template = asset("Asteroids", "Ring" .. i)
			if template then
				template:ScaleTo(size / WorldBuilder.Width(template))
				template:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				ghost(template)
				template.Name = "Rock"
				template.Parent = folder
			else
				decor({
					Name = "Rock",
					Shape = Enum.PartType.Ball,
					Size = Vector3.one * size,
					CFrame = CFrame.new(pos),
					Material = Enum.Material.Slate,
					Color = ring.Color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.3)),
					Parent = folder,
				})
			end
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
	buildPlanet(world)
	buildCorridor(world)
	buildRingDecor(world)

	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	world.Parent = workspace
	return world
end

WorldBuilder.Bases = {} :: { Model }
WorldBuilder.ShopPoints = {} :: { BasePart } -- ateliers + boutique (repères « Point » / « ShopPoint »)

return WorldBuilder
