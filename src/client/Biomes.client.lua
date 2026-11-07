-- Biomes : chaque anneau a sa propre ambiance (Config.Biomes).
-- Quand le joueur entre dans un anneau : le brouillard, la teinte et la lumière glissent vers ceux
-- du biome, ses particules (3 couches) flottent autour de lui, et un grand titre l'annonce.
-- Sur le vaisseau, on revient à l'éclairage réglé dans Studio (relu au démarrage).
-- Tout est local au client : chaque joueur voit le biome où il se trouve.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local M = Config.Map

local TEXTURES = {
	Glow = UIKit.Art.FxGlow,
	Sparkle = UIKit.Art.FxSparkle,
	Snow = UIKit.Art.FxSnow,
	Shard = UIKit.Art.FxShard,
	Shell = UIKit.Art.FxShell,
}

-- ÉCLAIRAGE DU VAISSEAU -------------------------------------------------------------

-- Le brouillard « classique » (FogStart/FogEnd) permet de cacher précisément tout ce qui est
-- au-delà d'une distance ; il ne marche que sans Atmosphere, qu'on retire donc chez le client.
-- Sans elle, Roblox éclaire la scène avec les couleurs du ciel (chaudes) : on coupe cet apport
-- pour garder le pont blanc tel qu'il est réglé dans Studio.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphere.Parent = nil
end
Lighting.EnvironmentDiffuseScale = 0
Lighting.FogColor = Config.Fog.ShipColor
Lighting.FogEnd = Config.Fog.ShipEnd
Lighting.FogStart = Config.Fog.ShipEnd * Config.Fog.StartRatio

local tint = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
if not tint then
	tint = Instance.new("ColorCorrectionEffect")
	tint.Parent = Lighting
end
local cc = tint :: ColorCorrectionEffect

local ship = {
	Tint = cc.TintColor,
	Saturation = cc.Saturation,
	Brightness = cc.Brightness,
	Outdoor = Lighting.OutdoorAmbient,
}

-- PARTICULES ---------------------------------------------------------------------
-- Un grand volume invisible suit la caméra ; ses émetteurs lâchent les particules dans le monde,
-- elles restent sur place quand on bouge (effet de profondeur).

local volume = Instance.new("Part")
volume.Name = "BiomeParticles"
volume.Anchored = true
volume.CanCollide = false
volume.CanQuery = false
volume.CanTouch = false
volume.Transparency = 1
volume.Size = Vector3.new(160, 70, 160)
volume.Parent = workspace

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

local emitters: { [number]: { ParticleEmitter } } = {}
for i, biome in ipairs(Config.Biomes) do
	emitters[i] = {}
	for _, l in ipairs(biome.Particles) do
		local e = Instance.new("ParticleEmitter")
		e.Texture = TEXTURES[l.Texture]
		e.Color = ColorSequence.new(l.Colors[1], l.Colors[2])
		-- Grandit en apparaissant, puis va vers sa taille de fin
		e.Size = NumberSequence.new({ kp(0, 0), kp(0.15, l.Size[1]), kp(1, l.Size[2]) })
		if l.Texture == "Shard" then
			-- Les éclats de la faille clignotent comme un bug d'écran
			e.Transparency = NumberSequence.new({
				kp(0, 1),
				kp(0.1, 0),
				kp(0.2, 0.85),
				kp(0.3, 0),
				kp(0.5, 0.8),
				kp(0.6, 0.1),
				kp(1, 1),
			})
		else
			e.Transparency = NumberSequence.new({ kp(0, 1), kp(0.15, l.Transparency[1]), kp(1, l.Transparency[2]) })
		end
		e.Rate = l.Rate
		e.Lifetime = NumberRange.new(l.Life[1], l.Life[2])
		e.Speed = NumberRange.new(l.Speed[1], l.Speed[2])
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = l.Drift
		e.LightEmission = l.Light
		e.LightInfluence = 0
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-l.Spin, l.Spin)
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Enabled = false
		e.Parent = volume
		table.insert(emitters[i], e)
	end
end

-- GRAND TITRE ----------------------------------------------------------------------

local titleGui = UIKit.new("ScreenGui", {
	Name = "BiomeTitle",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	IgnoreGuiInset = true,
	Parent = player:WaitForChild("PlayerGui"),
})
local titleHolder = UIKit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.33),
	Size = UDim2.fromOffset(700, 150),
	BackgroundTransparency = 1,
	Parent = titleGui,
})
UIKit.autoScale(titleHolder)
local showing = 0 -- jeton : un nouveau titre remplace le précédent
local currentBox: Frame? = nil

