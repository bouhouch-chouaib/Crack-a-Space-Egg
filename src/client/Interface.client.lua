-- Interface du MVP encore à refaire dans le style du kit (UIKit) : fenêtre d'améliorations, révélation
-- de la casse, annonces serveur et barre de vie de l'astéroïde visé. Le HUD est dans Hud.client.lua.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("Theme"))

local player = Players.LocalPlayer

local INK = Color3.fromRGB(235, 238, 248)
local MUTED = Color3.fromRGB(150, 158, 185)
local PANEL = Color3.fromRGB(22, 26, 46)
local ACCENT = Color3.fromRGB(233, 131, 74)
local GOOD = Color3.fromRGB(90, 210, 130)

local function new(class: string, props: { [string]: any }, children: { Instance }?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(o :: any)[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if props.Parent then
		o.Parent = props.Parent
	end
	return o
end

local function corner(r: number)
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function label(props)
	local base = {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextColor3 = INK,
		TextScaled = true,
	}
	for k, v in pairs(props) do
		if k ~= "MaxText" then
			base[k] = v
		end
	end
	return new("TextLabel", base, { new("UITextSizeConstraint", { MaxTextSize = props.MaxText or 28 }) })
end

local gui = new("ScreenGui", {
	Name = "HUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- MESSAGES ------------------------------------------------------------------
local function notice(text: string, kind: string?)
	UIKit.toast(text, kind)
end
Remotes.Notice.OnClientEvent:Connect(notice)

Remotes.Announcement.OnClientEvent:Connect(function(who: string, crystal: string, rarity: number)
	local r = Config.Rarities[rarity]
	local banner = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.7, 0, 0, 46),
		Position = UDim2.new(0.5, 0, 0, 120),
		BackgroundColor3 = r.Color,
		Parent = gui,
	}, { corner(12) })
	label({
		Size = UDim2.new(1, -20, 1, -12),
		Position = UDim2.fromOffset(10, 6),
		Text = string.format("%s just cracked a %s %s!", who, r.Name:upper(), crystal),
		TextColor3 = Color3.new(0.05, 0.05, 0.1),
		FontFace = Theme.Font,
		Parent = banner,
	})
	task.delay(5, function()
		banner:Destroy()
	end)
end)

-- Barre de vie de l'astéroïde visé
local hpGui = new("BillboardGui", {
	Size = UDim2.fromOffset(120, 14),
	StudsOffsetWorldSpace = Vector3.new(0, 14, 0),
	AlwaysOnTop = true,
	Enabled = false,
	Parent = gui,
})
local hpBack = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = PANEL, Parent = hpGui }, { corner(6) })
local hpFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ACCENT, Parent = hpBack }, { corner(6) })
local targetValue = player:WaitForChild("DrillTarget", 10) :: ObjectValue?

RunService.RenderStepped:Connect(function()
	local t = targetValue and targetValue.Value :: BasePart?
	if t and t.Parent then
		hpGui.Adornee = t
		hpGui.StudsOffsetWorldSpace = Vector3.new(0, t.Size.Y / 2 + 3, 0)
		hpGui.Enabled = true
		hpFill.Size = UDim2.fromScale(math.clamp((t:GetAttribute("HP") or 0) / (t:GetAttribute("MaxHP") or 1), 0, 1), 1)
	else
		hpGui.Enabled = false
	end
end)

