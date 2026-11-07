-- Modèles des géodes et des minerais.
-- MODÈLES FAITS DANS STUDIO (Ropilot) : s'ils existent, ils sont pris en priorité :
--   ReplicatedStorage.Assets.Gems.R<anneau>_T<rareté>     le minerai (ex. R1_T3 = Amethyst)
--   ReplicatedStorage.Assets.Geodes.R<anneau>_T<rareté>   la géode fermée de cet anneau et cette rareté,
--   sinon ReplicatedStorage.Assets.Geodes.R<anneau>, sinon ReplicatedStorage.Assets.Geodes.Geode
-- N'importe quel modèle convient : il est recentré, sa taille réglée, ses scripts retirés.
-- SINON, modèles de secours faits de pièces :
--   GemModel.Make("geode", anneau, rareté)  géode fermée : boule de roche de la couleur de l'anneau, avec
--                                            des pointes de cristal de la couleur de la rareté qui dépassent
--   GemModel.Make("gem", anneau, rareté, brillant)  minerai : grappe de cristaux sur un socle de roche,
--                                            lumière et étincelles (plus il est rare, plus il y en a)
-- Comme EggModel : pivot au centre (« Core »), attribut BodyHeight = hauteur à l'échelle 1 ; la taille
-- se change avec EggModel.SetHeight (ou Model:ScaleTo).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GemModel = {}

local SPARKLE = "rbxassetid://138922153683020"

local function part(m: Model, props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = m
	return p
end

-- Cristal pointu : un prisme carré et un toit en deux biseaux, le long de l'axe Y de cf
local function crystal(m: Model, cf: CFrame, width: number, height: number, color: Color3)
	local body = height * 0.7
	part(m, { Name = "Crystal", Size = Vector3.new(width, body, width), CFrame = cf * CFrame.new(0, body / 2, 0), Color = color, Reflectance = 0.12 })
	local tip = height - body
	for _, s in ipairs({ 1, -1 }) do
		part(m, {
			ClassName = "WedgePart",
			Name = "CrystalTip",
			Size = Vector3.new(width, tip, width / 2),
			CFrame = cf * CFrame.new(0, body + tip / 2, s * width / 4) * CFrame.Angles(0, if s > 0 then 0 else math.pi, 0),
			Color = color:Lerp(Color3.new(1, 1, 1), 0.25),
			Reflectance = 0.12,
		})
	end
end

local function rockColor(ring: number): Color3
	local r = Config.Rings[math.clamp(ring, 1, #Config.Rings)]
	return r.Color:Lerp(Color3.fromRGB(90, 85, 80), 0.25)
end

-- Modèle fait dans Studio, s'il existe : copie recentrée sur une pièce « Core », BodyHeight = sa hauteur
local function fromAssets(kind: string, ring: number, rarity: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild(if kind == "geode" then "Geodes" else "Gems")
	if not folder then
		return nil
	end
	local template = folder:FindFirstChild(("R%d_T%d"):format(ring, rarity))
	if not template and kind == "geode" then
		template = folder:FindFirstChild("R" .. ring) or folder:FindFirstChild("Geode")
	end
	if not template or not template:IsA("Model") then
		return nil
	end
	local m = template:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local cf, size = m:GetBoundingBox()
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.one * 0.2
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.CFrame = CFrame.new(cf.Position)
	core.Parent = m
	m.PrimaryPart = core
	m:SetAttribute("BodyHeight", size.Y)
	m:PivotTo(CFrame.new())
	return m
end

function GemModel.Make(kind: string, ring: number, rarity: number, shiny: boolean?): Model
	local made = fromAssets(kind, ring, rarity)
	if made then
		made.Name = if kind == "geode" then "Geode" else "Gem"
		return made
	end
	local m = Instance.new("Model")
	m.Name = if kind == "geode" then "Geode" else "Gem"
	local color = (Config.Rarities[rarity] or Config.Rarities[1]).Color
	if shiny then
		color = color:Lerp(Color3.fromRGB(255, 240, 150), 0.35)
	end
	local rng = Random.new(ring * 31 + rarity * 7 + (if kind == "geode" then 0 else 3))
	local core = part(m, { Name = "Core", Size = Vector3.one * 0.2, CFrame = CFrame.new(), Transparency = 1 })
	m.PrimaryPart = core
	if kind == "geode" then
		-- boule de roche bosselée et pointes de cristal
		part(m, { Name = "Rock", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(), Color = rockColor(ring) })
		for i = 1, 4 do
			local a = i * 1.7
			local off = Vector3.new(math.cos(a) * 0.55, math.sin(i) * 0.4, math.sin(a) * 0.55)
			part(m, { Name = "Lump", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(0.9, 1.2), CFrame = CFrame.new(off), Color = rockColor(ring):Lerp(Color3.new(0, 0, 0), 0.12) })
		end
		local tips = 3 + math.floor(rarity / 2)
		for _ = 1, tips do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.1, 1), rng:NextNumber(-1, 1)).Unit
			local cf = CFrame.lookAt(dir * 0.75, dir * 2) * CFrame.Angles(-math.pi / 2, 0, 0)
			crystal(m, cf, rng:NextNumber(0.22, 0.32), rng:NextNumber(0.45, 0.7), color)
		end
		m:SetAttribute("BodyHeight", 2)
	else
		-- socle : demi-coque de roche, intérieur sombre
		part(m, { Name = "Rock", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = CFrame.new(0, -0.55, 0), Color = rockColor(ring) })
		part(m, { Name = "Inside", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.8, 1.8), CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = color:Lerp(Color3.new(0, 0, 0), 0.55) })
		-- grappe : un grand cristal au centre, d'autres autour, penchés vers l'extérieur
		local count = 4 + math.min(rarity, 5)
		crystal(m, CFrame.new(0, 0.1, 0), 0.5, 1.6 + rarity * 0.08, color)
		for i = 1, count do
			local a = (i / count) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
			local r = rng:NextNumber(0.35, 0.65)
			local tilt = rng:NextNumber(0.25, 0.6)
			local cf = CFrame.new(math.cos(a) * r, 0.1, math.sin(a) * r) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, -tilt)
			crystal(m, cf, rng:NextNumber(0.24, 0.38), rng:NextNumber(0.7, 1.15), color)
		end
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 6 + rarity
		light.Brightness = 1 + rarity * 0.2
		light.Parent = core
		if rarity >= 3 or shiny then
			local at = Instance.new("Attachment")
			at.Position = Vector3.new(0, 0.9, 0)
			at.Parent = core
			local sp = Instance.new("ParticleEmitter")
			sp.Texture = SPARKLE
			sp.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
			sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 0) })
			sp.Lifetime = NumberRange.new(0.5, 0.9)
			sp.Rate = (rarity - 2) * 3 + (if shiny then 6 else 0)
			sp.Speed = NumberRange.new(0.3, 1)
			sp.SpreadAngle = Vector2.new(180, 180)
			sp.LightEmission = 1
			sp.LightInfluence = 0
			sp.Parent = at
		end
		m:SetAttribute("BodyHeight", 2.4)
	end
	return m
end

return GemModel
