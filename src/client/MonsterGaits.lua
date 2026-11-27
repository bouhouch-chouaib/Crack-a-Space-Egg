-- Démarche de chaque monstre (28 nov.) : une fonction par modèle, appelée à chaque image par MonsterRig.
-- Chacun bouge selon son corps : le serpent ondule à plat de tout son long, l'araignée marche par quatre
-- pattes, la raie bat des ailes en vague, le poisson godille de la queue, le colosse marche lourdement...
--   r     : le squelette (r:J(pièce, rx, ry, rz), r:Both(pièce, rx, ry, rz, suite) pour les deux côtés en miroir)
--   t     : temps (secondes)
--   s     : chemin parcouru, en tailles du monstre : les pas suivent la distance, les pattes ne patinent pas
--   k     : ardeur, 0 en promenade, 1 en pleine poursuite
--   lunge : bond final (0 à 1) : mâchoires et pinces se referment
-- Renvoie le décalage du corps (roulis, tangage, rebond) et, pour un corps de serpent, son ondulation :
--   { lat = ampleur de côté, vert = ampleur de haut en bas, len = longueur d'onde, head = part à la tête,
--     drift = glissement sur place } (en tailles du monstre).
-- Sens des angles : voir l'en-tête de MonsterRig.

local sin, cos, abs, max = math.sin, math.cos, math.abs, math.max
local PI = math.pi

local Gaits = {}

-- Patte de côté en deux pièces (cuisse « A », jambe « B ») : elle avance levée, recule posée
local function sideLeg(r: any, name: string, phase: number, swing: number, lift: number)
	local side = r:Side(name .. "A")
	local up = max(0, cos(phase))
	r:J(name .. "A", 0, -side * sin(phase) * swing, side * up * lift)
	r:J(name .. "B", 0, 0, side * up * lift * 0.8)
end

-- Patte sous le corps en trois pièces (épaule ou hanche « A », coude ou genou « B », pied « C »)
local function underLeg(r: any, name: string, phase: number, swing: number)
	local up = max(0, cos(phase))
	r:J(name .. "A", -sin(phase) * swing)
	r:J(name .. "B", up * swing * 1.1)
	r:J(name .. "C", -up * swing * 0.6)
end

-- Suite de pièces qui ondulent l'une après l'autre (queue, cou, tentacule)
local function wave(r: any, name: string, count: number, t: number, speed: number, yaw: number, pitch: number, lag: number, droop: number?)
	for i = 1, count do
		local a = t * speed - i * lag
		r:J(name .. i, sin(a + 0.8) * pitch + (droop or 0), sin(a) * yaw)
	end
end

function Gaits.Default(_r: any, t: number, _s: number, _k: number, _lunge: number): CFrame
	return CFrame.Angles(sin(t * 2) * 0.05, 0, sin(t * 2.5) * 0.06)
end

-- 1. Scarabée de roche : il trottine sur six pattes, trois par trois, la carapace qui tangue
function Gaits.DustSkitter(r, t, s, k, lunge)
	local ph = s * 14
	for i = 1, 3 do
		sideLeg(r, "LegL" .. i, ph + (if i % 2 == 1 then 0 else PI), 0.45, 0.32)
		sideLeg(r, "LegR" .. i, ph + (if i % 2 == 1 then PI else 0), 0.45, 0.32)
	end
	r:Both("Mand", 0, -(0.2 + 0.2 * sin(t * 7)) + lunge * 0.4)
	r:Both("Ant", sin(t * 3.1) * 0.18 - k * 0.25, 0, sin(t * 2.3) * 0.12)
	return CFrame.new(0, abs(sin(ph)) * 0.03 * r.size, 0) * CFrame.Angles(sin(ph * 2) * 0.03, 0, sin(ph) * 0.06)
end

-- 2. Serpent de glace : il ondule à plat de tout son long, la langue qui sort par à-coups
function Gaits.FrostSlink(r, t, _s, k, lunge)
	r:J("Jaw", 0.06 + lunge * 0.55 + max(0, sin(t * 0.9)) * 0.08)
	r:J("Tongue", 0, sin(t * 16) * 0.3 * max(0, sin(t * 1.7)))
	return CFrame.Angles(-0.05, 0, 0), { lat = 0.2 + 0.05 * k, len = 1.1, head = 0.25, drift = 0.25 }
end

