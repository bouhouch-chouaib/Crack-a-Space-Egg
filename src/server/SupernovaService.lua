-- Supernova (renaissance, Config.Supernova, docs/Interfaces.md §11).
-- Remotes.Supernova (RemoteFunction) :
--   ("go") -> { ok, count, mult } ou { ok = false, error }
-- Le serveur vérifie le prix, remet à zéro ce qui doit l'être, puis renvoie le joueur à sa base après
-- l'explosion affichée par le client (Config.Supernova.Delay).
-- Publié sur le joueur : Supernovas = nombre fait (GameService.Sync).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local WindTunnelService = require(script.Parent.WindTunnelService)
local Tracking = require(script.Parent.Tracking)

local Remotes = ReplicatedStorage.Remotes
local SupernovaService = {}

local busy: { [Player]: boolean } = {}

local function mult(n: number): string
	return "x" .. (string.gsub(string.format("%.1f", Config.SupernovaMult(n)), "%.0$", ""))
end

-- Tout repart de zéro, sauf les créatures, les œufs, l'Index, les minerais, les skins et les achats Robux
local function reset(d)
	d.credits = 0
	d.drill = math.clamp(d.paidDrill or 1, 1, #Config.Drills)
	for id in pairs(d.levels) do
		d.levels[id] = 0
	end
	d.jetXP = 0
	d.tunnel = 0
	d.ring = 1
	d.cargo = {}
	d.supernovas = (d.supernovas or 0) + 1
end

local function go(player: Player)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	if busy[player] then
		return { ok = false, error = "Already exploding!" }
	end
	if Config.JetpackLevel(d.jetXP or 0) < Config.Supernova.Level then
		return { ok = false, error = ("Reach Jetpack Lv %d first!"):format(Config.Supernova.Level) }
	end
	local cost = Config.SupernovaCost(d.supernovas or 0)
	if d.credits < cost then
		return { ok = false, error = ("You need $%s to go Supernova"):format(Format.Short(cost)) }
	end
	busy[player] = true
	reset(d)
	GameService.Sync(player)
	WindTunnelService.Refresh(player)
	task.spawn(DataService.Save, player)
	local n = d.supernovas
	Tracking.Funnel(player, "Supernova", 1, "Went Supernova")
	Tracking.Event(player, "Supernova", n)
	-- les autres joueurs l'apprennent
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			Remotes.Notice:FireClient(p, ("{Supernova} %s went SUPERNOVA! Money %s forever"):format(player.DisplayName, mult(n)), "good")
		end
	end
	-- retour à la base pendant le flash blanc (foreuse, jetpack et soufflerie du nouveau départ)
	task.delay(Config.Supernova.Delay, function()
		if player.Parent then
			player:LoadCharacter()
		end
		busy[player] = nil
	end)
	return { ok = true, count = n, mult = Config.SupernovaMult(n) }
end

function SupernovaService.Start()
	Remotes.Supernova.OnServerInvoke = function(player: Player, action: any)
		if action == "go" then
			return go(player)
		end
		return { ok = false, error = "Unknown action" }
	end
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
	-- Studio seulement : ("money", n) met l'argent à n ; ("count", n) fixe le nombre de Supernovas ; renvoie l'état
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "SupernovaDebug"
		bf.OnInvoke = function(cmd: string, arg: any)
			local player = Players:GetPlayers()[1]
			local d = player and DataService.Get(player)
			if not d then
				return "pas de partie chargée"
			end
			if cmd == "money" then
				d.credits = arg
			elseif cmd == "count" then
				d.supernovas = arg
			end
			GameService.Sync(player)
			return ("supernovas %d, $%s, prix %s, foreuse %d, jetXP %s, soufflerie %d, anneau %d, créatures %d"):format(
				d.supernovas or 0, Format.Short(d.credits), Format.Short(Config.SupernovaCost(d.supernovas or 0)),
				d.drill, tostring(d.jetXP), d.tunnel or 0, d.ring, #d.base)
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return SupernovaService
