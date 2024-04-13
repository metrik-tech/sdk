local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)

local ActionService = require(script.Parent.ActionService)

local MessageService = {}

MessageService.Priority = 10
MessageService.Reporter = Console.new(`{script.Name}`)

MessageService.Connections = {} :: { [string]: RBXScriptConnection }

-- overwritten in our ':OnStart' call.
function MessageService.OnMessageRecieved(_: string, _1: MessagingServicePacket?) end

function MessageService.MockEvent(self: MessageService, eventUuid: string, ...: any)
	self.OnMessageRecieved(eventUuid, {
		Data = {
			targetServerUuid = nil,
			targetServerVersion = nil,
			eventArguments = { ... },
		},
		Sent = 0,
	})
end

function MessageService.OnStart(self: MessageService)
	MessagingService:SubscribeAsync(`metrik`, function(packet: MessagingServicePacket)
		local packetJson = HttpService:JSONDecode(packet.Data)

		if packetJson.targetServerUuid then
			if game.JobId ~= packetJson.targetServerUuid then
				return
			end
		end

		if packetJson.targetServerVersion then
			if game.PlaceVersion ~= packetJson.targetServerVersion then
				return
			end
		end

		ActionService:InvokeActionAsync(packetJson.key, packetJson.arguments)
			:andThen(function()
				return
			end)
			:catch(function()
				return
			end)

		-- TO-DO: check status of Invoked Action.
	end)
end

export type MessageService = typeof(MessageService)
export type MessagingServicePacket = {
	Data: { [any]: any },
	Sent: number,
}

return MessageService
