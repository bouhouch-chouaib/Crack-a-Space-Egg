-- Effets « anime » en 4 calques (méthode du 25 nov., docs/Mecaniques.md « Effets en 4 calques ») :
-- chaque effet est dessiné en 4 planches blanches de 16 étapes (tools/fx/layered_fx.py) :
--   Glow (halo doux), Rim (silhouette), Mid (milieu), Core (cœur). Ici on les empile : une
-- ParticleEmitter par calque, mêmes réglages, émises au même instant, et on colore chaque calque
-- (Rim saturé, Mid plus clair, Core presque blanc, Glow saturé et transparent).

local LayeredFx = {}

local LAYERS = { "Glow", "Rim", "Mid", "Core" }

-- rbxassetid des planches (envoyées le 26 nov.)
LayeredFx.Sheets = {
	Impact = { Glow = "rbxassetid://99430433216884", Rim = "rbxassetid://134329991141227", Mid = "rbxassetid://125068976791911", Core = "rbxassetid://84045151298523" },
	Flame = { Glow = "rbxassetid://95614045088150", Rim = "rbxassetid://73757705580084", Mid = "rbxassetid://112648906450158", Core = "rbxassetid://94402525575848" },
	Wisp = { Glow = "rbxassetid://89833320312483", Rim = "rbxassetid://86403315002723", Mid = "rbxassetid://94898568825040", Core = "rbxassetid://71622138051019" },
	Electric = { Glow = "rbxassetid://117379048226205", Rim = "rbxassetid://128783684694351", Mid = "rbxassetid://82261877067943", Core = "rbxassetid://84603244460680" },
	Bubbles = { Glow = "rbxassetid://72422510138123", Rim = "rbxassetid://109362335000312", Mid = "rbxassetid://118309718170167", Core = "rbxassetid://108917590185949" },
	Spores = { Glow = "rbxassetid://85326723722081", Rim = "rbxassetid://120716509754606", Mid = "rbxassetid://129242767447973", Core = "rbxassetid://121697335477463" },
	Hearts = { Glow = "rbxassetid://128950308416854", Rim = "rbxassetid://102815209108801", Mid = "rbxassetid://120370952861437", Core = "rbxassetid://75171944546913" },
	Stardust = { Glow = "rbxassetid://102234956437051", Rim = "rbxassetid://91121943120697", Mid = "rbxassetid://102659482073527", Core = "rbxassetid://87047984336060" },
	Glitch = { Glow = "rbxassetid://136839470197355", Rim = "rbxassetid://129712351012427", Mid = "rbxassetid://102841455841247", Core = "rbxassetid://135364716585455" },
	Shards = { Glow = "rbxassetid://134920606713304", Rim = "rbxassetid://87254143878532", Mid = "rbxassetid://99812260957601", Core = "rbxassetid://120060051567666" },
	Pulse = { Glow = "rbxassetid://100011621251953", Rim = "rbxassetid://81455035593534", Mid = "rbxassetid://105400752004934", Core = "rbxassetid://74665979691155" },
	Rune = { Glow = "rbxassetid://134319124948669", Rim = "rbxassetid://101719644120967", Mid = "rbxassetid://80243949445220", Core = "rbxassetid://114942133164191" },
	Gear = { Glow = "rbxassetid://124663679834377", Rim = "rbxassetid://102295534812069", Mid = "rbxassetid://94679299550587", Core = "rbxassetid://117848019427270" },
	-- éclosion d'œuf (HatchFx) : explosion de coquille, onde de choc au sol, énergie aspirée pendant la charge
	Hatch = { Glow = "rbxassetid://74598796633742", Rim = "rbxassetid://122232441320336", Mid = "rbxassetid://71866108082050", Core = "rbxassetid://105850873147597" },
	HatchRing = { Glow = "rbxassetid://112613559635511", Rim = "rbxassetid://138754948553788", Mid = "rbxassetid://115697792909880", Core = "rbxassetid://73082566312600" },
	-- roche qui casse (Impact.client) : éclair et fissures puis éclats, nuage de poussière façon dessin animé
	Shatter = { Glow = "rbxassetid://95467819314073", Rim = "rbxassetid://130321780070587", Mid = "rbxassetid://115391815252358", Core = "rbxassetid://81840169311894" },
	Dust = { Glow = "rbxassetid://98815856856038", Rim = "rbxassetid://79136465450259", Mid = "rbxassetid://107311969464746", Core = "rbxassetid://140277773343582" },
	-- flamme des tuyères du jetpack (Jetpack.client), en boucle, tuyère en haut de l'image
	Thrust = { Glow = "rbxassetid://85617258806965", Rim = "rbxassetid://121451156008585", Mid = "rbxassetid://103169018205636", Core = "rbxassetid://139605118001905" },
	-- morsure du monstre (MonsterFx.client) : crocs qui claquent, éclair, trois entailles d'énergie
	Bite = { Glow = "rbxassetid://106171591917279", Rim = "rbxassetid://87980479626516", Mid = "rbxassetid://99658630256742", Core = "rbxassetid://81610182572383" },
	-- bonus x2 XP de la soufflerie (WindTunnel.client) : tourbillon violet qui s'ouvre
	PowerUp = { Glow = "rbxassetid://77232808283172", Rim = "rbxassetid://128129415044728", Mid = "rbxassetid://106879213808346", Core = "rbxassetid://125153285030214" },
	-- rugissement du monstre (MonsterFx.client) : ondes en dents de scie, lignes de vitesse
	Roar = { Glow = "rbxassetid://96977963111925", Rim = "rbxassetid://87077125099005", Mid = "rbxassetid://81994057772119", Core = "rbxassetid://95879753420510" },
	-- achat dans la boutique (Store.client) : soleil doré, anneau, étoiles qui scintillent
	Celebrate = { Glow = "rbxassetid://127190928214483", Rim = "rbxassetid://106263494394533", Mid = "rbxassetid://89835018857798", Core = "rbxassetid://92773400059896" },
	-- créature mutée (Creatures.client) : trait de lumière qui balaie la silhouette, étoiles qui scintillent
	Gleam = { Glow = "rbxassetid://84055851302915", Rim = "rbxassetid://123273352762654", Mid = "rbxassetid://121282950937926", Core = "rbxassetid://117937151072568" },
	-- œuf qui sort de la roche (Impact.client) : jaillissement vers le haut, halo qui tourne pendant le vol
	EggPop = { Glow = "rbxassetid://85864374889551", Rim = "rbxassetid://130591727503363", Mid = "rbxassetid://118427384435231", Core = "rbxassetid://75789850346283" },
	Halo = { Glow = "rbxassetid://79163174307055", Rim = "rbxassetid://98294404671465", Mid = "rbxassetid://131066703231740", Core = "rbxassetid://123240916788334" },
	Converge = { Glow = "rbxassetid://126224476094550", Rim = "rbxassetid://116332369242874", Mid = "rbxassetid://96225808912195", Core = "rbxassetid://134950337727915" },
}

