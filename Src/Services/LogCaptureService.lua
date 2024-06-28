local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)
local Signal = require(script.Parent.Parent.Packages.Signal)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)
local ApiService = require(script.Parent.ApiService)
local BreadcrumbService = require(script.Parent.BreadcrumbService)
local ContextService = require(script.Parent.ContextService)

local GetScriptFromFullName = require(script.Parent.Parent.Util.GetScriptFromFullName)

local Network = require(script.Parent.Parent.Network.Server)

local MESSAGE_REPORTER_DELAY = 60

local LogCaptureService = {}

LogCaptureService.Priority = 0
LogCaptureService.Reporter = Console.new(`{script.Name}`)

LogCaptureService.MessageQueue = {}

LogCaptureService.MessageQueueUpdated = Signal.new()

function LogCaptureService.OmitUserInformationFromSource(self: LogCaptureService, source: string)
	for _, player in Players:GetPlayers() do
		source = string.gsub(source, player.UserId, "<USER_ID>")
		source = string.gsub(source, player.Name, "<USER_NAME>")
		source = string.gsub(source, player.DisplayName, "<USER_DISPLAY_NAME>")
	end

	return source
end

function LogCaptureService.OnMessageError(self: LogCaptureService, source: string, trace: string)
	local filePath, message = string.match(source, "(%S+):%d+: (.+)")
	local scriptObject = GetScriptFromFullName(filePath)

	if not scriptObject then
		self.Reporter:Warn(`Dropping error '{message}' from '{filePath}' - script not found`)

		return
	end

	local breadcrumbs = BreadcrumbService:GetBreadcrumbsFor(filePath)
	local context = ContextService:GetContextFor(filePath)

	local ancestors = {}
	local parent = scriptObject

	while parent ~= game do
		table.insert(ancestors, {
			name = parent.Name,
			class = parent.ClassName,
		})

		parent = parent.Parent
	end

	table.insert(self.MessageQueue, {
		["message"] = self:OmitUserInformationFromSource(message),
		["placeVersion"] = game.PlaceVersion,
		["serverId"] = ApiService.JobId,
		["script"] = filePath,
		["trace"] = trace,
		["ancestors"] = ancestors,
		["breadcrumbs"] = breadcrumbs,
		["context"] = HttpService:JSONEncode(context)
	})
end

function LogCaptureService.OnStart(self: LogCaptureService)
	ScriptContext.Error:Connect(function(message: string, trace: string)
		self:OnMessageError(message, trace)
	end)

	Network.LogError.SetCallback(function(_: Player, clientErrorQueue)
		for _, clientErrorObject in clientErrorQueue do
			self:OnMessageError(clientErrorObject.message, clientErrorObject.trace)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(MESSAGE_REPORTER_DELAY)

			if #self.MessageQueue == 0 then
				continue
			end

			ApiService:PostAsync(string.format(ApiPaths.ServerLogBatch, ApiService.ProjectId), {
				items = self.MessageQueue,
			})

			self.MessageQueue = {}
		end
	end)
end

export type LogCaptureService = typeof(LogCaptureService)

return LogCaptureService
