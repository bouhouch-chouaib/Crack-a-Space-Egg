-- Anime le tapis d'astéroïdes sur ce client, image par image.
-- Chaque astéroïde porte la formule de son mouvement (attributs posés par BeltService) :
-- on calcule sa position à partir du temps serveur, donc tous les clients voient la même chose.
-- La vitesse donnée à la pièce entraîne le joueur qui se tient dessus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local folder = workspace:WaitForChild("World"):WaitForChild("Belt")

type Orbit = { radius: number, angle0: number, height: number, omega: number, t0: number }
local orbits: { [BasePart]: Orbit } = {}

local function track(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local radius = part:GetAttribute("Radius")
	if type(radius) ~= "number" then
		return
	end
	orbits[part] = {
		radius = radius,
		angle0 = part:GetAttribute("Angle0") :: number,
		height = part:GetAttribute("Height") :: number,
		omega = part:GetAttribute("Omega") :: number,
		t0 = part:GetAttribute("T0") :: number,
	}
end

folder.ChildAdded:Connect(track)
folder.ChildRemoved:Connect(function(part)
	orbits[part :: BasePart] = nil
end)
for _, part in ipairs(folder:GetChildren()) do
	track(part)
end

local parts: { BasePart } = {}
local cframes: { CFrame } = {}

RunService.PreRender:Connect(function()
	local t = workspace:GetServerTimeNow()
	table.clear(parts)
	table.clear(cframes)
	for part, o in pairs(orbits) do
		local angle = o.angle0 + o.omega * (t - o.t0)
		table.insert(parts, part)
		table.insert(cframes, CFrame.new(Config.OrbitPosition(o.radius, angle, o.height)))
		-- Vitesse tangentielle (dérivée de la position) : transporte le joueur posé dessus
		local speed = o.radius * o.omega
		part.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * speed, 0, -math.sin(angle) * speed)
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end)
