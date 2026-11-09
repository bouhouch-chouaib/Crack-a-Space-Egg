-- Modèles 3D des reliques (Config.Relics) : le modèle détaillé de ReplicatedStorage.Assets.Relics.<clé>,
-- sinon une version en pièces simples. Centrés sur l'origine et tournés vers +Z.
-- Utilisés par la grande révélation (RelicUI.client) et l'onglet RELICS de l'Index.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RelicModel = {}

local STUDS = "rbxassetid://99589690361139"
local CYLINDER, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local FACE = CFrame.Angles(0, math.rad(90), 0) -- un cylindre couché sur X, sa face tournée vers +Z
local STUDS_ACROSS = 7 -- nombre de picots sur la plus grande largeur d'une relique

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function piece(m: Model, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, tile: number?): Part
	local p = Instance.new("Part")
	p.Name = "Piece"
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if tile then
		for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
			local t = Instance.new("Texture")
			t.Texture = STUDS
			t.Face = face
			t.StudsPerTileU = tile
			t.StudsPerTileV = tile
			t.ZIndex = 2
			t.Parent = p
		end
	end
	p.Parent = m
	return p
end

local function ball(d: number): Vector3
	return Vector3.new(d, d, d)
end

local BUILD: { [string]: (Model) -> () } = {}

function BUILD.Compass(m)
	local brass, dark = rgb(214, 165, 72), rgb(130, 92, 40)
	piece(m, Vector3.new(0.4, 3.5, 3.5), FACE * CFrame.new(0.1, 0, 0), dark, CYLINDER)
	piece(m, Vector3.new(0.6, 3.1, 3.1), FACE, brass, CYLINDER, 1)
	piece(m, Vector3.new(0.66, 2.5, 2.5), FACE, rgb(240, 228, 196), CYLINDER)
	piece(m, Vector3.new(0.22, 1.25, 0.08), CFrame.new(0.2, 0.28, 0.36) * CFrame.Angles(0, 0, math.rad(-35)), rgb(70, 225, 210))
	piece(m, Vector3.new(0.22, 1.25, 0.08), CFrame.new(-0.2, -0.28, 0.36) * CFrame.Angles(0, 0, math.rad(-35)), rgb(205, 60, 50))
	piece(m, ball(0.34), CFrame.new(0, 0, 0.38), dark, BALL)
	piece(m, Vector3.new(0.34, 0.6, 0.6), CFrame.new(0, 1.92, 0) * FACE, brass, CYLINDER)
end

function BUILD.Logbook(m)
	local ice = rgb(170, 225, 250)
	piece(m, Vector3.new(2.7, 3.5, 0.2), CFrame.new(0, 0, -0.34), rgb(112, 70, 40), nil, 1)
	piece(m, Vector3.new(2.45, 3.25, 0.5), CFrame.new(0.05, 0, 0), rgb(236, 226, 200))
	piece(m, Vector3.new(2.7, 3.5, 0.2), CFrame.new(0, 0, 0.34), rgb(132, 84, 48), nil, 1)
	piece(m, Vector3.new(0.34, 0.6, 0.86), CFrame.new(1.3, 0, 0), rgb(226, 180, 80))
	for _, c in ipairs({ { -1.1, 1.5, 0.9, 35 }, { 1.05, -1.45, 1.05, 20 }, { -1.25, -1.2, 0.75, 55 }, { 0.9, 1.55, 0.7, 10 } }) do
		local p = piece(m, Vector3.new(c[3], c[3], c[3]), CFrame.new(c[1], c[2], 0.35) * CFrame.Angles(math.rad(c[4]), math.rad(c[4]), math.rad(c[4])), ice)
		p.Transparency = 0.12
	end
end

function BUILD.Visor(m)
	local gold, lava = rgb(240, 180, 60), rgb(250, 110, 40)
	piece(m, ball(3), CFrame.new(0, 0.3, 0), gold, BALL, 1)
	piece(m, ball(2.5), CFrame.new(0, 0.3, 0.68), lava, BALL)
	piece(m, ball(0.5), CFrame.new(-0.5, 1, 1.75), rgb(255, 240, 200), BALL)
	for _, d in ipairs({ { -1, 0.8, 1.2 }, { -0.35, 1.3, 1.45 }, { 0.4, 1, 1.4 }, { 1.05, 0.7, 1.05 } }) do
		piece(m, Vector3.new(0.34, d[2], 0.34), CFrame.new(d[1], -1.1 - d[2] / 2, d[3] - 0.4), lava)
		piece(m, ball(0.46), CFrame.new(d[1], -1.15 - d[2], d[3] - 0.4), lava, BALL)
	end
end

function BUILD.Medal(m)
	local gold, ribbon = rgb(238, 190, 70), rgb(120, 70, 210)
	piece(m, Vector3.new(0.9, 1.5, 0.14), CFrame.new(-0.42, 1.6, -0.1) * CFrame.Angles(0, 0, math.rad(-14)), ribbon, nil, 1)
	piece(m, Vector3.new(0.9, 1.5, 0.14), CFrame.new(0.42, 1.6, -0.1) * CFrame.Angles(0, 0, math.rad(14)), ribbon, nil, 1)
	piece(m, Vector3.new(2.3, 2.3, 0.3), CFrame.new(0, -0.15, 0), gold, nil, 1)
	piece(m, Vector3.new(2.3, 2.3, 0.3), CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(45)), gold, nil, 1)
	piece(m, Vector3.new(0.42, 1.5, 1.5), FACE * CFrame.new(0, -0.15, 0), ribbon, CYLINDER)
	piece(m, Vector3.new(0.5, 0.8, 0.8), FACE * CFrame.new(0, -0.15, 0), rgb(255, 225, 130), CYLINDER)
