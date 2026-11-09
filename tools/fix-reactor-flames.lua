-- Outil de Studio (mode édition) : remet les flammes des réacteurs au ras des tuyères (relançable).
-- Les attachements EngineLeft / EngineRight / Lift de Hull.HullGlow étaient restés à leur ancienne place
-- quand la coque a été étirée : 95 studs derrière le vaisseau et 21 studs trop bas.
-- Centres mesurés par lancer de rayons sur HullGlow : (±59, -7, -142.19), rayon 8.

local NOZZLE_Y, NOZZLE_Z = -7, -142.7 -- juste derrière le disque de la tuyère
local NOZZLE_X = 59
local LIFT = Vector3.new(0, -43, -17.3) -- sous la coque, décalé comme les réacteurs
local GLOW = "rbxassetid://103844906730878"

local function size(from: number, to: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) })
end

-- Effets à l'échelle d'une tuyère de 16 studs de large : colonne de feu, cœur blanc, halo et étincelles
local function tune(engine: Attachment)
	local core = engine:FindFirstChild("Core") :: ParticleEmitter
	core.Color = ColorSequence.new(Color3.fromRGB(235, 255, 255))
	core.LightEmission = 1
	core.Size = size(10, 1.5)
	core.Lifetime = NumberRange.new(0.35, 0.55)
	core.Speed = NumberRange.new(70, 90)
	core.Rate = 45
	local halo = engine:FindFirstChild("Halo") :: ParticleEmitter
	halo.Color = ColorSequence.new(Color3.fromRGB(70, 180, 255))
	halo.LightEmission = 1
	halo.LightInfluence = 0
	halo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
	halo.Size = size(16, 24)
	halo.Lifetime = NumberRange.new(0.7, 1.1)
	halo.Speed = NumberRange.new(25, 35)
	halo.Rate = 10
	local sparks = engine:FindFirstChild("Sparks") :: ParticleEmitter
	sparks.Size = size(1.8, 0)
	sparks.Lifetime = NumberRange.new(0.7, 1.2)
	sparks.Speed = NumberRange.new(60, 90)
	sparks.Rate = 35
	sparks.SpreadAngle = Vector2.new(12, 12)
	local plume = engine:FindFirstChild("Plume") :: ParticleEmitter?
	if not plume then
		plume = Instance.new("ParticleEmitter")
		plume.Name = "Plume"
		plume.Parent = engine
	end
	local p = plume :: ParticleEmitter
	p.Texture = GLOW
	p.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 235, 255)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(40, 170, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 70, 255)),
	})
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.42), NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(1, 1) })
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Size = size(19, 4)
	p.Lifetime = NumberRange.new(0.9, 1.2)
	p.Speed = NumberRange.new(90, 105)
	p.Rate = 110
	p.SpreadAngle = Vector2.new(1, 1)
	p.EmissionDirection = Enum.NormalId.Front
	local light = engine:FindFirstChildOfClass("PointLight")
	if light then
		light.Range = 26
		light.Brightness = 1.2
	end
end

return function(): string
	local glow = workspace.Ship.Hull.HullGlow :: BasePart
	local left = glow:FindFirstChild("EngineLeft") :: Attachment
	local right = glow:FindFirstChild("EngineRight") :: Attachment
	local lift = glow:FindFirstChild("Lift") :: Attachment
	left.WorldPosition = Vector3.new(-NOZZLE_X, NOZZLE_Y, NOZZLE_Z)
	right.WorldPosition = Vector3.new(NOZZLE_X, NOZZLE_Y, NOZZLE_Z)
	lift.WorldPosition = LIFT
	tune(left)
	tune(right)
	return "réacteurs replacés"
end
