-- Mode testeur (Config.Testers) : tant qu'il est allumé, chaque joueur reçoit tout à son arrivée,
-- au niveau maximum, pour pouvoir tout essayer. Les parties de test vont dans une sauvegarde à part
-- (DataService) et ne touchent ni les vraies parties ni les classements.
-- Relancé à chaque arrivée : ce qui a été vendu ou dépensé revient.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Testers = {}

function Testers.Enabled(): boolean
	return Config.Testers.Everyone == true
end

-- Créature du sac, comme celles qui sortent des œufs
local function creature(ring: number, rarity: number, n: number)
	local c = Config.CreatureFor(ring, rarity)
	local item = {
		kind = "pet",
		id = ("%d%02d%02d%02d"):format(os.time(), ring, rarity, n % 100),
		ring = ring,
		rarity = rarity,
		name = c and c.Name or "?",
		stage = 1,
		size = 1,
		weight = 1,
	}
	item.income = Config.PetIncome(item)
	return item
end

function Testers.Grant(d)
	local T = Config.Testers
	d.credits = math.max(d.credits or 0, T.Money)
	-- équipement au plus haut palier (« payé » : une Supernova ne le reprend pas)
	d.drill = #Config.Drills
	d.paidDrill = #Config.Drills
	d.suit = #Config.Suits
	d.paidSuit = #Config.Suits
	d.bat = #Config.Bats
	d.shields = math.max(d.shields or 0, T.Shields)
	d.levels = d.levels or {}
	for key, up in pairs(Config.Upgrades) do
		d.levels[key] = up.Max
	end
	d.machine = d.machine or {}
	for _, key in ipairs(Config.Machine.Order) do
		d.machine[key] = Config.Machine.Max
	end
	d.tunnel = #Config.Jetpack.Tunnels
	-- jetpack au niveau maximum : tous les anneaux à portée
	local xp = 0
	for level = 1, Config.Jetpack.MaxLevel - 1 do
		xp += Config.JetpackXPNeed(level)
	end
	d.jetXP = math.max(d.jetXP or 0, xp)
	d.ring = #Config.Rings
	-- skins : ceux en $ ici, ceux en Robux par les passes (considérés comme achetés)
	d.skins = d.skins or {}
	for _, s in ipairs(Config.DrillSkins) do
		d.skins[s.Key] = true
	end
	-- skins de base débloqués par les Supernovas
	local need = 0
	for _, s in ipairs(Config.BaseSkins) do
		need = math.max(need, s.Supernovas or 0)
	end
	d.supernovas = math.max(d.supernovas or 0, need)
	-- reliques
	d.relics = d.relics or {}
	d.relicsFound = d.relicsFound or {}
	for _, r in ipairs(Config.Relics) do
		d.relics[r.Key] = math.max(d.relics[r.Key] or 0, 1)
		d.relicsFound[r.Key] = true
	end
	-- une créature de chaque espèce dans le sac, et l'Index complet
	d.inventory = d.inventory or {}
	d.seen = d.seen or {}
	d.index = d.index or {}
	local have = {}
	for _, item in ipairs(d.inventory) do
		have[item.ring .. ":" .. item.rarity] = true
	end
	local n = 0
	for ring = 1, #Config.Rings do
		for rarity in pairs(Config.Eggs[ring] or {}) do
			local key = ring .. ":" .. rarity
			d.seen[key] = true
			d.index[key] = math.max(d.index[key] or 0, 1)
			if not have[key] and #d.inventory < Config.PetRules.InventoryMax then
				n += 1
				table.insert(d.inventory, creature(ring, rarity, n))
			end
		end
	end
	-- un œuf prêt à poser de chaque rareté, pour tester les éclosions
	d.ready = d.ready or {}
	if #d.ready == 0 then
		table.insert(d.ready, { ring = 1, rarity = 1 })
		local last = #Config.Rings
		for rarity in pairs(Config.Eggs[last] or {}) do
			table.insert(d.ready, { ring = last, rarity = rarity })
		end
	end
	-- pas de tutoriel : on arrive directement avec tout
	d.guide = Config.Guide.Steps
	d.guideRewarded = true
end

return Testers
