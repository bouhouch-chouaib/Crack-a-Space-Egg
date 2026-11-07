-- INDEX (docs/Interfaces.md §7), dans l'esprit des index des jeux d'œufs :
-- à gauche un onglet par anneau, au centre ses 6 créatures, à droite la créature choisie et la
-- récompense de l'anneau. Une créature jamais eue dans sa base reste une silhouette noire « ??? ».
-- Le serveur tient la liste (CreatureService : actions « index » et « claim »).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = game:GetService("Players").LocalPlayer
local new = UIKit.new

local W = UIKit.window({ name = "IndexWindow", title = "{Star} INDEX", color = "Blue", size = Vector2.new(1000, 660) })
local root = new("Frame", { Name = "Index", Size = UDim2.fromOffset(960, 548), BackgroundTransparency = 1, LayoutOrder = 1, Parent = W.body })

local seen: { [string]: boolean } = {}
local claimed: { [number]: boolean } = {}
local ring = 1
local pick = 1 -- espèce choisie dans l'anneau (1 à 6)

local function key(r: number, slot: number): string
	return r .. ":" .. Config.CreatureRarity(r, slot)
end

local function money(n: number): string
	return "$" .. Format.Short(n)
end

-- PORTRAIT (silhouette noire si pas encore eue) --------------------------------------------------

local turning: { { model: Model, vp: ViewportFrame, phase: number } } = {}

local function portrait(parent: GuiObject, r: number, rarity: number, known: boolean, size: UDim2, pos: UDim2, z: number): ViewportFrame
	local vp = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		Ambient = if known then Color3.fromRGB(190, 190, 205) else Color3.new(0, 0, 0),
		LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0),
		LightDirection = Vector3.new(-1, -1.5, -1),
		ImageColor3 = if known then Color3.new(1, 1, 1) else Color3.fromRGB(12, 12, 20),
		ZIndex = z,
		Parent = parent,
	})
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Creatures")
	local template = folder and folder:FindFirstChild(("R%d_T%d"):format(r, rarity)) :: Model?
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
		if known then
			table.insert(turning, { model = m, vp = vp, phase = math.random() * 6 })
		end
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
			e.model:PivotTo(CFrame.Angles(0, t * 0.8 + e.phase, 0))
		end
	end
end)

-- MISE EN PAGE --------------------------------------------------------------------------------

