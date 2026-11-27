-- Retour à la base avec un œuf (29 nov.) : quand le joueur pose le pied dans son enclos en rapportant au moins
-- une roche (attribut Cargo), la caméra fait un petit zoom avant et la base s'illumine : halo doré au sol,
-- éclat autour du joueur, lueur chaude sur l'écran. Rien quand il rentre les mains vides.
-- Purement visuel : rien n'est décidé ici.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local LayeredFx = require(script.Parent:WaitForChild("LayeredFx"))

local H = Config.HomeFx
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local GOLD = Color3.fromRGB(255, 214, 96)
local CREAM = Color3.fromRGB(255, 246, 214)

local gui = Instance.new("ScreenGui")
gui.Name = "HomeFx"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")
local glow = Instance.new("Frame")
glow.Name = "Glow"
glow.Size = UDim2.fromScale(1, 1)
glow.BackgroundColor3 = CREAM
glow.BackgroundTransparency = 1
glow.BorderSizePixel = 0
glow.Parent = gui

-- Le sol de l'enclos du joueur (Ship.Bases : attribut Index = attribut Base du joueur)
local function floorOf(): BasePart?
	local index = player:GetAttribute("Base")
	local ship = workspace:FindFirstChild("Ship")
	local bases = ship and ship:FindFirstChild("Bases")
	if type(index) ~= "number" or not bases then
		return nil
	end
	for _, b in ipairs(bases:GetChildren()) do
		if b:GetAttribute("Index") == index then
			return b:FindFirstChild("Floor") :: BasePart?
		end
	end
	return nil
end

local function inside(floor: BasePart, pos: Vector3): boolean
	local p = floor.CFrame:PointToObjectSpace(pos)
	local s = floor.Size
	return math.abs(p.X) <= s.X / 2 and math.abs(p.Z) <= s.Z / 2 and p.Y > -4 and p.Y < 30
end

local zooming = false
local function zoom()
	-- pas pendant une poursuite : MonsterFx règle déjà le champ de vision
	if zooming or player:GetAttribute("MonsterNear") then
		return
	end
	zooming = true
	local base = camera.FieldOfView
	local tIn = TweenService:Create(camera, TweenInfo.new(H.ZoomIn, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base - H.Zoom })
	tIn:Play()
	tIn.Completed:Wait()
	local tOut = TweenService:Create(camera, TweenInfo.new(H.ZoomOut, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { FieldOfView = base })
	tOut:Play()
	tOut.Completed:Wait()
	zooming = false
end

local function celebrate(floor: BasePart, root: BasePart)
	task.spawn(zoom)
	local colors = { GOLD, CREAM }
	-- halo doré qui s'ouvre sur le sol de l'enclos
	local ground = Instance.new("Attachment")
	ground.WorldPosition = Vector3.new(root.Position.X, floor.Position.Y + floor.Size.Y / 2 + 0.3, root.Position.Z)
	ground.Parent = workspace.Terrain
	LayeredFx.new(ground, { kind = "Halo", size = math.min(floor.Size.X, floor.Size.Z) * 0.7, colors = colors, lifetime = 0.9, flat = true }):Emit()
	Debris:AddItem(ground, 1.3)
	-- éclat autour du joueur
	local burst = Instance.new("Attachment")
	burst.Parent = root
	LayeredFx.new(burst, { kind = "Gleam", size = 16, colors = colors, lifetime = 0.8, zOffset = 2 }):Emit()
	Debris:AddItem(burst, 1.1)
	-- lumière chaude qui éclaire la base un instant
	local light = Instance.new("PointLight")
	light.Name = "HomeLight"
	light.Color = GOLD
	light.Range = 46
	light.Brightness = 0
	light.Shadows = false
	light.Parent = root
	TweenService:Create(light, TweenInfo.new(0.18), { Brightness = 6 }):Play()
	task.delay(0.2, function()
		TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	end)
	Debris:AddItem(light, 1.1)
	-- et une lueur sur l'écran
	glow.BackgroundTransparency = 0.72
	TweenService:Create(glow, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

local wasIn = true -- on apparaît dans sa base : pas d'effet à ce moment-là
local last = 0
RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local floor = floorOf()
	if not root or not floor then
		return
	end
	local isIn = inside(floor, root.Position)
	if isIn and not wasIn and ((player:GetAttribute("Cargo") or 0) :: number) > 0 and os.clock() - last > H.Cooldown then
		last = os.clock()
		celebrate(floor, root)
	end
	wasIn = isIn
end)
