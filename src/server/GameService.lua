-- La boucle de jeu côté serveur : forage, soute, casse des œufs, améliorations, anneaux.
-- Le serveur décide de tout ce qui rapporte : le client n'envoie que des intentions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local BeltService = require(script.Parent.BeltService)
local Bases = require(script.Parent.Bases)
local WorldBuilder = require(script.Parent.WorldBuilder)
local BoostService = require(script.Parent.BoostService)

local Remotes = ReplicatedStorage.Remotes

local GameService = {}

local rng = Random.new()
local lastDrill: { [Player]: number } = {}
local lastNotice: { [Player]: number } = {}

local function notice(player: Player, text: string, kind: string?)
	-- Pas plus d'un message par seconde pour ne pas noyer l'écran
	local now = os.clock()
	if lastNotice[player] and now - lastNotice[player] < 1 then
		return
	end
	lastNotice[player] = now
	Remotes.Notice:FireClient(player, text, kind or "info")
end

-- Recopie l'état utile dans les attributs du joueur (répliqués au client pour le HUD)
local function sync(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	player:SetAttribute("Credits", d.credits)
	player:SetAttribute("Cargo", #d.cargo)
	player:SetAttribute("CargoMax", Config.CargoSlots())
	-- Raretés des œufs de la soute (« 1,3,2 »), pour les pastilles de couleur du HUD
	local rarities = {}
	for _, egg in ipairs(d.cargo) do
		table.insert(rarities, tostring(if type(egg) == "table" then egg.rarity or 1 else 1))
	end
	player:SetAttribute("CargoRarities", table.concat(rarities, ","))
	player:SetAttribute("ReadyEggs", #(d.ready or {}))
	-- Œufs dérochés prêts à poser (« 1:5,2:3 » = anneau:rareté), pour la barre des œufs (Hatchery.client)
	local ready = {}
	for _, egg in ipairs(d.ready or {}) do
		table.insert(ready, egg.ring .. ":" .. egg.rarity)
	end
	player:SetAttribute("ReadyList", table.concat(ready, ","))
	player:SetAttribute("Ring", d.ring)
	player:SetAttribute("Drill", d.drill)
	-- Niveau du jetpack (HUD) et vitesses qui en découlent (Jetpack.client)
	local jl, jx, jn = Config.JetpackLevel(d.jetXP or 0)
	player:SetAttribute("JetLevel", jl)
	player:SetAttribute("JetXP", jx)
	player:SetAttribute("JetXPNeed", jn)
	player:SetAttribute("GroundSpeed", Config.GroundSpeed(jl))
	player:SetAttribute("AirSpeed", Config.AirSpeed(jl))
	for id in pairs(Config.Upgrades) do
		player:SetAttribute("Lvl_" .. id, d.levels[id])
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls:FindFirstChild("Credits") :: StringValue).Value = "$" .. Format.Short(d.credits)
	end
end
GameService.Sync = sync
GameService.Notice = notice

local function root(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function pick(weights: { number }): number
	local x = rng:NextNumber()
	local acc = 0
	local fallback = 1
	for i, w in ipairs(weights) do
		acc += w
		if w > 0 and fallback == 1 and weights[1] <= 0 then
			fallback = i -- premier œuf possible de l'anneau (anneaux 5-7 : pas de Common)
		end
		if x < acc then
			return i
		end
	end
	return fallback
end

-- Rareté d'un œuf, tirée au forage (ses veines brillent de cette couleur pendant le retour)
local function rollRarity(d, ringIndex: number): number
	local probs = Config.Probabilities(ringIndex, Config.Luck(d.levels.Scanner) * BoostService.LuckMult(d))
	local rarity = pick(probs)
	-- Compteur de veine
	d.pity += 1
	if rarity < 5 and d.pity >= Config.PityLegendary then
		rarity = 5
	end
	if rarity >= 5 then
		d.pity = 0
	end
	return rarity
end

-- FORAGE ------------------------------------------------------------------

local function onDrill(player: Player, target: any, at: any)
	local d = DataService.Get(player)
	if not d or typeof(target) ~= "Instance" then
		return
	end
	local a = BeltService.Get(target)
	if not a then
		return
	end
	-- Cadence : un coup tous les DrillTick, avec un peu de marge pour la latence
	local now = os.clock()
	if lastDrill[player] and now - lastDrill[player] < Config.DrillTick * 0.6 then
		return
	end
	lastDrill[player] = now

	local hrp = root(player)
	if not hrp then
		return
	end
	local pos = BeltService.Position(a, workspace:GetServerTimeNow())
	-- Distance à la surface, au plus large de la roche (les formes allongées ne sont pas pénalisées)
	local s = a.part.Size
	local reach = (hrp.Position - pos).Magnitude - math.max(s.X, s.Y, s.Z) / 2
	if reach > Config.DrillRange + Config.DrillSlack then
		return
	end
	-- État de forage pour l'animation chez tous les clients (le point d'impact n'est que visuel :
	-- on le ramène sur l'astéroïde s'il en est trop loin)
	local character = player.Character
	if character then
		local point = if typeof(at) == "Vector3" and (at - pos).Magnitude < a.part.Size.Magnitude then at else pos
		character:SetAttribute("DrillAt", point)
		character:SetAttribute("DrillingUntil", workspace:GetServerTimeNow() + Config.DrillTick * 2)
	end
	if a.ring > d.ring then
		notice(player, "Unlock the " .. Config.Rings[a.ring].Name .. " at the Space Shop", "warn")
		return
	end
	local max = Config.CargoSlots()
	local room = max - #d.cargo
	if room <= 0 then
		notice(player, "{Egg} You already carry an egg! Bring it back to your base", "warn")
		return
	end

	local damage = Config.DrillPower(d.drill) * Config.DrillTick
	local eggs, broken, progress = BeltService.Hit(a, player, damage, room)
	local rarities = {}
	if eggs > 0 then
		for _ = 1, eggs do
			local rarity = rollRarity(d, a.ring)
			table.insert(d.cargo, { ring = a.ring, rarity = rarity })
			table.insert(rarities, rarity)
		end
		sync(player)
	end
	-- Coup visible par tous : nombres de dégâts, œufs qui jaillissent (avec leur rareté), casse.
	-- Les effets ne passent pas par la position du modèle (il défile) : on envoie la roche visée.
	-- eggLeft : vie restante de l'œuf en cours pour ce joueur (sa barre), eggHP : vie d'un œuf
	local eggHP = Config.Rings[a.ring].EggHP
	Remotes.DrillHit:FireAllClients(a.part, player, damage, rarities, broken, eggHP - progress, eggHP)
end

-- CASSE DES ŒUFS -----------------------------------------------------------

-- egg : { ring, rarity } ; les anciennes sauvegardes n'ont que l'anneau (rareté tirée maintenant)
GameService.RollRarity = function(d, ringIndex: number): number
	return rollRarity(d, ringIndex)
end

local function crackEgg(d, egg)
	local ringIndex = egg.ring
	local rarity = egg.rarity or rollRarity(d, ringIndex)

	local sizeWeights = {}
	for i, s in ipairs(Config.Sizes) do
		sizeWeights[i] = s.Chance
	end
	local size = Config.Sizes[pick(sizeWeights)]
	local shiny = rng:NextNumber() < Config.ShinyChance

	local ring = Config.Rings[ringIndex]
	local r = Config.Rarities[rarity]
	local value = r.Value * ring.ValueMult * size.Mult * (if shiny then Config.ShinyMult else 1)
	value = math.max(1, math.floor(value + 0.5))
	return {
		Ring = ringIndex,
		Rarity = rarity,
		Name = ring.Crystals[rarity],
		Size = size.Name,
		Shiny = shiny,
		Value = value,
		Chance = Config.Probabilities(ringIndex, Config.Luck(d.levels.Scanner) * BoostService.LuckMult(d))[rarity],
	}
end

local function crackAll(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	if #d.cargo == 0 then
		notice(player, "No space eggs to crack. Drill asteroids out there!", "warn")
		return
	end
	local results = {}
	local total = 0
	for _, egg in ipairs(d.cargo) do
		local g = crackEgg(d, egg)
		table.insert(results, g)
		total += g.Value
		local key = g.Ring .. ":" .. g.Rarity
		d.index[key] = (d.index[key] or 0) + 1
		d.stats.geodes += 1
		d.stats.best = math.max(d.stats.best, g.Rarity)
		if g.Rarity >= Config.AnnounceFrom then
			Remotes.Announcement:FireAllClients(player.DisplayName, g.Name, g.Rarity)
		end
	end
	d.cargo = {}
	d.credits += total
	sync(player)
	Remotes.CrackResult:FireClient(player, results, total)
end

-- AMÉLIORATIONS ET ANNEAUX ---------------------------------------------------

local function buyUpgrade(player: Player, id: any)
	local d = DataService.Get(player)
	if not d or type(id) ~= "string" or not Config.Upgrades[id] then
		return
	end
	local level = d.levels[id]
	if level >= Config.Upgrades[id].Max then
		return
	end
	local cost = Config.UpgradeCost(id, level)
	if d.credits < cost then
		notice(player, "Not enough credits", "warn")
		return
	end
	d.credits -= cost
	d.levels[id] = level + 1
	sync(player)
end

-- FOREUSE TENUE ----------------------------------------------------------------
-- Le modèle de la foreuse équipée est soudé au torse (visible par tous). Au repos il est
-- porté sur le dos ; l'animation de forage (côté client) le ramène devant, à deux mains.
local function equipDrill(player: Player)
	local d = DataService.Get(player)
	local character = player.Character
	if not d or not character then
		return
	end
	local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local drills = assets and assets:FindFirstChild("Drills")
	local template = drills and drills:FindFirstChild("Drill" .. d.drill) :: Model?
	if not torso or not template then
		return
	end
	local old = character:FindFirstChild("EquippedDrill")
	if old then
		old:Destroy()
	end
	local model = template:Clone()
	model.Name = "EquippedDrill"
	model:SetAttribute("Tier", d.drill)
	model:ScaleTo(Config.DrillHold.Scale)
	local body = model.PrimaryPart :: BasePart
	local handle = body:FindFirstChild("Handle") :: Attachment?
	local weld = Instance.new("Weld")
	weld.Name = "DrillWeld"
	weld.Part0 = torso
	weld.Part1 = body
	weld.C0 = Config.DrillHold.Carry
	weld.C1 = if handle then handle.CFrame else CFrame.new()
	weld.Parent = body
	model.Parent = character
end
GameService.EquipDrill = equipDrill

-- JETPACK PORTÉ ----------------------------------------------------------------------
-- Le modèle ReplicatedStorage.Assets.Jetpack est soudé au dos (visible par tous). Ses tuyères
-- (attachements NozzleL / NozzleR) portent les flammes, gérées par Jetpack.client.
local function equipJetpack(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild("Jetpack") :: Model?
	if not character or not torso or not template then
		return
	end
	local old = character:FindFirstChild("EquippedJetpack")
	if old then
		old:Destroy()
	end
	local model = template:Clone()
	model.Name = "EquippedJetpack"
	local handle = model.PrimaryPart :: BasePart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "JetpackWeld"
	weld.Part0 = torso
	weld.Part1 = handle
	-- au dos, plaque contre le torse, tuyères vers l'arrière et le bas
	weld.C0 = CFrame.new(0, 0.05, torso.Size.Z / 2 + handle.Size.Z * 0.42) * CFrame.Angles(0, math.pi, 0)
	weld.Parent = handle
	model.Parent = character
end

-- État du jetpack envoyé par le client (0 = éteint, 1 = poussée, 2 = vol plané), recopié sur le
-- personnage pour que tous les joueurs voient les flammes et la traînée
local lastJet: { [Player]: number } = {}
local function onJetState(player: Player, state: any)
	if type(state) ~= "number" or (state ~= 0 and state ~= 1 and state ~= 2) then
		return
	end
	local now = os.clock()
	if lastJet[player] and now - lastJet[player] < 0.05 then
		return
	end
	lastJet[player] = now
	local character = player.Character
	if character then
		character:SetAttribute("Jet", state)
	end
end

-- Foreuse suivante, payée en $ (en Robux : MonetizationService)
local function buyDrill(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	local nextDrill = Config.Drills[d.drill + 1]
	if not nextDrill then
		return
	end
	if d.credits < nextDrill.Cost then
		notice(player, "Not enough $", "warn")
		return
	end
	d.credits -= nextDrill.Cost
	d.drill += 1
	sync(player)
	equipDrill(player)
	notice(player, nextDrill.Name .. " equipped!", "good")
end

-- Donne une foreuse achetée en Robux (appelé par MonetizationService). On ne redescend jamais.
function GameService.GrantDrill(player: Player, tier: number): boolean
	local d = DataService.Get(player)
	if not d or not Config.Drills[tier] then
		return false
	end
	if tier > d.drill then
		d.drill = tier
		sync(player)
		equipDrill(player)
		notice(player, Config.Drills[tier].Name .. " equipped!", "good")
	end
	return true
end

local function unlockRing(player: Player, index: any)
	local d = DataService.Get(player)
	if not d or type(index) ~= "number" or index ~= d.ring + 1 then
		return
	end
	local ring = Config.Rings[index]
	if not ring then
		return
	end
	if d.credits < ring.UnlockCost then
		notice(player, "Not enough credits", "warn")
		return
	end
	d.credits -= ring.UnlockCost
	d.ring = index
	sync(player)
	notice(player, ring.Name .. " unlocked! Rarer eggs out there", "good")
end

-- CHUTE DANS LE VIDE ---------------------------------------------------------

-- Tomber dans le Vide ramène à sa base avec une soute vide (docs/Mecaniques.md §13)
local function watchFalls()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = root(player)
			local d = DataService.Get(player)
			local character = player.Character
			if hrp and d and character and hrp.Position.Y < Config.Map.FallY then
				hrp.AssemblyLinearVelocity = Vector3.zero
				local grace = BeltService.Grace[player]
				if grace and os.clock() < grace then
					-- Sa roche a cassé ou disparu sous lui : on le sauve, il garde ses œufs
					BeltService.Grace[player] = nil
					character:SetPrimaryPartCFrame(CFrame.new(0, 4, Config.Map.FrontZ - 6))
					notice(player, "{Lifebuoy} Saved! Your rock broke, your eggs are safe", "info")
				else
					local lost = #d.cargo
					d.cargo = {}
					local cf = Bases.SpawnCFrame(player) or CFrame.new(0, 4, -40)
					character:SetPrimaryPartCFrame(cf)
					sync(player)
					if lost > 0 then
						notice(player, "You drifted into the Void and lost " .. lost .. " eggs", "bad")
					end
				end
			end
		end
	end
end

-- La machine à casser d'une base ne sert qu'à son propriétaire
local function bindBase(base: Model)
	local point = base:FindFirstChild("CrackPoint", true)
	local crackPrompt = point and point:FindFirstChildOfClass("ProximityPrompt")
	if not crackPrompt then
		return
	end
	crackPrompt.Triggered:Connect(function(p)
		if Bases.OwnerOf(base) == p then
			crackAll(p)
		else
			notice(p, "This is not your base", "warn")
		end
	end)
end

-- Points de service du pont : la boutique ouvre les améliorations ;
-- la vente et la fusion arrivent avec les créatures (semaine 2)
local function bindShopPoint(point: BasePart)
	local pp = point:FindFirstChildOfClass("ProximityPrompt")
	if not pp then
		return
	end
	pp.Triggered:Connect(function(p)
		if point.Name == "ShopPoint" then
			Remotes.OpenShop:FireClient(p)
		elseif point.Name == "SellPoint" then
			notice(p, "The Trading Post opens soon!", "info")
		else
			notice(p, "The Fusion Machine opens soon!", "info")
		end
	end)
end

function GameService.Start()
	Remotes.Drill.OnServerEvent:Connect(onDrill)
	Remotes.JetState.OnServerEvent:Connect(onJetState)
	Remotes.BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
	Remotes.BuyDrill.OnServerEvent:Connect(buyDrill)
	Remotes.UnlockRing.OnServerEvent:Connect(unlockRing)

	for _, base in ipairs(WorldBuilder.Bases) do
		bindBase(base)
	end
	for _, point in ipairs(WorldBuilder.ShopPoints) do
		bindShopPoint(point)
	end

	DataService.Loaded:Connect(function(player: Player)
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local credits = Instance.new("StringValue")
		credits.Name = "Credits"
		credits.Parent = ls
		ls.Parent = player
		sync(player)
		equipDrill(player)
		equipJetpack(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Attend le torse (R15 ou R6) avant d'y souder la foreuse
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait()
			sync(player)
			equipDrill(player)
			equipJetpack(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastDrill[player] = nil
		lastNotice[player] = nil
		lastJet[player] = nil
	end)
	task.spawn(watchFalls)
end

return GameService
