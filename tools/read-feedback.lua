-- Outil de Studio : affiche les retours des joueurs (boîte aux lettres, FeedbackService) dans la console.
-- À lancer dans la barre de commande, avec « Enable Studio Access to API Services » activé.
-- Change DAYS pour remonter plus loin.

local DAYS = 7
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("Feedback_v1")

for i = 0, DAYS - 1 do
	local key = "d_" .. os.date("!%Y%m%d", os.time() - i * 86400)
	local ok, list = pcall(function()
		return store:GetAsync(key)
	end)
	if not ok then
		warn(key, list)
	elseif type(list) == "table" then
		print(("---- %s : %d retours"):format(key, #list))
		for _, e in ipairs(list) do
			print(("[%s] anneau %s, XP %s, Supernovas %s (joueur %s) : %s"):format(e.c, tostring(e.ring), tostring(e.xp), tostring(e.sn), tostring(e.u), e.x ~= "" and e.x or "(sans texte)"))
		end
	end
end
