return table.freeze({
	TraceUrl = "metrik.app/cdn-cgi/trace",
	BaseUrl = "api.metrik.app/api/v1",

	ServerStart = "/projects/%s/server/start",
	ServerEnd = "/projects/%s/server/stop",
	ServerHeartbeat = "/projects/%s/server/heartbeat",

	GetLatestPlaceVersion = "/projects/%s/server/latest",

	ServerLogBatch = "/projects/%s/log/error/batch",

	RegisterAction = "/projects/%s/actions/register",
	ReturnAction = "/projects/%s/actions/return",
	ClaimAction = "/projects/%s/actions/claim",

	GetUserInformation = "/projects/%s/proxy/users/%s",

	GetModerationStatus = "/projects/%s/moderation/status",

	GetAllFlags = "/projects/%s/flags/get",
})
