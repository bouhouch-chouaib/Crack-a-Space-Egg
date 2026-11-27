-- Cinématique d'éclosion des œufs les plus rares (Config.Hatch.Cinema), pour leur propriétaire seulement.
--   local stage = HatchCinema.Start(egg, secondes)   -- l'écran passe au noir, renvoie la copie de l'œuf à charger
--   HatchCinema.Reveal({ ring, rarity, size, mutation }, done)   -- l'œuf a éclaté : la créature, puis le retour
-- L'œuf du joueur reste dans la base (les autres le voient éclore normalement). Chez lui, une salle noire est
-- construite loin de tout : une copie de l'œuf y attend sous une lampe, HatchFx la charge et la fait éclater, la
-- créature jaillit dans la lumière, puis l'écran repasse au noir et on revient à la base où elle l'attend.
-- Pendant ce temps l'interface est cachée (bandes noires en haut et en bas) et la lumière ambiante est coupée.
-- Purement visuel : rien n'est décidé ici, et un garde-fou ramène toujours le joueur à la base.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Mutation = require(ReplicatedStorage.Shared:WaitForChild("Mutation"))

local C = Config.Hatch.Cinema
local player = Players.LocalPlayer
local STUDS = "rbxassetid://99589690361139" -- picots du jeu
local GLOW = "rbxassetid://103844906730878" -- halo doux (comme HatchFx)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local WARM = Color3.fromRGB(255, 244, 226)
local STEP = "HatchCinema"
-- interfaces qui restent : la nôtre, le compteur de chance de l'œuf, les commandes tactiles de Roblox
local KEEP = { HatchCinema = true, HatchLuck = true, TouchGui = true }

local Cinema = {}

type State = {
	phase: string, -- « charge » puis « reveal »
	inside: boolean, -- la caméra est dans la salle
	leaving: boolean,
	t0: number,
	t1: number,
	dur: number,
	at: Vector3, -- centre du sol de la salle
	focus: Vector3,
	eggH: number,
	petH: number,
	dist: number,
	ang: number,
	folder: Folder,
	egg: Model,
	pedestal: BasePart?,
	lamp: SpotLight,
	shaft: Beam,
	pet: Model?,
	petBase: Vector3,
	petScale: number,
	petDone: boolean,
	hidden: { ScreenGui },
	fov0: number,
	ambient0: Color3,
}

local state: State? = nil

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local function studs(p: BasePart, face: Enum.NormalId, tile: number)
	local t = Instance.new("Texture")
	t.Name = "Studs"
	t.Texture = STUDS
	t.Face = face
	t.StudsPerTileU = tile
	t.StudsPerTileV = tile
	t.Transparency = 0.35
	t.Parent = p
end

-- ÉCRAN : fondu au noir et bandes de cinéma ---------------------------------------------------

local gui: ScreenGui? = nil
local shade: Frame
local top: Frame
local bottom: Frame

local function ensureGui(): ScreenGui
	if gui then
		return gui
	end
	local g = Instance.new("ScreenGui")
	g.Name = "HatchCinema"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 40
	g.Enabled = false
	local function bar(anchorY: number, y: number): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0, anchorY)
		f.Position = UDim2.fromScale(0, y)
		f.Size = UDim2.fromScale(1, C.Bars)
		f.BackgroundColor3 = BLACK
		f.BorderSizePixel = 0
		f.Parent = g
		return f
	end
	top = bar(1, 0)
	bottom = bar(0, 1)
	shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = BLACK
	shade.BackgroundTransparency = 1
	shade.BorderSizePixel = 0
	shade.ZIndex = 2
	shade.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	return g
end

local function bars(on: boolean, time: number)
	tween(top, time, { Position = UDim2.fromScale(0, if on then C.Bars else 0) })
	tween(bottom, time, { Position = UDim2.fromScale(0, if on then 1 - C.Bars else 1) })
end

-- LA SALLE NOIRE ----------------------------------------------------------------------------

