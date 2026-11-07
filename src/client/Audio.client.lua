-- Ambiance sonore (Config.Sounds) : musique selon le lieu, boucles (jetpack, foreuse, soufflerie,
-- vent glacé, machines à dérocher) et sons des moments clés, lus dans les attributs et les remotes
-- déjà publiés par le serveur. Contient aussi la fenêtre Réglages (musique et sons).
--   Musique : Base dans le vaisseau, Belt dans les anneaux, Event pendant la pluie de météores ;
--   hors du couloir elle s'efface sous le vent glacé.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))
local Sfx = require(script.Parent:WaitForChild("Sfx"))

local S = Config.Sounds
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local new = UIKit.new

-- MUSIQUE -----------------------------------------------------------------------------------

local tracks: { [string]: Sound } = {}
for key, id in pairs(S.Music) do
	local s = Instance.new("Sound")
	s.Name = "Music" .. key
	s.SoundId = "rbxassetid://" .. id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = Sfx.MusicGroup
	s.Parent = SoundService
	tracks[key] = s
end

local function inShip(pos: Vector3): boolean
	local ship = workspace:FindFirstChild("Ship")
	local mn = ship and ship:GetAttribute("SafeMin")
	local mx = ship and ship:GetAttribute("SafeMax")
	if typeof(mn) ~= "Vector3" or typeof(mx) ~= "Vector3" then
		return true
	end
	return pos.X >= mn.X and pos.X <= mx.X and pos.Z >= mn.Z and pos.Z <= mx.Z
end

-- BOUCLES -----------------------------------------------------------------------------------

local jet = Sfx.Loop("Jetpack")
local drill = Sfx.Loop("Drill")
local tunnel = Sfx.Loop("Tunnel")
local void = Sfx.Loop("Void")
local heart = Sfx.Loop("Heart")

-- Machines à dérocher : une boucle placée sur chaque machine pendant le forage de la roche
local machines: { [Model]: { loop: Sfx.Loop, broke: number? } } = {}
local function scanMachines()
	local bases = workspace:FindFirstChild("Ship") and workspace.Ship:FindFirstChild("Bases")
	if not bases then
		return
	end
	for _, b in ipairs(bases:GetChildren()) do
		local m = b:FindFirstChild("DerockMachine")
		if m and m:IsA("Model") and m.PrimaryPart and not machines[m] then
			machines[m] = { loop = Sfx.Loop("Machine", m.PrimaryPart) }
		end
	end
	for m, st in pairs(machines) do
		if not m:IsDescendantOf(workspace) then
			st.loop:Destroy()
			machines[m] = nil
		end
	end
end
task.spawn(function()
	while true do
		scanMachines()
		task.wait(3)
	end
end)

