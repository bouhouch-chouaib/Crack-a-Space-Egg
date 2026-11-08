-- Fenêtre MACHINE UPGRADES (invite « Upgrade » de la machine ou panneau de première fois).
-- En haut : niveau total de la machine, son palier de couleur et ce qu'il reste pour le suivant.
-- Trois cartes : Moteur (vitesse), Cœur chanceux (+1 rareté), Polisseuse (valeur des minerais).
-- Le serveur décide de tout (MachineService, Remotes.Machine).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new
local M = Config.Machine

local W_SIZE = Vector2.new(980, 620)
local GAP = 14
local CARD_W = math.floor((W_SIZE.X - GAP * 4) / 3)
local CARD_H = 408

local win = UIKit.window({ name = "MachineUp", title = "{MachineUp} MACHINE UPGRADES", color = "Orange", size = W_SIZE })
win.body.Visible = false

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?, align: Enum.TextXAlignment?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextXAlignment = align or Enum.TextXAlignment.Center,
		ZIndex = 5,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

local function level(key: string): number
	return (player:GetAttribute("Mach_" .. key) or 0) :: number
end

local function total(): number
	local n = 0
	for _, key in ipairs(M.Order) do
		n += level(key)
	end
	return n
end

-- BANDEAU : niveau total et palier ---------------------------------------------------------------
local top = new("Frame", { Name = "Top", Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, 86), Position = UDim2.fromOffset(GAP, 94), BackgroundColor3 = Color3.fromRGB(26, 28, 40), BackgroundTransparency = 0.15, ZIndex = 2, Parent = win.frame }, { UIKit.corner(14) })
local topGlow = UIKit.glow(top, { size = 130, position = UDim2.fromOffset(48, 43), transparency = 0.35, z = 3, pulse = 0.08 })
UIKit.icon("MachineUp", { Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(10, 4), ZIndex = 4, Parent = top })
local tierName = label(top, "", 98, 8, 420, 38, 32, nil, Enum.TextXAlignment.Left)
local tierNext = label(top, "", 98, 46, 420, 28, 21, Color3.fromRGB(215, 220, 240), Enum.TextXAlignment.Left)
local barBack = new("Frame", { Size = UDim2.fromOffset(360, 30), Position = UDim2.new(1, -378, 0, 28), BackgroundColor3 = Color3.fromRGB(18, 20, 32), ZIndex = 4, Parent = top }, { UIKit.corner(), UIKit.stroke(3) })
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = barBack }, { UIKit.corner() })
local barGrad = UIKit.gradient(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
barGrad.Parent = barFill
local barText = label(barBack, "", 6, 2, 348, 26, 22)
barText.ZIndex = 7

-- CARTES ------------------------------------------------------------------------------------------
type Card = { key: string, levelText: TextLabel, now: TextLabel, nxt: TextLabel, pips: { Frame }, button: TextButton, text: TextLabel, grad: UIGradient }
local cards: { Card } = {}
local busy = false
local refresh: () -> ()

local function buy(key: string, card: Frame)
	if busy then
		return
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Machine"):InvokeServer("buy", key)
	end)
	busy = false
	if ok and type(res) == "table" and res.ok then
		Sfx.Play("Buy")
		UIKit.bump(card, 0.05)
		UIKit.burst(card, UDim2.fromOffset(CARD_W / 2, 90), M.Tracks[key].Color)
		refresh()
	else
		Sfx.Play("Error")
		UIKit.toast(if ok and type(res) == "table" and res.error then res.error else "Try again", "warn")
	end
end

