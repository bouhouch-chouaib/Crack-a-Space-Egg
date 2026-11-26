-- Agrandissement de l'enclos (Config.Pen, shared/PenBuilder, PenUI.client).
-- Chaque niveau acheté en $ agrandit le sol de la base (vers le fond et le côté libre) et donne une
-- place en plus pour les œufs et les créatures (BoostService.BaseSlots). Niveau gardé dans d.pen.
-- 10 améliorations ; le prix double à chaque fois et suit l'anneau du joueur (Config.PenCost).
-- Remotes.PenUp (RemoteFunction) : ("buy") -> { ok }
-- Les positions des objets posés sont dans le repère du sol, qui se déplace en grandissant : à l'achat
-- on les décale pour que rien ne bouge dans le monde. La base libérée revient au niveau 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PenBuilder = require(ReplicatedStorage.Shared.PenBuilder)
local Bases = require(script.Parent.Bases)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local HatchService = require(script.Parent.HatchService)
local Tracking = require(script.Parent.Tracking)

local Remotes = ReplicatedStorage.Remotes
local P = Config.Pen

local PenService = {}

local function levelOf(player: Player): number
	local d = DataService.Get(player)
	return math.clamp(math.floor((d and d.pen) or 1), 1, #P.Levels)
end

-- Met la base du joueur à son niveau (au chargement de la partie, avant de reposer œufs et créatures)
local function apply(player: Player)
	local base = Bases.Get(player)
	if not base then
		return
	end
	local level = levelOf(player)
	if base:GetAttribute("PenLevel") ~= level then
		PenBuilder.Build(base, level)
	end
	player:SetAttribute("PenLevel", level)
end
PenService.Apply = apply

local function buy(player: Player): boolean
	local d = DataService.Get(player)
	local base = Bases.Get(player)
	if not d or not base then
		return false
	end
	local level = levelOf(player)
	local nextDef = P.Levels[level + 1]
	if not nextDef then
		return false
	end
	local cost = Config.PenCost(level + 1, d.ring)
	if (d.credits or 0) < cost then
		GameService.Notice(player, "Not enough $", "warn")
		return false
	end
	d.credits -= cost
	-- le sol se déplace en grandissant : œufs et créatures gardent leur place dans le monde
	local before, after = PenBuilder.Center(base, level), PenBuilder.Center(base, level + 1)
	for _, item in ipairs(d.base or {}) do
		if type(item.x) == "number" and type(item.z) == "number" then
			item.x += before.X - after.X
			item.z += before.Z - after.Z
		end
	end
	d.pen = level + 1
	Tracking.Funnel(player, "Pens", level + 1, ("Pen %d"):format(level + 1))
	apply(player)
	HatchService.Rebuild(player) -- repose tout sur le nouveau sol, et publie le nombre de places
	GameService.Sync(player)
	return true
end

function PenService.Start()
	Remotes.PenUp.OnServerInvoke = function(player: Player, action: any)
		if action == "buy" then
			return { ok = buy(player) }
		end
		return { ok = false }
	end
	-- avant que HatchService repose les œufs et créatures du joueur
	HatchService.BeforeBuild = apply
	-- la base libérée reprend sa taille de départ
	Players.PlayerRemoving:Connect(function(player)
		local base = Bases.Get(player)
		if base and base:GetAttribute("PenLevel") ~= 1 then
			PenBuilder.Build(base, 1)
		end
	end)
end

return PenService
