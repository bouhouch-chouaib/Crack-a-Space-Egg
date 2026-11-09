-- Outil de Studio (mode édition), à lancer une fois : passe le vaisseau à 6 bases.
-- La base du milieu du fond (traversée par la tour) part dans ServerStorage.OldShipParts ; l'ancienne Base7 devient Base6.
-- Les deux bases du fond se placent de chaque côté, devant la tour et loin des ailerons :
-- machine côté intérieur, tube côté extérieur, à l'écart des tubes des bases 3 et 4.
-- Les chemins au sol sont refaits ; relancer ensuite tools/build-upgrade-buttons.lua.

local ANNEX_W, ANNEX_D = 18, 20
local STUDS = "rbxassetid://99589690361139"
local PATH_COLOR = Color3.fromRGB(120, 214, 226)
local RAIL_COLOR = Color3.fromRGB(236, 240, 247)

-- side : côté de l'annexe (x local du sol)
local LOTS = {
	Base5 = { x = -39, z = -76, side = 1 },
	Base6 = { x = 39, z = -76, side = -1 },
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

local function place(base: Model, lot)
	local floor = base.Floor :: BasePart
	local target = CFrame.new(lot.x, floor.Position.Y, lot.z)
	base:PivotTo(target * floor.CFrame:Inverse() * base:GetPivot())
	local F = floor.CFrame
	base:SetAttribute("TunnelSide", -lot.side)
	-- annexe du bon côté, fermée à l'arrière et sur le côté extérieur
	local old = base:FindFirstChild("Annex")
	if old then
		old:Destroy()
	end
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
	local box = machine:GetBoundingBox()
	local center = F:PointToObjectSpace(box.Position)
	machine:PivotTo(machine:GetPivot() + F:VectorToWorldSpace(Vector3.new(cx - center.X, 0, cz + 1 - center.Z)))
end

local function buildPaths(paths: Instance)
	local function seg(x0, x1, z0, z1)
		part({ Name = "Path", Size = Vector3.new(x1 - x0, 0.08, z1 - z0), CFrame = CFrame.new((x0 + x1) / 2, 0.04, (z0 + z1) / 2), Color = PATH_COLOR, CanCollide = false, CanQuery = false, Parent = paths }, true)
	end
	local H = 3
	-- avenue centrale, coupée aux croisements (aucune pièce ne se superpose)
	seg(-H, H, -13, 22)
	seg(-H, H, -19, -13)
	seg(-H, H, -32, -19)
	seg(-H, H, -38, -32)
	-- traverse vers les bases 1 et 2
	seg(-78, -H, -19, -13)
	seg(H, 78, -19, -13)
	for _, s in ipairs({ -1, 1 }) do
		local function mirror(x0, x1, z0, z1)
			if s > 0 then
				seg(x0, x1, z0, z1)
			else
				seg(-x1, -x0, z0, z1)
			end
		end
		-- traverse arrière, avec l'embranchement vers la base du fond
		mirror(H, 36, -38, -32)
		mirror(36, 42, -38, -32)
		mirror(42, 60, -38, -32)
		mirror(36, 42, -58, -38)
		-- jusqu'à l'entrée des bases 3 et 4, en contournant leur tube et leur bouton
		mirror(60, 66, -38, -32)
		mirror(60, 66, -75, -38)
		mirror(66, 78, -75, -69)
	end
end

return function(): string
	local bases = workspace.Ship.Bases
	local storage = game:GetService("ServerStorage")
	local keep = storage:FindFirstChild("OldShipParts")
	if not keep then
		keep = Instance.new("Folder")
		keep.Name = "OldShipParts"
		keep.Parent = storage
	end
	if bases:FindFirstChild("Base7") then
		local middle = bases:FindFirstChild("Base6") :: Model
		middle.Name = "Base_milieu_retiree"
		middle.Parent = keep
		bases.Base7.Name = "Base6"
	end
	for name, lot in pairs(LOTS) do
		place(bases[name], lot)
	end
	local paths = workspace.Ship.Deck.Paths
	paths:ClearAllChildren()
	buildPaths(paths)
	return #bases:GetChildren() .. " bases"
end
