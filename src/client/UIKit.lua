-- Kit d'interface commun à tous les écrans (docs/Interfaces.md, style des jeux d'œufs) :
-- thème, illustrations, composants « gros boutons » et animations.
-- Règles : texte Montserrat très gras blanc à épais contour sombre, contours noirs épais,
-- dégradés vifs, coins arrondis, et tout ce qui se touche réagit (survol, appui).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))

local UIKit = {}

-- ILLUSTRATIONS (générées dans le style des captures de référence) ---------------
UIKit.Art = {
	Cash = "rbxassetid://119781577077916",
	Egg = "rbxassetid://126959641190337",
	Shop = "rbxassetid://102404040034757",
	Upgrades = "rbxassetid://116675420851961",
	Index = "rbxassetid://86262254117516",
	Creatures = "rbxassetid://99114407963651",
	Rewards = "rbxassetid://109708226182903",
	Oxygen = "rbxassetid://117165302090830",
	Settings = "rbxassetid://131831924082787",
	Jetpack = "rbxassetid://101405938770705",
	Comet = "rbxassetid://97641885073649",
	Noise = "rbxassetid://98491956885523",
	Supernova = "rbxassetid://83408422703072",
	Studs = "rbxassetid://99589690361139", -- picots carrés transparents, en fond de panneau
}

-- THÈME ------------------------------------------------------------------
UIKit.Font = Theme.Font
UIKit.Ink = Color3.fromRGB(255, 255, 255)
UIKit.Outline = Color3.fromRGB(22, 22, 32)
UIKit.Panel = Color3.fromRGB(44, 46, 58)
-- Paires (haut, bas) des dégradés de boutons
UIKit.Colors = {
	Green = { Color3.fromRGB(176, 245, 70), Color3.fromRGB(70, 196, 40) },
	Blue = { Color3.fromRGB(110, 205, 255), Color3.fromRGB(30, 120, 235) },
	Purple = { Color3.fromRGB(225, 150, 255), Color3.fromRGB(150, 70, 230) },
	Pink = { Color3.fromRGB(255, 160, 210), Color3.fromRGB(235, 70, 150) },
	Orange = { Color3.fromRGB(255, 205, 100), Color3.fromRGB(245, 130, 30) },
	Red = { Color3.fromRGB(255, 110, 100), Color3.fromRGB(210, 30, 40) },
	Gold = { Color3.fromRGB(255, 232, 110), Color3.fromRGB(240, 170, 20) },
	Teal = { Color3.fromRGB(120, 245, 240), Color3.fromRGB(30, 180, 200) },
	Dark = { Color3.fromRGB(70, 74, 92), Color3.fromRGB(40, 42, 54) },
}
UIKit.Money = Color3.fromRGB(120, 245, 80)

-- OUTILS ------------------------------------------------------------------

function UIKit.new(class: string, props: { [string]: any }?, children: { Instance }?): any
	local o = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			(o :: any)[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if parent then
		o.Parent = parent
	end
	return o
end
local new = UIKit.new

function UIKit.corner(radius: number?): UICorner
	return new("UICorner", { CornerRadius = if radius then UDim.new(0, radius) else UDim.new(0.25, 0) })
end

function UIKit.stroke(thickness: number?, color: Color3?): UIStroke
	return new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or UIKit.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

function UIKit.gradient(top: Color3, bottom: Color3): UIGradient
	return new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = 90 })
end

-- Texte du style « jeu d'œufs » : blanc, gras, épais contour sombre
function UIKit.text(props: { [string]: any }): TextLabel
	local strokeSize = props.Stroke or 2.5
	props.Stroke = nil
	local t = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = UIKit.Font,
		TextColor3 = UIKit.Ink,
		TextScaled = true,
	})
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(t :: any)[k] = v
		end
	end
	new("UIStroke", { Thickness = strokeSize, Color = UIKit.Outline, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round, Parent = t })
	t.Parent = props.Parent
	return t
end

function UIKit.icon(art: string, props: { [string]: any }?): ImageLabel
	local i = new("ImageLabel", { BackgroundTransparency = 1, Image = UIKit.Art[art] or art, ScaleType = Enum.ScaleType.Fit })
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			(i :: any)[k] = v
		end
	end
	i.Parent = (props or {}).Parent
	return i
end

-- Échelle de l'interface selon la taille de l'écran (téléphone → grand écran)
function UIKit.autoScale(root: GuiObject | ScreenGui)
	local scale = new("UIScale", { Parent = root })
	local function update()
		local v = Workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.55, 1.25)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return scale
end

-- ANIMATIONS ---------------------------------------------------------------

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
UIKit.tween = tween

local function scaleOf(g: GuiObject): UIScale
	local s = g:FindFirstChild("AnimScale") :: UIScale?
	if not s then
		s = new("UIScale", { Name = "AnimScale", Parent = g })
	end
	return s :: UIScale
end

