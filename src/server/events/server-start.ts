import { Options } from "../..";
import { Stats, Players, Workspace, HttpService } from "@rbxts/services";
import { apiFetch } from "../../lib/http";
import { Http } from "../../lib/http";

export function onServerStart(http: typeof Http.prototype, region: string) {
	http.apiFetch("ingest/analytics/server/start", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: HttpService.JSONEncode({
			universeId: tostring(game.GameId),
			jobId: game.JobId,
			placeId: tostring(game.PlaceId),
			timestamp: os.time(),
			region: region,
			privateServer: game.PrivateServerId !== "",
			playerCount: Players.GetPlayers().size(),
			heartbeat: Stats.HeartbeatTimeMs,
			physicsStepTime: Stats.PhysicsStepTimeMs,
			dataRecieveKbps: Stats.DataReceiveKbps,
			dataSendKbps: Stats.DataSendKbps,
			ramUsage: Stats.GetTotalMemoryUsageMb(),
			serverFps: Workspace.GetRealPhysicsFPS(),
		}),
	});
}
