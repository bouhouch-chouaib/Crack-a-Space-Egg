-- INDEX (docs/Interfaces.md §7), sur le modèle de l'index de « Throw Food for Animals » :
-- au centre une seule colonne qui défile avec tous les anneaux à la suite, à droite la créature choisie.
-- Un bloc par anneau : son monde (nom, image, pourcentage trouvé), ses 6 créatures rangées de la moins rare à
-- la plus rare, 3 par ligne (Common, Uncommon, Rare, puis les 3 suivantes), et la barre « n/6 » avec la
-- récompense de l'anneau au bout.
-- 30 nov. : fenêtre plus large et cartes plus grandes (moins tassées en hauteur) ; les astéroïdes ne sont plus
-- montrés nulle part (ni en tête de colonne, ni dans « FOUND IN ») : le joueur n'a pas besoin de savoir quel
-- type d'astéroïde donne quelle créature. À la place, le détail dit dans quel anneau elle vit.
-- Une créature jamais eue dans sa base reste une silhouette noire « ??? ».
-- Le serveur tient la liste (CreatureService : actions « index » et « claim »).
-- Dernier onglet : les reliques des explorateurs perdus (RelicService), en silhouettes tant qu'elles ne sont pas trouvées.
-- Chaque relique donne un bonus pour toujours (Config.RelicBonusText) : vert quand elle est trouvée, grisé sinon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local RelicModel = require(ReplicatedStorage.Shared:WaitForChild("RelicModel"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = game:GetService("Players").LocalPlayer
local new = UIKit.new

-- Mise en page (unités de la fenêtre, avant l'échelle de l'écran)
-- (25 nov. : plus de colonne d'onglets des anneaux à gauche ; le bouton RELICS est dans le bandeau de titre)
local ROOT_W, ROOT_H = 940, 548
local SCROLL_X, SCROLL_W = 0, 660 -- colonne qui défile
local DETAIL_X, DETAIL_W = 668, 272 -- créature (ou relique) choisie
local DETAIL_CX = DETAIL_W / 2
-- Bloc d'un anneau
local EDGE = 6 -- marge autour des blocs dans la colonne : la place de leur contour
local BLOCK_W, BLOCK_H, BLOCK_GAP = 636, 410, 14
local WORLD_X, WORLD_Y, WORLD_W, WORLD_H = 10, 10, 150, 332 -- panneau « monde »
local CARD_W, CARD_H = 146, 160 -- carte d'une créature
local CARD_X, CARD_GAP = 172, 10 -- première carte d'une ligne, écart entre deux cartes
local ROW_Y, ROW_GAP = 10, 12 -- les deux lignes de cartes
local PER_ROW = 3 -- créatures par ligne, de la moins rare à la plus rare
local FOOT_Y, FOOT_H = 354, 44 -- barre de progression et récompense
local BAR_X, BAR_W = 12, 330
local REWARD_X, REWARD_W = 390, 236

local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local PICK = Color3.fromRGB(255, 235, 120) -- contour de ce qui est choisi (onglet, carte)
local GOLD = Color3.fromRGB(255, 230, 110)

local W = UIKit.window({ name = "IndexWindow", title = "{Star} INDEX", color = "Blue", size = Vector2.new(980, 660) })
-- Le contenu tient juste dans la fenêtre : seule la colonne des anneaux défile, pas le corps de la fenêtre
W.body.AutomaticCanvasSize = Enum.AutomaticSize.None
W.body.CanvasSize = UDim2.new()
W.body.ScrollingEnabled = false
W.body.ScrollBarThickness = 0
local root = new("Frame", { Name = "Index", Size = UDim2.fromOffset(ROOT_W, ROOT_H), BackgroundTransparency = 1, LayoutOrder = 1, Parent = W.body })

local seen: { [string]: boolean } = {}
local claimed: { [number]: boolean } = {}
local selRing = 1 -- anneau de la créature choisie
local selSlot = 1 -- son rang dans l'anneau (1 à 6)
local relicMode = false
local relicPick = 1
local relicState = { found = {} :: { [string]: boolean } }

local function key(r: number, slot: number): string
	return r .. ":" .. Config.CreatureRarity(r, slot)
end

local function money(n: number): string
	return "$" .. Format.Short(n)
end

local function clear(f: Instance)
	for _, ch in ipairs(f:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
end

-- APERÇUS 3D ------------------------------------------------------------------------------------
-- Tout ce qui tourne dans un ViewportFrame. « where » dit où est l'aperçu dans le bloc de son anneau
-- (haut et bas, en unités du bloc) : il ne tourne que s'il est dans la partie visible de la colonne.
-- Sans « where » (panneau de détail, reliques), il tourne tant que la fenêtre est ouverte.

type Where = { block: number, top: number, bottom: number }
type Spin = { model: Model, vp: ViewportFrame, phase: number, where: Where? }
local turning: { Spin } = {}

-- Portrait d'une créature (silhouette noire si pas encore eue)
local function portrait(parent: GuiObject, r: number, rarity: number, known: boolean, size: UDim2, pos: UDim2, z: number, where: Where?): ViewportFrame
	local vp = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		Ambient = if known then Color3.fromRGB(190, 190, 205) else Color3.new(0, 0, 0),
		LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0),
		LightDirection = Vector3.new(-1, -1.5, -1),
		ImageColor3 = if known then Color3.new(1, 1, 1) else Color3.fromRGB(12, 12, 20),
		ZIndex = z,
		Parent = parent,
	})
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Creatures")
	local template = folder and folder:FindFirstChild(("R%d_T%d"):format(r, rarity)) :: Model?
	if template then
		local m = template:Clone()
		m:PivotTo(CFrame.new())
		m.Parent = vp
		local _, s = m:GetBoundingBox()
		local cam = new("Camera", { FieldOfView = 30, Parent = vp })
		local dist = math.max(s.X, s.Y, s.Z) * 2.1
		local mid = Vector3.new(0, s.Y * 0.45, 0)
		cam.CFrame = CFrame.lookAt(mid + Vector3.new(0, s.Y * 0.22, -dist), mid)
		vp.CurrentCamera = cam
		if known then
			table.insert(turning, { model = m, vp = vp, phase = math.random() * 6, where = where })
		end
	end
	return vp
end

-- MISE EN PAGE --------------------------------------------------------------------------------

-- Colonne des anneaux (centre) : un bloc par anneau, l'un sous l'autre, à des places fixes
local scroll = new("ScrollingFrame", {
	Name = "Rings",
	Position = UDim2.fromOffset(SCROLL_X, 0),
	Size = UDim2.fromOffset(SCROLL_W, ROOT_H),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Selectable = false, -- la manette va sur les cartes, pas sur la colonne elle-même
	CanvasSize = UDim2.fromOffset(0, EDGE * 2 + #Config.Rings * BLOCK_H + (#Config.Rings - 1) * BLOCK_GAP),
	Parent = root,
})
type Card = { button: TextButton, stroke: UIStroke }
-- sig : ce que le bloc affiche (espèces vues, récompense prise) ; il n'est refait que si ça change
type Block = { frame: Frame, content: Frame?, sig: string, cards: { [number]: Card } }
local blocks: { Block } = {}
for r in ipairs(Config.Rings) do
	local f = UIKit.card({ parent = scroll, color = "Dark", name = "Ring" .. r })
	f.Position = UDim2.fromOffset(EDGE, EDGE + (r - 1) * (BLOCK_H + BLOCK_GAP))
	f.Size = UDim2.fromOffset(BLOCK_W, BLOCK_H)
	blocks[r] = { frame = f, content = nil, sig = "", cards = {} }
end
-- Page des reliques (centre, à la place de la colonne des anneaux)
local middle = new("Frame", { Name = "RelicPage", Position = UDim2.fromOffset(SCROLL_X + (SCROLL_W - 476) / 2, 0), Size = UDim2.fromOffset(476, ROOT_H), BackgroundTransparency = 1, Visible = false, Parent = root })
local ringTitle = UIKit.text({ Size = UDim2.fromOffset(476, 44), Text = "", Stroke = 4, Parent = middle })
local barBack = new("Frame", { Position = UDim2.fromOffset(78, 48), Size = UDim2.fromOffset(320, 26), BackgroundColor3 = Color3.fromRGB(20, 26, 44), Parent = middle }, { UIKit.corner(), UIKit.stroke(3) })
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = barBack }, { UIKit.corner() })
local barGrad = UIKit.gradient(Color3.fromRGB(255, 235, 120), Color3.fromRGB(245, 160, 20))
barGrad.Parent = barFill
local barText = UIKit.text({ Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 2), Text = "", ZIndex = 3, Stroke = 2.5, Parent = barBack })
-- Cartes des reliques : 4 par rangée, la dernière rangée centrée ; la grille défile (14 reliques)
local relicCards = new("ScrollingFrame", {
	Name = "Relics",
	Position = UDim2.fromOffset(0, 86),
	Size = UDim2.fromOffset(500, 460),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = Color3.fromRGB(200, 205, 220),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Selectable = false,
	Parent = middle,
})
-- Détail (droite). Son contenu est vidé à chaque changement, sans toucher aux picots de la carte.
local detailCard = UIKit.card({ parent = root, color = "Dark", name = "Detail" })
detailCard.Position = UDim2.fromOffset(DETAIL_X, 0)
detailCard.Size = UDim2.fromOffset(DETAIL_W, ROOT_H)
local detail = new("Frame", { Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = detailCard })

