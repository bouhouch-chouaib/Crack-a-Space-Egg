-- STORE : tout ce qui s'achète en Robux, et seulement ça (docs/Boutique.md).
-- Ouvert par le bouton STORE du HUD (UIKit.Open "Store"). Une seule liste pleine largeur qui défile :
-- Starter Pack (vedette, offre de bienvenue de 3 jours), Passes, Cash, Boosts ; les catégories sont
-- des icônes flottantes accrochées à droite de la fenêtre (docs/Analyse-menus-references.md).
-- 25 nov. : refaite d'après les deux captures de l'utilisateur (references/boutique/exemple-*.png) :
-- titres « ~ Featured ~ » centrés, bandeau vedette dans un cadre doré orné (coins et barres découpés dans
-- references/boutique/coin-cadre.png) sur un fond illustré, emblème qui déborde en haut à gauche ;
-- passes en grandes cartes vives à médaillon rond (tools/store-icons/v2). Apparition en cascade à
-- l'ouverture, rayons, halos, reflets qui balaient, étincelles.
-- Les prix sont lus sur Roblox (Prices) ; le serveur accorde les achats (ProcessReceipt).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local LayeredFx = require(script.Parent:WaitForChild("LayeredFx"))
local Prices = require(script.Parent:WaitForChild("Prices"))

local player = Players.LocalPlayer
local new = UIKit.new
local Shop = Config.Shop

local W_SIZE = Vector2.new(1060, 650)
local win = UIKit.window({ name = "Store", title = "Store", color = "Green", size = W_SIZE })
win.body.Visible = false -- on construit notre propre mise en page (liste + navigation flottante)

local GAP = 14

