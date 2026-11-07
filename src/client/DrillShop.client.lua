-- ATELIER DES FOREUSES : ce qui s'achète en $ (docs/Boutique.md). Ouvert au stand Shop du vaisseau
-- (Remotes.OpenShop). Trois onglets :
--   DRILLS   : les 11 foreuses en liste, détail à droite (aperçu 3D qui tourne, puissance actuelle
--              → suivante, un seul bouton qui change d'état : équipée, possédée, acheter, verrouillée)
--   SKINS    : apparences de foreuse (Config.DrillSkins), en $ ou en Robux pour les premium
--   UPGRADES : le scanner (chance des œufs rares)
-- Le serveur décide de tout : BuyDrill, BuyUpgrade, Remotes.DrillShop (skins).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local DrillSkin = require(ReplicatedStorage.Shared:WaitForChild("DrillSkin"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Prices = require(script.Parent:WaitForChild("Prices"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

local W_SIZE = Vector2.new(1060, 650)
local win = UIKit.window({ name = "DrillShop", title = "{Lightning} DRILL WORKSHOP", color = "Orange", size = W_SIZE })
win.body.Visible = false

local GAP = 14
local PAGE_Y = 160
local PAGE_H = W_SIZE.Y - PAGE_Y - GAP
local PAGE_W = W_SIZE.X - GAP * 2

local function money(n: number): string
	return "$" .. Format.Short(n)
end

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?, align: Enum.TextXAlignment?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or UIKit.Ink,
		TextXAlignment = align or Enum.TextXAlignment.Center,
		ZIndex = 4,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

local function panel(parent: Instance, x: number, y: number, w: number, h: number): Frame
	return new("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = Color3.fromRGB(30, 32, 42),
		BackgroundTransparency = 0.2,
		ZIndex = 2,
		Parent = parent,
	}, { UIKit.corner(14) })
end

-- APERÇUS 3D -------------------------------------------------------------------------------------
local drillAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Drills")

-- Foreuse d'un palier avec un skin, posée dans une ViewportFrame, penchée et vue de trois quarts
local function preview(vp: ViewportFrame, tier: number, skin: string?, angle: number?): Model?
	vp:ClearAllChildren()
	local template = drillAssets:FindFirstChild("Drill" .. tier) :: Model?
	if not template then
		return nil
	end
	local m = template:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	DrillSkin.Apply(m, skin, false)
	local _, size = m:GetBoundingBox()
	m:PivotTo(CFrame.Angles(0, angle or 0.6, math.rad(-28)))
	m.Parent = vp
	local cf, s = m:GetBoundingBox()
	local cam = new("Camera", { FieldOfView = 30, Parent = vp })
	local dist = math.max(s.X, s.Y, s.Z, size.Y) * 1.75
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, s.Y * 0.08, dist), cf.Position)
	vp.CurrentCamera = cam
	return m
end

local function viewport(parent: Instance, size: number, x: number, y: number, z: number): ViewportFrame
	return new("ViewportFrame", {
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 185),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1.5, -1),
		ZIndex = z,
		Parent = parent,
	})
end

-- ONGLETS ----------------------------------------------------------------------------------------
local TABS = {
	{ key = "Drills", text = "DRILLS", art = "UpDrill", color = "Orange" },
	{ key = "Skins", text = "SKINS", art = "Sparkles", color = "Pink" },
	{ key = "Upgrades", text = "UPGRADES", art = "UpScanner", color = "Teal" },
}
local pages: { [string]: Frame } = {}
local tabButtons: { [string]: { button: TextButton, stroke: UIStroke } } = {}
local currentTab = "Drills"

