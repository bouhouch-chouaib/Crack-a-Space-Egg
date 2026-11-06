-- Animation des machines à dérocher (une par base), pour tous les joueurs.
-- Le serveur (MachineService) pose sur la machine JobStart/JobEnd, EggRing, EggRarity, Queue, Owner.
-- Déroulé d'un œuf (temps relatif au début du travail, durée totale T) :
--   0 → 0,7 s  : les pinces se ferment, la tête de forage descend sur l'œuf de roche
--   0,7 → T-0,8 : forage — la mèche tourne vite et tremble, la roche lâche des éclats et rétrécit
--   T-0,8      : la roche éclate en morceaux dans un flash, l'œuf apparaît (couleur de sa rareté)
--   T-0,8 → T  : la foreuse remonte, les pinces s'ouvrent, l'œuf flotte en tournant
--   après T    : l'œuf vole jusqu'au propriétaire (« +1 🥚 READY »)
-- L'écran de la console suit les étapes (barre orange « REMOVING ROCK... », puis verte « EGG REVEALED! »).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("Theme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local camera = workspace.CurrentCamera

local DESCEND = 0.7 -- secondes pour fermer les pinces et descendre la foreuse
local REVEAL = 0.8 -- secondes avant la fin où la roche éclate
local HOVER = 1.1 -- secondes où l'œuf révélé flotte avant de s'envoler
local DRILL_DOWN = 1.6 -- studs de descente de la tête de forage
local CLAMP_OPEN = 0.8 -- studs d'ouverture des pinces au repos
local EGG_H = 3.4 -- hauteur de l'œuf de roche
local OUTLINE = Color3.fromRGB(22, 22, 32)

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad), props)
	tw:Play()
	return tw
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.FontFace = Theme.FontHeavy
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	for k, v in pairs(props) do
		(t :: any)[k] = v
	end
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = OUTLINE
	s.Parent = t
	t.Parent = parent
	return t
end

-- ÉCRAN HOLOGRAPHIQUE --------------------------------------------------------------
-- La pièce « Screen » est penchée dans le modèle : on pose devant elle une plaque invisible
-- alignée sur l'écran (orientation calculée d'après le modèle Blender) qui porte la SurfaceGui.

local SCREEN_NORMAL = Vector3.new(-0.546, 0.309, 0.779) -- repère de la machine (marches vers +Z)
local SCREEN_UP = Vector3.new(0.177, 0.951, -0.253)

type Screen = { title: TextLabel, sub: TextLabel, fill: Frame, grad: UIGradient, icon: ImageLabel }

local function makeScreen(machine: Model): Screen?
	local part = machine:FindFirstChild("Screen") :: BasePart?
	if not part then
		return nil
	end
	local pivot = machine:GetPivot()
	local normal = pivot:VectorToWorldSpace(SCREEN_NORMAL)
	local up = pivot:VectorToWorldSpace(SCREEN_UP)
	local plate = Instance.new("Part")
	plate.Name = "HoloScreen"
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanQuery = false
	plate.CanTouch = false
	plate.Transparency = 1
	plate.Size = Vector3.new(1.95, 1.35, 0.05)
	plate.CFrame = CFrame.lookAt(part.Position + normal * 0.08, part.Position + normal * 2, up)
	plate.Parent = machine
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 160
	gui.LightInfluence = 0
	gui.Brightness = 1.5
	gui.Parent = plate
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(16, 40, 80)
	bg.Parent = gui
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(40, 120, 200), Color3.fromRGB(10, 30, 70))
	g.Rotation = 90
	g.Parent = bg
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = UIKit.Art.Egg
	icon.ImageColor3 = Color3.fromRGB(150, 230, 255)
	icon.Size = UDim2.fromScale(0.34, 0.5)
	icon.Position = UDim2.fromScale(0.33, 0.06)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = bg
	local title = label(bg, { Size = UDim2.fromScale(0.92, 0.17), Position = UDim2.fromScale(0.04, 0.56), Text = "DEROCK MACHINE" })
	local sub = label(bg, { Size = UDim2.fromScale(0.92, 0.11), Position = UDim2.fromScale(0.04, 0.73), Text = "", TextColor3 = Color3.fromRGB(190, 235, 255) })
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(0.86, 0.09)
	back.Position = UDim2.fromScale(0.07, 0.87)
	back.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
	back.Parent = bg
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = OUTLINE
	st.Parent = back
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Parent = fill
	return { title = title, sub = sub, fill = fill, grad = grad, icon = icon }
