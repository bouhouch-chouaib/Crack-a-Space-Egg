-- Carte v2 en greybox, construite au démarrage du serveur (docs/Mecaniques.md §2) :
-- la planète, le vaisseau et ses 8 bases, le quai, le couloir balisé, les relais de pression
-- et le décor des 7 anneaux. Les astéroïdes qui défilent sont gérés par BeltService.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

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

local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.KeyboardKeyCode = key
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

local function sign(parent: BasePart, text: string, color: Color3, height: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(12, 2.4) -- en studs : le panneau rapetisse avec la distance
	gui.MaxDistance = 150
	gui.StudsOffset = Vector3.new(0, height, 0)
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parent
	return label
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
		CFrame = CFrame.new(0, -M.PlanetDrop, -M.AxisDistance),
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

-- VAISSEAU ET BASES ----------------------------------------------------------

-- Les 8 bases sur le pourtour : 3 à gauche, 3 à droite, 2 à l'arrière
local function basePlacements(): { CFrame }
	local half = M.ShipSize / 2
	local depth = M.BaseSize.Z
	local list = {}
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -35, -70, -105 }) do
			local center = Vector3.new(side * (half.X + depth / 2), -1, z)
			-- La base « regarde » vers l'extérieur : son -Z pointe à l'opposé du vaisseau
			table.insert(list, CFrame.lookAt(center, center + Vector3.new(side, 0, 0)))
		end
	end
	for _, x in ipairs({ -40, 40 }) do
		local center = Vector3.new(x, -1, -M.ShipSize.Z - depth / 2)
		table.insert(list, CFrame.lookAt(center, center + Vector3.new(0, 0, -1)))
	end
	return list
end

