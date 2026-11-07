-- Effets d'éclosion (Hatchery.client) : l'œuf se charge puis éclate, de plus en plus fort avec la rareté.
--   local fx = HatchFx.Charge(egg, { rarity = 5, grow = 2.1, duration = 4.3, owner = true })
--   ... fx.center, fx.size : centre et hauteur actuels de l'œuf (il grossit) ; fx.stop()
--   HatchFx.Burst(center, size, groundY, rarity, owner)
-- Charge, de la plus commune à la plus rare (chaque rareté garde ce qu'ont les précédentes) :
--   Common     tremble, s'illumine, gonfle un peu
--   Uncommon   + rayons de lumière qui sortent des fissures
--   Rare       + disque de lumière au sol, battements de cœur, la caméra du propriétaire gronde
--   Epic       + l'œuf s'élève et tourne sur lui-même, l'énergie est aspirée vers lui
--   Legendary  + colonne de lumière venue du ciel, l'écran s'assombrit, le champ de vision s'élargit
--   Mythic     + plus haut, plus vite, plus de rayons
--   Cosmic     + couleurs arc-en-ciel, tout se fige un instant avant l'éclatement
-- L'œuf grossit pendant la charge jusqu'à la taille de la créature à naître (grow = hauteur finale / hauteur
-- de l'œuf) : plus elle est immense, plus il gonfle.
-- Aucune dépendance au joueur : le module marche aussi en mode édition (aperçu depuis Studio).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- mêmes images que UIKit.Art (FxGlow, FxSparkle, FxShell, FxRays, FxShard)
local ART = {
	Glow = "rbxassetid://103844906730878",
	Sparkle = "rbxassetid://138922153683020",
	Shell = "rbxassetid://73009463028666",
	Rays = "rbxassetid://100803246971606",
	Shard = "rbxassetid://121742631956253",
}
local TAU = math.pi * 2
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 215, 60)
local kp = NumberSequenceKeypoint.new

local HatchFx = {}

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Couleur de la rareté ; Cosmic change de teinte en continu
local function colorOf(rarity: number, t: number): Color3
	if rarity >= 7 then
		return Color3.fromHSV((t * 0.35) % 1, 0.6, 1)
	end
	return (Config.Rarities[rarity] or Config.Rarities[1]).Color
end

local function neon(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local function tween(
	o: Instance,
	t: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
)
	local tw =
		TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end

-- SECOUSSE DE CAMÉRA (propriétaire seulement) -----------------------------------------------
-- Rotation seule ; on retire l'écart de l'image précédente avant les scripts de caméra et on pose le
-- nouveau juste après, sinon la vue dériverait.
local shakes: { { mag: number, start: number, dur: number } } = {}
local held = 0 -- grondement continu pendant la charge (degrés)
local lastOffset = CFrame.new()
local bound = false

local function shakeStep()
	local cam = workspace.CurrentCamera
	local now = os.clock()
	local mag = held
	for i = #shakes, 1, -1 do
		local s = shakes[i]
		local f = (now - s.start) / s.dur
		if f >= 1 then
			table.remove(shakes, i)
		else
			mag = math.max(mag, s.mag * (1 - f) ^ 2)
		end
	end
	local r = math.rad(mag)
	lastOffset =
		CFrame.Angles(math.noise(now * 18, 0.3) * r, math.noise(now * 18, 4.7) * r, math.noise(now * 18, 9.1) * r * 0.5)
	cam.CFrame *= lastOffset
	if mag <= 0 and #shakes == 0 then
		RunService:UnbindFromRenderStep("HatchShakeUndo")
		RunService:UnbindFromRenderStep("HatchShakeApply")
		bound = false
		lastOffset = CFrame.new()
	end
end

local function ensureShake()
	if bound or not RunService:IsRunning() or not RunService:IsClient() then
		return
	end
	bound = true
	RunService:BindToRenderStep("HatchShakeUndo", Enum.RenderPriority.Camera.Value - 1, function()
		workspace.CurrentCamera.CFrame *= lastOffset:Inverse()
		lastOffset = CFrame.new()
	end)
	RunService:BindToRenderStep("HatchShakeApply", Enum.RenderPriority.Camera.Value + 1, shakeStep)
end

function HatchFx.Shake(mag: number, dur: number)
	table.insert(shakes, { mag = mag, start = os.clock(), dur = dur })
	ensureShake()
end

-- CHARGE ----------------------------------------------------------------------------------

type Opts = {
	rarity: number,
	grow: number?,
	duration: number?,
	owner: boolean?,
	speed: number?,
	onCrack: ((number) -> ())?,
}

function HatchFx.Charge(egg: Model, o: Opts)
	local rarity = math.clamp(o.rarity, 1, 7)
	local grow = math.max(1, o.grow or 1)
	local dur = o.duration or 2
	local speed = o.speed or 1
	local owner = o.owner == true
	local base = egg:GetPivot()
	local h = (egg:GetAttribute("BodyHeight") or 3) :: number
	local scale0 = egg:GetScale()
	local groundY = base.Position.Y - h / 2 - 0.6 -- l'œuf est posé à h / 2 + 0.6 au-dessus du sol
	local rng = Random.new()
	local folder = Instance.new("Folder")
	folder.Name = "HatchFx"
	folder.Parent = workspace

	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = egg
	hl.Parent = folder
	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Shadows = false
	light.Parent = egg.PrimaryPart

	-- rayons des fissures : un de plus à chaque cran de rareté, ils s'ouvrent l'un après l'autre
	local rays = {}
	local n = if rarity >= 2 then math.min(rarity * 2 - 1, 13) else 0
	for i = 1, n do
		local y = rng:NextNumber(-0.25, 0.9)
		local a = rng:NextNumber(0, TAU)
		local r = math.sqrt(1 - y * y)
		table.insert(rays, {
			dir = Vector3.new(math.cos(a) * r, y, math.sin(a) * r),
			at = 0.12 + 0.72 * (if n > 1 then (i - 1) / (n - 1) else 0) + rng:NextNumber(-0.03, 0.03),
			part = nil :: Part?,
		})
	end

	local disc = if rarity >= 3
		then neon({
			Name = "Disc",
			Shape = Enum.PartType.Cylinder,
			Transparency = 1,
			Size = Vector3.new(0.12, 1, 1),
			Parent = folder,
		})
		else nil
	local pillar = if rarity >= 5
		then neon({
			Name = "Pillar",
			Shape = Enum.PartType.Cylinder,
			Transparency = 1,
			Size = Vector3.new(400, 1, 1),
			Parent = folder,
		})
		else nil
	-- énergie aspirée vers l'œuf (particules sur une sphère, vers l'intérieur)
	local suck: ParticleEmitter? = nil
	local ball: Part? = nil
	if rarity >= 4 then
		ball = neon({
			Name = "Suck",
			Shape = Enum.PartType.Ball,
			Transparency = 1,
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
		local e = Instance.new("ParticleEmitter")
		e.Texture = ART.Sparkle
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.Lifetime = NumberRange.new(0.55, 0.65)
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Rate = 0
		e.Transparency = NumberSequence.new({ kp(0, 1), kp(0.25, 0), kp(1, 0) })
		e.Parent = ball
		suck = e
	end
	-- l'écran du propriétaire s'assombrit vers la couleur de la rareté
	local cc: ColorCorrectionEffect? = nil
	local cam = workspace.CurrentCamera
	local fov0 = cam.FieldOfView
	if owner and rarity >= 5 then
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "HatchTint"
		c.Parent = Lighting
		cc = c
	end

	local t0 = os.clock()
	local last = t0
	local spin = 0
	local cracks = 0
	local handle = {
		center = base.Position,
		size = h,
		groundY = groundY,
		origin = base.Position,
		rarity = rarity,
		stop = function() end,
	}
	local conn: RBXScriptConnection

	local function update()
		local now = os.clock()
		local dt = (now - last) * speed
		last = now
		if not egg.Parent then
			handle.stop()
			return
		end
		local k = math.clamp((now - t0) * speed / dur, 0, 1)
		local col = colorOf(rarity, now)
		local frozen = rarity >= 7 and k > 0.9 -- Cosmic : tout se fige juste avant l'éclatement
		-- taille : gonfle vers celle de la créature, battements de cœur, dernier gonflement avant de céder
		local g = 1 + (grow - 1) * k ^ 1.5
		local beat = if rarity >= 3 then 0.05 * math.max(0, math.sin(now * (5 + 12 * k))) ^ 6 * k else 0
		local pop = 0.14 * smooth((k - 0.86) / 0.14)
		local gs = g * (1 + beat + pop)
		egg:ScaleTo(scale0 * gs)
		-- s'élève et tourne (Epic+)
		local lift = 0
		if rarity >= 4 then
			lift = h * (0.35 + 0.15 * (rarity - 4)) * smooth(k / 0.4) + math.sin(now * 2.3) * h * 0.04 * k
			if not frozen then
				spin += dt * (0.6 + 10 * k * k) * (if rarity >= 6 then 1.4 else 1)
			end
		end
		local a = if frozen then 0 else (0.03 + 0.28 * k * k) * (if rarity >= 4 then 0.45 else 1)
		local jitter = if frozen
			then Vector3.zero
			else Vector3.new(math.sin(now * 53), math.abs(math.sin(now * 30)), math.cos(now * 47)) * 0.035 * h * k
		local center = Vector3.new(base.Position.X, groundY + 0.6 + h * gs / 2 + lift, base.Position.Z)
		egg:PivotTo(
			CFrame.new(center + jitter)
				* base.Rotation
				* CFrame.Angles(0, spin, 0)
				* CFrame.Angles(math.sin(now * 41) * a, 0, math.cos(now * 37) * a)
		)
		handle.center = center
		handle.size = h * gs
		-- lueur de l'œuf
		hl.FillColor = col:Lerp(WHITE, 0.45)
		hl.FillTransparency = 1 - 0.5 * k * k
		hl.OutlineColor = col
		hl.OutlineTransparency = 1 - 0.9 * k
		light.Color = col
		light.Brightness = (0.5 + 0.5 * rarity) * k ^ 1.5
		light.Range = math.min(40, h * gs * (1.5 + 1.5 * k))
		-- rayons des fissures
		local turn = CFrame.Angles(0, spin, 0)
		for i, ray in ipairs(rays) do
			if k >= ray.at then
				local p = ray.part
				if not p then
					p = neon({ Name = "Ray", Transparency = 0.3, Parent = folder })
					ray.part = p
					cracks += 1
					if o.onCrack then
						task.spawn(o.onCrack, cracks)
					end
				end
				local open = smooth((k - ray.at) / 0.22)
				local len = h * gs * (0.42 + (0.2 + 0.06 * rarity) * open)
				local w = h * gs * (0.03 + 0.04 * k) * (0.6 + 0.4 * open)
				local dir = turn:VectorToWorldSpace(ray.dir)
				local p2 = p :: Part
				p2.Color = col:Lerp(WHITE, 0.25 + 0.15 * math.sin(now * 20 + i))
				p2.Size = Vector3.new(w, w, len)
				p2.CFrame = CFrame.lookAt(center, center + dir) * CFrame.new(0, 0, -len / 2)
			end
		end
		if disc then
			local d = h * gs * (1.1 + 0.8 * k)
			disc.Size = Vector3.new(0.12, d, d)
			disc.CFrame = CFrame.new(center.X, groundY + 0.08, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
			disc.Color = col
			disc.Transparency = 1 - 0.4 * smooth(k / 0.3)
		end
		if pillar then
			local w = h * gs * 0.55 * smooth(k / 0.6)
			pillar.Size = Vector3.new(400, math.max(0.05, w), math.max(0.05, w))
			pillar.CFrame = CFrame.new(center.X, groundY + 200, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
			pillar.Color = col
			pillar.Transparency = 0.85 - 0.3 * k
		end
		if ball and suck then
			local radius = h * gs * 1.6
			ball.Size = Vector3.one * radius * 2
			ball.Position = center
			suck.Speed = NumberRange.new(radius / 0.6)
			suck.Size = NumberSequence.new({ kp(0, h * gs * 0.12), kp(1, h * gs * 0.04) })
			suck.Color = ColorSequence.new(WHITE, col)
			suck.Rate = if frozen then 0 else (10 + 18 * rarity) * k
		end
		if cc then
			cc.Brightness = -0.14 * k
			cc.Contrast = 0.2 * k
			cc.Saturation = 0.3 * k
			cc.TintColor = WHITE:Lerp(col, 0.18 * k)
		end
		if owner then
			if rarity >= 5 then
				cam.FieldOfView = fov0 + 14 * smooth(k)
			end
			held = if rarity >= 3 and not frozen then 0.07 * rarity * k * k else 0
			if held > 0 then
				ensureShake()
			end
		end
	end

	handle.stop = function()
		if conn then
			conn:Disconnect()
		end
		if folder.Parent then
			folder:Destroy()
		end
		if light.Parent then
			light:Destroy()
		end
		if cc then
			cc:Destroy()
		end
		if owner then
			held = 0
			if rarity >= 5 then
				cam.FieldOfView = fov0
			end
		end
	end

	conn = RunService.RenderStepped:Connect(update)
	update()
	return handle
end

-- ÉCLATEMENT --------------------------------------------------------------------------------

-- center : centre de l'œuf au moment où il cède ; size : sa hauteur ; groundY : hauteur du sol
function HatchFx.Burst(center: Vector3, size: number, groundY: number, rarity: number, owner: boolean?)
	rarity = math.clamp(rarity, 1, 7)
	local S = size
	local col = colorOf(rarity, os.clock())
	local folder = Instance.new("Folder")
	folder.Name = "HatchBurst"
	folder.Parent = workspace
	local holder = neon({ Name = "At", Transparency = 1, Size = Vector3.one * 0.2, Position = center, Parent = folder })
	local at = Instance.new("Attachment")
	at.Parent = holder
	local function emit(props: { [string]: any }, count: number, delay: number?)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.LightInfluence = 0
		for k, v in pairs(props) do
			(e :: any)[k] = v
		end
		e.Parent = at
		if delay and delay > 0 then
			task.delay(delay, function()
				e:Emit(count)
			end)
		else
			e:Emit(count)
		end
	end

	-- 1. l'éclair : le plus gros sur l'écran, très court
	emit({
		Texture = ART.Glow,
		Color = ColorSequence.new(WHITE, col),
		LightEmission = 1,
		Brightness = 3 + rarity,
		Size = NumberSequence.new({ kp(0, S * 2), kp(1, S * 0.3) }),
		Lifetime = NumberRange.new(0.14),
		Speed = NumberRange.new(0),
	}, 1)
	-- 2. le corps : une boule de lumière qui enfle et s'efface, et une étoile de rayons (Rare+)
	emit({
		Texture = ART.Glow,
		Color = ColorSequence.new(col),
		LightEmission = 1,
		Brightness = 2,
		Size = NumberSequence.new({ kp(0, S * 1.1), kp(1, S * (1.4 + 0.15 * rarity)) }),
		Transparency = NumberSequence.new({ kp(0, 0.35), kp(1, 1) }),
		Lifetime = NumberRange.new(0.5 + 0.06 * rarity),
		Speed = NumberRange.new(0),
	}, 2, 0.03)
	if rarity >= 3 then
		emit({
			Texture = ART.Rays,
			Color = ColorSequence.new(col:Lerp(WHITE, 0.3)),
			LightEmission = 1,
			Brightness = 1.5,
			Size = NumberSequence.new({ kp(0, S * 1.8), kp(1, S * (2.4 + 0.2 * rarity)) }),
			Transparency = NumberSequence.new({ kp(0, 0.3), kp(0.6, 0.55), kp(1, 1) }),
			Lifetime = NumberRange.new(0.7 + 0.1 * rarity),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(40, 70),
			Speed = NumberRange.new(0),
		}, 1, 0.05)
	end
	-- 3. éclats de coquille et étincelles qui partent loin puis ralentissent
	emit({
		Texture = ART.Shell,
		Color = ColorSequence.new(WHITE:Lerp(col, 0.25)),
		Size = NumberSequence.new({ kp(0, S * 0.18), kp(1, S * 0.08) }),
		Lifetime = NumberRange.new(0.9, 1.4),
		Speed = NumberRange.new(S * 4, S * 8),
		Drag = 2.5,
		Acceleration = Vector3.new(0, -S * 6, 0),
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-300, 300),
	}, 10 + rarity * 3, 0.06)
	emit({
		Texture = ART.Sparkle,
		Color = ColorSequence.new(WHITE, col),
		LightEmission = 1,
		Brightness = 2,
		Size = NumberSequence.new({ kp(0, 0), kp(0.15, S * (0.12 + 0.012 * rarity)), kp(1, 0) }),
		Lifetime = NumberRange.new(0.6, 1.3),
		Speed = NumberRange.new(S * 3, S * 9),
		Drag = 3,
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360),
	}, 12 + rarity * 5, 0.08)
	-- 4. confettis (Epic+) : couleur de la rareté, blanc et or, qui retombent doucement
	if rarity >= 4 then
		for i, c in ipairs({ col, WHITE, GOLD }) do
			emit({
				Texture = ART.Shard,
				Color = ColorSequence.new(c),
				LightEmission = 0.3,
				Size = NumberSequence.new(S * 0.06),
				Lifetime = NumberRange.new(1.6, 2.6),
				Speed = NumberRange.new(S * 3, S * 7),
				Drag = 1.6,
				Acceleration = Vector3.new(0, -S * 2, 0),
				SpreadAngle = Vector2.new(70, 70),
				EmissionDirection = Enum.NormalId.Top,
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-400, 400),
			}, 6 + rarity * 3, 0.1 + 0.03 * i)
		end
	end
	-- 5. ondes de choc au sol : 1 (Uncommon+), 2 (Legendary+), 3 (Cosmic)
	local rings = if rarity >= 7 then 3 elseif rarity >= 5 then 2 elseif rarity >= 2 then 1 else 0
	for i = 1, rings do
		task.delay(0.04 + 0.12 * (i - 1), function()
			local d0 = S * 0.6
			local ring = neon({
				Name = "Shockwave",
				Shape = Enum.PartType.Cylinder,
				Color = colorOf(rarity, os.clock()),
				Transparency = 0.35,
				Size = Vector3.new(0.12, d0, d0),
				CFrame = CFrame.new(center.X, groundY + 0.1 + 0.05 * i, center.Z) * CFrame.Angles(0, 0, math.pi / 2),
				Parent = folder,
			})
			local d1 = S * (1.5 + 0.25 * rarity) * (1 + 0.3 * (i - 1))
			tween(ring, 0.45 + 0.05 * rarity, { Size = Vector3.new(0.12, d1, d1), Transparency = 1 })
		end)
	end
	-- 6. colonne de lumière qui éclate vers le ciel (Legendary+)
	if rarity >= 5 then
		local w = S * 0.6
		local p = neon({
			Name = "Pillar",
			Shape = Enum.PartType.Cylinder,
			Color = col:Lerp(WHITE, 0.4),
			Transparency = 0.05,
			Size = Vector3.new(400, w, w),
			CFrame = CFrame.new(center.X, groundY + 200, center.Z) * CFrame.Angles(0, 0, math.pi / 2),
			Parent = folder,
		})
		tween(
			p,
			0.9,
			{ Size = Vector3.new(400, 0.05, 0.05), Transparency = 1 },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)
	end
	-- 7. lumière : un coup fort, puis la portée s'élargit pendant qu'elle s'éteint
	local light = Instance.new("PointLight")
	light.Color = col
	light.Brightness = 2 + 0.6 * rarity
	light.Range = math.min(60, S * 2)
	light.Shadows = false
	light.Parent = holder
	tween(light, 0.6 + 0.08 * rarity, { Brightness = 0, Range = math.min(60, S * 6) })
	-- 8. écran du propriétaire : secousse, flash, champ de vision
	if owner and RunService:IsRunning() then
		HatchFx.Shake(({ 0.4, 0.6, 0.9, 1.4, 2.2, 3.2, 4.5 })[rarity], 0.3 + 0.15 * rarity)
		if rarity >= 4 then
			task.spawn(function()
				local cc = Instance.new("ColorCorrectionEffect")
				cc.Name = "HatchFlash"
				cc.Parent = Lighting
				if rarity >= 6 then
					-- image noire puis blanche (Mythic+)
					cc.Contrast = 2
					cc.Saturation = -1
					task.wait(0.05)
					cc.Contrast = 0
				end
				cc.Brightness = 0.5
				cc.Saturation = -0.4
				cc.TintColor = WHITE:Lerp(col, 0.2)
				tween(cc, 0.15 + 0.05 * rarity, { Brightness = 0, Saturation = 0, TintColor = WHITE })
				task.delay(0.6 + 0.05 * rarity, function()
					cc:Destroy()
				end)
			end)
		end
		if rarity >= 5 then
			local cam = workspace.CurrentCamera
			local fov = cam.FieldOfView
			cam.FieldOfView = fov - 7
			tween(cam, 0.35, { FieldOfView = fov }, Enum.EasingStyle.Back)
		end
	end
	task.delay(3.5, function()
		folder:Destroy()
	end)
end

return HatchFx
