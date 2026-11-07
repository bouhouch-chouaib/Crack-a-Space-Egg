-- Fenêtre REWARDS (docs/Interfaces.md §8) : bouton REWARDS du HUD (ou croix haut à la manette).
-- Trois onglets :
--   DAILY    : 7 jours, le jour du jour en avant, CLAIM, puis le temps avant le suivant
--   PLAYTIME : 4 cadeaux (5, 15, 30, 60 min de jeu dans la journée), minuteur, CLAIM quand ils brillent
--   QUESTS   : 3 quêtes du jour, barre de progression, récompense, bonus quand les 3 sont réclamées
-- En bas : champ de code, « Join the group » (+10 % de chance), boost gratuit contre une pub.
-- Le serveur décide de tout (RewardService, Remotes.Rewards) ; ici on affiche et on demande.

local AdService = game:GetService("AdService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local new = UIKit.new

local W_SIZE = Vector2.new(1040, 640)
local win = UIKit.window({ name = "Rewards", title = "{Rewards} REWARDS", color = "Purple", size = W_SIZE })
win.body.Visible = false

local GAP = 14
local PAGE_Y = 160
local BOTTOM_H = 92
local PAGE_H = W_SIZE.Y - PAGE_Y - BOTTOM_H - GAP
local PAGE_W = W_SIZE.X - GAP * 2
local GOLD = Color3.fromRGB(255, 220, 90)

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

local function clock(s: number): string
	s = math.max(0, math.floor(s))
	if s >= 3600 then
		return ("%dh %02dm"):format(s // 3600, (s % 3600) // 60)
	end
	return ("%d:%02d"):format(s // 60, s % 60)
end

-- Récompense -> (icône, texte court), dans l'ordre : $ puis potions
local function rewardLines(r): { { art: string, text: string, color: Color3 } }
	local out = {}
	if r.money then
		table.insert(out, { art = "Cash", text = "$" .. Format.Short(r.money), color = UIKit.Money })
	end
	if r.luck then
		table.insert(out, { art = "PotionLuck", text = ("x2 Luck %dm"):format(r.luck), color = Color3.fromRGB(150, 255, 150) })
	end
	if r.moneyBoost then
		table.insert(out, { art = "PotionMoney", text = ("x2 Money %dm"):format(r.moneyBoost), color = Color3.fromRGB(255, 230, 120) })
	end
	if r.jetXP then
		table.insert(out, { art = "PotionSuit", text = ("x2 Jet XP %dm"):format(r.jetXP), color = Color3.fromRGB(140, 220, 255) })
	end
	return out
end

local function rewardText(r): string
	local parts = {}
	for _, l in ipairs(rewardLines(r)) do
		table.insert(parts, l.text)
	end
	return table.concat(parts, " + ")
end

local function card(parent: Instance, color: string, x: number, y: number, w: number, h: number): Frame
	local c = UIKit.card({ parent = parent, color = color })
	c.Size = UDim2.fromOffset(w, h)
	c.Position = UDim2.fromOffset(x, y)
	c.ZIndex = 3
	return c
end

-- ONGLETS -----------------------------------------------------------------------------------------
local TABS = {
	{ key = "Daily", text = "DAILY", art = "Rewards", color = "Purple" },
	{ key = "Playtime", text = "PLAYTIME", art = "Hourglass", color = "Teal" },
	{ key = "Quests", text = "QUESTS", art = "Star", color = "Orange" },
}
local pages: { [string]: Frame } = {}
local tabs: { [string]: { button: TextButton, stroke: UIStroke, badge: Frame } } = {}
local tabRow = new("Frame", { Size = UDim2.fromOffset(PAGE_W, 54), Position = UDim2.fromOffset(GAP, 96), BackgroundTransparency = 1, ZIndex = 2, Parent = win.frame }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})
for i, tab in ipairs(TABS) do
	pages[tab.key] = new("Frame", { Name = tab.key, Size = UDim2.fromOffset(PAGE_W, PAGE_H), Position = UDim2.fromOffset(GAP, PAGE_Y), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = win.frame })
	local colors = UIKit.Colors[tab.color]
	local b = new("TextButton", { Name = tab.key, Size = UDim2.fromOffset(220, 54), BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Text = "", LayoutOrder = i, ZIndex = 3, Parent = tabRow }, {
		UIKit.corner(14),
		UIKit.gradient(colors[1], colors[2]),
	})
	local stroke = UIKit.stroke(3.5)
	stroke.Parent = b
	UIKit.studs(b, 0.45, "Weld", 22)
	UIKit.icon(tab.art, { Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(4, 1), ZIndex = 4, Parent = b })
	label(b, tab.text, 58, 10, 156, 34, 26, nil, Enum.TextXAlignment.Left)
	UIKit.juice(b)
	tabs[tab.key] = { button = b, stroke = stroke, badge = UIKit.badge(b) }
end

local state: any = nil
local stateAt = 0 -- os.clock() de la réception (pour faire tourner les minuteurs)
local current = "Daily"
local refresh: () -> ()

local function showTab(key: string)
	current = key
	for k, p in pairs(pages) do
		p.Visible = k == key
	end
	for k, t in pairs(tabs) do
		local on = k == key
		t.stroke.Thickness = if on then 5 else 3.5
		t.stroke.Color = if on then Color3.fromRGB(255, 240, 150) else UIKit.Outline
		t.button.Size = UDim2.fromOffset(220, if on then 54 else 48)
	end
	refresh()
end
for key, t in pairs(tabs) do
	t.button.MouseButton1Click:Connect(function()
		showTab(key)
	end)
end

-- Demande au serveur ; affiche l'erreur s'il y en a une
local busy = false
local function ask(action: string, arg: any?): boolean
	if busy then
		return false
	end
	busy = true
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Rewards"):InvokeServer(action, arg)
	end)
	busy = false
	if not ok or type(res) ~= "table" then
		return false
	end
	if res.state then
		state, stateAt = res.state, os.clock()
	end
	if not res.ok and res.error then
		UIKit.toast(res.error, "warn")
		Sfx.Play("Error")
	end
	refresh()
	return res.ok == true
end

local function now(): number
	return if state then state.now + (os.clock() - stateAt) else os.time()
end

-- DAILY -------------------------------------------------------------------------------------------
type DayCard = { frame: Frame, title: TextLabel, icon: ImageLabel, text: TextLabel, check: ImageLabel, fx: Frame }
local days: { DayCard } = {}
do
	local page = pages.Daily
	local w = (PAGE_W - 6 * 10) // 7
	for i = 1, 7 do
		local big = i == 7
		local c = card(page, if big then "Gold" else "Purple", (i - 1) * (w + 10), 30, w, 220)
		local fx = UIKit.fxLayer(c)
		UIKit.rays(fx, { color = GOLD, size = 200, transparency = 0.6, z = 3 })
		fx.Visible = false
		local title = label(c, "DAY " .. i, 4, 8, w - 8, 30, 26)
		local icon = UIKit.icon(if big then "Rewards" else "Cash", { Size = UDim2.fromOffset(84, 84), Position = UDim2.new(0.5, -42, 0, 46), ZIndex = 5, Parent = c })
		UIKit.float(icon, 3, 4, 2.2, i * 0.4)
		local text = label(c, "", 4, 138, w - 8, 70, 20)
		text.TextWrapped = true
		local check = UIKit.icon("Star", { Size = UDim2.fromOffset(56, 56), Position = UDim2.new(1, -48, 0, -10), ZIndex = 7, Visible = false, Parent = c })
		days[i] = { frame = c, title = title, icon = icon, text = text, check = check, fx = fx }
	end
end
local dailyButton, dailyText, dailyGrad = UIKit.priceButton({ parent = pages.Daily, text = "", size = UDim2.fromOffset(360, 66), position = UDim2.new(0.5, -180, 0, 276) })
dailyButton.Name = "Claim"
dailyButton:SetAttribute("PadFirst", true)
local dailyNote = label(pages.Daily, "", 0, 350, PAGE_W, 30, 22, Color3.fromRGB(210, 215, 235))
dailyButton.MouseButton1Click:Connect(function()
	if state and state.dailyReady and ask("daily") then
		Sfx.Play("Reward")
		UIKit.burst(win.frame, UDim2.fromScale(0.5, 0.55), GOLD)
	end
end)

-- PLAYTIME ----------------------------------------------------------------------------------------
type PlayCard = { frame: Frame, fill: Frame, timer: TextLabel, button: TextButton, label: TextLabel, text: TextLabel, grad: UIGradient, fx: Frame }
local plays: { PlayCard } = {}
do
	local page = pages.Playtime
	local w = (PAGE_W - 3 * 16) // 4
	for i = 1, 4 do
		local c = card(page, "Teal", (i - 1) * (w + 16), 20, w, 330)
		local fx = UIKit.fxLayer(c)
		UIKit.rays(fx, { color = GOLD, size = 260, transparency = 0.55, z = 3 })
		fx.Visible = false
		label(c, "", 6, 8, w - 12, 34, 28).Name = "Title"
		local icon = UIKit.icon("Rewards", { Size = UDim2.fromOffset(96, 96), Position = UDim2.new(0.5, -48, 0, 48), ZIndex = 5, Parent = c })
		UIKit.float(icon, 3, 5, 2, i * 0.5)
		local text = label(c, "", 6, 150, w - 12, 50, 20)
		text.TextWrapped = true
		local bar = new("Frame", { Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 208), BackgroundColor3 = Color3.fromRGB(26, 28, 40), ZIndex = 5, Parent = c }, { UIKit.corner(), UIKit.stroke(2.5) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6, Parent = bar }, { UIKit.corner(), UIKit.gradient(Color3.fromRGB(150, 255, 240), Color3.fromRGB(30, 190, 210)) })
		local timer = label(bar, "", 0, 0, w - 24, 22, 18)
		timer.ZIndex = 7
		local b, t, g = UIKit.priceButton({ parent = c, text = "", size = UDim2.new(1, -24, 0, 56), position = UDim2.new(0, 12, 1, -70) })
		b.Name = "Claim" .. i
		b.MouseButton1Click:Connect(function()
			if ask("playtime", i) then
				Sfx.Play("Reward")
				UIKit.burst(c, UDim2.fromScale(0.5, 0.4), GOLD)
			end
		end)
		plays[i] = { frame = c, fill = fill, timer = timer, button = b, label = t, text = text, grad = g, fx = fx }
	end
