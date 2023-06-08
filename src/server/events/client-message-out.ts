import { Http } from "../../lib/http";
import { Options } from "../..";
import { HttpService, LocalizationService } from "@rbxts/services";
import { Data } from "..";

export async function onClientMessageOut(
	http: typeof Http.prototype,
	player: Player,
	message: string,
	messageType: Enum.MessageType,
	data: Data,
	options: Options,
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
			http.apiFetch("ingest/log/client/new", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					universeId: tostring(game.GameId),
					placeId: tostring(game.PlaceId),
					jobId: game.JobId,
					region: LocalizationService.GetCountryRegionForPlayerAsync(player),
					message,
					level: messageTypes.find((mt) => mt.messageType === messageType)!.type,
					timestamp: os.time(),
				}),
			});
		}
	}
}
