-- Téléphones et tablettes (écran tactile sans clavier).
-- 1. Gros bouton FORER à côté du bouton de saut de Roblox (qui sert aussi à voler : le maintenir pousse
--    le jetpack). Tant qu'on le tient, on fore la roche la plus proche à portée (attribut local
--    DrillHeld, lu par Controls.client) : plus besoin de viser la roche du doigt. Il devient vert et
--    pulse quand une roche est à portée (RockNear), gris sinon.
-- 2. Mode allégé : moitié moins de particules partout (les téléphones chauffent vite).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local new = UIKit.new

if not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled then
	return
end

-- BOUTON FORER --------------------------------------------------------------------------

local gui = new("ScreenGui", { Name = "Mobile", ResetOnSpawn = false, DisplayOrder = 3, Parent = player:WaitForChild("PlayerGui") })
local SIZE = 116
local drill = UIKit.roundButton({ name = "Drill", art = "UpDrill", color = "Orange", size = SIZE, parent = gui })
drill.AnchorPoint = Vector2.new(0.5, 0.5)
-- à gauche du bouton de saut de Roblox (en bas à droite), un peu plus haut pour le pouce
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
	drill.Size = UDim2.fromOffset(if on then SIZE * 0.92 else SIZE, if on then SIZE * 0.92 else SIZE)
end
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
