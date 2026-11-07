-- Animation des machines à dérocher (une par base), pour tous les joueurs.
-- Le serveur (MachineService) pose sur la machine JobStart/JobEnd, EggRing, EggRarity, Queue, Owner.
-- Déroulé d'un œuf (temps relatif au début du travail, durée totale T) :
--   0 → 0,7 s  : les pinces se ferment, la tête de forage descend sur l'œuf de roche
--   0,7 → T-0,8 : forage — la mèche tourne vite et tremble, la roche lâche des éclats et rétrécit
--   T-0,8      : la roche éclate en morceaux dans un flash, le vrai œuf apparaît (modèle de l'anneau et de la rareté)
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
local EggModel = require(script.Parent:WaitForChild("EggModel"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local ANTICIPATE = 1.1 -- secondes avant l'éclatement où la roche tremble fort et s'illumine

local DESCEND = 0.7 -- secondes pour fermer les pinces et descendre la foreuse
local REVEAL = 0.8 -- secondes avant la fin où la roche éclate
local HOVER = 1.1 -- secondes où l'œuf révélé flotte avant de s'envoler
local DRILL_DOWN = 1.6 -- studs de descente de la tête de forage
local CLAMP_OPEN = 0.8 -- studs d'ouverture des pinces au repos
local EGG_H = 3.4 -- hauteur de l'œuf de roche
local REVEAL_H = 2.6 -- hauteur de base de l'œuf révélé (corps, sans les ornements)
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

-- Le vrai œuf (modèle de l'anneau et de la rareté) avec lumière, halo et rayons (rayons à partir d'Épique)
local function makeEgg(ring: number, rarity: number): Model
	local r = Config.Rarities[rarity] or Config.Rarities[1]
	local egg = EggModel.Make(ring, rarity, REVEAL_H * 0.3)
	egg.Name = "RevealedEgg"
	local core = EggModel.Core(egg)
	if not core:FindFirstChildOfClass("PointLight") then
		local light = Instance.new("PointLight")
		light.Parent = core
	end
	local light = core:FindFirstChildOfClass("PointLight") :: PointLight
	light.Color = r.Color
	light.Range = 12
	light.Brightness = 2.5
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(6 + rarity, 6 + rarity)
	b.LightInfluence = 0
	b.Parent = core
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

-- Taille de l'œuf révélé : un peu plus gros quand il est rare
local function revealHeight(rarity: number): number
	return REVEAL_H * (0.85 + 0.05 * rarity)
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

-- FISSURES LUMINEUSES -----------------------------------------------------------------
-- À chaque craquement, une fissure en zigzag s'ouvre sur la roche : un trait blanc bordé de la
-- couleur de la rareté, et un rayon de lumière qui sort de la fente. Plus on approche de
-- l'éclatement, plus les rayons sont longs et vifs. Tout est attaché à la roche (suit ses
-- tremblements et sa taille) et disparaît avec elle.

type Crack = { shafts: { Beam }, tips: { Attachment }, normals: { Vector3 }, glows: { Beam } }

-- Point de la surface de la roche dans une direction (depuis le centre)
local function surfacePoint(shell: Model, center: Vector3, dir: Vector3): (BasePart?, Vector3?, Vector3?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { shell }
	-- la roche ignore les rayons (noCollide) : on l'active le temps du tir
	local parts = {}
	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = true
			table.insert(parts, d)
		end
	end
	local hit = workspace:Raycast(center + dir * 8, -dir * 8, params)
	for _, d in ipairs(parts) do
		d.CanQuery = false
	end
	if hit and hit.Instance:IsA("BasePart") then
		return hit.Instance :: BasePart, hit.Position, hit.Normal
	end
	return nil, nil, nil
end

local function crackBeam(a0: Attachment, a1: Attachment, color: Color3, width: number, transparency: number, textured: boolean, glow: boolean, z: number): Beam
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = ColorSequence.new(color)
	b.Width0 = width
	b.Width1 = width * 0.7
	b.Transparency = NumberSequence.new(transparency)
	b.LightEmission = if glow then 1 else 0
	b.LightInfluence = 0
	b.FaceCamera = true
	b.Segments = 1
	-- dessinée devant les bosses de la roche (sa forme de collision est plus lisse que le maillage)
	b.ZOffset = z
	if textured then
		b.Texture = UIKit.Art.FxGlow
	end
	b.Parent = a0
	return b
end

local function addCrack(shell: Model, center: Vector3, color: Color3): Crack?
	-- sur la face tournée vers la caméra (effet vu par chaque joueur), à ±70° près, plutôt sur les flancs
	local toCam = camera.CFrame.Position - center
	local flat = Vector3.new(toCam.X, 0, toCam.Z)
	if flat.Magnitude < 0.05 then
		flat = Vector3.zAxis
	end
	local yaw = math.rad((math.random() - 0.5) * 140)
	local dir = (CFrame.Angles(0, yaw, 0) * flat.Unit + Vector3.new(0, math.random() * 0.9 - 0.35, 0)).Unit
	local side = dir:Cross(Vector3.yAxis)
	if side.Magnitude < 0.05 then
		side = Vector3.xAxis
	end
	side = side.Unit
	local up = side:Cross(dir).Unit
	-- orientation de la fissure au hasard (horizontale, en biais ou verticale)
	local turn = math.random() * math.pi
	side, up = side * math.cos(turn) + up * math.sin(turn), up * math.cos(turn) - side * math.sin(turn)
	local crack: Crack = { shafts = {}, tips = {}, normals = {}, glows = {} }
	local prev: Attachment? = nil
	local prevCore: Attachment? = nil
	local n = math.random(3, 5)
	local mid = math.floor(n / 2)
	local zigSign = if math.random() < 0.5 then 1 else -1
	for i = 0, n do
		-- zigzag : on avance le long de la surface en déviant à gauche et à droite
		local along = (i / n - 0.5) * 0.6
		-- zigzag irrégulier : le sens change souvent, l'écart varie
		if math.random() < 0.7 then
			zigSign = -zigSign
		end
		local zig = zigSign * (0.02 + math.random() * 0.1)
		local d = (dir + side * along + up * zig).Unit
		local part, pos, normal = surfacePoint(shell, center, d)
		if part and pos and normal then
			-- deux couches décalées : le bord sombre contre la roche, la lumière juste devant
			-- (accrocher à la roche AVANT de placer : WorldPosition dépend du parent)
			local a = Instance.new("Attachment")
			a.Parent = part
			a.WorldPosition = pos + normal * 0.06
			local core = Instance.new("Attachment")
			core.Parent = part
			core.WorldPosition = pos + normal * 0.2
			if prev and prevCore then
				crackBeam(prev, a, OUTLINE, 0.22, 0, false, false, 0.3) -- bord sombre de la fente (style cartoon)
				crackBeam(prevCore, core, color:Lerp(Color3.new(1, 1, 1), 0.5), 0.1, 0, false, true, 0.4) -- cœur lumineux
				table.insert(crack.glows, crackBeam(prevCore, core, color, 0.6, 0.3, true, true, 0.35)) -- halo coloré
			end
			prevCore = core
			-- un rayon de lumière sort au milieu de la fissure
			if i == mid then
				local tip = Instance.new("Attachment")
				tip.Parent = part
				tip.WorldPosition = pos + normal * 0.6
				local shaft = Instance.new("Beam")
				shaft.Attachment0 = a
				shaft.Attachment1 = tip
				shaft.Texture = UIKit.Art.FxGlow
				shaft.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
				shaft.Width0 = 0.5
				shaft.Width1 = 1.4
				shaft.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
				shaft.LightEmission = 1
				shaft.LightInfluence = 0
				shaft.FaceCamera = true
				shaft.ZOffset = 0.4
				shaft.Parent = a
				table.insert(crack.shafts, shaft)
				table.insert(crack.tips, tip)
				table.insert(crack.normals, part.CFrame:VectorToObjectSpace(normal))
			end
			prev = a
		end
	end
	return crack
end

-- Les rayons s'allongent et les halos s'avivent quand l'éclatement approche (a de 0 à 1)
local function updateCracks(cracks: { Crack }, a: number, now: number)
	for ci, c in ipairs(cracks) do
		local flicker = 0.85 + 0.15 * math.sin(now * 30 + ci)
		for i, shaft in ipairs(c.shafts) do
			local tip = c.tips[i]
			local base = shaft.Attachment0
			if tip and base and tip.Parent then
				tip.Position = base.Position + c.normals[i] * (0.6 + 3.5 * a) * flicker
				shaft.Width1 = (1.4 + 2 * a) * flicker
			end
		end
		for _, g in ipairs(c.glows) do
			g.Width0 = (0.6 + 0.6 * a) * flicker
			g.Width1 = g.Width0 * 0.7
		end
	end
end

-- La roche éclate : morceaux qui partent en tournant, flash, poussière
local function burst(shell: Model, center: Vector3, color: Color3, rarity: number)
	local pieces = 4 + math.min(rarity, 7)
	for _, p in ipairs(shell:GetDescendants()) do
		if p:IsA("BasePart") then
			for _ = 1, pieces do
				local chunk = p:Clone()
				for _, c in ipairs(chunk:GetChildren()) do
					c:Destroy()
				end
				chunk.Size = p.Size * (0.25 + math.random() * 0.15)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.7, math.random() - 0.5).Unit
				chunk.CFrame = CFrame.new(center + dir * 0.6) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
				chunk.Parent = workspace
				tween(chunk, 0.9, {
					CFrame = CFrame.new(center + dir * (6 + math.random() * 5) + Vector3.new(0, -2, 0)) * CFrame.Angles(math.random() * 9, math.random() * 9, 0),
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
	s:Emit(30 + 10 * rarity)
	-- éclair de lumière à la couleur de la rareté
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12 + rarity
	light.Brightness = 2.5
	light.Shadows = false
	light.Parent = a
	tween(light, 0.6, { Brightness = 0 })
	Debris:AddItem(a, 1.5)
	-- sons : gros impact croquant + éboulis
	Sfx.Play("RockBreak", { at = center })
	Sfx.Play("RockCrumble", { at = center })
	-- secousse de la caméra pour le joueur tout près (plus forte pour les raretés hautes)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if root and hum and (root.Position - center).Magnitude < 45 then
		local amp = 0.25 + 0.06 * rarity
		task.spawn(function()
			local t0 = os.clock()
			while os.clock() - t0 < 0.35 do
				local k = 1 - (os.clock() - t0) / 0.35
				hum.CameraOffset = Vector3.new((math.random() - 0.5) * amp * k, (math.random() - 0.5) * amp * k, 0)
				RunService.RenderStepped:Wait()
			end
			hum.CameraOffset = Vector3.zero
		end)
	end
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
	egg: Model?,
	fx: Fx?,
	burst: boolean,
	flown: boolean,
	spin: number,
	grind: Sfx.Loop,
	motor: Sfx.Loop,
	clanked: boolean,
	riser: boolean,
	nextCrack: number,
	punch: number,
	glow: PointLight?,
	cracks: { Crack },
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
		grind = Sfx.Loop("MachineGrind", machine.PrimaryPart),
		motor = Sfx.Loop("MachineMotor", machine.PrimaryPart),
		clanked = false,
		riser = false,
		nextCrack = 0,
		punch = 0,
		cracks = {},
	}
	st.drillRest = rel(machine, st.drill)
	st.clampLRest = rel(machine, st.clampL)
	st.clampRRest = rel(machine, st.clampR)
	st.screen = makeScreen(machine)
	states[machine] = st
	machine.AncestryChanged:Connect(function()
		if not machine:IsDescendantOf(workspace) then
			st.grind:Destroy()
			st.motor:Destroy()
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
	st.clanked = false
	st.riser = false
	st.nextCrack = 0
	st.punch = 0
	st.glow = nil
	st.cracks = {}
	st.grind:Set(0)
	st.motor:Set(0)
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
		Debris:AddItem(egg, 0)
		return
	end
	local start = egg:GetPivot().Position
	Sfx.Play("EggFly", { at = start })
	local h = (egg:GetAttribute("RevealH") or REVEAL_H) :: number
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min(1, (os.clock() - t0) / 0.55)
		local e = k * k
		local goal = root.Position + Vector3.new(0, 1.5, 0)
		EggModel.SetHeight(egg, h * (1 - 0.7 * e))
		egg:PivotTo(CFrame.new(start:Lerp(goal, e) + Vector3.new(0, math.sin(k * math.pi) * 4, 0)) * CFrame.Angles(0, k * 12, 0))
		if k >= 1 then
			conn:Disconnect()
			egg:Destroy()
			if owner == player then
				Sfx.Play("Pop", { pitch = 1.2 })
				Sfx.Play("Coin", { pitch = 1.4 })
			end
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local camPos = camera.CFrame.Position
	for machine, st in pairs(states) do
		local pivot = machine:GetPivot()
		if (pivot.Position - camPos).Magnitude > 260 then
			st.grind:Set(0)
			st.motor:Set(0)
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
			local k = math.clamp((t - DESCEND) / math.max(0.1, revealAt - DESCEND), 0, 1)
			if st.fx then
				st.fx.at.WorldPosition = eggCenter + Vector3.new(0, EGG_H / 2 - 0.2, 0)
				setFx(st.fx, drilling)
			end
			-- les pinces se referment sur la roche : « clac »
			if not st.clanked and t >= DESCEND * 0.7 and t < revealAt then
				st.clanked = true
				Sfx.Play("Clamp", { at = eggCenter })
			end
			-- forage : la mèche et la pierre montent dans les aigus jusqu'à l'éclatement
			st.grind:Set(if drilling then 1 else 0)
			st.motor:Set(if drilling then 1 else 0)
			st.grind:SetPitch(0.85 + 0.35 * k)
			st.motor:SetPitch(0.85 + 0.45 * k)
			-- la roche se fend, de plus en plus vite : craquement, éclats, petit sursaut
			if drilling and st.shell and now >= st.nextCrack then
				st.nextCrack = now + (0.55 - 0.4 * k) * (0.8 + math.random() * 0.4)
				Sfx.Play("Crack", { at = eggCenter, pitch = 0.9 + 0.3 * k + math.random() * 0.15 })
				if st.fx then
					st.fx.chips:Emit(6)
					st.fx.sparks:Emit(8)
				end
				st.punch = 0.07
				-- une nouvelle fissure lumineuse (jusqu'à 7)
				if #st.cracks < 7 then
					local c = addCrack(st.shell, eggCenter, (Config.Rarities[rarity] or Config.Rarities[1]).Color)
					if c then
						table.insert(st.cracks, c)
					end
				end
			end
			st.punch = math.max(0, st.punch - dt * 0.5)
			-- juste avant l'éclatement : la roche tremble fort et la lumière de l'œuf perce
			local anticipation = if drilling then math.clamp(1 - (revealAt - t) / ANTICIPATE, 0, 1) else 0
			if st.shell then
				-- les fissures brillent un peu dès le début, puis de plus en plus (0,25 → 1)
				updateCracks(st.cracks, math.max(anticipation, 0.25 * k), now)
			end
			if anticipation > 0 and not st.riser then
				st.riser = true
				Sfx.Play("Riser", { at = eggCenter, pitch = 1.3 })
			end
			if st.shell and anticipation > 0 then
				local rc = (Config.Rarities[rarity] or Config.Rarities[1]).Color
				if not st.glow then
					local core = st.shell.PrimaryPart or st.shell:FindFirstChildWhichIsA("BasePart")
					if core then
						local g = Instance.new("PointLight")
						g.Color = rc
						g.Range = 8
						g.Shadows = false
						g.Brightness = 0
						g.Parent = core
						st.glow = g
						-- la roche s'illumine de l'intérieur (visible même en plein jour)
						local hl = Instance.new("Highlight")
						hl.Name = "RevealGlow"
						hl.FillColor = rc
						hl.OutlineColor = rc:Lerp(Color3.new(1, 1, 1), 0.5)
						hl.FillTransparency = 1
						hl.OutlineTransparency = 1
						hl.DepthMode = Enum.HighlightDepthMode.Occluded
						hl.Parent = st.shell
					end
				end
				if st.glow then
					local pulse = 0.8 + 0.2 * math.sin(now * 40)
					st.glow.Brightness = 2.5 * anticipation * pulse
					local hl = st.shell:FindFirstChild("RevealGlow") :: Highlight?
					if hl then
						hl.FillTransparency = 1 - 0.65 * anticipation * pulse
						hl.OutlineTransparency = 1 - anticipation
					end
				end
			end
			if st.shell and drilling then
				local amp = 1 + 3 * anticipation
				local jitter = Vector3.new((math.random() - 0.5) * 0.12 * amp, (math.random() - 0.5) * 0.08 * amp, (math.random() - 0.5) * 0.12 * amp)
				st.shell:PivotTo(CFrame.new(eggCenter + jitter) * st.shell:GetPivot().Rotation)
				local target = (EGG_H * 1.05) * (1 - 0.15 * k) * (1 + st.punch)
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
					burst(st.shell, eggCenter, color, rarity)
					st.shell = nil
				end
				if st.fx then
					setFx(st.fx, false)
				end
				-- l'œuf apparaît : tintement, et fanfare à partir d'Épique
				Sfx.Play("Coin", { at = eggCenter, pitch = 0.9 + 0.08 * rarity })
				if rarity >= Config.Sounds.RareFrom then
					Sfx.Play("HatchRare", { at = eggCenter })
				end
				local egg = makeEgg(ring, rarity)
				egg:SetAttribute("RevealH", revealHeight(rarity))
				egg:SetAttribute("Born", os.clock())
				egg:PivotTo(CFrame.new(eggCenter))
				egg.Parent = machine
				st.egg = egg
			end
			-- L'œuf révélé flotte en tournant
			if st.egg then
				st.spin += dt * 2.5
				local lift = math.clamp((t - revealAt) / 0.6, 0, 1) * 1.2
				-- Apparition : il grandit avec un petit rebond (Back), puis flotte
				local born = (st.egg:GetAttribute("Born") or 0) :: number
				local g = math.clamp((os.clock() - born) / 0.35, 0, 1)
				local back = 1 + 2.7 * (g - 1) ^ 3 + 1.7 * (g - 1) ^ 2
				EggModel.SetHeight(st.egg, ((st.egg:GetAttribute("RevealH") or REVEAL_H) :: number) * (0.3 + 0.7 * back))
				st.egg:PivotTo(CFrame.new(eggCenter + Vector3.new(0, lift + math.sin(now * 3) * 0.15, 0)) * CFrame.Angles(0, st.spin, 0))
				local bb = EggModel.Core(st.egg):FindFirstChildOfClass("BillboardGui")
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
ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EggRevealed").OnClientEvent:Connect(function(ring: number, rarity: number)
	local r = Config.Rarities[rarity] or Config.Rarities[1]
	UIKit.toast("{Egg} " .. string.upper(Config.EggName(ring, rarity)) .. " (" .. r.Name .. ") ready to hatch!", "good")
end)
