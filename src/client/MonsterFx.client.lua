-- Monstres de chaque anneau, côté joueur (MonsterService décide, ce script montre) :
-- - un monstre par anneau, toujours là (dossier dans Workspace.World.Monsters) : il se promène dans le
--   couloir de son anneau (State = Patrol : position calculée ici par Config.MonsterPatrol, comme sur
--   le serveur) ; quand un joueur vole un œuf, il rugit (ondes en dents de scie en 4 calques,
--   LayeredFx « Roar ») et fonce sur lui (Chase : position publiée
--   par le serveur), puis retourne se promener (Return). Trop loin de la caméra, il n'est pas affiché ;
-- - traînée, braises et yeux qui brillent ; il heurte les astéroïdes sur son passage ; arrivé à la
--   ligne rouge de la cour, une barrière s'allume en travers de la sortie, il s'y écrase puis repart ;
-- - pour le joueur poursuivi : pas de texte (20 nov. : le bandeau au nom du monstre est retiré), flèche
--   lumineuse jusqu'à la ligne rouge (et un éclat de victoire s'il la passe avec son œuf), bord rouge et battements
--   de cœur qui montent quand il approche, lignes de vitesse et champ de vision élargi, bonds en
--   claquant des mâchoires quand il est tout près, lueur rouge au bord de l'écran de son côté,
--   secousses, sons (deux coups de klaxon d'alarme au départ de la poursuite, chacun avec un éclair rouge,
--   des gyrophares aux coins de l'écran et une lumière rouge sur le joueur) ; mâchoires qui se ferment s'il attrape (avec la morsure dessinée en 4 calques,
--   LayeredFx « Bite », aussi visible dans le monde par les joueurs autour), puis, s'il manquait de Speed, un petit
--   encadré « [jetpack] Need 50K Speed » pendant quelques secondes ;
-- - roche lâchée après une prise (World.LostRocks) : elle flotte en apesanteur à l'endroit exact où le monstre
--   a attrapé le joueur (elle tourne lentement sur elle-même), rayon lumineux jusqu'à elle, contour et compte
--   à rebours pour son propriétaire ; à la fin du temps elle rétrécit et disparaît.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))
local LayeredFx = require(script.Parent:WaitForChild("LayeredFx"))
local MonsterRig = require(script.Parent:WaitForChild("MonsterRig"))
local MonsterPath = require(ReplicatedStorage.Shared:WaitForChild("MonsterPath"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))

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

-- Copie du modèle à la taille voulue : sa plus grande dimension = size x Span (un serpent allongé est bien
-- plus long que large : son Span dépasse 1, voir tools/blender/monster_rig.py)
local function makeModel(ring: number, size: number): Model?
	local t = template(ring)
	if not t then
		return nil
	end
	local m = t:Clone()
	local _, s = m:GetBoundingBox()
	local span = (t:GetAttribute("Span") or 1) :: number
	m:ScaleTo(m:GetScale() * size * span / math.max(s.X, s.Y, s.Z))
	m:SetAttribute("Kind", t.Name) -- la démarche se choisit au nom du modèle (MonsterGaits)
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
-- Petit encadré montré seulement après une prise, si le joueur manquait de Speed : l'icône du
-- jetpack et « Need 50K Speed »
local needPill = new("Frame", {
	Name = "Need",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.7), -- au-dessus de la barre d'objets et de la bulle du guide
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 46),
	BackgroundColor3 = Color3.fromRGB(28, 22, 40),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 21,
	Parent = gui,
}, {
	UIKit.corner(),
	UIKit.stroke(3),
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 16) }),
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
UIKit.autoScale(needPill)
UIKit.icon("Jetpack", { Size = UDim2.fromOffset(36, 36), LayoutOrder = 1, ZIndex = 22, Parent = needPill })
local needText = UIKit.text({
	Text = "",
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromOffset(0, 30),
	TextSize = 26,
	TextScaled = false,
	TextColor3 = Color3.fromRGB(150, 235, 255),
	Stroke = 3,
	LayoutOrder = 2,
	ZIndex = 22,
	Parent = needPill,
})
local needToken = 0
local function showNeed(need: number)
	needToken += 1
	local token = needToken
	needText.Text = ("Need %s Speed"):format(Format.Short(need))
	needPill.Visible = true
	UIKit.popIn(needPill)
	task.delay(4.5, function()
		if needToken == token then
			needPill.Visible = false
		end
	end)
