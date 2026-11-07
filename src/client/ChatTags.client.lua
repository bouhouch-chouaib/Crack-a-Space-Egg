-- Tag [VIP] doré devant les messages des joueurs qui ont le passe VIP (attribut Pass_VIP posé par
-- BoostService côté serveur).

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local sender = source and Players:GetPlayerByUserId(source.UserId)
	if sender and sender:GetAttribute("Pass_VIP") then
		props.PrefixText = '<font color="#FFD23C">[VIP]</font> ' .. message.PrefixText
	end
	return props
end
