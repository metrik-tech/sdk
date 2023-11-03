--[[
	InternalActionService - Service responsible for loading and handling internal metrik actions.
]]

local Console = require(script.Parent.Parent.Packages.Console)
local Loader = require(script.Parent.Parent.Packages.Loader)

local Action = require(script.Parent.Parent.API.Action)

local InternalActionService = { }

InternalActionService.Priority = -1
InternalActionService.Reporter = Console.new(`🎬 {script.Name}`)

InternalActionService.Actions = { } :: { [string]: Action.Action }

function InternalActionService.OnStart(self: InternalActionService)
	local Actions = Loader.LoadDescendants(script.Parent.Parent.Actions)

	for actionModuleName, actionConstructorFunction in Actions do
		local actionObject = actionConstructorFunction()

		self.Actions[actionModuleName] = actionObject
		self.Reporter:Debug(`Loaded internal Metrik action: '{actionModuleName}'`)
	end
end

export type InternalActionService = typeof(InternalActionService)

return InternalActionService