end

-- signaux rouges de l'alarme (29 nov.) : un éclair rouge sur tout l'écran et quatre lueurs de gyrophare aux
-- coins, rallumés à chaque coup de klaxon ; le bord rouge de l'écran et une lumière rouge sur le joueur suivent
local RED = Color3.fromRGB(255, 40, 40)
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = RED, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 8, Parent = gui })
local beacons: { ImageLabel } = {}
for _, corner in ipairs({ Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }) do
	table.insert(beacons, new("ImageLabel", {
		Name = "Beacon",
		Image = UIKit.Art.FxGlow,
		ImageColor3 = RED,
		ImageTransparency = 1,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(corner.X, corner.Y),
		Size = UDim2.fromScale(0.9, 1.4),
		ZIndex = 7,
		Parent = gui,
	}))
end
local alarmAt = 0 -- dernier coup d'alarme : le bord rouge de l'écran bat avec lui

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

local function bite(color: Color3?)
	-- morsure dessinée en 4 calques (crocs qui claquent avec les mâchoires, éclair, entailles d'énergie)
	local c = color or Color3.fromRGB(200, 40, 255)
	local h, s = c:ToHSV()
	LayeredFx.Screen(gui, {
		kind = "Bite",
		colors = { Color3.fromHSV(h, math.max(s, 0.75), 1), Color3.fromHSV(h, s * 0.35, 1) },
		duration = 0.95,
		size = UDim2.fromScale(0.95, 0.95),
		zIndex = 22,
	})
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

-- Morsure dans le monde (effet en 4 calques « Bite », couleur du monstre), face à la caméra
local function worldBite(at: Vector3, color: Color3, size: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = workspace.Terrain
	local h, s = color:ToHSV()
	local fx = LayeredFx.new(a, {
		kind = "Bite",
		size = size * 1.6,
		colors = { Color3.fromHSV(h, math.max(s, 0.75), 1), Color3.fromHSV(h, s * 0.35, 1) },
		lifetime = 0.95,
		zOffset = size * 0.8,
	})
	fx:Emit()
	Debris:AddItem(a, 1.2)
end

-- Rugissement dans le monde (effet en 4 calques « Roar ») : ondes en dents de scie de la couleur du monstre
local function roar(at: Vector3, color: Color3, size: number)
	local a = Instance.new("Attachment")
	a.WorldPosition = at
	a.Parent = workspace.Terrain
	local h, s = color:ToHSV()
	local fx = LayeredFx.new(a, {
		kind = "Roar",
		size = size,
		colors = { Color3.fromHSV(h, math.max(s, 0.75), 1), Color3.fromHSV(h, s * 0.35, 1) },
		lifetime = 0.85,
		zOffset = size * 0.3,
	})
	fx:Emit(math.random(0, 359))
	Debris:AddItem(a, 1.1)
end

local STUDS = "rbxassetid://99589690361139"

-- Barrière de la cour : elle s'allume en travers de la sortie quand un joueur poursuivi passe la ligne rouge,
-- le monstre s'y écrase
local SAFE = Color3.fromRGB(90, 255, 170)
local function gateShield()
	local map = Config.Map
	local width, height = map.CorridorWidth, 46
	local at = CFrame.new(0, height / 2 - 6, map.FrontZ)
	local wall = piece(2, SAFE, at)
	wall.Size = Vector3.new(width, 2, 1.2)
	wall.Transparency = 0.4
	local textures = {}
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local t = Instance.new("Texture")
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = 6
		t.StudsPerTileV = 6
		t.Transparency = 0.4
		t.Parent = wall
		table.insert(textures, t)
	end
	TweenService:Create(wall, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(width, height, 1.2) }):Play()
	shockwave(at.Position, SAFE, width * 0.9)
	Sfx.Play("Thaw", { at = at.Position, pitch = 0.6, volume = 3 })
	task.delay(1.1, function()
		local fade = TweenInfo.new(1.2)
		TweenService:Create(wall, fade, { Transparency = 1 }):Play()
		for _, t in ipairs(textures) do
			TweenService:Create(t, fade, { Transparency = 1 }):Play()
		end
	end)
	Debris:AddItem(wall, 2.6)
end

-- Le joueur poursuivi a passé la ligne : son de réussite ; s'il rapporte un œuf, éclat de victoire à l'écran
-- et autour de lui
local winGui = new("ScreenGui", { Name = "MonsterWin", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
local winFlash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = SAFE, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = winGui })
local function escaped()
	local withEgg = ((player:GetAttribute("Cargo") or 0) :: number) > 0
	Sfx.Play("Escape", { volume = if withEgg then 1.6 else 1 })
	if not withEgg then
		return
	end
	Sfx.Play("HatchRare", { volume = 0.9, pitch = 1.15 })
	local colors = { SAFE, Color3.fromRGB(230, 255, 240) }
	winFlash.BackgroundTransparency = 0.55
	TweenService:Create(winFlash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	LayeredFx.Screen(winGui, { kind = "Celebrate", colors = colors, duration = 0.95, size = UDim2.fromScale(0.95, 0.95), zIndex = 5 })
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local a = Instance.new("Attachment")
		a.Parent = hrp
		LayeredFx.new(a, { kind = "PowerUp", size = 14, colors = colors, lifetime = 0.9, zOffset = 2 }):Emit()
		Debris:AddItem(a, 1.2)
		shockwave(hrp.Position, SAFE, 34)
	end
end

-- Lueur rouge au bord de l'écran, du côté du monstre quand on ne le voit pas (29 nov. : elle remplace le
-- panneau d'avertissement)
local arrow = new("ImageLabel", {
	Name = "MonsterSide",
	Image = UIKit.Art.FxGlow,
	ImageColor3 = RED,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(260, 260),
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
	hl: Highlight?,
	leg: any?, -- étape de sa promenade parmi les astéroïdes (attribut Leg, shared/MonsterPath)
	rig: any?, -- squelette (MonsterRig) : il anime les pièces selon la démarche du monstre
	effort: number?, -- ardeur lissée : 0 en promenade, 1 en poursuite
	far: boolean?,
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

-- Un coup de signal rouge : éclair, gyrophares aux quatre coins, bord de l'écran, lumière rouge sur le joueur
local function redPulse()
	alarmAt = os.clock()
	flash.BackgroundColor3 = RED
	flash.BackgroundTransparency = 0.5
	TweenService:Create(flash, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	for _, b in ipairs(beacons) do
		b.ImageTransparency = 0.1
		b.Size = UDim2.fromScale(0.6, 0.95)
		TweenService:Create(b, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1, Size = UDim2.fromScale(1.1, 1.7) }):Play()
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local light = Instance.new("PointLight")
		light.Name = "AlarmLight"
		light.Color = RED
		light.Range = 30
		light.Brightness = 5
		light.Shadows = false
		light.Parent = hrp
		TweenService:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
		Debris:AddItem(light, 0.45)
	end
end

-- Alarme du joueur pris en chasse : deux coups de klaxon coup sur coup (« Wang ! Wang ! »), à l'écran,
-- chacun avec son signal rouge
local function alarm()
	local A = M.Alarm
	for i = 0, A.Count - 1 do
		task.delay(i * A.Gap, function()
			redPulse()
			local s = Sfx.Play("ChaseAlarm")
			if s then
				-- la note est coupée net, avec un fondu très court pour ne pas claquer
				task.delay(A.Length, function()
					if s.Parent then
						TweenService:Create(s, TweenInfo.new(0.07), { Volume = 0 }):Play()
						Debris:AddItem(s, 0.1)
					end
				end)
			end
		end)
	end
end

-- chargée d'avance (jouée une fois sans volume) : le premier coup de la première poursuite ne doit pas arriver en retard
task.defer(Sfx.Play, "ChaseAlarm", { volume = 0 })

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
		state = (f:GetAttribute("State") or "Patrol") :: string,
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
			-- le joueur poursuivi le voit à travers les roches (contour de sa couleur), le temps de la poursuite
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 1
			hl.OutlineColor = kind.Color
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Enabled = v.mine and v.state == "Chase"
			hl.Parent = m
			v.hl = hl
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
			-- deux yeux qui brillent, placés devant lui à chaque image (sauf les monstres faits au kit,
			-- qui ont leurs propres yeux lumineux : pièce « Glow »)
			local eyes = {}
			for _ = 1, if m:GetAttribute("Rig") or m:FindFirstChild("Glow", true) then 0 else 2 do
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
		if m:GetAttribute("Rig") and m.PrimaryPart then
			v.rig = MonsterRig.new(m, size, M.ChaseAnim)
		end
	end
	views[f] = v
	v.leg = MonsterPath.Decode(f:GetAttribute("Leg"))
	f.AttributeChanged:Connect(function(name)
		if name == "State" then
			onState(f)
		elseif name == "Leg" then
			v.leg = MonsterPath.Decode(f:GetAttribute("Leg"))
		end
	end)
	-- on arrive en pleine poursuite de ce joueur (réapparition, arrivée tardive) : l'interface suit
	if v.mine and v.state == "Chase" then
		gui.Enabled = true
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
	local state = (f:GetAttribute("State") or "Patrol") :: string
	if state == v.state then
		return
	end
	v.state = state
	local kind = M.Kinds[v.ring]
	local wasMine = v.mine
	v.mine = f:GetAttribute("Target") == player.UserId
	if v.hl then
		v.hl.Enabled = v.mine and state == "Chase"
	end
	local near = (v.shown - camera.CFrame.Position).Magnitude < 800
	if state == "Chase" then
		-- un œuf vient d'être volé : il rugit, onde de choc de sa couleur, puis il fonce
		v.startDist = nil
		v.lungeAt = nil
		if near and kind then
			roar(v.shown, kind.Color, v.size * 2.6)
		end
		Sfx.Play("MonsterRoar", { at = v.shown, pitch = math.clamp(1.35 - 0.045 * v.ring, 0.7, 1.3) })
		if v.mine then
			alarm()
			shake(0.9, 0.8)
			gui.Enabled = true
			needPill.Visible = false
			fovPunch = os.clock()
		end
	elseif state == "Return" then
		local reason = f:GetAttribute("Reason")
		-- il attrape : la morsure se voit aussi dans le monde, pour les joueurs autour
		if reason == "caught" and near and kind then
			worldBite(v.shown, kind.Color, v.size)
		end
		if reason == "line" then
			-- le joueur a passé la ligne rouge : la barrière de la cour s'allume, le monstre s'y écrase et rugit
			gateShield()
			Sfx.Play("MonsterRoar", { at = v.shown, pitch = 0.75 })
			if near and kind then
				roar(v.shown, kind.Color, v.size * 2.2) -- rugit de rage contre la barrière
			end
			if wasMine then
				escaped()
				shake(0.6, 0.4)
			end
		elseif reason == "caught" and wasMine then
			Sfx.Play("MonsterCatch")
			Sfx.Play("MonsterRoar", { pitch = 1.1 })
			shake(1.2, 0.7)
			-- les mâchoires se referment sur l'écran
			gui.Enabled = true
			arrow.Visible = false
			homeBeam.Enabled = false
			vignette.ImageTransparency = 1
			bite(kind and kind.Color)
			-- il manquait de Speed pour le semer : on le lui dit, une fois les mâchoires passées
			local need = (kind and kind.Need or 0) :: number
			local slow = ((player:GetAttribute("JetSpeed") or 0) :: number) < need
			if slow then
				task.delay(0.9, showNeed, need)
			end
			task.delay(if slow then 5.6 else 1.6, function()
				for _, other in pairs(views) do
					if other.mine and other.state == "Chase" then
						return
					end
				end
				gui.Enabled = false
			end)
		end
		if wasMine and reason ~= "caught" then
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

-- ROCHES TOMBÉES (après une prise) ---------------------------------------------------------

type LostView = { model: Model, mine: boolean, phase: number, scale: number, label: TextLabel?, from: Attachment?, to: Attachment?, beam: Beam?, sinkAt: number? }
local lostViews: { [Instance]: LostView } = {}
local lostFolder = world:WaitForChild("LostRocks", 30)

local function addLost(m: Instance)
	if not m:IsA("Model") or lostViews[m] then
		return
	end
	local mine = m:GetAttribute("Owner") == player.UserId
	local lv: LostView = { model = m, mine = mine, phase = math.random() * 6, scale = m:GetScale() }
	if mine then
		-- contour visible à travers les roches, compte à rebours au-dessus et rayon jusqu'à elle
		local hl = Instance.new("Highlight")
		hl.FillTransparency = 0.6
		hl.FillColor = Color3.fromRGB(255, 230, 120)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = m
		local body = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
		if body then
			local bb = new("BillboardGui", { Size = UDim2.fromOffset(150, 54), StudsOffsetWorldSpace = Vector3.new(0, ((m:GetAttribute("BodyHeight") or 3) :: number) * 0.8 + 2, 0), LightInfluence = 0, MaxDistance = 2000, Parent = body })
			lv.label = UIKit.text({ Text = "", Size = UDim2.fromScale(1, 1), TextColor3 = Color3.fromRGB(255, 235, 140), Stroke = 3, Parent = bb })
			local to = Instance.new("Attachment")
			to.Parent = body
			local from = Instance.new("Attachment")
			from.Name = "LostRockFrom"
			lv.to, lv.from = to, from
			lv.beam = new("Beam", {
				Attachment0 = from,
				Attachment1 = to,
				Texture = Config.Guide.Arrow,
				TextureMode = Enum.TextureMode.Static,
				TextureLength = 3,
				TextureSpeed = 2.4,
				Width0 = 2.4,
				Width1 = 2.4,
				FaceCamera = true,
				LightEmission = 0.4,
				LightInfluence = 0,
				Color = ColorSequence.new(Color3.fromRGB(255, 225, 110)),
				Parent = workspace.Terrain,
			})
		end
		Sfx.Play("Warning")
	end
	lostViews[m] = lv
end

local function removeLost(m: Instance)
	local lv = lostViews[m]
	if not lv then
		return
	end
	lostViews[m] = nil
	if lv.beam then
		lv.beam:Destroy()
	end
	if lv.from then
		lv.from:Destroy()
	end
end

if lostFolder then
	for _, m in ipairs(lostFolder:GetChildren()) do
		addLost(m)
	end
	lostFolder.ChildAdded:Connect(function(m)
		task.wait() -- on laisse arriver les attributs
		addLost(m)
	end)
	lostFolder.ChildRemoved:Connect(removeLost)
end

local function stepLost()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local t = workspace:GetServerTimeNow()
	for m, lv in pairs(lostViews) do
		local at = m:GetAttribute("From") :: Vector3?
		if at then
			-- en apesanteur là où le monstre a attrapé le joueur : elle monte et descend à peine et tourne
			-- lentement sur elle-même ; à la fin du temps elle rétrécit et s'éteint
			local sink = 0
			if m:GetAttribute("Sinking") then
				lv.sinkAt = lv.sinkAt or os.clock()
				sink = math.clamp((os.clock() - (lv.sinkAt :: number)) / 1.1, 0, 1)
				m:ScaleTo(lv.scale * math.max(0.05, 1 - sink))
			end
			local c = os.clock()
			local bob = math.sin(c * 1.6 + lv.phase) * 0.5 * (1 - sink)
			m:PivotTo(CFrame.new(at + Vector3.new(0, bob, 0)) * CFrame.Angles(c * 0.35 + lv.phase, c * 0.6 + lv.phase, math.sin(c * 0.4 + lv.phase) * 0.3))
		end
		if lv.mine then
			local left = math.max(0, ((m:GetAttribute("ExpiresAt") or t) :: number) - t)
			if lv.label then
				lv.label.Text = ("GRAB IT! %d"):format(math.ceil(left))
				lv.label.TextColor3 = if left < 8 then Color3.fromRGB(255, 110, 110) else Color3.fromRGB(255, 235, 140)
			end
			if lv.from and root and lv.from.Parent ~= root then
				lv.from.Parent = root
			end
			if lv.beam then
				lv.beam.Enabled = root ~= nil and not m:GetAttribute("Sinking")
			end
		end
	end
end

-- IMAGE PAR IMAGE ----------------------------------------------------------------------------

local fovBase: number? = nil -- champ de vision avant la poursuite (rendu à la fin)
local nearShown = 0 -- proximité du monstre, lissée (lignes de vitesse, champ de vision, cœur)
local hitRocks: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any

RunService.RenderStepped:Connect(function(dt)
	stepLost()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camPos = camera.CFrame.Position
	local chased = false
	local nearNow = 0

	for f, v in pairs(views) do
		-- en promenade, la position se calcule ici (même formule que le serveur) ; sinon le serveur la publie
		local target, look
		local hop: number?, squat = nil, 0 -- bond d'un marcheur entre deux astéroïdes (MonsterGaits.Leap)
		if v.state == "Patrol" then
			-- en promenade : il flotte (Float), ou il va d'astéroïde en astéroïde, à pied ou en rampant
			local kind = M.Kinds[v.ring]
			local move = kind and kind.Move or "Float"
			if v.leg and move ~= "Float" then
				local leg, clock = v.leg, workspace:GetServerTimeNow()
				target, look = MonsterPath.At(leg, clock, move, v.size, (kind.Foot or 0.35) * v.size)
				if move == "Walk" then
					-- il bondit vers l'astéroïde suivant, ou il se ramasse juste avant et amortit juste après
					if clock > leg.t1 and clock < leg.t2 then
						hop = (clock - leg.t1) / (leg.t2 - leg.t1)
					elseif clock <= leg.t1 then
						local before = math.clamp(1 - (leg.t1 - clock) / 0.35, 0, 1)
						local after = if leg.a.fixed then 0 else math.clamp(1 - (clock - leg.t0) / 0.3, 0, 1)
						squat = math.max(before, after)
					end
				end
			else
				target, look = Config.MonsterPatrol(v.ring, workspace:GetServerTimeNow())
			end
		else
			target = (f:GetAttribute("Pos") or v.shown) :: Vector3
			look = (f:GetAttribute("Look") or v.look) :: Vector3
		end
		-- trop loin pour être vu : on ne l'affiche pas et on ne l'anime pas
		local far = not v.mine and (target - camPos).Magnitude > 1600
		if far then
			v.shown = target
			if v.model and v.model.Parent then
				v.model.Parent = nil
			end
			v.far = true
			continue
		elseif v.far then
			v.far = false
			v.shown = target
			if v.model then
				v.model.Parent = workspace
			end
			if v.rig then
				v.rig:Reset()
			end
		end
		v.shown = v.shown:Lerp(target, 1 - math.exp(-10 * dt))
		if root and not player:GetAttribute("MonsterSeen") and (v.shown - root.Position).Magnitude < 280 then
			player:SetAttribute("MonsterSeen", true) -- premier monstre vu de près (Guide.client)
		end
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
			local grow = 1 -- toujours à sa taille (il ne sort plus d'un astéroïde)
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
			local pivot = CFrame.lookAt(at, at + dir)
			if v.rig then
				-- chaque monstre a sa démarche (MonsterGaits) : pattes, ailes, mâchoires, corps de serpent
				local goal = if v.state == "Chase" then 1 elseif v.state == "Return" then 0.6 else 0
				v.effort = (v.effort or 0) + (goal - (v.effort or 0)) * math.min(1, dt * 3)
				v.rig.hop, v.rig.squat = hop, squat
				v.rig:Step(pivot, t, v.effort, lunge)
			else
				pivot *= wobble
				m:PivotTo(pivot)
			end
			-- les yeux, devant lui
			if v.eyes and #v.eyes == 2 then
				local s2 = v.size * grow
				v.eyes[1].WorldPosition = (pivot * CFrame.new(-s2 * 0.12, s2 * 0.14, -s2 * 0.42)).Position
				v.eyes[2].WorldPosition = (pivot * CFrame.new(s2 * 0.12, s2 * 0.14, -s2 * 0.42)).Position
			end
			if not v.rig then
				local _, s = m:GetBoundingBox()
				local cur = math.max(s.X, s.Y, s.Z)
				local want = math.max(0.5, v.size * grow * (1 + 0.18 * lunge))
				if math.abs(cur - want) > 0.05 then
					m:ScaleTo(m:GetScale() * want / cur)
				end
			end
			if v.growl then
				v.growl:Set(if v.state == "Chase" then 1 elseif v.state == "Return" then 0.6 else 0.3)
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
		if v.mine and root and v.state == "Chase" then
			chased = true
			-- flèche lumineuse : le chemin jusqu'à la ligne rouge de la cour, là où le monstre s'arrête
			do
				local map = Config.Map
				local reach = map.CorridorWidth / 2 - 6
				homeTo.WorldPosition = Vector3.new(math.clamp(root.Position.X, -reach, reach), 3, map.FrontZ - 4)
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
			local beat = math.max(0, 1 - (os.clock() - alarmAt) / 0.45) -- le bord rouge bat avec l'alarme
			vignette.ImageTransparency = 1 - math.max(near * (0.55 + 0.25 * math.sin(os.clock() * (6 + 8 * near))), beat * 0.9)
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
				local edge = center + d2.Unit * (math.min(vp.X, vp.Y) / 2 - 20)
				arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
				arrow.ImageTransparency = 0.25 + 0.3 * math.sin(os.clock() * 9)
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
end)
