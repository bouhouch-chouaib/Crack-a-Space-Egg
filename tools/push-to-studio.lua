-- Envoie des scripts de src/ dans Studio (à lancer avec ropilot_edit_ctx_run_command).
-- Prérequis : `python -m http.server 34873 --bind 127.0.0.1` lancé dans src/.
-- Remplir FILES avec les chemins relatifs à src/ ; les scripts absents sont créés.
local FILES = { "shared/Config.lua" }
local URL = "http://127.0.0.1:34873/"

local Http = game:GetService("HttpService")
local SES = game:GetService("ScriptEditorService")

local ROOTS = {
	shared = function()
		return game.ReplicatedStorage:FindFirstChild("Shared")
	end,
	server = function()
		return game.ServerScriptService:FindFirstChild("Server")
	end,
	client = function()
		return game.StarterPlayer.StarterPlayerScripts:FindFirstChild("Client")
	end,
}

for _, path in ipairs(FILES) do
	local dir, file = path:match("^(%w+)/(.+)$")
	local name, kind = file:match("^(.-)%.(%a+)%.lua$")
	if not name then
		name, kind = file:match("^(.-)%.lua$"), "module"
	end
	local class = if kind == "server" then "Script" elseif kind == "client" then "LocalScript" else "ModuleScript"
	local parent = ROOTS[dir]()
	local source = Http:GetAsync(URL .. path, true)
	local script = parent:FindFirstChild(name)
	if script and script.ClassName ~= class then
		script:Destroy()
		script = nil
	end
	if not script then
		script = Instance.new(class)
		script.Name = name
		script.Parent = parent
	end
	SES:UpdateSourceAsync(script, function()
		return source
	end)
	print("OK", path, #source)
end
