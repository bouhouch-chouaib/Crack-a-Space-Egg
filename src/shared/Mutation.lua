-- Apparence d'une créature mutée (Config.Mutations) : tout son corps prend la matière et la couleur de la
-- mutation (argent, or, émeraude, rubis), comme les « golden pets » des jeux de créatures : on la reconnaît
-- de loin, sans lire. Les pièces lumineuses (yeux, cristaux) gardent leur lueur.
-- Rainbow : chaque pièce a sa teinte de départ, et MutationFx.client fait défiler les couleurs.
-- Sert au serveur (HatchService, créature posée dans la base) et aux portraits de l'interface.

local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.Config)

local Mutation = {}

Mutation.RainbowTag = "RainbowPart"

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

return Mutation
