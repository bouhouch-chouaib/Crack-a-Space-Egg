-- Outil de Studio (mode édition) : refonte du vaisseau (une seule fois ; l'ancien est copié dans
-- ServerStorage.OldShipParts.Ship_v1).
--   Pont : un seul sol rectangulaire à coins arrondis (x ±122, z -136 à 64), plus aucune surface superposée.
--   Coque étirée pour passer sous le pont. Rambarde refaite, ouverte sur le quai.
--   7 bases en U : côtés (les plus près du quai, attribuées en premier), puis le fond.
--   Chaque base : sol libre de 36 x 36, annexe avec la machine, tube devant l'entrée du côté opposé.
--   Coin gauche du quai : STORE, ITEMS, SELL. Coin droit : tableaux et fusion.

local W, BACK, FRONT = 122, -136, 64 -- demi-largeur, arrière et avant du pont
local R_BACK, R_FRONT = 44, 18 -- rayons des coins
local THICK = 4
local KX, KZ, HULL_Z = 1.18, 1.38, -40 -- étirement de la coque, nouveau centre en z
local ANNEX_W, ANNEX_D = 18, 20
local STUDS = "rbxassetid://99589690361139"

local FLOOR_COLOR = Color3.fromRGB(227, 218, 203)
local RIM_COLOR = Color3.fromRGB(251, 248, 242)
local CAP_COLOR = Color3.fromRGB(63, 201, 216)
local PATH_COLOR = Color3.fromRGB(120, 214, 226)
local RAIL_COLOR = Color3.fromRGB(236, 240, 247)
local CREAM = Color3.fromRGB(244, 239, 230)

-- Bases, dans l'ordre d'attribution : centre du sol, orientation, côté de l'annexe (x local du sol)
local LOTS = {
	{ x = -96, z = -16, yaw = 90, side = -1 },
	{ x = 96, z = -16, yaw = -90, side = 1 },
	{ x = -96, z = -72, yaw = 90, side = -1 },
	{ x = 96, z = -72, yaw = -90, side = 1 },
	{ x = -56, z = -112, yaw = 0, side = 1 },
	{ x = 0, z = -112, yaw = 0, side = 1 },
	{ x = 56, z = -112, yaw = 0, side = 1 },
}

local function addStuds(p: BasePart)
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

local function part(props: { [string]: any }, studs: boolean?): BasePart
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
	if studs then
		addStuds(p)
	end
	p.Parent = parent
	return p
end

local function backup(ship: Instance)
	local root = game.ServerStorage:FindFirstChild("OldShipParts")
	if not root then
		root = Instance.new("Folder")
		root.Name = "OldShipParts"
		root.Parent = game.ServerStorage
	end
	if root:FindFirstChild("Ship_v1") then
		error("Ship_v1 existe déjà : la refonte a déjà été faite")
	end
	local copy = Instance.new("Folder")
	copy.Name = "Ship_v1"
	for _, name in ipairs({ "Deck", "Corners", "Hull", "Bases", "Shops", "Leaderboards", "Fusion" }) do
		ship[name]:Clone().Parent = copy
	end
	copy.Parent = root
end

local function stretchHull(ship: Instance)
	for _, p in ipairs(ship.Hull:GetChildren()) do
		if p:IsA("BasePart") then
			for _, a in ipairs(p:GetChildren()) do
				if a:IsA("Attachment") then
					a.Position = Vector3.new(a.Position.X * KX, a.Position.Y, a.Position.Z * KZ)
				end
			end
			p.Size = Vector3.new(p.Size.X * KX, p.Size.Y, p.Size.Z * KZ)
			p.Position = Vector3.new(p.Position.X * KX, p.Position.Y, HULL_Z + (p.Position.Z + 46) * KZ)
		end
	end
end

