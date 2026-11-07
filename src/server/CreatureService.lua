-- Créatures du joueur hors éclosion : sac (rangement), cadenas, vente au Trading Post et fusion.
-- Deux endroits : la base (d.base, objets kind = "pet" posés) et le sac (d.inventory, 100 places).
-- Tout passe par Remotes.Creatures (RemoteFunction) : (action, données) -> résultat + liste à jour.
--   list                     -> { base, bag, max }
--   store(id)                base -> sac
--   send(id)                 sac -> base (première place libre)
--   lock(id)                 cadenas : ni vendue ni fusionnée
--   sell({ids})              près du stand SELL : vend, rapporte Config.PetPrice
--   selldupes()              près du stand SELL : garde le meilleur exemplaire de chaque espèce et stade
--   fuse({id, id, id})       près de la machine à fusion : 3 identiques -> stade suivant
-- Les stands ouvrent la fenêtre en mode vente / fusion (Remotes.OpenCreatures).
-- Règle : on ne vend ni n'achète de créature contre des Robux.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local HatchService = require(script.Parent.HatchService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Remotes = ReplicatedStorage.Remotes
local C = Config.PetRules

local CreatureService = {}

-- Ce que le client a besoin de savoir sur une créature
local function view(item, where: string)
	return {
		id = item.id,
		ring = item.ring,
		rarity = item.rarity,
		name = Config.PetName(item),
		species = item.name,
		stage = item.stage or 1,
		size = item.size,
		weight = item.weight,
		income = item.income,
		price = Config.PetPrice(item),
		locked = item.locked == true,
		where = where,
	}
end

local function list(d)
	local base, bag = {}, {}
	for _, item in ipairs(d.base) do
		if item.kind == "pet" then
			table.insert(base, view(item, "base"))
		end
	end
	for _, item in ipairs(d.inventory) do
		table.insert(bag, view(item, "bag"))
	end
	return { base = base, bag = bag, max = C.InventoryMax }
end

-- Trouve une créature (base ou sac) : objet, endroit, index
local function find(d, id: any): (any?, string?, number?)
	if type(id) ~= "string" then
		return nil
	end
	for i, item in ipairs(d.base) do
		if item.kind == "pet" and item.id == id then
			return item, "base", i
		end
	end
	for i, item in ipairs(d.inventory) do
		if item.id == id then
			return item, "bag", i
		end
	end
	return nil
end

-- Retire une créature de là où elle est
local function take(player: Player, d, id: string): any?
	local item, where, i = find(d, id)
	if not item then
		return nil
	end
	if where == "base" then
		return HatchService.TakePet(player, id)
	end
	table.remove(d.inventory, i :: number)
	return item
end

-- Le joueur est-il près d'un stand (SellPoint / FusionPoint) ?
local function near(player: Player, pointName: string): boolean
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	for _, point in ipairs(WorldBuilder.ShopPoints) do
		if point.Name == pointName and (point.Position - hrp.Position).Magnitude <= C.StandRange then
			return true
		end
	end
	return false
end

local function sellItems(player: Player, d, ids: { any }): (number, number)
	local total, count = 0, 0
	for _, id in ipairs(ids) do
		local item = find(d, id)
		if item and not item.locked then
			local price = Config.PetPrice(item)
			if take(player, d, id) then
				total += price
				count += 1
			end
		end
	end
	if total > 0 then
		d.credits += total
		GameService.Sync(player)
	end
	return total, count
end

local ACTIONS = {}

-- INDEX : créatures déjà eues dans la base (les autres restent des silhouettes) -----------------

-- Les créatures possédées aujourd'hui (base et sac) comptent aussi (anciennes sauvegardes)
local function markSeen(d)
	d.seen = d.seen or {}
	for _, item in ipairs(d.base) do
		if item.kind == "pet" then
			d.seen[item.ring .. ":" .. item.rarity] = true
		end
	end
	for _, item in ipairs(d.inventory) do
		d.seen[item.ring .. ":" .. item.rarity] = true
	end
end

