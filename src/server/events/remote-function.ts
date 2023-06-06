import { Data } from "..";
import { Http } from "../../lib/http";
import { HttpService } from "@rbxts/services";

interface RemoteFunctionData {
	device: "console" | "mobile" | "vr" | "tablet" | "desktop" | "unknown";
	locale: string;
}

export function onServerInvoke(http: typeof Http.prototype, data: Data, player: Player, details: RemoteFunctionData) {
	const { device, locale } = details;

	if (!data.players[player.Name]?.clientInited) {
		http.apiFetch("ingest/analytics/session/update", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				userId: tostring(player.UserId),
				device: device,
				locale: locale,
			}),
		}).then((response) => {
			if (response.ok) {
				return true;
			} else {
				return false;
			}
		});

		return true;
	} else {
		return false;
	}
}
