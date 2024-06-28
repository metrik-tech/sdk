local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:SetProjectId(ServerStorage.__Project_Id.Value)
MetrikSDK.Server:SetAuthenticationToken(ServerStorage.__Project_Auth.Value)

MetrikSDK.Server:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")

	print(MetrikSDK.Server:GetFlag("example-dynamic-flag"))
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)