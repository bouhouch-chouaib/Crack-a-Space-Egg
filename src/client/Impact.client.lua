-- Ce qui se passe sur la roche quand on la fore (modèle : la barre d'œuf de Break and Steal an Egg).
-- - Barre de vie au-dessus de la roche visée. On fore œuf par œuf : la barre est celle de l'œuf
--   en cours (« 12/40 HP »), elle se vide, l'œuf sort, puis elle se remplit pour l'œuf suivant.
--   Au-dessus : taille de la roche et « 🥚 3/8 left » œufs restants. Vert -> jaune -> rouge.
-- - Les fissures, elles, suivent l'état de toute la roche (œufs déjà sortis compris).
-- - Nombres de dégâts qui s'envolent à chaque coup (dorés quand un œuf sort).
-- - Fissures qui apparaissent par stades (Config.CrackStages), de la couleur du biome.
-- - L'œuf jaillit de la roche dans la couleur de sa rareté, fait un arc, vole jusqu'au foreur.
-- - À la casse : flash, la roche vole en morceaux, nuage de poussière.
-- Les coups arrivent du serveur (Remotes.DrillHit), pour tous les joueurs.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("Theme"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local targetValue = player:WaitForChild("DrillTarget", 10) :: ObjectValue?

local CRACKS = { "rbxassetid://94972210493198", "rbxassetid://94296533181521", "rbxassetid://125866557757494" }
local FACES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Right, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Bottom }
local OUTLINE = Color3.fromRGB(22, 22, 32)

local gui = UIKit.new("ScreenGui", { Name = "Impact", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function label(props: { [string]: any }): TextLabel
	local stroke = props.Stroke or 2
	props.Stroke = nil
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.FontFace = Theme.FontHeavy
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(t :: any)[k] = v
		end
	end
	local s = Instance.new("UIStroke")
	s.Thickness = stroke
	s.Color = OUTLINE
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = t
	t.Parent = props.Parent
	return t
end

local function rockColor(rock: BasePart): Color3
	return rock.Color
end

local function biomeColor(rock: BasePart): Color3
	local ring = rock:GetAttribute("Ring")
	local biome = Config.Biomes[ring or 1]
	return if biome then biome.Clouds[1] else Color3.fromRGB(255, 200, 120)
end

-- BARRE DE VIE --------------------------------------------------------------------

local bar = Instance.new("BillboardGui")
bar.Name = "RockBar"
bar.Size = UDim2.fromOffset(250, 92)
bar.AlwaysOnTop = true
bar.LightInfluence = 0
bar.MaxDistance = 180
bar.Enabled = false
-- Directement dans PlayerGui : une BillboardGui rangée dans une ScreenGui ne s'affiche pas
bar.Parent = player:WaitForChild("PlayerGui")

local barTitle = label({ Size = UDim2.new(1, 0, 0, 24), Text = "", Stroke = 2.5, Parent = bar })
local barEggs = label({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 24), Text = "", TextColor3 = Color3.fromRGB(255, 240, 160), Stroke = 2, Parent = bar })
local barBack = UIKit.new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.fromOffset(0, 50),
	BackgroundColor3 = Color3.fromRGB(40, 42, 54),
	Parent = bar,
}, { UIKit.corner(10), UIKit.stroke(3, OUTLINE) })
local barFill = UIKit.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = barBack,
}, { UIKit.corner(10) })
local barGrad = UIKit.gradient(Color3.fromRGB(140, 255, 90), Color3.fromRGB(60, 190, 40))
barGrad.Parent = barFill
-- Reflet sur le haut de la barre
UIKit.new("Frame", {
	Size = UDim2.new(1, -8, 0.35, 0),
	Position = UDim2.fromOffset(4, 3),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.7,
	ZIndex = 2,
	Parent = barBack,
}, { UIKit.corner(6) })
local barText = label({ Size = UDim2.new(1, -12, 0.78, 0), Position = UDim2.new(0, 6, 0.11, 0), Text = "", ZIndex = 3, Stroke = 2.5, Parent = barBack })