end

local function setBar(s: Screen, f: number, green: boolean)
	s.fill.Size = UDim2.fromScale(math.clamp(f, 0, 1), 1)
	if green then
		s.grad.Color = ColorSequence.new(Color3.fromRGB(150, 255, 100), Color3.fromRGB(50, 190, 50))
	else
		s.grad.Color = ColorSequence.new(Color3.fromRGB(255, 205, 90), Color3.fromRGB(240, 130, 30))
	end
end

-- ŒUF DE ROCHE ET EFFETS --------------------------------------------------------

local function noCollide(m: Instance)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

-- La coque de roche : une forme d'astéroïde de l'anneau d'origine, à la taille de l'œuf
local function makeShell(ring: number): Model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Asteroids")
	local set = folder and folder:FindFirstChild("Ring" .. ring)
	local template = set and (if set:IsA("Folder") then set:FindFirstChild("V1") else set)
	local shell: Model
	if template and template:IsA("Model") then
		shell = template:Clone()
		local size = shell:GetExtentsSize()
		shell:ScaleTo(EGG_H * 1.05 / math.max(size.X, size.Y, size.Z))
	else
		shell = Instance.new("Model")
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * EGG_H
		p.Material = Enum.Material.Slate
		p.Color = Color3.fromRGB(150, 140, 130)
		p.Parent = shell
		shell.PrimaryPart = p
	end
	shell.Name = "RockShell"
	noCollide(shell)
	return shell
end

local function makeEgg(rarity: number): Part
	local r = Config.Rarities[rarity] or Config.Rarities[1]
	local egg = Instance.new("Part")
	egg.Name = "RevealedEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.one * 2.4
	egg.Material = Enum.Material.SmoothPlastic
	egg.Color = r.Color
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanQuery = false
	egg.CanTouch = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.3, 1)
	mesh.Parent = egg
	local light = Instance.new("PointLight")
	light.Color = r.Color
	light.Range = 12
	light.Brightness = 2.5
	light.Parent = egg
	-- Halo et rayons (rayons à partir d'Épique)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(6 + rarity, 6 + rarity)
	b.LightInfluence = 0
	b.Parent = egg
	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Size = UDim2.fromScale(1, 1)
	glow.Image = UIKit.Art.FxGlow
	glow.ImageColor3 = r.Color
	glow.ImageTransparency = 0.3
	glow.Parent = b
	if rarity >= 4 then
		local rays = Instance.new("ImageLabel")
		rays.Name = "Rays"
		rays.BackgroundTransparency = 1
		rays.AnchorPoint = Vector2.new(0.5, 0.5)
		rays.Position = UDim2.fromScale(0.5, 0.5)
		rays.Size = UDim2.fromScale(1.5, 1.5)
		rays.Image = UIKit.Art.FxRays
		rays.ImageColor3 = r.Color
		rays.ImageTransparency = 0.2
		rays.Parent = b
	end
	return egg
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	e.Enabled = false
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

type Fx = { at: Attachment, sparks: ParticleEmitter, chips: ParticleEmitter, dust: ParticleEmitter, flash: ParticleEmitter }

local function makeFx(rockColor: Color3): Fx
	local at = Instance.new("Attachment")
	at.Parent = workspace.Terrain
	local sparks = emitter(at, {
		Texture = "rbxassetid://96887170089913",
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 160, 50)),
		Size = NumberSequence.new({ kp(0, 0.8), kp(1, 0.2) }),
		Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) }),
		Lifetime = NumberRange.new(0.25, 0.5),
		Speed = NumberRange.new(14, 28),
		SpreadAngle = Vector2.new(80, 80),
		Acceleration = Vector3.new(0, -30, 0),
		LightEmission = 1,
		Rate = 60,
	})
	local chips = emitter(at, {
		Texture = UIKit.Art.FxShard,
		Color = ColorSequence.new(rockColor, rockColor:Lerp(Color3.new(0, 0, 0), 0.35)),
		Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0.25) }),
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, -40, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-400, 400),
		LightInfluence = 1,
		Rate = 26,
	})
	local dust = emitter(at, {
		Texture = UIKit.Art.FxGlow,
		Color = ColorSequence.new(rockColor:Lerp(Color3.new(1, 1, 1), 0.4)),
		Size = NumberSequence.new({ kp(0, 1.2), kp(1, 4) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.2, 0.55), kp(1, 1) }),
		Lifetime = NumberRange.new(0.7, 1.1),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(80, 80),
		LightInfluence = 1,
		Rate = 10,
	})
	local flash = emitter(at, {
		Texture = UIKit.Art.FxGlow,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 170, 60)),
		Size = NumberSequence.new({ kp(0, 2), kp(1, 3) }),
		Transparency = NumberSequence.new({ kp(0, 0.2), kp(1, 1) }),
		Lifetime = NumberRange.new(0.06, 0.12),
		Speed = NumberRange.new(0),
		LightEmission = 1,
		LockedToPart = true,
		Rate = 25,
	})
	return { at = at, sparks = sparks, chips = chips, dust = dust, flash = flash }
