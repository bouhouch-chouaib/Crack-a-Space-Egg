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

-- Lance la pluie tout de suite (potion Meteor Shower achetée par un joueur) ; si elle est déjà
-- en cours, elle dure plus longtemps. Le prochain rendez-vous est recalé après la fin.
function EventService.StartNow(seconds: number)
	local now = workspace:GetServerTimeNow()
	local endsAt = math.max(now, if EventService.ShowerActive() then (workspace:GetAttribute("EventEndsAt") or now) else now) + seconds
	workspace:SetAttribute("EventActive", true)
	workspace:SetAttribute("EventEndsAt", endsAt)
end

function EventService.Start()
	workspace:SetAttribute("EventName", SHOWER.Name)
	workspace:SetAttribute("EventIcon", SHOWER.Icon)
	workspace:SetAttribute("EventActive", false)
	workspace:SetAttribute("EventStartsAt", workspace:GetServerTimeNow() + SHOWER.Every)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = workspace:GetServerTimeNow()
			if workspace:GetAttribute("EventActive") then
				if now >= (workspace:GetAttribute("EventEndsAt") or 0) then
					-- fin de la pluie : prochain rendez-vous
					local startsAt = now + SHOWER.Every
					workspace:SetAttribute("EventActive", false)
					workspace:SetAttribute("EventStartsAt", startsAt)
					workspace:SetAttribute("EventEndsAt", startsAt + SHOWER.Duration)
				end
			elseif now >= (workspace:GetAttribute("EventStartsAt") or math.huge) then
				workspace:SetAttribute("EventActive", true)
				workspace:SetAttribute("EventEndsAt", now + SHOWER.Duration)
			end
		end
	end)
end

return EventService
