-- Copie du vrai modèle d'œuf (ReplicatedStorage.Assets.Eggs.R<anneau>_T<rareté>) pour les effets :
-- œuf qui jaillit de la roche au forage, œuf révélé par la machine à dérocher.
-- La copie n'a ni le tag « Egg » (pas d'animation de vitrine), ni les effets du modèle
-- (rayons, aura, étincelles dimensionnés pour sa grande taille) : chaque effet ajoute les siens.
-- Son pivot est le centre du corps (« Core »). EggModel.SetHeight change sa taille à tout moment.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local EggModel = {}

local function folder(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("Eggs")
end

-- Œuf de secours (modèle absent) : un ovale de la couleur de la rareté
local function fallback(rarity: number): Model
	local m = Instance.new("Model")
	local p = Instance.new("Part")
	p.Name = "Core"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one
	p.Material = Enum.Material.SmoothPlastic
	p.Color = (Config.Rarities[rarity] or Config.Rarities[1]).Color
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1.3, 1)
	mesh.Parent = p
	p.Parent = m
	m.PrimaryPart = p
	m:SetAttribute("BodyHeight", 1.3)
	return m
end

-- Nouvelle copie de l'œuf, haute de height studs (hauteur du corps, sans les ornements)
function EggModel.Make(ring: number, rarity: number, height: number): Model
	local f = folder()
	local template = f and f:FindFirstChild(("R%d_T%d"):format(ring, rarity))
	local m: Model
	if template and template:IsA("Model") and template.PrimaryPart then
		m = template:Clone()
		CollectionService:RemoveTag(m, "Egg")
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("ParticleEmitter") or d:IsA("BillboardGui") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
			end
		end
	else
		m = fallback(rarity)
	end
	m.Name = "EggFx"
	m:SetAttribute("BaseScale", m:GetScale())
	EggModel.SetHeight(m, height)
	return m
end

-- Change la taille de la copie (hauteur du corps en studs)
function EggModel.SetHeight(m: Model, height: number)
	local base = (m:GetAttribute("BaseScale") or 1) :: number
	local body = (m:GetAttribute("BodyHeight") or 1) :: number
	local s = base * math.max(height, 0.05) / body
	if math.abs(m:GetScale() - s) > 1e-3 then
		m:ScaleTo(s)
	end
end

-- Centre du corps (porte la lumière, les halos et la traînée des effets)
function EggModel.Core(m: Model): BasePart
	return (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) :: BasePart
end

return EggModel
