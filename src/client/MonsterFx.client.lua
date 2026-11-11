-- Monstres des anneaux 5 à 7, côté joueur (MonsterService décide, ce script montre) :
-- - chaque monstre (dossier dans Workspace.World.Monsters) devient un modèle animé chez ce client,
--   qui glisse vers la position publiée par le serveur, grandit en sortant, plonge en repartant ;
--   au réveil son astéroïde vole en éclats (onde de choc) ; traînée, braises et yeux qui brillent ;
--   il heurte les astéroïdes sur son passage ; arrivé à la base du joueur, un dôme s'allume, il
--   s'y écrase puis rentre à son astéroïde (état Return) ;
-- - pour le joueur poursuivi : bandeau « RUN HOME » et jauge vers sa base, flèche lumineuse jusqu'à
--   sa base, bord rouge et battements de cœur qui montent quand il approche, lignes de vitesse et
--   champ de vision élargi, bonds en claquant des mâchoires quand il est tout près, icône de danger
--   au bord de l'écran de son côté, secousses, sons ; mâchoires qui se ferment s'il attrape ;
-- - astéroïdes gardés (anneaux 6 et 7) : un petit gardien flotte au-dessus, avec une lueur ;
-- - jauge de bruit : alerte quand elle dépasse Config.Monsters.Noise.Warn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local M = Config.Monsters
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local new = UIKit.new
local world = workspace:WaitForChild("World")
local monstersFolder = world:WaitForChild("Monsters", 30)
local beltFolder = world:WaitForChild("Belt")

local function template(ring: number): Model?
	local kind = M.Kinds[ring]
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Monsters")
	return kind and folder and folder:FindFirstChild(kind.Model) :: Model?
end

-- Copie du modèle à la taille voulue (plus grande dimension = size)
local function makeModel(ring: number, size: number): Model?
	local t = template(ring)
	if not t then
		return nil
	end
	local m = t:Clone()
	local _, s = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * size / math.max(s.X, s.Y, s.Z))
	return m
end

-- INTERFACE DE POURSUITE -----------------------------------------------------------------

local gui = new("ScreenGui", { Name = "MonsterHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local vignette = new("ImageLabel", {
	Name = "Vignette",
	Image = Config.Cold.Art.Vignette,
	ImageColor3 = Color3.fromRGB(255, 40, 40),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ImageTransparency = 1,
	Parent = gui,
})
local banner = new("Frame", {
	Name = "Banner",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -64), -- en bas, au-dessus de la ligne d'aide (en haut : soute et notifications)
	Size = UDim2.fromOffset(420, 66),
	BackgroundColor3 = Color3.fromRGB(40, 16, 24),
	Parent = gui,
}, { UIKit.corner(), UIKit.stroke(4) })
local title = UIKit.text({ Text = "{Warning} RUN HOME!", Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 5), TextColor3 = Color3.fromRGB(255, 90, 90), Parent = banner })
local barBack = new("Frame", { Size = UDim2.new(1, -40, 0, 14), Position = UDim2.fromOffset(20, 44), BackgroundColor3 = Color3.fromRGB(20, 10, 14), Parent = banner }, { UIKit.corner(), UIKit.stroke(2) })
-- jauge : le chemin déjà fait vers sa base
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(110, 240, 120), Parent = barBack }, { UIKit.corner() })
UIKit.studs(banner, 0.85).ZIndex = 0

-- éclair de la couleur du monstre à son réveil
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8, Parent = gui })

-- lignes de vitesse : elles filent vers les bords quand il se rapproche
local lines = new("Frame", { Name = "SpeedLines", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
type Line = { frame: Frame, angle: number, phase: number, speed: number }
local speedLines: { Line } = {}
for i = 1, 22 do
	local angle = (i / 22) * math.pi * 2 + math.random() * 0.2
	table.insert(speedLines, {
		frame = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(150, 4),
			Rotation = math.deg(angle),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = lines,
		}, { UIKit.corner(2) }),
		angle = angle,
		phase = math.random(),
		speed = 1.4 + math.random() * 1.2,
	})
end