local function buildRoom(at: Vector3, h: number): (Folder, BasePart, SpotLight, Beam)
	local side, high = C.Room[1], C.Room[2]
	local folder = Instance.new("Folder")
	folder.Name = "HatchCinema"
	-- sol sombre à picots : la lampe y dessine un rond de lumière
	local floor = part({
		Name = "Floor",
		Size = Vector3.new(side, 6, side),
		CFrame = CFrame.new(at - Vector3.new(0, 3, 0)),
		Color = C.Floor,
		Parent = folder,
	})
	studs(floor, Enum.NormalId.Top, 4)
	-- murs et plafond noirs, épais pour arrêter le soleil : on ne voit que ce que la lampe éclaire
	local t = 10
	for _, w in ipairs({
		{ Vector3.new(side + t * 2, high, t), Vector3.new(0, high / 2, side / 2 + t / 2) },
		{ Vector3.new(side + t * 2, high, t), Vector3.new(0, high / 2, -side / 2 - t / 2) },
		{ Vector3.new(t, high, side), Vector3.new(side / 2 + t / 2, high / 2, 0) },
		{ Vector3.new(t, high, side), Vector3.new(-side / 2 - t / 2, high / 2, 0) },
		{ Vector3.new(side + t * 2, t, side + t * 2), Vector3.new(0, high + t / 2, 0) },
	}) do
		part({ Name = "Wall", Size = w[1], CFrame = CFrame.new(at + w[2]), Color = BLACK, Parent = folder })
	end
	-- petit socle rond sous l'œuf
	local pedestal = part({
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, h * 1.5, h * 1.5),
		CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Floor:Lerp(WHITE, 0.12),
		Parent = folder,
	})
	studs(pedestal, Enum.NormalId.Right, 2)
	-- la lampe, son faisceau et quelques poussières qui passent dedans
	local head = part({
		Name = "Lamp",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CastShadow = false,
		CFrame = CFrame.new(at + Vector3.new(0, C.Lamp.Height, 0)),
		Parent = folder,
	})
	local lamp = Instance.new("SpotLight")
	lamp.Face = Enum.NormalId.Bottom
	lamp.Angle = C.Lamp.Angle
	lamp.Range = 60
	lamp.Brightness = C.Lamp.Brightness
	lamp.Color = WARM
	lamp.Shadows = true
	lamp.Parent = head
	local a0 = Instance.new("Attachment")
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 3, 0)
	a1.Parent = floor
	local shaft = Instance.new("Beam")
	shaft.Attachment0 = a0
	shaft.Attachment1 = a1
	shaft.Width0 = 3
	shaft.Width1 = 2 * C.Lamp.Height * math.tan(math.rad(C.Lamp.Angle / 2)) * 0.8
	shaft.FaceCamera = true
	shaft.Segments = 1
	shaft.Color = ColorSequence.new(WARM)
	shaft.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.86),
		NumberSequenceKeypoint.new(0.7, 0.94),
		NumberSequenceKeypoint.new(1, 1),
	})
	shaft.LightEmission = 1
	shaft.LightInfluence = 0
	shaft.Parent = head
	local dust = part({
		Name = "Dust",
		Size = Vector3.new(h * 4, C.Lamp.Height * 0.6, h * 4),
		Transparency = 1,
		CastShadow = false,
		CFrame = CFrame.new(at + Vector3.new(0, C.Lamp.Height * 0.32, 0)),
		Parent = folder,
	})
	local e = Instance.new("ParticleEmitter")
	e.Texture = GLOW
	e.Rate = 10
	e.Lifetime = NumberRange.new(4, 7)
	e.Speed = NumberRange.new(0.2, 0.6)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.18, 0.28)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.55),
		NumberSequenceKeypoint.new(0.8, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Color = ColorSequence.new(WARM)
	e.LightEmission = 0.6
	e.LightInfluence = 0
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Parent = dust
	return folder, pedestal, lamp, shaft
end

-- copie de l'œuf, sans rien de ce qui le fait vivre dans la base (étiquettes, boutons, pancartes)
local function copyEgg(egg: Model): Model
	local c = egg:Clone()
	for _, tag in ipairs(c:GetTags()) do
		c:RemoveTag(tag)
	end
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("LuaSourceContainer") or d:IsA("Highlight") then
			d:Destroy()
		else
			for _, tag in ipairs(d:GetTags()) do
				d:RemoveTag(tag)
			end
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
	end
	return c
end

-- CAMÉRA ------------------------------------------------------------------------------------

local function step(dt: number)
	local s = state
	if not s or not s.inside then
		return
	end
	local now = os.clock()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	if s.phase == "charge" then
		-- elle tourne lentement autour de l'œuf en s'approchant ; son regard le suit quand il s'élève
		local e = smooth((now - s.t0) / s.dur)
		s.ang = C.Arc[1] + (C.Arc[2] - C.Arc[1]) * e
		s.dist = s.eggH * (C.Dist[1] + (C.Dist[2] - C.Dist[1]) * e)
		local y = if s.egg.Parent then s.egg:GetPivot().Position.Y else s.focus.Y
		s.focus = s.focus:Lerp(Vector3.new(s.at.X, y, s.at.Z), math.min(1, dt * 4))
	else
		-- l'éclatement la repousse, puis elle continue de tourner autour de la créature
		local k = math.clamp((now - s.t1) / 0.7, 0, 1)
		local goal = s.petH * C.PetDist
		s.dist += (goal - s.dist) * math.min(1, dt * (2 + 8 * k))
		s.ang = C.Arc[2] + C.Turn * math.clamp((now - s.t1) / C.Reveal, 0, 1)
		s.focus = s.focus:Lerp(s.at + Vector3.new(0, s.petH * 0.5, 0), math.min(1, dt * 5))
		local pet = s.pet
		if pet and pet.Parent then
			-- la créature jaillit à sa taille, face à la caméra, et se balance un peu
			local f = math.clamp((now - s.t1 - C.PopDelay) / C.Pop, 0, 1)
			if f < 1 or not s.petDone then
				local back = 1 + 2.2 * (f - 1) ^ 3 + 1.2 * (f - 1) ^ 2 -- dépasse sa taille puis revient
				f = math.max(0.04, back)
				pet:ScaleTo(s.petScale * f)
				s.petDone = f >= 1 and now - s.t1 - C.PopDelay >= C.Pop
			else
				f = 1
			end
			local yaw = -s.ang + math.sin((now - s.t1) * 1.5) * 0.18
			pet:PivotTo(CFrame.new(s.at) * CFrame.Angles(0, yaw, 0) * CFrame.new(-s.petBase * f))
		end
	end
	local eye = s.focus + Vector3.new(math.sin(s.ang) * s.dist, s.dist * C.Tilt, -math.cos(s.ang) * s.dist)
	eye = Vector3.new(eye.X, math.max(eye.Y, s.at.Y + 1.5), eye.Z)
	cam.CFrame = CFrame.lookAt(eye, s.focus)
	cam.Focus = CFrame.new(s.focus)
end

-- ENTRÉE ET SORTIE --------------------------------------------------------------------------

local function enter(s: State)
	s.inside = true
	-- l'interface du jeu disparaît le temps de la scène
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if pg then
		for _, g in ipairs(pg:GetChildren()) do
			if g:IsA("ScreenGui") and g.Enabled and not KEEP[g.Name] then
				g.Enabled = false
				table.insert(s.hidden, g)
			end
		end
	end
	s.ambient0 = Lighting.Ambient
	Lighting.Ambient = C.Ambient
	-- entre l'annulation et l'application de la secousse de HatchFx, pour qu'elle joue aussi dans la salle
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value, step)
	step(0)
	bars(true, C.Open)
	tween(shade, C.Open, { BackgroundTransparency = 1 })
