-- Éclosion dans la base, côté joueur (serveur : HatchService).
-- - L'œuf qui sort de la machine atterrit dans les mains du joueur (le serveur le soude au torse,
--   ici on lève les bras). Tant qu'il le tient, un fantôme de l'œuf suit la souris sur le sol de
--   sa base : cercle vert = place libre, rouge = interdit. Clic (ou doigt) = poser.
-- - Au-dessus de chaque œuf qui incube : nom, barre de progression, temps restant, puis « READY! ».
--   Bouton « Hatch now ⚡ » (R) pour faire éclore tout de suite contre des Robux (serveur).
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

-- $/s lisibles même petits (« 0.9 », « 3.5 », « 12 », « 2.7K »)
local function money(n: number): string
	return if n < 10 then string.format("%.1f", n) else Format.Short(n)
end

local function artOf(ring: number, name: string): string?
	for _, c in ipairs(Config.Creatures[ring] or {}) do
		if c.Name == name and c.Art ~= "" then
			return c.Art
		end
	end
	return nil
end

-- ŒUF DANS LES MAINS : POSE DIRECTE ------------------------------------------------------
-- Le serveur soude l'œuf tenu au torse et pose l'attribut HeldEgg (« anneau:rareté »).
-- Tant qu'on le tient : un fantôme montre où il ira sur le sol de sa base, clic (ou doigt) = poser.

local gui = new("ScreenGui", { Name = "Hatchery", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })

local banner = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 110),
	Size = UDim2.fromOffset(560, 62),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = gui,
}, { UIKit.corner(), UIKit.stroke(3), UIKit.gradient(UIKit.Colors.Gold[1], UIKit.Colors.Gold[2]) })
UIKit.autoScale(banner)
local bannerText = UIKit.text({ Size = UDim2.new(1, -24, 0.56, 0), Position = UDim2.new(0, 12, 0.08, 0), Text = "", Parent = banner })
local bannerSub = UIKit.text({ Size = UDim2.new(1, -24, 0.32, 0), Position = UDim2.new(0, 12, 0.62, 0), Text = "", TextColor3 = Color3.fromRGB(255, 250, 220), Parent = banner })

local placing: { ring: number, rarity: number }? = nil
local ghost: Model? = nil
local ring3d: Part? = nil
local placeX, placeZ, placeOk = 0, 0, false
local pointer: Vector2? = nil
local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

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
local function canPlace(base: Model, floor: BasePart, x: number, z: number, rarity: number): (boolean, string?)
	local foot = H.Footprint[rarity] or 3
	if math.abs(x) > floor.Size.X / 2 - H.Margin - foot * 0.5 or math.abs(z) > floor.Size.Z / 2 - H.Margin - foot * 0.5 then
		return false, "Too close to the wall"
	end
	for name, radius in pairs(H.KeepOut) do
		local thing = base:FindFirstChild(name)
		local pos = if thing and thing:IsA("Model") then thing:GetPivot().Position elseif thing and thing:IsA("BasePart") then thing.Position else nil
		if pos then
			local p = floor.CFrame:PointToObjectSpace(pos)
			if Vector2.new(p.X - x, p.Z - z).Magnitude < radius + foot * 0.4 then
				return false, if name == "Spawn" then "Not on the spawn!" else "Too close to the machine"
			end
		end
	end
	local hatchery = base:FindFirstChild("Hatchery")
	for _, m in ipairs(hatchery and hatchery:GetChildren() or {}) do
		if m:IsA("Model") then
			-- La créature se promène : on mesure depuis son socle
			local pad = m:FindFirstChild("Pad") :: BasePart?
			local p = floor.CFrame:PointToObjectSpace(if pad then pad.Position else m:GetPivot().Position)
			local other = H.Footprint[(m:GetAttribute("Rarity") or 1) :: number] or 3
			if Vector2.new(p.X - x, p.Z - z).Magnitude < foot + other then
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
end