-- BOUTIQUE ------------------------------------------------------------------
local shop = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(460, 420),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = PANEL,
	Visible = false,
	Parent = gui,
}, { corner(16), new("UISizeConstraint", { MaxSize = Vector2.new(460, 420) }) })
label({ Size = UDim2.new(1, -60, 0, 36), Position = UDim2.fromOffset(18, 12), Text = "UPGRADES", FontFace = Theme.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
local close = new("TextButton", {
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.new(1, -48, 0, 12),
	Text = "X",
	FontFace = Theme.Font,
	TextScaled = true,
	TextColor3 = INK,
	BackgroundColor3 = Color3.fromRGB(50, 56, 86),
	Parent = shop,
}, { corner(10) })
close.MouseButton1Click:Connect(function()
	shop.Visible = false
end)
local list = new("Frame", {
	Size = UDim2.new(1, -36, 1, -64),
	Position = UDim2.fromOffset(18, 56),
	BackgroundTransparency = 1,
	Parent = shop,
}, { new("UIListLayout", { Padding = UDim.new(0, 8) }) })

local EFFECTS = {
	Drill = function(l)
		return string.format("Power %.1f", Config.DrillPower(l))
	end,
	Cargo = function(l)
		return string.format("%d eggs", Config.CargoSlots(l))
	end,
	Thruster = function(l)
		return string.format("Speed x%.2f", Config.Speed(l))
	end,
	Scanner = function(l)
		return string.format("Luck x%.2f", Config.Luck(l))
	end,
}

local rows = {}
local function row(title: string, onBuy: () -> ())
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = Color3.fromRGB(34, 40, 66), Parent = list }, { corner(10) })
	local t = label({ Size = UDim2.new(0.6, -12, 0, 24), Position = UDim2.fromOffset(12, 5), Text = title, TextXAlignment = Enum.TextXAlignment.Left, MaxText = 20, Parent = f })
	local sub = label({ Size = UDim2.new(0.6, -12, 0, 18), Position = UDim2.fromOffset(12, 29), Text = "", TextColor3 = MUTED, FontFace = Theme.Font, TextXAlignment = Enum.TextXAlignment.Left, MaxText = 14, Parent = f })
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0.38, 0, 0, 38),
		Position = UDim2.new(1, -8, 0.5, 0),
		Text = "",
		FontFace = Theme.Font,
		TextScaled = true,
		TextColor3 = Color3.new(0.08, 0.06, 0.04),
		BackgroundColor3 = ACCENT,
		Parent = f,
	}, { corner(8), new("UITextSizeConstraint", { MaxTextSize = 18 }) })
	b.MouseButton1Click:Connect(onBuy)
	return { Title = t, Sub = sub, Button = b }
end

for _, id in ipairs(Config.UpgradeOrder) do
	rows[id] = row(Config.Upgrades[id].Name, function()
		Remotes.BuyUpgrade:FireServer(id)
	end)
end
local ringRow = row("Next ring", function()
	Remotes.UnlockRing:FireServer((player:GetAttribute("Ring") or 1) + 1)
end)

local function refreshShop()
	local credits = player:GetAttribute("Credits") or 0
	for _, id in ipairs(Config.UpgradeOrder) do
		local l = player:GetAttribute("Lvl_" .. id) or 0
		local r = rows[id]
		r.Title.Text = string.format("%s  Lv %d", Config.Upgrades[id].Name, l)
		if l >= Config.Upgrades[id].Max then
			r.Sub.Text = EFFECTS[id](l)
			r.Button.Text = "MAX"
			r.Button.AutoButtonColor = false
		else
			local cost = Config.UpgradeCost(id, l)
			r.Sub.Text = EFFECTS[id](l) .. "  →  " .. EFFECTS[id](l + 1)
			r.Button.Text = "◆ " .. Format.Short(cost)
			r.Button.BackgroundColor3 = if credits >= cost then ACCENT else Color3.fromRGB(80, 84, 104)
		end
	end
	local nextIndex = (player:GetAttribute("Ring") or 1) + 1
	local nextRing = Config.Rings[nextIndex]
	if nextRing then
		local drill = player:GetAttribute("Lvl_Drill") or 0
		ringRow.Title.Text = "Unlock " .. nextRing.Name
		ringRow.Sub.Text = string.format("Needs Drill Lv %d · values x%d", nextRing.DrillLevel, nextRing.ValueMult)
		ringRow.Button.Text = "◆ " .. Format.Short(nextRing.UnlockCost)
		local ok = credits >= nextRing.UnlockCost and drill >= nextRing.DrillLevel
		ringRow.Button.BackgroundColor3 = if ok then GOOD else Color3.fromRGB(80, 84, 104)
	else
		ringRow.Title.Text = "All rings unlocked"
		ringRow.Sub.Text = "More rings in the next update"
		ringRow.Button.Text = "-"
	end
end
player.AttributeChanged:Connect(function(name)
	if shop.Visible and name ~= "Fuel" then
		refreshShop()
	end
end)

local function openShop()
	refreshShop()
	shop.Visible = true
