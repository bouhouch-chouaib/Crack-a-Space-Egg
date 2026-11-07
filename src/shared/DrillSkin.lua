-- Applique un skin (Config.DrillSkins) à un modèle de foreuse : couleurs des pièces Body, Trim,
-- Dark, Bit et Glow, et un effet éventuel. Sert au serveur (foreuse portée) et aux aperçus de
-- l'atelier (copie dans une ViewportFrame, sans effets).
--   Attributs posés sur le modèle : Skin (clé), Accent (couleur du rayon de forage), Rainbow (bool)

local Config = require(script.Parent.Config)

local DrillSkin = {}

local PARTS = { "Body", "Trim", "Dark", "Bit", "Glow" }

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- withFx : ajoute les particules (foreuse portée) ; les aperçus n'en ont pas besoin
function DrillSkin.Apply(model: Model, key: string?, withFx: boolean?)
	local s = Config.DrillSkin(key)
	model:SetAttribute("Skin", s.Key)
	model:SetAttribute("Accent", s.Accent)
	model:SetAttribute("Rainbow", if s.Effect == "Rainbow" then true else nil)
	if s.Body then
		for _, name in ipairs(PARTS) do
			local part = model:FindFirstChild(name, true)
			local color = s[name]
			if part and part:IsA("BasePart") and color then
				part.Color = color
			end
		end
	end
	if not withFx or not s.Effect or s.Effect == "Rainbow" then
		return
	end
	local body = model.PrimaryPart or model:FindFirstChild("Body", true) :: BasePart?
	if not body then
		return
	end
	local fx = Instance.new("ParticleEmitter")
	fx.Name = "SkinFx"
	fx.LightEmission = 1
	fx.LightInfluence = 0
	if s.Effect == "Flames" then
		-- petites flammes qui montent le long du corps
		fx.Texture = Config.DrillSkinArt.Glow
		fx.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 90, 40))
		fx.Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0) })
		fx.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
		fx.Lifetime = NumberRange.new(0.35, 0.6)
		fx.Speed = NumberRange.new(1.5, 3)
		fx.Acceleration = Vector3.new(0, 4, 0)
		fx.Rate = 22
	else
		-- étincelles de la couleur du skin
		fx.Texture = Config.DrillSkinArt.Sparkle
		fx.Color = ColorSequence.new(Color3.new(1, 1, 1), s.Glow or s.Body)
		fx.Size = NumberSequence.new({ kp(0, 0), kp(0.3, 0.32), kp(1, 0) })
		fx.Lifetime = NumberRange.new(0.5, 0.9)
		fx.Speed = NumberRange.new(0.2, 0.6)
		fx.Rotation = NumberRange.new(0, 360)
		fx.RotSpeed = NumberRange.new(-90, 90)
		fx.Rate = 6
	end
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.Parent = body
end

return DrillSkin
