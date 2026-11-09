-- Contrôles du joueur : foreuse (maintenir le clic / le doigt sur un astéroïde). Le jetpack est dans Jetpack.client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Device = require(script.Parent:WaitForChild("Device"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- DRILL ------------------------------------------------------------------

local drilling = false
local padHeld: { [Enum.KeyCode]: boolean } = {}
local pointer: Vector2? = nil -- position écran du clic / doigt
local target: BasePart? = nil
local lastSent = 0

-- Astéroïde visé, lu par l'interface pour afficher sa barre de vie (objet local au client)
local targetValue = Instance.new("ObjectValue")
targetValue.Name = "DrillTarget"
targetValue.Parent = player


-- Raison pour laquelle on ne peut pas forer cette roche (nil = on peut)
local function blocked(_rock: BasePart): string?
	if player:GetAttribute("Credits") == nil then
		return "Loading your save..."
	end
	return nil
end

-- Soute pleine : le joueur tient sa roche à deux mains (CarryService), plus de forage jusqu'à la base
local function carrying(): boolean
	return (player:GetAttribute("Cargo") or 0) >= (player:GetAttribute("CargoMax") or 1)
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
	padHeld[input.KeyCode] = nil
end)

-- Gâchettes de la manette tenues (RT / RB) : n'importe quelle manette branchée
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == Device.Pad.Drill or input.KeyCode == Device.Pad.DrillAlt) then
		padHeld[input.KeyCode] = true
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	table.clear(padHeld)
end)

-- Bouton FORER des téléphones (Mobile.client) : tant qu'il est enfoncé, on fore la roche la plus proche
-- à portée (attribut local DrillHeld). Roche à portée : attribut local RockNear (bouton et guide), 5 fois par seconde.
local lastNear = 0

-- BOUCLE PAR IMAGE ----------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then
		return
	end

	local full = carrying()
	if os.clock() - lastNear > 0.2 then
		lastNear = os.clock()
		player:SetAttribute("RockNear", not full and nearestInRange(hrp.Position) ~= nil)
	end

	-- Foreuse : clic / doigt sur la roche, bouton DRILL (téléphone) ou gâchette RT / RB (manette) :
	-- ces deux derniers forent la roche la plus proche à portée. Pas pendant la pose d'un œuf ni quand
	-- la manette navigue dans un menu.
	local padDrill = next(padHeld) ~= nil
		and not player:GetAttribute("PlacingEgg")
		and game:GetService("GuiService").SelectedObject == nil
	local wantDrill = (drilling or player:GetAttribute("DrillHeld") == true or padDrill) and not full
	local hitPart, hitPos, tooFar = nil, nil, nil
	if wantDrill then
		hitPart, hitPos, tooFar = findTarget(if drilling then pointer else nil)
		if not hitPart and os.clock() - lastWarn > 2.5 then
			lastWarn = os.clock()
			UIKit.toast(if tooFar then "{Jetpack} Too far! Fly closer" else "{Jetpack} No asteroid in reach! Fly to a rock", "warn")
		end
	elseif UserInputService.MouseEnabled and not full then
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
	if wantDrill then
		local shown = hitPart or tooFar
		outline.Adornee = shown and shown.Parent
		outline.OutlineColor = if hitPart then IN_RANGE else TOO_FAR
		outline.Enabled = shown ~= nil
	end
	if full then
		outline.Enabled = false
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
	player:SetAttribute("DrillReady", wantDrill)
	player:SetAttribute("DrillAtLocal", if active then hitPos else nil)
	if active and os.clock() - lastSent >= Config.DrillTick then
		lastSent = os.clock()
		Remotes.Drill:FireServer(hitPart, hitPos)
	end
	if targetValue.Value ~= target then
		targetValue.Value = target
	end
end)

-- La casse des roches (éclats, morceaux) est dans Impact.client.lua ; le rebond quand sa roche casse,
-- dans Jetpack.client.lua.
