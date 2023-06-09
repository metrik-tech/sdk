import { HttpService } from "@rbxts/services";
import { Http } from "../../lib/http";
import { IOptions } from "../..";
import { IData } from "..";

export function onMessageOut(
	http: typeof Http.prototype,
	message: string,
	messageType: Enum.MessageType,
	data: IData,
	options: IOptions,
) {
	const messageTypes = [
		{
			messageType: Enum.MessageType.MessageOutput,
			type: "info",
		},
		{
			messageType: Enum.MessageType.MessageWarning,
			type: "warn",
		},
		{
			messageType: Enum.MessageType.MessageError,
			type: "error",
		},
	];
	if (messageTypes.find((mt) => mt.messageType === messageType)) {
		if (!options.logMetrikMessages && string.match(message, "^[METRIK SDK]")[0]) {
			return;
		} else if (
			(options.logMetrikMessages && string.match(message, "^[METRIK SDK]")[0]) ||
			!string.match(message, "^[METRIK SDK]")[0]
		) {
			http.apiFetch("ingest/logs/new", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					universeId: tostring(game.GameId),
					placeId: tostring(game.PlaceId),
					jobId: game.JobId,
					env: "server",
					region: data.region,
					message,
					level: messageTypes.find((mt) => mt.messageType === messageType)!.type,
					timestamp: os.time(),
				}),
			});
		}
	}
}
