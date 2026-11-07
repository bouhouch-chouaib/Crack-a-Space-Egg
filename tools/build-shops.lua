-- Outil de Studio (mode édition) : construit les boutiques du vaisseau et arrondit les coins du quai.
-- Installé comme ModuleScript ServerStorage.BuildShops, lancé avec require(...).Build().
-- Relançable : il remplace ce qu'il a construit.
-- 1. Coins du quai : de chaque côté du quai, le pont faisait un angle droit vide. On le comble avec un
--    quart de disque (rayon CORNER_R) qui va du bord avant du pont jusqu'au bout du quai, avec une
--    rambarde arrondie, pour gagner de la place dans les deux coins.
-- 2. Coin gauche : trois stands en arc de cercle, tournés vers le coin : STORE (Robux, vert),
--    ITEMS (foreuses, skins, scanner, bleu) et SELL (vente, doré). L'arc déborde sur l'avant du pont
--    pour laisser de la place entre les stands. Chacun a son comptoir, son
--    auvent rayé, son enseigne, une icône holographique qui flotte et un vendeur astronaute.
-- 3. Coin droit : les trois tableaux de classement, en arc aussi, tournés vers le coin.
-- Les invites (StorePoint, ShopPoint, SellPoint) sont posées devant chaque comptoir ; WorldBuilder et
-- GameService les branchent au lancement du jeu.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Build = {}

local ship = workspace.Ship
local deck = ship.Deck
local CORNER_R = 44 -- rayon du coin arrondi (du coin du quai au bord du pont)
local DOCK_X = 60 -- demi-largeur du quai
local FRONT_Z = 24 -- bord avant du pont
local DOCK_END = 64 -- bout du quai
local FLOOR_Y = -2 -- centre du plancher (4 d'épaisseur, dessus à y = 0)
local WHITE = Color3.fromRGB(245, 246, 250)
local NAVY = Color3.fromRGB(34, 40, 72)
local INK = Color3.fromRGB(22, 22, 32)

local SHOPS = {
	{ key = "Store", point = "StorePoint", title = "STORE", sub = "Robux shop", icon = "rbxassetid://102404040034757", c1 = Color3.fromRGB(176, 245, 70), c2 = Color3.fromRGB(70, 196, 40), angle = 18 },
	{ key = "Items", point = "ShopPoint", title = "ITEMS", sub = "Drills · Skins · Scanner", icon = "rbxassetid://86154871998620", c1 = Color3.fromRGB(110, 205, 255), c2 = Color3.fromRGB(30, 120, 235), angle = 60 },
	{ key = "Sell", point = "SellPoint", title = "SELL", sub = "Trading post", icon = "rbxassetid://119781577077916", c1 = Color3.fromRGB(255, 232, 110), c2 = Color3.fromRGB(240, 170, 20), angle = 102 },
}

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

-- Ce qu'on retire du vaisseau est gardé dans ServerStorage.OldShipParts (on peut le remettre)
local function backup(): Instance
	local f = game.ServerStorage:FindFirstChild("OldShipParts")
	if not f then
		f = Instance.new("Folder")
		f.Name = "OldShipParts"
		f.Parent = game.ServerStorage
	end
	return f
end

-- COINS DU QUAI -------------------------------------------------------------------------------

local function corner(side: number, folder: Instance)
	local center = Vector3.new(side * DOCK_X, FLOOR_Y, FRONT_Z)
	local disc = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, CORNER_R * 2, CORNER_R * 2),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
	})
	local box = part({
		Size = Vector3.new(CORNER_R, 4, DOCK_END - FRONT_Z),
		CFrame = CFrame.new(side * (DOCK_X + CORNER_R / 2), FLOOR_Y, (FRONT_Z + DOCK_END) / 2),
	})
	disc.Parent, box.Parent = workspace, workspace
	local floor = disc:IntersectAsync({ box })
	disc:Destroy()
	box:Destroy()
	local front = deck.Floor_Front
	floor.Name = if side < 0 then "Floor_CornerL" else "Floor_CornerR"
	floor.Anchored = true
	floor.Color = front.Color
	floor.Material = front.Material
	floor.UsePartColor = true
	for _, t in ipairs(front:GetChildren()) do
		if t:IsA("Texture") then
			t:Clone().Parent = floor
		end
	end
	floor.Parent = folder
	-- rambarde : segments le long de l'arc, puis un bout droit au bout du quai
	local rim = deck.Rim:FindFirstChild("RimFrontR")
	local cap = deck.Rim:FindFirstChild("RimFrontRCap")
	local rimColor = if rim then rim.Color else WHITE
	local capColor = if cap then cap.Color else Color3.fromRGB(63, 201, 216)
	local capMat = if cap then cap.Material else Enum.Material.SmoothPlastic
	local r = CORNER_R - 0.8
	local phiMax = math.asin(math.clamp((DOCK_END - FRONT_Z - 0.8) / r, 0, 1))
	local n = 16
	for i = 0, n - 1 do
		local a0, a1 = phiMax * i / n, phiMax * (i + 1) / n
		local p0 = Vector3.new(center.X + side * r * math.cos(a0), 1, center.Z + r * math.sin(a0))
		local p1 = Vector3.new(center.X + side * r * math.cos(a1), 1, center.Z + r * math.sin(a1))
		local mid = (p0 + p1) / 2
		local len = (p1 - p0).Magnitude + 0.3
		local cf = CFrame.lookAt(mid, p1)
		part({ Name = "RimArc", Size = Vector3.new(1.6, 2, len), CFrame = cf, Color = rimColor, Parent = folder })
		part({ Name = "RimArcCap", Size = Vector3.new(0.5, 0.2, len), CFrame = cf + Vector3.new(0, 1.1, 0), Color = capColor, Material = capMat, Parent = folder })
	end
	local endX = center.X + side * r * math.cos(phiMax)
	local zEnd = DOCK_END - 0.8
	local mid = Vector3.new((side * DOCK_X + endX) / 2, 1, zEnd)
	local len = math.abs(endX - side * DOCK_X) + 0.8
	part({ Name = "RimEnd", Size = Vector3.new(len, 2, 1.6), CFrame = CFrame.new(mid), Color = rimColor, Parent = folder })
	part({ Name = "RimEndCap", Size = Vector3.new(len, 0.2, 0.5), CFrame = CFrame.new(mid + Vector3.new(0, 1.1, 0)), Color = capColor, Material = capMat, Parent = folder })
	-- l'ancienne rambarde avant de ce côté est remplacée
	for _, name in ipairs({ "RimFront", "RimFrontCap" }) do
		local old = deck.Rim:FindFirstChild((name:gsub("Front", "Front" .. (if side < 0 then "L" else "R"))))
		if old then
			old.Parent = backup()
		end
	end