-- 3. Ver de lave : sa courte queue fouette de côté, la gueule en corolle s'ouvre et se referme
function Gaits.CinderMaw(r, t, _s, k, lunge)
	local open = 0.12 + 0.14 * sin(t * 2.2) + lunge * 0.5 + k * 0.1
	for i = 0, 7 do
		r:J("Lip" .. i, 0, 0, open + 0.05 * sin(t * 5 + i))
	end
	r:Both("Horn", sin(t * 1.4) * 0.05)
	return CFrame.Angles(sin(t * 1.6) * 0.04, 0, sin(t * 1.1) * 0.05), { lat = 0.16 + 0.06 * k, vert = 0.03, len = 0.9, head = 0.2, drift = 0.3 }
end

-- 4. Raie de la nébuleuse : ses ailes battent en vague de l'épaule au bout, la queue traîne et balance
function Gaits.NebulaStalker(r, t, _s, k, lunge)
	local ph = t * (2 + 1.6 * k)
	for i = 1, 4 do
		local a = 0.04 + (0.05 + 0.03 * i) * sin(ph - i * 0.75)
		r:J("WingL" .. i, 0, 0, r:Side("WingL" .. i) * a)
		r:J("WingR" .. i, 0, 0, r:Side("WingR" .. i) * a)
	end
	wave(r, "Tail", 6, t, 1.7, 0.11, 0.06, 0.55)
	r:J("Jaw", 0.05 + 0.06 * sin(t * 1.3) + lunge * 0.5)
	r:Both("Horn", 0, 0.08 * sin(t * 2.4) - lunge * 0.3)
	return CFrame.new(0, -sin(ph) * 0.025 * r.size, 0) * CFrame.Angles(sin(ph + 1) * 0.05, 0, sin(t * 0.7) * 0.08)
end

-- 5. Dévoreur : il avance comme une chenille, l'onde court le long du corps de haut en bas, pinces qui claquent
function Gaits.Devourer(r, t, _s, k, lunge)
	local snap = 0.2 + 0.22 * sin(t * 2.6) - lunge * 0.5
	r:Both("Mand", 0, -snap, 0, "1")
	r:Both("Mand", 0, -0.18 * sin(t * 2.6 - 0.9), 0, "2")
	r:J("Jaw", 0.1 + 0.1 * sin(t * 3.1) + lunge * 0.5)
	return CFrame.Angles(sin(t * 2) * 0.05, 0, 0), { lat = 0.04, vert = 0.055 + 0.015 * k, len = 1.05, head = 0.15, drift = 0.3 }
end

-- 6. Guetteur : il flotte sans bouger le corps, ses tentacules pendent et traînent, l'anneau tourne, il cligne
function Gaits.Watcher(r, t, _s, k, _lunge)
	for _, side in ipairs({ "L", "R" }) do
		for n = 1, 3 do
			local name = "Tent" .. side .. n .. "_"
			local ph = t * 1.5 + n * 1.9 + (if side == "L" then 0 else 0.9)
			for i = 1, 3 do
				local sgn = r:Side(name .. i)
				r:J(name .. i, k * 0.22 + sin(ph - i * 0.7) * 0.13, 0, sgn * sin(ph * 0.8 - i * 0.6) * 0.09)
			end
		end
	end
	r:J("Halo", 0, 0, t * 0.7)
	local blink = max(0, 1 - abs((t % 4.2) - 0.18) / 0.18)
	r:J("LidUp", blink * 0.5)
	r:J("LidLow", -blink * 0.4)
	return CFrame.new(0, sin(t * 1.3) * 0.035 * r.size, 0) * CFrame.Angles(sin(t * 0.9) * 0.04, 0, sin(t * 0.6) * 0.05)
end

-- 7. Reine du nid : ses quatre ailes vrombissent, les pattes pendent, l'abdomen se recourbe, les faux se lèvent
function Gaits.Queen(r, t, _s, k, lunge)
	local buzz = t * 42
	r:Both("WingUp", 0, 0, 0.2 + 0.4 * sin(buzz))
	r:Both("WingLo", 0, 0, 0.1 + 0.35 * sin(buzz + 1.2))
	for i = 1, 2 do
		for _, side in ipairs({ "L", "R" }) do
			local ph = t * 2.1 + i * 1.3 + (if side == "L" then 0 else 0.7)
			r:J("Leg" .. side .. i .. "A", 0.12 + k * 0.3 + sin(ph) * 0.09)
			r:J("Leg" .. side .. i .. "B", 0.18 + k * 0.2 + sin(ph - 0.8) * 0.12)
		end
	end
	r:Both("Arm", -0.1 + sin(t * 1.5) * 0.12 - lunge * 0.4)
	r:Both("Scythe", sin(t * 1.5 + 1) * 0.2 + lunge * 0.7)
	for i = 1, 3 do
		r:J("Abdo" .. i, -0.07 - 0.06 * sin(t * 2.4 - i * 0.6))
	end
	r:J("Head", sin(t * 1.7) * 0.06)
	r:J("Jaw", 0.08 + 0.08 * sin(t * 3) + lunge * 0.4)
	r:Both("Mandible", 0, -(0.15 + 0.12 * sin(t * 5)))
	return CFrame.new(0, sin(t * 3.2) * 0.02 * r.size, 0) * CFrame.Angles(0.06 + sin(t * 1.9) * 0.03, 0, sin(t * 1.3) * 0.05)
