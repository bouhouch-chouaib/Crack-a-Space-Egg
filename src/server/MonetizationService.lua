-- Achats Robux (produits de développeur). Un seul ProcessReceipt pour tout le jeu :
-- chaque produit connu dans Config est relié ici à ce qu'il donne.
-- Pour l'instant : les foreuses (Config.Drills[i].ProductId). Les potions, packs et l'offre du jour
-- s'ajouteront dans HANDLERS quand leurs produits seront créés sur Roblox.
-- Règle : jamais d'œufs ni de créatures contre des Robux.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local MonetizationService = {}

-- ProductId -> fonction qui donne l'achat au joueur (renvoie true si c'est fait)
local HANDLERS: { [number]: (Player) -> boolean } = {}

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local handler = HANDLERS[receipt.ProductId]
	-- Joueur parti ou partie pas encore chargée : Roblox redemandera plus tard
	if not player or not handler or not DataService.Get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, granted = pcall(handler, player)
	if not ok or not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- On sauvegarde tout de suite : un achat Robux ne doit jamais se perdre
	pcall(DataService.Save, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Start()
	for tier, d in ipairs(Config.Drills) do
		if d.ProductId ~= 0 then
			HANDLERS[d.ProductId] = function(player)
				return GameService.GrantDrill(player, tier)
			end
		end
	end
	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
