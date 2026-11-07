-- STORE : tout ce qui s'achète en Robux, et seulement ça (docs/Boutique.md).
-- Ouvert par le bouton STORE du HUD (UIKit.Open "Store"). Menu de catégories à gauche, une seule
-- liste qui défile à droite : Starter Pack (vedette, offre de bienvenue de 3 jours), Passes, Cash,
-- Boosts. Les prix sont lus sur Roblox (Prices) ; le serveur accorde les achats (ProcessReceipt).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Prices = require(script.Parent:WaitForChild("Prices"))

local player = Players.LocalPlayer
local new = UIKit.new
local Shop = Config.Shop

local W_SIZE = Vector2.new(1060, 650)
local win = UIKit.window({ name = "Store", title = "{Cash} STORE", color = "Green", size = W_SIZE })
win.body.Visible = false -- on construit notre propre mise en page (menu à gauche + liste)

local SIDE_W = 184
local GAP = 14

-- MENU DE CATÉGORIES (à gauche) ---------------------------------------------------------
local side = new("Frame", {
	Name = "Categories",
	Size = UDim2.new(0, SIDE_W, 1, -110),
	Position = UDim2.fromOffset(GAP, 98),
	BackgroundColor3 = Color3.fromRGB(30, 32, 42),
	BackgroundTransparency = 0.25,
	ZIndex = 2,
	Parent = win.frame,
}, {
	UIKit.corner(14),
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	new("UIPadding", { PaddingTop = UDim.new(0, 12) }),
})

-- LISTE QUI DÉFILE (à droite) -------------------------------------------------------------
local content = new("ScrollingFrame", {
	Name = "Content",
	Size = UDim2.new(1, -(SIDE_W + GAP * 3), 1, -106),
	Position = UDim2.fromOffset(SIDE_W + GAP * 2, 94),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 10,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 2,
	Parent = win.frame,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 24), PaddingRight = UDim.new(0, 16) }),
})
local CONTENT_W = W_SIZE.X - SIDE_W - GAP * 3 - 26

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local sections: { [string]: GuiObject } = {}
local robuxCards: { [number]: GuiObject } = {} -- Id Robux -> carte, pour fêter l'achat

-- Fête un achat : explosion de lumière, rebond, texte qui s'envole
local function celebrate(card: GuiObject, text: string)
	UIKit.burst(card, UDim2.fromScale(0.5, 0.35), Color3.fromRGB(255, 236, 110))
	UIKit.bump(card, 0.15)
	UIKit.flyText(card, text, UDim2.fromOffset(8, 100), Color3.fromRGB(255, 236, 110))
end

local function buy(id: number, isPass: boolean)
	if id == 0 then
		UIKit.toast("Coming soon!", "info")
	elseif isPass then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
end

-- Texte de carte à taille fixe (lisible sur tous les écrans)
local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?, align: Enum.TextXAlignment?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or UIKit.Ink,
		TextXAlignment = align or Enum.TextXAlignment.Center,
		ZIndex = 4,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

-- Bouton prix Robux : prix lu sur Roblox
local function robuxButton(parent: Instance, id: number, isPass: boolean, fallback: number, size: UDim2, pos: UDim2): (TextButton, TextLabel, UIGradient)
	local b, text, grad = UIKit.priceButton({ parent = parent, text = "…", robux = true, size = size, position = pos })
	Prices.Show(text, id, isPass, fallback)
	b.MouseButton1Click:Connect(function()
		if b.Active then
			buy(id, isPass)
		end
	end)
	return b, text, grad
end