-- LISTE QUI DÉFILE (toute la largeur) -----------------------------------------------------
local content = new("ScrollingFrame", {
	Name = "Content",
	Size = UDim2.new(1, -GAP * 2, 1, -106),
	Position = UDim2.fromOffset(GAP, 94),
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
local CONTENT_W = W_SIZE.X - GAP * 2 - 26

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local sections: { [string]: GuiObject } = {}
-- Ce qui apparaît en cascade à chaque ouverture (dans l'ordre de la liste)
local reveal: { GuiObject } = {}
local robuxCards: { [number]: GuiObject } = {} -- Id Robux -> carte, pour fêter l'achat

-- Fête un achat : soleil doré en 4 calques (LayeredFx « Celebrate ») centré sur la carte, par-dessus la
-- fenêtre (posé dans le ScreenGui pour ne pas être coupé par la liste qui défile), explosion de lumière,
-- rebond, texte qui s'envole
local function celebrate(card: GuiObject, text: string)
	local screen = card:FindFirstAncestorWhichIsA("ScreenGui")
	if screen then
		local c = card.AbsolutePosition - screen.AbsolutePosition + card.AbsoluteSize / 2
		LayeredFx.Screen(screen, {
			kind = "Celebrate",
			colors = { Color3.fromRGB(255, 170, 20), Color3.fromRGB(255, 240, 140) },
			duration = 1.1,
			size = UDim2.fromScale(0.75, 0.75),
			position = UDim2.fromOffset(c.X, c.Y),
			zIndex = 60,
		})
	end
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

-- Remonte un élément et tout ce qu'il contient (les ZIndex sont globaux dans les écrans du jeu)
local function lift(g: GuiObject, z: number)
	local dz = z - g.ZIndex
	g.ZIndex = z
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex += dz
		end
	end
end

-- Gros prix (comme les captures de référence) : texte et icône Robux agrandis
local function bigPrice(b: TextButton, text: TextLabel, size: number)
	text.TextSize = size
	local robux = b:FindFirstChild("Robux", true) :: ImageLabel?
	if robux then
		robux.Size = UDim2.fromOffset(size, size)
	end
end

-- Titre de section centré « ~ Featured ~ » : grosses lettres de couleur à contour épais, reflet qui
-- balaie (sert aussi de point d'arrivée du menu)
local function section(key: string, title: string, color: Color3)
	local row = new("Frame", { Name = "Title_" .. key, Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = content })
	local t = UIKit.text({
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 54),
		Text = "~ " .. title .. " ~",
		TextScaled = false,
		TextSize = 46,
		ZIndex = 3,
		Stroke = 5,
		Parent = row,
	})
	UIKit.shinyText(t, color)
	sections[key] = row
	table.insert(reveal, row)
end

-- Images de la boutique (tools/store-icons/v2, envoyées sur Roblox)
local ART = Shop.Art

local function grid(cell: Vector2): Frame
	local g = UIKit.grid(content, cell, nextOrder())
	g.Size = UDim2.fromOffset(CONTENT_W, 0)
	return g
end

-- 1. STARTER PACK (vedette) --------------------------------------------------------------
-- Bandeau dans un cadre doré orné : fond illustré, emblème qui déborde en haut à gauche avec sa pastille
-- « NEW! », grand titre doré, ce qu'on obtient en tuiles, prix en dessous.
local F = Shop.Featured
section("Starter", "Featured", Color3.fromRGB(255, 222, 60))
local FEAT_H = 372
local CORNER = 118 -- taille d'un coin du cadre
-- place et épaisseur des barres : celles des bras du coin (6,7 % à 20 % de sa taille)
local BAR_IN, BAR_T = math.floor(CORNER * 0.067), math.ceil(CORNER * 0.134)
local featured = new("Frame", { Name = "Starter", Size = UDim2.fromOffset(CONTENT_W, FEAT_H), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = content })
table.insert(reveal, featured)
-- le fond illustré, sous le cadre
local inset = BAR_IN + 4
local bg = new("ImageLabel", {
	Name = "Background",
	Position = UDim2.fromOffset(inset, inset),
	Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
	BackgroundColor3 = Color3.fromRGB(30, 26, 70),
	Image = ART.FeaturedBg,
	ScaleType = Enum.ScaleType.Crop,
	ClipsDescendants = true,
	ZIndex = 2,
	Parent = featured,
})
-- voile sombre en bas (lisibilité des tuiles et du prix) et liseré arc-en-ciel le long du bas
new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2, Parent = bg }, {
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.85), NumberSequenceKeypoint.new(1, 0.35) }),
	}),
})
local rainbowLine = new("Frame", { Name = "Rainbow", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = bg })
local rainbowGrad = new("UIGradient", { Color = UIKit.Rainbow, Parent = rainbowLine })
UIKit.every(rainbowGrad, function(t)
	rainbowGrad.Offset = Vector2.new(math.sin(t * 0.7) * 0.3, 0)
end)
-- reflet qui balaie tout le bandeau de temps en temps, étincelles
UIKit.shine(bg, 4)
UIKit.sparkles(bg, { count = 6, size = 26, z = 4 })
-- cadre doré : 4 barres étirées entre 4 coins ornés (un même coin tourné)
local frameLayer = new("Frame", { Name = "Frame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6, Parent = featured })
local mid = BAR_IN + BAR_T / 2
local function bar(pos: UDim2, size: UDim2, rotation: number)
	new("ImageLabel", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		Rotation = rotation,
		BackgroundTransparency = 1,
		Image = ART.FrameBar,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 6,
		Parent = frameLayer,
	})
end
local hLen = UDim2.new(1, -CORNER * 2 + 24, 0, BAR_T)
local vLen = UDim2.fromOffset(FEAT_H - CORNER * 2 + 24, BAR_T) -- taille avant le quart de tour
bar(UDim2.new(0.5, 0, 0, mid), hLen, 0)
bar(UDim2.new(0.5, 0, 1, -mid), hLen, 180)
bar(UDim2.new(0, mid, 0.5, 0), vLen, 90)
bar(UDim2.new(1, -mid, 0.5, 0), vLen, 270)
for i, spot in ipairs({ { 0, 0, 0 }, { 1, 0, 90 }, { 1, 1, 180 }, { 0, 1, 270 } }) do
	local corner = new("ImageLabel", {
		Name = "Corner" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(spot[1], if spot[1] == 0 then CORNER / 2 else -CORNER / 2, spot[2], if spot[2] == 0 then CORNER / 2 else -CORNER / 2),
		Size = UDim2.fromOffset(CORNER, CORNER),
		Rotation = spot[3],
		BackgroundTransparency = 1,
		Image = ART.FrameCorner,
		ZIndex = 7,
		Parent = frameLayer,
	})
	-- la pierre violette de chaque coin scintille
	UIKit.sparkles(corner, { count = 1, size = 30, z = 8 })
end
-- emblème qui déborde du cadre en haut à gauche, sur des rayons dorés
local EMB = 270
local embHolder = new("Frame", { Name = "Emblem", Position = UDim2.fromOffset(-6, -26), Size = UDim2.fromOffset(EMB, EMB), BackgroundTransparency = 1, ZIndex = 8, Parent = featured })
UIKit.rays(embHolder, { color = Color3.fromRGB(255, 225, 110), size = EMB * 1.35, transparency = 0.35, z = 8, speed = 14 })
UIKit.glow(embHolder, { color = Color3.fromRGB(255, 240, 170), size = EMB * 1.05, transparency = 0.3, z = 8 })
local emblem = UIKit.icon(ART.StarterEmblem, { Name = "Art", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 9, Parent = embHolder })
UIKit.float(emblem, 5, 4, 1.8)
-- pastille rouge « NEW! » penchée, sur l'emblème
local newTag = new("Frame", { Name = "New", Position = UDim2.fromOffset(28, 58), Size = UDim2.fromOffset(120, 40), Rotation = -10, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 10, Parent = featured }, {
	UIKit.corner(8),
	UIKit.stroke(3.5, Color3.new(1, 1, 1)),
	UIKit.gradient(UIKit.Colors.Red[1], UIKit.Colors.Red[2]),
})
UIKit.text({ Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), Text = "NEW!", ZIndex = 11, Stroke = 3, Parent = newTag })
UIKit.wiggle(newTag, 4, 3)
-- grand titre doré, sous-titre, compte à rebours
local TX = EMB + 6
local title = UIKit.text({ Size = UDim2.fromOffset(560, 74), Position = UDim2.fromOffset(TX, 26), Text = "Starter Pack", TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 66, ZIndex = 8, Stroke = 6, Parent = featured })
UIKit.shinyText(title, Color3.fromRGB(255, 200, 50))
label(featured, "Only once, just for you!", TX + 4, 98, 420, 32, 28, nil, Enum.TextXAlignment.Left).ZIndex = 8
local starterTimer = label(featured, "", CONTENT_W - 300, 36, 260, 36, 30, nil, Enum.TextXAlignment.Right)
starterTimer.ZIndex = 8
-- ce qu'on obtient : grandes tuiles sombres, image au centre, montant en bas à droite
local starterCash: TextLabel
local TILE = 120
local tiles = {
	{ "Money3", "", UIKit.Colors.Gold[2] },
	{ "PotionLuck", "x2 Luck", Color3.fromRGB(120, 245, 80) },
	{ "PotionMoney", "x2 Money", Color3.fromRGB(255, 200, 60) },
}
for i, tile in ipairs(tiles) do
	local t = new("Frame", {
		Name = "Tile" .. i,
		Position = UDim2.fromOffset(TX + (i - 1) * (TILE + 16), 132),
		Size = UDim2.fromOffset(TILE, TILE),
		BackgroundColor3 = Color3.fromRGB(26, 24, 44),
		BackgroundTransparency = 0.15,
		ZIndex = 8,
		Parent = featured,
	}, { UIKit.corner(10), UIKit.stroke(4) })
	if i == 1 then
		UIKit.shinyStroke(t, UIKit.GoldShine, 4)
	else
		(t:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = tile[3]
	end
	UIKit.sunburst(t, UDim2.fromScale(0.5, 0.45), TILE * 1.6, tile[3])
	local img = UIKit.icon(tile[1], { Size = UDim2.fromOffset(TILE - 34, TILE - 34), Position = UDim2.fromOffset(17, 8), ZIndex = 9, Parent = t })
	UIKit.float(img, 3, 3, 2.2, i)
	local amount = label(t, tile[2], 6, TILE - 36, TILE - 12, 30, 24, if i == 1 then UIKit.Money else nil, Enum.TextXAlignment.Right)
	amount.ZIndex = 10
	if i == 1 then
		starterCash = amount
	end
end
-- prix : un grand bouton vert, avec sa ligne en dessous
local starterBuy, starterPrice = robuxButton(featured, F.Id, false, F.Price, UDim2.fromOffset(TILE * 3 + 32, 60), UDim2.fromOffset(TX, FEAT_H - 110))
lift(starterBuy, 8)
bigPrice(starterBuy, starterPrice, 40)
UIKit.buttonGlow(starterBuy)
label(featured, "Cash + 2 potions of 15 min", TX, FEAT_H - 46, TILE * 3 + 32, 24, 22, Color3.fromRGB(255, 245, 190)).ZIndex = 8
if F.Id ~= 0 then
	robuxCards[F.Id] = featured
end

-- Carte vive (passes, argent, potions) : dégradé clair au centre et saturé sur les bords (look = { clair,
-- foncé } ou "Rainbow" qui défile), contour noir épais, picots, reflet qui passe, grossit au survol
local function vividCard(parent: Instance, look: any, slot: number, name: string): Frame
	local c = new("Frame", { Name = name, BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = slot, ZIndex = 2 }, { UIKit.corner(10), UIKit.stroke(5) })
	if look == "Rainbow" then
		local g = new("UIGradient", { Color = UIKit.Rainbow, Rotation = 35, Parent = c })
		UIKit.every(g, function(t)
			g.Offset = Vector2.new(math.sin(t * 0.6) * 0.3, 0)
		end)
	else
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, look[1]:Lerp(Color3.new(1, 1, 1), 0.35)),
				ColorSequenceKeypoint.new(0.5, look[1]),
				ColorSequenceKeypoint.new(1, look[2]),
			}),
			Rotation = 35,
			Parent = c,
		})
	end
	UIKit.studs(c, 0.55)
	c.Parent = parent
	UIKit.hoverCard(c)
	UIKit.shine(c, 5 + slot % 3)
	if look == "Rainbow" then
		UIKit.shinyStroke(c, UIKit.Rainbow, 6)
	end
	return c