local function ringComplete(d, ring: number): boolean
	local species = Config.Creatures[ring]
	for slot = 1, #species do
		if not d.seen[ring .. ":" .. Config.CreatureRarity(ring, slot)] then
			return false
		end
	end
	return true
end

function ACTIONS.index(_player, d)
	markSeen(d)
	local seen, claimed = {}, {}
	for key in pairs(d.seen) do
		table.insert(seen, key)
	end
	for ring in pairs(d.indexClaimed or {}) do
		table.insert(claimed, tonumber(ring))
	end
	return true, nil, { seen = seen, claimed = claimed }
end

function ACTIONS.claim(player, d, ring)
	markSeen(d)
	d.indexClaimed = d.indexClaimed or {}
	if type(ring) ~= "number" or not Config.Creatures[ring] then
		return false, "Unknown ring"
	end
	if d.indexClaimed[tostring(ring)] then
		return false, "Already claimed"
	end
	if not ringComplete(d, ring) then
		return false, "Find all 6 creatures of this ring first"
	end
	d.indexClaimed[tostring(ring)] = true -- clé texte : la sauvegarde refuse les tableaux à trous
	local money = Config.IndexReward.Money * Config.Hatch.RingIncome[ring]
	d.credits += money
	GameService.Sync(player)
	GameService.Notice(player, ("{Star} %s complete! +$%s and +%d%% luck forever"):format(Config.Rings[ring].Name, Format.Short(money), math.floor(Config.IndexReward.Luck * 100)), "good")
	return ACTIONS.index(player, d)
end

function ACTIONS.list(_player, _d)
	return true
end

function ACTIONS.store(player, d, id)
	local item, where = find(d, id)
	if not item or where ~= "base" then
		return false, "Not in your base"
	end
	if #d.inventory >= C.InventoryMax then
		return false, "Your bag is full!"
	end
	local pet = HatchService.TakePet(player, id)
	if not pet then
		return false, "Not in your base"
	end
	pet.x, pet.z = nil, nil
	table.insert(d.inventory, pet)
	return true
end

function ACTIONS.send(player, d, id)
	local item, where, i = find(d, id)
	if not item or where ~= "bag" then
		return false, "Not in your bag"
	end
	table.remove(d.inventory, i :: number)
	if not HatchService.PlacePet(player, item) then
		table.insert(d.inventory, i :: number, item)
		return false, "No room in your base!"
	end
	return true
end

function ACTIONS.lock(_player, d, id)
	local item = find(d, id)
	if not item then
		return false, "Not found"
	end
	item.locked = not item.locked
	return true
end

function ACTIONS.sell(player, d, ids)
	if not near(player, "SellPoint") then
		return false, "Go to the Trading Post to sell"
	end
	if type(ids) ~= "table" then
		return false, "Nothing selected"
	end
	local total, count = sellItems(player, d, ids)
	if count == 0 then
		return false, "Nothing to sell"
	end
	GameService.Notice(player, ("{Cash} Sold %d creature%s for $%s"):format(count, if count > 1 then "s" else "", Format.Short(total)), "good")
	return true, nil, { sold = count, total = total }
end

function ACTIONS.selldupes(player, d)
	if not near(player, "SellPoint") then
		return false, "Go to the Trading Post to sell"
	end
	-- meilleur exemplaire de chaque espèce et stade : on le garde
	local best = {}
	local all = {}
	for _, item in ipairs(d.base) do
		if item.kind == "pet" then
			table.insert(all, item)
		end
	end
	for _, item in ipairs(d.inventory) do
		table.insert(all, item)
	end
	for _, item in ipairs(all) do
		local key = ("%d:%d:%d"):format(item.ring, item.rarity, item.stage or 1)
		if not best[key] or (item.income or 0) > (best[key].income or 0) then
			best[key] = item
		end
	end
	local ids = {}
	for _, item in ipairs(all) do
		local key = ("%d:%d:%d"):format(item.ring, item.rarity, item.stage or 1)
		if best[key] ~= item and not item.locked then
			table.insert(ids, item.id)
		end
	end
	return ACTIONS.sell(player, d, ids)
