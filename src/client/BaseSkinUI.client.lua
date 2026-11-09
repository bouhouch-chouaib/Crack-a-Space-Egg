-- Fenêtre BASE SKINS : s'ouvre depuis le panneau de l'onglet SKINS du stand ITEMS (DrillShop.client).
-- Une carte par thème, avec une miniature de la vraie base aux couleurs du thème.
-- Le serveur décide (BaseSkinService, Remotes.BaseSkin). Anime aussi les bases au thème arc-en-ciel.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BaseSkin = require(ReplicatedStorage.Shared:WaitForChild("BaseSkin"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))
local Prices = require(script.Parent:WaitForChild("Prices"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new
local SKINS = Config.BaseSkins

local W_SIZE = Vector2.new(980, 620)
local CARD = Vector2.new(178, 248)
local CARD_GAP = Vector2.new(13, 12)
local COLUMNS = 5
local VIEW = Vector2.new(160, 128)
local TICK = 1 / 12 -- rafraîchissements par seconde de l'arc-en-ciel

local win = UIKit.window({ name = "BaseSkins", title = "{BaseSkin} BASE SKINS", color = "Purple", size = W_SIZE })
win.body.Visible = false

local grid = new("Frame", {
	Name = "Grid",
	Size = UDim2.fromOffset(W_SIZE.X - 28, 510),
	Position = UDim2.fromOffset(14, 98),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = win.frame,
})

-- Cinq cartes par rangée, chaque rangée centrée
local function cardPosition(i: number): UDim2
	local row = math.floor((i - 1) / COLUMNS)
	local inRow = math.min(#SKINS - row * COLUMNS, COLUMNS)
	local left = (grid.Size.X.Offset - (inRow * CARD.X + (inRow - 1) * CARD_GAP.X)) / 2
	return UDim2.fromOffset(left + ((i - 1) % COLUMNS) * (CARD.X + CARD_GAP.X), row * (CARD.Y + CARD_GAP.Y))
end

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number, color: Color3?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		ZIndex = 6,
		Stroke = 3,
		Parent = parent,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

local function needs(s): string
	if s.Robux then
		return "Premium"
	elseif (s.Supernovas or 0) == 0 then
		return "Starter"
	end
	return if s.Supernovas == 1 then "1 Supernova" else ("%d Supernovas"):format(s.Supernovas)
end

type Card = { frame: Frame, view: ViewportFrame, button: TextButton, text: TextLabel, grad: UIGradient, mode: string }
local cards: { [string]: Card } = {}
local state = { owned = {} :: { [string]: boolean }, skin = SKINS[1].Key }
local refresh: () -> ()

local busy = false
local function equip(s, c: Card)
	if busy then
		return
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("BaseSkin"):InvokeServer("equip", s.Key)
	end)
	busy = false
	if ok and type(res) == "table" and res.ok then
		state.owned, state.skin = res.owned, res.skin
		Sfx.Play("Buy")
		UIKit.burst(c.frame, UDim2.fromScale(0.5, 0.35), s.Floor or Color3.new(1, 1, 1))
		UIKit.bump(c.frame, 0.08)
		refresh()
	else
		Sfx.Play("Error")
		UIKit.toast(if ok and type(res) == "table" and res.error then res.error else "Try again", "warn")
	end
end

for i, s in ipairs(SKINS) do
	local rarity = Config.Rarities[s.Rarity] or Config.Rarities[1]
	local frame = new("Frame", { Name = s.Key, Size = UDim2.fromOffset(CARD.X, CARD.Y), Position = cardPosition(i), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = grid }, {
		UIKit.corner(14),
		UIKit.gradient(rarity.Color:Lerp(Color3.fromRGB(40, 42, 54), 0.45), Color3.fromRGB(32, 34, 44)),
	})
	UIKit.stroke(4, rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25)).Parent = frame
	UIKit.studs(frame, 0.55, "Studs", 24)
	UIKit.hoverCard(frame)
	if s.Robux then
		UIKit.shinyStroke(frame, if s.Rainbow then UIKit.Rainbow else UIKit.GoldShine, 4)
	end
	local fx = new("Frame", { Size = UDim2.fromOffset(VIEW.X, VIEW.Y), Position = UDim2.fromOffset(9, 34), BackgroundTransparency = 1, ZIndex = 3, Parent = frame })
	UIKit.rays(fx, { color = rarity.Color, size = 170, speed = 18, transparency = 0.6, z = 3 })
	local view = new("ViewportFrame", {
		Size = UDim2.fromOffset(VIEW.X, VIEW.Y),
		Position = UDim2.fromOffset(9, 34),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(120, 120, 135),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -1),
		ZIndex = 4,
		Parent = frame,
	})
	label(frame, string.upper(s.Name), 6, 6, CARD.X - 12, 28, 24)
	label(frame, needs(s), 6, 162, CARD.X - 12, 22, 18, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35))
	local button, text, grad = UIKit.priceButton({ parent = frame, text = "", robux = s.Robux ~= nil, size = UDim2.new(1, -16, 0, 52), position = UDim2.new(0, 8, 1, -60) })
	button.Name = "Action"
	local c: Card = { frame = frame, view = view, button = button, text = text, grad = grad, mode = "" }
	cards[s.Key] = c
	if s.Robux then
		Prices.Show(text, s.PassId or 0, true, s.Robux)
	end
	button.MouseButton1Click:Connect(function()
		if c.mode == "equip" then
			equip(s, c)
		elseif c.mode == "robux" then
			if s.PassId and s.PassId ~= 0 then
				MarketplaceService:PromptGamePassPurchase(player, s.PassId)
			else
				UIKit.toast("Coming soon!", "info")
			end
		elseif c.mode == "locked" then
			UIKit.shake(button)
			UIKit.toast(if s.Supernovas == 1 then "Go Supernova once to unlock it!" else ("Go Supernova %d times to unlock it!"):format(s.Supernovas), "warn")
		end
	end)
