--[[
	
]]

local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local MessageReceiveService = require(script.Parent.MessageReceiveService)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local ArgumentType = require(script.Parent.Parent.Enums.ArgumentType)
local ActionBehaviour = require(script.Parent.Parent.Enums.ActionBehaviour)

local ApiService = require(script.Parent.ApiService)

local DELAY_BEFORE_MARKING_ACTION_AS_PENDING = 5

local ActionService = {}

ActionService.Priority = -1
ActionService.Reporter = Console.new(`{script.Name}`)

ActionService.Actions = {}

function ActionService.RegisterActionAsync(self: ActionService, action: any)
	local requestBody = {}

	requestBody.serverId = ApiService.JobId
	requestBody.key = action.Key
	requestBody.name = action.Name
	requestBody.placeVersion = game.PlaceVersion 
	requestBody.description = action.Description
	requestBody.arguments = {}

	for argumentName, argumentObject in action.Arguments do
		local argumentBody = {}

		argumentBody.name = argumentName
		argumentBody.description = argumentObject.Description
		argumentBody.required = argumentObject.Required
		argumentBody.default = argumentObject.Default
		argumentBody.type = string.upper(argumentObject.Type)

		table.insert(requestBody.arguments, argumentBody)
	end

	self.Actions[action.Key] = action

	return ApiService:PostAsync(string.format(
		ApiPaths.RegisterAction,
		ApiService.ProjectId
	), requestBody)
end

function ActionService.OnStart(self: ActionService)
	MessageReceiveService.OnAction:Connect(function(packet: ActionPacket)
		if packet.behaviour == ActionBehaviour.SelectedServers or packet.behaviour == ActionBehaviour.SelectedServer then
			assert(packet.serverIds ~= nil, `Action behaviour for '{packet.key}' was set to '{packet.behaviour}' but had no 'serverIds' key!`)

			if not table.find(packet.serverIds, ApiService.JobId) then
				self.Reporter:Debug(`Action '{packet.key}' dismissed - not in selected servers array.`)

				return
			end
		elseif packet.behaviour == ActionBehaviour.SelectedVersions or packet.behaviour == ActionBehaviour.SelectedVersion then
			assert(packet.placeVersions ~= nil, `Action behaviour for '{packet.key}' was set to '{packet.behaviour}' but had no 'placeVersions' key!`)

			if not table.find(packet.placeVersions, game.PlaceVersion) then
				self.Reporter:Debug(`Action '{packet.key}' dismissed - not in selected versions array.`)

				return
			end
		elseif packet.behaviour == ActionBehaviour.RandomServer then
			local success, claimResponse = ApiService:PostAsync(string.format(ApiPaths.ClaimAction, ApiService.ProjectId), {
				runId = packet.runId,
				serverId = ApiService.JobId
			}):await()

			if not success then
				self.Reporter:Warn(`Action '{packet.key}' dismissed - {claimResponse}.`)

				return
			end

			if not claimResponse.Success then
				self.Reporter:Warn(`Action '{packet.key}' dismissed - {claimResponse.StatusMessage}.`)

				return
			end

			local bodyMessage = HttpService:JSONDecode(claimResponse.Body)

			if not bodyMessage.success then
				self.Reporter:Warn(`Action '{packet.key}' dismissed - {bodyMessage.message}.`)

				return
			end
		elseif packet.behaviour == ActionBehaviour.AllServers then
			self.Reporter:Debug(`Action behaviour set to: '{packet.behaviour}', running!`)
		else
			self.Reporter:Warn(`Action behaviour set to: '{packet.behaviour}', this is unknown!`)
		end

		local actionObject = self.Actions[packet.key]
		local sanitizedArguments = {}

		if not actionObject then
			self.Reporter:Warn(`Attempted to invoke missing action '{packet.key}', this action was never registered!`)

			return
		end

		if packet.arguments then
			for sanitizedArgumentPosition, argumentName in actionObject.ArgumentOrderedList do
				local argumentData = actionObject.Arguments[argumentName]
				local serverArgumentData = Sift.Array.findWhere(packet.arguments, function(data)
					return data.name == argumentName
				end)

				local argumentValue

				if serverArgumentData then
					serverArgumentData = packet.arguments[serverArgumentData]

					if serverArgumentData.type ~= argumentData.Type then
						self.Reporter:Warn(`Argument '{argumentName}' has invalid types! Dropping Action request!`)
					
						return
					end

					if
						argumentData.Type == ArgumentType.String
						or argumentData.Type == ArgumentType.Number
						or argumentData.Type == ArgumentType.Boolean
					then
						argumentValue = serverArgumentData.value
					end

					table.insert(sanitizedArguments, argumentValue)
				else
					if argumentData.Required then
						self.Reporter:Warn(`Required argument '{argumentName}' is missing! Dropping Action request!`)
					
						return
					elseif argumentData.Default then
						argumentValue = argumentData.Default
					end
				end
			end
		end

		local success, response

		if actionObject:CanRun(sanitizedArguments) then
			local delayThreadRan = false
			local delayThread = task.delay(DELAY_BEFORE_MARKING_ACTION_AS_PENDING, function()
				delayThreadRan = true

				ApiService:PostAsync(string.format(ApiPaths.ReturnAction, ApiService.ProjectId), {
					runId = packet.runId,
					result = `Action has taken over 5 seconds to process, pending completion..`,
					status = "PENDING"
				})
			end)

			success, response = pcall(function()
				actionObject:OnRun(table.unpack(sanitizedArguments))
			end)

			if not delayThreadRan then
				task.cancel(delayThread)
			end
		else
			success = false
			response = `Action ":CanRun" call failed, action was never ran.`
		end
		
		ApiService:PostAsync(string.format(ApiPaths.ReturnAction, ApiService.ProjectId), {
			runId = packet.runId,
			result = tostring(response),
			status = success and "SUCCESS" or "FAILED"
		})
	end)
end

export type ActionService = typeof(ActionService)
export type ActionPacket = {
	key: string,
	arguments: { }?,
	placeVersions: { }?,
	serverIds: { }?,
	runId: string,
	behaviour: string
}

return ActionService
