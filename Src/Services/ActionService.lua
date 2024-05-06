--[[
	
]]


local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local MessageReceiveService = require(script.Parent.MessageReceiveService)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local ArgumentType = require(script.Parent.Parent.Enums.ArgumentType)

local ApiService = require(script.Parent.ApiService)

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
		-- fixme: account for 'behaviour' key in packet

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

		if actionObject:CanRun(sanitizedArguments) then
			actionObject:OnRun(table.unpack(sanitizedArguments))
		end
		
		-- todo: support different statuses!
	end)
end

export type ActionService = typeof(ActionService)
export type ActionPacket = {
	key: string,
	arguments: { }?,
	serverIds: { }?,
	runId: string,
	behaviour: string
}

return ActionService