-- mâchoires qui se referment sur l'écran quand il attrape
local JAW = Color3.fromRGB(28, 10, 16)
local TOOTH = Color3.fromRGB(246, 240, 222)
local function jaw(top: boolean): Frame
	local f = new("Frame", {
		Name = if top then "JawTop" else "JawBottom",
		AnchorPoint = Vector2.new(0.5, if top then 1 else 0),
		Position = UDim2.fromScale(0.5, if top then 0 else 1),
		Size = UDim2.fromScale(1.2, 0.56),
		BackgroundColor3 = JAW,
		BorderSizePixel = 0,
		ZIndex = 20,
		Visible = false,
		Parent = gui,
	})
	for i = 0, 13 do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale((i + (if top then 0 else 0.5)) / 13, if top then 1 else 0),
			Size = UDim2.fromOffset(62, 62),
			Rotation = 45,
			BackgroundColor3 = TOOTH,
			ZIndex = 19,
			Parent = f,
		}, { UIKit.stroke(3) })
	end
	return f
end
local jawTop, jawBottom = jaw(true), jaw(false)

local function bite()
	jawTop.Position = UDim2.fromScale(0.5, 0)
	jawBottom.Position = UDim2.fromScale(0.5, 1)
	jawTop.Visible, jawBottom.Visible = true, true
	local close = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(jawTop, close, { Position = UDim2.fromScale(0.5, 0.52) }):Play()
	TweenService:Create(jawBottom, close, { Position = UDim2.fromScale(0.5, 0.48) }):Play()
	-- le joueur est ramené à sa base pendant que la bouche est fermée
	task.delay(0.95, function()
		local open = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(jawTop, open, { Position = UDim2.fromScale(0.5, 0) }):Play()
		TweenService:Create(jawBottom, open, { Position = UDim2.fromScale(0.5, 1) }):Play()
		task.wait(0.45)
		jawTop.Visible, jawBottom.Visible = false, false
	end)
end

-- flèche lumineuse dans le monde, du joueur jusqu'à sa base
local homeFrom = Instance.new("Attachment")
homeFrom.Name = "MonsterHomeFrom"
local homeTo = Instance.new("Attachment")
homeTo.Name = "MonsterHomeTo"
homeTo.Parent = workspace.Terrain
local homeBeam = new("Beam", {
	Name = "MonsterHomeArrow",
	Attachment0 = homeFrom,
	Attachment1 = homeTo,
	Texture = Config.Guide.Arrow,
	TextureMode = Enum.TextureMode.Static,
	TextureLength = 3,
	TextureSpeed = 2.4,
	Width0 = 2.6,
	Width1 = 2.6,
	FaceCamera = true,
	LightEmission = 0.4,
	LightInfluence = 0,
	Color = ColorSequence.new(Color3.fromRGB(120, 255, 140)),
	Enabled = false,
	Parent = workspace.Terrain,
})

-- Le sol de la base d'un joueur (Ship.Bases : attribut Index = attribut Base du joueur)
local function baseFloor(userId: number): BasePart?
	local p = Players:GetPlayerByUserId(userId)
	local index = p and p:GetAttribute("Base")
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

-- EFFETS DANS LE MONDE -----------------------------------------------------------------------

local function piece(size: number, color: Color3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Size = Vector3.one * size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cf
	p.Parent = workspace
	return p
end

local function randomUnit(): Vector3
	local v = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
	return if v.Magnitude > 0.01 then v.Unit else Vector3.yAxis
end

-- Éclats de roche qui volent dans tous les sens
local function debris(at: Vector3, color: Color3, count: number, reach: number)
	for _ = 1, count do
		local p = piece(0.6 + math.random() * 1.6, color:Lerp(Color3.new(0, 0, 0), math.random() * 0.3), CFrame.new(at) * CFrame.Angles(math.random() * 6, math.random() * 6, 0))
		local to = at + randomUnit() * reach * (0.5 + math.random() * 0.7)
		TweenService:Create(p, TweenInfo.new(0.8 + math.random() * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(to) * CFrame.Angles(math.random() * 6, math.random() * 6, 0),
			Size = Vector3.one * 0.1,
		}):Play()
		Debris:AddItem(p, 1.3)
	end
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = workspace.Terrain
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = UIKit.Art.FxGlow
	dust.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3))
	dust.Transparency = NumberSequence.new(0.35, 1)
	dust.Size = NumberSequence.new(reach * 0.25, reach * 0.6)
	dust.Lifetime = NumberRange.new(0.6, 1)
	dust.Speed = NumberRange.new(reach * 0.4, reach * 0.9)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.LightInfluence = 0.3
	dust.Enabled = false
	dust.Parent = a
	dust:Emit(14)
	Debris:AddItem(a, 1.5)
