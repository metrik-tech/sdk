local ScriptContext = game:GetService("ScriptContext")

local Console = require(script.Parent.Parent.Packages.Console)
local Signal = require(script.Parent.Parent.Packages.Signal)

local Network = require(script.Parent.Parent.Network.Client)

local MESSAGE_REPORTER_DELAY = 60

local LogCaptureControllers = {}

LogCaptureControllers.Priority = 0
LogCaptureControllers.Reporter = Console.new(`{script.Name}`)

LogCaptureControllers.MessageQueue = {}

LogCaptureControllers.MessageQueueUpdated = Signal.new()

function LogCaptureControllers.OnMessageError(self: LogCaptureControllers, message: string, trace: string, filePath: string)
	table.insert(self.MessageQueue, {
		["message"] = message,
		["script"] = filePath,
		["trace"] = trace,
	})
end

function LogCaptureControllers.OnStart(self: LogCaptureControllers)
	ScriptContext.Error:Connect(function(message: string, trace: string, script: Instance)
		local filePath = script and script:GetFullName() or "?"

		self:OnMessageError(message, trace, filePath)
	end)

	task.spawn(function()
		while true do
			task.wait(MESSAGE_REPORTER_DELAY)

			if #self.MessageQueue == 0 then
				self.Reporter:Debug(`No logs captured, dropping report request.`)

				continue
			end

			self.Reporter:Debug(`Reporting {#self.MessageQueue} logs to remote server!`)

			Network.LogError.Fire(self.MessageQueue)

			self.MessageQueue = {}
		end
	end)
end

export type LogCaptureControllers = typeof(LogCaptureControllers)

return LogCaptureControllers
