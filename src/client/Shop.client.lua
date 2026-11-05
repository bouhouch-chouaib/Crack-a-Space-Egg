-- La boutique unique qui défile (docs/Interfaces.md §9) :
-- Featured, Upgrades ($), Pets, Rewards, Game Passes, Potions, Money packs, Skins.
-- Ouverte par le bouton SHOP du HUD (UIKit.Open "Shop") ou par le stand du vaisseau
-- (Remotes.OpenShop, qui saute directement aux améliorations).
-- Les achats Robux passent par MarketplaceService ; tant qu'un Id vaut 0 dans Config.Shop,
-- le bouton affiche « Coming soon! ». Le serveur reste seul juge des achats en $.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new
local Shop = Config.Shop

local win = UIKit.window({ name = "Shop", title = "SHOP", color = "Green" })
local body = win.body

-- Couleur des titres de section
local GOLD = Color3.fromRGB(255, 214, 70)
local SKY = Color3.fromRGB(120, 215, 255)
local PINK = Color3.fromRGB(255, 140, 200)
local LIME = Color3.fromRGB(150, 245, 80)

local function soon()
	UIKit.toast("Coming soon!", "info")
end

local function buyRobux(id: number, isPass: boolean)
	if id == 0 then
		soon()
	elseif isPass then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
end

