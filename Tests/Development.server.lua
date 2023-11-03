local ServerStorage = game:GetService("ServerStorage")

local MetrikSDK = require(ServerStorage.MetrikSDK)

MetrikSDK:InitializeAsync():andThen(function()
	print("Metrik SDK loaded!")
end)