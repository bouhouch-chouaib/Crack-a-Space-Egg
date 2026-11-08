-- Outil de Studio (mode édition) : construit la boîte aux lettres des retours (Workspace.Ship.Mailbox),
-- dans le coin droit du vaisseau, à côté de la machine à fusion et des tableaux de classement.
-- Relançable : il remplace l'ancienne. Le tapis « Mat » ouvre la fenêtre Feedback (ShipShops.client,
-- attribut Shop = "Mail").

local STUDS = "rbxassetid://99589690361139"
local ICON = "rbxassetid://102151511950781" -- étoile (Icons.Ids.Star)
local CORNER = Vector3.new(0, 0, 38) -- la boîte, sur le bord gauche du quai, regarde le quai
local ANGLE, RADIUS = -90, 66

local LIGHT = Color3.fromRGB(120, 245, 240)
local DARK = Color3.fromRGB(30, 180, 200)
local WHITE = Color3.fromRGB(245, 246, 250)
local NAVY = Color3.fromRGB(34, 40, 72)
local RED = Color3.fromRGB(235, 70, 70)

return function(): Model
	local old = workspace.Ship:FindFirstChild("Mailbox")
	if old then
		old:Destroy()
	end
	local a = math.rad(ANGLE)
	local pos = Vector3.new(CORNER.X + math.sin(a) * RADIUS, 0, CORNER.Z + math.cos(a) * RADIUS)
	local base = CFrame.lookAt(pos, CORNER) -- avant de la boîte = -Z local, vers le coin
	local m = Instance.new("Model")
	m.Name = "Mailbox"
	m:SetAttribute("Shop", "Mail")
	local function p(name: string, props: { [string]: any }, studs: boolean?): BasePart
		local part = Instance.new(props.ClassName or "Part")
		props.ClassName = nil
		part.Name = name
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			(part :: any)[k] = v
		end
		part.Parent = m
		if studs then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local t = Instance.new("Texture")
				t.Name = "Studs"
				t.Texture = STUDS
				t.Face = face
				t.StudsPerTileU = 2
				t.StudsPerTileV = 2
				t.ZIndex = 2
				t.Parent = part
			end
		end
		return part
	end
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local up = CFrame.Angles(0, 0, math.pi / 2)
	local deep = CFrame.Angles(0, math.pi / 2, 0)
	p("Platform", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 7, 7), CFrame = at(0, 0.25, 0) * up, Color = NAVY }, true)
	p("Trim", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 7.5, 7.5), CFrame = at(0, 0.1, 0) * up, Color = DARK })
	p("Post", { Size = Vector3.new(1.2, 5.2, 1.2), CFrame = at(0, 3, 0), Color = WHITE }, true)
	p("Box", { Size = Vector3.new(5.6, 3.2, 5), CFrame = at(0, 7.1, 0), Color = LIGHT }, true)
	p("Roof", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 5.6, 5.6), CFrame = at(0, 8.7, 0) * deep, Color = DARK }, true)
	p("Door", { Size = Vector3.new(4.2, 3.6, 0.2), CFrame = at(0, 7.6, -2.55), Color = WHITE }, true)
	p("Slot", { Size = Vector3.new(3.2, 0.5, 0.25), CFrame = at(0, 8.2, -2.65), Color = NAVY })
	p("Handle", { Shape = Enum.PartType.Ball, Size = Vector3.one * 0.6, CFrame = at(0, 6.6, -2.8), Color = RED })
	-- petit drapeau rouge levé : il y a du courrier à envoyer !
	p("FlagPole", { Size = Vector3.new(0.3, 3.4, 0.3), CFrame = at(3.1, 8.2, 0.8), Color = WHITE })
	p("Flag", { Size = Vector3.new(0.25, 1.4, 2), CFrame = at(3.1, 9.2, -0.2), Color = RED }, true)
	p("Mat", { Size = Vector3.new(8, 0.12, 5.5), CFrame = at(0, 0.06, -7), Color = LIGHT, Transparency = 0.15 }, true)
	-- enseigne qui flotte au-dessus
	local holo = p("Holo", { Size = Vector3.one, CFrame = at(0, 15, 0), Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(11, 6.5)
	bb.LightInfluence = 0
	bb.MaxDistance = 300
	bb.Parent = holo
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0)
	img.Position = UDim2.fromScale(0.5, 0)
	img.Size = UDim2.fromScale(0.5, 0.55)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = ICON
	img.Parent = bb
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromScale(0, 0.55)
	text.Size = UDim2.fromScale(1, 0.45)
	text.Text = "TELL US!"
	text.TextScaled = true
	text.Font = Enum.Font.GothamBlack
	text.TextColor3 = LIGHT
	text.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(22, 22, 32)
	stroke.Parent = text
	m.PrimaryPart = m:FindFirstChild("Platform") :: BasePart
	m.Parent = workspace.Ship
	return m
end