-- Texte de carte (titre, ligne d'effet), avec taille fixe pour rester lisible
local function cardText(parent: Instance, text: string, y: number, h: number, size: number, color: Color3?): TextLabel
	local t = UIKit.text({
		Size = UDim2.new(1, -12, 0, h),
		Position = UDim2.fromOffset(6, y),
		Text = text,
		TextColor3 = color or UIKit.Ink,
		ZIndex = 4,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, Parent = t })
	return t
end

-- EFFETS DES CARTES ------------------------------------------------------------

-- Position d'une illustration ramenée dans le calque d'effets rogné (décalé de 4 px)
local function inLayer(p: UDim2): UDim2
	return UDim2.new(p.X.Scale, p.X.Offset - 4 + 8 * p.X.Scale, p.Y.Scale, p.Y.Offset - 4 + 8 * p.Y.Scale)
end

local cascade: { GuiObject } = {} -- cartes qui apparaissent en vague à l'ouverture
local robuxCards: { [number]: GuiObject } = {} -- Id Robux -> carte, pour fêter l'achat

-- Donne vie à une carte : halo (et rayons) derrière l'illustration qui flotte, étincelles, survol
local function lively(card: Frame, icon: ImageLabel?, fx: { rays: Color3?, glow: Color3?, sparkles: number?, raySize: number? }?)
	local o = fx or {}
	table.insert(cascade, card)
	UIKit.hoverCard(card)
	if icon then
		local layer = UIKit.fxLayer(card)
		local center = inLayer(UIKit.centerOf(icon))
		local size = icon.Size.X.Offset
		if o.rays then
			UIKit.rays(layer, { color = o.rays, size = o.raySize or size * 1.8, position = center, transparency = 0.15, z = layer.ZIndex })
		end
		UIKit.glow(layer, { color = o.glow or Color3.new(1, 1, 1), size = size * 1.3, position = center, transparency = 0.2, z = layer.ZIndex })
		UIKit.float(icon, 4, 4, 2.2)
	end
	UIKit.sparkles(card, { count = o.sparkles or 2 })
end

-- Fête un achat sur une carte : explosion de lumière, rebond et texte qui s'envole
local function celebrate(card: GuiObject, text: string, color: Color3)
	UIKit.burst(card, UDim2.fromScale(0.5, 0.35), color)
	UIKit.bump(card, 0.15)
	UIKit.flyText(card, text, UDim2.fromOffset(8, 120), color)
end

-- SECTIONS -------------------------------------------------------------------

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local sections: { [string]: GuiObject } = {}

local function section(key: string, title: string, color: Color3)
	sections[key] = UIKit.sectionTitle(body, title, color, nextOrder())
end

-- Rangée de raccourcis vers chaque section (créée tout de suite, remplie à la fin)
local nav = new("Frame", {
	Name = "Nav",
	Size = UDim2.new(1, 0, 0, 74),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
	Parent = body,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- Fait défiler la fenêtre jusqu'à une section
local function scrollTo(key: string, instant: boolean?)
	local target = sections[key]
	if not target then
		return
	end
	-- CanvasPosition est en pixels écran, comme AbsolutePosition (échelle de l'interface comprise)
	local scale = win.frame.AbsoluteSize.Y / 600
	local y = target.AbsolutePosition.Y - body.AbsolutePosition.Y + body.CanvasPosition.Y - 6 * scale
	local maxY = math.max(0, body.AbsoluteCanvasSize.Y - body.AbsoluteWindowSize.Y)
	local goal = Vector2.new(0, math.clamp(y, 0, maxY))
	if instant then
		body.CanvasPosition = goal
	else
		UIKit.tween(body, 0.4, { CanvasPosition = goal }, Enum.EasingStyle.Quart)
	end
end

-- 1. FEATURED ------------------------------------------------------------------

section("Featured", "Featured", GOLD)
local featured = UIKit.card({ parent = body, color = "Orange", order = nextOrder(), name = "Featured" })
featured.Size = UDim2.new(1, -8, 0, 190)
local bag = UIKit.icon(Shop.Featured.Art, { Size = UDim2.fromOffset(200, 200), Position = UDim2.fromOffset(14, -12), ZIndex = 4, Parent = featured })
-- La vedette en fait le plus : grands rayons dorés, contour doré qui tourne, beaucoup d'étincelles
lively(featured, bag, { rays = Color3.fromRGB(255, 236, 140), glow = Color3.fromRGB(255, 250, 200), sparkles = 7, raySize = 420 })
UIKit.shinyStroke(featured, UIKit.GoldShine, 5)
UIKit.text({
	Size = UDim2.new(0.5, 0, 0, 54),
	Position = UDim2.fromOffset(230, 16),
	Text = string.upper(Shop.Featured.Name),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
	Stroke = 4,
	Parent = featured,
})
UIKit.text({
	Size = UDim2.new(0.48, 0, 0, 30),
	Position = UDim2.fromOffset(230, 74),
	Text = Shop.Featured.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
	Parent = featured,
})
local featuredTimer = UIKit.text({
	Size = UDim2.new(0.4, 0, 0, 30),
	Position = UDim2.fromOffset(230, 112),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 245, 150),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
	Parent = featured,
})
-- Ancien prix barré
local was = UIKit.text({
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(120, 32),
	Position = UDim2.new(1, -26, 0, 58),
	Text = "R$ " .. Shop.Featured.Was,
	TextColor3 = Color3.fromRGB(255, 200, 200),
	ZIndex = 4,
	Parent = featured,
})
new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(1, 0, 0, 4),
	Position = UDim2.fromScale(0.5, 0.5),
	Rotation = -8,
	BackgroundColor3 = Color3.fromRGB(235, 40, 50),
	BorderSizePixel = 0,
	ZIndex = 5,
	Parent = was,
})
local featuredBuy = UIKit.priceButton({
	parent = featured,
	text = tostring(Shop.Featured.Price),
	robux = true,
	size = UDim2.fromOffset(200, 58),
	position = UDim2.new(1, -226, 1, -74),
})
featuredBuy.MouseButton1Click:Connect(function()
	buyRobux(Shop.Featured.Id, false)
end)
UIKit.buttonGlow(featuredBuy)
if Shop.Featured.Id ~= 0 then
	robuxCards[Shop.Featured.Id] = featured
end
UIKit.giftButton(featured, UDim2.new(1, -292, 1, -70)).MouseButton1Click:Connect(soon)
UIKit.ribbon(featured, "NEW!", "Red")

-- 2. UPGRADES ($) ------------------------------------------------------------------

section("Upgrades", "Upgrades", LIME)
local upgradeGrid = UIKit.grid(body, Vector2.new(152, 258), nextOrder())

-- Ce qu'on montre pour chaque amélioration : titre, illustration, effet d'un niveau
local UPGRADES = {
	{ id = "Drill", title = "DRILL", art = "UpDrill", color = "Orange", effect = function(l)
		return string.format("%.1f", Config.DrillPower(l))
	end },
	{ id = "Cargo", title = "CARGO", art = "UpCargo", color = "Blue", effect = function(l)
		return string.format("%d eggs", Config.CargoSlots(l))
	end },
	{ id = "Thruster", title = "JETPACK", art = "Jetpack", color = "Pink", effect = function(l)
		return string.format("x%.2f", Config.Speed(l))
	end },
	{ id = "Scanner", title = "SCANNER", art = "UpScanner", color = "Teal", effect = function(l)
		return string.format("x%.2f", Config.Luck(l))
	end },
}

type UpgradeCard = {
	card: Frame,
	level: TextLabel,
	effect: TextLabel,
	price: TextLabel,
	grad: UIGradient,
	button: TextButton,
	light: ImageLabel,
	affordable: boolean,
	why: string, -- message si on ne peut pas acheter
}
local upgradeCards: { [string]: UpgradeCard } = {}

local function upgradeCard(title: string, art: string, color: string, i: number, onBuy: () -> ()): UpgradeCard
	local c = UIKit.card({ parent = upgradeGrid, color = color, order = i, name = title })
	cardText(c, title, 6, 30, 26)
	local icon = UIKit.icon(art, { Size = UDim2.fromOffset(116, 116), Position = UDim2.new(0.5, -58, 0, 36), ZIndex = 4, Parent = c })
	lively(c, icon, { sparkles = 2 })
	local level = cardText(c, "", 150, 24, 20, Color3.fromRGB(255, 245, 150))
	local effect = cardText(c, "", 174, 22, 18)
	local button, price, grad = UIKit.priceButton({ parent = c, text = "", size = UDim2.new(1, -16, 0, 48), position = UDim2.new(0, 8, 1, -56) })
	-- Lumière verte qui pulse derrière le bouton quand on peut acheter
	local light = UIKit.buttonGlow(button)
	local data: UpgradeCard = { card = c, level = level, effect = effect, price = price, grad = grad, button = button, light = light, affordable = false, why = "Not enough $!" }
	button.MouseButton1Click:Connect(function()
		if data.affordable then
			onBuy()
		else
			UIKit.shake(button)
			UIKit.toast(data.why, "bad")
		end
	end)
	return data
end

for i, u in ipairs(UPGRADES) do
	upgradeCards[u.id] = upgradeCard(u.title, u.art, u.color, i, function()
		Remotes.BuyUpgrade:FireServer(u.id)
	end)
end
-- La combinaison ouvre l'anneau suivant
local suit = upgradeCard("SUIT", "UpSuit", "Purple", #UPGRADES + 1, function()
	Remotes.UnlockRing:FireServer((player:GetAttribute("Ring") or 1) + 1)
end)

local function refreshUpgrades()
	local credits = player:GetAttribute("Credits") or 0
	for _, u in ipairs(UPGRADES) do
		local card = upgradeCards[u.id]
		local l = player:GetAttribute("Lvl_" .. u.id) or 0
		card.level.Text = "Lv " .. l
		if l >= Config.Upgrades[u.id].Max then
			card.effect.Text = u.effect(l)
			card.price.Text = "MAX"
			UIKit.recolor(card.grad, "Gold")
			card.affordable, card.why = false, "Already max level!"
		else
			local cost = Config.UpgradeCost(u.id, l)
			card.effect.Text = u.effect(l) .. " → " .. u.effect(l + 1)
			card.price.Text = "$" .. Format.Short(cost)
			card.affordable, card.why = credits >= cost, "Not enough $!"
			UIKit.recolor(card.grad, if card.affordable then "Green" else "Grey")
		end
		card.light.Visible = card.affordable
	end
	local ring = player:GetAttribute("Ring") or 1
	local nextRing = Config.Rings[ring + 1]
	suit.level.Text = "Lv " .. ring
	if nextRing then
		local drill = player:GetAttribute("Lvl_Drill") or 0
		if drill < nextRing.DrillLevel then
			-- Il faut d'abord une meilleure foreuse : on le dit sur le bouton
			suit.effect.Text = "Opens " .. nextRing.Name
			suit.price.Text = "Drill Lv " .. nextRing.DrillLevel
			UIKit.recolor(suit.grad, "Grey")
			suit.affordable, suit.why = false, "Upgrade your drill first!"
		else
			suit.effect.Text = "Opens " .. nextRing.Name
			suit.price.Text = "$" .. Format.Short(nextRing.UnlockCost)
			suit.affordable, suit.why = credits >= nextRing.UnlockCost, "Not enough $!"
			UIKit.recolor(suit.grad, if suit.affordable then "Green" else "Grey")
		end
	else
		suit.effect.Text = "All rings open"
		suit.price.Text = "MAX"
		UIKit.recolor(suit.grad, "Gold")
		suit.affordable, suit.why = false, "All rings are open!"
	end
	suit.light.Visible = suit.affordable
end

-- 3. PETS et 4. REWARDS : bientôt (semaine 2) -------------------------------------

local function comingSoon(key: string, title: string, color: Color3, art: string, cardColor: string, text: string)
	section(key, title, color)
	local c = UIKit.card({ parent = body, color = cardColor, order = nextOrder(), name = key })
	c.Size = UDim2.new(1, -8, 0, 110)
	local icon = UIKit.icon(art, { Size = UDim2.fromOffset(120, 120), Position = UDim2.fromOffset(16, -8), ZIndex = 4, Parent = c })
	lively(c, icon, { sparkles = 3 })
	UIKit.text({
		Size = UDim2.new(1, -330, 0, 40),
		Position = UDim2.fromOffset(150, 18),
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Stroke = 3,
		Parent = c,
	})
	UIKit.text({
		Size = UDim2.new(1, -330, 0, 28),
		Position = UDim2.fromOffset(150, 62),
		Text = "Coming soon!",
		TextColor3 = Color3.fromRGB(255, 245, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = c,
	})
	UIKit.ribbon(c, "SOON", "Blue")
end

comingSoon("Pets", "Pets", PINK, "Creatures", "Pink", "Equip your best creatures")
comingSoon("Rewards", "Rewards", GOLD, "Rewards", "Gold", "Daily gifts, playtime gifts, quests")

-- 5. GAME PASSES ------------------------------------------------------------------

section("Passes", "Game Passes", SKY)
local passGrid = UIKit.grid(body, Vector2.new(196, 262), nextOrder())
local PASS_COLORS = { "Blue", "Orange", "Teal", "Green", "Pink", "Purple", "Gold" }
local passOwned: { [string]: TextButton } = {}
for i, pass in ipairs(Shop.Passes) do
	local c = UIKit.card({ parent = passGrid, color = PASS_COLORS[(i - 1) % #PASS_COLORS + 1], order = i, name = pass.Key })
	cardText(c, string.upper(pass.Name), 6, 32, 26)
	local icon = UIKit.icon(pass.Art, { Size = UDim2.fromOffset(128, 128), Position = UDim2.new(0.5, -64, 0, 38), ZIndex = 4, Parent = c })
	lively(c, icon, { rays = Color3.new(1, 1, 1), sparkles = 3 })
	-- Les passes phares ont un contour qui brille
	if pass.Key == "VIP" then
		UIKit.shinyStroke(c, UIKit.Rainbow, 5)
	elseif pass.Ribbon then
		UIKit.shinyStroke(c, UIKit.GoldShine, 5)
	end
	if pass.Id ~= 0 then
		robuxCards[pass.Id] = c
	end
	cardText(c, pass.Text, 168, 30, 17)
	local button = UIKit.priceButton({ parent = c, text = tostring(pass.Price), robux = true, size = UDim2.new(1, -78, 0, 50), position = UDim2.new(0, 70, 1, -58) })
	button.MouseButton1Click:Connect(function()
		buyRobux(pass.Id, true)
	end)
	UIKit.giftButton(c, UDim2.new(0, 8, 1, -58)).MouseButton1Click:Connect(soon)
	if pass.Ribbon then
		UIKit.ribbon(c, pass.Ribbon, "Red")
	end
	passOwned[pass.Key] = button
end

-- Passes déjà achetés : le bouton devient « OWNED »
task.spawn(function()
	for _, pass in ipairs(Shop.Passes) do
		if pass.Id ~= 0 then
			local ok, owned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			if ok and owned then
				local b = passOwned[pass.Key]
				local label = b:FindFirstChild("Row") and b.Row:FindFirstChildOfClass("TextLabel")
				if label then
					label.Text = "OWNED"
				end
				local robux = b:FindFirstChild("Row") and b.Row:FindFirstChild("Robux")
				if robux then
					robux:Destroy()
				end
				b.Active = false
			end
		end
	end
end)

-- 6. POTIONS + boost gratuit -------------------------------------------------------

section("Potions", "Potions", PINK)
local potionGrid = UIKit.grid(body, Vector2.new(152, 240), nextOrder())
local POTION_COLORS = { "Green", "Gold", "Teal", "Purple" }
for i, potion in ipairs(Shop.Potions) do
	local c = UIKit.card({ parent = potionGrid, color = POTION_COLORS[i] or "Blue", order = i, name = potion.Key })
	cardText(c, string.upper(potion.Name), 6, 28, 22)
	local icon = UIKit.icon(potion.Art, { Size = UDim2.fromOffset(112, 112), Position = UDim2.new(0.5, -56, 0, 34), ZIndex = 4, Parent = c })
	lively(c, icon, { sparkles = 3 })
	if potion.Id ~= 0 then
		robuxCards[potion.Id] = c
	end
	cardText(c, potion.Text or (Shop.PotionMinutes .. " min"), 150, 24, 17, Color3.fromRGB(255, 245, 150))
	UIKit.priceButton({ parent = c, text = tostring(potion.Price), robux = true, size = UDim2.new(1, -16, 0, 48), position = UDim2.new(0, 8, 1, -56) }).MouseButton1Click:Connect(function()
		buyRobux(potion.Id, false)
	end)
end
do
	-- Boost gratuit : une pub récompensée (pas encore branchée)
	local c = UIKit.card({ parent = potionGrid, color = "Red", order = #Shop.Potions + 1, name = "FreeBoost" })
	cardText(c, "FREE!", 6, 28, 24)
	local icon = UIKit.icon(Shop.FreeBoost.Art, { Size = UDim2.fromOffset(112, 112), Position = UDim2.new(0.5, -56, 0, 34), ZIndex = 4, Parent = c })
	lively(c, icon, { rays = Color3.fromRGB(255, 230, 160), sparkles = 4 })
	cardText(c, "x2 for " .. Shop.FreeBoost.Minutes .. " min", 150, 24, 17, Color3.fromRGB(255, 245, 150))
	local watch = UIKit.priceButton({ parent = c, text = "WATCH", color = "Blue", size = UDim2.new(1, -16, 0, 48), position = UDim2.new(0, 8, 1, -56) })
	watch.MouseButton1Click:Connect(soon)
	UIKit.buttonGlow(watch, Color3.fromRGB(120, 210, 255))
end

-- 7. MONEY PACKS ---------------------------------------------------------------------

section("Money", "Money Packs", LIME)
local moneyGrid = UIKit.grid(body, Vector2.new(152, 240), nextOrder())
local moneyAmounts: { TextLabel } = {}
for i, pack in ipairs(Shop.MoneyPacks) do
	local c = UIKit.card({ parent = moneyGrid, color = if i == #Shop.MoneyPacks then "Gold" else "Green", order = i, name = "Money" .. i })
	local icon = UIKit.icon(pack.Art, { Size = UDim2.fromOffset(124, 124), Position = UDim2.new(0.5, -62, 0, 14), ZIndex = 4, Parent = c })
	-- Plus le paquet est gros, plus il brille
	local top = i == #Shop.MoneyPacks
	lively(c, icon, { rays = if top then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(200, 255, 150), sparkles = 1 + i })
	if top then
		UIKit.shinyStroke(c, UIKit.GoldShine, 5)
	end
	if pack.Id ~= 0 then
		robuxCards[pack.Id] = c
	end
	moneyAmounts[i] = cardText(c, "", 140, 34, 30, UIKit.Money)
	UIKit.priceButton({ parent = c, text = tostring(pack.Price), robux = true, size = UDim2.new(1, -16, 0, 48), position = UDim2.new(0, 8, 1, -56) }).MouseButton1Click:Connect(function()
		buyRobux(pack.Id, false)
	end)
	if pack.Ribbon then
		UIKit.ribbon(c, pack.Ribbon, "Red")
	end
end

local function refreshMoney()
	local ring = player:GetAttribute("Ring") or 1
	for i, pack in ipairs(Shop.MoneyPacks) do
		moneyAmounts[i].Text = "$" .. Format.Short(Config.MoneyPackAmount(pack.Base, ring))
	end
end

-- 8. SKINS : bientôt -------------------------------------------------------------------

comingSoon("Skins", "Skins", SKY, "Supernova", "Blue", "Base themes, suit colors, jetpack trails")

-- RACCOURCIS ------------------------------------------------------------------------

local NAV = {
	{ key = "Featured", art = "Shop", color = "Orange" },
	{ key = "Upgrades", art = "Upgrades", color = "Green" },
	{ key = "Pets", art = "Creatures", color = "Pink" },
	{ key = "Rewards", art = "Rewards", color = "Gold" },
	{ key = "Passes", art = "PassVIP", color = "Blue" },
	{ key = "Potions", art = "PotionLuck", color = "Purple" },
	{ key = "Money", art = "Money3", color = "Teal" },
	{ key = "Skins", art = "Supernova", color = "Dark" },
}
for i, n in ipairs(NAV) do
	local colors = UIKit.Colors[n.color]
	local b = new("TextButton", {
		Name = n.key,
		Size = UDim2.fromOffset(78, 66),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = i,
		ZIndex = 3,
		Parent = nav,
	}, { UIKit.corner(14), UIKit.stroke(3.5), UIKit.gradient(colors[1], colors[2]) })
	local icon = UIKit.icon(n.art, { Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0.5, -35, 0.5, -38), ZIndex = 4, Parent = b })
	UIKit.float(icon, 3, 5, 3, i * 0.7)
	UIKit.juice(b)
	b.MouseButton1Click:Connect(function()
		scrollTo(n.key)
		-- Le titre de la section visée rebondit à l'arrivée
		task.delay(0.35, function()
			local title = sections[n.key]
			if title then
				UIKit.bump(title, 0.25)
			end
		end)
	end)
end

-- OUVERTURE ------------------------------------------------------------------------

local function refresh()
	refreshUpgrades()
	refreshMoney()
end

-- Niveaux connus, pour fêter chaque niveau gagné
local known: { [string]: number } = {}
local function remember()
	for _, u in ipairs(UPGRADES) do
		known[u.id] = player:GetAttribute("Lvl_" .. u.id) or 0
	end
	known.Ring = player:GetAttribute("Ring") or 1
end
remember()

player.AttributeChanged:Connect(function(name)
	if not (name == "Credits" or name == "Ring" or string.sub(name, 1, 4) == "Lvl_") then
		return
	end
	if win.isOpen() then
		refresh()
	end
	if name == "Credits" then
		return
	end
	-- Chaque niveau est suivi séparément : les événements arrivent en différé,
	-- un autre attribut ne doit pas « voir » ce niveau avant lui
	local id = if name == "Ring" then "Ring" else string.sub(name, 5)
	local now = player:GetAttribute(name)
	if win.isOpen() and known[id] and type(now) == "number" and now > known[id] then
		if id == "Ring" then
			celebrate(suit.card, "NEW RING!", Color3.fromRGB(230, 170, 255))
		elseif upgradeCards[id] then
			celebrate(upgradeCards[id].card, "LEVEL UP!", Color3.fromRGB(255, 236, 110))
		end
	end
	if type(now) == "number" then
		known[id] = now
	end
end)

-- Achat Robux réussi : la carte achetée explose de lumière
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, id, purchased)
	if who == player and purchased and robuxCards[id] then
		celebrate(robuxCards[id], "THANK YOU!", Color3.fromRGB(255, 236, 110))
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, id, purchased)
	if userId == player.UserId and purchased and robuxCards[id] then
		celebrate(robuxCards[id], "THANK YOU!", Color3.fromRGB(255, 236, 110))
	end
end)

-- Les cartes visibles apparaissent en vague, de haut en bas et de gauche à droite
local function wave()
	local top = body.AbsolutePosition.Y
	local h = math.max(1, body.AbsoluteSize.Y)
	local left = body.AbsolutePosition.X
	local w = math.max(1, body.AbsoluteSize.X)
	for _, card in ipairs(cascade) do
		local y = (card.AbsolutePosition.Y - top) / h
		if y > -0.5 and y < 1.1 then
			local x = (card.AbsolutePosition.X - left) / w
			UIKit.popIn(card, 0.12 + math.clamp(y, 0, 1) * 0.3 + x * 0.12)
		end
	end
end

local function open(at: string?)
	refresh()
	-- Le saut se fait avant l'animation d'ouverture, quand les positions sont justes
	win.open(function()
		scrollTo(at or "Featured", true)
		wave()
	end)
end

UIKit.Open.Event:Connect(function(what: string)
	if what == "Shop" then
		if win.isOpen() then
			win.close()
		else
			open()
		end
	elseif what == "Close" then
		win.close()
	end
end)

Remotes.OpenShop.OnClientEvent:Connect(function()
	open("Upgrades")
end)

-- Compte à rebours de l'offre du jour (minuit UTC)
task.spawn(function()
	while true do
		if win.isOpen() then
			local left = 86400 - os.time() % 86400
			featuredTimer.Text = string.format("Ends in %02d:%02d:%02d", left // 3600, left % 3600 // 60, left % 60)
			-- Moins d'une heure : le minuteur clignote en rouge
			if left < 3600 then
				featuredTimer.TextColor3 = if left % 2 == 0 then Color3.fromRGB(255, 90, 90) else Color3.fromRGB(255, 245, 150)
				UIKit.bump(featuredTimer, 0.08)
			end
		end
		task.wait(1)
	end
end)
