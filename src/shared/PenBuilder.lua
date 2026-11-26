-- Construit l'enclos d'une base à un niveau donné (Config.Pen) : taille du sol et barrière de bois.
-- Sert à l'outil de Studio (tools/build-yard.lua, niveau 1) et au serveur (PenService, agrandissements).
-- L'enclos grandit vers le fond et vers son côté libre (celui de la soufflerie, attribut TunnelSide) :
-- l'entrée, l'atelier de la machine, la soufflerie et les boutons ne bougent pas.
-- Le repère de départ (centre du sol au niveau 1) est gardé dans l'attribut Origin de la base : le sol
-- se déplace quand il grandit, tout ce qui doit rester en place (soufflerie, boutons) part de Origin.

local Config = require(script.Parent:WaitForChild("Config"))
local BaseSkin = require(script.Parent:WaitForChild("BaseSkin"))

local PenBuilder = {}

local STUDS = "rbxassetid://99589690361139"
local WOOD = Color3.fromRGB(166, 102, 60)
local WOOD_DARK = Color3.fromRGB(122, 74, 46)
local GATE = 9 -- demi-largeur de l'entrée

local function wood(props: { [string]: any }, role: string, studs: boolean): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local parent = props.Parent
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	-- rôle et couleur d'origine pour les thèmes de base (shared/BaseSkin)
	p:SetAttribute("SkinRole", role)
	p:SetAttribute("SkinDefault", p.Color)
	if studs then
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local t = Instance.new("Texture")
			t.Name = "Studs"
			t.Texture = STUDS
			t.Face = face
			t.StudsPerTileU = 2
			t.StudsPerTileV = 2
			t.ZIndex = 2
			t.Parent = p
		end
	end
	p.Parent = parent
	return p
end

-- Barrière de bois de a à b (points du repère F, y = 0 au sol) : poteaux, deux lisses, croisillons
function PenBuilder.Fence(parent: Instance, F: CFrame, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	if len < 1 then
		return
	end
	local n = math.max(1, math.floor(len / 6 + 0.5))
	local function post(at: Vector3)
		wood({ Name = "Post", Color = WOOD_DARK, Size = Vector3.new(0.9, 3.4, 0.9), CFrame = F * CFrame.new(at + Vector3.new(0, 1.7, 0)), Parent = parent }, "Trim", true)
	end
	for i = 0, n - 1 do
		local p0 = a:Lerp(b, i / n)
		local p1 = a:Lerp(b, (i + 1) / n)
		local mid = (p0 + p1) / 2
		local seg = (p1 - p0).Magnitude
		post(p0)
		for _, y in ipairs({ 1.1, 2.5 }) do
			wood({ Name = "Rail", Color = WOOD, Size = Vector3.new(0.5, 0.6, seg), CFrame = F * CFrame.lookAt(mid + Vector3.new(0, y, 0), p1 + Vector3.new(0, y, 0)), Parent = parent }, "Main", true)
		end
		for _, up in ipairs({ true, false }) do
			local q0 = p0 + Vector3.new(0, if up then 1.1 else 2.5, 0)
			local q1 = p1 + Vector3.new(0, if up then 2.5 else 1.1, 0)
			wood({ Name = "Brace", Color = WOOD, Size = Vector3.new(0.3, 0.45, (q1 - q0).Magnitude), CFrame = F * CFrame.lookAt((q0 + q1) / 2, q1), CanCollide = false, CanQuery = false, Parent = parent }, "Main", false)
		end
	end
	post(b)
end

-- Repère de départ de la base (centre du sol au niveau 1)
function PenBuilder.Origin(base: Instance): CFrame?
	local origin = base:GetAttribute("Origin")
	if typeof(origin) == "CFrame" then
		return origin
	end
	local floor = base:FindFirstChild("Floor")
	return if floor and floor:IsA("BasePart") then floor.CFrame else nil
end

-- Centre du sol au niveau donné, dans le repère de départ
function PenBuilder.Center(base: Instance, level: number): Vector3
	local def = Config.PenLevel(level)
	local side = (base:GetAttribute("TunnelSide") or 1) :: number
	local first = Config.Pen.Levels[1].Size
	return Vector3.new(side * (def.Size.X - first.X) / 2, 0, -(def.Size.Y - first.Y) / 2)
end

-- Met le sol à la taille du niveau et refait la barrière (entrée au même endroit qu'au niveau 1)
function PenBuilder.Build(base: Instance, level: number)
	local floor = base:FindFirstChild("Floor")
	local walls = base:FindFirstChild("Walls")
	local origin = PenBuilder.Origin(base)
	if not floor or not floor:IsA("BasePart") or not walls or not origin then
		return
	end
	local def = Config.PenLevel(level)
	local c = PenBuilder.Center(base, level)
	floor.Size = Vector3.new(def.Size.X, floor.Size.Y, def.Size.Y)
	floor.CFrame = origin * CFrame.new(c)
	local F = floor.CFrame
	local hx, hz = def.Size.X / 2, def.Size.Y / 2
	local gate = -c.X -- milieu de l'entrée dans le repère du sol
	walls:ClearAllChildren()
	PenBuilder.Fence(walls, F, Vector3.new(-hx, 0, -hz), Vector3.new(hx, 0, -hz)) -- fond
	PenBuilder.Fence(walls, F, Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz))
	PenBuilder.Fence(walls, F, Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz))
	PenBuilder.Fence(walls, F, Vector3.new(-hx, 0, hz), Vector3.new(gate - GATE, 0, hz)) -- devant, de part et d'autre de l'entrée
	PenBuilder.Fence(walls, F, Vector3.new(gate + GATE, 0, hz), Vector3.new(hx, 0, hz))
	base:SetAttribute("PenLevel", level)
	-- la barrière neuve prend le thème de la base
	local skin = base:GetAttribute("Skin")
	if type(skin) == "string" then
		BaseSkin.Apply(base, skin)
	end
end

return PenBuilder