end

-- Grosse image de carte sur un soleil de rayons blancs, qui flotte
local function cardArt(c: Frame, image: string, size: number, pos: UDim2, phase: number): ImageLabel
	UIKit.sunburst(c, pos + UDim2.fromOffset(size / 2, size / 2), size * 2.1)
	local img = UIKit.icon(image, { Name = "Art", Size = UDim2.fromOffset(size, size), Position = pos, ZIndex = 5, Parent = c })
	UIKit.float(img, 4, 4, 2, phase)
	return img
end

-- 2. PASSES -------------------------------------------------------------------------------
-- Grandes cartes vives, deux par ligne : médaillon rond à gauche sur des rayons, nom en haut à droite,
-- effet en dessous, grand bouton de prix vert en bas à droite.
section("Passes", "Game Passes", Color3.fromRGB(150, 245, 70))
local PASS_W = math.floor((CONTENT_W - 14) / 2)
local PASS_H = 236
local passGrid = grid(Vector2.new(PASS_W, PASS_H))
table.insert(reveal, passGrid)
-- fond de chaque carte (clair au centre, saturé sur les bords) ; "Rainbow" : arc-en-ciel qui défile
local PASS_LOOK: { [string]: any } = {
	JetXP2x = { Color3.fromRGB(120, 235, 255), Color3.fromRGB(20, 150, 235) },
	TurboJetpack = { Color3.fromRGB(255, 220, 90), Color3.fromRGB(245, 120, 20) },
	FastHatch = "Rainbow",
	Money2x = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(245, 170, 20) },
	BaseSlots = { Color3.fromRGB(170, 250, 90), Color3.fromRGB(50, 180, 40) },
	VIP = { Color3.fromRGB(255, 130, 110), Color3.fromRGB(205, 25, 50) },
}
type PassCard = { button: TextButton, text: TextLabel, grad: UIGradient }
local passCards: { [string]: PassCard } = {}
for i, pass in ipairs(Shop.Passes) do
	local look = PASS_LOOK[pass.Key] or { UIKit.Colors.Blue[1], UIKit.Colors.Blue[2] }
	local c = vividCard(passGrid, look, i, pass.Key)
	-- médaillon rond sur un soleil de rayons blancs, qui flotte
	local MED = 186
	cardArt(c, ART[pass.Key] or pass.Art, MED, UDim2.fromOffset(24, (PASS_H - MED) / 2), i).Name = "Medal"
	local right = PASS_W - MED - 48
	label(c, pass.Name, MED + 34, 16, right, 46, 40).ZIndex = 6
	local textLabel = label(c, pass.Text .. "!", MED + 34, 66, right, 82, 27)
	textLabel.ZIndex = 6
	textLabel.TextScaled = false
	textLabel.TextSize = 25
	textLabel.TextWrapped = true
	local b, t, g = robuxButton(c, pass.Id, true, pass.Price, UDim2.fromOffset(right, 64), UDim2.new(0, MED + 34, 1, -82))
	lift(b, 6)
	bigPrice(b, t, 38)
	passCards[pass.Key] = { button = b, text = t, grad = g }
	if pass.Key == "VIP" then
		UIKit.shinyStroke(c, UIKit.GoldShine, 6)
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
-- Même style que les passes : cartes vives (clair au centre, saturé sur les bords), grosse image sur un
-- soleil de rayons qui flotte, nom en haut, montant dans une pastille sombre, gros prix vert.
-- Trois petits paquets, puis les deux plus gros en grand sur la ligne suivante.
section("Cash", "Cash", Color3.fromRGB(150, 245, 80))
local SMALL = math.floor((CONTENT_W - 24) / 3)
local BIG = math.floor((CONTENT_W - 12) / 2)
local cashSmall = grid(Vector2.new(SMALL, 300))
local cashBig = grid(Vector2.new(BIG, 330))
table.insert(reveal, cashSmall)
table.insert(reveal, cashBig)
-- de l'air au-dessus : les rubans (« GOOD VALUE », « BEST VALUE! ») dépassent du haut des cartes
for _, g in ipairs({ cashSmall, cashBig }) do
	(g:FindFirstChildOfClass("UIPadding") :: UIPadding).PaddingTop = UDim.new(0, 24)
