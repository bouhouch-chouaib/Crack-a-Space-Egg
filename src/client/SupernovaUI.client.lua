-- Fenêtre SUPERNOVA (renaissance, docs/Interfaces.md §11), ouverte par le bouton SUPERNOVA du HUD
-- (UIKit.Open "Supernova"), et l'explosion d'étoile qui suit.
-- En haut : l'étoile qui pulse, « SUPERNOVA #N » et le multiplicateur d'argent avant -> après.
-- Au milieu, trois cartes faciles à lire pour un enfant : YOU LOSE / YOU KEEP / YOU GET.
-- En bas : barre de progression vers le prix et le gros bouton (deux appuis : le second confirme).
-- Le serveur décide de tout (SupernovaService, Remotes.Supernova).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

local W_SIZE = Vector2.new(980, 640)
local GAP = 14
local GOLD = Color3.fromRGB(255, 220, 90)
local STAR = Color3.fromRGB(255, 170, 60)

local win = UIKit.window({ name = "Supernova", title = "{Supernova} SUPERNOVA", color = "Orange", size = W_SIZE })
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

local function multText(n: number): string
	return "x" .. (string.gsub(string.format("%.1f", Config.SupernovaMult(n)), "%.0$", ""))
end

local function count(): number
	return (player:GetAttribute("Supernovas") or 0) :: number
end

-- HAUT : l'étoile et le multiplicateur -------------------------------------------------------
local hero = new("Frame", { Name = "Hero", Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, 150), Position = UDim2.fromOffset(GAP, 94), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = win.frame }, {
	UIKit.corner(14),
	UIKit.gradient(Color3.fromRGB(70, 30, 90), Color3.fromRGB(25, 18, 45)),
})
UIKit.stroke(3.5, Color3.fromRGB(20, 12, 30)).Parent = hero
UIKit.studs(hero, 0.7, "Inlets", 24)
local starFx = new("Frame", { Name = "StarFx", Size = UDim2.fromOffset(150, 150), Position = UDim2.fromOffset(4, 0), BackgroundTransparency = 1, ZIndex = 3, Parent = hero })
UIKit.rays(starFx, { color = STAR, size = 210, speed = 30, transparency = 0.35, z = 3 })
UIKit.glow(starFx, { color = GOLD, size = 180, transparency = 0.3, z = 3, pulse = 0.1 })
UIKit.sparkles(starFx, { count = 5, color = Color3.fromRGB(255, 240, 200), size = 18, z = 6 })
local starIcon = UIKit.icon("Supernova", { Size = UDim2.fromOffset(124, 124), Position = UDim2.fromOffset(13, 13), ZIndex = 5, Parent = starFx })
UIKit.float(starIcon, 3, 8, 1.6)
local titleText = label(hero, "", 166, 14, 420, 54, 46, GOLD, Enum.TextXAlignment.Left)
UIKit.shinyText(titleText, GOLD)
label(hero, "Blow up your star, start again RICHER!", 166, 70, 420, 30, 24, Color3.fromRGB(240, 225, 255), Enum.TextXAlignment.Left)
label(hero, "Your creatures stay with you.", 166, 102, 420, 28, 21, Color3.fromRGB(190, 255, 170), Enum.TextXAlignment.Left)
-- multiplicateur : avant -> après
local multBox = new("Frame", { Name = "Mult", Size = UDim2.fromOffset(330, 122), Position = UDim2.new(1, -344, 0, 14), BackgroundColor3 = Color3.fromRGB(20, 14, 32), BackgroundTransparency = 0.2, ZIndex = 3, Parent = hero }, { UIKit.corner(12) })
label(multBox, "MONEY FOREVER", 0, 4, 330, 28, 22, Color3.fromRGB(230, 220, 255))
local multFrom = label(multBox, "", 6, 34, 120, 70, 40, Color3.fromRGB(200, 200, 215))
UIKit.icon("ArrowUp", { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(139, 44), Rotation = 90, ZIndex = 6, Parent = multBox })
local multTo = label(multBox, "", 200, 30, 126, 78, 58, UIKit.Money)
UIKit.wiggle(multTo, 4, 2)