end
local playNote = label(pages.Playtime, "Play time today. Gifts come back every day!", 0, 362, PAGE_W, 28, 20, Color3.fromRGB(210, 215, 235))

-- QUESTS ------------------------------------------------------------------------------------------
type QuestRow = { frame: Frame, icon: ImageLabel, text: TextLabel, fill: Frame, count: TextLabel, reward: TextLabel, button: TextButton, label: TextLabel, grad: UIGradient }
local quests: { QuestRow } = {}
do
	local page = pages.Quests
	for i = 1, 3 do
		local c = card(page, "Orange", 0, (i - 1) * 104, PAGE_W, 94)
		local icon = UIKit.icon("Star", { Size = UDim2.fromOffset(78, 78), Position = UDim2.fromOffset(10, 8), ZIndex = 5, Parent = c })
		local text = label(c, "", 100, 8, 520, 36, 28, nil, Enum.TextXAlignment.Left)
		local bar = new("Frame", { Size = UDim2.fromOffset(420, 26), Position = UDim2.fromOffset(100, 54), BackgroundColor3 = Color3.fromRGB(26, 28, 40), ZIndex = 5, Parent = c }, { UIKit.corner(), UIKit.stroke(2.5) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6, Parent = bar }, { UIKit.corner(), UIKit.gradient(Color3.fromRGB(176, 245, 70), Color3.fromRGB(70, 196, 40)) })
		local count = label(bar, "", 0, 0, 420, 26, 20)
		count.ZIndex = 7
		local reward = label(c, "", 540, 52, 200, 30, 22, UIKit.Money, Enum.TextXAlignment.Left)
		local b, t, g = UIKit.priceButton({ parent = c, text = "", size = UDim2.fromOffset(230, 64), position = UDim2.new(1, -246, 0.5, -32) })
		b.Name = "Claim" .. i
		b.MouseButton1Click:Connect(function()
			if ask("quest", i) then
				Sfx.Play("Reward")
				UIKit.burst(c, UDim2.new(1, -130, 0.5, 0), GOLD)
			end
		end)
		quests[i] = { frame = c, icon = icon, text = text, fill = fill, count = count, reward = reward, button = b, label = t, grad = g }
	end
