-- Jetpack : vol, effets et pose du joueur.
-- VOL (joueur local) : maintenir Saut en l'air pousse vers le haut (carburant) ; relâché, on plane
-- (chute freinée). La direction se pilote au clavier / joystick, à la vitesse en vol (AirSpeed),
-- avec de l'inertie. Au sol, on marche à la vitesse au sol (GroundSpeed). Carburant rechargé au sol.
-- Les vitesses viennent du serveur (attributs GroundSpeed / AirSpeed, amélioration Jetpack).
-- EFFETS (tous les joueurs) : sur les deux tuyères du jetpack porté (Assets.Jetpack, soudé au dos
-- par le serveur) : cœur de flamme, flamme, fumée, étincelles, traînée lumineuse, lumière ;
-- poussière au décollage et à l'atterrissage. L'état (0 éteint, 1 poussée, 2 plané) passe par le
-- serveur (Remotes.JetState -> attribut « Jet » du personnage) pour que tout le monde le voie.
-- POSE (tous les joueurs) : en vol, le corps se penche dans le sens du déplacement, s'incline dans
-- les virages, les jambes pendent et se balancent, les bras s'écartent (sauf foreuse ou œuf en main).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MV = Config.Movement

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local GLOW = "rbxassetid://103844906730878"
local SPARKLE = "rbxassetid://138922153683020"
local BASE_FOV = 70

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- EFFETS SUR LES TUYÈRES --------------------------------------------------------------------

type Nozzle = { core: ParticleEmitter, flame: ParticleEmitter, smoke: ParticleEmitter, sparks: ParticleEmitter, trail: Trail }
type Rig = {
	character: Model,
	hrp: BasePart,
	hum: Humanoid,
	nozzles: { Nozzle },
	light: PointLight?,
	dust: ParticleEmitter,
	shown: number, -- état affiché
	k: number, -- 0 au sol -> 1 en vol (pose)
	airborne: boolean,
	lastVy: number,
}

local rigs: { [Model]: Rig } = {}

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function makeNozzle(a: Attachment): Nozzle
	local core = emitter(a, {
		Texture = GLOW,
		Color = ColorSequence.new(Color3.fromRGB(220, 250, 255), Color3.fromRGB(80, 200, 255)),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.55), kp(1, 0) }),
		Lifetime = NumberRange.new(0.08, 0.14),
		Speed = NumberRange.new(10, 14),
		Rate = 70,
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(4, 4),
	})
	local flame = emitter(a, {
		Texture = FIRE,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 160)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 50, 20)),
		}),
		LightEmission = 0.45, -- plus bas : la flamme reste orange au lieu de blanchir
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.8), kp(0.5, 1.05), kp(1, 0.1) }),
		Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) }),
		Lifetime = NumberRange.new(0.18, 0.32),
		Speed = NumberRange.new(14, 20),
		Rate = 90,
		RotSpeed = NumberRange.new(-200, 200),
		Rotation = NumberRange.new(0, 360),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(9, 9),
	})
	local smoke = emitter(a, {
		Texture = SMOKE,
		Color = ColorSequence.new(Color3.fromRGB(200, 200, 215)),
		LightInfluence = 0.5,
		Size = NumberSequence.new({ kp(0, 0.6), kp(1, 2.6) }),
		Transparency = NumberSequence.new({ kp(0, 0.55), kp(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(4, 7),
		Rate = 22,
		RotSpeed = NumberRange.new(-60, 60),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(18, 18),
		Drag = 2,
	})
	local sparks = emitter(a, {
		Texture = SPARKLE,
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 110, 40)),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ kp(0, 0.25), kp(1, 0) }),
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(14, 24),
		Rate = 14,
		Acceleration = Vector3.new(0, -40, 0),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(30, 30),
	})
	-- Traînée : un ruban entre deux points de part et d'autre de la tuyère
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = a.Position + Vector3.new(0, 0.05, -0.22)
	a0.Parent = a.Parent
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = a.Position + Vector3.new(0, 0.05, 0.22)
	a1.Parent = a.Parent
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(120, 230, 255), Color3.fromRGB(255, 150, 60))
	trail.Transparency = NumberSequence.new({ kp(0, 0.15), kp(1, 1) })
	trail.WidthScale = NumberSequence.new({ kp(0, 1), kp(1, 0.2) })
	trail.Lifetime = 0.55
	trail.MinLength = 0.05
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = a.Parent
	return { core = core, flame = flame, smoke = smoke, sparks = sparks, trail = trail }
end

