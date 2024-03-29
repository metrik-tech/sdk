local TextService = game:GetService("TextService")

local Action = require(script.Parent.Parent.API.Action)

return function()
	local DisplayMessageAction = Action.new({
		Name = "Display Message Action",
		Uuid = "internal:display-message-action",

		Arguments = {
			{
				Name = "Target Player Id",
				Type = "Number",
				-- to-do, fix default so that it's a number, not a string
				Default = "-1",
				IsRequired = false,
			},
			{
				Name = "Server Message",
				Type = "String",
				Default = "Hello, World!",
				IsRequired = true,
			}
		}
	})
	
	function DisplayMessageAction:OnRun(targetPlayerId: number?, serverMessage: string)
		local textFilterResult: TextFilterResult = TextService:FilterStringAsync(serverMessage, 1, Enum.TextFilterContext.PublicChat)
		local filteredServerMessage

		if targetPlayerId then
			filteredServerMessage = textFilterResult:GetNonChatStringForUserAsync(targetPlayerId)
		else
			filteredServerMessage = textFilterResult:GetNonChatStringForBroadcastAsync()
		end

		if not string.match(filteredServerMessage, "(%S+)") then
			filteredServerMessage = "This message was filtered"
		end

		-- TO-DO: broadcast server message.

		warn(`Broadcasting '{filteredServerMessage}' to '{targetPlayerId or 0}'`)
	end
	
	return DisplayMessageAction
end