-- Créatures qui vivent dans les bases (tag « Creature », modèle 3D « Body » posé par HatchService).
-- Chaque espèce a sa façon de bouger (Config.CreatureMotion) :
--   trot, hop, waddle, slither, scuttle, stomp, fly, swim, float, flop
-- et une figure qu'elle fait de temps en temps (spin, flip, roar, pounce, charge, sit, pulse, glitch,
-- flame, dive, strike, slide, stomp), avec étirement et écrasement du corps (squash & stretch).
-- Elle se promène autour de son socle : va vers un point, s'arrête, regarde autour d'elle, repart.
-- Tout dépend de l'heure du serveur et de l'identifiant de la créature : tous les joueurs la voient
-- faire la même chose au même endroit, sans réseau.
-- Les anciennes créatures en pièces gardent leurs groupes animés (Tail, WingL / WingR, Orbit).
-- Les rares brillent : lumière et étincelles (Epic+), aura (Legendary+), particules qui montent (Mythic+).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local camera = workspace.CurrentCamera
local H = Config.Hatch
local MAX_DISTANCE = 160
local SPARKLE = "rbxassetid://138922153683020"
local GLOW = "rbxassetid://103844906730878"
local TAU = math.pi * 2
local WALK = 0.45 -- part d'un cycle passée à se déplacer (le reste : pause, figure)
local DEFAULT = { Style = "trot", Trick = "spin", Speed = 1 }
local BIRTH = 1.5 -- secondes de l'animation de naissance

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- EFFETS ------------------------------------------------------------------------------------

-- Effets permanents à la taille de la créature (au centre du corps, ils la suivent)
local function addFx(core: BasePart, rarity: number, h: number)
	if rarity < 4 or core:FindFirstChild("PetFx") then
		return
	end
	local color = (Config.Rarities[rarity] or Config.Rarities[1]).Color
	local at = Instance.new("Attachment")
	at.Name = "PetFx"
	at.Position = Vector3.new(0, h * 0.5, 0)
	at.Parent = core
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = h * 1.6
	light.Brightness = 0.5 + (rarity - 4) * 0.35
	light.Parent = at
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = SPARKLE
	sp.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	sp.Size = NumberSequence.new({ kp(0, 0), kp(0.3, h * 0.07), kp(1, 0) })
	sp.Lifetime = NumberRange.new(0.8, 1.4)
	sp.Rate = 3 + (rarity - 4) * 5
	sp.Speed = NumberRange.new(0.5, 1.5)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.RotSpeed = NumberRange.new(-120, 120)
	sp.LightEmission = 1
	sp.LightInfluence = 0
	sp.Shape = Enum.ParticleEmitterShape.Sphere
	sp.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	sp.Parent = at
	if rarity >= 5 then
		local au = Instance.new("ParticleEmitter")
		au.Texture = GLOW
		au.Color = ColorSequence.new(color)
		au.Size = NumberSequence.new({ kp(0, h * 0.9), kp(1, h * 1.3) })
		au.Transparency = NumberSequence.new({ kp(0, 1), kp(0.3, 0.84), kp(1, 1) })
		au.Lifetime = NumberRange.new(1.4, 1.8)
		au.Rate = 3
		au.Speed = NumberRange.new(0)
		au.LightEmission = 0.5
		au.LightInfluence = 0
		au.LockedToPart = true
		au.ZOffset = -4
		au.Parent = at
	end
	if rarity >= 6 then
		local up = Instance.new("ParticleEmitter")
		up.Texture = SPARKLE
		up.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		up.Size = NumberSequence.new({ kp(0, h * 0.05), kp(1, 0) })
		up.Lifetime = NumberRange.new(1.5, 2.5)
		up.Rate = if rarity >= 7 then 30 else 16
		up.Speed = NumberRange.new(2, 4)
		up.EmissionDirection = Enum.NormalId.Top
		up.SpreadAngle = Vector2.new(30, 30)
		up.LightEmission = 1
		up.LightInfluence = 0
		up.Parent = at
	end
end

