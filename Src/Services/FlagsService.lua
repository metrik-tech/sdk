--[[
	
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local ApiPaths = require(script.Parent.Parent.Data.ApiPaths)

local RuleOperator = require(script.Parent.Parent.Enums.RuleOperator)
local RuleType = require(script.Parent.Parent.Enums.RuleType)
local RuleBehaviour = require(script.Parent.Parent.Enums.RuleBehaviour)

local ApiService = require(script.Parent.ApiService)

local Network = require(script.Parent.Parent.Network.Server)

local MessageReceiveService = require(script.Parent.MessageReceiveService)

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

		table.insert(self.DynamicFlags, {
			Id = flagObject.id,
			Name = flagObject.name,
			Value = flagObject.value,
			Behaviour = flagObject.ruleBehaviour,
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
	-- parameter isn't used on the Server.
	-- local parameter = ruleObject.param

	local type = ruleObject.type
	local operator = ruleObject.operator
	local operand = ruleObject.operand

	local dynamicObject

	if type == RuleType.PlayerCount then
		dynamicObject = #Players:GetPlayers()
	elseif type == RuleType.PlayerList then
		dynamicObject = Players:GetPlayers()
	elseif type == RuleType.Region then
		dynamicObject = ApiService.Trace.loc
	elseif type == RuleType.PlaceVersion then
		dynamicObject = game.PlaceVersion
	elseif type == RuleType.ServerType then
		dynamicObject = ApiService.ServerType
	elseif type == RuleType.PlayerNotInGroup then
		self.Reporter:Warn(`Attempted to fetch dynamic flag with invalid context, type '{type}' is only avaliable on the client.`)

		return false
	elseif type == RuleType.PlayerInGroup then
		self.Reporter:Warn(`Attempted to fetch dynamic flag with invalid context, type '{type}' is only avaliable on the client.`)

		return false
	elseif type == RuleType.PlayerRankInGroup then
		self.Reporter:Warn(`Attempted to fetch dynamic flag with invalid context, type '{type}' is only avaliable on the client.`)

		return false
	elseif type == RuleType.PlayerRoleInGroup then
		self.Reporter:Warn(`Attempted to fetch dynamic flag with invalid context, type '{type}' is only avaliable on the client.`)

		return false
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

function FlagsService.EvaluateDynamicFlag(self: FlagsService, flagName: string)
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

	MessageReceiveService.OnFlags:Connect(function(message: ActionPacket)
		print(message)
	end)
end

export type FlagsService = typeof(FlagsService)
export type ActionPacket = {
	id: string,
	name: string,
	value: any,
	type: string
}

return FlagsService