local current = ""
RunService.Heartbeat:Connect(function(dt: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local cold = (player:GetAttribute("Cold") or 0) :: number
	local outside = player:GetAttribute("ColdGrace") ~= nil or cold > 0

	-- musique du lieu
	local want = "Base"
	if root and not inShip(root.Position) then
		want = if workspace:GetAttribute("EventActive") then "Event" else "Belt"
	end
	if want ~= current then
		current = want
		tracks[want].TimePosition = 0
	end
	local musicLevel = if outside then S.MusicVolume * 0.25 else S.MusicVolume
	for key, s in pairs(tracks) do
		local goal = if key == current then musicLevel else 0
		local step = (S.MusicVolume / S.MusicFade) * dt
		s.Volume = if s.Volume < goal then math.min(goal, s.Volume + step) else math.max(goal, s.Volume - step)
		if s.Volume > 0 and not s.IsPlaying then
			s:Play()
		elseif s.Volume == 0 and s.IsPlaying then
			s:Stop()
		end
	end

	-- jetpack (0 arrêté, 1 en vol, 2 poussée), foreuse, soufflerie, froid
	local j = (character and character:GetAttribute("Jet") or 0) :: number
	jet:Set(if j == 2 then 1 elseif j == 1 then 0.55 else 0)
	jet.sound.PlaybackSpeed = if j == 2 then 1.15 else 1
	local drilling = player:GetAttribute("DrillReady") == true and typeof(player:GetAttribute("DrillAtLocal")) == "Vector3"
	drill:Set(if drilling then 1 else 0)
	tunnel:Set(if player:GetAttribute("InTunnel") then 1 else 0)
	void:Set(if outside then 0.35 + 0.65 * cold else 0)
	heart:Set(if cold > 0.45 then (cold - 0.45) / 0.55 else 0)

	-- machines : forage entre la fermeture des pinces et l'éclatement de la roche
	local now = workspace:GetServerTimeNow()
	for m, st in pairs(machines) do
		local js = m:GetAttribute("JobStart") :: number?
		local je = m:GetAttribute("JobEnd") :: number?
		local working = js and je and now >= js + 0.7 and now < je - 0.8
		st.loop:Set(if working then 1 else 0)
		if je and now >= je - 0.8 and now < je and st.broke ~= je then
			st.broke = je
			Sfx.Play("Derock", { at = m.PrimaryPart.Position })
		end
	end
end)

-- MOMENTS CLÉS ------------------------------------------------------------------------------

-- Coups de foreuse : petits éclats (pas plus d'un toutes les 0,12 s), gros fracas quand la roche cède
local lastHit = 0
Remotes:WaitForChild("DrillHit").OnClientEvent:Connect(function(rock: BasePart?, by: Player, _damage: number, _rarities, broken: boolean)
	if not rock or not rock.Parent then
		return
	end
	local at = (if by == player then player:GetAttribute("DrillAtLocal") else nil) or (by.Character and by.Character:GetAttribute("DrillAt")) or rock.Position
	if typeof(at) ~= "Vector3" then
		at = rock.Position
	end
	local mine = by == player
	if broken then
		Sfx.Play("RockBreak", { at = at, volume = if mine then 1 else 0.6 })
	elseif os.clock() - lastHit > 0.12 then
		lastHit = os.clock()
		Sfx.Play("RockHit", { at = at, volume = if mine then 1 else 0.5, pitch = 0.85 + math.random() * 0.35 })
	end
end)

-- Éclosion : fanfare pour les créatures rares, son placé à la base (les voisins l'entendent aussi)
Remotes:WaitForChild("Hatched").OnClientEvent:Connect(function(owner: Player, pos: Vector3, _ring: number, rarity: number)
	local rare = rarity >= S.RareFrom
	Sfx.Play(if rare then "HatchRare" else "Hatch", { at = pos, volume = if owner == player then 1 else 0.5 })
	Sfx.Play("Pop", { at = pos, pitch = 0.8 })
end)

-- Œuf révélé par la machine : petit « pop » plus aigu selon la rareté
Remotes:WaitForChild("EggRevealed").OnClientEvent:Connect(function(_ring: number, rarity: number)
	Sfx.Play("Pop", { pitch = 0.9 + 0.06 * rarity })
end)

Remotes:WaitForChild("Notice").OnClientEvent:Connect(function(_text: string, kind: string?)
	if kind == "bad" or kind == "warn" then
		Sfx.Play("Error")
	end
end)

-- Attributs du joueur : soute, argent, niveau du jetpack, gel
local last = {
	Cargo = player:GetAttribute("Cargo") or 0,
	Credits = player:GetAttribute("Credits") or 0,
	JetLevel = player:GetAttribute("JetLevel") or 1,
	Grace = player:GetAttribute("ColdGrace"),
}
player.AttributeChanged:Connect(function(name: string)
	local v = player:GetAttribute(name)
	if name == "Cargo" and type(v) == "number" then
		if v > last.Cargo then
			Sfx.Play("Pop", { pitch = 1.1 + 0.05 * math.min(v, 8) })
		end
		last.Cargo = v
	elseif name == "Credits" and type(v) == "number" then
		local income = (player:GetAttribute("Income") or 0) :: number
		if v < last.Credits then
			Sfx.Play("Buy")
		elseif v - last.Credits > income * 2 + 1 then
			Sfx.Play("Coin") -- gain d'un coup (vente, récompense), pas le revenu de chaque seconde
		end
		last.Credits = v
	elseif name == "JetLevel" and type(v) == "number" then
		if v > last.JetLevel then
			Sfx.Play("LevelUp")
		end
		last.JetLevel = v
	elseif name == "ColdGrace" then
		if v ~= nil and last.Grace == nil then
			Sfx.Play("Warning") -- on vient de sortir de la zone où l'on respire
		end
		last.Grace = v
	end
end)

-- Gel du personnage
local function watchCharacter(character: Model)
	character:GetAttributeChangedSignal("Frozen"):Connect(function()
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if character:GetAttribute("Frozen") then
			Sfx.Play("Freeze", { at = root and root.Position })
		else
			Sfx.Play("Thaw")
		end
	end)
end
if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

-- Début de la pluie de météores
workspace:GetAttributeChangedSignal("EventActive"):Connect(function()
	if workspace:GetAttribute("EventActive") then
		Sfx.Play("MeteorStart")
	end
end)

-- Achat Robux réussi
local MarketplaceService = game:GetService("MarketplaceService")
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, _id, purchased)
	if who == player and purchased then
		Sfx.Play("Reward")
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _id, purchased)
	if userId == player.UserId and purchased then
		Sfx.Play("Reward")
	end
end)