local barRock: BasePart? = nil
local shownHp = 0 -- vie affichée (défile vers eggLeft)
local eggLeft = 0 -- vie restante de l'œuf en cours (le sien)
local eggHP = 1 -- vie d'un œuf de cet anneau
local lastHit = 0

local function barColors(f: number): (Color3, Color3)
	if f > 0.5 then
		return Color3.fromRGB(140, 255, 90), Color3.fromRGB(60, 190, 40)
	elseif f > 0.25 then
		return Color3.fromRGB(255, 230, 90), Color3.fromRGB(240, 160, 30)
	end
	return Color3.fromRGB(255, 110, 100), Color3.fromRGB(210, 30, 40)
end

local function showBar(rock: BasePart)
	if barRock ~= rock then
		barRock = rock
		local ringCfg = Config.Rings[rock:GetAttribute("Ring") or 1]
		eggHP = if ringCfg then ringCfg.EggHP else 1
		eggLeft = eggHP
		shownHp = eggHP
		bar.Adornee = rock
		local ring = rock:GetAttribute("Ring") or 1
		local biome = Config.Biomes[ring]
		local size = string.upper(tostring(rock:GetAttribute("Size") or ""))
		barTitle.Text = (if biome then biome.Icon .. " " else "") .. size .. (if size ~= "" then " " else "") .. "ROCK"
		barTitle.TextColor3 = biomeColor(rock):Lerp(Color3.new(1, 1, 1), 0.35)
		UIKit.bump(barBack, 0.15)
	end
	bar.Enabled = true
end

RunService.RenderStepped:Connect(function(dt)
	local target = targetValue and targetValue.Value :: BasePart?
	if target and target.Parent then
		showBar(target)
		lastHit = os.clock()
	end
	local rock = barRock
	if not rock or not rock.Parent or os.clock() - lastHit > 1.5 then
		bar.Enabled = false
		barRock = nil
		return
	end
	-- Le nombre défile vers la vraie valeur, comme dans les jeux d'œufs
	shownHp += (eggLeft - shownHp) * math.min(1, dt * 12)
	local f = math.clamp(shownHp / eggHP, 0, 1)
	barFill.Size = UDim2.fromScale(math.max(f, 0.02), 1)
	local c1, c2 = barColors(f)
	barGrad.Color = ColorSequence.new(c1, c2)
	barText.Text = Format.Short(math.max(0, shownHp)) .. "/" .. Format.Short(eggHP) .. " HP"
	barEggs.Text = "🥚 " .. (rock:GetAttribute("Eggs") or 0) .. "/" .. (rock:GetAttribute("MaxEggs") or 0) .. " left"
	bar.StudsOffsetWorldSpace = Vector3.new(0, rock.Size.Y / 2 + 4, 0)
end)

-- NOMBRES DE DÉGÂTS -----------------------------------------------------------------

local function damageNumber(at: Vector3, text: string, color: Color3, big: boolean)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = at + Vector3.new((math.random() - 0.5) * 2, 0.5, (math.random() - 0.5) * 2)
	holder.Parent = workspace
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(if big then 170 else 120, if big then 56 else 40)
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.MaxDistance = 120
	b.Parent = holder
	local t = label({ Size = UDim2.fromScale(1, 1), Text = text, TextColor3 = color, Stroke = if big then 3.5 else 2.5, Parent = b })
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = t
	tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	t.Rotation = (math.random() - 0.5) * 16
	tween(holder, 0.9, { Position = holder.Position + Vector3.new(0, if big then 6 else 4.5, 0) }, Enum.EasingStyle.Quad)
	task.delay(0.5, function()
		tween(t, 0.4, { TextTransparency = 1 })
		local s = t:FindFirstChildOfClass("UIStroke")
		if s then
			tween(s, 0.4, { Transparency = 1 })
		end
	end)
	Debris:AddItem(holder, 1)
