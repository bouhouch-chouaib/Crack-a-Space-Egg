-- Éclosion dans la base, côté joueur (serveur : HatchService).
-- - Barre des œufs prêts (en bas) : chaque œuf dérroché, en 3D qui tourne, avec son nom et sa rareté.
--   Un clic dessus lance la pose : un fantôme de l'œuf suit la souris sur le sol de sa base,
--   cercle vert = place libre, rouge = interdit. Clic = poser, Q ou clic droit = annuler.
-- - Au-dessus de chaque œuf qui incube : nom, barre de progression, temps restant, puis « READY! ».
-- - Éclosion : l'œuf tremble de plus en plus fort et blanchit, puis éclate en lumière ;
--   le propriétaire voit une grande bannière avec la créature née et ses $/s.
-- - Créatures posées : leur carte (image, nom, $/s) flotte au-dessus de leur socle,
--   en attendant les modèles 3D des créatures.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local EggModel = require(script.Parent:WaitForChild("EggModel"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local H = Config.Hatch
local new = UIKit.new

local GOOD = Color3.fromRGB(110, 255, 90)
local BAD = Color3.fromRGB(255, 70, 70)
local GOLD = Color3.fromRGB(255, 215, 60)

local function rarityOf(r: number)
	return Config.Rarities[r] or Config.Rarities[1]
end

local function timeText(s: number): string
	s = math.max(0, math.ceil(s))
	if s >= 3600 then
		return ("%dh %02dm"):format(s // 3600, (s % 3600) // 60)
	end
	return ("%d:%02d"):format(s // 60, s % 60)
end

local function artOf(ring: number, name: string): string?
	for _, c in ipairs(Config.Creatures[ring] or {}) do
		if c.Name == name and c.Art ~= "" then
			return c.Art
		end
	end
	return nil
end

-- BARRE DES ŒUFS PRÊTS ------------------------------------------------------------------

local gui = new("ScreenGui", { Name = "Hatchery", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
local root = new("Frame", {
	Name = "Bar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -64),
	Size = UDim2.fromOffset(700, 150),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})
UIKit.autoScale(root)
local title = UIKit.text({ Size = UDim2.new(1, 0, 0, 30), Text = "🥚 PLACE YOUR EGGS", TextColor3 = GOLD, Stroke = 3, Parent = root })
local slots = UIKit.text({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 28), Text = "", TextColor3 = Color3.fromRGB(200, 240, 255), Parent = root })
local row = new("Frame", { Size = UDim2.new(1, 0, 0, 100), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1, Parent = root }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10) }),
})

-- Bandeau de pose (« Click to place · Q to cancel »)
local banner = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 110),
	Size = UDim2.fromOffset(520, 56),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, { UIKit.corner(), UIKit.stroke(3), UIKit.gradient(UIKit.Colors.Gold[1], UIKit.Colors.Gold[2]) })
UIKit.autoScale(banner)
local bannerText = UIKit.text({ Size = UDim2.new(1, -90, 0.7, 0), Position = UDim2.new(0, 14, 0.15, 0), Text = "", Parent = banner })
local cancel = new("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(70, 40),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "",
	Parent = banner,
}, { UIKit.corner(), UIKit.stroke(3), UIKit.gradient(UIKit.Colors.Red[1], UIKit.Colors.Red[2]) })
UIKit.text({ Size = UDim2.fromScale(0.8, 0.7), Position = UDim2.fromScale(0.1, 0.15), Text = "✖", Parent = cancel })

-- Œuf 3D qui tourne dans une vignette
local spinners: { [ViewportFrame]: Model } = {}
local function eggViewport(parent: GuiObject, ring: number, rarity: number): ViewportFrame
	local vp = new("ViewportFrame", {
		Size = UDim2.fromScale(1, 0.72),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1.5, -1),
		Parent = parent,
	})
	local egg = EggModel.Make(ring, rarity, 2)
	egg:PivotTo(CFrame.new())
	egg.Parent = vp
	local cam = new("Camera", { FieldOfView = 30, Parent = vp })
	local _, size = egg:GetBoundingBox()
	local dist = math.max(size.X, size.Y, size.Z) * 2.1
	cam.CFrame = CFrame.lookAt(Vector3.new(0, size.Y * 0.1, -dist), Vector3.zero)
	vp.CurrentCamera = cam
	spinners[vp] = egg
	return vp
