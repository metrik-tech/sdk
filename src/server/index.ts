import { Options } from "../";
import { LogService, Chat, Players, DataStoreService, HttpService, LocalizationService } from "@rbxts/services";
import { fetch, apiFetch } from "../lib/http";
import { isBanned } from "../lib/moderation";
import log from "../lib/log";

export interface Data {
	players: {
		[player: string]:
			| {
					userId: number;
					chatMessages: number;
					sessionStart: number;
			  }
			| undefined;
	};
}

export function startServer(token: string, options: Options) {
	const data: Data = {
		players: {},
	} satisfies Data;

	Players.PlayerAdded.Connect(async (player) => {
		const banned = await isBanned(player.UserId, token, options);
		if (banned) {
			player.Kick(
				`You have been banned from this experience.\n\nReason: ${banned.reason}\n\n${
					banned.permanent ? "This is a permanent ban" : `Time remaining: ${banned.timeRemaining} hours`
				}`,
			);
			return;
		} else {
			apiFetch("ingest/analytics/session/start", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: HttpService.JSONEncode({
					userId: tostring(player.UserId),
					universeId: tostring(game.GameId),
					placeId: tostring(game.PlaceId),
					region: LocalizationService.GetCountryRegionForPlayerAsync(player),
					premium: player.MembershipType === Enum.MembershipType.Premium,
					paying: false,
					sessionStart: os.time(),
				}),
				apiBase: options.apiBase as string,
			}).andThen((response) => {
				if (response.ok) {
					data.players[player.Name] = {
						userId: player.UserId,
						chatMessages: 0,
						sessionStart: os.time(),
					};
				}
			});
		}
	});

	Players.PlayerRemoving.Connect((player) => {
		const storedPlayer = data.players[player.Name];

		if (storedPlayer) {
			apiFetch("ingest/analytics/session/end", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: HttpService.JSONEncode({
					userId: storedPlayer.userId,
					sessionEnd: os.time(),
					chatMessages: storedPlayer.chatMessages,
				}),
				apiBase: options.apiBase as string,
			});

			data.players[player.Name] = undefined;
		}
	});

	LogService.MessageOut.Connect((message, messageType) => {
		const messageTypes = [
			{
				messageType: Enum.MessageType.MessageOutput,
				type: "info",
			},
			{
				messageType: Enum.MessageType.MessageInfo,
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
		if (messageType === Enum.MessageType.MessageOutput) {
			apiFetch("ingest/analytics/log", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: HttpService.JSONEncode({
					universeId: tostring(game.GameId),
					placeId: tostring(game.PlaceId),
					message,
					level: messageTypes.find((mt) => mt.messageType === messageType)!.type,
					timestamp: os.time(),
				}),
				apiBase: options.apiBase as string,
			});
		}
	});

	Chat.Chatted.Connect((_, player) => {
		const storedPlayer = data.players[player];

		if (storedPlayer) {
			if (storedPlayer.chatMessages === undefined) {
				storedPlayer.chatMessages = 1;
			} else {
				storedPlayer.chatMessages++;
			}
		}
	});

	log.info("Started SDK server.");
}
