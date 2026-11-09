-- Messages serveur pour les trouvailles rares (Config.AnnounceLevel, bandeaux : AnnounceUI.client).
-- Niveau 1 Rare, 2 Épique : ce serveur. Niveau 3 Légendaire : aussi tous les autres serveurs (MessagingService).
-- Remotes.Announcement (vers les clients) : { level, text, color, icon, chatOnly?, far? }
--   chatOnly : pas de bandeau, seulement la ligne de chat (le découvreur a déjà sa grande révélation).

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage.Remotes
local AnnounceService = {}

local TOPIC = "RareFinds"
local FAR_PREFIX = "Somewhere in the galaxy, "
local LEGENDARY = 3

local function publish(level: number, text: string, color: Color3, icon: string)
	local ok, err = pcall(MessagingService.PublishAsync, MessagingService, TOPIC, {
		server = game.JobId,
		level = level,
		text = text,
		color = { color.R, color.G, color.B },
		icon = icon,
	})
	if not ok then
		warn("[Announce] envoi aux autres serveurs impossible :", err)
	end
end

function AnnounceService.Send(player: Player?, level: number, text: string, color: Color3, icon: string, skipFinder: boolean?)
	for _, p in ipairs(Players:GetPlayers()) do
		Remotes.Announcement:FireClient(p, { level = level, text = text, color = color, icon = icon, chatOnly = skipFinder == true and p == player })
	end
	if level >= LEGENDARY then
		task.spawn(publish, level, text, color, icon)
	end
end

-- Créature qui vient d'éclore : le niveau dépend de sa rareté et de sa taille
function AnnounceService.Creature(player: Player, item)
	local level = Config.AnnounceLevel(item.rarity, Config.PetSize(item.size).Name == "Giant")
	if level then
		local r = Config.Rarities[item.rarity]
		AnnounceService.Send(player, level, ("%s hatched a %s %s!"):format(player.DisplayName, r.Name:upper(), Config.PetName(item)), r.Color, "Creatures")
	end
end

function AnnounceService.Gem(player: Player, name: string, rarity: number)
	local level = Config.AnnounceLevel(rarity, false)
	if level then
		local r = Config.Rarities[rarity]
		AnnounceService.Send(player, level, ("%s opened a %s %s!"):format(player.DisplayName, r.Name:upper(), name), r.Color, "OreRock")
	end
end

function AnnounceService.Start()
	task.spawn(function()
		local ok, err = pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or data.server == game.JobId or type(data.text) ~= "string" or type(data.color) ~= "table" then
				return
			end
			Remotes.Announcement:FireAllClients({
				level = LEGENDARY,
				text = FAR_PREFIX .. data.text,
				color = Color3.new(data.color[1] or 1, data.color[2] or 1, data.color[3] or 1),
				icon = data.icon or "Star",
				far = true,
			})
		end)
		if not ok then
			warn("[Announce] abonnement aux autres serveurs impossible :", err)
		end
	end)
end

return AnnounceService
