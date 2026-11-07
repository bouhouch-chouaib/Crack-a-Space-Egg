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
	{ "Shop", "SHOP", "Shop", "Green" },
	{ "Index", "INDEX", "Index", "Blue" },
}) do
	local button, badge = UIKit.menuButton({ name = b[1], text = b[2], art = b[3], color = b[4], parent = menu })
	button.Parent.LayoutOrder = i
	UIKit.popIn(button.Parent :: Frame, 0.08 * i)
	buttons[b[1]] = { button = button, badge = badge }
	button.MouseButton1Click:Connect(function()
		if b[1] == "Shop" then
			UIKit.Open:Fire("Shop")
		else
			UIKit.Open:Fire("Index")
		end
	end)
end

-- La pastille de SHOP s'allume quand une amélioration est à portée de bourse
local function refreshBadges()
	local credits = player:GetAttribute("Credits") or 0
	local affordable = false
	for id, u in pairs(Config.Upgrades) do
		local level = player:GetAttribute("Lvl_" .. id) or 0
		if level < u.Max and credits >= Config.UpgradeCost(id, level) then
			affordable = true
		end
	end
	local nextDrill = Config.Drills[(player:GetAttribute("Drill") or 1) + 1]
	if nextDrill and credits >= nextDrill.Cost then
		affordable = true
	end
	buttons.Shop.badge.Visible = affordable
end

-- SOUTE (en haut au centre) ---------------------------------------------------
local cargoGroup = group("Cargo", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 14), UDim2.fromOffset(240, 120))
local cargoPill, cargoText = UIKit.pill({ name = "CargoPill", art = "Egg", size = UDim2.fromOffset(200, 56), parent = cargoGroup })
cargoPill.Position = UDim2.fromOffset(28, 0)
local dots = new("Frame", {
	Name = "Dots",
	Size = UDim2.fromOffset(240, 18),
	Position = UDim2.fromOffset(0, 62),
	BackgroundTransparency = 1,
	Parent = cargoGroup,
}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4) }) })
local goHome = UIKit.text({
	Size = UDim2.fromOffset(240, 34),
	Position = UDim2.fromOffset(0, 84),
	Text = "{Home} GO HOME!",
	TextColor3 = Color3.fromRGB(255, 120, 110),
	Visible = false,
	Stroke = 3,
	Parent = cargoGroup,
})

local lastCargo = -1
local function refreshCargo()
	local cargo = player:GetAttribute("Cargo") or 0
	local max = player:GetAttribute("CargoMax") or 1
	cargoText.Text = string.format("%d/%d", cargo, max)
	local full = cargo >= max
	local grad = cargoPill:FindFirstChildOfClass("UIGradient")
	if grad then
		local c = if full then UIKit.Colors.Red else UIKit.Colors.Dark
		grad.Color = ColorSequence.new(c[1], c[2])
	end
	goHome.Visible = full
	if cargo ~= lastCargo then
		UIKit.bump(cargoPill, 0.1)
		if full then
			UIKit.shake(cargoPill)
		end
		lastCargo = cargo
	end
	-- Une pastille par œuf, de la couleur de sa rareté
	for _, d in ipairs(dots:GetChildren()) do
		if d:IsA("Frame") then
			d:Destroy()
		end
	end
	local list = string.split(player:GetAttribute("CargoRarities") or "", ",")
	for _, r in ipairs(list) do
		local rarity = Config.Rarities[tonumber(r) or 0]
		if rarity then
			new("Frame", { Size = UDim2.fromOffset(14, 18), BackgroundColor3 = rarity.Color, Parent = dots }, { UIKit.corner(7), UIKit.stroke(2) })
		end
	end
end

-- EN HAUT À DROITE : événement + réglages -----------------------------------------
local topRight = group("TopRight", Vector2.new(1, 0), UDim2.new(1, -18, 0, 14), UDim2.fromOffset(260, 60))
local eventPill, eventText = UIKit.pill({ name = "EventPill", art = "Comet", size = UDim2.fromOffset(170, 52), parent = topRight })
eventPill.Position = UDim2.fromOffset(16, 2)
local settings = UIKit.roundButton({ name = "Settings", art = "Settings", size = 56, parent = topRight })
settings.Position = UDim2.fromOffset(202, 0)
settings.MouseButton1Click:Connect(function()
	UIKit.toast("Coming soon!", "info")
end)

-- POTIONS ACTIVES (sous l'horloge, en haut à droite) : icône qui flotte et temps restant ---------
local boostGroup = group("Boosts", Vector2.new(1, 0), UDim2.new(1, -18, 0, 84), UDim2.fromOffset(260, 84))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), Parent = boostGroup })
local boostCards: { [string]: { frame: Frame, time: TextLabel } } = {}
for i, potion in ipairs(Config.Shop.Potions) do
	if potion.Key ~= "Meteor" then
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
local gauges = group("Gauges", Vector2.new(1, 0.5), UDim2.new(1, -18, 0.5, 0), UDim2.fromOffset(160, 200))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), Parent = gauges })
local noiseGauge, noiseFill = UIKit.gauge({ name = "Noise", art = "Noise", color = "Purple", parent = gauges })
local _, fuelFill = UIKit.gauge({ name = "Jetpack", art = "Jetpack", color = "Orange", parent = gauges })

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
	elseif name == "Drill" or string.sub(name, 1, 4) == "Lvl_" then
		refreshBadges()
	end
end)
refreshMoney()
refreshSpeed()
refreshCargo()
refreshBadges()

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

RunService.RenderStepped:Connect(function()
	fuelFill.Size = UDim2.fromScale(1, math.clamp(player:GetAttribute("Fuel") or 1, 0, 1))
	-- Le bruit n'apparaît que lorsque le serveur le publie
	local noise = player:GetAttribute("Noise")
	noiseGauge.Visible = noise ~= nil
	if noise then
		noiseFill.Size = UDim2.fromScale(1, math.clamp(noise, 0, 1))
	end
	-- Minuteur de l'événement
	local now = workspace:GetServerTimeNow()
	if workspace:GetAttribute("EventActive") then
		eventText.Text = "NOW!"
		eventText.TextColor3 = Color3.fromRGB(255, 214, 90)
	else
		eventText.Text = clock((workspace:GetAttribute("EventStartsAt") or now) - now)
		eventText.TextColor3 = Color3.new(1, 1, 1)
	end
end)
