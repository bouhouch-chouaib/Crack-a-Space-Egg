-- Achats Robux (produits de développeur). Un seul ProcessReceipt pour tout le jeu :
-- chaque produit connu dans Config est relié ici à ce qu'il donne.
-- Foreuses (Config.Drills[i].ProductId), « Hatch now » (Config.Hatch.Skip[rareté]), potions,
-- paquets d'argent et offre du moment (Config.Shop). Les passes sont lus par BoostService.
-- Règle : jamais d'œufs ni de créatures contre des Robux.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local HatchService = require(script.Parent.HatchService)
local BoostService = require(script.Parent.BoostService)
local EventService = require(script.Parent.EventService)
local Format = require(ReplicatedStorage.Shared.Format)

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
	-- Faire éclore tout de suite : du temps gagné, pas un œuf ni une créature
	for rarity, s in ipairs(Config.Hatch.Skip) do
		if s.ProductId ~= 0 then
			HANDLERS[s.ProductId] = function(player)
				return HatchService.SkipEgg(player, rarity)
			end
		end
	end
	local shop = Config.Shop
	local minutes = shop.PotionMinutes
	-- Potions : 15 min de bonus (Meteor Shower : pluie de météores pour tout le serveur)
	for _, potion in ipairs(shop.Potions) do
		if potion.Id ~= 0 then
			HANDLERS[potion.Id] = function(player)
				if potion.Key == "Meteor" then
					EventService.StartNow(minutes * 60)
					for _, p in ipairs(Players:GetPlayers()) do
						GameService.Notice(p, ("{Comet} %s started a Meteor Shower!"):format(player.DisplayName), "good")
					end
					return true
				end
				local ok = BoostService.Add(player, potion.Key, minutes)
				if ok then
					GameService.Notice(player, ("{Lightning} %s active for %d min!"):format(potion.Name, minutes), "good")
				end
				return ok
			end
		end
	end
	-- Paquets d'argent : montant selon l'anneau le plus loin débloqué
	local function giveMoney(player: Player, base: number): boolean
		local d = DataService.Get(player)
		if not d then
			return false
		end
		local amount = Config.MoneyPackAmount(base, d.ring)
		d.credits += amount
		GameService.Sync(player)
		GameService.Notice(player, "{Cash} +$" .. Format.Short(amount) .. "!", "good")
		return true
	end
	for _, pack in ipairs(shop.MoneyPacks) do
		if pack.Id ~= 0 then
			HANDLERS[pack.Id] = function(player)
				return giveMoney(player, pack.Base)
			end
		end
	end
	-- Offre du moment : gros paquet d'argent + potions x2 Luck et x2 Money
	if shop.Featured.Id ~= 0 then
		HANDLERS[shop.Featured.Id] = function(player)
			if not giveMoney(player, shop.Featured.PackBase) then
				return false
			end
			BoostService.Add(player, "Luck", minutes)
			BoostService.Add(player, "Money", minutes)
			return true
		end
	end
	MarketplaceService.ProcessReceipt = processReceipt
	-- Studio seulement : faire passer un reçu fictif par le vrai traitement (test des livraisons)
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "ReceiptDebug"
		bf.OnInvoke = function(player: Player, productId: number)
			return processReceipt({ PlayerId = player.UserId, ProductId = productId, PurchaseId = "debug" .. os.clock() })
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return MonetizationService