local refresh: () -> ()

local function call(action: string, arg: any?)
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Creatures"):InvokeServer(action, arg)
	end)
	if ok and type(res) == "table" and res.extra then
		table.clear(seen)
		for _, k in ipairs(res.extra.seen or {}) do
			seen[k] = true
		end
		table.clear(claimed)
		for _, r in ipairs(res.extra.claimed or {}) do
			claimed[r] = true
		end
	end
	return ok and res
end

local function ringCount(r: number): (number, number)
	local n, total = 0, #Config.Creatures[r]
	for slot = 1, total do
		if seen[key(r, slot)] then
			n += 1
		end
	end
	return n, total
end

local function fetchRelics()
	local ok, res = pcall(function()
		return Remotes:WaitForChild("Relics"):InvokeServer("state")
	end)
	if ok and type(res) == "table" and res.ok then
		relicState.found = res.found or {}
	end
end

-- DÉFILEMENT ----------------------------------------------------------------------------------

-- Position du défilement qui amène le bloc d'un anneau en haut de la colonne
-- (calculée avec les positions à l'écran, comme les sections de la boutique)
local function blockTarget(r: number): Vector2
	local height = scroll.AbsoluteSize.Y
	if height <= 0 then
		return scroll.CanvasPosition -- pas encore mis en page
	end
	local y = blocks[r].frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y - EDGE * height / ROOT_H
	local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
	return Vector2.new(0, math.clamp(y, 0, maxY))
end

local holdRing: number? = nil
local holdUntil = 0

-- Saut direct à un bloc, tenu quelques instants : la fenêtre change d'échelle en s'ouvrant, et la
-- colonne vient peut-être d'être réaffichée
local function hold(r: number, seconds: number)
	holdRing = r
	holdUntil = os.clock() + seconds
end

-- Bouton des reliques, dans le bandeau de titre : « RELICS 3/14 », ou « CREATURES » pour revenir
local header = W.body.Parent:FindFirstChild("Header") :: Frame
local relicTab = new("TextButton", {
	Name = "Relics",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -64, 0.5, 0),
	Size = UDim2.fromOffset(250, 54),
	BackgroundColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = false,
	Text = "",
	ZIndex = 5,
	Parent = header,
}, { UIKit.corner(12), UIKit.gradient(UIKit.Colors.Gold[1], UIKit.Colors.Gold[2]) })
local relicTabStroke = UIKit.stroke(3.5)
relicTabStroke.Parent = relicTab
local relicTabText = UIKit.text({ Size = UDim2.new(1, -12, 1, -10), Position = UDim2.fromOffset(6, 5), Text = "{Star} RELICS", ZIndex = 6, Stroke = 3, Parent = relicTab })
UIKit.juice(relicTab)
relicTab.MouseButton1Click:Connect(function()
	relicMode = not relicMode
	if relicMode then
		fetchRelics()
		refresh()
	else
		-- retour aux créatures : la colonne réapparaît sur le bloc de l'anneau choisi
		refresh()
		hold(selRing, 0.15)
	end
end)