local tabRow = new("Frame", { Size = UDim2.fromOffset(PAGE_W, 54), Position = UDim2.fromOffset(GAP, 96), BackgroundTransparency = 1, ZIndex = 2, Parent = win.frame }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})
for i, tab in ipairs(TABS) do
	pages[tab.key] = new("Frame", {
		Name = tab.key,
		Size = UDim2.fromOffset(PAGE_W, PAGE_H),
		Position = UDim2.fromOffset(GAP, PAGE_Y),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = win.frame,
	})
	local colors = UIKit.Colors[tab.color]
	local b = new("TextButton", {
		Name = tab.key,
		Size = UDim2.fromOffset(210, 54),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = i,
		ZIndex = 3,
		Parent = tabRow,
	}, { UIKit.corner(14), UIKit.gradient(colors[1], colors[2]) })
	local stroke = UIKit.stroke(3.5)
	stroke.Parent = b
	UIKit.studs(b, 0.45, "Weld", 22)
	UIKit.icon(tab.art, { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(4, 1), ZIndex = 4, Parent = b })
	label(b, tab.text, 58, 10, 146, 34, 26, nil, Enum.TextXAlignment.Left)
	UIKit.juice(b)
	tabButtons[tab.key] = { button = b, stroke = stroke }
end

local refreshAll: () -> ()

local function showTab(key: string)
	currentTab = key
	for k, p in pairs(pages) do
		p.Visible = k == key
	end
	for k, t in pairs(tabButtons) do
		local on = k == key
		t.stroke.Thickness = if on then 5 else 3.5
		t.stroke.Color = if on then Color3.fromRGB(255, 240, 150) else UIKit.Outline
		t.button.BackgroundTransparency = 0
		t.button.Size = UDim2.fromOffset(210, if on then 54 else 48)
	end
	if refreshAll then
		refreshAll()
	end
end
for key, t in pairs(tabButtons) do
	t.button.MouseButton1Click:Connect(function()
		showTab(key)
	end)
end

-- Skin équipé et skins possédés (réponse du serveur)
local skinState = { owned = { Classic = true } :: { [string]: boolean }, skin = "Classic" }
local function fetchSkins()
	local ok, res = pcall(function()
		return Remotes:WaitForChild("DrillShop"):InvokeServer("state")
	end)
	if ok and type(res) == "table" and res.ok then
		skinState.owned, skinState.skin = res.owned, res.skin
	end
end

-- PAGE DRILLS ------------------------------------------------------------------------------------
local drillPage = pages.Drills
local LIST_W = 420
local listPanel = panel(drillPage, 0, 0, LIST_W, PAGE_H)
local list = new("ScrollingFrame", {
	Size = UDim2.new(1, -12, 1, -12),
	Position = UDim2.fromOffset(6, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 3,
	Parent = listPanel,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8) }),
})

type Row = { frame: TextButton, stroke: UIStroke, vp: ViewportFrame, state: TextLabel, grad: UIGradient }
local rows: { Row } = {}
local selected = 1

local DETAIL_X = LIST_W + GAP
local DETAIL_W = PAGE_W - DETAIL_X
local detail = panel(drillPage, DETAIL_X, 0, DETAIL_W, PAGE_H)
local detailFx = new("Frame", { Size = UDim2.fromOffset(320, 320), Position = UDim2.fromOffset(24, 30), BackgroundTransparency = 1, ZIndex = 3, Parent = detail })
local detailRays = UIKit.rays(detailFx, { color = Color3.new(1, 1, 1), size = 380, speed = 16, transparency = 0.35, z = 3 })
local detailGlow = UIKit.glow(detailFx, { color = Color3.new(1, 1, 1), size = 300, transparency = 0.35, z = 3, pulse = 2 })
local bigVp = viewport(detail, 320, 24, 30, 4)
local bigModel: Model? = nil
local detailName = label(detail, "", 352, 34, DETAIL_W - 368, 50, 40, nil, Enum.TextXAlignment.Left)
local detailTier = label(detail, "", 352, 86, DETAIL_W - 368, 26, 20, Color3.fromRGB(200, 205, 225), Enum.TextXAlignment.Left)
-- Puissance : actuelle → celle-ci, gain en vert
local statBox = new("Frame", { Size = UDim2.fromOffset(DETAIL_W - 368, 120), Position = UDim2.fromOffset(352, 128), BackgroundColor3 = Color3.fromRGB(20, 22, 30), BackgroundTransparency = 0.3, ZIndex = 3, Parent = detail }, { UIKit.corner(12) })
label(statBox, "{Lightning} DRILL POWER", 14, 10, DETAIL_W - 400, 28, 22, Color3.fromRGB(255, 225, 120), Enum.TextXAlignment.Left)
local statValue = label(statBox, "", 14, 44, DETAIL_W - 400, 40, 34, nil, Enum.TextXAlignment.Left)
local statGain = label(statBox, "", 14, 84, DETAIL_W - 400, 28, 22, UIKit.Money, Enum.TextXAlignment.Left)
local detailHint = label(detail, "", 352, 262, DETAIL_W - 368, 54, 20, Color3.fromRGB(220, 225, 240), Enum.TextXAlignment.Left)
local actionButton, actionText, actionGrad = UIKit.priceButton({ parent = detail, text = "", size = UDim2.fromOffset(DETAIL_W - 140, 70), position = UDim2.new(0, 24, 1, -94) })
local actionGlow = UIKit.buttonGlow(actionButton)
local robuxButton, robuxText = UIKit.priceButton({ parent = detail, text = "…", robux = true, size = UDim2.fromOffset(92, 70), position = UDim2.new(1, -108, 1, -94) })
robuxText.TextSize = 24
local action = "none"