-- Mélange de chaque calque : le halo s'ajoute à la lumière, les autres se posent comme de la peinture
local LIGHT = { Glow = 1, Rim = 0, Mid = 0.15, Core = 0.45 }
local ALPHA = { Glow = 0.45, Rim = 0, Mid = 0, Core = 0 }

export type Fx = {
	emitters: { ParticleEmitter },
	Emit: (self: Fx, rotation: number?, size: number?) -> (),
	SetColors: (self: Fx, rim: Color3, mid: Color3) -> (),
	Clear: (self: Fx) -> (),
	Destroy: (self: Fx) -> (),
}

local function kp(t: number, v: number): NumberSequenceKeypoint
	return NumberSequenceKeypoint.new(t, v)
end

-- Couleurs des 4 calques à partir de deux teintes (silhouette, milieu)
function LayeredFx.Colors(rim: Color3, mid: Color3): { [string]: Color3 }
	return {
		Glow = rim,
		Rim = rim,
		Mid = mid,
		Core = mid:Lerp(Color3.new(1, 1, 1), 0.82),
	}
end

-- Crée les 4 calques sous `parent` (Attachment).
-- opts : kind, size, colors = { rim, mid }, lifetime, loop (secondes d'une boucle, sinon une seule fois),
--        flat (posé à plat), zOffset, locked, fade (secondes de fondu au début et à la fin), alpha (0..1 en plus),
--        light (LightEmission par calque, ex. { Glow = 0 } pour de la fumée qui ne brille pas), glowAlpha,
--        upright (l'image garde le haut du monde en haut : jets, colonnes)
function LayeredFx.new(parent: Instance, opts: { [string]: any }): Fx
	local sheet = LayeredFx.Sheets[opts.kind]
	assert(sheet, "LayeredFx : effet inconnu " .. tostring(opts.kind))
	local cols = LayeredFx.Colors(opts.colors[1], opts.colors[2])
	local life = opts.lifetime or 0.5
	local fade = math.clamp((opts.fade or 0) / life, 0, 0.45)
	local extra = opts.alpha or 0
	local emitters = {}
	for i, layer in ipairs(LAYERS) do
		local e = Instance.new("ParticleEmitter")
		e.Name = "Fx" .. layer
		e.Texture = sheet[layer]
		e.Color = ColorSequence.new(cols[layer])
		e.LightEmission = if opts.light and opts.light[layer] then opts.light[layer] else LIGHT[layer]
		e.LightInfluence = 0
		e.Enabled = false
		e.Rate = 0
		e.Lifetime = NumberRange.new(life)
		e.Size = NumberSequence.new(opts.size or 4)
		local base = if layer == "Glow" and opts.glowAlpha then opts.glowAlpha else ALPHA[layer]
		local a = 1 - (1 - base) * (1 - extra)
		if fade > 0 then
			e.Transparency = NumberSequence.new({ kp(0, 1), kp(fade, a), kp(1 - fade, a), kp(1, 1) })
		else
			e.Transparency = NumberSequence.new(a)
		end
		e.Speed = NumberRange.new(if opts.flat then 0.001 else 0)
		e.SpreadAngle = Vector2.zero
		e.Rotation = NumberRange.new(0)
		e.RotSpeed = NumberRange.new(0)
		e.Drag = 0
		e.Acceleration = Vector3.zero
		e.LockedToPart = opts.locked == true
		e.EmissionDirection = Enum.NormalId.Top
		if opts.flat then
			e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		elseif opts.upright then
			e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
		end
		-- les calques sont empilés dans l'ordre (le cœur devant)
		e.ZOffset = (opts.zOffset or 0) + i * 0.02
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookStartRandom = false
		if opts.loop then
			e.FlipbookMode = Enum.ParticleFlipbookMode.Loop
			e.FlipbookFramerate = NumberRange.new(16 / opts.loop)
		else
			e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		end
		e.Parent = parent
		emitters[i] = e
	end
	local fx = { emitters = emitters } :: any
	-- Émet une image de chaque calque au même instant (même rotation, même taille : ils se superposent)
	function fx:Emit(rotation: number?, size: number?)
		for _, e in ipairs(self.emitters) do
			if rotation then
				e.Rotation = NumberRange.new(rotation)
			end
			if size then
				e.Size = NumberSequence.new(size)
			end
			e:Emit(1)
		end
	end
	-- Change les teintes (ex. couleur du biome de la roche frappée)
	function fx:SetColors(rim: Color3, mid: Color3)
		local c = LayeredFx.Colors(rim, mid)
		for i, e in ipairs(self.emitters) do
			e.Color = ColorSequence.new(c[LAYERS[i]])
		end
	end
	-- Efface tout de suite ce qui est affiché
	function fx:Clear()
		for _, e in ipairs(self.emitters) do
			e:Clear()
		end
	end
	function fx:Destroy()
		for _, e in ipairs(self.emitters) do
			e:Destroy()
		end
	end
	return fx :: Fx
end

-- À l'écran : les 4 calques en ImageLabel empilés, qui passent les 16 étapes en `duration` secondes
-- (une seule fois) puis disparaissent. opts : kind, colors = { rim, mid }, duration, size (UDim2),
-- position (UDim2, centre), zIndex
function LayeredFx.Screen(parent: Instance, opts: { [string]: any })
	local sheet = LayeredFx.Sheets[opts.kind]
	assert(sheet, "LayeredFx : effet inconnu " .. tostring(opts.kind))
	local cols = LayeredFx.Colors(opts.colors[1], opts.colors[2])
	local labels = {}
	for i, layer in ipairs(LAYERS) do
		local img = Instance.new("ImageLabel")
		img.Name = "Fx" .. layer
		img.BackgroundTransparency = 1
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = opts.position or UDim2.fromScale(0.5, 0.5)
		img.Size = opts.size or UDim2.fromScale(0.6, 0.6)
		img.SizeConstraint = Enum.SizeConstraint.RelativeYY
		img.Image = sheet[layer]
		img.ImageColor3 = cols[layer]
		img.ImageTransparency = ALPHA[layer]
		img.ImageRectSize = Vector2.new(256, 256)
		img.ZIndex = (opts.zIndex or 30) + i
		img.Parent = parent
		labels[i] = img
	end
	local t0 = os.clock()
	local dur = opts.duration or 0.8
	local conn
	conn = game:GetService("RunService").RenderStepped:Connect(function()
		local f = math.floor((os.clock() - t0) / dur * 16)
		if f >= 16 then
			conn:Disconnect()
			for _, img in ipairs(labels) do
				img:Destroy()
			end
			return
		end
		local off = Vector2.new((f % 4) * 256, math.floor(f / 4) * 256)
		for _, img in ipairs(labels) do
			img.ImageRectOffset = off
		end
	end)
end

-- Où se pose chaque aura par rapport à la créature (h = sa hauteur) :
-- Scale = taille de l'image en hauteurs, Anchor = centre de l'image au-dessus des pieds (en tailles d'image),
-- Behind = derrière la créature (flammes, fumée) ; sinon au milieu (ce qui tourne passe devant et derrière)
LayeredFx.AuraShape = {
	Flame = { Scale = 1.6, Anchor = 0.4, Behind = true },
	Wisp = { Scale = 1.6, Anchor = 0.4, Behind = true },
	Electric = { Scale = 1.6, Anchor = 0.3 },
	Bubbles = { Scale = 1.6, Anchor = 0.35 },
	Spores = { Scale = 1.7, Anchor = 0.35 },
	Hearts = { Scale = 1.6, Anchor = 0.4 },
	Stardust = { Scale = 1.8, Anchor = 0.25 },
	Glitch = { Scale = 1.6, Anchor = 0.28 },
	Shards = { Scale = 1.8, Anchor = 0.25 },
}

return LayeredFx