-- MILIEU : on perd / on garde / on gagne -----------------------------------------------------
local COL_W = math.floor((W_SIZE.X - GAP * 2 - 24) / 3)
local function column(i: number, title: string, color: string, lines: { { string } }): Frame
	local c = UIKit.Colors[color]
	local f = new("Frame", { Name = title, Size = UDim2.fromOffset(COL_W, 246), Position = UDim2.fromOffset(GAP + (i - 1) * (COL_W + 12), 256), BackgroundColor3 = Color3.fromRGB(30, 32, 44), ZIndex = 2, Parent = win.frame }, {
		UIKit.corner(14),
	})
	UIKit.stroke(3.5, c[2]:Lerp(Color3.new(0, 0, 0), 0.3)).Parent = f
	UIKit.studs(f, 0.75, "Inlets", 22)
	local head = new("Frame", { Name = "Head", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = f }, {
		UIKit.corner(14),
		UIKit.gradient(c[1], c[2]),
		UIKit.stroke(3),
	})
	UIKit.studs(head, 0.6, "Weld", 18)
	label(head, title, 0, 4, COL_W, 36, 30)
	for j, line in ipairs(lines) do
		local y = 50 + (j - 1) * 34
		UIKit.icon(line[1], { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(12, y), ZIndex = 4, Parent = f })
		label(f, line[2], 54, y + 3, COL_W - 62, 28, 23, nil, Enum.TextXAlignment.Left)
	end
	return f
end
local loseCol = column(1, "YOU LOSE", "Red", {
	{ "Cash", "Your money" },
	{ "UpDrill", "Your drill" },
	{ "Jetpack", "Jetpack level" },
	{ "WindTunnel", "Wind tunnel" },
	{ "MachineUp", "Scanner & machine" },
})
local loseNote = label(loseCol, "(Robux drills stay!)", 8, 218, COL_W - 16, 22, 18, Color3.fromRGB(255, 200, 190))
column(2, "YOU KEEP", "Green", {
	{ "Creatures", "All creatures" },
	{ "Egg", "Your eggs" },
	{ "Index", "Your Index" },
	{ "Sparkles", "Your gems" },
	{ "Star", "Skins & passes" },
})
local get = column(3, "YOU GET", "Gold", {})
local getBig = label(get, "+50%", 0, 56, COL_W, 80, 72, UIKit.Money)
UIKit.shinyText(getBig, UIKit.Money)
label(get, "MONEY", 0, 132, COL_W, 34, 30, Color3.new(1, 1, 1))
label(get, "from creatures, forever!", 8, 166, COL_W - 16, 26, 21, Color3.fromRGB(230, 230, 245))
label(get, "Stacks, and unlocks base skins!", 8, 202, COL_W - 16, 24, 19, GOLD)
UIKit.sparkles(get, { count = 4, color = GOLD, size = 16, z = 6 })

-- BAS : progression et gros bouton ------------------------------------------------------------
local barBack = new("Frame", { Name = "Progress", Size = UDim2.fromOffset(560, 46), Position = UDim2.fromOffset(GAP, 528), BackgroundColor3 = Color3.fromRGB(25, 28, 44), ZIndex = 3, Parent = win.frame }, { UIKit.corner(), UIKit.stroke(3.5) })
local barFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, Parent = barBack }, {
	UIKit.corner(),
	UIKit.gradient(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 130, 40)),
})
UIKit.shine(barFill, 3)
local barText = label(barBack, "", 8, 4, 544, 38, 28)
barText.ZIndex = 6
local needText = label(win.frame, "", GAP, 578, 560, 30, 22, Color3.fromRGB(230, 230, 245))
local goButton, goText, goGrad = UIKit.priceButton({ parent = win.frame, text = "SUPERNOVA!", color = "Grey", size = UDim2.fromOffset(370, 82), position = UDim2.new(1, -384, 0, 524) })
goButton.Name = "Go"
goText.TextSize = 38
local goGlow = UIKit.buttonGlow(goButton, STAR)

