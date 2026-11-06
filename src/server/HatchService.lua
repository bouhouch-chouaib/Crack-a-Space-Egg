-- Éclosion dans la base (docs/Mecaniques.md §7).
-- 1. Le joueur pose un œuf dérroché (Remotes.PlaceEgg) où il veut sur le sol de sa base.
-- 2. L'œuf (vrai modèle, animé par Eggs.client) incube : HatchAt = fin, en temps Unix (le temps
--    passe aussi hors ligne). Le client affiche le compte à rebours (Hatchery.client).
-- 3. Quand il est prêt, le propriétaire appuie sur « Hatch » : l'œuf tremble et éclate,
--    la créature de l'anneau et de la rareté naît à sa place (Remotes.Hatched pour les effets).
-- 4. Chaque créature rapporte des $ chaque seconde (Config.CreatureIncome).
-- Les positions sont gardées dans le repère du sol de la base : tout se reconstruit au retour du joueur,
-- même s'il obtient une autre base.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Bases = require(script.Parent.Bases)

local Remotes = ReplicatedStorage.Remotes
local H = Config.Hatch

local HatchService = {}

local rng = Random.new()
local models: { [Player]: { [string]: Model } } = {}
local remainder: { [Player]: number } = {}
local nextId = 0

local function floorOf(base: Model): BasePart?
	return base:FindFirstChild("Floor") :: BasePart?
end

local function folderOf(base: Model): Folder
	local f = base:FindFirstChild("Hatchery") :: Folder?
	if not f then
		local nf = Instance.new("Folder")
		nf.Name = "Hatchery"
		nf.Parent = base
		f = nf
	end
	return f :: Folder
end

-- Point du sol (x, z dans le repère du sol) en coordonnées du monde, à la surface
local function surface(floor: BasePart, x: number, z: number): CFrame
	local top = floor.CFrame * CFrame.new(x, floor.Size.Y / 2, z)
	return CFrame.new(top.Position) * (floor.CFrame - floor.CFrame.Position)
end

local function totalIncome(d): number
	local sum = 0
	for _, item in ipairs(d.base) do
		if item.kind == "pet" then
			sum += item.income or 0
		end
	end
	return sum
end

local function syncBase(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	player:SetAttribute("BaseUsed", #d.base)
	player:SetAttribute("BaseSlots", H.Slots)
	player:SetAttribute("Income", totalIncome(d))
	GameService.Sync(player)
end

-- MODÈLES DANS LA BASE --------------------------------------------------------------

-- Œuf en incubation : le vrai modèle, réduit à la taille de la base, avec le bouton « Hatch »
local function buildEgg(player: Player, floor: BasePart, item): Model?
	local eggs = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Eggs")
	local template = eggs and eggs:FindFirstChild(("R%d_T%d"):format(item.ring, item.rarity))
	if not template then
		warn("[Hatch] Modèle d'œuf absent", item.ring, item.rarity)
		return nil
	end
	local m = template:Clone() :: Model
	local h = H.EggHeight[item.rarity] or 3
	local body = (m:GetAttribute("BodyHeight") or 1) :: number
	m:ScaleTo(m:GetScale() * h / body)
	m:SetAttribute("BodyHeight", h)
	-- Les effets du modèle étaient réglés pour sa grande taille : on les ramène à la taille posée
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Name == "Rays" then
			d.Size = UDim2.fromScale(h * 1.9, h * 1.9)
		elseif d:IsA("ParticleEmitter") and d.Name == "Aura" then
			d.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, h * 0.9), NumberSequenceKeypoint.new(1, h * 1.3) })
		elseif d:IsA("ParticleEmitter") and d.Name == "Sparkles" then
			d.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35 + item.rarity * 0.06), NumberSequenceKeypoint.new(1, 0) })
		end
	end
	local yaw = CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)
	m:PivotTo(surface(floor, item.x, item.z) * CFrame.new(0, h / 2 + 0.6, 0) * yaw)
	m.Name = "Egg_" .. item.id
	m:SetAttribute("Owner", player.UserId)
	m:SetAttribute("ItemId", item.id)
	m:SetAttribute("HatchAt", item.hatchAt)
	m:SetAttribute("HatchTime", H.Time[item.rarity] or 60)
	m:SetAttribute("EggName", Config.EggName(item.ring, item.rarity))
	CollectionService:AddTag(m, "Incubating")
	local core = m.PrimaryPart :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HatchPrompt"
	prompt.ActionText = "Hatch!"
	prompt.ObjectText = Config.EggName(item.ring, item.rarity)
	-- F (et pas E) : la machine à dérocher, juste à côté, utilise déjà E
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10 + h
	prompt.RequiresLineOfSight = false
	prompt.Enabled = os.time() >= item.hatchAt
	prompt.Parent = core
	prompt.Triggered:Connect(function(who)
		HatchService.Hatch(who, item.id)
	end)
	m.Parent = folderOf(floor.Parent :: Model)
	return m
