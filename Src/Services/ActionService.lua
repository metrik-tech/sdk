--[[
	
]]


local Console = require(script.Parent.Parent.Packages.Console)

local MessageReceiveService = require(script.Parent.MessageReceiveService)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local ApiService = require(script.Parent.ApiService)

local ActionService = {}

ActionService.Priority = -1
ActionService.Reporter = Console.new(`{script.Name}`)

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

	local success, result = ApiService:PostAsync(string.format(
		ApiPaths.RegisterAction,
		ApiService.ProjectId
	), requestBody)

	if not success then
		self.Reporter:Critical(`Failed to register action: '{action.Name}' - {result}`)
	end
end

function ActionService.OnStart(self: ActionService)
	MessageReceiveService.OnAction:Connect(function(packet: ActionPacket)
		
	end)
end

export type ActionService = typeof(ActionService)
export type ActionPacket = {
	id: string,
	message: string,
	type: string
}

return ActionService