-- Onglets des anneaux (gauche)
local tabs = new("Frame", { Size = UDim2.fromOffset(190, 548), BackgroundTransparency = 1, Parent = root }, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
-- Anneau (centre)
local middle = new("Frame", { Position = UDim2.fromOffset(204, 0), Size = UDim2.fromOffset(476, 548), BackgroundTransparency = 1, Parent = root })
local ringTitle = UIKit.text({ Size = UDim2.fromOffset(476, 44), Text = "", Stroke = 4, Parent = middle })
local barBack = new("Frame", { Position = UDim2.fromOffset(78, 48), Size = UDim2.fromOffset(320, 26), BackgroundColor3 = Color3.fromRGB(20, 26, 44), Parent = middle }, { UIKit.corner(), UIKit.stroke(3) })
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = barBack }, { UIKit.corner() })
local barGrad = UIKit.gradient(Color3.fromRGB(255, 235, 120), Color3.fromRGB(245, 160, 20))
barGrad.Parent = barFill
local barText = UIKit.text({ Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 2), Text = "", ZIndex = 3, Stroke = 2.5, Parent = barBack })
local cards = new("Frame", { Position = UDim2.fromOffset(0, 86), Size = UDim2.fromOffset(476, 460), BackgroundTransparency = 1, Parent = middle }, {
	new("UIGridLayout", { CellSize = UDim2.fromOffset(148, 214), CellPadding = UDim2.fromOffset(12, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})
-- Détail (droite)
local detail = UIKit.card({ parent = root, color = "Dark", name = "Detail" })
detail.Position = UDim2.fromOffset(694, 0)
detail.Size = UDim2.fromOffset(266, 548)

local refresh: () -> ()

local function call(action: string, arg: any?)
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Creatures"):InvokeServer(action, arg)
	end)
	if ok and type(res) == "table" and res.extra then
		table.clear(seen)
		for _, k in ipairs(res.extra.seen or {}) do
			seen[k] = true
		end
		table.clear(claimed)
		for _, r in ipairs(res.extra.claimed or {}) do
			claimed[r] = true
		end
	end
	return ok and res
end

local function ringCount(r: number): (number, number)
	local n, total = 0, #Config.Creatures[r]
	for slot = 1, total do
		if seen[key(r, slot)] then
			n += 1
		end
	end
	return n, total
end

local tabButtons: { [number]: { grad: UIGradient, frame: TextButton } } = {}
for r, ringCfg in ipairs(Config.Rings) do
	local biome = Config.Biomes[r]
	local color = biome and biome.Clouds[1] or ringCfg.Color
	local grad = UIKit.gradient(color:Lerp(Color3.new(1, 1, 1), 0.3), color:Lerp(Color3.new(0, 0, 0), 0.35))
	local b = new("TextButton", {
		Name = "Ring" .. r,
		Size = UDim2.fromOffset(190, 70),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = r,
		Parent = tabs,
	}, { UIKit.corner(12), UIKit.stroke(3.5), grad })
	UIKit.text({ Size = UDim2.new(1, -12, 0, 32), Position = UDim2.fromOffset(6, 6), Text = "{" .. (biome and biome.Icon or "Star") .. "} " .. (biome and biome.Title or ringCfg.Name), Stroke = 3, Parent = b })
	UIKit.text({ Name = "Count", Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 40), Text = "", TextColor3 = Color3.fromRGB(255, 245, 190), Stroke = 2.5, Parent = b })
	UIKit.juice(b)
	b.MouseButton1Click:Connect(function()
		ring = r
		pick = 1
		refresh()
	end)
	tabButtons[r] = { grad = grad, frame = b }
end

-- RAFRAÎCHIR ----------------------------------------------------------------------------------

local function clear(f: Instance)
	for _, ch in ipairs(f:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
end

local function buildDetail()
	clear(detail)
	local slot = pick
	local rarity = Config.CreatureRarity(ring, slot)
	local r = Config.Rarities[rarity]
	local species = Config.Creatures[ring][slot]
	local known = seen[key(ring, slot)] == true
	UIKit.rays(detail, { color = r.Color, size = 300, transparency = 0.55, position = UDim2.fromOffset(133, 120) })
	portrait(detail, ring, rarity, known, UDim2.fromOffset(230, 210), UDim2.fromOffset(133, 120), 3)
	if not known then
		UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(133, 120), Size = UDim2.fromOffset(90, 90), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 4, Stroke = 5, Parent = detail })
	end
	local name = UIKit.text({ Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 232), Text = if known then species.Name else "???", ZIndex = 4, Stroke = 3.5, Parent = detail })
	if known and rarity >= 5 then
		UIKit.shinyText(name, r.Color)
	end
	UIKit.text({ Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 268), Text = r.Name:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.3), ZIndex = 4, Stroke = 3, Parent = detail })
	local p = Config.Probabilities(ring, 1)[rarity] or 0
	local chance = if p > 0 then ("Chance: 1 in %s"):format(Format.Short(math.max(1, math.floor(1 / p + 0.5)))) else ""
	UIKit.text({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 300), Text = "{Sparkles} " .. chance, ZIndex = 4, Stroke = 2.5, Parent = detail })
	UIKit.text({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.fromOffset(8, 326),
		Text = if known then "{Cash} " .. money(Config.CreatureIncome(ring, rarity, 1)) .. "/s in your base" else "{Hatch} Hatch it to reveal it!",
		TextColor3 = if known then UIKit.Money else Color3.fromRGB(220, 225, 240),
		ZIndex = 4,
		Stroke = 2.5,
		Parent = detail,
	})
	-- Récompense de l'anneau
	local box = new("Frame", { Position = UDim2.fromOffset(10, 362), Size = UDim2.new(1, -20, 0, 176), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, Parent = detail }, {
		UIKit.corner(12),
		UIKit.stroke(3),
		UIKit.gradient(UIKit.Colors.Gold[1]:Lerp(Color3.new(0, 0, 0), 0.55), UIKit.Colors.Gold[2]:Lerp(Color3.new(0, 0, 0), 0.65)),
	})
	UIKit.text({ Size = UDim2.new(1, -12, 0, 26), Position = UDim2.fromOffset(6, 6), Text = "{Star} RING REWARD", TextColor3 = Color3.fromRGB(255, 230, 110), ZIndex = 5, Stroke = 3, Parent = box })
	UIKit.text({ Size = UDim2.new(1, -12, 0, 22), Position = UDim2.fromOffset(6, 36), Text = ("{Sparkles} +%d%% luck forever"):format(math.floor(Config.IndexReward.Luck * 100)), ZIndex = 5, Stroke = 2.5, Parent = box })
	UIKit.text({ Size = UDim2.new(1, -12, 0, 22), Position = UDim2.fromOffset(6, 62), Text = "{Cash} +" .. money(Config.IndexReward.Money * Config.Hatch.RingIncome[ring]), TextColor3 = UIKit.Money, ZIndex = 5, Stroke = 2.5, Parent = box })
	local n, total = ringCount(ring)
	local done = n >= total
	local isClaimed = claimed[ring] == true
	local b, label, grad = UIKit.priceButton({
		parent = box,
		text = if isClaimed then "CLAIMED" elseif done then "CLAIM!" else ("%d/%d FOUND"):format(n, total),
		color = if isClaimed then "Grey" elseif done then "Green" else "Grey",
		size = UDim2.new(1, -20, 0, 56),
		position = UDim2.new(0, 10, 1, -66),
	})
	b.ZIndex = 6
	label.ZIndex = 7
	local _ = grad
	if done and not isClaimed then
		UIKit.buttonGlow(b, Color3.fromRGB(150, 255, 120))
		UIKit.wiggle(b)
	end
	b.MouseButton1Click:Connect(function()
		if done and not isClaimed then
			local res = call("claim", ring)
			if res and res.ok then
				UIKit.burst(W.frame, UDim2.fromScale(0.83, 0.75), Color3.fromRGB(255, 230, 110))
			end
			refresh()
		end
	end)
