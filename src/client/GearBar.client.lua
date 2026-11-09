-- Barre des objets (Config.Gear) : un bouton par objet possédé, au-dessus de la barre d'aide en bas d'écran.
-- Touches 1, 2, 3, 4 selon la place du bouton ; toucher le bouton sur téléphone ; LB / LT à la manette pour les deux premiers.
-- Le serveur décide de ce qu'on a (GearService, Remotes.Gear). Ce script fait aussi :
--   - l'animation du coup de batte (tous les joueurs, attribut BatSwing du personnage) ;
--   - le sol invisible des bottes, seulement dans le couloir (attribut local VoidFloor : Jetpack.client ne recharge pas dessus) ;
--   - le grappin : l'astéroïde le plus en face de la caméra, on est tiré vers lui (attribut local Hooking) ; le câble se voit chez tous (HookTo).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SafeZone = require(ReplicatedStorage.Shared:WaitForChild("SafeZone"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local new = UIKit.new
local G = Config.Gear

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
local PADS = { Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2 }
local BUTTON = 74
local GAP = 12
local ROPE_COLOR = Color3.fromRGB(255, 150, 60)

local function character(): Model?
	return player.Character
end

local function root(): BasePart?
	local c = character()
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- INTERFACE ----------------------------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "GearBar", ResetOnSpawn = false, DisplayOrder = 4, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
local bar = new("Frame", {
	Name = "Bar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -62),
	Size = UDim2.fromOffset(4 * BUTTON + 3 * GAP, BUTTON + 8),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
})
UIKit.autoScale(gui)

type Slot = { key: string, art: string, color: string, use: () -> (), owned: () -> boolean, active: (() -> boolean)?, cooldown: number, frame: TextButton, shade: Frame, tag: TextLabel, stroke: UIStroke, lastUsed: number }
local slots: { Slot } = {}

