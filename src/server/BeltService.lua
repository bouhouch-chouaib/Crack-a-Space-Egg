-- Tapis d'astéroïdes : chaque anneau fait naître ses astéroïdes juste avant le couloir,
-- les fait défiler le long de son orbite, puis les supprime après le couloir.
-- Le serveur ne déplace pas les pièces : il garde la formule du mouvement (attributs répliqués)
-- et chaque client anime sa copie (Belt.client). Le serveur reste maître des PV et des stocks d'œufs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local WorldBuilder = require(script.Parent.WorldBuilder)
local EventService = require(script.Parent.EventService)

local BeltService = {}

type Asteroid = {
	part: BasePart, -- la roche « Asteroid » (PrimaryPart) : c'est elle qu'on vise et qu'on fore
	model: Model,
	ring: number,
	radius: number,
	angle0: number,
	height: number,
	omega: number,
	t0: number,
	tEnd: number,
	stock: number,
	maxStock: number,
	hp: number,
	progress: { [Player]: number }, -- dégâts accumulés par joueur vers le prochain œuf
}

local rng = Random.new()
local active: { [BasePart]: Asteroid } = {}
local count = 0
local folder: Folder
local nextSpawn: { number } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function travelTime(ringIndex: number): number
	return 2 * Config.Belt.SpawnArc / Config.Rings[ringIndex].Speed
end

local function pickSize()
	local x = rng:NextNumber()
	local acc = 0
	for _, s in ipairs(Config.AsteroidSizes) do
		acc += s.Chance
		if x < acc then
			return s
		end
	end
	return Config.AsteroidSizes[1]
end

-- Position d'un astéroïde à l'instant t (même formule que Belt.client)
function BeltService.Position(a: Asteroid, t: number): Vector3
	return Config.OrbitPosition(a.radius, a.angle0 + a.omega * (t - a.t0), a.height)
end

function BeltService.Get(part: Instance): Asteroid?
	return active[part :: BasePart]
end

-- Joueurs qui se tenaient sur une roche qui vient de casser ou de disparaître : délai de grâce
-- (lu par GameService.watchFalls : une chute pendant ce délai ne fait pas perdre la soute)
BeltService.Grace = {} :: { [Player]: number }

local function rescueRiders(a: Asteroid)
	local pos = BeltService.Position(a, now())
	local s = a.part.Size
	local reach = math.max(s.X, s.Y, s.Z) / 2 + 8
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and (hrp.Position - pos).Magnitude <= reach then
			BeltService.Grace[player] = os.clock() + Config.RescueTime
		end
	end
end

local function remove(a: Asteroid)
	rescueRiders(a)
	if active[a.part] then
		active[a.part] = nil
		count -= 1
	end
	a.model:Destroy()
end

-- Le modèle de l'anneau (ReplicatedStorage.Assets.Asteroids.RingN) à la bonne taille,
-- ou une boule grise s'il n'existe pas encore
local function build(ringIndex: number, diameter: number): Model
	local model = WorldBuilder.Asset("Asteroids", "Ring" .. ringIndex)
	if model then
		model:ScaleTo(diameter / WorldBuilder.Width(model))
		return model
	end
	local ring = Config.Rings[ringIndex]
	local m = Instance.new("Model")
	local p = Instance.new("Part")
	p.Name = "Asteroid"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * diameter
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Slate
	p.Color = ring.Color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25))
	p.Parent = m
	m.PrimaryPart = p
	return m
end

