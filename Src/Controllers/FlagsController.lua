local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local Network = require(script.Parent.Parent.Network.Client)

local FlagOperator = require(script.Parent.Parent.Enums.FlagOperator)
local FlagOperand = require(script.Parent.Parent.Enums.FlagOperand)

local FlagsController = { }

FlagsController.Priority = 0
FlagsController.Reporter = Console.new(`{script.Name}`)

FlagsController.DynamicFlags = {}
FlagsController.StaticFlags = {}

FlagsController.FlagsLoaded = true

function FlagsController.OnStart(self: FlagsController)
	local serverFlags = Network.FetchFlagsAsync.Call()

	for _, flagObject in serverFlags.DynamicFlags do
		local rules = {}

		for _, ruleObject in flagObject.Rules do
			table.insert(rules, {
				Type = ruleObject.Type,
				Operator = ruleObject.Operator,
				Operand = ruleObject.Operand,
				Parameter = HttpService:JSONDecode(ruleObject.Parameter)[1],
				Value = HttpService:JSONDecode(ruleObject.Value)[1],
			})
		end

		table.insert(self.DynamicFlags, {
			Id = flagObject.Id,
			Name = flagObject.Name,
			Value = HttpService:JSONDecode(flagObject.Value)[1],
			Rules = rules
		})
	end

	for _, flagObject in serverFlags.StaticFlags do
		table.insert(self.DynamicFlags, {
			Id = flagObject.Id,
			Name = flagObject.Name,
			Value = HttpService:JSONDecode(flagObject.Value)[1],
		})
	end

	self.FlagsLoaded = true
end

function FlagsController.EvaluateFlagRule(self: FlagsController, ruleObject)
	local _type = ruleObject.type -- todo: what is this?

	local parameter = ruleObject.param

	local value = ruleObject.value
	local operator = ruleObject.operator
	local operand = ruleObject.operand

	local dynamicObject

	if operand == FlagOperand.PlayerCount then
		dynamicObject = #Players:GetPlayers()
	elseif operand == FlagOperand.PlayerList then
		dynamicObject = Players:GetPlayers()
	elseif operand == FlagOperand.PlayerRankInGroup then
		dynamicObject = Players.LocalPlayer:GetRankInGroup(parameter)
	elseif operand == FlagOperand.PlayerRoleInGroup then
		dynamicObject = Players.LocalPlayer:GetRoleInGroup(parameter)
	end

	if operator == FlagOperator.Equals then
		return dynamicObject == value
	elseif operator == FlagOperator.Contains then
		if Sift.Array.is(dynamicObject) then
			return table.find(dynamicObject, value) ~= nil
		else
			return dynamicObject[value] ~= nil
		end
	elseif operator == FlagOperator.GreaterThan then
		return value > dynamicObject
	elseif operator == FlagOperator.GreaterThanOrEquals then
		return value >= dynamicObject
	elseif operator == FlagOperator.LessThan then
		return value < dynamicObject
	elseif operator == FlagOperator.LessThanOrEquals then
		return value <= dynamicObject
	elseif operator == FlagOperator.NotContains then
		if Sift.Array.is(dynamicObject) then
			return table.find(dynamicObject, value) == nil
		else
			return dynamicObject[value] == nil
		end
	elseif operator == FlagOperator.NotEquals then
		return dynamicObject ~= value
	else
		self.Reporter:Error(`Unknown rule operator: '{operator}'`)

		return false
	end
end

function FlagsController.EvaluateDynamicFlag(self: FlagsController, flagName: string)
	local index = Sift.Array.findWhere(self.DynamicFlags, function(object)
		return object.Name == flagName or object.Id == flagName
	end)

	local flagObject = self.DynamicFlags[index]

	if flagObject then
		local flagEnabled = true

		for _, ruleObject in flagObject.Rules do
			if not self:EvaluateFlagRule(ruleObject) then
				flagEnabled = false
				
				break
			end
		end

		return flagEnabled and flagObject.Value or nil
	else
		self.Reporter:Warn(`Failed to query flag '{flagName}' - returning 'nil'!`)

		return nil
	end
end

function FlagsController.EvaluateFlag(self: FlagsController, flagName: string)
	while not self.FlagsLoaded do
		task.wait()
	end

	local index = Sift.Array.findWhere(self.StaticFlags, function(object)
		return object.Name == flagName or object.Id == flagName
	end)

	local flagObject = self.StaticFlags[index]

	if flagObject then
		return flagObject.Value
	else
		return self:EvaluateDynamicFlag(flagName)
	end
end

export type FlagsController = typeof(FlagsController)

return FlagsController