end

-- 8. Baudroie des abysses : elle godille de la queue, le corps contre-braque, les nageoires rament, le leurre danse
function Gaits.AbyssAngler(r, t, s, k, lunge)
	local ph = t * 2.4 + s * 5
	local beat = 0.7 + 0.5 * k
	r:J("Tail1", 0, sin(ph) * 0.14 * beat)
	r:J("Tail2", 0, sin(ph - 0.8) * 0.22 * beat)
	r:J("Tail3", 0, sin(ph - 1.6) * 0.34 * beat)
	r:Both("Pec", 0, 0.15 * sin(t * 2.6), 0.18 + 0.28 * sin(t * 2.6 + 0.9))
	r:J("Jaw", 0.1 + 0.09 * sin(t * 1.1) + lunge * 0.6)
	wave(r, "Stalk", 3, t, 1.9, 0.07, 0.1, 0.7, k * 0.12)
	r:J("Dorsal", 0, 0, sin(t * 3) * 0.07)
	return CFrame.Angles(0, -sin(ph) * 0.07 * beat, sin(ph - 0.5) * 0.04)
end

-- 9. Hydre d'orage : elle trotte, les pattes en diagonale, ses trois cous ondulent chacun pour soi
function Gaits.StormHydra(r, t, s, k, lunge)
	local ph = s * 9
	underLeg(r, "ForeL", ph, 0.4)
	underLeg(r, "HindR", ph + 0.4, 0.4)
	underLeg(r, "ForeR", ph + PI, 0.4)
	underLeg(r, "HindL", ph + PI + 0.4, 0.4)
	for n, name in ipairs({ "L", "C", "R" }) do
		local off = n * 2.1
		for i = 1, 3 do
			r:J("Neck" .. name .. i, sin(t * 0.9 + off - i * 0.6) * 0.09, sin(t * 1.15 + off - i * 0.5) * 0.11)
		end
		r:J("Head" .. name, sin(t * 1.3 + off) * 0.12)
		r:J("Jaw" .. name, max(0, sin(t * 1.7 + off)) * 0.32 + lunge * 0.4)
	end
	r:Both("Wing", 0, 0, 0.12 + 0.22 * sin(t * 2), "A")
	r:Both("Wing", 0, 0, 0.18 * sin(t * 2 - 0.8), "B")
	wave(r, "Tail", 4, t, 1.5, 0.15, 0.05, 0.6)
	return CFrame.new(0, abs(sin(ph)) * 0.025 * r.size, 0) * CFrame.Angles(sin(ph * 2) * 0.025 - k * 0.05, 0, sin(ph) * 0.03)
end

-- 10. Araignée mécanique : huit pattes, quatre en l'air pendant que quatre poussent, rouages et aiguilles qui tournent
function Gaits.GearSpider(r, t, s, k, lunge)
	local ph = s * 10
	for i = 1, 4 do
		sideLeg(r, "LegL" .. i, ph + (if i % 2 == 1 then 0 else PI), 0.32, 0.3)
		sideLeg(r, "LegR" .. i, ph + (if i % 2 == 1 then PI else 0), 0.32, 0.3)
	end
	local turn = t * (1.4 + 2 * k)
	r:J("GearAL", 0, 0, turn)
	r:J("GearAR", 0, 0, -turn)
	r:J("GearBL", 0, 0, -turn * 1.5)
	r:J("GearBR", 0, 0, turn * 1.5)
	r:J("HandM", 0, 0, t * 1.2)
	r:J("HandH", 0, 0, t * 0.1)
	r:Both("Pincer", 0, -(0.12 + 0.16 * sin(t * 3)) + lunge * 0.35)
	r:J("SteamA", sin(t * 2.3) * 0.08, 0, sin(t * 1.9) * 0.08)
	r:J("SteamB", sin(t * 2.1 + 1) * 0.08, 0, sin(t * 1.7 + 2) * 0.08)
	return CFrame.new(0, sin(ph * 2) * 0.012 * r.size, 0) * CFrame.Angles(0, 0, sin(ph) * 0.03)
