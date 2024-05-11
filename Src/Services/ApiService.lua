local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local State = require(script.Parent.Parent.Packages.State)
local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)
local Api = require(script.Parent.Parent.Enums.Api)
local ServerType = require(script.Parent.Parent.Enums.ServerType)

local HEARTBEAT_UPDATE_SECONDS = 60 * 10 -- send server heartbeat every 10 minutes.
local DELAY_BEFORE_FIRST_HEARTBEAT = 120

local ApiService = {}

ApiService.Priority = 100
ApiService.Reporter = Console.new(`{script.Name}`)

ApiService.HTTPEnabled = true
ApiService.JobId = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)

ApiService.ProjectId = ""
ApiService.AuthenticationToken = ""

ApiService.Trace = {}

ApiService.Authenticated = State.new(false)

function ApiService._QueryTraceAsync(self: ApiService)
	return self:RawRequestAsync({
		Url = `https://{ApiPaths[Api.TraceUrl]}`,
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

	return self:PostAsync(Api.ServerStart, {
		["serverId"] = self.JobId,
		["placeVersion"] = game.PlaceVersion,
		["type"] = string.upper(serverType),
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

				self:PostAsync(Api.ServerEnd, {
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

function ApiService.RequestAsync(self: ApiService, apiMethod: "GET" | "POST", api: string, data: { [any]: any })
	return Promise.new(function(resolve, reject)
		self.Reporter:Debug(`'{apiMethod}' request made to API '{api}'`)

		if not self.HTTPEnabled then
			reject(
				`HTTP Service Requests failed to process, please ensure that HTTP requests are enabled via game settings!`
			)
		end

		self:RawRequestAsync({
			Url = `https://{ApiPaths[Api.BaseUrl]}{string.format(ApiPaths[api], self.ProjectId)}`,
			Method = apiMethod,
			Headers = {
				["x-api-key"] = self.AuthenticationToken,
				["content-type"] = "application/json",
			},
			Body = HttpService:JSONEncode(data),
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
				Url = `https://{ApiPaths[Api.BaseUrl]}{string.format(ApiPaths[api], self.ProjectId)}`,
				Method = apiMethod,
				Headers = {
					["x-api-key"] = string.sub(self.AuthenticationToken, 0, #self.AuthenticationToken - 10)
						.. string.rep(`*`, 10),
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

			self.Reporter:Warn(`'{apiMethod}' request failed for API '{api}': %s`, errorObject)

			reject(errorObject)
		end)
	end)
end

function ApiService.GetAsync(self: ApiService, api: string, data: { [any]: any })
	return self:RequestAsync("GET", api, data)
end

function ApiService.PostAsync(self: ApiService, api: string, data: { [any]: any })
	return self:RequestAsync("POST", api, data)
end

function ApiService.Heartbeat(self: ApiService, nextHeartbeatIn: number?)
	local playerArray = {}

	for _, player in Players:GetPlayers() do
		table.insert(playerArray, player.UserId)
	end

	self:PostAsync(Api.ServerHeartbeat, {
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

function ApiService.SetAuthenticationToken(self: ApiService, authenticationToken: string)
	self.AuthenticationToken = authenticationToken
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
