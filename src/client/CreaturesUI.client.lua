-- Fenêtre CREATURES (docs/Interfaces.md §4 à §6) : toutes ses créatures, dans la base et dans le sac.
-- Trois modes :
--   bag  (bouton CREATURES du menu) : ranger dans le sac / renvoyer dans la base, cadenas ;
--   sell (stand SELL)  : sélectionner puis vendre, ou « Sell duplicates » ;
--   fuse (machine à fusion) : 3 créatures identiques -> stade suivant (Adult, puis Elder).
-- Le serveur fait tout (CreatureService) ; chaque réponse renvoie la liste à jour.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local Icons = require(ReplicatedStorage.Shared:WaitForChild("Icons"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local new = UIKit.new
local C = Config.PetRules

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function money(n: number): string
	return "$" .. Format.Short(n)
end

local W = UIKit.window({ name = "CreaturesWindow", title = "CREATURES", color = "Purple", size = Vector2.new(1000, 660) })
local body = W.body

type Pet = {
	id: string,
	ring: number,
	rarity: number,
	name: string,
	species: string,
	stage: number,
	size: number,
	weight: number?,
	income: number,
	price: number,
	locked: boolean,
	where: string,
}

local mode = "bag"
local filter = "All"
local data = { base = {} :: { Pet }, bag = {} :: { Pet }, max = C.InventoryMax }
local selected: { [string]: boolean } = {} -- vente : sélection multiple
local focus: string? = nil -- sac : créature choisie
local slots: { string? } = {} -- fusion : 3 emplacements

local function all(): { Pet }
	local out = {}
	for _, p in ipairs(data.base) do
		table.insert(out, p)
	end
	for _, p in ipairs(data.bag) do
		table.insert(out, p)
	end
	-- les plus rares et les plus évoluées d'abord
	table.sort(out, function(a, b)
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		elseif a.stage ~= b.stage then
			return a.stage > b.stage
		end
		return a.income > b.income
	end)
	return out
end

local function byId(id: string?): Pet?
	if not id then
		return nil
	end
	for _, p in ipairs(data.base) do
		if p.id == id then
			return p
		end
	end
	for _, p in ipairs(data.bag) do
		if p.id == id then
			return p
		end
	end
	return nil
end

-- PORTRAIT 3D ---------------------------------------------------------------------------------

local turning: { { vp: ViewportFrame, model: Model, phase: number } } = {}

local function portrait(parent: GuiObject, p: { ring: number, rarity: number }, size: UDim2, pos: UDim2, z: number): ViewportFrame
	local vp = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 205),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1.5, -1),
		ZIndex = z,
		Parent = parent,
	})
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Creatures")
	local template = folder and folder:FindFirstChild(("R%d_T%d"):format(p.ring, p.rarity)) :: Model?
	if template then
		local m = template:Clone()
		m:PivotTo(CFrame.new())
		m.Parent = vp
		local _, s = m:GetBoundingBox()
		local cam = new("Camera", { FieldOfView = 30, Parent = vp })
		local dist = math.max(s.X, s.Y, s.Z) * 2.1
		local mid = Vector3.new(0, s.Y * 0.45, 0)
		cam.CFrame = CFrame.lookAt(mid + Vector3.new(0, s.Y * 0.22, -dist), mid)
		vp.CurrentCamera = cam
		table.insert(turning, { vp = vp, model = m, phase = math.random() * 6 })
	end
	return vp
end

RunService.RenderStepped:Connect(function()
	if not W.isOpen() then
		return
	end
	local t = os.clock()
	for i = #turning, 1, -1 do
		local e = turning[i]
		if not e.vp.Parent then
			table.remove(turning, i)
		else
			e.model:PivotTo(CFrame.Angles(0, math.sin(t * 1.2 + e.phase) * 0.6, 0))
		end
	end
end)

-- MISE EN PAGE --------------------------------------------------------------------------------

local top = new("Frame", { Name = "Top", Size = UDim2.new(1, -10, 0, 64), BackgroundTransparency = 1, LayoutOrder = 1, Parent = body })
local tabs = new("Frame", { Size = UDim2.fromOffset(330, 54), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1, Parent = top }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
})
local counter = UIKit.text({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 352, 0.5, 0), Size = UDim2.fromOffset(200, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Left, Stroke = 3, Parent = top })
local actions = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 5), Size = UDim2.fromOffset(470, 54), BackgroundTransparency = 1, Parent = top }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local refresh: () -> ()

