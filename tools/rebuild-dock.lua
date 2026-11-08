-- Outil de Studio (mode édition) : le quai sans barrières ni maillage bleu (DockTeal, qui contenait
-- les rambardes latérales, les flèches et l'arche). Arche et flèches refaites en pièces à studs.
-- La machine à fusion est sur l'axe du bord droit du quai (la boîte à retours sur le bord gauche : tools/build-mailbox.lua).
-- Relançable : il remplace ce qu'il a construit.

local STUDS = "rbxassetid://99589690361139"
local TEAL = Color3.fromRGB(63, 201, 216)
local ARROW = Color3.fromRGB(70, 215, 232)
local PILLAR_X, PILLAR_TOP = 57, 16
local ARCH_RISE, ARCH_Z = 14, 61.8 -- derrière le panneau LAUNCH
local PILLAR_Z = 60

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
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
	p.Parent = parent
	return p
end

-- Une flèche au sol qui pointe vers le départ (+z) : deux branches, l'une un peu plus haute que l'autre
-- pour que leur croisement au sommet ne scintille pas
local function chevron(parent: Instance, x: number, z: number, arm: number, width: number)
	local spread = math.rad(38)
	for i, s in ipairs({ -1, 1 }) do
		local thick = 0.08 + i * 0.03
		local half = arm / 2
		local tip = Vector3.new(x, thick / 2, z)
		local mid = tip + Vector3.new(s * math.sin(spread) * half, 0, -math.cos(spread) * half)
		local cf = CFrame.lookAt(mid, tip)
		part(parent, "Arrow", Vector3.new(width, thick, arm), cf, ARROW)
	end
end

return function(): string
	local ship = workspace.Ship
	local dock = ship.Deck.Dock
	local teal = dock:FindFirstChild("DockTeal")
	if teal then
		teal:Destroy()
	end
	for _, name in ipairs({ "Arch", "Arrows" }) do
		local old = dock:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	-- arche : de pilier à pilier, en passant derrière le panneau LAUNCH
	local arch = Instance.new("Model")
	arch.Name = "Arch"
	local n = 24
	local function point(i: number): Vector3
		local t = -1 + 2 * i / n
		return Vector3.new(PILLAR_X * t, PILLAR_TOP + ARCH_RISE * math.cos(t * math.pi / 2), ARCH_Z)
	end
	for i = 0, n - 1 do
		local a, b = point(i), point(i + 1)
		part(arch, "ArchBar", Vector3.new(3, 2, (b - a).Magnitude + 0.3), CFrame.lookAt((a + b) / 2, b), TEAL)
	end
	for _, x in ipairs({ -PILLAR_X, PILLAR_X }) do
		part(arch, "Band", Vector3.new(1, 10.8, 10.8), CFrame.new(x, 5, PILLAR_Z) * CFrame.Angles(0, 0, math.pi / 2), TEAL).Shape = Enum.PartType.Cylinder
	end
	arch.Parent = dock
	-- flèches au sol : trois colonnes, trois rangées, vers le départ
	local arrows = Instance.new("Model")
	arrows.Name = "Arrows"
	for _, x in ipairs({ -34, 0, 34 }) do
		for _, z in ipairs({ 36, 46, 56 }) do
			chevron(arrows, x, z, 14, 3.2)
		end
	end
	arrows.Parent = dock
	-- machine à fusion : sur le bord droit du quai, tournée vers le quai
	local fusion = ship.Fusion :: Model
	local y = fusion:GetPivot().Y
	fusion:PivotTo(CFrame.lookAt(Vector3.new(66, y, 38), Vector3.new(0, y, 38)))
	return "ok"
end