end
Remotes.OpenShop.OnClientEvent:Connect(openShop)

-- Le bouton SHOP du HUD ouvre et ferme la fenêtre (en attendant la boutique complète)
UIKit.Open.Event:Connect(function(what: string)
	if what == "Shop" then
		if shop.Visible then
			shop.Visible = false
		else
			openShop()
		end
	end
end)

-- RÉVÉLATION DES GÉODES ------------------------------------------------------------------
local reveal = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
})
-- Titre, cartes et total empilés et centrés, pour ne jamais se chevaucher sur un petit écran
local stack = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromScale(0.94, 0.9),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = reveal,
}, {
	new("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local big = label({
	Size = UDim2.new(1, 0, 0, 56),
	LayoutOrder = 1,
	Text = "",
	FontFace = Theme.Font,
	MaxText = 44,
	ZIndex = 11,
	Parent = stack,
})
local cards = new("Frame", {
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 2,
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = stack,
}, {
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(120, 130),
		CellPadding = UDim2.fromOffset(8, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local totalText = label({
	Size = UDim2.new(1, 0, 0, 40),
	LayoutOrder = 3,
	Text = "",
	TextColor3 = Color3.fromRGB(255, 210, 110),
	FontFace = Theme.Font,
	MaxText = 32,
	ZIndex = 11,
	Parent = stack,
})

local function card(g, order: number)
	local r = Config.Rarities[g.Rarity]
	local c = new("Frame", { BackgroundColor3 = PANEL, LayoutOrder = order, ZIndex = 10, Parent = cards }, {
		corner(12),
		new("UIStroke", { Color = r.Color, Thickness = if g.Rarity >= 5 then 4 else 2 }),
	})
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(0.5, 0, 0, 10),
		Rotation = 45,
		BackgroundColor3 = r.Color,
		ZIndex = 11,
		Parent = c,
	}, { corner(6) })
	local tags = {}
	if g.Size ~= "" then
		table.insert(tags, g.Size)
	end
	if g.Shiny then
		table.insert(tags, "Shiny")
	end
	label({ Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 66), Text = g.Name, MaxText = 15, ZIndex = 11, Parent = c })
	label({ Size = UDim2.new(1, -10, 0, 14), Position = UDim2.fromOffset(5, 85), Text = r.Name .. (if #tags > 0 then " · " .. table.concat(tags, " ") else ""), TextColor3 = r.Color, MaxText = 12, ZIndex = 11, Parent = c })
	label({ Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 104), Text = "+◆ " .. Format.Short(g.Value), TextColor3 = Color3.fromRGB(255, 210, 110), MaxText = 15, ZIndex = 11, Parent = c })
	c.Size = UDim2.fromOffset(120, 130)
	return c
end

local revealing = false
Remotes.CrackResult.OnClientEvent:Connect(function(results, total: number)
	if revealing then
		return
	end
	revealing = true
	shop.Visible = false
	for _, child in ipairs(cards:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	-- Les plus rares en dernier : on garde le meilleur pour la fin
	table.sort(results, function(a, b)
		return a.Rarity < b.Rarity
	end)
	big.Text = "CRACKING..."
	big.TextColor3 = INK
	totalText.Text = ""
	reveal.Visible = true
	local shown = math.min(#results, 12)
	local skip = #results - shown
	for i = skip + 1, #results do
		card(results[i], i)
		task.wait(if results[i].Rarity >= 5 then 0.8 else 0.18)
	end
	local best = results[#results]
	local r = Config.Rarities[best.Rarity]
	if best.Rarity >= 3 then
		big.Text = string.format("%s! %s — %s", r.Name:upper(), best.Name, Format.OneIn(best.Chance))
		big.TextColor3 = r.Color
	else
		big.Text = "CRACKED!"
		big.TextColor3 = INK
	end
	local grow = TweenService:Create(big, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 56) })
	big.Size = UDim2.new(0.6, 0, 0, 40)
	grow:Play()
	totalText.Text = string.format("+◆ %s credits%s", Format.Short(total), if skip > 0 then string.format("  (%d more eggs)", skip) else "")
	task.wait(if best.Rarity >= 5 then 3.5 else 2.2)
	reveal.Visible = false
	revealing = false
end)
