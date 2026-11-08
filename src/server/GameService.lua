-- La boucle de jeu côté serveur : forage, soute, casse des œufs, améliorations, anneaux.
-- Le serveur décide de tout ce qui rapporte : le client n'envoie que des intentions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DrillSkin = require(ReplicatedStorage.Shared.DrillSkin)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local BeltService = require(script.Parent.BeltService)
local Bases = require(script.Parent.Bases)
local WorldBuilder = require(script.Parent.WorldBuilder)
local BoostService = require(script.Parent.BoostService)
local Tracking = require(script.Parent.Tracking)

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
	-- « egg » ou « geode » pour chaque entrée de la soute (HUD)
	local kinds = {}
	for _, egg in ipairs(d.cargo) do
		table.insert(kinds, if type(egg) == "table" and egg.kind == "geode" then "geode" else "egg")
	end
	player:SetAttribute("CargoKinds", table.concat(kinds, ","))
	-- sac de minerais (stand SELL)
	local gemValue = 0
	for _, g in ipairs(d.gems or {}) do
		gemValue += g.value
	end
	player:SetAttribute("GemCount", #(d.gems or {}))
	player:SetAttribute("GemValue", gemValue)
	player:SetAttribute("GemsSold", d.stats.gemsSold or 0)
	player:SetAttribute("ReadyEggs", #(d.ready or {}))
	-- Œufs dérochés prêts à poser (« 1:5,2:3 » = anneau:rareté), pour la barre des œufs (Hatchery.client)
	local ready = {}
	for _, egg in ipairs(d.ready or {}) do
		table.insert(ready, egg.ring .. ":" .. egg.rarity)
	end
	player:SetAttribute("ReadyList", table.concat(ready, ","))
	player:SetAttribute("Ring", d.ring)
	-- Starter Pack : fin de l'offre (3 jours après la première partie) et achat déjà fait
	player:SetAttribute("StarterEnds", (d.firstJoin or 0) + Config.Shop.Featured.Duration)
	player:SetAttribute("StarterBought", d.starterBought == true)
	-- Guide de la première minute (Guide.client) : étape atteinte, Config.Guide.Steps à la fin
	player:SetAttribute("GuideStep", d.guide or 0)
	for key in pairs(d.tips or {}) do
		player:SetAttribute("Tip_" .. key, true)
	end
	player:SetAttribute("Drill", d.drill)
	player:SetAttribute("Supernovas", d.supernovas or 0)
	player:SetAttribute("TunnelTier", d.tunnel or 0)
	for key, level in pairs(d.machine or {}) do
		player:SetAttribute("Mach_" .. key, level)
	end
	-- Niveau du jetpack (HUD) et vitesses qui en découlent (Jetpack.client)
	local jl, jx, jn = Config.JetpackLevel(d.jetXP or 0)
	player:SetAttribute("JetLevel", jl)
	player:SetAttribute("JetXP", jx)
	player:SetAttribute("JetXPNeed", jn)
	player:SetAttribute("GroundSpeed", Config.GroundSpeed(jl))
	player:SetAttribute("AirSpeed", Config.AirSpeed(jl))
	-- palier du jetpack (modèle porté, jauge) : un changement rééquipe le joueur (Start)
	player:SetAttribute("JetTier", (Config.JetpackTier(jl)))
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
-- Quêtes du jour : les services signalent ce que fait le joueur (RewardService remplace cette fonction)
GameService.Quest = function(_player: Player, _kind: string, _amount: number?) end
-- Fin du tutoriel : RewardService remplace cette fonction
GameService.GuideDone = function(_player: Player) end
-- Appelé à chaque coup de foreuse (posé par MonsterService) : (player, roche, anneau)
GameService.DrillHook = nil :: ((Player, BasePart, number) -> ())?

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

-- Ce que le tutoriel impose au prochain forage : { rarity, kind, size? } ou nil
local function tutorialDrop(d, ringIndex: number)
	local G = Config.Guide
	local step = d.guide or 0
	if step >= G.Steps or ringIndex ~= 1 then
		return nil
	end
	local hatched = 0
	for _, n in pairs(d.index) do
		hatched += n
	end
	local pending = #d.ready
	for _, item in ipairs(d.base) do
		if item.kind == "egg" then
			pending += 1
		end
	end
	if hatched > 0 or pending > 0 then
		return nil
	end
	-- d'abord une géode à vendre ; une fois le minerai vendu, l'œuf surprise
	if (d.stats.gemsSold or 0) == 0 then
		return if #d.gems == 0 then { rarity = G.GeodeRarity, kind = "geode", size = G.GeodeSize } else nil
	end
	return { rarity = G.SecondRarity, kind = "egg" }
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
	local max = Config.CargoSlots()
	local room = max - #d.cargo
	if room <= 0 then
		notice(player, "{Egg} You already carry an egg! Bring it back to your base", "warn")
		return
	end

	local damage = Config.DrillPower(d.drill) * Config.DrillTick
	local guarded = a.part:GetAttribute("Guarded") == true
	-- bruit et gardiens des anneaux à monstres (MonsterService)
	if GameService.DrillHook then
		GameService.DrillHook(player, a.part, a.ring)
	end
	local eggs, broken, progress = BeltService.Hit(a, player, damage, room)
	if eggs > 0 then
		GameService.Quest(player, "drill", eggs)
	end
	if broken then
		GameService.Quest(player, "break", 1)
	end
	local rarities = {}
	local kinds = {}
	if eggs > 0 then
		local forced = tutorialDrop(d, a.ring)
		for _ = 1, eggs do
			local rarity = rollRarity(d, a.ring)
			if guarded then
				-- astéroïde gardé : la rareté est tirée deux fois, on garde la meilleure
				rarity = math.max(rarity, rollRarity(d, a.ring))
			end
			-- une fois sur 3 : une géode à la place de l'œuf (Config.Geodes)
			local kind = if rng:NextNumber() < Config.Geodes.Chance then "geode" else "egg"
			if forced then
				rarity, kind = forced.rarity, forced.kind
			end
			if kind == "geode" then
				Tracking.Funnel(player, "Gems", 1, "Geode drilled")
			end
			table.insert(d.cargo, { ring = a.ring, rarity = rarity, kind = kind, size = forced and forced.size })
			table.insert(rarities, rarity)
			table.insert(kinds, kind)
		end
		-- tous les anneaux sont ouverts (on y va à ses risques) : d.ring retient le plus lointain
		-- où l'on a déjà sorti un œuf (onglets de l'Index, montant des paquets d'argent)
		if a.ring > d.ring then
			d.ring = a.ring
			notice(player, ("{Star} First egg from the %s!"):format(Config.Rings[a.ring].Name), "good")
			Tracking.Funnel(player, "Rings", a.ring, Config.Rings[a.ring].Name)
		end
		sync(player)
	end
	-- Coup visible par tous : nombres de dégâts, œufs qui jaillissent (avec leur rareté), casse.
	-- Les effets ne passent pas par la position du modèle (il défile) : on envoie la roche visée.
	-- eggLeft : vie restante de l'œuf en cours pour ce joueur (sa barre), eggHP : vie d'un œuf
	local eggHP = Config.Rings[a.ring].EggHP
	Remotes.DrillHit:FireAllClients(a.part, player, damage, rarities, broken, eggHP - progress, eggHP, kinds)
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
	Tracking.Funnel(player, id, level + 1, ("%s %d"):format(id, level + 1))
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
	-- skin choisi à l'atelier (couleurs, effet), gardé quand on change de foreuse
	DrillSkin.Apply(model, d.skin, true)
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
-- Le modèle du palier (ReplicatedStorage.Assets.Jetpacks.JetN, sinon Assets.Jetpack) est soudé au
-- dos (visible par tous). Ses tuyères (attachements NozzleL / NozzleR) portent les flammes,
-- gérées par Jetpack.client.
local function equipJetpack(player: Player)
	local character = player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local _, tier = Config.JetpackTier((player:GetAttribute("JetLevel") or 1) :: number)
	local tiers = assets and assets:FindFirstChild("Jetpacks")
	local template = (tiers and tiers:FindFirstChild(tier.Model) or assets and assets:FindFirstChild("Jetpack")) :: Model?
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
	-- modèles générés à l'envers (plaque de dos vers -Z) : on les retourne
	if template:GetAttribute("Flip") then
		weld.C1 = CFrame.Angles(0, math.pi, 0)
	end
	weld.Parent = handle
	model.Parent = character
end
GameService.EquipJetpack = equipJetpack

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
	Tracking.Funnel(player, "Drills", d.drill, nextDrill.Name)
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
	d.paidDrill = math.max(d.paidDrill or 1, tier) -- gardée après une Supernova
	if tier > d.drill then
		d.drill = tier
		Tracking.Funnel(player, "Drills", tier, Config.Drills[tier].Name)
		sync(player)
		equipDrill(player)
		notice(player, Config.Drills[tier].Name .. " equipped!", "good")
	end
	return true
end

-- CHUTE DANS LE VIDE ---------------------------------------------------------

-- Tomber dans le Vide tue le joueur : il réapparaît à sa base et perd l'œuf porté (§13).
-- Le carburant du jetpack (Config.Jetpack.Tiers) décide jusqu'où on peut aller sans tomber.
local function watchFalls()
	Players.RespawnTime = Config.Map.RespawnTime
	while true do
		task.wait(0.2)
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
				elseif not character:GetAttribute("VoidDead") then
					local lost = #d.cargo
					Tracking.Death(player, "Void", d.cargo[1])
					d.cargo = {}
					sync(player)
					-- mort : le client montre la chute (VoidDead), puis réapparition à la base
					character:SetAttribute("VoidDead", true)
					local hum = character:FindFirstChildOfClass("Humanoid")
					hrp.Anchored = true
					if hum then
						hum.Health = 0
					end
					notice(player, if lost > 0
						then "{Warning} You fell into the Void and lost your egg! Train your jetpack to fly further"
						else "{Warning} You fell into the Void! Train your jetpack to fly further", "bad")
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

-- Points de service du pont (stands de Ship.Shops, tools/build-shops.lua) : STORE ouvre la boutique
-- Robux, ITEMS l'atelier des foreuses, SELL la vente des créatures, la machine la fusion
local function bindShopPoint(point: BasePart)
	local pp = point:FindFirstChildOfClass("ProximityPrompt")
	if not pp then
		return
	end
	-- STORE, ITEMS et SELL s'ouvrent en marchant sur le tapis du stand (ShipShops.client) : pas d'invite
	if point.Name == "StorePoint" or point.Name == "ShopPoint" or point.Name == "SellPoint" then
		pp.Enabled = false
	end
	pp.Triggered:Connect(function(p)
		if point.Name == "StorePoint" then
			Remotes.OpenShop:FireClient(p, "Store")
		elseif point.Name == "ShopPoint" then
			Remotes.OpenShop:FireClient(p)
		elseif point.Name == "SellPoint" then
			-- comptoir de vente : minerais et créatures (SellUI.client)
			Remotes.OpenShop:FireClient(p, "Sell")
		else
			Remotes.OpenCreatures:FireClient(p, "fuse")
		end
	end)
end

function GameService.Start()
	Remotes.Drill.OnServerEvent:Connect(onDrill)
	-- Guide : le client dit quelle étape il a finie ; on garde la plus avancée (jamais de retour en arrière)
	-- ("tip", clé) : un tutoriel au bon moment a été montré ; ("skip") : le joueur passe le guide
	Remotes.Guide.OnServerEvent:Connect(function(player: Player, step: any, key: any)
		local d = DataService.Get(player)
		if not d then
			return
		end
		if step == "tip" then
			local known = type(key) == "string" and (Config.Guide.Tips[key] or string.match(key, "^drill%d%d?$") or string.match(key, "^tunnel%d%d?$"))
			if known and not d.tips[key] then
				d.tips[key] = true
				player:SetAttribute("Tip_" .. key, true)
				Tracking.Event(player, "Tip_" .. key)
			end
			return
		end
		if step == "skip" then
			if (d.guide or 0) < Config.Guide.Steps then
				Tracking.Event(player, ("GuideSkipped_%d"):format(d.guide or 0))
				d.guide = Config.Guide.Steps
				player:SetAttribute("GuideStep", d.guide)
			end
			return
		end
		if type(step) ~= "number" or step ~= step then
			return
		end
		step = math.clamp(math.floor(step), 0, Config.Guide.Steps)
		if step > (d.guide or 0) then
			for s = (d.guide or 0) + 1, step do
				Tracking.Onboarding(player, s + 1, Config.Guide.Names[s] or ("Step " .. s))
			end
			d.guide = step
			player:SetAttribute("GuideStep", step)
			-- tutoriel fini pour de bon (pas passé) : la récompense
			if step >= Config.Guide.Steps and not d.guideRewarded and d.drill >= Config.Guide.Drill and (d.tunnel or 0) >= 1 then
				d.guideRewarded = true
				GameService.GuideDone(player)
			end
		end
	end)
	Remotes.JetState.OnServerEvent:Connect(onJetState)
	Remotes.BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
	Remotes.BuyDrill.OnServerEvent:Connect(buyDrill)

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
		local d = DataService.Get(player)
		if d and (d.firstJoin or 0) == 0 then
			d.firstJoin = os.time()
		end
		-- Guide : nouveau joueur = depuis le début ; ancien joueur qui a déjà des créatures = déjà fait
		if d and (d.guide or -1) < 0 then
			d.guide = if next(d.index) ~= nil then Config.Guide.Steps else 0
			if d.guide == 0 then
				Tracking.Onboarding(player, 1, "Join")
			end
		end
		sync(player)
		equipDrill(player)
		equipJetpack(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		-- nouveau palier de jetpack : nouveau modèle sur le dos, et l'anneau qu'il permet d'atteindre
		local tierShown = nil :: number?
		player:GetAttributeChangedSignal("JetTier"):Connect(function()
			local tier = player:GetAttribute("JetTier") :: number?
			if tierShown and tier and tier > tierShown then
				equipJetpack(player)
				local t = Config.Jetpack.Tiers[tier]
				Tracking.Funnel(player, "JetpackTiers", tier, t.Name)
				local ring = Config.Rings[math.min(tier, #Config.Rings)]
				notice(player, if tier <= #Config.Rings
					then ("{Jetpack} New jetpack: %s! You can now fly to the %s"):format(t.Name, ring.Name)
					else ("{Jetpack} New jetpack: %s!"):format(t.Name), "good")
			end
			tierShown = tier
		end)
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
	-- Studio seulement : mettre le jetpack d'un joueur à un niveau (tests des paliers)
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "JetDebug"
		bf.OnInvoke = function(player: Player, level: number)
			local d = DataService.Get(player)
			if not d then
				return "pas de données"
			end
			local xp = 0
			for l = 1, level - 1 do
				xp += Config.JetpackXPNeed(l)
			end
			d.jetXP = xp
			sync(player)
			return ("niveau %d, palier %s, carburant %.2f s, vitesse %.1f"):format(level, tostring(player:GetAttribute("JetTier")), Config.JetpackFuel(level), Config.AirSpeed(level))
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return GameService
