-- Inventaires rapides (en haut à droite) : deux petits carrés, une patte pour les créatures et une pierre
-- précieuse pour les minerais. Chacun ouvre un petit menu déroulant : aperçu, nom, et boutons.
--   créatures : EQUIP (sac -> base) ou UNEQUIP (base -> sac), et SELL
--   minerais  : SELL
-- SELL affiche d'abord ce que le joueur va recevoir et demande confirmation, dans la ligne elle-même.
-- Le serveur décide de tout (Remotes.Creatures, Remotes.Gems).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))
local GemModel = require(script.Parent:WaitForChild("GemModel"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

local BUTTON = 66
local WIDTH, HEIGHT = 400, 440
local MAX_ROWS = 40 -- au-delà, on garde les plus précieuses (chaque ligne a son aperçu 3D)

local gui = new("ScreenGui", { Name = "Inventory", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5, Parent = player:WaitForChild("PlayerGui") })
local holder = new("Frame", {
	Name = "Holder",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 14),
	Size = UDim2.fromOffset(BUTTON * 2 + 10, BUTTON),
	BackgroundTransparency = 1,
	Parent = gui,
})
UIKit.autoScale(holder)

local function square(name: string, x: number): TextButton
	local b = new("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(BUTTON, BUTTON),
		Position = UDim2.fromOffset(x, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	}, { UIKit.corner(14), UIKit.stroke(4), UIKit.gradient(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2]) })
	UIKit.studs(b, 0.45, "Studs", 16)
	UIKit.juice(b)
	return b
end

-- aperçu 3D d'un modèle, cadré pour tenir dans son carré
local function viewport(parent: Instance, model: Model, size: number, pos: UDim2): ViewportFrame
	local vp = new("ViewportFrame", {
		Size = UDim2.fromOffset(size, size),
		Position = pos,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 205),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(0.6, -1.5, 1), -- la lumière vient du côté de la caméra
		ZIndex = 3,
		Parent = parent,
	})
	model:PivotTo(CFrame.new())
	-- dans un ViewportFrame, le reflet et le verre rendent les couleurs grises
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Reflectance = 0
			if d.Material == Enum.Material.Glass then
				d.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	model.Parent = vp
	local cf, s = model:GetBoundingBox()
	local cam = new("Camera", { FieldOfView = 30, Parent = vp })
	local dist = math.max(s.X, s.Y, s.Z) * 2.2
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.25, s.Y * 0.2, -dist), cf.Position)
	vp.CurrentCamera = cam
	return vp
end

local pawButton = square("Creatures", 0)
UIKit.icon("Creatures", { Size = UDim2.fromScale(0.86, 0.86), Position = UDim2.fromScale(0.07, 0.07), ZIndex = 3, Parent = pawButton })
local gemButton = square("Gems", BUTTON + 10)
UIKit.icon("OreRock", { Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.05, 0.05), ZIndex = 3, Parent = gemButton })

-- LE MENU DÉROULANT ----------------------------------------------------------------------------

local drop = new("Frame", {
	Name = "Drop",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, BUTTON + 10),
	Size = UDim2.fromOffset(WIDTH, 0),
	BackgroundColor3 = UIKit.Panel,
	ClipsDescendants = true,
	Visible = false,
	ZIndex = 10,
	Parent = holder,
}, { UIKit.corner(16), UIKit.stroke(4) })
UIKit.studs(drop, 0.6, "Inlets", 26)
local title = UIKit.text({ Size = UDim2.new(1, -76, 0, 34), Position = UDim2.fromOffset(12, 8), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12, Stroke = 3, Parent = drop })
local list = new("ScrollingFrame", {
	Name = "List",
	Size = UDim2.new(1, -12, 1, -52),
	Position = UDim2.fromOffset(6, 46),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 11,
	Parent = drop,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8) }),
})

