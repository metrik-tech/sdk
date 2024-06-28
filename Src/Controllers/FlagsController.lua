local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local Network = require(script.Parent.Parent.Network.Client)

local RuleOperator = require(script.Parent.Parent.Enums.RuleOperator)
local RuleType = require(script.Parent.Parent.Enums.RuleType)
local ServerType = require(script.Parent.Parent.Enums.ServerType)
local RuleBehaviour = require(script.Parent.Parent.Enums.RuleBehaviour)

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
	local parameter = ruleObject.param
	
	local type = ruleObject.type
	local operator = ruleObject.operator
	local operand = ruleObject.operand

	local dynamicObject

	if type == RuleType.PlayerCount then
		dynamicObject = #Players:GetPlayers()
	elseif type == RuleType.PlayerList then
		dynamicObject = Players:GetPlayers()
	elseif type == RuleType.Region then
		self.Reporter:Warn(`Attempted to fetch dynamic flag with invalid context, operand '{operand}' is only avaliable on the server.`)

		return false
	elseif type == RuleType.PlaceVersion then
		dynamicObject = game.PlaceVersion
	elseif type == RuleType.ServerType then
		dynamicObject = ServerType.Public

		if RunService:IsStudio() then
			dynamicObject = ServerType.Reserved
		elseif game.VIPServerOwnerId ~= 0 then
			dynamicObject = ServerType.Private
		elseif game.VIPServerId ~= "" then
			dynamicObject = ServerType.Reserved
		end
	elseif type == RuleType.PlayerNotInGroup then
		dynamicObject = not Players.LocalPlayer:IsInGroup(parameter)
	elseif type == RuleType.PlayerInGroup then
		dynamicObject = Players.LocalPlayer:IsInGroup(parameter)
	elseif type == RuleType.PlayerRankInGroup then
		dynamicObject = Players.LocalPlayer:GetRankInGroup(parameter)
	elseif type == RuleType.PlayerRoleInGroup then
		dynamicObject = Players.LocalPlayer:GetRoleInGroup(parameter)
	end

	if operator == RuleOperator.Equals then
		return dynamicObject == operand
	elseif operator == RuleOperator.Contains then
		if Sift.Array.is(dynamicObject) then
			return table.find(dynamicObject, operand) ~= nil
		else
			return dynamicObject[operand] ~= nil
		end
	elseif operator == RuleOperator.GreaterThan then
		return operand > dynamicObject
	elseif operator == RuleOperator.GreaterThanOrEquals then
		return operand >= dynamicObject
	elseif operator == RuleOperator.LessThan then
		return operand < dynamicObject
	elseif operator == RuleOperator.LessThanOrEquals then
		return operand <= dynamicObject
	elseif operator == RuleOperator.NotContains then
		if Sift.Array.is(dynamicObject) then
			return table.find(dynamicObject, operand) == nil
		else
			return dynamicObject[operand] == nil
		end
	elseif operator == RuleOperator.NotEquals then
		return dynamicObject ~= operand
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
		local flagStatuses = {}

		for _, ruleObject in flagObject.Rules do
			table.insert(flagStatuses, self:EvaluateFlagRule(ruleObject))
		end

		if flagObject.Behaviour == RuleBehaviour.All then
			for _, status in flagStatuses do
				if not status then
					flagEnabled = false
					
					break
				end
			end
		elseif flagObject.Behaviour == RuleBehaviour.Some then
			local hasFlagEnabled

			for _, status in flagStatuses do
				if status then
					hasFlagEnabled = true
				end
			end

			if not hasFlagEnabled then
				flagEnabled = false
			end
		elseif flagObject.Behaviour == RuleBehaviour.None then
			for _, status in flagStatuses do
				if status then
					flagEnabled = false
					
					break
				end
			end
		end

		return flagEnabled and flagObject.Value or false
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