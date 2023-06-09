import { Http } from "../../lib/http";
import type { IData } from "..";
import { HttpService } from "@rbxts/services";

export function onServerClose(http: typeof Http.prototype, data: IData) {
	http.apiFetch("ingest/analytics/server/stop", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: HttpService.JSONEncode({
			jobId: game.JobId,
			timestamp: os.time(),
			stats: data.stats,
		}),
	});
}