for tier, drill in ipairs(Config.Drills) do
	local b = new("TextButton", {
		Name = "Drill" .. tier,
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = tier,
		ZIndex = 3,
		Parent = list,
	}, { UIKit.corner(12) })
	local grad = UIKit.gradient(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2])
	grad.Parent = b
	local stroke = UIKit.stroke(3)
	stroke.Parent = b
	UIKit.studs(b, 0.55, "Inlets", 22)
	-- pastille de la couleur du palier
	new("Frame", { Size = UDim2.fromOffset(8, 56), Position = UDim2.fromOffset(8, 10), BackgroundColor3 = drill.Color, ZIndex = 4, Parent = b }, { UIKit.corner(4) })
	local vp = viewport(b, 70, 18, 3, 4)
	label(b, drill.Name, 92, 8, 172, 32, 26, nil, Enum.TextXAlignment.Left)
	label(b, "{Lightning} " .. Format.Short(drill.Power), 92, 42, 200, 26, 20, Color3.fromRGB(255, 225, 120), Enum.TextXAlignment.Left)
	local state = label(b, "", 270, 24, 116, 28, 20, nil, Enum.TextXAlignment.Right)
	b.MouseButton1Click:Connect(function()
		selected = tier
		refreshAll()
	end)
	rows[tier] = { frame = b, stroke = stroke, vp = vp, state = state, grad = grad }
end

