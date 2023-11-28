--[[
	
]]

local Console = require(script.Parent.Parent.Packages.Console)
local Loader = require(script.Parent.Parent.Packages.Loader)
local State = require(script.Parent.Parent.Packages.State)
local Promise = require(script.Parent.Parent.Packages.Promise)

local Api = require(script.Parent.Parent.Enums.Api)
local ActionType = require(script.Parent.Parent.Enums.ActionType)
local Error = require(script.Parent.Parent.Enums.Error)

local ErrorFormats = require(script.Parent.Parent.Data.ErrorFormats)

local Action = require(script.Parent.Parent.API.Action)

local ApiService = require(script.Parent.ApiService)

local ActionService = { }

ActionService.Priority = -1
ActionService.Reporter = Console.new(`🎬 {script.Name}`)

ActionService.Actions = { } :: { [string]: Action.Action }
ActionService.InternalActionsLoaded = State.new(false)

function ActionService.InvokeActionAsync(self: ActionService, actionUuid: string, eventArguments: { [any]: any })
	local actionObject = Action.fromUuid(actionUuid)

	return Promise.try(function()
		return actionObject:OnRemoteServerInputRecieved(eventArguments)
	end)
end

function ActionService.OnStart(self: ActionService)
	local Actions = Loader.LoadDescendants(script.Parent.Parent.Actions)

	for actionModuleName, actionConstructorFunction in Actions do
		local actionObject = actionConstructorFunction()

		self.Actions[actionModuleName] = actionObject
		self.Reporter:Debug(`Loaded internal Metrik action: '{actionModuleName}'`)
	end

	self.InternalActionsLoaded:Set(true)
end

function ActionService.OnInit(self: ActionService)
	Action.ActionAdded:Connect(function(actionObject: Action.Action)
		local camelCaseActionArguments = { }

		if actionObject.Arguments then
			for index, actionMetadata in next, actionObject.Arguments do
				self.Reporter:Assert(
					ActionType[actionMetadata.Type] ~= nil,
					string.format(
						ErrorFormats[Error.InvalidActionArgumentType],
						actionMetadata.Type,
						actionObject.Name
					)
				)

				camelCaseActionArguments[index] = {
					["default"] = actionMetadata.Default,
					["required"] = actionMetadata.IsRequired,
					["name"] = actionMetadata.Name,
					["type"] = string.upper(actionMetadata.Type)
				}
			end
		end

		ApiService:PostAsync(Api.RegisterAction, {
			["serverId"] = ApiService.JobId,
			["placeVersion"] = tostring(game.PlaceVersion),
			["key"] = actionObject.Uuid,
			["name"] = actionObject.Name,
			["arguments"] = camelCaseActionArguments,
		}):andThen(function()
			self.Reporter:Log(`Registered action '{actionObject.Name}' with metrik backend`)
		end)
	end)
end

export type ActionService = typeof(ActionService)

return ActionService