-- Clic sur n'importe quel bouton de l'interface
local hooked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function hook(o: Instance)
	if o:IsA("GuiButton") and not hooked[o] then
		hooked[o] = true
		o.Activated:Connect(function()
			Sfx.Play("Click", { pitch = 0.95 + math.random() * 0.1 })
		end)
	end
end
local gui = player:WaitForChild("PlayerGui")
for _, o in ipairs(gui:GetDescendants()) do
	hook(o)
end
gui.DescendantAdded:Connect(hook)

-- RÉGLAGES ----------------------------------------------------------------------------------

local W = UIKit.window({ name = "SettingsWindow", title = "{Settings} SETTINGS", color = "Blue", size = Vector2.new(520, 400) })
local list = new("Frame", { Name = "List", Size = UDim2.fromOffset(460, 200), BackgroundTransparency = 1, LayoutOrder = 1, Parent = W.body })
new("UIListLayout", { Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = list })

local function toggleRow(order: number, label: string, attr: string)
	local row = new("Frame", { Size = UDim2.fromOffset(440, 80), BackgroundColor3 = Color3.fromRGB(40, 60, 110), LayoutOrder = order, Parent = list }, { UIKit.corner(), UIKit.stroke(3) })
	UIKit.text({ Text = label, Size = UDim2.fromScale(0.55, 0.6), Position = UDim2.fromScale(0.05, 0.2), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local b = new("TextButton", {
		Name = "Toggle",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(150, 56),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Text = "",
		Parent = row,
	}, { UIKit.corner(), UIKit.stroke(3) })
	local t = UIKit.text({ Size = UDim2.fromScale(0.8, 0.7), Position = UDim2.fromScale(0.1, 0.15), Parent = b })
	UIKit.juice(b)
	local function refresh()
		local on = not player:GetAttribute(attr)
		b.BackgroundColor3 = if on then Color3.fromRGB(90, 210, 90) else Color3.fromRGB(220, 70, 70)
		t.Text = if on then "ON" else "OFF"
	end
	refresh()
	player:GetAttributeChangedSignal(attr):Connect(refresh)
	b.MouseButton1Click:Connect(function()
		Remotes:WaitForChild("Settings"):FireServer(attr, not player:GetAttribute(attr))
	end)
end
toggleRow(1, "Music", "MusicOff")
toggleRow(2, "Sounds", "SfxOff")

UIKit.Open.Event:Connect(function(what: string)
	if what == "Settings" then
		W.open()
	end
end)
