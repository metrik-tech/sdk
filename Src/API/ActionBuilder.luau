local Sift = require(script.Parent.Parent.Packages.Sift)

local ActionService = require(script.Parent.Parent.Services.ActionService)

--[[
	Metrik SDK ActionBuilder & Action
]]

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

function Action.Prototype:CanRun(...: unknown) -- todo: figure out how the 'middleware' impl is going to look.
	return true
end

function Action.Prototype:OnRun(...: unknown)
	print(`Method ':OnRun' has been called on Action<"{self.Name}">`)
end

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

function ActionBuilder.Prototype.SetDescription(self: ActionBuilder, description: string): ActionBuilder
	assert(string.len(description) <= 500, "Action Description must be under 500 characters!")
	
	self.Prototype.Description = description

	return self
end

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
		Default = argumentMetadata and argumentMetadata.Default or ""
	}

	table.insert(self.Prototype.ArgumentOrderedList, filteredArgumentName)

	return self
end

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