-- À chaque image, fenêtre ouverte : seuls les aperçus visibles tournent (ceux des blocs hors de la colonne restent figés)
local viewFrom: { number } = table.create(#Config.Rings, 1) -- partie visible de chaque bloc, en unités du bloc
local viewTo: { number } = table.create(#Config.Rings, 0)
RunService.RenderStepped:Connect(function()
	if not W.isOpen() then
		return
	end
	local now = os.clock()
	if holdRing then
		if now < holdUntil then
			scroll.CanvasPosition = blockTarget(holdRing)
		else
			holdRing = nil
		end
	end
	local top = scroll.AbsolutePosition.Y
	local height = scroll.AbsoluteSize.Y
	for r, b in ipairs(blocks) do
		local y, h = b.frame.AbsolutePosition.Y, b.frame.AbsoluteSize.Y
		if relicMode or h <= 0 or y >= top + height or y + h <= top then
			viewFrom[r], viewTo[r] = 1, 0 -- rien de visible
		else
			viewFrom[r], viewTo[r] = (top - y) / h * BLOCK_H, (top + height - y) / h * BLOCK_H
		end
	end
	for i = #turning, 1, -1 do
		local e = turning[i]
		local where = e.where
		if not e.vp.Parent then
			table.remove(turning, i)
		elseif not where or (where.bottom > viewFrom[where.block] and where.top < viewTo[where.block]) then
			e.model:PivotTo(CFrame.Angles(0, now * 0.8 + e.phase, 0))
		end
	end
end)

-- RELIQUES --------------------------------------------------------------------------------------

-- Relique en 3D, en silhouette noire tant qu'elle n'est pas trouvée
local function relicView(parent: GuiObject, relicKey: string, known: boolean, size: UDim2, pos: UDim2, z: number)
	local vp = new("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		Ambient = if known then Color3.fromRGB(165, 165, 180) else Color3.new(0, 0, 0),
		LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0),
		LightDirection = Vector3.new(-1, -1.5, -1.5),
		ImageColor3 = if known then Color3.new(1, 1, 1) else Color3.fromRGB(12, 12, 20),
		ZIndex = z,
		Parent = parent,
	})
	local m = RelicModel.Build(relicKey)
	m.Parent = vp
	local _, s = m:GetBoundingBox()
	local cam = new("Camera", { FieldOfView = 30, Parent = vp })
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.2, 1).Unit * (s.Magnitude / 2 / math.tan(math.rad(15)) * 1.04), Vector3.zero)
	vp.CurrentCamera = cam
	if known then
		table.insert(turning, { model = m, vp = vp, phase = math.random() * 6 })
	end