-- Apparition en « pop » avec un petit rebond
function UIKit.popIn(g: GuiObject, delay: number?)
	local s = scaleOf(g)
	s.Scale = 0.4
	task.delay(delay or 0, function()
		tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- Petit rebond ponctuel (quand une valeur change)
function UIKit.bump(g: GuiObject, amount: number?)
	local s = scaleOf(g)
	s.Scale = 1 + (amount or 0.12)
	tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Tremblement (soute pleine, erreur)
function UIKit.shake(g: GuiObject)
	local base = g.Rotation
	task.spawn(function()
		for _, r in ipairs({ -6, 6, -4, 4, -2, 0 }) do
			g.Rotation = base + r
			task.wait(0.04)
		end
		g.Rotation = base
	end)
end

-- Reflet qui balaie un bouton de gauche à droite, de temps en temps
function UIKit.shine(g: GuiObject, every: number?)
	local band = new("Frame", {
		Name = "Shine",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		ZIndex = g.ZIndex + 1,
		Parent = g,
	}, { UIKit.corner(), })
	local grad = new("UIGradient", {
		Rotation = 20,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = band,
	})
	task.spawn(function()
		while band.Parent do
			grad.Offset = Vector2.new(-1, 0)
			tween(grad, 0.7, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine)
			task.wait((every or 4) + math.random() * 2)
		end
	end)
	return band
end

-- Compteur qui défile jusqu'à sa nouvelle valeur (un seul défilement à la fois par texte)
local countTokens: { [TextLabel]: {} } = setmetatable({}, { __mode = "k" }) :: any
function UIKit.countTo(label: TextLabel, from: number, to: number, format: (number) -> string, duration: number?)
	local token = {}
	countTokens[label] = token
	task.spawn(function()
		local d = duration or 0.5
		local t0 = os.clock()
		while os.clock() - t0 < d do
			if countTokens[label] ~= token then
				return
			end
			local a = (os.clock() - t0) / d
			a = 1 - (1 - a) ^ 3
			label.Text = format(from + (to - from) * a)
			task.wait()
		end
		if countTokens[label] == token then
			label.Text = format(to)
		end
	end)
end

-- COMPOSANTS ---------------------------------------------------------------

-- Pastille rouge « ! » qui pulse, en haut à droite d'un bouton
function UIKit.badge(parent: GuiObject, text: string?): Frame
	local b = new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -4, 0, 4),
		BackgroundColor3 = Color3.fromRGB(235, 40, 50),
		ZIndex = parent.ZIndex + 5,
		Visible = false,
		Parent = parent,
	}, { UIKit.corner(15), UIKit.stroke(2.5, Color3.new(1, 1, 1)) })
	UIKit.text({ Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Text = text or "!", ZIndex = b.ZIndex + 1, Stroke = 1.5, Parent = b })
	task.spawn(function()
		local s = scaleOf(b)
		while b.Parent do
			if b.Visible then
				tween(s, 0.45, { Scale = 1.18 }, Enum.EasingStyle.Sine)
				task.wait(0.45)
				tween(s, 0.45, { Scale = 1 }, Enum.EasingStyle.Sine)
			end
			task.wait(0.5)
		end
	end)
	return b
end