end
-- couleur de chaque paquet, du plus petit au plus gros (le dernier en arc-en-ciel)
local CASH_LOOK: { any } = {
	{ Color3.fromRGB(170, 250, 90), Color3.fromRGB(50, 180, 40) },
	{ Color3.fromRGB(120, 245, 220), Color3.fromRGB(20, 165, 150) },
	{ Color3.fromRGB(120, 235, 255), Color3.fromRGB(20, 150, 235) },
	{ Color3.fromRGB(255, 220, 90), Color3.fromRGB(245, 120, 20) },
	"Rainbow",
}
local cashAmounts: { TextLabel } = {}
local nPacks = #Shop.MoneyPacks
for i, pack in ipairs(Shop.MoneyPacks) do
	local best = i == nPacks
	local big = i > nPacks - 2
	local w = if big then BIG else SMALL
	local look = CASH_LOOK[i] or CASH_LOOK[1]
	local c = vividCard(if big then cashBig else cashSmall, look, i, "Cash" .. i)
	local artSize = if big then 156 else 128
	label(c, pack.Name or "Cash Pack", 8, 10, w - 16, 38, if big then 36 else 32).ZIndex = 6
	local art = cardArt(c, pack.Art, artSize, UDim2.new(0.5, -artSize / 2, 0, 46), i)
	art.ZIndex = 5
	local pill = new("Frame", { Name = "Amount", Size = UDim2.fromOffset(w - 40, 42), Position = UDim2.fromOffset(20, artSize + 46), BackgroundColor3 = Color3.fromRGB(14, 30, 16), BackgroundTransparency = 0.3, ZIndex = 6, Parent = c }, { UIKit.corner(12), UIKit.stroke(3) })
	cashAmounts[i] = label(pill, "", 6, 2, w - 52, 38, 34, UIKit.Money)
	cashAmounts[i].ZIndex = 7
	local b, t, grad = robuxButton(c, pack.Id, false, pack.Price, UDim2.new(1, -28, 0, 58), UDim2.new(0, 14, 1, -68))
	lift(b, 6)
	bigPrice(b, t, 38)
	if pack.Tag then
		lift(UIKit.ribbon(c, pack.Tag, pack.TagColor), 9)
	end
	if best then
		-- le plus gros paquet est vraiment le plus avantageux ($ par Robux) : contour doré, prix arc-en-ciel
		UIKit.shinyStroke(c, UIKit.GoldShine, 6)
		UIKit.rainbowButton(grad)
		UIKit.sparkles(c, { count = 4, size = 26 })
	end
	if pack.Id ~= 0 then
		robuxCards[pack.Id] = c
	end