end

-- Bonus d'une relique (gagné pour toujours une fois trouvée) : icône et pourcentage court
local BONUS_OFF = Color3.fromRGB(150, 155, 172) -- texte d'un bonus pas encore gagné
local function relicBonusArt(r): string
	return if r.Bonus and r.Bonus.Kind == "XP" then "Jetpack" else "Cash"
end
local function relicBonusPercent(r): string
	return ("+%d%%"):format(math.floor(((r.Bonus and r.Bonus.Value) or 0) * 100 + 0.5))
end
-- Grise l'icône collée devant un texte (bonus pas encore gagné)
local function dimIcon(t: TextLabel)
	local img = t:FindFirstChild("InlineIcon")
	if img and img:IsA("ImageLabel") then
		img.ImageColor3 = Color3.fromRGB(110, 115, 130)
	end
end

local function relicDetail()
	clear(detail)
	local r = Config.Relics[relicPick]
	local known = relicState.found[r.Key] == true
	local ringName = Config.Rings[r.Ring].Name
	UIKit.rays(detail, { color = r.Color, size = 300, transparency = if known then 0.45 else 0.75, position = UDim2.fromOffset(DETAIL_CX, 124) })
	relicView(detail, r.Key, known, UDim2.fromOffset(220, 210), UDim2.fromOffset(DETAIL_CX, 124), 3)
	if not known then
		UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DETAIL_CX, 124), Size = UDim2.fromOffset(90, 90), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 4, Stroke = 5, Parent = detail })
	end
	local name = UIKit.text({ Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 236), Text = if known then r.Name else "???", ZIndex = 4, Stroke = 3.5, Parent = detail })
	if known then
		UIKit.shinyText(name, r.Color)
	end
	UIKit.text({ Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 272), Text = ringName:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.3), ZIndex = 4, Stroke = 3, Parent = detail })
	UIKit.text({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 300), Text = ("{Sparkles} Chance: 1 in %s"):format(Format.Short(r.Chance)), ZIndex = 4, Stroke = 2.5, Parent = detail })
	UIKit.text({ Size = UDim2.new(1, -24, 0, 90), Position = UDim2.fromOffset(12, 328), Text = if known then r.Story else ("Lost somewhere in the %s... Keep drilling."):format(ringName), TextColor3 = Color3.fromRGB(225, 230, 250), ZIndex = 4, Stroke = 2.5, Parent = detail })
	-- Bonus de la relique : doré et vert quand elle est trouvée, grisé sinon
	local top = if known then UIKit.Colors.Gold[1]:Lerp(Color3.new(0, 0, 0), 0.55) else Color3.fromRGB(58, 60, 74)
	local bottom = if known then UIKit.Colors.Gold[2]:Lerp(Color3.new(0, 0, 0), 0.65) else Color3.fromRGB(38, 40, 52)
	local box = new("Frame", { Name = "Bonus", Position = UDim2.new(0, 10, 1, -118), Size = UDim2.new(1, -20, 0, 108), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, Parent = detail }, {
		UIKit.corner(12),
		UIKit.stroke(3),
		UIKit.gradient(top, bottom),
	})
	local boxTitle = UIKit.text({ Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 6), Text = "{Star} RELIC BONUS", TextColor3 = if known then Color3.fromRGB(255, 230, 110) else BONUS_OFF, ZIndex = 5, Stroke = 3, Parent = box })
	local bonus = UIKit.text({ Size = UDim2.new(1, -12, 0, 36), Position = UDim2.fromOffset(6, 34), Text = ("{%s} %s"):format(relicBonusArt(r), string.upper(Config.RelicBonusText(r))), TextColor3 = if known then UIKit.Money else BONUS_OFF, ZIndex = 5, Stroke = 3, Parent = box })
	local status = UIKit.text({ Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 76), Text = if known then "ACTIVE FOREVER!" else "{Lock} Find it to activate", TextColor3 = if known then Color3.fromRGB(190, 255, 150) else BONUS_OFF, ZIndex = 5, Stroke = 2.5, Parent = box })
	if known then
		UIKit.shinyText(bonus, UIKit.Money)
	else
		dimIcon(boxTitle)
		dimIcon(bonus)
		dimIcon(status)
	end
end

