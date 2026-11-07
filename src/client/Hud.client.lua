-- HUD permanent (docs/Interfaces.md §1), dans le style des jeux d'œufs :
-- argent en énorme, colonne de gros boutons à pastilles, soute, minuteur d'événement, jauges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local new = UIKit.new
local player = Players.LocalPlayer

local gui = new("ScreenGui", {
	Name = "MainHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Un groupe par coin de l'écran, chacun à l'échelle de l'écran
local function group(name: string, anchor: Vector2, pos: UDim2, size: UDim2): Frame
	local f = new("Frame", { Name = name, AnchorPoint = anchor, Position = pos, Size = size, BackgroundTransparency = 1, Parent = gui })
	UIKit.autoScale(f)
	return f
end

-- STATS (en bas à gauche) : le niveau du jetpack et sa barre d'XP au-dessus, l'argent en énorme dessous -------
local moneyGroup = group("Money", Vector2.new(0, 1), UDim2.new(0, 18, 1, -18), UDim2.fromOffset(420, 180))
local speedIcon = UIKit.icon("Jetpack", { Size = UDim2.fromOffset(72, 72), Position = UDim2.fromOffset(16, 0), ZIndex = 2, Parent = moneyGroup })
local JET_COLOR = Color3.fromRGB(110, 235, 255)
local speedText = UIKit.text({
	Size = UDim2.fromOffset(300, 36),
	Position = UDim2.fromOffset(100, 2),
	Text = "Jetpack Lv 1",
	TextColor3 = JET_COLOR,
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 3.5,
	Parent = moneyGroup,
})
-- Barre d'XP du jetpack (se remplit dans les souffleries et en vol)
local xpBar = UIKit.new("Frame", {
	Name = "JetXPBar",
	Size = UDim2.fromOffset(270, 22),
	Position = UDim2.fromOffset(100, 42),
	BackgroundColor3 = Color3.fromRGB(25, 30, 48),
	Parent = moneyGroup,
}, { UIKit.corner(), UIKit.stroke(3) })
local xpFill = UIKit.new("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = xpBar,
}, { UIKit.corner(), UIKit.gradient(Color3.fromRGB(150, 245, 255), Color3.fromRGB(40, 150, 255)) })
local xpText = UIKit.text({
	Size = UDim2.new(1, -8, 1, -4),
	Position = UDim2.fromOffset(4, 2),
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	Stroke = 2,
	ZIndex = 3,
	Parent = xpBar,
})
local cashIcon = UIKit.icon("Cash", { Size = UDim2.fromOffset(104, 104), Position = UDim2.fromOffset(0, 72), ZIndex = 2, Parent = moneyGroup })
local moneyText = UIKit.text({
	Size = UDim2.fromOffset(300, 68),
	Position = UDim2.fromOffset(104, 82),
	Text = "$0",
	TextColor3 = UIKit.Money,
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 4,
	Parent = moneyGroup,
})
local incomeText = UIKit.text({
	Size = UDim2.fromOffset(200, 26),
	Position = UDim2.fromOffset(108, 150),
	Text = "",
	TextColor3 = Color3.fromRGB(200, 255, 170),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = moneyGroup,
})

-- Niveau du jetpack et barre d'XP (la vitesse au sol et en vol monte avec le niveau)
local shownLevel = 0
local function refreshSpeed()
	local level = player:GetAttribute("JetLevel") or 1
	local xp = player:GetAttribute("JetXP") or 0
	local need = player:GetAttribute("JetXPNeed") or 0
	speedText.Text = ("Jetpack Lv %d"):format(level)
	local ratio = if need > 0 then math.clamp(xp / need, 0, 1) else 1
	xpText.Text = if need > 0 then ("%s / %s XP"):format(Format.Short(xp), Format.Short(need)) else "MAX"
	TweenService:Create(xpFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(ratio, 1) }):Play()
	if shownLevel > 0 and level > shownLevel then
		xpFill.Size = UDim2.fromScale(0, 1)
		UIKit.flyText(moneyGroup, "LEVEL UP! FASTER!", UDim2.fromOffset(110, -10), JET_COLOR)
		UIKit.bump(speedIcon, 0.3)
		UIKit.burst(moneyGroup, UDim2.fromOffset(52, 36), JET_COLOR)
	end
	shownLevel = level
