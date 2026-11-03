-- La boucle de jeu côté serveur : forage, soute, casse des géodes, améliorations, anneaux.
-- Le serveur décide de tout ce qui rapporte : le client n'envoie que des intentions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local Remotes = ReplicatedStorage.Remotes

local GameService = {}

local rng = Random.new()
local lastDrill: { [Player]: number } = {}
local lastNotice: { [Player]: number } = {}
local STATION_SPAWN = CFrame.new(0, 4, 0)

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
	player:SetAttribute("CargoMax", Config.CargoSlots(d.levels.Cargo))
	player:SetAttribute("Ring", d.ring)
	for id in pairs(Config.Upgrades) do
		player:SetAttribute("Lvl_" .. id, d.levels[id])
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls:FindFirstChild("Credits") :: IntValue).Value = d.credits
	end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16 * Config.Speed(d.levels.Thruster)
	end
end
GameService.Sync = sync

local function root(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- FORAGE ------------------------------------------------------------------

local function onDrill(player: Player, target: any)
	local d = DataService.Get(player)
	if not d or typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return
	end
	local asteroids = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Asteroids")
	if not asteroids or target.Parent ~= asteroids then
		return
	end
	-- Cadence : un coup tous les DrillTick, avec un peu de marge pour la latence
	local now = os.clock()
	if lastDrill[player] and now - lastDrill[player] < Config.DrillTick * 0.8 then
		return
	end
	lastDrill[player] = now

	local hrp = root(player)
	if not hrp then
		return
	end
	local reach = (hrp.Position - target.Position).Magnitude - target.Size.X / 2
	if reach > Config.DrillRange + 6 then
		return
	end
	local ringIndex = target:GetAttribute("Ring") :: number
	if ringIndex > d.ring then
		notice(player, "Unlock the " .. Config.Rings[ringIndex].Name .. " at the Upgrades terminal", "warn")
		return
	end
	local hp = target:GetAttribute("HP") :: number
	if hp <= 0 then
		return
	end
	local max = Config.CargoSlots(d.levels.Cargo)
	if #d.cargo >= max then
		notice(player, "Cargo full! Go back to the station to crack your space eggs", "warn")
		return
	end

	hp -= Config.DrillPower(d.levels.Drill) * Config.DrillTick
	if hp > 0 then
		target:SetAttribute("HP", hp)
		return
	end

	-- L'astéroïde casse : des géodes dans la soute, puis il se recharge
	target:SetAttribute("HP", 0)
	local ring = Config.Rings[ringIndex]
	local gained = math.min(ring.EggsPerAsteroid, max - #d.cargo)
	for _ = 1, gained do
		table.insert(d.cargo, ringIndex)
	end
	sync(player)
	Remotes.AsteroidBroken:FireAllClients(target, player, gained)

	local color = target.Color
	target.Color = Color3.fromRGB(40, 40, 44)
	target.Transparency = 0.35
	task.delay(Config.AsteroidRespawn, function()
		if target.Parent then
			target.Color = color
			target.Transparency = 0
			target:SetAttribute("HP", target:GetAttribute("MaxHP"))
		end
	end)
end

-- CASSE DES GÉODES ---------------------------------------------------------

local function pick(weights: { number }): number
	local x = rng:NextNumber()
	local acc = 0
	for i, w in ipairs(weights) do
		acc += w
		if x < acc then
			return i
		end
	end
	return 1
end

local function rollEgg(d, ringIndex: number)
	local probs = Config.Probabilities(ringIndex, Config.Luck(d.levels.Scanner))
	local rarity = pick(probs)
	-- Compteur de veine
	d.pity += 1
	if rarity < 5 and d.pity >= Config.PityLegendary then
		rarity = 5
	end
	if rarity >= 5 then
		d.pity = 0
	end

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
		Chance = probs[rarity],
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
	for _, ringIndex in ipairs(d.cargo) do
		local g = rollEgg(d, ringIndex)
		table.insert(results, g)
		total += g.Value
		local key = ringIndex .. ":" .. g.Rarity
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

local function unlockRing(player: Player, index: any)
	local d = DataService.Get(player)
	if not d or type(index) ~= "number" or index ~= d.ring + 1 then
		return
	end
	local ring = Config.Rings[index]
	if not ring then
		return
	end
	if d.levels.Drill < ring.DrillLevel then
		notice(player, "Your drill must be level " .. ring.DrillLevel, "warn")
		return
	end
	if d.credits < ring.UnlockCost then
		notice(player, "Not enough credits", "warn")
		return
	end
	d.credits -= ring.UnlockCost
	d.ring = index
	sync(player)
	notice(player, ring.Name .. " unlocked! Rarer crystals out there", "good")
end

-- CHUTE DANS LE VIDE ---------------------------------------------------------

-- Tomber dans l'espace ramène à la station, mais fait perdre la moitié de la soute
local function watchFalls()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = root(player)
			local d = DataService.Get(player)
			if hrp and d and hrp.Position.Y < -140 then
				local lost = math.floor(#d.cargo / 2)
				for _ = 1, lost do
					table.remove(d.cargo)
				end
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = STATION_SPAWN
				sync(player)
				if lost > 0 then
					notice(player, "You drifted into space and lost " .. lost .. " eggs", "bad")
				end
			end
		end
	end
end

function GameService.Start()
	Remotes.Drill.OnServerEvent:Connect(onDrill)
	Remotes.BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
	Remotes.UnlockRing.OnServerEvent:Connect(unlockRing)

	local station = workspace.World.Station
	local crackPrompt = station.CrackMachine:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	local shopPrompt = station.ShopTerminal:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	crackPrompt.Triggered:Connect(crackAll)
	shopPrompt.Triggered:Connect(function(p)
		Remotes.OpenShop:FireClient(p)
	end)

	DataService.Loaded:Connect(function(player: Player)
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local credits = Instance.new("IntValue")
		credits.Name = "Credits"
		credits.Parent = ls
		ls.Parent = player
		sync(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait()
			sync(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastDrill[player] = nil
		lastNotice[player] = nil
	end)
	task.spawn(watchFalls)
end

return GameService
