-- Oxygène de l'œuf (règle : ColdService, Config.Oxygen) : quand on porte un œuf hors du vaisseau,
-- une jauge d'air se vide sous l'emplacement de l'œuf (en haut à droite) avec le temps restant.
-- Sous Config.Oxygen.Low : elle passe au rouge et tremble, l'écran bat en rouge, un bip chaque seconde,
-- « HURRY HOME! » au centre. À zéro (personnage Suffocated) : flash rouge et « OUT OF AIR! ».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local player = Players.LocalPlayer
local new = UIKit.new
local O = Config.Oxygen
local SAFE_A, SAFE_B = Color3.fromRGB(140, 240, 255), Color3.fromRGB(40, 140, 255)
local LOW_A, LOW_B = Color3.fromRGB(255, 130, 120), Color3.fromRGB(215, 30, 45)

local gui = new("ScreenGui", { Name = "OxygenFx", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, Parent = player:WaitForChild("PlayerGui") })

-- jauge juste sous l'emplacement de l'œuf (dans son groupe du HUD : même échelle, même place)
local eggGroup = player.PlayerGui:WaitForChild("MainHUD"):WaitForChild("Egg", 10) :: Frame?
local holder = new("Frame", {
	Name = "Oxygen",
	Position = UDim2.fromOffset(0, 100),
	Size = UDim2.fromOffset(280, 56),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = eggGroup or gui,
})
if not eggGroup then
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, -18, 0, 112)
	UIKit.autoScale(holder)
end
local box = new("Frame", {
	Name = "Box",
	Position = UDim2.fromOffset(10, 0),
	Size = UDim2.fromOffset(270, 50),
	BackgroundColor3 = Color3.fromRGB(20, 26, 44),
	Parent = holder,
}, { UIKit.corner(), UIKit.stroke(4) })
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = box }, { UIKit.corner() })
local grad = UIKit.gradient(SAFE_A, SAFE_B)
grad.Parent = fill
-- reflet sur le haut
new("Frame", { Size = UDim2.new(1, -10, 0.35, 0), Position = UDim2.fromOffset(5, 4), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, ZIndex = 3, Parent = box }, { UIKit.corner() })
local icon = UIKit.icon("Oxygen", { Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(-22, -8), ZIndex = 5, Parent = box })
local label = UIKit.text({
	Size = UDim2.new(1, -60, 0.8, 0),
	Position = UDim2.new(0, 48, 0.1, 0),
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 3,
	ZIndex = 4,
	Parent = box,
})

-- bords de l'écran qui battent en rouge
local vignette = new("ImageLabel", {
	Name = "Vignette",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = Config.Cold.Art.Vignette,
	ImageColor3 = Color3.fromRGB(255, 40, 50),
	ImageTransparency = 1,
	ZIndex = 0,
	Parent = gui,
})
local hurry = UIKit.text({
	Name = "Hurry",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromOffset(600, 70),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 90, 90),
	Stroke = 5,
	Visible = false,
	ZIndex = 6,
	Parent = gui,
})
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 40, 40), BackgroundTransparency = 1, ZIndex = 7, Parent = gui })

local function clock(s: number): string
	s = math.max(0, math.ceil(s))
	return ("%d:%02d"):format(s // 60, s % 60)
end

local lastBeep = -1
local wasShown = false

RunService.RenderStepped:Connect(function()
	local left = player:GetAttribute("O2Left") :: number?
	local max = player:GetAttribute("O2Max") :: number?
	if not left or not max or max <= 0 then
		if wasShown then
			wasShown = false
			holder.Visible = false
			hurry.Visible = false
			vignette.ImageTransparency = 1
		end
		return
	end
	if not wasShown then
		wasShown = true
		holder.Visible = true
		UIKit.popIn(box)
	end
	local f = math.clamp(left / max, 0, 1)
	local low = f <= O.Low
	local now = os.clock()
	fill.Size = UDim2.fromScale(math.max(f, 0.03), 1)
	grad.Color = if low then ColorSequence.new(LOW_A, LOW_B) else ColorSequence.new(SAFE_A, SAFE_B)
	label.Text = "AIR " .. clock(left)
	if low then
		-- tremble, l'écran bat en rouge de plus en plus vite, bip chaque seconde
		local urgency = 1 - f / O.Low
		box.Position = UDim2.fromOffset(10 + math.sin(now * 40) * 3 * urgency, 0)
		local beat = 0.5 + 0.5 * math.sin(now * math.pi * 2 * (1.2 + urgency * 1.8))
		vignette.ImageTransparency = 1 - (0.35 + 0.45 * urgency) * beat
		hurry.Visible = true
		hurry.Text = "HURRY HOME! " .. clock(left)
		hurry.Rotation = math.sin(now * 6) * 3
		local sec = math.ceil(left)
		if sec ~= lastBeep then
			lastBeep = sec
			Sfx.Play("Warning", { volume = 0.6 + urgency * 0.6, pitch = 1 + urgency * 0.3 })
			UIKit.bump(icon, 0.25)
		end
	else
		box.Position = UDim2.fromOffset(10, 0)
		vignette.ImageTransparency = 1
		hurry.Visible = false
	end
end)

-- plus d'air : flash rouge et grand message
local function watch(character: Model)
	character:GetAttributeChangedSignal("Suffocated"):Connect(function()
		if not character:GetAttribute("Suffocated") then
			return
		end
		flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
		hurry.Visible = true
		hurry.Text = "OUT OF AIR!"
		task.delay(1.6, function()
			if not player:GetAttribute("O2Left") then
				hurry.Visible = false
			end
		end)
	end)
end
if player.Character then
	watch(player.Character)
end
player.CharacterAdded:Connect(watch)
