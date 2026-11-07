-- Outil de Studio (mode édition) : pose les 45 minerais ReplicatedStorage.Assets.Gems.R<anneau>_T<rareté>
-- à partir des 25 types de taille faits dans Blender (tools/blender/gems.py, importés en un modèle « GemTypes »
-- dans le Workspace, ou déjà rangés dans ServerStorage.GemTypes).
-- Chaque minerai = un type + sa couleur + sa matière :
--   glass   pierre transparente (Glass)       deep    verre sombre (obsidienne, singularité)
--   opaque  opale, jade, ivoire (lisse, reflets)   pearl   perle (nacre, plus de reflets)
--   basalt  roche cristallisée (matière Basalt)
-- Pièces : Gem (la pierre), Heart (cœur Neon, gardé à partir d'Epic), Base (roche, couleur de l'anneau),
-- Setting (monture d'or). GemModel.lua (client) ajoute lumière, étincelles et teinte des brillants.

local Config = require(game.ReplicatedStorage.Shared.Config:Clone()) -- copie : pas la version en cache du plugin

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

-- { clé, type, couleur, matière, couleur du cœur (facultative) }
local GEMS = {
	-- 1. Dust Belt
	{ "R1_T1", "QuartzPoint", "#c4c6cf", "glass" }, -- Grey Quartz
	{ "R1_T2", "Rhomb", "#f3d58f", "glass" }, -- Calcite
	{ "R1_T3", "Cluster", "#9a4dff", "glass" }, -- Amethyst
	{ "R1_T4", "Pear", "#ffa928", "glass" }, -- Topaz
	{ "R1_T5", "Cabochon", "#e4f4ff", "opaque" }, -- Stellar Opal
	{ "R1_T6", "RoundBrilliant", "#e6f7ff", "glass" }, -- Pluto Diamond
	-- 2. Ice Ring
	{ "R2_T1", "Octahedron", "#a6e4ff", "glass" }, -- Frostite
	{ "R2_T2", "Star", "#f2fbff", "glass" }, -- Snow Crystal
	{ "R2_T3", "EmeraldCut", "#59dbe0", "glass" }, -- Aquamarine
	{ "R2_T4", "Cushion", "#2456ff", "glass" }, -- Boreal Sapphire
	{ "R2_T5", "TearCabochon", "#74f2ff", "opaque" }, -- Comet Tear
	{ "R2_T6", "Heart", "#3ff0a6", "glass" }, -- Aurora Heart
	-- 3. Magma Field
	{ "R3_T1", "Nugget", "#1d1b24", "deep" }, -- Obsidian
	{ "R3_T2", "CubeCluster", "#93301f", "basalt" }, -- Red Basalt
	{ "R3_T3", "Orb", "#a3102e", "glass" }, -- Garnet
	{ "R3_T4", "Oval", "#ff1d3d", "glass" }, -- Volcanic Ruby
	{ "R3_T5", "Marquise", "#ff6a14", "glass" }, -- Phoenix Eye
	{ "R3_T6", "Jewel", "#ff3a12", "glass" }, -- Sun Blood
	-- 4. Nebula
	{ "R4_T1", "QuartzPoint", "#cdb5ff", "glass" }, -- Haze Quartz
	{ "R4_T2", "Pearl", "#f3e9ff", "pearl" }, -- Mist Pearl
	{ "R4_T3", "Column", "#8b3cff", "glass" }, -- Violet Flux
	{ "R4_T4", "Cabochon", "#ff86d6", "opaque" }, -- Dreamstone
	{ "R4_T5", "Trillion", "#ff4fd2", "glass" }, -- Nova Shard
	{ "R4_T6", "Heart", "#c03cff", "glass" }, -- Nebula Heart
	-- 5. Devourer Belt
	{ "R5_T1", "Nugget", "#e6dcc4", "opaque" }, -- Bone Flint
	{ "R5_T2", "QuartzPoint", "#efe4c8", "opaque" }, -- Fang Stone
	{ "R5_T3", "Cluster", "#7c0f22", "glass" }, -- Maw Garnet
	{ "R5_T4", "Cabochon", "#49d98f", "opaque" }, -- Hunger Opal
	{ "R5_T5", "Marquise", "#9cff2a", "glass" }, -- Devourer Eye
	{ "R5_T6", "Jewel", "#5a18b0", "glass" }, -- Abyss Crown
	{ "R5_T7", "Pearl", "#2a1438", "pearl" }, -- Void Pearl
	-- 6. The Rift
	{ "R6_T1", "Rhomb", "#3c5568", "opaque" }, -- Rift Shale
	{ "R6_T2", "Nugget", "#3fb06c", "opaque" }, -- Split Jade
	{ "R6_T3", "Geode", "#2fe5ff", "glass" }, -- Fracture Gem
	{ "R6_T4", "Princess", "#1c66ff", "glass" }, -- Warp Sapphire
	{ "R6_T5", "Baguette", "#3cf2ff", "glass" }, -- Paradox Prism
	{ "R6_T6", "DoublePoint", "#ffd23a", "glass" }, -- Time Shard
	{ "R6_T7", "Orb", "#0d1c30", "deep", "#2fe5ff" }, -- Rift Singularity
	-- 7. The Nest
	{ "R7_T1", "QuartzPoint", "#fff2d6", "glass" }, -- Shell Quartz
	{ "R7_T2", "Nugget", "#ff9a14", "glass" }, -- Nest Amber
	{ "R7_T3", "Cushion", "#e3123c", "glass" }, -- Brood Ruby
	{ "R7_T4", "Cabochon", "#ffe1ef", "opaque" }, -- Mother Opal
	{ "R7_T5", "Star", "#ffd648", "glass" }, -- Hatchling Star
	{ "R7_T6", "Pear", "#fff09a", "glass" }, -- Queen's Tear
	{ "R7_T7", "Jewel", "#ffb000", "glass" }, -- Cosmic Yolk
}

-- 1. Les 25 types : depuis le modèle importé (pièces « Gnn_Type_Part »), rangés dans ServerStorage.GemTypes
local types = game.ServerStorage:FindFirstChild("GemTypes")
local imported = workspace:FindFirstChild("GemTypes")
if imported then
	if types then
		types:Destroy()
	end
	types = Instance.new("Folder")
	types.Name = "GemTypes"
	types.Parent = game.ServerStorage
	for _, d in ipairs(imported:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("Weld") then
			d:Destroy()
		end
	end
	for _, p in ipairs(imported:GetDescendants()) do
		if p:IsA("MeshPart") then
			local typeName, partName = p.Name:match("^G%d+_(.-)_(%a+)$")
			if typeName then
				local m = types:FindFirstChild(typeName) or Instance.new("Model")
				m.Name = typeName
				m.Parent = types
				p.Name = if partName == "Core" then "Heart" else partName
				p.Parent = m
			end
		end
	end
	imported:Destroy()
	for _, m in ipairs(types:GetChildren()) do
		local cf = m:GetBoundingBox()
		m.WorldPivot = CFrame.new(cf.Position)
		m:PivotTo(CFrame.new())
	end
end
assert(types and #types:GetChildren() == 25, "il faut les 25 types (GemTypes)")

-- 2. Les 45 minerais
local folder = game.ReplicatedStorage.Assets:FindFirstChild("Gems") or Instance.new("Folder")
folder.Name = "Gems"
folder.Parent = game.ReplicatedStorage.Assets
local done = {}
for _, g in ipairs(GEMS) do
	local key, typeName, colorHex, mat, heartHex = g[1], g[2], g[3], g[4], g[5]
	local ring = tonumber(key:match("^R(%d)")) :: number
	local rarity = tonumber(key:match("_T(%d)$")) :: number
	local color = hex(colorHex)
	local old = folder:FindFirstChild(key)
	if old then
		old:Destroy()
	end
	local m = types[typeName]:Clone()
	m.Name = key
	for _, p in ipairs(m:GetChildren()) do
		if not p:IsA("BasePart") then
			continue
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		if p.Name == "Gem" then
			p.Color = color
			if mat == "glass" then
				p.Material = Enum.Material.Glass
				p.Transparency = 0.25
				p.Reflectance = 0.15
			elseif mat == "deep" then
				p.Material = Enum.Material.Glass
				p.Transparency = 0.08
				p.Reflectance = 0.3
			elseif mat == "pearl" then
				p.Material = Enum.Material.SmoothPlastic
				p.Reflectance = 0.35
			elseif mat == "basalt" then
				p.Material = Enum.Material.Basalt
			else
				p.Material = Enum.Material.SmoothPlastic
				p.Reflectance = 0.22
			end
		elseif p.Name == "Heart" then
			-- cœur lumineux à partir d'Epic, visible à travers la pierre transparente
			if rarity >= 4 and (mat == "glass" or mat == "deep") then
				p.Material = Enum.Material.Neon
				p.Color = if heartHex then hex(heartHex) else color:Lerp(Color3.new(1, 1, 1), 0.2)
				p.Transparency = 0.45 -- plus opaque, il noie la pierre et cache ses facettes
			else
				p:Destroy()
			end
		elseif p.Name == "Base" then
			p.Material = Enum.Material.Slate
			p.Color = Config.Rings[ring].Color:Lerp(Color3.fromRGB(90, 85, 80), 0.3)
		elseif p.Name == "Setting" then
			p.Material = Enum.Material.Foil
			p.Color = Color3.fromRGB(235, 180, 50)
			p.Reflectance = 0.2
		end
	end
	m:SetAttribute("GemName", Config.GemName(ring, rarity))
	m:SetAttribute("GemType", typeName)
	m.Parent = folder
	table.insert(done, key)
end
print(#done .. " minerais posés dans ReplicatedStorage.Assets.Gems")
