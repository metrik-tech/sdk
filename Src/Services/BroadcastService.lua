local Console = require(script.Parent.Parent.Packages.Console)

local MessageReceiveService = require(script.Parent.MessageReceiveService)

local BroadcastType = require(script.Parent.Parent.Enums.BroadcastType)

local Network = require(script.Parent.Parent.Network.Server)

local BroadcastService = { }

BroadcastService.Priority = 0
BroadcastService.Reporter = Console.new(`{script.Name}`)

function BroadcastService.OnStart(self: BroadcastService)
	MessageReceiveService.OnBroadcast:Connect(function(packet: BroadcastPacket)
		if packet.type == BroadcastType.Chat then
			Network.BroadcastChatMessage.FireAll(packet.message)
		elseif packet.type == BroadcastType.Popup then
			Network.BroadcastPopupMessage.FireAll(packet.message)
		elseif packet.type == BroadcastType.Toast then
			Network.BroadcastToastMessage.FireAll(packet.message)
		elseif packet.type == BroadcastType.Topbar then
			Network.BroadcastTopbarMessage.FireAll(packet.message)
		end
	end)
end

export type BroadcastService = typeof(BroadcastService)
export type BroadcastPacket = {
	id: string,
	message: string,
	type: string
}

return BroadcastService