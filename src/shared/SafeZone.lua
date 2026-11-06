-- Zone où l'on respire : le couloir (entre les bouées, au-delà du quai) et le vaisseau.
-- Le serveur publie la boîte du vaisseau (attributs SafeMin / SafeMax de Workspace.Ship) pour que
-- le client calcule la même chose (flèche de retour dans ColdFx.client).

local Config = require(script.Parent.Config)

local SafeZone = {}

local M = Config.Map
local C = Config.Cold

-- Point sûr le plus proche (même hauteur) et distance horizontale jusqu'à lui (0 = dans la zone)
function SafeZone.Nearest(pos: Vector3): (Vector3, number)
	-- couloir : bande |x| <= demi-largeur, à partir du bout du quai
	local half = M.CorridorWidth / 2 + C.Margin
	local cx = math.clamp(pos.X, -half, half)
	local cz = math.max(pos.Z, M.FrontZ - 4)
	local best = Vector3.new(cx, pos.Y, cz)
	local dist = Vector2.new(pos.X - cx, pos.Z - cz).Magnitude
	-- vaisseau : sa boîte, un peu élargie
	local ship = workspace:FindFirstChild("Ship")
	local mn = ship and ship:GetAttribute("SafeMin")
	local mx = ship and ship:GetAttribute("SafeMax")
	if typeof(mn) == "Vector3" and typeof(mx) == "Vector3" then
		local sx = math.clamp(pos.X, mn.X - C.Margin, mx.X + C.Margin)
		local sz = math.clamp(pos.Z, mn.Z - C.Margin, mx.Z + C.Margin)
		local ds = Vector2.new(pos.X - sx, pos.Z - sz).Magnitude
		if ds < dist then
			best, dist = Vector3.new(sx, pos.Y, sz), ds
		end
	end
	return best, dist
end

return SafeZone
