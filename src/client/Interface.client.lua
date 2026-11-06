-- Interface du MVP encore à refaire dans le style du kit (UIKit) : fenêtre d'améliorations, révélation
-- de la casse, annonces serveur et barre de vie de l'astéroïde visé. Le HUD est dans Hud.client.lua.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("Theme"))

local player = Players.LocalPlayer

local INK = Color3.fromRGB(235, 238, 248)
local PANEL = Color3.fromRGB(22, 26, 46)

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

-- La barre de vie de la roche visée est dans Impact.client.lua

-- La boutique est dans Shop.client.lua

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
	UIKit.Open:Fire("Close")
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
