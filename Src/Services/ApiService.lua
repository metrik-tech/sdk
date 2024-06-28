local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local State = require(script.Parent.Parent.Packages.State)
local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)
local ServerType = require(script.Parent.Parent.Enums.ServerType)

local HEARTBEAT_UPDATE_SECONDS = 60 * 10 -- send server heartbeat every 10 minutes.
local DELAY_BEFORE_FIRST_HEARTBEAT = 120

local ApiService = {}

ApiService.Priority = 100
ApiService.Reporter = Console.new(`{script.Name}`)

ApiService.HTTPEnabled = true
ApiService.JobId = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)

ApiService.AuthenticationSecret = (nil :: any) :: Secret
ApiService.ProjectId = (nil :: any) :: string

ApiService.Trace = {}
ApiService.ServerType = "Unknown"

ApiService.Authenticated = State.new(false)

-- todo: re-queue HTTP requests if they fail! 

function ApiService._QueryTraceAsync(self: ApiService)
	return self:RawRequestAsync({
		Url = `https://{ApiPaths.TraceUrl}`,
		Method = "GET"
	})
		:andThen(function(response)
			local traceData = {}
			
			local responseBody = response.Body
			local responseBodySplit = string.split(responseBody, "\n")
			
			for _, lineInformation in responseBodySplit do
				local lineInformationSplit = string.split(lineInformation, "=")
				local lineKey = table.remove(lineInformationSplit, 1)
				local lineData = table.concat(lineInformationSplit, "=")

				traceData[lineKey] = lineData
			end

			self.Reporter:Debug(`Server trace collected; loc={traceData.loc}; ip={traceData.ip}`)

			self.Trace = traceData
		end)
end

function ApiService._QueryServerStartAsync(self: ApiService)
	local serverType = ServerType.Public

	if RunService:IsStudio() then
		-- todo, backend doesn't support STUDIO

		serverType = ServerType.Reserved
	elseif game.VIPServerOwnerId ~= 0 then
		serverType = ServerType.Private
	elseif game.VIPServerId ~= "" then
		serverType = ServerType.Reserved
	end

	self.ServerType = serverType

	return self:PostAsync(string.format(ApiPaths.ServerStart, self.ProjectId), {
		["serverId"] = self.JobId,
		["placeVersion"] = game.PlaceVersion,
		["type"] = string.upper(serverType),
		["maxPlayers"] = Players.MaxPlayers,
		["region"] = self.Trace.loc
	})
		:andThen(function(request)
			task.delay(DELAY_BEFORE_FIRST_HEARTBEAT, function()
				self:Heartbeat(HEARTBEAT_UPDATE_SECONDS)
			end)

			self.Reporter:Log(`Server '{self.JobId}' has authenticated with the Metrik API`)

			self.Authenticated:Set(true)

			game:BindToClose(function()
				self:StopHeartbeat()

				self:PostAsync(string.format(ApiPaths.ServerEnd, self.ProjectId), {
					serverId = self.JobId,
				})
			end)
		end)
end

function ApiService.RawRequestAsync(self: ApiService, data: { [any]: any })
	return Promise.new(function(resolve, reject)
		local success, response = pcall(HttpService.RequestAsync, HttpService, data)

		if not success or not response.Success then
			local responseIsTable = typeof(response) == "table"
			
			return reject({
				Success = responseIsTable and response.Success or success,
				StatusCode = responseIsTable and response.StatusCode or 0,
				StatusMessage = responseIsTable and response.StatusMessage or response,
				Headers = responseIsTable and response.Headers or {},
				Body = responseIsTable and response.Body or HttpService:JSONEncode({
					code = 0,
					message = response
				})
			})
		end

		return resolve(response)
	end)
end

function ApiService.RequestAsync(self: ApiService, apiMethod: "GET" | "POST", apiEndpoint: string, data: { [any]: any }?)
	return Promise.new(function(resolve, reject)
		self.Reporter:Debug(`'{apiMethod}' request made to endpoint '{apiEndpoint}'`)

		if not self.HTTPEnabled then
			reject(
				`HTTP Service Requests failed to process, please ensure that HTTP requests are enabled via game settings!`
			)
		end

		self:RawRequestAsync({
			Url = `https://{ApiPaths.BaseUrl}{apiEndpoint}`,
			Method = apiMethod,
			Headers = {
				["x-api-key"] = self.AuthenticationSecret,
				["content-type"] = "application/json",
			},
			Body = data and HttpService:JSONEncode(data) or nil,
		}):andThen(function(response)
			resolve(response)
		end):catch(function(response)
			local decodedJson = HttpService:JSONDecode(response.Body)
			local errorObject = {}

			errorObject.StatusCode = response.StatusCode
			errorObject.StatusMessage = response.StatusMessage
			errorObject.BodyCode = decodedJson.code
			errorObject.BodyMessage = decodedJson.code
			errorObject.Errors = {}
			errorObject.Request = {
				Url = `https://{ApiPaths.BaseUrl}{apiEndpoint}`,
				Method = apiMethod,
				Headers = {
					["x-api-key"] = self.AuthenticationSecret,
					["content-type"] = "application/json",
				},
				Body = HttpService:JSONEncode(data),
			}

			if decodedJson.issues then
				for _, issue in decodedJson.issues do
					table.insert(errorObject.Errors, issue)
				end
			elseif decodedJson.message then
				table.insert(errorObject.Errors, decodedJson.message)
			end

			self.Reporter:Warn(`'{apiMethod}' request failed for endpoint '{apiEndpoint}': %s`, errorObject)

			reject(errorObject)
		end)
	end)
end

function ApiService.GetAsync(self: ApiService, apiEndpoint: string, queries: { [string]: any })
	local url = apiEndpoint
	local counter = 0

	for queryName, queryValue in queries do
		url ..= `{counter == 0 and "?" or "&"}{HttpService:UrlEncode(queryName)}={HttpService:UrlEncode(queryValue)}`

		counter += 1
	end

	return self:RequestAsync("GET", url)
end

function ApiService.PostAsync(self: ApiService, apiEndpoint: string, data: { [any]: any })
	return self:RequestAsync("POST", apiEndpoint, data)
end

function ApiService.Heartbeat(self: ApiService, nextHeartbeatIn: number?)
	local playerArray = {}

	for _, player in Players:GetPlayers() do
		table.insert(playerArray, player.UserId)
	end

	self:PostAsync(ApiPaths.ServerHeartbeat, {
		serverId = self.JobId,
		players = playerArray,
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

function ApiService.SetProjectId(self: ApiService, projectId: string)
	self.ProjectId = projectId
end

function ApiService.SetAuthenticationSecret(self: ApiService, authenticationSecret: Secret)
	self.AuthenticationSecret = authenticationSecret
end

function ApiService.OnStart(self: ApiService)
	local thread = coroutine.running()

	task.defer(function()
		self:_QueryTraceAsync():catch(function(request)
			coroutine.resume(thread, false, request.StatusMessage)
		end):await()

		self:_QueryServerStartAsync():catch(function(request)
			coroutine.resume(thread, false, request.StatusMessage)
		end):await()

		coroutine.resume(thread, true)
	end)

	local status, message = coroutine.yield()

	ApiService.HTTPEnabled = status

	assert(status, message)
end

export type ApiService = typeof(ApiService)

return ApiService