local armedUntil = 0 -- premier appui : on demande confirmation pendant quelques secondes
local busy = false

local function refresh()
	local n = count()
	local cost = Config.SupernovaCost(n)
	local credits = (player:GetAttribute("Credits") or 0) :: number
	local levelOk = ((player:GetAttribute("JetLevel") or 1) :: number) >= Config.Supernova.Level
	local ready = credits >= cost and levelOk
	titleText.Text = ("SUPERNOVA #%d"):format(n + 1)
	multFrom.Text = multText(n)
	multTo.Text = multText(n + 1)
	barFill.Size = UDim2.fromScale(math.clamp(credits / cost, 0, 1), 1)
	barText.Text = ("$%s / $%s"):format(Format.Short(math.min(credits, cost)), Format.Short(cost))
	needText.Text = if not levelOk then ("Reach Jetpack Lv %d first!"):format(Config.Supernova.Level)
		elseif ready then "Ready! Your star is about to explode!"
		else ("Earn $%s more to explode"):format(Format.Short(cost - credits))
	loseNote.Visible = ((player:GetAttribute("Drill") or 1) :: number) > 1
	local armed = os.clock() < armedUntil
	UIKit.recolor(goGrad, if not ready then "Grey" elseif armed then "Red" else "Orange")
	goText.Text = if not ready then "NOT YET" elseif armed then "SURE? TAP AGAIN!" else "SUPERNOVA!"
	goGlow.Visible = ready
end

-- EXPLOSION : l'étoile grossit en tournant, rayons, flash blanc, puis on se réveille à la base ------
local fxGui = new("ScreenGui", { Name = "SupernovaFx", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 250, 235), BackgroundTransparency = 1, ZIndex = 1, Parent = fxGui })
local center = new("Frame", { Name = "Center", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 2, Parent = fxGui })
-- (images simples : les halos de UIKit se redimensionnent tout seuls à chaque image)
local function fxImage(name: string, art: string, color: Color3, z: number): ImageLabel
	return new("ImageLabel", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Image = UIKit.Art[art], ImageColor3 = color, ZIndex = z, Parent = center })
end
local boomRays = fxImage("Rays", "FxRays", STAR, 2)
local boomGlow = fxImage("Glow", "FxGlow", GOLD, 3)
local boomStar = fxImage("Star", "Supernova", Color3.new(1, 1, 1), 4)
-- les textes sont dans un cadre à l'échelle de l'écran (le rebond se fait sur les textes eux-mêmes)
local textBox = new("Frame", { Name = "Texts", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 280), BackgroundTransparency = 1, ZIndex = 8, Parent = fxGui })
UIKit.autoScale(textBox)
local boomTitle = UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(900, 130), Text = "SUPERNOVA!", TextColor3 = GOLD, TextTransparency = 1, ZIndex = 8, Stroke = 6, Parent = textBox })
local boomSub = UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.fromOffset(800, 70), Text = "", TextColor3 = UIKit.Money, TextTransparency = 1, ZIndex = 8, Stroke = 5, Parent = textBox })

