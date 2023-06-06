import { Data } from "..";
import { Options } from "../..";
import { Http } from "../../lib/http";
import { DataStoreService, HttpService, LocalizationService, VoiceChatService } from "@rbxts/services";
import log from "../../lib/log";
import { isBanned } from "../../lib/moderation";

export async function onPlayerAdded(http: typeof Http.prototype, data: Data, player: Player, options: Options) {
	const dataStore = DataStoreService.GetDataStore("metrik_sdk_data");
	const [success, hasPlayed] = pcall(() => dataStore.GetAsync(`played/${tostring(player.UserId)}`));

	if (!success) {
		if (options.debug) log.error(`Failed to get played data for ${player.Name}`);
		return;
	}

	if (!hasPlayed) {
		if (options.debug) {
			log.info(`${player.Name} has not played before, setting played data`);
		}

		const [success, _] = pcall(() => dataStore.SetAsync(`played/${tostring(player.UserId)}`, true));

		if (!success) {
			if (options.debug) log.error(`Failed to set played data for ${player.Name}`);
			return;
		}
	} else {
		if (options.debug) {
			log.info(`${player.Name} has played before, not setting played data`);
		}
	}

	const banned = await isBanned(player.UserId, http, options);
	if (banned) {
		if (options.debug) {
			log.info(`${player.Name} is banned, kicking`);
		}

		player.Kick(
			`You have been banned from this experience.\nReason: ${banned.reason}\n${
				banned.permanent
					? "This is a permanent ban"
					: `Time remaining: ${banned.timeRemaining} hours\n\n(c) 2023 Metrik`
			}`,
		);
		return;
	} else {
		http.apiFetch("ingest/analytics/session/start", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				userId: tostring(player.UserId),
				universeId: tostring(game.GameId),
				placeId: tostring(game.PlaceId),
				region: LocalizationService.GetCountryRegionForPlayerAsync(player),
				premium: player.MembershipType === Enum.MembershipType.Premium,
				voiceChatEnabled: VoiceChatService.IsVoiceEnabledForUserIdAsync(player.UserId),
				newPlayer: !hasPlayed,
				paying: false,
				sessionStart: os.time(),
			}),
		}).andThen((response) => {
			if (response.ok) {
				data.players[player.Name] = {
					clientInited: false,
					userId: player.UserId,
					chatMessages: 0,
					sessionStart: os.time(),
				};
				if (options.debug) {
					log.info(`${player.Name} has started a session`);
				}
			}
		});
	}
}
