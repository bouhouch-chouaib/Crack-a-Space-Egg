-- Tableaux de classement sur la ligne avant du vaisseau (Workspace.Ship.Leaderboards).
-- Chaque tableau porte un attribut « Stat » (Credits, Eggs, Best) et une pièce « Screen »
-- sur laquelle on dessine le top 10. Classement mondial via OrderedDataStore ;
-- si le service n'est pas joignable (Studio sans accès API), on classe les joueurs du serveur.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Icons = require(ReplicatedStorage.Shared.Icons)
local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local REFRESH = 60 -- secondes entre deux mises à jour
local ROWS = 10

-- Titre, icône et lecture de la valeur dans une sauvegarde
local STATS = {
	-- Les $ montent jusqu'aux quadrillions : on classe log10($) × 10^6 (entier), relu avec Decode
	Credits = {
		Title = "RICHEST",
		Icon = "Cash",
		Read = function(d) return d.credits end,
		Encode = function(v: number): number return math.floor(math.log10(math.max(1, v)) * 1e6) end,
		Decode = function(x: number): number return 10 ^ (x / 1e6) end,
		Key = "LB_Credits_v2",
	},
	Eggs = { Title = "EGGS CRACKED", Icon = "Egg", Read = function(d) return d.stats.geodes end },
	Best = { Title = "BEST FIND", Icon = "Star", Read = function(d) return d.stats.best end },
}

local stores: { [string]: OrderedDataStore? } = {}
local offline = false -- service injoignable (ex. Studio sans accès API) : on ne réessaie plus
local names: { [number]: string } = {}

local function store(stat: string): OrderedDataStore?
	if offline then
		return nil
	end
	if stores[stat] == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore(STATS[stat].Key or ("LB_" .. stat .. "_v1"))
		end)
		stores[stat] = if ok then s else nil
	end
	return stores[stat]
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok then name else ("Player " .. userId)
	return names[userId]
end

local function show(stat: string, value: number): (string, Color3)
	if stat == "Credits" then
		return "$" .. Format.Short(value), Color3.fromRGB(255, 214, 90)
	elseif stat == "Best" then
		local r = Config.Rarities[value]
		return r and string.upper(r.Name) or "-", r and r.Color or Color3.new(1, 1, 1)
	end
	return Format.Short(value), Color3.fromRGB(127, 243, 255)
end

-- Écran d'un tableau : titre + 10 lignes (rang, nom, valeur)
local function buildScreen(board: Model, stat: string)
	local screen = board:FindFirstChild("Screen") :: BasePart?
	if not screen then
		return nil
	end
	local old = screen:FindFirstChild("BoardGui")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(0.78, 0.12)
	title.Position = UDim2.fromScale(0.19, 0.02)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.FontFace = Theme.FontHeavy
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = STATS[stat].Title
	title.Parent = gui
	-- icône dessinée à gauche du titre (src/shared/Icons.lua)
	local icon = Instance.new("ImageLabel")
	icon.Name = "TitleIcon"
	icon.BackgroundTransparency = 1
	icon.Image = Icons.Ids[STATS[stat].Icon] or ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Size = UDim2.fromScale(0.15, 0.13)
	icon.Position = UDim2.fromScale(0.03, 0.015)
	icon.Parent = gui
	local rows = {}
	for i = 1, ROWS do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.fromScale(0.94, 0.078)
		row.Position = UDim2.fromScale(0.03, 0.15 + (i - 1) * 0.084)
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BackgroundTransparency = if i % 2 == 0 then 0.94 else 0.88
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 0)
		corner.Parent = row
		local function cell(name: string, x: number, w: number, align: Enum.TextXAlignment)
			local t = Instance.new("TextLabel")
			t.Name = name
			t.Size = UDim2.fromScale(w, 0.8)
			t.Position = UDim2.fromScale(x, 0.1)
			t.BackgroundTransparency = 1
			t.FontFace = Theme.Font
			t.TextScaled = true
			t.TextXAlignment = align
			t.TextColor3 = Color3.new(1, 1, 1)
			t.Text = ""
			t.Parent = row
			return t
		end
		rows[i] = {
			rank = cell("Rank", 0.02, 0.12, Enum.TextXAlignment.Center),
			name = cell("Name", 0.16, 0.5, Enum.TextXAlignment.Left),
			value = cell("Value", 0.66, 0.32, Enum.TextXAlignment.Right),
		}
		rows[i].rank.Text = tostring(i)
		-- Or, argent, bronze pour le podium
		if i <= 3 then
			rows[i].rank.TextColor3 = ({ Color3.fromRGB(255, 214, 90), Color3.fromRGB(220, 225, 235), Color3.fromRGB(240, 160, 100) })[i]
		end
		row.Parent = gui
	end
	gui.Parent = screen
	return rows
end

-- Le top à afficher : mondial si possible, sinon les joueurs du serveur
local function top(stat: string): { { name: string, value: number } }
	local list = {}
	local s = store(stat)
	if s then
		local ok, pages = pcall(function()
			return (s :: OrderedDataStore):GetSortedAsync(false, ROWS)
		end)
		if not ok then
			offline = true
		else
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local userId = tonumber(string.match(entry.key, "%d+"))
				local decode = STATS[stat].Decode
				table.insert(list, { name = userId and nameOf(userId) or entry.key, value = if decode then decode(entry.value) else entry.value })
			end
			return list
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(p)
		if d then
			table.insert(list, { name = p.DisplayName, value = STATS[stat].Read(d) })
		end
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	return list
end

-- Envoie les scores des joueurs présents (seulement si leur partie a bien été chargée)
local function submit()
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataService.Get(p)
		-- (pas en mode testeur : des scores au maximum resteraient dans les classements)
		if d and DataService.CanSave(p) and not Config.Testers.Everyone then
			for stat, info in pairs(STATS) do
				local s = store(stat)
				if s then
					pcall(function()
						local v = info.Read(d)
						local ods = s :: OrderedDataStore
						ods:SetAsync("u_" .. p.UserId, if info.Encode then info.Encode(v) else math.floor(v))
					end)
				end
			end
		end
	end
end

function LeaderboardService.Start()
	local folder = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Leaderboards")
	if not folder then
		warn("[Leaderboards] Workspace.Ship.Leaderboards introuvable")
		return
	end
	local boards = {}
	for _, board in ipairs(folder:GetChildren()) do
		local stat = board:GetAttribute("Stat")
		if type(stat) == "string" and STATS[stat] then
			local rows = buildScreen(board, stat)
			if rows then
				table.insert(boards, { stat = stat, rows = rows })
			end
		end
	end
	task.spawn(function()
		task.wait(8) -- laisse le temps aux premières parties de se charger
		while true do
			submit()
			for _, b in ipairs(boards) do
				local list = top(b.stat)
				for i, row in ipairs(b.rows) do
					local e = list[i]
					row.name.Text = e and e.name or ""
					local text, color = "", Color3.new(1, 1, 1)
					if e then
						text, color = show(b.stat, e.value)
					end
					row.value.Text = text
					row.value.TextColor3 = color
				end
			end
			task.wait(REFRESH)
		end
	end)
end

return LeaderboardService
