local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)
local Api = require(script.Parent.Parent.Enums.Api)
local ServerType = require(script.Parent.Parent.Enums.ServerType)

local MetrikAPI = require(script.Parent.Parent)

local HEARTBEAT_UPDATE_SECONDS = 60 * 30 -- send server heartbeat every 30 minutes.

local ApiService = { }

ApiService.Priority = 100
ApiService.Reporter = Console.new(`🎯 {script.Name}`)

ApiService.HTTPEnabled = true
ApiService.JobId = game.JobId ~= "" and game.JobId
	or HttpService:GenerateGUID(false)

function ApiService.RequestAsync(
	self: ApiService,
	apiMethod: "GET" | "POST",
	api: string,
	data: { [any]: any }
)
	return Promise.new(function(resolve, reject)
		self.Reporter:Debug(`'{apiMethod}' request made to API '{api}'`)

		if not self.HTTPEnabled then
			reject(`HTTP Service Requests failed to process, please ensure that HTTP requests are enabled via game settings!`)
		end

		local response = HttpService:RequestAsync({
			Url = `https://{ApiPaths[Api.BaseUrl]}{ApiPaths[api]}`,
			Method = apiMethod,
			Headers = {
				["x-api-key"] = MetrikAPI.Private.ProjectId,
				["content-type"] = "application/json"
			},
			Body = HttpService:JSONEncode(data)
		})

		if not response.Success then
			local decodedJson = HttpService:JSONDecode(response.Body)
			local errorObject = { }

			errorObject.StatusCode = response.StatusCode
			errorObject.StatusMessage = response.StatusMessage
			errorObject.BodyCode = decodedJson.code
			errorObject.BodyMessage = decodedJson.code
			errorObject.Errors = { }

			if decodedJson.issues then
				for _, issue in decodedJson.issues do
					table.insert(errorObject.Errors, issue)
				end
			end

			self.Reporter:Warn(`'{apiMethod}' request failed for API '{api}': %s`, errorObject)

			reject(errorObject)
		end

		resolve(response)
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
		serverId = self.JobId,
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
	local serverType = ServerType.Public

	if RunService:IsStudio() then
		-- todo, backend doesn't support STUDIO

		serverType = ServerType.Reserved
	elseif game.VIPServerOwnerId ~= 0 then
		serverType = ServerType.Private
	elseif game.VIPServerId  ~= "" then
		serverType = ServerType.Reserved
	end

	self:PostAsync(Api.ServerStart, {
		["serverId"] = self.JobId,
		["placeVersion"] = game.PlaceVersion,
		["type"] = string.upper(serverType)
	}):andThen(function(request)
		if not request.Success then
			self.Reporter:Critical(`Server HTTP Request failed: '{request.StatusCode}' ~ '{request.StatusMessage}'`)

			return
		end
		
		self:Heartbeat(HEARTBEAT_UPDATE_SECONDS)
		
		self.Reporter:Log(`Server '{self.JobId}' has authenticated with the Metrik API`)

		game:BindToClose(function()
			self:StopHeartbeat()
	
			self:PostAsync(Api.ServerEnd, {
				serverUuid = self.JobId
			})
		end)
	end):catch(function(exception: string)
		self.HTTPEnabled = false

		task.spawn(function()
			self.Reporter:Critical(`Server HTTP Request failed: {exception}`)
		end)
	end)
end

export type ApiService = typeof(ApiService)

return ApiService