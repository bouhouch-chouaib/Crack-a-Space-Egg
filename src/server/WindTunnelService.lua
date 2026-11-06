-- Souffleries personnelles : on y farme le niveau du jetpack (l'équivalent des tapis de course).
-- Chaque base a son emplacement de soufflerie, devant l'entrée (Config.Jetpack.TunnelOffset).
-- Le joueur l'achète (Breeze Tunnel), puis l'améliore palier par palier (Config.Jetpack.Tunnels) :
-- invite « Buy » / « Upgrade » sur le socle, visible seulement par le propriétaire (WindTunnel.client).
-- Dans le courant d'air de SA soufflerie, il flotte (WindTunnel.client) et gagne de l'XP de jetpack
-- chaque seconde, même AFK. Hors soufflerie, chaque seconde de vol réel rapporte un peu d'XP.
-- Le serveur décide de l'XP et des achats ; le client ne fait que l'affichage.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local J = Config.Jetpack
local STREAK = "rbxassetid://96887170089913"
local GLOW = "rbxassetid://103844906730878"
local STUDS = "rbxassetid://99589690361139" -- picots carrés (comme tools/apply-studs.lua)
local EMPTY_COLOR = Color3.fromRGB(120, 130, 150)

local WindTunnelService = {}

type Tunnel = { model: Model, base: Vector3, tier: number, owner: Player? }
local tunnels: { [number]: Tunnel } = {} -- par numéro de base
local folder: Folder

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

local function money(n: number): string
	return "$" .. Format.Short(n)
end

-- Hauteur du pont sous un point (rayon vers le bas)
local function deckY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Ship") }
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
	return if hit then hit.Position.Y else 0.6
end

-- Centre du socle de la soufflerie de cette base
local function spot(base: Model): Vector3
	local floor = base:FindFirstChild("Floor") :: BasePart?
	local cf = if floor then floor.CFrame else base:GetPivot()
	local p = cf:PointToWorldSpace(J.TunnelOffset)
	return Vector3.new(p.X, deckY(p.X, p.Z), p.Z)
end

local function addStuds(m: Model)
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
end

local buy: (Player, number) -> ()

-- Construit la soufflerie d'une base au palier « tier » (0 = socle à acheter)
local function build(index: number, pos: Vector3, tier: number, owner: Player?): Model
	local def = J.Tunnels[tier]
	local nextDef = J.Tunnels[tier + 1]
	local x, y, z = pos.X, pos.Y, pos.Z
	local r, h = J.TunnelRadius, J.TunnelHeight
	local color = if def then def.Color else EMPTY_COLOR
	local dark = Color3.fromRGB(40, 44, 58)
	local m = Instance.new("Model")
	m.Name = "Tunnel" .. index
	local flat = CFrame.Angles(0, 0, math.pi / 2)

	-- socle : bordure claire, anneau lumineux, grille sombre (on peut marcher dessus)
	local base = part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, r * 2 + 1.6, r * 2 + 1.6), Color = Color3.fromRGB(225, 230, 240), CanCollide = true, CFrame = CFrame.new(x, y + 0.4, z) * flat })
	base.Parent = m
	part({ Name = "GlowRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.85, r * 2 + 0.6, r * 2 + 0.6), Color = color, Material = Enum.Material.Neon, Transparency = if def then 0 else 0.5, CFrame = base.CFrame }).Parent = m
	part({ Name = "Grate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, r * 2 - 0.4, r * 2 - 0.4), Color = dark, CanCollide = true, CFrame = base.CFrame }).Parent = m
	-- hélice (le client la fait tourner une fois la soufflerie achetée)
	local fan = Instance.new("Model")
	fan.Name = "Fan"
	local hub = part({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.4, 1.4), Color = color, Material = Enum.Material.Neon, CFrame = CFrame.new(x, y + 1.0, z) * flat })
	hub.Parent = fan
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		part({ Name = "Blade", Size = Vector3.new(r * 0.9, 0.15, 1.1), Color = Color3.fromRGB(200, 205, 220), CFrame = CFrame.new(x, y + 1.0, z) * CFrame.Angles(0, a, 0) * CFrame.new(r * 0.45, 0, 0) * CFrame.Angles(0.35, 0, 0) }).Parent = fan
	end
	fan.PrimaryPart = hub
	fan.Parent = m

	if def then
		-- colonne d'air, anneaux de vent (animés par le client), couronne, piliers
		part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), Color = color, Material = Enum.Material.ForceField, Transparency = 0.2, CFrame = CFrame.new(x, y + 0.8 + h / 2, z) * flat }).Parent = m
		for i = 1, 3 do
			local ring = part({ Name = "WindRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, r * 2 + 0.2, r * 2 + 0.2), Color = color, Material = Enum.Material.Neon, Transparency = 0.5, CFrame = CFrame.new(x, y + 1 + i * h / 4, z) * flat })
			ring:SetAttribute("Phase", i / 3)
			ring.Parent = m
		end
		local top = part({ Name = "Top", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 2 + 1.2, r * 2 + 1.2), Color = dark, CFrame = CFrame.new(x, y + 0.8 + h, z) * flat })
		top.Parent = m
		part({ Name = "TopGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.65, r * 2 + 0.4, r * 2 + 0.4), Color = color, Material = Enum.Material.Neon, CFrame = top.CFrame }).Parent = m
		for i = 0, 2 do
			local a = i / 3 * math.pi * 2 + math.pi / 6
			part({ Name = "Pillar", Size = Vector3.new(0.6, h, 0.6), Color = Color3.fromRGB(225, 230, 240), CanCollide = true, CFrame = CFrame.new(x + math.cos(a) * (r + 0.6), y + 0.8 + h / 2, z + math.sin(a) * (r + 0.6)) }).Parent = m
		end
	else
		-- pas encore achetée : silhouette holographique de la colonne
		part({ Name = "Hologram", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h * 0.5, r * 2, r * 2), Color = Color3.fromRGB(150, 235, 255), Material = Enum.Material.ForceField, Transparency = 0.6, CFrame = CFrame.new(x, y + 0.8 + h / 4, z) * flat }).Parent = m
	end

	-- vent qui monte, lueur (plus fort à chaque palier)
	local emitterPart = part({ Name = "WindEmitter", Size = Vector3.new(r * 1.7, 0.2, r * 1.7), Transparency = 1, CFrame = CFrame.new(x, y + 1.3, z) })
	emitterPart.Parent = m
	if def then
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
		wind.Rate = 30 + tier * 8
		wind.EmissionDirection = Enum.NormalId.Top
		wind.Parent = emitterPart
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
		glow.Rate = 3 + tier
		glow.EmissionDirection = Enum.NormalId.Top
		glow.Parent = emitterPart
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 14
		light.Brightness = 1.5
		light.Parent = emitterPart
	end
	-- panneau (rempli par le client) et invite d'achat / d'amélioration (propriétaire seulement)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromScale(13, 5.5)
	bb.StudsOffsetWorldSpace = Vector3.new(0, (if def then h else h * 0.5) + 3.5, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.Adornee = emitterPart
	bb.Parent = emitterPart
	if nextDef and owner then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyPrompt"
		prompt.ActionText = if def then "Upgrade to " .. nextDef.Name else "Buy " .. nextDef.Name
		prompt.ObjectText = money(nextDef.Cost)
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = base
		prompt.Triggered:Connect(function(player)
			buy(player, index)
		end)
	end

	addStuds(m)
	m:SetAttribute("Base", index)
	m:SetAttribute("OwnerId", if owner then owner.UserId else 0)
	m:SetAttribute("OwnerName", if owner then owner.DisplayName else "")
	m:SetAttribute("Tier", tier)
	m:SetAttribute("Title", if def then def.Name else "Wind Tunnel")
	m:SetAttribute("XP", if def then def.XP else 0)
	m:SetAttribute("NextName", if nextDef then nextDef.Name else "")
	m:SetAttribute("NextCost", if nextDef then nextDef.Cost else 0)
	m:SetAttribute("Color", color)
	m:SetAttribute("Radius", r)
	m:SetAttribute("Height", h)
	m:SetAttribute("BaseY", y + 0.8)
	m.PrimaryPart = base
	m.Parent = folder
	return m
end

-- (Re)construit la soufflerie d'une base selon son propriétaire actuel (sauf le joueur qui part)
local function refresh(index: number, leaving: Player?)
	local base = WorldBuilder.Bases[index]
	if not base then
		return
	end
	local owner: Player? = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= leaving and p:GetAttribute("Base") == index then
			owner = p
		end
	end
	local d = owner and DataService.Get(owner)
	if not d then
		owner = nil
	end
	local tier = if d then math.clamp(d.tunnel or 0, 0, #J.Tunnels) else 0
	local old = tunnels[index]
	if old and old.tier == tier and old.owner == owner then
		return
	end
	if old then
		old.model:Destroy()
	end
	local pos = spot(base)
	local model = build(index, pos, tier, owner)
	tunnels[index] = { model = model, base = Vector3.new(pos.X, pos.Y + 0.8, pos.Z), tier = tier, owner = owner }
end

buy = function(player: Player, index: number)
	if player:GetAttribute("Base") ~= index then
		return -- la soufflerie d'un autre joueur
	end
	local d = DataService.Get(player)
	if not d then
		return
	end
	local nextDef = J.Tunnels[(d.tunnel or 0) + 1]
	if not nextDef then
		GameService.Notice(player, "{WindTunnel} Your wind tunnel is already at max level!", "info")
		return
	end
	if d.credits < nextDef.Cost then
		GameService.Notice(player, ("Not enough money: %s needed"):format(money(nextDef.Cost)), "warn")
		return
	end
	d.credits -= nextDef.Cost
	d.tunnel = (d.tunnel or 0) + 1
	GameService.Sync(player)
	refresh(index)
	GameService.Notice(player, ("{WindTunnel} %s ready! +%s XP/s"):format(nextDef.Name, Format.Short(nextDef.XP)), "good")
end
WindTunnelService.Buy = buy

-- Soufflerie où se trouve ce point (ou nil)
local function tunnelAt(pos: Vector3): Tunnel?
	for _, t in pairs(tunnels) do
		local dist = Vector2.new(pos.X - t.base.X, pos.Z - t.base.Z).Magnitude
		local up = pos.Y - t.base.Y
		if dist <= J.TunnelRadius + 0.5 and up > -1 and up < J.TunnelHeight + 4 then
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
		GameService.Notice(player, ("{Jetpack} Jetpack level %d! You are faster"):format(after), "good")
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
				-- seulement dans sa propre soufflerie, une fois achetée
				if t.owner == player and t.tier >= 1 then
					addXP(player, d, J.Tunnels[t.tier].XP)
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
	folder = Instance.new("Folder")
	folder.Name = "WindTunnels"
	folder.Parent = ship
	for i in ipairs(WorldBuilder.Bases) do
		refresh(i)
	end
	-- la base change de propriétaire : à l'arrivée (une fois la partie chargée) et au départ
	DataService.Loaded:Connect(function(player: Player)
		local i = player:GetAttribute("Base")
		if type(i) == "number" then
			refresh(i)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local i = player:GetAttribute("Base")
		if type(i) == "number" then
			refresh(i, player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
	-- Studio seulement : point d'accès de test (donner de l'argent, lire l'état)
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "TunnelDebug"
		bf.OnInvoke = function(cmd: string, player: Player, arg: any)
			local d = DataService.Get(player)
			if not d then
				return "pas de données"
			end
			if cmd == "credits" then
				d.credits += arg
				GameService.Sync(player)
			end
			return ("credits %s tunnel %d jetXP %s"):format(Format.Short(d.credits), d.tunnel or 0, tostring(d.jetXP))
		end
		bf.Parent = ServerStorage
	end
end

return WindTunnelService