end
local questNote = label(pages.Quests, "", 0, 322, PAGE_W, 30, 22, GOLD)
local questTimer = label(pages.Quests, "", 0, 354, PAGE_W, 26, 20, Color3.fromRGB(210, 215, 235))

-- BAS : CODES, GROUPE, BOOST GRATUIT ------------------------------------------------------------
local bottom = new("Frame", { Name = "Bottom", Size = UDim2.fromOffset(PAGE_W, BOTTOM_H - 10), Position = UDim2.fromOffset(GAP, W_SIZE.Y - BOTTOM_H - 4), BackgroundColor3 = Color3.fromRGB(26, 28, 40), BackgroundTransparency = 0.15, ZIndex = 2, Parent = win.frame }, { UIKit.corner(14) })
local codeBox = new("TextBox", {
	Name = "Code",
	Size = UDim2.fromOffset(250, 54),
	Position = UDim2.fromOffset(12, 14),
	BackgroundColor3 = Color3.fromRGB(240, 242, 255),
	PlaceholderText = "Enter code...",
	PlaceholderColor3 = Color3.fromRGB(140, 145, 170),
	Text = "",
	TextColor3 = Color3.fromRGB(28, 30, 44),
	FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy),
	TextScaled = true,
	ClearTextOnFocus = false,
	ZIndex = 4,
	Parent = bottom,
}, { UIKit.corner(10), UIKit.stroke(3), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }) })
local redeem = UIKit.priceButton({ parent = bottom, text = "REDEEM", color = "Blue", size = UDim2.fromOffset(140, 54), position = UDim2.fromOffset(270, 14) })
redeem.Name = "Redeem"
local function tryCode()
	if codeBox.Text ~= "" and ask("code", codeBox.Text) then
		codeBox.Text = ""
		Sfx.Play("Reward")
		UIKit.burst(bottom, UDim2.fromOffset(200, 40), GOLD)
	end