for i, key in ipairs(M.Order) do
	local track = M.Tracks[key]
	local c = new("Frame", {
		Name = key,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		Position = UDim2.fromOffset(GAP + (i - 1) * (CARD_W + GAP), 192),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = win.frame,
	}, { UIKit.corner(16), UIKit.gradient(track.Color:Lerp(Color3.fromRGB(40, 42, 54), 0.55), Color3.fromRGB(28, 30, 42)) })
	UIKit.stroke(4, track.Color:Lerp(Color3.new(0, 0, 0), 0.25)).Parent = c
	UIKit.studs(c, 0.7, "Studs", 24)
	local fx = new("Frame", { Size = UDim2.fromOffset(150, 130), Position = UDim2.new(0.5, -75, 0, 8), BackgroundTransparency = 1, ZIndex = 3, Parent = c })
	UIKit.rays(fx, { color = track.Color, size = 190, speed = 22, transparency = 0.55, z = 3 })
	local ic = UIKit.icon(track.Art, { Size = UDim2.fromOffset(120, 120), Position = UDim2.new(0.5, -60, 0, 12), ZIndex = 4, Parent = c })
	UIKit.float(ic, 3, 4, 2, i)
	label(c, track.Name:upper(), 8, 136, CARD_W - 16, 36, 30)
	label(c, track.Text, 12, 172, CARD_W - 24, 26, 20, Color3.fromRGB(225, 228, 245))
	local levelText = label(c, "", 8, 202, CARD_W - 16, 26, 22, track.Color:Lerp(Color3.new(1, 1, 1), 0.4))
	-- rangée de plots : un par niveau
	local row = new("Frame", { Size = UDim2.fromOffset(M.Max * 13, 12), Position = UDim2.new(0.5, -M.Max * 13 / 2, 0, 232), BackgroundTransparency = 1, ZIndex = 4, Parent = c })
	local pips = {}
	for p = 1, M.Max do
		pips[p] = new("Frame", { Size = UDim2.fromOffset(11, 12), Position = UDim2.fromOffset((p - 1) * 13, 0), BackgroundColor3 = Color3.fromRGB(50, 54, 72), ZIndex = 4, Parent = row }, { UIKit.corner(3) })
	end
	-- effet : maintenant -> prochain niveau
	local box = new("Frame", { Size = UDim2.new(1, -24, 0, 70), Position = UDim2.fromOffset(12, 254), BackgroundColor3 = Color3.fromRGB(18, 20, 32), BackgroundTransparency = 0.25, ZIndex = 3, Parent = c }, { UIKit.corner(12) })
	local boxW = CARD_W - 24
	local now = label(box, "", 8, 12, boxW / 2 - 34, 46, 34, Color3.fromRGB(210, 212, 228))
	UIKit.icon("ArrowUp", { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0.5, -22, 0, 13), Rotation = 90, ZIndex = 6, Parent = box })
	local nxt = label(box, "", boxW / 2 + 26, 10, boxW / 2 - 34, 50, 38, UIKit.Money)
	local button, text, grad = UIKit.priceButton({ parent = c, text = "", size = UDim2.new(1, -24, 0, 60), position = UDim2.new(0, 12, 1, -72) })
	button.Name = "Buy"
	if i == 1 then
		button:SetAttribute("PadFirst", true)
	end
	button.MouseButton1Click:Connect(function()
		buy(key, c)
	end)
	cards[i] = { key = key, levelText = levelText, now = now, nxt = nxt, pips = pips, button = button, text = text, grad = grad }
end

refresh = function()
	local credits = (player:GetAttribute("Credits") or 0) :: number
	for _, card in ipairs(cards) do
		local key = card.key
		local track = M.Tracks[key]
		local lvl = level(key)
		card.levelText.Text = ("Level %d / %d"):format(lvl, M.Max)
		for p, pip in ipairs(card.pips) do
			pip.BackgroundColor3 = if p <= lvl then track.Color else Color3.fromRGB(50, 54, 72)
		end
		card.now.Text = Config.MachineEffect(key, lvl)
		if lvl >= M.Max then
			card.nxt.Text = "MAX"
			card.text.Text = "MAXED"
			UIKit.recolor(card.grad, "Gold")
		else
			local cost = Config.MachineCost(key, lvl)
			card.nxt.Text = Config.MachineEffect(key, lvl + 1)
			card.text.Text = "$" .. Format.Short(cost)
			UIKit.recolor(card.grad, if credits >= cost then "Green" else "Grey")
		end
	end
	local n = total()
	local tier, nextTier = Config.MachineTier(n)
	tierName.Text = ("Level %d · %s"):format(n, tier.Name)
	tierName.TextColor3 = tier.Accent
	topGlow.ImageColor3 = tier.Accent
	if nextTier then
		tierNext.Text = ("Next look: %s"):format(nextTier.Name)
		local span = nextTier.Min - tier.Min
		barFill.Size = UDim2.fromScale(math.clamp((n - tier.Min) / span, 0, 1), 1)
		barText.Text = ("%d / %d"):format(n, nextTier.Min)
		barGrad.Color = ColorSequence.new(nextTier.Accent:Lerp(Color3.new(1, 1, 1), 0.3), nextTier.Accent)
	else
		tierNext.Text = "Fully upgraded!"
		barFill.Size = UDim2.fromScale(1, 1)
		barText.Text = "MAX"
		barGrad.Color = ColorSequence.new(tier.Accent:Lerp(Color3.new(1, 1, 1), 0.3), tier.Accent)
	end
end

player.AttributeChanged:Connect(function(name)
	if win.isOpen() and (name == "Credits" or string.sub(name, 1, 5) == "Mach_") then
		refresh()
	end
end)

UIKit.Open.Event:Connect(function(what: string)
	if what == "MachineUp" then
		win.open(refresh)
	elseif what == "Close" then
		win.close()
	end
end)
