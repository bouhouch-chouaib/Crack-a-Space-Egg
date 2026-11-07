-- Monstres des anneaux 5 à 7, côté joueur (MonsterService décide, ce script montre) :
-- - chaque monstre (dossier dans Workspace.World.Monsters) devient un modèle animé chez ce client,
--   qui glisse vers la position publiée par le serveur, grandit en sortant, plonge en repartant ;
-- - pour le joueur poursuivi : bandeau « ESCAPE » avec le temps restant, bord rouge qui bat plus
--   fort quand il approche, icône de danger au bord de l'écran de son côté, secousses, sons ;
-- - astéroïdes gardés (anneaux 6 et 7) : un petit gardien flotte au-dessus, avec une lueur ;
-- - jauge de bruit : alerte quand elle dépasse Config.Monsters.Noise.Warn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local M = Config.Monsters
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local new = UIKit.new
local world = workspace:WaitForChild("World")
local monstersFolder = world:WaitForChild("Monsters", 30)
local beltFolder = world:WaitForChild("Belt")

local function template(ring: number): Model?
	local kind = M.Kinds[ring]
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Monsters")
	return kind and folder and folder:FindFirstChild(kind.Model) :: Model?
end

-- Copie du modèle à la taille voulue (plus grande dimension = size)
local function makeModel(ring: number, size: number): Model?
	local t = template(ring)
	if not t then
		return nil
	end
	local m = t:Clone()
	local _, s = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * size / math.max(s.X, s.Y, s.Z))
	return m
end

-- INTERFACE DE POURSUITE -----------------------------------------------------------------

local gui = new("ScreenGui", { Name = "MonsterHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
local vignette = new("ImageLabel", {
	Name = "Vignette",
	Image = Config.Cold.Art.Vignette,
	ImageColor3 = Color3.fromRGB(255, 40, 40),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ImageTransparency = 1,
	Parent = gui,
})
local banner = new("Frame", {
	Name = "Banner",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -64), -- en bas, au-dessus de la ligne d'aide (en haut : soute et notifications)
	Size = UDim2.fromOffset(420, 66),
	BackgroundColor3 = Color3.fromRGB(40, 16, 24),
	Parent = gui,
}, { UIKit.corner(), UIKit.stroke(4) })
local title = UIKit.text({ Text = "{Warning} ESCAPE!", Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 5), TextColor3 = Color3.fromRGB(255, 90, 90), Parent = banner })
local barBack = new("Frame", { Size = UDim2.new(1, -40, 0, 14), Position = UDim2.fromOffset(20, 44), BackgroundColor3 = Color3.fromRGB(20, 10, 14), Parent = banner }, { UIKit.corner(), UIKit.stroke(2) })
local barFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 80, 80), Parent = barBack }, { UIKit.corner() })
local arrow = new("ImageLabel", {
	Name = "Arrow",
	Image = UIKit.Art.Warning, -- icône de danger au bord de l'écran, du côté du monstre
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(76, 76),
	Visible = false,
	Parent = gui,
})

-- MONSTRES ---------------------------------------------------------------------------------

type View = {
	folder: Instance,
	model: Model?,
	ring: number,
	size: number,
	shown: Vector3,
	look: Vector3,
	born: number,
	state: string,
	growl: Sfx.Loop?,
	light: PointLight?,
	mine: boolean,
	leftAt: number?,
}
local views: { [Instance]: View } = {}

local function shake(amount: number, duration: number)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < duration do
			local k = 1 - (os.clock() - t0) / duration
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * amount * k, (math.random() - 0.5) * amount * k, 0)
			RunService.RenderStepped:Wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local onState: (Instance) -> ()

