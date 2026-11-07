-- Appareil utilisé en ce moment : « Keyboard » (clavier et souris), « Touch » (téléphone, tablette)
-- ou « Gamepad » (manette, consoles). Suit la dernière entrée utilisée : brancher une manette sur un
-- PC ou toucher l'écran d'un PC tactile bascule tout de suite les aides, boutons et textes.
--   Device.Kind()            -> "Keyboard" | "Touch" | "Gamepad"
--   Device.Changed:Connect(fn(kind))
--   Device.Key(action)       -> texte court de la touche à appuyer (ex. "RT", "E", "DRILL")
-- Les touches de la manette sont réglées ici (une seule source pour le jeu et les textes d'aide).

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Device = {}

-- Touches de la manette (les invites ProximityPrompt gardent leurs propres touches)
Device.Pad = {
	Drill = Enum.KeyCode.ButtonR2, -- maintenir : forer la roche la plus proche
	DrillAlt = Enum.KeyCode.ButtonR1,
	Place = Enum.KeyCode.ButtonR2, -- poser l'œuf tenu
	Cancel = Enum.KeyCode.ButtonB, -- fermer une fenêtre, annuler
	Store = Enum.KeyCode.DPadLeft,
	Index = Enum.KeyCode.DPadRight,
	Rewards = Enum.KeyCode.DPadUp,
}

local GAMEPADS = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true,
}

local function kindOf(t: Enum.UserInputType): string?
	if GAMEPADS[t] then
		return "Gamepad"
	elseif t == Enum.UserInputType.Touch then
		return "Touch"
	elseif t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.TextInput or t.Name:sub(1, 5) == "Mouse" then
		return "Keyboard"
	end
	return nil
end

-- Au démarrage : console = manette ; écran tactile sans clavier = tactile ; sinon la dernière entrée
local current: string = "Keyboard"
local console = GuiService:IsTenFootInterface()
	or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled)
if console then
	current = "Gamepad"
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	current = "Touch"
else
	current = kindOf(UserInputService:GetLastInputType()) or "Keyboard"
end

local changed = Instance.new("BindableEvent")
Device.Changed = changed.Event

UserInputService.LastInputTypeChanged:Connect(function(t)
	local k = kindOf(t)
	-- un PC tactile qui bouge sa souris reste en souris ; une console reste en manette
	if not k or k == current or (GuiService:IsTenFootInterface() and k ~= "Gamepad") then
		return
	end
	current = k
	changed:Fire(k)
end)

function Device.Kind(): string
	return current
end

function Device.IsTouch(): boolean
	return current == "Touch"
end

function Device.IsGamepad(): boolean
	return current == "Gamepad"
end

-- Nom court d'une touche de manette (Xbox ; PlayStation affiche R2 / L2 / Croix...)
local PAD_NAMES = {
	[Enum.KeyCode.ButtonR2] = "RT",
	[Enum.KeyCode.ButtonL2] = "LT",
	[Enum.KeyCode.ButtonR1] = "RB",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.DPadLeft] = "D-pad ←",
	[Enum.KeyCode.DPadRight] = "D-pad →",
}
function Device.PadName(key: Enum.KeyCode): string
	-- le nom affiché par Roblox suit la manette branchée (PlayStation, Xbox) quand il le connaît
	local ok, s = pcall(UserInputService.GetStringForKeyCode, UserInputService, key)
	if ok and type(s) == "string" and s ~= "" and #s <= 6 then
		return s
	end
	return PAD_NAMES[key] or key.Name
end

-- Texte de la touche pour une action, selon l'appareil
--   drill : forer   jump : voler   hatch : faire éclore   machine : machine à dérocher   place : poser l'œuf
function Device.Key(action: string): string
	if current == "Gamepad" then
		if action == "drill" or action == "place" then
			return Device.PadName(Device.Pad.Drill)
		elseif action == "jump" then
			return Device.PadName(Enum.KeyCode.ButtonA)
		elseif action == "hatch" then
			return Device.PadName(Enum.KeyCode.ButtonY)
		elseif action == "machine" then
			return Device.PadName(Enum.KeyCode.ButtonX)
		end
	elseif current == "Touch" then
		if action == "drill" then
			return "DRILL"
		elseif action == "jump" then
			return "JUMP"
		end
		return "Tap"
	end
	if action == "drill" or action == "place" then
		return "Click"
	elseif action == "jump" then
		return "Space"
	elseif action == "hatch" then
		return "F"
	elseif action == "machine" then
		return "E"
	end
	return ""
end

return Device
