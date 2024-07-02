local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK:InitializeAsync({
	projectId = ServerStorage.__Project_Id.Value,
	authenticationSecret = RunService:IsStudio() and ServerStorage.__Project_Auth.Value
		or HttpService:GetSecret("metrik_token")
}):andThen(function()
	warn("Metrik SDK loaded!")
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)