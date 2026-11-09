-- Combinaisons (Config.Suits) : on tient plus longtemps hors du couloir et on a plus d'oxygène (ColdService lit d.suit).
-- Achetées une par une, en $ ou en Robux (MonetizationService) ; une combinaison payée en Robux reste après une Supernova.
-- Porter une combinaison (à partir de la deuxième) met un casque et un plastron sur l'avatar, visibles par tous.
-- Remotes.BuySuit (RemoteEvent) : achète la combinaison suivante. Publié sur le joueur : Suit (palier, GameService.Sync).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Tracking = require(script.Parent.Tracking)

local Remotes = ReplicatedStorage.Remotes
local SuitService = {}

local STUDS = "rbxassetid://99589690361139"
local SHOULDERS_FROM = 5 -- palier à partir duquel le plastron a des épaulettes
local ANTENNA_FROM = 6 -- palier à partir duquel le casque a une antenne

local function studs(p: BasePart)
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local t = Instance.new("Texture")
		t.Name = "Studs"
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = 1
		t.StudsPerTileV = 1
		t.ZIndex = 2
		t.Parent = p
	end
end

local BALL, CYLINDER = Enum.PartType.Ball, Enum.PartType.Cylinder
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- un cylindre est couché sur X : on le met debout

local function piece(parent: Instance, bone: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, withStuds: boolean?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = bone.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = bone
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	if withStuds ~= false then
		studs(p)
	end
	p.Parent = parent
	return p
end

-- Casque rond : une boule, deux boules plus petites poussées vers l'avant font le rebord et la visière bombée
local function helmet(model: Model, head: BasePart, s, tier: number)
	local r = math.max(head.Size.X, head.Size.Y, head.Size.Z) * 0.88
	local y = 0.16
	local function ball(d: number): Vector3
		return Vector3.new(d, d, d)
	end
	piece(model, head, "Shell", ball(2 * r), CFrame.new(0, y, 0), s.Color, true, BALL)
	piece(model, head, "Stripe", Vector3.new(0.3, 2 * r + 0.08, 2 * r + 0.08), CFrame.new(0, y, 0), s.Accent, true, CYLINDER)
	piece(model, head, "VisorRim", ball(1.62 * r), CFrame.new(0, y, -0.36 * r), s.Accent, false, BALL)
	local visor = piece(model, head, "Visor", ball(1.46 * r), CFrame.new(0, y, -0.46 * r), s.Visor, false, BALL)
	visor.Reflectance = 0.12
	-- petit reflet de dessin animé sur la visière
	piece(model, head, "Shine", ball(0.26 * r), CFrame.new(-0.3 * r, y + 0.36 * r, -1.08 * r), Color3.new(1, 1, 1), false, BALL)
	for _, side in ipairs({ -1, 1 }) do
		piece(model, head, "Ear", Vector3.new(0.24, 0.95 * r, 0.95 * r), CFrame.new(side * (r + 0.05), y, 0), s.Accent, true, CYLINDER)
	end
	piece(model, head, "Neck", Vector3.new(0.22, 1.5 * r, 1.5 * r), CFrame.new(0, -0.66, 0) * UPRIGHT, s.Accent, true, CYLINDER)
	if tier >= ANTENNA_FROM then
		local x, z = 0.62 * r, 0.2 * r
		piece(model, head, "Antenna", Vector3.new(0.1, 1.1, 0.1), CFrame.new(x, y + 0.78 * r + 0.45, z), s.Accent, false)
		piece(model, head, "AntennaTip", ball(0.3), CFrame.new(x, y + 0.78 * r + 1.02, z), s.Visor, false, BALL)
	end
end

local function plate(model: Model, torso: BasePart, s, tier: number)
	local w, h, d = torso.Size.X + 0.2, torso.Size.Y + 0.08, torso.Size.Z + 0.26
	piece(model, torso, "Plate", Vector3.new(w, h, d), CFrame.new(), s.Color)
	piece(model, torso, "Panel", Vector3.new(w * 0.52, h * 0.46, 0.12), CFrame.new(0, h * 0.08, -(d / 2 + 0.05)), s.Accent)
	piece(model, torso, "Light", Vector3.new(w * 0.3, h * 0.14, 0.08), CFrame.new(0, h * 0.08, -(d / 2 + 0.13)), s.Visor, false)
	if tier >= SHOULDERS_FROM then
		for _, side in ipairs({ -1, 1 }) do
			local at = CFrame.new(side * (w / 2 + 0.22), h / 2 - 0.08, 0)
			piece(model, torso, "Shoulder", Vector3.new(0.98, 0.98, 0.98), at, s.Color, true, BALL)
			piece(model, torso, "ShoulderTrim", Vector3.new(0.14, 1.04, 1.04), at * UPRIGHT, s.Accent, false, CYLINDER)
		end
	end
end

-- Le casque couvre la tête : les chapeaux et cheveux dépasseraient, on les cache
local function hideHeadwear(character: Model)
	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChild("Handle") :: BasePart?
			local weld = handle and handle:FindFirstChild("AccessoryWeld") :: Weld?
			if handle and weld and (weld.Part0 and weld.Part0.Name == "Head" or weld.Part1 and weld.Part1.Name == "Head") then
				handle.Transparency = 1
			end
		end
	end
end

local function equip(player: Player)
	local d = DataService.Get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not d or not character or not head or not torso then
		return
	end
	local old = character:FindFirstChild("EquippedSuit")
	if old then
		old:Destroy()
	end
	local tier = math.clamp(d.suit or 1, 1, #Config.Suits)
	if tier <= 1 then
		return -- la combinaison de départ, c'est l'avatar tel quel
	end
	local model = Instance.new("Model")
	model.Name = "EquippedSuit"
	local s = Config.Suits[tier]
	helmet(model, head, s, tier)
	plate(model, torso, s, tier)
	model.Parent = character
	hideHeadwear(character)
end

-- Personnage neuf : on attend son apparence (taille de la tête, accessoires), sans jamais bloquer longtemps
local function onCharacter(player: Player, character: Model)
	local started = os.clock()
	while character.Parent and not player:HasAppearanceLoaded() and os.clock() - started < 4 do
		task.wait(0.1)
	end
	character:WaitForChild("Head", 5)
	if character.Parent then
		equip(player)
	end
	character.ChildAdded:Connect(function(child)
		if child:IsA("Accessory") then
			task.delay(0.3, function()
				if character:FindFirstChild("EquippedSuit") then
					hideHeadwear(character)
				end
			end)
		end
	end)
end

local function buy(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	local tier = (d.suit or 1) + 1
	local nextSuit = Config.Suits[tier]
	if not nextSuit then
		return
	end
	if d.credits < nextSuit.Cost then
		GameService.Notice(player, "Not enough $", "warn")
		return
	end
	d.credits -= nextSuit.Cost
	d.suit = tier
	Tracking.Funnel(player, "Suits", tier, nextSuit.Name)
	GameService.Sync(player)
	equip(player)
	GameService.Notice(player, nextSuit.Name .. " equipped!", "good")
end

-- Combinaison achetée en Robux (MonetizationService). On ne redescend jamais.
function SuitService.Grant(player: Player, tier: number): boolean
	local d = DataService.Get(player)
	if not d or not Config.Suits[tier] then
		return false
	end
	d.paidSuit = math.max(d.paidSuit or 1, tier) -- gardée après une Supernova
	if tier > (d.suit or 1) then
		d.suit = tier
		Tracking.Funnel(player, "Suits", tier, Config.Suits[tier].Name)
		GameService.Sync(player)
		equip(player)
		GameService.Notice(player, Config.Suits[tier].Name .. " equipped!", "good")
	end
	return true
end

function SuitService.Start()
	Remotes.BuySuit.OnServerEvent:Connect(buy)
	local function added(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(added)
	for _, player in ipairs(Players:GetPlayers()) do
		added(player)
	end
	-- la partie arrive souvent après le personnage
	DataService.Loaded:Connect(equip)
end

return SuitService
