local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)
local Signal = require(script.Parent.Parent.Packages.Signal)

local TopicType = require(script.Parent.Parent.Enums.TopicType)

local MessageReceiveService = {}

MessageReceiveService.Priority = 10
MessageReceiveService.Reporter = Console.new(`{script.Name}`)

MessageReceiveService.OnBroadcast = Signal.new()
MessageReceiveService.OnAction = Signal.new()
MessageReceiveService.OnModeration = Signal.new()
MessageReceiveService.OnFlags = Signal.new()
MessageReceiveService.OnServers = Signal.new()

function MessageReceiveService.HandleMessageServicePacket(self: MessageReceiveService, packet: MessagingServicePacket)
	local dateTimeSent = DateTime.fromUnixTimestamp(packet.Sent)
	local decodedPacketJson = HttpService:JSONDecode(packet.Data)

	local messageContent = HttpService:JSONDecode(decodedPacketJson.message)
	local topicContent = decodedPacketJson.topic

	self.Reporter:Debug(`Received '{topicContent}' request at '{dateTimeSent:FormatLocalTime("LLL", "en-us")}'`)

	if topicContent == TopicType.Actions then
		self.OnAction:Fire(messageContent)
	elseif topicContent == TopicType.Broadcasts then
		self.OnBroadcast:Fire(messageContent)
	elseif topicContent == TopicType.Flags then
		self.OnFlags:Fire(messageContent)
	elseif topicContent == TopicType.Moderation then
		self.OnModeration:Fire(messageContent)
	elseif topicContent == TopicType.Servers then
		self.OnServers:Fire(messageContent)
	else
		self.Reporter:Warn(`Unknown Topic: '{topicContent}', dropping request!`)
	end
end

function MessageReceiveService.MockTopicMessage(self: MessageReceiveService, topic: string, data: { [any]: any })
	self:HandleMessageServicePacket({
		Sent = DateTime.now().UnixTimestamp,
		Data = HttpService:JSONEncode({
			topic = topic,
			message = HttpService:JSONEncode(data)
		})
	})
end

function MessageReceiveService.OnStart(self: MessageReceiveService)
	MessagingService:SubscribeAsync(`metrik`, function(packet: MessagingServicePacket)
		self:HandleMessageServicePacket(packet)
	end)
end

export type MessageReceiveService = typeof(MessageReceiveService)
export type MessagingServicePacket = {
	Data: string,
	Sent: number,
}

return MessageReceiveService
