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

local GetScriptFromFullName = require(script.Parent.Util.GetScriptFromFullName)

local ActionBuilder = require(script.Parent.API.ActionBuilder)

local ApiService = require(script.Parent.Services.ApiService)
local BreadcrumbService = require(script.Parent.Services.BreadcrumbService)
local ContextService = require(script.Parent.Services.ContextService)
local FlagsService = require(script.Parent.Services.FlagsService)

local ON_INIT_LIFECYCLE_NAME = "OnInit"
local ON_START_LIFECYCLE_NAME = "OnStart"

--[=[
	@class MetrikSDK.Server

	The MetrikSDK.Server class is the main entry point for interacting with the Metrik Service on the Server.
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

--[=[
	@prop ActionBuilder ActionBuilder
	@within MetrikSDK.Server
]=]

MetrikSDK.Public.ActionBuilder = ActionBuilder

function MetrikSDK.Private.FromError(_: MetrikPrivateAPI, errorEnum: string, ...: string)
	return string.format(ErrorFormats[errorEnum], ...)
end

function MetrikSDK.Private.GetCallingScript(_: MetrikPrivateAPI)
	local level = 3
	
	while true do
		local source = debug.info(level, "s")

		if not source then
			return nil
		end

		local instance = GetScriptFromFullName(source)

		if not instance then
			return nil
		end

		if instance:IsDescendantOf(script.Parent) or instance == script.Parent then
			level += 1
		else
			return source
		end
	end
end

--[=[
	Defer to @MetrikSDK.CreateBreadcrumb

	@method CreateBreadcrumb
	@param message string
	@within MetrikSDK.Server

	@return ()
]=]
function MetrikSDK.Public.CreateBreadcrumb(self: MetrikPublicAPI, message: string)
	BreadcrumbService:CreateBreadcrumbFor(nil, self.Private:GetCallingScript(), message)
end

--[=[
	Defer to @MetrikSDK.SetContext

	@method SetContext
	@param context { [string]: any }
	@within MetrikSDK.Server

	@return ()
]=]
function MetrikSDK.Public.SetContext(self: MetrikPublicAPI, context: { [string]: any })
	ContextService:CreateContextFor(nil, self.Private:GetCallingScript(), context)
end

--[=[
	Defer to @MetrikSDK.IsServerUpToDate

	@method IsServerUpToDate
	@within MetrikSDK.Server

	@return boolean
]=]
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
	Defer to @MetrikSDK.GetFlag

	@method GetFlag
	@param flagName string
	@within MetrikSDK.Server

	@return boolean
]=]
function MetrikSDK.Public.GetFlag(self: MetrikPublicAPI, flagName: string)
	return FlagsService:EvaluateFlag(flagName)
end

--[=[
	Defer to @MetrikSDK.InitializeAsync

	@method InitializeAsync
	@param settings { projectId: string, authenticationSecret: Secret }
	@within MetrikSDK.Client

	@return Promise<()>
]=]
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

		script.Parent:SetAttribute("INIT_COMPLETE", true)

		self.Private.IsInitialized = true

		self.Private.Reporter:Debug(`Loaded all MetrikSDK Services ({os.clock() - runtimeClockSnapshot}ms)`)

		return resolve()
	end)
end

type MetrikPublicAPI = typeof(MetrikSDK.Public)
type MetrikPrivateAPI = typeof(MetrikSDK.Private)

export type MetrikSDK = MetrikPublicAPI & { Private: nil }

return MetrikSDK.Public