end
redeem.MouseButton1Click:Connect(tryCode)
codeBox.FocusLost:Connect(function(enter)
	if enter then
		tryCode()
	end
end)
local groupButton, groupText, groupGrad = UIKit.priceButton({ parent = bottom, text = "", color = "Gold", size = UDim2.fromOffset(270, 54), position = UDim2.fromOffset(426, 14) })
groupButton.Name = "Group"
groupButton.MouseButton1Click:Connect(function()
	if not state or state.group.id == 0 then
		return
	end
	if state.group.inGroup or not state.group.claimed then
		if ask("group") then
			Sfx.Play("Reward")
			UIKit.burst(bottom, UDim2.fromOffset(560, 40), GOLD)
			return
		end
	end
	-- pas encore membre : on propose de rejoindre le groupe (si Roblox le permet ici)
	if state and not state.group.inGroup then
		local ok = pcall(function()
			game:GetService("GroupService"):PromptJoinAsync(state.group.id)
		end)
		if ok then
			task.wait(1)
			ask("group")
		end
	end
end)
local adButton, adText, adGrad = UIKit.priceButton({ parent = bottom, text = "", color = "Pink", size = UDim2.fromOffset(PAGE_W - 712 - 12, 54), position = UDim2.fromOffset(712, 14) })
adButton.Name = "FreeBoost"
-- textes du bas un peu plus petits, pour tenir dans les boutons
for _, l in ipairs({ adText, groupText }) do
	l.TextSize = 24
