-- Carte v2, préparée au démarrage du serveur (docs/Mecaniques.md §2).
-- Le vaisseau (Workspace.Ship : bases, boutique, magasin de vente, machine à fusion, quai) est construit dans Studio :
-- on y ajoute seulement les invites d'interaction. Le reste est généré par code dans Workspace.World :
-- la planète, le couloir balisé (sans plateformes), les relais de pression et le décor des 7 anneaux.
-- Les astéroïdes qui défilent sont gérés par BeltService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(ReplicatedStorage.Shared.Theme)

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

-- Repère -> texte de l'invite (action, objet)
local SERVICES = {
	ShopPoint = { "Shop", "Space Shop" },
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
		local crack = base:FindFirstChild("CrackPoint", true)
		if crack then
			prompt(crack, "Crack eggs", "Cracking Machine", Enum.KeyCode.E)
		else
			warn("[WorldBuilder] CrackPoint manquant dans " .. base.Name)
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

-- BANNIÈRE D'ÉVÉNEMENT ---------------------------------------------------------
-- Grand panneau au-dessus du portique LAUNCH, tourné vers le vaisseau ; le texte
-- (événement à venir et compte à rebours) est mis à jour par chaque client (Markers.client).
local function buildEventBanner(world: Folder)
	local board = decor({
		Name = "EventBanner",
		Size = Vector3.new(34, 9, 0.2),
		CFrame = CFrame.new(0, 38, M.FrontZ - 4),
		Transparency = 1,
		Parent = world,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BannerGui"
	gui.Face = Enum.NormalId.Front -- vers -Z : vers le vaisseau
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(43, 51, 80)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(63, 201, 216)
	stroke.Thickness = 8
	stroke.Parent = bg
	local function label(name: string, y: number, h: number, color: Color3)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.Size = UDim2.fromScale(0.92, h)
		t.Position = UDim2.fromScale(0.04, y)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.FontFace = Theme.FontHeavy
		t.TextColor3 = color
		t.TextStrokeTransparency = 0.3
		t.Text = ""
		t.Parent = bg
	end
	label("Title", 0.08, 0.5, Color3.fromRGB(255, 255, 255))
	label("Timer", 0.58, 0.34, Color3.fromRGB(127, 243, 255))
	bg.Parent = gui
	gui.Parent = board
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
	buildEventBanner(world)

	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	world.Parent = workspace
	return world
end

WorldBuilder.Bases = {} :: { Model }
WorldBuilder.ShopPoints = {} :: { BasePart } -- repères ShopPoint, SellPoint, FusionPoint

return WorldBuilder