end

local placing: { ring: number, rarity: number }? = nil
local startPlacing: (number, number) -> ()

local function parseReady(): { { ring: number, rarity: number, count: number } }
	local list = {}
	local byKey = {}
	for pair in string.gmatch(player:GetAttribute("ReadyList") or "", "[^,]+") do
		local ring, rarity = pair:match("(%d+):(%d+)")
		local k = pair
		if ring and rarity then
			if byKey[k] then
				byKey[k].count += 1
			else
				byKey[k] = { ring = tonumber(ring) :: number, rarity = tonumber(rarity) :: number, count = 1 }
				table.insert(list, byKey[k])
			end
		end
	end
	table.sort(list, function(a, b)
		return if a.rarity ~= b.rarity then a.rarity > b.rarity else a.ring > b.ring
	end)
	return list
end

local function refreshBar()
	for vp in pairs(spinners) do
		spinners[vp] = nil
	end
	for _, c in ipairs(row:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local list = parseReady()
	local used, max = player:GetAttribute("BaseUsed") or 0, player:GetAttribute("BaseSlots") or H.Slots
	local income = player:GetAttribute("Income") or 0
	slots.Text = ("🏠 Base %d/%d   ·   💰 %s/s"):format(used, max, Format.Short(income))
	root.Visible = #list > 0 and not placing
	for i, e in ipairs(list) do
		if i > 6 then
			break
		end
		local r = rarityOf(e.rarity)
		local b = new("TextButton", {
			Name = "Egg" .. i,
			Size = UDim2.fromOffset(100, 100),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = row,
		}, { UIKit.corner(), UIKit.stroke(3), UIKit.gradient(r.Color:Lerp(Color3.new(1, 1, 1), 0.35), r.Color:Lerp(Color3.new(0, 0, 0), 0.35)) })
		if e.rarity >= 4 then
			UIKit.rays(b, { color = r.Color, size = 1.6, transparency = 0.45, z = 0 })
		end
		eggViewport(b, e.ring, e.rarity)
		UIKit.text({ Size = UDim2.new(1, -6, 0.2, 0), Position = UDim2.new(0, 3, 0.72, 0), Text = Config.EggName(e.ring, e.rarity):gsub(" Egg$", ""), Parent = b })
		if e.count > 1 then
			UIKit.text({ AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(40, 24), Position = UDim2.new(1, -3, 0, 2), Text = "x" .. e.count, TextColor3 = GOLD, Parent = b })
		end
		UIKit.juice(b)
		UIKit.popIn(b, i * 0.04)
		b.Activated:Connect(function()
			if used >= max then
				UIKit.toast("🏠 Your base is full!", "warn")
				return
			end
			startPlacing(e.ring, e.rarity)
		end)
	end
	if #list > 0 then
		UIKit.bump(title, 0.15)
	end
end

for _, a in ipairs({ "ReadyList", "BaseUsed", "Income" }) do
	player:GetAttributeChangedSignal(a):Connect(refreshBar)
end

-- POSE DE L'ŒUF -------------------------------------------------------------------------

local ghost: Model? = nil
local ring3d: Part? = nil
local placeX, placeZ, placeOk = 0, 0, false
local pointer: Vector2? = nil

local function myBase(): Model?
	local index = player:GetAttribute("Base")
	local bases = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Bases")
	if not bases or type(index) ~= "number" then
		return nil
	end
	for _, b in ipairs(bases:GetChildren()) do
		if b:GetAttribute("Index") == index then
			return b :: Model
		end
	end
	return nil
end

-- Même règle que le serveur (HatchService.CanPlace), pour la couleur du cercle
local function canPlace(base: Model, floor: BasePart, x: number, z: number): (boolean, string?)
	if math.abs(x) > floor.Size.X / 2 - H.Margin or math.abs(z) > floor.Size.Z / 2 - H.Margin then
		return false, "Too close to the wall"
	end
	for name, radius in pairs(H.KeepOut) do
		local thing = base:FindFirstChild(name)
		local pos = if thing and thing:IsA("Model") then thing:GetPivot().Position elseif thing and thing:IsA("BasePart") then thing.Position else nil
		if pos then
			local p = floor.CFrame:PointToObjectSpace(pos)
			if Vector2.new(p.X - x, p.Z - z).Magnitude < radius then
				return false, if name == "Spawn" then "Not on the spawn!" else "Too close to the machine"
			end
		end
	end
	local hatchery = base:FindFirstChild("Hatchery")
	for _, m in ipairs(hatchery and hatchery:GetChildren() or {}) do
		if m:IsA("Model") then
			local p = floor.CFrame:PointToObjectSpace(m:GetPivot().Position)
			if Vector2.new(p.X - x, p.Z - z).Magnitude < H.Gap then
				return false, "Too close to another egg"
			end
		end
	end
	return true, nil
end

local function stopPlacing()
	placing = nil
	player:SetAttribute("PlacingEgg", nil)
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if ring3d then
		ring3d:Destroy()
		ring3d = nil
	end
	banner.Visible = false
	refreshBar()
end

startPlacing = function(ring: number, rarity: number)
	stopPlacing()
	local base = myBase()
	if not base or not base:FindFirstChild("Floor") then
		UIKit.toast("Go back to your base first 🏠", "warn")
		return
	end
	placing = { ring = ring, rarity = rarity }
	player:SetAttribute("PlacingEgg", true)
	local g = EggModel.Make(ring, rarity, H.EggHeight[rarity] or 3)
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			d.Transparency = 0.35
		end
	end
	g.Parent = workspace
	ghost = g
	ring3d = new("Part", {
		Name = "PlaceRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, H.Gap, H.Gap),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = workspace,
	})
	bannerText.Text = (if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then "Tap your base floor to place" else "Click to place  ·  Q to cancel")
	banner.Visible = true
	UIKit.popIn(banner)
	root.Visible = false
	pointer = UserInputService:GetMouseLocation()
end

cancel.Activated:Connect(stopPlacing)

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include

RunService.RenderStepped:Connect(function()
	if not placing or not ghost or not ring3d then
		return
	end
	local base = myBase()
	local floor = base and base:FindFirstChild("Floor") :: BasePart?
	if not base or not floor then
		return
	end
	local screen = if UserInputService.MouseEnabled then UserInputService:GetMouseLocation() else pointer
	if not screen then
		return
	end
	floorParams.FilterDescendantsInstances = { floor }
	-- Souris : position dans la fenêtre ; doigt : position dans l'interface (sans la barre du haut)
	local ray = if UserInputService.MouseEnabled then camera:ViewportPointToRay(screen.X, screen.Y) else camera:ScreenPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, floorParams)
	if not hit then
		ghost:PivotTo(CFrame.new(0, -500, 0))
		ring3d.CFrame = CFrame.new(0, -500, 0)
		placeOk = false
		return
	end
	local p = floor.CFrame:PointToObjectSpace(hit.Position)
	placeX, placeZ = p.X, p.Z
	local ok, why = canPlace(base, floor, placeX, placeZ)
	placeOk = ok
	local h = H.EggHeight[placing.rarity] or 3
	local top = floor.CFrame * CFrame.new(placeX, floor.Size.Y / 2, placeZ)
	local t = os.clock()
	ghost:PivotTo(CFrame.new(top.Position + Vector3.new(0, h / 2 + 0.6 + math.sin(t * 4) * 0.15, 0)) * CFrame.Angles(0, t, 0))
	ring3d.CFrame = CFrame.new(top.Position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring3d.Color = if ok then GOOD else BAD
	bannerText.Text = if ok then (if UserInputService.MouseEnabled then "Click to place  ·  Q to cancel" else "Tap to place") else "❌ " .. (why or "Not here")
end)

local function tryPlace()
	if not placing then
		return
	end
	if not placeOk then
		UIKit.shake(banner)
		return
	end
	Remotes.PlaceEgg:FireServer(placing.ring, placing.rarity, placeX, placeZ)
	stopPlacing()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not placing then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q or input.UserInputType == Enum.UserInputType.MouseButton2 then
		stopPlacing()
		return
	end
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryPlace()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- Doigt : le fantôme va où l'on touche, on pose au relâchement
		pointer = Vector2.new(input.Position.X, input.Position.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input, processed)
	if placing and not processed and input.UserInputType == Enum.UserInputType.Touch then
		pointer = Vector2.new(input.Position.X, input.Position.Y)
		task.wait() -- laisse le fantôme se placer
		tryPlace()
	end
end)

