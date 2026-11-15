-- Reliques des explorateurs perdus (Config.Relics) : une par anneau, tirage à part à chaque œuf foré
-- (tant qu'on ne l'a pas). Ni le scanner ni les potions n'aident. Une relique trouvée est mise à l'abri
-- tout de suite (sauvegarde immédiate) et donne son bonus pour toujours (+5 % d'argent ou d'XP de jetpack :
-- BoostService.IncomeMult et JetXPMult). On ne la vend plus (15 nov.).
-- Remotes.Relics (RemoteFunction) : ("state") -> { ok, owned, found } (owned : mêmes clés que found, valeur 1)
-- Remotes.RelicFound (RemoteEvent) vers le joueur : (clé), lance la grande révélation (RelicUI.client).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local GameService = require(script.Parent.GameService)
local Tracking = require(script.Parent.Tracking)
local AnnounceService = require(script.Parent.AnnounceService)

local Remotes = ReplicatedStorage.Remotes
local RelicService = {}
local rng = Random.new()
local BEAM_HEIGHT = 900

local function state(d)
	local owned = {}
	for key in pairs(d.relicsFound) do
		owned[key] = 1
	end
	return { ok = true, owned = owned, found = d.relicsFound }
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
	d.relicsFound[relic.Key] = true
	-- le bonus compte tout de suite : revenu affiché à jour
	GameService.Sync(player)
	Tracking.Event(player, "Relic_" .. relic.Key)
	task.spawn(DataService.Save, player) -- une trouvaille pareille ne doit jamais se perdre
	lightBeam(player, relic)
	-- le joueur regarde sa trouvaille : ColdService laisse passer ce moment
	player:SetAttribute("RelicGrace", os.clock() + Config.RelicReveal)
	Remotes.RelicFound:FireClient(player, relic.Key)
	-- tous les serveurs l'apprennent ; le découvreur a sa révélation, le bandeau gâcherait la surprise
	AnnounceService.Send(player, 3, ("%s found the lost relic: %s!"):format(player.DisplayName, relic.Name), relic.Color, "Star", true)
end

-- Appelé par GameService à chaque foret qui sort des œufs
local function roll(player: Player, ring: number, eggs: number)
	local d = DataService.Get(player)
	local relic = Config.RelicOfRing(ring)
	if not d or not relic or (d.guide or 0) < Config.Guide.Steps or d.relicsFound[relic.Key] then
		return
	end
	for _ = 1, eggs do
		if rng:NextNumber() * relic.Chance < 1 or player:GetAttribute("RelicForce") then
			give(player, d, relic)
			return
		end
	end
end

local function onInvoke(player: Player, action: any)
	local d = DataService.Get(player)
	if not d then
		return { ok = false, error = "Loading your save..." }
	end
	if action == "state" then
		return state(d)
	end
	return { ok = false, error = "Unknown action" }
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
