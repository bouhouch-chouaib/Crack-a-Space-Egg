-- Modèles 3D des objets (Config.Gear), construits autour de l'origine avec des pièces ancrées.
-- La batte et le tapis servent aussi sur l'avatar (GearService les soude) ; tous servent aux aperçus de GearBar.client.

local Config = require(script.Parent:WaitForChild("Config"))

local GearModel = {}

local STUDS = "rbxassetid://99589690361139"
local CYLINDER, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

local function piece(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, tile: number?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	if tile then
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
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
	p.Parent = model
	return p
end

local function ball(d: number): Vector3
	return Vector3.new(d, d, d)
end

-- Manche à l'origine, la batte s'étend vers +X
function GearModel.Bat(tier: number): Model
	local b = Config.Bats[math.clamp(tier, 1, #Config.Bats)]
	local m = Instance.new("Model")
	m.Name = "Bat"
	piece(m, "Handle", Vector3.new(1.7, 0.24, 0.24), CFrame.new(), b.Grip, CYLINDER)
	piece(m, "Barrel", Vector3.new(2, 0.56, 0.56), CFrame.new(1.8, 0, 0), b.Color, CYLINDER, 1)
	piece(m, "Cap", ball(0.56), CFrame.new(2.8, 0, 0), b.Color, BALL)
	piece(m, "Knob", ball(0.34), CFrame.new(-0.85, 0, 0), b.Grip, BALL)
	for i = 1, b.Bands do
		piece(m, "Band", Vector3.new(0.14, 0.62, 0.62), CFrame.new(1.2 + (i - 1) * 0.5, 0, 0), b.Accent, CYLINDER)
	end
	return m
end

function GearModel.Carpet(): Model
	local c = Config.Gear.Carpet
	local m = Instance.new("Model")
	m.Name = "Carpet"
	piece(m, "Main", Vector3.new(c.Width, 0.26, c.Length), CFrame.new(), c.Color, nil, 1)
	piece(m, "Border", Vector3.new(c.Width + 0.5, 0.2, c.Length + 0.5), CFrame.new(), c.Accent, nil, 1)
	piece(m, "Star", Vector3.new(1.5, 0.3, 1.5), CFrame.Angles(0, math.rad(45), 0), c.Accent)
	for _, z in ipairs({ -1, 1 }) do
		for i = -2, 2 do
			piece(m, "Tassel", Vector3.new(0.34, 0.14, 0.55), CFrame.new(i * (c.Width / 5), 0, z * (c.Length / 2 + 0.5)), c.Accent)
		end
	end
	return m
end

-- La paire de bottes de l'aperçu (sur l'avatar, GearService les ajuste à ses pieds)
function GearModel.Boots(): Model
	local c = Config.Gear.Boots
	local m = Instance.new("Model")
	m.Name = "Boots"
	for _, x in ipairs({ -0.75, 0.75 }) do
		piece(m, "Sole", Vector3.new(1.05, 0.22, 1.85), CFrame.new(x, -0.61, -0.25), c.Sole)
		piece(m, "Foot", Vector3.new(0.95, 0.5, 1.7), CFrame.new(x, -0.25, -0.25), c.Color, nil, 1)
		piece(m, "Leg", Vector3.new(0.9, 1.1, 0.95), CFrame.new(x, 0.5, 0.1), c.Color, nil, 1)
		piece(m, "Strap", Vector3.new(0.98, 0.3, 1.03), CFrame.new(x, 0.75, 0.1), c.Strap)
	end
	return m
end

-- Lanceur vers +X ; la tête et le câble sortent quand on clique (noms lus par GearBar.client)
function GearModel.Hook(): Model
	local m = Instance.new("Model")
	m.Name = "Hook"
	local steel, dark, orange = Color3.fromRGB(175, 185, 205), Color3.fromRGB(70, 76, 96), Color3.fromRGB(245, 140, 50)
	piece(m, "Cable", Vector3.new(2.4, 0.12, 0.12), CFrame.new(0.4, 0, 0), orange, CYLINDER)
	piece(m, "Body", Vector3.new(2, 0.8, 0.8), CFrame.new(-0.3, 0, 0), steel, CYLINDER, 1)
	piece(m, "Coil", Vector3.new(0.6, 1, 1), CFrame.new(-0.8, 0, 0), orange, CYLINDER)
	piece(m, "Grip", Vector3.new(0.42, 1, 0.42), CFrame.new(-0.55, -0.75, 0), dark)
	piece(m, "Head", ball(0.62), CFrame.new(1, 0, 0), dark, BALL)
	for i = 0, 2 do
		local spin = CFrame.Angles(math.rad(i * 120), 0, 0)
		piece(m, "Claw", Vector3.new(0.85, 0.16, 0.22), spin * CFrame.new(1.4, 0.34, 0) * CFrame.Angles(0, 0, math.rad(40)), steel)
		piece(m, "Claw", Vector3.new(0.5, 0.16, 0.22), spin * CFrame.new(1.86, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-55)), steel)
	end
	return m
end

function GearModel.Shield(): Model
	local m = Instance.new("Model")
	m.Name = "Shield"
	local facing = CFrame.Angles(0, math.rad(90), 0) -- la face du disque regarde la caméra
	local gold = Color3.fromRGB(250, 205, 80)
	local rim = piece(m, "Rim", Vector3.new(0.2, 3, 3), facing, gold, CYLINDER)
	rim.CFrame = facing * CFrame.new(-0.05, 0, 0)
	piece(m, "Disc", Vector3.new(0.3, 2.6, 2.6), facing, Color3.fromRGB(110, 225, 255), CYLINDER)
	piece(m, "Star", Vector3.new(1.05, 1.05, 0.2), CFrame.new(0, 0, 0.2), gold)
	piece(m, "Star", Vector3.new(1.05, 1.05, 0.2), CFrame.new(0, 0, 0.2) * CFrame.Angles(0, 0, math.rad(45)), gold)
	return m
end

return GearModel