-- Titre de section (sert aussi de point d'arrivée du menu)
local function section(key: string, title: string, color: Color3)
	sections[key] = UIKit.sectionTitle(content, title, color, nextOrder())
end

local function grid(cell: Vector2): Frame
	local g = UIKit.grid(content, cell, nextOrder())
	g.Size = UDim2.fromOffset(CONTENT_W, 0)
	return g
end

-- Illustration de carte avec un halo doux derrière (les rayons sont réservés à la vedette)
local function art(card: Frame, image: string, size: number, y: number): ImageLabel
	local holder = new("Frame", { Size = UDim2.fromOffset(size, size), Position = UDim2.new(0.5, -size / 2, 0, y), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
	UIKit.glow(holder, { color = Color3.new(1, 1, 1), size = size * 1.15, transparency = 0.45, z = 3 })
	local icon = UIKit.icon(image, { Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = holder })
	UIKit.float(icon, 3, 3, 2)
	UIKit.hoverCard(card)
	return icon
end

-- 1. STARTER PACK (vedette) --------------------------------------------------------------
local F = Shop.Featured
section("Starter", "Starter Pack", Color3.fromRGB(255, 214, 70))
local featured = UIKit.card({ parent = content, color = "Orange", order = nextOrder(), name = "Starter" })
featured.Size = UDim2.fromOffset(CONTENT_W, 244)
do
	local layer = UIKit.fxLayer(featured)
	UIKit.rays(layer, { color = Color3.fromRGB(255, 240, 160), size = 380, position = UDim2.fromOffset(120, 122), transparency = 0.25, z = layer.ZIndex })
	UIKit.glow(layer, { color = Color3.fromRGB(255, 250, 210), size = 240, position = UDim2.fromOffset(120, 122), transparency = 0.2, z = layer.ZIndex })
	local bag = UIKit.icon(F.Art, { Size = UDim2.fromOffset(210, 210), Position = UDim2.fromOffset(16, 16), ZIndex = 4, Parent = featured })
	UIKit.float(bag, 4, 4, 2.2)
	UIKit.shinyStroke(featured, UIKit.GoldShine, 5)
	UIKit.sparkles(featured, { count = 5 })
	UIKit.ribbon(featured, "ONE TIME!", "Red")
end
label(featured, "STARTER PACK", 236, 14, 360, 46, 40, nil, Enum.TextXAlignment.Left)
label(featured, "Welcome offer, only once!", 236, 60, 360, 26, 20, Color3.fromRGB(255, 245, 190), Enum.TextXAlignment.Left)
-- Ce qu'on obtient, en trois pastilles
local chips = new("Frame", { Size = UDim2.fromOffset(470, 64), Position = UDim2.fromOffset(236, 96), BackgroundTransparency = 1, ZIndex = 4, Parent = featured }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local starterCash: TextLabel
for i, chip in ipairs({ { "Money3", "" }, { "PotionLuck", "x2 Luck 15m" }, { "PotionMoney", "x2 Money 15m" } }) do
	local c = new("Frame", { Size = UDim2.fromOffset(150, 64), BackgroundColor3 = Color3.fromRGB(40, 30, 20), BackgroundTransparency = 0.45, LayoutOrder = i, ZIndex = 4, Parent = chips }, { UIKit.corner(12) })
	UIKit.icon(chip[1], { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(4, 6), ZIndex = 5, Parent = c })
	local t = label(c, chip[2], 56, 8, 90, 48, 20, if i == 1 then UIKit.Money else nil)
	t.ZIndex = 5
	if i == 1 then
		starterCash = t
	end
end
local starterTimer = label(featured, "", 236, 180, 300, 34, 26, Color3.fromRGB(255, 245, 150), Enum.TextXAlignment.Left)
local starterBuy = robuxButton(featured, F.Id, false, F.Price, UDim2.fromOffset(220, 66), UDim2.new(1, -244, 1, -80))
UIKit.buttonGlow(starterBuy)
if F.Id ~= 0 then
	robuxCards[F.Id] = featured
end

-- 2. PASSES -------------------------------------------------------------------------------
section("Passes", "Game Passes", Color3.fromRGB(120, 215, 255))
local passGrid = grid(Vector2.new(250, 292))
local PASS_COLORS = { "Blue", "Orange", "Purple", "Green", "Teal", "Gold" }
type PassCard = { button: TextButton, text: TextLabel, grad: UIGradient }
local passCards: { [string]: PassCard } = {}
for i, pass in ipairs(Shop.Passes) do
	local c = UIKit.card({ parent = passGrid, color = PASS_COLORS[(i - 1) % #PASS_COLORS + 1], order = i, name = pass.Key })
	label(c, string.upper(pass.Name), 8, 10, 234, 34, 28)
	art(c, pass.Art, 130, 46)
	label(c, pass.Text, 12, 182, 226, 40, 18, Color3.fromRGB(255, 250, 225))
	local b, t, g = robuxButton(c, pass.Id, true, pass.Price, UDim2.new(1, -24, 0, 52), UDim2.new(0, 12, 1, -64))
	passCards[pass.Key] = { button = b, text = t, grad = g }
	if pass.Key == "VIP" then
		UIKit.shinyStroke(c, UIKit.Rainbow, 5)
	end
	if pass.Id ~= 0 then
		robuxCards[pass.Id] = c
	end
end

-- Passe possédé : « OWNED », bouton gris et inactif
local function markOwned(key: string)
	local card = passCards[key]
	if not card then
		return
	end
	card.text.Text = "OWNED"
	local robux = card.button:FindFirstChild("Robux", true)
	if robux then
		robux:Destroy()
	end
	UIKit.recolor(card.grad, "Grey")
	card.button.Active = false
end
local function refreshPasses()
	for _, pass in ipairs(Shop.Passes) do
		if player:GetAttribute("Pass_" .. pass.Key) then
			markOwned(pass.Key)
		end
	end
end

-- 3. CASH -----------------------------------------------------------------------------------
section("Cash", "Cash", Color3.fromRGB(150, 245, 80))
local cashGrid = grid(Vector2.new(152, 236))
local cashAmounts: { TextLabel } = {}
for i, pack in ipairs(Shop.MoneyPacks) do
	local best = i == #Shop.MoneyPacks
	local c = UIKit.card({ parent = cashGrid, color = if best then "Gold" else "Green", order = i, name = "Cash" .. i })
	art(c, pack.Art, 112, 14)
	cashAmounts[i] = label(c, "", 6, 128, 140, 36, 30, UIKit.Money)
	robuxButton(c, pack.Id, false, pack.Price, UDim2.new(1, -16, 0, 48), UDim2.new(0, 8, 1, -58))
	if best then
		-- le plus gros paquet est vraiment le plus avantageux ($ par Robux)
		UIKit.shinyStroke(c, UIKit.GoldShine, 5)
		UIKit.ribbon(c, "BEST VALUE!", "Red")
	end
	if pack.Id ~= 0 then
		robuxCards[pack.Id] = c
	end
end

-- 4. BOOSTS -----------------------------------------------------------------------------------
section("Boosts", "Boosts", Color3.fromRGB(255, 150, 210))
local boostGrid = grid(Vector2.new(250, 272))
local BOOST_COLORS = { "Purple", "Green", "Teal" }
local boostTimers: { [string]: TextLabel } = {}
for i, potion in ipairs(Shop.Potions) do
	local c = UIKit.card({ parent = boostGrid, color = BOOST_COLORS[i] or "Blue", order = i, name = potion.Key })
	label(c, string.upper(potion.Name), 8, 10, 234, 34, 28)
	art(c, potion.Art, 124, 46)
	boostTimers[potion.Key] = label(c, "", 12, 172, 226, 30, 20, Color3.fromRGB(255, 245, 150))
	robuxButton(c, potion.Id, false, potion.Price, UDim2.new(1, -24, 0, 52), UDim2.new(0, 12, 1, -64))
	if potion.Id ~= 0 then
		robuxCards[potion.Id] = c
	end
end

-- MENU : un bouton par catégorie, celui de la section visible s'éclaire --------------------------
local CATEGORIES = {
	{ key = "Starter", text = "STARTER", art = F.Art, color = "Orange" },
	{ key = "Passes", text = "PASSES", art = "PassVIP", color = "Blue" },
	{ key = "Cash", text = "CASH", art = "Money3", color = "Green" },
	{ key = "Boosts", text = "BOOSTS", art = "PotionLuck", color = "Purple" },
}
local catButtons: { [string]: { button: TextButton, stroke: UIStroke } } = {}

local function scrollTo(key: string, instant: boolean?)
	local target = sections[key]
	if not target or not target.Visible then
		return
	end
	local y = target.AbsolutePosition.Y - content.AbsolutePosition.Y + content.CanvasPosition.Y
	local maxY = math.max(0, content.AbsoluteCanvasSize.Y - content.AbsoluteWindowSize.Y)
	local goal = Vector2.new(0, math.clamp(y, 0, maxY))
	if instant then
		content.CanvasPosition = goal
	else
		UIKit.tween(content, 0.35, { CanvasPosition = goal }, Enum.EasingStyle.Quart)
	end
end

for i, cat in ipairs(CATEGORIES) do
	local colors = UIKit.Colors[cat.color]
	local b = new("TextButton", {
		Name = cat.key,
		Size = UDim2.fromOffset(SIDE_W - 20, 64),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = i,
		ZIndex = 3,
		Parent = side,
	}, { UIKit.corner(14), UIKit.gradient(colors[1], colors[2]) })
	local stroke = UIKit.stroke(3.5)
	stroke.Parent = b
	UIKit.studs(b, 0.45, "Weld", 22)
	UIKit.icon(cat.art, { Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0, -4, 0.5, -30), ZIndex = 4, Parent = b })
	label(b, cat.text, 54, 14, SIDE_W - 80, 36, 24, nil, Enum.TextXAlignment.Left)
	UIKit.juice(b)
	b.MouseButton1Click:Connect(function()
		scrollTo(cat.key)
	end)
	catButtons[cat.key] = { button = b, stroke = stroke }
end

-- La catégorie dont la section est en haut de la liste est mise en avant
local function highlight()
	local current = nil
	for _, cat in ipairs(CATEGORIES) do
		local s = sections[cat.key]
		if s and s.Visible and s.AbsolutePosition.Y - content.AbsolutePosition.Y <= 60 then
			current = cat.key
		end
	end
	current = current or "Starter"
	for key, c in pairs(catButtons) do
		local on = key == current
		c.stroke.Thickness = if on then 5 else 3.5
		c.stroke.Color = if on then Color3.fromRGB(255, 240, 150) else UIKit.Outline
		c.button.Size = UDim2.fromOffset(if on then SIDE_W - 12 else SIDE_W - 20, 64)
	end
end
content:GetPropertyChangedSignal("CanvasPosition"):Connect(highlight)

-- STARTER PACK : visible pendant sa fenêtre et tant qu'il n'est pas acheté ---------------------
local function starterLeft(): number
	return ((player:GetAttribute("StarterEnds") or 0) :: number) - os.time()
end
local function starterAvailable(): boolean
	return F.Id ~= 0 and not player:GetAttribute("StarterBought") and starterLeft() > 0
end
local function refreshStarter()
	local show = starterAvailable()
	featured.Visible = show
	sections.Starter.Visible = show
	catButtons.Starter.button.Visible = show
	local ring = (player:GetAttribute("Ring") or 1) :: number
	starterCash.Text = "$" .. Format.Short(Config.MoneyPackAmount(F.PackBase, ring))
end
local function timerText(left: number): string
	if left >= 86400 then
		return ("Ends in %dd %dh"):format(left // 86400, left % 86400 // 3600)
	end
	return ("Ends in %02d:%02d:%02d"):format(left // 3600, left % 3600 // 60, left % 60)
end

-- MISE À JOUR -----------------------------------------------------------------------------------
local function refresh()
	refreshStarter()
	refreshPasses()
	local ring = (player:GetAttribute("Ring") or 1) :: number
	for i, pack in ipairs(Shop.MoneyPacks) do
		cashAmounts[i].Text = "$" .. Format.Short(Config.MoneyPackAmount(pack.Base, ring))
	end
end

task.spawn(function()
	while true do
		if win.isOpen() then
			if starterAvailable() then
				starterTimer.Text = timerText(starterLeft())
			end
			local now = os.time()
			for key, t in pairs(boostTimers) do
				local ends = player:GetAttribute("Boost_" .. key) :: number?
				local left = if ends then ends - now else 0
				t.Text = if left > 0 then ("ACTIVE %d:%02d"):format(left // 60, left % 60) else Shop.PotionMinutes .. " minutes"
			end
		end
		task.wait(1)
	end
end)

player.AttributeChanged:Connect(function(name)
	if win.isOpen() and (name == "Ring" or name == "StarterBought" or name == "StarterEnds" or string.sub(name, 1, 5) == "Pass_") then
		refresh()
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, id, purchased)
	if who == player and purchased and robuxCards[id] then
		celebrate(robuxCards[id], "THANK YOU!")
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, id, purchased)
	if userId == player.UserId and purchased and robuxCards[id] then
		celebrate(robuxCards[id], "THANK YOU!")
	end
end)

-- OUVERTURE ---------------------------------------------------------------------------------------
local function open(at: string?)
	refresh()
	win.open(function()
		scrollTo(at or (if starterAvailable() then "Starter" else "Passes"), true)
		highlight()
	end)
end

UIKit.Open.Event:Connect(function(what: string, at: string?)
	if what == "Store" then
		if win.isOpen() then
			win.close()
		else
			open(at)
		end
	elseif what == "Close" then
		win.close()
	end
end)
