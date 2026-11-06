-- Animation et effets du forage, pour tous les personnages (le sien et ceux des autres joueurs).
-- La foreuse (soudée au torse par GameService.EquipDrill) passe du dos aux deux mains, pointe vers
-- l'astéroïde, pompe comme un marteau-piqueur, sa mèche tourne ; les bras vont chercher les poignées.
-- Au point d'impact : étincelles en traînées, éclats de roche, poussière, point chaud lumineux et
-- faisceau d'énergie de la couleur de la foreuse. Tout est calculé ici : aucune animation à téléverser.
--
-- Son forage : lu dans les attributs locaux posés par Controls.client (DrillReady, DrillAtLocal).
-- Celui des autres : attributs DrillAt et DrillingUntil posés par le serveur sur leur personnage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SPARK = "rbxassetid://96887170089913" -- traînée lumineuse (tools/fx/make_spark.py)
local DOWN = Vector3.new(0, -1, 0)
local HOLD = Vector3.new(0, -0.15, -1.45) -- guidon devant la poitrine (repère du torse)
local DEFAULT_AIM = Vector3.new(0, -0.8, -0.6).Unit -- prêt à forer, sans cible : vers le bas, en avant
local GRIP = 1.0 -- demi-largeur du guidon (studs, avant mise à l'échelle)
local MAX_DISTANCE = 220 -- au-delà, on n'anime pas les autres joueurs

type Fx = {
	contact: Attachment,
	emitters: { ParticleEmitter },
	sparks: ParticleEmitter,
	stars: ParticleEmitter,
	chips: ParticleEmitter,
	dust: ParticleEmitter,
	light: PointLight,
	core: Beam,
	outer: Beam,
}

type Rig = {
	character: Model,
	drill: Model?,
	body: BasePart?,
	weld: Weld?,
	bitWeld: Weld?,
	bitBase: CFrame,
	tip: Attachment?,
	carry: CFrame,
	tier: number,
	k: number, -- 0 = sur le dos, 1 = en main
	aim: Vector3, -- direction de la mèche (repère du torse), lissée
	spin: number,
	spinSpeed: number,
	stroke: number, -- dernier coup de marteau (pour les gerbes d'étincelles)
	fx: Fx?,
}

local rigs: { [Model]: Rig } = {}

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

local function rotFromTo(a: Vector3, b: Vector3): CFrame
	local axis = a:Cross(b)
	local dot = math.clamp(a:Dot(b), -1, 1)
	if axis.Magnitude < 1e-5 then
		return if dot > 0 then CFrame.new() else CFrame.Angles(math.pi, 0, 0)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
end

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

-- EFFETS AU POINT D'IMPACT ------------------------------------------------------------

local function makeFx(rig: Rig): Fx
	local tierColor = (Config.Drills[rig.tier] or Config.Drills[1]).Color
	local contact = Instance.new("Attachment")
	contact.Name = "DrillContact"
	contact.Parent = workspace.Terrain

	-- 1. Étincelles en traînées (suivent leur vitesse, retombent)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARK
	sparks.Orientation = Enum.ParticleOrientation.VelocityParallel
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 220, 120)),
		ColorSequenceKeypoint.new(1, tierColor:Lerp(Color3.fromRGB(255, 120, 40), 0.5)),
	})
	sparks.Size = NumberSequence.new({ kp(0, 0.9), kp(1, 0.25) })
	sparks.Transparency = NumberSequence.new({ kp(0, 0), kp(0.7, 0.1), kp(1, 1) })
	sparks.Lifetime = NumberRange.new(0.25, 0.6)
	sparks.Speed = NumberRange.new(20, 42)
	sparks.SpreadAngle = Vector2.new(75, 75)
	sparks.Acceleration = Vector3.new(0, -35, 0)
	sparks.Drag = 2.5
	sparks.Rate = 120
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.EmissionDirection = Enum.NormalId.Front
	sparks.Parent = contact

	-- 2. Petites étoiles qui éclatent au contact
	local stars = Instance.new("ParticleEmitter")
	stars.Texture = UIKit.Art.FxSparkle
	stars.Color = ColorSequence.new(Color3.new(1, 1, 1), tierColor)
	stars.Size = NumberSequence.new({ kp(0, 0), kp(0.2, 1.6), kp(1, 0) })
	stars.Lifetime = NumberRange.new(0.15, 0.35)
	stars.Speed = NumberRange.new(2, 7)
	stars.SpreadAngle = Vector2.new(180, 180)
	stars.RotSpeed = NumberRange.new(-300, 300)
	stars.Rate = 40
	stars.LightEmission = 1
	stars.LightInfluence = 0
	stars.Parent = contact

	-- 3. Éclats de roche (couleur de l'astéroïde)
	local chips = Instance.new("ParticleEmitter")
	chips.Texture = UIKit.Art.FxShard
	chips.Size = NumberSequence.new({ kp(0, 0.45), kp(1, 0.2) })
	chips.Transparency = NumberSequence.new({ kp(0, 0), kp(0.8, 0), kp(1, 1) })
	chips.Lifetime = NumberRange.new(0.6, 1.1)
	chips.Speed = NumberRange.new(9, 18)
	chips.SpreadAngle = Vector2.new(60, 60)
	chips.Acceleration = Vector3.new(0, -45, 0)
	chips.Rotation = NumberRange.new(0, 360)
	chips.RotSpeed = NumberRange.new(-400, 400)
	chips.Rate = 30
	chips.LightEmission = 0
	chips.LightInfluence = 1
	chips.EmissionDirection = Enum.NormalId.Front
	chips.Parent = contact

	-- 4. Nuage de poussière
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = UIKit.Art.FxGlow
	dust.Size = NumberSequence.new({ kp(0, 1.5), kp(1, 6) })
	dust.Transparency = NumberSequence.new({ kp(0, 1), kp(0.15, 0.55), kp(1, 1) })
	dust.Lifetime = NumberRange.new(0.6, 1.1)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Rate = 12
	dust.LightEmission = 0
	dust.LightInfluence = 1
	dust.EmissionDirection = Enum.NormalId.Front
	dust.Parent = contact

	-- 5. Point chaud qui pulse
	local flash = Instance.new("ParticleEmitter")
	flash.Texture = UIKit.Art.FxGlow
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), tierColor:Lerp(Color3.fromRGB(255, 170, 60), 0.4))
	flash.Size = NumberSequence.new({ kp(0, 2.4), kp(1, 3.6) })
	flash.Transparency = NumberSequence.new({ kp(0, 0.3), kp(1, 1) })
	flash.Lifetime = NumberRange.new(0.06, 0.12)
	flash.Speed = NumberRange.new(0)
	flash.Rate = 30
	flash.LightEmission = 1
	flash.LightInfluence = 0
	flash.LockedToPart = true
	flash.Parent = contact

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 90):Lerp(tierColor, 0.35)
	light.Range = 12
	light.Brightness = 2
	light.Shadows = false
	light.Parent = contact

	-- 6. Faisceau d'énergie entre la mèche et la roche (cœur blanc + gaine colorée)
	local function beam(width0: number, width1: number, color: ColorSequence, transparency: number): Beam
		local b = Instance.new("Beam")
		b.Attachment0 = rig.tip
		b.Attachment1 = contact
		b.Width0 = width0
		b.Width1 = width1
		b.Color = color
		b.Transparency = NumberSequence.new(transparency)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Segments = 12
		b.Texture = UIKit.Art.FxGlow
		b.TextureMode = Enum.TextureMode.Stretch
		b.Parent = contact
		return b
	end
	local core = beam(0.14, 0.08, ColorSequence.new(Color3.new(1, 1, 1)), 0.05)
	local outer = beam(0.7, 0.35, ColorSequence.new(tierColor, Color3.fromRGB(255, 200, 120)), 0.35)

	return {
		contact = contact,
		emitters = { sparks, stars, chips, dust, flash },
		sparks = sparks,
		stars = stars,
		chips = chips,
		dust = dust,
		light = light,
		core = core,
		outer = outer,
	}
