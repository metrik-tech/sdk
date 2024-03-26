local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:SetAuthenticationToken(ServerStorage.__Secret_Key.Value)
MetrikSDK.Server:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")
end)