end

-- Onde de choc : une bulle qui gonfle et s'efface
local function shockwave(at: Vector3, color: Color3, size: number)
	local p = piece(2, color, CFrame.new(at))
	p.Shape = Enum.PartType.Ball
	p.Transparency = 0.45
	TweenService:Create(p, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.one * size, Transparency = 1 }):Play()
	Debris:AddItem(p, 0.7)
end

local STUDS = "rbxassetid://99589690361139"

-- Dôme de protection sur la base du joueur : le monstre s'y écrase
local function dome(floor: BasePart, color: Color3)
	local top = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
	local full = math.max(floor.Size.X, floor.Size.Z) * 1.35
	local d = piece(2, color, top)
	d.Shape = Enum.PartType.Ball
	d.Transparency = 0.55
	local textures = {}
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local t = Instance.new("Texture")
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = 6
		t.StudsPerTileV = 6
		t.Transparency = 0.4
		t.Parent = d
		table.insert(textures, t)
	end
	TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.one * full }):Play()
	shockwave(top.Position, color, full * 1.5)
	Sfx.Play("Thaw", { at = top.Position, pitch = 0.6, volume = 3 })
	task.delay(1.1, function()
		local fade = TweenInfo.new(1.2)
		TweenService:Create(d, fade, { Transparency = 1 }):Play()
		for _, t in ipairs(textures) do
			TweenService:Create(t, fade, { Transparency = 1 }):Play()
		end
	end)
	Debris:AddItem(d, 2.6)
end

-- Couleur de l'astéroïde le plus proche (pour ses éclats)
local function rockColorNear(ring: number, at: Vector3): Color3
	local folder = beltFolder:FindFirstChild("Ring" .. ring)
	local best, bestDist = nil, 80
	if folder then
		for _, p in ipairs(folder:GetDescendants()) do
			if p:IsA("BasePart") and p.Name == "Asteroid" then
				local dist = (p.Position - at).Magnitude
				if dist < bestDist then
					best, bestDist = p, dist
				end
			end
		end
	end
	return if best then best.Color else Color3.fromRGB(150, 128, 110)
end
local arrow = new("ImageLabel", {
	Name = "Arrow",
	Image = UIKit.Art.Warning, -- icône de danger au bord de l'écran, du côté du monstre
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(76, 76),
	Visible = false,
	Parent = gui,
})

-- MONSTRES ---------------------------------------------------------------------------------

type View = {
	folder: Instance,
	model: Model?,
	ring: number,
	size: number,
	shown: Vector3,
	look: Vector3,
	born: number,
	state: string,
	growl: Sfx.Loop?,
	light: PointLight?,
	mine: boolean,
	leftAt: number?,
	eyes: { Attachment }?,
	lungeAt: number?,
	startDist: number?,
	nextRocks: number?,
}
local views: { [Instance]: View } = {}

local function shake(amount: number, duration: number)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration do
			local k = 1 - (os.clock() - t0) / duration
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * amount * k, (math.random() - 0.5) * amount * k, 0)
			RunService.RenderStepped:Wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local onState: (Instance) -> ()
local fovPunch = 0 -- coup de zoom au réveil

