local Api = require(script.Parent.Parent.Enums.Api)

return table.freeze({
	[Api.TraceUrl] = "metrik.app/cdn-cgi/trace",
	[Api.BaseUrl] = "api.metrik.app/api",

	[Api.ServerStart] = "/server/start",
	[Api.ServerEnd] = "/server/stop",
	[Api.ServerHeartbeat] = "/server/heartbeat",

	[Api.ServerLogBatch] = "/log/error/bulk",

	[Api.RegisterAction] = "/actions/register",
})
