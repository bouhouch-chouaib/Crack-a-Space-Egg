-- Simulateur d'économie : joue des parties accélérées avec les vrais chiffres de src/shared/Config.lua
-- et dit à quel moment un joueur atteint chaque anneau, chaque foreuse et chaque soufflerie.
-- À lancer depuis la racine du dépôt, après chaque changement de prix ou de courbe :
--     lune run tools/eco-sim
--     lune run tools/eco-sim 0.6     (part du temps passée dans la soufflerie, 0.4 par défaut)
-- Le joueur simulé : il fore un œuf par voyage dans l'anneau et le type d'astéroïde qui rapportent le
-- plus par seconde de voyage (parmi ceux à sa portée), garde ses meilleures créatures (il vend les
-- autres), achète ce qu'il peut payer (soufflerie, foreuse, puis scanner et machine) et passe
-- TUNNEL_SHARE de son temps dans sa soufflerie. Pas de Robux, pas de
-- potions, pas de fusion, pas de récompenses du jour : c'est le rythme d'un joueur gratuit régulier.
-- Les monstres, le froid et les chutes ne sont pas simulés (un vrai joueur perd quelques voyages).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Config = luau.load(fs.readFile("src/shared/Config.lua"), {
	debugName = "Config",
	environment = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Enum = roblox.Enum },
})()