local function buildFloor(deck: Instance): BasePart
	local y = -THICK / 2
	local function box(x0, x1, z0, z1)
		return part({ Size = Vector3.new(x1 - x0, THICK, z1 - z0), CFrame = CFrame.new((x0 + x1) / 2, y, (z0 + z1) / 2), Color = FLOOR_COLOR, Parent = workspace })
	end
	local function disc(x, z, r)
		return part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(THICK, r * 2, r * 2), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2), Color = FLOOR_COLOR, Parent = workspace })
	end
	local main = box(-W, W, BACK + R_BACK, FRONT - R_FRONT)
	local others = {
		box(-(W - R_BACK), W - R_BACK, BACK, BACK + R_BACK),
		box(-(W - R_FRONT), W - R_FRONT, FRONT - R_FRONT, FRONT),
		disc(-(W - R_BACK), BACK + R_BACK, R_BACK),
		disc(W - R_BACK, BACK + R_BACK, R_BACK),
		disc(-(W - R_FRONT), FRONT - R_FRONT, R_FRONT),
		disc(W - R_FRONT, FRONT - R_FRONT, R_FRONT),
	}
	local floor = main:UnionAsync(others) :: BasePart
	main:Destroy()
	for _, o in ipairs(others) do
		o:Destroy()
	end
	floor.Name = "Floor"
	floor.Anchored = true
	floor.UsePartColor = true
	floor.Color = FLOOR_COLOR
	addStuds(floor)
	floor.Parent = deck
	return floor
end

local function buildRim(rim: Instance)
	local inset = 0.8
	local hx, zb, zf = W - inset, BACK + inset, FRONT - inset
	local rb, rf = R_BACK - inset, R_FRONT - inset
	local pts: { { Vector3 } } = {}
	local function arc(cx: number, cz: number, r: number, a0: number, a1: number): { Vector3 }
		local list = {}
		for i = 0, 10 do
			local a = math.rad(a0 + (a1 - a0) * i / 10)
			table.insert(list, Vector3.new(cx + math.cos(a) * r, 1, cz + math.sin(a) * r))
		end
		return list
	end
	-- côté droit du quai -> arrière -> côté gauche du quai (a : angle dans le plan x, z)
	table.insert(pts, { Vector3.new(62, 1, zf), Vector3.new(hx - rf, 1, zf) })
	table.insert(pts, arc(hx - rf, zf - rf, rf, 90, 0))
	table.insert(pts, { Vector3.new(hx, 1, zf - rf), Vector3.new(hx, 1, zb + rb) })
	table.insert(pts, arc(hx - rb, zb + rb, rb, 0, -90))
	table.insert(pts, { Vector3.new(hx - rb, 1, zb), Vector3.new(-(hx - rb), 1, zb) })
	table.insert(pts, arc(-(hx - rb), zb + rb, rb, -90, -180))
	table.insert(pts, { Vector3.new(-hx, 1, zb + rb), Vector3.new(-hx, 1, zf - rf) })
	table.insert(pts, arc(-(hx - rf), zf - rf, rf, 180, 90))
	table.insert(pts, { Vector3.new(-(hx - rf), 1, zf), Vector3.new(-62, 1, zf) })
	for _, line in ipairs(pts) do
		local isArc = #line > 2
		for i = 1, #line - 1 do
			local a, b = line[i], line[i + 1]
			local mid = (a + b) / 2
			local len = (b - a).Magnitude + (if isArc then 0.25 else 0)
			local cf = CFrame.lookAt(mid, b)
			part({ Name = "Rail", Size = Vector3.new(1.6, 2, len), CFrame = cf, Color = RIM_COLOR, Parent = rim }, true)
			part({ Name = "RailCap", Size = Vector3.new(0.5, 0.2, len), CFrame = cf + Vector3.new(0, 1.1, 0), Color = CAP_COLOR, CanCollide = false, Parent = rim })
		end
	end
end

