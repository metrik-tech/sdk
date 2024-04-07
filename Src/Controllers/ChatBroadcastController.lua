local TextChatService = game:GetService("TextChatService")

local Network = require(script.Parent.Parent.Network.Client)

local Console = require(script.Parent.Parent.Packages.Console)

local InterfaceTheme = require(script.Parent.Parent.Data.InterfaceTheme)

local SetCoreAsync = require(script.Parent.Parent.Util.SetCoreAsync)

local ChatBroadcastController = { }

ChatBroadcastController.Priority = 0
ChatBroadcastController.Reporter = Console.new(`{script.Name}`)

function ChatBroadcastController.PublishLegacyChatMessage(self: ChatBroadcastController, message: string)
	self.Reporter:Debug(`Displaying system message for: '{message}'`)

	SetCoreAsync("ChatMakeSystemMessage", {
		Text = message,

		Font = InterfaceTheme.LegacyChatFont,
		Color = InterfaceTheme.LegacyChatFontColor,
		TextSize = InterfaceTheme.LegacyChatFontSize
	}):expect()
end

function ChatBroadcastController.PublishChatMessage(self: ChatBroadcastController, message: string)
	local rbxSystemTextChannel = TextChatService:FindFirstChild("RBXSystem", true)

	if not rbxSystemTextChannel then
		self.Reporter:Warn(`Failed to find the 'RBXSystem' TextChannel in TextChatService!`)

		return
	end

	self.Reporter:Debug(`Displaying system message for: '{message}'`)

	rbxSystemTextChannel:DisplaySystemMessage(message)
end

function ChatBroadcastController.OnStart(self: ChatBroadcastController)
	Network.BroadcastChatMessage.SetCallback(function(message: string)
		if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
			self:PublishLegacyChatMessage(message)
		else
			self:PublishChatMessage(message)
		end
	end)
end

export type ChatBroadcastController = typeof(ChatBroadcastController)

return ChatBroadcastController