local function startPlacing(ring: number, rarity: number)
	stopPlacing()
	placing = { ring = ring, rarity = rarity }
	player:SetAttribute("PlacingEgg", true)
	local g = EggModel.Make(ring, rarity, H.EggHeight[rarity] or 3)
	for _, d in ipairs(g:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			d.Transparency = 0.45
		end
	end
	g:PivotTo(CFrame.new(0, -500, 0))
	g.Parent = workspace
	ghost = g
	ring3d = new("Part", {
		Name = "PlaceRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, (H.Footprint[rarity] or 3) * 2, (H.Footprint[rarity] or 3) * 2),
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CFrame = CFrame.new(0, -500, 0),
		Parent = workspace,
	})
	banner.Visible = true
	UIKit.popIn(banner)
	pointer = nil
end

-- L'œuf tenu change (nouvel œuf sorti de la machine, œuf posé) : on suit
local function onHeld()
	local key = player:GetAttribute("HeldEgg")
	local ring, rarity = nil, nil
	if type(key) == "string" then
		local a, b = key:match("(%d+):(%d+)")
		ring, rarity = tonumber(a), tonumber(b)
	end
	if ring and rarity then
		if not placing or placing.ring ~= ring or placing.rarity ~= rarity then
			startPlacing(ring, rarity)
		end
	elseif placing then
		stopPlacing()
	end
end
player:GetAttributeChangedSignal("HeldEgg"):Connect(onHeld)
task.defer(onHeld)

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include

RunService.RenderStepped:Connect(function()
	if not placing or not ghost or not ring3d then
		return
	end
	local current = placing :: { ring: number, rarity: number }
	local waiting = (player:GetAttribute("WaitingEggs") or 0) :: number
	local name = Config.EggName(current.ring, current.rarity)
	bannerSub.Text = ("🏠 Base %d/%d"):format((player:GetAttribute("BaseUsed") or 0) :: number, (player:GetAttribute("BaseSlots") or H.Slots) :: number)
		.. (if waiting > 0 then ("   ·   🥚 +%d waiting"):format(waiting) else "")
	local hide = function(text: string)
		ghost:PivotTo(CFrame.new(0, -500, 0))
		ring3d.CFrame = CFrame.new(0, -500, 0)
		placeOk = false
		bannerText.Text = text
	end
	local base = myBase()
	local floor = base and base:FindFirstChild("Floor") :: BasePart?
	if not base or not floor then
		return hide("🏠 Bring your " .. name .. " to your base!")
	end
	-- Loin de sa base : on lui dit d'y retourner
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp and (hrp.Position - floor.Position).Magnitude > math.max(floor.Size.X, floor.Size.Z) * 1.2 then
		return hide("🏠 Bring your " .. name .. " to your base!")
	end
	local screen = if touch then pointer else UserInputService:GetMouseLocation()
	if not screen then
		return hide("👆 Tap your base floor to place your " .. name)
	end
	floorParams.FilterDescendantsInstances = { floor }
	-- Souris : position dans la fenêtre ; doigt : position dans l'interface (sans la barre du haut)
	local ray = if touch then camera:ScreenPointToRay(screen.X, screen.Y) else camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, floorParams)
	if not hit then
		return hide("🖱️ Point at your base floor to place your " .. name)
	end
	local p = floor.CFrame:PointToObjectSpace(hit.Position)
	placeX, placeZ = p.X, p.Z
	local ok, why = canPlace(base, floor, placeX, placeZ, current.rarity)
	placeOk = ok
	local h = H.EggHeight[current.rarity] or 3
	local top = floor.CFrame * CFrame.new(placeX, floor.Size.Y / 2, placeZ)
	local t = os.clock()
	ghost:PivotTo(CFrame.new(top.Position + Vector3.new(0, h / 2 + 0.6 + math.sin(t * 4) * 0.15, 0)) * CFrame.Angles(0, t, 0))
	ring3d.CFrame = CFrame.new(top.Position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring3d.Color = if ok then GOOD else BAD
	bannerText.Text = if ok then (if touch then "👆 Tap to place your " else "🖱️ Click to place your ") .. name else "❌ " .. (why or "Not here")
end)

local function tryPlace()
	if not placing then
		return
	end
	if not placeOk then
		UIKit.shake(banner)
		return
	end
	local current = placing :: { ring: number, rarity: number }
	Remotes.PlaceEgg:FireServer(current.ring, current.rarity, placeX, placeZ)
	-- Le fantôme disparaît tout de suite ; le serveur pose l'œuf et met le suivant dans les mains
	if ghost then
		ghost:PivotTo(CFrame.new(0, -500, 0))
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not placing or processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryPlace()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		pointer = Vector2.new(input.Position.X, input.Position.Y)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if placing and input.UserInputType == Enum.UserInputType.Touch then
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

-- Bras qui portent l'œuf (tous les joueurs qui tiennent un œuf, R15)
local DOWN = Vector3.new(0, -1, 0)
local function rotFromTo(a: Vector3, b: Vector3): CFrame
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-5 then
		return CFrame.new()
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(a:Dot(b), -1, 1)))
end
local function aimArm(character: Model, upper: string, shoulderName: string, lower: string, elbowName: string, grip: Vector3)
	local up = character:FindFirstChild(upper)
	local shoulder = up and up:FindFirstChild(shoulderName) :: Motor6D?
	if not shoulder or not shoulder.Part0 then
		return
	end
	local joint = shoulder.Part0.CFrame * shoulder.C0
	local d = grip - joint.Position
	if d.Magnitude < 0.05 then
		return
	end
	shoulder.Transform = rotFromTo(DOWN, joint:VectorToObjectSpace(d.Unit))
	local low = character:FindFirstChild(lower)
	local elbow = low and low:FindFirstChild(elbowName) :: Motor6D?
	if elbow then
		elbow.Transform = CFrame.Angles(0.35, 0, 0)
	end
