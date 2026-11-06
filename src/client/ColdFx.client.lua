-- Effet de gel et de manque d'oxygène hors du couloir (règle : ColdService côté serveur).
-- JOUEUR LOCAL, plein écran :
--   - répit (ColdGrace) : bandeau « Leaving the corridor », compte à rebours, flèche de retour ;
--   - gel (Cold 0..1) : givre qui envahit l'écran depuis les coins (deux couches), vignette bleue qui
--     bat comme un cœur, flocons, image teintée de bleu puis floue, jauge d'O₂ qui se vide, frissons ;
--   - gelé (Frozen) : flash blanc, glace fissurée sur tout l'écran, « FROZEN! », puis la glace éclate.
-- TOUS LES PERSONNAGES : teinte de glace (Highlight), givre qui s'échappe, éclats quand le bloc casse.

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SafeZone = require(ReplicatedStorage.Shared:WaitForChild("SafeZone"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ART = Config.Cold.Art
local ICE = Color3.fromRGB(175, 225, 255)
local new = UIKit.new

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- ÉCRAN ---------------------------------------------------------------------------------------

local gui = new("ScreenGui", {
	Name = "ColdFX",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local function layer(name: string, image: string, z: number): ImageLabel
	return new("ImageLabel", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = image,
		ImageTransparency = 1,
		ZIndex = z,
		Parent = gui,
	})
end

local vignette = layer("Vignette", ART.Vignette, 1)
local frostLight = layer("FrostLight", ART.FrostLight, 2)
local frostHeavy = layer("FrostHeavy", ART.FrostHeavy, 3)
local cracks = layer("Cracks", ART.Cracks, 6)
local flash = new("Frame", {
	Name = "Flash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(230, 245, 255),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 7,
	Parent = gui,
})

-- flocons qui dérivent devant l'écran
local flakes = {}
for i = 1, 26 do
	local f = new("ImageLabel", {
		Name = "Flake",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = UIKit.Art.FxSnow,
		ImageColor3 = Color3.fromRGB(220, 240, 255),
		ImageTransparency = 1,
		ZIndex = 4,
		Parent = gui,
	})
	local size = math.random(14, 46)
	f.Size = UDim2.fromOffset(size, size)
	flakes[i] = { label = f, x = math.random(), y = math.random(), vx = (math.random() - 0.5) * 0.05, vy = 0.03 + math.random() * 0.06, spin = (math.random() - 0.5) * 120 }
end

-- bandeau d'alerte : titre, sous-titre, jauge d'oxygène
local panel = new("Frame", {
	Name = "Warning",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.25),
	Size = UDim2.fromOffset(620, 150),
	BackgroundTransparency = 1,
	ZIndex = 10,
	Visible = false,
	Parent = gui,
})
UIKit.autoScale(panel)
local title = UIKit.text({ Size = UDim2.new(1, 0, 0, 64), Text = "", TextColor3 = Color3.fromRGB(255, 255, 255), Stroke = 5, ZIndex = 11, Parent = panel })
local subtitle = UIKit.text({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 64), Text = "", TextColor3 = Color3.fromRGB(200, 235, 255), Stroke = 3.5, ZIndex = 11, Parent = panel })
local bar = new("Frame", {
	Name = "O2Bar",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 108),
	Size = UDim2.fromOffset(380, 30),
	BackgroundColor3 = Color3.fromRGB(20, 26, 44),
	ZIndex = 11,
	Parent = panel,
}, { UIKit.corner(), UIKit.stroke(3) })
local barFill = new("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = 12,
	Parent = bar,
}, { UIKit.corner() })
local barGrad = UIKit.gradient(Color3.fromRGB(140, 240, 255), Color3.fromRGB(40, 140, 255))
barGrad.Parent = barFill
local barText = UIKit.text({ Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), Text = "O₂", TextColor3 = Color3.new(1, 1, 1), Stroke = 2.5, ZIndex = 13, Parent = bar })

-- flèche vers la zone sûre
local arrow = new("ImageLabel", {
	Name = "Arrow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(120, 120),
	BackgroundTransparency = 1,
	Image = ART.Arrow,
	ZIndex = 9,
	Visible = false,
	Parent = gui,
})

local frozenText = UIKit.text({
	Name = "FrozenText",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromScale(0.6, 0.18),
	Text = "🥶 FROZEN!",
	TextColor3 = Color3.fromRGB(200, 240, 255),
	TextTransparency = 1,
	Stroke = 6,
	ZIndex = 9,
	Parent = gui,
})
local frozenStroke = frozenText:FindFirstChildOfClass("UIStroke")
if frozenStroke then
	frozenStroke.Transparency = 1