end

local shownMoney = 0
local function money(n: number): string
	return "$" .. Format.Short(n)
end
local function refreshMoney()
	local credits = player:GetAttribute("Credits") or 0
	if credits ~= shownMoney then
		if credits > shownMoney and shownMoney > 0 then
			UIKit.flyText(moneyGroup, "+" .. money(credits - shownMoney), UDim2.fromOffset(110, 76))
			UIKit.bump(cashIcon, 0.2)
		end
		UIKit.countTo(moneyText, shownMoney, credits, money, 0.6)
		shownMoney = credits
	end
	local income = player:GetAttribute("Income") or 0
	incomeText.Text = if income > 0 then "+" .. money(income) .. "/s" else ""
end

-- GROS BOUTONS (à gauche) : la boutique (améliorations, passes, potions, récompenses…
-- tout s'y trouve en faisant défiler) et l'index des créatures
local menu = group("Menu", Vector2.new(0, 0.5), UDim2.new(0, 34, 0.5, -20), UDim2.fromOffset(220, 2 * 76))
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
local buttons = {}
for i, b in ipairs({
	{ "Store", "STORE", "Shop", "Green" }, -- tout ce qui s'achète en Robux (Store.client)
	{ "Index", "INDEX", "Index", "Blue" },
}) do
	local button, badge = UIKit.menuButton({ name = b[1], text = b[2], art = b[3], color = b[4], parent = menu })
	button.Parent.LayoutOrder = i
	UIKit.popIn(button.Parent :: Frame, 0.08 * i)
	buttons[b[1]] = { button = button, badge = badge }
	button.MouseButton1Click:Connect(function()
		if b[1] == "Store" then
			UIKit.Open:Fire("Store")
		else
			UIKit.Open:Fire("Index")
		end
	end)
end

-- La pastille de STORE s'allume tant que l'offre de bienvenue (Starter Pack) est disponible
local function refreshBadges()
	local ends = (player:GetAttribute("StarterEnds") or 0) :: number
	buttons.Store.badge.Visible = Config.Shop.Featured.Id ~= 0 and not player:GetAttribute("StarterBought") and ends > os.time()
end

-- ŒUF PORTÉ (en haut à droite) ------------------------------------------------------
-- On ne porte qu'un œuf à la fois : pas de compteur, juste un emplacement. Vide, il reste discret ;
-- quand on ramasse un œuf, il s'allume à la couleur de la rareté (« RARE EGG! », « Bring it home! »).
local eggGroup = group("Egg", Vector2.new(1, 0), UDim2.new(1, -18, 0, 14), UDim2.fromOffset(280, 92))
local eggSlot = new("Frame", {
	Name = "EggSlot",
	Size = UDim2.fromOffset(270, 84),
	Position = UDim2.fromOffset(10, 4),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = eggGroup,
}, { UIKit.corner(), UIKit.stroke(4) })
local eggGrad = UIKit.gradient(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2])
eggGrad.Parent = eggSlot
local eggFx = new("Frame", { Name = "Fx", Size = UDim2.fromOffset(110, 110), Position = UDim2.fromOffset(-14, -13), BackgroundTransparency = 1, Parent = eggSlot })
local eggRays = UIKit.rays(eggFx, { color = Color3.new(1, 1, 1), size = 130, speed = 40, transparency = 0.5, z = 1 })
local eggGlow = UIKit.glow(eggFx, { color = Color3.new(1, 1, 1), size = 120, transparency = 0.45, z = 1, pulse = 1.6 })
local eggIcon = UIKit.icon("Egg", { Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(2, 3), ZIndex = 3, Parent = eggSlot })
local eggTitle = UIKit.text({ Size = UDim2.fromOffset(176, 38), Position = UDim2.fromOffset(86, 8), Text = "NO EGG", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Stroke = 3, Parent = eggSlot })
local eggSub = UIKit.text({ Size = UDim2.fromOffset(176, 26), Position = UDim2.fromOffset(86, 48), Text = "Drill an asteroid", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Stroke = 2.5, Parent = eggSlot })
UIKit.float(eggIcon, 2, 5, 2.4)

