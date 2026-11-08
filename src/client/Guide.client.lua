-- Guide de la première minute (docs/Mecaniques.md §16, Config.Guide).
-- Fait pour qu'un enfant le suive sans difficulté : une bulle de 3 à 5 mots avec une grosse icône,
-- une flèche au sol qui file vers le but, une flèche qui rebondit au-dessus et un contour qui le fait
-- briller, une main qui montre le geste à faire (maintenir, toucher), et une petite fête à chaque réussite.
-- Il suit l'état réel du joueur, pas un script figé : s'il tombe, perd son œuf ou part ailleurs, la
-- bulle s'adapte (« Fly to a rock! », « Bring it home! »...). Il l'accompagne pendant toute la première
-- boucle et ses détours : premier œuf, machine, pose, deuxième œuf pendant l'incubation, éclosion,
-- 3 créatures, soufflerie, entraînement du jetpack (niveau 3), meilleure foreuse, puis la chance (Scanner).
-- Étape atteinte : attribut GuideStep (sauvegardé par le serveur via Remotes.Guide).
-- La même bulle sert aux tutoriels au bon moment (Config.Guide.Tips), une seule fois par joueur et
-- seulement quand il en a besoin : sa première géode, son premier minerai, sa base pleine, la Supernova.
-- Publie l'attribut local Guide (texte en cours) : l'aide du bas (Hud) se cache pendant le guide.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local Icons = require(ReplicatedStorage.Shared:WaitForChild("Icons"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local G = Config.Guide
local new = UIKit.new
local Device = require(script.Parent:WaitForChild("Device"))

local INK = Color3.fromRGB(28, 30, 44)
local GOLD = Color3.fromRGB(255, 205, 60)
local ARROW = Color3.fromRGB(120, 255, 110)

-- BULLE ------------------------------------------------------------------------------------

local gui = new("ScreenGui", { Name = "Guide", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
local holder = new("Frame", {
	Name = "Holder",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(600, 140),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
UIKit.autoScale(holder)
local bubble = new("Frame", {
	Name = "Bubble",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromOffset(560, 104),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = holder,
}, { UIKit.corner(28), UIKit.stroke(5, INK), UIKit.gradient(Color3.new(1, 1, 1), Color3.fromRGB(225, 232, 255)) })
UIKit.studs(bubble, 0.85, "Studs", 22)
-- petite pointe de bulle vers le haut (vers le jeu)
new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(26, 26),
	Rotation = 45,
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 0,
	Parent = bubble,
}, { UIKit.stroke(5, INK) })
local icon = UIKit.icon("Jetpack", { Size = UDim2.fromOffset(104, 104), Position = UDim2.new(0, -30, 0.5, -60), ZIndex = 3, Parent = bubble })
UIKit.float(icon, 4, 4, 2.4)
local mainText = UIKit.text({
	Name = "Main",
	Size = UDim2.new(1, -110, 0, 54),
	Position = UDim2.fromOffset(88, 10),
	Text = "",
	TextColor3 = INK,
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 0,
	ZIndex = 3,
	Parent = bubble,
})
local subText = UIKit.text({
	Name = "Sub",
	Size = UDim2.new(1, -110, 0, 28),
	Position = UDim2.fromOffset(90, 64),
	Text = "",
	TextColor3 = Color3.fromRGB(90, 96, 130),
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 0,
	ZIndex = 3,
	Parent = bubble,
})
-- étoiles de progression au-dessus de la bulle
local stars = new("Frame", {
	Name = "Stars",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -112),
	Size = UDim2.fromOffset(G.Steps * 26, 24),
	BackgroundTransparency = 1,
	Parent = holder,
}, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4) }),
})
local starIcons = {}
for i = 1, G.Steps do
	starIcons[i] = UIKit.icon("Star", { Size = UDim2.fromOffset(22, 22), LayoutOrder = i, Parent = stars })
end
-- « passer » : deux touches pour ne pas le faire par erreur
local skip = new("TextButton", {
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 8, 0, -14),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = Color3.fromRGB(70, 74, 96),
	Text = "",
	AutoButtonColor = false,
	ZIndex = 5,
	Parent = bubble,
}, { UIKit.corner(17), UIKit.stroke(3, INK) })
UIKit.icon("Cross", { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), ZIndex = 6, Parent = skip })
local skipAsk = UIKit.text({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 0, -18),
	Size = UDim2.fromOffset(220, 26),
	Text = "Tap again to skip",
	Visible = false,
	ZIndex = 6,
	Parent = bubble,
})
local skipArmed = 0

