-- Monstres de chaque anneau (Config.Monsters, docs/Mecaniques.md §13 et §0) : deux petits aux anneaux 1 et 2
-- (ils poursuivent dès le premier œuf, mais on les sème toujours), les grands à partir du 3e.
-- Un seul monstre par anneau, toujours là (20 nov.) : il se promène dans le couloir de son anneau
-- (Config.MonsterPatrol, le même calcul chez les clients). Dès qu'un joueur sort un œuf d'un astéroïde
-- de son anneau, il fonce droit sur lui et le poursuit jusqu'à la ligne rouge de la cour (29 nov. : il ne
-- la passe plus ; avant, il allait jusqu'à la base du joueur).
-- Le serveur décide : cible, poursuite, prise, retour. Il ne déplace pas de modèle : chaque monstre est
-- un dossier dans Workspace.World.Monsters dont les attributs sont lus par MonsterFx.client, qui anime
-- le modèle chez chaque joueur.
--   Kind (anneau), Size, State (Patrol / Chase / Return), Target (UserId, 0 = personne),
--   Pos, Look (publiés pendant Chase et Return ; en Patrol le client calcule la position),
--   ChaseAt (heure serveur du début de la poursuite), Reason (fin de poursuite : line / caught / lost),
--   Stunned (heure serveur de fin)
-- Publié sur le joueur : Chased (heure de fin, pendant qu'il est poursuivi).
-- Vitesse : chaque monstre demande une Speed de jetpack (Kinds[].Need) ; en dessous, il va d'autant
-- plus vite que le joueur en manque. S'il l'attrape, le joueur est projeté et sa roche retombe sur
-- l'astéroïde le plus proche (Workspace.World.LostRocks), à reprendre en DropTime s.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local BeltService = require(script.Parent.BeltService)
local CarryService = require(script.Parent.CarryService)
local Path = require(ReplicatedStorage.Shared.MonsterPath)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local M = Config.Monsters
local MonsterService = {}

type Monster = {
	ring: number,
	folder: Folder,
	pos: Vector3,
	look: Vector3,
	state: string, -- Patrol, Chase, Return
	target: Player?,
	t0: number, -- début de la poursuite (heure serveur)
	endsAt: number,
	leaveAt: number, -- début du retour
	pause: number, -- secondes immobiles avant de repartir (rage contre le dôme)
	size: number,
	lastSent: number,
	stunUntil: number?,
	stunReady: number?,
	-- promenade parmi les astéroïdes (Walk, Crawl) : étape en cours, ses deux astéroïdes, sens de rotation
	leg: any?,
	legA: any?,
	legB: any?,
	spin: number?,
	home: any?, -- astéroïde où il retourne après une poursuite
	homeAng: number?,
}

local monsters: { [number]: Monster } = {} -- par anneau
local cooldown: { [Player]: number } = {}
local folder: Folder
local lostFolder: Folder

-- Roches tombées sur un astéroïde après une prise, à reprendre avant expiresAt
type Lost = { owner: Player, items: { any }, asteroid: any, offset: Vector3, expiresAt: number, model: Model }
local lost: { Lost } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function root(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Anneau à monstre où se trouve une position (selon la distance à l'axe des anneaux), sinon nil
function MonsterService.RingAt(pos: Vector3): number?
	local map = Config.Map
	local axisZ = map.FrontZ - map.AxisDistance
	local d = Vector2.new(pos.X, pos.Z - axisZ).Magnitude - map.AxisDistance
	for ring in pairs(M.Kinds) do
		if math.abs(d - Config.RingDistance(ring)) <= Config.RingWidth(ring) / 2 + M.RingMargin then
			return ring
		end
	end
	return nil
end

local function inShip(pos: Vector3): boolean
	local ship = workspace:FindFirstChild("Ship")
	local mn = ship and ship:GetAttribute("SafeMin")
	local mx = ship and ship:GetAttribute("SafeMax")
	if typeof(mn) ~= "Vector3" or typeof(mx) ~= "Vector3" then
		return false
	end
	return pos.X >= mn.X and pos.X <= mx.X and pos.Z >= mn.Z and pos.Z <= mx.Z
end

MonsterService.InShip = inShip

-- Dans la cour, derrière la ligne rouge (Workspace.Ship.Yard.SafeLine, à Config.Map.FrontZ) : le monstre
-- ne la passe jamais, la poursuite s'arrête là
local function inYard(pos: Vector3): boolean
	return pos.Z < Config.Map.FrontZ and inShip(pos)
end

-- Multiplicateur de vitesse du monstre face à ce joueur : sa propre Speed s'il a assez de Speed,
-- sinon d'autant plus que le joueur en manque (jusqu'à MaxFactor)
function MonsterService.Factor(ring: number, jetSpeed: number): number
	local kind = M.Kinds[ring]
	local need = kind.Need or 0
	if jetSpeed >= need then
		return kind.Speed
	end
	local missing = math.log10(need / math.max(1, jetSpeed)) / M.Decades
	return kind.Speed + (M.MaxFactor - kind.Speed) * math.clamp(missing, 0.12, 1)
end

-- PROMENADE PARMI LES ASTÉROÏDES (shared/MonsterPath, Config.Monsters.Route) -----------------------------

local rng = Random.new()

local function moveOf(m: Monster): string
	return M.Kinds[m.ring].Move or "Float"
end

local function footOf(m: Monster): number
	return (M.Kinds[m.ring].Foot or 0.35) * m.size
end

local function spotOf(a: any)
	local s = a.part.Size
	return Path.Rock(a.radius, a.angle0, a.height, a.omega, a.t0, math.max(s.X, s.Z), s.Y)
end

-- Secondes pendant lesquelles un astéroïde reste dans la partie du couloir où les monstres se promènent
local function inside(s: any, t: number): number
	local limit = Config.Map.CorridorWidth * M.Route.Side
	if math.abs(Path.Across(s, t)) > limit then
		return 0
	elseif s.om == 0 then
		return math.huge
	end
	local exit = s.t0 + (math.asin(math.clamp(limit / s.r, -1, 1)) * math.sign(s.om) - s.a0) / s.om
	return math.max(0, exit - t)
end

-- Où est le monstre en promenade, et où il regarde
local function patrol(m: Monster, t: number): (Vector3, Vector3)
	if m.leg then
		return Path.At(m.leg, t, moveOf(m), m.size, footOf(m))
	end
	return Config.MonsterPatrol(m.ring, t)
end

-- Le prochain astéroïde : pas trop loin, encore longtemps dans le couloir, assez gros pour lui
local function pick(m: Monster, from: Vector3, t: number, exclude: any?): any?
	local R = M.Route
	local best, bestScore = nil, math.huge
	for _, a in ipairs(BeltService.InRing(m.ring)) do
		if a ~= exclude and a.tEnd > t + 10 then
			local s = spotOf(a)
			local stay = inside(s, t + 1)
			if stay > 4 then
				local d = (Path.Center(s, t + 1) - from).Magnitude
				if d > s.sx / 2 + m.size * 0.3 and d < R.Reach then
					local score = d - math.min(stay, 30) * R.Keep - s.sx * R.Big * m.size / 20 + rng:NextNumber(0, R.Jitter)
					if score < bestScore then
						best, bestScore = a, score
					end
				end
			end
		end
	end
	return best
end

-- Nouvelle étape à partir de l'instant t : le temps passé sur l'astéroïde `rock` (ou nulle part : il part de là
-- où il est), puis le trajet vers le suivant. ang : par où il est arrivé sur `rock`.
local function plan(m: Monster, t: number, rock: any?, ang: number)
	local R = M.Route
	local move = moveOf(m)
	local a
	if rock and BeltService.Alive(rock) then
		a = spotOf(rock)
	else
		rock = nil
		a = Path.Point(m.pos)
	end
	local t1, turn = t, 0
	if rock then
		local stay
		if move == "Walk" then
			stay = math.clamp(a.sx * 0.56 / (R.WalkSpeed[1] + R.WalkSpeed[2] * m.size), R.Stay[1], R.Stay[2])
		else
			m.spin = m.spin or (if rng:NextNumber() < 0.5 then -1 else 1)
			turn = m.spin * rng:NextNumber(R.Turn[1], R.Turn[2])
			stay = math.abs(turn) * (a.sx / 2 + m.size * 0.22) / (R.CrawlSpeed[1] + R.CrawlSpeed[2] * m.size)
		end
		-- pas plus longtemps que l'astéroïde ne reste dans le couloir
		local keep = math.min(stay, inside(a, t))
		if stay > 0 then
			turn *= keep / stay
		end
		t1 = t + keep
	end
	-- d'où il part à t1
	local from = Path.At({ a = a, b = a, t0 = t, t1 = t1, t2 = t1, ang = ang, turn = turn, ang2 = ang }, t1, move, m.size, footOf(m))
	local nextRock = pick(m, from, t1, rock)
	local b = if nextRock then spotOf(nextRock) else Path.Point((Config.MonsterPatrol(m.ring, t1 + 3)))
	local speed = if move == "Walk" then R.HopSpeed[1] + R.HopSpeed[2] * m.size else R.CrawlSpeed[1] + R.CrawlSpeed[2] * m.size
	local gap = Path.Center(b, t1 + 1) - from
	local duration = math.clamp(gap.Magnitude / speed, 0.9, 9)
	local dir = Path.Center(b, t1 + duration) - from
	local heading = math.atan2(dir.Z, dir.X)
	local ang2
	if move == "Walk" then
		ang2 = heading -- il se pose sur le bord le plus proche et traverse la roche dans le même sens
	else
		-- il aborde le flanc le plus proche, un peu de côté, et continue de tourner dans ce sens
		m.spin = if rng:NextNumber() < 0.5 then -1 else 1
		ang2 = heading + math.pi + m.spin * 0.8
	end
	local leg = { a = a, b = b, t0 = t, t1 = t1, t2 = t1 + duration, ang = ang, turn = turn, ang2 = ang2 }
	m.leg, m.legA, m.legB = leg, rock, nextRock
	m.folder:SetAttribute("Leg", Path.Encode(leg))
end

-- En promenade : étape suivante quand celle-ci est finie, ou tout de suite si son astéroïde a disparu
local function stroll(m: Monster, t: number)
	if moveOf(m) == "Float" then
		return
	end
	local leg = m.leg
	if not leg then
		m.pos = Config.MonsterPatrol(m.ring, t)
		plan(m, t, nil, 0)
	elseif t >= leg.t2 then
		m.pos = patrol(m, leg.t2)
		plan(m, leg.t2, m.legB, leg.ang2)
	elseif (t < leg.t1 and m.legA and not BeltService.Alive(m.legA)) or (m.legB and not BeltService.Alive(m.legB)) then
		-- la roche sous lui (ou celle qu'il visait) vient de casser : il repart de là où il est
		m.pos = patrol(m, t)
		plan(m, t, nil, 0)
	end
end

local function publish(m: Monster)
	m.folder:SetAttribute("Pos", m.pos)
	m.folder:SetAttribute("Look", m.look)
end

local function setState(m: Monster, state: string)
	m.state = state
	publish(m)
	m.folder:SetAttribute("State", state)
end

-- Fin de poursuite : le joueur est libéré, le monstre retourne se promener
-- reason : line (le joueur a passé la ligne rouge de la cour, il s'écrase sur la barrière), caught,
-- lost (temps écoulé, joueur parti)
local function release(m: Monster, reason: string)
	local player = m.target
	m.target = nil
	-- après la poursuite, il retourne sur un astéroïde de son anneau et reprend sa promenade de là
	m.leg, m.legA, m.legB = nil, nil, nil
	m.folder:SetAttribute("Leg", nil)
	m.home = if moveOf(m) ~= "Float" then pick(m, Config.MonsterPatrol(m.ring, now()), now(), nil) else nil
	m.leaveAt = now()
	m.pause = if reason == "line" then M.ReturnPause elseif reason == "caught" then 0.6 else 0
	m.folder:SetAttribute("Reason", reason)
	m.folder:SetAttribute("Target", 0)
	setState(m, "Return")
	if player then
		cooldown[player] = os.clock() + M.Cooldown
		if player.Parent then
			player:SetAttribute("Chased", nil)
		end
	end
end

-- Un joueur vient de sortir un œuf d'un astéroïde de cet anneau : le monstre de l'anneau fonce sur lui
-- (s'il ne poursuit pas déjà quelqu'un). Renvoie vrai si la poursuite commence.
function MonsterService.Alert(player: Player, ring: number): boolean
	local m = monsters[ring]
	local hrp = root(player)
	if not m or not hrp or m.state == "Chase" or (cooldown[player] or 0) > os.clock() then
		return false
	end
	-- œuf sorti depuis la cour, derrière la ligne rouge : il n'y a personne à poursuivre
	if inYard(hrp.Position) then
		return false
	end
	-- déjà poursuivi par le monstre d'un autre anneau : un seul à la fois
	for _, other in pairs(monsters) do
		if other.target == player then
			return false
		end
	end
	if m.state == "Patrol" then
		m.pos, m.look = patrol(m, now())
	end
	local t = now()
	m.target = player
	m.t0 = t
	m.endsAt = t + M.Emerge + M.MaxChase
	m.stunUntil, m.stunReady = nil, nil
	m.folder:SetAttribute("Stunned", nil)
	m.folder:SetAttribute("Target", player.UserId)
	m.folder:SetAttribute("ChaseAt", t)
	setState(m, "Chase")
	player:SetAttribute("Chased", m.endsAt)
	-- pas de message : le bandeau RUN HOME et le rugissement suffisent (MonsterFx.client)
	return true
end

-- Coup de batte : assomme les monstres à portée. Renvoie le nom du monstre touché, sinon nil.
function MonsterService.Stun(pos: Vector3, range: number, seconds: number): string?
	local t = now()
	local name = nil
	for _, m in pairs(monsters) do
		if m.state == "Chase" and t >= (m.stunReady or 0) and (m.pos - pos).Magnitude <= m.size / 2 + M.CatchRadius + range then
			m.stunUntil = t + seconds
			m.stunReady = t + seconds + M.StunGap
			m.folder:SetAttribute("Stunned", m.stunUntil)
			name = M.Kinds[m.ring].Name
		end
	end
	return name
end

-- La roche du joueur attrapé retombe sur l'astéroïde le plus proche : elle y reste DropTime s
local function dropRock(player: Player, items: { any }, from: Vector3): boolean
	local a, at = BeltService.NearestAsteroid(from, M.DropSearch)
	local first = items[1]
	local ring = if type(first) == "table" then first.ring or 1 else 1
	local model = if a then CarryService.LooseRock(ring, 1.3) else nil
	if not a or not at or not model then
		if model then
			model:Destroy()
		end
		GameService.Notice(player, "{Warning} ROCK LOST!", "bad")
		return false
	end
	-- posée sur le dessus de l'astéroïde (le client la garde collée à la roche qui défile)
	local s = a.part.Size
	local offset = Vector3.new(0, s.Y / 2 + (model:GetAttribute("BodyHeight") or 3) * 0.35, 0)
	local t = now()
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("ExpiresAt", t + M.DropTime)
	model:SetAttribute("Offset", offset)
	model:SetAttribute("From", from)
	model:SetAttribute("Ring", ring)
	local ref = Instance.new("ObjectValue")
	ref.Name = "Asteroid"
	ref.Value = a.part
	ref.Parent = model
	model:PivotTo(CFrame.new(at + offset))
	model.Parent = lostFolder
	table.insert(lost, { owner = player, items = items, asteroid = a, offset = offset, expiresAt = t + M.DropTime, model = model })
	return true
end

-- Le monstre attrape le joueur : il le projette, et sa roche retombe sur l'astéroïde le plus proche
local function caught(m: Monster)
	local player = m.target :: Player
	local d = DataService.Get(player)
	local kind = M.Kinds[m.ring]
	-- bouclier : le monstre repart, le joueur garde tout
	if d and (d.shields or 0) > 0 then
		d.shields -= 1
		GameService.Sync(player)
		release(m, "lost")
		GameService.Notice(player, "{Star} SHIELD USED!", "good")
		return
	end
	local hrp = root(player)
	local where = if hrp then hrp.Position else m.pos
	if d and #d.cargo > 0 then
		local items = d.cargo
		d.cargo = {}
		CarryService.Drop(player) -- la roche quitte ses mains
		GameService.Sync(player)
		-- pas de message (20 nov.) : la roche tombée s'affiche avec « GRAB IT! » et un rayon jusqu'à elle
		dropRock(player, items, where)
	end
	-- projeté loin du monstre (le client applique la poussée, comme un coup de batte)
	local away = where - m.pos
	away = if away.Magnitude > 0.01 then Vector3.new(away.X, 0, away.Z).Unit else Vector3.xAxis
	Remotes.Gear:FireClient(player, "pushed", away * M.Knock + Vector3.new(0, M.KnockUp, 0), kind.Name, "monster")
	release(m, "caught")
end

-- Roches tombées : on la reprend en la touchant ; à la fin du temps (ou si l'astéroïde disparaît),
-- elle s'enfonce dans l'astéroïde et l'œuf est perdu
local function stepLost()
	local t = now()
	for i = #lost, 1, -1 do
		local l = lost[i]
		local owner = l.owner
		local alive = owner.Parent ~= nil and BeltService.Alive(l.asteroid)
		local pos = if alive then BeltService.Position(l.asteroid, t) + l.offset else nil
		local hrp = if alive then root(owner) else nil
		local d = if alive then DataService.Get(owner) else nil
		local reach = M.PickRadius + (l.model:GetAttribute("BodyHeight") or 3) / 2
		if hrp and d and pos and (hrp.Position - pos).Magnitude <= reach and #d.cargo + #l.items <= Config.CargoSlots() then
			for _, egg in ipairs(l.items) do
				table.insert(d.cargo, egg)
			end
			GameService.Sync(owner)
			l.model:Destroy()
			table.remove(lost, i)
		elseif not alive or t >= l.expiresAt then
			l.model:SetAttribute("Sinking", true)
			local model = l.model
			task.delay(1.2, function()
				model:Destroy()
			end)
			table.remove(lost, i)
		end
	end
end

local function step(dt: number)
	stepLost()
	local t = now()
	for ring, m in pairs(monsters) do
		if m.state == "Chase" then
			local player = m.target
			local hrp = player and root(player)
			if not player or not player.Parent or not hrp then
				release(m, "lost")
				continue
			end
			local target = hrp.Position
			local safe = inYard(target)
			if safe or t >= m.endsAt then
				-- le joueur a passé la ligne rouge : le monstre s'écrase contre la barrière de la cour (il reste
				-- du côté du couloir), puis retourne à son anneau
				if safe then
					local line = Config.Map.FrontZ
					m.pos = Vector3.new(m.pos.X, m.pos.Y, math.max(m.pos.Z, line + m.size * 0.6) + M.Recoil)
				end
				release(m, if safe then "line" else "lost")
				continue
			end
			if t < m.t0 + M.Emerge then
				-- il t'a vu : il se tourne vers toi et rugit, on a le temps de fuir
				local delta = target - m.pos
				if delta.Magnitude > 0.01 then
					m.look = m.look:Lerp(delta.Unit, math.min(1, dt * 6)).Unit
				end
			elseif t >= (m.stunUntil or 0) then -- assommé par une batte : il ne bouge plus
				local speed
				local factor = MonsterService.Factor(ring, (player:GetAttribute("JetSpeed") or 0) :: number)
				if inShip(target) then
					-- sur le vaisseau on court : il se cale sur la vitesse à pied
					local ground = (player:GetAttribute("GroundSpeed") or Config.Movement.Walk) :: number
					speed = ground * factor
				else
					local air = (player:GetAttribute("AirSpeed") or Config.Movement.Air) :: number
					speed = math.max(M.MinSpeed, air * factor)
				end
				local delta = target - m.pos
				local dist = delta.Magnitude
				if dist > 0.01 then
					m.look = m.look:Lerp(delta.Unit, math.min(1, dt * 4)).Unit
					m.pos += delta.Unit * math.min(dist, speed * dt)
				end
				if (target - m.pos).Magnitude <= m.size / 2 + M.CatchRadius then
					caught(m)
					continue
				end
			end
			if t - m.lastSent >= 1 / 15 then
				m.lastSent = t
				publish(m)
			end
		elseif m.state == "Return" then
			-- un moment sur place (rage contre le dôme, ou après un coup), puis il rentre se promener
			if t >= m.leaveAt + m.pause then
				local goal = Config.MonsterPatrol(ring, t)
				local home = m.home
				if home and BeltService.Alive(home) then
					-- il vise le bord de son astéroïde (le dessus pour un marcheur, le flanc pour un rampeur)
					local spot = spotOf(home)
					local c = Path.Center(spot, t)
					m.homeAng = math.atan2(c.Z - m.pos.Z, c.X - m.pos.X)
					local ang = if moveOf(m) == "Walk" then m.homeAng else m.homeAng + math.pi
					goal = Path.At({ a = spot, b = spot, t0 = t, t1 = t + 1, t2 = t + 1, ang = ang, turn = 0, ang2 = ang }, t, moveOf(m), m.size, footOf(m))
				elseif home then
					m.home = pick(m, m.pos, t, nil)
				end
				local delta = goal - m.pos
				local dist = delta.Magnitude
				if dist > 0.01 then
					m.look = m.look:Lerp(delta.Unit, math.min(1, dt * 3)).Unit
					m.pos += delta.Unit * math.min(dist, M.ReturnSpeed * dt)
				end
				if dist <= 4 or t >= m.leaveAt + m.pause + M.ReturnTime then
					m.folder:SetAttribute("Reason", nil)
					if moveOf(m) ~= "Float" then
						local arrived = dist <= 4 and m.home ~= nil and BeltService.Alive(m.home)
						local ang = (m.homeAng or 0) + (if moveOf(m) == "Walk" then 0 else math.pi)
						plan(m, t, if arrived then m.home else nil, ang)
						m.home = nil
					end
					setState(m, "Patrol")
					continue
				end
			end
			if t - m.lastSent >= 1 / 15 then
				m.lastSent = t
				publish(m)
			end
		end
		-- Patrol : la position se calcule (Config.MonsterPatrol, ou l'étape en cours parmi les astéroïdes)
		if m.state == "Patrol" then
			stroll(m, t)
		end
	end
end

-- Œuf sorti d'un astéroïde (appelé par GameService) : le monstre de l'anneau fonce sur le voleur
function MonsterService.OnEgg(player: Player, _part: BasePart, ring: number)
	MonsterService.Alert(player, ring)
end

function MonsterService.Start()
	local world = workspace:WaitForChild("World")
	folder = world:FindFirstChild("Monsters") :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Monsters"
		folder.Parent = world
	end
	lostFolder = world:FindFirstChild("LostRocks") :: Folder
	if not lostFolder then
		lostFolder = Instance.new("Folder")
		lostFolder.Name = "LostRocks"
		lostFolder.Parent = world
	end
	-- un monstre par anneau, là dès le début de la partie
	for ring, kind in pairs(M.Kinds) do
		local pos, look = Config.MonsterPatrol(ring, now())
		local f = Instance.new("Folder")
		f.Name = kind.Model
		f:SetAttribute("Kind", ring)
		f:SetAttribute("Size", kind.Size)
		f:SetAttribute("Target", 0)
		f:SetAttribute("Pos", pos)
		f:SetAttribute("Look", look)
		f:SetAttribute("State", "Patrol")
		f.Parent = folder
		monsters[ring] = { ring = ring, folder = f, pos = pos, look = look, state = "Patrol", target = nil, t0 = 0, endsAt = 0, leaveAt = 0, pause = 0, size = kind.Size, lastSent = 0 }
	end
	GameService.EggHook = MonsterService.OnEgg
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		for _, m in pairs(monsters) do
			if m.target == player then
				release(m, "lost")
			end
		end
		cooldown[player] = nil
		for i = #lost, 1, -1 do
			if lost[i].owner == player then
				lost[i].model:Destroy()
				table.remove(lost, i)
			end
		end
	end)
	-- Studio seulement : lancer le monstre d'un anneau sur le joueur (test)
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "MonsterDebug"
		bf.OnInvoke = function(player: Player, ring: number, rarity: number?)
			cooldown[player] = nil
			local d = DataService.Get(player)
			if d and rarity then
				-- un œuf de cette rareté dans la soute, comme s'il venait d'être sorti de la roche
				d.cargo = { { ring = ring, rarity = rarity } }
				GameService.Sync(player)
			end
			return MonsterService.Alert(player, ring)
		end
		bf.Parent = ServerStorage
	end
end

return MonsterService
