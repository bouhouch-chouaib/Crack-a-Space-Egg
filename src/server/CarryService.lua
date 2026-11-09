-- Roche portée à deux mains : tant que la soute contient quelque chose, le joueur tient devant lui
-- une roche de l'anneau d'origine, à ramener à la machine de sa base. Elle remplace les messages :
-- on voit tout de suite qu'on porte déjà quelque chose. Visible par tous ; Hatchery.client lève les bras.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataService = require(script.Parent.DataService)

local CarryService = {}

local carried: { [Player]: Model } = {}

local function rockTemplate(ring: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Asteroids")
	local set = folder and folder:FindFirstChild("Ring" .. ring)
	local template = set and (if set:IsA("Folder") then set:FindFirstChild("V1") else set)
	return if template and template:IsA("Model") then template else nil
end

local function makeRock(character: Model, ring: number, key: string): Model?
	local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	local template = rockTemplate(ring)
	if not torso or not template then
		return nil
	end
	local h = Config.CarriedRock.Size
	local m = template:Clone()
	local size = m:GetExtentsSize()
	m:ScaleTo(m:GetScale() * h / math.max(size.X, size.Y, size.Z))
	-- Pièce invisible au centre de la roche : c'est elle qu'on soude et que les bras visent
	local cf = m:GetBoundingBox()
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.one * 0.2
	core.Transparency = 1
	core.CFrame = CFrame.new(cf.Position)
	core.Anchored = true
	core.Parent = m
	m.PrimaryPart = core
	m:PivotTo(torso.CFrame * CFrame.new(0, 0.15, -(1 + h * 0.35)))
	for _, d in ipairs(m:GetDescendants()) do
		for _, tag in ipairs(CollectionService:GetTags(d)) do
			CollectionService:RemoveTag(d, tag)
		end
		if d:IsA("LuaSourceContainer") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui") then
			d:Destroy()
		elseif d:IsA("Texture") and d.Name == "Studs" then
			d.StudsPerTileU = Config.CarriedRock.StudTile
			d.StudsPerTileV = Config.CarriedRock.StudTile
		elseif d:IsA("BasePart") then
			-- le nom « Asteroid » est celui des roches à forer
			d.Name = if d == core then "Core" else "Rock"
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			if d ~= core then
				local w = Instance.new("WeldConstraint")
				w.Part0 = core
				w.Part1 = d
				w.Parent = d
				d.Anchored = false
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "HoldWeld"
	weld.Part0 = torso
	weld.Part1 = core
	weld.C0 = CFrame.new(0, 0.15, -(1 + h * 0.35))
	weld.Parent = core
	core.Anchored = false
	m.Name = "CarriedRock"
	m:SetAttribute("BodyHeight", h)
	m:SetAttribute("Key", key)
	m.Parent = character
	return m
end

-- La roche à tenir : la première de la soute, sauf si les mains tiennent déjà un œuf dérroché
function CarryService.Update(player: Player)
	local d = DataService.Get(player)
	local character = player.Character
	local first = d and d.cargo[1]
	local ring = if type(first) == "table" then first.ring else first
	local key = if ring and not player:GetAttribute("HeldEgg") then tostring(ring) else nil
	local cur = carried[player]
	if cur and cur.Parent and character and cur:IsDescendantOf(character) and cur:GetAttribute("Key") == key then
		return
	end
	if cur then
		cur:Destroy()
		carried[player] = nil
	end
	if key and character then
		local made = makeRock(character, ring, key)
		if made then
			carried[player] = made
		end
	end
end

local function watch(player: Player)
	local count = 0
	player:GetAttributeChangedSignal("Cargo"):Connect(function()
		local n = player:GetAttribute("Cargo") or 0
		local more = n > count
		count = n
		if more then
			-- elle arrive dans les mains quand l'œuf qui jaillit de la roche atteint le joueur
			task.delay(Config.CarriedRock.HandDelay, CarryService.Update, player)
		else
			CarryService.Update(player)
		end
	end)
	player:GetAttributeChangedSignal("HeldEgg"):Connect(function()
		CarryService.Update(player)
	end)
	local function onCharacter(character: Model)
		character:WaitForChild("UpperTorso", 5)
		CarryService.Update(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

function CarryService.Start()
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		carried[player] = nil
	end)
end

return CarryService
