-- Mise en forme des nombres affichés (1,2K, 3,4M...)

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Short(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return string.format("%d", n)
	end
	local i = 1
	local v = n
	while v >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	if v >= 100 then
		return string.format("%d%s", math.floor(v), SUFFIXES[i])
	end
	return string.format("%.1f%s", math.floor(v * 10) / 10, SUFFIXES[i])
end

-- "1 in 400" pour une probabilité
function Format.OneIn(p: number): string
	if p <= 0 then
		return "-"
	end
	if p >= 0.1 then
		return string.format("%d%%", math.floor(p * 100 + 0.5))
	end
	return "1 in " .. Format.Short(math.floor(1 / p + 0.5))
end

return Format
