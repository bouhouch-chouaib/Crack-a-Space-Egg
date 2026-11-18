-- Monstres des anneaux 3 à 14 (Config.Monsters, docs/Mecaniques.md §13 et §0).
-- Le serveur décide : bruit de chaque joueur, réveil, poursuite, prise, abandon. Il ne déplace pas
-- de modèle : chaque monstre est un dossier dans Workspace.World.Monsters dont les attributs sont
-- lus par MonsterFx.client, qui anime le modèle chez chaque joueur.
-- Vitesse (18 nov.) : chaque monstre demande une Speed de jetpack (Kinds[].Need) ; en dessous, il va
-- d'autant plus vite que le joueur en manque. S'il l'attrape, le joueur est projeté et sa roche
-- retombe sur l'astéroïde le plus proche (Workspace.World.LostRocks), à reprendre en DropTime s.
--   Kind (anneau), Target (UserId), Pos, Look, State (Emerge / Chase / Return / Leave / Caught),
--   StartedAt, EndsAt (temps serveur), Size
-- Publié sur le joueur : Noise (0..1, seulement dans un anneau à bruit), Chased (EndsAt, pendant une poursuite).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local BeltService = require(script.Parent.BeltService)
local CarryService = require(script.Parent.CarryService)
local Bases = require(script.Parent.Bases)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local M = Config.Monsters
local MonsterService = {}

type Chase = {
	player: Player,
	ring: number,
	folder: Folder,
	pos: Vector3,
	look: Vector3,
	state: string,
	t0: number,
	endsAt: number,
	leaveAt: number,
	size: number,
	lastSent: number,
	stunUntil: number?,
	stunReady: number?,
	home: Vector3, -- son astéroïde : il y rentre quand le joueur atteint sa base
}

local chases: { [Player]: Chase } = {}
local noise: { [Player]: number } = {}
local lastLoud: { [Player]: number } = {}
local lastDrill: { [Player]: number } = {}
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

-- Dans sa propre base (sol ou annexe) : le monstre abandonne
local function inBase(player: Player, pos: Vector3): boolean
	local base = Bases.Get(player)
	if not base then
		return false
	end
	local floors = { base:FindFirstChild("Floor") }
	local annex = base:FindFirstChild("Annex")
	table.insert(floors, annex and annex:FindFirstChild("AnnexFloor"))
	for _, f in ipairs(floors) do
		if f and f:IsA("BasePart") then
			local p = f.CFrame:PointToObjectSpace(pos)
			local s = f.Size
			if math.abs(p.X) <= s.X / 2 + M.BaseMargin and math.abs(p.Z) <= s.Z / 2 + M.BaseMargin and p.Y > -4 and p.Y < M.BaseHeight then
				return true
			end
		end
	end
	return false
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

local function senses(ring: number, what: string): boolean
	local kind = M.Kinds[ring]
	return kind ~= nil and (kind.Sense == what or kind.Sense == "Both")
end

local function publish(c: Chase)
	c.folder:SetAttribute("Pos", c.pos)
	c.folder:SetAttribute("Look", c.look)
	c.folder:SetAttribute("State", c.state)
end

local function finish(c: Chase)
	chases[c.player] = nil
	cooldown[c.player] = os.clock() + M.Cooldown
	noise[c.player] = 0
	if c.player.Parent then
		c.player:SetAttribute("Chased", nil)
		c.player:SetAttribute("Noise", if c.player:GetAttribute("Noise") ~= nil then 0 else nil)
	end
	task.delay(3, function()
		c.folder:Destroy()
	end)
end

-- Réveil : le monstre de l'anneau sort près du joueur (ou de l'astéroïde gardé) et le poursuit
function MonsterService.Wake(player: Player, ring: number, from: Vector3?): boolean
	local kind = M.Kinds[ring]
	local hrp = root(player)
	local d = DataService.Get(player)
	if not kind or not hrp or not d or chases[player] or (cooldown[player] or 0) > os.clock() then
		return false
	end
	local duration = M.MaxChase
	-- point de sortie : l'astéroïde voisin le plus proche, sinon sous le joueur, un peu à l'écart
	local spawnAt = from or BeltService.NearestPosition(hrp.Position, ring, 90)
	if not spawnAt then
		local a = math.random() * math.pi * 2
		spawnAt = hrp.Position + Vector3.new(math.cos(a) * 45, -25, math.sin(a) * 45)
	end
	local t = now()
	local f = Instance.new("Folder")
	f.Name = kind.Model .. "_" .. player.UserId
	f:SetAttribute("Kind", ring)
	f:SetAttribute("Target", player.UserId)
	f:SetAttribute("StartedAt", t)
	f:SetAttribute("EndsAt", t + M.Emerge + duration)
	f:SetAttribute("Size", kind.Size)
	local c: Chase = {
		player = player,
		ring = ring,
		folder = f,
		pos = spawnAt,
		look = (hrp.Position - spawnAt).Unit,
		state = "Emerge",
		t0 = t,
		endsAt = t + M.Emerge + duration,
		leaveAt = 0,
		size = kind.Size,
		lastSent = 0,
		home = spawnAt,
	}
	publish(c)
	f.Parent = folder
	chases[player] = c
	player:SetAttribute("Chased", c.endsAt)
	player:SetAttribute("Noise", if player:GetAttribute("Noise") ~= nil then 1 else nil)
	-- pas de message : le bandeau RUN HOME et le rugissement suffisent (MonsterFx.client)
	return true
