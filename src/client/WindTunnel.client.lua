-- Souffleries (affichage et sensation) : hélices qui tournent, anneaux de vent qui montent,
-- panneaux (nom, XP/s, cadenas), et le courant d'air qui porte le joueur : il flotte sur place,
-- jetpack en vol plané (attribut InTunnel lu par Jetpack.client). Saut tenu = monter plus haut.
-- L'XP est donnée par le serveur (WindTunnelService) ; ici rien ne compte.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local J = Config.Jetpack

local HOVER = 7 -- hauteur de flottaison au-dessus du socle
local HOVER_UP = 0.8 -- part de la colonne atteinte en tenant Saut
local LIFT = 5 -- raideur du rappel vers la hauteur visée
local SIDE = 14 -- vitesse horizontale dans le courant
local FAN_SPEED = 9 -- tours d'hélice (rad/s)

type Tunnel = {
	model: Model,
	base: Vector3,
	ring: number,
	fan: { center: Vector3, rot: CFrame, parts: { { part: BasePart, offset: CFrame } } },
	rings: { BasePart },
	sign: BillboardGui?,
	locked: boolean?,
	lockLabel: TextLabel?,
}
local tunnels: { Tunnel } = {}

local function makeSign(t: Tunnel, title: string, xp: number, color: Color3)
	local sign = t.model:FindFirstChild("Sign", true) :: BillboardGui?
	if not sign then
		return
	end
	sign:ClearAllChildren()
	UIKit.text({ Size = UDim2.fromScale(1, 0.42), Text = title, TextColor3 = color, Stroke = 3, Parent = sign })
	UIKit.text({ Size = UDim2.fromScale(1, 0.32), Position = UDim2.fromScale(0, 0.42), Text = ("+%s XP/s"):format(Format.Short(xp)), TextColor3 = Color3.fromRGB(255, 240, 140), Stroke = 2.5, Parent = sign })
	t.lockLabel = UIKit.text({ Size = UDim2.fromScale(1, 0.26), Position = UDim2.fromScale(0, 0.74), Text = "", TextColor3 = Color3.fromRGB(255, 120, 120), Stroke = 2.5, Parent = sign })
	t.sign = sign
end

local function refreshLocks()
	local ring = player:GetAttribute("Ring") or 1
	for _, t in ipairs(tunnels) do
		local locked = ring < t.ring
		t.locked = locked
		if t.lockLabel then
			t.lockLabel.Text = if locked then ("🔒 Unlock ring %d"):format(t.ring) else ""
		end
		local column = t.model:FindFirstChild("Column") :: BasePart?
		if column then
			column.Transparency = if locked then 0.7 else 0.2
		end
		for _, d in ipairs(t.model:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				d.Enabled = not locked
			end
		end
	end
end

local function register(m: Model)
	local fanModel = m:WaitForChild("Fan", 10) :: Model?
	local hub = fanModel and fanModel:WaitForChild("Hub", 10) :: BasePart?
	if not fanModel or not hub then
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
	local x, z = hub.Position.X, hub.Position.Z
	local t: Tunnel = {
		model = m,
		base = Vector3.new(x, (m:GetAttribute("BaseY") or hub.Position.Y) :: number, z),
		ring = (m:GetAttribute("Ring") or 1) :: number,
		fan = { center = hub.Position, rot = hub.CFrame - hub.Position, parts = fanParts },
		rings = rings,
	}
	local def = J.Tunnels[(m:GetAttribute("Index") or 1) :: number]
	makeSign(t, (m:GetAttribute("Title") or "Wind Tunnel") :: string, (m:GetAttribute("XP") or 1) :: number, def and def.Color or Color3.new(1, 1, 1))
	table.insert(tunnels, t)
	refreshLocks()
end

local function tunnelAt(pos: Vector3): Tunnel?
	for _, t in ipairs(tunnels) do
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
end)
player:GetAttributeChangedSignal("Ring"):Connect(refreshLocks)

local spin = 0
RunService.RenderStepped:Connect(function(dt)
	spin += dt * FAN_SPEED
	local now = os.clock()
	-- hélices et anneaux de vent
	for _, t in ipairs(tunnels) do
		if not t.locked then
			-- rotation autour de l'axe vertical, en gardant l'orientation d'origine du moyeu (cylindre couché)
			local hubCF = CFrame.new(t.fan.center) * CFrame.Angles(0, spin, 0) * t.fan.rot
			for _, fp in ipairs(t.fan.parts) do
				fp.part.CFrame = hubCF * fp.offset
			end
		end
		for _, ring in ipairs(t.rings) do
			local phase = ((ring:GetAttribute("Phase") or 0) :: number + now * (if t.locked then 0.08 else 0.45)) % 1
			ring.CFrame = CFrame.new(t.base.X, t.base.Y + 0.5 + phase * J.TunnelHeight, t.base.Z) * CFrame.Angles(0, 0, math.pi / 2)
			ring.Transparency = 0.35 + 0.65 * math.max(phase - 0.6, 0) / 0.4
		end
	end

	-- le courant d'air porte le joueur
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		player:SetAttribute("InTunnel", nil)
		return
	end
	local t = tunnelAt(hrp.Position)
	if not t then
		if player:GetAttribute("InTunnel") then
			player:SetAttribute("InTunnel", nil)
		end
		return
	end
	if t.locked then
		-- soufflerie verrouillée : le vent repousse doucement vers l'extérieur
		player:SetAttribute("InTunnel", nil)
		local away = Vector3.new(hrp.Position.X - t.base.X, 0, hrp.Position.Z - t.base.Z)
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(0, 0, 1)
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(away.X * 18, math.max(v.Y, 6), away.Z * 18)
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
