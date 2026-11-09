-- Grande révélation d'une relique (Remotes.RelicFound), en quatre temps :
--   1. l'attente : écran noir, lueur qui grossit, « SOMETHING ANCIENT AWAKENS... » ;
--   2. l'explosion : flash, écran qui tremble, ondes de choc, la relique arrive en tournoyant, titre qui s'abat ;
--   3. l'histoire : nom, texte tapé lettre par lettre, valeur qui monte, pluie de billets ;
--   4. le choix : la vendre tout de suite ou la garder (onglet RELICS de l'Index).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local RelicModel = require(ReplicatedStorage.Shared:WaitForChild("RelicModel"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

local AUTO_CLOSE = Config.RelicReveal -- le jeu continue derrière, la fenêtre ne doit pas rester indéfiniment
local GOLD = Color3.fromRGB(255, 215, 90)
local CENTER_POS = UDim2.fromScale(0.5, 0.5)
local RELIC_AT = UDim2.fromOffset(410, 222) -- centre de la relique dans le cadre de 820 x 600
local ANTICIPATION = 1.15 -- secondes d'attente avant l'explosion
local STORY_AT, CHOICE_AT = 0.7, 1.9 -- après l'explosion
local ORBITERS = 10
local COINS = 26

local gui = new("ScreenGui", { Name = "RelicReveal", ResetOnSpawn = false, DisplayOrder = 50, IgnoreGuiInset = true, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local dim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, Parent = gui })
local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 20, Parent = gui })
local center = new("Frame", { Name = "Center", AnchorPoint = Vector2.new(0.5, 0.5), Position = CENTER_POS, Size = UDim2.fromOffset(820, 600), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
UIKit.autoScale(center)

-- Lumières derrière la relique
local fx = new("Frame", { Size = UDim2.fromOffset(340, 300), Position = UDim2.fromOffset(240, 72), BackgroundTransparency = 1, ZIndex = 2, Parent = center })
local rays = UIKit.rays(fx, { color = GOLD, size = 800, speed = 26, transparency = 0.2, z = 2 })
UIKit.rays(fx, { color = Color3.new(1, 1, 1), size = 520, speed = -38, transparency = 0.55, z = 2 })
local glow = UIKit.glow(fx, { color = GOLD, size = 480, transparency = 0.15, z = 2, pulse = 2 })
UIKit.sparkles(fx, { count = 12, color = GOLD, size = 26, z = 5 })

local view = new("ViewportFrame", {
	Size = UDim2.fromOffset(340, 300),
	Position = UDim2.fromOffset(240, 72),
	BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(165, 165, 180),
	LightColor = Color3.new(1, 1, 1),
	LightDirection = Vector3.new(-1, -1.5, -1.5),
	ZIndex = 4,
	Parent = center,
})
local shot = new("Camera", { FieldOfView = 30, Parent = view })
view.CurrentCamera = shot

-- Étincelles en orbite autour de la relique
local orbiters: { ImageLabel } = {}
for i = 1, ORBITERS do
	orbiters[i] = UIKit.icon("Sparkles", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), ZIndex = 5, Parent = center })
end

local function label(y: number, h: number, size: number, color: Color3?, stroke: number?): TextLabel
	local t = UIKit.text({ Size = UDim2.new(1, -40, 0, h), Position = UDim2.fromOffset(20, y), Text = "", TextColor3 = color or Color3.new(1, 1, 1), ZIndex = 6, Stroke = stroke or 4, Parent = center })
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 12, Parent = t })
	return t
end

local omen = UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(780, 60), Position = RELIC_AT, Text = "SOMETHING ANCIENT AWAKENS...", TextColor3 = Color3.fromRGB(235, 235, 255), ZIndex = 7, Stroke = 4, Parent = center })
new("UITextSizeConstraint", { MaxTextSize = 38, MinTextSize = 12, Parent = omen })
local title = label(0, 72, 68, GOLD, 6)
title.Text = "RELIC FOUND!"
UIKit.shinyText(title, GOLD)
local titleScale = new("UIScale", { Scale = 1, Parent = title })
local nameText = label(374, 50, 46)
local nameScale = new("UIScale", { Scale = 1, Parent = nameText })
local storyText = label(424, 34, 24, Color3.fromRGB(225, 230, 250), 3)
local valueText = label(460, 42, 38, UIKit.Money, 4)
UIKit.shinyText(valueText, UIKit.Money)

