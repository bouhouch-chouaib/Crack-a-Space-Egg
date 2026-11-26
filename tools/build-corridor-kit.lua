-- Range les maillages low-poly du couloir (faits dans Blender : tools/blender/corridor_kit*.py, importés par lots
-- « Work_CK_* » dans Workspace) en modèles prêts à cloner dans ReplicatedStorage.Assets.CorridorKit :
--   Props/<Nom>      décor d'un biome : Body (texture au pixel, picots peints), Glow (néon), sous-modèle Spin
--                    (ce qui tourne). Pivot au pied, l'avant du modèle vers +Z.
--   Struct/<Nom>     pilier, arche, île : pièces unies Trim / Dark / Glow, reteintes par biome (CorridorDecor).
--   Critters/<Nom>   petite créature volante : Body + pièces mobiles (ailes, hélice, queue, mâchoire), chacune
--                    avec sa charnière (PivotOffset, l'axe de rotation est son Z) et ses réglages (attributs
--                    Anim, Speed, Amp, Phase), lus par Critters.client.
-- Dans Studio : require(ServerStorage.BuildCorridorKit).Build() ; à relancer après chaque nouvel import.
-- Les lots « Work_CK_* » sont supprimés à la fin (Build(true) les garde).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

-- Chaque lot : boîte englobante dans Blender (lo, hi) et décalage en X de l'origine de chaque modèle
-- (valeurs rendues par batch() dans corridor_kit.py). Blender (x, y, z) -> Roblox (x, z, -y).
local LOTS = {
	{ model = "Work_CK_Lot1", kind = "Props", lo = { 0, -6.053, 0 }, hi = { 86.171, 6.053, 15.5 },
		dx = { Spire = 4.056, Pebbles = 18.632, Crystal = 32.572, Snow = 47.254, Volcano = 63.983, LavaRock = 80.885 } },
	{ model = "Work_CK_Lot2", kind = "Props", lo = { 0, -6.589, 0 }, hi = { 161.671, 6.867, 14.1 },
		dx = { Puff = 6.1, Planet = 24.732, Fang = 41.237, Eye = 55.437, Hourglass = 70.356, Glitch = 87.835, Nest = 105.852, BigEgg = 123.826,
			Coral = 139.782, Clam = 156.601 } },
	{ model = "Work_CK_Lot3", kind = "Props", lo = { 0, -5.1, -0.204 }, hi = { 229.28, 5.6, 15.457 },
		dx = { StormCloud = 6.3, Rod = 22.115, Gear = 35.966, Pipe = 51.456, Lollipop = 66.412, CandyCane = 79.93, Gumdrop = 94.988,
			Mushroom = 111.391, Spores = 127.845, Pillar = 143.159, Torii = 163.613, Idol = 183.013, Lantern = 196.113, Pumpkin = 211.037,
			Ghost = 225.63 } },
	{ model = "Work_CK_Struct", kind = "Struct", lo = { 0, -6.263, -7.722 }, hi = { 54.636, 6.263, 10 },
		dx = { PostCap = 3.1, PostShaft = 14.5, PostLamp = 24.1, ArchBlock = 33.85, Island = 48.66 } },
	{ model = "Work_CK_CrA", kind = "Critters", lo = { 0, -2.809, -0.713 }, hi = { 66.664, 4.2, 5.2 },
		dx = { CrPuff = 2.8, CrSprite = 12.013, CrBat = 23.677, CrJelly = 33.682, CrChomper = 41.237, CrCube = 48.833, CrChick = 57.06,
			CrFish = 64.389 } },
	{ model = "Work_CK_CrB", kind = "Critters", lo = { 0, -2.801, -0.3 }, hi = { 56.772, 2.801, 5.7 },
		dx = { CrSpark = 2.754, CrDrone = 10.208, CrSaucer = 17.709, CrFairy = 26.461, CrDragon = 35.236, CrDragonSeg = 42.26,
			CrGhost = 49.022, CrGhostSeg = 55.772 } },
}

-- Vitesse des décors qui tournent (tours lents : ils sont grands)
local SPIN = { Gear = { Spin = 0.5, Spin2 = -0.9 }, Pipe = { Spin = 0.8 }, Lollipop = { Spin = 0.35 } }

-- Mouvement des pièces des créatures : { type, vitesse, amplitude (radians), phase }
local WING = { Puff = 16, Sprite = 20, Bat = 11, Chomper = 24, Chick = 18, Spark = 26, Fairy = 22 }
local FIN = { Fish = { 7, 0.5 }, Dragon = { 2.5, 0.3 }, Ghost = { 3, 0.45 } }
local SPINNERS = { Cube = { Spin = 2.4 }, Chick = { Spin = 22 }, Drone = { Spin = 22, Spin2 = 4 }, Saucer = { Spin = 1.5 } }

local X, Y, Z = Vector3.xAxis, Vector3.yAxis, Vector3.zAxis

-- Repère placé en « pos » dont l'axe Z est « axis » (l'axe de rotation de la pièce)
local function frame(pos: Vector3, axis: Vector3): CFrame
	if axis == Y then
		return CFrame.fromMatrix(pos, X, -Z, Y)
	elseif axis == X then
		return CFrame.fromMatrix(pos, Y, Z, X)
	end
	return CFrame.new(pos)
end

local function thinAxis(p: BasePart): Vector3
	local s = p.Size
	if s.Y <= s.X and s.Y <= s.Z then
		return Y
	elseif s.Z <= s.X then
		return Z
	end
	return X
end

local function plain(p: BasePart, glow: boolean)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Material = if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	pcall(function()
		(p :: any).CollisionFidelity = Enum.CollisionFidelity.Box
	end)
end