local carrying = nil :: boolean?
local function refreshCargo()
	local has = (player:GetAttribute("Cargo") or 0) > 0
	local r = tonumber(string.split(player:GetAttribute("CargoRarities") or "", ",")[1] or "")
	local rarity = Config.Rarities[r or 1] or Config.Rarities[1]
	if has then
		local c = rarity.Color
		eggGrad.Color = ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.25), c:Lerp(Color3.new(0, 0, 0), 0.45))
		eggIcon.ImageTransparency = 0
		eggIcon.ImageColor3 = Color3.new(1, 1, 1)
		eggRays.ImageColor3, eggGlow.ImageColor3 = c, c
		eggFx.Visible = true
		eggTitle.Text = string.upper(rarity.Name) .. " EGG!"
		eggTitle.TextColor3 = Color3.new(1, 1, 1)
		UIKit.setIconText(eggSub, "{Home} Bring it home!")
		eggSub.TextColor3 = Color3.fromRGB(255, 245, 200)
	else
		eggGrad.Color = ColorSequence.new(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2])
		eggIcon.ImageTransparency = 0.55
		eggIcon.ImageColor3 = Color3.fromRGB(150, 150, 170)
		eggFx.Visible = false
		eggTitle.Text = "NO EGG"
		eggTitle.TextColor3 = Color3.fromRGB(190, 195, 215)
		UIKit.setIconText(eggSub, "Drill an asteroid")
		eggSub.TextColor3 = Color3.fromRGB(160, 165, 185)
	end
	-- on vient de ramasser un œuf : il saute, éclat de lumière
	if carrying == false and has then
		UIKit.bump(eggSlot, 0.18)
		UIKit.burst(eggSlot, UDim2.fromOffset(42, 42), rarity.Color)
	end
	carrying = has
end

-- POTIONS ACTIVES (sous l'œuf, en haut à droite) : icône qui flotte et temps restant ---------
local boostGroup = group("Boosts", Vector2.new(1, 0), UDim2.new(1, -18, 0, 112), UDim2.fromOffset(260, 84))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), Parent = boostGroup })
local boostCards: { [string]: { frame: Frame, time: TextLabel } } = {}
for i, potion in ipairs(Config.Shop.Potions) do
	do
		local f = new("Frame", { Name = potion.Key, Size = UDim2.fromOffset(70, 84), BackgroundTransparency = 1, LayoutOrder = i, Visible = false, Parent = boostGroup })
		local icon = UIKit.icon(potion.Art, { Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(4, 0), Parent = f })
		UIKit.float(icon, 3, 4, 1.4, i)
		UIKit.glow(f, { color = Color3.fromRGB(255, 230, 120), size = 80, transparency = 0.6, position = UDim2.fromOffset(35, 31), z = 0, pulse = 1.5 })
		local t = UIKit.text({ Size = UDim2.fromOffset(70, 24), Position = UDim2.fromOffset(0, 60), Text = "", Stroke = 2.5, Parent = f })
		boostCards[potion.Key] = { frame = f, time = t }
	end
end
task.spawn(function()
	while true do
		local now = os.time()
		for key, card in pairs(boostCards) do
			local ends = player:GetAttribute("Boost_" .. key) :: number?
			local left = if ends then ends - now else 0
			card.frame.Visible = left > 0
			if left > 0 then
				card.time.Text = ("%d:%02d"):format(left // 60, left % 60)
			end
		end
		task.wait(1)
	end
end)

-- JAUGES (bord droit) ---------------------------------------------------------
local gauges = group("Gauges", Vector2.new(1, 0.5), UDim2.new(1, -18, 0.5, 0), UDim2.fromOffset(200, 300))
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
	Parent = gauges,
})
local noiseGauge, noiseFill = UIKit.gauge({ name = "Noise", art = "Noise", color = "Purple", parent = gauges })