end

-- Coup de batte : assomme les monstres à portée. Renvoie le nom du monstre touché, sinon nil.
function MonsterService.Stun(pos: Vector3, range: number, seconds: number): string?
	local t = now()
	local name = nil
	for _, c in pairs(chases) do
		local awake = c.state == "Chase" or c.state == "Emerge"
		if awake and t >= (c.stunReady or 0) and (c.pos - pos).Magnitude <= c.size / 2 + M.CatchRadius + range then
			c.stunUntil = t + seconds
			c.stunReady = t + seconds + M.StunGap
			c.folder:SetAttribute("Stunned", c.stunUntil)
			name = M.Kinds[c.ring].Name
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
		GameService.Notice(player, "{Warning} Your rock fell into space!", "bad")
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
local function caught(c: Chase)
	local player = c.player
	local d = DataService.Get(player)
	local kind = M.Kinds[c.ring]
	-- bouclier : le monstre repart, le joueur garde tout
	if d and (d.shields or 0) > 0 then
		d.shields -= 1
		GameService.Sync(player)
		c.state = "Leave"
		c.leaveAt = now()
		player:SetAttribute("Chased", nil)
		GameService.Notice(player, ("{Star} Your shield stopped the %s! %d left"):format(kind.Name, d.shields), "good")
		return
	end
	c.state = "Caught"
	publish(c)
	local hrp = root(player)
	local where = if hrp then hrp.Position else c.pos
	if d and #d.cargo > 0 then
		local items = d.cargo
		d.cargo = {}
		CarryService.Drop(player) -- la roche quitte ses mains
		GameService.Sync(player)
		if dropRock(player, items, where) then
			GameService.Notice(player, ("{Warning} The %s knocked your rock away! Grab it back!"):format(kind.Name), "bad")
		end
	end
	-- projeté loin du monstre (le client applique la poussée, comme un coup de batte)
	local away = where - c.pos
	away = if away.Magnitude > 0.01 then Vector3.new(away.X, 0, away.Z).Unit else Vector3.xAxis
	Remotes.Gear:FireClient(player, "pushed", away * M.Knock + Vector3.new(0, M.KnockUp, 0), kind.Name, "monster")
	finish(c)
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
			GameService.Notice(owner, "{Star} You got your rock back!", "good")
			l.model:Destroy()
			table.remove(lost, i)
		elseif not alive or t >= l.expiresAt then
			if owner.Parent then
				GameService.Notice(owner, "{Warning} Your rock sank into the asteroid!", "bad")
			end
			l.model:SetAttribute("Sinking", true)
			local m = l.model
			task.delay(1.2, function()
				m:Destroy()
			end)
			table.remove(lost, i)
		end
	end
end

