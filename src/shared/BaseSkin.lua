-- Applique un thème (Config.BaseSkins) à une base : sol de l'enclos, barrière de bois et atelier.
-- Le rôle de chaque pièce (attribut SkinRole : Floor, Main, Trim, Glass) est posé par tools/build-yard.lua ;
-- le serveur note une fois sa couleur d'origine (SkinDefault), celle du thème de départ (herbe et bois) :
-- le client s'en sert aussi pour les miniatures de la fenêtre BASE SKINS et pour le thème arc-en-ciel.

local Config = require(script.Parent:WaitForChild("Config"))

local BaseSkin = {}

local GROUPS = { "Floor", "Walls", "Annex" }

local function parts(base: Instance): { BasePart }
	local list = {}
	for _, name in ipairs(GROUPS) do
		local group = base:FindFirstChild(name)
		if group and group:IsA("BasePart") then
			table.insert(list, group)
		end
		if group then
			for _, d in ipairs(group:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(list, d)
				end
			end
		end
	end
	return list
end

-- Une seule fois au démarrage, quand les bases ont encore leurs couleurs d'origine
function BaseSkin.Prepare(base: Instance)
	for _, p in ipairs(parts(base)) do
		-- rôle posé par l'outil de construction ; sinon deviné d'après la matière et la couleur
		local role = p:GetAttribute("SkinRole")
		if not role then
			role = "Main"
			if p.Material == Enum.Material.Glass then
				role = "Glass"
			elseif p.BrickColor.Name == "Dove blue" then
				role = "Trim"
			elseif p.BrickColor.Name == "Fog" then
				role = "Floor"
			end
		end
		p:SetAttribute("SkinRole", role)
		p:SetAttribute("SkinDefault", p.Color)
	end
end

function BaseSkin.Apply(base: Instance, key: string?)
	local s = Config.BaseSkin(key)
	for _, p in ipairs(parts(base)) do
		local role = p:GetAttribute("SkinRole")
		local color = role and s[role] or p:GetAttribute("SkinDefault")
		if color then
			p.Color = color
		end
	end
end

-- Thème arc-en-ciel : les couleurs défilent lentement (côté client seulement)
local HUES = {
	Floor = { 0, 0.55, 0.95 },
	Main = { 0.12, 0.25, 1 },
	Trim = { 0.3, 0.8, 0.95 },
	Glass = { 0.45, 0.4, 1 },
}
function BaseSkin.Rainbow(base: Instance, t: number)
	local h = t * Config.BaseSkinRainbowSpeed
	for _, p in ipairs(parts(base)) do
		local hue = HUES[p:GetAttribute("SkinRole")]
		if hue then
			p.Color = Color3.fromHSV((h + hue[1]) % 1, hue[2], hue[3])
		end
	end
end

return BaseSkin
