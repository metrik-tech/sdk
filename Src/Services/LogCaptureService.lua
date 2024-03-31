local ScriptContext = game:GetService("ScriptContext")

local Console = require(script.Parent.Parent.Packages.Console)
local Signal = require(script.Parent.Parent.Packages.Signal)

local Api = require(script.Parent.Parent.Enums.Api)

local ApiService = require(script.Parent.ApiService)

local MESSAGE_REPORTER_DELAY = 60

local LogCaptureService = {}

LogCaptureService.Priority = 0
LogCaptureService.Reporter = Console.new(`🕵️ {script.Name}`)

LogCaptureService.MessageQueue = {}

LogCaptureService.MessageQueueUpdated = Signal.new()

function LogCaptureService.OnMessageError(self: LogCaptureService, message: string, trace: string, filePath: string)
	table.insert(self.MessageQueue, {
		["message"] = message,
		["placeVersion"] = game.PlaceVersion,
		["serverId"] = ApiService.JobId,
		["script"] = filePath,
		["trace"] = trace,
	})
end

function LogCaptureService.OnStart(self: LogCaptureService)
	ScriptContext.Error:Connect(function(message: string, trace: string, script: Instance)
		local filePath = script and script:GetFullName() or "?"

		self:OnMessageError(message, trace, filePath)
	end)

	task.spawn(function()
		while true do
			task.wait(MESSAGE_REPORTER_DELAY)

			if #self.MessageQueue == 0 then
				continue
			end

			ApiService:PostAsync(Api.ServerLogBatch, {
				items = self.MessageQueue,
			})

			self.MessageQueue = {}
		end
	end)
end

export type LogCaptureService = typeof(LogCaptureService)

return LogCaptureService
