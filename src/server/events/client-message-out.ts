import { Http } from "../../lib/http";
import { IOptions } from "../..";
import { HttpService, LocalizationService } from "@rbxts/services";
import { IData } from "..";

// !! THIS IS NON-FUNCTIONAL !!

export async function onClientMessageOut(
	http: typeof Http.prototype,
	player: Player,
	message: string,
	messageType: Enum.MessageType,
	data: IData,
	options: IOptions,
) {
	if (!options.sendClientLogs) {
		return;
	}

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

	if (
		!options.clientLogTypes ||
		options.clientLogTypes.size() === 0 ||
		!options.clientLogTypes.find((t) => t === messageTypes.find((mt) => mt.messageType === messageType)!.type)
	) {
		return;
	}

	if (messageTypes.find((mt) => mt.messageType === messageType)) {
		if (!options.sendMetrikLogs && string.match(message, "^[METRIK SDK]")[0]) {
			return;
		} else if (
			(options.sendMetrikLogs && string.match(message, "^[METRIK SDK]")[0]) ||
			!string.match(message, "^[METRIK SDK]")[0]
		) {
			http.apiFetch("ingest/logs/new", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					placeId: tostring(game.PlaceId),
					env: "client",
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