local function addView(f: Instance)
	if views[f] then
		return
	end
	local ring = (f:GetAttribute("Kind") or 5) :: number
	local size = (f:GetAttribute("Size") or 24) :: number
	local pos = (f:GetAttribute("Pos") or Vector3.zero) :: Vector3
	local kind = M.Kinds[ring]
	local v: View = {
		folder = f,
		ring = ring,
		size = size,
		shown = pos,
		look = (f:GetAttribute("Look") or Vector3.zAxis) :: Vector3,
		born = os.clock(),
		state = (f:GetAttribute("State") or "Emerge") :: string,
		mine = f:GetAttribute("Target") == player.UserId,
	}
	local m = makeModel(ring, size)
	if m then
		m.Name = "MonsterView"
		local body = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
		if body and kind then
			local light = Instance.new("PointLight")
			light.Color = kind.Color
			light.Range = size * 1.4
			light.Brightness = 2
			light.Shadows = false
			light.Parent = body
			v.light = light
			-- le joueur poursuivi le voit à travers les roches (contour de sa couleur)
			if v.mine then
				local hl = Instance.new("Highlight")
				hl.FillTransparency = 1
				hl.OutlineColor = kind.Color
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = m
			end
			v.growl = Sfx.Loop("MonsterGrowl", body)
		end
		m.Parent = workspace
		v.model = m
	end
	views[f] = v
	f.AttributeChanged:Connect(function(name)
		if name == "State" then
			onState(f)
		end
	end)
	-- réveil : rugissement, éclats de roche, secousse
	Sfx.Play("MonsterRoar", { at = pos, pitch = if ring == 6 then 1.25 elseif ring == 7 then 0.9 else 1 })
	if v.mine then
		Sfx.Play("Warning")
		shake(0.6, 0.6)
		gui.Enabled = true
	end
end

local function removeView(f: Instance)
	local v = views[f]
	if not v then
		return
	end
	views[f] = nil
	if v.growl then
		v.growl:Destroy()
	end
	if v.model then
		v.model:Destroy()
	end
	if v.mine then
		gui.Enabled = false
		arrow.Visible = false
	end
end

function onState(f: Instance)
	local v = views[f]
	if not v then
		return
	end
	local state = (f:GetAttribute("State") or "") :: string
	if state == v.state then
		return
	end
	v.state = state
	if state == "Caught" then
		v.leftAt = os.clock()
		if v.mine then
			Sfx.Play("MonsterCatch")
			Sfx.Play("MonsterRoar", { pitch = 1.1 })
			shake(1.2, 0.7)
			-- écran qui se ferme comme une bouche
			vignette.ImageTransparency = 0
			vignette.ImageColor3 = Color3.new(0, 0, 0)
			TweenService:Create(vignette, TweenInfo.new(1.2), { ImageTransparency = 1 }):Play()
		end
	elseif state == "Leave" then
		v.leftAt = os.clock()
		if v.mine then
			Sfx.Play("Escape")
			gui.Enabled = false
			arrow.Visible = false
		end
	end
end

if monstersFolder then
	for _, f in ipairs(monstersFolder:GetChildren()) do
		addView(f)
	end
	monstersFolder.ChildAdded:Connect(function(f)
		task.wait() -- on laisse arriver tous les attributs
		addView(f)
	end)
	monstersFolder.ChildRemoved:Connect(removeView)
end

-- GARDIENS DES ASTÉROÏDES (anneaux 6 et 7) ------------------------------------------------

type Guard = { model: Model, rock: BasePart, light: PointLight, phase: number }
local guards: { [BasePart]: Guard } = {}

