local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:SetProjectId(ServerStorage.__Project_Id.Value)
MetrikSDK.Server:SetAuthenticationToken(ServerStorage.__Project_Auth.Value)

MetrikSDK.Server:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")
	
	local action = MetrikSDK.Server.ActionBuilder.new()
		:SetName("Hello, world!")
		:SetDescription("A simple 'Hello, World' print!")
		:AddArgument("String", {
			Type = "string",
			Required = false,
			Description = "Anything else you want to print?"
		})
		:Build()

	function action:OnRun(source: string?)
		print("Hello, World!")

		if source then
			print(source)
		end
	end
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)