local function showTitle(index: number)
	local biome = Config.Biomes[index]
	showing += 1
	local token = showing
	if currentBox then
		currentBox:Destroy()
	end
	local box = UIKit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = titleHolder })
	currentBox = box
	local color = biome.Clouds[1]
	UIKit.rays(box, { color = color, size = 420, transparency = 0.45, position = UDim2.fromScale(0.5, 0.45) })
	local title = UIKit.text({
		Size = UDim2.new(1, 0, 0, 84),
		Position = UDim2.fromOffset(0, 8),
		Text = "{" .. biome.Icon .. "} " .. biome.Title,
		ZIndex = 3,
		Stroke = 5,
		Parent = box,
	})
	UIKit.shinyText(title, color)
	-- tous les anneaux sont ouverts, sans avertissement : on y va à ses risques
	UIKit.text({
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.fromOffset(0, 96),
		Text = "RING " .. index,
		TextColor3 = Color3.fromRGB(255, 250, 220),
		ZIndex = 3,
		Stroke = 3.5,
		Parent = box,
	})
	UIKit.sparkles(box, { count = 5, size = 34, z = 4 })
	UIKit.popIn(box)
	task.delay(2.6, function()
		if showing ~= token then
			return
		end
		for _, d in ipairs(box:GetDescendants()) do
			if d:IsA("TextLabel") then
				UIKit.tween(d, 0.5, { TextTransparency = 1 })
			elseif d:IsA("UIStroke") then
				UIKit.tween(d, 0.5, { Transparency = 1 })
			elseif d:IsA("ImageLabel") then
				UIKit.tween(d, 0.5, { ImageTransparency = 1 })
			end
		end
		task.wait(0.55)
		if showing == token then
			box:Destroy()
		end
	end)
end

-- CHANGEMENT DE BIOME ------------------------------------------------------------------

-- Anneau où se trouve une position (0 = vaisseau et quai). Chaque anneau s'étend
-- jusqu'au milieu du vide qui le sépare du suivant.
local function zoneAt(pos: Vector3): number
	local r = math.sqrt(pos.X ^ 2 + (pos.Z - M.FrontZ + M.AxisDistance) ^ 2)
	local d = r - M.AxisDistance
	if d < M.FirstRingGap / 2 then
		return 0
	end
	local n = #Config.Rings
	for i = 1, n - 1 do
		if d < Config.RingDistance(i) + Config.RingWidth(i) / 2 + Config.RingGapAfter(i) / 2 then
			return i
		end
	end
	return n
end

local function apply(index: number)
	local biome = Config.Biomes[index]
	local info = TweenInfo.new(Config.BiomeFade, Enum.EasingStyle.Sine)
	-- Brouillard : sa couleur suit le biome, sa distance laisse voir la moitié de l'anneau suivant
	local fogEnd = Config.FogEnd(index)
	TweenService:Create(Lighting, info, {
		FogColor = if biome then biome.Fog else Config.Fog.ShipColor,
		FogEnd = fogEnd,
		FogStart = fogEnd * Config.Fog.StartRatio,
	}):Play()
	TweenService:Create(cc, info, {
		TintColor = if biome then biome.Tint else ship.Tint,
		Saturation = if biome then biome.Saturation else ship.Saturation,
		Brightness = if biome then biome.Brightness or ship.Brightness else ship.Brightness,
	}):Play()
	TweenService:Create(Lighting, info, { OutdoorAmbient = if biome then biome.Outdoor else ship.Outdoor }):Play()
	-- Les particules de l'ancien biome finissent leur vie doucement, celles du nouveau arrivent
	for k, list in pairs(emitters) do
		for _, e in ipairs(list) do
			e.Enabled = k == index
		end
	end
end

local current = 0
local lastCheck = 0
RunService.RenderStepped:Connect(function()
	volume.CFrame = CFrame.new(camera.CFrame.Position)
	local now = os.clock()
	if now - lastCheck < 0.25 then
		return
	end
	lastCheck = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local zone = zoneAt(if root then root.Position else camera.Focus.Position)
	if zone ~= current then
		current = zone
		apply(zone)
		if zone > 0 then
			showTitle(zone)
		end
	end
end)
