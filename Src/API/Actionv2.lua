--[[
	Metrik SDK Action.
]]

local HttpService = game:GetService("HttpService")

local Signal = require(script.Parent.Parent.Packages.Signal)

local ActionType = require(script.Parent.Parent.Enums.ActionType)

--[=[
	@class Action

	Actions enable developers to interact with the Metrik backend, when an action is instantiated the backend is notified so that servers
		that have this action is callable from the Metrik site.
]=]
local Action = {}

Action.Public = {}
Action.Prototype = {}
Action.Builder = {}
Action.Instantiated = {}

Action.Public.ActionAdded = Signal.new()

---------------------------------------------------------

function Action.Builder.AddArgument(self: ActionBuilder, argumentName: string, argumentOptionals: { }?)
	local arguments = argumentOptionals or {}

	if not arguments.Type then
		arguments.Type = "string"
	end

	if not arguments.Required then
		arguments.Required = false
	end

	if not arguments.Required then
		arguments.Required = false
	end

	if not arguments.Description then
		arguments.Description = ""
	end
	
	table.insert(self.BuilderConfig.Arguments, {
		name = argumentName,
		optionals = argumentOptionals
	})
end

function Action.Builder.Build(self: ActionBuilder)
	local actionObject = setmetatable({}, {
		__index = Action.Prototype
	})

	actionObject.Name = self.Name
	actionObject.Uuid = self.Uuid

	actionObject.Arguments = self.BuilderConfig.Arguments

	Action.Instantiated[self.Name] = actionObject

	Action.Public.ActionAdded:Fire(actionObject)

	self.Object = actionObject

	return self.Object
end

---------------------------------------------------------

function Action.Public.new(actionName: string)
	local self = setmetatable({}, {
		__index = Action.Builder,
	})

	self.Name = actionName
	self.Uuid = HttpService:UrlEncode(actionName)
	self.Object = nil

	self.BuilderConfig = {}
	self.BuilderConfig.Arguments = {}

	return self
end

export type ActionBuilder = typeof(Action.Public.new("__typechecker"))

return Action.Public
