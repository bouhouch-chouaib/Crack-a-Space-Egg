-- Apparence d'une créature mutée (Config.Mutations) : tout son corps prend la matière et la couleur de la
-- mutation (argent, or, émeraude, rubis), comme les « golden pets » des jeux de créatures : on la reconnaît
-- de loin, sans lire. Les pièces lumineuses (yeux, cristaux) gardent leur lueur.
-- Rainbow : chaque pièce a sa teinte de départ, et MutationFx.client fait défiler les couleurs.
-- Effets de lumière (Mutation.Effects, créature posée dans la base) : une lumière de sa couleur qui
-- pulse, des étincelles et des éclats en étoile qui passent sur elle.
-- Sert au serveur (HatchService, créature posée dans la base) et aux portraits de l'interface.

local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.Config)

local Mutation = {}

Mutation.RainbowTag = "RainbowPart"
Mutation.LightTag = "MutationLight" -- lumières qui pulsent (MutationFx.client)

local SPARKLE = "rbxassetid://138922153683020" -- étincelle (comme HatchFx)
local STAR = "rbxassetid://102151511950781" -- étoile à quatre branches (Icons.Star)
local kp = NumberSequenceKeypoint.new

-- Couleur d'une pièce arc-en-ciel à l'instant t (hue : décalage de la pièce, 0 à 1)
function Mutation.RainbowColor(hue: number, t: number): Color3
	return Color3.fromHSV((hue + t * 0.25) % 1, 0.7, 1)
end

-- Applique la mutation au modèle d'une créature (déjà cloné). Sans mutation connue : ne fait rien.
function Mutation.Apply(model: Model, key: string?)
	local mut = Config.Mutation(key)
	if not mut then
		return
	end
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("SurfaceAppearance") then
			d:Destroy()
		elseif d:IsA("Texture") and d.Name == "Studs" and mut.Key == "Silver" then
			-- argent nacré : les picots ressortent en clair sur le corps
			d.Color3 = Color3.new(1, 1, 1)
		elseif d:IsA("BasePart") and d.Transparency < 1 and d.Material ~= Enum.Material.Neon then
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
			d.Material = if mut.Metal then Enum.Material.Metal else Enum.Material.SmoothPlastic
			d.Reflectance = mut.Reflect or 0
			if mut.Rainbow then
				n += 1
				local hue = (n * 0.13) % 1
				d:SetAttribute("Hue", hue)
				d.Color = Mutation.RainbowColor(hue, 0)
				CollectionService:AddTag(d, Mutation.RainbowTag)
			else
				d.Color = mut.Color
			end
		end
	end
	model:SetAttribute("Mutation", mut.Key)
end

-- Effets de lumière d'une créature mutée de hauteur h (sur sa pièce centrale, qui suit ses déplacements)
function Mutation.Effects(model: Model, key: string?, h: number)
	local mut = Config.Mutation(key)
	local core = model.PrimaryPart
	if not mut or not core then
		return
	end
	local col = mut.GlowColor or mut.Color
	local light = Instance.new("PointLight")
	light.Name = "MutationGlow"
	light.Color = col
	light.Range = math.clamp(h * 1.8, 6, 40)
	light.Brightness = mut.Glow or 1.2
	light.Shadows = false
	light:SetAttribute("Base", light.Brightness)
	light.Parent = core
	CollectionService:AddTag(light, Mutation.LightTag)
	-- étincelles tout autour du corps
	local sp = Instance.new("ParticleEmitter")
	sp.Name = "MutationSparkle"
	sp.Texture = SPARKLE
	sp.Color = ColorSequence.new(Color3.new(1, 1, 1), col)
	sp.LightEmission = 1
	sp.LightInfluence = 0
	sp.Size = NumberSequence.new({ kp(0, 0), kp(0.3, h * 0.12), kp(1, 0) })
	sp.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
	sp.Lifetime = NumberRange.new(0.7, 1.2)
	sp.Speed = NumberRange.new(h * 0.25, h * 0.55)
	sp.Drag = 2
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Rate = mut.Sparkles or 6
	local at = Instance.new("Attachment")
	at.Name = "MutationFx"
	at.Position = Vector3.new(0, h * 0.45, 0)
	at.Parent = core
	sp.Parent = at
	-- éclats en étoile : de gros reflets qui s'allument sur la créature
	local st = Instance.new("ParticleEmitter")
	st.Name = "MutationShine"
	st.Texture = STAR
	st.Color = ColorSequence.new(Color3.new(1, 1, 1), col:Lerp(Color3.new(1, 1, 1), 0.5))
	st.LightEmission = 1
	st.LightInfluence = 0
	st.Size = NumberSequence.new({ kp(0, 0), kp(0.4, h * 0.3), kp(1, 0) })
	st.Lifetime = NumberRange.new(0.45, 0.6)
	st.Speed = NumberRange.new(0)
	st.Rotation = NumberRange.new(0, 90)
	st.RotSpeed = NumberRange.new(-120, 120)
	st.Rate = mut.Shine or 1
	st.Parent = at
end

return Mutation