end

-- 4. BOOSTS -----------------------------------------------------------------------------------
section("Boosts", "Boosts", Color3.fromRGB(255, 150, 210))
local boostGrid = grid(Vector2.new(SMALL, 312))
table.insert(reveal, boostGrid)
-- chaque potion à sa couleur : chance en vert, argent en doré, XP de jetpack en bleu
local BOOST_LOOK: { [string]: any } = {
	Luck = { Color3.fromRGB(170, 250, 90), Color3.fromRGB(50, 180, 40) },
	Money = { Color3.fromRGB(255, 235, 110), Color3.fromRGB(240, 160, 20) },
	JetXP = { Color3.fromRGB(120, 235, 255), Color3.fromRGB(20, 150, 235) },
}
local boostTimers: { [string]: TextLabel } = {}
for i, potion in ipairs(Shop.Potions) do
	local c = vividCard(boostGrid, BOOST_LOOK[potion.Key] or BOOST_LOOK.JetXP, i, potion.Key)
	label(c, potion.Name, 8, 10, SMALL - 16, 40, 34).ZIndex = 6
	local art = cardArt(c, potion.Art, 136, UDim2.new(0.5, -68, 0, 52), i)
	art.ZIndex = 5
	local timer = label(c, "", 12, 194, SMALL - 24, 32, 26, Color3.fromRGB(255, 250, 200))
	timer.ZIndex = 6
	boostTimers[potion.Key] = timer
	local b, t = robuxButton(c, potion.Id, false, potion.Price, UDim2.new(1, -28, 0, 60), UDim2.new(0, 14, 1, -72))
	lift(b, 6)
	bigPrice(b, t, 38)
	if potion.Id ~= 0 then
		robuxCards[potion.Id] = c
	end
