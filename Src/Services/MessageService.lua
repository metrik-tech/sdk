local MessagingService = game:GetService("MessagingService")

local Console = require(script.Parent.Parent.Packages.Console)

local ActionService = require(script.Parent.ActionService)

local Action = require(script.Parent.Parent.API.Action)

local MessageService = { }

MessageService.Priority = 10
MessageService.Reporter = Console.new(`💭 {script.Name}`)

MessageService.Connections = { } :: { [string]: RBXScriptConnection }

-- overwritten in our ':OnStart' call.
function MessageService.OnMessageRecieved(_: string, _: MessagingServicePacket?) end

function MessageService.SubscribeToEvent(self: MessageService, eventUuid: string)
	self.Reporter:Debug(`Listening to message service event '{`metrik:{eventUuid}`}'`)

	self.Connections[eventUuid] = MessagingService:SubscribeAsync(`metrik:{eventUuid}`, function(...)
		self.OnMessageRecieved(eventUuid, ...)
	end)
end

function MessageService.MockEvent(self: MessageService, eventUuid: string, ...: any)
	self.OnMessageRecieved(eventUuid, {
		Data = {
			targetServerUuid = nil,
			targetServerVersion = nil,
			eventArguments = { ... }
		},
		Sent = 0,
	})
end

function MessageService.OnStart(self: MessageService)
	--[[
		Example 'packet' object:

		{
			targetServerUuid: number | nil,
			targetServerVersion: number | nil,
			eventArguments: { ... },
		}
	]]

	function MessageService.OnMessageRecieved(eventUuid: string, packet: MessagingServicePacket?)
		-- satify luau-lsp, we should always have a packate.
		if not packet then
			return
		end

		if packet.Data.targetServerUuid then
			if game.JobId ~= packet.Data.targetServerUuid then
				return
			end
		end

		if packet.Data.targetServerVersion then
			if game.PlaceVersion ~= packet.Data.targetServerVersion then
				return
			end
		end

		(ActionService :: { [any]: any }):InvokeActionAsync(eventUuid, packet.Data.eventArguments)
			:andThen(function()
				return 
			end)
			:catch(function()
				return 
			end)

		-- TO-DO: check status of Invoked Action.
	end
end

function MessageService.OnInit(self: MessageService)
	Action.ActionAdded:Connect(function(actionObject: Action.Action)
		self:SubscribeToEvent(actionObject.Uuid)
	end)
end

export type MessageService = typeof(MessageService)
export type MessagingServicePacket = {
	Data: { [any]: any },
	Sent: number
}

return MessageService