local function relicPage()
	clear(relicCards)
	local total = #Config.Relics
	local found = 0
	for _, r in ipairs(Config.Relics) do
		if relicState.found[r.Key] then
			found += 1
		end
	end
	ringTitle.Text = ("Lost Explorers' Relics   ·   %d/%d"):format(found, total)
	barFill.Size = UDim2.fromScale(math.max(found / total, 0.02), 1)
	barText.Text = ("%d/%d found"):format(found, total)
	local CW, CH, GX, GY, PER = 112, 216, 9, 12, 4
	local rows = math.ceil(total / PER)
	relicCards.CanvasSize = UDim2.fromOffset(0, 6 + rows * CH + (rows - 1) * GY + 6)
	for i, r in ipairs(Config.Relics) do
		local known = relicState.found[r.Key] == true
		local row, col = (i - 1) // PER, (i - 1) % PER
		local inRow = math.min(PER, total - row * PER)
		local x = 6 + (PER - inRow) * (CW + GX) / 2 + col * (CW + GX)
		local c = new("TextButton", {
			Name = r.Key,
			Position = UDim2.fromOffset(x, 6 + row * (CH + GY)),
			Size = UDim2.fromOffset(CW, CH),
			BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			Text = "",
			Parent = relicCards,
		}, {
			UIKit.corner(14),
			UIKit.gradient(r.Color:Lerp(Color3.new(1, 1, 1), if known then 0.3 else 0.05), r.Color:Lerp(Color3.new(0, 0, 0), if known then 0.3 else 0.65)),
		})
		UIKit.stroke(if i == relicPick then 6 else 4, if i == relicPick then Color3.fromRGB(255, 235, 120) else nil).Parent = c
		UIKit.studs(c, 0.6)
		relicView(c, r.Key, known, UDim2.fromOffset(104, 112), UDim2.new(0.5, 0, 0, 66), 3)
		if not known then
			UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.fromOffset(50, 50), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 4, Stroke = 4, Parent = c })
		end
		UIKit.text({ Size = UDim2.new(1, -8, 0, 42), Position = UDim2.fromOffset(4, 124), Text = if known then r.Name else "???", ZIndex = 4, Stroke = 2.5, Parent = c })
		-- son bonus : vert quand elle est trouvée, grisé sinon
		local bonus = UIKit.text({ Size = UDim2.new(1, -8, 0, 26), Position = UDim2.fromOffset(4, 176), Text = ("{%s} %s"):format(relicBonusArt(r), relicBonusPercent(r)), TextColor3 = if known then UIKit.Money else BONUS_OFF, ZIndex = 4, Stroke = 2.5, Parent = c })
		if not known then
			dimIcon(bonus)
		end
		UIKit.hoverCard(c)
		c.MouseButton1Click:Connect(function()
			relicPick = i
			refresh()
		end)
	end
	relicDetail()
end

-- DÉTAIL DE LA CRÉATURE CHOISIE -----------------------------------------------------------------

local function percent(p: number): string
	local n = math.floor(p * 100 + 0.5)
	return if p > 0 and n < 1 then "<1%" else n .. "%"
end

local function buildDetail()
	clear(detail)
	local r, slot = selRing, selSlot
	local rarity = Config.CreatureRarity(r, slot)
	local rar = Config.Rarities[rarity]
	local species = Config.Creatures[r][slot]
	local known = seen[key(r, slot)] == true
	-- rayons rognés par le panneau (le calque est décalé de 4 px)
	UIKit.rays(UIKit.fxLayer(detail), { color = rar.Color, size = 330, transparency = 0.55, position = UDim2.fromOffset(DETAIL_CX - 4, 128) })
	portrait(detail, r, rarity, known, UDim2.fromOffset(244, 236), UDim2.fromOffset(DETAIL_CX, 132), 3)
	if not known then
		UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DETAIL_CX, 132), Size = UDim2.fromOffset(100, 100), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 4, Stroke = 5, Parent = detail })
	end
	local name = UIKit.text({ Size = UDim2.new(1, -16, 0, 38), Position = UDim2.fromOffset(8, 258), Text = if known then species.Name else "???", ZIndex = 4, Stroke = 3.5, Parent = detail })
	if known and rarity >= 5 then
		UIKit.shinyText(name, rar.Color)
	end
	UIKit.text({ Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 300), Text = rar.Name:upper(), TextColor3 = rar.Color:Lerp(WHITE, 0.3), ZIndex = 4, Stroke = 3, Parent = detail })
	UIKit.text({
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 334),
		Text = if known then "{Cash} " .. money(Config.CreatureIncome(r, rarity, 1)) .. "/s in your base" else "{Hatch} Hatch it to reveal it!",
		TextColor3 = if known then UIKit.Money else Color3.fromRGB(220, 225, 240),
		ZIndex = 4,
		Stroke = 2.5,
		Parent = detail,
	})
	-- Où elle vit : l'anneau, sur l'image de son monde (pas le type d'astéroïde : le joueur n'a pas à le savoir)
	local ringCfg = Config.Rings[r]
	local color = ringCfg.Color
	local box = new("Frame", { Name = "Where", Position = UDim2.fromOffset(10, 376), Size = UDim2.fromOffset(DETAIL_W - 20, 162), BackgroundColor3 = WHITE, ClipsDescendants = true, ZIndex = 4, Parent = detail }, {
		UIKit.corner(12),
		UIKit.stroke(3),
		UIKit.gradient(color:Lerp(WHITE, 0.35), color:Lerp(BLACK, 0.5)),
	})
	local art = Config.WorldArt[r]
	if art then
		new("ImageLabel", { Name = "Art", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Crop, ZIndex = 5, Parent = box }, { UIKit.corner(12) })
		new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 6, Parent = box }, { UIKit.corner(12) })
	else
		UIKit.studs(box, 0.6)
	end
	UIKit.text({ Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 14), Text = "{Sparkles} LIVES IN", TextColor3 = GOLD, ZIndex = 7, Stroke = 3, Parent = box })
	UIKit.text({ Size = UDim2.new(1, -16, 0, 44), Position = UDim2.fromOffset(8, 48), Text = ringCfg.Name:upper(), ZIndex = 7, Stroke = 4, Parent = box })
	UIKit.text({ Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 104), Text = ("RING %d"):format(r), TextColor3 = color:Lerp(WHITE, 0.6), ZIndex = 7, Stroke = 3, Parent = box })
