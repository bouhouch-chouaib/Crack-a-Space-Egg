-- Créatures arc-en-ciel (Config.Mutations, shared/Mutation) : leurs pièces changent de couleur en continu.
-- Chaque pièce porte l'étiquette Mutation.RainbowTag et son décalage de teinte (attribut Hue).
-- Lumières des créatures mutées (Mutation.LightTag) : elles pulsent doucement, chacune à son rythme.
-- Reflets sur la peau (Mutation.ShineTag) : la bande de reflet glisse en continu sur le corps et la tête.
-- Vingt fois par seconde suffit : couleurs et reflets bougent doucement.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mutation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Mutation"))

local SHINE_PERIOD = 2.6 -- secondes entre deux passages du reflet

while true do
	local t = os.clock()
	for _, part in ipairs(CollectionService:GetTagged(Mutation.RainbowTag)) do
		if part:IsA("BasePart") then
			part.Color = Mutation.RainbowColor((part:GetAttribute("Hue") or 0) :: number, t)
		elseif part:IsA("Texture") then
			-- voile de couleur posé sur la peau
			part.Color3 = Mutation.RainbowColor((part:GetAttribute("Hue") or 0) :: number, t)
		end
	end
	for _, shine in ipairs(CollectionService:GetTagged(Mutation.ShineTag)) do
		if shine:IsA("Texture") then
			-- un passage toutes les SHINE_PERIOD secondes environ, quelle que soit la taille de la créature
			shine.OffsetStudsU = (t / SHINE_PERIOD % 1) * shine.StudsPerTileU
		end
	end
	for i, light in ipairs(CollectionService:GetTagged(Mutation.LightTag)) do
		if light:IsA("PointLight") then
			local base = (light:GetAttribute("Base") or 1) :: number
			light.Brightness = base * (0.75 + 0.35 * math.sin(t * 2.4 + i * 1.7))
		end
	end
	task.wait(0.05)
end
