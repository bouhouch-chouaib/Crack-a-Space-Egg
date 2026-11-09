-- Objets (Config.Gear, onglet GEAR du stand ITEMS, barre de boutons GearBar.client).
-- Batte en $ (3 paliers, perdue à la Supernova) ; tapis, bottes et grappin en passes Robux (BoostService) ;
-- bouclier en produit Robux (consommé par MonsterService.Caught).
-- Remotes.Gear (RemoteEvent) :
--   client -> serveur : ("buyBat"), ("swing"), ("carpet", bool), ("boots", bool), ("hook", Vector3), ("hookEnd")
--   serveur -> client : ("pushed", Vector3) coup de batte reçu (appliqué par Jetpack.client)
-- Publié sur le joueur : Bat, Shields (GameService.Sync).
-- Sur le personnage : BatSwing (horodatage du coup), Carpet, Boots, HookTo (lus par GearBar.client et Jetpack.client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SafeZone = require(ReplicatedStorage.Shared.SafeZone)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local BoostService = require(script.Parent.BoostService)
local MonsterService = require(script.Parent.MonsterService)
local Tracking = require(script.Parent.Tracking)

local G = Config.Gear
local Remotes = ReplicatedStorage.Remotes
local GearService = {}

local STUDS = "rbxassetid://99589690361139"
local CARPET_CHECK = 0.25
local CYLINDER, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

local lastSwing: { [Player]: number } = {}
local lastHook: { [Player]: number } = {}
local immuneUntil: { [Player]: number } = {} -- un joueur repoussé ne peut pas être refrappé tout de suite

local function studs(p: BasePart, tile: number)
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local t = Instance.new("Texture")
		t.Name = "Studs"
		t.Texture = STUDS
		t.Face = face
		t.StudsPerTileU = tile
		t.StudsPerTileV = tile
		t.ZIndex = 2
		t.Parent = p
	end
end

local function piece(parent: Instance, name: string, size: Vector3, color: Color3, shape: Enum.PartType?): Part
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
	p.Parent = parent
	return p
end

local function weldTo(p: BasePart, bone: BasePart, offset: CFrame, name: string?)
	p.CFrame = bone.CFrame * offset
	local w = Instance.new("Weld")
	w.Name = name or "Weld"
	w.Part0 = bone
	w.Part1 = p
	w.C0 = offset
	w.Parent = p
end

local function clear(character: Model, name: string)
	local old = character:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

-- BATTE --------------------------------------------------------------------------------------------

-- Portée à la hanche ; au moment du coup, GearBar.client la met dans la main le temps de l'animation
local function equipBat(player: Player)
	local d = DataService.Get(player)
	local character = player.Character
	local hip = character and (character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not d or not character or not hip then
		return
	end
	clear(character, "EquippedBat")
	local tier = d.bat or 0
	if tier <= 0 then
		return
	end
	local b = Config.Bats[math.min(tier, #Config.Bats)]
	local model = Instance.new("Model")
	model.Name = "EquippedBat"
	local handle = piece(model, "Handle", Vector3.new(1.7, 0.24, 0.24), b.Grip, CYLINDER)
	weldTo(handle, hip, G.BatHip, "BatWeld")
	local barrel = piece(model, "Barrel", Vector3.new(2, 0.56, 0.56), b.Color, CYLINDER)
	studs(barrel, 1)
	weldTo(barrel, handle, CFrame.new(1.8, 0, 0))
	weldTo(piece(model, "Cap", Vector3.new(0.56, 0.56, 0.56), b.Color, BALL), handle, CFrame.new(2.8, 0, 0))
	weldTo(piece(model, "Knob", Vector3.new(0.34, 0.34, 0.34), b.Grip, BALL), handle, CFrame.new(-0.85, 0, 0))
	for i = 1, b.Bands do
		weldTo(piece(model, "Band", Vector3.new(0.14, 0.62, 0.62), b.Accent, CYLINDER), handle, CFrame.new(1.2 + (i - 1) * 0.5, 0, 0))
	end
	model.PrimaryPart = handle
	model.Parent = character
end

local function buyBat(player: Player)
	local d = DataService.Get(player)
	if not d then
		return
	end
	local tier = (d.bat or 0) + 1
	local bat = Config.Bats[tier]
	if not bat then
		return
	end
	if d.credits < bat.Cost then
		GameService.Notice(player, "Not enough $", "warn")
		return
	end
	d.credits -= bat.Cost
	d.bat = tier
	Tracking.Funnel(player, "Bats", tier, bat.Name)
	GameService.Sync(player)
	equipBat(player)
	GameService.Notice(player, bat.Name .. " equipped!", "good")
end

local function swing(player: Player)
	local d = DataService.Get(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not d or not character or not hrp or (d.bat or 0) <= 0 then
		return
	end
	local t = os.clock()
	if t - (lastSwing[player] or 0) < G.BatCooldown then
		return
	end
	lastSwing[player] = t
	local bat = Config.Bats[math.min(d.bat, #Config.Bats)]
	character:SetAttribute("BatSwing", t)
	-- monstre à portée : assommé
	local name = MonsterService.Stun(hrp.Position, G.BatRange, bat.Stun)
	if name then
		GameService.Notice(player, ("{Star} %s stunned for %ds!"):format(name, bat.Stun), "good")
	end
	-- autres joueurs : repoussés, jamais sur le vaisseau, et sans leur faire perdre quoi que ce soit
	if MonsterService.InShip(hrp.Position) then
		return
	end
	for _, other in ipairs(Players:GetPlayers()) do
		local oc = other ~= player and other.Character
		local ohrp = oc and oc:FindFirstChild("HumanoidRootPart") :: BasePart?
		if ohrp and not MonsterService.InShip(ohrp.Position) and (immuneUntil[other] or 0) < t then
			local delta = ohrp.Position - hrp.Position
			if delta.Magnitude <= G.BatRange then
				immuneUntil[other] = t + G.PushImmune
				local flat = Vector3.new(delta.X, 0, delta.Z)
				local dir = if flat.Magnitude > 0.1 then flat.Unit else hrp.CFrame.LookVector
				Remotes.Gear:FireClient(other, "pushed", dir * bat.Push + Vector3.new(0, G.PushUp, 0), player.DisplayName)
			end
		end
	end
end

-- TAPIS --------------------------------------------------------------------------------------------

local function buildCarpet(character: Model, hrp: BasePart)
	clear(character, "EquippedCarpet")
	local model = Instance.new("Model")
	model.Name = "EquippedCarpet"
	local c = G.Carpet
	local at = CFrame.new(0, c.Below, 0)
	local base = piece(model, "Border", Vector3.new(c.Width + 0.5, 0.2, c.Length + 0.5), c.Accent)
	studs(base, 1)
	weldTo(base, hrp, at)
	local main = piece(model, "Main", Vector3.new(c.Width, 0.26, c.Length), c.Color)
	studs(main, 1)
	weldTo(main, hrp, at)
	local star = piece(model, "Star", Vector3.new(1.5, 0.3, 1.5), c.Accent)
	weldTo(star, hrp, at * CFrame.Angles(0, math.rad(45), 0))
	for _, z in ipairs({ -1, 1 }) do
		for i = -2, 2 do
			local tassel = piece(model, "Tassel", Vector3.new(0.34, 0.14, 0.55), c.Accent)
			weldTo(tassel, hrp, at * CFrame.new(i * (c.Width / 5), 0, z * (c.Length / 2 + 0.5)))
		end
	end
	model.Parent = character
end

local function setCarpet(player: Player, on: boolean)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hrp then
		return
	end
	if on then
		local _, dist = SafeZone.Nearest(hrp.Position)
		if not BoostService.HasPass(player, "Carpet") or dist > 0 then
			return
		end
		buildCarpet(character, hrp)
		character:SetAttribute("Carpet", true)
	else
		clear(character, "EquippedCarpet")
		character:SetAttribute("Carpet", nil)
	end
end

-- BOTTES -------------------------------------------------------------------------------------------

local function setBoots(player: Player, on: boolean)
	local character = player.Character
	if not character then
		return
	end
	clear(character, "EquippedBoots")
	character:SetAttribute("Boots", nil)
	if not on or not BoostService.HasPass(player, "Boots") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "EquippedBoots"
	local c = G.Boots
	for _, side in ipairs({ "Left", "Right" }) do
		local foot = character:FindFirstChild(side .. "Foot") :: BasePart?
		local leg = character:FindFirstChild(side .. "LowerLeg") :: BasePart?
		if foot then
			local boot = piece(model, "Boot", foot.Size + Vector3.new(0.22, 0.2, 0.3), c.Color)
			studs(boot, 1)
			weldTo(boot, foot, CFrame.new())
			weldTo(piece(model, "Sole", Vector3.new(foot.Size.X + 0.32, 0.18, foot.Size.Z + 0.4), c.Sole), foot, CFrame.new(0, -foot.Size.Y / 2 - 0.08, 0))
		end
		if leg then
			local cuff = piece(model, "Cuff", Vector3.new(leg.Size.X + 0.2, leg.Size.Y * 0.4, leg.Size.Z + 0.2), c.Strap)
			studs(cuff, 1)
			weldTo(cuff, leg, CFrame.new(0, -leg.Size.Y * 0.25, 0))
		end
	end
	model.Parent = character
	character:SetAttribute("Boots", true)
end

-- GRAPPIN : le mouvement est fait par le client, le serveur publie juste où va le câble pour les autres ----
local function hook(player: Player, at: any)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hrp or typeof(at) ~= "Vector3" or not BoostService.HasPass(player, "Hook") then
		return
	end
	local t = os.clock()
	if t - (lastHook[player] or 0) < G.Hook.Cooldown - 0.2 or (at - hrp.Position).Magnitude > G.Hook.Range + 30 then
		return
	end
	lastHook[player] = t
	character:SetAttribute("HookTo", at)
	task.delay(G.Hook.Range / G.Hook.Speed + 1, function()
		if character.Parent and character:GetAttribute("HookTo") == at then
			character:SetAttribute("HookTo", nil)
		end
	end)
end

-- Bouclier acheté en Robux (MonetizationService) : un de plus, gardé après une Supernova
function GearService.GrantShield(player: Player): boolean
	local d = DataService.Get(player)
	if not d then
		return false
	end
	d.shields = (d.shields or 0) + 1
	GameService.Sync(player)
	GameService.Notice(player, ("{Star} Monster Shield ready! You have %d"):format(d.shields), "good")
	return true
end

function GearService.Start()
	Remotes.Gear.OnServerEvent:Connect(function(player: Player, action: any, arg: any)
		if action == "buyBat" then
			buyBat(player)
		elseif action == "swing" then
			swing(player)
		elseif action == "carpet" then
			setCarpet(player, arg == true)
		elseif action == "boots" then
			setBoots(player, arg == true)
		elseif action == "hook" then
			hook(player, arg)
		elseif action == "hookEnd" then
			local character = player.Character
			if character then
				character:SetAttribute("HookTo", nil)
			end
		end
	end)
	local function added(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 5)
			character:WaitForChild(if character:FindFirstChild("Torso") then "Torso" else "LowerTorso", 5)
			equipBat(player)
		end)
		if player.Character then
			task.spawn(equipBat, player)
		end
	end
	Players.PlayerAdded:Connect(added)
	for _, player in ipairs(Players:GetPlayers()) do
		added(player)
	end
	DataService.Loaded:Connect(equipBat) -- la partie arrive souvent après le personnage
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player], lastHook[player], immuneUntil[player] = nil, nil, nil
	end)
	-- Studio seulement : (joueur) donne un bouclier, pour le tester sans acheter
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "GearDebug"
		bf.OnInvoke = GearService.GrantShield
		bf.Parent = game:GetService("ServerStorage")
	end
	-- le tapis ne vole que dans le couloir et sur le vaisseau
	task.spawn(function()
		while true do
			task.wait(CARPET_CHECK)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and hrp and character:GetAttribute("Carpet") then
					local _, dist = SafeZone.Nearest(hrp.Position)
					if dist > 0 then
						setCarpet(player, false)
						GameService.Notice(player, "{Warning} The carpet only flies inside the corridor!", "warn")
					end
				end
			end
		end
	end)
end

return GearService