local function makeSlot(key: string, art: string, color: string, order: number, cooldown: number, use: () -> (), owned: () -> boolean, active: (() -> boolean)?): Slot
	local colors = UIKit.Colors[color]
	local frame = new("TextButton", {
		Name = key,
		Size = UDim2.fromOffset(BUTTON, BUTTON),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Visible = false,
		ZIndex = 2,
		Parent = bar,
	}, { UIKit.corner(16), UIKit.gradient(colors[1], colors[2]) })
	local stroke = UIKit.stroke(3.5)
	stroke.Parent = frame
	UIKit.studs(frame, 0.5, "Weld", 18)
	UIKit.icon(art, { Size = UDim2.fromOffset(BUTTON - 10, BUTTON - 10), Position = UDim2.fromOffset(5, 5), ZIndex = 3, Parent = frame })
	local shade = new("Frame", { Size = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 4, Parent = frame }, { UIKit.corner(16) })
	local tag = UIKit.text({ Size = UDim2.fromOffset(26, 22), Position = UDim2.fromOffset(2, 0), Text = "", TextColor3 = Color3.new(1, 1, 1), ZIndex = 5, Stroke = 2.5, Parent = frame })
	new("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 10, Parent = tag })
	UIKit.juice(frame)
	local slot: Slot = { key = key, art = art, color = color, use = use, owned = owned, active = active, cooldown = cooldown, frame = frame, shade = shade, tag = tag, stroke = stroke, lastUsed = -100 }
	frame.MouseButton1Click:Connect(function()
		slot.use()
	end)
	table.insert(slots, slot)
	return slot
end

local shieldPill = new("Frame", { Name = "Shield", Size = UDim2.fromOffset(BUTTON, BUTTON), BackgroundColor3 = Color3.fromRGB(26, 28, 42), BackgroundTransparency = 0.15, LayoutOrder = 9, Visible = false, ZIndex = 2, Parent = bar }, { UIKit.corner(16), UIKit.stroke(3.5, Color3.fromRGB(120, 230, 255)) })
UIKit.icon("Shield", { Size = UDim2.fromOffset(BUTTON - 16, BUTTON - 16), Position = UDim2.fromOffset(8, 4), ZIndex = 3, Parent = shieldPill })
local shieldCount = UIKit.text({ Size = UDim2.fromOffset(BUTTON - 6, 26), Position = UDim2.new(0, 3, 1, -26), Text = "", TextColor3 = Color3.new(1, 1, 1), ZIndex = 5, Stroke = 3, Parent = shieldPill })

-- BATTE --------------------------------------------------------------------------------------------
local function useBat(slot: () -> Slot)
	local s = slot()
	if os.clock() - s.lastUsed < s.cooldown then
		return
	end
	s.lastUsed = os.clock()
	Sfx.Play("Pop")
	Remotes.Gear:FireServer("swing")
end

-- Tout le monde voit le coup : la batte passe de la hanche à la main le temps du geste.
-- Le bras est animé par Transform, à chaque image (les avatars récents n'ont plus de Motor6D à l'épaule).
local SWING_TIME = 0.36
local swings: { [Model]: number } = {}
RunService.PreSimulation:Connect(function()
	local t = os.clock()
	for c, started in pairs(swings) do
		local age = t - started
		local upper = c:FindFirstChild("RightUpperArm")
		local shoulder = upper and upper:FindFirstChild("RightShoulder") :: any
		if not c.Parent or age > SWING_TIME then
			swings[c] = nil
		elseif shoulder then
			-- bras levé d'un coup, puis on frappe vers l'avant et il redescend
			local angle = if age < 0.16 then 165 - 135 * (age / 0.16) ^ 2 else 30 * (1 - (age - 0.16) / (SWING_TIME - 0.16))
			shoulder.Transform = shoulder.Transform * CFrame.Angles(math.rad(angle), 0, 0)
		end
	end
end)

local function playSwing(c: Model)
	local bat = c:FindFirstChild("EquippedBat")
	local handle = bat and bat:FindFirstChild("Handle")
	local weld = handle and handle:FindFirstChild("BatWeld") :: Weld?
	local hand = c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")
	if not weld or not hand or weld:GetAttribute("Busy") then
		return
	end
	weld:SetAttribute("Busy", true)
	local p0, c0 = weld.Part0, weld.C0
	weld.Part0 = hand :: BasePart
	weld.C0 = CFrame.new(0, -0.3, 0) * CFrame.Angles(0, math.rad(90), 0)
	swings[c] = os.clock()
	task.wait(SWING_TIME)
	-- le temps de finir le geste
	task.wait(0.2)
	if weld.Parent then
		weld.Part0, weld.C0 = p0, c0
		weld:SetAttribute("Busy", nil)
	end
end

local function watchCharacter(c: Model)
	c:GetAttributeChangedSignal("BatSwing"):Connect(function()
		task.spawn(playSwing, c)
	end)
end
local function watchPlayer(p: Player)
	p.CharacterAdded:Connect(watchCharacter)
	if p.Character then
		watchCharacter(p.Character)
	end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	watchPlayer(p)
end

-- TAPIS ET BOTTES : interrupteurs -------------------------------------------------------------------
local function inCorridor(): boolean
	local hrp = root()
	if not hrp then
		return false
	end
	local _, dist = SafeZone.Nearest(hrp.Position)
	return dist <= 0
end

local function isOn(name: string): boolean
	local c = character()
	return c ~= nil and c:GetAttribute(name) == true
end

local function toggle(name: string, wire: string, other: string?, otherWire: string?)
	local on = isOn(name)
	if not on and not inCorridor() then
		Sfx.Play("Error")
		UIKit.toast("Only works inside the corridor!", "warn")
		return
	end
	Sfx.Play("Click")
	if not on and other and isOn(other) then
		Remotes.Gear:FireServer(otherWire, false)
	end
	Remotes.Gear:FireServer(wire, not on)
end

-- SOL INVISIBLE DES BOTTES ---------------------------------------------------------------------------
local floor = new("Part", { Name = "VoidFloor", Size = Vector3.new(11, 1, 11), Anchored = true, CanCollide = true, CanQuery = false, CanTouch = false, Transparency = 1 })
local disc = new("Part", {
	Name = "VoidGlow",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(0.1, 7, 7),
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	CastShadow = false,
	Material = Enum.Material.SmoothPlastic,
	Color = G.Boots.Sole,
	Transparency = 0.6,
})
local floorY: number? = nil

local function stepBoots()
	local c = character()
	local hrp = root()
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	local on = c ~= nil and hrp ~= nil and hum ~= nil and isOn("Boots") and inCorridor() and player:GetAttribute("Hooking") ~= true and not isOn("Carpet")
	local thrust = player:GetAttribute("JetLocal") == 1
	if not on or thrust then
		floor.Parent, disc.Parent = nil, nil
		floorY = nil
		if player:GetAttribute("VoidFloor") then
			player:SetAttribute("VoidFloor", nil)
		end
		return
	end
	local h = hrp :: BasePart
	if not floorY then
		floorY = h.Position.Y - h.Size.Y / 2 - (hum :: Humanoid).HipHeight
	end
	local y = floorY :: number
	floor.CFrame = CFrame.new(h.Position.X, y - floor.Size.Y / 2, h.Position.Z)
	disc.CFrame = CFrame.new(h.Position.X, y + 0.02, h.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	floor.Parent, disc.Parent = workspace, workspace
	-- au-dessus du vide (rien de solide sous les pieds) : le jetpack ne recharge pas
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { c :: Model, floor, disc }
	local solid = workspace:Raycast(h.Position, Vector3.new(0, -12, 0), params)
	local overVoid = solid == nil
	if (player:GetAttribute("VoidFloor") == true) ~= overVoid then
		player:SetAttribute("VoidFloor", if overVoid then true else nil)
	end
end

-- GRAPPIN --------------------------------------------------------------------------------------------
local hookPart: BasePart? = nil
local hookOffset = CFrame.new()
local hookEnds = 0

local function belt(): Instance?
	local world = workspace:FindFirstChild("World")
	return world and world:FindFirstChild("Belt")
end

-- L'astéroïde le plus en face de la caméra, à portée : pas besoin de viser au pixel près
local function findRock(from: Vector3, rocks: Instance): BasePart?
	local look = camera.CFrame.LookVector
	local best, score = nil, G.Hook.Cone
	for _, d in ipairs(rocks:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local delta = d.Position - from
			local dist = delta.Magnitude
			if dist > 1 and dist <= G.Hook.Range then
				local dot = delta.Unit:Dot(look)
				if dot > score then
					best, score = d, dot
				end
			end
		end
	end
	return best
end

local function stopHook()
	if hookPart then
		hookPart = nil
		player:SetAttribute("Hooking", nil)
		Remotes.Gear:FireServer("hookEnd")
	end
end

local function useHook(slot: () -> Slot)
	local s = slot()
	local hrp = root()
	local rocks = belt()
	if not hrp or not rocks or hookPart then
		return
	end
	if os.clock() - s.lastUsed < s.cooldown then
		UIKit.toast("Grappling hook is recharging", "info")
		return
	end
	local rock = findRock(hrp.Position, rocks)
	if not rock then
		Sfx.Play("Error")
		UIKit.toast("Face an asteroid closer to you!", "warn")
		return
	end
	-- on s'accroche à la surface de la roche, côté joueur
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { rock }
	local hit = workspace:Raycast(hrp.Position, (rock.Position - hrp.Position) * 1.1, params)
	local at = if hit then hit.Position else rock.Position
	s.lastUsed = os.clock()
	hookPart = rock
	hookOffset = rock.CFrame:ToObjectSpace(CFrame.new(at))
	hookEnds = os.clock() + G.Hook.Range / G.Hook.Speed + 0.4
	player:SetAttribute("Hooking", true)
	local c = character()
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	Sfx.Play("Clamp")
	Remotes.Gear:FireServer("hook", at)
end

local function stepHook()
	local hrp = root()
	if not hookPart then
		return
	end
	if not hrp or not hookPart.Parent or os.clock() > hookEnds then
		stopHook()
		return
	end
	local target = (hookPart.CFrame * hookOffset).Position
	local delta = target - hrp.Position
	if delta.Magnitude < G.Hook.Arrive then
		hrp.AssemblyLinearVelocity = delta.Unit * 12 + Vector3.new(0, 18, 0) -- petit saut pour se poser sur la roche
		stopHook()
		return
	end
	hrp.AssemblyLinearVelocity = delta.Unit * G.Hook.Speed
end

-- Câble du grappin, vu chez tous les joueurs
local ropes: { [Model]: Part } = {}
local function stepRopes()
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local at = c and c:GetAttribute("HookTo")
		local hand = c and (c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")) :: BasePart?
		local rope = c and ropes[c :: Model]
		if c and hand and typeof(at) == "Vector3" then
			local line: Part = rope or new("Part", { Name = "HookRope", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic, Color = ROPE_COLOR, Parent = workspace })
			ropes[c :: Model] = line
			local from = hand.Position
			line.Size = Vector3.new(0.18, 0.18, (at - from).Magnitude)
			line.CFrame = CFrame.lookAt(from:Lerp(at, 0.5), at)
		elseif c and rope then
			rope:Destroy()
			ropes[c :: Model] = nil
		end
	end
	for c, rope in pairs(ropes) do
		if not c.Parent then
			rope:Destroy()
			ropes[c] = nil
		end
	end
end

-- LES QUATRE BOUTONS ----------------------------------------------------------------------------------
local batSlot: Slot
local hookSlot: Slot
batSlot = makeSlot("Bat", "BatWood", "Orange", 1, G.BatCooldown, function()
	useBat(function()
		return batSlot
	end)
end, function()
	return ((player:GetAttribute("Bat") or 0) :: number) > 0
end)
makeSlot("Carpet", "Carpet", "Purple", 2, 0, function()
	toggle("Carpet", "carpet", "Boots", "boots")
end, function()
	return player:GetAttribute("Pass_Carpet") == true
end, function()
	return isOn("Carpet")
end)
makeSlot("Boots", "Boots", "Blue", 3, 0, function()
	toggle("Boots", "boots", "Carpet", "carpet")
end, function()
	return player:GetAttribute("Pass_Boots") == true
end, function()
	return isOn("Boots")
end)
hookSlot = makeSlot("Hook", "Hook", "Teal", 4, G.Hook.Cooldown, function()
	useHook(function()
		return hookSlot
	end)
end, function()
	return player:GetAttribute("Pass_Hook") == true
end)

local function refreshIcons()
	local tier = (player:GetAttribute("Bat") or 0) :: number
	local b = Config.Bats[math.clamp(tier, 1, #Config.Bats)]
	local icon = batSlot.frame:FindFirstChildOfClass("ImageLabel")
	if icon then
		icon.Image = UIKit.Art[b.Art] or b.Art
	end
end

-- Les touches suivent la place du bouton dans la barre
local function rebind()
	for i = 1, #KEYS do
		ContextActionService:UnbindAction("Gear" .. i)
	end
	local place = 0
	for _, s in ipairs(slots) do
		local visible = s.owned()
		s.frame.Visible = visible
		if visible then
			place += 1
			s.tag.Text = tostring(place)
			local inputs: { Enum.KeyCode } = { KEYS[place] }
			if PADS[place] then
				table.insert(inputs, PADS[place])
			end
			ContextActionService:BindAction("Gear" .. place, function(_, state)
				if state == Enum.UserInputState.Begin then
					s.use()
				end
				return Enum.ContextActionResult.Pass
			end, false, table.unpack(inputs))
		end
	end
	local shields = (player:GetAttribute("Shields") or 0) :: number
	shieldPill.Visible = shields > 0
	shieldCount.Text = "x" .. shields
	refreshIcons()
end

player.AttributeChanged:Connect(function(name)
	if name == "Bat" or name == "Shields" or name == "Pass_Carpet" or name == "Pass_Boots" or name == "Pass_Hook" then
		rebind()
	end
end)
rebind()

player.CharacterAdded:Connect(function()
	stopHook()
	floorY = nil
end)

RunService.RenderStepped:Connect(function()
	stepBoots()
	stepHook()
	stepRopes()
	local t = os.clock()
	for _, s in ipairs(slots) do
		local left = if s.cooldown > 0 then math.max(0, 1 - (t - s.lastUsed) / s.cooldown) else 0
		s.shade.Size = UDim2.fromScale(1, left)
		local on = s.active ~= nil and (s.active :: () -> boolean)()
		s.stroke.Color = if on then Color3.fromRGB(255, 240, 150) else UIKit.Outline
		s.stroke.Thickness = if on then 5 else 3.5
	end
end)