end

-- Créature : socle à la couleur de sa rareté + centre invisible. Le client affiche sa carte
-- (image, nom, $/s) tant que les modèles 3D des créatures ne sont pas faits.
local function buildPet(player: Player, floor: BasePart, item): Model
	local m = Instance.new("Model")
	m.Name = "Pet_" .. item.id
	local r = Config.Rarities[item.rarity] or Config.Rarities[1]
	local at = surface(floor, item.x, item.z)
	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.5, 3.6, 3.6)
	pad.CFrame = at * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.pi / 2)
	pad.Color = r.Color
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.CanCollide = false
	pad.CanTouch = false
	pad.Parent = m
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.one
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.CFrame = at * CFrame.new(0, 2.6, 0)
	core.Parent = m
	m.PrimaryPart = core
	m:SetAttribute("Owner", player.UserId)
	m:SetAttribute("ItemId", item.id)
	m:SetAttribute("Ring", item.ring)
	m:SetAttribute("Rarity", item.rarity)
	m:SetAttribute("Creature", item.name)
	m:SetAttribute("Size", item.size)
	m:SetAttribute("Income", item.income)
	CollectionService:AddTag(m, "Creature")
	m.Parent = folderOf(floor.Parent :: Model)
	return m
end

local function build(player: Player, item)
	local base = Bases.Get(player)
	local floor = base and floorOf(base)
	if not floor then
		return
	end
	models[player] = models[player] or {}
	local old = models[player][item.id]
	if old then
		old:Destroy()
	end
	local m = if item.kind == "egg" then buildEgg(player, floor, item) else buildPet(player, floor, item)
	if m then
		models[player][item.id] = m
	end
end

local function clear(player: Player)
	for _, m in pairs(models[player] or {}) do
		m:Destroy()
	end
	models[player] = nil
end

-- POSER UN ŒUF ------------------------------------------------------------------------

-- Une place est libre si elle est sur le sol (loin des murs), loin de la machine, du point
-- d'apparition et des autres objets posés
function HatchService.CanPlace(base: Model, d, x: number, z: number): (boolean, string?)
	local floor = floorOf(base)
	if not floor then
		return false, "No floor"
	end
	local hx, hz = floor.Size.X / 2 - H.Margin, floor.Size.Z / 2 - H.Margin
	if math.abs(x) > hx or math.abs(z) > hz then
		return false, "Too close to the wall"
	end
	for name, radius in pairs(H.KeepOut) do
		local thing = base:FindFirstChild(name)
		local pos = if thing and thing:IsA("Model") then thing:GetPivot().Position elseif thing and thing:IsA("BasePart") then thing.Position else nil
		if pos then
			local p = floor.CFrame:PointToObjectSpace(pos)
			if Vector2.new(p.X - x, p.Z - z).Magnitude < radius then
				return false, if name == "Spawn" then "Not on the spawn!" else "Too close to the machine"
			end
		end
	end
	for _, item in ipairs(d.base) do
		if Vector2.new(item.x - x, item.z - z).Magnitude < H.Gap then
			return false, "Too close to another egg"
		end
	end
	return true, nil
end

local function placeEgg(player: Player, ring: any, rarity: any, x: any, z: any)
	if type(ring) ~= "number" or type(rarity) ~= "number" or type(x) ~= "number" or type(z) ~= "number" then
		return
	end
	if x ~= x or z ~= z then
		return -- NaN
	end
	local d = DataService.Get(player)
	local base = Bases.Get(player)
	if not d or not base then
		return
	end
	if #d.base >= H.Slots then
		GameService.Notice(player, "Your base is full! (" .. H.Slots .. " max)", "warn")
		return
	end
	local index = nil
	for i, egg in ipairs(d.ready) do
		if egg.ring == ring and egg.rarity == rarity then
			index = i
			break
		end
	end
	if not index then
		return
	end
	local ok, why = HatchService.CanPlace(base, d, x, z)
	if not ok then
		GameService.Notice(player, why or "You can't place it here", "warn")
		return
	end
	table.remove(d.ready, index)
	nextId += 1
	local item = {
		kind = "egg",
		id = ("%d%03d"):format(os.time(), nextId % 1000),
		ring = ring,
		rarity = rarity,
		x = x,
		z = z,
		hatchAt = os.time() + (H.Time[rarity] or 60),
	}
	table.insert(d.base, item)
	build(player, item)
	syncBase(player)
end

-- ÉCLOSION ------------------------------------------------------------------------------