end

-- VENDEUR -------------------------------------------------------------------------------------
-- Personnage R15 de base avec la tête jaune classique (forme arrondie, sourire d'origine), en
-- combinaison blanche : bulle de casque, col, sac à oxygène, plastron, ceinture, gants et bottes
-- de la couleur du stand.

local function weld(p: BasePart, to: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, p
	w.Parent = p
end

local function vendor(shop, at: CFrame): Model
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = Color3.fromRGB(245, 205, 48)
	d.TorsoColor, d.LeftArmColor, d.RightArmColor = WHITE, WHITE, WHITE
	d.LeftLegColor, d.RightLegColor = WHITE, WHITE
	local m = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	m.Name = "Vendor"
	local animate = m:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	m:PivotTo(at)
	m.Parent = workspace
	local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart
	hrp.Anchored = true
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	-- tête jaune classique par-dessus la tête du rig
	local head = m:FindFirstChild("Head") :: BasePart
	head.Transparency = 1
	for _, c in ipairs(head:GetChildren()) do
		if c:IsA("Decal") then
			c:Destroy()
		end
	end
	local classic = part({ Name = "ClassicHead", Size = Vector3.new(2, 1, 1), CFrame = head.CFrame, Color = Color3.fromRGB(245, 205, 48), Anchored = false, CanCollide = false, CanQuery = false, CanTouch = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = classic
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = classic
	classic.Parent = m
	weld(classic, head)
	local function add(name: string, props: { [string]: any }, to: BasePart): BasePart
		props.Name = name
		props.Anchored = false
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		props.Massless = true
		local p = part(props)
		p.Parent = m
		weld(p, to)
		return p
	end
	local torso = m:FindFirstChild("UpperTorso") :: BasePart
	local lower = m:FindFirstChild("LowerTorso") :: BasePart
	local tc = torso.CFrame
	-- bulle de casque (on voit la tête jaune au travers) et col
	add("Helmet", { Shape = Enum.PartType.Ball, Size = Vector3.one * 2.3, CFrame = head.CFrame, Color = Color3.fromRGB(220, 240, 255), Transparency = 0.72, CastShadow = false }, head)
	add("Collar", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2.1, 2.1), CFrame = head.CFrame * CFrame.new(0, -0.75, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = shop.c2 }, torso)
	-- plastron, boutons, ceinture
	add("ChestPanel", { Size = Vector3.new(1.1, 0.7, 0.2), CFrame = tc * CFrame.new(0, 0.15, -0.55), Color = shop.c1 }, torso)
	for i, col in ipairs({ Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 255, 120) }) do
		add("Button", { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.22, CFrame = tc * CFrame.new(-0.3 + (i - 1) * 0.3, 0.15, -0.67), Color = col }, torso)
	end
	add("Belt", { Size = Vector3.new(2.05, 0.3, 1.1), CFrame = lower.CFrame, Color = NAVY }, lower)
	add("Buckle", { Size = Vector3.new(0.45, 0.32, 0.15), CFrame = lower.CFrame * CFrame.new(0, 0, -0.57), Color = shop.c2 }, lower)
	-- sac à oxygène : boîte et deux bouteilles
	add("Pack", { Size = Vector3.new(1.6, 1.5, 0.7), CFrame = tc * CFrame.new(0, 0.05, 0.85), Color = WHITE }, torso)
	add("PackStripe", { Size = Vector3.new(1.62, 0.3, 0.72), CFrame = tc * CFrame.new(0, 0.35, 0.85), Color = shop.c2 }, torso)
	for _, x in ipairs({ -0.45, 0.45 }) do
		add("Tank", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.55, 0.55), CFrame = tc * CFrame.new(x, 0.1, 1.35) * CFrame.Angles(0, 0, math.pi / 2), Color = shop.c1 }, torso)
	end
	-- gants et bottes de la couleur du stand
	for _, n in ipairs({ "LeftHand", "RightHand", "LeftFoot", "RightFoot" }) do
		local p = m:FindFirstChild(n) :: BasePart?
		if p then
			p.Color = shop.c2
		end
	end
	for _, n in ipairs({ "LeftLowerArm", "RightLowerArm" }) do
		local p = m:FindFirstChild(n) :: BasePart?
		if p then
			add("Cuff", { Size = Vector3.new(p.Size.X + 0.12, 0.3, p.Size.Z + 0.12), CFrame = p.CFrame * CFrame.new(0, -p.Size.Y / 2 + 0.2, 0), Color = shop.c2 }, p)
		end
	end
	for _, n in ipairs({ "LeftLowerLeg", "RightLowerLeg" }) do
		local p = m:FindFirstChild(n) :: BasePart?
		if p then
			add("Boot", { Size = Vector3.new(p.Size.X + 0.14, 0.7, p.Size.Z + 0.14), CFrame = p.CFrame * CFrame.new(0, -p.Size.Y / 2 + 0.35, 0), Color = shop.c2 }, p)
		end
	end
	CollectionService:AddTag(m, "ShopVendor")
	return m
