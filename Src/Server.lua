--[[
	Metrik SDK - https://github.com/metrik-tech/sdk
]]

local HttpService = game:GetService("HttpService")

local Runtime = require(script.Parent.Packages.Runtime)
local Promise = require(script.Parent.Packages.Promise)
local Console = require(script.Parent.Packages.Console)

local Error = require(script.Parent.Enums.Error)

local ErrorFormats = require(script.Parent.Data.ErrorFormats)
local ApiPaths = require(script.Parent.Data.ApiPaths)

local ActionBuilder = require(script.Parent.API.ActionBuilder)

local ApiService = require(script.Parent.Services.ApiService)
local BreadcrumbService = require(script.Parent.Services.BreadcrumbService)
local ContextService = require(script.Parent.Services.ContextService)
local FlagsService = require(script.Parent.Services.FlagsService)

local ON_INIT_LIFECYCLE_NAME = "OnInit"
local ON_START_LIFECYCLE_NAME = "OnStart"

--[=[
	@class MetrikSDK.Server

	The base class developers will be interacting with. *(TO-DO: add a descriptive class description!)*
]=]
local MetrikSDK = {}

MetrikSDK.Public = {}
MetrikSDK.Private = {}

MetrikSDK.Public.Private = MetrikSDK.Private
MetrikSDK.Private.Public = MetrikSDK.Public

MetrikSDK.Private.Reporter = Console.new("MetrikSDK-Server")
MetrikSDK.Private.IsInitialized = false
MetrikSDK.Private.ProjectId = ""

--[=[
	@prop ActionBuilder ActionBuilder
	@within MetrikSDK.Server
]=]
--
MetrikSDK.Public.ActionBuilder = ActionBuilder

function MetrikSDK.Private.FromError(_: MetrikPrivateAPI, errorEnum: string, ...: string)
	return string.format(ErrorFormats[errorEnum], ...)
end

--[=[
	...

	@method CreateBreadcrumb
	@within MetrikSDK.Server

	@return ()
]=]
--
function MetrikSDK.Public.CreateBreadcrumb(self: MetrikPublicAPI, message: string)
	BreadcrumbService:CreateBreadcrumbFor(debug.info(2, "s"), message)
end

--[=[
	...

	@method SetContext
	@within MetrikSDK.Server

	@return ()
]=]
--
function MetrikSDK.Public.SetContext(self: MetrikPublicAPI, context: { [string]: any })
	ContextService:CreateContextFor(debug.info(2, "s"), context)
end

--[=[
	@method IsServerUpToDate
	@within MetrikSDK.Server

	@return ()
]=]
--
function MetrikSDK.Public.IsServerUpToDate(self: MetrikPublicAPI)
	local success, response = ApiService:GetAsync(string.format(ApiPaths.GetLatestPlaceVersion, ApiService.ProjectId), { }):await()

	if not success or not response.Success then
		-- fail gracefully
		
		return true
	end
	
	local body = HttpService:JSONDecode(response.Body)

	return body.latest == game.PlaceVersion
end

--[=[
	...

	@method EvaluateFlag
	@within MetrikSDK.Server

	@return ()
]=]
--
function MetrikSDK.Public.GetFlag(self: MetrikPublicAPI, flagName: string)
	return FlagsService:EvaluateFlag(flagName)
end

--[=[
	Start the Metrik SDK, once this function has been called, internal Metrik Services and Controllers should come online and start to respond and
		handle Metrik backend calls made to the current Roblox server.

	:::warning
		Please ensure that any pre-init variables are set before calling this function, otherwise Metrik will have issues attempting to authenticate
		the current SDK!
	:::

	@method InitializeAsync
	@param settings { projectId: string, authenticationSecret: Secret }
	@within MetrikSDK.Server

	@return Promise<()>
]=]
--
function MetrikSDK.Public.InitializeAsync(self: MetrikPublicAPI, settings: {
	projectId: string,
	authenticationSecret: Secret
})
	return Promise.new(function(resolve, reject)
		ApiService:SetProjectId(settings.projectId)
		ApiService:SetAuthenticationSecret(settings.authenticationSecret)

		if self.Private.IsInitialized then
			return reject(self.Private:FromError(Error.AlreadyInitializedError))
		end

		local runtimeClockSnapshot = os.clock()
		local metrikServices = Runtime:RequireChildren(
			script.Parent.Services,
			function(module: ModuleScript, moduleContent: { [any]: any })
				self.Private.Reporter:Debug(`Loading MetrikSDK Service module: '{module.Name}'`)

				return moduleContent
			end
		)

		table.sort(metrikServices, function(serviceA, serviceB)
			return (serviceA.Priority or 0) > (serviceB.Priority or 0)
		end)

		local success, response = pcall(function()
			Runtime:CallMethodOn(metrikServices, ON_INIT_LIFECYCLE_NAME)
			Runtime:CallMethodOn(metrikServices, ON_START_LIFECYCLE_NAME)
		end)

		if not success then
			return reject(response)
		end

		self.Private.IsInitialized = true

		self.Private.Reporter:Debug(`Loaded all MetrikSDK Services ({os.clock() - runtimeClockSnapshot}ms)`)

		return resolve()
	end)
end

type MetrikPublicAPI = typeof(MetrikSDK.Public)
type MetrikPrivateAPI = typeof(MetrikSDK.Private)

export type MetrikSDK = MetrikPublicAPI & { Private: nil }

return MetrikSDK.Public
