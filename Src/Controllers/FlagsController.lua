local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)
local Sift = require(script.Parent.Parent.Packages.Sift)

local Network = require(script.Parent.Parent.Network.Client)

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

function FlagsController.EvaluateDynamicFlag(self: FlagsController, flagName: string)
	local index = Sift.Array.findWhere(self.StaticFlags, function(object)
		return object.Name == flagName or object.Id == flagName
	end)

	local flagObject = self.StaticFlags[index]

	if flagObject then
		

		return 0 -- todo: add dynamic flag support
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