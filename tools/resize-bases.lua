-- Outil de Studio (mode édition) : agrandit les bases du vaisseau (Workspace.Ship.Bases.BaseN).
-- Lancé une fois le 8 nov. (32 -> 36 studs). Relançable : il ne touche qu'aux bases qui n'ont pas
-- encore la taille SIZE.
-- Le mur du fond reste contre le bord du vaisseau : la base grandit vers l'avant (l'entrée) et sur
-- les côtés. Dans le repère du sol, un point (x, z) va en (x × k, (z + old/2) × k − old/2).
-- Les pièces longues (sol, rambardes, vitres, néons) s'allongent ; les poteaux et le point
-- d'apparition gardent leur taille ; la machine à dérocher est déplacée sans être agrandie.
-- Après : relancer tools/apply-studs.lua n'est pas nécessaire (les textures du sol se répètent seules).

local SIZE = 36

return function()
	local done = {}
	for _, base in ipairs(workspace.Ship.Bases:GetChildren()) do
		local floor = base:FindFirstChild("Floor") :: BasePart?
		if floor and math.abs(floor.Size.X - SIZE) > 0.01 then
			local old = floor.Size.X
			local k = SIZE / old
			local F = floor.CFrame
			local function move(p: Vector3): Vector3
				local v = F:PointToObjectSpace(p)
				return F:PointToWorldSpace(Vector3.new(v.X * k, v.Y, (v.Z + old / 2) * k - old / 2))
			end
			for _, d in ipairs(base:GetDescendants()) do
				if d:IsA("BasePart") and not d:IsDescendantOf(base:FindFirstChild("DerockMachine") or floor) or d == floor then
					local part = d :: BasePart
					local cf = part.CFrame
					local size = part.Size
					if part.Name ~= "Spawn" then
						-- allonge les côtés alignés avec les axes du sol (seulement les pièces longues)
						local axes = { cf.RightVector, cf.UpVector, -cf.LookVector }
						local s = { size.X, size.Y, size.Z }
						for i, axis in ipairs(axes) do
							local ax = math.abs(axis:Dot(F.RightVector))
							local az = math.abs(axis:Dot(-F.LookVector))
							if s[i] > 2 and (ax > 0.9 or az > 0.9) then
								s[i] *= k
							end
						end
						part.Size = Vector3.new(s[1], s[2], s[3])
					end
					part.CFrame = (cf - cf.Position) + move(cf.Position)
				end
			end
			local machine = base:FindFirstChild("DerockMachine")
			if machine and machine:IsA("Model") then
				local pv = machine:GetPivot()
				machine:PivotTo((pv - pv.Position) + move(pv.Position))
			end
			table.insert(done, base.Name)
		end
	end
	return done
end
