local TextService = game:GetService("TextService")

local Action = require(script.Parent.Parent.API.Action)

return function()
	local DisplayMessageAction = Action.new({
		Name = "Display Message Action",
		Uuid = "internal:display-message-action",

		Arguments = {
			{
				ArgumentName = "Target Player Id",
				ArgumentType = "number",
				ArgumentDefault = -1,
				ArgumentIsOptional = true,
			},
			{
				ArgumentName = "Server Message",
				ArgumentType = "string",
				ArgumentDefault = "Hello, World!",
				ArgumentIsOptional = false,
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

		-- TO-DO: broadcast server message.

		warn(`Broadcasting '{filteredServerMessage}' to '{targetPlayerId or 0}'`)
	end
	
	return DisplayMessageAction
end