local function refreshDrills()
	local owned = (player:GetAttribute("Drill") or 1) :: number
	local credits = (player:GetAttribute("Credits") or 0) :: number
	for tier, r in ipairs(rows) do
		local drill = Config.Drills[tier]
		local isSel = tier == selected
		r.stroke.Thickness = if isSel then 5 else 3
		r.stroke.Color = if isSel then Color3.fromRGB(255, 240, 150) else UIKit.Outline
		local colors = if tier <= owned then UIKit.Colors.Dark else { Color3.fromRGB(56, 58, 72), Color3.fromRGB(34, 35, 44) }
		r.grad.Color = ColorSequence.new(colors[1], colors[2])
		if tier == owned then
			r.state.Text = "EQUIPPED"
			r.state.TextColor3 = UIKit.Money
		elseif tier < owned then
			r.state.Text = "OWNED"
			r.state.TextColor3 = Color3.fromRGB(190, 195, 215)
		elseif tier == owned + 1 then
			r.state.Text = money(drill.Cost)
			r.state.TextColor3 = if credits >= drill.Cost then UIKit.Money else Color3.fromRGB(255, 110, 110)
		else
			UIKit.setIconText(r.state, "{Lock}")
			r.state.TextColor3 = Color3.fromRGB(190, 195, 215)
		end
		if not r.vp:FindFirstChildWhichIsA("Model") or r.vp:GetAttribute("Skin") ~= skinState.skin then
			preview(r.vp, tier, skinState.skin, 0.4)
			r.vp:SetAttribute("Skin", skinState.skin)
		end
	end

	-- détail de la foreuse choisie
	local drill = Config.Drills[selected]
	local current = Config.Drills[owned]
	bigModel = preview(bigVp, selected, skinState.skin, 0)
	detailName.Text = drill.Name
	detailName.TextColor3 = drill.Color:Lerp(Color3.new(1, 1, 1), 0.35)
	detailTier.Text = ("Drill %d of %d"):format(selected, #Config.Drills)
	detailRays.ImageColor3, detailGlow.ImageColor3 = drill.Color, drill.Color
	statValue.Text = Format.Short(drill.Power)
	if selected > owned then
		local gain = (drill.Power / current.Power - 1) * 100
		statValue.Text = Format.Short(current.Power) .. "  →  " .. Format.Short(drill.Power)
		statGain.Text = ("+%d%% faster drilling"):format(math.floor(gain + 0.5))
	else
		statGain.Text = ""
	end
	robuxButton.Visible = false
	actionGlow.Visible = false
	if selected == owned then
		action = "none"
		actionText.Text = "EQUIPPED"
		UIKit.recolor(actionGrad, "Grey")
		detailHint.Text = "This is the drill in your hands."
	elseif selected < owned then
		action = "none"
		actionText.Text = "OWNED"
		UIKit.recolor(actionGrad, "Grey")
		detailHint.Text = "You already have a better drill."
	elseif selected == owned + 1 then
		action = "buy"
		local ok = credits >= drill.Cost
		actionText.Text = "BUY  " .. money(drill.Cost)
		UIKit.recolor(actionGrad, if ok then "Green" else "Grey")
		actionGlow.Visible = ok
		detailHint.Text = if ok then "Drill faster, get eggs out sooner!" else ("You need %s more."):format(money(drill.Cost - credits))
		if drill.ProductId then
			robuxButton.Visible = true
			Prices.Show(robuxText, drill.ProductId, false, drill.Robux)
		end
	else
		action = "locked"
		UIKit.setIconText(actionText, "{Lock} LOCKED")
		UIKit.recolor(actionGrad, "Grey")
		detailHint.Text = ("Buy the %s first."):format(Config.Drills[selected - 1].Name)
	end
end

actionButton.MouseButton1Click:Connect(function()
	if action == "buy" then
		local drill = Config.Drills[selected]
		if ((player:GetAttribute("Credits") or 0) :: number) >= drill.Cost then
			Remotes.BuyDrill:FireServer()
		else
			UIKit.shake(actionButton)
			UIKit.toast("Not enough $!", "bad")
		end
	elseif action == "locked" then
		UIKit.shake(actionButton)
	end
end)
robuxButton.MouseButton1Click:Connect(function()
	local drill = Config.Drills[selected]
	if drill and drill.ProductId and selected == ((player:GetAttribute("Drill") or 1) :: number) + 1 then
		MarketplaceService:PromptProductPurchase(player, drill.ProductId)
	end
end)

-- la grande foreuse tourne doucement
RunService.RenderStepped:Connect(function()
	if win.isOpen() and currentTab == "Drills" and bigModel and bigModel.Parent then
		local cf = bigModel:GetPivot()
		bigModel:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, os.clock() * 0.8, math.rad(-28)))
	end
end)

