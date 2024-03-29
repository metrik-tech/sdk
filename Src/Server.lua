--[[
	Metrik SDK - https://github.com/metrik-tech/sdk
]]

local Runtime = require(script.Parent.Packages.Runtime)
local Promise = require(script.Parent.Packages.Promise)
local Console = require(script.Parent.Packages.Console)

local Error = require(script.Parent.Enums.Error)

local ErrorFormats = require(script.Parent.Data.ErrorFormats)

local Action = require(script.Parent.API.Action)

local ApiService = require(script.Parent.Services.ApiService)

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
	@prop Action Action
	@within MetrikSDK.Server
]=]
--
MetrikSDK.Public.Action = Action

function MetrikSDK.Private.FromError(_: MetrikPrivateAPI, errorEnum: string, ...: string)
	return string.format(ErrorFormats[errorEnum], ...)
end

--[=[
	...

	@method SetAuthenticationToken
	@within MetrikSDK.Server

	@return ()
]=]
--
function MetrikSDK.Public.SetAuthenticationToken(self: MetrikPublicAPI, projectId: string)
	self.Private.Reporter:Assert(
		not self.Private.IsInitialized,
		self.Private:FromError(Error.ExpectedCallAfterCall, "Metrik:SetAuthenticationToken", "Metrik:InitializeAsync")
	)

	ApiService:SetAuthenticationToken(projectId)
	ApiService:SetProjectId(projectId)
end

--[=[
	Start the Metrik SDK, once this function has been called, internal Metrik Services and Controllers should come online and start to respond and
		handle Metrik backend calls made to the current Roblox server.

	:::warning
		Please ensure that any pre-init variables are set before calling this function, otherwise Metrik will have issues attempting to authenticate
		the current SDK!
	:::

	@method InitializeAsync
	@within MetrikSDK.Server

	@return Promise<()>
]=]
--
function MetrikSDK.Public.InitializeAsync(self: MetrikPublicAPI)
	return Promise.new(function(resolve, reject)
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

		Runtime:CallMethodOn(metrikServices, ON_INIT_LIFECYCLE_NAME)
		Runtime:CallMethodOn(metrikServices, ON_START_LIFECYCLE_NAME)

		self.Private.IsInitialized = true

		self.Private.Reporter:Debug(`Loaded all MetrikSDK Services ({os.clock() - runtimeClockSnapshot}ms)`)

		return resolve()
	end)
end

type MetrikPublicAPI = typeof(MetrikSDK.Public)
type MetrikPrivateAPI = typeof(MetrikSDK.Private)

export type MetrikSDK = MetrikPublicAPI & { Private: nil }

return MetrikSDK.Public