local TUNNEL_SHARE = tonumber(process.args[1]) or 0.4 -- part du temps dans la soufflerie (une fois achetée)
local RUNS = 25
local HOURS = 680
local OVERHEAD = 14 -- secondes perdues par voyage (viser, poser l'œuf, appuyer sur Hatch...)
local BASE_WALK = 60 -- studs à pied entre la base et le bout du quai
local BOOST_GRAB = 0.5 -- part des bonus x2 de la soufflerie attrapés
local RESERVE = 2 -- scanner et machine : achetés seulement si on garde ce multiple du prix

local J = Config.Jetpack
local H = Config.Hatch

local function median(list: { number }): number?
	if #list < RUNS / 2 then
		return nil -- moins d'une partie sur deux y arrive dans le temps simulé
	end
	table.sort(list)
	return list[math.ceil(#list / 2)]
end

local function clock(s: number?): string
	if not s then
		return "    —"
	elseif s < 3600 then
		return ("%2d min"):format(math.floor(s / 60 + 0.5))
	end
	return ("%5.1f h"):format(s / 3600)
end

local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
local function short(n: number): string
	local i = 1
	while n >= 1000 and i < #SUFFIX do
		n /= 1000
		i += 1
	end
	return (if n >= 100 or i == 1 then "%d%s" else "%.1f%s"):format(n, SUFFIX[i])
end

local function pick(weights: { number }): number
	local x = math.random()
	local last = 1
	for i, w in ipairs(weights) do
		if w > 0 then
			last = i
			x -= w
			if x <= 0 then
				return i
			end
		end
	end
	return last
end

-- Générateur à la manière de Random (Config.RollMutation attend r:NextNumber())
local dice = {
	NextNumber = function(_self): number
		return math.random()
	end,
}

-- Revenu moyen d'un œuf de cet anneau et de ce type (taille et mutation moyennes, sans chance)
local sizeAvg = 0
for _, t in ipairs(Config.PetSizes) do
	sizeAvg += t.Chance * Config.SizeIncomeMult((t.Min + t.Max) / 2)
end
local mutAvg = 1
for _, m in ipairs(Config.Mutations) do
	mutAvg += m.Chance * (m.Mult - 1)
end
local function expected(ring: number, rock: number): number
	local sum = 0
	for rarity, p in ipairs(Config.RockChances(ring, rock)) do
		if p > 0 then
			sum += p * Config.CreatureIncome(ring, rarity, 1)
		end
	end
	return sum * sizeAvg * mutAvg
end

local function petSize(): number
	local x = math.random()
	for _, t in ipairs(Config.PetSizes) do
		x -= t.Chance
		if x <= 0 then
			return t.Min + math.random() * (t.Max - t.Min)
		end
	end
	return 1
end

-- Anneau le plus lointain que ce niveau de jetpack permet d'atteindre
local function farthest(level: number): number
	local reach = Config.JetpackReach(level)
	local ring = 1
	for k = 2, #Config.Rings do
		if reach >= Config.RingGapAfter(k - 1) * 1.05 then
			ring = k
		else
			break
		end
	end
	return ring
end

type Run = { rings: { number }, drills: { number }, tunnels: { number }, marks: { [number]: { level: number, income: number } } }
local MARKS = { 600, 1800, 3600, 2 * 3600, 5 * 3600, 10 * 3600, 24 * 3600, 48 * 3600, 72 * 3600, 120 * 3600, 180 * 3600, 250 * 3600, 350 * 3600, 480 * 3600, 640 * 3600 }

local function play(): Run
	local t, credits, xp = 0, 0, 0
	local drill, tunnel, scanner, mSpeed, mLuck, mMut = 1, 0, 0, 0, 0, 0
	local pets: { number } = {} -- revenus des créatures posées
	local pending: { { at: number, income: number } } = {} -- œufs en incubation
	local seen: { [string]: boolean } = {}
	local tunnelTime = 0
	local machineFree = 0
	local run: Run = { rings = {}, drills = { 0 }, tunnels = {}, marks = {} }
	local nextMark = 1

	local function income(): number
		local sum = 0
		for _, v in ipairs(pets) do
			sum += v
		end
		return sum
	end

	local function pass(dt: number)
		-- les œufs éclos pendant ce temps rejoignent la base (la moins bonne créature est vendue)
		local i = 1
		while i <= #pending do
			if pending[i].at <= t + dt then
				local v = pending[i].income
				table.remove(pending, i)
				if #pets < H.Slots then
					table.insert(pets, v)
				else
					table.sort(pets)
					local sold = math.min(pets[1], v)
					pets[1] = math.max(pets[1], v)
					credits += sold * Config.PetRules.SellSeconds
				end
			else
				i += 1
			end
		end
		credits += income() * dt
		t += dt
		while nextMark <= #MARKS and t >= MARKS[nextMark] do
			run.marks[nextMark] = { level = (Config.JetpackLevel(xp)), income = income() }
			nextMark += 1
		end
	end

	local function shop()
		local bought = true
		while bought do
			bought = false
			local nt = J.Tunnels[tunnel + 1]
			if nt and credits >= nt.Cost then
				credits -= nt.Cost
				tunnel += 1
				run.tunnels[tunnel] = t
				bought = true
			end
			local nd = Config.Drills[drill + 1]
			if nd and credits >= nd.Cost then
				credits -= nd.Cost
				drill += 1
				run.drills[drill] = t
				bought = true
				if drill == Config.Guide.Drill then
					credits += Config.Guide.Reward.Money * H.RingIncome[1] -- récompense de fin de tutoriel
				end
			end
			if scanner < Config.Upgrades.Scanner.Max and credits >= Config.UpgradeCost("Scanner", scanner) * RESERVE then
				credits -= Config.UpgradeCost("Scanner", scanner)
				scanner += 1
				bought = true
			end
			if mSpeed < Config.Machine.Max and credits >= Config.MachineCost("Speed", mSpeed) * RESERVE then
				credits -= Config.MachineCost("Speed", mSpeed)
				mSpeed += 1
				bought = true
			end
			if mLuck < Config.Machine.Max and credits >= Config.MachineCost("Luck", mLuck) * RESERVE then
				credits -= Config.MachineCost("Luck", mLuck)
				mLuck += 1
				bought = true
			end
			if mMut < Config.Machine.Max and credits >= Config.MachineCost("Mutation", mMut) * RESERVE then
				credits -= Config.MachineCost("Mutation", mMut)
				mMut += 1
				bought = true
			end
		end
	end

	local first = true
	while t < HOURS * 3600 do
		local level = Config.JetpackLevel(xp)
		-- soufflerie : par tranches d'une minute, jusqu'à sa part du temps
		if tunnel >= 1 and tunnelTime < TUNNEL_SHARE * t then
			local boost = 1 + BOOST_GRAB * (J.Boost.Mult - 1) * J.Boost.Duration / ((J.Boost.Every[1] + J.Boost.Every[2]) / 2 + J.Boost.Offer + J.Boost.Duration)
			xp += J.Tunnels[tunnel].XP * 60 * boost
			tunnelTime += 60
			pass(60)
			shop()
			continue
		end
		-- voyage : l'anneau et le type d'astéroïde à portée qui rapportent le plus par seconde de voyage
		local air, ground = Config.AirSpeed(level), Config.GroundSpeed(level)
		local best, bestRock, bestScore, bestTime, bestFlight = 1, 1, -1, 0, 0
		for k = 1, farthest(level) do
			local flight = 2 * Config.RingDistance(k) / air
			for rock, def in ipairs(Config.RockTypes) do
				local time = flight + 2 * BASE_WALK / ground + Config.Rings[k].EggHP * def.HP / Config.DrillPower(drill) + OVERHEAD
				local score = expected(k, rock) / time
				if score > bestScore then
					best, bestRock, bestScore, bestTime, bestFlight = k, rock, score, time, flight
				end
			end
		end
		pass(bestTime)
		xp += bestFlight * J.FlightXP
		if not run.rings[best] then
			run.rings[best] = t
		end
		local rarity = pick(Config.RockChances(best, bestRock))
		local mutation = Config.RollMutation(dice :: any, Config.Luck(scanner) * Config.MachineMutation(mMut))
		if first then
			rarity = Config.Guide.FirstRarity
			mutation = nil
			first = false
		end
		if Config.Eggs[best][rarity + 1] and math.random() < Config.MachineLuck(mLuck) then
			rarity += 1
		end
		local value = Config.CreatureIncome(best, rarity, petSize(), mutation)
		local key = best .. ":" .. rarity
		if not seen[key] then
			seen[key] = true
			credits += math.max(Config.IndexReward.NewMin, value * Config.IndexReward.NewSeconds)
		end
		-- la machine ne dégage qu'un œuf à la fois : un œuf très rare fait attendre les suivants
		local start = math.max(t, machineFree)
		machineFree = start + Config.MachineTime(rarity, mSpeed)
		table.insert(pending, { at = machineFree + H.Time[rarity], income = value })
		shop()
	end
	return run
end

-- PARTIES ET TABLEAUX --------------------------------------------------------------------------------

local runs: { Run } = {}
for i = 1, RUNS do
	math.randomseed(1000 + i)
	runs[i] = play()
end

local function column(get: (Run) -> number?): number?
	local list = {}
	for _, r in ipairs(runs) do
		local v = get(r)
		if v then
			table.insert(list, v)
		end
	end
	return median(list)
end

print(("Simulation : %d parties de %d h, %d %% du temps dans la soufflerie (médianes)"):format(RUNS, HOURS, TUNNEL_SHARE * 100))
print("")
print("ANNEAU                 premier œuf   niveau du palier")
for k, ring in ipairs(Config.Rings) do
	print(("%d %-20s %s        Lv %d"):format(k, ring.Name, clock(column(function(r)
		return r.rings[k]
	end)), J.Tiers[k].Level))
end
print("")
print("FOREUSE                achetée à     prix")
for k = 2, #Config.Drills do
	print(("%2d %-19s %s        $%s"):format(k, Config.Drills[k].Name, clock(column(function(r)
		return r.drills[k]
	end)), short(Config.Drills[k].Cost)))
end
print("")
print("SOUFFLERIE             achetée à     prix       XP/s")
for k, tu in ipairs(J.Tunnels) do
	print(("%d %-20s %s        $%-8s %s"):format(k, tu.Name, clock(column(function(r)
		return r.tunnels[k]
	end)), short(tu.Cost), short(tu.XP)))
end
print("")
print("TEMPS DE JEU    niveau    revenu par seconde")
for i, s in ipairs(MARKS) do
	local level = column(function(r)
		return r.marks[i] and r.marks[i].level
	end)
	local inc = column(function(r)
		return r.marks[i] and r.marks[i].income
	end)
	print(("%s         Lv %-5d  $%s"):format(clock(s), level or 0, short(inc or 0)))
end
