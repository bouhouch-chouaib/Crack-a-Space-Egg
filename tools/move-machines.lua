-- Outil de Studio (mode édition) : sort la machine à dérocher de chaque base, posée sur le pont juste
-- devant l'entrée (le sol de la base reste libre pour les créatures). Relançable.
-- Dans le repère du sol de la base : la machine est à gauche de l'allée, le tube (Config.Jetpack.TunnelOffset)
-- à droite, et le chemin du pont passe entre les deux pour entrer dans la base.

local LEFT = -8.5 -- centre de la machine sur l'axe X du sol
local GAP = 0.7 -- espace entre le bord avant du sol et le dos de la machine

return function(): { string }
	local done = {}
	for _, base in ipairs(workspace.Ship.Bases:GetChildren()) do
		local floor = base:FindFirstChild("Floor") :: BasePart?
		local machine = base:FindFirstChild("DerockMachine") :: Model?
		if floor and machine then
			local F = floor.CFrame
			local box, size = machine:GetBoundingBox()
			local center = F:PointToObjectSpace(box.Position)
			local want = Vector3.new(LEFT, center.Y, floor.Size.Z / 2 + GAP + size.Z / 2)
			local move = F:VectorToWorldSpace(want - center)
			-- posée sur le pont (le dessus du pont est à y = 0 ; le sol de la base est un peu plus haut)
			move += Vector3.new(0, 0 - (box.Position.Y - size.Y / 2), 0)
			machine:PivotTo(machine:GetPivot() + move)
			table.insert(done, base.Name)
		end
	end
	return done
end