-- JAUGE DU JETPACK : elle grandit et devient plus stylée à chaque palier (Config.Jetpack.Tiers) :
-- couleur du palier, contour coloré (palier 2), halo qui pulse (3), reflet qui balaie (4),
-- étincelles (5), rayons qui tournent (6), contour brillant (7), contour arc-en-ciel (8).
-- Elle clignote en rouge quand le carburant passe sous 25 %.
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII" }
local jetHolder = new("Frame", { Name = "Jetpack", BackgroundTransparency = 1, LayoutOrder = 2, Size = UDim2.fromOffset(70, 212), Parent = gauges })
local fuelFill: Frame = new("Frame")
local lowFlash: Frame = new("Frame")
local function buildJetGauge(tier: number)
	for _, c in ipairs(jetHolder:GetChildren()) do
		c:Destroy()
	end
	local tiers = Config.Jetpack.Tiers
	local t = tiers[tier] or tiers[1]
	local k = (tier - 1) / math.max(1, #tiers - 1) -- 0 au palier 1, 1 au dernier
	local w, h = math.floor(26 + 14 * k), math.floor(150 + 80 * k)
	local W = w + 46
	jetHolder.Size = UDim2.fromOffset(W, h + 68)
	local mid = UDim2.fromOffset(W / 2, 30 + h / 2)
	local dark = t.Color:Lerp(Color3.new(0, 0, 0), 0.35)
	-- derrière la jauge
	if tier >= 6 then
		UIKit.rays(jetHolder, { color = t.Color, size = h * 1.25, speed = 20 + 6 * tier, transparency = 0.55, position = mid, z = 0 })
	end
	if tier >= 3 then
		UIKit.glow(jetHolder, { color = t.Color, size = h * (0.9 + 0.3 * k), transparency = 0.6 - 0.15 * k, position = mid, z = 0, pulse = 1.4 })
	end
	local back = new("Frame", {
		Name = "Back",
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset((W - w) / 2, 30),
		BackgroundColor3 = UIKit.Colors.Dark[2],
		ZIndex = 2,
		Parent = jetHolder,
	}, { UIKit.corner(), UIKit.stroke(3 + 2 * k, if tier >= 2 then dark else nil) })
	fuelFill = new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = back,
	}, { UIKit.corner(), UIKit.gradient(t.Color:Lerp(Color3.new(1, 1, 1), 0.45), t.Color:Lerp(Color3.new(0, 0, 0), 0.2)) })
	lowFlash = new("Frame", { Name = "Low", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 50, 50), BackgroundTransparency = 1, ZIndex = 5, Parent = back }, { UIKit.corner() })
	-- graduations : un quart, une moitié, trois quarts
	for i = 1, 3 do
		new("Frame", {
			Size = UDim2.new(0.5, 0, 0, 2),
			Position = UDim2.new(0.25, 0, i / 4, -1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = back,
		})
	end
	if tier >= 4 then
		UIKit.shine(fuelFill, 3)
	end
	if tier >= 5 then
		UIKit.sparkles(jetHolder, { count = tier - 2, color = t.Color:Lerp(Color3.new(1, 1, 1), 0.4), size = 14 + 2 * tier, z = 7 })
	end
	if tier >= 8 then
		UIKit.shinyStroke(back, UIKit.Rainbow, 5, 120)
	elseif tier >= 7 then
		UIKit.shinyStroke(back, UIKit.GoldShine, 5, 90)
	end
	-- palier en chiffres romains (en haut), icône du jetpack (en bas)
	local badge = new("Frame", {
		Name = "Tier",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(math.max(40, w + 14), 26),
		Position = UDim2.fromOffset(W / 2, 0),
		BackgroundColor3 = t.Color,
		ZIndex = 6,
		Parent = jetHolder,
	}, { UIKit.corner(), UIKit.stroke(3), UIKit.gradient(t.Color:Lerp(Color3.new(1, 1, 1), 0.35), dark) })
	UIKit.text({ Text = ROMAN[tier] or tostring(tier), Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(3, 2), ZIndex = 7, Parent = badge })
	local size = math.floor(48 + 18 * k)
	local icon = UIKit.icon("Jetpack", { Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, 30 + h - size * 0.35), ZIndex = 8, Parent = jetHolder })
	if tier >= 5 then
		UIKit.float(icon, 2 + k * 2, 4, 2.2)
	end
	UIKit.popIn(back)
