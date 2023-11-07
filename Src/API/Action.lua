--[[
	Metrik SDK Action.
]]

local Signal = require(script.Parent.Parent.Packages.Signal)

local NULL_ACTION_ARGUMENT = "\2<<NULL>>"

--[=[
	@class Action

	Actions enable developers to interact with the Metrik backend, when an action is instantiated the backend is notified so that servers
		that have this action is callable from the Metrik site.
]=]
local Action = { }

Action.Public = { }
Action.Prototype = { }
Action.Instantiated = { }

Action.Public.ActionAdded = Signal.new()

--[=[
	The 'CanActivate' function is called before all lifecycle calls, if the CanActivate call returns false, the event will be stopped,
		however, if this function returns true, execution of the Action will continue.

	@method PreActivated
	@within Action

	@return boolean
]=]--
function Action.Prototype.CanActivate(self: Action): boolean
	return true
end

--[=[
	The 'PreRun' function is called before the Run function is called, this allows developers to modify the arguments going into the
		Run call.

	@method PreActivated
	@within Action

	@param arguments { [any]: any }

	@return arguments { [any]: any }
]=]--
function Action.Prototype.PreRun(self: Action, arguments: { [any]: any }): { [any]: any }
	return arguments
end

--[=[
	The 'OnRun' function is called when the action needs to be executed, most of your action logic should be in this lifecycle method.

	@method OnRun
	@within Action

	@param exception string

	@return ... any
]=]--
function Action.Prototype.OnRun(self: Action, ...: any): ... any
	return
end

--[=[
	The 'OnError' function is in the case the 'OnActivation' function has errored out.

	@method OnError
	@within Action

	@param exception string

	@return ()
]=]--
function Action.Prototype.OnError(self: Action, exception: string): ()
	return warn(`Action '{self.Name}' failed to execute ':OnActivated' call with error:\n{exception}`)
end

--[=[
	The 'PostActivated' function is called after the 'OnActivated' function has finished execution.

	:::note
		The 'PostActivated' function will not be invoked if the 'OnActivated' function has failed to execute.
	:::

	@method PostActivated
	@within Action

	@param arguments { any: any }
	@param results { any: any }

	@return ... any
]=]--
function Action.Prototype.PostRun(self: Action, arguments: { [any]: any }, results: { [any]: any }): ()
	return
end

--[=[
	The 'OnRemoteServerInputRecieved' function is called to handle when the Metrik dashboard has executed an action, allowing developers
		to overwrite the logic that handles the Actions lifetime calls.

	:::warning
		Only change this function if you want to change the behavior of the Action class, otherwise leave this function be! It's boilerplate code
			is required for proper execution.
	:::

	```lua
	local SomeAction = Metrik.Action.new({
		Name = "Some Action",

		Arguments = { }
	})

	function SomeAction:OnRemoteServerInputRecieved()
		-- implement your own behaviour for how an action should behave.
	end
	```

	@method OnRemoteServerInputRecieved
	@within Action

	@param arguments { any: any }

	@return boolean
]=]--
function Action.Prototype.OnRemoteServerInputRecieved(self: Action, arguments: { [any]: any }): boolean
	if not self:CanActivate() then
		return false
	end

	if self.Arguments then
		for argumentIndex, argumentMetadata in next, self.Arguments do
			if arguments[argumentIndex] == NULL_ACTION_ARGUMENT then
				arguments[argumentIndex] = argumentMetadata.ArgumentDefault
			else
				local typeofTrueArgument = typeof(arguments[argumentIndex])

				if typeofTrueArgument ~= argumentMetadata.ArgumentType then
					return false
				end
			end
		end
	end

	local processedArguments = self:PreRun(arguments)

	if not processedArguments then
		processedArguments = arguments
	end

	local success, result = pcall(function()
		return { self:OnRun(table.unpack(processedArguments, 1, table.maxn(processedArguments))) }
	end)

	if not success then
		self:OnError(result)

		return false
	end

	self:PostRun(arguments, result)

	return true
end

--[=[
	Constructor function to create a new Metrik Action, Metrik Actions use lifetime methods to interact with the developer, lifetime methods
		are called when the Metrik dashboard interacts with a Metrik Action.

	```lua
	local KickPlayerAction = Metrik.Action.new({
		Name = "Kick Player Action",

		Arguments = { "number", "string" }
	})

	function KickPlayerAction:OnActivated(userId: number, message: string)
		local targetPlayer = game.Players:GetPlayerFromUserId(userId)

		if not targetPlayer then
			return
		end

		targetPlayer:Kick(message)
	end
	```

	@function new
	@within Action

	@param actionSettings { Name: string }

	@return Action
]=]--
function Action.Public.new(actionSettings: ActionSettings): Action
	assert(not Action.Instantiated[actionSettings.Uuid], `Action '{actionSettings.Uuid}' already exists.`)

	local self = setmetatable({ }, {
		__index = Action.Prototype
	})

	self.Name = actionSettings.Name
	self.Uuid = actionSettings.Uuid

	self.Arguments = actionSettings.Arguments

	Action.Instantiated[actionSettings.Uuid] = self
	Action.Public.ActionAdded:Fire(self)

	return self
end

--[=[
	Function used to fetch an action from it's action name.

	```lua
	local KickPlayerAction = Metrik.Action.fetch("Kick Player Action")

	KickPlayerAction:OnActivated(0, "This is a test kick!")
	```

	@function from
	@within Action

	@param actionName string

	@return Action?
]=]--
function Action.Public.fromUuid(actionUuid: string): Action?
	return Action.Instantiated[actionUuid]
end

export type Action = typeof(Action.Prototype) & ActionSettings

export type ActionSettings = {
	Name: string,
	Uuid: string,

	Arguments: {
		{
			ArgumentName: string,
			ArgumentType: string,
			ArgumentDefault: any?,
			ArgumentIsOptional: boolean?,
		}
	}?
}

return Action.Public