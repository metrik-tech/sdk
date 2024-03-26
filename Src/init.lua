local RunService = game:GetService("RunService")

local MetrikSDK = {}

if RunService:IsRunMode() then
	MetrikSDK.Disabled = true
else
	MetrikSDK.Client = RunService:IsClient() and require(script.Client)
	MetrikSDK.Server = RunService:IsServer() and require(script.Server)
end

return MetrikSDK