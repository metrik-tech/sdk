local Error = require(script.Parent.Parent.Enums.Error)

return table.freeze({
	[Error.AlreadyInitializedError] = "MetrikSDK has already been initialized.",
	[Error.ExpectedCallAfterCall] = "Expected '%s' to be called after '%s'",
	[Error.InvalidActionArgumentType] = "Invalid argument type '%s' in action '%s'"
})