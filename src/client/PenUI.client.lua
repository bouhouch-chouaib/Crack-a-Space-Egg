-- Fenêtre BIGGER BASE : s'ouvre en marchant sur le bouton rouge dans son enclos (ShipShops.client).
-- Niveau de l'enclos, places actuelles -> places au niveau suivant, prix. Le serveur décide (PenService,
-- Remotes.PenUp) ; à l'achat l'enclos s'agrandit sous les yeux du joueur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new
local LEVELS = Config.Pen.Levels
local GREEN = Color3.fromRGB(150, 240, 110)

local W_SIZE = Vector2.new(660, 500)
local win = UIKit.window({ name = "PenUp", title = "{Home} BIGGER BASE", color = "Green", size = W_SIZE })
win.body.Visible = false

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		ZIndex = 5,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

local fx = new("Frame", { Size = UDim2.fromOffset(170, 150), Position = UDim2.new(0.5, -85, 0, 92), BackgroundTransparency = 1, ZIndex = 3, Parent = win.frame })
UIKit.rays(fx, { color = GREEN, size = 210, speed = 24, transparency = 0.5, z = 3 })
local icon = UIKit.icon("Home", { Size = UDim2.fromOffset(136, 136), Position = UDim2.new(0.5, -68, 0, 98), ZIndex = 4, Parent = win.frame })
UIKit.float(icon, 3, 4, 2)

local title = label(win.frame, "", 20, 238, W_SIZE.X - 40, 42, 36, GREEN)
local pipsRow = new("Frame", { Size = UDim2.fromOffset(#LEVELS * 40, 16), Position = UDim2.new(0.5, -#LEVELS * 20, 0, 284), BackgroundTransparency = 1, ZIndex = 4, Parent = win.frame })
local pips: { Frame } = {}
for i = 1, #LEVELS do
	pips[i] = new("Frame", { Size = UDim2.fromOffset(34, 14), Position = UDim2.fromOffset((i - 1) * 40 + 3, 1), BackgroundColor3 = Color3.fromRGB(50, 54, 72), ZIndex = 4, Parent = pipsRow }, { UIKit.corner(4) })
end

local box = new("Frame", { Size = UDim2.fromOffset(W_SIZE.X - 80, 76), Position = UDim2.fromOffset(40, 312), BackgroundColor3 = Color3.fromRGB(18, 20, 32), BackgroundTransparency = 0.25, ZIndex = 3, Parent = win.frame }, { UIKit.corner(12) })
local BOX_W = W_SIZE.X - 80
local now = label(box, "", 12, 14, BOX_W / 2 - 50, 48, 32, Color3.fromRGB(210, 212, 228))
UIKit.icon("ArrowUp", { Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0.5, -23, 0, 15), Rotation = 90, ZIndex = 6, Parent = box })
local nxt = label(box, "", BOX_W / 2 + 38, 12, BOX_W / 2 - 50, 52, 36, UIKit.Money)

local button, text, grad = UIKit.priceButton({ parent = win.frame, text = "", size = UDim2.fromOffset(340, 70), position = UDim2.new(0.5, -170, 0, 408) })
button.Name = "Buy"
button:SetAttribute("PadFirst", true)
text.TextSize = 34

local function level(): number
	return math.clamp((player:GetAttribute("PenLevel") or 1) :: number, 1, #LEVELS)
end

local function refresh()
	local lv = level()
	local cur, nextDef = LEVELS[lv], LEVELS[lv + 1]
	-- places réelles (passe +5 compris) ; au niveau suivant : la différence entre les deux niveaux en plus
	local slots = (player:GetAttribute("BaseSlots") or (Config.Hatch.Slots + cur.Slots)) :: number
	title.Text = ("Level %d"):format(lv)
	for i, p in ipairs(pips) do
		p.BackgroundColor3 = if i <= lv then GREEN else Color3.fromRGB(50, 54, 72)
	end
	now.Text = ("%d slots"):format(slots)
	if nextDef then
		nxt.Text = ("%d slots"):format(slots + nextDef.Slots - cur.Slots)
		text.Text = "UPGRADE $" .. Format.Short(nextDef.Cost)
		UIKit.recolor(grad, if ((player:GetAttribute("Credits") or 0) :: number) >= nextDef.Cost then "Green" else "Grey")
	else
		nxt.Text = "MAX"
		text.Text = "MAXED"
		UIKit.recolor(grad, "Gold")
	end
end

local busy = false
button.MouseButton1Click:Connect(function()
	if busy or not LEVELS[level() + 1] then
		return
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("PenUp"):InvokeServer("buy")
	end)
	busy = false
	if ok and type(res) == "table" and res.ok then
		Sfx.Play("Buy")
		UIKit.burst(win.frame, UDim2.fromOffset(W_SIZE.X / 2, 170), GREEN)
		UIKit.bump(icon, 0.15)
		refresh()
	else
		Sfx.Play("Error")
	end
end)

player.AttributeChanged:Connect(function(name)
	if win.isOpen() and (name == "Credits" or name == "PenLevel" or name == "BaseSlots") then
		refresh()
	end
end)

UIKit.Open.Event:Connect(function(what: string)
	if what == "PenUp" then
		win.open(refresh)
	elseif what == "Close" then
		win.close()
	end
end)
