-- Souffleries personnelles (affichage et sensation) : hélices qui tournent, anneaux de vent qui
-- montent, panneaux (palier, XP/s, prochain palier ou prix d'achat), et le courant d'air qui porte
-- le joueur dans SA soufflerie achetée : il flotte sur place, jetpack en vol plané (attribut
-- InTunnel lu par Jetpack.client). Saut tenu = monter plus haut.
-- Les achats et l'XP sont gérés par le serveur (WindTunnelService) ; ici rien ne compte.
-- Chaque seconde d'entraînement, des « +XP » jaillissent du joueur : d'autant plus nombreux, gros et
-- dorés que la soufflerie est haut de gamme (Remotes.TunnelXP : XP gagnée, boosts compris, et palier).

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

local function popXP(amount: number, tier: number, i: number)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local color = XP_COLORS[math.clamp(tier, 1, #XP_COLORS)]
	local big = 1 + (tier - 1) * 0.12
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

ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TunnelXP").OnClientEvent:Connect(function(gain: number, tier: number)
	if type(gain) ~= "number" or gain <= 0 then
		return
	end
	tier = if type(tier) == "number" then tier else 1
	-- plus la soufflerie est haut de gamme, plus il y a de bulles dans la seconde (2 à 9)
	-- nombres entiers qui, additionnés, font l'XP gagnée
	gain = math.max(1, math.floor(gain + 0.5))
	local count = math.min(math.clamp(1 + tier, 2, 9), gain)
	local base = gain // count
	local extra = gain - base * count
	for i = 0, count - 1 do
		task.delay(i / count, popXP, base + (if i < extra then 1 else 0), tier, i)
	end
end)
