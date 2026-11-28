-- Tapis d'astéroïdes : chaque anneau fait naître ses astéroïdes juste avant le couloir,
-- les fait défiler le long de son orbite, puis les supprime après le couloir.
-- Le serveur ne déplace pas les pièces : il garde la formule du mouvement (attributs répliqués)
-- et chaque client anime sa copie (Belt.client). Le serveur reste maître des PV et des stocks d'œufs.
-- Chaque anneau a 3 types d'astéroïdes (Config.RockTypes), rangés par profondeur : tendres du côté du
-- vaisseau, durs au fond. Le type fixe la taille, le stock, la vie de chaque œuf, l'apparence
-- (shared/RockLook) et ce qu'on y trouve (GameService).
-- Répartition (30 nov.) : chaque type naît à son propre rythme régulier dans chaque anneau (sa part des
-- astéroïdes, Share), au lieu d'être tiré au hasard à chaque naissance : les trois types défilent en même
-- temps, espacés régulièrement, sans long moment sans l'un d'eux.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local RockLook = require(game:GetService("ReplicatedStorage").Shared.RockLook)
local WorldBuilder = require(script.Parent.WorldBuilder)

local BeltService = {}

type Asteroid = {
	part: BasePart, -- la roche « Asteroid » (PrimaryPart) : c'est elle qu'on vise et qu'on fore
	model: Model,
	ring: number,
	type: number, -- type d'astéroïde (index dans Config.RockTypes)
	eggHP: number, -- dégâts pour détacher un œuf (EggHP de l'anneau × HP du type)
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
local nextSpawn: { { number } } = {} -- par anneau puis par type : heure de la prochaine naissance
local tries: { { number } } = {} -- naissances ratées de suite (place prise)

local function now(): number
	return workspace:GetServerTimeNow()
end

local function travelTime(ringIndex: number): number
	return 2 * Config.Belt.SpawnArc / Config.Rings[ringIndex].Speed
end

-- Secondes entre deux naissances d'un type dans un anneau : sa part des Active astéroïdes de la traversée
local function interval(ringIndex: number, rockType: number): number
	return travelTime(ringIndex) / math.max(0.01, Config.Rings[ringIndex].Active * Config.RockTypes[rockType].Share)
end

local function jitter(): number
	return 1 + rng:NextNumber(-Config.Belt.Jitter, Config.Belt.Jitter)
end

-- Position d'un astéroïde à l'instant t (même formule que Belt.client)
function BeltService.Position(a: Asteroid, t: number): Vector3
	return Config.OrbitPosition(a.radius, a.angle0 + a.omega * (t - a.t0), a.height)
end

function BeltService.Get(part: Instance): Asteroid?
	return active[part :: BasePart]
end

-- Position de l'astéroïde de l'anneau le plus proche d'un point (dans maxDist), pour la sortie d'un monstre
function BeltService.NearestPosition(pos: Vector3, ringIndex: number, maxDist: number): Vector3?
	local best, bestDist = nil, maxDist
	local t = now()
	for _, a in pairs(active) do
		if a.ring == ringIndex then
			local p = BeltService.Position(a, t)
			local d = (p - pos).Magnitude
			if d < bestDist then
				best, bestDist = p, d
			end
		end
	end
	return best
end

-- Astéroïde (tous anneaux) le plus proche d'un point dans maxDist, et sa position à cet instant
-- (MonsterService : la roche du joueur attrapé y retombe)
function BeltService.NearestAsteroid(pos: Vector3, maxDist: number): (Asteroid?, Vector3?)
	local best, bestPos, bestDist = nil, nil, maxDist
	local t = now()
	for _, a in pairs(active) do
		local p = BeltService.Position(a, t)
		local d = (p - pos).Magnitude
		if d < bestDist then
			best, bestPos, bestDist = a, p, d
		end
	end
	return best, bestPos
end

-- Astéroïdes vivants d'un anneau (MonsterService : les monstres se promènent de roche en roche)
function BeltService.InRing(ringIndex: number): { Asteroid }
	local list = {}
	for _, a in pairs(active) do
		if a.ring == ringIndex then
			table.insert(list, a)
		end
	end
	return list
end

-- L'astéroïde est-il encore là (pas cassé ni sorti du couloir) ?
function BeltService.Alive(a: Asteroid): boolean
	return active[a.part] == a
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

-- Le modèle de ce type dans cet anneau (ReplicatedStorage.Assets.Asteroids.RingN.<forme>) à la bonne
-- taille, avec les picots à la couleur du type ; ou une boule grise s'il n'existe pas encore
local function build(ringIndex: number, diameter: number, rockType: number): Model
	local template = RockLook.Template(ringIndex, rockType)
	local model = template and template:Clone()
	if model then
		model:ScaleTo(diameter / WorldBuilder.Width(model))
		RockLook.Apply(model, rockType)
		-- ScaleTo agrandit aussi les picots : on les ramène à la taille de ceux du vaisseau
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Texture") and d.Name == "Studs" then
				d.StudsPerTileU = Config.AsteroidStudTile
				d.StudsPerTileV = Config.AsteroidStudTile
			end
		end
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

-- age : secondes déjà écoulées depuis la naissance (pour remplir le tapis au démarrage).
-- Renvoie faux si la place était prise (rien n'est né).
local function spawn(ringIndex: number, rockType: number, age: number): boolean
	local ring = Config.Rings[ringIndex]
	local size = Config.RockTypes[rockType]
	local diameter = rng:NextNumber(size.Min, size.Max)
	local width = Config.RingWidth(ringIndex)
	local field = Config.FieldHeight(ringIndex)
	-- bande de profondeur du type (du bord côté vaisseau vers le fond), sans dépasser de l'anneau
	local inner = Config.RingRadius(ringIndex) - width / 2
	local lo = math.max(inner + width * size.Depth[1], inner + math.min(diameter, width) / 2)
	local hi = math.min(inner + width * size.Depth[2], inner + width - math.min(diameter, width) / 2)
	if lo > hi then
		lo, hi = (lo + hi) / 2, (lo + hi) / 2
	end
	local t0 = now() - age
	local eggs = math.ceil(rng:NextInteger(size.Eggs[1], size.Eggs[2]))
	-- Place sur toute l'épaisseur et la hauteur du champ, sans chevaucher un voisin du même anneau
	-- (même vitesse linéaire : deux voisins gardent à peu près leur écart en défilant)
	local radius, height
	for attempt = 1, 6 do
		local B = Config.Belt
		radius = rng:NextNumber(lo, hi)
		if rockType == 1 and rng:NextNumber() < B.WalkShare then
			-- Couche de marche : les astéroïdes tendres, côté vaisseau, passent surtout à hauteur du pont
			height = rng:NextNumber(B.WalkHeight[1], B.WalkHeight[2])
		else
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
			return false -- champ trop plein à cet endroit : on réessaie un peu plus tard
		end
	end
	local a: Asteroid = {
		part = nil :: any,
		model = nil :: any,
		ring = ringIndex,
		type = rockType,
		eggHP = ring.EggHP * size.HP,
		radius = radius,
		angle0 = -Config.Belt.SpawnArc / radius,
		height = height,
		omega = ring.Speed / radius,
		t0 = t0,
		tEnd = t0 + travelTime(ringIndex),
		stock = eggs,
		maxStock = eggs,
		hp = eggs * ring.EggHP * size.HP,
		progress = {},
	}

	local model = build(ringIndex, diameter, rockType)
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
	p:SetAttribute("Size", if rockType == 1 then "" else (string.split(size.Name, " ")[1])) -- « SILVER ROCK », « GOLD ROCK » (barre de vie)
	p:SetAttribute("Rock", rockType)
	p:SetAttribute("EggHP", a.eggHP)
	a.part = p
	a.model = model
	active[p] = a
	count += 1
	model.Parent = folder
	return true
end

local function step()
	local t = now()
	for _, a in pairs(active) do
		if t >= a.tEnd then
			remove(a)
		end
	end
	local B = Config.Belt
	for i in ipairs(Config.Rings) do
		for k in ipairs(Config.RockTypes) do
			local due = nextSpawn[i][k]
			if t >= due then
				if count < B.MaxActive and not spawn(i, k, 0) and tries[i][k] < B.Retries then
					-- place prise : on réessaie bientôt, sans perdre le tour de ce type
					tries[i][k] += 1
					nextSpawn[i][k] = t + B.Retry
				else
					-- le rythme part de l'heure prévue, pas de l'heure réelle : il ne dérive pas
					tries[i][k] = 0
					nextSpawn[i][k] = math.max(due, t - interval(i, k)) + interval(i, k) * jitter()
				end
			end
		end
	end
end

-- Coup de foreuse : renvoie le nombre d'œufs détachés pour ce joueur (0 si rien), si l'astéroïde
-- vient de se briser, et l'avancée du joueur sur l'œuf en cours (0..EggHP). On fore œuf par œuf :
-- chaque barre de vie correspond à un seul œuf. room = place libre dans la soute.
function BeltService.Hit(a: Asteroid, player: Player, damage: number, room: number): (number, boolean, number)
	local eggHP = a.eggHP
	a.progress[player] = (a.progress[player] or 0) + damage
	a.hp = math.max(0, a.hp - damage)
	local eggs = 0
	while a.progress[player] >= eggHP and a.stock > 0 and eggs < room do
		a.progress[player] -= eggHP
		a.stock -= 1
		eggs += 1
	end
	-- La barre de vie suit le stock restant (à plusieurs, les progrès partiels la font baisser un peu plus vite)
	a.hp = math.clamp(a.hp, if a.stock > 0 then eggHP * 0.05 else 0, a.stock * eggHP)
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
	-- (chaque type à son rythme, décalé au hasard pour que les trois ne naissent pas ensemble)
	for i in ipairs(Config.Rings) do
		local travel = travelTime(i)
		nextSpawn[i] = {}
		tries[i] = {}
		for k in ipairs(Config.RockTypes) do
			local gap = interval(i, k)
			local youngest = gap * rng:NextNumber(0.1, 0.9) -- âge du dernier né de ce type
			local age = youngest
			while age < travel do
				spawn(i, k, math.clamp(age + gap * rng:NextNumber(-Config.Belt.Jitter, Config.Belt.Jitter), 0, travel - 1))
				age += gap
			end
			nextSpawn[i][k] = now() + gap - youngest
			tries[i][k] = 0
		end
	end
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		for _, a in pairs(active) do
			a.progress[player] = nil
		end
	end)
end

return BeltService
