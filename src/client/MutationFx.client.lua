-- Créatures arc-en-ciel (Config.Mutations, shared/Mutation) : leurs pièces changent de couleur en continu.
-- Chaque pièce porte l'étiquette Mutation.RainbowTag et son décalage de teinte (attribut Hue).
-- Lumières des créatures mutées (Mutation.LightTag) : elles pulsent doucement, chacune à son rythme.
-- Dix fois par seconde suffit : le défilement est lent.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mutation = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Mutation"))

while true do
	local t = os.clock()
	for _, part in ipairs(CollectionService:GetTagged(Mutation.RainbowTag)) do
		if part:IsA("BasePart") then
			part.Color = Mutation.RainbowColor((part:GetAttribute("Hue") or 0) :: number, t)
		end
	end
	for i, light in ipairs(CollectionService:GetTagged(Mutation.LightTag)) do
		if light:IsA("PointLight") then
			local base = (light:GetAttribute("Base") or 1) :: number
			light.Brightness = base * (0.75 + 0.35 * math.sin(t * 2.4 + i * 1.7))
		end
	end
	task.wait(0.1)
end