-- main qui montre le geste (maintenir le clic / toucher le bouton FORER / toucher le sol)
-- (tactile : un doigt ; souris : la souris ; manette : un rond avec le nom de la touche, plus bas)
local hand = UIKit.icon(if Device.IsTouch() then "Tap" else "Mouse", {
	Name = "Hand",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(84, 84),
	Visible = false,
	ZIndex = 20,
	Parent = gui,
})
local handScale = new("UIScale", { Parent = hand })
local padBadge = new("Frame", {
	Name = "PadBadge",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(78, 78),
	BackgroundColor3 = Color3.fromRGB(30, 32, 46),
	Visible = false,
	ZIndex = 20,
	Parent = gui,
}, { UIKit.corner(39), UIKit.stroke(5, Color3.new(1, 1, 1)) })
local padLabel = UIKit.text({ Size = UDim2.fromScale(0.86, 0.6), Position = UDim2.fromScale(0.07, 0.2), Text = "RT", ZIndex = 21, Parent = padBadge })
local badgeScale = new("UIScale", { Parent = padBadge })
Device.Changed:Connect(function()
	hand.Image = UIKit.Art[if Device.IsTouch() then "Tap" else "Mouse"] or hand.Image
end)

-- fête : « GREAT! » au centre, rayons, étincelles, son
local cheer = UIKit.text({
	Name = "Cheer",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.24), -- au-dessus des messages du jeu (toasts, au milieu)
	Size = UDim2.fromOffset(520, 110),
	Text = "",
	TextColor3 = GOLD,
	Stroke = 6,
	Visible = false,
	ZIndex = 30,
	Parent = gui,
})
local cheerScale = new("UIScale", { Parent = cheer })
-- calque plein écran pour les étincelles de la fête (UIKit.burst a besoin d'un cadre)
local fxLayer = new("Frame", { Name = "Fx", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 29, Parent = gui })
local CHEERS = { "Great!", "Awesome!", "Nice job!", "Super!", "Amazing!" }

local function celebrate(text: string?)
	cheer.Text = text or CHEERS[math.random(1, #CHEERS)]
	cheer.Visible = true
	cheer.TextTransparency = 0
	cheerScale.Scale = 0.2
	TweenService:Create(cheerScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	UIKit.burst(fxLayer, UDim2.fromScale(0.5, 0.24), GOLD)
	Sfx.Play("Pop")
	task.delay(1.4, function()
		TweenService:Create(cheer, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.4)
		cheer.Visible = false
	end)
end

-- FLÈCHE DANS LE MONDE ---------------------------------------------------------------------

local a0 = new("Attachment", { Name = "GuideFrom" })
local a1 = new("Attachment", { Name = "GuideTo", Parent = workspace.Terrain })
local beam = new("Beam", {
	Name = "GuideArrow",
	Attachment0 = a0,
	Attachment1 = a1,
	Texture = G.Arrow,
	TextureMode = Enum.TextureMode.Static,
	TextureLength = 3,
	TextureSpeed = 1.6,
	Width0 = 2.2,
	Width1 = 2.2,
	FaceCamera = true,
	LightEmission = 0.4,
	LightInfluence = 0,
	Color = ColorSequence.new(ARROW),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.1), NumberSequenceKeypoint.new(0.9, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	Segments = 1,
	Enabled = false,
	Parent = workspace.Terrain,
})
-- Chaîne de flèches entre le joueur et le but : une grosse flèche verte tous les CHAIN_GAP studs,
-- posée à plat sur le sol (ou en l'air au-dessus du vide), pointée vers le but ; une vague de lumière
-- les parcourt du joueur vers le but pour montrer le sens.
local CHAIN_GAP = 5
local CHAIN_MAX = 48
local CHAIN_SIZE = 3.8
local chainFolder = new("Folder", { Name = "GuideChain", Parent = workspace })
local chain: { BasePart } = {}
local chainDecals: { { Decal } } = {}
for i = 1, CHAIN_MAX do
	local p = new("Part", {
		Name = "Arrow" .. i,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Transparency = 1,
		Size = Vector3.new(CHAIN_SIZE, 0.05, CHAIN_SIZE),
		CFrame = CFrame.new(0, -1e4, 0),
		Parent = chainFolder,
	})
	-- dessus et dessous : on la voit aussi en volant sous elle
	local top = new("Decal", { Face = Enum.NormalId.Top, Texture = UIKit.Art.ArrowUp or Icons.Ids.ArrowUp, Parent = p })
	local bottom = new("Decal", { Face = Enum.NormalId.Bottom, Texture = UIKit.Art.ArrowUp or Icons.Ids.ArrowUp, Parent = p })
	chain[i] = p
	chainDecals[i] = { top, bottom }
end
local chainParams = RaycastParams.new()
chainParams.FilterType = Enum.RaycastFilterType.Exclude
chainParams.IgnoreWater = true
local chainCFrames: { CFrame } = {}
local HIDDEN = CFrame.new(0, -1e4, 0)

-- Pose la chaîne de « from » (pieds du joueur) vers « to » (le but) ; nil = tout cacher
local function placeChain(from: Vector3?, to: Vector3?, character: Model?)
	local count = 0
	if from and to then
		local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		local dist = (to - from).Magnitude
		-- on laisse un peu de place autour du joueur et du but
		local first, last = 3.5, dist - 4
		if last > first and flat.Magnitude > 0.5 then
			chainParams.FilterDescendantsInstances = { chainFolder, character :: Instance }
			local now = os.clock()
			local d = first
			while d <= last and count < CHAIN_MAX do
				count += 1
				local p = from:Lerp(to, d / dist)
				-- collée au sol s'il y en a juste dessous (pont du vaisseau, base) ; sinon en l'air
				local hit = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -9, 0), chainParams)
				if hit then
					p = hit.Position + Vector3.new(0, 0.15, 0)
				end
				-- vague de lumière qui file vers le but, petit rebond
				local wave = (math.sin(now * 6 - count * 0.7) + 1) / 2
				-- le haut de l'image va vers l'arrière de la pièce (+Z) : on tourne la pièce dos au but
				local cf = CFrame.lookAt(p, p - flat) * CFrame.new(0, wave * 0.35, 0)
				chainCFrames[count] = cf
				local decals = chainDecals[count]
				local t = 0.45 - 0.45 * wave
				decals[1].Transparency = t
				decals[2].Transparency = t
				d += CHAIN_GAP
			end
		end
	end
	for i = count + 1, CHAIN_MAX do
		chainCFrames[i] = HIDDEN
	end
	workspace:BulkMoveTo(chain, chainCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

-- but hors de l'écran (derrière la caméra, sur le côté) : grosse flèche au bord de l'écran qui montre
-- où se tourner, avec l'icône de l'étape dedans
local edge = UIKit.icon("ArrowUp", {
	Name = "EdgeArrow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(110, 110),
	Visible = false,
	ZIndex = 15,
	Parent = gui,
})
local edgeIcon = UIKit.icon("Jetpack", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(64, 64),
	Visible = false,
	ZIndex = 16,
	Parent = gui,
})
-- flèche qui rebondit au-dessus du but (pas AlwaysOnTop : ces BillboardGui ne s'affichent pas dans ce jeu)
local markerPart = new("Part", {
	Name = "GuideMarker",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.one * 0.2,
	Parent = workspace,
})
local marker = new("BillboardGui", {
	Size = UDim2.fromScale(5, 5),
	LightInfluence = 0,
	MaxDistance = 3000,
	Enabled = false,
	Parent = markerPart,
})
UIKit.icon("ArrowUp", { Size = UDim2.fromScale(1, 1), Rotation = 180, Parent = marker })
-- contour qui fait briller le but, même derrière un mur
local glow = new("Highlight", {
	Name = "GuideGlow",
	FillColor = ARROW,
	OutlineColor = Color3.new(1, 1, 1),
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	Enabled = false,
	Parent = gui,
})

-- OÙ SONT LES CHOSES ----------------------------------------------------------------------

local function myBase(): Model?
	local index = player:GetAttribute("Base")
	local ship = workspace:FindFirstChild("Ship")
	local bases = ship and ship:FindFirstChild("Bases")
	return bases and type(index) == "number" and bases:FindFirstChild("Base" .. index) :: Model? or nil
end

local function myMachine(): Model?
	local base = myBase()
	return base and base:FindFirstChild("DerockMachine") :: Model?
end

local function myTunnel(): Model?
	local index = player:GetAttribute("Base")
	local ship = workspace:FindFirstChild("Ship")
	local tunnels = ship and ship:FindFirstChild("WindTunnels")
	return tunnels and type(index) == "number" and tunnels:FindFirstChild("Tunnel" .. index) :: Model? or nil
end

local function posOf(x: Instance?): Vector3?
	if not x then
		return nil
	elseif x:IsA("BasePart") then
		return x.Position
	elseif x:IsA("Attachment") then
		return x.WorldPosition -- ex. PromptPoint, le point de l'invite de la machine
	elseif x:IsA("Model") then
		-- centre réel (le pivot d'un modèle importé peut être loin de lui)
		return (x :: Model):GetBoundingBox().Position
	end
	return nil
end

local function rootPos(): Vector3?
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return hrp and hrp.Position
end

-- Roche la plus proche (de l'anneau voulu, sinon n'importe laquelle), bien visible
local function nearestRock(ring: number?): BasePart?
	local from = rootPos()
	local belt = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Belt")
	if not from or not belt then
		return nil
	end
	local best, bestD = nil, math.huge
	for _, m in ipairs(belt:GetChildren()) do
		local rock = m:FindFirstChild("Asteroid")
		if rock and rock:IsA("BasePart") and (rock:GetAttribute("HP") or 0) > 0 and rock.Transparency < 0.5 then
			local d = (rock.Position - from).Magnitude
			if ring and m.Name ~= "Ring" .. ring then
				d += 10000
			end
			if d < bestD then
				best, bestD = rock, d
			end
		end
	end
	return best
end

-- Mes œufs en incubation (et le premier prêt à éclore), mes créatures
local function myEggs(): (number, Model?, Model?)
	local n, ready, any = 0, nil, nil
	local now = workspace:GetServerTimeNow()
	for _, m in ipairs(CollectionService:GetTagged("Incubating")) do
		if m:GetAttribute("Owner") == player.UserId and m.Parent then
			n += 1
			any = m
			local at = m:GetAttribute("HatchAt") :: number?
			if at and at <= now and not m:GetAttribute("Hatching") and not ready then
				ready = m
			end
		end
	end
	return n, ready, any
end

local function myPets(): number
	local n = 0
	for _, m in ipairs(CollectionService:GetTagged("Creature")) do
		if m:GetAttribute("Owner") == player.UserId and m.Parent then
			n += 1
		end
	end
	return n
end

-- Stand ITEMS du vaisseau (Ship.Shops.ItemsStand) : on vise son tapis, qui ouvre l'atelier quand on marche dessus
local function shopKiosk(): Instance?
	local shops = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Shops")
	local stand = shops and shops:FindFirstChild("ItemsStand")
	return stand and (stand:FindFirstChild("Mat") or stand:FindFirstChild("ShopPoint"))
end

local function attr(name: string): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

-- Tapis du stand SELL : y marcher ouvre le comptoir
local function sellMat(): Instance?
	local shops = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Shops")
	local stand = shops and shops:FindFirstChild("SellStand")
	return stand and stand:FindFirstChild("Mat")
end

local function windowOpen(name: string): boolean
	local w = UIKit.Windows[name]
	return w ~= nil and w.isOpen()
end

-- QUOI DIRE --------------------------------------------------------------------------------

type Hint = { icon: string, text: string, sub: string?, target: Instance?, hold: string? }

local reached = -1 -- étape la plus avancée envoyée au serveur
local petCheerAt = 0

-- Étape suivante franchie : on l'enregistre et on fait la fête
local function advance(step: number, quiet: boolean?)
	if step <= reached then
		return
	end
	reached = step
	Remotes.Guide:FireServer(step)
	if not quiet then
		celebrate(if step >= G.Steps then "You did it!" else nil)
	end
end

-- « Vole jusqu'à une roche » ou, une fois dessus, « maintiens pour forer »
local function goRock(ring: number?, sub: string?): Hint
	local rock = nearestRock(ring)
	if player:GetAttribute("RockNear") then
		local kind = Device.Kind()
		return {
			icon = if kind == "Touch" then "Tap" elseif kind == "Gamepad" then "Lightning" else "Mouse",
			text = if kind == "Touch" then "Hold DRILL!" elseif kind == "Gamepad" then ("Hold %s to drill!"):format(Device.Key("drill")) else "Hold click to drill!",
			sub = sub,
			target = rock,
			hold = "drill",
		}
	end
	return { icon = "Jetpack", text = if ring and ring > 1 then ("Fly to Ring %d!"):format(ring) else "Fly to a rock!", sub = sub or ("Hold %s to fly"):format(if Device.IsTouch() then "jump" else Device.Key("jump")), target = rock }
end

-- Rapporter ce qu'on porte à la machine (œuf ou géode)
local function carryHint(machine: Model?, geode: boolean): Hint
	local here = rootPos()
	local console = machine and machine:FindFirstChild("PromptPoint", true)
	local mp = posOf(console or machine)
	if here and mp and (here - mp).Magnitude < G.MachineNear then
		return { icon = "Lightning", text = if Device.IsTouch() then "Tap the button!" else ("Press %s!"):format(Device.Key("machine")), sub = if geode then "The machine opens your geode" else "Free your egg from the rock", target = machine }
	end
	-- l'air de l'œuf s'épuise (ColdService) : on le dit à l'enfant, en secondes
	local air = player:GetAttribute("O2Left")
	return {
		icon = if geode then "Sparkles" else "Home",
		text = if geode then "A geode! Bring it home!" else "Bring it home!",
		sub = if type(air) == "number" then ("Fast! %d s of air left"):format(math.ceil(air)) else "Follow the arrow",
		target = machine,
	}
end

local function decide(step: number): Hint?
	local cargo = attr("Cargo")
	local held = player:GetAttribute("HeldEgg")
	local machine = myMachine()
	local job = machine and machine:GetAttribute("Owner") == player.UserId and machine:GetAttribute("JobEnd") ~= nil
	local eggs, readyEgg, anyEgg = myEggs()
	local pets = myPets()
	local base = myBase()
	local floor = base and base:FindFirstChild("Floor")

	-- étapes franchies (dans l'ordre ; un joueur qui saute des étapes les franchit toutes d'un coup)
	if step < 1 and (cargo > 0 or job or held or eggs > 0 or pets > 0) then
		advance(1)
		step = 1
	end
	if step < 2 and (job or held or attr("ReadyEggs") > 0 or eggs > 0 or pets > 0) then
		advance(2)
		step = 2
	end
	if step < 3 and (eggs > 0 or pets > 0) then
		advance(3)
		step = 3
	end
	if step < 4 and pets > 0 then
		advance(4, true) -- la bannière d'éclosion fait déjà la fête
		step = 4
		petCheerAt = os.clock()
	end
	if step == 4 then
		if petCheerAt == 0 then
			petCheerAt = os.clock()
		end
		if os.clock() - petCheerAt > G.PetCheer then
			advance(5)
			step = 5
		else
			return { icon = "Cash", text = "Your pet makes money!", sub = "Every second, even when you're away" }
		end
	end
	if step == 5 and pets >= G.Pets then
		advance(6, true)
		step = 6
	end
	local tunnel = myTunnel()
	if step == 6 and tunnel and tunnel:GetAttribute("OwnerId") == player.UserId and (tunnel:GetAttribute("Tier") or 0) >= 1 then
		advance(7)
		step = 7
	end
	if step == 7 and attr("JetLevel") >= G.JetLevel then
		advance(8)
		step = 8
	end
	if step == 8 and attr("Drill") >= G.Drill then
		advance(9)
		step = 9
	end
	if step == 9 and attr("Lvl_Scanner") >= 1 then
		advance(G.Steps)
		step = G.Steps
	end
	if step >= G.Steps then
		return nil
	end

	-- la boucle de l'œuf passe avant tout (même pendant les objectifs suivants)
	if readyEgg then
		return { icon = "Hatch", text = if Device.IsTouch() then "Tap HATCH!" else ("Press %s to hatch!"):format(Device.Key("hatch")), sub = "Your egg is ready", target = readyEgg }
	end
	if held then
		return { icon = "Egg", text = "Put your egg down!", sub = if Device.IsTouch() then "Tap the floor of your base" elseif Device.IsGamepad() then ("Walk on your base, press %s"):format(Device.Key("place")) else "Click the floor of your base", target = floor, hold = "tap" }
	end
	if job then
		return { icon = "Lightning", text = "Watch the machine!", sub = "It breaks the rock", target = machine }
	end
	if cargo > 0 then
		return carryHint(machine, string.split(player:GetAttribute("CargoKinds") or "", ",")[1] == "geode")
	end

	-- objectifs
	if step <= 2 then
		return goRock(1)
	elseif step == 3 and pets == 0 and eggs == 1 and anyEgg and ((anyEgg:GetAttribute("HatchTime") or 99) :: number) <= Config.Hatch.FirstTime then
		-- le tout premier œuf éclot en quelques secondes : on reste là pour le voir
		return { icon = "Hatch", text = "Your egg is hatching!", sub = "Just a few seconds...", target = anyEgg }
	elseif step == 3 then
		-- l'œuf couve : on apprend à repartir chercher le suivant en attendant
		return goRock(1, "Get another egg while it hatches!")
	elseif step == 5 then
		return goRock(nil, ("Get %d pets!  %d/%d"):format(G.Pets, pets, G.Pets))
	elseif step == 6 then
		local cost = Config.Jetpack.Tunnels[1].Cost
		if attr("Credits") >= cost then
			return { icon = "WindTunnel", text = "Buy your wind tunnel!", sub = "It makes your jetpack stronger", target = tunnel }
		end
		return goRock(nil, ("Save $%s for a wind tunnel  ($%s)"):format(Format.Short(cost), Format.Short(attr("Credits"))))
	elseif step == 7 then
		local level = ("Jetpack level %d/%d"):format(attr("JetLevel"), G.JetLevel)
		if player:GetAttribute("InTunnel") then
			return { icon = "WindTunnel", text = "Train in the wind!", sub = level }
		end
		return { icon = "WindTunnel", text = "Stand in the wind!", sub = level, target = tunnel }
	elseif step == 8 then
		local cost = Config.Drills[G.Drill].Cost
		if attr("Credits") >= cost then
			return { icon = "Lightning", text = "Buy a new drill!", sub = "It drills much faster", target = shopKiosk() }
		end
		return goRock(nil, ("Save $%s for a new drill  ($%s)"):format(Format.Short(cost), Format.Short(attr("Credits"))))
	elseif step == 9 then
		-- la chance : le Scanner (atelier des foreuses, onglet UPGRADES) donne des œufs plus rares
		local cost = Config.UpgradeCost("Scanner", attr("Lvl_Scanner"))
		if attr("Credits") >= cost then
			return { icon = "Sparkles", text = "Boost your luck!", sub = "Shop > UPGRADES > Scanner: rarer eggs!", target = shopKiosk() }
		end
		return goRock(nil, ("Save $%s for more luck  ($%s)"):format(Format.Short(cost), Format.Short(attr("Credits"))))
	end
	return nil
end

-- TUTORIELS AU BON MOMENT -------------------------------------------------------------------

local tipStart: { [string]: number } = {}
local tipDone: { [string]: boolean } = {}
local activeTip: string? = nil

local function tipSeen(key: string): boolean
	return tipDone[key] == true or player:GetAttribute("Tip_" .. key) == true
end

local function finishTip(key: string)
	if not tipSeen(key) then
		tipDone[key] = true
		Remotes.Guide:FireServer("tip", key)
	end
	if activeTip == key then
		activeTip = nil
	end
end

-- Montre ce tip jusqu'à maxTime secondes, puis le considère comme vu (on ne bloque jamais le joueur)
local function timedTip(key: string, maxTime: number, hint: Hint): Hint?
	tipStart[key] = tipStart[key] or os.clock()
	if os.clock() - tipStart[key] > maxTime then
		finishTip(key)
		return nil
	end
	activeTip = key
	return hint
end

local function decideTip(): Hint?
	activeTip = nil
	local cargo = attr("Cargo")
	local machine = myMachine()
	local job = machine and machine:GetAttribute("Owner") == player.UserId and machine:GetAttribute("JobEnd") ~= nil
	local geode = cargo > 0 and string.split(player:GetAttribute("CargoKinds") or "", ",")[1] == "geode"
	-- première géode portée : ce n'est pas un œuf, on explique où l'emmener
	if geode and not tipSeen("geode") then
		if job then
			finishTip("geode")
		else
			activeTip = "geode"
			return carryHint(machine, true)
		end
	end
	-- la boucle en cours passe d'abord : on n'interrompt pas un joueur qui a les mains pleines
	local _, readyEgg = myEggs()
	if cargo > 0 or job or player:GetAttribute("HeldEgg") or readyEgg then
		return nil
	end
	-- un œuf attend et la base est pleine
	if not tipSeen("basefull") and attr("BaseSlots") > 0 and attr("BaseUsed") >= attr("BaseSlots") and attr("ReadyEggs") > 0 then
		if windowOpen("Sell") or windowOpen("CreaturesWindow") then
			finishTip("basefull")
		else
			return timedTip("basefull", G.TipMax, { icon = "Home", text = "Your base is full!", sub = "At SELL, sell a pet to make room", target = sellMat() })
		end
	end
	-- premier minerai dans le sac
	if not tipSeen("gem") and attr("GemCount") > 0 then
		if windowOpen("Sell") then
			finishTip("gem")
		else
			return timedTip("gem", G.TipMax, { icon = "Sparkles", text = "You got a gem!", sub = "Step on the SELL mat to cash it in", target = sellMat() })
		end
	end
	-- la Supernova vient de se débloquer
	if not tipSeen("supernova") and attr("JetLevel") >= Config.Supernova.Level then
		if windowOpen("Supernova") then
			finishTip("supernova")
		else
			local where = if Device.IsGamepad() then "D-pad down" else "the SUPERNOVA button"
			return timedTip("supernova", G.TipShort, { icon = "Supernova", text = "SUPERNOVA unlocked!", sub = ("Press %s: +50%% money forever"):format(where) })
		end
	end
	return nil
end

-- AFFICHAGE --------------------------------------------------------------------------------

local shown: Hint? = nil
local currentTarget: Instance? = nil

local function show(h: Hint?)
	if not h then
		if shown then
			holder.Visible = false
			hand.Visible = false
			player:SetAttribute("Guide", nil)
		end
		shown = nil
		currentTarget = nil
		return
	end
	local changed = not shown or shown.text ~= h.text or shown.icon ~= h.icon
	shown = h
	currentTarget = h.target
	if changed then
		icon.Image = Icons.Ids[h.icon] or UIKit.Art[h.icon] or ""
		Icons.Apply(mainText, h.text)
		player:SetAttribute("Guide", h.text)
		holder.Visible = true
		UIKit.popIn(bubble)
	end
	subText.Text = h.sub or ""
	local step = attr("GuideStep")
	stars.Visible = step < G.Steps
	for i, s in ipairs(starIcons) do
		s.ImageTransparency = if i <= step then 0 else 0.7
		s.ImageColor3 = if i <= step then Color3.new(1, 1, 1) else Color3.fromRGB(120, 120, 140)
	end
end

skip.MouseButton1Click:Connect(function()
	-- un tip : la croix l'efface tout de suite
	if activeTip then
		finishTip(activeTip)
		show(nil)
		return
	end
	if os.clock() - skipArmed < 3 then
		Remotes.Guide:FireServer("skip")
		reached = G.Steps
		show(nil)
		return
	end
	skipArmed = os.clock()
	skipAsk.Visible = true
	task.delay(3, function()
		skipAsk.Visible = false
	end)
end)

task.spawn(function()
	while true do
		task.wait(0.15)
		local step = player:GetAttribute("GuideStep")
		if type(step) ~= "number" then
			show(nil)
		else
			-- une erreur ne doit jamais figer le guide : on l'affiche et on continue
			local hint: Hint? = nil
			if step < G.Steps and reached < G.Steps then
				reached = math.max(reached, step)
				local ok, result = pcall(decide, math.max(step, reached))
				if ok then
					hint = result
				else
					warn("[Guide]", result)
				end
			end
			local okTip, tip = pcall(decideTip)
			if not okTip then
				warn("[Guide]", tip)
				tip = nil
			end
			show(tip or hint)
		end
	end
end)

-- Chaque image : flèche au sol vers le but, flèche qui rebondit au-dessus, contour, main qui montre
RunService.RenderStepped:Connect(function()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local target = currentTarget
	local tp = posOf(target)
	if not hrp or not tp or not target or not target.Parent then
		beam.Enabled = false
		marker.Enabled = false
		glow.Enabled = false
		edge.Visible = false
		edgeIcon.Visible = false
		placeChain(nil, nil, nil)
	else
		-- flèche au bord de l'écran si le but n'est pas visible
		local cam = workspace.CurrentCamera
		local vp = cam.ViewportSize
		local v, onScreen = cam:WorldToViewportPoint(tp)
		local near = (tp - hrp.Position).Magnitude < 14
		if near or (onScreen and v.X > 40 and v.X < vp.X - 40 and v.Y > 40 and v.Y < vp.Y - 40) then
			edge.Visible = false
			edgeIcon.Visible = false
		else
			local center = vp / 2
			local dir = Vector2.new(v.X, v.Y) - center
			if v.Z < 0 then
				dir = -dir -- derrière la caméra : la projection est inversée
			end
			if dir.Magnitude < 1 then
				dir = Vector2.new(0, 1)
			end
			dir = dir.Unit
			-- sur une ellipse, sans cacher les boutons du HUD (gauche, haut droite) ni la bulle
			local rx, ry = math.max(120, vp.X / 2 - 250), math.max(100, vp.Y / 2 - 150)
			local p = center + Vector2.new(dir.X * rx, dir.Y * ry)
			local pulse = 1 + 0.12 * math.sin(os.clock() * 6)
			edge.Position = UDim2.fromOffset(p.X, p.Y)
			edge.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
			edge.Size = UDim2.fromOffset(110 * pulse, 110 * pulse)
			edgeIcon.Image = icon.Image
			edgeIcon.Position = UDim2.fromOffset(p.X - dir.X * 70, p.Y - dir.Y * 70)
			edge.Visible = true
			edgeIcon.Visible = true
		end
		if a0.Parent ~= hrp then
			a0.Parent = hrp
			a0.Position = Vector3.new(0, -2.4, 0)
		end
		local size = if target:IsA("Model") then (target :: Model):GetExtentsSize() elseif target:IsA("BasePart") then (target :: BasePart).Size else Vector3.one
		-- assez haut pour ne pas cacher le nom et le minuteur affichés au-dessus des œufs
		local top = tp + Vector3.new(0, size.Y / 2 + 7, 0)
		a1.WorldPosition = tp
		local far = (tp - hrp.Position).Magnitude
		beam.Enabled = far > 7
		placeChain(hrp.Position - Vector3.new(0, 2.6, 0), tp, character)
		-- plus le but est loin, plus la flèche est large (on la voit de loin)
		local w = math.clamp(far / 25, 1.6, 4)
		beam.Width0, beam.Width1 = w, w
		local bob = math.abs(math.sin(os.clock() * 4)) * 1.5
		markerPart.Position = top + Vector3.new(0, bob, 0)
		local s = math.clamp(far / 12, 4, 14)
		marker.Size = UDim2.fromScale(s, s)
		-- tout près du but (debout sur la roche, devant la machine) : le contour suffit
		marker.Enabled = far > 14
		local glowTarget = if target:IsA("BasePart") and target.Name == "Asteroid" then target.Parent else target
		if glowTarget and glowTarget.Name ~= "Floor" then
			glow.Adornee = glowTarget
			glow.Enabled = true
			glow.FillTransparency = 0.6 + 0.3 * math.abs(math.sin(os.clock() * 3))
		else
			glow.Enabled = false
		end
	end
	-- main : sur téléphone, elle appuie sur le bouton DRILL ; sur ordinateur, elle clique sur la roche ;
	-- à la manette, un rond avec le nom de la touche (RT) s'enfonce à côté du but
	local h = shown
	local pad = Device.IsGamepad()
	padBadge.Visible = false
	if h and h.hold and pad then
		hand.Visible = false
		if tp then
			local v, onScreen = workspace.CurrentCamera:WorldToViewportPoint(tp)
			if onScreen then
				padBadge.Visible = true
				padBadge.Position = UDim2.fromOffset(v.X + 50, v.Y + 20)
				padLabel.Text = Device.Key(if h.hold == "drill" then "drill" else "place")
				local t = os.clock()
				badgeScale.Scale = if h.hold == "drill" then 1 - 0.15 * math.min(1, (t % 1.6) * 4) else 1 - 0.15 * math.abs(math.sin(t * 6))
			end
		end
	elseif h and h.hold then
		local pos: Vector2? = nil
		if h.hold == "drill" and Device.IsTouch() then
			local mobile = player.PlayerGui:FindFirstChild("Mobile")
			local btn = mobile and mobile:FindFirstChild("Drill", true) :: GuiObject?
			if btn then
				pos = btn.AbsolutePosition + btn.AbsoluteSize / 2 + Vector2.new(18, 26)
			end
		elseif tp then
			local v, onScreen = workspace.CurrentCamera:WorldToViewportPoint(tp)
			if onScreen then
				pos = Vector2.new(v.X + 22, v.Y + 30)
			end
		end
		if pos then
			hand.Visible = true
			hand.Position = UDim2.fromOffset(pos.X, pos.Y)
			-- « maintenir » : la main appuie et reste enfoncée ; « toucher » : petites tapes
			local t = os.clock()
			handScale.Scale = if h.hold == "drill" then 1 - 0.15 * math.min(1, (t % 1.6) * 4) else 1 - 0.15 * math.abs(math.sin(t * 6))
		else
			hand.Visible = false
		end
	else
		hand.Visible = false
	end
end)
