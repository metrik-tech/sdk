--[[
	Metrik SDK - https://github.com/metrik-tech/sdk
]]

local Loader = require(script.Packages.Loader)
local Promise = require(script.Packages.Promise)
local Console = require(script.Packages.Console)
local Sift = require(script.Packages.Sift)

local Error = require(script.Enums.Error)
 
local ErrorFormats = require(script.Data.ErrorFormats)

local Action = require(script.API.Action)

local ON_INIT_LIFECYCLE_NAME = "OnInit"
local ON_START_LIFECYCLE_NAME = "OnStart"

--[=[
	@class MetrikSDK

	The base class developers will be interacting with. *(TO-DO: add a descriptive class description!)*
]=]
local MetrikSDK = { }

MetrikSDK.Public = { }
MetrikSDK.Private = { }

MetrikSDK.Public.Private = MetrikSDK.Private
MetrikSDK.Private.Public = MetrikSDK.Public

MetrikSDK.Private.Reporter = Console.new("🕙 MetrikSDK-Reporter")
MetrikSDK.Private.IsInitialized = false

--[=[
	@prop Action Action
	@within MetrikSDK
]=]--
MetrikSDK.Public.Action = Action

function MetrikSDK.Private.FromError(_: MetrikPrivateAPI, errorEnum:string, ...: string)
	return string.format(ErrorFormats[errorEnum], ...)
end

--[=[
	Start the Metrik SDK, once this function has been called, internal Metrik Services and Controllers should come online and start to respond and
		handle Metrik backend calls made to the current Roblox server.

	:::warning
		Please ensure that any pre-init variables are set before calling this function, otherwise Metrik will have issues attempting to authenticate
		the current SDK!
	:::

	@method InitializeAsync
	@within MetrikSDK

	@return Promise<()>
]=]--
function MetrikSDK.Public.InitializeAsync(self: MetrikPublicAPI)
	return Promise.new(function(resolve, reject)
		if self.Private.IsInitialized then
			return reject(self.Private:FromError(Error.AlreadyInitializedError))
		end
		
		local runtimeClockSnapshot = os.clock()
		local metrikServices = Sift.Dictionary.values(Loader.LoadChildren(script.Services, function(moduleInstance)
			self.Private.Reporter:Debug(`Loading MetrikSDK Service module: '{moduleInstance.Name}'`)

			return true
		end))

		table.sort(metrikServices, function(serviceA, serviceB)
			return (serviceA.Priority or 0) > (serviceB.Priority or 0)
		end)

		Loader.SpawnAll(metrikServices, ON_INIT_LIFECYCLE_NAME)
		Loader.SpawnAll(metrikServices, ON_START_LIFECYCLE_NAME)

		self.Private.IsInitialized = true

		self.Private.Reporter:Debug(`Loaded all MetrikSDK Services ({os.clock() - runtimeClockSnapshot}ms)`)

		return resolve()
	end)
end

type MetrikPublicAPI = typeof(MetrikSDK.Public)
type MetrikPrivateAPI = typeof(MetrikSDK.Private)

export type MetrikSDK = MetrikPublicAPI & { Private: nil }

return MetrikSDK.Public