local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

<<<<<<< HEAD
local ProblematicModule = require(script.Parent.ProblematicModule)

MetrikSDK.Server:SetProjectId(ServerStorage.__Project_Id.Value)
MetrikSDK.Server:SetAuthenticationToken(ServerStorage.__Project_Auth.Value)

MetrikSDK.Server:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")

	task.spawn(function()
		ProblematicModule.abc()
	end)
=======
MetrikSDK.Server:InitializeAsync({
	projectId = ServerStorage.__Project_Id.Value,
	authenticationSecret = RunService:IsStudio() and ServerStorage.__Project_Auth.Value
		or HttpService:GetSecret("metrik_token")
}):andThen(function()
	warn("Metrik SDK loaded!")

	print(MetrikSDK.Server:GetFlag("example-dynamic-flag"))
>>>>>>> 937388f1faac82959267026529124e2da5c7badc
end):catch(function(exception)
	warn("Metrik SDK failed: ", exception)
end)