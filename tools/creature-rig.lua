-- Outil de Studio (mode édition) : monte une créature découpée en pièces (segment_mesh) pour l'animation.
-- Installé comme ModuleScript ServerStorage.CreatureRig ; usage :
--   require(game.ServerStorage.CreatureRig).Install(workspace.Work_R1_T5, "R1_T5", { ["tail"] = "Tail" })
-- 1. Donne un rôle à chaque pièce d'après son nom (et celui de ses parents) : Head, Jaw, Body, LegFL/FR/BL/BR,
--    LegL/R, ArmL/R, WingL/R, FinL/R, Tail, Tentacles, Ears, Horn... ; overrides = { [nom] = rôle } pour corriger.
--    Côté gauche = -X une fois la créature tournée vers -Z. Avant / arrière d'après la position de la tête.
-- 2. Les modèles générés regardent vers -Z (sens de marche de Creatures.client) ; turn = true les retourne.
-- 3. Pose une Attachment « Joint » dans chaque pièce animée : le point autour duquel elle tourne
--    (haut des pattes, bord intérieur des ailes, base de la queue, cou, charnière de la mâchoire).
-- 4. Range les pièces à plat dans le modèle « body », recrée le Core aux pieds, les attributs, et remplace
--    ReplicatedStorage.Assets.Creatures[key] (l'ancienne version va dans ServerStorage.OldCreatures).

local Rig = {}

local SIDED = { Leg = true, Arm = true, Wing = true, Fin = true, Ear = true }

-- Rôles exacts (créatures « blocky » faites dans Blender, tools/blender/rigjoin.py) : une pièce qui porte
-- déjà le nom d'un rôle le garde tel quel ; « Head__Glow » suit la tête sans joint à elle (attribut Follow).
local EXACT = {}
for _, r in ipairs({
	"Body", "Head", "Jaw", "Tail", "Tentacles", "LegFL", "LegFR", "LegBL", "LegBR", "LegL", "LegR", "LegF", "LegB",
	"ArmL", "ArmR", "WingL", "WingR", "FinL", "FinR", "EarL", "EarR",
}) do
	EXACT[r] = true
end

local function roleFromName(name: string): string?
	local n = string.lower(name)
	if n:find("jaw") or n:find("mouth") then
		return "Jaw"
	elseif n:find("head") then
		return "Head"
	elseif n:find("wing") then
		return "Wing"
	elseif n:find("arm") or n:find("claw") or n:find("pincer") or n:find("hand") then
		return "Arm"
	elseif n:find("leg") or n:find("foot") or n:find("feet") or n:find("paw") then
		return "Leg"
	elseif n:find("tail") then
		return "Tail"
	elseif n:find("fin") or n:find("flipper") then
		return "Fin"
	elseif n:find("tentacle") then
		return "Tentacles"
	elseif n:find("ear") then
		return "Ear"
	elseif n:find("body") or n:find("torso") or n:find("shell") or n:find("belly") then
		return "Body"
	end
	return nil
end

local function bbox(p: BasePart): (Vector3, Vector3)
	-- boîte alignée sur les axes du monde (les pièces découpées sont droites)
	local s = p.Size
	local cf = p.CFrame
	local ext = Vector3.new(
		math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
		math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
		math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z
	)
	return cf.Position, ext
end

function Rig.Install(work: Model, key: string, overrides: { [string]: string }?, turn: (boolean | number)?)
	local ring, rarity = nil, nil
	overrides = overrides or {}
	local parts = {}
	-- soudures posées par l'import : les membres doivent bouger seuls
	for _, d in ipairs(work:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("Weld") or d:IsA("Motor6D") then
			d:Destroy()
		end
	end
	for _, d in ipairs(work:GetDescendants()) do
		-- « R1_T1:Head » (nom unique dans Blender) -> « Head »
		if d:IsA("MeshPart") and d.Name:find(":") then
			d.Name = d.Name:match("^.-:(.*)$")
		end
	end
	for _, d in ipairs(work:GetDescendants()) do
		local base = if d:IsA("MeshPart") then d.Name:match("^(.-)__") else nil
		if d:IsA("MeshPart") and (EXACT[d.Name] or (base and EXACT[base])) then
			local follow = if base and base ~= "Body" then base else nil
			table.insert(parts, { part = d, role = base or d.Name, exact = true, follow = follow, path = d:GetFullName() })
		elseif d:IsA("MeshPart") then
			local role = overrides[d.Name]
			if not role then
				-- nom de la pièce, sinon celui de ses parents (« front legs » > « left leg »)
				role = roleFromName(d.Name)
				local anc = d.Parent
				while anc and anc ~= work and (not role or role == "Leg") do
					local r = roleFromName(anc.Name)
					if r and not role then
						role = r
					end
					anc = anc.Parent
				end
			end
			table.insert(parts, { part = d, role = role or "Body", path = d:GetFullName() })
		end
	end
	assert(#parts > 0, "aucune MeshPart")

	-- centre du corps et sens de la tête
	local bodyC, headC, tailC = Vector3.zero, nil, nil
	local frontZ, backZ = nil, nil
	local nb = 0
	for _, e in ipairs(parts) do
		local path = string.lower(e.path)
		if e.role == "Body" then
			bodyC += e.part.Position
			nb += 1
		elseif e.role == "Head" and not e.follow then
			headC = e.part.Position
		elseif e.role == "Tail" then
			tailC = e.part.Position
		elseif e.role == "Leg" and path:find("front") then
			frontZ = e.part.Position.Z
		elseif e.role == "Leg" and path:find("back") then
			backZ = e.part.Position.Z
		end
	end
	local cf0 = work:GetBoundingBox()
	bodyC = if nb > 0 then bodyC / nb else cf0.Position
	-- Les modèles générés ne regardent pas tous du même côté. Vote : tête devant le corps, pattes
	-- avant devant les pattes arrière, queue derrière. Avant = -Z ; si le vote dit +Z, on retourne.
	-- turn = true / false force le choix (vérifié à l'œil quand le vote hésite).
	if turn == nil then
		local score = 0
		if headC then
			score += (headC - bodyC).Z
		end
		if frontZ and backZ then
			score += 2 * (frontZ - backZ)
		end
		if tailC then
			score -= (tailC - bodyC).Z
		end
		turn = score > 0
	end
	-- turn : true = demi-tour, ou un angle en radians (quart de tour pour un modèle couché de travers)
	local yaw = if type(turn) == "number" then turn elseif turn then math.pi else 0
	if yaw ~= 0 then
		local c = cf0.Position
		local rot = CFrame.Angles(0, yaw, 0)
		work:PivotTo(CFrame.new(c) * rot * CFrame.new(c):Inverse() * work:GetPivot())
		bodyC = c + rot:VectorToWorldSpace(bodyC - c)
	end

	-- côtés et avant / arrière (une paire non séparée, à cheval sur le milieu, n'a pas de côté)
	local renamed = {}
	for _, e in ipairs(parts) do
		local p = e.part
		local c, ext = bbox(p)
		local side = if math.abs(c.X - bodyC.X) < ext.X * 0.2 then "" elseif c.X - bodyC.X < 0 then "L" else "R"
		if e.exact then
			-- rôle exact : on garde le type de membre, le côté vient de la position (gauche de la
			-- créature = -X une fois tournée vers -Z ; dans Blender, le « _L » du kit est sa droite)
			local r = e.role
			if not e.follow and side ~= "" then
				local leg = r:match("^(Leg[FB])[LR]$")
				local base = r:match("^(%a+)[LR]$")
				if leg then
					e.role = leg .. side
				elseif base and SIDED[base] then
					e.role = base .. side
				end
			end
			if not e.follow then
				renamed[r] = e.role
			end
			continue
		elseif overrides[p.Name] then
			continue
		end
		if e.role == "Leg" then
			local fb = ""
			local path = string.lower(e.path)
			if path:find("front") or path:find("fore") then
				fb = "F"
			elseif path:find("back") or path:find("hind") or path:find("rear") then
				fb = "B"
			elseif headC then
				-- pattes sans nom avant / arrière : d'après leur position par rapport au milieu du corps
				local rel = c.Z - bodyC.Z
				if math.abs(rel) > ext.Z * 0.6 then
					fb = if rel < 0 then "F" else "B"
				end
			end
			e.role = "Leg" .. fb .. side
		elseif SIDED[e.role] then
			e.role = e.role .. side
		end
	end

	-- les pièces qui suivent un membre renommé suivent son nouveau nom
	for _, e in ipairs(parts) do
		if e.follow and renamed[e.follow] then
			e.follow = renamed[e.follow]
		end
	end

	-- joints
	for _, e in ipairs(parts) do
		local p = e.part
		local c, ext = bbox(p)
		local half = ext / 2
		local top, bottom = c.Y + half.Y, c.Y - half.Y
		local towardBodyX = if bodyC.X - c.X >= 0 then 1 else -1
		local r = e.role
		local joint: Vector3? = nil
		if e.follow then
			-- pas de joint : suit son membre
			r = ""
		end
		if r:sub(1, 3) == "Leg" then
			joint = Vector3.new(c.X, top - ext.Y * 0.08, c.Z)
		elseif r:sub(1, 3) == "Arm" then
			joint = Vector3.new(c.X + towardBodyX * half.X * 0.6, top - ext.Y * 0.15, c.Z)
		elseif r:sub(1, 4) == "Wing" or r:sub(1, 3) == "Fin" or r:sub(1, 3) == "Ear" then
			joint = Vector3.new(c.X + towardBodyX * half.X * 0.9, c.Y, c.Z)
		elseif r == "Tail" then
			-- point de la queue le plus proche du centre du corps
			local q = Vector3.new(
				math.clamp(bodyC.X, c.X - half.X, c.X + half.X),
				math.clamp(bodyC.Y, c.Y - half.Y, c.Y + half.Y),
				math.clamp(bodyC.Z, c.Z - half.Z, c.Z + half.Z)
			)
			joint = q
		elseif r == "Head" then
			joint = Vector3.new(c.X, bottom + ext.Y * 0.2, c.Z + half.Z * 0.5) -- cou, vers l'arrière
		elseif r == "Jaw" then
			joint = Vector3.new(c.X, top, c.Z + half.Z * 0.8) -- charnière en haut, à l'arrière
		elseif r == "Tentacles" then
			joint = Vector3.new(c.X, top, c.Z)
		end
		local old = p:FindFirstChild("Joint")
		if old then
			old:Destroy()
		end
		if joint then
			local a = Instance.new("Attachment")
			a.Name = "Joint"
			a.CFrame = CFrame.new(p.CFrame:PointToObjectSpace(joint))
			a.Parent = p
		end
	end

	-- modèle final
	local final = Instance.new("Model")
	final.Name = key
	local holder = Instance.new("Model")
	holder.Name = "body"
	holder.Parent = final
	local used = {}
	for _, e in ipairs(parts) do
		local p = e.part
		local name = if e.follow then e.follow .. "__" .. (p.Name:match("__(.*)$") or "Glow") else e.role
		used[name] = (used[name] or 0) + 1
		if used[name] > 1 then
			name ..= used[name]
		end
		p.Name = name
		if e.follow then
			p:SetAttribute("Role", nil)
			p:SetAttribute("Follow", e.follow)
		else
			p:SetAttribute("Role", e.role)
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = true
		p.Parent = holder
	end
	for _, d in ipairs(final:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local cf, size = final:GetBoundingBox()
	local bottom = cf.Position - Vector3.new(0, size.Y / 2, 0)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Transparency = 1
	core.Size = Vector3.one * 0.3
	core.CFrame = CFrame.lookAt(bottom, bottom + Vector3.new(0, 0, -1))
	core.Parent = final
	final.PrimaryPart = core
	final:SetAttribute("Ring", ring or tonumber(key:match("^R(%d+)")))
	final:SetAttribute("Rarity", rarity or tonumber(key:match("_T(%d+)")))
	-- taille de référence : la hauteur, ou la longueur pour une créature plate ou allongée (raie,
	-- serpent) : sinon, mise à la hauteur de sa rareté, elle deviendrait immense
	local _, hb = holder:GetBoundingBox()
	final:SetAttribute("Height", math.max(hb.Y, 0.55 * math.max(hb.X, hb.Z)))
	final:SetAttribute("Source", if parts[1] and parts[1].exact then "Blocky" else "RobloxCube3D")
	final:SetAttribute("Rigged", true)
	final.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local folder = game.ReplicatedStorage.Assets.Creatures
	local backup = game.ServerStorage:FindFirstChild("OldCreatures")
	if not backup then
		backup = Instance.new("Folder")
		backup.Name = "OldCreatures"
		backup.Parent = game.ServerStorage
	end
	local prev = folder:FindFirstChild(key)
	if prev then
		if not backup:FindFirstChild(key) then
			prev.Parent = backup
		else
			prev:Destroy()
		end
	end
	final.Parent = folder
	work:Destroy()
	local out = {}
	for _, p in ipairs(holder:GetChildren()) do
		table.insert(out, p.Name)
	end
	table.sort(out)
	return ("%s : %s (h=%.2f)"):format(key, table.concat(out, ", "), size.Y)
end

-- Aperçu : copie de la créature posée à « at », tournée vers +Z (vers une caméra placée devant),
-- hauteur h ; pose = true : membres dans une pose de marche (pour vérifier les joints)
function Rig.Preview(key: string, at: Vector3, h: number, pose: boolean?): Model
	local src = game.ReplicatedStorage.Assets.Creatures[key]
	local m = src:Clone()
	m.Name = "Preview_" .. key
	m:ScaleTo(m:GetScale() * h / (m:GetAttribute("Height") or 1))
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.pi, 0))
	m.Parent = workspace
	if pose then
		local core = m.PrimaryPart
		local angles = {
			LegFL = CFrame.Angles(0.4, 0, 0), LegBR = CFrame.Angles(0.4, 0, 0),
			LegFR = CFrame.Angles(-0.4, 0, 0), LegBL = CFrame.Angles(-0.4, 0, 0),
			LegL = CFrame.Angles(0.4, 0, 0), LegR = CFrame.Angles(-0.4, 0, 0),
			LegF = CFrame.Angles(0.4, 0, 0), LegB = CFrame.Angles(-0.4, 0, 0),
			ArmL = CFrame.Angles(0, 0, -0.9), ArmR = CFrame.Angles(0, 0, 0.9),
			WingL = CFrame.Angles(0, 0, -0.5), WingR = CFrame.Angles(0, 0, 0.5),
			FinL = CFrame.Angles(0, 0, -0.3), FinR = CFrame.Angles(0, 0, 0.3),
			Tail = CFrame.Angles(0, 0.4, 0), Head = CFrame.Angles(0.25, 0.3, 0), Jaw = CFrame.Angles(-0.5, 0, 0),
			Tentacles = CFrame.Angles(0.15, 0, 0.1),
		}
		local headTurn = CFrame.new()
		local list = m.body:GetChildren()
		table.sort(list, function(a, b)
			return (if a.Name == "Head" then 0 else 1) < (if b.Name == "Head" then 0 else 1)
		end)
		for _, p in ipairs(list) do
			local j = p:FindFirstChild("Joint")
			local role = p:GetAttribute("Role")
			local r = role and angles[role]
			if j and r then
				local jc = core.CFrame:PointToObjectSpace(j.WorldPosition)
				local turn = CFrame.new(jc) * r * CFrame.new(-jc)
				if role == "Head" then
					headTurn = turn
				elseif role == "Jaw" then
					turn = headTurn * turn
				end
				p.CFrame = core.CFrame * turn * core.CFrame:ToObjectSpace(p.CFrame)
			end
		end
	end
	return m
end

return Rig
