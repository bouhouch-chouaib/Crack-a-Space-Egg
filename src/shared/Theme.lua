-- Style commun à toutes les interfaces (docs/Direction-artistique.md) : la police des jeux d'œufs.
-- Montserrat très grasse, comme sur les captures de référence (« x2 Argent », « Boutique »).

local Theme = {}

Theme.Font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold)
Theme.FontHeavy = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)

return Theme