-- PAGE SKINS -------------------------------------------------------------------------------------
local skinPage = pages.Skins
local skinScroll = new("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 10,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 2,
	Parent = skinPage,
}, {
	new("UIGridLayout", { CellSize = UDim2.fromOffset(236, 300), CellPadding = UDim2.fromOffset(14, 26), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	new("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 20), PaddingRight = UDim.new(0, 14) }),
})

type SkinCard = { card: Frame, vp: ViewportFrame, button: TextButton, text: TextLabel, grad: UIGradient, mode: string }
local skinCards: { [string]: SkinCard } = {}
for i, s in ipairs(Config.DrillSkins) do
	local rarity = Config.Rarities[s.Rarity] or Config.Rarities[1]
	local c = new("Frame", { Name = s.Key, BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = i, ZIndex = 3, Parent = skinScroll }, {
		UIKit.corner(14),
		UIKit.gradient(rarity.Color:Lerp(Color3.fromRGB(40, 42, 54), 0.45), Color3.fromRGB(32, 34, 44)),
	})
	local stroke = UIKit.stroke(4, rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25))
	stroke.Parent = c
	UIKit.studs(c, 0.55, "Studs", 24)
	UIKit.hoverCard(c)
	if s.Robux then
		UIKit.shinyStroke(c, if s.Key == "Rainbow" then UIKit.Rainbow else UIKit.GoldShine, 4)
		UIKit.ribbon(c, "PREMIUM", "Purple")
	end
	local fx = new("Frame", { Size = UDim2.fromOffset(170, 170), Position = UDim2.fromOffset(33, 34), BackgroundTransparency = 1, ZIndex = 3, Parent = c })
	UIKit.glow(fx, { color = rarity.Color, size = 190, transparency = 0.45, z = 3 })
	local vp = viewport(c, 170, 33, 34, 4)
	label(c, string.upper(s.Name), 8, 8, 220, 30, 26)
	label(c, rarity.Name, 8, 206, 220, 22, 18, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3))
	local b, t, g = UIKit.priceButton({ parent = c, text = "", robux = s.Robux ~= nil, size = UDim2.new(1, -20, 0, 50), position = UDim2.new(0, 10, 1, -60) })
	local data: SkinCard = { card = c, vp = vp, button = b, text = t, grad = g, mode = "" }
	skinCards[s.Key] = data
	if s.Robux then
		Prices.Show(t, s.PassId or 0, true, s.Robux)
	end
	b.MouseButton1Click:Connect(function()
		if data.mode == "equip" or data.mode == "buy" then
			if data.mode == "buy" and ((player:GetAttribute("Credits") or 0) :: number) < s.Price then
				UIKit.shake(b)
				UIKit.toast("Not enough $!", "bad")
				return
			end
			local ok, res = pcall(function()
				return Remotes:WaitForChild("DrillShop"):InvokeServer(data.mode, s.Key)
			end)
			if ok and type(res) == "table" and res.ok then
				skinState.owned, skinState.skin = res.owned, res.skin
				UIKit.burst(c, UDim2.fromScale(0.5, 0.4), rarity.Color)
				UIKit.bump(c, 0.12)
				refreshAll()
			elseif ok and type(res) == "table" then
				UIKit.toast(res.error or "Try again", "bad")
			end
		elseif data.mode == "robux" then
			if s.PassId and s.PassId ~= 0 then
				MarketplaceService:PromptGamePassPurchase(player, s.PassId)
			else
				UIKit.toast("Coming soon!", "info")
			end
		end
	end)
end

local shownTierForSkins = 0
local function refreshSkins()
	local tier = (player:GetAttribute("Drill") or 1) :: number
	local credits = (player:GetAttribute("Credits") or 0) :: number
	for _, s in ipairs(Config.DrillSkins) do
		local c = skinCards[s.Key]
		if shownTierForSkins ~= tier then
			preview(c.vp, tier, s.Key, 0.5)
		end
		local robux = c.button:FindFirstChild("Robux", true)
		if skinState.skin == s.Key then
			c.mode = "none"
			c.text.Text = "EQUIPPED"
			UIKit.recolor(c.grad, "Grey")
			if robux then
				robux.Visible = false
			end
		elseif skinState.owned[s.Key] then
			c.mode = "equip"
			c.text.Text = "EQUIP"
			UIKit.recolor(c.grad, "Blue")
			if robux then
				robux.Visible = false
			end
		elseif s.Robux then
			c.mode = "robux"
			UIKit.recolor(c.grad, "Green")
			if robux then
				robux.Visible = true
			end
			Prices.Show(c.text, s.PassId or 0, true, s.Robux)
		else
			c.mode = "buy"
			c.text.Text = money(s.Price)
			UIKit.recolor(c.grad, if credits >= s.Price then "Green" else "Grey")
		end
	end
	shownTierForSkins = tier
end

-- PAGE UPGRADES ----------------------------------------------------------------------------------
local upPage = pages.Upgrades
local scan = UIKit.card({ parent = upPage, color = "Teal", name = "Scanner" })
scan.Size = UDim2.fromOffset(560, 360)
scan.Position = UDim2.fromOffset((PAGE_W - 560) / 2, 30)
do
	local fx = new("Frame", { Size = UDim2.fromOffset(200, 200), Position = UDim2.fromOffset(24, 70), BackgroundTransparency = 1, ZIndex = 3, Parent = scan })
	UIKit.glow(fx, { color = Color3.new(1, 1, 1), size = 230, transparency = 0.4, z = 3 })
	local icon = UIKit.icon("UpScanner", { Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = fx })
	UIKit.float(icon, 4, 4, 2.2)
