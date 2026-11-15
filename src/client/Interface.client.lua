-- Messages du serveur (Remotes.Notice), affichés par UIKit.toast.
-- Le HUD est dans Hud.client.lua, la barre de vie de la roche visée dans Impact.client.lua,
-- la boutique dans DrillShop.client.lua.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIKit = require(script.Parent:WaitForChild("UIKit"))

-- MESSAGES ------------------------------------------------------------------
local function notice(text: string, kind: string?)
	UIKit.toast(text, kind)
end
Remotes.Notice.OnClientEvent:Connect(notice)