local function smallButton(parent: Instance, text: string, color: string, width: number, order: number): (TextButton, TextLabel, UIGradient)
	local colors = UIKit.Colors[color]
	local grad = UIKit.gradient(colors[1], colors[2])
	local b = new("TextButton", {
		Size = UDim2.fromOffset(width, 50),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Parent = parent,
	}, { UIKit.corner(12), UIKit.stroke(3.5), grad })
	local label = UIKit.text({ Size = UDim2.new(1, -14, 1, -12), Position = UDim2.fromOffset(7, 6), Text = text, Stroke = 3, Parent = b })
	UIKit.juice(b)
	return b, label, grad
end

local tabButtons = {}
for i, name in ipairs({ "All", "Base", "Bag" }) do
	local b, _, grad = smallButton(tabs, if name == "Base" then "{Home} BASE" elseif name == "Bag" then "{Lock} BAG" else "ALL", "Grey", 104, i)
	tabButtons[name] = grad
	b.MouseButton1Click:Connect(function()
		filter = name
		refresh()
	end)
end

-- Panneau de fusion (mode fuse)
local fusePanel = new("Frame", { Name = "Fusion", Size = UDim2.new(1, -10, 0, 230), BackgroundTransparency = 1, LayoutOrder = 2, Visible = false, Parent = body })
local slotCards: { Frame } = {}
for i = 1, 3 do
	local c = UIKit.card({ parent = fusePanel, color = "Dark", name = "Slot" .. i })
	c.Size = UDim2.fromOffset(150, 190)
	c.Position = UDim2.fromOffset(20 + (i - 1) * 165, 20)
	UIKit.text({ Name = "Hint", Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0.5, -20), Text = "+", TextColor3 = Color3.fromRGB(200, 205, 220), Stroke = 3, Parent = c })
	slotCards[i] = c
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 8, Parent = c })
	hit.MouseButton1Click:Connect(function()
		slots[i] = nil
		refresh()
	end)
end
UIKit.text({ Size = UDim2.fromOffset(60, 60), Position = UDim2.fromOffset(515, 85), Text = "=", Stroke = 4, Parent = fusePanel })
local preview = UIKit.card({ parent = fusePanel, color = "Gold", name = "Preview" })
preview.Size = UDim2.fromOffset(170, 210)
preview.Position = UDim2.fromOffset(585, 10)
local previewHolder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = preview })
local fuseBox = new("Frame", { Position = UDim2.fromOffset(775, 30), Size = UDim2.fromOffset(190, 170), BackgroundTransparency = 1, Parent = fusePanel }, {
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local autoFill = smallButton(fuseBox, "AUTO-FILL", "Blue", 190, 1)
local fuseButton, _, fuseGrad = smallButton(fuseBox, "FUSE!", "Green", 190, 2)
fuseButton.Size = UDim2.fromOffset(190, 70)

local grid = UIKit.grid(body, Vector2.new(150, 200), 3)

-- Confirmation (vente d'une créature rare)
local confirm = new("Frame", {
	Name = "Confirm",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(520, 230),
	BackgroundColor3 = UIKit.Panel,
	Visible = false,
	ZIndex = 40,
	Parent = W.frame,
}, { UIKit.corner(18), UIKit.stroke(5) })
local confirmText = UIKit.text({ Size = UDim2.new(1, -40, 0, 110), Position = UDim2.fromOffset(20, 18), Text = "", ZIndex = 41, Stroke = 3, Parent = confirm })
local confirmRow = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(420, 60), BackgroundTransparency = 1, ZIndex = 41, Parent = confirm }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 16) }),
})
local yes = smallButton(confirmRow, "YES, SELL", "Green", 190, 1)
local no = smallButton(confirmRow, "NO", "Red", 150, 2)
for _, b in ipairs({ yes, no }) do
	b.ZIndex = 42
	for _, d in ipairs(b:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = 43
		end
	end
end
local onYes: (() -> ())? = nil
yes.MouseButton1Click:Connect(function()
	confirm.Visible = false
	if onYes then
		onYes()
	end
end)
no.MouseButton1Click:Connect(function()
	confirm.Visible = false
end)
local function ask(text: string, fn: () -> ())
	confirmText.Text = text
	onYes = fn
	confirm.Visible = true
	UIKit.popIn(confirm)
end

-- SERVEUR -------------------------------------------------------------------------------------

local function call(action: string, arg: any?): any
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Creatures"):InvokeServer(action, arg)
	end)
	if ok and type(res) == "table" then
		if res.list then
			data = res.list
		end
		return res
	end
	return { ok = false }
