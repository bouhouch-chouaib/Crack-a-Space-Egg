-- Récompenses qui font revenir (Config.Rewards, docs/Mecaniques.md §16) : connexion quotidienne,
-- cadeaux de temps de jeu, 3 quêtes du jour, codes, bonus du groupe, boost gratuit contre une pub.
-- Le serveur décide de tout ; la fenêtre REWARDS (RewardsUI.client) ne fait qu'afficher et demander.
--   Remotes.Rewards (RemoteFunction) : ("state") -> état complet ; ("daily") ; ("playtime", i) ;
--     ("quest", i) ; ("code", texte) ; ("group") ; ("ad")  -> { ok, error?, state }
--   Publié sur le joueur : RewardsReady (nombre de cadeaux à réclamer, pour la pastille du HUD)
-- Les autres services font avancer les quêtes avec GameService.Quest(joueur, type, quantité).
-- Les journées changent à minuit UTC (même jour pour tous les serveurs).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local BoostService = require(script.Parent.BoostService)

local R = Config.Rewards
local Remotes = ReplicatedStorage.Remotes
local RewardService = {}

local DAY = 86400
local POTIONS = { Luck = "Luck", MoneyBoost = "Money", JetXP = "JetXP" } -- clé de récompense -> potion
local POTION_NAMES = { Luck = "x2 Luck", MoneyBoost = "x2 Money", JetXP = "x2 Jetpack XP" }

local function today(): number
	return os.time() // DAY
end

-- Groupe du jeu : Config.Rewards.GroupId, sinon le groupe propriétaire du jeu
local function groupId(): number
	if R.GroupId ~= 0 then
		return R.GroupId
	end
	return if game.CreatorType == Enum.CreatorType.Group then game.CreatorId else 0
end

-- DONNÉES -------------------------------------------------------------------------------------