end

-- FISSURES ---------------------------------------------------------------------

local crackStage: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any

local function addCracks(rock: BasePart, stage: number)
	local color = biomeColor(rock):Lerp(Color3.fromRGB(255, 240, 200), 0.3)
	local count = if stage == 1 then 2 elseif stage == 2 then 2 else 2
	for k = 1, count do
		local face = FACES[((stage - 1) * 2 + k - 1) % #FACES + 1]
		local d = Instance.new("Decal")
		d.Name = "Crack"
		d.Texture = CRACKS[math.random(1, #CRACKS)]
		d.Face = face
		d.Color3 = color
		d.Transparency = 1
		d.ZIndex = stage
		d.Parent = rock
		tween(d, 0.15, { Transparency = 0 })
	end
end

local function updateCracks(rock: BasePart)
	local hp = tonumber(rock:GetAttribute("HP")) or 0
	local maxHp = math.max(1, tonumber(rock:GetAttribute("MaxHP")) or 1)
	local f = hp / maxHp
	local stage = 0
	for i, limit in ipairs(Config.CrackStages) do
		if f <= limit then
			stage = i
		end
	end
	local current = crackStage[rock] or 0
	while current < stage do
		current += 1
		addCracks(rock, current)
	end
	crackStage[rock] = current
	return current
end

-- ŒUF QUI JAILLIT ----------------------------------------------------------------

local function eggPart(color: Color3, size: number): Part
	local egg = Instance.new("Part")
	egg.Name = "FlyingEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.one * size
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanQuery = false
	egg.CanTouch = false
	egg.Material = Enum.Material.SmoothPlastic
	egg.Color = color
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.3, 1)
	mesh.Parent = egg
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8
	light.Brightness = 2
	light.Parent = egg
	-- Traînée de lumière derrière l'œuf
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, size * 0.3, 0)
	a0.Parent = egg
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -size * 0.3, 0)
	a1.Parent = egg
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.35
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Parent = egg
	return egg
end

-- Halo et rayons autour de l'œuf (plus la rareté est haute, plus c'est gros)
local function eggAura(egg: Part, color: Color3, rarity: number)
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromScale(4 + rarity, 4 + rarity)
	b.LightInfluence = 0
	b.AlwaysOnTop = false
	b.Parent = egg
	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Size = UDim2.fromScale(1, 1)
	glow.Image = UIKit.Art.FxGlow
	glow.ImageColor3 = color
	glow.ImageTransparency = 0.25
	glow.Parent = b
	if rarity >= 4 then
		local rays = Instance.new("ImageLabel")
		rays.BackgroundTransparency = 1
		rays.AnchorPoint = Vector2.new(0.5, 0.5)
		rays.Position = UDim2.fromScale(0.5, 0.5)
		rays.Size = UDim2.fromScale(1.6, 1.6)
		rays.Image = UIKit.Art.FxRays
		rays.ImageColor3 = color
		rays.ImageTransparency = 0.15
		rays.Parent = b
		tween(rays, 1.4, { Rotation = 200 }, Enum.EasingStyle.Linear)
	end
end

