local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:SetProjectId(ServerStorage.__Project_Id.Value)
MetrikSDK.Server:SetAuthenticationToken(ServerStorage.__Project_Auth.Value)

MetrikSDK.Server:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")

	local action = MetrikSDK.Server.ActionBuilder.new()
		:SetName("Hello World")
		:SetDescription("Prints 'Hello, World' with an option for another message")
		:AddArgument("Message", {
			Required = true,
			Type = "string",
		})
		:Build()

	function action:OnRun(message: string)
		print("Hello, World")

		print(message)
	end
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)