-- Squelette des monstres (28 nov.) : fait bouger les pièces d'un modèle articulé (Assets.Monsters, rangé par
-- tools/build-monsters.lua) selon la démarche du monstre (MonsterGaits). Deux sortes de pièces :
--   - articulations : soudées à la pièce qui les porte par leur charnière (PivotOffset) ; la démarche donne
--     leurs angles à chaque image (rig:J) ;
--   - tronçons d'un corps de serpent (attribut Chain) : libres, posés à chaque image le long du chemin que la
--     tête vient de parcourir, à plat, avec une ondulation qui reste fixe dans l'espace pendant que le corps
--     glisse dedans (c'est ainsi qu'un serpent avance).
-- Angles dans le repère du modèle au repos (l'avant = +Z, le haut = +Y) :
--   rx > 0 : l'avant d'une pièce descend (une patte qui pend part vers l'arrière) ;
--   ry > 0 : l'avant tourne vers +X ;   rz > 0 : le côté +X monte.
-- side = +1 pour une pièce du côté +X, -1 de l'autre : multiplier un angle par side donne le geste en miroir.
-- Pour une pièce dont l'axe est imposé (roue, pétale), c'est rz qui tourne autour de cet axe.

local Gaits = require(script.Parent:WaitForChild("MonsterGaits"))

local Rig = {}
Rig.__index = Rig

type Joint = { weld: Weld, base: CFrame, side: number }
type Seg = { part: BasePart, d: number, y: number }
export type Wave = { lat: number?, vert: number?, len: number?, head: number?, drift: number? }

local IDENT = CFrame.identity
local UP = Vector3.yAxis
local TAU = math.pi * 2

local function quiet(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
end

-- model : copie du modèle, déjà à sa taille ; size : taille du monstre (Config.Monsters.Kinds[].Size) ;
-- rush : vitesse de ses gestes à pleine ardeur (1 = comme en promenade)
function Rig.new(model: Model, size: number, rush: number?)
	local root = model.PrimaryPart :: BasePart
	local self = setmetatable({
		model = model,
		root = root,
		size = size,
		joints = {} :: { [string]: Joint },
		segs = {} :: { Seg },
		gait = Gaits[model:GetAttribute("Kind") or model.Name] or Gaits.Default,
		travel = 0,
		rush = rush or 1,
		clock = 0, -- temps propre au monstre : il s'écoule plus vite en poursuite
		tick = nil :: number?,
		last = nil :: Vector3?,
		pts = {} :: { Vector3 }, -- chemin de la tête, du plus ancien au plus récent
		q = {} :: { Vector3 },
	}, Rig)
	local parts: { [string]: BasePart } = {}
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= root then
			parts[p.Name] = p
			quiet(p)
		end
	end
	local function weld(parent: BasePart, p: BasePart, at: CFrame): Weld
		local w = Instance.new("Weld")
		w.Part0 = parent
		w.Part1 = p
		w.C0 = parent.CFrame:ToObjectSpace(at)
		w.C1 = p.CFrame:ToObjectSpace(at)
		w.Parent = p
		p.Anchored = false
		return w
	end
	for name, p in pairs(parts) do
		local glowOf = p:GetAttribute("Glow")
		if glowOf then
			weld(parts[glowOf :: string] or root, p, p.CFrame)
		elseif p:GetAttribute("Chain") then
			local off = root.CFrame:PointToObjectSpace(p.Position)
			p.Anchored = true
			table.insert(self.segs, { part = p, d = math.max(0.1, off.Z), y = off.Y })
		else
			local parent = parts[(p:GetAttribute("Joint") or "") :: string] or root
			local hinge = p.CFrame * p.PivotOffset
			local w = weld(parent, p, hinge)
			local hx = root.CFrame:PointToObjectSpace(hinge.Position).X
			self.joints[name] = { weld = w, base = w.C0, side = if hx > size * 0.004 then -1 elseif hx < -size * 0.004 then 1 else 0 }
		end
	end
	table.sort(self.segs, function(a, b)
		return a.d < b.d
	end)
	return self
end

-- Angles d'une articulation (radians) ; rien si le monstre n'a pas cette pièce
function Rig:J(name: string, rx: number, ry: number?, rz: number?)
	local j = self.joints[name]
	if j then
		j.weld.C0 = j.base * CFrame.Angles(rx, ry or 0, rz or 0)
	end
end

-- La même articulation des deux côtés (« <nom>L<suite> » et « <nom>R<suite> ») : ry et rz sont pris en miroir
function Rig:Both(name: string, rx: number, ry: number?, rz: number?, suffix: string?)
	for _, s in ipairs({ "L", "R" }) do
		local j = self.joints[name .. s .. (suffix or "")]
		if j then
			j.weld.C0 = j.base * CFrame.Angles(rx, (ry or 0) * j.side, (rz or 0) * j.side)
		end
	end
end

function Rig:Side(name: string): number
	local j = self.joints[name]
	return if j then j.side else 0
end

-- Le monstre vient d'être replacé loin de là où il était : le chemin repart tout droit derrière lui
function Rig:Reset()
	self.pts = {}
	self.last = nil
end

-- Point du chemin à la distance d derrière `from` (et la direction vers la tête à cet endroit)
local function along(pts: { Vector3 }, from: Vector3, back: Vector3, d: number): (Vector3, Vector3)
	local at = from
	local left = d
	for i = #pts, 1, -1 do
		local step = at - pts[i]
		local len = step.Magnitude
		if len >= left and len > 1e-4 then
			return at - step / len * left, step / len
		end
		left -= len
		at = pts[i]
	end
	return at + back * left, -back
end

-- base : où est le monstre et où il regarde ; k : ardeur (0 en promenade, 1 en poursuite) ; lunge : bond (0 à 1)
function Rig:Step(base: CFrame, now: number, k: number, lunge: number)
	-- ses gestes suivent son propre temps, qui file plus vite quand il poursuit
	self.clock += math.clamp(now - (self.tick or now), 0, 0.1) * (1 + (self.rush - 1) * k)
	self.tick = now
	local t = self.clock
	local pos = base.Position
	if self.last then
		self.travel += (pos - self.last).Magnitude
	end
	self.last = pos
	local size = self.size
	local body, wave: Wave? = self.gait(self, t, self.travel / size, k, lunge)
	local rootCF = base * (body or IDENT)
	local segs = self.segs
	if #segs > 0 then
		local w = wave or {}
		local pts = self.pts
		local look = base.LookVector
		local total = segs[#segs].d + size
		if #pts == 0 then
			table.insert(pts, pos - look * total)
			table.insert(pts, pos - look * 0.01)
		elseif (pos - pts[#pts]).Magnitude > size * 0.03 then
			table.insert(pts, pos)
			-- on oublie ce qui est plus loin que le bout de la queue
			local len = 0
			for i = #pts, 2, -1 do
				len += (pts[i] - pts[i - 1]).Magnitude
				if len > total then
					for _ = 1, i - 2 do
						table.remove(pts, 1)
					end
					break
				end
			end
		end
		local lat, vert = (w.lat or 0) * size, (w.vert or 0) * size
		local waveLen = math.max(0.05, w.len or 0.6) * size
		local head = w.head or 0.3
		local slide = self.travel + t * (w.drift or 0.12) * size
		local ramp = segs[#segs].d * 0.3
		local function offset(d: number, tangent: Vector3): Vector3
			local env = head + (1 - head) * math.min(1, d / ramp)
			local a = TAU * (d - slide) / waveLen
			local n = Vector3.new(tangent.Z, 0, -tangent.X)
			n = if n.Magnitude > 1e-3 then n.Unit else Vector3.xAxis
			return n * (lat * env * math.sin(a)) + UP * (vert * env * math.sin(a + 1.3))
		end
		local q = self.q
		for i, s in ipairs(segs) do
			local p, tangent = along(pts, pos, -look, s.d)
			q[i] = p + offset(s.d, tangent) + UP * s.y
		end
		-- la tête ondule un peu elle aussi et regarde dans le sens de son cou
		local headPos = pos + offset(0, look)
		local neck = headPos - (q[1] - UP * segs[1].y)
		local dir = if neck.Magnitude > 1e-3 then look:Lerp(neck.Unit, 0.5) else look
		rootCF = CFrame.lookAt(headPos, headPos + dir) * (body or IDENT)
		for i, s in ipairs(segs) do
			local before = if i == 1 then headPos + UP * s.y else q[i - 1] + UP * (s.y - segs[i - 1].y)
			local after = if i == #segs then q[i] * 2 - before else q[i + 1] + UP * (s.y - segs[i + 1].y)
			local toHead = before - after
			if toHead.Magnitude > 1e-3 then
				s.part.CFrame = CFrame.lookAt(q[i], q[i] - toHead)
			end
		end
	end
	self.root.CFrame = rootCF
end

return Rig
