-- Comptoir de vente (stand SELL du vaisseau) : la fenêtre TRADING POST.
-- En haut : nombre de minerais et valeur totale, gros bouton SELL ALL, et SELL PETS qui ouvre la
-- fenêtre des créatures en mode vente. Dessous : le sac de minerais, chacun avec son aperçu 3D qui
-- tourne, son nom, sa rareté, sa taille, « SHINY » s'il brille, sa valeur et un bouton SELL.
-- Le serveur décide de tout (GemService, Remotes.Gems).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))
local GemModel = require(script.Parent:WaitForChild("GemModel"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local new = UIKit.new

local W_SIZE = Vector2.new(1000, 640)
local win = UIKit.window({ name = "Sell", title = "{Cash} TRADING POST", color = "Gold", size = W_SIZE })
win.body.Visible = false
local GAP = 14
local GOLD = Color3.fromRGB(255, 220, 90)

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

-- BARRE DU HAUT ------------------------------------------------------------------------------
local top = new("Frame", { Name = "Top", Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, 84), Position = UDim2.fromOffset(GAP, 96), BackgroundColor3 = Color3.fromRGB(26, 28, 40), BackgroundTransparency = 0.15, ZIndex = 2, Parent = win.frame }, { UIKit.corner(14) })
UIKit.icon("Sparkles", { Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(8, 7), ZIndex = 4, Parent = top })
local countText = label(top, "", 84, 8, 330, 36, 30, nil, Enum.TextXAlignment.Left)
local valueText = label(top, "", 84, 44, 330, 30, 24, UIKit.Money, Enum.TextXAlignment.Left)
local sellAll, sellAllText, sellAllGrad = UIKit.priceButton({ parent = top, text = "", size = UDim2.fromOffset(260, 64), position = UDim2.new(1, -540, 0, 10) })
sellAll.Name = "SellAll"
sellAll:SetAttribute("PadFirst", true)
local sellPets = UIKit.priceButton({ parent = top, text = "SELL PETS", color = "Purple", size = UDim2.fromOffset(250, 64), position = UDim2.new(1, -266, 0, 10) })
sellPets.Name = "SellPets"
UIKit.icon("Creatures", { Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, -10, 0.5, -28), ZIndex = 6, Parent = sellPets })

-- SAC DE MINERAIS ----------------------------------------------------------------------------
local list = new("ScrollingFrame", {
	Name = "Gems",
	Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, W_SIZE.Y - 200),
	Position = UDim2.fromOffset(GAP, 188),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 10,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 2,
	Parent = win.frame,
}, {
	new("UIGridLayout", { CellSize = UDim2.fromOffset(180, 236), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 10) }),
})
local empty = label(win.frame, "No gems yet! One drill in 3 gives a geode: bring it to your base machine.", GAP, 300, W_SIZE.X - GAP * 2, 40, 24, Color3.fromRGB(210, 215, 235))

local gems: { any } = {}
local refresh: () -> ()
local spinning: { { model: Model, cam: Camera } } = {}
local busy = false

local function ask(action: string, arg: any?): boolean
	if busy then
		return false
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Gems"):InvokeServer(action, arg)
	end)
	busy = false
	if not ok or type(res) ~= "table" then
		return false
	end
	if res.gems then
		gems = res.gems
	end
	if not res.ok and res.error then
		UIKit.toast(res.error, "warn")
		Sfx.Play("Error")
	end
	return res.ok == true
end

local function gemCard(i: number, g: any): Frame
	local r = Config.Rarities[g.rarity] or Config.Rarities[1]
	local c = new("Frame", { Name = "Gem" .. i, BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = -g.value, ZIndex = 3, Parent = list }, {
		UIKit.corner(14),
		UIKit.gradient(r.Color:Lerp(Color3.fromRGB(40, 42, 54), 0.4), Color3.fromRGB(30, 32, 44)),
	})
	local stroke = UIKit.stroke(3.5, if g.shiny then GOLD else r.Color:Lerp(Color3.new(0, 0, 0), 0.2))
	stroke.Parent = c
	UIKit.studs(c, 0.6, "Studs", 22)
	-- aperçu 3D
	local vp = new("ViewportFrame", { Size = UDim2.fromOffset(120, 100), Position = UDim2.fromOffset(30, 4), BackgroundTransparency = 1, Ambient = Color3.fromRGB(180, 180, 195), LightDirection = Vector3.new(-1, -1.4, -1), ZIndex = 4, Parent = c })
	local m = GemModel.Make("gem", g.ring, g.rarity, g.shiny)
	m:PivotTo(CFrame.new())
	m.Parent = vp
	local cam = new("Camera", { FieldOfView = 34, Parent = vp })
	vp.CurrentCamera = cam
	table.insert(spinning, { model = m, cam = cam })
	label(c, string.upper(Config.GemName(g.ring, g.rarity)), 6, 104, 168, 26, 22)
	label(c, r.Name .. (if g.size ~= "" then " · " .. g.size else ""), 6, 128, 168, 20, 17, r.Color:Lerp(Color3.new(1, 1, 1), 0.35))
	if g.shiny then
		UIKit.ribbon(c, "SHINY!", "Gold")
	end
	label(c, "$" .. Format.Short(g.value), 6, 150, 168, 28, 24, UIKit.Money)
	local b = UIKit.priceButton({ parent = c, text = "SELL", size = UDim2.new(1, -20, 0, 46), position = UDim2.new(0, 10, 1, -54) })
	b.Name = "Sell"
	b.MouseButton1Click:Connect(function()
		if ask("sell", { i }) then
			Sfx.Play("Coin")
			UIKit.burst(win.frame, UDim2.fromScale(0.5, 0.5), UIKit.Money)
			refresh()
		end
	end)
	return c
end

refresh = function()
	for _, ch in ipairs(list:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	table.clear(spinning)
	local total = 0
	for i, g in ipairs(gems) do
		total += g.value
		gemCard(i, g)
	end
	countText.Text = ("%d gem%s"):format(#gems, if #gems == 1 then "" else "s")
	valueText.Text = "Worth $" .. Format.Short(total)
	empty.Visible = #gems == 0
	UIKit.recolor(sellAllGrad, if #gems > 0 then "Green" else "Grey")
	UIKit.setIconText(sellAllText, if #gems > 0 then "SELL ALL $" .. Format.Short(total) else "SELL ALL")
end

sellAll.MouseButton1Click:Connect(function()
	if #gems > 0 and ask("sellAll") then
		Sfx.Play("Coin", { pitch = 1.2 })
		Sfx.Play("Reward")
		UIKit.burst(win.frame, UDim2.fromScale(0.5, 0.3), UIKit.Money)
		refresh()
	end
end)
sellPets.MouseButton1Click:Connect(function()
	win.close()
	UIKit.Open:Fire("Creatures", "sell")
end)

-- les minerais tournent dans leur aperçu
RunService.RenderStepped:Connect(function()
	if not win.isOpen() then
		return
	end
	local t = os.clock()
	for _, s in ipairs(spinning) do
		s.cam.CFrame = CFrame.new(Vector3.new(math.sin(t * 0.8) * 4.2, 1.6, math.cos(t * 0.8) * 4.2), Vector3.new(0, 0.3, 0))
	end
end)

UIKit.Open.Event:Connect(function(what: string)
	if what ~= "Sell" then
		return
	end
	win.open(function()
		ask("list")
		refresh()
	end)
end)
