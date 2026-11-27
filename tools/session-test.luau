-- Essais du verrou de session et de la sauvegarde (src/server/DataService.lua), hors de Roblox :
-- le vrai fichier est chargé deux fois (deux « serveurs ») sur un faux DataStore commun, avec une horloge
-- accélérée. Studio ne laisse pas écrire dans le DataStore : c'est ici qu'on vérifie ces cas.
-- À lancer depuis la racine du dépôt, après chaque changement de DataService :
--     lune run tools/session-test

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local SPEED = 40 -- une seconde du jeu dure 1/40 s ici
local t0 = os.clock()
local function now(): number
	return 1_800_000_000 + (os.clock() - t0) * SPEED
end
local fakeTask = {
	wait = function(n: number?)
		task.wait((n or 0.03) / SPEED)
	end,
	spawn = task.spawn,
	delay = function(n: number, fn, ...)
		return task.delay(n / SPEED, fn, ...)
	end,
}
local fakeOs = { time = function()
	return math.floor(now())
end, clock = now }

local Config = luau.load(fs.readFile("src/shared/Config.lua"), {
	debugName = "Config",
	environment = { Color3 = roblox.Color3, Vector2 = roblox.Vector2, Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Enum = roblox.Enum },
})()

local function copy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in pairs(v) do
		out[k] = copy(x)
	end
	return out
end

-- FAUX DATASTORE (commun aux deux serveurs) -----------------------------------------------------------
local disk: { [string]: any } = {}
local failure: string? = nil -- message d'erreur à renvoyer à chaque appel (panne simulée)
local store = {}
function store:UpdateAsync(key: string, fn: (any) -> any)
	fakeTask.wait(0.2)
	if failure then
		error(failure)
	end
	local result = fn(copy(disk[key]))
	if result == nil then
		return nil
	end
	disk[key] = copy(result)
	return copy(result)
end

local function signal()
	local list = {}
	return {
		Connect = function(_, fn)
			table.insert(list, fn)
		end,
		Fire = function(_, ...)
			for _, fn in ipairs(list) do
				task.spawn(fn, ...)
			end
		end,
	}
end

-- UN SERVEUR : DataService chargé dans son propre monde -------------------------------------------------
local function server(job: string, studio: boolean)
	local players = { list = {}, PlayerAdded = signal(), PlayerRemoving = signal() }
	function players:GetPlayers()
		return table.clone(self.list)
	end
	local closers = {}
	local configToken, testersToken = {}, {}
	local services = {
		DataStoreService = { GetDataStore = function()
			return store
		end },
		Players = players,
		RunService = { IsStudio = function()
			return studio
		end },
		ReplicatedStorage = { Shared = { Config = configToken } },
	}
	local game = { JobId = job }
	function game:GetService(name: string)
		return services[name]
	end
	function game:BindToClose(fn)
		table.insert(closers, fn)
	end
	local env = {
		game = game,
		script = { Parent = { Testers = testersToken } },
		require = function(token)
			if token == configToken then
				return Config
			end
			return { Enabled = function()
				return false
			end, Grant = function() end }
		end,
		Instance = { new = function()
			local s = signal()
			return { Event = s, Fire = s.Fire }
		end },
		task = fakeTask,
		os = fakeOs,
		warn = function() end,
	}
	local DataService = luau.load(fs.readFile("src/server/DataService.lua"), { debugName = "DataService@" .. job, environment = env })()
	DataService.Start()
	local S = { Data = DataService }
	function S.join(userId: number)
		local p = { Name = "p" .. userId, UserId = userId, Parent = players, kicked = nil :: string? }
		function p:Kick(message: string)
			self.kicked = message
			S.leave(self)
		end
		table.insert(players.list, p)
		players.PlayerAdded:Fire(p)
		return p
	end
	function S.leave(p)
		local i = table.find(players.list, p)
		if i then
			table.remove(players.list, i)
			p.Parent = nil
			players.PlayerRemoving:Fire(p)
		end
	end
	-- le serveur meurt d'un coup : plus aucune écriture
	function S.crash()
		players.list = {}
	end
	function S.close()
		for _, fn in ipairs(closers) do
			fn()
		end
	end
	return S
end

local failed = 0
local function check(name: string, ok: boolean, detail: any?)
	if ok then
		print("  ok    " .. name)
	else
		failed += 1
		print("  ÉCHEC " .. name .. (if detail ~= nil then "  -> " .. tostring(detail) else ""))
	end
end
local function waitUntil(fn: () -> boolean, seconds: number): boolean
	local limit = now() + seconds
	while not fn() and now() < limit do
		fakeTask.wait(0.1)
	end
	return fn()
end

local A, B = server("A", false), server("B", false)

print("1. Partie normale")
do
	local p = A.join(1)
	check("la partie se charge", waitUntil(function()
		return A.Data.Get(p) ~= nil
	end, 5))
	check("le verrou est posé par A", disk.u_1.session and disk.u_1.session.job == "A")
	A.Data.Get(p).credits = 500
	check("la sauvegarde réussit", A.Data.Save(p) == true)
	check("le verrou reste après une sauvegarde normale", disk.u_1.session and disk.u_1.session.job == "A")
	A.leave(p)
	check("au départ, tout est écrit et le verrou retiré", waitUntil(function()
		return disk.u_1.session == nil and disk.u_1.credits == 500
	end, 5), disk.u_1.session)
	check("une session comptée", disk.u_1.stats.sessions == 1, disk.u_1.stats.sessions)
