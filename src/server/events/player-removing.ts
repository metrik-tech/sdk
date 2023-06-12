import { IData, IPlayers } from "..";
import { Http } from "../../lib/http";
import { HttpService } from "@rbxts/services";
import log from "../../lib/log";

export async function onPlayerRemoving(http: typeof Http.prototype, data: IData, player: Player) {
	const storedPlayer = (data.players as IPlayers)[player.Name];

	if (storedPlayer) {
		const res = await http
			.apiFetch("ingest/analytics/session/end", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					userId: storedPlayer.userId,
					sessionEnd: os.time(),
					chatMessages: storedPlayer.chatMessages,
				}),
			})
			.then((response) => {
				if (response.ok) {
					return true;
				} else {
					log.error("Failed to end session for player " + player.Name);
				}
			});

		return res;
	}
}
