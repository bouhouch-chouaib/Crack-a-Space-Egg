-- Outil de Studio (mode édition) : remplace le vaisseau par une cour en herbe, comme le point de départ
-- des jeux « Steal an Egg » (26 nov.) : sol vert à damier, hauts murs de brique, enclos à barrière de bois,
-- stands à auvent et tableaux de classement de part et d'autre de la sortie, grande ouverture (sans arche)
-- vers le couloir d'astéroïdes.
-- Installé comme ModuleScript (ServerStorage.BuildYard), lancé avec require(...).Build(). Relançable.
-- Ce qui ne change pas : le conteneur s'appelle toujours Workspace.Ship (tout le code s'en sert), les 6
-- bases gardent leur contenu (Bases.BaseN : Floor, Walls, Annex, DerockMachine, boutons, Spawn), le bout
-- du quai (DockEnd) reste en z = 64 et la sortie fait la largeur du couloir (120).
-- Place pour grandir : chaque enclos (36 x 36) a GROW_BACK studs libres derrière lui et GROW_SIDE du côté
-- opposé à l'atelier (attributs GrowBack / GrowSide de la base) : son sol pourra passer à 48 x 60 sans rien
-- déplacer (l'entrée, la machine, la soufflerie et les boutons restent devant).
-- L'allée centrale jusqu'à la sortie reste vide : stands, machine à fusion et classements sont le long
-- du mur de devant, de part et d'autre de la porte.
-- L'ancien vaisseau (Hull, Deck) est rangé dans ServerStorage.OldShipParts.Ship_2026_11_26.

local Build = {}

local STUDS = "rbxassetid://99589690361139"
local CHECKER = "rbxassetid://136038449389796" -- damier noir transparent (tools/ui-icons/yard_checker.png)

local GRASS = Color3.fromRGB(98, 212, 60)
local GRASS_PEN = Color3.fromRGB(134, 228, 94) -- sol des enclos, un peu plus clair
local GRASS_TOP = Color3.fromRGB(72, 186, 62) -- dessus des murs, feuillages
local LEAF = Color3.fromRGB(58, 166, 66)
local DIRT = Color3.fromRGB(146, 96, 62)
local DIRT_DARK = Color3.fromRGB(112, 72, 48)
local BRICK = Color3.fromRGB(178, 90, 84)
local WOOD = Color3.fromRGB(166, 102, 60)
local WOOD_DARK = Color3.fromRGB(122, 74, 46)
local WOOD_LIGHT = Color3.fromRGB(226, 188, 134)
local PATCH = Color3.fromRGB(216, 178, 120) -- terre battue de l'atelier (annexe)
local RED = Color3.fromRGB(232, 44, 52)

local X_IN = 160 -- demi-largeur intérieure de la cour
local Z_BACK = -110 -- face intérieure du mur du fond
local GROW_BACK, GROW_SIDE = 24, 12 -- place réservée derrière chaque enclos et sur son côté libre
-- centre du sol de chaque enclos (deux de chaque côté tournés vers l'allée, deux au fond tournés vers la porte)
local LOTS = {
	Base1 = Vector3.new(-116, 0, -10),
	Base2 = Vector3.new(116, 0, -10),
	Base3 = Vector3.new(-116, 0, -76),
	Base4 = Vector3.new(116, 0, -76),
	Base5 = Vector3.new(-39, 0, -64),
	Base6 = Vector3.new(39, 0, -64),
}
local Z_FRONT = 60 -- face intérieure du mur de devant
local LINE_Z = 64 -- ligne rouge : début du couloir (Config.Map.FrontZ)
local EDGE_Z = 68 -- bord du sol
local WALL_T = 8
local WALL_H = 30
local GATE = 60 -- demi-largeur de la sortie (= demi-largeur du couloir)

local function texture(p: BasePart, id: string, face: Enum.NormalId, tile: number, name: string)
	local t = Instance.new("Texture")
	t.Name = name
	t.Texture = id
	t.Face = face
	t.StudsPerTileU = tile
	t.StudsPerTileV = tile
	t.ZIndex = if name == "Studs" then 2 else 1
	t.Parent = p
end

local function studs(p: BasePart)
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		texture(p, STUDS, face, 2, "Studs")
	end
end

local function part(props: { [string]: any }, withStuds: boolean?): Part
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
	if withStuds ~= false then
		studs(p)
	end
	p.Parent = parent
	return p
end

-- Pièce posée entre deux coins (x0..x1, y0..y1, z0..z1)
local function box(parent: Instance, name: string, color: Color3, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number): Part
	return part({
		Name = name,
		Color = color,
		Size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
		Position = Vector3.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
		Parent = parent,
	})
end

-- Mur de brique avec son damier et son dessus en herbe
local function wall(parent: Instance, x0: number, x1: number, z0: number, z1: number, h: number)
	local w = box(parent, "Wall", BRICK, x0, x1, 0, h, z0, z1)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
		texture(w, CHECKER, face, 16, "Checker")
	end
	box(parent, "WallTop", GRASS_TOP, x0, x1, h, h + 2, z0, z1)
end

-- Arbre en cubes (comme le décor des cartes du genre)
local function tree(parent: Instance, x: number, y: number, z: number, s: number)
	local m = Instance.new("Model")
	m.Name = "Tree"
	box(m, "Trunk", WOOD_DARK, x - s, x + s, y, y + 5 * s, z - s, z + s)
	box(m, "Leaves", LEAF, x - 4 * s, x + 4 * s, y + 5 * s, y + 10 * s, z - 4 * s, z + 4 * s)
	box(m, "Leaves", GRASS_TOP, x - 2.5 * s, x + 2.5 * s, y + 10 * s, y + 13.5 * s, z - 2.5 * s, z + 2.5 * s)
	m.Parent = parent
end

-- Barrière de bois de a à b (points du repère F, y = 0 au sol) : poteaux, deux lisses, croisillons
local function fence(parent: Instance, F: CFrame, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	local n = math.max(1, math.floor(len / 6 + 0.5))
	local function post(at: Vector3)
		local p = part({ Name = "Post", Color = WOOD_DARK, Size = Vector3.new(0.9, 3.4, 0.9), CFrame = F * CFrame.new(at + Vector3.new(0, 1.7, 0)), Parent = parent })
		p:SetAttribute("SkinRole", "Trim")
	end
	for i = 0, n - 1 do
		local p0 = a:Lerp(b, i / n)
		local p1 = a:Lerp(b, (i + 1) / n)
		local mid = (p0 + p1) / 2
		local seg = (p1 - p0).Magnitude
		post(p0)
		for _, y in ipairs({ 1.1, 2.5 }) do
			local r = part({ Name = "Rail", Color = WOOD, Size = Vector3.new(0.5, 0.6, seg), CFrame = F * CFrame.lookAt(mid + Vector3.new(0, y, 0), p1 + Vector3.new(0, y, 0)), Parent = parent })
			r:SetAttribute("SkinRole", "Main")
		end
		for _, up in ipairs({ true, false }) do
			local q0 = p0 + Vector3.new(0, if up then 1.1 else 2.5, 0)
			local q1 = p1 + Vector3.new(0, if up then 2.5 else 1.1, 0)
			local br = part({ Name = "Brace", Color = WOOD, Size = Vector3.new(0.3, 0.45, (q1 - q0).Magnitude), CFrame = F * CFrame.lookAt((q0 + q1) / 2, q1), CanCollide = false, CanQuery = false, Parent = parent }, false)
			br:SetAttribute("SkinRole", "Main")
		end
	end
	post(b)
end

-- Tourne un modèle autour de la verticale pour que « front » regarde vers « goal », centre de sa boîte en (x, z)
local function face(model: Model, front: Vector3, goal: Vector3, x: number, z: number)
	local cf = model:GetBoundingBox()
	local c = cf.Position
	local yaw = math.atan2(goal.X, goal.Z) - math.atan2(front.X, front.Z)
	local T = CFrame.new(x, c.Y, z) * CFrame.Angles(0, yaw, 0) * CFrame.new(-c)
	model:PivotTo(T * model:GetPivot())
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 0.01 then f.Unit else Vector3.new(0, 0, -1)
end

function Build.Build(): string
	local ship = workspace:FindFirstChild("Ship")
	assert(ship, "Workspace.Ship introuvable")
	local toYard = Vector3.new(0, 0, -1) -- les stands regardent vers la cour

	-- 1. L'ancien vaisseau part à la réserve
	local store = game:GetService("ServerStorage"):FindFirstChild("OldShipParts") or Instance.new("Folder")
	store.Name = "OldShipParts"
	store.Parent = game:GetService("ServerStorage")
	local archive = store:FindFirstChild("Ship_2026_11_26") or Instance.new("Folder")
	archive.Name = "Ship_2026_11_26"
	archive.Parent = store
	for _, name in ipairs({ "Hull", "Deck" }) do
		local old = ship:FindFirstChild(name)
		if old then
			old.Parent = archive
		end
	end
	local oldYard = ship:FindFirstChild("Yard")
	if oldYard then
		oldYard:Destroy()
	end

	-- 2. La cour
	local yard = Instance.new("Model")
	yard.Name = "Yard"
	local xo = X_IN + WALL_T -- bord extérieur
	local zo = Z_BACK - WALL_T
	local grass = box(yard, "Grass", GRASS, -xo, xo, -4, 0, zo, EDGE_Z)
	texture(grass, CHECKER, Enum.NormalId.Top, 24, "Checker")
	-- île de terre sous l'herbe, en gradins
	box(yard, "Dirt", DIRT, -xo, xo, -16, -4, zo, EDGE_Z)
	box(yard, "Dirt", DIRT_DARK, -xo + 22, xo - 22, -27, -16, zo + 22, EDGE_Z - 22)
	box(yard, "Dirt", DIRT_DARK, -xo + 52, xo - 52, -38, -27, zo + 50, EDGE_Z - 50)
	-- murs : fond, côtés, devant de part et d'autre de la sortie
	wall(yard, -xo, xo, zo, Z_BACK, WALL_H)
	wall(yard, -xo, -X_IN, Z_BACK, EDGE_Z, WALL_H)
	wall(yard, X_IN, xo, Z_BACK, EDGE_Z, WALL_H)
	wall(yard, -X_IN, -GATE, Z_FRONT, EDGE_Z, WALL_H)
	wall(yard, GATE, X_IN, Z_FRONT, EDGE_Z, WALL_H)
	-- la sortie reste ouverte jusqu'au ciel : ni arche ni panneau (retirés le 26 nov. à la demande de Chouaib)
	-- ligne rouge : au-delà, c'est l'espace et le couloir d'astéroïdes
	part({ Name = "SafeLine", Color = RED, Size = Vector3.new(GATE * 2, 0.3, 1.6), Position = Vector3.new(0, 0.1, LINE_Z), CanCollide = false, Parent = yard }, false)
	part({ Name = "DockEnd", Size = Vector3.one, Position = Vector3.new(0, 0, LINE_Z), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = yard }, false)
	-- décor : arbres en cubes sur les murs et dans les coins libres
	local top = WALL_H + 2
	for _, t in ipairs({
		{ -xo + 4, top, -90, 1 }, { -xo + 4, top, -30, 0.8 }, { -xo + 4, top, 34, 1 }, { xo - 4, top, -70, 0.8 }, { xo - 4, top, -6, 1 }, { xo - 4, top, 46, 0.8 },
		{ -120, top, zo + 4, 1 }, { -30, top, zo + 4, 0.8 }, { 64, top, zo + 4, 1 }, { 130, top, zo + 4, 0.8 }, { -112, top, 64, 0.8 }, { 100, top, 64, 0.8 },
		{ -142, 0, 48, 1 }, { -152, 0, 36, 0.8 }, { -128, 0, 54, 0.7 }, -- coin avant gauche, hors des places réservées
	}) do
		tree(yard, t[1], t[2], t[3], t[4])
	end
	yard.PrimaryPart = grass
	yard.Parent = ship

	-- 3. Les enclos : barrière de bois à la place des vitres, sol d'herbe claire, atelier en terre battue
	local bases = ship:FindFirstChild("Bases")
	local pens = 0
	for _, base in ipairs(if bases then bases:GetChildren() else {}) do
		local floor = base:FindFirstChild("Floor")
		local walls = base:FindFirstChild("Walls")
		local annex = base:FindFirstChild("Annex")
		if floor and floor:IsA("BasePart") and walls then
			local lot = LOTS[base.Name]
			if lot and base:IsA("Model") then
				local delta = Vector3.new(lot.X - floor.Position.X, 0, lot.Z - floor.Position.Z)
				if delta.Magnitude > 0.01 then
					base:PivotTo(base:GetPivot() + delta)
				end
			end
			base:SetAttribute("GrowBack", GROW_BACK)
			base:SetAttribute("GrowSide", GROW_SIDE)
			local F = floor.CFrame
			local hx, hz = floor.Size.X / 2, floor.Size.Z / 2
			-- on apparaît tourné vers l'entrée de son enclos (et plus vers le mur du fond)
			local spawn = base:FindFirstChild("Spawn")
			if spawn and spawn:IsA("BasePart") then
				spawn.CFrame = CFrame.lookAt(spawn.Position, spawn.Position + F:VectorToWorldSpace(Vector3.zAxis))
			end
			floor.Color = GRASS_PEN
			floor:SetAttribute("SkinRole", "Floor")
			if not floor:FindFirstChild("Checker") then
				texture(floor, CHECKER, Enum.NormalId.Top, 12, "Checker")
			end
			walls:ClearAllChildren()
			fence(walls, F, Vector3.new(-hx, 0, -hz), Vector3.new(hx, 0, -hz)) -- fond
			fence(walls, F, Vector3.new(-hx, 0, -hz), Vector3.new(-hx, 0, hz))
			fence(walls, F, Vector3.new(hx, 0, -hz), Vector3.new(hx, 0, hz))
			fence(walls, F, Vector3.new(-hx, 0, hz), Vector3.new(-hx / 2, 0, hz)) -- devant : une entrée au milieu
			fence(walls, F, Vector3.new(hx / 2, 0, hz), Vector3.new(hx, 0, hz))
			local af = annex and annex:FindFirstChild("AnnexFloor")
			if annex and af and af:IsA("BasePart") then
				for _, c in ipairs(annex:GetChildren()) do
					if c ~= af then
						c:Destroy()
					end
				end
				af.Color = PATCH
				af:SetAttribute("SkinRole", "Floor")
				local loc = F:PointToObjectSpace(af.Position)
				local s = if loc.X >= 0 then 1 else -1
				local x0, x1 = loc.X - s * af.Size.X / 2, loc.X + s * af.Size.X / 2
				local z0, z1 = loc.Z - af.Size.Z / 2, loc.Z + af.Size.Z / 2
				fence(annex, F, Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z0)) -- fond de l'atelier
				fence(annex, F, Vector3.new(x1, 0, z0), Vector3.new(x1, 0, z1)) -- côté extérieur
			end
			pens += 1
		end
	end

	-- 4. Stands, machine à fusion et classements : le long du mur de devant, de part et d'autre de la
	-- porte et tournés vers la cour ; l'allée centrale reste vide jusqu'au couloir
	local shops = ship:FindFirstChild("Shops")
	local spots = { StoreStand = -84, ItemsStand = -106, SellStand = 84 }
	for name, x in pairs(spots) do
		local stand = shops and shops:FindFirstChild(name)
		if stand and stand:IsA("Model") then
			local back, mat = stand:FindFirstChild("BackWall"), stand:FindFirstChild("Mat")
			if back and mat then
				face(stand, flat(mat.Position - back.Position), toYard, x, 49)
			end
			for _, d in ipairs(stand:GetChildren()) do
				if d.Name == "Antenna" or d.Name == "AntennaBall" then
					d:Destroy()
				elseif d:IsA("BasePart") and (d.Name == "Pillar" or d.Name == "BackWall") then
					d.Color = WOOD_LIGHT
				elseif d:IsA("BasePart") and (d.Name == "Platform" or d.Name == "Step") then
					d.Color = WOOD_DARK
				end
			end
		end
	end
	local fusion = ship:FindFirstChild("Fusion")
	if fusion and fusion:IsA("Model") then
		local body, point = fusion:FindFirstChild("FM_Body"), fusion:FindFirstChild("FusionPoint")
		if body and point then
			face(fusion, flat(point.Position - body.Position), toYard, 104, 46)
		end
	end
	local boards = ship:FindFirstChild("Leaderboards")
	for i, name in ipairs({ "Richest", "EggsCracked", "BestFind" }) do
		local b = boards and boards:FindFirstChild(name)
		local screen = b and b:FindFirstChild("Screen")
		if b and b:IsA("Model") and screen and screen:IsA("BasePart") then
			local gui = screen:FindFirstChildOfClass("SurfaceGui")
			local normal = Vector3.FromNormalId(if gui then gui.Face else Enum.NormalId.Front)
			face(b, flat(screen.CFrame:VectorToWorldSpace(normal)), toYard, 106 + i * 14, Z_FRONT - 1.6)
		end
	end

	return ("Cour construite : %d pièces, %d enclos refaits"):format(#yard:GetDescendants(), pens)
end

return Build