end

function ACTIONS.fuse(player, d, ids)
	if not near(player, "FusionPoint") then
		return false, "Go to the Fusion Machine to fuse"
	end
	if type(ids) ~= "table" or #ids ~= 3 or ids[1] == ids[2] or ids[1] == ids[3] or ids[2] == ids[3] then
		return false, "Pick 3 creatures"
	end
	local items = {}
	for _, id in ipairs(ids) do
		local item = find(d, id)
		if not item then
			return false, "Creature not found"
		end
		if item.locked then
			return false, "Unlock it first"
		end
		table.insert(items, item)
	end
	local a = items[1]
	local stage = a.stage or 1
	for _, item in ipairs(items) do
		if item.ring ~= a.ring or item.rarity ~= a.rarity or (item.stage or 1) ~= stage then
			return false, "They must be 3 identical creatures"
		end
	end
	if stage >= #C.Stages then
		return false, "Already at the last stage"
	end
	-- le résultat va dans la base si l'une des trois y était, sinon dans le sac
	local fromBase = false
	for _, id in ipairs(ids) do
		local _, where = find(d, id)
		if where == "base" then
			fromBase = true
		end
		take(player, d, id)
	end
	local size = (items[1].size + items[2].size + items[3].size) / 3
	local weight = ((items[1].weight or 1) + (items[2].weight or 1) + (items[3].weight or 1)) / 3
	local result = {
		kind = "pet",
		id = ("%d%04d"):format(os.time(), math.random(0, 9999)),
		ring = a.ring,
		rarity = a.rarity,
		name = a.name,
		stage = stage + 1,
		size = math.floor(size * 100 + 0.5) / 100,
		weight = math.floor(weight * 10 + 0.5) / 10,
	}
	result.income = Config.PetIncome(result)
	local placed = fromBase and HatchService.PlacePet(player, result)
	if not placed then
		result.x, result.z = nil, nil
		table.insert(d.inventory, result)
	end
	GameService.Notice(player, ("{Star} %s! $%s/s"):format(Config.PetName(result), Format.Short(result.income)), "good")
	return true, nil, { result = view(result, if placed then "base" else "bag") }
end

local busy: { [Player]: boolean } = {}

local function invoke(player: Player, action: any, arg: any)
	local fn = type(action) == "string" and ACTIONS[action]
	local d = DataService.Get(player)
	if not fn or not d then
		return { ok = false, error = "Not ready" }
	end
	if busy[player] then
		return { ok = false, error = "Wait a moment" }
	end
	busy[player] = true
	d.inventory = d.inventory or {}
	local ran, ok, err, extra = pcall(fn, player, d, arg)
	busy[player] = nil
	if not ran then
		warn("[Creatures] " .. tostring(ok))
		return { ok = false, error = "Something went wrong", list = list(d) }
	end
	if not ok and err then
		GameService.Notice(player, err, "warn")
	end
	return { ok = ok == true, error = err, extra = extra, list = list(d) }
end

function CreatureService.Start()
	Remotes.Creatures.OnServerInvoke = invoke
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
	-- Studio seulement : mettre des créatures dans le sac ({ {anneau, rareté, stade, nombre} })
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "CreatureDebug"
		bf.OnInvoke = function(player: Player, specs)
			local d = DataService.Get(player)
			if not d then
				return "pas de partie"
			end
			d.inventory = d.inventory or {}
			for _, e in ipairs(specs) do
				for _ = 1, e[4] or 1 do
					local c = Config.CreatureFor(e[1], e[2])
					local item = {
						kind = "pet",
						id = ("%d%05d"):format(os.time(), math.random(0, 99999)),
						ring = e[1],
						rarity = e[2],
						name = c and c.Name or "?",
						stage = e[3] or 1,
						size = math.floor(math.random(80, 120)) / 100,
						weight = 1,
					}
					item.income = Config.PetIncome(item)
					table.insert(d.inventory, item)
				end
			end
			return ("sac %d, base %d, $%s"):format(#d.inventory, #d.base, Format.Short(d.credits))
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return CreatureService
