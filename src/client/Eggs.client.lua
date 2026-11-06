-- Animation des œufs (tag CollectionService « Egg », modèles ReplicatedStorage.Assets.Eggs.RX_TY).
-- Plus l'œuf est rare, plus il bouge : il flotte, ses pièces séparées s'animent
-- (Orbit : anneau ou cristaux en orbite ; Halo : halo qui tourne ; Crown : couronne qui tourne ;
-- WingL / WingR : ailes qui battent), ses rayons tournent et sa lumière respire.
-- Tout est calculé ici, chez chaque joueur : rien à téléverser, rien côté serveur.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera
local MAX_DISTANCE = 160

type Part = { model: Model, offset: CFrame, root: Vector3?, side: number }
type EggState = {
	model: Model,
	core: BasePart,
	base: CFrame, -- position de repos du centre
	rarity: number,
	phase: number,
	parts: { [string]: Part },
	others: { BasePart }, -- pièces fixes (suivent le flottement)
	otherOffsets: { CFrame },
	light: PointLight?,
	lightBase: number,
	rays: ImageLabel?,
	rays2: ImageLabel?,
}

local eggs: { [Model]: EggState } = {}

local function track(model: Instance)
	if not model:IsA("Model") or eggs[model] then
		return
	end
	-- Avec le chargement en continu, les pièces peuvent arriver après le modèle : on attend le centre
	local core = model:WaitForChild("Core", 10) :: BasePart?
	if not core or eggs[model] then
		return
	end
	task.wait(0.2) -- laisse arriver les pièces animées
	local rarity = (model:GetAttribute("Rarity") or 1) :: number
	if rarity < 3 then
		return -- les œufs simples restent posés
	end
	local st: EggState = {
		model = model,
		core = core,
		base = core.CFrame,
		rarity = rarity,
		phase = math.random() * 10,
		parts = {},
		others = {},
		otherOffsets = {},
		light = core:FindFirstChildOfClass("PointLight"),
		lightBase = 0,
		rays = nil,
		rays2 = nil,
	}
	if st.light then
		st.lightBase = st.light.Brightness
	end
	local bb = core:FindFirstChild("Rays")
	if bb then
		st.rays = bb:FindFirstChild("Rays") :: ImageLabel?
		st.rays2 = bb:FindFirstChild("Rays2") :: ImageLabel?
	end
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Model") then
			local p: Part = { model = child, offset = core.CFrame:ToObjectSpace(child:GetPivot()), root = nil, side = 1 }
			if child.Name == "WingL" or child.Name == "WingR" then
				-- l'aile bat autour de son bord le plus proche du corps
				local cf, size = child:GetBoundingBox()
				local rel = core.CFrame:PointToObjectSpace(cf.Position)
				p.side = if rel.X >= 0 then 1 else -1
				p.root = core.CFrame:PointToObjectSpace(cf.Position - core.CFrame.RightVector * p.side * size.X * 0.45)
			end
			st.parts[child.Name] = p
		elseif child:IsA("BasePart") and child ~= core then
			table.insert(st.others, child)
			table.insert(st.otherOffsets, core.CFrame:ToObjectSpace(child.CFrame))
		end
	end
	eggs[model] = st
end

local function untrack(model: Instance)
	eggs[model :: Model] = nil
end

CollectionService:GetInstanceAddedSignal("Egg"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Egg"):Connect(untrack)
for _, m in ipairs(CollectionService:GetTagged("Egg")) do
	task.spawn(track, m)
end

local SPIN = { Orbit = 0.7, Halo = 1.1, Crown = 0.45 }

local moveParts: { BasePart } = {}
local moveCFrames: { CFrame } = {}

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local camPos = camera.CFrame.Position
	table.clear(moveParts)
	table.clear(moveCFrames)
	for model, st in pairs(eggs) do
		if not model.Parent then
			eggs[model] = nil
			continue
		end
		if (st.base.Position - camPos).Magnitude > MAX_DISTANCE then
			continue
		end
		local r = st.rarity
		local ph = st.phase
		-- flottement et léger balancement, plus amples pour les plus rares
		local amp = 0.12 * (r - 2)
		local center = st.base
			* CFrame.new(0, math.sin(t * 1.6 + ph) * amp, 0)
			* CFrame.Angles(math.sin(t * 1.1 + ph) * 0.02 * (r - 2), t * 0.15 * (r - 3), math.cos(t * 1.3 + ph) * 0.02 * (r - 2))
		table.insert(moveParts, st.core)
		table.insert(moveCFrames, center)
		for i, p in ipairs(st.others) do
			table.insert(moveParts, p)
			table.insert(moveCFrames, center * st.otherOffsets[i])
		end
		for name, p in pairs(st.parts) do
			local cf: CFrame
			if SPIN[name] then
				local dir = if name == "Orbit" and r >= 6 then -1 else 1
				cf = center * CFrame.Angles(0, t * SPIN[name] * dir, 0) * p.offset
			elseif p.root then
				-- battement d'aile autour de sa racine
				local a = math.sin(t * 4 + ph) * 0.28 * p.side
				local rootCF = CFrame.new(p.root)
				cf = center * rootCF * CFrame.Angles(0, 0, a) * rootCF:Inverse() * p.offset
			else
				cf = center * p.offset
			end
			p.model:PivotTo(cf)
		end
		-- rayons qui tournent, lumière qui respire
		if st.rays then
			st.rays.Rotation = (t * 25) % 360
		end
		if st.rays2 then
			st.rays2.Rotation = (-t * 40) % 360
		end
		if st.light then
			st.light.Brightness = st.lightBase * (1 + 0.35 * math.sin(t * 2.5 + ph))
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