-- age : secondes déjà écoulées depuis la naissance (pour remplir le tapis au démarrage)
local function spawn(ringIndex: number, age: number)
	local ring = Config.Rings[ringIndex]
	local size = pickSize()
	local diameter = rng:NextNumber(size.Min, size.Max)
	local width = Config.RingWidth(ringIndex)
	local margin = math.max(0, width / 2 - diameter / 2)
	local field = Config.FieldHeight(ringIndex)
	local t0 = now() - age
	local eggs = math.ceil(rng:NextInteger(size.Eggs[1], size.Eggs[2]) * EventService.EggMult())
	-- Place sur toute l'épaisseur et la hauteur du champ, sans chevaucher un voisin du même anneau
	-- (même vitesse linéaire : deux voisins gardent à peu près leur écart en défilant)
	local radius, height
	for attempt = 1, 6 do
		local B = Config.Belt
		if rng:NextNumber() < B.WalkShare then
			-- Couche de marche : à hauteur du pont, côté intérieur de l'anneau (atteignable)
			radius = Config.RingRadius(ringIndex) - margin + rng:NextNumber(0, 2 * margin * B.WalkDepth)
			height = rng:NextNumber(B.WalkHeight[1], B.WalkHeight[2])
		else
			radius = Config.RingRadius(ringIndex) + rng:NextNumber(-margin, margin)
			height = rng:NextNumber(-field, field)
		end
		local angle = -Config.Belt.SpawnArc / radius + ring.Speed / radius * age
		local pos = Config.OrbitPosition(radius, angle, height)
		local free = true
		for _, other in pairs(active) do
			if other.ring == ringIndex then
				local gap = (other.part.Size.X + diameter) / 2 * Config.Belt.Spacing
				if (BeltService.Position(other, now()) - pos).Magnitude < gap then
					free = false
					break
				end
			end
		end
		if free then
			break
		elseif attempt == 6 then
			return -- champ trop plein à cet endroit : on réessaiera au prochain tour
		end
	end
	local a: Asteroid = {
		part = nil :: any,
		model = nil :: any,
		ring = ringIndex,
		radius = radius,
		angle0 = -Config.Belt.SpawnArc / radius,
		height = height,
		omega = ring.Speed / radius,
		t0 = t0,
		tEnd = t0 + travelTime(ringIndex),
		stock = eggs,
		maxStock = eggs,
		hp = eggs * ring.EggHP,
		progress = {},
	}

	local model = build(ringIndex, diameter)
	local yaw = rng:NextNumber(0, math.pi * 2)
	model.Name = "Ring" .. ringIndex
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- le modèle arrive entier chez le client
	model:PivotTo(CFrame.new(BeltService.Position(a, now())) * CFrame.Angles(0, yaw, 0))
	-- Formule du mouvement, lue par les clients
	model:SetAttribute("Ring", ringIndex)
	model:SetAttribute("Radius", a.radius)
	model:SetAttribute("Angle0", a.angle0)
	model:SetAttribute("Height", a.height)
	model:SetAttribute("Omega", a.omega)
	model:SetAttribute("T0", a.t0)
	model:SetAttribute("Yaw", yaw)
	-- État du forage, sur la roche visée (lu par l'interface)
	local p = model.PrimaryPart :: BasePart
	p.Name = "Asteroid"
	p:SetAttribute("Ring", ringIndex)
	p:SetAttribute("MaxHP", a.hp)
	p:SetAttribute("HP", a.hp)
	p:SetAttribute("Eggs", a.stock)
	p:SetAttribute("MaxEggs", a.maxStock)
	p:SetAttribute("Size", size.Name)
	a.part = p
	a.model = model
	active[p] = a
	count += 1
	model.Parent = folder
end

local function step()
	local t = now()
	for _, a in pairs(active) do
		if t >= a.tEnd then
			remove(a)
		end
	end
	for i, ring in ipairs(Config.Rings) do
		if t >= nextSpawn[i] then
			if count < Config.Belt.MaxActive then
				spawn(i, 0)
			end
			-- Pendant une pluie de météores, les astéroïdes arrivent plus souvent
			nextSpawn[i] = t + travelTime(i) / ring.Active * rng:NextNumber(0.6, 1.4) / EventService.SpawnMult()
		end
	end
end

-- Coup de foreuse : renvoie le nombre d'œufs détachés pour ce joueur (0 si rien), si l'astéroïde
-- vient de se briser, et l'avancée du joueur sur l'œuf en cours (0..EggHP). On fore œuf par œuf :
-- chaque barre de vie correspond à un seul œuf. room = place libre dans la soute.
function BeltService.Hit(a: Asteroid, player: Player, damage: number, room: number): (number, boolean, number)
	local ring = Config.Rings[a.ring]
	a.progress[player] = (a.progress[player] or 0) + damage
	a.hp = math.max(0, a.hp - damage)
	local eggs = 0
	while a.progress[player] >= ring.EggHP and a.stock > 0 and eggs < room do
		a.progress[player] -= ring.EggHP
		a.stock -= 1
		eggs += 1
	end
	-- La barre de vie suit le stock restant (à plusieurs, les progrès partiels la font baisser un peu plus vite)
	a.hp = math.clamp(a.hp, if a.stock > 0 then ring.EggHP * 0.05 else 0, a.stock * ring.EggHP)
	a.part:SetAttribute("HP", a.hp)
	a.part:SetAttribute("Eggs", a.stock)
	if a.stock <= 0 then
		rescueRiders(a)
		-- On ne cache pas la roche ici : chaque client la fait voler en éclats (Impact.client).
		-- On la rend juste intraversable et non visable, et on la supprime un peu plus tard.
		for _, d in ipairs(a.model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
			end
		end
		if active[a.part] then
			active[a.part] = nil
			count -= 1
		end
		task.delay(1, function()
			a.model:Destroy()
		end)
		return eggs, true, 0
	end
	return eggs, false, a.progress[player] or 0
end

function BeltService.Start()
	folder = workspace:WaitForChild("World"):WaitForChild("Belt") :: Folder
	-- Remplit le tapis dès le démarrage : des astéroïdes à tous les stades de leur traversée
	for i, ring in ipairs(Config.Rings) do
		local travel = travelTime(i)
		for k = 1, ring.Active do
			spawn(i, travel * (k - rng:NextNumber(0.2, 0.8)) / ring.Active)
		end
		nextSpawn[i] = now() + travel / ring.Active * rng:NextNumber(0.3, 1)
	end
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		for _, a in pairs(active) do
			a.progress[player] = nil
		end
	end)
end

return BeltService
