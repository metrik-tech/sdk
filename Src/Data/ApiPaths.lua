local Api = require(script.Parent.Parent.Enums.Api)

return table.freeze({
	[Api.BaseUrl] = "api.metrik.app",

	[Api.ServerStart] = "/servers/start",
	[Api.ServerEnd] = "/servers/end",
	[Api.ServerHeartbeat] = "/servers/heartbeat",

	[Api.RegisterAction] = "/actions/register"
})