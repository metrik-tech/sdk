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
local COMMON_UUID_PATTERNS = table.freeze({
	"rbxassetid://%d+",
	"https://www.roblox.com/asset/?id=%d+",
})

local LogCaptureService = {}

LogCaptureService.Priority = 0
LogCaptureService.Reporter = Console.new(`{script.Name}`)

LogCaptureService.MessageQueue = {}

LogCaptureService.MessageQueueUpdated = Signal.new()

function LogCaptureService.OmitAssetUrlFromSource(self: LogCaptureService, url: string, source: string)
	local index = string.find(source, url)

	while index do
		local lastIndex = string.find(source, " ", index)

		if lastIndex then
			lastIndex -= 1
		else
			lastIndex = string.find(source, "\n", index)
		end

		if not lastIndex then
			lastIndex = #source
		end

		local input = string.sub(source, index, lastIndex)
		
		source = string.gsub(source, input, "<ASSET_URL>")
		index = string.find(source, url)
	end

	return source
end

function LogCaptureService.OmitUUIDsFromSource(self: LogCaptureService, source: string)
	for _, player in Players:GetPlayers() do
		source = string.gsub(source, player.UserId, "<USER_ID>")
		source = string.gsub(source, player.Name, "<USER_NAME>")
		source = string.gsub(source, player.DisplayName, "<USER_DISPLAY_NAME>")
	end

	for _, pattern in COMMON_UUID_PATTERNS do
		source = string.gsub(source, pattern, "<UUID>")
	end

	source = self:OmitAssetUrlFromSource("rbxasset://", source)
	source = self:OmitAssetUrlFromSource("rbxthumb://", source)

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

	print(self:OmitUUIDsFromSource(message))

	table.insert(self.MessageQueue, {
		["message"] = self:OmitUUIDsFromSource(message),
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