end

local function setFx(fx: Fx, on: boolean)
	fx.sparks.Enabled = on
	fx.chips.Enabled = on
	fx.dust.Enabled = on
	fx.flash.Enabled = on
end

-- La roche éclate : morceaux qui partent en tournant, flash, poussière
local function burst(shell: Model, center: Vector3, color: Color3)
	for _, p in ipairs(shell:GetDescendants()) do
		if p:IsA("BasePart") then
			for _ = 1, 4 do
				local chunk = p:Clone()
				for _, c in ipairs(chunk:GetChildren()) do
					c:Destroy()
				end
				chunk.Size = p.Size * (0.25 + math.random() * 0.15)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.7, math.random() - 0.5).Unit
				chunk.CFrame = CFrame.new(center + dir * 0.6) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
				chunk.Parent = workspace
				tween(chunk, 0.9, {
					CFrame = CFrame.new(center + dir * (5 + math.random() * 3) + Vector3.new(0, -2, 0)) * CFrame.Angles(math.random() * 9, math.random() * 9, 0),
					Size = chunk.Size * 0.3,
					Transparency = 1,
				})
				Debris:AddItem(chunk, 1)
			end
		end
	end
	shell:Destroy()
	local a = Instance.new("Attachment")
	a.WorldPosition = center
	a.Parent = workspace.Terrain
	local f = emitter(a, {
		Texture = UIKit.Art.FxGlow,
		Color = ColorSequence.new(Color3.new(1, 1, 1), color),
		Size = NumberSequence.new({ kp(0, 3), kp(1, 12) }),
		Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) }),
		Lifetime = NumberRange.new(0.4, 0.5),
		Speed = NumberRange.new(0),
		LightEmission = 1,
	})
	f:Emit(3)
	local s = emitter(a, {
		Texture = UIKit.Art.FxSparkle,
		Color = ColorSequence.new(Color3.new(1, 1, 1), color),
		Size = NumberSequence.new({ kp(0, 0), kp(0.2, 1.4), kp(1, 0) }),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(10, 22),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 1,
	})
	s:Emit(30)
	Debris:AddItem(a, 1.5)
end

-- MACHINES -----------------------------------------------------------------------

type State = {
	machine: Model,
	drill: Model?,
	drillRest: CFrame, -- position de repos (repère de la machine)
	clampL: Model?,
	clampR: Model?,
	clampLRest: CFrame,
	clampRRest: CFrame,
	spot: Attachment?,
	screen: Screen?,
	job: number?, -- JobStart du travail affiché
	shell: Model?,
	egg: Part?,
	fx: Fx?,
	burst: boolean,
	flown: boolean,
	spin: number,
}

local states: { [Model]: State } = {}

local function rel(machine: Model, m: Model?): CFrame
	return if m then machine:GetPivot():ToObjectSpace(m:GetPivot()) else CFrame.new()
end

local function track(machine: Model)
	if states[machine] then
		return
	end
	local st: State = {
		machine = machine,
		drill = machine:FindFirstChild("Drill") :: Model?,
		clampL = machine:FindFirstChild("ClampL") :: Model?,
		clampR = machine:FindFirstChild("ClampR") :: Model?,
		drillRest = CFrame.new(),
		clampLRest = CFrame.new(),
		clampRRest = CFrame.new(),
		spot = machine.PrimaryPart and machine.PrimaryPart:FindFirstChild("EggSpot") :: Attachment?,
		burst = false,
		flown = false,
		spin = 0,
	}
	st.drillRest = rel(machine, st.drill)
	st.clampLRest = rel(machine, st.clampL)
	st.clampRRest = rel(machine, st.clampR)
	st.screen = makeScreen(machine)
	states[machine] = st
	machine.AncestryChanged:Connect(function()
		if not machine:IsDescendantOf(workspace) then
			states[machine] = nil
		end
	end)