local function hinge(p: BasePart, world: CFrame, anim: string, speed: number, amp: number, phase: number?)
	p.PivotOffset = p.CFrame:ToObjectSpace(world)
	p:SetAttribute("Anim", anim)
	p:SetAttribute("Speed", speed)
	p:SetAttribute("Amp", amp)
	p:SetAttribute("Phase", phase or 0)
end

function Kit.Build(keep: boolean?)
	local assets = ReplicatedStorage:WaitForChild("Assets")
	local old = assets:FindFirstChild("CorridorKit")
	local root = Instance.new("Folder")
	root.Name = "CorridorKit"
	for _, n in ipairs({ "Props", "Struct", "Critters" }) do
		local f = Instance.new("Folder")
		f.Name = n
		f.Parent = root
	end
	local report = {}
	for _, lot in ipairs(LOTS) do
		local work = workspace:FindFirstChild(lot.model)
		if not work then
			-- lot déjà rangé lors d'un passage précédent : on garde ses modèles
			if old then
				for name in pairs(lot.dx) do
					local short = if lot.kind == "Critters" then name:sub(3) else name
					local m = old[lot.kind]:FindFirstChild(short)
					if m then
						m:Clone().Parent = root[lot.kind]
					end
				end
			end
			table.insert(report, lot.model .. " : absent (modèles précédents gardés)")
			continue
		end
		local cf, size = (work :: Model):GetBoundingBox()
		local bottom = cf.Position - Vector3.new(0, size.Y / 2, 0)
		local cx, cy = (lot.lo[1] + lot.hi[1]) / 2, (lot.lo[2] + lot.hi[2]) / 2
		local count = 0
		for name, dx in pairs(lot.dx) do
			local origin = bottom + Vector3.new(dx - cx, -lot.lo[3], cy)
			local short = if lot.kind == "Critters" then name:sub(3) else name
			local m = Instance.new("Model")
			m.Name = short
			local parts: { [string]: BasePart } = {}
			for _, src in ipairs(work:GetChildren()) do
				local prefix, group = src.Name:match("^(.-)__(.+)$")
				if prefix == name and src:IsA("BasePart") then
					local p = src:Clone()
					p.Name = group
					for _, c in ipairs(p:GetChildren()) do
						c:Destroy()
					end
					plain(p, group == "Glow" or p.Material == Enum.Material.Neon)
					parts[group] = p
					p.Parent = m
				end
			end
			if lot.kind == "Props" then
				m.WorldPivot = CFrame.new(origin)
				for group, p in pairs(parts) do
					if group:sub(1, 4) == "Spin" then
						local sub = Instance.new("Model")
						sub.Name = group
						sub.WorldPivot = frame(p.Position, thinAxis(p))
						sub:SetAttribute("Speed", (SPIN[short] and SPIN[short][group]) or 0.5)
						sub.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
						p.Name = "Part"
						p.Parent = sub
						sub.Parent = m
					end
				end
			elseif lot.kind == "Struct" then
				m.WorldPivot = if short == "PostShaft" or short == "ArchBlock" then CFrame.new(parts.Trim.Position) else CFrame.new(origin)
				for group, p in pairs(parts) do
					if group ~= "Glow" then
						p.Color = if group == "Dark" then Color3.fromRGB(90, 90, 90) else Color3.fromRGB(190, 190, 190)
					end
				end
			else
				local body = parts.Body
				m.PrimaryPart = body
				m.WorldPivot = CFrame.new(body.Position)
				local c = body.Position
				for group, p in pairs(parts) do
					local pos, half = p.Position, p.Size / 2
					if group == "WingL" or group == "WingR" or group == "FinL" or group == "FinR" then
						-- charnière sur le bord le plus proche du corps, battement autour de l'axe avant-arrière
						local side = if pos.X < c.X then -1 else 1
						local at = Vector3.new(pos.X - side * half.X, pos.Y, pos.Z)
						if group:sub(1, 4) == "Wing" then
							hinge(p, frame(at, Z), "swing", WING[short] or 16, side * (if short == "Bat" then 0.55 else 0.7))
						else
							local f = FIN[short] or { 4, 0.4 }
							hinge(p, frame(at, Z), "swing", f[1], side * f[2], if side < 0 then 0 else 0.6)
						end
					elseif group == "Tail" then
						-- queue du poisson : charnière à l'avant de la nageoire, balayage gauche-droite
						hinge(p, frame(Vector3.new(pos.X, pos.Y, pos.Z + half.Z), Y), "swing", 9, 0.5)
					elseif group == "Tail0" or group == "Tail1" then
						-- tentacules : accrochées en haut, elles ondulent
						hinge(p, frame(Vector3.new(pos.X, pos.Y + half.Y, pos.Z), X), "swing", 3, 0.2, if group == "Tail0" then 0 else 1.6)
					elseif group == "Jaw" then
						-- mâchoire : charnière en haut à l'arrière, elle s'ouvre vers le bas
						hinge(p, frame(Vector3.new(pos.X, pos.Y + half.Y, pos.Z - half.Z), X), "open", 5, 0.38)
					elseif group:sub(1, 4) == "Spin" then
						local axis = thinAxis(p)
						local at = if axis == Y then Vector3.new(c.X, pos.Y, c.Z) else pos
						hinge(p, frame(at, axis), "spin", (SPINNERS[short] and SPINNERS[short][group]) or 4, 0)
					end
				end
				if short == "Sprite" then
					parts.WingL.Transparency = 0.25
					parts.WingR.Transparency = 0.25
				end
			end
			m.Parent = root[lot.kind]
			count += 1
		end
		table.insert(report, ("%s : %d modèles"):format(lot.model, count))
		if not keep then
			work:Destroy()
		end
	end
	if old then
		old:Destroy()
	end
	root.Parent = assets
	return table.concat(report, "\n")
end

return Kit