end

-- image teintée de bleu et floue (effets locaux, en plus de ceux des biomes)
local tint = new("ColorCorrectionEffect", { Name = "ColdTint", Parent = Lighting })
local blur = new("BlurEffect", { Name = "ColdBlur", Size = 0, Parent = Lighting })

-- ÉTAT DU JOUEUR LOCAL --------------------------------------------------------------------------

local shown = 0 -- jauge affichée (suit la jauge serveur en douceur)
local frozen = false

local function onFrozen(on: boolean)
	if on == frozen then
		return
	end
	frozen = on
	if on then
		-- pris dans la glace : flash, glace fissurée plein écran, titre qui claque
		flash.BackgroundTransparency = 0.05
		tween(flash, 0.7, { BackgroundTransparency = 0.55 })
		cracks.Size = UDim2.fromScale(1.15, 1.15)
		cracks.ImageTransparency = 0
		tween(cracks, 0.25, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Back)
		frozenText.Size = UDim2.fromScale(0.9, 0.27)
		frozenText.TextTransparency = 0
		if frozenStroke then
			frozenStroke.Transparency = 0
		end
		tween(frozenText, 0.35, { Size = UDim2.fromScale(0.6, 0.18) }, Enum.EasingStyle.Back)
		UIKit.shake(frozenText)
		frostHeavy.ImageTransparency = 0
		frostLight.ImageTransparency = 0
	else
		-- la glace éclate
		flash.BackgroundTransparency = 0
		tween(flash, 0.6, { BackgroundTransparency = 1 })
		tween(cracks, 0.5, { Size = UDim2.fromScale(1.6, 1.6), ImageTransparency = 1 })
		tween(frozenText, 0.5, { TextTransparency = 1 })
		if frozenStroke then
			tween(frozenStroke, 0.5, { Transparency = 1 })
		end
	end
end

local function watchCharacter(character: Model)
	onFrozen(character:GetAttribute("Frozen") == true)
	character:GetAttributeChangedSignal("Frozen"):Connect(function()
		onFrozen(character:GetAttribute("Frozen") == true)
	end)
end
if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

RunService.RenderStepped:Connect(function(dt)
	local target = (player:GetAttribute("Cold") or 0) :: number
	local grace = player:GetAttribute("ColdGrace") :: number?
	shown += (target - shown) * math.min(1, dt * (if target > shown then 4 else 2.5))
	if shown < 0.001 then
		shown = 0
	end
	local c = if frozen then 1 else shown
	local now = os.clock()

	-- givre : la couche légère gagne depuis les coins, l'épaisse arrive dans la 2e moitié
	if not frozen then
		frostLight.ImageTransparency = 1 - math.clamp(c * 1.8, 0, 1)
		frostLight.Size = UDim2.fromScale(1 + (1 - c) * 0.45, 1 + (1 - c) * 0.45)
		local h = math.clamp((c - 0.4) / 0.6, 0, 1)
		frostHeavy.ImageTransparency = 1 - h
		frostHeavy.Size = UDim2.fromScale(1 + (1 - h) * 0.35, 1 + (1 - h) * 0.35)
	end
	-- vignette bleue qui bat comme un cœur, plus vite quand on gèle
	local beat = 0.5 + 0.5 * math.sin(now * math.pi * 2 * (1 + c * 1.6))
	local hasGrace = grace ~= nil
	local danger = math.max(c, if hasGrace then 0.25 else 0)
	vignette.ImageTransparency = 1 - math.clamp(danger * (0.75 + 0.25 * beat), 0, 0.95)
	-- flocons
	for _, f in ipairs(flakes) do
		f.y += f.vy * dt
		f.x += f.vx * dt
		if f.y > 1.05 then
			f.y, f.x = -0.05, math.random()
		end
		f.label.Position = UDim2.fromScale(f.x, f.y)
		f.label.Rotation += f.spin * dt
		f.label.ImageTransparency = 1 - math.clamp(c * 1.2, 0, 0.85)
	end
	-- image bleue et floue
	tint.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(165, 205, 255), c)
	tint.Saturation = -0.45 * c
	tint.Brightness = 0.06 * c
	tint.Contrast = 0.1 * c
	blur.Size = if frozen then 18 else 12 * c * c
	-- frissons de la caméra
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		local amp = if c > 0.45 and not frozen then (c - 0.45) * 0.35 else 0
		hum.CameraOffset = Vector3.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
	end

	-- bandeau d'alerte et flèche de retour
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local alert = not frozen and (hasGrace or c > 0.01)
	panel.Visible = alert
	if alert then
		if c > 0.01 then
			title.Text = "🥶 FREEZING! NO OXYGEN"
			title.TextColor3 = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255, 90, 90), beat * c)
			subtitle.Text = "Get back to the corridor!"
		else
			title.Text = "⚠️ LEAVING THE CORRIDOR"
			title.TextColor3 = Color3.fromRGB(255, 230, 120)
			subtitle.Text = ("Freezing in %.1f s"):format(grace or 0)
		end
		local o2 = 1 - c
		barFill.Size = UDim2.fromScale(math.max(o2, 0.02), 1)
		barGrad.Color = ColorSequence.new(Color3.fromRGB(140, 240, 255):Lerp(Color3.fromRGB(255, 120, 120), c), Color3.fromRGB(40, 140, 255):Lerp(Color3.fromRGB(220, 40, 60), c))
		barText.Text = ("O₂ %d%%"):format(math.floor(o2 * 100 + 0.5))
		panel.Position = UDim2.new(0.5, (math.random() - 0.5) * 6 * c, 0.25, 0)
	end
	arrow.Visible = alert and hrp ~= nil
	if alert and hrp then
		local safe = SafeZone.Nearest(hrp.Position)
		local view = camera.ViewportSize
		local p = camera:WorldToViewportPoint(safe)
		local dir = Vector2.new(p.X - view.X / 2, p.Y - view.Y / 2)
		if p.Z < 0 then
			dir = -dir -- derrière la caméra
		end
		if dir.Magnitude < 1 then
			dir = Vector2.new(0, 1)
		end
		dir = dir.Unit
		local radius = math.min(view.X, view.Y) * 0.32
		local bob = 1 + 0.08 * math.sin(now * 8)
		arrow.Position = UDim2.fromOffset(view.X / 2 + dir.X * radius * bob, view.Y / 2 + dir.Y * radius * bob)
		arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
	end