local function addView(f: Instance)
	if views[f] then
		return
	end
	local ring = (f:GetAttribute("Kind") or 5) :: number
	local size = (f:GetAttribute("Size") or 24) :: number
	local pos = (f:GetAttribute("Pos") or Vector3.zero) :: Vector3
	local kind = M.Kinds[ring]
	local v: View = {
		folder = f,
		ring = ring,
		size = size,
		shown = pos,
		look = (f:GetAttribute("Look") or Vector3.zAxis) :: Vector3,
		born = os.clock(),
		state = (f:GetAttribute("State") or "Emerge") :: string,
		mine = f:GetAttribute("Target") == player.UserId,
	}
	local m = makeModel(ring, size)
	if m then
		m.Name = "MonsterView"
		local body = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if body and kind then
			local light = Instance.new("PointLight")
			light.Color = kind.Color
			light.Range = size * 1.4
			light.Brightness = 2
			light.Shadows = false
			light.Parent = body
			v.light = light
			-- le joueur poursuivi le voit à travers les roches (contour de sa couleur)
			if v.mine then
				local hl = Instance.new("Highlight")
				hl.FillTransparency = 1
				hl.OutlineColor = kind.Color
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = m
			end
			v.growl = Sfx.Loop("MonsterGrowl", body)
			-- traînée lumineuse et braises de sa couleur
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, size * 0.2, 0)
			a0.Parent = body
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, -size * 0.2, 0)
			a1.Parent = body
			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Color = ColorSequence.new(kind.Color, Color3.new(1, 1, 1))
			trail.Transparency = NumberSequence.new(0.35, 1)
			trail.Lifetime = 0.55
			trail.LightEmission = 1
			trail.LightInfluence = 0
			trail.FaceCamera = true
			trail.Parent = body
			local embers = Instance.new("ParticleEmitter")
			embers.Texture = UIKit.Art.FxSparkle
			embers.Color = ColorSequence.new(kind.Color, Color3.new(1, 1, 1))
			embers.Size = NumberSequence.new(size * 0.06, 0)
			embers.Lifetime = NumberRange.new(0.5, 1)
			embers.Speed = NumberRange.new(3, 9)
			embers.SpreadAngle = Vector2.new(180, 180)
			embers.Rate = 28
			embers.LightEmission = 1
			embers.LightInfluence = 0
			embers.Parent = body
			-- deux yeux qui brillent, placés devant lui à chaque image
			local eyes = {}
			for _ = 1, 2 do
				local e = Instance.new("Attachment")
				e.Parent = workspace.Terrain
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.fromScale(size * 0.16, size * 0.16)
				bb.LightInfluence = 0
				bb.Adornee = e
				bb.Parent = e
				local glow = Instance.new("ImageLabel")
				glow.BackgroundTransparency = 1
				glow.Size = UDim2.fromScale(1, 1)
				glow.Image = UIKit.Art.FxGlow
				glow.ImageColor3 = kind.Color:Lerp(Color3.new(1, 1, 1), 0.35)
				glow.Parent = bb
				table.insert(eyes, e)
			end
			v.eyes = eyes
		end
		m.Parent = workspace
		v.model = m
	end
	views[f] = v
	-- réveil : son astéroïde vole en éclats, onde de choc de sa couleur
	if (pos - camera.CFrame.Position).Magnitude < 600 and kind then
		debris(pos, rockColorNear(ring, pos), 26, size * 1.3)
		shockwave(pos, kind.Color, size * 2.6)
	end
	f.AttributeChanged:Connect(function(name)
		if name == "State" then
			onState(f)
		end
	end)
	-- réveil : rugissement, éclats de roche, secousse
	Sfx.Play("MonsterRoar", { at = pos, pitch = if ring == 6 then 1.25 elseif ring == 7 then 0.9 else 1 })
	if v.mine then
		Sfx.Play("Warning")
		shake(0.9, 0.8)
		gui.Enabled = true
		banner.Visible = true
		if kind then
			flash.BackgroundColor3 = kind.Color
			flash.BackgroundTransparency = 0.6
			TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		end
		fovPunch = os.clock()
	end
end

local function removeView(f: Instance)
	local v = views[f]
	if not v then
		return
	end
	views[f] = nil
	if v.growl then
		v.growl:Destroy()
	end
	if v.model then
		v.model:Destroy()
	end
	for _, e in ipairs(v.eyes or {}) do
		e:Destroy()
	end
	if v.mine then
		gui.Enabled = false
		arrow.Visible = false
		homeBeam.Enabled = false
	end
end