end

function BUILD.Helmet(m)
	local shell, slime = rgb(92, 98, 112), rgb(120, 230, 80)
	piece(m, ball(3.2), CFrame.new(0, 0, 0), shell, BALL, 1)
	piece(m, ball(2.5), CFrame.new(0, 0, 0.76), rgb(20, 24, 40), BALL)
	piece(m, ball(0.42), CFrame.new(-0.55, 0.65, 1.86), rgb(160, 190, 220), BALL)
	for i = -2, 2 do -- marques de dents autour du sommet
		local a = math.rad(i * 19)
		piece(m, Vector3.new(0.34, 0.8, 0.5), CFrame.new(math.sin(a) * 1.55, 1.3 - math.abs(i) * 0.1, math.cos(a) * 0.4) * CFrame.Angles(0, 0, -a), rgb(46, 50, 62))
	end
	for _, b in ipairs({ { 1.1, -0.8, 1.15, 0.7 }, { 0.75, -1.2, 1.1, 0.45 }, { -1.3, -0.5, 0.75, 0.5 } }) do
		piece(m, ball(b[4]), CFrame.new(b[1], b[2], b[3]), slime, BALL)
	end
end

function BUILD.Map(m)
	local paper, glow = rgb(214, 196, 150), rgb(90, 225, 245)
	piece(m, Vector3.new(4, 2.9, 0.14), CFrame.new(), paper, nil, 1)
	for _, t in ipairs({ { -2, 1.3, 25 }, { 1.95, 1.4, -35 }, { 1.9, -1.35, 30 }, { -1.1, -1.5, 12 } }) do
		piece(m, Vector3.new(0.75, 0.55, 0.16), CFrame.new(t[1], t[2], 0.01) * CFrame.Angles(0, 0, math.rad(t[3])), rgb(120, 92, 62))
	end
	local stars = { { -1.3, 0.7 }, { -0.4, 0.15 }, { 0.5, 0.75 }, { 1.2, -0.35 }, { -0.6, -0.8 } }
	for i, s in ipairs(stars) do
		piece(m, ball(0.32), CFrame.new(s[1], s[2], 0.1), glow, BALL)
		local nxt = stars[i + 1]
		if nxt then
			local from, to = Vector3.new(s[1], s[2], 0.09), Vector3.new(nxt[1], nxt[2], 0.09)
			piece(m, Vector3.new(0.05, 0.05, (to - from).Magnitude), CFrame.lookAt(from:Lerp(to, 0.5), to), glow)
		end
	end
end

function BUILD.Flag(m)
	local gold, cloth = rgb(240, 192, 70), rgb(205, 60, 70)
	piece(m, Vector3.new(2.6, 0.9, 2), CFrame.new(0, -2.05, 0), rgb(110, 100, 104), nil, 1)
	piece(m, Vector3.new(5, 0.26, 0.26), CFrame.new(-0.9, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, CYLINDER)
	piece(m, ball(0.5), CFrame.new(-0.9, 2.9, 0), gold, BALL)
	piece(m, Vector3.new(2.3, 1.5, 0.1), CFrame.new(0.3, 1.8, 0), cloth, nil, 1)
	piece(m, ball(0.55), CFrame.new(0.3, 1.8, 0.06), gold, BALL)
	-- franges déchirées
	for i, x in ipairs({ 1.28, 1.48, 1.6 }) do
		piece(m, Vector3.new(0.5, 0.28, 0.08), CFrame.new(x, 2.45 - i * 0.42, 0.01) * CFrame.Angles(0, 0, math.rad(i * 19)), cloth)
	end
end

-- Les modèles générés reçoivent aussi les picots du jeu, à l'échelle de chaque objet
local function addStuds(m: Model)
	local _, size = m:GetBoundingBox()
	local tile = math.max(size.X, size.Y, size.Z) / STUDS_ACROSS
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local t = Instance.new("Texture")
				t.Name = "Studs"
				t.Texture = STUDS
				t.Face = face
				t.StudsPerTileU = tile
				t.StudsPerTileV = tile
				t.ZIndex = 2
				t.Parent = p
			end
		end
	end
end

-- Orientation des modèles générés qui ne sont pas de face (la boussole a son cadran sur le côté, à plat)
local TURN: { [string]: CFrame } = {
	Compass = CFrame.Angles(math.rad(30), 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
}

-- Modèle prêt à poser dans une ViewportFrame : son centre est à l'origine
function RelicModel.Build(key: string): Model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Relics")
	local template = folder and folder:FindFirstChild(key) :: Model?
	local m: Model
	if template then
		m = template:Clone()
	else
		m = Instance.new("Model")
		m.Name = key
		BUILD[key](m)
	end
	if template then
		addStuds(m)
		local turn = TURN[key]
		if turn then
			m:PivotTo(turn * m:GetPivot())
		end
	end
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position)
	m:PivotTo(CFrame.new())
	return m
end

return RelicModel
