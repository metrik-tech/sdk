local RunService = game:GetService("RunService")

--[=[
	@class MetrikSDK

	The MetrikSDK class is the main entry point for interacting with the Metrik backend.
]=]
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

function MetrikSDK.InitializeAsync(self: MetrikSDK, settings: {
	projectId: string,
	authenticationSecret: Secret
}?)
	if MetrikSDK.Server then
		return MetrikSDK.Server:InitializeAsync(settings)
	else
		return MetrikSDK.Client:InitializeAsync()
	end
end

function MetrikSDK.GetFlag(self: MetrikSDK, flagName: string)
	if MetrikSDK.Server then
		return MetrikSDK.Server:GetFlag(flagName)
	else
		return MetrikSDK.Client:GetFlag(flagName)
	end
end

function MetrikSDK.IsServerUpToDate(self: MetrikSDK)
	if MetrikSDK.Server then
		return MetrikSDK.Server:IsServerUpToDate()
	else
		error(`MetrikSDK.IsServerUpToDate() is not available on the client.`)
	end
end

function MetrikSDK.CreateBreadcrumb(self: MetrikSDK, message: string)
	if MetrikSDK.Server then
		return MetrikSDK.Server:CreateBreadcrumb(message)
	else
		return MetrikSDK.Client:CreateBreadcrumb(message)
	end
end

function MetrikSDK.SetContext(self: MetrikSDK, context: { [string]: any })
	if MetrikSDK.Server then
		return MetrikSDK.Server:SetContext(context)
	else
		return MetrikSDK.Client:SetContext(context)
	end
end

export type MetrikSDK = typeof(MetrikSDK)

return MetrikSDK