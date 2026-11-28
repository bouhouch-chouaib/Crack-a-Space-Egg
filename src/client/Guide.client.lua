-- Guide des premières minutes (docs/Mecaniques.md §16, Config.Guide), refait le 30 nov. en trois actes.
--   Acte 1, le premier œuf : guidé de bout en bout, une consigne à la fois (voler, forer, rentrer, machine,
--           poser, faire éclore). Le premier œuf est rare ; le monstre poursuit mais ne rattrape pas (serveur).
--   Acte 2, tout seul : le joueur refait la boucle jusqu'à avoir Config.Guide.Pets créatures. Il ne reste à
--           l'écran qu'une petite pastille « PETS 1/3 » ; la consigne et la flèche ne reviennent que s'il
--           n'avance plus (Config.Guide.Patience). À la fin : un cadeau (potion de chance, de quoi payer la soufflerie).
--   Acte 3, plus fort : acheter sa soufflerie, y passer quelques secondes, puis le coffre de fin et le bouton
--           REWARDS qu'une main vient montrer.
-- Règles : 2 ou 3 mots en gros avec une grosse icône, jamais de phrase ; au plus un chiffre dans la pastille de
-- droite (secondes d'air, compte à rebours, argent). Une flèche au sol file vers le but, une flèche rebondit
-- au-dessus, un contour le fait briller, une main montre le geste, et une petite fête salue chaque réussite.
-- Il suit l'état réel du joueur, pas un script figé : s'il tombe, perd son œuf ou part ailleurs, la consigne
-- s'adapte. Étape atteinte : attribut GuideStep (sauvegardé par le serveur via Remotes.Guide).
-- La même bulle sert aux tutoriels au bon moment (Config.Guide.Tips), une seule fois par joueur et seulement
-- quand il en a besoin. Publie l'attribut local Guide (texte en cours) : l'aide du bas (Hud) se cache.

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
	Size = UDim2.fromOffset(470, 96),
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
local icon = UIKit.icon("Jetpack", { Size = UDim2.fromOffset(104, 104), Position = UDim2.new(0, -34, 0.5, -56), ZIndex = 3, Parent = bubble })
UIKit.float(icon, 4, 4, 2.4)
-- la consigne : 2 ou 3 mots, sur toute la hauteur de la bulle
local mainText = UIKit.text({
	Name = "Main",
	Size = UDim2.new(1, -100, 0, 64),
	Position = UDim2.fromOffset(80, 16),
	Text = "",
	TextColor3 = INK,
	TextXAlignment = Enum.TextXAlignment.Left,
	Stroke = 0,
	ZIndex = 3,
	Parent = bubble,
})
-- pastille sombre à droite : un chiffre seulement (secondes, argent), jamais une phrase
local chip = new("Frame", {
	Name = "Chip",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(104, 50),
	BackgroundColor3 = INK,
	Visible = false,
	ZIndex = 3,
	Parent = bubble,
}, { UIKit.corner(16) })
local chipText = UIKit.text({ Size = UDim2.new(1, -12, 1, -10), Position = UDim2.fromOffset(6, 5), Text = "", ZIndex = 4, Stroke = 0, Parent = chip })
-- petite pastille d'objectif (acte 2 : « PETS 1/3 ») : le joueur joue seul, elle ne demande rien
local pill = new("Frame", {
	Name = "Pill",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromOffset(250, 52),
	BackgroundColor3 = INK,
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = holder,
}, { UIKit.corner(26), UIKit.stroke(3, Color3.new(1, 1, 1)) })
local pillIcon = UIKit.icon("Egg", { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(10, 4), ZIndex = 3, Parent = pill })
local pillText = UIKit.text({ Size = UDim2.new(1, -72, 1, -14), Position = UDim2.fromOffset(60, 7), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Stroke = 2.5, Parent = pill })
-- étoiles de progression au-dessus de la bulle
local stars = new("Frame", {
	Name = "Stars",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -104),
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
	Position = UDim2.new(1, 0, 0, -4),
	Size = UDim2.fromOffset(170, 26),
	Text = "TAP AGAIN!",
	Visible = false,
	ZIndex = 6,
	Parent = skip,
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
	Size = UDim2.fromOffset(220, 44),
	Text = "",
	TextColor3 = GOLD,
	Stroke = 4,
	Visible = false,
	ZIndex = 30,
	Parent = gui,
})
local cheerScale = new("UIScale", { Parent = cheer })
-- calque plein écran pour les étincelles de la fête (UIKit.burst a besoin d'un cadre)
local fxLayer = new("Frame", { Name = "Fx", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 29, Parent = gui })
local CHEERS = { "GREAT!", "AWESOME!", "NICE JOB!", "SUPER!", "AMAZING!" }

local cheerToken = 0

local function celebrate(text: string?)
	cheerToken += 1
	local token = cheerToken
	cheer.Text = text or CHEERS[math.random(1, #CHEERS)]
	cheer.Visible = true
	cheer.TextTransparency = 0
	cheerScale.Scale = 0.2
	TweenService:Create(cheerScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	UIKit.burst(fxLayer, UDim2.fromScale(0.5, 0.24), GOLD)
	Sfx.Play("Pop")
	task.delay(0.7, function()
		if token ~= cheerToken then
			return
		end
		TweenService:Create(cheer, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		task.wait(0.2)
		if token == cheerToken then
			cheer.Visible = false
		end
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
-- Une consigne : icône, 2 ou 3 mots, et au besoin un chiffre (chip), un but dans le monde (target), un geste
-- montré par la main (hold), un bouton de l'écran à montrer (ui), ou la petite pastille d'objectif (small).

type Hint = { icon: string, text: string, chip: string?, target: Instance?, hold: string?, ui: string?, small: boolean? }

local reached = -1 -- étape la plus avancée envoyée au serveur
local petCheerAt = 0
local justFinished = false -- le tutoriel vient d'être fini dans cette partie (la main montre REWARDS)

-- Étape suivante franchie : on l'enregistre et on fait la fête
local function advance(step: number, quiet: boolean?, cheerText: string?)
	if step <= reached then
		return
	end
	reached = step
	Remotes.Guide:FireServer(step)
	if step >= G.Steps then
		justFinished = true
	end
	if not quiet then
		celebrate(if step >= G.Steps then "YOU DID IT!" else cheerText)
	end
end

local function pressText(action: string, touch: string): string
	return if Device.IsTouch() then touch else ("PRESS %s!"):format(Device.Key(action))
end

-- « Vole jusqu'à une roche » ou, une fois dessus, « maintiens pour forer »
local function rockHint(): Hint
	local rock = nearestRock(1)
	if player:GetAttribute("RockNear") then
		local kind = Device.Kind()
		return {
			icon = if kind == "Touch" then "Tap" elseif kind == "Gamepad" then "Lightning" else "Mouse",
			text = if kind == "Touch" then "HOLD DRILL!" elseif kind == "Gamepad" then ("HOLD %s!"):format(Device.Key("drill")) else "HOLD TO DRILL!",
			target = rock,
			hold = "drill",
		}
	end
	return { icon = "Jetpack", text = "FLY TO ROCK!", target = rock }
end

-- Rapporter la roche à la machine ; l'air qui reste à l'œuf (ColdService) s'affiche en secondes, sans phrase
local function carryHint(machine: Model?, rare: boolean): Hint
	local here = rootPos()
	local console = machine and machine:FindFirstChild("PromptPoint", true)
	local mp = posOf(console or machine)
	if here and mp and (here - mp).Magnitude < G.MachineNear then
		return { icon = "Lightning", text = pressText("machine", "TAP BUTTON!"), target = machine }
	end
	local air = player:GetAttribute("O2Left")
	return {
		icon = "Home",
		text = if rare then "RARE EGG! RUN!" else "RUN HOME!",
		chip = if type(air) == "number" then ("%d s"):format(math.ceil(air)) else nil,
		target = machine,
	}
end

-- Acte 2 : le joueur a-t-il cessé d'avancer ? On regarde ce qu'il a à faire (state) et s'il s'en rapproche
-- (distance au but, ou vie de la roche qui baisse) ; tant qu'il avance, on se tait.
local watch = { state = "", since = 0, best = math.huge }
local function stuck(state: string, patience: number, measure: number?): boolean
	local now = os.clock()
	local m = measure or math.huge
	if watch.state ~= state then
		watch.state, watch.since, watch.best = state, now, m
	elseif m < watch.best - 3 then
		watch.best, watch.since = m, now
	end
	return now - watch.since >= patience
end

local function distanceTo(x: Instance?): number?
	local here = rootPos()
	local there = posOf(x)
	return if here and there then (here - there).Magnitude else nil
end

local tunnelTime = 0 -- secondes passées dans sa soufflerie pendant l'acte 3
local lastDecide = os.clock()

local function decideStep(step: number): Hint?
	local cargo = attr("Cargo")
	local held = player:GetAttribute("HeldEgg")
	local machine = myMachine()
	local job = machine and machine:GetAttribute("Owner") == player.UserId and machine:GetAttribute("JobEnd") ~= nil
	local eggs, readyEgg, anyEgg = myEggs()
	local pets = myPets()
	local base = myBase()
	local floor = base and base:FindFirstChild("Floor")
	local tunnel = myTunnel()
	local hasTunnel = tunnel ~= nil and tunnel:GetAttribute("OwnerId") == player.UserId and ((tunnel:GetAttribute("Tier") or 0) :: number) >= 1
	local tunnelCost = Config.Jetpack.Tunnels[1].Cost
	local now = os.clock()
	local dt = math.min(now - lastDecide, 1)
	lastDecide = now

	-- étapes franchies (dans l'ordre ; un joueur qui saute des étapes les franchit toutes d'un coup)
	local later = eggs > 0 or pets > 0 or held ~= nil or attr("ReadyEggs") > 0
	if step < 1 and (cargo > 0 or job or later) then
		advance(1)
		step = 1
	end
	if step < 2 and (job or later) then
		advance(2)
		step = 2
	end
	if step < 3 and (eggs > 0 or pets > 0) then
		advance(3)
		step = 3
	end
	if step < 4 and pets > 0 then
		advance(4, true) -- la bannière de la créature rare fait la fête
		step = 4
		petCheerAt = os.clock()
	end
	-- acte 2 fini : il a ses créatures (ou déjà de quoi acheter la soufflerie) ; le serveur donne le cadeau
	if step == 4 and (pets >= G.Pets or hasTunnel or attr("Credits") >= tunnelCost) then
		advance(5, false, "GIFT!")
		Sfx.Play("Coin")
		step = 5
	end
	if step == 5 and hasTunnel then
		advance(6)
		step = 6
	end
	if step == 6 then
		if player:GetAttribute("InTunnel") then
			tunnelTime += dt
		end
		if tunnelTime >= G.TunnelTime then
			advance(G.Steps)
			step = G.Steps
		end
	end
	if step >= G.Steps then
		return nil
	end

	-- ce que la boucle de l'œuf demande maintenant
	local rare = false
	if step <= 2 and cargo > 0 then
		local rarity = tonumber(string.split(player:GetAttribute("CargoRarities") or "", ",")[1] or "")
		rare = rarity ~= nil and rarity >= G.FirstRarity
	end
	local state, hint, patience, measure
	if readyEgg then
		state, patience, measure = "hatch", G.Patience.Hatch, distanceTo(readyEgg)
		hint = { icon = "Hatch", text = pressText("hatch", "TAP HATCH!"), target = readyEgg }
	elseif held then
		state, patience, measure = "place", G.Patience.Place, distanceTo(floor)
		hint = { icon = "Egg", text = "PLACE YOUR EGG!", target = floor, hold = "tap" }
	elseif job then
		state, patience = "job", math.huge
		hint = { icon = "Lightning", text = "ROCK BREAKING!", target = machine }
	elseif cargo > 0 then
		state, patience, measure = "carry", G.Patience.Carry, distanceTo(machine)
		hint = carryHint(machine, rare)
	else
		local rock = nearestRock(1)
		state, patience = "rock", G.Patience.Rock
		-- sur la roche : c'est sa vie qui montre qu'il avance ; sinon la distance qui reste
		measure = if player:GetAttribute("RockNear") and rock then ((rock:GetAttribute("HP") or 0) :: number) / math.max(1, (rock:GetAttribute("MaxHP") or 1) :: number) * 30 else distanceTo(rock)
		hint = rockHint()
	end

	-- ACTE 1 : tout est guidé
	if step <= 3 then
		if state == "rock" and step == 3 and anyEgg then
			-- l'œuf est posé : il n'y a qu'à attendre quelques secondes
			local at = anyEgg:GetAttribute("HatchAt") :: number?
			local left = if at then math.max(0, math.ceil(at - workspace:GetServerTimeNow())) else nil
			return { icon = "Hatch", text = "ALMOST READY!", chip = if left then ("%d s"):format(left) else nil, target = anyEgg }
		end
		return hint
	end

	-- ACTE 2 : il joue seul ; la consigne ne revient que s'il n'avance plus
	if step == 4 then
		if petCheerAt > 0 and os.clock() - petCheerAt < G.PetCheer then
			return { icon = "Cash", text = "IT EARNS MONEY!" }
		end
		if stuck(state, patience, measure) then
			return hint
		end
		return { icon = "Egg", text = ("PETS %d/%d"):format(math.min(pets, G.Pets), G.Pets), small = true }
	end

	-- ACTE 3 : la soufflerie
	if step == 5 then
		if attr("Credits") < tunnelCost then
			-- ne devrait pas arriver (le cadeau complète son argent) : on montre ce qui manque, sans phrase
			if stuck(state, patience, measure) then
				return hint
			end
			return { icon = "Cash", text = ("$%s / $%s"):format(Format.Short(attr("Credits")), Format.Short(tunnelCost)), small = true }
		end
		if windowOpen("TunnelUp") then
			return { icon = "WindTunnel", text = "PRESS BUY!" }
		end
		-- debout sur le bouton : il reste à appuyer (ShipShops.client publie l'attribut OnButton)
		if player:GetAttribute("OnButton") == "TunnelUp" then
			return { icon = "WindTunnel", text = pressText("machine", "TAP UPGRADE!") }
		end
		return { icon = "WindTunnel", text = "RED BUTTON!", target = base and base:FindFirstChild("TunnelButton") }
	end
	if player:GetAttribute("InTunnel") then
		local offer = player:GetAttribute("TunnelBoostOffer")
		local bonus = type(offer) == "number" and offer > workspace:GetServerTimeNow()
		return { icon = "WindTunnel", text = if bonus then "TAP x2!" else "TRAINING!", chip = ("%d s"):format(math.max(0, math.ceil(G.TunnelTime - tunnelTime))) }
	end
	return { icon = "WindTunnel", text = "JUMP IN!", target = tunnel }
end

local function decide(step: number): Hint?
	return decideStep(step)
end

-- TUTORIELS AU BON MOMENT -------------------------------------------------------------------

local tipStart: { [string]: number } = {}
local tipDone: { [string]: boolean } = {}
local activeTip: string? = nil
local lastTip = os.clock() -- fin du dernier tip (au départ : on laisse le joueur arriver)

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
	lastTip = os.clock()
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
	-- tutoriel de fusion (Offers.client) : flèche vers la machine, puis CreaturesUI prend le relais
	if player:GetAttribute("FuseTour") then
		if windowOpen("CreaturesWindow") then
			return nil
		end
		local fusion = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Fusion")
		return { icon = "Creatures", text = if Device.IsTouch() then "TAP BUTTON!" else ("PRESS %s!"):format(if Device.IsGamepad() then Device.Key("machine") else "F"), target = fusion }
	end
	local cargo = attr("Cargo")
	local machine = myMachine()
	local job = machine and machine:GetAttribute("Owner") == player.UserId and machine:GetAttribute("JobEnd") ~= nil
	-- la boucle en cours passe d'abord : on n'interrompt pas un joueur qui a les mains pleines
	local _, readyEgg = myEggs()
	if cargo > 0 or job or player:GetAttribute("HeldEgg") or readyEgg then
		return nil
	end
	-- un œuf attend et la base est pleine
	if not tipSeen("basefull") and attr("BaseSlots") > 0 and attr("BaseUsed") >= attr("BaseSlots") and attr("ReadyEggs") > 0 then
		if windowOpen("CreaturesWindow") then
			finishTip("basefull")
		else
			return timedTip("basefull", G.TipMax, { icon = "Home", text = "BASE FULL! SELL!", target = sellMat() })
		end
	end
	-- le grand panneau (récompense, retour de pause) est à l'écran : on ne parle pas en même temps
	local offers = player.PlayerGui:FindFirstChild("Offers")
	local offerCard = offers and offers:FindFirstChild("Holder") :: GuiObject?
	if offerCard and offerCard.Visible then
		lastTip = os.clock()
		return nil
	end
	-- tips d'information : un à la fois, avec du calme entre eux. Un tip déjà affiché continue.
	local running = tipStart.monsters and not tipSeen("monsters")
	if not running and os.clock() - lastTip < G.TipGap then
		return nil
	end
	-- (26 nov. : plus de conseil « A gift for you! » : le bouton REWARDS a déjà sa pastille)
	-- premier passage dans un anneau à monstres
	if not tipSeen("monsters") and player:GetAttribute("MonsterSeen") then
		return timedTip("monsters", G.TipShort, { icon = "Warning", text = "MONSTER HERE!" })
	end
	-- le tutoriel vient d'être fini : une main montre le bouton REWARDS qui vient d'apparaître (cadeaux du jour)
	if justFinished and not tipSeen("rewards") then
		if windowOpen("Rewards") then
			finishTip("rewards")
		else
			return timedTip("rewards", G.TipShort, { icon = "Rewards", text = "DAILY GIFTS!", ui = "Rewards" })
		end
	end
	-- (25 nov. : plus de conseil vers la boîte aux lettres, le joueur y va de lui-même s'il en a envie)
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
	local changed = not shown or shown.text ~= h.text or shown.icon ~= h.icon or shown.small ~= h.small
	local swapped = not shown or shown.icon ~= h.icon or shown.small ~= h.small or (shown.small ~= true and shown.text ~= h.text)
	shown = h
	currentTarget = h.target
	local art = Icons.Ids[h.icon] or UIKit.Art[h.icon] or ""
	if changed then
		player:SetAttribute("Guide", h.text)
		holder.Visible = true
		bubble.Visible = not h.small
		pill.Visible = h.small == true
		skip.Parent = if h.small then pill else bubble
		if h.small then
			pillIcon.Image = art
			Icons.Apply(pillText, h.text)
		else
			icon.Image = art
			Icons.Apply(mainText, h.text)
		end
		-- la pastille d'objectif ne saute pas à chaque créature : seul un vrai changement de consigne « pope »
		if swapped then
			UIKit.popIn(if h.small then pill else bubble)
		end
	end
	if not h.small then
		chip.Visible = h.chip ~= nil
		chipText.Text = h.chip or ""
		mainText.Size = UDim2.new(1, if h.chip then -208 else -100, 0, 64)
	end
	local step = attr("GuideStep")
	stars.Visible = step < G.Steps and not h.small
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
	if h and h.ui then
		-- un bouton du HUD : la main tapote à côté de lui
		local hud = player.PlayerGui:FindFirstChild("MainHUD")
		local menu = hud and hud:FindFirstChild("Menu")
		local button = menu and menu:FindFirstChild(h.ui, true) :: GuiObject?
		if button and button.Visible and button.AbsoluteSize.X > 0 then
			local pos = button.AbsolutePosition + Vector2.new(button.AbsoluteSize.X + 26, button.AbsoluteSize.Y * 0.7) + game:GetService("GuiService"):GetGuiInset()
			hand.Visible = true
			hand.Position = UDim2.fromOffset(pos.X, pos.Y)
			handScale.Scale = 1 - 0.15 * math.abs(math.sin(os.clock() * 6))
		else
			hand.Visible = false
		end
	elseif h and h.hold and pad then
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
