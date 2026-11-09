-- Bandeaux des trouvailles rares (Remotes.Announcement, AnnounceService) : un à la fois en haut de l'écran,
-- derrière les menus, plus grand et plus animé selon le niveau. Chaque message laisse aussi une ligne dans le chat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

local TOP = 66 -- sous la barre de Roblox
local CHAT_COLOR = "#FFD23C"
local BUSY = 2 -- au-delà de ce nombre en attente, les bandeaux restent moins longtemps
local LEVELS = {
	{ w = 640, h = 64, time = 3.6, text = 30, sound = "Reward" },
	{ w = 800, h = 86, time = 4.6, text = 38, sound = "HatchRare" },
	{ w = 980, h = 118, time = 6, text = 48, sound = "HatchRare" },
}

local gui = new("ScreenGui", { Name = "Announcements", ResetOnSpawn = false, DisplayOrder = 6, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = gui })
UIKit.autoScale(gui)

type Message = { level: number, text: string, color: Color3, icon: string, chatOnly: boolean?, far: boolean? }
local queue: { Message } = {}

local function chatLine(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local system = channels and channels:FindFirstChild("RBXSystem")
	if system and system:IsA("TextChannel") then
		local safe = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
		pcall(function()
			system:DisplaySystemMessage(('<font color="%s"><b>%s</b></font>'):format(CHAT_COLOR, safe))
		end)
	end
end

local function play(msg: Message)
	local L = LEVELS[msg.level] or LEVELS[1]
	local color = msg.color
	local hidden = UDim2.new(0.5, 0, 0, -L.h - 30)
	local frame = new("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = hidden,
		Size = UDim2.fromOffset(L.w, L.h),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = gui,
	}, { UIKit.corner(16), UIKit.gradient(color:Lerp(Color3.new(1, 1, 1), 0.2), color:Lerp(Color3.new(0, 0, 0), 0.4)) })
	UIKit.stroke(4, color:Lerp(Color3.new(0, 0, 0), 0.55)).Parent = frame
	UIKit.studs(frame, 0.55, "Studs", 22)
	local iconSize = L.h - 12
	if msg.level >= 2 then
		local fx = new("Frame", { Size = UDim2.fromOffset(iconSize, iconSize), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, ZIndex = 4, Parent = frame })
		UIKit.rays(fx, { color = Color3.new(1, 1, 1), size = iconSize * 2.2, speed = 32, transparency = 0.35, z = 4 })
		UIKit.glow(fx, { color = Color3.new(1, 1, 1), size = iconSize * 1.7, transparency = 0.4, z = 4, pulse = 3 })
	end
	if msg.level >= 3 then
		UIKit.shinyStroke(frame, UIKit.Rainbow, 5)
		UIKit.sparkles(frame, { count = 10, color = Color3.new(1, 1, 1), size = 22, z = 7 })
	end
	local icon = UIKit.icon(msg.icon, { Size = UDim2.fromOffset(iconSize, iconSize), Position = UDim2.fromOffset(12, 6), ZIndex = 5, Parent = frame })
	UIKit.float(icon, 2, 4, 2)
	local text = UIKit.text({ Size = UDim2.new(1, -iconSize - 34, 1, -14), Position = UDim2.fromOffset(iconSize + 22, 7), Text = msg.text, TextColor3 = Color3.new(1, 1, 1), ZIndex = 6, Stroke = 3.5, Parent = frame })
	new("UITextSizeConstraint", { MaxTextSize = L.text, MinTextSize = 12, Parent = text })
	if msg.level >= 3 then
		UIKit.shinyText(text, color:Lerp(Color3.new(1, 1, 1), 0.55))
	end
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, TOP) }):Play()
	Sfx.Play(L.sound)
	if msg.level >= 2 then
		task.delay(0.25, function()
			UIKit.burst(frame, UDim2.fromScale(0.5, 0.5), color)
		end)
	end
	if msg.level >= 3 then
		Sfx.Play("Reward")
		flash.BackgroundTransparency = 0.55
		TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	end
	task.wait(if #queue > BUSY then L.time * 0.55 else L.time)
	TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = hidden }):Play()
	task.wait(0.35)
	frame:Destroy()
end

Remotes.Announcement.OnClientEvent:Connect(function(msg: Message)
	if type(msg) ~= "table" or type(msg.text) ~= "string" then
		return
	end
	chatLine(msg.text)
	if not msg.chatOnly then
		table.insert(queue, msg)
	end
end)

task.spawn(function()
	while true do
		if #queue > 0 then
			play(table.remove(queue, 1) :: Message)
		else
			task.wait(0.15)
		end
	end
end)