local function scanGuards()
	for _, d in ipairs(beltFolder:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Asteroid" and d:GetAttribute("Guarded") and not guards[d] then
			local ring = (d:GetAttribute("Ring") or 6) :: number
			local m = makeModel(ring, 9)
			if m then
				m.Name = "GuardView"
				local light = Instance.new("PointLight")
				light.Color = M.Kinds[ring] and M.Kinds[ring].Color or Color3.new(1, 1, 1)
				light.Range = 24
				light.Brightness = 2.5
				light.Shadows = false
				light.Parent = d
				m.Parent = workspace
				guards[d] = { model = m, rock = d, light = light, phase = math.random() * 6 }
			end
		end
	end
	for rock, g in pairs(guards) do
		if not rock:IsDescendantOf(workspace) or not rock:GetAttribute("Guarded") then
			g.model:Destroy()
			g.light:Destroy()
			guards[rock] = nil
		end
	end
end
task.spawn(function()
	while true do
		scanGuards()
		task.wait(0.5)
	end
end)

-- BRUIT --------------------------------------------------------------------------------------

local warned = false
player:GetAttributeChangedSignal("Noise"):Connect(function()
	local n = player:GetAttribute("Noise")
	if type(n) ~= "number" then
		warned = false
		return
	end
	if n >= M.Noise.Warn and not warned and not player:GetAttribute("Chased") then
		warned = true
		Sfx.Play("MonsterWarn")
		UIKit.toast("{Warning} Too loud! Something is waking up... glide to stay quiet", "warn")
		shake(0.3, 0.8)
	elseif n < M.Noise.Warn * 0.6 then
		warned = false
	end
end)

-- IMAGE PAR IMAGE ----------------------------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local camPos = camera.CFrame.Position

	for f, v in pairs(views) do
		local target = (f:GetAttribute("Pos") or v.shown) :: Vector3
		local look = (f:GetAttribute("Look") or v.look) :: Vector3
		v.shown = v.shown:Lerp(target, 1 - math.exp(-10 * dt))
		if look.Magnitude > 0.01 then
			v.look = v.look:Lerp(look.Unit, 1 - math.exp(-6 * dt))
		end
		local m = v.model
		if m then
			local age = os.clock() - v.born
			-- taille : il grandit en sortant, rapetisse en repartant
			local k = math.clamp(age / M.Emerge, 0, 1)
			local grow = 0.25 + 0.75 * (1 - (1 - k) ^ 3)
			if v.leftAt then
				grow *= math.clamp(1 - (os.clock() - v.leftAt) / 2.2, 0, 1)
			end
			-- mouvements propres à chaque monstre
			local t = os.clock()
			local wobble: CFrame
			if v.ring == 5 then
				wobble = CFrame.Angles(math.sin(t * 5) * 0.12, math.sin(t * 3) * 0.25, math.sin(t * 4) * 0.15)
			elseif v.ring == 6 then
				wobble = CFrame.new(0, math.sin(t * 2) * 1.2, 0) * CFrame.Angles(0, 0, math.sin(t * 1.5) * 0.1)
			else
				wobble = CFrame.new(0, math.sin(t * 9) * 0.5, 0) * CFrame.Angles(math.sin(t * 2) * 0.08, 0, math.sin(t * 2.5) * 0.12)
			end
			local dir = Vector3.new(v.look.X, v.look.Y * 0.5, v.look.Z)
			if dir.Magnitude < 0.01 then
				dir = Vector3.zAxis
			end
			m:PivotTo(CFrame.lookAt(v.shown, v.shown + dir) * wobble)
			local _, s = m:GetBoundingBox()
			local cur = math.max(s.X, s.Y, s.Z)
			local want = math.max(0.5, v.size * grow)
			if math.abs(cur - want) > 0.05 then
				m:ScaleTo(m:GetScale() * want / cur)
			end
			if v.growl then
				v.growl:Set(if v.state == "Chase" or v.state == "Emerge" then 1 else 0)
			end
		end

		-- interface du joueur poursuivi
		if v.mine and root and v.state ~= "Leave" and v.state ~= "Caught" then
			local endsAt = (f:GetAttribute("EndsAt") or now) :: number
			local startedAt = (f:GetAttribute("StartedAt") or now) :: number
			local left = math.max(0, endsAt - now)
			local total = math.max(1, endsAt - startedAt)
			local name = M.Kinds[v.ring] and string.upper(M.Kinds[v.ring].Name) or "MONSTER"
			UIKit.setIconText(title, ("{Warning} %s! ESCAPE %ds"):format(name, math.ceil(left)))
			barFill.Size = UDim2.fromScale(left / total, 1)
			-- bord rouge : plus il est près, plus ça bat fort
			local dist = (v.shown - root.Position).Magnitude
			local near = math.clamp(1 - (dist - v.size / 2) / 80, 0, 1)
			vignette.ImageColor3 = Color3.fromRGB(255, 40, 40)
			vignette.ImageTransparency = 1 - near * (0.55 + 0.25 * math.sin(os.clock() * (6 + 8 * near)))
			if near > 0.6 and math.random() < dt * 4 then
				shake(0.25 * near, 0.2)
			end
			-- flèche vers le monstre quand il est hors de l'écran
			local sp, onScreen = camera:WorldToViewportPoint(v.shown)
			if onScreen and sp.Z > 0 then
				arrow.Visible = false
			else
				local vp = camera.ViewportSize
				local center = vp / 2
				local d2 = Vector2.new(sp.X, sp.Y) - center
				if sp.Z < 0 then
					d2 = -d2
				end
				if d2.Magnitude < 1 then
					d2 = Vector2.new(0, 1)
				end
				local edge = center + d2.Unit * (math.min(vp.X, vp.Y) / 2 - 70)
				arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
				arrow.Visible = true
			end
		end
	end

	-- gardiens : ils flottent au-dessus de leur astéroïde et regardent la caméra
	for rock, g in pairs(guards) do
		local top = rock.Position + Vector3.new(0, rock.Size.Y / 2 + 6 + math.sin(os.clock() * 2 + g.phase) * 0.8, 0)
		g.model:PivotTo(CFrame.lookAt(top, Vector3.new(camPos.X, top.Y, camPos.Z)))
	end
end)
