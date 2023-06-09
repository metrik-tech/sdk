import { IOptions } from "../..";
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
			version: game.PlaceVersion,
			serverType:
				game.PrivateServerId !== "" && game.PrivateServerOwnerId !== 0
					? "private"
					: game.PrivateServerId !== "" && game.PrivateServerOwnerId === 0
					? "reserved"
					: "public",
			initialStats: {
				playerCount: Players.GetPlayers().size(),
				heartbeat: Stats.HeartbeatTimeMs,
				contactsCount: Stats.ContactsCount,
				instanceCount: Stats.InstanceCount,
				primitivesCount: Stats.PrimitivesCount,
				movingPrimitivesCount: Stats.MovingPrimitivesCount,
				physicsStepTime: Stats.PhysicsStepTimeMs,
				physicsReceiveKbps: Stats.PhysicsReceiveKbps,
				physicsSendKbps: Stats.PhysicsSendKbps,
				dataRecieveKbps: Stats.DataReceiveKbps,
				dataSendKbps: Stats.DataSendKbps,
				ramUsage: Stats.GetTotalMemoryUsageMb(),
				serverFps: Workspace.GetRealPhysicsFPS(),
			},
		}),
	});
}