end

-- STANDS --------------------------------------------------------------------------------------

local function sign(p: BasePart, shop)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = p
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = shop.icon
	icon.Size = UDim2.fromScale(0.2, 0.9)
	icon.Position = UDim2.fromScale(0.02, 0.05)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = gui
	local function text(t: string, y: number, h: number, color: Color3, stroke: number)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(0.74, h)
		l.Position = UDim2.fromScale(0.24, y)
		l.Text = t
		l.TextScaled = true
		l.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		local s = Instance.new("UIStroke")
		s.Thickness = stroke
		s.Color = INK
		s.Parent = l
		l.Parent = gui
	end
	text(shop.title, 0.04, 0.6, Color3.new(1, 1, 1), 6)
	text(shop.sub, 0.64, 0.3, Color3.fromRGB(255, 250, 225), 3)
end

local function stand(shop, folder: Instance, center: Vector3, radius: number)
	local a = math.rad(shop.angle)
	local pos = Vector3.new(center.X - math.sin(a) * radius, 0, center.Z + math.cos(a) * radius)
	local base = CFrame.lookAt(pos, Vector3.new(center.X, 0, center.Z)) -- avant du stand = -Z local, vers le coin
	local m = Instance.new("Model")
	m.Name = shop.key .. "Stand"
	m:SetAttribute("Shop", shop.key)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local function p(name: string, props: { [string]: any })
		props.Name = name
		props.Parent = m
		return part(props)
	end
	-- socle et tapis devant le comptoir
	p("Platform", { Size = Vector3.new(17, 0.6, 12), CFrame = at(0, 0.3, 0.5), Color = NAVY })
	p("PlatformTrim", { Size = Vector3.new(17.1, 0.25, 0.5), CFrame = at(0, 0.62, -5.3), Color = shop.c2 })
	p("Mat", { Size = Vector3.new(11, 0.12, 6), CFrame = at(0, 0.06, -9), Color = shop.c1, Transparency = 0.15 })
	-- mur du fond rayé
	p("BackWall", { Size = Vector3.new(15, 10.5, 1), CFrame = at(0, 5.85, 5.2), Color = WHITE })
	p("WallStripe", { Size = Vector3.new(15.05, 1.4, 1.05), CFrame = at(0, 8.4, 5.2), Color = shop.c1 })
	p("WallStripe2", { Size = Vector3.new(15.05, 0.5, 1.05), CFrame = at(0, 7.3, 5.2), Color = shop.c2 })
	-- étagères avec des « produits » (petits cubes de couleur)
	for i, y in ipairs({ 3.2, 5.4 }) do
		p("Shelf" .. i, { Size = Vector3.new(12, 0.3, 1.4), CFrame = at(0, y, 4.1), Color = NAVY })
		for k = -2, 2 do
			p("Goods", { Size = Vector3.new(1.1, 1.1, 1.1), CFrame = at(k * 2.4, y + 0.7, 4.1) * CFrame.Angles(0, math.rad(15 * k), 0), Color = if (k + i) % 2 == 0 then shop.c1 else shop.c2 })
		end
	end
	-- piliers et boules
	for _, x in ipairs({ -7.6, 7.6 }) do
		for _, z in ipairs({ -4.4, 4.6 }) do
			p("Pillar", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(13, 1.6, 1.6), CFrame = at(x, 7.1, z) * CFrame.Angles(0, 0, math.pi / 2), Color = WHITE })
			p("PillarRing", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.9, 1.9), CFrame = at(x, 1.2, z) * CFrame.Angles(0, 0, math.pi / 2), Color = shop.c2 })
		end
	end
	-- comptoir
	p("Counter", { Size = Vector3.new(13, 3.4, 2.8), CFrame = at(0, 2.3, -2.6), Color = WHITE })
	p("CounterStripe", { Size = Vector3.new(13.1, 0.8, 2.9), CFrame = at(0, 2.5, -2.6), Color = shop.c1 })
	p("CounterTop", { Size = Vector3.new(14, 0.5, 3.6), CFrame = at(0, 4.25, -2.6), Color = shop.c2 })
	-- auvent rayé en pente, festons
	local n = 8
	local w = 17 / n
	local slope = math.atan2(2.2, 11)
	for i = 0, n - 1 do
		local x = -8.5 + w * (i + 0.5)
		p("Awning", { Size = Vector3.new(w, 0.5, 11.2), CFrame = at(x, 14.1, -0.1) * CFrame.Angles(-slope, 0, 0), Color = if i % 2 == 0 then shop.c1 else WHITE })
		p("Scallop", { Shape = Enum.PartType.Ball, Size = Vector3.one * w * 0.7, CFrame = at(x, 12.9, -5.5), Color = if i % 2 == 0 then shop.c1 else WHITE })
	end
	-- enseigne au-dessus de l'auvent, cadre, antennes
	p("SignFrame", { Size = Vector3.new(16, 4.6, 0.7), CFrame = at(0, 17.6, 4.9), Color = NAVY })
	local board = p("SignBoard", { Size = Vector3.new(15, 3.8, 0.8), CFrame = at(0, 17.6, 4.7), Color = shop.c2 })
	sign(board, shop)
	for _, x in ipairs({ -7.2, 7.2 }) do
		p("Antenna", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 0.3, 0.3), CFrame = at(x, 21.4, 4.9) * CFrame.Angles(0, 0, math.pi / 2), Color = WHITE })
		p("AntennaBall", { Shape = Enum.PartType.Ball, Size = Vector3.one * 1, CFrame = at(x, 23, 4.9), Color = shop.c1 })
	end
	-- lumière sous l'auvent
	local glow = p("Glow", { Size = Vector3.new(1, 1, 1), CFrame = at(0, 11.5, -1), Transparency = 1, CanCollide = false, CanQuery = false })
	local light = Instance.new("PointLight")
	light.Color = shop.c1
	light.Range = 16
	light.Brightness = 1.4
	light.Parent = glow
	-- icône holographique qui flotte au-dessus (animée par ShipShops.client)
	local holo = p("Holo", { Size = Vector3.new(1, 1, 1), CFrame = at(0, 27, 3), Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(7, 7)
	bb.LightInfluence = 0
	bb.MaxDistance = 400
	bb.Parent = holo
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = shop.icon
	img.Parent = bb
	-- invite devant le comptoir
	p(shop.point, { Size = Vector3.new(2, 1, 2), CFrame = at(0, 1.5, -7.5), Transparency = 1, CanCollide = false, CanQuery = false })
	m.PrimaryPart = m:FindFirstChild("Platform") :: BasePart
	m.Parent = folder
	-- vendeur derrière le comptoir, sur une estrade, tourné vers le client
	p("Step", { Size = Vector3.new(7, 1.6, 3.4), CFrame = at(0, 1.4, 0.6), Color = NAVY })
	local v = vendor(shop, at(0, 6, 0.6))
	v:ScaleTo(1.3)
	local _, size = v:GetBoundingBox()
	-- pieds posés sur l'estrade (dessus à y = 2.2)
	local feet = math.huge
	for _, d in ipairs(v:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "LeftFoot" or d.Name == "RightFoot") then
			feet = math.min(feet, d.Position.Y - d.Size.Y / 2)
		end
	end
	if feet < math.huge then
		v:PivotTo(v:GetPivot() + Vector3.new(0, at(0, 2.2, 0).Y - feet, 0))
	end
	local _ = size
	v.Parent = m
	return m
end

-- TABLEAUX DE CLASSEMENT ----------------------------------------------------------------------

local function boards(center: Vector3, radius: number)
	local lb = ship:FindFirstChild("Leaderboards")
	if not lb then
		return
	end
	local list = { lb:FindFirstChild("Richest"), lb:FindFirstChild("EggsCracked"), lb:FindFirstChild("BestFind") }
	for i, b in ipairs(list) do
		if b and b:IsA("Model") then
			local screen = b:FindFirstChild("Screen") :: BasePart?
			local look = if screen then screen.CFrame.LookVector else Vector3.new(0, 0, -1)
			local a = math.rad(({ 15, 50, 85 })[i])
			local pos = Vector3.new(center.X + math.sin(a) * radius, b:GetPivot().Y, center.Z + math.cos(a) * radius)
			local dir = (Vector3.new(center.X, pos.Y, center.Z) - pos).Unit
			-- rotation qui amène l'écran face au coin
			local turn = math.atan2(-dir.X, -dir.Z) - math.atan2(-look.X, -look.Z)
			local old = b:GetPivot()
			b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, turn, 0) * (old - old.Position))
		end
	end
end

function Build.Build(): string
	-- ce qu'on avait construit avant
	for _, name in ipairs({ "Corners", "Shops" }) do
		local old = ship:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	-- anciens stands et leurs chemins
	for _, name in ipairs({ "Shop", "Sell" }) do
		local old = ship:FindFirstChild(name)
		if old then
			old.Parent = backup()
		end
	end
	for _, path in ipairs(deck.Paths:GetChildren()) do
		if path:IsA("BasePart") and math.abs(path.Position.Z - 7.7) < 0.2 and (math.abs(path.Position.X + 60) < 1 or math.abs(path.Position.X + 36) < 1) then
			path:Destroy()
		end
	end
	local corners = Instance.new("Folder")
	corners.Name = "Corners"
	corners.Parent = ship
	corner(-1, corners)
	corner(1, corners)
	local shops = Instance.new("Folder")
	shops.Name = "Shops"
	shops.Parent = ship
	local left = Vector3.new(-DOCK_X, 0, FRONT_Z)
	for _, shop in ipairs(SHOPS) do
		stand(shop, shops, left, 31)
	end
	boards(Vector3.new(DOCK_X, 0, FRONT_Z), 32)
	return "ok"
end

return Build