-- flèche pour refermer le menu
local closeButton = new("TextButton", {
	Name = "CloseArrow",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 6),
	Size = UDim2.fromOffset(40, 36),
	BackgroundColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = false,
	Text = "",
	ZIndex = 12,
	Parent = drop,
}, { UIKit.corner(10), UIKit.stroke(3), UIKit.gradient(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2]) })
UIKit.icon("ArrowUp", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(5, 3), ZIndex = 13, Parent = closeButton })
UIKit.juice(closeButton)

local current: string? = nil
local refresh: () -> ()
local busy = false

local function money(n: number): string
	return "$" .. Format.Short(n)
end

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Stroke = 2.5,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

local function button(parent: Instance, text: string, color: string, x: number, y: number, w: number): TextButton
	local b, t = UIKit.priceButton({ parent = parent, text = text, color = color, size = UDim2.fromOffset(w, 36), position = UDim2.fromOffset(x, y) })
	t.TextSize = 20
	return b
end

local function makeRow(order: number, rarity: number, model: Model?, name: string, sub: string): Frame
	local r = Config.Rarities[rarity] or Config.Rarities[1]
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = order,
		ZIndex = 2,
		Parent = list,
	}, { UIKit.corner(12), UIKit.gradient(r.Color:Lerp(Color3.fromRGB(40, 42, 54), 0.55), Color3.fromRGB(30, 32, 44)) })
	UIKit.stroke(3, r.Color:Lerp(Color3.new(0, 0, 0), 0.2)).Parent = row
	if model then
		viewport(row, model, 88, UDim2.fromOffset(4, 6))
	end
	label(row, name, 98, 6, WIDTH - 136, 28, 22)
	label(row, sub, 98, 34, WIDTH - 136, 20, 17, r.Color:Lerp(Color3.new(1, 1, 1), 0.45))
	return row
end

-- Remplace la ligne par « Sell for $X? » + OUI / NON
local function confirmSell(row: Frame, price: number, onYes: () -> ())
	local box = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 26, 38), BackgroundTransparency = 0.05, ZIndex = 8, Parent = row }, { UIKit.corner(12) })
	local question = UIKit.text({ Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 6), Text = "Sell for " .. money(price) .. "?", TextColor3 = UIKit.Money, ZIndex = 9, Stroke = 3, Parent = box })
	new("UITextSizeConstraint", { MaxTextSize = 28, MinTextSize = 12, Parent = question })
	local yes = button(box, "YES", "Green", 40, 54, 140)
	local no = button(box, "NO", "Red", 192, 54, 140)
	yes.ZIndex, no.ZIndex = 9, 9
	UIKit.popIn(box)
	Sfx.Play("Warning")
	yes.MouseButton1Click:Connect(onYes)
	no.MouseButton1Click:Connect(function()
		box:Destroy()
	end)
end

local function clearRows()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function empty(text: string)
	local t = UIKit.text({ Size = UDim2.new(1, 0, 0, 60), Text = text, TextColor3 = Color3.fromRGB(210, 215, 235), ZIndex = 3, Stroke = 2.5, Parent = list })
	new("UITextSizeConstraint", { MaxTextSize = 22, MinTextSize = 10, Parent = t })
end

-- CRÉATURES -----------------------------------------------------------------------------------

local function creatures(action: string, arg: any?): any
	if busy then
		return nil
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Creatures"):InvokeServer(action, arg)
	end)
	busy = false
	return if ok and type(res) == "table" then res else nil
end