local sellButton, sellText = UIKit.priceButton({ parent = center, text = "", size = UDim2.fromOffset(370, 84), position = UDim2.new(0.5, -380, 0, 510) })
sellButton.Name = "Sell"
UIKit.buttonGlow(sellButton, Color3.fromRGB(150, 255, 120))
local keepButton, keepText = UIKit.priceButton({ parent = center, text = "KEEP IT", color = "Blue", size = UDim2.fromOffset(370, 84), position = UDim2.new(0.5, 10, 0, 510) })
keepButton.Name = "Keep"
sellText.TextSize, keepText.TextSize = 36, 36

local PARTS: { GuiObject } = { title, nameText, storyText, valueText, sellButton, keepButton, view }

local current: string? = nil
local model: Model? = nil
local dist = 12
local token = 0
local burstAt = math.huge -- moment de l'explosion
local storyAt = math.huge
local shake = 0

local function tween(obj: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal):Play()
end

local function shockwave(color: Color3, after: number)
	task.delay(after, function()
		local stroke = new("UIStroke", { Thickness = 14, Color = color })
		local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = RELIC_AT, Size = UDim2.fromOffset(60, 60), BackgroundTransparency = 1, ZIndex = 3, Parent = center }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke })
		tween(ring, 0.9, { Size = UDim2.fromOffset(1050, 1050) })
		tween(stroke, 0.9, { Thickness = 1, Transparency = 1 })
		task.delay(1, function()
			ring:Destroy()
		end)
	end)
end

local function coinRain()
	for i = 1, COINS do
		task.delay(i * 0.05, function()
			local x = math.random()
			local coin = UIKit.icon("Cash", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(46, 46), Position = UDim2.fromScale(x, -0.08), Rotation = math.random(-40, 40), ZIndex = 1, Parent = gui })
			local time = 1.3 + math.random() * 0.8
			tween(coin, time, { Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.1, 1.1), Rotation = math.random(-300, 300) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			task.delay(time + 0.1, function()
				coin:Destroy()
			end)
		end)
	end
end

local function close()
	if not current then
		return
	end
	current = nil
	token += 1
	burstAt, storyAt = math.huge, math.huge
	gui.Enabled = false
	UIKit.setBlur(false)
	if model then
		model:Destroy()
		model = nil
	end
end

