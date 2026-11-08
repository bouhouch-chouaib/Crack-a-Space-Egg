-- Outil de Studio (mode édition) : les boutons rouges au sol de chaque base (relançable).
-- MachineButton : devant le sol, côté machine. TunnelButton : devant le tube.
-- Marcher dessus ouvre le menu d'amélioration (ShipShops.client) : aucune bulle au-dessus des machines.

local STUDS = "rbxassetid://99589690361139"
local ICONS = { MachineButton = "rbxassetid://124846923096618", TunnelButton = "rbxassetid://124670815550762" }
local WINDOWS = { MachineButton = "MachineUp", TunnelButton = "TunnelUp" }

local function disc(parent: Instance, name: string, cf: CFrame, height: number, size: number, color: Color3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(height, size, size)
	p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
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

local function build(base: Model, name: string, localPos: Vector3)
	local old = base:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local F = (base.Floor :: BasePart).CFrame
	local p = F:PointToWorldSpace(localPos)
	local at = CFrame.new(p.X, 0, p.Z)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Window", WINDOWS[name])
	disc(m, "Ring", at + Vector3.new(0, 0.15, 0), 0.3, 5.4, Color3.fromRGB(34, 40, 72))
	local top = disc(m, "RedTop", at + Vector3.new(0, 0.5, 0), 0.5, 4.2, Color3.fromRGB(232, 48, 48))
	local icon = Instance.new("Decal")
	icon.Name = "Icon"
	icon.Face = Enum.NormalId.Right -- le dessus du cylindre couché
	icon.Texture = ICONS[name]
	icon.ZIndex = 3
	icon.Parent = top
	m.PrimaryPart = top
	m.Parent = base
end

return function(): string
	local bases = workspace.Ship.Bases:GetChildren()
	for _, base in ipairs(bases) do
		-- le tube est du côté TunnelSide ; la machine de l'autre
		local tube = (base:GetAttribute("TunnelSide") or 1) :: number
		build(base, "MachineButton", Vector3.new(-tube * 14.5, 0, 21.5))
		build(base, "TunnelButton", Vector3.new(tube * 12, 0, 34.5))
	end
	return #bases .. " bases"
end
