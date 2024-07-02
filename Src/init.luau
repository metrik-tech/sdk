local RunService = game:GetService("RunService")

--[=[
	@class MetrikSDK

	The MetrikSDK class is the main entry point for interacting with the Metrik backend.

	```lua
	local MetrikSDK = require(script.Parent.MetrikSDK)

	MetrikSDK:InitializeAsync({
		projectId = "<PROJECT_ID>",
		authenticationSecret = HttpService:GetSecret("metrik_token")
	}):andThen(function()
		warn("Metrik SDK loaded!")
	end):catch(function(exception)
		warn("Metrik SDK failed: ", exception)
	end)
	```
]=]

--[=[
	@prop Disabled boolean
	@within MetrikSDK
]=]

--[=[
	@prop Client MetrikSDK.Client
	@within MetrikSDK
	@client
]=]

--[=[
	@prop Server MetrikSDK.Server
	@within MetrikSDK
	@server
]=]

--[=[
	@prop ActionBuilder ActionBuilder
	@within MetrikSDK
	@server
]=]

local MetrikSDK = {}

if not RunService:IsRunning() then
	MetrikSDK.Disabled = true
else
	if RunService:IsClient() then
		MetrikSDK.Client = require(script.Client)
	else
		MetrikSDK.Server = require(script.Server)
		MetrikSDK.ActionBuilder = MetrikSDK.Server.ActionBuilder
	end
end

--[=[
	Initialize the Metrik SDK, once this function has been called, internal Metrik Services and Controllers should come online and start to respond and handle Metrik backend calls made for the current Roblox server.

	@method InitializeAsync
	@param settings { projectId: string, authenticationSecret: Secret }
	@return Promise<()>
	@within MetrikSDK
]=]
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

--[=[
	Get the current flag value for the given flag name, flags are set via the Metrik dashboard.

	@method GetFlag
	@param flagName string
	@return boolean
	@within MetrikSDK
]=]
function MetrikSDK.GetFlag(self: MetrikSDK, flagName: string)
	if MetrikSDK.Server then
		return MetrikSDK.Server:GetFlag(flagName)
	else
		return MetrikSDK.Client:GetFlag(flagName)
	end
end

--[=[
	Validate that the current Roblox server is up to date with the Roblox server running the Metrik SDK.

	@method IsServerUpToDate
	@return boolean
	@within MetrikSDK

	@server
]=]
function MetrikSDK.IsServerUpToDate(self: MetrikSDK)
	if MetrikSDK.Server then
		return MetrikSDK.Server:IsServerUpToDate()
	else
		error(`MetrikSDK.IsServerUpToDate() is not available on the client.`)
	end
end

--[=[
	Create a breadcrumb with the given message. Breadcrumbs are used to track events that lead up to an error.

	@method CreateBreadcrumb
	@param message string
	@within MetrikSDK
]=]
function MetrikSDK.CreateBreadcrumb(self: MetrikSDK, message: string)
	if MetrikSDK.Server then
		return MetrikSDK.Server:CreateBreadcrumb(message)
	else
		return MetrikSDK.Client:CreateBreadcrumb(message)
	end
end

--[=[
	Set the context of the current script to the given context. Context is a table that will be sent to the Metrik backend if an error occurs in that script.

	@method SetContext
	@param context { [string]: any }
	@within MetrikSDK
]=]
function MetrikSDK.SetContext(self: MetrikSDK, context: { [string]: any })
	if MetrikSDK.Server then
		return MetrikSDK.Server:SetContext(context)
	else
		return MetrikSDK.Client:SetContext(context)
	end
end

export type MetrikSDK = typeof(MetrikSDK)

return MetrikSDK