local function show(key: string)
	local relic = Config.Relic(key)
	if not relic then
		return
	end
	if model then
		model:Destroy()
	end
	local wasOpen = gui.Enabled
	current = key
	token += 1
	local mine = token
	local function at(time: number, fn: () -> ())
		task.delay(time, function()
			if token == mine then
				fn()
			end
		end)
	end
	local m = RelicModel.Build(key)
	m.Parent = view
	model = m
	local _, size = m:GetBoundingBox()
	dist = size.Magnitude / 2 / math.tan(math.rad(15)) * 0.9
	rays.ImageColor3, glow.ImageColor3 = relic.Color, relic.Color
	nameText.Text = relic.Name
	storyText.Text = relic.Story
	storyText.MaxVisibleGraphemes = 0
	valueText.Text = "WORTH $0"
	sellText.Text = "SELL  $" .. Format.Short(relic.Value)
	for _, part in ipairs(PARTS) do
		part.Visible = false
	end
	omen.Visible = true
	omen.TextTransparency = 1
	tween(omen, 0.4, { TextTransparency = 0 })
	burstAt, storyAt = os.clock() + ANTICIPATION, math.huge
	-- 1. l'attente : le noir se fait, la lueur grandit
	dim.BackgroundTransparency = 0.3
	tween(dim, ANTICIPATION * 0.8, { BackgroundTransparency = 0.05 })
	if not wasOpen then
		UIKit.setBlur(true) -- une seule fois, même si deux reliques s'enchaînent
	end
	gui.Enabled = true
	Sfx.Play("Riser")
	-- 2. l'explosion
	at(ANTICIPATION, function()
		omen.Visible = false
		view.Visible, title.Visible = true, true
		titleScale.Scale = 3
		tween(titleScale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(dim, 0.5, { BackgroundTransparency = 0.3 })
		flash.BackgroundTransparency = 0
		tween(flash, 1, { BackgroundTransparency = 1 })
		shake = 1
		shockwave(relic.Color, 0)
		shockwave(Color3.new(1, 1, 1), 0.14)
		shockwave(GOLD, 0.3)
		UIKit.burst(center, RELIC_AT, relic.Color)
		UIKit.burst(center, RELIC_AT, GOLD)
		Sfx.Play("HatchRare")
		Sfx.Play("Reward")
	end)
	-- 3. l'histoire
	at(ANTICIPATION + STORY_AT, function()
		nameText.Visible, storyText.Visible, valueText.Visible = true, true, true
		nameScale.Scale = 1.8
		tween(nameScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		storyAt = os.clock()
		UIKit.countTo(valueText, 0, relic.Value, function(n: number): string
			return "WORTH $" .. Format.Short(n)
		end, 1.1)
		coinRain()
		Sfx.Play("Coin")
		UIKit.burst(center, UDim2.fromOffset(410, 480), UIKit.Money)
	end)
	-- 4. le choix
	at(ANTICIPATION + CHOICE_AT, function()
		sellButton.Visible, keepButton.Visible = true, true
		UIKit.popIn(sellButton)
		UIKit.popIn(keepButton, 0.08)
	end)
	task.delay(AUTO_CLOSE, function()
		if token == mine then
			close()
		end
	end)
end

Remotes:WaitForChild("RelicFound").OnClientEvent:Connect(show)

keepButton.MouseButton1Click:Connect(function()
	Sfx.Play("Click")
	close()
end)

local selling = false
sellButton.MouseButton1Click:Connect(function()
	local key = current
	if not key or selling then
		return
	end
	selling = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Relics"):InvokeServer("sell", key)
	end)
	selling = false
	if ok and type(res) == "table" and res.ok then
		Sfx.Play("Buy")
		close()
	else
		Sfx.Play("Error")
		UIKit.toast("Try again", "warn")
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not current then
		return
	end
	local t = os.clock()
	local age = t - burstAt
	-- la lueur enfle pendant l'attente, puis la relique arrive en tournoyant et se balance
	if age < 0 then
		local grow = 0.5 + (ANTICIPATION + age) / ANTICIPATION * 0.5
		fx.Size = UDim2.fromOffset(340 * grow, 300 * grow)
		fx.Position = UDim2.fromOffset(410 - 170 * grow, 222 - 150 * grow)
	else
		fx.Size = UDim2.fromOffset(340, 300)
		fx.Position = UDim2.fromOffset(240, 72)
	end
	if model and age >= 0 then
		local spin = math.sin(age * 0.9) * 0.6 + 12 * math.exp(-age * 2.2)
		model:PivotTo(CFrame.Angles(0, spin, 0) * CFrame.new(0, math.sin(age * 1.8) * 0.012 * dist, 0))
		shot.CFrame = CFrame.lookAt(Vector3.new(0, 0.2, 1).Unit * dist * (1 + 3 * math.exp(-age * 5)), Vector3.zero)
	end
	-- texte tapé lettre par lettre
	if t >= storyAt then
		storyText.MaxVisibleGraphemes = math.floor((t - storyAt) * 55)
	end
	for i, star in ipairs(orbiters) do
		local visible = age >= 0
		star.Visible = visible
		if visible then
			local a = t * 1.3 + i * math.pi * 2 / ORBITERS
			local wobble = 158 + math.sin(t * 2 + i) * 22
			star.Position = UDim2.fromOffset(410 + math.cos(a) * wobble, 222 + math.sin(a) * wobble * 0.72)
			star.Rotation = t * 90
			star.ImageTransparency = 0.1 + math.abs(math.sin(t * 3 + i)) * 0.5
		end
	end
	-- tremblement de l'explosion, qui s'amortit
	if shake > 0.01 then
		shake *= math.exp(-dt * 5)
		center.Position = CENTER_POS + UDim2.fromOffset(math.random(-16, 16) * shake, math.random(-16, 16) * shake)
	else
		center.Position = CENTER_POS
	end
end)
