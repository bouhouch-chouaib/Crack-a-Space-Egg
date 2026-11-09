-- Reliques des explorateurs perdus (Config.Relics) : une par anneau, tirage à part à chaque œuf foré.
-- Ni le scanner ni les potions n'aident. Une relique trouvée est mise à l'abri tout de suite (sauvegarde immédiate) :
-- rien de ce qui arrive ensuite au joueur ne peut la lui faire perdre. La Supernova n'y touche pas.
-- Remotes.Relics (RemoteFunction) : ("state") -> { ok, owned, found } ; ("sell", clé) -> idem + value
-- Remotes.RelicFound (RemoteEvent) vers le joueur : (clé), lance la grande révélation (RelicUI.client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Tracking = require(script.Parent.Tracking)

local Remotes = ReplicatedStorage.Remotes
local RelicService = {}
local rng = Random.new()
local BEAM_HEIGHT = 900

local function state(d)
	return { ok = true, owned = d.relics, found = d.relicsFound }
end

-- Colonne de lumière à l'endroit de la trouvaille : tout le serveur la voit de loin
local function lightBeam(player: Player, relic)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local beam = Instance.new("Part")
	beam.Name = "RelicBeam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(BEAM_HEIGHT, 9, 9)
	beam.CFrame = CFrame.new(hrp.Position + Vector3.new(0, BEAM_HEIGHT / 2 - 12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.CastShadow = false
	beam.Material = Enum.Material.SmoothPlastic
	beam.Color = relic.Color
	beam.Transparency = 0.45
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = Config.DrillSkinArt.Sparkle
	sparks.Color = ColorSequence.new(relic.Color)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(3)
	sparks.Lifetime = NumberRange.new(2, 4)
	sparks.Speed = NumberRange.new(10, 30)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 60
	sparks.Parent = beam
	local light = Instance.new("PointLight")
	light.Color = relic.Color
	light.Range = 60
	light.Brightness = 4
	light.Parent = beam
	beam.Parent = workspace
	task.delay(Config.RelicReveal - 2, function()
		sparks.Enabled = false
		TweenService:Create(beam, TweenInfo.new(2), { Transparency = 1 }):Play()
		TweenService:Create(light, TweenInfo.new(2), { Brightness = 0 }):Play()
		task.delay(2.2, function()
			beam:Destroy()
		end)
	end)
end

local function give(player: Player, d, relic)
	d.relics[relic.Key] = (d.relics[relic.Key] or 0) + 1
	d.relicsFound[relic.Key] = true
	Tracking.Event(player, "Relic_" .. relic.Key)
	task.spawn(DataService.Save, player) -- une trouvaille pareille ne doit jamais se perdre
	lightBeam(player, relic)
	-- le joueur regarde sa trouvaille : ColdService laisse passer ce moment
	player:SetAttribute("RelicGrace", os.clock() + Config.RelicReveal)
	Remotes.RelicFound:FireClient(player, relic.Key)
	-- les autres joueurs l'apprennent ; le découvreur a sa révélation, le bandeau gâcherait la surprise
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			Remotes.Announcement:FireClient(other, player.DisplayName, relic.Name, #Config.Rarities, ("%s found the lost relic: %s!"):format(player.DisplayName, relic.Name))
		end
	end
end

-- Appelé par GameService à chaque foret qui sort des œufs
local function roll(player: Player, ring: number, eggs: number)
	local d = DataService.Get(player)
	local relic = Config.RelicOfRing(ring)
	if not d or not relic or (d.guide or 0) < Config.Guide.Steps then
		return
	end
	for _ = 1, eggs do
		if rng:NextNumber() * relic.Chance < 1 or player:GetAttribute("RelicForce") then
			give(player, d, relic)
		end
	end
end

local function onInvoke(player: Player, action: any, key: any)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	if action == "state" then
		return state(d)
	end
	if action ~= "sell" or type(key) ~= "string" then
		return { ok = false, error = "Unknown action" }
	end
	local relic = Config.Relic(key)
	if not relic or (d.relics[key] or 0) <= 0 then
		return { ok = false, error = "You don't have this relic" }
	end
	d.relics[key] -= 1
	if d.relics[key] <= 0 then
		d.relics[key] = nil
	end
	d.credits += relic.Value
	GameService.Sync(player)
	task.spawn(DataService.Save, player)
	GameService.Notice(player, ("{Cash} Sold %s for $%s!"):format(relic.Name, Format.Short(relic.Value)), "good")
	local res = state(d)
	res.value = relic.Value
	return res
end

function RelicService.Start()
	Remotes.Relics.OnServerInvoke = onInvoke
	GameService.RelicHook = roll
	-- Studio seulement : (joueur, clé) donne une relique ; l'attribut RelicForce fait réussir chaque tirage
	if RunService:IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "RelicDebug"
		bf.OnInvoke = function(player: Player, key: string)
			local d = DataService.Get(player)
			local relic = Config.Relic(key)
			if d and relic then
				give(player, d, relic)
			end
			return d ~= nil and relic ~= nil
		end
		bf.Parent = game:GetService("ServerStorage")
	end
end

return RelicService