end)

-- TOUS LES PERSONNAGES : teinte de glace, givre, éclats --------------------------------------------

local function shatterAt(pos: Vector3)
	for _ = 1, 14 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Ice
		p.Color = ICE
		p.Transparency = 0.2
		local s = 0.4 + math.random() * 1.1
		p.Size = Vector3.new(s, s * 1.6, s)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9, math.random() - 0.5).Unit
		tween(p, 0.9, {
			CFrame = CFrame.new(pos + dir * (5 + math.random() * 6) + Vector3.new(0, -2, 0)) * CFrame.Angles(math.random() * 9, math.random() * 9, math.random() * 9),
			Transparency = 1,
			Size = p.Size * 0.4,
		})
		Debris:AddItem(p, 1)
	end
end

local function setupCharacter(character: Model)
	local hl: Highlight? = nil
	local emitter: ParticleEmitter? = nil
	local function update()
		local c = (character:GetAttribute("Cold") or 0) :: number
		if character:GetAttribute("Frozen") == true then
			c = 1
		end
		if c > 0.01 and not hl then
			hl = new("Highlight", {
				Name = "ColdHighlight",
				FillColor = ICE,
				OutlineColor = Color3.fromRGB(230, 250, 255),
				DepthMode = Enum.HighlightDepthMode.Occluded,
				Parent = character,
			})
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				emitter = new("ParticleEmitter", {
					Name = "ColdMist",
					Texture = UIKit.Art.FxSnow,
					Color = ColorSequence.new(Color3.fromRGB(220, 240, 255)),
					LightEmission = 0.6,
					Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.05) }),
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
					Lifetime = NumberRange.new(0.8, 1.4),
					Speed = NumberRange.new(1, 3),
					SpreadAngle = Vector2.new(180, 180),
					Rotation = NumberRange.new(0, 360),
					RotSpeed = NumberRange.new(-90, 90),
					Rate = 0,
					Parent = hrp,
				})
			end
		end
		if hl then
			hl.FillTransparency = 1 - 0.6 * c
			hl.OutlineTransparency = 1 - 0.8 * c
		end
		if emitter then
			emitter.Rate = 30 * c
		end
	end
	character:GetAttributeChangedSignal("Cold"):Connect(update)
	character:GetAttributeChangedSignal("Frozen"):Connect(update)
	character:GetAttributeChangedSignal("FrozenAt"):Connect(function()
		local at = character:GetAttribute("FrozenAt")
		if typeof(at) == "Vector3" then
			shatterAt(at)
		end
	end)
	update()
end

local function watchPlayer(p: Player)
	if p.Character then
		setupCharacter(p.Character)
	end
	p.CharacterAdded:Connect(setupCharacter)
end
for _, p in ipairs(Players:GetPlayers()) do
	watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)
