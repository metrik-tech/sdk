local Sift = require(script.Parent.Parent.Packages.Sift)

local ActionService = require(script.Parent.Parent.Services.ActionService)

--[=[
	@class ActionBuilder

	ActionBuilder enables developers to build sophisticated/complicated Actions.

	The ActionBuilder class follows the Builder design pattern; https://refactoring.guru/design-patterns/builder
]=]
local ActionBuilder = {}

--[=[
	@class Action

	Action enable developers to interact with the Metrik backend, when an Action is instantiated the backend is notified so that servers
		that have this Action is callable from the Metrik site.

	You can only create an Action, through an ActionBuilder.
]=]
local Action = {}

Action.Instantiated = {}
Action.Prototype = {}

ActionBuilder.Public = {}
ActionBuilder.Prototype = {}

--[=[
	CanRun is called when the Action is run, this method is used to determine if the Action can be run.

	@method CanRun
	@within Action
	@return boolean
]=]
function Action.Prototype:CanRun(...: unknown)
	return true
end

--[=[
	OnRun is called when the Action is run, this method is used to execute the Action.

	@method OnRun
	@within Action
	@return boolean
]=]
function Action.Prototype:OnRun(...: unknown)
	print(`Method ':OnRun' has been called on Action<"{self.Name}">`)
end

--[=[
	SetName is used to set the name of the Action.

	@method SetName
	@param actionName string
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.SetName(self: ActionBuilder, actionName: string): ActionBuilder
	assert(#actionName <= 50, `Action name is too large, action name ranges between 1 <-> 50 characters!`)

	local actionNameKey = string.lower(actionName)

	actionNameKey = string.gsub(actionNameKey, "\32", "-")
	actionNameKey = string.gsub(actionNameKey, "\9", "-")
	actionNameKey = string.gsub(actionNameKey, "\0", "")
	
	self.Prototype.Name = actionName
	self.Prototype.Key =  actionNameKey

	return self
end

--[=[
	SetDescription is used to set the description of the Action.

	@method SetDescription
	@param description string
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.SetDescription(self: ActionBuilder, description: string): ActionBuilder
	assert(string.len(description) <= 500, "Action Description must be under 500 characters!")
	
	self.Prototype.Description = description

	return self
end

--[=[
	OnRun is used to set the callback that is called when the Action is run.

	@method OnRun
	@param callback (Action, ...any) -> ...any
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.OnRun(self: ActionBuilder, callback: (Action, ...any) -> ...any): ActionBuilder
	self.Prototype.OnRun = callback

	return self
end

--[=[
	CanRun is used to set the callback that is called when the Action can be run.

	@method CanRun
	@param callback (Action, ...any) -> boolean
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.CanRun(self: ActionBuilder, callback: (Action, ...any) -> boolean): ActionBuilder
	self.Prototype.CanRun = callback

	return self
end

--[=[
	AddArgument is used to add an argument to the Action.

	@method AddArgument
	@param argumentName string
	@param argumentMetadata {
		Type: ("string" | "number" | "boolean")?,
		Description: string?,
		Required: boolean?,
		IsArray: boolean?,
		Default: any,
	}?
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.AddArgument(self: ActionBuilder, argumentName: string, argumentMetadata: ArgumentMetadata?): ActionBuilder
	local filteredArgumentName = string.lower(argumentName)
	local argumentsDict = self.Prototype.Arguments :: { }

	filteredArgumentName = string.gsub(filteredArgumentName, "\32", "-")
	filteredArgumentName = string.gsub(filteredArgumentName, "\9", "-")
	filteredArgumentName = string.gsub(filteredArgumentName, "\0", "")
	
	argumentsDict[filteredArgumentName] = {
		Type = argumentMetadata and string.upper(argumentMetadata.Type or "STRING"),
		Description = argumentMetadata and argumentMetadata.Description or "",
		Required = argumentMetadata and argumentMetadata.Required or false,
		Default = argumentMetadata and argumentMetadata.Default or "",
		IsArray = argumentMetadata and argumentMetadata.IsArray or false
	}

	table.insert(self.Prototype.ArgumentOrderedList, filteredArgumentName)

	return self
end

--[=[
	AddArguments is used to add multiple arguments to the Action.

	@method AddArguments
	@param arguments {
		[string]: {
			Type: ("string" | "number" | "boolean")?,
			Description: string?,
			Required: boolean?,
			Default: any,
		}
	}
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Prototype.AddArguments(self: ActionBuilder, arguments: {
	[string]: {
		Type: ("string" | "number" | "boolean")?,
		Description: string?,
		Required: boolean?,
		Default: any,
	}
}): ActionBuilder
	for argumentName, argument in arguments do
		self:AddArgument(argumentName, {
			Type = argument.Type,
			Description = argument.Description,
			Required = argument.Required,
			Default = argument.Default
		})
	end

	return self
end

--[=[
	Build is used to build the Action.

	@method Build
	@within ActionBuilder
	@return Action
]=]
function ActionBuilder.Prototype.Build(self: ActionBuilder): Action
	assert(self.Prototype.Name ~= nil, "Actions are required to have a 'Name', please call ':SetName'")
	assert(Action.Instantiated[self.Prototype.Key] == nil, `Action '{self.Prototype.Name}' is a duplicate action!`)

	Action.Instantiated[self.Prototype.Key] = setmetatable(
		Sift.Dictionary.copyDeep(self.Prototype) :: { },
		{
			__index = Action.Prototype
		}
	) :: Action

	task.defer(function()
		ActionService:RegisterActionAsync(Action.Instantiated[self.Prototype.Key]):expect()
	end)

	return Action.Instantiated[self.Prototype.Key]
end

--[=[
	Creates a new ActionBuilder.

	@function new
	@within ActionBuilder
	@return ActionBuilder
]=]
function ActionBuilder.Public.new(): ActionBuilder
	return setmetatable({
		Prototype = {
			Arguments = { },
			ArgumentOrderedList = { }
		}
	}, {
		__index = ActionBuilder.Prototype
	}) :: ActionBuilder
end

export type ArgumentMetadata = typeof(Action.Prototype) & {
	Type: ("string" | "number" | "boolean")?,
	Description: string?,
	Required: boolean?,
	IsArray: boolean?,
	Default: any,
}

export type Action = typeof(Action.Prototype) & {
	Key: string,
	Name: string,
}

export type ActionBuilder = typeof(ActionBuilder.Prototype) & {
	Prototype: { [unknown]: unknown }
}

return ActionBuilder.Public
