-- HUD permanent (docs/Interfaces.md §1), dans le style des jeux d'œufs :
-- argent en énorme, colonne de gros boutons à pastilles, soute, minuteur d'événement, jauges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- STATS (en bas à gauche) : l'oxygène max au-dessus, l'argent en énorme dessous -------------
local moneyGroup = group("Money", Vector2.new(0, 1), UDim2.new(0, 18, 1, -18), UDim2.fromOffset(420, 180))
local oxygenIcon = UIKit.icon("Oxygen", { Size = UDim2.fromOffset(72, 72), Position = UDim2.fromOffset(16, 0), ZIndex = 2, Parent = moneyGroup })
local oxygenText = UIKit.text({
	Size = UDim2.fromOffset(280, 50),
	Position = UDim2.fromOffset(104, 10),
	Text = "0s",
	TextColor3 = Color3.fromRGB(110, 235, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 3.5,
	Parent = moneyGroup,
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

-- Oxygène max (secondes), qui défile quand on s'entraîne
local shownOxygen = 0
local function oxygenLabel(n: number): string
	return Format.Short(n) .. "s O₂"
end
local function refreshOxygen()
	local o2 = player:GetAttribute("OxygenMax") or Config.Oxygen.Start
	if o2 ~= shownOxygen then
		if o2 > shownOxygen and shownOxygen > 0 then
			UIKit.flyText(moneyGroup, "+" .. oxygenLabel(o2 - shownOxygen), UDim2.fromOffset(110, 0), Color3.fromRGB(110, 235, 255))
			UIKit.bump(oxygenIcon, 0.2)
		end
		UIKit.countTo(oxygenText, shownOxygen, o2, oxygenLabel, 0.5)
		shownOxygen = o2
	end
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

-- DEUX GROS BOUTONS (à gauche) : la boutique (améliorations, passes, potions, récompenses…
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
			UIKit.toast("Coming soon!", "info")
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
	Text = "🏠 GO HOME!",
	TextColor3 = Color3.fromRGB(255, 120, 110),
	Visible = false,
	Stroke = 3,
	Parent = cargoGroup,
})

local lastCargo = -1
local function refreshCargo()
	local cargo = player:GetAttribute("Cargo") or 0
	local max = player:GetAttribute("CargoMax") or 4
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

-- JAUGES (bord droit) ---------------------------------------------------------
local gauges = group("Gauges", Vector2.new(1, 0.5), UDim2.new(1, -18, 0.5, 0), UDim2.fromOffset(160, 200))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), Parent = gauges })
local oxygenGauge, oxygenFill = UIKit.gauge({ name = "Oxygen", art = "Oxygen", color = "Teal", parent = gauges })
local noiseGauge, noiseFill = UIKit.gauge({ name = "Noise", art = "Noise", color = "Purple", parent = gauges })
local _, fuelFill = UIKit.gauge({ name = "Jetpack", art = "Jetpack", color = "Orange", parent = gauges })

-- AIDE (en bas au centre, en attendant le guide de la première minute) -------------------
UIKit.text({
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(0.6, 0, 0, 26),
	Position = UDim2.new(0.5, 0, 1, -12),
	Text = "🖱️ Hold click on an asteroid to drill   ·   ⬆️ Hold jump in the air to fly",
	TextColor3 = Color3.fromRGB(230, 235, 255),
	Stroke = 2,
	Parent = gui,
})

-- MISE À JOUR ---------------------------------------------------------------
player.AttributeChanged:Connect(function(name)
	if name == "Credits" or name == "Income" then
		refreshMoney()
		refreshBadges()
	elseif name == "OxygenMax" then
		refreshOxygen()
	elseif name == "Cargo" or name == "CargoMax" or name == "CargoRarities" then
		refreshCargo()
	elseif string.sub(name, 1, 4) == "Lvl_" then
		refreshBadges()
	end
end)
refreshMoney()
refreshOxygen()
refreshCargo()
refreshBadges()

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

RunService.RenderStepped:Connect(function()
	fuelFill.Size = UDim2.fromScale(1, math.clamp(player:GetAttribute("Fuel") or 1, 0, 1))
	-- Oxygène et bruit n'apparaissent que lorsque le serveur les publie
	local oxygen = player:GetAttribute("Oxygen")
	oxygenGauge.Visible = oxygen ~= nil
	if oxygen then
		oxygenFill.Size = UDim2.fromScale(1, math.clamp(oxygen, 0, 1))
	end
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