end

-- 11. Ver acide : un vrai serpent, long, qui ondule à plat en grandes boucles ; le capuchon s'ouvre en poursuite
function Gaits.SourWorm(r, t, _s, k, lunge)
	r:Both("Hood", 0, -(0.05 + 0.3 * k + lunge * 0.2))
	r:Both("Ant", sin(t * 2.8) * 0.2 - k * 0.3, 0, sin(t * 2.1) * 0.14)
	return CFrame.Angles(-0.1 - 0.08 * k, 0, 0), { lat = 0.3 + 0.08 * k, len = 1.5, head = 0.2, drift = 0.3 }
end

-- 12. Béhémoth des spores : il marche sur les poings comme un gorille, le bras gauche avec la jambe droite
function Gaits.SporeBehemoth(r, t, s, _k, lunge)
	local ph = s * 8
	r:J("ArmLA", -sin(ph) * 0.42)
	r:J("ArmLB", -max(0, cos(ph)) * 0.4)
	r:J("ArmRA", sin(ph) * 0.42)
	r:J("ArmRB", -max(0, -cos(ph)) * 0.4)
	r:J("LegL", sin(ph) * 0.3)
	r:J("LegR", -sin(ph) * 0.3)
	r:J("Head", sin(ph * 2) * 0.04 + sin(t * 1.1) * 0.03)
	r:J("Jaw", 0.06 + 0.05 * sin(t * 2) + lunge * 0.5)
	r:J("Cap", sin(ph * 2 + 1.2) * 0.04, 0, -sin(ph - 0.6) * 0.07)
	return CFrame.new(0, -abs(sin(ph)) * 0.03 * r.size, 0) * CFrame.Angles(0.08, 0, sin(ph) * 0.07)
end

-- 13. Colosse du temple : une marche lourde sur deux jambes, les bras balancent à l'opposé, le panache suit
function Gaits.TempleColossus(r, t, s, _k, lunge)
	local ph = s * 7
	r:J("LegL", -sin(ph) * 0.42)
	r:J("LegR", sin(ph) * 0.42)
	r:J("ArmLA", sin(ph) * 0.32 - lunge * 0.5)
	r:J("ArmRA", -sin(ph) * 0.32 - lunge * 0.5)
	r:J("ArmLB", -0.2 - max(0, -sin(ph)) * 0.3)
	r:J("ArmRB", -0.2 - max(0, sin(ph)) * 0.3)
	r:J("Head", sin(t * 0.8) * 0.04, sin(ph) * 0.05)
	r:J("Plume", sin(ph * 2 + 1) * 0.07, 0, sin(ph - 0.7) * 0.06)
	r:J("Skirt", sin(ph * 2) * 0.06)
	return CFrame.new(0, abs(sin(ph)) * 0.035 * r.size, 0) * CFrame.Angles(0.03, sin(ph) * 0.06, sin(ph) * 0.045)
end

-- 14. Roi fantôme : il glisse penché en avant, la robe traîne, les bras se tendent, les lanternes se balancent
function Gaits.PhantomKing(r, t, _s, k, lunge)
	r:Both("Arm", -0.1 + sin(t * 1.2) * 0.12 - lunge * 0.5, 0, 0, "A")
	r:Both("Arm", sin(t * 1.5 + 1) * 0.16 - lunge * 0.3, 0, 0, "B")
	for i, name in ipairs({ "LanL", "LanR", "LanBL", "LanBR" }) do
		r:J(name, k * 0.3 + sin(t * 1.7 + i * 1.4) * 0.14, 0, sin(t * 2.1 + i * 1.9) * 0.22)
	end
	for i = 1, 5 do
		r:J("Tail" .. i, sin(t * 1.8 - i * 0.6) * 0.09 - k * 0.05, sin(t * 1.3 - i * 0.7) * 0.11)
	end
	for i = 1, 4 do
		local a = sin(t * 3 - i * 0.8) * 0.2
		r:J("FinL" .. i, 0, 0, r:Side("FinL" .. i) * a)
		r:J("FinR" .. i, 0, 0, r:Side("FinR" .. i) * a)
	end
	r:J("Cape", -k * 0.2 + sin(t * 1.6) * 0.05)
	return CFrame.new(0, sin(t * 1.4) * 0.03 * r.size, 0) * CFrame.Angles(0.05 + 0.12 * k, 0, sin(t * 0.8) * 0.06)
end

return Gaits
