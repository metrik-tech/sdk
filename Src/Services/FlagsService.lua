--[[
	
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local FlagOperator = require(script.Parent.Parent.Enums.FlagOperator)
local FlagOperand = require(script.Parent.Parent.Enums.FlagOperand)

local ApiService = require(script.Parent.ApiService)

local Network = require(script.Parent.Parent.Network.Server)

local FlagsService = {}

FlagsService.Priority = -1
FlagsService.Reporter = Console.new(`{script.Name}`)

FlagsService.DynamicFlags = {}
FlagsService.StaticFlags = {}

FlagsService.FlagsLoaded = false

function FlagsService._PollExistingFlags(self: FlagsService)
	local success, result = ApiService:GetAsync(string.format(ApiPaths.GetAllFlags, ApiService.ProjectId), { }):await()

	if not success then
		self.Reporter:Critical(`Failed to poll dynamic/static flags: {result}`)
	end
	
	local body = HttpService:JSONDecode(result.Body)

	for _, flagObject in body.dynamic do
		local rules = {}

		for _, ruleObject in flagObject.rules do
			table.insert(rules, {
				Type = ruleObject.type,
				Parameter = ruleObject.param,
				Operator = ruleObject.operator,
				Operand = ruleObject.operand,
				Value = ruleObject.value
			})
		end

		table.insert(self.StaticFlags, {
			Id = flagObject.id,
			Name = flagObject.name,
			Value = flagObject.value,
			Rules = rules,
		})
	end

	for _, flagObject in body.static do
		table.insert(self.StaticFlags, {
			Id = flagObject.id,
			Name = flagObject.name,
			Value = flagObject.value
		})
	end

	self.FlagsLoaded = true
end

function FlagsService.EvaluateFlagRule(self: FlagsService, ruleObject)
	local _type = ruleObject.type -- todo: what is this?
	local _parameter = ruleObject.param

	local value = ruleObject.value
	local operator = ruleObject.operator
	local operand = ruleObject.operand

	local dynamicObject

	if operand == FlagOperand.PlayerCount then
		dynamicObject = #Players:GetPlayers()
	elseif operand == FlagOperand.PlayerList then
		dynamicObject = Players:GetPlayers()
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

function FlagsService.EvaluateDynamicFlag(self: FlagsService, flagName: string)
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

function FlagsService.EvaluateFlag(self: FlagsService, flagName: string)
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

function FlagsService.OnStart(self: FlagsService)
	self:_PollExistingFlags()

	Network.FetchFlagsAsync.SetCallback(function()
		local payload = {}

		payload.DynamicFlags = {}
		payload.StaticFlags = {}

		for _, flagObject in FlagsService.DynamicFlags do
			local rules = {}

			for _, ruleObject in flagObject.Rules do
				table.insert(rules, {
					Type = ruleObject.Type,
					Operator = ruleObject.Operator,
					Operand = ruleObject.Operand,
					Parameter = HttpService:JSONEncode({ ruleObject.Parameter }),
					Value = HttpService:JSONEncode({ ruleObject.Value }),
				})
			end

			table.insert(payload.DynamicFlags, {
				Id = flagObject.Id,
				Name = flagObject.Name,
				Value = HttpService:JSONEncode({ flagObject.Value }),
				Rules = rules
			})
		end

		for _, flagObject in FlagsService.StaticFlags do
			table.insert(payload.StaticFlags, {
				Id = flagObject.Id,
				Name = flagObject.Name,
				Value = HttpService:JSONEncode({ flagObject.Value })
			})
		end

		return payload
	end)
end

export type FlagsService = typeof(FlagsService)
export type ActionPacket = {
	id: string,
	message: string,
	type: string
}

return FlagsService