end
RunService.PreSimulation:Connect(function()
	local camPos = camera.CFrame.Position
	for _, p in ipairs(Players:GetPlayers()) do
		local character = p.Character
		local egg = character and character:FindFirstChild("HeldEgg") :: Model?
		local core = egg and egg.PrimaryPart
		if character and core and (core.Position - camPos).Magnitude < 150 then
			local h = (egg:GetAttribute("BodyHeight") or 2) :: number
			local side = core.CFrame.RightVector * h * 0.42
			local right = character:FindFirstChild("RightUpperArm") :: BasePart?
			local a, b = core.Position + side, core.Position - side
			if right and (b - right.Position).Magnitude < (a - right.Position).Magnitude then
				a, b = b, a
			end
			aimArm(character, "RightUpperArm", "RightShoulder", "RightLowerArm", "RightElbow", a)
			aimArm(character, "LeftUpperArm", "LeftShoulder", "LeftLowerArm", "LeftElbow", b)
		end
	end
end)

-- ŒUFS QUI INCUBENT ---------------------------------------------------------------------

type Incub = { model: Model, gui: BillboardGui, fill: Frame, time: TextLabel, ready: boolean, prompts: { ProximityPrompt } }
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
	local prompts = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			table.insert(prompts, d)
		end
	end
	incubating[m] = { model = m, gui = b, fill = fill, time = time, ready = false, prompts = prompts }
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
		-- Les boutons « Hatch » et « Hatch now » ne s'affichent que chez le propriétaire de l'œuf
		if m:GetAttribute("Owner") ~= player.UserId then
			for _, pr in ipairs(st.prompts) do
				if pr.Enabled then
					pr.Enabled = false
				end
			end
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
	-- La créature en 3D qui tourne (ou son image tant qu'elle n'a pas de modèle)
	local folder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Creatures")
	local template = folder and folder:FindFirstChild(("R%d_T%d"):format(ring, rarity)) :: Model?
	local img: GuiObject
	if template then
		local vp = new("ViewportFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(230, 230),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(190, 190, 205),
			LightColor = Color3.new(1, 1, 1),
			LightDirection = Vector3.new(-1, -1.5, -1),
			ZIndex = 32,
			Parent = frame,
		})
		local c = template:Clone()
		c:PivotTo(CFrame.new())
		c.Parent = vp
		local _, size = c:GetBoundingBox()
		local cam = new("Camera", { FieldOfView = 30, Parent = vp })
		local dist = math.max(size.X, size.Y, size.Z) * 2.2
		local mid = Vector3.new(0, size.Y * 0.45, 0)
		cam.CFrame = CFrame.lookAt(mid + Vector3.new(0, size.Y * 0.25, -dist), mid)
		vp.CurrentCamera = cam
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not vp.Parent then
				conn:Disconnect()
				return
			end
			c:PivotTo(CFrame.Angles(0, math.sin(os.clock() * 1.4) * 0.7, 0))
		end)
		img = vp
	else
		local art = artOf(ring, name)
		img = UIKit.icon(art or "Creatures", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(190, 190), ZIndex = 32, Parent = frame })
	end
	UIKit.float(img, 6, 4, 2)
	UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, -6), Text = "🐣 YOU HATCHED", ZIndex = 33, Stroke = 3, Parent = frame })
	local nameLabel = UIKit.text({ Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 1, -86), Text = name:upper(), TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.2), ZIndex = 33, Stroke = 4, Parent = frame })
	if rarity >= 5 then
		UIKit.shinyText(nameLabel, r.Color)
	end
	UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, -40), Text = r.Name:upper() .. "  ·  💰 " .. money(income) .. "/s", TextColor3 = UIKit.Money, ZIndex = 33, Stroke = 3, Parent = frame })
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
	-- Créature en 3D : le nom et les $/s flottent au-dessus de sa tête (elle se promène : Creatures.client)
	if m:GetAttribute("Has3D") then
		local body = m:WaitForChild("Body", 10) :: Model?
		local bcore = body and body:WaitForChild("Core", 10) :: BasePart?
		if not body or not bcore or creatures[m] then
			return
		end
		local r = rarityOf((m:GetAttribute("Rarity") or 1) :: number)
		local h = (body:GetAttribute("Height") or 3) :: number
		local tag = new("BillboardGui", {
			Name = "CreatureTag",
			Size = UDim2.fromOffset(170, 46),
			StudsOffsetWorldSpace = Vector3.new(0, h + 1.1, 0),
			MaxDistance = 90,
			LightInfluence = 0,
			Adornee = bcore,
			Parent = gui,
		})
		UIKit.text({ Size = UDim2.fromScale(1, 0.55), Text = (m:GetAttribute("Creature") or "?") :: string, TextColor3 = r.Color:Lerp(Color3.new(1, 1, 1), 0.2), Parent = tag })
		UIKit.text({ Size = UDim2.fromScale(1, 0.45), Position = UDim2.fromScale(0, 0.55), Text = "💰 " .. money((m:GetAttribute("Income") or 0) :: number) .. "/s", TextColor3 = UIKit.Money, Parent = tag })
		creatures[m] = tag
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
	UIKit.text({ Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 0.87), Text = "💰 " .. money(income) .. "/s", TextColor3 = UIKit.Money, Parent = holder })
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
