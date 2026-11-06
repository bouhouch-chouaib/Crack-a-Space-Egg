-- Contrôles du joueur : jetpack (maintenir Saut en l'air) et foreuse (maintenir le clic / le doigt sur un astéroïde).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local UIKit = require(script.Parent:WaitForChild("UIKit"))
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


-- Raison pour laquelle on ne peut pas forer cette roche (nil = on peut)
local function blocked(rock: BasePart): string?
	if player:GetAttribute("Credits") == nil then
		return "Loading your save..."
	end
	if (player:GetAttribute("Cargo") or 0) >= (player:GetAttribute("CargoMax") or 1) then
		return "🥚 You carry an egg! Bring it back to your base 🏠"
	end
	if (rock:GetAttribute("Ring") or 1) > (player:GetAttribute("Ring") or 1) then
		return "🔒 Locked ring! Unlock it at the shop"
	end
	return nil
end
local lastWarn = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local onlyParams = RaycastParams.new()
onlyParams.FilterType = Enum.RaycastFilterType.Include

local belt = workspace:WaitForChild("World"):WaitForChild("Belt")

-- Contour de la roche visée : vert = à portée, rouge = trop loin (lisible sans texte)
local outline = Instance.new("Highlight")
outline.Name = "DrillOutline"
outline.FillTransparency = 1
outline.OutlineTransparency = 0
outline.DepthMode = Enum.HighlightDepthMode.Occluded
outline.Enabled = false
outline.Parent = player:WaitForChild("PlayerGui")
local IN_RANGE = Color3.fromRGB(120, 255, 90)
local TOO_FAR = Color3.fromRGB(255, 80, 70)

-- Roche sous le curseur (ou le doigt), quelle que soit sa distance
local function rockUnder(screen: Vector2, character: Model): (BasePart?, Vector3?)
	rayParams.FilterDescendantsInstances = { character }
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, rayParams)
	if hit and hit.Instance.Name == "Asteroid" and (hit.Instance:GetAttribute("HP") or 0) > 0 then
		return hit.Instance :: BasePart, hit.Position
	end
	return nil, nil
end

-- Point de la surface d'une roche le plus proche du joueur (rayon du joueur vers son centre)
local function surfacePoint(rock: BasePart, from: Vector3): Vector3
	onlyParams.FilterDescendantsInstances = { rock }
	local dir = rock.Position - from
	local hit = workspace:Raycast(from, dir, onlyParams)
	return if hit then hit.Position else rock.Position
end

-- Aide à la visée : la roche la plus proche à portée (pour les clics à côté et les enfants)
local function nearestInRange(from: Vector3): (BasePart?, Vector3?)
	local best, bestPoint, bestDist = nil, nil, math.huge
	for _, model in ipairs(belt:GetChildren()) do
		local rock = model:FindFirstChild("Asteroid")
		if rock and rock:IsA("BasePart") and (rock:GetAttribute("HP") or 0) > 0 then
			local s = rock.Size
			local rough = (rock.Position - from).Magnitude - math.max(s.X, s.Y, s.Z) / 2
			if rough <= Config.DrillRange then
				local point = surfacePoint(rock, from)
				local d = (point - from).Magnitude
				if d <= Config.DrillRange and d < bestDist then
					best, bestPoint, bestDist = rock, point, d
				end
			end
		end
	end
	return best, bestPoint
end

-- Cible du forage : la roche visée si elle est à portée, sinon la plus proche à portée.
-- Renvoie aussi la roche visée trop loin (pour le contour rouge et le message).
local function findTarget(screen: Vector2?): (BasePart?, Vector3?, BasePart?)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hrp then
		return nil, nil, nil
	end
	local aimed, aimedPoint = nil, nil
	if screen then
		aimed, aimedPoint = rockUnder(screen, character)
	end
	if aimed and aimedPoint then
		if (aimedPoint - hrp.Position).Magnitude <= Config.DrillRange then
			return aimed, aimedPoint, nil
		end
		-- Visée trop loin : on garde quand même la plus proche à portée si on en a une
		local near, nearPoint = nearestInRange(hrp.Position)
		if near then
			return near, nearPoint, nil
		end
		return nil, nil, aimed
	end
	local near, nearPoint = nearestInRange(hrp.Position)
	return near, nearPoint, nil
end

local function isPointer(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- Pendant qu'il pose un œuf dans sa base (Hatchery.client), le clic sert à poser, pas à forer
	if processed or not isPointer(input) or player:GetAttribute("PlacingEgg") then
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
	local hitPart, hitPos, tooFar = nil, nil, nil
	if drilling then
		hitPart, hitPos, tooFar = findTarget(pointer)
		if not hitPart and os.clock() - lastWarn > 2.5 then
			lastWarn = os.clock()
			UIKit.toast(if tooFar then "Too far! Jump closer 🚀" else "No asteroid in reach! Jump on a rock 🚀", "warn")
		end
	elseif UserInputService.MouseEnabled then
		-- Survol à la souris : on montre déjà si la roche est à portée
		local mouse = UserInputService:GetMouseLocation()
		local inset = game:GetService("GuiService"):GetGuiInset()
		local aimed, aimedPoint = rockUnder(Vector2.new(mouse.X, mouse.Y - inset.Y), character)
		if aimed and aimedPoint then
			if (aimedPoint - hrp.Position).Magnitude <= Config.DrillRange then
				outline.Adornee = aimed.Parent
				outline.OutlineColor = IN_RANGE
			else
				outline.Adornee = aimed.Parent
				outline.OutlineColor = TOO_FAR
			end
			outline.Enabled = true
		else
			outline.Enabled = false
		end
	end
	if drilling then
		local shown = hitPart or tooFar
		outline.Adornee = shown and shown.Parent
		outline.OutlineColor = if hitPart then IN_RANGE else TOO_FAR
		outline.Enabled = shown ~= nil
	end
	target = hitPart
	-- État lu par l'animation de forage (Drilling.client) : prêt à forer, et point d'impact
	local active = hitPart ~= nil and hitPos ~= nil and (hitPart:GetAttribute("HP") or 0) > 0
	if active and hitPart then
		local why = blocked(hitPart)
		if why then
			active = false
			if os.clock() - lastWarn > 2.5 then
				lastWarn = os.clock()
				UIKit.toast(why, "warn")
			end
		end
	end
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

-- La casse des roches (éclats, morceaux) est dans Impact.client.lua.
-- Si la roche sous le joueur casse, il rebondit et son jetpack est plein : il peut se rattraper.
Remotes.DrillHit.OnClientEvent:Connect(function(rock: BasePart?, _by: Player, _damage: number, _rarities: { number }, broken: boolean)
	if not broken or not rock then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local s = rock.Size
	if (hrp.Position - rock.Position).Magnitude <= math.max(s.X, s.Y, s.Z) / 2 + 8 then
		fuel = maxFuel()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 45), v.Z)
		UIKit.toast("🚀 Your rock broke! Fly to the next one", "info")
	end
end)
