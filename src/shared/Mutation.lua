-- Apparence d'une créature mutée (Config.Mutations) : tout son corps prend la matière et la couleur de la
-- mutation (argent, or, émeraude, rubis), comme les « golden pets » des jeux de créatures : on la reconnaît
-- de loin, sans lire. Depuis le 29 nov., la peau garde son dessin sous un voile de couleur : on voit encore
-- ses yeux, sa bouche et ses motifs (avant, la texture était retirée et la créature n'avait plus de visage),
-- et un reflet glisse sur son corps et sa tête. Les pièces lumineuses (yeux, cristaux) gardent leur lueur. Une mutation peut avoir
-- deux tons (Dark) : ses membres sont alors plus sombres que le corps, pour qu'on lise encore les formes.
-- Rainbow : chaque pièce a sa teinte de départ, et MutationFx.client fait défiler les couleurs.
-- Mutation.Effects (créature posée dans la base) : seulement une lumière douce de sa couleur, qui pulse.
-- (29 nov. : plus d'étincelles ni d'éclats en étoile autour d'elle ; tout l'effet est sur sa peau.)
-- Sert au serveur (HatchService, créature posée dans la base) et aux portraits de l'interface.

local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.Config)

local Mutation = {}

Mutation.RainbowTag = "RainbowPart"
Mutation.LightTag = "MutationLight" -- lumières qui pulsent (MutationFx.client)
Mutation.ShineTag = "MutationShine" -- reflets qui glissent sur la peau (MutationFx.client)

-- Voile de couleur (image blanche unie, teintée) et bande de reflet, posés par-dessus la texture de la créature
-- (une Texture se projette bien sur un MeshPart). Dessinés par tools/fx : Documents/Ropilot/Renders/MutationSkin.
local VEIL = "rbxassetid://116109629841075"
local SHINE = "rbxassetid://83837775330728"
local DEFAULT_VEIL = 0.27 -- transparence du voile : assez couvrant pour la couleur, assez fin pour qu'on voie les yeux
local SHINE_ALPHA = 0.3
local FACES = Enum.NormalId:GetEnumItems()

-- Membres d'une créature (début du nom de la pièce) : ils prennent la teinte sombre d'une mutation à deux tons
local LIMBS = { "Arm", "Ear", "Fin", "Jaw", "Leg", "Tail", "Tentacles", "Wing" }

local function isLimb(name: string): boolean
	for _, prefix in ipairs(LIMBS) do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

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
			-- argent : les picots ressortent en clair sur le corps
			d.Color3 = Color3.new(1, 1, 1)
		elseif d:IsA("BasePart") and d.Transparency < 1 and d.Material ~= Enum.Material.Neon then
			local limb = mut.Dark ~= nil and isLimb(d.Name)
			local color = if limb then mut.Dark else mut.Color
			local hue: number? = nil
			if mut.Rainbow then
				n += 1
				hue = (n * 0.13) % 1
				color = Mutation.RainbowColor(hue :: number, 0)
			end
			d.Material = if limb or mut.Metal then Enum.Material.Metal elseif mut.Material then (Enum.Material :: any)[mut.Material] else Enum.Material.SmoothPlastic
			d.Reflectance = mut.Reflect or 0
			if d:IsA("MeshPart") and d.TextureID ~= "" then
				-- la peau garde son dessin (yeux, bouche, motifs) et reçoit un voile de la couleur de la mutation
				for _, face in ipairs(FACES) do
					local veil = Instance.new("Texture")
					veil.Name = "Skin"
					veil.Texture = VEIL
					veil.Face = face
					veil.Color3 = color
					veil.Transparency = mut.Veil or DEFAULT_VEIL
					veil.ZIndex = 5
					if hue then
						veil:SetAttribute("Hue", hue)
						CollectionService:AddTag(veil, Mutation.RainbowTag)
					end
					veil.Parent = d
				end
				-- reflet qui passe sur le corps et la tête (MutationFx.client le fait glisser)
				if not isLimb(d.Name) then
					local tile = math.max(6, math.max(d.Size.X, d.Size.Y, d.Size.Z) * 2.2)
					for _, face in ipairs(FACES) do
						if face ~= Enum.NormalId.Bottom then
							local shine = Instance.new("Texture")
							shine.Name = "Shine"
							shine.Texture = SHINE
							shine.Face = face
							shine.Transparency = SHINE_ALPHA
							shine.StudsPerTileU = tile
							shine.StudsPerTileV = tile
							shine.ZIndex = 6
							CollectionService:AddTag(shine, Mutation.ShineTag)
							shine.Parent = d
						end
					end
				end
			else
				-- pièce sans dessin : elle prend simplement la couleur
				d.Color = color
				if hue then
					d:SetAttribute("Hue", hue)
					CollectionService:AddTag(d, Mutation.RainbowTag)
				end
			end
		end
	end
	model:SetAttribute("Mutation", mut.Key)
end

-- Lueur d'une créature mutée de hauteur h (sur sa pièce centrale, qui suit ses déplacements)
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
end

return Mutation
