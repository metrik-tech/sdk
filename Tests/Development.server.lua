local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:InitializeAsync({
	projectId = ServerStorage.__Project_Id.Value,
	authenticationSecret = RunService:IsStudio() and ServerStorage.__Project_Auth.Value
		or HttpService:GetSecret("metrik_token")
}):andThen(function()
	warn("Metrik SDK loaded!")

	print(MetrikSDK.Server:GetFlag("example-dynamic-flag"))
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)