end

-- CRÉATURE CHOISIE ------------------------------------------------------------------------------
-- Choisir une créature ne refait aucun bloc : seuls le contour de sa carte et le détail changent.
-- La carte choisie porte « PadFirst » : c'est elle que la manette sélectionne à l'ouverture (UIKit).

local pickMark: Frame? = nil
local function showPick()
	if pickMark then
		pickMark:Destroy()
		pickMark = nil
	end
	for r, b in ipairs(blocks) do
		for slot, card in pairs(b.cards) do
			local on = r == selRing and slot == selSlot
			card.stroke.Color = if on then PICK else UIKit.Outline
			card.button:SetAttribute("PadFirst", if on then true else nil)
			if on then
				-- liseré doré qui pulse à l'intérieur de la carte
				local mark = new("Frame", { Name = "Pick", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 6, Parent = card.button })
				local glint = new("UIStroke", { Thickness = 3, Color = PICK, LineJoinMode = Enum.LineJoinMode.Miter, Parent = mark })
				UIKit.every(mark, function(t)
					glint.Transparency = 0.35 + 0.3 * math.sin(t * 5)
				end)
				pickMark = mark
			end
		end
	end
end

local function setPick(r: number, slot: number)
	if r == selRing and slot == selSlot then
		return
	end
	selRing, selSlot = r, slot
	showPick()
	buildDetail()
end

-- BLOC D'UN ANNEAU ------------------------------------------------------------------------------

-- Ce qu'un bloc affiche : récompense prise ou non, puis vue ou non pour chaque espèce
local function signature(r: number): string
	local s = if claimed[r] then "C" else "-"
	for slot = 1, #Config.Creatures[r] do
		s ..= if seen[key(r, slot)] then "1" else "0"
	end
	return s
end