local function petModel(ring: number, rarity: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Creatures")
	local template = folder and folder:FindFirstChild(("R%d_T%d"):format(ring, rarity))
	return if template and template:IsA("Model") then template:Clone() else nil
end

local function showCreatures(data: any)
	clearRows()
	local all = {}
	for _, p in ipairs(data.base) do
		table.insert(all, p)
	end
	for _, p in ipairs(data.bag) do
		table.insert(all, p)
	end
	table.sort(all, function(a, b)
		if (a.where == "base") ~= (b.where == "base") then
			return a.where == "base"
		end
		return (a.income or 0) > (b.income or 0)
	end)
	title.Text = ("CREATURES  %d"):format(#all)
	if #all == 0 then
		empty("No creatures yet: hatch some eggs!")
	end
	for i = 1, math.min(#all, MAX_ROWS) do
		local p = all[i]
		local r = Config.Rarities[p.rarity] or Config.Rarities[1]
		local row = makeRow(i, p.rarity, petModel(p.ring, p.rarity), p.name, ("%s · %s/s"):format(r.Name, money(p.income or 0)))
		local inBase = p.where == "base"
		local equip = button(row, if inBase then "UNEQUIP" else "EQUIP", if inBase then "Blue" else "Green", 98, 58, 130)
		equip.MouseButton1Click:Connect(function()
			local res = creatures(if inBase then "store" else "send", p.id)
			if res and res.list then
				Sfx.Play("Click")
				showCreatures(res.list)
			end
		end)
		local sell = button(row, "SELL", "Orange", 236, 58, 130)
		sell.MouseButton1Click:Connect(function()
			if p.locked then
				UIKit.toast("{Lock} Unlock it first", "warn")
				return
			end
			confirmSell(row, p.price or 0, function()
				local res = creatures("sell", { p.id })
				if res and res.ok then
					Sfx.Play("Coin", { pitch = 1.2 })
					UIKit.toast("{Cash} +" .. money(p.price or 0), "good")
				end
				if res and res.list then
					showCreatures(res.list)
				end
			end)
		end)
	end
end

-- MINERAIS ------------------------------------------------------------------------------------

local function gemsCall(action: string, arg: any?): any
	if busy then
		return nil
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Gems"):InvokeServer(action, arg)
	end)
	busy = false
	return if ok and type(res) == "table" then res else nil
end

local function showGems(gems: { any })
	clearRows()
	title.Text = ("GEMS  %d"):format(#gems)
	if #gems == 0 then
		empty("No gems yet: drill geodes!")
	end
	local order = {}
	for i in ipairs(gems) do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		return gems[a].value > gems[b].value
	end)
	for rank = 1, math.min(#order, MAX_ROWS) do
		local index = order[rank]
		local g = gems[index]
		local r = Config.Rarities[g.rarity] or Config.Rarities[1]
		local size = if g.size ~= "" then g.size .. " " else ""
		local row = makeRow(rank, g.rarity, GemModel.Make("gem", g.ring, g.rarity, g.shiny), (if g.shiny then "Shiny " else "") .. size .. Config.GemName(g.ring, g.rarity), ("%s · worth %s"):format(r.Name, money(g.value)))
		local sell = button(row, "SELL", "Orange", 98, 58, 268)
		sell.MouseButton1Click:Connect(function()
			confirmSell(row, g.value, function()
				local res = gemsCall("sell", { index })
				if res and res.ok then
					Sfx.Play("Coin", { pitch = 1.2 })
				elseif res and res.error then
					UIKit.toast(res.error, "warn")
				end
				if res and res.gems then
					showGems(res.gems)
				end
			end)
		end)
	end
end

-- OUVERTURE -----------------------------------------------------------------------------------

local function close()
	if not current then
		return
	end
	current = nil
	local tw = TweenService:Create(drop, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(WIDTH, 0) })
	tw.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and not current then
			drop.Visible = false
			clearRows()
		end
	end)
	tw:Play()
end

refresh = function()
	if current == "Creatures" then
		local res = creatures("list")
		if res and res.list then
			showCreatures(res.list)
		end
	elseif current == "Gems" then
		local res = gemsCall("list")
		if res and res.gems then
			showGems(res.gems)
		end
	end
end

local function toggle(kind: string)
	Sfx.Play("Click")
	if current == kind then
		close()
		return
	end
	local wasOpen = current ~= nil
	current = kind
	drop.Visible = true
	if not wasOpen then
		TweenService:Create(drop, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(WIDTH, HEIGHT) }):Play()
	end
	refresh()
end

closeButton.MouseButton1Click:Connect(function()
	Sfx.Play("Click")
	close()
end)
pawButton.MouseButton1Click:Connect(function()
	toggle("Creatures")
end)
gemButton.MouseButton1Click:Connect(function()
	toggle("Gems")
end)