end

refresh = function()
	for _, s in ipairs(SKINS) do
		local c = cards[s.Key]
		local robux = c.button:FindFirstChild("Robux", true)
		local showRobux = false
		if state.skin == s.Key then
			c.mode = "none"
			c.text.Text = "EQUIPPED"
			UIKit.recolor(c.grad, "Grey")
		elseif state.owned[s.Key] then
			c.mode = "equip"
			c.text.Text = "EQUIP"
			UIKit.recolor(c.grad, "Blue")
		elseif s.Robux then
			c.mode = "robux"
			showRobux = true
			UIKit.recolor(c.grad, "Green")
			Prices.Show(c.text, s.PassId or 0, true, s.Robux)
		else
			c.mode = "locked"
			UIKit.setIconText(c.text, "{Lock} LOCKED")
			UIKit.recolor(c.grad, "Grey")
		end
		if robux and robux:IsA("GuiObject") then
			robux.Visible = showRobux
		end
	end
end

local function fetch()
	local ok, res = pcall(function()
		return Remotes:WaitForChild("BaseSkin"):InvokeServer("state")
	end)
	if ok and type(res) == "table" and res.ok then
		state.owned, state.skin = res.owned, res.skin
		refresh()
	end
end

-- MINIATURES : une copie allégée de sa propre base, aux couleurs de chaque thème ---------------------
local minis: { [string]: Model } = {}
local function myBase(): Instance?
	local bases = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Bases")
	return bases and bases:FindFirstChild("Base" .. tostring(player:GetAttribute("Base")))
end

local function buildMinis()
	local base = myBase()
	local floor = base and base:FindFirstChild("Floor") :: BasePart?
	if not base or not floor or next(minis) then
		return
	end
	for _, s in ipairs(SKINS) do
		local m = Instance.new("Model")
		for _, name in ipairs({ "Floor", "Walls", "Annex" }) do
			local source = base:FindFirstChild(name)
			if source then
				source:Clone().Parent = m
			end
		end
		-- à cette taille les picots des murets ne se voient pas : on les retire pour alléger
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("Texture") and d.Parent and d.Parent.Name ~= "Floor" then
				d:Destroy()
			end
		end
		BaseSkin.Apply(m, s.Key)
		local c = cards[s.Key]
		m.Parent = c.view
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		local center = m:GetBoundingBox().Position
		camera.CFrame = CFrame.lookAt(center + floor.CFrame:VectorToWorldSpace(Vector3.new(0, 62, 74)), center)
		camera.Parent = c.view
		c.view.CurrentCamera = camera
		minis[s.Key] = m
	end
end

-- Préparées dès l'arrivée, quand sa base est chargée : le stand ITEMS en est loin
task.spawn(function()
	while not player:GetAttribute("Base") do
		task.wait(0.5)
	end
	local base = workspace:WaitForChild("Ship"):WaitForChild("Bases"):WaitForChild("Base" .. tostring(player:GetAttribute("Base")))
	for _, name in ipairs({ "Floor", "Walls", "Annex" }) do
		base:WaitForChild(name, 30)
	end
	task.wait(3)
	buildMinis()
end)

UIKit.Open.Event:Connect(function(what: string)
	if what == "BaseSkins" then
		buildMinis()
		win.open(function()
			refresh()
			task.spawn(fetch)
		end)
	elseif what == "Close" then
		win.close()
	end
end)

player.AttributeChanged:Connect(function(name)
	if name == "BaseSkin" then
		state.skin = player:GetAttribute("BaseSkin") or SKINS[1].Key
	end
	if win.isOpen() and (name == "BaseSkin" or name == "Supernovas") then
		task.spawn(fetch)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, _id, purchased)
	if who == player and purchased and win.isOpen() then
		task.wait(0.6)
		fetch()
	end
end)

-- ARC-EN-CIEL : les bases de tout le serveur, et la miniature quand la fenêtre est ouverte ------------
local rainbowKey: string? = nil
for _, s in ipairs(SKINS) do
	if s.Rainbow then
		rainbowKey = s.Key
	end
end
local wasRainbow: { [Instance]: boolean } = {}
local last = 0
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if t - last < TICK then
		return
	end
	last = t
	local bases = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Bases")
	if not bases then
		return
	end
	for _, base in ipairs(bases:GetChildren()) do
		local skin = base:GetAttribute("Skin")
		if skin == rainbowKey then
			wasRainbow[base] = true
			BaseSkin.Rainbow(base, t)
		elseif wasRainbow[base] then
			-- le serveur peut ne rien renvoyer si sa couleur n'a pas changé : on repeint nous-mêmes
			wasRainbow[base] = nil
			BaseSkin.Apply(base, skin)
		end
	end
	local mini = rainbowKey and minis[rainbowKey]
	if mini and win.isOpen() then
		BaseSkin.Rainbow(mini, t)
	end
end)