end

local function setFx(fx: Fx, on: boolean)
	for _, e in ipairs(fx.emitters) do
		e.Enabled = on
	end
	fx.light.Enabled = on
	fx.core.Enabled = on
	fx.outer.Enabled = on
end

local function dropFx(rig: Rig)
	if rig.fx then
		rig.fx.contact:Destroy()
		rig.fx = nil
	end
end

-- FOREUSE ÉQUIPÉE ----------------------------------------------------------------

local function bindDrill(rig: Rig)
	dropFx(rig)
	local drill = rig.character:FindFirstChild("EquippedDrill") :: Model?
	rig.drill = drill
	rig.body = nil
	rig.weld = nil
	rig.bitWeld = nil
	rig.tip = nil
	if not drill then
		return
	end
	local body = drill.PrimaryPart or drill:WaitForChild("Body", 5) :: BasePart?
	if not body then
		return
	end
	rig.body = body
	rig.weld = body:WaitForChild("DrillWeld", 5) :: Weld?
	if rig.weld then
		rig.carry = rig.weld.C0
	end
	local bit = drill:FindFirstChild("Bit") :: BasePart?
	if bit then
		rig.bitWeld = bit:FindFirstChild("BitWeld") :: Weld?
		rig.bitBase = if rig.bitWeld then rig.bitWeld.C0 else CFrame.new()
		rig.tip = bit:FindFirstChild("Tip") :: Attachment?
	end
	rig.tier = (drill:GetAttribute("Tier") or 1) :: number