-- ŒUFS QUI INCUBENT ---------------------------------------------------------------------

type Incub = { model: Model, gui: BillboardGui, fill: Frame, time: TextLabel, ready: boolean }
local incubating: { [Model]: Incub } = {}

local function trackIncubating(m: Instance)
	if not m:IsA("Model") or incubating[m] then
		return
	end
	local core = m:WaitForChild("Core", 10) :: BasePart?
	if not core or incubating[m] then
		return
	end
	local h = (m:GetAttribute("BodyHeight") or 3) :: number
	local name = (m:GetAttribute("EggName") or "Egg") :: string
	local rarity = (m:GetAttribute("Rarity") or 1) :: number
	local r = rarityOf(rarity)
	local b = new("BillboardGui", {
		Name = "HatchTimer",
		Size = UDim2.fromOffset(170, 66),
		StudsOffsetWorldSpace = Vector3.new(0, h * 0.9 + 1.4, 0),
		MaxDistance = 90,
		LightInfluence = 0,
		Adornee = core,
		Parent = gui,
	})
	UIKit.text({ Size = UDim2.new(1, 0, 0, 22), Text = name, TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.25), Parent = b })
	local bar = new("Frame", { Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 24), BackgroundColor3 = Color3.fromRGB(30, 32, 44), Parent = b }, { UIKit.corner(), UIKit.stroke(2) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar }, { UIKit.gradient(r.Color:Lerp(Color3.new(1, 1, 1), 0.4), r.Color) })
	local time = UIKit.text({ Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 44), Text = "", Parent = b })
	incubating[m] = { model = m, gui = b, fill = fill, time = time, ready = false }
