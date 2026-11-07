-- Téléphones et tablettes.
-- 1. Gros bouton DRILL juste à gauche du bouton de saut de Roblox (qui sert aussi à voler : le maintenir
--    pousse le jetpack), à sa taille et recalé quand l'écran tourne ou change. Tant qu'on le tient, on
--    fore la roche la plus proche à portée (attribut local DrillHeld, lu par Controls.client) : plus
--    besoin de viser la roche du doigt. Il devient vert quand une roche est à portée (RockNear).
--    Visible seulement quand on joue au doigt (Device) : un PC tactile à la souris ne le voit pas.
-- 2. Mode allégé sur les appareils tactiles sans clavier : moitié moins de particules partout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Device = require(script.Parent:WaitForChild("Device"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local new = UIKit.new

if not UserInputService.TouchEnabled then
	return
end

-- BOUTON FORER --------------------------------------------------------------------------

local gui = new("ScreenGui", { Name = "Mobile", ResetOnSpawn = false, DisplayOrder = 3, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
local SIZE = 116
local size = SIZE
local drill = UIKit.roundButton({ name = "Drill", art = "UpDrill", color = "Orange", size = SIZE, parent = gui })
drill.AnchorPoint = Vector2.new(0.5, 0.5)
drill.Position = UDim2.new(1, -220, 1, -150)
UIKit.studs(drill, 0.5, "Studs", 18).UICorner.CornerRadius = UDim.new(0.5, 0)
UIKit.text({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 1, -30),
	Size = UDim2.new(1.1, 0, 0, 34),
	Text = "DRILL",
	Stroke = 3,
	ZIndex = 4,
	Parent = drill,
})
local halo = UIKit.glow(drill, { color = Color3.fromRGB(120, 255, 90), size = SIZE * 2, transparency = 1, z = 0 })
local grad = drill:FindFirstChildOfClass("UIGradient") :: UIGradient

local function setHeld(on: boolean)
	player:SetAttribute("DrillHeld", if on then true else nil)
	local s = if on then size * 0.92 else size
	drill.Size = UDim2.fromOffset(s, s)
end

-- À gauche du bouton de saut de Roblox, 25 % plus gros que lui, un peu plus haut pour le pouce.
-- Sans bouton de saut trouvé : en bas à droite.
local function place()
	local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
	local jump = touchGui and touchGui:FindFirstChild("JumpButton", true) :: GuiObject?
	if jump and jump.AbsoluteSize.X > 10 then
		size = math.floor(math.clamp(jump.AbsoluteSize.X * 1.25, 80, 140))
		local c = jump.AbsolutePosition + jump.AbsoluteSize / 2 - gui.AbsolutePosition
		drill.Position = UDim2.fromOffset(c.X - jump.AbsoluteSize.X / 2 - size * 0.62, c.Y - size * 0.35)
	else
		local v = workspace.CurrentCamera.ViewportSize
		size = math.floor(math.clamp(math.min(v.X, v.Y) * 0.22, 80, 140))
		drill.Position = UDim2.new(1, -size * 1.9, 1, -size * 1.3)
	end
	setHeld(player:GetAttribute("DrillHeld") == true)
end

local function refreshShown()
	local on = Device.IsTouch()
	gui.Enabled = on
	if not on then
		setHeld(false)
	else
		task.defer(place)
	end
end
Device.Changed:Connect(refreshShown)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	task.defer(place)
end)
-- le bouton de saut arrive avec le personnage
player.CharacterAdded:Connect(function()
	task.delay(1, place)
end)
task.delay(1, place)
refreshShown()
drill.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setHeld(true)
	end
end)
drill.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setHeld(false)
	end
end)
-- le doigt glisse hors du bouton ou l'appli passe en arrière-plan : on arrête
UserInputService.WindowFocusReleased:Connect(function()
	setHeld(false)
end)

local function refresh()
	local near = player:GetAttribute("RockNear") == true
	local colors = UIKit.Colors[if near then "Green" else "Orange"]
	grad.Color = ColorSequence.new(colors[1], colors[2])
	halo.ImageTransparency = if near then 0.45 else 1
end
player:GetAttributeChangedSignal("RockNear"):Connect(refresh)
refresh()

-- MODE ALLÉGÉ ---------------------------------------------------------------------------

if UserInputService.KeyboardEnabled then
	return
end
player:SetAttribute("Lite", true)
local LITE = Config.Mobile.ParticleScale
local seen = setmetatable({}, { __mode = "k" })
local function lighten(d: Instance)
	if d:IsA("ParticleEmitter") and not seen[d] then
		seen[d] = true
		-- après les réglages du script qui l'a créé
		task.defer(function()
			d.Rate *= LITE
		end)
	end
end
for _, d in ipairs(workspace:GetDescendants()) do
	lighten(d)
end
workspace.DescendantAdded:Connect(lighten)
