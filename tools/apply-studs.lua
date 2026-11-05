-- Pose la texture de picots carrés (studs) sur toutes les faces des pièces visibles.
-- À lancer dans Studio avec ropilot_edit_ctx_run_command (ou la barre de commande).
-- La texture est transparente : chaque pièce garde sa couleur et gagne les picots.
-- Relançable sans risque : les anciennes textures « Studs » sont remplacées.
local STUDS = "rbxassetid://99589690361139" -- d'après la case « Studs » de la texture intégrée de Roblox (2 x 2 picots)
local ROOTS = {
	workspace:FindFirstChild("Ship"),
	game.ReplicatedStorage:FindFirstChild("Assets") and game.ReplicatedStorage.Assets:FindFirstChild("Corridor"),
	game.ReplicatedStorage:FindFirstChild("Assets") and game.ReplicatedStorage.Assets:FindFirstChild("BaseKit"),
}
local SKIP_MATERIALS = { [Enum.Material.Glass] = true, [Enum.Material.Neon] = true, [Enum.Material.ForceField] = true }
local SKIP_NAMES = { SignText = true, NameBoard = true, CreatureArea = true, DockEnd = true }

local count = 0
for _, root in ipairs(ROOTS) do
	if root then
		for _, p in ipairs(root:GetDescendants()) do
			if p:IsA("BasePart") and not p:IsA("SpawnLocation") then
				local s = p.Size
				local tiny = (s.X < 0.6 and s.Y < 0.6) or (s.X < 0.6 and s.Z < 0.6) or (s.Y < 0.6 and s.Z < 0.6)
				local skip = SKIP_MATERIALS[p.Material] or p.Transparency > 0.5 or SKIP_NAMES[p.Name] or p.Name:find("Point$") or tiny
				for _, t in ipairs(p:GetChildren()) do
					if t:IsA("Texture") and (t.Name == "Studs" or t.Texture == "rbxassetid://108876554364166") then
						t:Destroy() -- anciens picots, ou dalles du pont remplacées par les picots
					end
				end
				if not skip then
					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local t = Instance.new("Texture")
						t.Name = "Studs"
						t.Texture = STUDS
						t.Face = face
						t.StudsPerTileU = 2
						t.StudsPerTileV = 2
						t.ZIndex = 2
						t.Parent = p
					end
					count += 1
				end
			end
		end
	end
end
print("Picots posés sur", count, "pièces")