function HatchService.Hatch(player: Player, id: string)
	local d = DataService.Get(player)
	if not d then
		return
	end
	local item = nil
	for _, it in ipairs(d.base) do
		if it.id == id then
			item = it
			break
		end
	end
	local m = models[player] and models[player][id]
	if not item or item.kind ~= "egg" or not m then
		-- L'œuf d'un autre joueur
		if not item then
			GameService.Notice(player, "This is not your egg", "warn")
		end
		return
	end
	if os.time() < item.hatchAt then
		GameService.Notice(player, "Not ready yet!", "info")
		return
	end
	-- La créature est décidée tout de suite (pas de double éclosion possible)
	local c = Config.CreatureFor(item.ring, item.rarity)
	local size = rng:NextNumber(c.Size[1], c.Size[2])
	item.kind = "pet"
	item.name = c.Name
	item.size = math.floor(size * 100 + 0.5) / 100
	item.weight = math.floor(rng:NextNumber(c.Weight[1], c.Weight[2]) * 10 + 0.5) / 10
	item.income = Config.CreatureIncome(item.ring, item.rarity, item.size)
	item.hatchAt = nil
	local key = item.ring .. ":" .. item.rarity
	d.index[key] = (d.index[key] or 0) + 1
	d.stats.best = math.max(d.stats.best, item.rarity)
	-- L'œuf tremble et se fissure chez tous les clients, puis éclate
	local prompt = m:FindFirstChild("HatchPrompt", true) :: ProximityPrompt?
	if prompt then
		prompt.Enabled = false
	end
	m:SetAttribute("Hatching", workspace:GetServerTimeNow())
	local pos = m:GetPivot().Position
	task.delay(H.Burst or 1.6, function()
		if models[player] and models[player][id] == m then
			m:Destroy()
			models[player][id] = nil
		end
		if player.Parent then
			build(player, item)
			syncBase(player)
			Remotes.Hatched:FireAllClients(player, pos, item.ring, item.rarity, item.name, item.income, item.size)
			if item.rarity >= Config.AnnounceFrom then
				Remotes.Announcement:FireAllClients(player.DisplayName, item.name, item.rarity)
			end
		end
	end)
end

-- REVENUS --------------------------------------------------------------------------------

local function payIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(player)
		if d and d.base then
			local inc = totalIncome(d)
			if inc > 0 then
				-- Les $ sont entiers : on garde les fractions pour la seconde suivante
				local total = (remainder[player] or 0) + inc
				local whole = math.floor(total)
				remainder[player] = total - whole
				if whole > 0 then
					d.credits += whole
					GameService.Sync(player)
				end
			end
		end
	end
end

-- Œufs prêts : on active le bouton « Hatch »
local function refreshPrompts()
	local now = os.time()
	for player, list in pairs(models) do
		local d = DataService.Get(player)
		if d then
			for _, item in ipairs(d.base) do
				local m = list[item.id]
				if item.kind == "egg" and m and now >= item.hatchAt and not m:GetAttribute("Hatching") then
					local prompt = m:FindFirstChild("HatchPrompt", true) :: ProximityPrompt?
					if prompt and not prompt.Enabled then
						prompt.Enabled = true
					end
				end
			end
		end
	end
end

function HatchService.Start()
	Remotes.PlaceEgg.OnServerEvent:Connect(placeEgg)
	DataService.Loaded:Connect(function(player: Player)
		local d = DataService.Get(player)
		if not d then
			return
		end
		d.base = d.base or {}
		-- Attendre la base (attribuée à l'arrivée du joueur)
		for _ = 1, 50 do
			if Bases.Get(player) then
				break
			end
			task.wait(0.1)
		end
		for _, item in ipairs(d.base) do
			build(player, item)
		end
		syncBase(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		clear(player)
		remainder[player] = nil
	end)
	-- Studio seulement : point d'accès de test (donner des œufs prêts, finir les incubations, lire l'état)
	if RunService:IsStudio() then
		local debug = Instance.new("BindableFunction")
		debug.Name = "HatchDebug"
		debug.OnInvoke = function(cmd: string, arg: any)
			local player = Players:GetPlayers()[1]
			local d = player and DataService.Get(player)
			if not d then
				return "pas de partie chargée"
			end
			if cmd == "give" then
				for _, e in ipairs(arg) do
					table.insert(d.ready, { ring = e[1], rarity = e[2] })
				end
			elseif cmd == "finish" then
				for _, item in ipairs(d.base) do
					if item.kind == "egg" then
						item.hatchAt = os.time()
						local m = models[player] and models[player][item.id]
						if m then
							m:SetAttribute("HatchAt", item.hatchAt)
						end
					end
				end
			end
			syncBase(player)
			local parts = {}
			for _, item in ipairs(d.base) do
				table.insert(parts, ("%s %d:%d (%.1f,%.1f)%s"):format(item.kind, item.ring, item.rarity, item.x, item.z, if item.name then " " .. item.name .. " $" .. item.income .. "/s" else ""))
			end
			return ("credits=%d ready=%d base=[%s]"):format(d.credits, #d.ready, table.concat(parts, "; "))
		end
		debug.Parent = game:GetService("ServerStorage")
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 1 then
			acc -= 1
			payIncome()
			refreshPrompts()
		end
	end)
end

return HatchService