local function buildBlock(r: number)
	local b = blocks[r]
	-- manette : si elle était sur ce bloc, on lui rendra une carte une fois le bloc refait
	local focus = GuiService.SelectedObject
	local hadFocus = focus ~= nil and b.content ~= nil and focus:IsDescendantOf(b.content)
	if b.content then
		b.content:Destroy()
	end
	table.clear(b.cards)
	b.sig = signature(r)
	local ringCfg = Config.Rings[r]
	local n, total = ringCount(r)
	local done = n >= total
	local isClaimed = claimed[r] == true
	local content = new("Frame", { Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = b.frame })
	b.content = content

	-- Monde : nom de l'anneau, son image (ou un fond à sa couleur), pourcentage trouvé
	local color = ringCfg.Color
	local world = new("Frame", { Name = "World", Position = UDim2.fromOffset(WORLD_X, WORLD_Y), Size = UDim2.fromOffset(WORLD_W, WORLD_H), BackgroundColor3 = WHITE, ZIndex = 2, Parent = content }, {
		UIKit.corner(14),
		UIKit.stroke(4),
		UIKit.gradient(color:Lerp(WHITE, 0.45), color:Lerp(BLACK, 0.4)),
	})
	local art = Config.WorldArt[r]
	if art then
		-- image du monde (Config.WorldArt) sur tout le panneau, assombrie en haut et en bas sous les textes
		new("ImageLabel", { Name = "Art", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Crop, ZIndex = 3, Parent = world })
		new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 4, Parent = world }, {
			new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(0.16, 1),
					NumberSequenceKeypoint.new(0.68, 1),
					NumberSequenceKeypoint.new(1, 0.25),
				}),
			}),
		})
	else
		UIKit.studs(world, 0.6)
		UIKit.rays(UIKit.fxLayer(world), { color = color:Lerp(WHITE, 0.65), size = 250, speed = 8, transparency = 0.5, position = UDim2.fromOffset(WORLD_W / 2 - 4, 140) })
	end
	UIKit.text({ Name = "Title", Size = UDim2.new(1, -12, 0, 36), Position = UDim2.fromOffset(6, 8), Text = ringCfg.Name:upper(), ZIndex = 5, Stroke = 3, Parent = world })
	local found = UIKit.text({ Name = "Percent", Size = UDim2.new(1, -12, 0, 50), Position = UDim2.fromOffset(6, 242), Text = percent(n / total), ZIndex = 5, Stroke = 4, Parent = world })
	if done then
		UIKit.shinyText(found, GOLD)
	end
	UIKit.text({ Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(6, 294), Text = "FOUND", TextColor3 = Color3.fromRGB(235, 240, 255), ZIndex = 5, Stroke = 2.5, Parent = world })

	-- Les créatures, de la moins rare à la plus rare, 3 par ligne : Common, Uncommon, Rare, puis les 3 suivantes
	for slot, species in ipairs(Config.Creatures[r]) do
		local rarity = Config.CreatureRarity(r, slot)
		local rar = Config.Rarities[rarity]
		local known = seen[key(r, slot)] == true
		local x = CARD_X + ((slot - 1) % PER_ROW) * (CARD_W + CARD_GAP)
		local y = ROW_Y + ((slot - 1) // PER_ROW) * (CARD_H + ROW_GAP)
		local card = new("TextButton", {
			Name = "Slot" .. slot,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(CARD_W, CARD_H),
			BackgroundColor3 = WHITE,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 3,
			Parent = content,
		}, {
			UIKit.corner(14),
			UIKit.gradient(rar.Color:Lerp(WHITE, if known then 0.35 else 0.1), rar.Color:Lerp(BLACK, if known then 0.25 else 0.6)),
		})
		local cardStroke = UIKit.stroke(4)
		cardStroke.Parent = card
		UIKit.studs(card, 0.6)
		portrait(card, r, rarity, known, UDim2.fromOffset(CARD_W - 10, 102), UDim2.new(0.5, 0, 0, 57), 5, { block = r, top = y, bottom = y + CARD_H })
		if not known then
			UIKit.text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 57), Size = UDim2.fromOffset(54, 54), Text = "?", TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 6, Stroke = 4, Parent = card })
		end
		UIKit.text({ Size = UDim2.new(1, -10, 0, 28), Position = UDim2.fromOffset(5, 108), Text = if known then species.Name else "???", ZIndex = 6, Stroke = 2.5, Parent = card })
		UIKit.text({ Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(5, 136), Text = rar.Name:upper(), TextColor3 = rar.Color:Lerp(WHITE, 0.45), ZIndex = 6, Stroke = 2.5, Parent = card })
		UIKit.hoverCard(card)
		card.MouseButton1Click:Connect(function()
			setPick(r, slot)
		end)
		-- manette : le détail suit la carte sélectionnée
		card.SelectionGained:Connect(function()
			setPick(r, slot)
		end)
		b.cards[slot] = { button = card, stroke = cardStroke }
	end

	-- Barre de progression « n/6 »
	local back = new("Frame", { Name = "Bar", Position = UDim2.fromOffset(BAR_X, FOOT_Y + 7), Size = UDim2.fromOffset(BAR_W, FOOT_H - 14), BackgroundColor3 = Color3.fromRGB(20, 26, 44), ZIndex = 2, Parent = content }, { UIKit.corner(), UIKit.stroke(3) })
	local fill = new("Frame", { Size = UDim2.fromScale(0.02, 1), BackgroundColor3 = WHITE, ZIndex = 2, Parent = back }, {
		UIKit.corner(),
		UIKit.gradient(Color3.fromRGB(255, 235, 120), Color3.fromRGB(245, 160, 20)),
	})
	UIKit.tween(fill, 0.5, { Size = UDim2.fromScale(math.max(n / total, 0.02), 1) })
	UIKit.text({ Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 2), Text = ("%d/%d"):format(n, total), ZIndex = 4, Stroke = 2.5, Parent = back })

	-- Récompense au bout de la barre : bouton CLAIM! quand l'anneau est complet, « CLAIMED » ensuite,
	-- sinon ce qu'elle rapporte (chance pour toujours et argent)
	if done and not isClaimed then
		local claim = UIKit.priceButton({ parent = content, text = "CLAIM!", color = "Green", size = UDim2.fromOffset(REWARD_W, FOOT_H), position = UDim2.fromOffset(REWARD_X, FOOT_Y) })
		claim.Name = "Claim"
		UIKit.buttonGlow(claim, Color3.fromRGB(150, 255, 120))
		UIKit.wiggle(claim, 2)
		local busy = false
		claim.MouseButton1Click:Connect(function()
			if busy then
				return
			end
			busy = true
			-- centre du bouton dans la fenêtre, pour l'explosion d'étincelles
			local at = claim.AbsolutePosition + claim.AbsoluteSize / 2 - W.frame.AbsolutePosition
			local frameSize = W.frame.AbsoluteSize
			local res = call("claim", r)
			if res and res.ok and frameSize.X > 0 and frameSize.Y > 0 then
				UIKit.burst(W.frame, UDim2.fromScale(at.X / frameSize.X, at.Y / frameSize.Y), GOLD)
			end
			busy = false
			refresh()
		end)
	else
		local gold = UIKit.Colors.Gold
		local box = new("Frame", { Name = "Reward", Position = UDim2.fromOffset(REWARD_X, FOOT_Y), Size = UDim2.fromOffset(REWARD_W, FOOT_H), BackgroundColor3 = WHITE, ZIndex = 3, Parent = content }, {
			UIKit.corner(10),
			UIKit.stroke(3),
			UIKit.gradient(if isClaimed then Color3.fromRGB(58, 60, 74) else gold[1]:Lerp(BLACK, 0.55), if isClaimed then Color3.fromRGB(38, 40, 52) else gold[2]:Lerp(BLACK, 0.65)),
		})
		if isClaimed then
			UIKit.text({ Size = UDim2.new(1, -30, 1, -14), Position = UDim2.fromOffset(22, 7), Text = "CLAIMED", TextColor3 = Color3.fromRGB(190, 255, 150), ZIndex = 5, Stroke = 3, Parent = box })
		else
			UIKit.text({ Size = UDim2.new(1, -28, 0, 19), Position = UDim2.fromOffset(22, 3), Text = ("{Sparkles} +%d%% luck forever"):format(math.floor(Config.IndexReward.Luck * 100 + 0.5)), ZIndex = 5, Stroke = 2.5, Parent = box })
			UIKit.text({ Size = UDim2.new(1, -28, 0, 19), Position = UDim2.fromOffset(22, 22), Text = "{Cash} +" .. money(Config.IndexReward.Money * Config.Hatch.RingIncome[r]), TextColor3 = UIKit.Money, ZIndex = 5, Stroke = 2.5, Parent = box })
		end
	end
	-- Le cadeau entre la barre et la récompense (grisé une fois pris)
	local gift = UIKit.icon("Rewards", { Name = "Gift", Position = UDim2.fromOffset(REWARD_X - 31, FOOT_Y - 1), Size = UDim2.fromOffset(46, 46), ZIndex = 6, Parent = content })
	if isClaimed then
		gift.ImageColor3 = Color3.fromRGB(110, 115, 130)
	else
		UIKit.float(gift, 2, 5, 2.4)
	end

	if selRing == r then
		showPick()
	end
	if hadFocus then
		local card = b.cards[if selRing == r then selSlot else 1]
		if card then
			GuiService.SelectedObject = card.button
		end
	end