end

-- CARTES --------------------------------------------------------------------------------------

local function rarityOf(p: Pet)
	return Config.Rarities[p.rarity] or Config.Rarities[1]
end

local function fuseGroupOk(): (boolean, Pet?)
	local a = byId(slots[1])
	local b = byId(slots[2])
	local c = byId(slots[3])
	if not (a and b and c) then
		return false, nil
	end
	for _, p in ipairs({ b, c }) do
		if p.ring ~= a.ring or p.rarity ~= a.rarity or p.stage ~= a.stage then
			return false, nil
		end
	end
	return a.stage < #C.Stages, a
end

local function makeCard(p: Pet, order: number)
	local r = rarityOf(p)
	local c = new("Frame", {
		Name = p.id,
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = order,
		Parent = grid,
	}, { UIKit.corner(14), UIKit.gradient(r.Color:Lerp(Color3.new(1, 1, 1), 0.35), r.Color:Lerp(Color3.new(0, 0, 0), 0.25)) })
	local isSel = (mode == "sell" and selected[p.id]) or (mode == "bag" and focus == p.id) or (mode == "fuse" and table.find(slots, p.id) ~= nil)
	UIKit.stroke(if isSel then 6 else 4, if isSel then Color3.fromRGB(255, 230, 90) else nil).Parent = c
	UIKit.studs(c, 0.85)
	portrait(c, p, UDim2.fromOffset(130, 112), UDim2.new(0.5, 0, 0, 66), 3)
	UIKit.text({ Size = UDim2.new(1, -10, 0, 24), Position = UDim2.fromOffset(5, 124), Text = p.name, ZIndex = 4, Stroke = 2.5, Parent = c })
	UIKit.text({ Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 148), Text = r.Name:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.5), ZIndex = 4, Stroke = 2, Parent = c })
	local bottom = if mode == "sell" then "{Cash} " .. money(p.price) else "{Cash} " .. money(p.income) .. "/s"
	UIKit.text({ Size = UDim2.new(1, -10, 0, 24), Position = UDim2.fromOffset(5, 168), Text = bottom, TextColor3 = UIKit.Money, ZIndex = 4, Stroke = 2.5, Parent = c })
	if p.stage > 1 then
		UIKit.ribbon(c, (Config.PetRules.Stages[p.stage].Name):upper(), if p.stage == 3 then "Gold" else "Blue")
	end
	-- coins : où elle est, cadenas
	UIKit.icon(if p.where == "base" then "Home" else "Egg", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(6, 6), ZIndex = 5, Parent = c })
	if p.locked then
		UIKit.icon("Lock", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -38, 0, 6), ZIndex = 5, Parent = c })
	end
	local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = c })
	UIKit.hoverCard(c)
	hit.MouseButton1Click:Connect(function()
		if mode == "sell" then
			if p.locked then
				UIKit.toast("{Lock} Unlock it first", "warn")
				return
			end
			selected[p.id] = if selected[p.id] then nil else true
		elseif mode == "fuse" then
			if p.locked then
				UIKit.toast("{Lock} Unlock it first", "warn")
				return
			end
			local at = table.find(slots, p.id)
			if at then
				slots[at] = nil
			else
				for i = 1, 3 do
					if not slots[i] then
						slots[i] = p.id
						break
					end
				end
			end
		else
			focus = if focus == p.id then nil else p.id
		end
		refresh()
	end)
end

-- BOUTONS D'ACTION ----------------------------------------------------------------------------

