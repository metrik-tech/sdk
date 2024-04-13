local Api = require(script.Parent.Parent.Enums.Api)

return table.freeze({
	[Api.TraceUrl] = "metrik.app/cdn-cgi/trace",
	[Api.BaseUrl] = "api.metrik.app/api/v1",

	[Api.ServerStart] = "/projects/%s/server/start",
	[Api.ServerEnd] = "/projects/%s/server/stop",
	[Api.ServerHeartbeat] = "/projects/%S/server/heartbeat",

	[Api.ServerLogBatch] = "/projects/%s/log/error/batch",

	[Api.RegisterAction] = "/projects/%s/actions/register",
})