end

-- Refait les blocs dont les données ont changé, celui de l'anneau « first » tout de suite puis les autres
-- du plus proche au plus loin, un par image (un bloc = 6 créatures à cloner)
local buildRun = 0
local function rebuild(first: number)
	buildRun += 1
	local run = buildRun
	local order = { first }
	for d = 1, #blocks do
		if blocks[first + d] then
			table.insert(order, first + d)
		end
		if blocks[first - d] then
			table.insert(order, first - d)
		end
	end
	task.spawn(function()
		for _, r in ipairs(order) do
			if buildRun ~= run then
				return -- un rafraîchissement plus récent a pris le relais
			end
			if blocks[r].sig ~= signature(r) then
				buildBlock(r)
				task.wait()
			end
		end
	end)
end

-- RAFRAÎCHIR ----------------------------------------------------------------------------------

refresh = function()
	local foundRelics = 0
	for _, relic in ipairs(Config.Relics) do
		if relicState.found[relic.Key] then
			foundRelics += 1
		end
	end
	UIKit.setIconText(relicTabText, if relicMode then "{Egg} CREATURES" else ("{Star} RELICS %d/%d"):format(foundRelics, #Config.Relics))
	relicTabStroke.Thickness = if relicMode then 6 else 3.5
	relicTabStroke.Color = if relicMode then PICK else UIKit.Outline
	scroll.Visible = not relicMode
	middle.Visible = relicMode
	if relicMode then
		relicPage()
		return
	end
	rebuild(selRing)
	showPick()
	buildDetail()
end

UIKit.Open.Event:Connect(function(what: string)
	if what == "Index" then
		selRing = math.clamp((player:GetAttribute("Ring") or 1) :: number, 1, #Config.Rings)
		selSlot = 1
		call("index")
		relicMode = false
		fetchRelics()
		refresh()
		-- la colonne s'ouvre sur le bloc de l'anneau du joueur (tenu pendant l'animation d'ouverture)
		hold(selRing, 0.4)
		W.open()
	elseif what == "Close" and W.isOpen() then
		W.close()
	end
end)
