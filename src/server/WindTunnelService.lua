-- Souffleries du vaisseau : on y farme le niveau du jetpack (l'équivalent des tapis de course).
-- Une soufflerie par anneau (Config.Jetpack.Tunnels), alignées sur le pont devant les bases.
-- Le joueur entre dans le courant d'air : il flotte (WindTunnel.client) et gagne de l'XP de jetpack
-- chaque seconde, même AFK, à condition d'avoir débloqué l'anneau de la soufflerie.
-- En dehors des souffleries, chaque seconde de vol réel (jetpack allumé) rapporte un peu d'XP.
-- Le serveur décide de l'XP : il regarde où sont les joueurs (le client ne fait que l'affichage).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)

local J = Config.Jetpack
local STREAK = "rbxassetid://96887170089913"
local GLOW = "rbxassetid://103844906730878"
local STUDS = "rbxassetid://99589690361139" -- picots carrés (comme tools/apply-studs.lua)

local WindTunnelService = {}

type Tunnel = { model: Model, base: Vector3, def: any }
local tunnels: { Tunnel } = {}
local lastLocked: { [Player]: number } = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- Hauteur du pont sous un point (rayon vers le bas)
local function deckY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Ship") }
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
	return if hit then hit.Position.Y else 0.6
end

local function build(index: number, def, folder: Folder): Tunnel
	local n = #J.Tunnels
	local x = (index - (n + 1) / 2) * J.TunnelSpacing
	local z = J.TunnelZ
	local y = deckY(x, z)
	local r, h = J.TunnelRadius, J.TunnelHeight
	local color = def.Color
	local m = Instance.new("Model")
	m.Name = ("Tunnel%d"):format(index)
	local dark = Color3.fromRGB(40, 44, 58)
	-- socle : anneau lumineux, grille sombre, bordure métallique
	local base = part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, r * 2 + 1.6, r * 2 + 1.6), Color = Color3.fromRGB(225, 230, 240), CanCollide = true, CFrame = CFrame.new(x, y + 0.4, z) * CFrame.Angles(0, 0, math.pi / 2) })
	base.Parent = m
	local glowRing = part({ Name = "GlowRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.85, r * 2 + 0.6, r * 2 + 0.6), Color = color, Material = Enum.Material.Neon, CFrame = base.CFrame })
	glowRing.Parent = m
	local grate = part({ Name = "Grate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, r * 2 - 0.4, r * 2 - 0.4), Color = dark, CanCollide = true, CFrame = base.CFrame })
	grate.Parent = m
	-- hélice (le client la fait tourner)
	local fan = Instance.new("Model")
	fan.Name = "Fan"
	local hub = part({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.4, 1.4), Color = color, Material = Enum.Material.Neon, CFrame = CFrame.new(x, y + 1.0, z) * CFrame.Angles(0, 0, math.pi / 2) })
	hub.Parent = fan
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		local blade = part({ Name = "Blade", Size = Vector3.new(r * 0.9, 0.15, 1.1), Color = Color3.fromRGB(200, 205, 220), CFrame = CFrame.new(x, y + 1.0, z) * CFrame.Angles(0, a, 0) * CFrame.new(r * 0.45, 0, 0) * CFrame.Angles(0.35, 0, 0) })
		blade.Parent = fan
	end
	fan.PrimaryPart = hub
	fan.Parent = m
	-- colonne d'air : tube translucide, anneaux lumineux qui montent (le client les anime)
	local column = part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), Color = color, Material = Enum.Material.ForceField, Transparency = 0.2, CFrame = CFrame.new(x, y + 0.8 + h / 2, z) * CFrame.Angles(0, 0, math.pi / 2) })
	column.Parent = m
	for i = 1, 3 do
		local ring = part({ Name = "WindRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, r * 2 + 0.2, r * 2 + 0.2), Color = color, Material = Enum.Material.Neon, Transparency = 0.5, CFrame = CFrame.new(x, y + 1 + i * h / 4, z) * CFrame.Angles(0, 0, math.pi / 2) })
		ring:SetAttribute("Phase", i / 3)
		ring.Parent = m
	end
	-- couronne au sommet
	local top = part({ Name = "Top", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 2 + 1.2, r * 2 + 1.2), Color = dark, CFrame = CFrame.new(x, y + 0.8 + h, z) * CFrame.Angles(0, 0, math.pi / 2) })
	top.Parent = m
	local topGlow = part({ Name = "TopGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.65, r * 2 + 0.4, r * 2 + 0.4), Color = color, Material = Enum.Material.Neon, CFrame = top.CFrame })
	topGlow.Parent = m
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		local pillar = part({ Name = "Pillar", Size = Vector3.new(0.6, h, 0.6), Color = Color3.fromRGB(225, 230, 240), CanCollide = true, CFrame = CFrame.new(x + math.cos(a) * (r + 0.6), y + 0.8 + h / 2, z + math.sin(a) * (r + 0.6)) })
		pillar.Parent = m
	end
	-- courant d'air : traits de vent qui montent, lueur
	local emitterPart = part({ Name = "WindEmitter", Size = Vector3.new(r * 1.7, 0.2, r * 1.7), Transparency = 1, CFrame = CFrame.new(x, y + 1.3, z) })
	emitterPart.Parent = m
	local wind = Instance.new("ParticleEmitter")
	wind.Name = "Wind"
	wind.Texture = STREAK
	wind.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	wind.LightEmission = 1
	wind.LightInfluence = 0
	wind.Orientation = Enum.ParticleOrientation.VelocityParallel
	wind.Size = NumberSequence.new({ kp(0, 0.35), kp(1, 0.1) })
	wind.Transparency = NumberSequence.new({ kp(0, 0.3), kp(1, 1) })
	wind.Lifetime = NumberRange.new(0.5, 0.8)
	wind.Speed = NumberRange.new(h * 1.4, h * 2)
	wind.Rate = 40
	wind.EmissionDirection = Enum.NormalId.Top
	wind.Parent = emitterPart
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = emitterPart
	local glow = Instance.new("ParticleEmitter")
	glow.Name = "Glow"
	glow.Texture = GLOW
	glow.Color = ColorSequence.new(color)
	glow.LightEmission = 1
	glow.LightInfluence = 0
	glow.Size = NumberSequence.new({ kp(0, r * 0.8), kp(1, r * 1.4) })
	glow.Transparency = NumberSequence.new({ kp(0, 1), kp(0.3, 0.8), kp(1, 1) })
	glow.Lifetime = NumberRange.new(1.2, 1.6)
	glow.Speed = NumberRange.new(4, 7)
	glow.Rate = 4
	glow.EmissionDirection = Enum.NormalId.Top
	glow.Parent = emitterPart
	-- panneau : nom, XP par seconde, anneau requis (le client ajoute le cadenas si besoin)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromScale(J.TunnelSpacing * 0.8, J.TunnelSpacing * 0.33) -- en studs : les panneaux voisins ne se chevauchent pas
	bb.StudsOffsetWorldSpace = Vector3.new(0, h + 3.5, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.Adornee = emitterPart
	bb.Parent = emitterPart
	-- picots carrés sur les pièces pleines (pas sur le néon ni le courant d'air)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.5 and p.Material ~= Enum.Material.Neon and p.Material ~= Enum.Material.ForceField then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local tex = Instance.new("Texture")
				tex.Name = "Studs"
				tex.Texture = STUDS
				tex.Face = face
				tex.StudsPerTileU = 2
				tex.StudsPerTileV = 2
				tex.ZIndex = 2
				tex.Parent = p
			end
		end
	end
	m:SetAttribute("Index", index)
	m:SetAttribute("XP", def.XP)
	m:SetAttribute("Ring", def.Ring)
	m:SetAttribute("Title", def.Name)
	m:SetAttribute("Radius", r)
	m:SetAttribute("Height", h)
	m:SetAttribute("BaseY", y + 0.8)
	m.PrimaryPart = base
	m.Parent = folder
	return { model = m, base = Vector3.new(x, y + 0.8, z), def = def }
end

-- Soufflerie où se trouve ce point (ou nil)
local function tunnelAt(pos: Vector3): Tunnel?
	for _, t in ipairs(tunnels) do
		local d = Vector2.new(pos.X - t.base.X, pos.Z - t.base.Z).Magnitude
		local up = pos.Y - t.base.Y
		if d <= J.TunnelRadius + 0.5 and up > -1 and up < J.TunnelHeight + 4 then
			return t
		end
	end
	return nil
end
WindTunnelService.TunnelAt = tunnelAt

local function addXP(player: Player, d, xp: number)
	local before = Config.JetpackLevel(d.jetXP or 0)
	d.jetXP = (d.jetXP or 0) + xp
	local after = Config.JetpackLevel(d.jetXP)
	GameService.Sync(player)
	if after > before then
		GameService.Notice(player, ("🚀 Jetpack level %d! You are faster"):format(after), "good")
	end
end

local function tick()
	for _, player in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(player)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if d and hrp and hum then
			local t = tunnelAt(hrp.Position)
			if t then
				if d.ring >= t.def.Ring then
					addXP(player, d, t.def.XP)
				elseif not lastLocked[player] or os.clock() - lastLocked[player] > 4 then
					lastLocked[player] = os.clock()
					GameService.Notice(player, ("🔒 Unlock ring %d to use the %s"):format(t.def.Ring, t.def.Name), "warn")
				end
			elseif hum.FloorMaterial == Enum.Material.Air and (character:GetAttribute("Jet") or 0) ~= 0 then
				addXP(player, d, J.FlightXP)
			end
		end
	end
end

function WindTunnelService.Start()
	local ship = workspace:WaitForChild("Ship")
	local old = ship:FindFirstChild("WindTunnels")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "WindTunnels"
	folder.Parent = ship
	for i, def in ipairs(J.Tunnels) do
		table.insert(tunnels, build(i, def, folder))
	end
	Players.PlayerRemoving:Connect(function(player)
		lastLocked[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return WindTunnelService
