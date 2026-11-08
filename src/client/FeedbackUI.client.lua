-- Boîte à retours : la fenêtre qui s'ouvre sur le tapis de la boîte aux lettres du vaisseau
-- (ShipShops.client, UIKit.Open "Feedback"). Pour un enfant : on choisit un gros bouton (bug, idée,
-- trop dur, j'adore), écrire un texte est facultatif. Le serveur décide de tout (FeedbackService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local F = Config.Feedback
local new = UIKit.new

local W_SIZE = Vector2.new(760, 540)
local GAP = 22
local win = UIKit.window({ name = "Feedback", title = "{Star} TELL US!", color = "Teal", size = W_SIZE })
win.body.Visible = false

local function label(text: string, y: number, h: number, size: number, color: Color3?): TextLabel
	local t = UIKit.text({
		Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, h),
		Position = UDim2.fromOffset(GAP, y),
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		ZIndex = 5,
		Stroke = 3,
		Parent = win.frame,
	})
	new("UITextSizeConstraint", { MaxTextSize = size, MinTextSize = 10, Parent = t })
	return t
end

label("What do you want to tell us?", 96, 36, 30)

-- GROS BOUTONS : une catégorie à choisir
local CHIP_W = math.floor((W_SIZE.X - GAP * 2 - 12 * (#F.Categories - 1)) / #F.Categories)
local chosen: string? = nil
local chips: { { key: string, color: string, grad: UIGradient, button: TextButton } } = {}

local function refreshChips()
	for _, c in ipairs(chips) do
		UIKit.recolor(c.grad, if chosen == nil or chosen == c.key then c.color else "Grey")
		local stroke = c.button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if chosen == c.key then Color3.fromRGB(255, 225, 110) else UIKit.Outline
			stroke.Thickness = if chosen == c.key then 5 else 3.5
		end
	end
end

for i, c in ipairs(F.Categories) do
	local b, text, grad = UIKit.priceButton({
		parent = win.frame,
		text = c.Label,
		color = c.Color,
		size = UDim2.fromOffset(CHIP_W, 78),
		position = UDim2.fromOffset(GAP + (i - 1) * (CHIP_W + 12), 140),
	})
	b.Name = c.Key
	text.TextSize = 24
	UIKit.icon(c.Art, { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(-8, -14), ZIndex = 7, Parent = b })
	table.insert(chips, { key = c.Key, color = c.Color, grad = grad, button = b })
	b.MouseButton1Click:Connect(function()
		chosen = c.Key
		Sfx.Play("Click")
		UIKit.bump(b, 0.12)
		refreshChips()
	end)
end

-- TEXTE (facultatif)
local boxFrame = new("Frame", {
	Name = "BoxFrame",
	Size = UDim2.fromOffset(W_SIZE.X - GAP * 2, 150),
	Position = UDim2.fromOffset(GAP, 232),
	BackgroundColor3 = Color3.fromRGB(26, 28, 40),
	ZIndex = 3,
	Parent = win.frame,
}, { UIKit.corner(14), UIKit.stroke(3.5) })
local box = new("TextBox", {
	Name = "Message",
	Size = UDim2.new(1, -24, 1, -36),
	Position = UDim2.fromOffset(12, 8),
	BackgroundTransparency = 1,
	ClearTextOnFocus = false,
	MultiLine = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	FontFace = UIKit.Font,
	TextSize = 24,
	TextColor3 = Color3.new(1, 1, 1),
	PlaceholderText = "Write here if you want...",
	PlaceholderColor3 = Color3.fromRGB(150, 155, 175),
	Text = "",
	ZIndex = 4,
	Parent = boxFrame,
})
local counter = UIKit.text({
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(120, 24),
	Position = UDim2.new(1, -10, 1, -4),
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(170, 175, 195),
	ZIndex = 5,
	Stroke = 2,
	Parent = boxFrame,
})
box:GetPropertyChangedSignal("Text"):Connect(function()
	local n = utf8.len(box.Text)
	if n and n > F.MaxChars then
		box.Text = string.sub(box.Text, 1, (utf8.offset(box.Text, F.MaxChars + 1) :: number) - 1)
		return
	end
	counter.Text = ("%d / %d"):format(n or 0, F.MaxChars)
end)
counter.Text = ("0 / %d"):format(F.MaxChars)

label("Never write your name, address or password.", 388, 28, 22, Color3.fromRGB(255, 215, 150))

-- ENVOYER
local send, sendText = UIKit.priceButton({
	parent = win.frame,
	text = "SEND",
	color = "Green",
	size = UDim2.fromOffset(300, 76),
	position = UDim2.new(0.5, -150, 0, 436),
})
send.Name = "Send"
sendText.TextSize = 36
UIKit.buttonGlow(send, Color3.fromRGB(170, 255, 90))

local busy = false
send.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	if not chosen then
		Sfx.Play("Error")
		UIKit.toast("Pick one of the big buttons first!", "warn")
		for _, c in ipairs(chips) do
			UIKit.shake(c.button)
		end
		return
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Feedback"):InvokeServer("send", chosen, box.Text)
	end)
	busy = false
	if ok and type(res) == "table" and res.ok then
		Sfx.Play("Reward")
		UIKit.burst(win.frame, UDim2.fromScale(0.5, 0.7), Color3.fromRGB(120, 245, 240))
		UIKit.toast("{Star} Thank you! We read everything", "good")
		box.Text = ""
		chosen = nil
		refreshChips()
		win.close()
	else
		Sfx.Play("Error")
		UIKit.toast(if ok and type(res) == "table" and res.error then res.error else "Try again", "warn")
	end
end)

UIKit.Open.Event:Connect(function(what: string)
	if what == "Feedback" then
		win.open(refreshChips)
	end
end)
