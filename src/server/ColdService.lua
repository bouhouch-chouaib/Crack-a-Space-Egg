-- Gel hors du couloir : hors de la zone où l'on respire (SafeZone : couloir + vaisseau), le froid
-- et le manque d'oxygène gagnent. Après Config.Cold.Grace secondes (aucun répit si on est trop loin),
-- la jauge « Cold » monte de 0 à 1. À 1, le joueur est pris dans un bloc de glace, puis renvoyé à sa
-- base en perdant les œufs de sa soute (comme une chute dans le Vide).
-- Le serveur décide ; il publie sur le joueur :
--   Cold (0..1)       jauge de gel (lue par ColdFx.client pour l'effet plein écran)
--   ColdGrace (s)     secondes de répit restantes quand on est sorti (nil dans la zone)
-- et sur le personnage : Cold (teinte de glace vue par tous), Frozen, FrozenAt (éclats).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SafeZone = require(ReplicatedStorage.Shared.SafeZone)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Bases = require(script.Parent.Bases)

local C = Config.Cold
local STEP = 0.2
local ICE = Color3.fromRGB(175, 225, 255)

local ColdService = {}

type State = { outside: number, cold: number, frozen: boolean }
local states: { [Player]: State } = {}

local function round(x: number): number
	return math.floor(x * 100 + 0.5) / 100
end

-- Bloc de glace autour du personnage, avec des éclats qui dépassent
local function iceBlock(character: Model): Model
	local cf, size = character:GetBoundingBox()
	local m = Instance.new("Model")
	m.Name = "IceBlock"
	local function ice(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Ice
		p.Color = ICE
		p.Transparency = 0.18
		p.Reflectance = 0.15
		for k, v in pairs(props) do
			(p :: any)[k] = v
		end
		p.Parent = m
		return p
	end
	local core = ice({ Name = "Core", Size = size * Vector3.new(1.35, 1.12, 1.35) + Vector3.new(0.6, 0.4, 0.6), CFrame = cf * CFrame.Angles(0, math.rad(8), 0) })
	local rng = Random.new()
	-- éclats de glace qui jaillissent du bloc, penchés vers l'extérieur
	for _ = 1, 12 do
		local s = rng:NextNumber(1.0, 2.1)
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1)).Unit
		local at = cf.Position + dir * (size.Magnitude * 0.5)
		ice({
			Name = "Shard",
			Size = Vector3.new(s * 0.6, s * 2.4, s * 0.6),
			CFrame = CFrame.lookAt(at, at + dir) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.Angles(0, math.rad(45), 0),
			Color = Color3.fromRGB(215, 240, 255),
			Transparency = 0.05,
		})
	end
	local light = Instance.new("PointLight")
	light.Color = ICE
	light.Range = 14
	light.Brightness = 2
	light.Parent = core
	m.PrimaryPart = core
	return m
end

local function freeze(player: Player, st: State)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not hrp then
		return
	end
	st.frozen = true
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.Anchored = true
	local block = iceBlock(character)
	block.Parent = workspace
	character:SetAttribute("Frozen", true)
	task.delay(C.FrozenTime, function()
		local pos = hrp.Position
		block:Destroy()
		if character.Parent then
			character:SetAttribute("FrozenAt", pos)
			character:SetAttribute("Frozen", false)
			hrp.Anchored = false
			local cf = Bases.SpawnCFrame(player) or CFrame.new(0, 4, -40)
			character:SetPrimaryPartCFrame(cf)
		end
		local d = DataService.Get(player)
		if d then
			local lost = #d.cargo
			d.cargo = {}
			GameService.Sync(player)
			if lost > 0 then
				GameService.Notice(player, ("{Freezing} You froze in space and lost %d egg%s"):format(lost, if lost > 1 then "s" else ""), "bad")
			else
				GameService.Notice(player, "{Freezing} You froze in space! Stay inside the corridor", "bad")
			end
		end
		st.cold, st.outside, st.frozen = 0, 0, false
		player:SetAttribute("Cold", 0)
		player:SetAttribute("ColdGrace", nil)
		if character.Parent then
			character:SetAttribute("Cold", 0)
		end
	end)
end

local function step()
	for _, player in ipairs(Players:GetPlayers()) do
		local st = states[player]
		if not st then
			st = { outside = 0, cold = 0, frozen = false }
			states[player] = st
		end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if st.frozen or not hrp or not hum or hum.Health <= 0 then
			continue
		end
		local _, dist = SafeZone.Nearest(hrp.Position)
		local before = st.cold
		if dist <= 0 then
			st.outside = 0
			st.cold = math.max(0, st.cold - C.Thaw * STEP)
			if player:GetAttribute("ColdGrace") ~= nil then
				player:SetAttribute("ColdGrace", nil)
			end
		else
			st.outside += STEP
			local far = dist > C.FarDistance
			if far or st.outside > C.Grace then
				st.cold = math.min(1, st.cold + STEP / C.FreezeTime * (if far then 2 else 1))
			end
			player:SetAttribute("ColdGrace", if far then 0 else round(math.max(0, C.Grace - st.outside)))
		end
		if st.cold ~= before then
			player:SetAttribute("Cold", round(st.cold))
			character:SetAttribute("Cold", round(st.cold))
		end
		if st.cold >= 1 then
			freeze(player, st)
		end
	end
end

function ColdService.Start()
	-- boîte du vaisseau, publiée pour le calcul de la zone sûre chez tous
	local ship = workspace:WaitForChild("Ship") :: Model
	local cf, size = ship:GetBoundingBox()
	ship:SetAttribute("SafeMin", cf.Position - size / 2)
	ship:SetAttribute("SafeMax", cf.Position + size / 2)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	-- au respawn : jauge remise à zéro
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local st = states[player]
			if st then
				st.cold, st.outside, st.frozen = 0, 0, false
			end
			player:SetAttribute("Cold", 0)
			player:SetAttribute("ColdGrace", nil)
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(STEP)
			step()
		end
	end)
end

return ColdService