-- Particules ponctuelles des figures (éclat, flammes, glitch, poussière au sol)
local function makeBursts(core: BasePart, rarity: number, h: number): { [string]: ParticleEmitter }
	local color = (Config.Rarities[rarity] or Config.Rarities[1]).Color
	local at = Instance.new("Attachment")
	at.Name = "TrickFx"
	at.Position = Vector3.new(0, h * 0.45, 0)
	at.Parent = core
	local foot = Instance.new("Attachment")
	foot.Name = "FootFx"
	foot.Parent = core
	local function emitter(parent: Attachment, props: { [string]: any }): ParticleEmitter
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.LightInfluence = 0
		for k, v in pairs(props) do
			(e :: any)[k] = v
		end
		e.Parent = parent
		return e
	end
	return {
		burst = emitter(at, {
			Texture = SPARKLE,
			Color = ColorSequence.new(Color3.new(1, 1, 1), color),
			LightEmission = 1,
			Size = NumberSequence.new({ kp(0, 0), kp(0.2, h * 0.18), kp(1, 0) }),
			Lifetime = NumberRange.new(0.4, 0.8),
			Speed = NumberRange.new(h * 1.5, h * 3),
			SpreadAngle = Vector2.new(180, 180),
		}),
		flame = emitter(at, {
			Texture = GLOW,
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 70, 20)),
			LightEmission = 1,
			Size = NumberSequence.new({ kp(0, h * 0.25), kp(1, 0) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(h * 1.5, h * 2.5),
			SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Front,
		}),
		glitch = emitter(at, {
			Texture = GLOW,
			Color = ColorSequence.new(Color3.fromRGB(60, 255, 255), Color3.fromRGB(255, 60, 240)),
			LightEmission = 1,
			Size = NumberSequence.new({ kp(0, h * 0.12), kp(1, 0) }),
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(h, h * 2),
			SpreadAngle = Vector2.new(180, 180),
		}),
		dust = emitter(foot, {
			Texture = GLOW,
			Color = ColorSequence.new(Color3.fromRGB(230, 225, 240)),
			LightInfluence = 0.6,
			Size = NumberSequence.new({ kp(0, h * 0.15), kp(1, h * 0.45) }),
			Transparency = NumberSequence.new({ kp(0, 0.4), kp(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.8),
			Speed = NumberRange.new(h * 0.8, h * 1.4),
			SpreadAngle = Vector2.new(180, 10),
			Acceleration = Vector3.new(0, -h, 0),
		}),
	}
end

-- SUIVI -------------------------------------------------------------------------------------

type Group = { model: Model, offset: CFrame, root: CFrame, kind: string, side: number }
type Mesh = { part: BasePart, offset: CFrame, size: Vector3 }
-- Membre d'une créature découpée (tools/creature-rig.lua) : il tourne autour de son Joint
-- follow : pièce sans joint qui suit un membre (« Head__Glow » : yeux et cristaux lumineux de la tête)
type Limb = {
	part: BasePart,
	offset: CFrame,
	size: Vector3,
	role: string,
	joint: Vector3,
	side: number,
	phase: number,
	follow: string?,
}
type Pet = {
	body: Model,
	core: BasePart,
	home: CFrame,
	seed: number,
	height: number,
	motion: any,
	groups: { Group },
	meshes: { Mesh },
	limbs: { Limb },
	head: Limb?,
	fx: { [string]: ParticleEmitter },
	lastTrick: number,
	lastStep: number,
	born: number?, -- vient d'éclore (heure serveur) : elle jaillit de l'œuf
	spinBirth: boolean,
}

local pets: { [Model]: Pet } = {}

-- Hasard reproductible (même résultat chez tous les clients)
local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

local function seedOf(id: string): number
	local h = 0
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 100000
	end
	return h
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Point visé pendant le k-ième aller (k multiple de 4 : retour au socle)
local function spot(p: Pet, k: number): Vector3
	if k % 4 == 0 then
		return Vector3.zero
	end
	local a = hash(p.seed + k * 7.1) * TAU
	local giant = math.clamp(H.WanderFullHeight / p.height, 0.25, 1) -- les géantes restent près de leur socle
	local r = H.WanderRadius * (0.45 + 0.55 * hash(p.seed * 3 + k)) * math.clamp(p.motion.Speed, 0.6, 1.5) * giant
	return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

local function track(m: Instance)
	if not m:IsA("Model") or pets[m] or not m:GetAttribute("Has3D") then
		return
	end
	local body = m:WaitForChild("Body", 10) :: Model?
	local core = body and body:WaitForChild("Core", 10) :: BasePart?
	if not body or not core or pets[m] then
		return
	end
	task.wait(0.2) -- laisse arriver toutes les pièces
	local h = (body:GetAttribute("Height") or 3) :: number
	local rarity = (m:GetAttribute("Rarity") or 1) :: number
	local p: Pet = {
		body = body,
		core = core,
		home = core.CFrame,
		seed = seedOf((m:GetAttribute("ItemId") or m.Name) :: string),
		height = h,
		motion = Config.CreatureMotion[(m:GetAttribute("Species") or m:GetAttribute("Creature") or "") :: string] or DEFAULT,
		groups = {},
		meshes = {},
		limbs = {},
		fx = {},
		lastTrick = -1,
		lastStep = -1,
		born = m:GetAttribute("BornAt") :: number?,
		spinBirth = rarity >= 4,
	}
	local ANIMATED = { Tail = true, WingL = true, WingR = true, Orbit = true }
	-- Pièces du corps (étirées avec lui) : toutes celles qui ne sont pas dans un groupe animé,
	-- même rangées dans un sous-modèle (les modèles générés par l'IA le sont)
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("BasePart") and d ~= core then
			local group = d:FindFirstAncestorWhichIsA("Model")
			local role = d:GetAttribute("Role") :: string?
			local joint = d:FindFirstChild("Joint") :: Attachment?
			local follow = d:GetAttribute("Follow") :: string?
			if follow then
				table.insert(p.limbs, {
					part = d,
					offset = core.CFrame:ToObjectSpace(d.CFrame),
					size = d.Size,
					role = "Follow",
					joint = Vector3.zero,
					side = 0,
					phase = 0,
					follow = follow,
				})
			elseif role and role ~= "Body" and joint then
				-- membre animé : pattes, bras, ailes, nageoires, oreilles, queue, tête, mâchoire, tentacules
				local side = if role:sub(-1) == "L" then -1 elseif role:sub(-1) == "R" then 1 else 0
				local limb: Limb = {
					part = d,
					offset = core.CFrame:ToObjectSpace(d.CFrame),
					size = d.Size,
					role = role,
					joint = core.CFrame:PointToObjectSpace(joint.WorldPosition),
					side = side,
					-- pas en diagonale (trot) : avant gauche avec arrière droite ; une paire de pattes
					-- non séparée (LegF, LegB) bat en opposition avec l'autre paire
					phase = if role == "LegFR"
							or role == "LegBL"
							or role == "LegR"
							or role == "LegB"
						then math.pi
						else 0,
				}
				table.insert(p.limbs, limb)
				if role == "Head" then
					p.head = limb
				end
			elseif group == body or not ANIMATED[(group :: Model).Name] then
				table.insert(p.meshes, { part = d, offset = core.CFrame:ToObjectSpace(d.CFrame), size = d.Size })
			end
		end
	end
	-- la mâchoire et les oreilles suivent la tête : on anime la tête d'abord, les pièces qui suivent en dernier
	local function order(l: Limb): number
		return if l.role == "Head" then 0 elseif l.follow then 2 else 1
	end
	table.sort(p.limbs, function(a, b)
		return order(a) < order(b)
	end)
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("Model") and ANIMATED[child.Name] then
			local cf, size = child:GetBoundingBox()
			local rel = core.CFrame:ToObjectSpace(cf)
			local g: Group = {
				model = child,
				offset = core.CFrame:ToObjectSpace(child:GetPivot()),
				root = CFrame.new(),
				kind = child.Name,
				side = 1,
			}
			if child.Name == "WingL" or child.Name == "WingR" then
				g.side = if rel.Position.X >= 0 then 1 else -1
				g.root = CFrame.new(rel.Position - Vector3.new(g.side * size.X * 0.45, 0, 0))
			elseif child.Name == "Tail" then
				local toBody = (Vector3.new(0, h * 0.45, 0) - rel.Position)
				g.root = CFrame.new(
					rel.Position + (if toBody.Magnitude > 0 then toBody.Unit else Vector3.zero) * size.Magnitude * 0.4
				)
			end
			table.insert(p.groups, g)
		end
	end
	addFx(core, rarity, h)
	p.fx = makeBursts(core, rarity, h)
	pets[m] = p
end

CollectionService:GetInstanceAddedSignal("Creature"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Creature"):Connect(function(m)
	pets[m :: Model] = nil
end)
for _, m in ipairs(CollectionService:GetTagged("Creature")) do
	task.spawn(track, m)
end

-- POSES -------------------------------------------------------------------------------------
-- Position (x, z) dans le repère du socle, hauteur y, cap (yaw), tangage (pitch, + = nez en l'air),
-- roulis (roll), étirement (sx, sy, sz : largeur, hauteur, longueur)
-- Pour les membres : phase des pas, gait (0 arrêté -> 1 en marche), roar (bouche ouverte, 0 -> 1),
-- act (figure en cours, 0 -> 1)
type Pose = {
	x: number,
	y: number,
	z: number,
	yaw: number,
	pitch: number,
	roll: number,
	sx: number,
	sy: number,
	sz: number,
	phase: number,
	gait: number,
	roar: number,
	act: number,
}

local function walkPose(p: Pet, pose: Pose, w: number, from: Vector3, to: Vector3, now: number)
	local mo = p.motion
	local h = p.height
	local style = mo.Style
	local dir = to - from
	local dist = dir.Magnitude
	local side = if dist > 0.01 then Vector3.new(-dir.Z, 0, dir.X) / dist else Vector3.zero
	local pos = from:Lerp(to, smooth(w))
	local stride = math.max(0.3, h * 0.35)
	local sp = w * dist / stride * math.pi -- phase des pas
	if style == "trot" then
		pose.y = math.abs(math.sin(sp)) * h * 0.06
		pose.pitch = math.sin(sp * 2) * 0.05
		pose.roll = math.sin(sp) * 0.04
		pose.sy = 1 + math.sin(sp * 2) * 0.03
	elseif style == "hop" then
		local hops = math.max(1, math.ceil(dist / (h * 0.6)))
		local hw = w * hops
		local i = math.floor(hw)
		local fr = hw - i
		pos = from:Lerp(to, math.clamp((i + smooth(fr)) / hops, 0, 1))
		pose.y = math.sin(fr * math.pi) * h * (mo.HopHeight or 0.35)
		local sq = mo.Squash or 1
		if fr < 0.12 or fr > 0.88 then
			pose.sy, pose.sx, pose.sz = 1 - 0.14 * sq, 1 + 0.08 * sq, 1 + 0.08 * sq
		else
			pose.sy, pose.sx, pose.sz = 1 + 0.1 * sq, 1 - 0.05 * sq, 1 - 0.05 * sq
		end
		pose.pitch = (0.5 - fr) * 0.3
	elseif style == "waddle" then
		pose.y = math.abs(math.sin(sp * 1.6)) * h * 0.03
		pose.roll = math.sin(sp * 1.6) * 0.2
		pose.yaw += math.sin(sp * 1.6) * 0.12
	elseif style == "slither" then
		local wave = w * dist / (h * 0.5) * math.pi
		pos += side * math.sin(wave) * h * 0.18
		pose.yaw += math.cos(wave) * 0.35
		pose.sz = 1 + math.sin(now * 6) * 0.07
		pose.sy = 1 - math.sin(now * 6) * 0.04
	elseif style == "scuttle" then
		pose.y = math.abs(math.sin(sp * 3)) * h * 0.035
		pose.roll = math.sin(sp * 3) * 0.06
		pose.pitch = -0.04
	elseif style == "stomp" then
		local s = math.sin(sp * 0.8)
		pose.y = math.max(0, s) * h * 0.07
		pose.roll = s * 0.07
		pose.pitch = -0.06
		pose.sy = 1 - 0.05 * (1 - math.abs(s)) ^ 6
	elseif style == "flop" then
		local flops = math.max(1, math.ceil(dist / (h * 0.4)))
		local fw = w * flops
		local fr = fw - math.floor(fw)
		pos = from:Lerp(to, math.clamp((math.floor(fw) + smooth(fr)) / flops, 0, 1))
		pose.y = math.sin(fr * math.pi) * h * 0.12
		pose.pitch = math.sin(fr * TAU) * 0.16
		pose.sz = 1 + math.sin(fr * math.pi) * 0.08
	elseif style == "fly" then
		-- penche vers l'avant, s'incline dans le virage, monte un peu en milieu de trajet
		pose.pitch = -0.18
		pose.roll = math.sin(w * math.pi) * 0.25 * (if hash(p.seed + math.floor(now / 30)) > 0.5 then 1 else -1)
		pose.y = math.sin(w * math.pi) * h * 0.15
	elseif style == "swim" then
		pose.yaw += math.sin(now * 4 + p.seed) * 0.15
		pose.roll = math.sin(now * 2 + p.seed) * 0.1
		pose.pitch = math.sin(w * TAU) * 0.08
	elseif style == "float" then
		pose.y = math.max(0, math.sin(now * 3 + p.seed)) * h * 0.08
	end
	pose.x, pose.z = pos.X, pos.Z
	pose.phase = if style == "scuttle" then sp * 3 elseif style == "waddle" then sp * 1.6 else sp
	pose.gait = math.min(1, w * 8, (1 - w) * 8)
end

local function idlePose(p: Pet, pose: Pose, g: number, now: number)
	local style = p.motion.Style
	-- regarde autour d'elle, respire
	pose.yaw += math.sin(g * 9) * 0.3 * math.sin(math.min(1, g * 4) * math.pi)
	pose.sy = 1 + math.sin(now * 2.2 + p.seed) * 0.025
	if style == "float" then
		local pulse = math.sin(now * 3 + p.seed)
		pose.sy = 1 + pulse * 0.08
		pose.sx, pose.sz = 1 - pulse * 0.05, 1 - pulse * 0.05
	elseif style == "slither" then
		pose.roll = math.sin(now * 1.6 + p.seed) * 0.06
	end
end

-- Figure (pendant la pause d'un cycle sur trois). g : avancée de la figure, 0 -> 1
local function trickPose(p: Pet, pose: Pose, g: number, now: number)
	local h = p.height
	local trick = p.motion.Trick
	local up = math.sin(g * math.pi)
	local fwdX, fwdZ = -math.sin(pose.yaw), -math.cos(pose.yaw)
	-- déplacements des figures limités : une géante ne traverse pas toute la base
	local reach = math.min(h, H.WanderFullHeight)
	pose.act = up
	if trick == "roar" or trick == "flame" or trick == "strike" then
		pose.roar = smooth(g / 0.25) * (1 - smooth((g - 0.75) / 0.25))
	end
	if trick == "spin" then
		pose.yaw += smooth(g) * TAU
		pose.y += up * h * 0.25
	elseif trick == "flip" then
		pose.pitch += smooth(g) * TAU
		pose.y += up * h * 0.6
		pose.sy = 1 + up * 0.1
	elseif trick == "roar" then
		local a = smooth(g / 0.25) * (1 - smooth((g - 0.75) / 0.25))
		pose.pitch += a * 0.32
		pose.sx, pose.sy, pose.sz = 1 + a * 0.06, 1 + a * 0.1, 1 + a * 0.06
		if g > 0.25 and g < 0.75 then
			pose.roll += math.sin(now * 40) * 0.03
		end
	elseif trick == "pounce" then
		local crouch = smooth(g / 0.3) * (1 - smooth((g - 0.3) / 0.1))
		local leap = math.clamp((g - 0.35) / 0.4, 0, 1)
		local back = smooth((g - 0.75) / 0.25)
		pose.sy = 1 - crouch * 0.15
		pose.y += math.sin(leap * math.pi) * h * 0.5
		local d = smooth(leap) * (1 - back) * reach * 0.8
		pose.x += fwdX * d
		pose.z += fwdZ * d
		pose.pitch += (0.5 - leap) * 0.4 * math.sin(leap * math.pi)
	elseif trick == "charge" then
		local d = (smooth(g / 0.35) - smooth((g - 0.5) / 0.5)) * reach * 1.2
		pose.x += fwdX * d
		pose.z += fwdZ * d
		pose.pitch -= 0.12 * math.sin(math.clamp(g / 0.5, 0, 1) * math.pi)
	elseif trick == "sit" then
		local a = smooth(g / 0.2) * (1 - smooth((g - 0.8) / 0.2))
		pose.pitch += a * 0.3
		pose.sy = 1 - a * 0.1
		pose.y -= a * h * 0.03
	elseif trick == "pulse" then
		local pulse = math.sin(g * TAU * 3) * up
		pose.sy = 1 + pulse * 0.25
		pose.sx, pose.sz = 1 - pulse * 0.15, 1 - pulse * 0.15
		pose.y += math.max(0, pulse) * h * 0.1
	elseif trick == "glitch" then
		if g > 0.1 and g < 0.9 then
			local tick = math.floor(now * 12)
			pose.x += (hash(tick + p.seed) - 0.5) * reach * 0.6
			pose.z += (hash(tick * 3 + p.seed) - 0.5) * reach * 0.6
			pose.yaw += (hash(tick * 7 + p.seed) - 0.5) * 1.5
			pose.sx = 1 + (hash(tick * 5) - 0.5) * 0.4
		end
	elseif trick == "flame" then
		local a = smooth(g / 0.2) * (1 - smooth((g - 0.7) / 0.3))
		pose.pitch += a * 0.25
		pose.sy = 1 + a * 0.06
	elseif trick == "dive" then
		pose.y -= up * h * (p.motion.Hover or 0.4) * 0.9
		pose.pitch -= math.cos(g * math.pi) * 0.4 * up
	elseif trick == "strike" then
		local a = math.clamp((g - 0.3) / 0.15, 0, 1) * (1 - smooth((g - 0.5) / 0.3))
		local coil = smooth(g / 0.3) * (1 - a)
		pose.sz = 1 - coil * 0.2 + a * 0.25
		pose.x += fwdX * a * reach * 0.5
		pose.z += fwdZ * a * reach * 0.5
		pose.pitch += coil * 0.2
	elseif trick == "slide" then
		local a = smooth(g / 0.2) * (1 - smooth((g - 0.8) / 0.2))
		pose.pitch -= a * 1.3
		pose.y += a * h * 0.15
		local d = smooth((g - 0.15) / 0.65) * (1 - smooth((g - 0.85) / 0.15)) * reach * 1.2
		pose.x += fwdX * d
		pose.z += fwdZ * d
	elseif trick == "stomp" then
		local jump = math.clamp(g / 0.6, 0, 1)
		pose.y += math.sin(jump * math.pi) * h * 0.8
		local land = math.clamp((g - 0.6) / 0.15, 0, 1) * (1 - smooth((g - 0.75) / 0.25))
		pose.sy = 1 - land * 0.25 + (if jump < 1 then math.sin(jump * math.pi) * 0.1 else 0)
		pose.sx, pose.sz = 1 + land * 0.15, 1 + land * 0.15
	end
end

local function fireTrick(p: Pet)
	local trick = p.motion.Trick
	local fx = p.fx
	if trick == "flame" and fx.flame then
		fx.flame:Emit(30)
	elseif trick == "glitch" and fx.glitch then
		fx.glitch:Emit(25)
	elseif (trick == "charge" or trick == "stomp" or trick == "pounce") and fx.dust then
		fx.dust:Emit(16)
	elseif fx.burst then
		fx.burst:Emit(if trick == "roar" then 30 else 14)
	end
end

-- MEMBRES -----------------------------------------------------------------------------------
-- Rotation d'un membre autour de son joint, dans le repère de la créature (avant = -Z, gauche = -X).
-- Angles(a, 0, 0) : a > 0 lance une patte vers l'avant, relève le museau ; Angles(0, 0, c) côté
-- gauche (side -1) : c < 0 lève l'aile ou le bras.
local function limbRotation(p: Pet, l: Limb, pose: Pose, now: number): CFrame
	local role = l.role
	local style = p.motion.Style
	local s = l.side
	local seed = p.seed
	local walk = pose.gait
	local flying = style == "fly" or style == "swim" or style == "float"
	local kind = role:sub(1, 3)
	if kind == "Leg" then
		if flying then
			-- pattes repliées vers l'arrière, qui pédalent un peu
			return CFrame.Angles(-0.45 + math.sin(now * 3 + l.phase + seed) * 0.08, 0, 0)
		end
		-- amplitudes modérées : au-delà, la découpe des pattes laisse voir une fente au niveau de l'épaule
		local amp = if style == "stomp"
			then 0.26
			elseif style == "scuttle" then 0.4
			elseif style == "waddle" then 0.22
			else 0.32
		local a = math.sin(pose.phase + l.phase) * amp * walk
		-- au repos : petit piétinement de temps en temps
		a += math.sin(now * 7 + l.phase + seed) * 0.05 * (1 - walk) * math.max(0, math.sin(now * 0.6 + seed))
		return CFrame.Angles(a, 0, if style == "waddle" then s * 0.08 * walk else 0)
	elseif kind == "Arm" then
		local swing = -math.sin(pose.phase + (if s < 0 then 0 else math.pi)) * 0.4 * walk
		local idle = math.sin(now * 2 + seed + s) * 0.07
		local raise = s * 1.1 * pose.roar
		return CFrame.Angles(swing + idle - pose.roar * 0.4, 0, raise - s * 0.05)
	elseif kind == "Win" then
		local flap
		if flying then
			local beat = if p.motion.Flutter then 18 else 9
			flap = math.sin(now * beat + seed) * 0.65 + 0.15
		else
			-- au sol : ailes posées qui respirent, grand battement pendant une figure
			flap = math.sin(now * 2 + seed) * 0.08 + pose.act * (0.35 + math.sin(now * 11) * 0.45)
		end
		return CFrame.Angles(0, 0, s * flap)
	elseif kind == "Fin" then
		return CFrame.Angles(0, 0, s * (math.sin(now * 4 + seed) * 0.3 + 0.05))
	elseif kind == "Ear" then
		-- petit frémissement toutes les quelques secondes
		local twitch = math.max(0, math.sin(now * 0.9 + seed * 2)) ^ 12
		return CFrame.Angles(0, 0, s * 0.3 * math.sin(now * 30) * twitch)
	elseif role == "Tail" then
		local wag = math.sin(now * (5 + 4 * walk) + seed) * (0.3 + 0.15 * walk)
		return CFrame.Angles(math.sin(now * 2 + seed) * 0.1 - pose.roar * 0.3, wag, 0)
	elseif role == "Head" then
		-- regarde autour d'elle à l'arrêt, hoche la tête en marchant, relève le museau pour rugir
		-- amplitudes faibles : la tête est découpée dans le modèle, tourner fort ouvrirait le cou
		local look = math.sin(now * 0.7 + seed) * 0.16 * (1 - walk) * (1 - pose.act)
		local nod = math.sin(pose.phase * 2) * 0.05 * walk + math.sin(now * 2.2 + seed) * 0.025
		return CFrame.Angles(nod + pose.roar * 0.2, look, math.sin(now * 0.5 + seed) * 0.04 * (1 - walk))
	elseif role == "Jaw" then
		-- bouche : grande ouverture pour rugir, petit mâchonnement de temps en temps
		local chomp = math.max(0, math.sin(now * 0.8 + seed * 3)) ^ 20 * (0.5 + 0.5 * math.sin(now * 18))
		return CFrame.Angles(-(pose.roar * 0.55 + chomp * 0.22), 0, 0)
	elseif role == "Tentacles" then
		return CFrame.Angles(math.sin(now * 3 + seed) * 0.12, 0, math.cos(now * 2.6 + seed) * 0.12)
	end
	return CFrame.new()
end

-- BOUCLE ------------------------------------------------------------------------------------

local moveParts: { BasePart } = {}
local moveCFrames: { CFrame } = {}

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local camPos = camera.CFrame.Position
	table.clear(moveParts)
	table.clear(moveCFrames)
	for m, p in pairs(pets) do
		if not m.Parent or not p.body.Parent then
			pets[m] = nil
			continue
		end
		if (p.home.Position - camPos).Magnitude > MAX_DISTANCE then
			continue
		end
		local mo = p.motion
		local h = p.height
		local period = H.WanderPeriod * (0.85 + 0.3 * hash(p.seed)) / math.clamp(mo.Speed, 0.3, 2)
		local t = now / period + hash(p.seed + 1)
		local k = math.floor(t)
		local f = t - k
		local from, to = spot(p, k - 1), spot(p, k)
		local pose: Pose = {
			x = from.X,
			y = 0,
			z = from.Z,
			yaw = 0,
			pitch = 0,
			roll = 0,
			sx = 1,
			sy = 1,
			sz = 1,
			phase = 0,
			gait = 0,
			roar = 0,
			act = 0,
		}
		-- cap : celui du trajet en cours (on le garde pendant la pause)
		local d = to - from
		if d.Magnitude > 0.05 then
			pose.yaw = math.atan2(-d.X, -d.Z) + (if mo.Sideways then math.pi / 2 else 0)
		end
		if f < WALK then
			walkPose(p, pose, f / WALK, from, to, now)
			-- poussière à chaque pas lourd
			if mo.Style == "stomp" and p.fx.dust then
				local step = math.floor((f / WALK) * d.Magnitude / math.max(0.3, h * 0.35) * 0.8)
				if step ~= p.lastStep then
					p.lastStep = step
					p.fx.dust:Emit(4)
				end
			end
		else
			pose.x, pose.z = to.X, to.Z
			local g = (f - WALK) / (1 - WALK)
			idlePose(p, pose, g, now)
			if (k + math.floor(p.seed)) % 3 == 1 then
				local tg = math.clamp((g - 0.15) / 0.6, 0, 1)
				if tg > 0 and tg < 1 then
					trickPose(p, pose, tg, now)
					if p.lastTrick ~= k and tg > 0.25 then
						p.lastTrick = k
						fireTrick(p)
					end
				end
			end
		end
		-- naissance : surgit de l'œuf (rebond de taille), saute de joie, puis rejoint sa promenade
		local born = p.born
		if born then
			local age = now - born
			if age > BIRTH or age < -1 then
				p.born = nil
			elseif age >= 0 then
				local pop = math.clamp(age / 0.55, 0, 1) - 1
				local s = math.max(0.02, 1 + 2.70158 * pop ^ 3 + 1.70158 * pop ^ 2) -- Back Out : 0 -> 1,1 -> 1
				pose.sx *= s
				pose.sy *= s
				pose.sz *= s
				pose.y += h * 0.45 * math.sin(math.pi * math.clamp(age / 0.8, 0, 1))
				local w = smooth((age - 0.9) / 0.6)
				pose.x *= w
				pose.z *= w
				if p.spinBirth then
					pose.yaw += (1 - smooth(age / 1.0)) * TAU
				end
			else
				pose.sx, pose.sy, pose.sz = 0.02, 0.02, 0.02
			end
		end
		-- vol / nage / flottement : en l'air, avec un battement
		local style = mo.Style
		if style == "fly" or style == "swim" or style == "float" then
			local hover = (mo.Hover or 0.4) * h
			local beat = if style == "fly" then (if mo.Flutter then 14 else 7) else 1.6
			pose.y += hover + math.sin(now * beat + p.seed) * h * (if style == "fly" then 0.04 else 0.06)
		end
		-- tangage et roulis autour du milieu du corps ; étirement depuis les pieds
		local base = p.home * CFrame.new(pose.x, pose.y, pose.z) * CFrame.Angles(0, pose.yaw, 0)
		local center = CFrame.new(0, h * 0.5, 0)
		local pivot = base * center * CFrame.Angles(pose.pitch, 0, pose.roll) * center:Inverse()
		local scale = Vector3.new(pose.sx, pose.sy, pose.sz)
		table.insert(moveParts, p.core)
		table.insert(moveCFrames, pivot)
		for _, mesh in ipairs(p.meshes) do
			local o = mesh.offset
			table.insert(moveParts, mesh.part)
			table.insert(moveCFrames, pivot * CFrame.new(o.Position * scale) * o.Rotation)
			local want = mesh.size * scale
			if (mesh.part.Size - want).Magnitude > 1e-3 then
				mesh.part.Size = want
			end
		end
		-- membres : chacun tourne autour de son joint ; la mâchoire et les oreilles suivent la tête,
		-- les pièces « Follow » suivent leur membre
		local turns: { [string]: CFrame } = {}
		for _, l in ipairs(p.limbs) do
			local turn
			if l.follow then
				turn = turns[l.follow] or CFrame.new()
			else
				local j = l.joint * scale
				turn = CFrame.new(j) * limbRotation(p, l, pose, now) * CFrame.new(-j)
				if (l.role == "Jaw" or l.role:sub(1, 3) == "Ear") and turns["Head"] then
					turn = turns["Head"] * turn
				end
				turns[l.role] = turn
			end
			local o = l.offset
			table.insert(moveParts, l.part)
			table.insert(moveCFrames, pivot * turn * CFrame.new(o.Position * scale) * o.Rotation)
			local want = l.size * scale
			if (l.part.Size - want).Magnitude > 1e-3 then
				l.part.Size = want
			end
		end
		for _, gr in ipairs(p.groups) do
			local cf
			if gr.kind == "Orbit" then
				cf = pivot * CFrame.Angles(0, now * 1.2, 0) * gr.offset
			elseif gr.kind == "WingL" or gr.kind == "WingR" then
				local a = math.sin(now * 9 + p.seed) * 0.35 * gr.side
				cf = pivot * gr.root * CFrame.Angles(0, 0, a) * gr.root:Inverse() * gr.offset
			elseif gr.kind == "Tail" then
				local a = math.sin(now * 6 + p.seed) * 0.3
				cf = pivot * gr.root * CFrame.Angles(0, a, 0) * gr.root:Inverse() * gr.offset
			else
				cf = pivot * gr.offset
			end
			gr.model:PivotTo(cf)
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
