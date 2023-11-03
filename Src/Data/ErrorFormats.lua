local Error = require(script.Parent.Parent.Enums.Error)

return table.freeze({
	[Error.AlreadyInitializedError] = "MetrikSDK has already been initialized."
})