local function buildBase(index: number, cf: CFrame, parent: Instance): Model
	local base = Instance.new("Model")
	base.Name = "Base" .. index
	base:SetAttribute("Index", index)
	local size = M.BaseSize
	-- Dans le repère de la base : X le long du bord du vaisseau, Z vers l'extérieur (-Z)
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(size.X, size.Y, size.Z),
		CFrame = cf,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(58, 64, 84),
		Parent = base,
	})
	base.PrimaryPart = floor
	part({
		Name = "Trim",
		Size = Vector3.new(size.X, 0.4, 1),
		CFrame = cf * CFrame.new(0, size.Y / 2 + 0.2, -size.Z / 2 + 0.5),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(233, 131, 74),
		CanCollide = false,
		Parent = base,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.4, 6)
	spawn.CFrame = cf * CFrame.new(0, size.Y / 2 + 0.2, 6)
	spawn.Material = Enum.Material.Metal
	spawn.Color = Color3.fromRGB(110, 120, 140)
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = base

	local machine = part({
		Name = "CrackMachine",
		Size = Vector3.new(8, 8, 6),
		CFrame = cf * CFrame.new(-10, size.Y / 2 + 4, -7),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(60, 64, 80),
		Parent = base,
	})
	part({
		Name = "Press",
		Size = Vector3.new(6.5, 1.2, 4.5),
		CFrame = machine.CFrame * CFrame.new(0, 4.6, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 40),
		Parent = base,
	})
	prompt(machine, "Crack eggs", "Cracking Machine", Enum.KeyCode.E)
	sign(machine, "CRACK EGGS", Color3.fromRGB(255, 220, 120), 7)

	local shop = part({
		Name = "ShopTerminal",
		Size = Vector3.new(5, 6, 3),
		CFrame = cf * CFrame.new(10, size.Y / 2 + 3, -7),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(50, 90, 140),
		Parent = base,
	})
	prompt(shop, "Upgrades", "Shop", Enum.KeyCode.F)
	sign(shop, "UPGRADES", Color3.fromRGB(140, 200, 255), 6)

	-- Nom du propriétaire au-dessus de la base (rempli par Bases)
	local post = decor({
		Name = "OwnerPost",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CFrame = cf * CFrame.new(0, 12, 0),
		Parent = base,
	})
	local label = sign(post, "FREE BASE", Color3.fromRGB(220, 225, 240), 0)
	label.Parent.Size = UDim2.fromScale(20, 3)

	base.Parent = parent
	return base
end

local function buildShip(world: Folder): { Model }
	local ship = Instance.new("Model")
	ship.Name = "Ship"
	local half = M.ShipSize / 2

	local deck = part({
		Name = "Deck",
		Size = M.ShipSize,
		CFrame = CFrame.new(0, -half.Y, -half.Z),
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(70, 78, 98),
		Parent = ship,
	})
	ship.PrimaryPart = deck
	part({
		Name = "Hull",
		Size = Vector3.new(M.ShipSize.X - 20, 30, M.ShipSize.Z - 20),
		CFrame = CFrame.new(0, -M.ShipSize.Y - 15, -half.Z),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(46, 52, 68),
		Parent = ship,
	})

	-- Apparition de secours, au centre du pont (chaque joueur réapparaît ensuite dans sa base)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(0, 0.2, -half.Z)
	spawn.Material = Enum.Material.Metal
	spawn.Color = Color3.fromRGB(110, 120, 140)
	spawn.Duration = 0
	spawn.Parent = ship

	-- Quai de départ vers le couloir
	part({
		Name = "Dock",
		Size = Vector3.new(M.CorridorWidth, M.ShipSize.Y, M.DockLength),
		CFrame = CFrame.new(0, -half.Y, M.DockLength / 2),
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(80, 88, 110),
		Parent = ship,
	})
	part({
		Name = "DockLight",
		Size = Vector3.new(M.CorridorWidth, 0.4, 1),
		CFrame = CFrame.new(0, 0.2, M.DockLength - 0.5),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(90, 220, 255),
		CanCollide = false,
		Parent = ship,
	})

	-- Bulle de pression : décor seulement, la protection est calculée par le serveur
	decor({
		Name = "Bubble",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * M.BubbleSize,
		CFrame = CFrame.new(0, 0, -half.Z),
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(120, 200, 255),
		Transparency = 0.6,
		Parent = ship,
	})

	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = ship
	local bases = {}
	for i, cf in ipairs(basePlacements()) do
		bases[i] = buildBase(i, cf, basesFolder)
	end

	ship.Parent = world
	return bases
end

-- COULOIR ------------------------------------------------------------------

local function pad(cf: CFrame, parent: Instance)
	part({
		Name = "Pad",
		Size = M.PadSize,
		CFrame = cf,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(90, 100, 125),
		Parent = parent,
	})
end

local function relay(z: number, index: number, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Relay" .. index
	local floor = part({
		Name = "Floor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, M.RelaySize - 6, M.RelaySize - 6),
		CFrame = CFrame.new(0, -1, z) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(80, 90, 110),
		Parent = model,
	})
	model.PrimaryPart = floor
	decor({
		Name = "Bubble",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * M.RelaySize,
		CFrame = CFrame.new(0, 4, z),
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(120, 220, 255),
		Transparency = 0.5,
		Parent = model,
	})
	model:SetAttribute("Radius", M.RelaySize / 2)
	model.Parent = parent
end

-- Plateformes régulières de a à b (z), sur l'axe du couloir avec un léger décalage
local function padsBetween(a: number, b: number, parent: Instance)
	local length = b - a
	local count = math.max(1, math.ceil(length / M.PadSpacing) - 1)
	for s = 1, count do
		local z = a + length * s / (count + 1)
		local x = rng:NextNumber(-12, 12)
		pad(CFrame.new(x, -2, z), parent)
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
	local lastZ = Config.RingDistance(n) + Config.RingWidth(n) / 2

	-- Du quai au premier anneau, puis entre deux anneaux (avec un relais au milieu)
	padsBetween(M.DockLength, Config.RingDistance(1) - Config.RingWidth(1) / 2, pads)
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
	local z = M.DockLength
	while z <= lastZ do
		for _, side in ipairs({ -1, 1 }) do
			decor({
				Name = "Buoy",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.5, 2.5, 2.5),
				CFrame = CFrame.new(side * M.CorridorWidth / 2, 0, z),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(90, 220, 255),
				Parent = buoys,
			})
		end
		z += M.BuoySpacing
	end

	corridor:SetAttribute("Length", lastZ)
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
			decor({
				Name = "Rock",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * size,
				CFrame = CFrame.new(Config.OrbitPosition(r, angle, rng:NextNumber(-12, 12))),
				Material = Enum.Material.Slate,
				Color = ring.Color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.3)),
				Parent = folder,
			})
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

	buildPlanet(world)
	local bases = buildShip(world)
	buildCorridor(world)
	buildRingDecor(world)

	local belt = Instance.new("Folder")
	belt.Name = "Belt"
	belt.Parent = world

	world.Parent = workspace
	WorldBuilder.Bases = bases
	return world
end

WorldBuilder.Bases = {} :: { Model }

return WorldBuilder
