-- Anime le tapis d'astéroïdes sur ce client, image par image.
-- Chaque astéroïde (un Model) porte la formule de son mouvement (attributs posés par BeltService) :
-- on calcule sa position à partir du temps serveur, donc tous les clients voient la même chose.
-- La vitesse donnée à la roche entraîne le joueur qui se tient dessus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local folder = workspace:WaitForChild("World"):WaitForChild("Belt")
local FADE = 30 -- studs d'arc sur lesquels une roche apparaît ou disparaît en fondu

type Orbit = {
	radius: number,
	angle0: number,
	height: number,
	omega: number,
	t0: number,
	yaw: CFrame,
	root: BasePart?, -- la roche sur laquelle on marche
	fade: number, -- transparence de fondu actuelle (0 = bien visible)
	parts: { BasePart },
	offsets: { CFrame }, -- position de chaque pièce par rapport au pivot du modèle
}
local orbits: { [Instance]: Orbit } = {}

local function track(model: Instance)
	local radius = model:GetAttribute("Radius")
	if type(radius) ~= "number" or not model:IsA("Model") then
		return
	end
	local pivot = model:GetPivot()
	local o: Orbit = {
		radius = radius,
		angle0 = model:GetAttribute("Angle0") :: number,
		height = model:GetAttribute("Height") :: number,
		omega = model:GetAttribute("Omega") :: number,
		t0 = model:GetAttribute("T0") :: number,
		yaw = CFrame.Angles(0, (model:GetAttribute("Yaw") or 0) :: number, 0),
		root = model.PrimaryPart,
		fade = -1, -- forcé au premier calcul
		parts = {},
		offsets = {},
	}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(o.parts, d)
			table.insert(o.offsets, pivot:ToObjectSpace(d.CFrame))
		end
	end
	orbits[model] = o
end

folder.ChildAdded:Connect(track)
folder.ChildRemoved:Connect(function(model)
	orbits[model] = nil
end)
for _, model in ipairs(folder:GetChildren()) do
	track(model)
end

local parts: { BasePart } = {}
local cframes: { CFrame } = {}

RunService.PreRender:Connect(function()
	local t = workspace:GetServerTimeNow()
	table.clear(parts)
	table.clear(cframes)
	for _, o in pairs(orbits) do
		local angle = o.angle0 + o.omega * (t - o.t0)
		local pivot = CFrame.new(Config.OrbitPosition(o.radius, angle, o.height)) * o.yaw
		-- Apparition et disparition en fondu aux deux bouts du tapis (pas de roche qui « pop »)
		local fade = 1 - math.clamp((Config.Belt.SpawnArc - math.abs(angle * o.radius)) / FADE, 0, 1)
		local fadeChanged = math.abs(fade - o.fade) > 0.02 or (fade == 0 and o.fade ~= 0)
		if fadeChanged then
			o.fade = fade
		end
		for i, part in ipairs(o.parts) do
			table.insert(parts, part)
			table.insert(cframes, pivot * o.offsets[i])
			if fadeChanged then
				part.LocalTransparencyModifier = fade
			end
		end
		-- Vitesse tangentielle (dérivée de la position) : transporte le joueur posé dessus
		if o.root then
			local speed = o.radius * o.omega
			o.root.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * speed, 0, -math.sin(angle) * speed)
		end
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end)