local function step(dt: number)
	stepLost()
	local t = now()
	-- BRUIT --------------------------------------------------------------------------------
	for _, player in ipairs(Players:GetPlayers()) do
		local hrp = root(player)
		local ring = hrp and MonsterService.RingAt(hrp.Position)
		if hrp and ring and senses(ring, "Noise") and not chases[player] and not inShip(hrp.Position) then
			local n = noise[player] or 0
			local character = player.Character
			local drilling = os.clock() - (lastDrill[player] or 0) < 0.45
			local thrust = character ~= nil and character:GetAttribute("Jet") == 1
			-- pendant le répit qui suit une poursuite, le bruit ne fait que retomber
			local resting = (cooldown[player] or 0) > os.clock()
			if not resting and (drilling or thrust) then
				n += ((if drilling then M.Noise.Drill else 0) + (if thrust then M.Noise.Jet else 0)) * dt
				lastLoud[player] = os.clock()
			elseif resting or os.clock() - (lastLoud[player] or 0) > M.Noise.QuietDelay then
				n = math.max(0, n - M.Noise.Decay * dt)
			end
			n = math.clamp(n, 0, 1)
			noise[player] = n
			local shown = math.floor(n * 100 + 0.5) / 100
			if player:GetAttribute("Noise") ~= shown then
				player:SetAttribute("Noise", shown)
			end
			if n >= 1 then
				MonsterService.Wake(player, ring)
			end
		elseif not chases[player] then
			noise[player] = 0
			if player:GetAttribute("Noise") ~= nil then
				player:SetAttribute("Noise", nil)
			end
		end
	end

	-- POURSUITES ---------------------------------------------------------------------------
	for player, c in pairs(chases) do
		local hrp = root(player)
		if not player.Parent or not hrp then
			finish(c)
			continue
		end
		local target = hrp.Position
		if c.state == "Emerge" then
			-- il sort de sa cachette en montant doucement, tourné vers le joueur
			c.pos += Vector3.new(0, 6 * dt, 0)
			c.look = (target - c.pos).Unit
			if t >= c.t0 + M.Emerge then
				c.state = "Chase"
			end
		elseif c.state == "Chase" then
			local home = inBase(player, target)
			if home or t >= c.endsAt then
				-- arrivé chez lui : le monstre s'écrase contre le dôme de la base, puis rentre à son astéroïde
				c.state = "Return"
				c.leaveAt = t
				local away = c.pos - target
				if away.Magnitude > 0.01 then
					c.pos += away.Unit * M.Recoil
				end
				c.home = BeltService.NearestPosition(c.home, c.ring, 80) or c.home
				player:SetAttribute("Chased", nil)
				if not home then
					GameService.Notice(player, ("{Star} You escaped the %s!"):format(M.Kinds[c.ring].Name), "good")
				end
			elseif t >= (c.stunUntil or 0) then -- assommé par une batte : il ne bouge plus
				local speed
				local factor = MonsterService.Factor(c.ring, (player:GetAttribute("JetSpeed") or 0) :: number)
				if inShip(target) then
					-- sur le vaisseau on court : il se cale sur la vitesse à pied
					local ground = (player:GetAttribute("GroundSpeed") or Config.Movement.Walk) :: number
					speed = ground * factor
				else
					local air = (player:GetAttribute("AirSpeed") or Config.Movement.Air) :: number
					speed = math.max(M.MinSpeed, air * factor)
				end
				local delta = target - c.pos
				local dist = delta.Magnitude
				if dist > 0.01 then
					c.look = c.look:Lerp(delta.Unit, math.min(1, dt * 4)).Unit
					c.pos += delta.Unit * math.min(dist, speed * dt)
				end
				if (target - c.pos).Magnitude <= c.size / 2 + M.CatchRadius then
					caught(c)
					continue
				end
			end
		elseif c.state == "Return" then
			-- un moment de rage contre le dôme, puis il rentre à son astéroïde
			if t >= c.leaveAt + M.ReturnPause then
				local delta = c.home - c.pos
				local dist = delta.Magnitude
				if dist > 0.01 then
					c.look = c.look:Lerp(delta.Unit, math.min(1, dt * 3)).Unit
					c.pos += delta.Unit * math.min(dist, M.ReturnSpeed * dt)
				end
				if dist <= c.size * 0.5 or t >= c.leaveAt + M.ReturnTime then
					c.state = "Leave"
					c.leaveAt = t
				end
			end
		elseif c.state == "Leave" then
			-- il plonge dans son astéroïde, puis disparaît
			c.pos += (-c.look + Vector3.new(0, -0.6, 0)).Unit * 40 * dt
			if t >= c.leaveAt + 2.5 then
				publish(c)
				finish(c)
				continue
			end
		end
		if t - c.lastSent >= 1 / 15 then
			c.lastSent = t
			publish(c)
		end
	end
end

-- Coup de foreuse (appelé par GameService) : bruit, et réveil du gardien d'un astéroïde gardé
function MonsterService.OnDrill(player: Player, part: BasePart, ring: number)
	lastDrill[player] = os.clock()
	if part:GetAttribute("Guarded") and senses(ring, "Guard") then
		part:SetAttribute("Guarded", nil) -- l'œil quitte son poste pour poursuivre
		MonsterService.Wake(player, ring, part.Position + Vector3.new(0, part.Size.Y / 2 + 6, 0))
	end
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
	GameService.DrillHook = MonsterService.OnDrill
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		local c = chases[player]
		if c then
			finish(c)
		end
		noise[player], lastLoud[player], lastDrill[player], cooldown[player] = nil, nil, nil, nil
		for i = #lost, 1, -1 do
			if lost[i].owner == player then
				lost[i].model:Destroy()
				table.remove(lost, i)
			end
		end
	end)
	-- Studio seulement : réveiller un monstre sur commande (test)
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "MonsterDebug"
		bf.OnInvoke = function(player: Player, ring: number, rarity: number?, guard: boolean?)
			cooldown[player] = nil
			if guard then
				-- comme un coup de foreuse sur l'astéroïde gardé le plus proche de cet anneau
				local hrp = root(player)
				local best, bd = nil, math.huge
				for _, d in ipairs(workspace.World.Belt:GetDescendants()) do
					if d:IsA("BasePart") and d:GetAttribute("Guarded") and d:GetAttribute("Ring") == ring and hrp then
						local dist = (d.Position - hrp.Position).Magnitude
						if dist < bd then
							best, bd = d, dist
						end
					end
				end
				if best then
					MonsterService.OnDrill(player, best, ring)
					return chases[player] ~= nil
				end
				return false
			end
			local d = DataService.Get(player)
			if d and rarity then
				-- un œuf de cette rareté dans la soute, pour tester la durée de la poursuite
				d.cargo = { { ring = ring, rarity = rarity } }
				GameService.Sync(player)
			end
			return MonsterService.Wake(player, ring)
		end
		bf.Parent = ServerStorage
	end
end

return MonsterService
