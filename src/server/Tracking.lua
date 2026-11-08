-- Suivi des joueurs (AnalyticsService de Roblox) : à lire dans le Creator Hub, Analytics > Funnels et Events.
--   Tracking.Onboarding(joueur, n, nom)     entonnoir du premier parcours (Join, puis les étapes du guide)
--   Tracking.Funnel(joueur, entonnoir, n, nom)  progression : Drills, WindTunnels, JetpackTiers, Rings,
--                                           Scanner, Hatches, Gems. Une session par Supernova : on voit
--                                           séparément la première partie et les suivantes.
--   Tracking.Event(joueur, nom, valeur?)    événement libre : morts par anneau, base pleine, tips, retours...
-- Une panne du suivi ne doit jamais gêner le jeu : tout passe par pcall.
-- Studio seulement : ServerStorage.TrackDebug("log") renvoie ce qui a été envoyé (pour les tests).

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)

local Tracking = {}

local sent: { [Player]: { [string]: boolean } } = {}
local log: { string } = {}

local function record(text: string)
	if RunService:IsStudio() then
		table.insert(log, text)
	end
end

local function once(player: Player, key: string): boolean
	local s = sent[player]
	if not s then
		s = {}
		sent[player] = s
	end
	if s[key] then
		return false
	end
	s[key] = true
	return true
end

function Tracking.Onboarding(player: Player, step: number, name: string)
	if not once(player, "onboarding:" .. step) then
		return
	end
	record(("Onboarding %d %s"):format(step, name))
	pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, step, name)
end

function Tracking.Funnel(player: Player, funnel: string, step: number, name: string)
	local d = DataService.Get(player)
	local session = ("%d_%d"):format(player.UserId, d and d.supernovas or 0)
	if not once(player, ("%s:%s:%d"):format(funnel, session, step)) then
		return
	end
	record(("Funnel %s %d %s (%s)"):format(funnel, step, name, session))
	pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, player, funnel, session, step, name)
end

function Tracking.Event(player: Player, name: string, value: number?)
	record(("Event %s %s"):format(name, tostring(value or 1)))
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, name, value or 1)
end

-- Mort d'un joueur (kind : Void, Oxygen, Freeze), avec l'anneau de l'œuf perdu : montre où ça coince
function Tracking.Death(player: Player, kind: string, egg: any)
	local ring = if type(egg) == "table" then egg.ring or 0 else 0
	Tracking.Event(player, ("Death_%s_R%d"):format(kind, ring))
end

Players.PlayerRemoving:Connect(function(player)
	sent[player] = nil
end)

if RunService:IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "TrackDebug"
	bf.OnInvoke = function()
		return table.concat(log, "\n")
	end
	bf.Parent = game:GetService("ServerStorage")
end

return Tracking
