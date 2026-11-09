-- Télécharge dès l'arrivée du joueur la texture de chaque créature, en arrière-plan.
-- Sans ça, une créature vue pour la première fois reste grise une à deux secondes :
-- ses pièces n'ont qu'une couleur neutre le temps que sa texture arrive.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Creatures")

-- Une pièce par texture suffit : toutes les pièces d'une créature partagent la même
local seen: { [string]: boolean } = {}
local parts: { Instance } = {}
for _, d in ipairs(folder:GetDescendants()) do
	if d:IsA("MeshPart") and d.TextureID ~= "" and not seen[d.TextureID] then
		seen[d.TextureID] = true
		table.insert(parts, d)
	end
end

local function preload(): boolean
	local complete = true
	local ok = pcall(function()
		ContentProvider:PreloadAsync(parts, function(_, status)
			if status == Enum.AssetFetchStatus.Failure then
				complete = false
			end
		end)
	end)
	return ok and complete
end

-- Un réseau capricieux ne doit pas laisser des créatures grises : un second essai suffit
if not preload() then
	task.wait(5)
	preload()
end