end

local function untrackIncubating(m: Instance)
	local st = incubating[m :: Model]
	if st then
		st.gui:Destroy()
		incubating[m :: Model] = nil
	end
end

CollectionService:GetInstanceAddedSignal("Incubating"):Connect(trackIncubating)
CollectionService:GetInstanceRemovedSignal("Incubating"):Connect(untrackIncubating)
for _, m in ipairs(CollectionService:GetTagged("Incubating")) do
	task.spawn(trackIncubating, m)
end

-- Éclosion en cours : l'œuf n'est plus animé par Eggs.client, il tremble ici
type Shake = { model: Model, start: number, base: CFrame, light: Highlight }
local shaking: { [Model]: Shake } = {}

local function startShake(m: Model)
	if shaking[m] then
		return
	end
	CollectionService:RemoveTag(m, "Egg")
	local hl = new("Highlight", { FillColor = Color3.new(1, 1, 1), FillTransparency = 1, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded, Adornee = m, Parent = m })
	shaking[m] = { model = m, start = os.clock(), base = m:GetPivot(), light = hl }
end

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	local t = os.clock()
	for m, st in pairs(incubating) do
		if not m.Parent then
			untrackIncubating(m)
			continue
		end
		local at = (m:GetAttribute("HatchAt") or 0) :: number
		local total = (m:GetAttribute("HatchTime") or 1) :: number
		local left = at - now
		local f = math.clamp(1 - left / total, 0, 1)
		st.fill.Size = UDim2.fromScale(f, 1)
		if m:GetAttribute("Hatching") then
			st.time.Text = "🐣 HATCHING!"
			st.time.TextColor3 = GOLD
			startShake(m)
		elseif left <= 0 then
			if not st.ready then
				st.ready = true
				UIKit.bump(st.time, 0.3)
			end
			local own = m:GetAttribute("Owner") == player.UserId
			st.time.Text = if own then "READY! Press F 🐣" else "READY!"
			st.time.TextColor3 = GOLD:Lerp(Color3.new(1, 1, 1), 0.5 + 0.5 * math.sin(t * 6))
		else
			st.time.Text = "⏳ " .. timeText(left)
			st.time.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	for m, st in pairs(shaking) do
		if not m.Parent then
			shaking[m] = nil
			continue
		end
		local k = math.clamp((t - st.start) / H.Burst, 0, 1)
		local a = 0.04 + 0.3 * k * k
		m:PivotTo(st.base * CFrame.new(0, math.abs(math.sin(t * 30)) * 0.15 * k, 0) * CFrame.Angles(math.sin(t * 41) * a, 0, math.cos(t * 37) * a))
		st.light.FillTransparency = 1 - 0.85 * k
	end
