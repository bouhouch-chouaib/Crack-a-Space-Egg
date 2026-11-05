-- Attribution des bases du vaisseau (7) : une par joueur, libérée quand il part.
-- Le joueur réapparaît dans sa base ; son nom s'affiche au-dessus.

local Players = game:GetService("Players")

local WorldBuilder = require(script.Parent.WorldBuilder)

local Bases = {}

local owners: { [number]: Player } = {}

-- Panneau au nom du propriétaire (TextLabel « OwnerName » à l'arrière de la base)
local function label(base: Model): TextLabel?
	return base:FindFirstChild("OwnerName", true) :: TextLabel?
end

function Bases.Get(player: Player): Model?
	local index = player:GetAttribute("Base")
	return if type(index) == "number" then WorldBuilder.Bases[index] else nil
end

-- Le joueur propriétaire d'une base, à partir de n'importe quelle pièce de celle-ci
function Bases.OwnerOf(instance: Instance): Player?
	local base: Instance? = instance
	while base and base:GetAttribute("Index") == nil do
		base = base:FindFirstAncestorWhichIsA("Model")
	end
	return base and owners[base:GetAttribute("Index") :: number]
end

function Bases.SpawnCFrame(player: Player): CFrame?
	local base = Bases.Get(player)
	local spawn = base and base:FindFirstChild("Spawn") :: BasePart?
	return spawn and spawn.CFrame * CFrame.new(0, 3.5, 0)
end

local function assign(player: Player)
	for i, base in ipairs(WorldBuilder.Bases) do
		if not owners[i] then
			owners[i] = player
			player:SetAttribute("Base", i)
			player.RespawnLocation = base:FindFirstChild("Spawn") :: SpawnLocation
			local l = label(base)
			if l then
				l.Text = player.DisplayName .. "'s Base"
			end
			return
		end
	end
	warn("[Bases] Plus de base libre pour " .. player.Name)
end

local function release(player: Player)
	for i, p in pairs(owners) do
		if p == player then
			owners[i] = nil
			local l = label(WorldBuilder.Bases[i])
			if l then
				l.Text = "FREE BASE"
			end
		end
	end
end

-- Place le personnage dans sa base (au cas où il serait apparu ailleurs)
local function onCharacter(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local cf = Bases.SpawnCFrame(player)
	if hrp and cf and character.PrimaryPart then
		character:SetPrimaryPartCFrame(cf)
	end
end

function Bases.Start()
	local function added(player: Player)
		assign(player)
		player.CharacterAdded:Connect(function(c)
			onCharacter(player, c)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(added)
	for _, p in ipairs(Players:GetPlayers()) do
		added(p)
	end
	Players.PlayerRemoving:Connect(release)
end

return Bases