end
label(scan, "SCANNER", 20, 14, 520, 46, 40)
local scanLevel = label(scan, "", 244, 80, 296, 34, 28, Color3.fromRGB(255, 245, 150), Enum.TextXAlignment.Left)
local scanEffect = label(scan, "", 244, 120, 296, 34, 26, nil, Enum.TextXAlignment.Left)
label(scan, "Better odds of rare eggs from every asteroid.", 244, 162, 296, 56, 20, Color3.fromRGB(230, 250, 255), Enum.TextXAlignment.Left)
local scanButton, scanText, scanGrad = UIKit.priceButton({ parent = scan, text = "", size = UDim2.fromOffset(296, 66), position = UDim2.fromOffset(244, 262) })
local scanGlow = UIKit.buttonGlow(scanButton)
local scanAffordable = false
scanButton.MouseButton1Click:Connect(function()
	if scanAffordable then
		Remotes.BuyUpgrade:FireServer("Scanner")
	else
		UIKit.shake(scanButton)
	end
end)

local function refreshUpgrades()
	local credits = (player:GetAttribute("Credits") or 0) :: number
	local l = (player:GetAttribute("Lvl_Scanner") or 0) :: number
	scanLevel.Text = "Level " .. l
	if l >= Config.Upgrades.Scanner.Max then
		scanEffect.Text = ("Luck x%.2f"):format(Config.Luck(l))
		scanText.Text = "MAX"
		UIKit.recolor(scanGrad, "Gold")
		scanAffordable = false
	else
		local cost = Config.UpgradeCost("Scanner", l)
		scanEffect.Text = ("Luck x%.2f → x%.2f"):format(Config.Luck(l), Config.Luck(l + 1))
		scanText.Text = "UPGRADE  " .. money(cost)
		scanAffordable = credits >= cost
		UIKit.recolor(scanGrad, if scanAffordable then "Green" else "Grey")
	end
	scanGlow.Visible = scanAffordable
end

-- MISE À JOUR ------------------------------------------------------------------------------------
function refreshAll()
	if currentTab == "Drills" then
		refreshDrills()
	elseif currentTab == "Skins" then
		refreshSkins()
	else
		refreshUpgrades()
	end
end

local lastDrill = (player:GetAttribute("Drill") or 1) :: number
player.AttributeChanged:Connect(function(name)
	if not win.isOpen() then
		return
	end
	if name == "Drill" then
		local now = (player:GetAttribute("Drill") or 1) :: number
		if now > lastDrill then
			selected = math.min(now + 1, #Config.Drills)
			UIKit.burst(detail, UDim2.fromOffset(184, 190), Config.Drills[now].Color)
			UIKit.flyText(detail, "NEW DRILL!", UDim2.fromOffset(120, 80), Config.Drills[now].Color)
		end
		lastDrill = now
		refreshAll()
	elseif name == "Credits" or name == "Lvl_Scanner" or name == "DrillSkin" then
		refreshAll()
	end
end)

local function open(tab: string?)
	local owned = (player:GetAttribute("Drill") or 1) :: number
	lastDrill = owned
	selected = math.min(owned + 1, #Config.Drills)
	fetchSkins()
	win.open(function()
		showTab(tab or "Drills")
	end)
end

Remotes.OpenShop.OnClientEvent:Connect(function(which: string?)
	-- stand STORE du vaisseau : c'est la boutique Robux (Store.client) qui s'ouvre
	if which == "Store" or which == "Sell" then
		UIKit.Open:Fire(which)
		return
	end
	if not win.isOpen() then
		open()
	end
end)
UIKit.Open.Event:Connect(function(what: string, tab: string?)
	if what == "DrillShop" then
		if win.isOpen() then
			win.close()
		else
			open(tab)
		end
	elseif what == "Close" then
		win.close()
	end
end)