-- Rend un bouton vivant : se soulève au survol, s'écrase à l'appui
function UIKit.juice(button: GuiButton)
	local s = scaleOf(button)
	button.MouseEnter:Connect(function()
		tween(s, 0.15, { Scale = 1.06 })
	end)
	button.MouseLeave:Connect(function()
		tween(s, 0.15, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		tween(s, 0.08, { Scale = 0.9 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(s, 0.3, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
end

-- Gros bouton « pilule » : dégradé, contour noir, ombre, icône qui déborde à gauche
function UIKit.menuButton(props: { name: string, text: string, art: string, color: string, size: UDim2?, parent: Instance? }): (TextButton, Frame)
	local colors = UIKit.Colors[props.color] or UIKit.Colors.Green
	local holder = new("Frame", { Name = props.name, Size = props.size or UDim2.fromOffset(210, 64), BackgroundTransparency = 1, Parent = props.parent })
	-- Ombre portée
	new("Frame", {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 5),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		Parent = holder,
	}, { UIKit.corner(16) })
	local b = new("TextButton", {
		Name = "Button",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	}, { UIKit.corner(16), UIKit.stroke(3.5), UIKit.gradient(colors[1], colors[2]) })
	-- Reflet clair sur le haut
	new("Frame", {
		Name = "Gloss",
		Size = UDim2.new(1, -16, 0.38, 0),
		Position = UDim2.fromOffset(8, 5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		Parent = b,
	}, { UIKit.corner(10) })
	UIKit.icon(props.art, { Size = UDim2.fromOffset(78, 78), Position = UDim2.new(0, -18, 0.5, -42), ZIndex = 3, Parent = b })
	UIKit.text({ Size = UDim2.new(1, -78, 0.62, 0), Position = UDim2.new(0, 68, 0.19, 0), Text = props.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Stroke = 3, Parent = b })
	UIKit.shine(b, 5)
	UIKit.juice(b)
	return b, UIKit.badge(b)
end

-- Petit bouton rond avec une icône (réglages, raccourcis)
function UIKit.roundButton(props: { name: string, art: string, color: string?, size: number?, parent: Instance? }): TextButton
	local colors = UIKit.Colors[props.color or "Dark"]
	local size = props.size or 58
	local b = new("TextButton", {
		Name = props.name,
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = props.parent,
	}, { UIKit.corner(size / 2), UIKit.stroke(3), UIKit.gradient(colors[1], colors[2]) })
	UIKit.icon(props.art, { Size = UDim2.fromScale(0.82, 0.82), Position = UDim2.fromScale(0.09, 0.07), ZIndex = 2, Parent = b })
	UIKit.juice(b)
	return b
end

-- Pilule d'information (soute, minuteur) : fond sombre, contour noir, icône à gauche
function UIKit.pill(props: { name: string, art: string, size: UDim2?, parent: Instance? }): (Frame, TextLabel)
	local f = new("Frame", {
		Name = props.name,
		Size = props.size or UDim2.fromOffset(190, 52),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = props.parent,
	}, { UIKit.corner(26), UIKit.stroke(3), UIKit.gradient(UIKit.Colors.Dark[1], UIKit.Colors.Dark[2]) })
	UIKit.icon(props.art, { Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, -14, 0.5, -34), ZIndex = 2, Parent = f })
	local t = UIKit.text({ Size = UDim2.new(1, -66, 0.7, 0), Position = UDim2.new(0, 54, 0.15, 0), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = f })
	return f, t
end

-- Jauge verticale (jetpack, oxygène, bruit)
function UIKit.gauge(props: { name: string, art: string, color: string, height: number?, parent: Instance? }): (Frame, Frame)
	local colors = UIKit.Colors[props.color]
	local h = props.height or 150
	local holder = new("Frame", { Name = props.name, Size = UDim2.fromOffset(46, h + 40), BackgroundTransparency = 1, Parent = props.parent })
	local back = new("Frame", {
		Name = "Back",
		Size = UDim2.fromOffset(26, h),
		Position = UDim2.fromOffset(10, 0),
		BackgroundColor3 = UIKit.Colors.Dark[2],
		Parent = holder,
	}, { UIKit.corner(13), UIKit.stroke(3) })
	local fill = new("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = back,
	}, { UIKit.corner(13), UIKit.gradient(colors[1], colors[2]) })
	UIKit.icon(props.art, { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(0, h - 6), ZIndex = 3, Parent = holder })
	return holder, fill
end

-- MESSAGES ---------------------------------------------------------------

local toastStack: Frame? = nil
local function stack(): Frame
	if toastStack and toastStack.Parent then
		return toastStack
	end
	local gui = new("ScreenGui", { Name = "Toasts", ResetOnSpawn = false, DisplayOrder = 20, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(520, 300),
		Position = UDim2.new(0.5, 0, 0, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
	UIKit.autoScale(f)
	toastStack = f
	return f
end

-- Petite bulle qui apparaît en « pop » puis s'efface : good (vert), warn/bad (rouge), info (bleu)
function UIKit.toast(text: string, kind: string?)
	local color = if kind == "good" then "Green" elseif kind == "bad" or kind == "warn" then "Red" else "Blue"
	local colors = UIKit.Colors[color]
	local box = new("Frame", {
		Size = UDim2.fromOffset(460, 50),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = stack(),
	}, { UIKit.corner(25), UIKit.stroke(3), UIKit.gradient(colors[1], colors[2]) })
	UIKit.text({ Size = UDim2.new(1, -30, 0.66, 0), Position = UDim2.new(0, 15, 0.17, 0), Text = text, Parent = box })
	UIKit.popIn(box)
	if kind == "warn" or kind == "bad" then
		UIKit.shake(box)
	end
	task.delay(2.6, function()
		local fade = tween(box, 0.3, { BackgroundTransparency = 1 })
		for _, d in ipairs(box:GetDescendants()) do
			if d:IsA("TextLabel") then
				tween(d, 0.3, { TextTransparency = 1 })
			elseif d:IsA("UIStroke") then
				tween(d, 0.3, { Transparency = 1 })
			end
		end
		fade.Completed:Wait()
		box:Destroy()
	end)
end

-- Gain qui s'envole (« +$12.5K ») à partir d'une position écran
function UIKit.flyText(parent: Instance, text: string, from: UDim2, color: Color3?)
	local t = UIKit.text({
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(220, 44),
		Position = from,
		Text = text,
		TextColor3 = color or UIKit.Money,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 20,
		Stroke = 3,
		Parent = parent,
	})
	UIKit.popIn(t)
	tween(t, 1.1, { Position = from + UDim2.fromOffset(20, -70), TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local stroke = t:FindFirstChildOfClass("UIStroke")
	if stroke then
		tween(stroke, 1.1, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(1.2, function()
		t:Destroy()
	end)
end

-- Signaux entre scripts (ex. le HUD ouvre la fenêtre d'améliorations de Interface)
UIKit.Open = new("BindableEvent", { Name = "UIKitOpen" })

return UIKit
