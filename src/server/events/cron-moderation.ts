import { Players, HttpService } from "@rbxts/services";
import { Http } from "../../lib/http";
import { IData, IPlayers } from "..";

export function onCronCheckModeration(http: typeof Http.prototype, data: IData) {
	http.apiFetch(`moderation/check/bulk?users=${Players.GetPlayers().join(",")}`, {
		method: "GET",
	}).then((response) => {
		if (response.ok) {
			const body = HttpService.JSONDecode(response.body) as {
				kicked: {
					userId: number;
					reason: string;
				}[];
				banned: {
					userId: number;
					reason: string;
					permanent: boolean;
					timeRemaining?: number;
				}[];
			};

			body.banned.forEach((user) => {
				const player = Players.GetPlayerByUserId(user.userId);
				if (player) {
					delete (data.players as IPlayers)[player.Name];
					player.Kick(
						`You have been banned from this experience.\nReason: ${user.reason}\n${
							user.permanent
								? "This is a permanent ban"
								: `Time remaining: ${user.timeRemaining} hours\n\n(c) 2023 Metrik`
						}`,
					);
				}
			});

			body.kicked.forEach((user) => {
				const player = Players.GetPlayerByUserId(user.userId);
				if (player) {
					player.Kick(`You have been kicked from this experience.\nReason: ${user.reason}`);
				}
			});

			return body;
		}
	});
}
