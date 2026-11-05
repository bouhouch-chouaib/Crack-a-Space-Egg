-- Repères qui guident sans lire (docs/Direction-artistique.md §7 bis) :
-- - une grande maison « YOUR BASE » qui flotte au-dessus de SA base (lui seul la voit) ;
-- - la bannière d'événement au-dessus du portique LAUNCH, avec son compte à rebours.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))

local player = Players.LocalPlayer

-- MAISON « YOUR BASE » ------------------------------------------------------

local marker: BillboardGui? = nil

local function buildMarker(adornee: BasePart): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "YourBaseMarker"
	gui.Adornee = adornee
	gui.Size = UDim2.fromScale(12, 12) -- en studs : grandit et rapetisse avec la distance
	gui.StudsOffsetWorldSpace = Vector3.new(0, 22, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 2000
	gui.LightInfluence = 0

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(1, 0.72)
	icon.BackgroundTransparency = 1
	icon.Text = "🏠"
	icon.TextScaled = true
	icon.Parent = gui

	local text = Instance.new("TextLabel")
	text.Name = "Label"
	text.Size = UDim2.fromScale(1.6, 0.3)
	text.Position = UDim2.fromScale(-0.3, 0.7)
	text.BackgroundTransparency = 1
	text.Text = "YOUR BASE"
	text.TextScaled = true
	text.FontFace = Theme.Font
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.fromRGB(30, 35, 60)
	text.Parent = gui

	-- Petit rebond continu, pour attirer l'œil
	local up = TweenService:Create(gui, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		StudsOffsetWorldSpace = Vector3.new(0, 25, 0),
	})
	up:Play()
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

local function refreshMarker()
	if marker then
		marker:Destroy()
		marker = nil
	end
	local index = player:GetAttribute("Base")
	local ship = workspace:FindFirstChild("Ship")
	local bases = ship and ship:FindFirstChild("Bases")
	local base = bases and type(index) == "number" and bases:FindFirstChild("Base" .. index)
	local floor = base and base:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		marker = buildMarker(floor)
	end
end

player:GetAttributeChangedSignal("Base"):Connect(refreshMarker)
task.spawn(function()
	-- Le vaisseau peut arriver un peu après (chargement en continu)
	workspace:WaitForChild("Ship", 30)
	refreshMarker()
end)

-- On cache la maison quand on est déjà dans sa base : elle ne sert qu'à la retrouver
RunService.Heartbeat:Connect(function()
	if not marker or not marker.Adornee then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local d = (root.Position - (marker.Adornee :: BasePart).Position).Magnitude
		marker.Enabled = d > 26
	end
end)

-- BANNIÈRE D'ÉVÉNEMENT -------------------------------------------------------

local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

task.spawn(function()
	local world = workspace:WaitForChild("World", 30)
	local banner = world and world:WaitForChild("EventBanner", 30)
	if not banner then
		return
	end
	local bg = banner:WaitForChild("BannerGui"):WaitForChild("Background")
	local title = bg:WaitForChild("Title") :: TextLabel
	local timer = bg:WaitForChild("Timer") :: TextLabel
	local stroke = bg:FindFirstChildOfClass("UIStroke")
	while true do
		local now = workspace:GetServerTimeNow()
		local name = workspace:GetAttribute("EventName") or "Event"
		local icon = workspace:GetAttribute("EventIcon") or "⭐"
		if workspace:GetAttribute("EventActive") then
			title.Text = string.format("%s %s!", icon, string.upper(name))
			timer.Text = "ENDS IN " .. clock((workspace:GetAttribute("EventEndsAt") or now) - now)
			-- Le cadre clignote doucement en or pendant l'événement
			if stroke then
				stroke.Color = if math.floor(now * 2) % 2 == 0 then Color3.fromRGB(255, 196, 60) else Color3.fromRGB(63, 201, 216)
			end
		else
			title.Text = string.format("%s %s", icon, string.upper(name))
			timer.Text = "IN " .. clock((workspace:GetAttribute("EventStartsAt") or now) - now)
			if stroke then
				stroke.Color = Color3.fromRGB(63, 201, 216)
			end
		end
		task.wait(0.25)
	end
end)