local function clearActions()
	for _, ch in ipairs(actions:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
end

local function sellIds(ids: { string })
	local total, rare = 0, false
	for _, id in ipairs(ids) do
		local p = byId(id)
		if p then
			total += p.price
			rare = rare or p.rarity >= C.ConfirmFrom or p.stage > 1
		end
	end
	local function go()
		local res = call("sell", ids)
		if res.ok then
			table.clear(selected)
			UIKit.burst(W.frame, UDim2.fromScale(0.5, 0.5), UIKit.Money)
		end
		refresh()
	end
	if rare then
		ask(("Sell %d creature%s for %s?\nSome of them are rare!"):format(#ids, if #ids > 1 then "s" else "", money(total)), go)
	else
		go()
	end
end

local function buildActions()
	clearActions()
	if mode == "sell" then
		local ids, total = {}, 0
		for id in pairs(selected) do
			local p = byId(id)
			if p then
				table.insert(ids, id)
				total += p.price
			end
		end
		local dup = smallButton(actions, "SELL DUPLICATES", "Orange", 220, 1)
		dup.MouseButton1Click:Connect(function()
			ask("Sell every duplicate?\nThe best of each creature is kept.", function()
				call("selldupes")
				table.clear(selected)
				refresh()
			end)
		end)
		local sell, _, grad = smallButton(actions, "{Cash} SELL " .. money(total), "Green", 230, 2)
		if #ids == 0 then
			UIKit.recolor(grad, "Grey")
		end
		sell.MouseButton1Click:Connect(function()
			if #ids > 0 then
				sellIds(ids)
			end
		end)
	elseif mode == "bag" then
		local p = byId(focus)
		if p then
			local move = smallButton(actions, if p.where == "base" then "{Lock} STORE IN BAG" else "{Home} SEND TO BASE", "Blue", 240, 1)
			move.MouseButton1Click:Connect(function()
				call(if p.where == "base" then "store" else "send", p.id)
				refresh()
			end)
			local lock = smallButton(actions, if p.locked then "UNLOCK" else "{Lock} LOCK", if p.locked then "Grey" else "Gold", 160, 2)
			lock.MouseButton1Click:Connect(function()
				call("lock", p.id)
				refresh()
			end)
		end
	end
end

-- FUSION --------------------------------------------------------------------------------------

local function refreshFusion()
	fusePanel.Visible = mode == "fuse"
	if mode ~= "fuse" then
		return
	end
	for i, card in ipairs(slotCards) do
		for _, ch in ipairs(card:GetChildren()) do
			if ch:IsA("ViewportFrame") or ch.Name == "SlotName" then
				ch:Destroy()
			end
		end
		local p = byId(slots[i])
		if not p then
			slots[i] = nil
		end
		local hint = card:FindFirstChild("Hint") :: TextLabel
		hint.Visible = p == nil
		if p then
			portrait(card, p, UDim2.fromOffset(130, 130), UDim2.new(0.5, 0, 0, 80), 3)
			UIKit.text({ Name = "SlotName", Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 155), Text = p.name, ZIndex = 4, Stroke = 2.5, Parent = card })
		end
	end
	previewHolder:ClearAllChildren()
	local ok, a = fuseGroupOk()
	UIKit.recolor(fuseGrad, if ok then "Green" else "Grey")
	if ok and a then
		local nextStage = a.stage + 1
		local s1, s2, s3 = byId(slots[1]), byId(slots[2]), byId(slots[3])
		local size = ((s1 and s1.size or 1) + (s2 and s2.size or 1) + (s3 and s3.size or 1)) / 3
		local income = Config.PetIncome({ ring = a.ring, rarity = a.rarity, size = size, stage = nextStage })
		portrait(previewHolder, a, UDim2.fromOffset(150, 130), UDim2.new(0.5, 0, 0, 78), 3)
		UIKit.text({ Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 146), Text = C.Stages[nextStage].Name .. " " .. a.species, ZIndex = 4, Stroke = 2.5, Parent = previewHolder })
		UIKit.text({ Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 174), Text = "{Cash} " .. money(income) .. "/s", TextColor3 = UIKit.Money, ZIndex = 4, Stroke = 2.5, Parent = previewHolder })
	else
		UIKit.text({ Size = UDim2.new(1, -20, 0, 90), Position = UDim2.fromOffset(10, 60), Text = "Pick 3 identical creatures", ZIndex = 4, Stroke = 2.5, Parent = previewHolder })
	end
end