local function tw(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tween = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function explode(mult: number)
	local delay = Config.Supernova.Delay
	fxGui.Enabled = true
	flash.BackgroundTransparency = 1
	boomTitle.TextTransparency, boomSub.TextTransparency = 1, 1
	boomSub.Text = ("Money x%s forever!"):format((string.gsub(string.format("%.1f", mult), "%.0$", "")))
	for _, g in ipairs({ boomRays, boomGlow, boomStar } :: { GuiObject }) do
		g.Size = UDim2.fromOffset(10, 10)
		g.Rotation = 0
	end
	boomRays.ImageTransparency, boomGlow.ImageTransparency, boomStar.ImageTransparency = 0.1, 0, 0
	tw(boomRays, delay + 3, { Rotation = 540 }, Enum.EasingStyle.Linear)
	Sfx.Play("Riser")
	-- l'étoile enfle en tournant
	tw(boomStar, delay * 0.55, { Size = UDim2.fromOffset(260, 260), Rotation = 200 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tw(boomGlow, delay * 0.55, { Size = UDim2.fromOffset(520, 520) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(boomRays, delay * 0.55, { Size = UDim2.fromOffset(700, 700) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(delay * 0.55)
	-- BOUM : tout explose et l'écran devient blanc
	Sfx.Play("HatchRare")
	Sfx.Play("RockBreak", { pitch = 0.6 })
	tw(boomRays, 0.5, { Size = UDim2.fromOffset(3000, 3000), ImageTransparency = 0.4 })
	tw(boomGlow, 0.5, { Size = UDim2.fromOffset(2600, 2600) })
	tw(boomStar, 0.35, { Size = UDim2.fromOffset(900, 900), ImageTransparency = 1 })
	tw(flash, 0.35, { BackgroundTransparency = 0 })
	tw(boomTitle, 0.3, { TextTransparency = 0 })
	UIKit.bump(boomTitle, 0.3)
	task.wait(0.4)
	tw(boomSub, 0.3, { TextTransparency = 0 })
	UIKit.bump(boomSub, 0.25)
	Sfx.Play("Reward")
	-- le serveur nous renvoie à la base pendant le blanc ; on attend le nouveau personnage
	local deadline = os.clock() + delay + 3
	local old = player.Character
	while player.Character == old and os.clock() < deadline do
		task.wait(0.1)
	end
	task.wait(0.8)
	tw(boomRays, 1.2, { ImageTransparency = 1 })
	tw(boomGlow, 1.2, { ImageTransparency = 1 })
	tw(boomTitle, 1, { TextTransparency = 1 })
	tw(boomSub, 1, { TextTransparency = 1 })
	tw(flash, 1.4, { BackgroundTransparency = 1 }).Completed:Wait()
	fxGui.Enabled = false
	UIKit.toast(("{Supernova} New start! Money x%s forever"):format((string.gsub(string.format("%.1f", mult), "%.0$", ""))), "good")
end

goButton.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	if ((player:GetAttribute("JetLevel") or 1) :: number) < Config.Supernova.Level then
		Sfx.Play("Error")
		UIKit.shake(goButton)
		UIKit.toast(("Reach Jetpack Lv %d first!"):format(Config.Supernova.Level), "warn")
		return
	end
	local cost = Config.SupernovaCost(count())
	if ((player:GetAttribute("Credits") or 0) :: number) < cost then
		Sfx.Play("Error")
		UIKit.shake(goButton)
		UIKit.toast(("Earn $%s to go Supernova!"):format(Format.Short(cost)), "warn")
		return
	end
	-- premier appui : confirmation
	if os.clock() >= armedUntil then
		armedUntil = os.clock() + 4
		Sfx.Play("Warning")
		UIKit.bump(goButton, 0.15)
		refresh()
		task.delay(4.05, refresh)
		return
	end
	armedUntil = 0
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Supernova"):InvokeServer("go")
	end)
	if ok and type(res) == "table" and res.ok then
		win.close()
		explode(res.mult)
	else
		Sfx.Play("Error")
		UIKit.toast(if ok and type(res) == "table" and res.error then res.error else "Try again", "warn")
	end
	busy = false
	refresh()
end)

player.AttributeChanged:Connect(function(name)
	if win.isOpen() and (name == "Credits" or name == "Supernovas" or name == "Drill" or name == "JetLevel") then
		refresh()
	end
end)

UIKit.Open.Event:Connect(function(what: string)
	if what ~= "Supernova" then
		return
	end
	armedUntil = 0
	win.open(refresh)
end)
