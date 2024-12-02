--[[
	Metrik SDK - https://github.com/metrik-tech/sdk
]]

local Runtime = require(script.Parent.Packages.Runtime)
local Promise = require(script.Parent.Packages.Promise)
local Console = require(script.Parent.Packages.Console)

local Error = require(script.Parent.Enums.Error)

local ErrorFormats = require(script.Parent.Data.ErrorFormats)

local FlagsController = require(script.Parent.Controllers.FlagsController)
local BreadcrumbController = require(script.Parent.Controllers.BreadcrumbController)
local ContextController = require(script.Parent.Controllers.ContextController)

local ON_INIT_LIFECYCLE_NAME = "OnInit"
local ON_START_LIFECYCLE_NAME = "OnStart"

--[=[
	@class MetrikSDK.Client

	The MetrikSDK.Client class is the main entry point for interacting with the Metrik Service on the Client.
]=]
local MetrikSDK = {}

MetrikSDK.Public = {}
MetrikSDK.Private = {}

MetrikSDK.Public.Private = MetrikSDK.Private
MetrikSDK.Private.Public = MetrikSDK.Public

MetrikSDK.Private.Reporter = Console.new("MetrikSDK-Client")

function MetrikSDK.Private.FromError(_: MetrikPrivateAPI, errorEnum: string, ...: string)
	return string.format(ErrorFormats[errorEnum], ...)
end

function MetrikSDK.Private.AwaitUntilReady(self: MetrikPrivateAPI)
	repeat task.wait() until self.IsInitialized
end

--[=[
	Defer to @MetrikSDK.CreateBreadcrumb

	@method CreateBreadcrumb
	@param message string
	@within MetrikSDK.Client

	@return ()
]=]
--
function MetrikSDK.Public.CreateBreadcrumb(self: MetrikPublicAPI, message: string)
	self.Private:AwaitUntilReady()

	BreadcrumbController:CreateBreadcrumbFor(debug.info(2, "s"), message)
end

--[=[
	Defer to @MetrikSDK.SetContext

	@method SetContext
	@param context { [string]: any }
	@within MetrikSDK.Client

	@return ()
]=]
--
function MetrikSDK.Public.SetContext(self: MetrikPublicAPI, context: { [string]: any })
	self.Private:AwaitUntilReady()

	ContextController:CreateContextFor(debug.info(2, "s"), context)
end

--[=[
	Defer to @MetrikSDK.GetFlag

	@method GetFlag
	@param context { [string]: any }
	@within MetrikSDK.Client

	@return boolean
]=]
--
function MetrikSDK.Public.GetFlag(self: MetrikPublicAPI, flagName: string)
	self.Private:AwaitUntilReady()

	return FlagsController:EvaluateFlag(flagName)
end

--[=[
	Defer to @MetrikSDK.InitializeAsync

	@method InitializeAsync
	@within MetrikSDK.Client

	@return Promise<()>
]=]
--
function MetrikSDK.Public.InitializeAsync(self: MetrikPublicAPI)
	return Promise.new(function(resolve, reject)
		if self.Private.IsInitialized then
			return reject(self.Private:FromError(Error.AlreadyInitializedError))
		end

		local runtimeClockSnapshot = os.clock()
		local metrikControllers = Runtime:RequireChildren(
			script.Parent.Controllers,
			function(module: ModuleScript, moduleContent: { [any]: any })
				self.Private.Reporter:Debug(`Loading MetrikSDK Controller module: '{module.Name}'`)

				return moduleContent
			end
		)

		table.sort(metrikControllers, function(serviceA, serviceB)
			return (serviceA.Priority or 0) > (serviceB.Priority or 0)
		end)
		
		repeat task.wait() until script.Parent:GetAttribute("INIT_COMPLETE")

		Runtime:CallMethodOn(metrikControllers, ON_INIT_LIFECYCLE_NAME)
		Runtime:CallMethodOn(metrikControllers, ON_START_LIFECYCLE_NAME)

		self.Private.IsInitialized = true

		self.Private.Reporter:Debug(`Loaded all MetrikSDK Controller ({os.clock() - runtimeClockSnapshot}ms)`)

		return resolve()
	end)
end

type MetrikPublicAPI = typeof(MetrikSDK.Public)
type MetrikPrivateAPI = typeof(MetrikSDK.Private)

export type MetrikSDK = MetrikPublicAPI & { Private: nil }

return MetrikSDK.Public