function onState(f: Instance)
	local v = views[f]
	if not v then
		return
	end
	local state = (f:GetAttribute("State") or "") :: string
	if state == v.state then
		return
	end
	v.state = state
	if state == "Caught" then
		v.leftAt = os.clock()
		if v.mine then
			Sfx.Play("MonsterCatch")
			Sfx.Play("MonsterRoar", { pitch = 1.1 })
			shake(1.2, 0.7)
			-- les mâchoires se referment sur l'écran
			gui.Enabled = true
			banner.Visible = false
			arrow.Visible = false
			homeBeam.Enabled = false
			vignette.ImageTransparency = 1
			bite()
		end
	elseif state == "Return" then
		-- le joueur est chez lui : dôme sur sa base, le monstre s'y écrase et rugit de rage
		local floor = baseFloor((f:GetAttribute("Target") or 0) :: number)
		if floor then
			local trim = floor.Parent and floor.Parent:GetAttribute("TrimColor")
			dome(floor, if typeof(trim) == "Color3" then trim else Color3.fromRGB(110, 210, 255))
		end
		Sfx.Play("MonsterRoar", { at = v.shown, pitch = 0.75 })
		if v.mine then
			Sfx.Play("Escape")
			shake(0.8, 0.5)
			gui.Enabled = false
			arrow.Visible = false
			homeBeam.Enabled = false
		end
	elseif state == "Leave" then
		v.leftAt = os.clock()
		if v.mine then
			gui.Enabled = false
			arrow.Visible = false
			homeBeam.Enabled = false
		end
	end
end

if monstersFolder then
	for _, f in ipairs(monstersFolder:GetChildren()) do
		addView(f)
	end
	monstersFolder.ChildAdded:Connect(function(f)
		task.wait() -- on laisse arriver tous les attributs
		addView(f)
	end)
	monstersFolder.ChildRemoved:Connect(removeView)
end

-- GARDIENS DES ASTÉROÏDES (anneaux 6 et 7) ------------------------------------------------

type Guard = { model: Model, rock: BasePart, light: PointLight, phase: number }
local guards: { [BasePart]: Guard } = {}

