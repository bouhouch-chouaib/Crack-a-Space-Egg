-- Promenade des monstres parmi les astéroïdes (29 nov., Config.Monsters.Kinds[].Move) :
--   Float : il flotte librement dans le couloir (raie, poisson, guêpe, œil, fantôme) : Config.MonsterPatrol ;
--   Walk  : il se tient sur un astéroïde, le traverse à pied, puis saute sur le suivant (scarabée, araignée,
--           hydre, gorille, colosse) ;
--   Crawl : il rampe à plat autour d'un astéroïde, puis file vers le suivant (serpents et vers).
-- Pour Walk et Crawl, le serveur (MonsterService) choisit une étape : un astéroïde A où le monstre se trouve
-- de t0 à t1, puis le trajet vers un astéroïde B de t1 à t2. Il la publie telle quelle (attribut Leg du
-- monstre, une chaîne) ; le serveur et chaque joueur en tirent la même position à chaque instant avec
-- Path.At, sans rien envoyer d'autre. Un astéroïde est décrit par la formule de son défilement (celle de
-- BeltService) ; un simple point de l'espace est un « astéroïde » immobile et sans taille (fixed).

local Config = require(script.Parent.Config)

local Path = {}

export type Spot = { r: number, a0: number, h: number, om: number, t0: number, sx: number, sy: number, fixed: boolean }
export type Leg = { a: Spot, b: Spot, t0: number, t1: number, t2: number, ang: number, turn: number, ang2: number }

-- Formule de défilement d'un astéroïde (BeltService) ; size : sa pièce (largeur, hauteur)
function Path.Rock(radius: number, angle0: number, height: number, omega: number, t0: number, sx: number, sy: number): Spot
	return { r = radius, a0 = angle0, h = height, om = omega, t0 = t0, sx = sx, sy = sy, fixed = false }
end

-- Point immobile de l'espace
function Path.Point(pos: Vector3): Spot
	local m = Config.Map
	local z = pos.Z + m.AxisDistance - m.FrontZ
	return { r = math.sqrt(pos.X * pos.X + z * z), a0 = math.atan2(pos.X, z), h = pos.Y, om = 0, t0 = 0, sx = 0, sy = 0, fixed = true }
end

function Path.Center(s: Spot, t: number): Vector3
	return Config.OrbitPosition(s.r, s.a0 + s.om * (t - s.t0), s.h)
end

-- Position en travers du couloir (0 au centre) d'un astéroïde à l'instant t
function Path.Across(s: Spot, t: number): number
	return s.r * math.sin(s.a0 + s.om * (t - s.t0))
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Marcheur : sur le dessus de l'astéroïde, à la distance u du centre dans la direction ang
local function top(s: Spot, t: number, ang: number, u: number, foot: number): Vector3
	local c = Path.Center(s, t)
	if s.fixed then
		return c
	end
	return c + Vector3.new(math.cos(ang) * u, s.sy / 2 + foot, math.sin(ang) * u)
end

-- Rampeur : contre le flanc de l'astéroïde, à l'angle ang, à mi-hauteur
local function flank(s: Spot, t: number, ang: number, gap: number): Vector3
	local c = Path.Center(s, t)
	if s.fixed then
		return c
	end
	local d = s.sx / 2 + gap
	return c + Vector3.new(math.cos(ang) * d, 0, math.sin(ang) * d)
end

-- Demi-largeur du trajet à pied sur le dessus d'un astéroïde
local function pace(s: Spot): number
	return s.sx * 0.28
end

local function at(leg: Leg, t: number, mode: string, size: number, foot: number): Vector3
	local a, b = leg.a, leg.b
	if mode == "Walk" then
		local wa, wb = pace(a), pace(b)
		if t <= leg.t1 then
			local k = if leg.t1 > leg.t0 then (t - leg.t0) / (leg.t1 - leg.t0) else 1
			return top(a, t, leg.ang, -wa + 2 * wa * math.clamp(k, 0, 1), foot)
		end
		local k = if leg.t2 > leg.t1 then math.clamp((t - leg.t1) / (leg.t2 - leg.t1), 0, 1) else 1
		local from = top(a, t, leg.ang, wa, foot)
		local to = top(b, t, leg.ang2, -wb, foot)
		-- un bond : l'élan vient vite, la retombée aussi
		local jump = math.clamp((to - from).Magnitude * 0.28, size * 0.2, size * 1.2)
		return from:Lerp(to, k) + Vector3.new(0, 4 * k * (1 - k) * jump, 0)
	end
	-- Crawl
	local gap = size * 0.22
	if t <= leg.t1 then
		local k = if leg.t1 > leg.t0 then math.clamp((t - leg.t0) / (leg.t1 - leg.t0), 0, 1) else 1
		return flank(a, t, leg.ang + leg.turn * k, gap)
	end
	local k = if leg.t2 > leg.t1 then math.clamp((t - leg.t1) / (leg.t2 - leg.t1), 0, 1) else 1
	local from = flank(a, t, leg.ang + leg.turn, gap)
	local to = flank(b, t, leg.ang2, gap)
	return from:Lerp(to, smooth(k))
end

-- Position et direction du monstre à l'instant t sur cette étape.
-- mode : "Walk" ou "Crawl" ; size : taille du monstre ; foot : distance de son centre à ses pieds
function Path.At(leg: Leg, t: number, mode: string, size: number, foot: number): (Vector3, Vector3)
	local p = at(leg, t, mode, size, foot)
	local ahead = at(leg, t + 0.2, mode, size, foot) - p
	-- on retire le défilement de l'astéroïde : le monstre regarde où il va sur la roche, pas où la roche l'emporte
	local s = if t <= leg.t1 then leg.a else leg.b
	local drift = Path.Center(s, t + 0.2) - Path.Center(s, t)
	local own = ahead - drift
	local look = if own.Magnitude > 0.05 then own.Unit elseif ahead.Magnitude > 0.01 then ahead.Unit else Vector3.zAxis
	return p, look
end

local function spotText(s: Spot): string
	return string.format("%.3f,%.6f,%.3f,%.8f,%.3f,%.2f,%.2f,%d", s.r, s.a0, s.h, s.om, s.t0, s.sx, s.sy, if s.fixed then 1 else 0)
end

function Path.Encode(leg: Leg): string
	return table.concat({ spotText(leg.a), spotText(leg.b), string.format("%.3f,%.3f,%.3f,%.4f,%.4f,%.4f", leg.t0, leg.t1, leg.t2, leg.ang, leg.turn, leg.ang2) }, "|")
end

local function numbers(text: string): { number }
	local out = {}
	for piece in string.gmatch(text, "[^,]+") do
		table.insert(out, tonumber(piece) or 0)
	end
	return out
end

local function spotFrom(text: string): Spot
	local n = numbers(text)
	return { r = n[1], a0 = n[2], h = n[3], om = n[4], t0 = n[5], sx = n[6], sy = n[7], fixed = n[8] == 1 }
end

function Path.Decode(text: any): Leg?
	if type(text) ~= "string" then
		return nil
	end
	local parts = string.split(text, "|")
	if #parts ~= 3 then
		return nil
	end
	local n = numbers(parts[3])
	if #n < 6 then
		return nil
	end
	return { a = spotFrom(parts[1]), b = spotFrom(parts[2]), t0 = n[1], t1 = n[2], t2 = n[3], ang = n[4], turn = n[5], ang2 = n[6] }
end

return Path
