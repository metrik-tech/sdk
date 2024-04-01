local RunService = game:GetService("RunService")

local MetrikSDK = {}

if not RunService:IsRunning() then
	MetrikSDK.Disabled = true
else
	if RunService:IsClient() then
		MetrikSDK.Client = require(script.Client)
	else
		MetrikSDK.Server = require(script.Server)
	end
end

return MetrikSDK