-- Fondu des objets lointains (décor des anneaux, relais, bouées, vaisseau vu de loin).
-- Le brouillard « classique » peint tout ce qui est au-delà de Lighting.FogEnd de sa couleur :
-- devant le ciel clair (planète, nébuleuses), ces objets formaient des silhouettes sombres.
-- On les rend transparents juste avant la fin du brouillard : ils se fondent dans le ciel.
-- Les astéroïdes du tapis ont leur propre fondu dans Belt.client (ils bougent à chaque image).

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local FF = Config.FarFade
local PER_FRAME = 500 -- pièces mises à jour par image (le tour complet prend quelques images)

type Entry = { part: BasePart, half: number, fade: number }
local entries: { Entry } = {}
local index: { [BasePart]: Entry } = {}

local function add(d: Instance)
	if d:IsA("BasePart") and not index[d] then
		local e = { part = d, half = d.Size.Magnitude / 2, fade = 0 }
		index[d] = e
		table.insert(entries, e)
	end
end

local function watch(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		add(d)
	end
	root.DescendantAdded:Connect(add)
end

task.spawn(function()
	local world = workspace:WaitForChild("World")
	for _, name in ipairs({ "RingDecor", "Corridor" }) do
		local f = world:WaitForChild(name, 30)
		if f then
			watch(f)
		end
	end
end)
task.spawn(function()
	watch(workspace:WaitForChild("Ship"))
end)

local cursor = 1
RunService.Heartbeat:Connect(function()
	local n = #entries
	if n == 0 then
		return
	end
	local cam = workspace.CurrentCamera.CFrame.Position
	local fogEnd = Lighting.FogEnd
	local a, b = fogEnd * FF.Start, fogEnd * FF.Finish
	local count = math.min(PER_FRAME, n)
	local i = 0
	while i < count do
		if cursor > #entries then
			cursor = 1
		end
		local e = entries[cursor]
		local p = e.part
		if p.Parent == nil then
			-- pièce détruite : on la retire (échange avec la dernière)
			index[p] = nil
			entries[cursor] = entries[#entries]
			entries[#entries] = nil
		else
			-- distance au bord de la pièce (une grande dalle proche ne s'efface pas)
			local dist = (p.Position - cam).Magnitude - e.half
			local fade = math.clamp((dist - a) / (b - a), 0, 1)
			if math.abs(fade - e.fade) > 0.03 or (fade == 0 and e.fade ~= 0) or (fade == 1 and e.fade ~= 1) then
				e.fade = fade
				p.LocalTransparencyModifier = fade
			end
			cursor += 1
		end
		i += 1
	end
end)
