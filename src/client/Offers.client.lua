-- Petits panneaux qui arrivent la première fois qu'une situation se présente (après le tutoriel) :
--   3 créatures identiques   « Try fusion? » : OUI = devant la machine, avec des flèches (attribut FuseTour)
--   nouveau matériel payable  foreuse ou Scanner : ITEMS ; soufflerie : TUNNEL ; Starter Pack : STORE.
--                             Le bouton amène le joueur devant le stand et son menu s'ouvre tout seul.
-- Et le panneau de fin de tutoriel, avec sa récompense (attribut TutorialReward, RewardService).
-- « LATER » : on n'insiste plus pendant cette session ; l'offre revient à la prochaine partie.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local G = Config.Guide
local new = UIKit.new

local GAP = 20 -- secondes de calme entre deux panneaux
local W, H = 520, 240

local gui = new("ScreenGui", { Name = "Offers", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 8, Parent = player:WaitForChild("PlayerGui") })
local holder = new("Frame", { Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false, Parent = gui })
UIKit.autoScale(holder)
local card = new("Frame", { Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = UIKit.Panel, Parent = holder }, { UIKit.corner(18), UIKit.stroke(5) })
UIKit.studs(card, 0.5, "Inlets", 28)
local fx = new("Frame", { Name = "Fx", Size = UDim2.fromOffset(150, 150), Position = UDim2.fromOffset(14, 26), BackgroundTransparency = 1, ZIndex = 2, Parent = card })
UIKit.rays(fx, { color = Color3.fromRGB(255, 220, 90), size = 220, speed = 30, transparency = 0.45, z = 2 })
local icon = UIKit.icon("Star", { Size = UDim2.fromOffset(130, 130), Position = UDim2.fromOffset(24, 36), ZIndex = 4, Parent = card })
UIKit.float(icon, 4, 5, 2)
local title = UIKit.text({ Size = UDim2.fromOffset(330, 54), Position = UDim2.fromOffset(176, 18), Text = "", TextColor3 = Color3.fromRGB(255, 225, 110), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Stroke = 3.5, Parent = card })
new("UITextSizeConstraint", { MaxTextSize = 36, MinTextSize = 14, Parent = title })
local body = UIKit.text({ Size = UDim2.fromOffset(330, 66), Position = UDim2.fromOffset(176, 76), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Stroke = 2.5, Parent = card })
new("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 12, Parent = body })
local main, mainText = UIKit.priceButton({ parent = card, text = "", color = "Green", size = UDim2.fromOffset(190, 62), position = UDim2.fromOffset(176, 160) })
main.Name = "Main"
mainText.TextSize = 26
mainText.AutomaticSize = Enum.AutomaticSize.None -- largeur fixe : le texte change à chaque panneau
mainText.Size = UDim2.fromOffset(170, 36)
local later, laterText = UIKit.priceButton({ parent = card, text = "LATER", color = "Grey", size = UDim2.fromOffset(130, 62), position = UDim2.fromOffset(376, 160) })
later.Name = "Later"
laterText.TextSize = 24

type Offer = { key: string?, art: string, title: string, text: string, button: string, go: (() -> ())?, single: boolean? }
local shown: Offer? = nil
local lastEnd = os.clock()
local waiting: { Offer } = {}
local dismissed: { [string]: boolean } = {}

local function display(o: Offer)
	shown = o
	icon.Image = UIKit.Art[o.art] or o.art
	title.Text = o.title
	body.Text = o.text
	mainText.Text = o.button
	later.Visible = not o.single
	main.Size = UDim2.fromOffset(if o.single then 330 else 190, 62)
	holder.Visible = true
	UIKit.popIn(holder)
	UIKit.burst(card, UDim2.fromOffset(90, 100), Color3.fromRGB(255, 220, 90))
	Sfx.Play(if o.single then "Reward" else "Open")
end

local function hide()
	holder.Visible = false
	shown = nil
	lastEnd = os.clock()
end

local function seen(key: string)
	Remotes.Guide:FireServer("tip", key)
end

main.MouseButton1Click:Connect(function()
	local o = shown
	if not o then
		return
	end
	hide()
	if o.key then
		seen(o.key)
	end
	if o.go then
		o.go()
	end
end)
later.MouseButton1Click:Connect(function()
	local o = shown
	if o and o.key then
		dismissed[o.key] = true
	end
	hide()
end)

-- VOYAGE ------------------------------------------------------------------------------------------

local function ship(): Instance?
	return workspace:FindFirstChild("Ship")
end

-- Sur le tapis du stand : ShipShops ouvre alors son menu (ShopTab : onglet voulu)
local function toStand(standName: string, tab: string?)
	local shops = ship() and (ship() :: Instance):FindFirstChild("Shops")
	local stand = shops and shops:FindFirstChild(standName)
	local mat = stand and stand:FindFirstChild("Mat") :: BasePart?
	local character = player.Character
	if mat and character then
		player:SetAttribute("ShopTab", tab)
		character:PivotTo(mat.CFrame * CFrame.new(0, 3.4, 0) * CFrame.Angles(0, math.pi, 0))
	end
end

-- Debout sur un bouton rouge de sa base : le menu s'ouvre tout seul (ShipShops.client)
local function toButton(name: string)
	local bases = ship() and (ship() :: Instance):FindFirstChild("Bases")
	local mine = bases and bases:FindFirstChild("Base" .. tostring(player:GetAttribute("Base")))
	local button = mine and mine:FindFirstChild(name) :: Model?
	local character = player.Character
	if button and character then
		local p = button:GetPivot().Position
		character:PivotTo(CFrame.new(p.X, 3.4, p.Z))
	end
end

local function toTunnel()
	toButton("TunnelButton")
end

local function toMachine()
	toButton("MachineButton")
end

local function toFusion()
	local fusion = ship() and (ship() :: Instance):FindFirstChild("Fusion") :: Model?
	local point = fusion and fusion:FindFirstChild("FusionPoint") :: BasePart?
	local character = player.Character
	if fusion and point and character then
		local out = (point.Position - fusion:GetPivot().Position) * Vector3.new(1, 0, 1)
		local stand = point.Position + out.Unit * 3 + Vector3.new(0, 3, 0)
		character:PivotTo(CFrame.lookAt(stand, Vector3.new(point.Position.X, stand.Y, point.Position.Z)))
		player:SetAttribute("FuseTour", true)
	end
end

-- QUELLE OFFRE ? ------------------------------------------------------------------------------------

local function attr(name: string): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

local function fresh(key: string): boolean
	return not dismissed[key] and player:GetAttribute("Tip_" .. key) ~= true
end

local function canFuse(): boolean
	local count: { [string]: number } = {}
	for _, m in ipairs(CollectionService:GetTagged("Creature")) do
		local stage = (m:GetAttribute("Stage") or 1) :: number
		if m:GetAttribute("Owner") == player.UserId and m.Parent and stage < #Config.PetRules.Stages then
			local key = ("%s:%s:%d"):format(tostring(m:GetAttribute("Ring")), tostring(m:GetAttribute("Rarity")), stage)
			count[key] = (count[key] or 0) + 1
			if count[key] >= 3 then
				return true
			end
		end
	end
	return false
end

local function anyWindowOpen(): boolean
	for _, w in pairs(UIKit.Windows) do
		if w.isOpen() then
			return true
		end
	end
	return false
end

local function nextOffer(): Offer?
	local credits = attr("Credits")
	if fresh("fuse") and canFuse() then
		return { key = "fuse", art = "Creatures", title = "3 same pets!", text = "Fuse them into a stronger one. Want to try?", button = "YES!", go = toFusion }
	end
	local tier = attr("Drill") + 1
	local drill = Config.Drills[tier]
	if drill and credits >= drill.Cost and fresh("drill" .. tier) then
		return { key = "drill" .. tier, art = "UpDrill", title = "New drill!", text = ("%s for $%s: it drills much faster"):format(drill.Name, Format.Short(drill.Cost)), button = "ITEMS", go = function()
			toStand("ItemsStand")
		end }
	end
	local scanner = Config.UpgradeCost("Scanner", attr("Lvl_Scanner"))
	if attr("Lvl_Scanner") == 0 and credits >= scanner and fresh("scanner") then
		return { key = "scanner", art = "UpScanner", title = "Scanner!", text = ("$%s: find rarer eggs"):format(Format.Short(scanner)), button = "ITEMS", go = function()
			toStand("ItemsStand", "Upgrades")
		end }
	end
	local folder = ship() and (ship() :: Instance):FindFirstChild("WindTunnels")
	local tunnel = folder and folder:FindFirstChild("Tunnel" .. tostring(player:GetAttribute("Base")))
	local level = tunnel and (tunnel:GetAttribute("Tier") or 0) :: number or 0
	local nextTunnel = Config.Jetpack.Tunnels[level + 1]
	if level >= 1 and nextTunnel and credits >= nextTunnel.Cost and fresh("tunnel" .. (level + 1)) then
		return { key = "tunnel" .. (level + 1), art = "WindTunnel", title = "Better wind tunnel!", text = ("%s for $%s: train faster"):format(nextTunnel.Name, Format.Short(nextTunnel.Cost)), button = "TUNNEL", go = toTunnel }
	end
	if credits >= Config.MachineCost("Speed", attr("Mach_Speed")) and fresh("machine") then
		return { key = "machine", art = "MachineUp", title = "Upgrade your machine!", text = "Faster, luckier, and better gems", button = "MACHINE", go = toMachine }
	end
	if Config.Shop.Featured.Id ~= 0 and fresh("starter") and not player:GetAttribute("StarterBought") and attr("StarterEnds") > os.time() then
		return { key = "starter", art = "Shop", title = "Starter Pack!", text = "A big bundle of boosts, only for new players", button = "STORE", go = function()
			toStand("StoreStand")
		end }
	end
	return nil
end

-- FIN DU TUTORIEL -----------------------------------------------------------------------------------

local function onReward()
	local got = player:GetAttribute("TutorialReward")
	if type(got) == "string" and got ~= "" then
		table.insert(waiting, { art = "Rewards", title = "TUTORIAL COMPLETE!", text = "Thanks for following along!\n" .. got, button = "AWESOME!", single = true })
	end
end
player:GetAttributeChangedSignal("TutorialReward"):Connect(onReward)

task.spawn(function()
	while true do
		task.wait(1)
		if shown then
			continue
		end
		if #waiting > 0 then
			display(table.remove(waiting, 1) :: Offer)
			continue
		end
		local busy = attr("GuideStep") < G.Steps
			or attr("Cargo") > 0
			or player:GetAttribute("HeldEgg")
			or player:GetAttribute("FuseTour")
			or os.clock() - lastEnd < GAP
			or anyWindowOpen()
		if not busy then
			local ok, offer = pcall(nextOffer)
			if ok and offer then
				display(offer)
			elseif not ok then
				warn("[Offers]", offer)
			end
		end
	end
end)
