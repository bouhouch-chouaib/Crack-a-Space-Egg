-- Range les monstres articulés (découpés dans Blender par tools/blender/monster_rig.py, importés en
-- « Work_R_<Nom> » dans Workspace) en modèles prêts pour le jeu dans ReplicatedStorage.Assets.Monsters.
-- Un modèle = une racine invisible « Body » (PrimaryPart, l'avant vers -Z) et une pièce par groupe :
--   attribut Joint  : nom de la pièce qui la porte ("" = la racine) ; sa charnière est son PivotOffset
--                     (repère du modèle, ou axe Z = l'axe de rotation quand il est imposé : roue, pétale) ;
--   attributs Chain, Index : tronçon d'un corps de serpent, posé chaque image le long du trajet ;
--   attribut Glow   : lueur soudée à cette pièce.
-- Attributs du modèle : Rig = true, Span (longueur en jeu = Size du monstre x Span).
-- Lu par client/MonsterRig. Les anciens modèles (un bloc « Shell ») sont gardés dans ServerStorage.OldMonsters.
-- Dans Studio, le petit serveur local lancé (python -m http.server 34873) :
--     require(ServerStorage.BuildMonsters).Build()     (Build(true) garde les lots importés)

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Builder = {}

local JSON_URL = "http://127.0.0.1:34873/tools/blender/monster_rigs.json"

local function quiet(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	if p.Material ~= Enum.Material.Neon then
		p.Material = Enum.Material.SmoothPlastic
	end
	pcall(function()
		(p :: any).CollisionFidelity = Enum.CollisionFidelity.Box
	end)
end

-- Repère en `pos` dont l'axe Z est `axis`
local function frame(pos: Vector3, axis: Vector3?): CFrame
	if not axis or axis.Magnitude < 0.01 then
		return CFrame.new(pos)
	end
	local z = axis.Unit
	local ref = if math.abs(z.Y) > 0.9 then Vector3.xAxis else Vector3.yAxis
	local x = ref:Cross(z).Unit
	return CFrame.fromMatrix(pos, x, z:Cross(x), z)
end

function Builder.Build(keep: boolean?)
	local rigs = HttpService:JSONDecode(HttpService:GetAsync(JSON_URL, true))
	local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Monsters")
	local backup = ServerStorage:FindFirstChild("OldMonsters")
	if not backup then
		backup = Instance.new("Folder")
		backup.Name = "OldMonsters"
		backup.Parent = ServerStorage
	end
	local report = {}
	for name, rig in pairs(rigs) do
		local work = workspace:FindFirstChild("Work_R_" .. name)
		if not work then
			table.insert(report, name .. " : lot absent, modèle gardé")
			continue
		end
		local m = Instance.new("Model")
		m.Name = name
		local parts: { [string]: BasePart } = {}
		for _, src in ipairs(work:GetChildren()) do
			local prefix, group = src.Name:match("^(.-)__(.+)$")
			if prefix == name and src:IsA("BasePart") then
				local p = src:Clone()
				p.Name = group
				quiet(p)
				parts[group] = p
				p.Parent = m
			end
		end
		local missing = {}
		local chained = false
		for group, info in pairs(rig.parts) do
			local p = parts[group]
			if not p then
				table.insert(missing, group)
				continue
			end
			if info.chain then
				chained = true
				p:SetAttribute("Chain", info.chain)
				p:SetAttribute("Index", info.index)
			else
				p:SetAttribute("Joint", info.parent)
				local axis = if info.axis then Vector3.new(info.axis[1], info.axis[2], info.axis[3]) else nil
				p.PivotOffset = frame(Vector3.new(info.hinge[1], info.hinge[2], info.hinge[3]), axis)
			end
			-- lueurs du groupe : « <Groupe>_G », « <Groupe>_G2 »...
			for i = 1, info.glow do
				local g = parts[group .. "_G" .. (if i == 1 then "" else tostring(i))]
				if g then
					g:SetAttribute("Glow", group)
				else
					table.insert(missing, group .. "_G" .. i)
				end
			end
		end
		-- racine : au centre du monstre, ou au centre de la tête quand le corps est une chaîne (elle mène le trajet)
		local center = if chained and parts.Torso then parts.Torso.Position else (m:GetBoundingBox()).Position
		local root = Instance.new("Part")
		root.Name = "Body"
		root.Size = Vector3.one
		root.Transparency = 1
		root.CFrame = CFrame.new(center) * CFrame.Angles(0, math.pi, 0) -- les modèles regardent vers +Z, le jeu vers -Z
		quiet(root)
		root.Parent = m
		m.PrimaryPart = root
		m:SetAttribute("Rig", true)
		m:SetAttribute("Span", rig.span or 1)
		local old = folder:FindFirstChild(name)
		if old then
			if old:GetAttribute("Rig") then
				old:Destroy()
			else
				local kept = backup:FindFirstChild(name)
				if kept then
					kept:Destroy()
				end
				old.Parent = backup
			end
		end
		m.Parent = folder
		local count = 0
		for _ in pairs(parts) do
			count += 1
		end
		table.insert(report, ("%s : %d pièces%s"):format(name, count, if #missing > 0 then " ; MANQUE " .. table.concat(missing, ", ") else ""))
		if not keep then
			work:Destroy()
		end
	end
	table.sort(report)
	return table.concat(report, "\n")
end

return Builder
