-- Icônes dessinées (style du jeu : 3D cartoon brillant, contour sombre épais), à la place des emojis.
-- Icons.Ids : nom -> image (aussi recopiées dans UIKit.Art).
-- Icons.Apply(label, "{Egg} You carry an egg") : le jeton {Nom} en début de texte devient une image
-- collée devant le texte (marche avec TextScaled et les trois alignements). À appeler côté client :
-- la position dépend de TextBounds, calculé seulement là où le texte est affiché.
-- Les textes envoyés par le serveur (notifications) utilisent la même écriture {Nom}.

local Icons = {}

Icons.Ids = {
	-- déjà dans le jeu
	Egg = "rbxassetid://126959641190337",
	Cash = "rbxassetid://119781577077916",
	Jetpack = "rbxassetid://101405938770705",
	Comet = "rbxassetid://97641885073649",
	Supernova = "rbxassetid://83408422703072", -- étoile qui explose (renaissance)
	Settings = "rbxassetid://131831924082787",
	-- jeu d'icônes du 7 nov. (ropilot_generate_ui_art, style « simulator »)
	Home = "rbxassetid://112808991360692",
	Lock = "rbxassetid://112490514299425",
	Warning = "rbxassetid://101051646622504",
	Freezing = "rbxassetid://105548630128276",
	Snowflake = "rbxassetid://81655278007754",
	WindTunnel = "rbxassetid://124670815550762",
	Lightning = "rbxassetid://124816685444573",
	Star = "rbxassetid://102151511950781",
	Hourglass = "rbxassetid://91431451397821",
	Hatch = "rbxassetid://89284819009348",
	Mouse = "rbxassetid://106721370272712",
	Tap = "rbxassetid://91401767168534",
	ArrowUp = "rbxassetid://89393697221320",
	Cross = "rbxassetid://130530490841529",
	Lifebuoy = "rbxassetid://104960365252528",
	Fire = "rbxassetid://101623438804796",
	Galaxy = "rbxassetid://97643043109062",
	Eye = "rbxassetid://118287707219483",
	Rift = "rbxassetid://88003725449676",
	Sparkles = "rbxassetid://74527316576347",
}

local PAD = "     " -- place réservée devant le texte pour l'icône
local PAD_EM = 1.25 -- largeur de PAD, en hauteurs de ligne (environ)
local SIZE = 1.25 -- taille de l'icône, en hauteurs de ligne

local function place(label: TextLabel)
	local img = label:FindFirstChild("InlineIcon") :: ImageLabel?
	if not img or not img.Visible then
		return
	end
	local b = label.TextBounds
	local size = label.AbsoluteSize
	if size.X <= 0 or b.Y <= 0 then
		return
	end
	-- hauteur d'une ligne : le texte est presque toujours sur une ligne
	local lineH = math.min(b.Y, size.Y)
	local x0 = if label.TextXAlignment == Enum.TextXAlignment.Left then 0
		elseif label.TextXAlignment == Enum.TextXAlignment.Right then size.X - b.X
		else (size.X - b.X) / 2
	local top = if label.TextYAlignment == Enum.TextYAlignment.Top then 0
		elseif label.TextYAlignment == Enum.TextYAlignment.Bottom then size.Y - b.Y
		else (size.Y - b.Y) / 2
	local s = lineH * SIZE
	img.Size = UDim2.fromOffset(s, s)
	img.Position = UDim2.fromOffset(x0 + lineH * PAD_EM * 0.42, top + lineH * 0.5)
end

-- Écrit le texte dans le label ; un jeton {Nom} en tête devient une icône
function Icons.Apply(label: TextLabel, text: string)
	if label:GetAttribute("IconText") == text and label:GetAttribute("IconShown") == label.Text then
		return -- déjà affiché (et pas réécrit entre-temps)
	end
	label:SetAttribute("IconText", text)
	local name, rest = string.match(text, "^{(%w+)}%s*(.*)$")
	local img = label:FindFirstChild("InlineIcon") :: ImageLabel?
	if name and Icons.Ids[name] then
		label.Text = PAD .. rest
		if not img then
			local i = Instance.new("ImageLabel")
			i.Name = "InlineIcon"
			i.AnchorPoint = Vector2.new(0.5, 0.5)
			i.BackgroundTransparency = 1
			i.ZIndex = label.ZIndex + 1
			i.ImageTransparency = label.TextTransparency
			i.Parent = label
			img = i
			-- suit la position du texte et ses fondus
			label:GetPropertyChangedSignal("TextBounds"):Connect(function()
				place(label)
			end)
			label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				place(label)
			end)
			label:GetPropertyChangedSignal("TextTransparency"):Connect(function()
				i.ImageTransparency = label.TextTransparency
			end)
		end
		local icon = img :: ImageLabel
		icon.Image = Icons.Ids[name]
		icon.Visible = true
		place(label)
	else
		label.Text = if name then rest else text
		if img then
			img.Visible = false
		end
	end
	label:SetAttribute("IconShown", label.Text)
end

return Icons