local function buildPaths(paths: Instance)
	local function seg(x0, x1, z0, z1)
		part({ Name = "Path", Size = Vector3.new(x1 - x0, 0.08, z1 - z0), CFrame = CFrame.new((x0 + x1) / 2, 0.04, (z0 + z1) / 2), Color = PATH_COLOR, CanCollide = false, CanQuery = false, Parent = paths }, true)
	end
	-- avenue centrale, coupée aux croisements (aucune pièce ne se superpose)
	local H = 3
	seg(-H, H, -13, 22)
	seg(-H, H, -16 - H, -16 + H)
	seg(-H, H, -69, -19)
	seg(-H, H, -72 - H, -72 + H)
	seg(-H, H, -94, -75)
	-- deux traverses vers les côtés, et les embranchements vers les bases du fond
	seg(-78, -H, -19, -13)
	seg(H, 78, -19, -13)
	seg(-53, -H, -75, -69)
	seg(-59, -53, -75, -69)
	seg(-78, -59, -75, -69)
	seg(H, 53, -75, -69)
	seg(53, 59, -75, -69)
	seg(59, 78, -75, -69)
	seg(-59, -53, -94, -75)
	seg(53, 59, -94, -75)
end

local function rail(parent: Instance, F: CFrame, a: Vector3, b: Vector3)
	local mid = (a + b) / 2
	local cf = F * CFrame.lookAt(mid, b)
	local len = (b - a).Magnitude
	part({ Name = "RailTop", Size = Vector3.new(0.64, 0.32, len), CFrame = cf + Vector3.new(0, 2.44, 0), Color = RAIL_COLOR, Parent = parent })
	part({ Name = "RailBottom", Size = Vector3.new(0.64, 0.32, len), CFrame = cf + Vector3.new(0, 0.36, 0), Color = RAIL_COLOR, Parent = parent })
	part({ Name = "Glass", Size = Vector3.new(0.2, 1.76, len), CFrame = cf + Vector3.new(0, 1.4, 0), Color = Color3.fromRGB(190, 235, 245), Material = Enum.Material.Glass, Transparency = 0.5, Parent = parent })
	part({ Name = "Post", Size = Vector3.new(0.6, 2.4, 0.6), CFrame = F * CFrame.new(a) + Vector3.new(0, 1.4, 0), Color = RAIL_COLOR, Parent = parent })
	part({ Name = "Post", Size = Vector3.new(0.6, 2.4, 0.6), CFrame = F * CFrame.new(b) + Vector3.new(0, 1.4, 0), Color = RAIL_COLOR, Parent = parent })
end

local function placeBases(ship: Instance)
	local folder = ship.Bases
	for i = 6, #LOTS do
		if not folder:FindFirstChild("Base" .. i) then
			local c = folder.Base1:Clone()
			c.Name = "Base" .. i
			c.Parent = folder
		end
	end
	for i, lot in ipairs(LOTS) do
		local base = folder["Base" .. i] :: Model
		local floor = base.Floor :: BasePart
		local target = CFrame.new(lot.x, floor.Position.Y, lot.z) * CFrame.Angles(0, math.rad(lot.yaw), 0)
		base:PivotTo(target * floor.CFrame:Inverse() * base:GetPivot())
		local F = floor.CFrame
		base:SetAttribute("TunnelSide", -lot.side)
		-- annexe : même sol que la base, fermée à l'arrière et sur le côté extérieur
		local cx = lot.side * (18 + ANNEX_W / 2)
		local cz = 18 - ANNEX_D / 2
		local annex = Instance.new("Model")
		annex.Name = "Annex"
		part({ Name = "AnnexFloor", Size = Vector3.new(ANNEX_W, floor.Size.Y, ANNEX_D), CFrame = F * CFrame.new(cx, 0, cz), Color = floor.Color, Parent = annex }, true)
		local outer = lot.side * (18 + ANNEX_W - 0.3)
		local near = lot.side * 18.3
		local back = 18 - ANNEX_D + 0.3
		rail(annex, F, Vector3.new(outer, 0, 17.6), Vector3.new(outer, 0, back))
		rail(annex, F, Vector3.new(outer, 0, back), Vector3.new(near, 0, back))
		annex.Parent = base
		-- machine posée sur l'annexe, tournée vers la place
		local machine = base.DerockMachine :: Model
		local box, size = machine:GetBoundingBox()
		local center = F:PointToObjectSpace(box.Position)
		local move = F:VectorToWorldSpace(Vector3.new(cx - center.X, 0, cz + 1 - center.Z))
		move += Vector3.new(0, floor.Position.Y + floor.Size.Y / 2 - (box.Position.Y - size.Y / 2), 0)
		machine:PivotTo(machine:GetPivot() + move)
	end
