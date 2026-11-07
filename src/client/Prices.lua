-- Prix Robux lus sur Roblox (règle Roblox : jamais de prix en dur, ils peuvent changer selon le pays
-- ou les tests de prix). Prices.Show(label, id, isPass) écrit « … » puis le vrai prix, ou le prix
-- indicatif de Config en secours si Roblox ne répond pas. Un seul appel par article (cache).

local MarketplaceService = game:GetService("MarketplaceService")

local Prices = {}

local cache: { [string]: number } = {}
local waiting: { [string]: { (number?) -> () } } = {}

local function fetch(id: number, isPass: boolean)
	local key = (if isPass then "P" else "D") .. id
	if cache[key] or waiting[key] then
		return
	end
	waiting[key] = {}
	task.spawn(function()
		local price: number? = nil
		for attempt = 1, 3 do
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(id, if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product)
			end)
			if ok and info and type(info.PriceInRobux) == "number" then
				price = info.PriceInRobux
				break
			end
			task.wait(attempt)
		end
		if price then
			cache[key] = price
		end
		for _, fn in ipairs(waiting[key]) do
			fn(price)
		end
		waiting[key] = nil
	end)
end

-- Appelle fn(prix) dès que le prix est connu (nil si Roblox n'a pas répondu)
function Prices.Get(id: number, isPass: boolean, fn: (number?) -> ())
	local key = (if isPass then "P" else "D") .. id
	if cache[key] then
		fn(cache[key])
		return
	end
	fetch(id, isPass)
	if waiting[key] then
		table.insert(waiting[key], fn)
	end
end

-- Écrit le prix dans un texte : « … » pendant le chargement, prix indicatif en secours
function Prices.Show(label: TextLabel, id: number, isPass: boolean, fallback: number?)
	if id == 0 then
		label.Text = "SOON"
		return
	end
	label.Text = "…"
	Prices.Get(id, isPass, function(price)
		if price then
			label.Text = tostring(price)
		elseif fallback then
			label.Text = tostring(fallback)
		else
			label.Text = "?"
		end
	end)
end

return Prices