local function setup(character: Model)
	if rigs[character] then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local pack = character:WaitForChild("EquippedJetpack", 15) :: Model?
	if not hrp or not hum or not pack or rigs[character] then
		return
	end
	local handle = pack.PrimaryPart or pack:FindFirstChildWhichIsA("BasePart")
	if not handle then
		return
	end
	local nozzles = {}
	for _, n in ipairs({ "NozzleL", "NozzleR" }) do
		local a = handle:FindFirstChild(n) :: Attachment?
		if a then
			table.insert(nozzles, makeNozzle(a))
		end
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 70)
	light.Range = 12
	light.Brightness = 0
	light.Parent = handle
	local feet = Instance.new("Attachment")
	feet.Name = "JetDust"
	feet.Position = Vector3.new(0, -3, 0)
	feet.Parent = hrp
	local dust = emitter(feet, {
		Texture = SMOKE,
		Color = ColorSequence.new(Color3.fromRGB(235, 235, 245)),
		LightInfluence = 0.6,
		Size = NumberSequence.new({ kp(0, 1), kp(1, 3.2) }),
		Transparency = NumberSequence.new({ kp(0, 0.35), kp(1, 1) }),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(10, 16),
		SpreadAngle = Vector2.new(180, 5),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -8, 0),
		Drag = 3,
	})
	rigs[character] = {
		character = character,
		hrp = hrp,
		hum = hum,
		nozzles = nozzles,
		light = light,
		dust = dust,
		shown = -1,
		k = 0,
		airborne = false,
		lastVy = 0,
	}
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			rigs[character] = nil
		end
	end)
end

local function watch(p: Player)
	p.CharacterAdded:Connect(function(c)
		task.spawn(setup, c)
	end)
	if p.Character then
		task.spawn(setup, p.Character)
	end
end
for _, p in ipairs(Players:GetPlayers()) do
	watch(p)
end
Players.PlayerAdded:Connect(watch)

-- Allume les effets selon l'état (0 éteint, 1 poussée, 2 plané)
local function show(rig: Rig, state: number)
	if rig.shown == state then
		return
	end
	if state == 1 and rig.shown == 0 and not rig.airborne then
		rig.dust:Emit(14) -- décollage
	end
	rig.shown = state
	for _, n in ipairs(rig.nozzles) do
		n.core.Enabled = state ~= 0
		n.core.Rate = if state == 1 then 70 else 25
		n.flame.Enabled = state == 1
		n.smoke.Enabled = state == 1
		n.sparks.Enabled = state == 1
		n.trail.Enabled = state ~= 0
	end
end

-- VOL DU JOUEUR LOCAL ----------------------------------------------------------------------

local fuel = Config.JetpackFuelBase
local lastJump = 0
local sentState = 0

local function maxFuel(): number
	return Config.JetpackFuelBase + Config.JetpackFuelPerLevel * (player:GetAttribute("Lvl_Thruster") or 0)
end

-- JumpRequest se répète tant que Saut est tenu (clavier, manette, bouton tactile)
UserInputService.JumpRequest:Connect(function()
	lastJump = os.clock()
end)

player.CharacterAdded:Connect(function()
	fuel = maxFuel()
end)

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hum or not hrp then
		return
	end
	local ground = (player:GetAttribute("GroundSpeed") or MV.Walk) :: number
	local air = (player:GetAttribute("AirSpeed") or MV.Air) :: number
	local st = hum:GetState()
	local airborne = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
	-- Saut tenu : touche Espace, bouton A de la manette, bouton de saut tactile (Humanoid.Jump)
	local holding = UserInputService:IsKeyDown(Enum.KeyCode.Space)
		or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
		or hum.Jump
		or os.clock() - lastJump < 0.15
	local state = 0
	-- la vitesse de déplacement suit l'état : marche au sol, vol en l'air
	local want = if airborne then air else ground
	if math.abs(hum.WalkSpeed - want) > 0.01 then
		hum.WalkSpeed = want
	end
	if airborne then
		local v = hrp.AssemblyLinearVelocity
		local vy = v.Y
		if holding and fuel > 0 then
			-- poussée : on monte jusqu'à la vitesse de montée
			fuel = math.max(0, fuel - dt)
			vy = math.min(MV.Climb * (0.85 + 0.15 * (air / MV.Air)), math.max(vy, 0) + MV.ClimbAccel * dt)
			state = 1
		elseif fuel > 0 and vy < 0 then
			-- vol plané : la chute est freinée
			vy += workspace.Gravity * MV.FallBrake * dt
			state = 2
		end
		-- inertie : la vitesse horizontale rejoint la direction voulue en douceur
		local wantH = hum.MoveDirection * air
		local curH = Vector3.new(v.X, 0, v.Z)
		local h = curH:Lerp(wantH, 1 - math.exp(-MV.AirAccel * dt))
		hrp.AssemblyLinearVelocity = Vector3.new(h.X, vy, h.Z)
	else
		fuel = math.min(maxFuel(), fuel + Config.JetpackRefill * dt)
	end
	player:SetAttribute("Fuel", fuel / maxFuel())
	if state ~= sentState then
		sentState = state
		Remotes.JetState:FireServer(state)
	end
	local rig = rigs[character]
	if rig then
		show(rig, state)
	end
	-- la caméra s'élargit avec la vitesse
	local speed = hrp.AssemblyLinearVelocity.Magnitude
	local fov = BASE_FOV + math.clamp((speed - ground) * 0.35, 0, 16)
	camera.FieldOfView += (fov - camera.FieldOfView) * math.min(1, dt * 4)