end)

-- ÉCLATEMENT ET BANNIÈRE ------------------------------------------------------------------

local function burstAt(pos: Vector3, color: Color3, rarity: number)
	local at = new("Attachment", { WorldPosition = pos, Parent = workspace.Terrain })
	local function emit(props: { [string]: any }, count: number)
		local e = new("ParticleEmitter", { Enabled = false, LightInfluence = 0, Parent = at })
		for k, v in pairs(props) do
			(e :: any)[k] = v
		end
		e:Emit(count)
	end
	local kp = NumberSequenceKeypoint.new
	emit({ Texture = UIKit.Art.FxShell, Color = ColorSequence.new(Color3.new(1, 1, 1)), Size = NumberSequence.new({ kp(0, 0.9), kp(1, 0.4) }), Lifetime = NumberRange.new(0.7, 1.1),
		Speed = NumberRange.new(12, 22), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -40, 0), RotSpeed = NumberRange.new(-300, 300), Rotation = NumberRange.new(0, 360) }, 14 + rarity * 2)
	emit({ Texture = UIKit.Art.FxSparkle, Color = ColorSequence.new(Color3.new(1, 1, 1), color), LightEmission = 1, Size = NumberSequence.new({ kp(0, 0), kp(0.2, 1.6 + rarity * 0.25), kp(1, 0) }),
		Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(10, 26), SpreadAngle = Vector2.new(180, 180) }, 20 + rarity * 6)
	emit({ Texture = UIKit.Art.FxGlow, Color = ColorSequence.new(color), LightEmission = 1, Size = NumberSequence.new({ kp(0, 2), kp(1, 9 + rarity) }),
		Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) }), Lifetime = NumberRange.new(0.5, 0.5), Speed = NumberRange.new(0, 0) }, 2)
	local light = new("PointLight", { Color = color, Range = 18, Brightness = 6, Parent = at })
	UIKit.tween(light, 1, { Brightness = 0 })
	Debris:AddItem(at, 2)
end

