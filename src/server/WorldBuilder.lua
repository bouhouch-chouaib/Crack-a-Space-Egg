-- Carte greybox générée au démarrage : la station au centre, les anneaux d'astéroïdes autour,
-- et des « pierres de passage » pour sauter de la station à chaque anneau.
-- Tout est construit par code pour que la carte vive dans le dépôt Git.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local STATION_RADIUS = 42
local rng = Random.new(20261212) -- graine fixe : la même carte à chaque serveur

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

local function buildStation(world: Folder)
	local station = Instance.new("Model")
	station.Name = "Station"

	part({
		Name = "Deck",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, STATION_RADIUS * 2, STATION_RADIUS * 2),
		CFrame = CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(70, 78, 98),
		Parent = station,
	})
	part({
		Name = "Ring",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, STATION_RADIUS * 2 + 4, STATION_RADIUS * 2 + 4),
		CFrame = CFrame.new(0, -3.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(233, 131, 74),
		Parent = station,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Material = Enum.Material.Metal
	spawn.Color = Color3.fromRGB(110, 120, 140)
	spawn.Duration = 0
	spawn.Parent = station

	-- Machine à casser
	local machine = part({
		Name = "CrackMachine",
		Size = Vector3.new(10, 9, 8),
		CFrame = CFrame.new(-22, 4.5, -10),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(60, 64, 80),
		Parent = station,
	})
	part({
		Name = "Press",
		Size = Vector3.new(8, 1.5, 6),
		CFrame = CFrame.new(-22, 9.8, -10),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 196, 40),
		Parent = station,
	})
	prompt(machine, "Crack geodes", "Cracking Machine", Enum.KeyCode.E)
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(240, 50)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "CRACK GEODES"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.TextStrokeTransparency = 0.3
	label.Parent = sign
	sign.Parent = machine

	-- Terminal d'améliorations
	local shop = part({
		Name = "ShopTerminal",
		Size = Vector3.new(6, 7, 4),
		CFrame = CFrame.new(22, 3.5, -10),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(50, 90, 140),
		Parent = station,
	})
	prompt(shop, "Upgrades", "Shop", Enum.KeyCode.F)
	local sign2 = sign:Clone()
	;(sign2:FindFirstChildOfClass("TextLabel") :: TextLabel).Text = "UPGRADES"
	;(sign2:FindFirstChildOfClass("TextLabel") :: TextLabel).TextColor3 = Color3.fromRGB(140, 200, 255)
	sign2.StudsOffset = Vector3.new(0, 7, 0)
	sign2.Parent = shop

	station.Parent = world
	return station
end

local function asteroid(ringIndex: number, pos: Vector3, size: number, drillable: boolean): Part
	local ring = Config.Rings[ringIndex]
	local a = part({
		Name = if drillable then "Asteroid" else "Stepping",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size, size, size),
		CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
		Material = Enum.Material.Slate,
		Color = ring.Color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
	})
	if drillable then
		a:SetAttribute("Ring", ringIndex)
		a:SetAttribute("MaxHP", ring.HP * (size / 16))
		a:SetAttribute("HP", ring.HP * (size / 16))
	end
	return a
end

function WorldBuilder.Build(): Folder
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "World"
	local asteroids = Instance.new("Folder")
	asteroids.Name = "Asteroids"
	asteroids.Parent = world
	local steps = Instance.new("Folder")
	steps.Name = "Stepping"
	steps.Parent = world

	buildStation(world)

	local prevOuter = STATION_RADIUS
	for i, ring in ipairs(Config.Rings) do
		-- Astéroïdes de l'anneau, répartis sur le pourtour avec un peu de désordre
		for n = 1, ring.Asteroids do
			local angle = (n / ring.Asteroids) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			local r = ring.Radius + rng:NextNumber(-ring.Width / 2, ring.Width / 2)
			local y = rng:NextNumber(-14, 14)
			local size = rng:NextNumber(12, 22)
			asteroid(i, Vector3.new(math.cos(angle) * r, y, math.sin(angle) * r), size, true).Parent = asteroids
		end
		-- Pierres de passage depuis l'anneau précédent, dans 4 directions
		local inner = ring.Radius - ring.Width / 2
		local gap = inner - prevOuter
		local count = math.max(1, math.floor(gap / 24))
		for d = 0, 3 do
			local angle = d * math.pi / 2 + math.rad(20 * i)
			for s = 1, count do
				local r = prevOuter + gap * (s / (count + 1))
				local pos = Vector3.new(math.cos(angle) * r, -4 + s * 2, math.sin(angle) * r)
				asteroid(i, pos, 10, false).Parent = steps
			end
		end
		prevOuter = ring.Radius + ring.Width / 2
	end

	world.Parent = workspace
	return world
end

WorldBuilder.StationRadius = STATION_RADIUS

return WorldBuilder