end

-- NAVIGATION : icônes flottantes à droite de la fenêtre, nom en couleur pour la section affichée ---
local CATEGORIES = {
	{ key = "Starter", text = "STARTER", art = F.Art, color = Color3.fromRGB(255, 214, 70) },
	{ key = "Passes", text = "PASSES", art = "PassVIP", color = Color3.fromRGB(120, 215, 255) },
	{ key = "Cash", text = "CASH", art = "Money3", color = Color3.fromRGB(150, 245, 80) },
	{ key = "Boosts", text = "BOOSTS", art = "PotionLuck", color = Color3.fromRGB(255, 150, 210) },
}

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

local nav = UIKit.sideNav(win, CATEGORIES, function(key)
	scrollTo(key)
end)

-- La catégorie dont la section est en haut de la liste est mise en avant
local function highlight()
	local current = nil
	for _, cat in ipairs(CATEGORIES) do
		local s = sections[cat.key]
		if s and s.Visible and s.AbsolutePosition.Y - content.AbsolutePosition.Y <= 60 then
			current = cat.key
		end
	end
	nav.set(current or (if sections.Starter.Visible then "Starter" else "Passes"))
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
	nav.show("Starter", show)
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
		cashAmounts[i].Text = "+$" .. Format.Short(Config.MoneyPackAmount(pack.Base, ring))
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
-- Apparition en cascade : les titres et le bandeau surgissent en rebond, puis chaque carte d'une grille
-- l'une après l'autre ; l'emblème arrive en tournoyant avec un éclat de lumière.
local function playReveal()
	local delay = 0.05
	for _, g in ipairs(reveal) do
		if g:FindFirstChildOfClass("UIGridLayout") then
			for _, card in ipairs(g:GetChildren()) do
				if card:IsA("GuiObject") then
					UIKit.popIn(card, delay)
					delay += 0.04
				end
			end
		elseif g.Visible then
			UIKit.popIn(g, delay)
			delay += 0.06
		end
	end
	if featured.Visible then
		emblem.Rotation = -25
		emblem.Size = UDim2.fromScale(0.2, 0.2)
		task.delay(0.15, function()
			UIKit.tween(emblem, 0.55, { Size = UDim2.fromScale(1, 1), Rotation = 0 }, Enum.EasingStyle.Back)
			UIKit.burst(embHolder, UDim2.fromScale(0.5, 0.5), Color3.fromRGB(255, 225, 110))
		end)
	end
end

local function open(at: string?)
	refresh()
	win.open(function()
		scrollTo(at or (if starterAvailable() then "Starter" else "Passes"), true)
		highlight()
		playReveal()
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