local function hatchBanner(ring: number, rarity: number, name: string, income: number)
	local r = rarityOf(rarity)
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(460, 300),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = gui,
	})
	UIKit.autoScale(frame)
	UIKit.rays(frame, { color = r.Color, size = 2.1, transparency = 0.25, z = 30 })
	UIKit.glow(frame, { color = r.Color, size = 1.6, transparency = 0.3, z = 30 })
	if rarity >= 4 then
		UIKit.sparkles(frame, { count = 6 + rarity, color = r.Color, z = 33 })
	end
	local art = artOf(ring, name)
	local img = UIKit.icon(art or "Creatures", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(190, 190), ZIndex = 32, Parent = frame })
	UIKit.float(img, 6, 4, 2)
	UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, -6), Text = "🐣 YOU HATCHED", ZIndex = 33, Stroke = 3, Parent = frame })
	local nameLabel = UIKit.text({ Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 1, -86), Text = name:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.2), ZIndex = 33, Stroke = 4, Parent = frame })
	if rarity >= 5 then
		UIKit.shinyText(nameLabel, r.Color)
	end
	UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, -40), Text = r.Name:upper() .. "  ·  💰 " .. Format.Short(income) .. "/s", TextColor3 = UIKit.Money, ZIndex = 33, Stroke = 3, Parent = frame })
	UIKit.popIn(frame)
	task.delay(3.2, function()
		local s = frame:FindFirstChild("AnimScale") :: UIScale?
		if s then
			UIKit.tween(s, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end
		task.wait(0.3)
		frame:Destroy()
	end)
end

Remotes:WaitForChild("Hatched").OnClientEvent:Connect(function(owner: Player, pos: Vector3, ring: number, rarity: number, name: string, income: number)
	local r = rarityOf(rarity)
	if (pos - camera.CFrame.Position).Magnitude < 200 then
		burstAt(pos, r.Color, rarity)
	end
	if owner == player then
		hatchBanner(ring, rarity, name, income)
	end
end)

-- CRÉATURES POSÉES ------------------------------------------------------------------------

local creatures: { [Model]: BillboardGui } = {}

local function trackCreature(m: Instance)
	if not m:IsA("Model") or creatures[m] then
		return
	end
	local core = m:WaitForChild("Core", 10) :: BasePart?
	if not core or creatures[m] then
		return
	end
	local ring = (m:GetAttribute("Ring") or 1) :: number
	local rarity = (m:GetAttribute("Rarity") or 1) :: number
	local name = (m:GetAttribute("Creature") or "?") :: string
	local size = (m:GetAttribute("Size") or 1) :: number
	local income = (m:GetAttribute("Income") or 0) :: number
	local r = rarityOf(rarity)
	-- Taille de la carte : plus grande pour les créatures rares et les grands spécimens
	local s = (1.8 + rarity * 0.25) * size
	local b = new("BillboardGui", {
		Name = "CreatureCard",
		Size = UDim2.fromScale(s, s * 1.35),
		StudsOffsetWorldSpace = Vector3.new(0, s * 0.35, 0),
		MaxDistance = 120,
		LightInfluence = 0,
		Adornee = core,
		Parent = gui,
	})
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = b })
	if rarity >= 4 then
		UIKit.glow(holder, { color = r.Color, size = 1.3, transparency = 0.45, position = UDim2.fromScale(0.5, 0.38) })
	end
	local art = artOf(ring, name)
	local img = UIKit.icon(art or "Creatures", { Size = UDim2.fromScale(1, 0.74), Parent = holder })
	if not art then
		img.ImageColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	end
	UIKit.float(img, 4, 3, 1.6, math.random() * 6)
	UIKit.text({ Size = UDim2.fromScale(1, 0.13), Position = UDim2.fromScale(0, 0.74), Text = name, TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.2), Parent = holder })
	UIKit.text({ Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 0.87), Text = "💰 " .. Format.Short(income) .. "/s", TextColor3 = UIKit.Money, Parent = holder })
	creatures[m] = b
end

local function untrackCreature(m: Instance)
	local b = creatures[m :: Model]
	if b then
		b:Destroy()
		creatures[m :: Model] = nil
	end
end

CollectionService:GetInstanceAddedSignal("Creature"):Connect(trackCreature)
CollectionService:GetInstanceRemovedSignal("Creature"):Connect(untrackCreature)
for _, m in ipairs(CollectionService:GetTagged("Creature")) do
	task.spawn(trackCreature, m)
end

-- Vignettes 3D qui tournent
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for vp, egg in pairs(spinners) do
		if vp.Parent then
			egg:PivotTo(CFrame.Angles(0, t * 1.2, 0))
		else
			spinners[vp] = nil
		end
	end
end)

refreshBar()
