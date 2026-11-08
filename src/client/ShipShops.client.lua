-- Stands du vaisseau (Ship.Shops, construits par tools/build-shops.lua) : un peu de vie.
-- - L'icône holographique au-dessus de chaque stand flotte et tourne doucement.
-- - Chaque vendeur astronaute (tag « ShopVendor ») respire en boucle ; quand le joueur arrive à moins
--   de WAVE_RANGE studs, il lui fait coucou (une fois, puis de nouveau s'il revient plus tard).
-- - Marcher sur le tapis (« Mat ») devant un stand ouvre directement son menu, sans touche à appuyer :
--   STORE = boutique Robux, ITEMS = atelier des foreuses, SELL = comptoir de vente. Il faut quitter
--   le tapis pour qu'il puisse se rouvrir (on peut donc fermer la fenêtre en restant dessus).
--   En quittant le tapis, ses fenêtres se ferment toutes seules (SELL : aussi celle des créatures
--   ouverte par SELL PETS).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local player = Players.LocalPlayer
local IDLE = "rbxassetid://507766388" -- animations R15 de base de Roblox
local WAVE = "rbxassetid://507770239"
local WAVE_RANGE = 22
local WAVE_AGAIN = 12 -- secondes avant de pouvoir refaire coucou

type Vendor = { model: Model, root: BasePart, wave: AnimationTrack?, near: boolean, lastWave: number }
local vendors: { [Model]: Vendor } = {}

local function load(hum: Humanoid, id: string, looped: boolean, priority: Enum.AnimationPriority): AnimationTrack?
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(animator.LoadAnimation, animator, anim)
	if not ok then
		return nil
	end
	track.Looped = looped
	track.Priority = priority
	return track
end

local function track(m: Instance)
	if not m:IsA("Model") or vendors[m] then
		return
	end
	local hum = m:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = m:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hum or not root then
		return
	end
	local idle = load(hum, IDLE, true, Enum.AnimationPriority.Idle)
	if idle then
		idle:Play(0.3, 1, 0.9 + math.random() * 0.2)
	end
	vendors[m] = { model = m, root = root, wave = load(hum, WAVE, false, Enum.AnimationPriority.Action), near = false, lastWave = -100 }
end

CollectionService:GetInstanceAddedSignal("ShopVendor"):Connect(track)
CollectionService:GetInstanceRemovedSignal("ShopVendor"):Connect(function(m)
	vendors[m :: Model] = nil
end)
for _, m in ipairs(CollectionService:GetTagged("ShopVendor")) do
	task.spawn(track, m)
end

-- TAPIS DES STANDS : fenêtre ouverte en marchant dessus ----------------------------------------
local OPEN = { Store = "Store", Items = "DrillShop", Sell = "Sell" } -- attribut Shop du stand -> fenêtre
-- fenêtres fermées en quittant le tapis (noms des UIKit.window)
local CLOSE = { Store = { "Store" }, DrillShop = { "DrillShop" }, Sell = { "Sell", "CreaturesWindow" } }
local MAT_MARGIN = 1 -- studs autour du tapis qui comptent encore
local mats: { { part: BasePart, window: string, on: boolean } } = {}
task.spawn(function()
	local shops = workspace:WaitForChild("Ship"):WaitForChild("Shops", 30)
	if not shops then
		return
	end
	for _, stand in ipairs(shops:GetChildren()) do
		local window = OPEN[stand:GetAttribute("Shop") or ""]
		local mat = stand:FindFirstChild("Mat")
		if window and mat and mat:IsA("BasePart") then
			table.insert(mats, { part = mat, window = window, on = false })
		end
	end
end)

local function onMat(mat: BasePart, pos: Vector3): boolean
	local p = mat.CFrame:PointToObjectSpace(pos)
	return math.abs(p.X) <= mat.Size.X / 2 + MAT_MARGIN and math.abs(p.Z) <= mat.Size.Z / 2 + MAT_MARGIN and p.Y > -1 and p.Y < 7
end

-- icônes holographiques
local holos: { { part: BasePart, base: CFrame, phase: number } } = {}
task.spawn(function()
	local shops = workspace:WaitForChild("Ship"):WaitForChild("Shops", 30)
	if not shops then
		return
	end
	local function add(d: Instance)
		if d:IsA("BasePart") and d.Name == "Holo" then
			table.insert(holos, { part = d, base = d.CFrame, phase = #holos * 1.3 })
		end
	end
	for _, d in ipairs(shops:GetDescendants()) do
		add(d)
	end
	shops.DescendantAdded:Connect(add)
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, h in ipairs(holos) do
		if h.part.Parent then
			h.part.CFrame = h.base * CFrame.new(0, math.sin(t * 1.6 + h.phase) * 0.8, 0)
			local bb = h.part:FindFirstChildOfClass("BillboardGui")
			local img = bb and bb:FindFirstChildOfClass("ImageLabel")
			if img then
				img.Rotation = math.sin(t * 1.2 + h.phase) * 8
			end
		end
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	local alive = hum ~= nil and hum.Health > 0
	for _, m in ipairs(mats) do
		local on = alive and onMat(m.part, hrp.Position)
		if on and not m.on then
			Sfx.Play("Open")
			UIKit.Open:Fire(m.window)
		elseif m.on and not on then
			for _, name in ipairs(CLOSE[m.window] or {}) do
				local w = UIKit.Windows[name]
				if w and w.isOpen() then
					w.close()
				end
			end
		end
		m.on = on
	end
	for _, v in pairs(vendors) do
		local near = (v.root.Position - hrp.Position).Magnitude < WAVE_RANGE
		if near and not v.near and t - v.lastWave > WAVE_AGAIN and v.wave then
			v.lastWave = t
			v.wave:Play(0.2)
		end
		v.near = near
	end
end)
