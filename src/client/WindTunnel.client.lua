-- Souffleries personnelles (affichage et sensation) : hélices qui tournent, anneaux de vent qui
-- montent, panneaux (palier, XP/s, prochain palier ou prix d'achat), et le courant d'air qui porte
-- le joueur dans SA soufflerie achetée : il flotte sur place, jetpack en vol plané (attribut
-- InTunnel lu par Jetpack.client). Saut tenu = monter plus haut.
-- Les achats et l'XP sont gérés par le serveur (WindTunnelService) ; ici rien ne compte.
-- Chaque seconde d'entraînement, des « +XP » jaillissent du joueur : d'autant plus nombreux, gros et
-- dorés que la soufflerie est haut de gamme (Remotes.TunnelXP : XP gagnée, boosts compris, et palier).
-- Bonus à attraper (Config.Jetpack.Boost) : de temps en temps un gros bouton « x2 » apparaît quelques
-- secondes (attribut TunnelBoostOffer) ; cliqué à temps, l'XP est doublée un court moment (TunnelBoostEnd).
-- Chaque niveau gagné dans la soufflerie : un flash très léger et un petit tremblement de la caméra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Theme = require(ReplicatedStorage.Shared:WaitForChild("Theme"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local player = Players.LocalPlayer
local J = Config.Jetpack

local HOVER = 7 -- hauteur de flottaison au-dessus du socle
local HOVER_UP = 0.8 -- part de la colonne atteinte en tenant Saut
local LIFT = 5 -- raideur du rappel vers la hauteur visée
local SIDE = 14 -- vitesse horizontale dans le courant
local FAN_SPEED = 9 -- tours d'hélice (rad/s)
local GOLD = Color3.fromRGB(255, 240, 140)
local GREY = Color3.fromRGB(200, 205, 220)

type Tunnel = {
	model: Model,
	base: Vector3,
	active: boolean, -- achetée (palier >= 1)
	mine: boolean, -- c'est la soufflerie du joueur local
	fan: { center: Vector3, rot: CFrame, parts: { { part: BasePart, offset: CFrame } } },
	rings: { BasePart },
}
local tunnels: { [Model]: Tunnel } = {}

local function money(n: number): string
	return "$" .. Format.Short(n)
end

-- Panneau au-dessus de la soufflerie, selon le palier et le propriétaire
local function makeSign(m: Model, mine: boolean)
	local sign = m:FindFirstChild("Sign", true) :: BillboardGui?
	if not sign then
		return
	end
	sign:ClearAllChildren()
	local tier = (m:GetAttribute("Tier") or 0) :: number
	local color = (m:GetAttribute("Color") or Color3.new(1, 1, 1)) :: Color3
	local owner = (m:GetAttribute("OwnerName") or "") :: string
	local nextName = (m:GetAttribute("NextName") or "") :: string
	local nextCost = (m:GetAttribute("NextCost") or 0) :: number
	local title, line2, line3, c2, c3
	if tier >= 1 then
		title = (m:GetAttribute("Title") or "Wind Tunnel") :: string
		line2 = ("+%s XP/s"):format(Format.Short((m:GetAttribute("XP") or 0) :: number))
		c2 = GOLD
		if mine then
			line3 = if nextName ~= "" then ("{ArrowUp} %s · %s"):format(nextName, money(nextCost)) else "{Star} MAX LEVEL"
			c3 = Color3.fromRGB(140, 255, 160)
		else
			line3 = if owner ~= "" then owner .. "'s tunnel" else ""
			c3 = GREY
		end
	elseif mine then
		title = "{WindTunnel} WIND TUNNEL"
		color = Color3.fromRGB(150, 235, 255)
		line2 = "Buy for " .. money(nextCost)
		c2 = Color3.fromRGB(140, 255, 160)
		line3 = "Train your jetpack here, even AFK!"
		c3 = Color3.new(1, 1, 1)
	else
		title = "Wind Tunnel"
		line2 = if owner ~= "" then owner .. "'s base" else ""
		c2 = GREY
		line3 = ""
		c3 = GREY
	end
	UIKit.text({ Size = UDim2.fromScale(1, 0.42), Text = title, TextColor3 = color, Stroke = 3, Parent = sign })
	UIKit.text({ Size = UDim2.fromScale(1, 0.32), Position = UDim2.fromScale(0, 0.42), Text = line2, TextColor3 = c2, Stroke = 2.5, Parent = sign })
	UIKit.text({ Size = UDim2.fromScale(1, 0.24), Position = UDim2.fromScale(0, 0.76), Text = line3, TextColor3 = c3, Stroke = 2.5, Parent = sign })
end

local function register(m: Model)
	local fanModel = m:WaitForChild("Fan", 10) :: Model?
	local hub = fanModel and fanModel:WaitForChild("Hub", 10) :: BasePart?
	if not fanModel or not hub or not m.Parent then
		return
	end
	local fanParts = {}
	for _, p in ipairs(fanModel:GetChildren()) do
		if p:IsA("BasePart") then
			table.insert(fanParts, { part = p, offset = hub.CFrame:ToObjectSpace(p.CFrame) })
		end
	end
	local rings = {}
	for _, p in ipairs(m:GetChildren()) do
		if p.Name == "WindRing" and p:IsA("BasePart") then
			table.insert(rings, p)
		end
	end
	local mine = m:GetAttribute("OwnerId") == player.UserId
	tunnels[m] = {
		model = m,
		base = Vector3.new(hub.Position.X, (m:GetAttribute("BaseY") or hub.Position.Y) :: number, hub.Position.Z),
		active = ((m:GetAttribute("Tier") or 0) :: number) >= 1,
		mine = mine,
		fan = { center = hub.Position, rot = hub.CFrame - hub.Position, parts = fanParts },
		rings = rings,
	}
	makeSign(m, mine)
end

local function tunnelAt(pos: Vector3): Tunnel?
	for _, t in pairs(tunnels) do
		local d = Vector2.new(pos.X - t.base.X, pos.Z - t.base.Z).Magnitude
		local up = pos.Y - t.base.Y
		if d <= J.TunnelRadius and up > -1 and up < J.TunnelHeight + 4 then
			return t
		end
	end
	return nil
end

task.spawn(function()
	local folder = workspace:WaitForChild("Ship"):WaitForChild("WindTunnels")
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") then
			task.spawn(register, m)
		end
	end
	folder.ChildAdded:Connect(function(m)
		if m:IsA("Model") then
			register(m)
		end
	end)
	folder.ChildRemoved:Connect(function(m)
		tunnels[m :: Model] = nil
	end)
end)

local spin = 0
RunService.RenderStepped:Connect(function(dt)
	spin += dt * FAN_SPEED
	local now = os.clock()
	-- hélices et anneaux de vent (seulement sur les souffleries achetées)
	for _, t in pairs(tunnels) do
		if t.active then
			-- rotation autour de l'axe vertical, en gardant l'orientation d'origine du moyeu (cylindre couché)
			local hubCF = CFrame.new(t.fan.center) * CFrame.Angles(0, spin, 0) * t.fan.rot
			for _, fp in ipairs(t.fan.parts) do
				fp.part.CFrame = hubCF * fp.offset
			end
			for _, ring in ipairs(t.rings) do
				local phase = ((ring:GetAttribute("Phase") or 0) :: number + now * 0.45) % 1
				ring.CFrame = CFrame.new(t.base.X, t.base.Y + 0.5 + phase * J.TunnelHeight, t.base.Z) * CFrame.Angles(0, 0, math.pi / 2)
				ring.Transparency = 0.35 + 0.65 * math.max(phase - 0.6, 0) / 0.4
			end
		end
	end

	-- le courant d'air de sa propre soufflerie porte le joueur
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		player:SetAttribute("InTunnel", nil)
		return
	end
	local t = tunnelAt(hrp.Position)
	if not t or not t.active or not t.mine then
		if player:GetAttribute("InTunnel") then
			player:SetAttribute("InTunnel", nil)
		end
		return
	end
	player:SetAttribute("InTunnel", true)
	local rising = UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA) or hum.Jump
	local target = t.base.Y + (if rising then J.TunnelHeight * HOVER_UP else HOVER) + math.sin(now * 2.2) * 0.6
	local vy = math.clamp((target - hrp.Position.Y) * LIFT, -14, 22)
	local move = hum.MoveDirection * SIDE
	-- léger rappel vers l'axe pour ne pas glisser hors du courant sans le vouloir
	local toAxis = Vector3.new(t.base.X - hrp.Position.X, 0, t.base.Z - hrp.Position.Z) * 0.6
	local v = hrp.AssemblyLinearVelocity
	local goal = Vector3.new(move.X + (if move.Magnitude < 1 then toAxis.X else 0), vy, move.Z + (if move.Magnitude < 1 then toAxis.Z else 0))
	hrp.AssemblyLinearVelocity = v:Lerp(goal, math.min(1, dt * 8))
	if hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end)

-- « +XP » QUI JAILLISSENT DU JOUEUR ------------------------------------------------------------

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local OUTLINE = Color3.fromRGB(22, 22, 32)
local XP_COLORS = { Color3.fromRGB(150, 235, 255), Color3.fromRGB(110, 210, 255), Color3.fromRGB(140, 255, 200), Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 140, 220), Color3.fromRGB(190, 150, 255), Color3.fromRGB(255, 225, 90) }

local PURPLE = Color3.fromRGB(200, 120, 255)
local PURPLE_LIGHT = Color3.fromRGB(235, 190, 255)

-- Le joueur brille en violet le temps d'un gain doublé : contour et voile violets, lumière, étincelles
local function shinePurple()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hrp then
		return
	end
	local hl = Instance.new("Highlight")
	hl.Name = "BoostShine"
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.FillColor = PURPLE
	hl.FillTransparency = 0.25
	hl.OutlineColor = PURPLE_LIGHT
	hl.OutlineTransparency = 0
	hl.Parent = character
	local light = Instance.new("PointLight")
	light.Color = PURPLE
	light.Range = 18
	light.Brightness = 4
	light.Shadows = false
	light.Parent = hrp
	local at = Instance.new("Attachment")
	at.Parent = hrp
	local e = Instance.new("ParticleEmitter")
	e.Texture = UIKit.Art.FxSparkle
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), PURPLE)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Enabled = false
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 3
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.3), NumberSequenceKeypoint.new(1, 0) })
	e.Rotation = NumberRange.new(0, 360)
	e.Parent = at
	e:Emit(36)
	task.delay(0.35, function()
		e:Emit(18)
	end)
	TweenService:Create(hl, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	TweenService:Create(light, TweenInfo.new(1.1), { Brightness = 0 }):Play()
	Debris:AddItem(hl, 1.2)
	Debris:AddItem(light, 1.2)
	Debris:AddItem(at, 1.6)
end

local function popXP(amount: number, tier: number, i: number, boosted: boolean?)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	-- gain doublé par le bonus x2 : bulles violettes et plus grosses
	local gold = boosted == true
	local color = if gold then PURPLE else XP_COLORS[math.clamp(tier, 1, #XP_COLORS)]
	local big = (1 + (tier - 1) * 0.12) * (if gold then 1.35 else 1)
	-- part du corps du joueur dans une direction au hasard, monte en s'écartant
	local a = math.random() * math.pi * 2
	local out = Vector3.new(math.cos(a), 0, math.sin(a))
	local start = hrp.Position + out * 1.2 + Vector3.new(0, math.random() * 2 - 0.5, 0)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = start
	holder.Parent = workspace
	local b = Instance.new("BillboardGui")
	b.Size = UDim2.fromOffset(150 * big, 46 * big)
	b.AlwaysOnTop = false -- les BillboardGui « toujours devant » ne s'affichent pas dans ce jeu
	b.LightInfluence = 0
	b.MaxDistance = 120
	b.Parent = holder
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.FontFace = Theme.FontHeavy
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = "+" .. Format.Short(amount) .. " XP"
	t.Rotation = math.random(-12, 12)
	t.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5 + tier * 0.25
	stroke.Color = OUTLINE
	stroke.Parent = t
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = t
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(holder, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = start + out * 2.5 + Vector3.new(0, 4 + math.random() * 2, 0) }):Play()
	task.delay(0.65, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
	Debris:AddItem(holder, 1.2)
	-- petit « pop » qui monte d'un ton à chaque bulle de la seconde
	Sfx.Play("Pop", { volume = 0.18, pitch = 1 + i * 0.06 })
end

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TunnelXP").OnClientEvent:Connect(function(gain: number, tier: number, boosted: boolean?)
	if type(gain) ~= "number" or gain <= 0 then
		return
	end
	tier = if type(tier) == "number" then tier else 1
	if boosted then
		shinePurple()
	end
	-- plus la soufflerie est haut de gamme, plus il y a de bulles dans la seconde (2 à 9)
	-- nombres entiers qui, additionnés, font l'XP gagnée
	gain = math.max(1, math.floor(gain + 0.5))
	local count = math.min(math.clamp(1 + tier, 2, 9), gain)
	local base = gain // count
	local extra = gain - base * count
	for i = 0, count - 1 do
		task.delay(i / count, popXP, base + (if i < extra then 1 else 0), tier, i, boosted)
	end
end)

-- BONUS x2 À ATTRAPER ----------------------------------------------------------------------------
-- Le serveur décide quand il apparaît et s'il est attrapé à temps (WindTunnelService) ; ici le bouton :
-- un gros rond violet avec un doigt qui tape et « x2 XP », qui traverse l'écran en rebondissant sur les
-- bords : il faut le toucher (19 nov.). À la manette, qui n'a pas de pointeur, la touche X l'attrape.

local ContextActionService = game:GetService("ContextActionService")
local Device = require(script.Parent:WaitForChild("Device"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local new = UIKit.new
local BOOST = J.Boost
local BOOST_KEYS = { Enum.KeyCode.ButtonX }

local boostGui = new("ScreenGui", { Name = "TunnelBoost", ResetOnSpawn = false, DisplayOrder = 6, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = boostGui })
local BOOST_SIZE = 215
local holder = new("Frame", { Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(BOOST_SIZE, BOOST_SIZE), BackgroundTransparency = 1, Visible = false, Parent = boostGui })
UIKit.autoScale(holder)
UIKit.rays(holder, { color = PURPLE_LIGHT, size = BOOST_SIZE * 2, speed = 70, transparency = 0.3, z = 1 })
UIKit.glow(holder, { color = PURPLE, size = BOOST_SIZE * 1.8, transparency = 0.35, z = 1, pulse = 2.2 })
-- le bouton : un rond (le reste de l'interface a des angles vifs, lui se détache)
local function round(): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end
local bubble = new("TextButton", { Name = "Boost", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Text = "", ZIndex = 2, Parent = holder }, {
	round(),
	new("UIStroke", { Thickness = 7, Color = UIKit.Outline, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	UIKit.gradient(Color3.fromRGB(235, 170, 255), Color3.fromRGB(150, 70, 240)),
})
local boostStuds = UIKit.studs(bubble, 0.5, "Studs", 22, "button")
local studCorner = boostStuds:FindFirstChildOfClass("UICorner")
if studCorner then
	studCorner.CornerRadius = UDim.new(0.5, 0)
end
-- anneau clair à l'intérieur du bord, pour le relief
new("Frame", { Name = "Rim", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.9), BackgroundTransparency = 1, ZIndex = 3, Parent = bubble }, {
	round(),
	new("UIStroke", { Thickness = 3, Color = PURPLE_LIGHT, Transparency = 0.25 }),
})
-- le doigt qui tape (il s'enfonce en rythme pour dire « touche-moi ») et le texte en dessous
local finger = UIKit.icon("Tap", { Name = "Finger", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromScale(0.56, 0.56), ZIndex = 4, Parent = bubble })
UIKit.text({ Name = "Big", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.3), Position = UDim2.fromScale(0.5, 0.76), Text = ("x%d XP"):format(BOOST.Mult), TextColor3 = Color3.fromRGB(255, 240, 140), ZIndex = 5, Stroke = 5, Parent = bubble })
-- temps restant pour l'attraper : une barre qui se vide sous le bouton
local timeBack = new("Frame", { Name = "Time", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.7, 0, 0, 12), Position = UDim2.new(0.5, 0, 1, 14), BackgroundColor3 = Color3.fromRGB(25, 30, 48), ZIndex = 2, Parent = holder }, { UIKit.corner(), UIKit.stroke(3) })
local timeFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = PURPLE_LIGHT, BorderSizePixel = 0, ZIndex = 3, Parent = timeBack })
-- touche de la manette
local keyTag = UIKit.text({ Name = "Key", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(44, 36), Position = UDim2.fromScale(0.92, 0.08), Text = "X", ZIndex = 6, Stroke = 3.5, Parent = holder })
UIKit.juice(bubble)

local offerEnds = 0
local grabbing = false
-- déplacement du bouton : position (part de l'écran) et vitesse (part de l'écran par seconde)
local boostPos = Vector2.new(0.5, 0.4)
local boostVel = Vector2.zero
local BOOST_MIN, BOOST_MAX = Vector2.new(0.16, 0.24), Vector2.new(0.84, 0.66)

local function hideOffer()
	holder.Visible = false
	offerEnds = 0
	ContextActionService:UnbindAction("TunnelBoost")
end

local function grab()
	if grabbing or not holder.Visible then
		return
	end
	grabbing = true
	local at = UDim2.fromScale(holder.Position.X.Scale, holder.Position.Y.Scale)
	local ok, res = pcall(function()
		return Remotes.TunnelUp:InvokeServer("boost")
	end)
	grabbing = false
	hideOffer()
	if ok and type(res) == "table" and res.ok then
		Sfx.Play("Coin", { pitch = 1.5 })
		UIKit.burst(flash, at, PURPLE)
		UIKit.flyText(boostGui, ("x%d XP!"):format(BOOST.Mult), at, PURPLE_LIGHT)
	end
end
bubble.MouseButton1Click:Connect(grab)

local function showOffer(ends: number)
	offerEnds = ends
	-- il part d'un endroit au hasard, dans une direction au hasard, et rebondit sur les bords
	boostPos = Vector2.new(0.25 + math.random() * 0.5, 0.3 + math.random() * 0.3)
	local a = math.random() * math.pi * 2
	boostVel = Vector2.new(math.cos(a), math.sin(a)) * BOOST.Speed
	holder.Position = UDim2.fromScale(boostPos.X, boostPos.Y)
	local kind = Device.Kind()
	keyTag.Visible = kind == "Gamepad"
	keyTag.Text = Device.PadName(Enum.KeyCode.ButtonX)
	holder.Visible = true
	UIKit.popIn(holder)
	Sfx.Play("Pop", { pitch = 1.4 })
	ContextActionService:BindAction("TunnelBoost", function(_, state)
		if state == Enum.UserInputState.Begin then
			task.spawn(grab)
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(BOOST_KEYS))
end

local function onOffer()
	local ends = player:GetAttribute("TunnelBoostOffer")
	if type(ends) == "number" and ends > workspace:GetServerTimeNow() then
		showOffer(ends)
	else
		hideOffer()
	end
end
player:GetAttributeChangedSignal("TunnelBoostOffer"):Connect(onOffer)
onOffer()

RunService.Heartbeat:Connect(function(dt)
	if not holder.Visible then
		return
	end
	local left = offerEnds - workspace:GetServerTimeNow()
	if left <= 0 or not player:GetAttribute("InTunnel") then
		hideOffer()
		return
	end
	timeFill.Size = UDim2.fromScale(math.clamp(left / BOOST.Offer, 0, 1), 1)
	-- le doigt tape en rythme
	local tap = math.abs(math.sin(os.clock() * 7))
	finger.Position = UDim2.fromScale(0.5, 0.36 + 0.05 * tap)
	finger.Rotation = -8 + 6 * tap
	-- il file en ligne droite et rebondit sur les bords (x ralenti par le rapport de l'écran)
	local vp = workspace.CurrentCamera.ViewportSize
	local ratio = if vp.X > 0 then vp.Y / vp.X else 0.56
	local p = boostPos + Vector2.new(boostVel.X * ratio, boostVel.Y) * math.min(dt, 0.1)
	if p.X < BOOST_MIN.X or p.X > BOOST_MAX.X then
		boostVel = Vector2.new(-boostVel.X, boostVel.Y)
		p = Vector2.new(math.clamp(p.X, BOOST_MIN.X, BOOST_MAX.X), p.Y)
	end
	if p.Y < BOOST_MIN.Y or p.Y > BOOST_MAX.Y then
		boostVel = Vector2.new(boostVel.X, -boostVel.Y)
		p = Vector2.new(p.X, math.clamp(p.Y, BOOST_MIN.Y, BOOST_MAX.Y))
	end
	boostPos = p
	holder.Position = UDim2.fromScale(p.X, p.Y)
end)