local function flyEgg(from: Vector3, rarity: number, to: () -> Vector3?, delay: number, isMine: boolean)
	task.delay(delay, function()
		local r = Config.Rarities[rarity] or Config.Rarities[1]
		local color = r.Color
		local size = 1.6 + rarity * 0.15
		local egg = eggPart(color, size)
		egg.CFrame = CFrame.new(from)
		egg.Parent = workspace
		eggAura(egg, color, rarity)
		-- Éclat de sortie
		local burst = Instance.new("Attachment")
		burst.WorldPosition = from
		burst.Parent = workspace.Terrain
		local p = Instance.new("ParticleEmitter")
		p.Texture = UIKit.Art.FxSparkle
		p.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 1.4 + rarity * 0.2), NumberSequenceKeypoint.new(1, 0) })
		p.Lifetime = NumberRange.new(0.3, 0.6)
		p.Speed = NumberRange.new(8, 18)
		p.SpreadAngle = Vector2.new(180, 180)
		p.LightEmission = 1
		p.LightInfluence = 0
		p.Enabled = false
		p.Parent = burst
		p:Emit(12 + rarity * 4)
		Debris:AddItem(burst, 1)
		-- Arc vers le haut en tournant, puis vol jusqu'au joueur
		local start = os.clock()
		local up = from + Vector3.new((math.random() - 0.5) * 4, 6 + math.random() * 2, (math.random() - 0.5) * 4)
		local hang = 0.45 + rarity * 0.05
		local fly = 0.45
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			local spin = CFrame.Angles(0, t * 9, math.sin(t * 7) * 0.4)
			if t < hang then
				local k = t / hang
				local e = 1 - (1 - k) ^ 3
				local pos = from:Lerp(up, e)
				egg.CFrame = CFrame.new(pos) * spin
				egg.Size = Vector3.one * size * (0.4 + 0.6 * math.min(1, k * 3))
			elseif t < hang + fly then
				local k = (t - hang) / fly
				local goal = to() or up
				local e = k * k
				local pos = up:Lerp(goal, e) + Vector3.new(0, math.sin(k * math.pi) * 3, 0)
				egg.CFrame = CFrame.new(pos) * spin
				egg.Size = Vector3.one * size * (1 - 0.7 * e)
			else
				conn:Disconnect()
				local goal = to() or up
				egg:Destroy()
				if isMine then
					damageNumber(goal + Vector3.new(0, 2, 0), "+1 🥚 " .. string.upper(r.Name), color, true)
				end
			end
		end)
	end)
end

-- CASSE EN MORCEAUX ------------------------------------------------------------------

local function shatter(rock: BasePart)
	local model = rock.Parent
	local center = rock.Position
	local size = rock.Size
	local color = rockColor(rock)
	-- On cache la vraie roche (elle sera supprimée par le serveur)
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end
	end
	-- Flash
	local flash = Instance.new("Part")
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.Transparency = 1
	flash.Size = Vector3.one * 0.2
	flash.Position = center
	flash.Parent = workspace
	local fb = Instance.new("BillboardGui")
	fb.Size = UDim2.fromScale(size.Magnitude * 0.8, size.Magnitude * 0.8)
	fb.LightInfluence = 0
	fb.Parent = flash
	local fi = Instance.new("ImageLabel")
	fi.BackgroundTransparency = 1
	fi.Size = UDim2.fromScale(1, 1)
	fi.Image = UIKit.Art.FxGlow
	fi.ImageColor3 = Color3.new(1, 1, 1)
	fi.Parent = fb
	tween(fb, 0.45, { Size = UDim2.fromScale(size.Magnitude * 2.2, size.Magnitude * 2.2) })
	tween(fi, 0.45, { ImageTransparency = 1 })
	Debris:AddItem(flash, 0.6)
	-- Morceaux : des copies réduites de la roche qui partent en tournant
	local pieces = math.clamp(math.floor(size.Magnitude / 3), 6, 11)
	for _ = 1, pieces do
		local chunk = rock:Clone()
		for _, c in ipairs(chunk:GetChildren()) do
			c:Destroy()
		end
		chunk.Anchored = true
		chunk.CanCollide = false
		chunk.CanQuery = false
		chunk.CanTouch = false
		chunk.LocalTransparencyModifier = 0
		chunk.Size = size * (0.18 + math.random() * 0.17)
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5).Unit
		chunk.CFrame = CFrame.new(center + dir * size.Magnitude * 0.15) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		chunk.Parent = workspace
		local goal = center + dir * (size.Magnitude * (0.6 + math.random() * 0.6)) + Vector3.new(0, -3, 0)
		tween(chunk, 1.1, {
			CFrame = CFrame.new(goal) * CFrame.Angles(math.random() * 8, math.random() * 8, math.random() * 8),
			Size = chunk.Size * 0.3,
			Transparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		Debris:AddItem(chunk, 1.2)
	end
	-- Poussière et étincelles
	local a = Instance.new("Attachment")
	a.WorldPosition = center
	a.Parent = workspace.Terrain
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = UIKit.Art.FxGlow
	dust.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.4))
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size.Magnitude * 0.2), NumberSequenceKeypoint.new(1, size.Magnitude * 0.55) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.8, 1.4)
	dust.Speed = NumberRange.new(4, 10)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.LightInfluence = 1
	dust.Enabled = false
	dust.Parent = a
	dust:Emit(14)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = UIKit.Art.FxSparkle
	sparks.Color = ColorSequence.new(Color3.new(1, 1, 1), biomeColor(rock))
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 1.6), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.4, 0.8)
	sparks.Speed = NumberRange.new(14, 30)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Enabled = false
	sparks.Parent = a
	sparks:Emit(30)
	Debris:AddItem(a, 1.6)