end

-- Le quai : plus de maillage crème superposé au sol ; piliers et panneau refaits en pièces simples
local function rebuildDock(deck: Instance)
	local dock = deck.Dock
	dock.DockCream:Destroy()
	for _, x in ipairs({ -57, 57 }) do
		part({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 10, 10), CFrame = CFrame.new(x, 8, 60) * CFrame.Angles(0, 0, math.pi / 2), Color = CREAM, Parent = dock }, true)
	end
	part({ Name = "SignPanel", Size = Vector3.new(46, 8.5, 1), CFrame = CFrame.new(0, 26.6, 59.2), Color = CREAM, Parent = dock }, true)
end

local function placeStands(ship: Instance)
	-- coin gauche : les trois stands, tournés vers le centre de l'arc
	local cl = Vector3.new(-70, 0, 22)
	local R = 34
	for name, a in pairs({ StoreStand = 10, ItemsStand = 42.5, SellStand = 75 }) do
		local stand = ship.Shops[name] :: Model
		local plat = stand.Platform :: BasePart
		local frame = plat.CFrame * CFrame.new(0, -0.3, -0.5)
		local ra = math.rad(a)
		local pos = Vector3.new(cl.X - math.sin(ra) * R, 0, cl.Z + math.cos(ra) * R)
		local target = CFrame.lookAt(pos, cl)
		stand:PivotTo(target * frame:Inverse() * stand:GetPivot())
	end
	-- coin droit : tableaux puis machine à fusion
	local cr = Vector3.new(70, 0, 22)
	local function at(a: number, y: number): Vector3
		local ra = math.rad(a)
		return Vector3.new(cr.X + math.sin(ra) * R, y, cr.Z + math.cos(ra) * R)
	end
	for name, a in pairs({ Richest = 10, EggsCracked = 34, BestFind = 58 }) do
		local b = ship.Leaderboards[name] :: Model
		local old = b:GetPivot()
		local pos = at(a, old.Y)
		local look = (b.Screen :: BasePart).CFrame.LookVector
		local dir = (Vector3.new(cr.X, pos.Y, cr.Z) - pos).Unit
		local turn = math.atan2(-dir.X, -dir.Z) - math.atan2(-look.X, -look.Z)
		b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, turn, 0) * (old - old.Position))
	end
	local fusion = ship.Fusion :: Model
	local pos = at(82, fusion:GetPivot().Y)
	fusion:PivotTo(CFrame.lookAt(pos, Vector3.new(cr.X, pos.Y, cr.Z)))
end

return function(): string
	local ship = workspace.Ship
	backup(ship)
	stretchHull(ship)
	local deck = ship.Deck
	deck.Floor_Curve:Destroy()
	deck.Floor_Front:Destroy()
	ship.Corners:Destroy()
	deck.Paths:ClearAllChildren()
	deck.Rim:ClearAllChildren()
	buildFloor(deck)
	buildRim(deck.Rim)
	buildPaths(deck.Paths)
	rebuildDock(deck)
	placeBases(ship)
	placeStands(ship)
	return "ok"
end