end
local shownTier = 0
local function refreshJetGauge()
	local tier = (player:GetAttribute("JetTier") or 1) :: number
	if tier ~= shownTier then
		local upgraded = shownTier > 0 and tier > shownTier
		shownTier = tier
		buildJetGauge(tier)
		if upgraded then
			UIKit.burst(jetHolder, UDim2.fromScale(0.5, 0.5), Config.Jetpack.Tiers[tier].Color)
		end
	end
end
refreshJetGauge()
player:GetAttributeChangedSignal("JetTier"):Connect(refreshJetGauge)

-- CHUTE DANS LE VIDE : l'écran devient noir, « LOST IN THE VOID », puis on réapparaît à la base
local voidScreen = new("Frame", { Name = "Void", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 50, Parent = gui })
local voidText = UIKit.text({
	Text = "LOST IN THE VOID",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(700, 80),
	TextColor3 = Color3.fromRGB(255, 90, 110),
	TextTransparency = 1,
	ZIndex = 51,
	Parent = voidScreen,
})
local function watchVoid(character: Model)
	voidScreen.Visible = false
	voidScreen.BackgroundTransparency = 1
	voidText.TextTransparency = 1
	character:GetAttributeChangedSignal("VoidDead"):Connect(function()
		if character:GetAttribute("VoidDead") then
			voidScreen.Visible = true
			TweenService:Create(voidScreen, TweenInfo.new(0.8), { BackgroundTransparency = 0.15 }):Play()
			TweenService:Create(voidText, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()
		end
	end)
end
if player.Character then
	watchVoid(player.Character)
end
player.CharacterAdded:Connect(watchVoid)

-- AIDE (en bas au centre, en attendant le guide de la première minute) -------------------
UIKit.text({
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(0.6, 0, 0, 26),
	Position = UDim2.new(0.5, 0, 1, -12),
	Text = "{Mouse} Hold click on an asteroid to drill   ·   Hold jump to fly, steer to glide",
	TextColor3 = Color3.fromRGB(230, 235, 255),
	Stroke = 2,
	Parent = gui,
})

-- MISE À JOUR ---------------------------------------------------------------
player.AttributeChanged:Connect(function(name)
	if name == "Credits" or name == "Income" then
		refreshMoney()
		refreshBadges()
	elseif name == "JetLevel" or name == "JetXP" or name == "JetXPNeed" then
		refreshSpeed()
	elseif name == "Cargo" or name == "CargoMax" or name == "CargoRarities" then
		refreshCargo()
	elseif name == "StarterBought" or name == "StarterEnds" then
		refreshBadges()
	end
end)
refreshMoney()
refreshSpeed()
refreshCargo()
refreshBadges()

RunService.RenderStepped:Connect(function()
	local fuel = math.clamp(player:GetAttribute("Fuel") or 1, 0, 1)
	fuelFill.Size = UDim2.fromScale(1, fuel)
	-- presque vide : la jauge clignote en rouge
	lowFlash.BackgroundTransparency = if fuel < 0.25 then 0.45 + 0.35 * math.sin(os.clock() * 14) else 1
	-- Le bruit n'apparaît que lorsque le serveur le publie
	local noise = player:GetAttribute("Noise")
	noiseGauge.Visible = noise ~= nil
	if noise then
		noiseFill.Size = UDim2.fromScale(1, math.clamp(noise, 0, 1))
	end
end)
