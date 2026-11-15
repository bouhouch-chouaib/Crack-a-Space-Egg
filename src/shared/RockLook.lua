-- Apparence des 3 types d'astéroïdes de chaque anneau (Config.RockTypes) : une forme par type
-- (ReplicatedStorage.Assets.Asteroids.Ring<n>.<Shape>) et sa matière : la roche de l'anneau telle
-- quelle, une roche d'argent, une roche d'or (les mêmes dans tous les anneaux, pour qu'on les reconnaisse
-- de loin sans rien lire). Les picots restent par-dessus.
-- Sert au serveur (BeltService) et aux aperçus de l'interface (IndexUI.client).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local RockLook = {}

-- Modèle d'origine de ce type dans cet anneau (à cloner) ; à défaut, une autre forme de l'anneau
function RockLook.Template(ring: number, rockType: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Asteroids")
	local set = folder and folder:FindFirstChild("Ring" .. ring)
	if not set then
		return nil
	end
	if set:IsA("Model") then
		return set
	end
	local shape = set:FindFirstChild(Config.RockType(rockType).Shape)
	if shape and shape:IsA("Model") and shape.PrimaryPart then
		return shape
	end
	for _, v in ipairs(set:GetChildren()) do
		if v:IsA("Model") and v.PrimaryPart then
			return v
		end
	end
	return nil
end

-- Donne à un astéroïde (déjà cloné) la matière de son type : sa texture d'anneau laisse place à une
-- couleur unie (argent, or). Le premier type garde la roche de l'anneau.
function RockLook.Apply(model: Model, rockType: number)
	local def = Config.RockType(rockType)
	if not def.Color then
		return
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
			d.Color = def.Color
			d.Material = Enum.Material.SmoothPlastic
			d.Reflectance = def.Reflect or 0
		end
	end
end

return RockLook