end
new("UIPadding", { PaddingLeft = UDim.new(0, 40), Parent = adText.Parent })
UIKit.icon("FreeBoost", { Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0, -14, 0.5, -30), ZIndex = 6, Parent = adButton })
local adAvailable = false
local function checkAd()
	local ok, res = pcall(function()
		return AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)
	end)
	adAvailable = ok and res and res.AdAvailabilityResult == Enum.AdAvailabilityResult.IsAvailable
	refresh()
end
adButton.MouseButton1Click:Connect(function()
	if adAvailable and state and state.ad.ready then
		if ask("ad") then
			Sfx.Play("Reward")
		end
		task.spawn(checkAd)
	end
end)

-- AFFICHAGE ---------------------------------------------------------------------------------------
local function setButton(grad: UIGradient, text: TextLabel, color: string, s: string)
	UIKit.recolor(grad, color)
	UIKit.setIconText(text, s)
end

refresh = function()
	if not state then
		return
	end
	local t = now()
	local untilDay = state.nextDay - t
	-- badges des onglets
	local playReady, questReady = 0, 0
	local played = state.playSeconds + (os.clock() - stateAt)
	for _, p in ipairs(state.play) do
		if not p.claimed and played >= p.minutes * 60 then
			playReady += 1
		end
	end
	for _, q in ipairs(state.quests) do
		if not q.claimed and q.progress >= q.goal then
			questReady += 1
		end
	end
	tabs.Daily.badge.Visible = state.dailyReady
	tabs.Playtime.badge.Visible = playReady > 0
	tabs.Quests.badge.Visible = questReady > 0

	-- DAILY
	local claimedUpTo = if state.dailyReady then state.dailyDay - 1 else state.dailyDay
	for i, dc in ipairs(days) do
		local rw = state.daily[i]
		local lines = rewardLines(rw)
		dc.icon.Image = UIKit.Art[if i == 7 then "Rewards" else (lines[1] and lines[1].art or "Cash")]
		dc.text.Text = rewardText(rw)
		dc.text.TextColor3 = if lines[1] then lines[1].color else Color3.new(1, 1, 1)
		dc.check.Visible = i <= claimedUpTo
		local today = i == state.dailyDay
		dc.fx.Visible = today and state.dailyReady
		dc.frame.Rotation = 0
		dc.frame.BackgroundTransparency = if i <= claimedUpTo then 0.45 else 0
		dc.title.Text = if today then "TODAY" else "DAY " .. i
	end
	if state.dailyReady then
		setButton(dailyGrad, dailyText, "Green", "CLAIM DAY " .. state.dailyDay)
		dailyNote.Text = "Come back every day! Miss a day and you start again at day 1."
	else
		setButton(dailyGrad, dailyText, "Grey", "{Hourglass} " .. clock(untilDay))
		dailyNote.Text = "Next reward in " .. clock(untilDay)
	end

	-- PLAYTIME
	for i, pc in ipairs(plays) do
		local p = state.play[i]
		local title = pc.frame:FindFirstChild("Title") :: TextLabel
		title.Text = p.minutes .. " MIN"
		pc.text.Text = rewardText(p.reward)
		local f = math.clamp(played / (p.minutes * 60), 0, 1)
		pc.fill.Size = UDim2.fromScale(f, 1)
		if p.claimed then
			pc.timer.Text = "DONE"
			setButton(pc.grad, pc.label, "Grey", "CLAIMED")
			pc.fx.Visible = false
		elseif f >= 1 then
			pc.timer.Text = "READY!"
			setButton(pc.grad, pc.label, "Green", "CLAIM")
			pc.fx.Visible = true
		else
			pc.timer.Text = clock(p.minutes * 60 - played)
			setButton(pc.grad, pc.label, "Grey", "{Hourglass} " .. clock(p.minutes * 60 - played))
			pc.fx.Visible = false
		end
	end
	playNote.Text = ("Play time today: %s  ·  Gifts come back every day!"):format(clock(played))

	-- QUESTS
	local claimedAll = true
	for i, row in ipairs(quests) do
		local q = state.quests[i]
		row.frame.Visible = q ~= nil
		if q then
			row.icon.Image = UIKit.Art[q.art] or UIKit.Art.Star
			row.text.Text = q.text
			row.fill.Size = UDim2.fromScale(math.clamp(q.progress / q.goal, 0, 1), 1)
			row.count.Text = Format.Short(q.progress) .. " / " .. Format.Short(q.goal)
			row.reward.Text = rewardText(q.reward)
			claimedAll = claimedAll and q.claimed
			if q.claimed then
				setButton(row.grad, row.label, "Grey", "CLAIMED")
			elseif q.progress >= q.goal then
				setButton(row.grad, row.label, "Green", "CLAIM")
			else
				setButton(row.grad, row.label, "Dark", "IN PROGRESS")
			end
		end
	end
	questNote.Text = if state.allQuestsClaimed
		then "All quests done today!"
		else "Finish all 3 quests: bonus " .. rewardText(state.allQuestsReward)
	questTimer.Text = "New quests in " .. clock(untilDay)

	-- BAS
	local g = state.group
	if g.id == 0 then
		setButton(groupGrad, groupText, "Grey", "GROUP SOON")
	elseif g.inGroup and g.claimed then
		setButton(groupGrad, groupText, "Grey", ("{Star} +%d%% LUCK ON"):format(math.floor(g.luck * 100)))
	elseif g.inGroup then
		setButton(groupGrad, groupText, "Green", "{Star} CLAIM GROUP GIFT")
	else
		setButton(groupGrad, groupText, "Gold", ("{Star} JOIN GROUP: +%d%% LUCK"):format(math.floor(g.luck * 100)))
	end
	local wait = math.max(0, state.ad.wait - (os.clock() - stateAt))
	if not adAvailable then
		setButton(adGrad, adText, "Grey", "NO AD NOW")
	elseif wait > 0 then
		setButton(adGrad, adText, "Grey", "BOOST IN " .. clock(wait))
	else
		setButton(adGrad, adText, "Pink", "FREE BOOST!")
	end
end

-- minuteurs qui tournent pendant que la fenêtre est ouverte ; état relu toutes les 15 s
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not win.isOpen() then
		return
	end
	acc += dt
	if acc >= 0.5 then
		acc = 0
		refresh()
	end
end)
task.spawn(function()
	while true do
		task.wait(15)
		if win.isOpen() then
			ask("state")
		end
	end
end)

UIKit.Open.Event:Connect(function(what: string, tab: string?)
	if what ~= "Rewards" then
		return
	end
	win.open(function()
		ask("state")
		-- onglet le plus utile : celui qui a quelque chose à réclamer
		local pick = tab
		if not pick and state then
			pick = if state.dailyReady then "Daily" elseif tabs.Quests.badge.Visible then "Quests" elseif tabs.Playtime.badge.Visible then "Playtime" else current
		end
		showTab(pick or current)
		task.spawn(checkAd)
	end)
end)
showTab("Daily")