local function scanGuards()
	for _, d in ipairs(beltFolder:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Asteroid" and d:GetAttribute("Guarded") and not guards[d] then
			local ring = (d:GetAttribute("Ring") or 6) :: number
			local m = makeModel(ring, 9)
			if m then
				m.Name = "GuardView"
				local light = Instance.new("PointLight")
				light.Color = M.Kinds[ring] and M.Kinds[ring].Color or Color3.new(1, 1, 1)
				light.Range = 24
				light.Brightness = 2.5
				light.Shadows = false
				light.Parent = d
				m.Parent = workspace
				guards[d] = { model = m, rock = d, light = light, phase = math.random() * 6 }
			end
		end
	end
	for rock, g in pairs(guards) do
		if not rock:IsDescendantOf(workspace) or not rock:GetAttribute("Guarded") then
			g.model:Destroy()
			g.light:Destroy()
			guards[rock] = nil
		end
	end
end
task.spawn(function()
	while true do
		scanGuards()
		task.wait(0.5)
	end
end)

-- BRUIT --------------------------------------------------------------------------------------

local warned = false
player:GetAttributeChangedSignal("Noise"):Connect(function()
	local n = player:GetAttribute("Noise")
	if type(n) ~= "number" then
		warned = false
		return
	end
	if n >= M.Noise.Warn and not warned and not player:GetAttribute("Chased") then
		warned = true
		Sfx.Play("MonsterWarn")
		UIKit.toast("{Warning} Too loud! Something is waking up... glide to stay quiet", "warn")
		shake(0.3, 0.8)
	elseif n < M.Noise.Warn * 0.6 then
		warned = false
	end
end)

-- IMAGE PAR IMAGE ----------------------------------------------------------------------------

local fovBase: number? = nil -- champ de vision avant la poursuite (rendu à la fin)
local nearShown = 0 -- proximité du monstre, lissée (lignes de vitesse, champ de vision, cœur)
local hitRocks: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camPos = camera.CFrame.Position
	local chased = false
	local nearNow = 0

	for f, v in pairs(views) do
		local target = (f:GetAttribute("Pos") or v.shown) :: Vector3
		local look = (f:GetAttribute("Look") or v.look) :: Vector3
		v.shown = v.shown:Lerp(target, 1 - math.exp(-10 * dt))
		if look.Magnitude > 0.01 then
			v.look = v.look:Lerp(look.Unit, 1 - math.exp(-6 * dt))
		end
		local m = v.model
		-- bond en claquant des mâchoires quand il est tout près du joueur poursuivi
		local lunge = 0
		if v.lungeAt then
			lunge = math.sin(math.pi * math.clamp((os.clock() - v.lungeAt) / 0.45, 0, 1))
		end
		if m then
			local age = os.clock() - v.born
			-- taille : il grandit en sortant, rapetisse en repartant
			local k = math.clamp(age / M.Emerge, 0, 1)
			local grow = 0.25 + 0.75 * (1 - (1 - k) ^ 3)
			if v.leftAt then
				grow *= math.clamp(1 - (os.clock() - v.leftAt) / 2.2, 0, 1)
			end
			-- mouvements propres à chaque monstre
			local t = os.clock()
			local wobble: CFrame
			if v.ring == 5 then
				wobble = CFrame.Angles(math.sin(t * 5) * 0.12, math.sin(t * 3) * 0.25, math.sin(t * 4) * 0.15)
			elseif v.ring == 6 then
				wobble = CFrame.new(0, math.sin(t * 2) * 1.2, 0) * CFrame.Angles(0, 0, math.sin(t * 1.5) * 0.1)
			else
				wobble = CFrame.new(0, math.sin(t * 9) * 0.5, 0) * CFrame.Angles(math.sin(t * 2) * 0.08, 0, math.sin(t * 2.5) * 0.12)
			end
			local dir = Vector3.new(v.look.X, v.look.Y * 0.5, v.look.Z)
			if dir.Magnitude < 0.01 then
				dir = Vector3.zAxis
			end
			local at = v.shown
			if lunge > 0 and root then
				local toward = root.Position - v.shown
				if toward.Magnitude > 0.01 then
					at += toward.Unit * v.size * 0.35 * lunge
				end
			end
			local pivot = CFrame.lookAt(at, at + dir) * wobble
			m:PivotTo(pivot)
			-- les yeux, devant lui
			if v.eyes then
				local s2 = v.size * grow
				v.eyes[1].WorldPosition = (pivot * CFrame.new(-s2 * 0.12, s2 * 0.14, -s2 * 0.42)).Position
				v.eyes[2].WorldPosition = (pivot * CFrame.new(s2 * 0.12, s2 * 0.14, -s2 * 0.42)).Position
			end
			local _, s = m:GetBoundingBox()
			local cur = math.max(s.X, s.Y, s.Z)
			local want = math.max(0.5, v.size * grow * (1 + 0.18 * lunge))
			if math.abs(cur - want) > 0.05 then
				m:ScaleTo(m:GetScale() * want / cur)
			end
			if v.growl then
				v.growl:Set(if v.state == "Chase" or v.state == "Emerge" then 1 elseif v.state == "Return" then 0.6 else 0)
			end
			-- il heurte les astéroïdes sur son passage (éclats et poussière, la roche ne bouge pas)
			if (v.state == "Chase" or v.state == "Return") and os.clock() >= (v.nextRocks or 0) then
				v.nextRocks = os.clock() + 0.15
				local folder = beltFolder:FindFirstChild("Ring" .. v.ring)
				if folder and (v.shown - camPos).Magnitude < 500 then
					for _, p in ipairs(folder:GetDescendants()) do
						if p:IsA("BasePart") and p.Name == "Asteroid" and os.clock() - (hitRocks[p] or 0) > 1.2 then
							local gap = (p.Position - v.shown).Magnitude
							if gap < v.size * 0.5 + p.Size.X * 0.5 then
								hitRocks[p] = os.clock()
								local contact = p.Position + (v.shown - p.Position).Unit * p.Size.X * 0.5
								debris(contact, p.Color, 10, p.Size.X * 0.8)
								Sfx.Play("RockHit", { at = contact, volume = 0.8, pitch = 0.8 })
							end
						end
					end
				end
			end
		end

		-- interface du joueur poursuivi
		if v.mine and root and (v.state == "Emerge" or v.state == "Chase") then
			chased = true
			local name = M.Kinds[v.ring] and string.upper(M.Kinds[v.ring].Name) or "MONSTER"
			UIKit.setIconText(title, ("{Warning} %s! RUN HOME"):format(name))
			-- jauge et flèche lumineuse : le chemin jusqu'à sa base
			local floor = baseFloor(player.UserId)
			if floor then
				local goal = floor.Position + Vector3.new(0, floor.Size.Y / 2 + 3, 0)
				local toHome = (goal - root.Position).Magnitude
				v.startDist = math.max(v.startDist or 0, toHome)
				barFill.Size = UDim2.fromScale(math.clamp(1 - toHome / math.max(1, v.startDist :: number), 0.02, 1), 1)
				homeTo.WorldPosition = goal
				if homeFrom.Parent ~= root then
					homeFrom.Parent = root
				end
				homeBeam.Enabled = true
			end
			-- bord rouge : plus il est près, plus ça bat fort
			local dist = (v.shown - root.Position).Magnitude
			local near = math.clamp(1 - (dist - v.size / 2) / 80, 0, 1)
			nearNow = math.max(nearNow, near)
			if v.state == "Chase" and dist - v.size / 2 < M.LungeDistance and os.clock() - (v.lungeAt or 0) > 2.4 then
				v.lungeAt = os.clock()
				Sfx.Play("MonsterRoar", { at = v.shown, pitch = 1.3, volume = 0.7 })
				task.delay(0.3, function()
					Sfx.Play("Clamp", { volume = 4, pitch = 0.7 })
					shake(0.9, 0.35)
				end)
			end
			vignette.ImageColor3 = Color3.fromRGB(255, 40, 40)
			vignette.ImageTransparency = 1 - near * (0.55 + 0.25 * math.sin(os.clock() * (6 + 8 * near)))
			if near > 0.6 and math.random() < dt * 4 then
				shake(0.25 * near, 0.2)
			end
			-- flèche vers le monstre quand il est hors de l'écran
			local sp, onScreen = camera:WorldToViewportPoint(v.shown)
			if onScreen and sp.Z > 0 then
				arrow.Visible = false
			else
				local vp = camera.ViewportSize
				local center = vp / 2
				local d2 = Vector2.new(sp.X, sp.Y) - center
				if sp.Z < 0 then
					d2 = -d2
				end
				if d2.Magnitude < 1 then
					d2 = Vector2.new(0, 1)
				end
				local edge = center + d2.Unit * (math.min(vp.X, vp.Y) / 2 - 70)
				arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
				arrow.Visible = true
			end
		end
	end

	-- poursuite : lignes de vitesse, champ de vision élargi, cœur qui bat (Audio.client)
	nearShown += ((if chased then nearNow else 0) - nearShown) * math.min(1, dt * 5)
	player:SetAttribute("MonsterNear", if nearShown > 0.01 then nearShown else nil)
	if not chased then
		homeBeam.Enabled = false
	end
	local punch = math.max(0, 1 - (os.clock() - fovPunch) / 0.7)
	if chased or nearShown > 0.01 or punch > 0 then
		fovBase = fovBase or camera.FieldOfView
		camera.FieldOfView = (fovBase :: number) + 12 * nearShown + 16 * punch
	elseif fovBase then
		camera.FieldOfView = fovBase
		fovBase = nil
	end
	local vp = camera.ViewportSize
	local half = math.min(vp.X, vp.Y) / 2
	for _, l in ipairs(speedLines) do
		local k = (os.clock() * l.speed + l.phase) % 1
		local r = half * (0.45 + 0.8 * k)
		l.frame.Position = UDim2.fromOffset(vp.X / 2 + math.cos(l.angle) * r, vp.Y / 2 + math.sin(l.angle) * r)
		l.frame.BackgroundTransparency = 1 - nearShown * 0.6 * math.sin(math.pi * k)
	end

	-- gardiens : ils flottent au-dessus de leur astéroïde et regardent la caméra
	for rock, g in pairs(guards) do
		local top = rock.Position + Vector3.new(0, rock.Size.Y / 2 + 6 + math.sin(os.clock() * 2 + g.phase) * 0.8, 0)
		g.model:PivotTo(CFrame.lookAt(top, Vector3.new(camPos.X, top.Y, camPos.Z)))
	end
end)
