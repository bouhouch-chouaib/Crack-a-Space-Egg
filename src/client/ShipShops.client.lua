-- Stands du vaisseau (Ship.Shops, construits par tools/build-shops.lua) : un peu de vie.
-- - L'icône holographique au-dessus de chaque stand flotte et tourne doucement.
-- - Chaque vendeur astronaute (tag « ShopVendor ») respire en boucle ; quand le joueur arrive à moins
--   de WAVE_RANGE studs, il lui fait coucou (une fois, puis de nouveau s'il revient plus tard).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
	for _, v in pairs(vendors) do
		local near = (v.root.Position - hrp.Position).Magnitude < WAVE_RANGE
		if near and not v.near and t - v.lastWave > WAVE_AGAIN and v.wave then
			v.lastWave = t
			v.wave:Play(0.2)
		end
		v.near = near
	end
end)