end

print("2. Deuxième serveur pendant que le premier tient la partie")
do
	local pa = A.join(2)
	waitUntil(function()
		return A.Data.Get(pa) ~= nil
	end, 5)
	A.Data.Get(pa).credits = 900
	local pb = B.join(2)
	check("B renvoie le joueur après l'attente", waitUntil(function()
		return pb.kicked ~= nil
	end, Config.Session.WaitSeconds + 15), pb.kicked)
	check("B n'a rien chargé", B.Data.Get(pb) == nil)
	check("le verrou est toujours celui de A", disk.u_2.session and disk.u_2.session.job == "A")
	A.leave(pa)
	waitUntil(function()
		return disk.u_2.session == nil
	end, 5)
end

print("3. Changement de serveur : l'ancien finit sa sauvegarde pendant que le nouveau attend")
do
	local pa = A.join(3)
	waitUntil(function()
		return A.Data.Get(pa) ~= nil
	end, 5)
	A.Data.Get(pa).credits = 1234
	local pb = B.join(3)
	fakeTask.wait(6)
	A.leave(pa)
	check("B charge la partie à jour", waitUntil(function()
		return B.Data.Get(pb) ~= nil
	end, Config.Session.WaitSeconds), pb.kicked)
	check("avec l'argent gagné sur A", B.Data.Get(pb) and B.Data.Get(pb).credits == 1234)
	check("deux sessions comptées", B.Data.Get(pb) and B.Data.Get(pb).stats.sessions == 2)
	B.leave(pb)
	waitUntil(function()
		return disk.u_3.session == nil
	end, 5)
end

print("4. Serveur mort : son verrou expire, le suivant reprend la partie")
do
	local C = server("C", false)
	local pc = C.join(4)
	waitUntil(function()
		return C.Data.Get(pc) ~= nil
	end, 5)
	C.Data.Get(pc).credits = 50
	C.Data.Save(pc)
	C.crash()
	local early = B.join(4)
	check("trop tôt : le joueur est renvoyé", waitUntil(function()
		return early.kicked ~= nil
	end, Config.Session.WaitSeconds + 15), early.kicked)
	fakeTask.wait(Config.Session.LockSeconds)
	local pb = B.join(4)
	check("après LockSeconds, B reprend la partie", waitUntil(function()
		return B.Data.Get(pb) ~= nil
	end, 10), pb.kicked)
	B.Data.Get(pb).credits = 70
	B.Data.Save(pb)
	-- le serveur « mort » revient à lui et veut écrire sa vieille partie
	C.Data.Get(pc).credits = 99999
	pc.Parent = {}
	check("l'ancien serveur ne peut plus écrire", C.Data.Save(pc) == false)
	check("il renvoie son joueur", pc.kicked ~= nil, pc.kicked)
	check("la partie de B est intacte", disk.u_4.credits == 70 and disk.u_4.session.job == "B", disk.u_4.credits)
	B.leave(pb)
	waitUntil(function()
		return disk.u_4.session == nil
	end, 5)
end

print("5. DataStore en panne")
do
	failure = "502: API Services rejected request"
	local p = A.join(5)
	check("vrai jeu : le joueur est renvoyé, sans partie vide", waitUntil(function()
		return p.kicked ~= nil
	end, 40) and A.Data.Get(p) == nil, p.kicked)
	check("rien n'est écrit", disk.u_5 == nil)
	failure = "Studio access to APIs is not allowed"
	local St = server("S", true)
	local ps = St.join(5)
	check("Studio : on joue sans sauvegarde", waitUntil(function()
		return St.Data.Get(ps) ~= nil
	end, 10) and St.Data.CanSave(ps) == false and St.Data.Sandbox(ps) == true)
	check("Studio : la sauvegarde répond non", St.Data.Save(ps) == false)
	failure = nil
end

print("6. Sauvegarde automatique et départ en même temps")
do
	local p = A.join(6)
	waitUntil(function()
		return A.Data.Get(p) ~= nil
	end, 5)
	for _ = 1, 4 do
		task.spawn(A.Data.Save, p)
	end
	A.leave(p)
	fakeTask.wait(8)
	check("la dernière écriture est celle du départ (verrou retiré)", disk.u_6.session == nil, disk.u_6.session and disk.u_6.session.job)
end

print("7. Fermeture du serveur")
do
	local D = server("D", false)
	local list = {}
	for id = 70, 75 do
		table.insert(list, D.join(id))
	end
	waitUntil(function()
		for _, p in ipairs(list) do
			if not D.Data.Get(p) then
				return false
			end
		end
		return true
	end, 10)
	for i, p in ipairs(list) do
		D.Data.Get(p).credits = i * 10
	end
	D.close()
	local all = true
	for i = 1, #list do
		local d = disk["u_" .. (69 + i)]
		if not d or d.credits ~= i * 10 or d.session ~= nil then
			all = false
		end
	end
	check("toutes les parties sont écrites avant la fin de la fermeture", all)
end

print(if failed == 0 then "\nTout passe." else ("\n%d échec(s)."):format(failed))
process.exit(if failed == 0 then 0 else 1)