autoFill.MouseButton1Click:Connect(function()
	-- le groupe de 3 identiques le plus précieux (rareté, puis stade)
	local groups = {}
	for _, p in ipairs(all()) do
		if not p.locked and p.stage < #C.Stages then
			local key = ("%d:%d:%d"):format(p.ring, p.rarity, p.stage)
			groups[key] = groups[key] or {}
			table.insert(groups[key], p)
		end
	end
	local best
	for _, g in pairs(groups) do
		if #g >= 3 then
			local p = g[1]
			if not best or p.rarity > best[1].rarity or (p.rarity == best[1].rarity and p.stage > best[1].stage) then
				best = g
			end
		end
	end
	if not best then
		UIKit.toast("{Cross} You need 3 identical creatures", "warn")
		return
	end
	-- les moins rentables d'abord (on garde les meilleures)
	table.sort(best, function(x, y)
		return x.income < y.income
	end)
	slots = { best[1].id, best[2].id, best[3].id }
	refresh()
end)

fuseButton.MouseButton1Click:Connect(function()
	local ok = fuseGroupOk()
	if not ok then
		UIKit.toast("{Cross} Pick 3 identical creatures", "warn")
		return
	end
	-- les 3 cartes glissent vers le centre et s'effacent
	for _, card in ipairs(slotCards) do
		local scale = card:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = card })
		tween(scale, 0.35, { Scale = 0.2 }, Enum.EasingStyle.Back)
	end
	task.wait(0.35)
	local res = call("fuse", { slots[1], slots[2], slots[3] })
	for _, card in ipairs(slotCards) do
		local scale = card:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
	slots = {}
	if res.ok and res.extra and res.extra.result then
		UIKit.burst(W.frame, UDim2.fromScale(0.68, 0.3), Color3.fromRGB(255, 230, 120))
		UIKit.rays(preview, { color = Color3.fromRGB(255, 230, 120), size = 380, transparency = 0.4 })
		focus = res.extra.result.id
	end
	refresh()
	if res.ok and res.extra and res.extra.result then
		-- montre le résultat dans l'aperçu
		previewHolder:ClearAllChildren()
		local p = res.extra.result
		portrait(previewHolder, p, UDim2.fromOffset(150, 130), UDim2.new(0.5, 0, 0, 78), 3)
		local name = UIKit.text({ Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 146), Text = p.name, ZIndex = 4, Stroke = 2.5, Parent = previewHolder })
		UIKit.shinyText(name, rarityOf(p).Color)
		UIKit.text({ Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 174), Text = "{Cash} " .. money(p.income) .. "/s", TextColor3 = UIKit.Money, ZIndex = 4, Stroke = 2.5, Parent = previewHolder })
		UIKit.popIn(preview)
	end
end)

-- RAFRAÎCHIR ----------------------------------------------------------------------------------

refresh = function()
	for name, grad in pairs(tabButtons) do
		UIKit.recolor(grad, if name == filter then "Purple" else "Grey")
	end
	counter.Text = ("Bag %d/%d · Base %d"):format(#data.bag, data.max or C.InventoryMax, #data.base)
	for _, ch in ipairs(grid:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local list = all()
	local shown = 0
	for i, p in ipairs(list) do
		if filter == "All" or (filter == "Base" and p.where == "base") or (filter == "Bag" and p.where == "bag") then
			makeCard(p, i)
			shown += 1
		end
	end
	if shown == 0 then
		local empty = UIKit.text({ Size = UDim2.fromOffset(600, 60), Text = "No creature here yet: hatch some eggs!", Stroke = 3, Parent = grid })
		empty.LayoutOrder = 1
	end
	buildActions()
	refreshFusion()
end

local TITLES = { bag = "CREATURES", sell = "TRADING POST", fuse = "FUSION MACHINE" }

local function open(newMode: string)
	mode = newMode
	table.clear(selected)
	slots = {}
	focus = nil
	local title = W.header:FindFirstChildWhichIsA("TextLabel", true)
	if title then
		Icons.Apply(title, TITLES[mode] or "CREATURES")
	end
	call("list")
	refresh()
	W.open()
end

Remotes:WaitForChild("OpenCreatures").OnClientEvent:Connect(function(m: string)
	open(if m == "sell" or m == "fuse" then m else "bag")
end)
UIKit.Open.Event:Connect(function(what: string)
	if what == "Creatures" then
		open("bag")
	elseif what == "Close" and W.isOpen() then
		W.close()
	end
end)
