-- Événements du serveur : pour l'instant la pluie de météores (docs/Mecaniques.md §14).
-- L'horaire est publié dans des attributs de Workspace, lus par la bannière (Markers.client)
-- et par BeltService pour accélérer le tapis et remplir davantage les astéroïdes.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local EventService = {}

local SHOWER = Config.Events.MeteorShower

function EventService.ShowerActive(): boolean
	return workspace:GetAttribute("EventActive") == true
end

-- Multiplicateurs appliqués au tapis pendant l'événement
function EventService.SpawnMult(): number
	return if EventService.ShowerActive() then SHOWER.SpawnMult else 1
end

function EventService.EggMult(): number
	return if EventService.ShowerActive() then SHOWER.EggMult else 1
end

function EventService.Start()
	workspace:SetAttribute("EventName", SHOWER.Name)
	workspace:SetAttribute("EventIcon", SHOWER.Icon)
	task.spawn(function()
		while true do
			local now = workspace:GetServerTimeNow()
			local startsAt = now + SHOWER.Every
			workspace:SetAttribute("EventActive", false)
			workspace:SetAttribute("EventStartsAt", startsAt)
			workspace:SetAttribute("EventEndsAt", startsAt + SHOWER.Duration)
			task.wait(SHOWER.Every)
			workspace:SetAttribute("EventActive", true)
			task.wait(SHOWER.Duration)
		end
	end)
end

return EventService
