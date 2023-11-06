local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)
local Api = require(script.Parent.Parent.Enums.Api)

local HEARTBEAT_UPDATE_SECONDS = 60 * 30 -- send server heartbeat every 30 minutes.

local ApiService = { }

ApiService.Priority = 100
ApiService.Reporter = Console.new(`🎯 {script.Name}`)

function ApiService.RequestAsync(
	self: ApiService,
	apiMethod: "GET" | "POST",
	api: string,
	data: { [any]: any }
)
	return Promise.new(function(resolve, reject)
		self.Reporter:Debug(`'{apiMethod}' request made to API '{api}'`)

		resolve(HttpService:RequestAsync({
			Url = `https://{ApiPaths[Api.BaseUrl]}{ApiPaths[api]}`,
			Method = apiMethod,
			Headers = { },
			Body = HttpService:JSONEncode(data)
		}))
	end)
end

function ApiService.GetAsync(self: ApiService, api: string, data: { [any]: any })
	return self:RequestAsync("GET", api, data)
end

function ApiService.PostAsync(self: ApiService, api: string, data: { [any]: any })
	return self:RequestAsync("POST", api, data)
end

function ApiService.Heartbeat(self: ApiService, nextHeartbeatIn: number?)
	self:PostAsync(Api.ServerHeartbeat, {
		serverUuid = game.JobId,
		epochTimestamp = workspace:GetServerTimeNow()
	}):await()

	if nextHeartbeatIn then
		self.HeartbeatThread = task.delay(nextHeartbeatIn, function()
			self:Heartbeat(nextHeartbeatIn)
		end)
	end
end

function ApiService.StopHeartbeat(self: ApiService, nextHeartbeatIn: number?)
	if self.HeartbeatThread then
		task.cancel(self.HeartbeatThread)

		self.HeartbeatThread = nil
	end
end

function ApiService.OnStart(self: ApiService)
	self:PostAsync(Api.ServerStart, {
		serverUuid = game.JobId,
		isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0,
		isStudioSession = RunService:IsStudio()
	}):andThen(function()
		self:Heartbeat(HEARTBEAT_UPDATE_SECONDS)

		game:BindToClose(function()
			self:StopHeartbeat()
	
			self:PostAsync(Api.ServerEnd, {
				serverUuid = game.JobId
			})
		end)
	end)
end

export type ApiService = typeof(ApiService)

return ApiService