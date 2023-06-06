import { Http } from "../../lib/http";
import type { Data } from "..";
import { HttpService } from "@rbxts/services";

export function onServerClose(http: typeof Http.prototype, data: Data) {
	http.apiFetch("ingest/analytics/server/stop", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: HttpService.JSONEncode({
			jobId: game.JobId,
			timestamp: os.time(),
			playerCount: data.playerCounts,
			heartbeat: data.heartbeats,
			physicsStepTime: data.physicsStepTimes,
			dataRecieveKbps: data.dataReceiveKbps,
			dataSendKbps: data.dataSendKbps,
			ramUsage: data.ramUsage,
			serverFps: data.serverFps,
		}),
	});
}
