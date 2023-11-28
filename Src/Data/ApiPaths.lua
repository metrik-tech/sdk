local Api = require(script.Parent.Parent.Enums.Api)

return table.freeze({
	[Api.BaseUrl] = "api.metrik.app/api",

	[Api.ServerStart] = "/server/start",
	[Api.ServerEnd] = "/server/stop",
	[Api.ServerHeartbeat] = "/server/heartbeat",

	[Api.ServerLogBatch] = "/servers/logs",

	[Api.RegisterAction] = "/actions/register"
})