local function data(player: Player)
	local d = DataService.Get(player)
	if not d then
		return nil
	end
	local r = d.rewards
	if type(r) ~= "table" then
		r = {}
		d.rewards = r
	end
	r.daily = r.daily or { streak = 0, lastDay = -1 }
	r.play = r.play or { day = -1, seconds = 0, claimed = {} }
	r.quests = r.quests or { day = -1, list = {}, bonus = false }
	r.codes = r.codes or {}
	r.lastAd = r.lastAd or 0
	-- nouvelle journée : temps de jeu remis à zéro, nouvelles quêtes
	local t = today()
	if r.play.day ~= t then
		r.play = { day = t, seconds = 0, claimed = {} }
	end
	if r.quests.day ~= t then
		local rng = Random.new(t * 7919 + player.UserId % 100000)
		local pool = {}
		for i = 1, #R.Quests do
			pool[i] = i
		end
		local list = {}
		for _ = 1, math.min(3, #pool) do
			local def = R.Quests[table.remove(pool, rng:NextInteger(1, #pool))]
			local goal
			if def.IncomeGoal then
				goal = math.floor(def.IncomeGoal * Config.Hatch.RingIncome[math.clamp(d.ring or 1, 1, #Config.Hatch.RingIncome)])
			elseif type(def.Goal) == "table" then
				goal = rng:NextInteger(def.Goal[1], def.Goal[2])
			else
				goal = def.Goal
			end
			table.insert(list, { kind = def.Kind, goal = goal, progress = 0, claimed = false })
		end
		r.quests = { day = t, list = list, bonus = false }
	end
	return d, r
end

-- Montant en $ d'une récompense (selon l'anneau le plus lointain atteint)
local function moneyOf(d, units: number): number
	local inc = Config.Hatch.RingIncome
	return math.floor(units * inc[math.clamp(d.ring or 1, 1, #inc)])
end

-- Donne une récompense ; renvoie le texte « +$1K, x2 Luck 10m »
local function give(player: Player, d, reward): string
	local parts = {}
	if reward.Money then
		local m = moneyOf(d, reward.Money)
		d.credits += m
		table.insert(parts, "+$" .. Format.Short(m))
	end
	for key, potion in pairs(POTIONS) do
		local minutes = reward[key]
		if minutes then
			BoostService.Add(player, potion, minutes)
			table.insert(parts, ("%s %dm"):format(POTION_NAMES[key], minutes))
		end
	end
	GameService.Sync(player)
	return table.concat(parts, ", ")
end

-- Récompense décrite pour l'affichage (le client ne connaît pas l'anneau du calcul)
local function describe(d, reward)
	return {
		money = if reward.Money then moneyOf(d, reward.Money) else nil,
		luck = reward.Luck,
		moneyBoost = reward.MoneyBoost,
		jetXP = reward.JetXP,
	}
end

-- ÉTAT ----------------------------------------------------------------------------------------

local function dailyReady(r): boolean
	return r.daily.lastDay ~= today()
end

-- Jour de la série qu'on réclamerait maintenant (1..7)
local function dailyNext(r): number
	local gap = today() - r.daily.lastDay
	if r.daily.lastDay < 0 or gap > 1 then
		return 1
	end
	if gap == 0 then
		return r.daily.streak
	end
	return r.daily.streak % #R.Daily + 1
end

local function readyCount(r, inGroup: boolean, groupClaimed: boolean): number
	local n = if dailyReady(r) then 1 else 0
	for i, p in ipairs(R.Playtime) do
		if not r.play.claimed[i] and r.play.seconds >= p.Minutes * 60 then
			n += 1
		end
	end
	for _, q in ipairs(r.quests.list) do
		if not q.claimed and q.progress >= q.goal then
			n += 1
		end
	end
	if inGroup and not groupClaimed then
		n += 1
	end
	return n
end

local inGroupCache: { [Player]: boolean } = {}

local function stateOf(player: Player)
	local d, r = data(player)
	if not d then
		return nil
	end
	local daily = {}
	for i, rw in ipairs(R.Daily) do
		daily[i] = describe(d, rw)
	end
	local play = {}
	for i, p in ipairs(R.Playtime) do
		play[i] = { minutes = p.Minutes, reward = describe(d, p.Reward), claimed = r.play.claimed[i] == true }
	end
	local quests = {}
	for i, q in ipairs(r.quests.list) do
		local def
		for _, x in ipairs(R.Quests) do
			if x.Kind == q.kind then
				def = x
			end
		end
		local text = if q.kind == "income" then def.Text:format("$" .. Format.Short(q.goal)) else def.Text:format(q.goal)
		quests[i] = { text = text, art = def.Art, goal = q.goal, progress = math.min(q.progress, q.goal), claimed = q.claimed, reward = describe(d, R.QuestReward) }
	end
	local gid = groupId()
	return {
		now = os.time(),
		nextDay = (today() + 1) * DAY,
		daily = daily,
		dailyDay = dailyNext(r),
		dailyReady = dailyReady(r),
		playSeconds = r.play.seconds,
		play = play,
		quests = quests,
		allQuestsReward = describe(d, R.AllQuestsReward),
		allQuestsClaimed = r.quests.bonus,
		group = { id = gid, inGroup = inGroupCache[player] == true, claimed = d.groupClaimed == true, luck = R.GroupLuck, reward = describe(d, R.GroupReward) },
		ad = { boost = describe(d, R.AdBoost), ready = os.time() - r.lastAd >= R.AdCooldown, wait = math.max(0, R.AdCooldown - (os.time() - r.lastAd)) },
	}
end

local function publish(player: Player)
	local d, r = data(player)
	if d then
		local n = readyCount(r, inGroupCache[player] == true, d.groupClaimed == true)
		if player:GetAttribute("RewardsReady") ~= n then
			player:SetAttribute("RewardsReady", n)
		end
	end
end

-- Membre du groupe : bonus de chance permanent tant qu'on l'est (lu par BoostService.LuckMult)
local function checkGroup(player: Player)
	local gid = groupId()
	if gid == 0 then
		return
	end
	local ok, inGroup = pcall(player.IsInGroupAsync, player, gid)
	if not ok then
		ok, inGroup = pcall(player.IsInGroup, player, gid)
	end
	inGroupCache[player] = ok and inGroup == true
	local d = DataService.Get(player)
	if d then
		d.inGroup = inGroupCache[player]
	end
end

-- QUÊTES --------------------------------------------------------------------------------------

function RewardService.Quest(player: Player, kind: string, amount: number?)
	local d, r = data(player)
	if not d then
		return
	end
	local changed = false
	for _, q in ipairs(r.quests.list) do
		if q.kind == kind and not q.claimed and q.progress < q.goal then
			local before = q.progress
			q.progress = math.min(q.goal, q.progress + (amount or 1))
			changed = true
			if before < q.goal and q.progress >= q.goal then
				GameService.Notice(player, "{Star} Quest complete! Claim it in REWARDS", "good")
			end
		end
	end
	if changed then
		publish(player)
	end
end

-- DEMANDES ------------------------------------------------------------------------------------

local function claimDaily(player: Player, d, r)
	if not dailyReady(r) then
		return false, "Come back tomorrow!"
	end
	local day = dailyNext(r)
	r.daily.streak = day
	r.daily.lastDay = today()
	local got = give(player, d, R.Daily[day])
	GameService.Notice(player, ("{Star} Day %d reward: %s"):format(day, got), "good")
	return true
end

local function claimPlaytime(player: Player, d, r, i: any)
	local p = type(i) == "number" and R.Playtime[i]
	if not p or r.play.claimed[i] then
		return false, "Already claimed"
	end
	if r.play.seconds < p.Minutes * 60 then
		return false, "Not ready yet!"
	end
	r.play.claimed[i] = true
	local got = give(player, d, p.Reward)
	GameService.Notice(player, ("{Hourglass} %d min gift: %s"):format(p.Minutes, got), "good")
	return true
end

local function claimQuest(player: Player, d, r, i: any)
	local q = type(i) == "number" and r.quests.list[i]
	if not q or q.claimed then
		return false, "Already claimed"
	end
	if q.progress < q.goal then
		return false, "Not finished yet!"
	end
	q.claimed = true
	local got = give(player, d, R.QuestReward)
	GameService.Notice(player, "{Star} Quest reward: " .. got, "good")
	local all = true
	for _, x in ipairs(r.quests.list) do
		all = all and x.claimed
	end
	if all and not r.quests.bonus then
		r.quests.bonus = true
		local bonus = give(player, d, R.AllQuestsReward)
		GameService.Notice(player, "{Sparkles} All quests done! Bonus: " .. bonus, "good")
	end
	return true
end

local function redeem(player: Player, d, r, text: any)
	if type(text) ~= "string" then
		return false, "Type a code"
	end
	local code = string.upper((text:gsub("%s", ""))):sub(1, 32)
	local reward = Config.Codes[code]
	if not reward then
		return false, "Unknown code"
	end
	if r.codes[code] then
		return false, "Code already used"
	end
	r.codes[code] = true
	local got = give(player, d, reward)
	GameService.Notice(player, ("{Sparkles} Code %s: %s"):format(code, got), "good")
	return true
end

local function claimGroup(player: Player, d)
	if groupId() == 0 then
		return false, "No group yet"
	end
	checkGroup(player)
	if not inGroupCache[player] then
		return false, "Join the group first!"
	end
	if d.groupClaimed then
		return false, "Already claimed"
	end
	d.groupClaimed = true
	local got = give(player, d, R.GroupReward)
	GameService.Notice(player, ("{Star} Thanks for joining! %s and +%d%% luck forever"):format(got, math.floor(R.GroupLuck * 100)), "good")
	return true
end

local function showAd(player: Player, r)
	if os.time() - r.lastAd < R.AdCooldown then
		return false, "Next free boost soon!"
	end
	local potion = Config.Shop.Potions[1]
	if not potion or potion.Id == 0 then
		return false, "Not available"
	end
	local AdService = game:GetService("AdService")
	local ok, res = pcall(function()
		local reward = AdService:CreateAdRewardFromDevProductId(potion.Id)
		return AdService:ShowRewardedVideoAdAsync(player, reward)
	end)
	if not ok then
		return false, "No ad available right now"
	end
	-- le boost arrive par ProcessReceipt (canal AdReward, MonetizationService) ; on note la pub vue
	if res == Enum.ShowAdResult.ShowCompleted then
		r.lastAd = os.time()
		return true
	end
	return false, "Watch the whole ad to get the boost"
end

local function onInvoke(player: Player, action: any, arg: any)
	local d, r = data(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	local ok, err = true, nil
	if action == "daily" then
		ok, err = claimDaily(player, d, r)
	elseif action == "playtime" then
		ok, err = claimPlaytime(player, d, r, arg)
	elseif action == "quest" then
		ok, err = claimQuest(player, d, r, arg)
	elseif action == "code" then
		ok, err = redeem(player, d, r, arg)
	elseif action == "group" then
		ok, err = claimGroup(player, d)
	elseif action == "ad" then
		ok, err = showAd(player, r)
	elseif action ~= "state" then
		ok, err = false, "Unknown action"
	end
	publish(player)
	return { ok = ok, error = err, state = stateOf(player) }
end

-- Boost de la pub : appelé par MonetizationService (reçu sur le canal AdReward)
function RewardService.GrantAdBoost(player: Player): boolean
	local d, r = data(player)
	if not d then
		return false
	end
	r.lastAd = os.time()
	local got = give(player, d, R.AdBoost)
	GameService.Notice(player, "{Lightning} Free boost: " .. got, "good")
	publish(player)
	return true
end

function RewardService.Start()
	Remotes.Rewards.OnServerInvoke = onInvoke
	GameService.Quest = RewardService.Quest
	DataService.Loaded:Connect(function(player: Player)
		task.spawn(checkGroup, player)
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		inGroupCache[player] = nil
	end)
	-- temps de jeu : une seconde par seconde passée en jeu (AFK compris), sur la journée
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local d, r = data(player)
				if d then
					r.play.seconds += 1
					publish(player)
				end
			end
		end
	end)
	-- Studio seulement : avancer le temps de jeu, finir les quêtes, oublier la connexion d'hier
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "RewardDebug"
		bf.OnInvoke = function(cmd: string, arg: any)
			local player = Players:GetPlayers()[1]
			local d, r = data(player)
			if not d then
				return "pas de partie"
			end
			if cmd == "play" then
				r.play.seconds += arg
			elseif cmd == "quests" then
				for _, q in ipairs(r.quests.list) do
					q.progress = q.goal
				end
			elseif cmd == "newday" then
				r.daily.lastDay -= 1
			elseif cmd == "group" then
				inGroupCache[player] = arg == true
				d.inGroup = arg == true
			end
			publish(player)
			return ("credits=%d ready=%s play=%d streak=%d"):format(d.credits, tostring(player:GetAttribute("RewardsReady")), r.play.seconds, r.daily.streak)
		end
		bf.Parent = ServerStorage
	end
end

return RewardService
