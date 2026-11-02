-- Interface du MVP : HUD (crédits, soute, carburant), boutique d'améliorations, révélation des géodes,
-- messages et annonces serveur. Tout est construit par code (greybox), l'art viendra remplacer les styles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local INK = Color3.fromRGB(235, 238, 248)
local MUTED = Color3.fromRGB(150, 158, 185)
local PANEL = Color3.fromRGB(22, 26, 46)
local ACCENT = Color3.fromRGB(233, 131, 74)
local GOOD = Color3.fromRGB(90, 210, 130)
local BAD = Color3.fromRGB(240, 100, 100)

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
		Font = Enum.Font.GothamBold,
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

-- CRÉDITS ------------------------------------------------------------------
local creditsBox = new("Frame", {
	Size = UDim2.fromOffset(200, 48),
	Position = UDim2.fromOffset(16, 16),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(12) })
local creditsText = label({
	Size = UDim2.new(1, -20, 1, -12),
	Position = UDim2.fromOffset(10, 6),
	Text = "0",
	TextColor3 = Color3.fromRGB(255, 210, 110),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = creditsBox,
})

-- SOUTE ------------------------------------------------------------------
local cargoBox = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(260, 44),
	Position = UDim2.new(0.5, 0, 0, 16),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(12) })
local cargoFill = new("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = ACCENT,
	BackgroundTransparency = 0.25,
	Parent = cargoBox,
}, { corner(12) })
local cargoText = label({
	Size = UDim2.new(1, -16, 1, -14),
	Position = UDim2.fromOffset(8, 7),
	Text = "Cargo 0/4",
	ZIndex = 2,
	Parent = cargoBox,
})
local ringText = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(260, 20),
	Position = UDim2.new(0.5, 0, 0, 64),
	Text = "",
	TextColor3 = MUTED,
	Font = Enum.Font.GothamMedium,
	MaxText = 16,
	Parent = gui,
})

-- CARBURANT ------------------------------------------------------------------
local fuelBox = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Size = UDim2.fromOffset(16, 160),
	Position = UDim2.new(0, 16, 0.5, 0),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(8) })
local fuelFill = new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(110, 190, 255),
	Parent = fuelBox,
}, { corner(8) })
label({
	AnchorPoint = Vector2.new(0, 0),
	Size = UDim2.fromOffset(60, 16),
	Position = UDim2.new(0, 10, 0.5, 86),
	Text = "JETPACK",
	TextColor3 = MUTED,
	MaxText = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = gui,
})

-- AIDE ------------------------------------------------------------------
local hint = label({
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(0.9, 0, 0, 22),
	Position = UDim2.new(0.5, 0, 1, -14),
	Text = "Hold click on an asteroid to drill  ·  Hold Jump in the air to use your jetpack",
	TextColor3 = MUTED,
	Font = Enum.Font.GothamMedium,
	MaxText = 16,
	Parent = gui,
})

-- MESSAGES ------------------------------------------------------------------
local noticeStack = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(420, 200),
	Position = UDim2.new(0.5, 0, 0, 92),
	BackgroundTransparency = 1,
	Parent = gui,
}, { new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

local function notice(text: string, kind: string?)
	local color = if kind == "good" then GOOD elseif kind == "bad" or kind == "warn" then BAD else INK
	local box = new("Frame", {
		Size = UDim2.fromOffset(420, 36),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.1,
		Parent = noticeStack,
	}, { corner(10) })
	label({ Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), Text = text, TextColor3 = color, MaxText = 18, Parent = box })
	task.delay(3, function()
		box:Destroy()
	end)
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
		Font = Enum.Font.GothamBlack,
		Parent = banner,
	})
	task.delay(5, function()
		banner:Destroy()
	end)
end)

-- HUD : mise à jour depuis les attributs du joueur --------------------------------
local function refresh()
	creditsText.Text = "◆ " .. Format.Short(player:GetAttribute("Credits") or 0)
	local cargo = player:GetAttribute("Cargo") or 0
	local max = player:GetAttribute("CargoMax") or 4
	cargoText.Text = string.format("Cargo %d/%d", cargo, max)
	cargoFill.Size = UDim2.fromScale(math.clamp(cargo / max, 0, 1), 1)
	cargoFill.BackgroundColor3 = if cargo >= max then BAD else ACCENT
	local ring = Config.Rings[player:GetAttribute("Ring") or 1]
	ringText.Text = "Unlocked up to: " .. (ring and ring.Name or "?")
	hint.Text = if cargo >= max
		then "Cargo full! Fly back to the station and crack your geodes"
		else "Hold click on an asteroid to drill  ·  Hold Jump in the air to use your jetpack"
end
player.AttributeChanged:Connect(function(name)
	if name ~= "Fuel" then
		refresh()
	end
end)
refresh()

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
	fuelFill.Size = UDim2.fromScale(1, player:GetAttribute("Fuel") or 1)
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
label({ Size = UDim2.new(1, -60, 0, 36), Position = UDim2.fromOffset(18, 12), Text = "UPGRADES", Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Parent = shop })
local close = new("TextButton", {
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.new(1, -48, 0, 12),
	Text = "X",
	Font = Enum.Font.GothamBlack,
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
		return string.format("%d geodes", Config.CargoSlots(l))
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
	local sub = label({ Size = UDim2.new(0.6, -12, 0, 18), Position = UDim2.fromOffset(12, 29), Text = "", TextColor3 = MUTED, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, MaxText = 14, Parent = f })
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0.38, 0, 0, 38),
		Position = UDim2.new(1, -8, 0.5, 0),
		Font = Enum.Font.GothamBlack,
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

local shopButton = new("TextButton", {
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(150, 48),
	Position = UDim2.new(1, -16, 1, -48),
	Text = "UPGRADES",
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextColor3 = Color3.new(0.08, 0.06, 0.04),
	BackgroundColor3 = ACCENT,
	Parent = gui,
}, { corner(12), new("UITextSizeConstraint", { MaxTextSize = 20 }) })
shopButton.MouseButton1Click:Connect(function()
	if shop.Visible then
		shop.Visible = false
	else
		openShop()
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
local cards = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.9, 0, 0, 280),
	Position = UDim2.fromScale(0.5, 0.45),
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = reveal,
}, {
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(120, 130),
		CellPadding = UDim2.fromOffset(8, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local big = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.9, 0, 0, 70),
	Position = UDim2.fromScale(0.5, 0.16),
	Text = "",
	Font = Enum.Font.GothamBlack,
	MaxText = 48,
	ZIndex = 11,
	Parent = reveal,
})
local totalText = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.9, 0, 0, 40),
	Position = UDim2.fromScale(0.5, 0.82),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 210, 110),
	Font = Enum.Font.GothamBlack,
	MaxText = 32,
	ZIndex = 11,
	Parent = reveal,
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
	local grow = TweenService:Create(big, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0.95, 0, 0, 84) })
	big.Size = UDim2.new(0.6, 0, 0, 50)
	grow:Play()
	totalText.Text = string.format("+◆ %s credits%s", Format.Short(total), if skip > 0 then string.format("  (%d more geodes)", skip) else "")
	task.wait(if best.Rarity >= 5 then 3.5 else 2.2)
	reveal.Visible = false
	revealing = false
end)