end

refresh = function()
	local all, allTotal = 0, 0
	for r, t in pairs(tabButtons) do
		local n, total = ringCount(r)
		all += n
		allTotal += total
		local count = t.frame:FindFirstChild("Count") :: TextLabel
		count.Text = ("%d/%d"):format(n, total) .. (if claimed[r] then "  CLAIMED" elseif n >= total then "  CLAIM!" else "")
		local stroke = t.frame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if r == ring then 6 else 3.5
			stroke.Color = if r == ring then Color3.fromRGB(255, 235, 120) else UIKit.Outline
		end
	end
	local biome = Config.Biomes[ring]
	local n, total = ringCount(ring)
	ringTitle.Text = (if biome then biome.Title else Config.Rings[ring].Name) .. ("   ·   collection %d/%d"):format(all, allTotal)
	barFill.Size = UDim2.fromScale(math.max(n / total, 0.02), 1)
	barText.Text = ("%d/%d found"):format(n, total)
	clear(cards)
	for slot, species in ipairs(Config.Creatures[ring]) do
		local rarity = Config.CreatureRarity(ring, slot)
		local r = Config.Rarities[rarity]
		local known = seen[key(ring, slot)] == true
		local c = new("TextButton", {
			Name = "Slot" .. slot,
			BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = slot,
			Parent = cards,
		}, {
			UIKit.corner(14),
			UIKit.gradient(r.Color:Lerp(Color3.new(1, 1, 1), if known then 0.35 else 0.1), r.Color:Lerp(Color3.new(0, 0, 0), if known then 0.25 else 0.6)),
		})
		UIKit.stroke(if slot == pick then 6 else 4, if slot == pick then Color3.fromRGB(255, 235, 120) else nil).Parent = c
		UIKit.studs(c, 0.6)
		portrait(c, ring, rarity, known, UDim2.fromOffset(134, 124), UDim2.new(0.5, 0, 0, 74), 3)
		if not known then
			UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(60, 60), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 4, Stroke = 4, Parent = c })
		end
		UIKit.text({ Size = UDim2.new(1, -10, 0, 26), Position = UDim2.fromOffset(5, 140), Text = if known then species.Name else "???", ZIndex = 4, Stroke = 2.5, Parent = c })
		UIKit.text({ Size = UDim2.new(1, -10, 0, 22), Position = UDim2.fromOffset(5, 170), Text = r.Name:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.45), ZIndex = 4, Stroke = 2.5, Parent = c })
		UIKit.hoverCard(c)
		c.MouseButton1Click:Connect(function()
			pick = slot
			refresh()
		end)
	end
	buildDetail()
end

UIKit.Open.Event:Connect(function(what: string)
	if what == "Index" then
		ring = math.clamp((player:GetAttribute("Ring") or 1) :: number, 1, #Config.Rings)
		pick = 1
		call("index")
		refresh()
		W.open()
	elseif what == "Close" and W.isOpen() then
		W.close()
	end
end)
