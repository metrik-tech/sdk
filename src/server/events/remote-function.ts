import { IData, IPlayers } from "..";
import { IOptions } from "../..";
import { Http } from "../../lib/http";
import { HttpService, LocalizationService, VoiceChatService } from "@rbxts/services";
import log from "../../lib/log";

interface IRemoteFunctionData {
	device: "console" | "mobile" | "vr" | "tablet" | "desktop" | "unknown";
	locale: string;
}

export async function onServerInvoke(
	http: typeof Http.prototype,
	data: IData,
	player: Player,
	details: IRemoteFunctionData,
	options: IOptions,
): Promise<LuaTuple<boolean[]>> {
	const { device, locale } = details;
	const dataPlayer = (data.players as IPlayers)[player.Name];

	if (!dataPlayer) {
		log.error(`Failed to get player data for ${player.Name}`);

		return $tuple(false, false);
	}

	if (!dataPlayer.clientInited) {
		return await http
			.apiFetch("ingest/analytics/session/start", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					userId: tostring(player.UserId),
					placeId: tostring(game.PlaceId),
					region: LocalizationService.GetCountryRegionForPlayerAsync(player),
					premium: player.MembershipType === Enum.MembershipType.Premium,
					voiceChatEnabled: VoiceChatService.IsVoiceEnabledForUserIdAsync(player.UserId),
					newPlayer: !dataPlayer.hasPlayed,
					device: device,
					locale: locale,
					paying: false,
					sessionStart: os.time(),
				}),
			})
			.then((response) => {
				if (response.ok) {
					if (options.debug) {
						log.info(`${player.Name} has started a session`);
					}
					return $tuple(true, true);
				} else {
					return $tuple(false, false);
				}
			});
	} else {
		return $tuple(false, true);
	}
}