end

local function track(character: Model)
	local rig: Rig = {
		character = character,
		carry = Config.DrillHold.Carry,
		bitBase = CFrame.new(),
		tier = 1,
		k = 0,
		aim = DEFAULT_AIM,
		spin = 0,
		spinSpeed = 0,
		stroke = 0,
	}
	rigs[character] = rig
	character.ChildAdded:Connect(function(child)
		if child.Name == "EquippedDrill" then
			task.defer(bindDrill, rig)
		end
	end)
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			dropFx(rig)
			rigs[character] = nil
		end
	end)
	task.defer(bindDrill, rig)
end

local function watch(p: Player)
	p.CharacterAdded:Connect(track)
	if p.Character then
		track(p.Character)
	end
end
for _, p in ipairs(Players:GetPlayers()) do
	watch(p)
end
Players.PlayerAdded:Connect(watch)

-- BRAS VERS LES POIGNÉES ----------------------------------------------------------

local function aimArm(shoulder: Motor6D?, elbow: Motor6D?, grip: Vector3, k: number, bend: number)
	if not shoulder or not shoulder.Part0 then
		return
	end
	local joint = shoulder.Part0.CFrame * shoulder.C0
	local d = grip - joint.Position
	if d.Magnitude < 0.05 then
		return
	end
	local want = rotFromTo(DOWN, joint:VectorToObjectSpace(d.Unit))
	shoulder.Transform = shoulder.Transform:Lerp(want, k)
	if elbow then
		elbow.Transform = elbow.Transform:Lerp(CFrame.Angles(bend, 0, 0), k)
	end
end

-- BOUCLE ---------------------------------------------------------------------------

local function part(character: Model, name: string): BasePart?
	return character:FindFirstChild(name) :: BasePart?
end

local function motor(character: Model, partName: string, name: string): Motor6D?
	local p = character:FindFirstChild(partName)
	return p and p:FindFirstChild(name) :: Motor6D?
end