end)

-- Si la roche sous le joueur casse, il rebondit et son jetpack est plein : il peut se rattraper
Remotes.DrillHit.OnClientEvent:Connect(function(rock: BasePart?, _by: Player, _damage: number, _rarities: { number }, broken: boolean)
	if not broken or not rock then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local s = rock.Size
	if (hrp.Position - rock.Position).Magnitude <= math.max(s.X, s.Y, s.Z) / 2 + 8 then
		fuel = maxFuel()
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 45), v.Z)
		UIKit.toast("🚀 Your rock broke! Fly to the next one", "info")
	end
end)

-- POSE EN VOL ET EFFETS DES AUTRES JOUEURS ---------------------------------------------------

local function motor(character: Model, partName: string, name: string): Motor6D?
	local p = character:FindFirstChild(partName)
	return p and p:FindFirstChild(name) :: Motor6D?
end

RunService.PreSimulation:Connect(function(dt)
	local t = os.clock()
	local camPos = camera.CFrame.Position
	for character, rig in pairs(rigs) do
		local hrp, hum = rig.hrp, rig.hum
		if not hrp.Parent then
			continue
		end
		if (hrp.Position - camPos).Magnitude > 250 then
			continue
		end
		local st = hum:GetState()
		local airborne = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
		local v = hrp.AssemblyLinearVelocity
		-- atterrissage : poussière si on arrive vite
		if rig.airborne and not airborne and rig.lastVy < -25 then
			rig.dust:Emit(10)
		end
		rig.airborne = airborne
		rig.lastVy = v.Y
		-- état des autres joueurs (le local est déjà réglé dans sa boucle)
		if character ~= player.Character then
			show(rig, (character:GetAttribute("Jet") or 0) :: number)
		end
		-- lumière qui vacille pendant la poussée
		if rig.light then
			rig.light.Brightness = if rig.shown == 1 then 2.2 + math.sin(t * 40) * 0.6 else (if rig.shown == 2 then 0.6 else 0)
		end
		-- pose : on bascule doucement vers la pose de vol
		local goal = if airborne and rig.shown ~= 0 then 1 else 0
		rig.k += (goal - rig.k) * math.min(1, dt * 6)
		local k = rig.k
		if k < 0.01 then
			continue
		end
		local cf = hrp.CFrame
		local air = (if character == player.Character then player:GetAttribute("AirSpeed") else nil) or MV.Air
		local fwd = -v:Dot(cf.LookVector) -- négatif = avance
		local side = v:Dot(cf.RightVector)
		local lean = math.clamp(-fwd / air, -0.2, 1) * 0.5 -- penché vers l'avant quand on avance
		local roll = math.clamp(side / air, -1, 1) * 0.35
		local bob = math.sin(t * 5 + hrp.Position.X) * 0.05
		local root = motor(character, "LowerTorso", "Root")
		if root then
			root.Transform *= CFrame.Angles((-lean + bob) * k, 0, -roll * k)
		end
		-- jambes : pendent, légèrement repliées, se balancent
		for i, side_ in ipairs({ { "LeftUpperLeg", "LeftHip", "LeftLowerLeg", "LeftKnee" }, { "RightUpperLeg", "RightHip", "RightLowerLeg", "RightKnee" } }) do
			local hip = motor(character, side_[1], side_[2])
			local knee = motor(character, side_[3], side_[4])
			local swing = math.sin(t * 4 + i * 1.7) * 0.12
			-- on remplace l'animation de chute de Roblox par la pose de vol
			if hip then
				hip.Transform = hip.Transform:Lerp(CFrame.Angles(-0.3 - lean * 0.3 + swing, 0, 0), k)
			end
			if knee then
				knee.Transform = knee.Transform:Lerp(CFrame.Angles(-0.5 - swing * 0.5, 0, 0), k)
			end
		end
		-- bras : écartés vers l'arrière (pas pendant le forage ni avec un œuf en main)
		local busy = character:FindFirstChild("HeldEgg") ~= nil
			or (if character == player.Character then player:GetAttribute("DrillReady") == true else (character:GetAttribute("DrillingUntil") or 0) > workspace:GetServerTimeNow())
		if not busy then
			for _, arm in ipairs({ { "LeftUpperArm", "LeftShoulder", 1 }, { "RightUpperArm", "RightShoulder", -1 } }) do
				local sh = motor(character, arm[1], arm[2])
				if sh then
					sh.Transform = sh.Transform:Lerp(CFrame.Angles(-0.35 - lean * 0.4, 0, arm[3] * -0.4), k)
				end
			end
		end
	end
end)
