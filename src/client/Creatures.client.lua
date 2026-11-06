-- Créatures qui vivent dans les bases (tag « Creature », modèle 3D « Body » posé par HatchService).
-- Chaque créature se promène autour de son socle : elle choisit un point, y va en sautillant,
-- se pose, regarde autour d'elle, puis repart. Le trajet dépend seulement de l'heure du serveur
-- et de l'identifiant de la créature : tous les joueurs la voient au même endroit, sans réseau.
-- Ses pièces animées bougent aussi : Tail (balance), WingL / WingR (battent), Orbit (tourne).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local camera = workspace.CurrentCamera
local H = Config.Hatch
local MAX_DISTANCE = 160
local WALK = 0.45 -- part de la période passée à marcher (le reste : pause)

type Group = { model: Model, offset: CFrame, root: CFrame, kind: string, side: number }
type Pet = { body: Model, home: CFrame, seed: number, height: number, groups: { Group } }

local pets: { [Model]: Pet } = {}

-- Hasard reproductible (même résultat chez tous les clients)
local function hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

local function seedOf(id: string): number
	local h = 0
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 100000
	end
	return h
end

-- Point visé pendant le k-ième aller (k = 0 : le socle)
local function spot(p: Pet, k: number): Vector3
	if k % 4 == 0 then
		return Vector3.zero -- revient régulièrement sur son socle
	end
	local a = hash(p.seed + k * 7.1) * math.pi * 2
	local r = H.WanderRadius * (0.45 + 0.55 * hash(p.seed * 3 + k))
	return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

local function track(m: Instance)
	if not m:IsA("Model") or pets[m] or not m:GetAttribute("Has3D") then
		return
	end
	local body = m:WaitForChild("Body", 10) :: Model?
	local core = body and body:WaitForChild("Core", 10) :: BasePart?
	if not body or not core or pets[m] then
		return
	end
	task.wait(0.2) -- laisse arriver les pièces animées
	local p: Pet = {
		body = body,
		home = core.CFrame,
		seed = seedOf((m:GetAttribute("ItemId") or m.Name) :: string),
		height = (body:GetAttribute("Height") or 3) :: number,
		groups = {},
	}
	for _, child in ipairs(body:GetChildren()) do
		if child:IsA("Model") then
			local cf, size = child:GetBoundingBox()
			local rel = core.CFrame:ToObjectSpace(cf)
			local g: Group = { model = child, offset = core.CFrame:ToObjectSpace(child:GetPivot()), root = CFrame.new(), kind = child.Name, side = 1 }
			if child.Name == "WingL" or child.Name == "WingR" then
				-- l'aile bat autour de son bord le plus proche du corps
				g.side = if rel.Position.X >= 0 then 1 else -1
				g.root = CFrame.new(rel.Position - Vector3.new(g.side * size.X * 0.45, 0, 0))
			elseif child.Name == "Tail" then
				-- la queue balance autour de son attache (le bout le plus proche du centre du corps)
				local toBody = (Vector3.new(0, p.height * 0.45, 0) - rel.Position)
				g.root = CFrame.new(rel.Position + (if toBody.Magnitude > 0 then toBody.Unit else Vector3.zero) * size.Magnitude * 0.4)
			end
			table.insert(p.groups, g)
		end
	end
	pets[m] = p
end

CollectionService:GetInstanceAddedSignal("Creature"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Creature"):Connect(function(m)
	pets[m :: Model] = nil
end)
for _, m in ipairs(CollectionService:GetTagged("Creature")) do
	task.spawn(track, m)
end

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local camPos = camera.CFrame.Position
	for m, p in pairs(pets) do
		if not m.Parent or not p.body.Parent then
			pets[m] = nil
			continue
		end
		if (p.home.Position - camPos).Magnitude > MAX_DISTANCE then
			continue
		end
		local period = H.WanderPeriod * (0.85 + 0.3 * hash(p.seed))
		local t = now / period + hash(p.seed + 1)
		local k = math.floor(t)
		local f = t - k
		local from, to = spot(p, k - 1), spot(p, k)
		local walking = f < WALK
		local w = math.clamp(f / WALK, 0, 1)
		local e = w * w * (3 - 2 * w)
		local pos = from:Lerp(to, e)
		-- Direction : vers où elle va ; à l'arrêt, elle tourne un peu la tête de gauche à droite
		local dir = to - from
		local yaw = if dir.Magnitude > 0.05 then math.atan2(-dir.X, -dir.Z) else 0
		if not walking then
			yaw += math.sin((f - WALK) * 9) * 0.35 * math.sin(math.min(1, (f - WALK) * 4) * math.pi)
		end
		-- Sautillements en marchant, respiration à l'arrêt
		local hop = if walking then math.abs(math.sin(w * math.pi * 5)) * p.height * 0.07 else 0
		local squash = if walking then 1 else 1 + math.sin(now * 3 + p.seed) * 0.02
		local base = p.home * CFrame.new(pos.X, hop, pos.Z) * CFrame.Angles(0, yaw, 0)
		if dir.Magnitude <= 0.05 then
			-- Sur place (aller vers le socle depuis le socle) : garde l'orientation d'origine
			base = p.home * CFrame.new(pos.X, hop, pos.Z) * CFrame.Angles(0, if not walking then math.sin((f - WALK) * 9) * 0.3 else 0, 0)
		end
		base *= CFrame.Angles(if walking then math.sin(w * math.pi * 10) * 0.05 else 0, 0, 0)
		p.body:PivotTo(base * CFrame.new(0, (squash - 1) * p.height, 0))
		for _, g in ipairs(p.groups) do
			local cf
			if g.kind == "Orbit" then
				cf = base * CFrame.Angles(0, now * 1.2, 0) * g.offset
			elseif g.kind == "WingL" or g.kind == "WingR" then
				local a = math.sin(now * (if walking then 9 else 4) + p.seed) * 0.35 * g.side
				cf = base * g.root * CFrame.Angles(0, 0, a) * g.root:Inverse() * g.offset
			elseif g.kind == "Tail" then
				local a = math.sin(now * (if walking then 8 else 3) + p.seed) * (if walking then 0.35 else 0.18)
				cf = base * g.root * CFrame.Angles(0, a, 0) * g.root:Inverse() * g.offset
			else
				cf = base * g.offset
			end
			g.model:PivotTo(cf)
		end
	end
end)