end

local function scan()
	local ship = workspace:FindFirstChild("Ship")
	local bases = ship and ship:FindFirstChild("Bases")
	if not bases then
		return
	end
	for _, b in ipairs(bases:GetChildren()) do
		local m = b:FindFirstChild("DerockMachine")
		if m and m:IsA("Model") and m.PrimaryPart then
			track(m)
		end
	end
end
task.spawn(function()
	while true do
		scan()
		task.wait(2) -- les machines arrivent avec le chargement en continu
	end
end)

local function clearJob(st: State)
	if st.shell then
		st.shell:Destroy()
		st.shell = nil
	end
	if st.egg then
		st.egg:Destroy()
		st.egg = nil
	end
	if st.fx then
		st.fx.at:Destroy()
		st.fx = nil
	end
	st.job = nil
	st.burst = false
	st.flown = false
end

-- L'œuf révélé vole jusqu'au propriétaire, puis « +1 🥚 READY »
local function flyEgg(st: State, owner: Player?)
	local egg = st.egg
	st.egg = nil
	if not egg then
		return
	end
	local character = owner and owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		tween(egg, 0.4, { Size = Vector3.zero, Transparency = 1 })
		Debris:AddItem(egg, 0.5)
		return
	end
	local start = egg.Position
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / 0.55)
		local e = k * k
		local goal = root.Position + Vector3.new(0, 1.5, 0)
		egg.CFrame = CFrame.new(start:Lerp(goal, e) + Vector3.new(0, math.sin(k * math.pi) * 4, 0)) * CFrame.Angles(0, k * 12, 0)
		egg.Size = Vector3.one * 2.4 * (1 - 0.7 * e)
		if k >= 1 then
			conn:Disconnect()
			egg:Destroy()
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local camPos = camera.CFrame.Position
	for machine, st in pairs(states) do
		local pivot = machine:GetPivot()
		if (pivot.Position - camPos).Magnitude > 260 then
			continue
		end
		local js = machine:GetAttribute("JobStart") :: number?
		local je = machine:GetAttribute("JobEnd") :: number?
		local ring = (machine:GetAttribute("EggRing") or 1) :: number
		local rarity = (machine:GetAttribute("EggRarity") or 1) :: number
		local queue = (machine:GetAttribute("Queue") or 0) :: number
		local owner = Players:GetPlayerByUserId((machine:GetAttribute("Owner") or 0) :: number)
		local spot = st.spot and st.spot.WorldPosition or pivot.Position
		local eggCenter = spot + Vector3.new(0, EGG_H / 2, 0)
		local down, closed, spinGoal = 0, 0, 0

		if js and je then
			-- Nouveau travail : nouvel œuf de roche sur le plateau
			if st.job ~= js then
				clearJob(st)
				st.job = js
				local shell = makeShell(ring)
				shell:PivotTo(CFrame.new(eggCenter) * CFrame.Angles(0, math.random() * 6, 0))
				shell.Parent = machine
				st.shell = shell
				local p = shell.PrimaryPart or shell:FindFirstChildWhichIsA("BasePart")
				st.fx = makeFx(if p then p.Color else Color3.fromRGB(150, 140, 130))
			end
			local T = je - js
			local t = now - js
			local revealAt = T - REVEAL
			if t < DESCEND then
				local k = smooth(t / DESCEND)
				down, closed, spinGoal = k, k, 10
			elseif t < revealAt then
				down, closed, spinGoal = 1, 1, 40
			else
				local k = smooth((t - revealAt) / REVEAL)
				down, closed, spinGoal = 1 - k, 1 - k, 40 * (1 - k)
			end
			-- Forage : vibration, éclats, la roche rétrécit
			local drilling = t >= DESCEND * 0.8 and t < revealAt
			if st.fx then
				st.fx.at.WorldPosition = eggCenter + Vector3.new(0, EGG_H / 2 - 0.2, 0)
				setFx(st.fx, drilling)
			end
			if st.shell and drilling then
				local k = math.clamp((t - DESCEND) / math.max(0.1, revealAt - DESCEND), 0, 1)
				local jitter = Vector3.new((math.random() - 0.5) * 0.12, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.12)
				st.shell:PivotTo(CFrame.new(eggCenter + jitter) * st.shell:GetPivot().Rotation)
				local target = (EGG_H * 1.05) * (1 - 0.15 * k)
				local size = st.shell:GetExtentsSize()
				local cur = math.max(size.X, size.Y, size.Z)
				if math.abs(cur - target) > 0.02 then
					st.shell:ScaleTo(st.shell:GetScale() * target / cur)
				end
			end
			-- La roche éclate, l'œuf apparaît
			if t >= revealAt and not st.burst then
				st.burst = true
				local color = (Config.Rarities[rarity] or Config.Rarities[1]).Color
				if st.shell then
					burst(st.shell, eggCenter, color)
					st.shell = nil
				end
				if st.fx then
					setFx(st.fx, false)
				end
				local egg = makeEgg(rarity)
				egg.CFrame = CFrame.new(eggCenter)
				egg.Parent = machine
				st.egg = egg
				egg.Size = Vector3.one * 0.7
				tween(egg, 0.35, { Size = Vector3.one * 2.4 }, Enum.EasingStyle.Back)
			end
			-- L'œuf révélé flotte en tournant
			if st.egg then
				st.spin += dt * 2.5
				local lift = math.clamp((t - revealAt) / 0.6, 0, 1) * 1.2
				st.egg.CFrame = CFrame.new(eggCenter + Vector3.new(0, lift + math.sin(now * 3) * 0.15, 0)) * CFrame.Angles(0, st.spin, 0)
				local bb = st.egg:FindFirstChildOfClass("BillboardGui")
				local rays = bb and bb:FindFirstChild("Rays") :: ImageLabel?
				if rays then
					rays.Rotation = (now * 60) % 360
				end
				if t >= T + HOVER - 0.3 and not st.flown then
					st.flown = true
					flyEgg(st, owner)
				end
			end
			-- Écran de la console
			if st.screen then
				local s = st.screen
				if t < revealAt then
					s.title.Text = "REMOVING ROCK..."
					s.title.TextColor3 = Color3.fromRGB(255, 205, 90)
					setBar(s, t / revealAt, false)
					s.icon.ImageColor3 = Color3.fromRGB(150, 230, 255)
				else
					local r = Config.Rarities[rarity] or Config.Rarities[1]
					s.title.Text = "EGG REVEALED!"
					s.title.TextColor3 = Color3.fromRGB(150, 255, 110)
					setBar(s, 1, true)
					s.icon.ImageColor3 = r.Color
				end
				local r = Config.Rarities[rarity] or Config.Rarities[1]
				s.sub.Text = string.upper(r.Name) .. (if queue > 0 then "  ·  " .. queue .. " in line" else "")
				s.sub.TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.3)
			end
		else
			if st.job then
				-- Fin de la file : l'œuf encore affiché s'envole
				if st.egg and not st.flown then
					flyEgg(st, owner)
				end
				clearJob(st)
			end
			if st.screen then
				local s = st.screen
				s.title.Text = "DEROCK MACHINE"
				s.title.TextColor3 = Color3.new(1, 1, 1)
				s.sub.Text = "Bring your rock eggs here!"
				s.sub.TextColor3 = Color3.fromRGB(190, 235, 255)
				s.icon.ImageColor3 = Color3.fromRGB(150, 230, 255)
				setBar(s, 0, false)
			end
		end

		-- Pièces mobiles : tête de forage (descente + rotation + tremblement), pinces
		if st.drill then
			local shake = if spinGoal > 30 then CFrame.new((math.random() - 0.5) * 0.06, (math.random() - 0.5) * 0.08, (math.random() - 0.5) * 0.06) else CFrame.new()
			local spinAngle = (now * spinGoal) % (math.pi * 2)
			local restWorld = pivot * st.drillRest
			st.drill:PivotTo(CFrame.new(restWorld.Position - Vector3.new(0, DRILL_DOWN * down, 0)) * restWorld.Rotation * CFrame.Angles(0, spinAngle, 0) * shake)
		end
		local open = CLAMP_OPEN * (1 - closed)
		if st.clampL then
			st.clampL:PivotTo(pivot * st.clampLRest * CFrame.new(-open, 0, 0))
		end
		if st.clampR then
			st.clampR:PivotTo(pivot * st.clampRRest * CFrame.new(open, 0, 0))
		end
	end
end)

-- Message quand un de ses œufs est dégagé
ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EggRevealed").OnClientEvent:Connect(function(_ring: number, rarity: number)
	local r = Config.Rarities[rarity] or Config.Rarities[1]
	UIKit.toast("🥚 " .. string.upper(r.Name) .. " egg ready to hatch!", "good")
end)
