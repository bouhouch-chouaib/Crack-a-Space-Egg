-- Contrôles du joueur : jetpack (maintenir Saut en l'air) et foreuse (maintenir le clic / le doigt sur un astéroïde).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- JETPACK ------------------------------------------------------------------

local fuel = Config.JetpackFuelBase
local lastJumpRequest = 0
local flame: ParticleEmitter? = nil

local function maxFuel(): number
	return Config.JetpackFuelBase + Config.JetpackFuelPerLevel * (player:GetAttribute("Lvl_Thruster") or 0)
end

-- JumpRequest se répète tant que le bouton Saut est tenu (clavier, manette et bouton tactile)
UserInputService.JumpRequest:Connect(function()
	lastJumpRequest = os.clock()
end)

local function setupCharacter(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	local attach = Instance.new("Attachment")
	attach.Name = "JetpackAttachment"
	attach.Position = Vector3.new(0, -0.6, 0.9)
	attach.Parent = hrp
	local p = Instance.new("ParticleEmitter")
	p.Texture = "rbxasset://textures/particles/fire_main.dds"
	p.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 160, 80))
	p.Size = NumberSequence.new(0.8, 0)
	p.Lifetime = NumberRange.new(0.15, 0.3)
	p.Rate = 80
	p.Speed = NumberRange.new(12)
	p.EmissionDirection = Enum.NormalId.Bottom
	p.LightEmission = 1
	p.Enabled = false
	p.Parent = attach
	flame = p
	fuel = maxFuel()
end
player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	task.spawn(setupCharacter, player.Character)
end

-- DRILL ------------------------------------------------------------------

local drilling = false
local pointer: Vector2? = nil -- position écran du clic / doigt
local target: BasePart? = nil
local lastSent = 0

-- Astéroïde visé, lu par l'interface pour afficher sa barre de vie (objet local au client)
local targetValue = Instance.new("ObjectValue")
targetValue.Name = "DrillTarget"
targetValue.Parent = player

local sparks = Instance.new("Attachment")
local sparkEmitter = Instance.new("ParticleEmitter")
sparkEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparkEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
sparkEmitter.Size = NumberSequence.new(0.6, 0)
sparkEmitter.Lifetime = NumberRange.new(0.2, 0.5)
sparkEmitter.Rate = 0
sparkEmitter.Speed = NumberRange.new(10, 20)
sparkEmitter.SpreadAngle = Vector2.new(60, 60)
sparkEmitter.LightEmission = 1
sparkEmitter.Parent = sparks
sparks.Parent = workspace.Terrain

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function findTarget(): (BasePart?, Vector3?)
	if not pointer then
		return nil, nil
	end
	local character = player.Character
	if not character then
		return nil, nil
	end
	rayParams.FilterDescendantsInstances = { character }
	local ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, rayParams)
	if not hit or hit.Instance.Name ~= "Asteroid" then
		return nil, nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or (hrp.Position - hit.Position).Magnitude > Config.DrillRange + 4 then
		return nil, nil
	end
	return hit.Instance :: BasePart, hit.Position
end

local function isPointer(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not isPointer(input) then
		return
	end
	drilling = true
	pointer = Vector2.new(input.Position.X, input.Position.Y)
end)
UserInputService.InputChanged:Connect(function(input)
	if drilling and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		pointer = Vector2.new(input.Position.X, input.Position.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if isPointer(input) then
		drilling = false
		pointer = nil
	end
end)

-- BOUCLE PAR IMAGE ----------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then
		return
	end

	-- Jetpack : pousse vers le haut tant que Saut est tenu, en l'air, avec du carburant
	local state = hum:GetState()
	local airborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
	local thrusting = airborne and fuel > 0 and os.clock() - lastJumpRequest < 0.15
	if thrusting then
		fuel = math.max(0, fuel - dt)
		local v = hrp.AssemblyLinearVelocity
		local up = math.min(v.Y + Config.JetpackThrust * 3 * dt, Config.JetpackThrust * 0.55)
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, up), v.Z)
	elseif not airborne then
		fuel = math.min(maxFuel(), fuel + Config.JetpackRefill * dt)
	end
	if flame then
		flame.Enabled = thrusting
	end
	player:SetAttribute("Fuel", fuel / maxFuel())

	-- Foreuse
	local hitPart, hitPos = nil, nil
	if drilling then
		hitPart, hitPos = findTarget()
	end
	target = hitPart
	-- État lu par l'animation de forage (Drilling.client) : prêt à forer, et point d'impact
	local active = hitPart ~= nil and hitPos ~= nil and (hitPart:GetAttribute("HP") or 0) > 0
	player:SetAttribute("DrillReady", drilling)
	player:SetAttribute("DrillAtLocal", if active then hitPos else nil)
	if active and os.clock() - lastSent >= Config.DrillTick then
		lastSent = os.clock()
		Remotes.Drill:FireServer(hitPart, hitPos)
	end
	if targetValue.Value ~= target then
		targetValue.Value = target
	end
end)

-- Petite explosion visuelle quand un astéroïde casse
Remotes.AsteroidBroken.OnClientEvent:Connect(function(asteroid: BasePart, _by: Player, _gained: number)
	if not asteroid or not asteroid.Parent then
		return
	end
	local a = Instance.new("Attachment")
	a.WorldPosition = asteroid.Position
	a.Parent = workspace.Terrain
	local e = sparkEmitter:Clone()
	e.Color = ColorSequence.new(asteroid.Color)
	e.Size = NumberSequence.new(1.5, 0)
	e.Speed = NumberRange.new(20, 40)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = a
	e:Emit(40)
	game:GetService("Debris"):AddItem(a, 2)
end)