end

-- COUPS DU SERVEUR ---------------------------------------------------------------

Remotes.DrillHit.OnClientEvent:Connect(function(rock: BasePart?, by: Player, damage: number, rarities: { number }, broken: boolean, left: number?, perEgg: number?)
	if not rock or not rock.Parent then
		return
	end
	local isMine = by == player
	local character = by.Character
	local at = (character and character:GetAttribute("DrillAt")) :: Vector3?
	if isMine then
		at = player:GetAttribute("DrillAtLocal") or at
	end
	local point = at or rock.Position
	if (point - camera.CFrame.Position).Magnitude > 220 then
		return
	end
	if isMine then
		lastHit = os.clock()
		player:SetAttribute("LastDrillHit", workspace:GetServerTimeNow())
		showBar(rock)
		eggHP = perEgg or eggHP
		if #rarities > 0 then
			-- Un œuf vient de sortir : la barre se vide jusqu'au bout, puis repart pleine pour le suivant
			shownHp = 0
			eggLeft = left or eggHP
			UIKit.bump(barBack, 0.25)
		else
			eggLeft = left or eggLeft
		end
	end
	-- Nombre de dégâts (seulement les siens, pour rester lisible à plusieurs)
	if isMine then
		local gold = #rarities > 0
		damageNumber(point, "-" .. Format.Short(damage), if gold then Color3.fromRGB(255, 220, 80) else Color3.new(1, 1, 1), gold)
	end
	-- Petit éclair blanc sur la roche (comme l'éclat sur l'œuf des jeux d'œufs)
	local hl = rock:FindFirstChild("HitFlash") :: Highlight?
	if not hl then
		local h = Instance.new("Highlight")
		h.Name = "HitFlash"
		h.FillColor = Color3.new(1, 1, 1)
		h.OutlineTransparency = 1
		h.FillTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = rock.Parent
		h.Parent = rock
		hl = h
	end
	if hl and not broken then
		hl.FillTransparency = 0.55
		tween(hl, 0.12, { FillTransparency = 1 })
	end
	-- Fissures par stades ; un petit éclat se détache à chaque nouveau stade
	local before = crackStage[rock] or 0
	local after = updateCracks(rock)
	if after > before and not broken then
		UIKit.bump(barBack, 0.2)
	end
	-- Œufs qui jaillissent et volent vers le foreur
	for i, rarity in ipairs(rarities) do
		flyEgg(point, rarity, function()
			local c = by.Character
			local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			return if root then root.Position + Vector3.new(0, 1, 0) else nil
		end, (i - 1) * 0.12, isMine)
	end
	if broken then
		task.delay(if #rarities > 0 then 0.15 else 0, function()
			if rock.Parent then
				shatter(rock)
			end
		end)
	end
end)
