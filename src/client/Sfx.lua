-- Sons du joueur (Config.Sounds) : effets courts, boucles et musique.
-- Deux groupes dans SoundService, Music et Effects.
--   Sfx.Play("Coin")                         son à l'écran
--   Sfx.Play("RockBreak", { at = position })  son placé dans le monde (on l'entend de près)
--   local l = Sfx.Loop("Jetpack") ; l:Set(0.6) volume de 0 à 1 (0 = arrêté)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local S = Config.Sounds

local Sfx = {}

local function group(name: string): SoundGroup
	local g = SoundService:FindFirstChild(name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Parent = SoundService
	end
	return g :: SoundGroup
end

Sfx.MusicGroup = group("Music")
Sfx.EffectsGroup = group("Effects")


-- Un son de chaque sorte, prêt à être cloné (chargé une seule fois)
local templates: { [string]: Sound } = {}
local holder = Instance.new("Folder")
holder.Name = "Sfx"
holder.Parent = SoundService

local function template(name: string, def): Sound
	local t = templates[name]
	if not t then
		t = Instance.new("Sound")
		t.Name = name
		t.SoundId = "rbxassetid://" .. def.Id
		t.Volume = def.Volume or 0.5
		t.PlaybackSpeed = def.Pitch or 1
		t.SoundGroup = Sfx.EffectsGroup
		t.Parent = holder
		templates[name] = t
	end
	return t
end

-- Point d'ancrage pour les sons placés dans le monde
local function anchorAt(pos: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	return a
end

function Sfx.Play(name: string, opts: { at: Vector3?, volume: number?, pitch: number? }?): Sound?
	local def = S.Sfx[name]
	if not def then
		return nil
	end
	local t = template(name, def)
	local s = t:Clone()
	local o = opts or {}
	s.Volume = t.Volume * (o.volume or 1)
	s.PlaybackSpeed = t.PlaybackSpeed * (o.pitch or 1)
	local anchor: Attachment? = nil
	if o.at then
		anchor = anchorAt(o.at)
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = S.Range
		s.Parent = anchor
	else
		s.Parent = holder
	end
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
		if anchor then
			anchor:Destroy()
		end
	end)
	task.delay(12, function()
		if s.Parent then
			s:Destroy()
		end
		if anchor and anchor.Parent then
			anchor:Destroy()
		end
	end)
	return s
end

export type Loop = {
	sound: Sound,
	Set: (self: Loop, level: number) -> (),
	SetPitch: (self: Loop, mult: number) -> (),
	Destroy: (self: Loop) -> (),
}

-- Boucle : le volume suit doucement le niveau demandé, le son s'arrête à 0.
-- parent : une pièce ou un attachment pour placer la boucle dans le monde (sinon à l'écran).
function Sfx.Loop(name: string, parent: Instance?): Loop
	local def = S.Loops[name]
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. def.Id
	s.Looped = true
	s.Volume = 0
	s.PlaybackSpeed = def.Pitch or 1
	s.SoundGroup = Sfx.EffectsGroup
	if def.Region then
		-- seulement la partie régulière de l'enregistrement, en boucle
		s.PlaybackRegionsEnabled = true
		s.LoopRegion = NumberRange.new(def.Region[1], def.Region[2])
	end
	if parent then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 10
		s.RollOffMaxDistance = S.Range * 0.6
	end
	s.Parent = parent or holder
	local loop = { sound = s, target = 0 }
	function loop.Set(self, level: number)
		self.target = math.clamp(level, 0, 1) * (def.Volume or 0.5)
	end
	function loop.SetPitch(self, mult: number)
		self.sound.PlaybackSpeed = (def.Pitch or 1) * mult
	end
	function loop.Destroy(self)
		self.sound:Destroy()
	end
	-- fondu du volume
	task.spawn(function()
		while s.Parent do
			local dt = task.wait()
			local v = s.Volume + (loop.target - s.Volume) * math.min(1, dt * 8)
			if math.abs(v - loop.target) < 0.002 then
				v = loop.target
			end
			s.Volume = v
			if v > 0 and not s.IsPlaying then
				if def.Region then
					-- départ au hasard dans la partie régulière : chaque reprise sonne un peu différemment
					s.TimePosition = def.Region[1] + math.random() * (def.Region[2] - def.Region[1] - 4)
				end
				s:Play()
			elseif v == 0 and s.IsPlaying then
				s:Stop()
			end
		end
	end)
	return loop :: any
end

return Sfx