RunService.PreSimulation:Connect(function(dt)
	local t = os.clock()
	local serverNow = workspace:GetServerTimeNow()
	local camPos = camera.CFrame.Position
	local mine = player.Character
	for character, rig in pairs(rigs) do
		local weld, body = rig.weld, rig.body
		local torso = weld and weld.Part0
		if not weld or not body or not torso or not weld.Parent then
			continue
		end
		local isMine = character == mine
		if not isMine and (torso.Position - camPos).Magnitude > MAX_DISTANCE then
			continue
		end

		-- État : prêt (outil en main), en train de forer, point d'impact
		local at: Vector3?, ready: boolean, drilling: boolean
		if isMine then
			at = player:GetAttribute("DrillAtLocal")
			ready = player:GetAttribute("DrillReady") == true
		else
			at = character:GetAttribute("DrillAt")
			ready = (character:GetAttribute("DrillingUntil") or 0) > serverNow
		end
		drilling = ready and typeof(at) == "Vector3"

		-- Passage du dos aux mains
		local goal = if ready then 1 else 0
		rig.k += (goal - rig.k) * math.min(1, dt * 9)
		local e = smooth(math.clamp(rig.k, 0, 1))

		-- Direction de la mèche (repère du torse) : vers le point d'impact, toujours devant et vers le bas
		local holdWorld = torso.CFrame * HOLD
		local aim = DEFAULT_AIM
		if drilling and at then
			local d = torso.CFrame:VectorToObjectSpace((at :: Vector3) - holdWorld)
			if d.Magnitude > 0.1 then
				d = d.Unit
				aim = Vector3.new(d.X, math.min(d.Y, 0.2), math.min(d.Z, -0.15)).Unit
			end
		end
		rig.aim = rig.aim:Lerp(aim, math.min(1, dt * 10)).Unit

		-- Marteau-piqueur : pompe le long de la mèche et tremble
		local pump, shake = Vector3.zero, CFrame.new()
		if drilling then
			pump = rig.aim * (math.sin(t * 32) * 0.12)
			shake = CFrame.Angles((math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05, (math.random() - 0.5) * 0.05)
		end
		local hold = CFrame.new(HOLD + pump) * rotFromTo(DOWN, rig.aim) * CFrame.Angles(0, math.pi, 0) * shake
		weld.C0 = rig.carry:Lerp(hold, e)

		-- Mèche qui tourne (vite en forant, doucement quand on est prêt)
		local spinGoal = if drilling then 38 elseif ready then 6 else 0
		rig.spinSpeed += (spinGoal - rig.spinSpeed) * math.min(1, dt * 4)
		rig.spin = (rig.spin + rig.spinSpeed * dt) % (math.pi * 2)
		if rig.bitWeld then
			rig.bitWeld.C0 = rig.bitBase * CFrame.Angles(0, rig.spin, 0)
		end

		-- Bras vers les poignées, buste penché qui vibre (R15)
		if e > 0.02 and rig.drill then
			local handle = body:FindFirstChild("Handle") :: Attachment?
			local center = if handle then handle.WorldPosition else body.Position
			local scale = rig.drill:GetScale()
			local side = body.CFrame.RightVector * GRIP * scale * 0.85
			local right = part(character, "RightUpperArm")
			local g1, g2 = center + side, center - side
			local rightGrip, leftGrip = g1, g2
			if right and (g2 - right.Position).Magnitude < (g1 - right.Position).Magnitude then
				rightGrip, leftGrip = g2, g1
			end
			aimArm(motor(character, "RightUpperArm", "RightShoulder"), motor(character, "RightLowerArm", "RightElbow"), rightGrip, e, 0.45)
			aimArm(motor(character, "LeftUpperArm", "LeftShoulder"), motor(character, "LeftLowerArm", "LeftElbow"), leftGrip, e, 0.45)
			local waist = motor(character, "UpperTorso", "Waist")
			if waist then
				local lean = -0.18 * e + (if drilling then math.sin(t * 32) * 0.03 else 0)
				waist.Transform = waist.Transform * CFrame.Angles(lean, 0, 0)
			end
		end

		-- Effets au point d'impact
		if drilling and rig.tip then
			local fx = rig.fx or makeFx(rig)
			rig.fx = fx
			local point = at :: Vector3
			local back = (holdWorld - point)
			back = if back.Magnitude > 0.01 then back.Unit else Vector3.yAxis
			fx.contact.WorldCFrame = CFrame.lookAt(point, point + back)
			setFx(fx, true)
			fx.light.Brightness = 1.5 + math.random() * 1.5
			-- Un coup de marteau toutes les ~0,2 s (une période de la pompe) : grosse gerbe
			local stroke = math.floor(t * 32 / (math.pi * 2))
			if stroke ~= rig.stroke then
				rig.stroke = stroke
				fx.sparks:Emit(22)
				fx.stars:Emit(6)
				fx.chips:Emit(6)
			end
			-- Faisceau visible seulement si la mèche ne touche pas la roche
			local gap = (rig.tip.WorldPosition - point).Magnitude
			fx.core.Enabled = gap > 1.2
			fx.outer.Enabled = gap > 1.2
			fx.core.CurveSize0 = (math.random() - 0.5) * gap * 0.25
			fx.core.CurveSize1 = (math.random() - 0.5) * gap * 0.25
			fx.outer.CurveSize0 = fx.core.CurveSize0
			fx.outer.CurveSize1 = fx.core.CurveSize1
			-- Couleur des éclats et de la poussière : celle de l'astéroïde visé
			local target = if isMine then player:FindFirstChild("DrillTarget") :: ObjectValue? else nil
			local rock = target and target.Value :: BasePart?
			local rockColor = if rock then rock.Color else Color3.fromRGB(190, 160, 130)
			fx.chips.Color = ColorSequence.new(rockColor, rockColor:Lerp(Color3.new(0, 0, 0), 0.35))
			fx.dust.Color = ColorSequence.new(rockColor:Lerp(Color3.new(1, 1, 1), 0.35))
		elseif rig.fx then
			setFx(rig.fx, false)
		end

		-- Son propre forage : on se tourne vers la roche, la caméra tremble
		if isMine then
			local hum = character:FindFirstChildOfClass("Humanoid")
			local root = part(character, "HumanoidRootPart")
			if hum and root then
				if drilling and at then
					hum.AutoRotate = false
					local flat = Vector3.new((at :: Vector3).X, root.Position.Y, (at :: Vector3).Z)
					if (flat - root.Position).Magnitude > 0.5 then
						local want = CFrame.lookAt(root.Position, flat)
						root.CFrame = root.CFrame:Lerp(want, math.min(1, dt * 10))
					end
					hum.CameraOffset = Vector3.new((math.random() - 0.5) * 0.12, (math.random() - 0.5) * 0.12, 0)
				else
					hum.AutoRotate = true
					hum.CameraOffset = Vector3.zero
				end
			end
		end
	end
end)
