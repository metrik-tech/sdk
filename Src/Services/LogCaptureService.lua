local LogService = game:GetService("LogService")

local Console = require(script.Parent.Parent.Packages.Console)
local Signal = require(script.Parent.Parent.Packages.Signal)

local Api = require(script.Parent.Parent.Enums.Api)

local ApiService = require(script.Parent.ApiService)

local MESSAGE_REPORTER_DELAY = 60

local ROBLOX_ERROR_STACK_INFO_PATTERN = "Script '(%S+)', Line (%d+)"
local ROBLOX_ERROR_STACK_BEGIN_PATTERN = "Stack Begin"
local ROBLOX_ERROR_STACK_END_PATTERN = "Stack End"

local LogCaptureService = { }

LogCaptureService.Priority = 0
LogCaptureService.Reporter = Console.new(`🕵️ {script.Name}`)

LogCaptureService.MessageQueue = { }

LogCaptureService.MessageQueueUpdated = Signal.new()

function LogCaptureService.OnMessageOutput(self: LogCaptureService, message: string)
	table.insert(self.MessageQueue, {
		["message"] = message,
		["type"] = Enum.MessageType.MessageOutput.Name
	})
end

function LogCaptureService.OnMessageWarning(self: LogCaptureService, message: string)
	table.insert(self.MessageQueue, {
		["message"] = message,
		["type"] = Enum.MessageType.MessageWarning.Name
	})
end

function LogCaptureService.OnMessageError(self: LogCaptureService, message: string)
	table.insert(self.MessageQueue, {
		["message"] = message,
		["type"] = Enum.MessageType.MessageError.Name
	})
end

function LogCaptureService.OnMessageInfo(self: LogCaptureService, message: string)
	local lastSentMessage = self.MessageQueue[#self.MessageQueue]

	if
		(
			string.match(message, ROBLOX_ERROR_STACK_INFO_PATTERN)
			or string.match(message, ROBLOX_ERROR_STACK_BEGIN_PATTERN)
			or string.match(message, ROBLOX_ERROR_STACK_END_PATTERN)
		) and (
			lastSentMessage and lastSentMessage.type == Enum.MessageType.MessageError
		)
	then
		lastSentMessage.message ..= `\n{message}`
	else
		table.insert(self.MessageQueue, {
			["message"] = message,
			["type"] = Enum.MessageType.MessageInfo.Name
		})
	end
end

function LogCaptureService.OnStart(self: LogCaptureService)
	LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		if messageType == Enum.MessageType.MessageOutput then
			self:OnMessageOutput(message)
		elseif messageType == Enum.MessageType.MessageWarning then
			self:OnMessageWarning(message)
		elseif messageType == Enum.MessageType.MessageError then
			self:OnMessageError(message)
		elseif messageType == Enum.MessageType.MessageInfo then
			self:OnMessageInfo(message)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(MESSAGE_REPORTER_DELAY)

			if #self.MessageQueue == 0 then
				continue
			end

			ApiService:PostAsync(Api.ServerLogBatch, self.MessageQueue)

			self.MessageQueue = { }
		end
	end)
end

export type LogCaptureService = typeof(LogCaptureService)

return LogCaptureService