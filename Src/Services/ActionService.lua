--[[
	
]]

local Console = require(script.Parent.Parent.Packages.Console)
local Loader = require(script.Parent.Parent.Packages.Loader)
local State = require(script.Parent.Parent.Packages.State)
local Promise = require(script.Parent.Parent.Packages.Promise)

local Action = require(script.Parent.Parent.API.Action)

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

export type ActionService = typeof(ActionService)

return ActionService