end

local function leave(s: State, done: (() -> ())?)
	if s.leaving then
		return
	end
	s.leaving = true
	if s.inside then
		tween(shade, C.FadeOut, { BackgroundTransparency = 0 })
		task.wait(C.FadeOut + 0.03)
	end
	RunService:UnbindFromRenderStep(STEP)
	local cam = workspace.CurrentCamera
	if s.inside then
		Lighting.Ambient = s.ambient0
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
	end
	cam.FieldOfView = s.fov0
	for _, g in ipairs(s.hidden) do
		if g.Parent then
			g.Enabled = true
		end
	end
	s.folder:Destroy()
	player:SetAttribute("HatchCinema", nil)
	state = nil
	bars(false, C.Open)
	tween(shade, C.Open, { BackgroundTransparency = 1 })
	task.delay(C.Open + 0.05, function()
		if not state and gui then
			gui.Enabled = false
		end
	end)
	if done then
		task.spawn(done)
	end
end

function Cinema.Active(): boolean
	return state ~= nil
end

-- Lance la cinématique pour cet œuf, qui éclatera dans dur secondes. Renvoie la copie de l'œuf posée dans la
-- salle noire (c'est elle que HatchFx doit charger), ou nil si une cinématique joue déjà.
function Cinema.Start(egg: Model, dur: number): Model?
	if state or not egg.PrimaryPart then
		return nil
	end
	local cam = workspace.CurrentCamera
	local at = Vector3.new(C.At[1], C.At[2], C.At[3])
	local h = (egg:GetAttribute("BodyHeight") or 3) :: number
	local grow = math.clamp((egg:GetAttribute("HatchGrow") or 1) :: number, 1, C.MaxGrow)
	local folder, pedestal, lamp, shaft = buildRoom(at, h)
	local clone = copyEgg(egg)
	clone:PivotTo(CFrame.new(at + Vector3.new(0, h / 2 + 0.6, 0)) * egg:GetPivot().Rotation)
	clone.Parent = folder
	folder.Parent = workspace
	local s: State = {
		phase = "charge",
		inside = false,
		leaving = false,
		t0 = os.clock(),
		t1 = 0,
		dur = dur,
		at = at,
		focus = at + Vector3.new(0, h / 2 + 0.6, 0),
		eggH = h * grow * 1.14,
		petH = C.PetHeight,
		dist = 0,
		ang = C.Arc[1],
		folder = folder,
		egg = clone,
		pedestal = pedestal,
		lamp = lamp,
		shaft = shaft,
		pet = nil,
		petBase = Vector3.zero,
		petScale = 1,
		petDone = false,
		hidden = {},
		fov0 = cam.FieldOfView,
		ambient0 = Lighting.Ambient,
	}
	state = s
	player:SetAttribute("HatchCinema", true)
	cam.FieldOfView = C.Fov -- HatchFx part de ce champ de vision pour ses effets de zoom
	local g = ensureGui()
	g.Enabled = true
	shade.BackgroundTransparency = 1
	tween(shade, C.FadeIn, { BackgroundTransparency = 0 })
	task.delay(C.FadeIn, function()
		if state == s and not s.leaving then
			enter(s)
		end
	end)
	-- garde-fou : si l'éclatement n'arrive jamais (œuf retiré, déconnexion...), on rentre à la base
	task.delay(dur + 4, function()
		if state == s and s.phase == "charge" then
			leave(s)
		end
	end)
	return clone
end

-- L'œuf vient d'éclater (HatchFx.Burst est lancé par l'appelant) : la créature jaillit sous la lampe, la
-- caméra recule, puis retour à la base ; done est appelé quand l'image revient (la bannière peut s'afficher).
function Cinema.Reveal(info: { ring: number, rarity: number, size: number?, mutation: string? }, done: () -> ())
	local s = state
	if not s or s.phase ~= "charge" or s.leaving then
		task.spawn(done)
		return
	end
	s.phase = "reveal"
	s.t1 = os.clock()
	if s.egg.Parent then
		s.egg:Destroy()
	end
	if s.pedestal then
		s.pedestal:Destroy()
		s.pedestal = nil
	end
	local rarity = Config.Rarities[info.rarity]
	local mut = Config.Mutation(info.mutation)
	local col: Color3 = if mut then mut.Color elseif rarity then rarity.Color else WHITE
	-- une Big ou une Large se voit un peu : la créature montrée est plus haute
	s.petH = C.PetHeight * (1 + math.clamp((info.size or 1) - 1, 0, 2) * 0.14)
	local creatures = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Creatures")
	local template = creatures and creatures:FindFirstChild(("R%d_T%d"):format(info.ring, info.rarity))
	if template and template:IsA("Model") then
		local c = template:Clone()
		for _, tag in ipairs(c:GetTags()) do
			c:RemoveTag(tag)
		end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		Mutation.Apply(c, info.mutation)
		c:PivotTo(CFrame.new())
		local _, size = c:GetBoundingBox()
		c:ScaleTo(c:GetScale() * s.petH / math.max(0.1, size.Y))
		local cf, full = c:GetBoundingBox()
		s.petBase = Vector3.new(cf.X, cf.Y - full.Y / 2, cf.Z)
		s.petScale = c:GetScale()
		c:ScaleTo(s.petScale * 0.04)
		c:PivotTo(CFrame.new(s.at))
		c.Parent = s.folder
		s.pet = c
	end
	-- la lampe s'ouvre et prend un peu de la couleur de la créature ; une lumière derrière elle détache sa silhouette
	tween(s.lamp, 0.5, { Brightness = C.Lamp.Reveal, Color = WARM:Lerp(col, 0.3), Angle = math.min(90, C.Lamp.Angle + 14) })
	s.shaft.Color = ColorSequence.new(WARM:Lerp(col, 0.4))
	local rim = part({
		Name = "Rim",
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CastShadow = false,
		CFrame = CFrame.new(s.at + Vector3.new(0, s.petH * 0.75, s.petH * 0.95)),
		Parent = s.folder,
	})
	local back = Instance.new("PointLight")
	back.Color = col
	back.Brightness = 0
	back.Range = math.min(60, s.petH * 2.6)
	back.Shadows = false
	back.Parent = rim
	tween(back, 0.6, { Brightness = 2.6 })
	task.delay(C.Reveal, function()
		if state == s then
			leave(s, done)
		end
	end)
end

return Cinema
