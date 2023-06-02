import { Options } from "../";
import {
	LogService,
	Chat,
	Players,
	DataStoreService,
	HttpService,
	LocalizationService,
	VoiceChatService,
} from "@rbxts/services";
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

	const remoteFunction = new Instance("RemoteFunction");

	remoteFunction.Name = "MetrikClientBoundary";
	remoteFunction.Parent = game.GetService("ReplicatedStorage");

	interface RemoteFunctionData {
		device: "console" | "mobile" | "vr" | "tablet" | "desktop" | "unknown";
		locale: string;
	}

	remoteFunction.OnServerInvoke = (player, ...args) => {
		const data = args[0] as RemoteFunctionData;

		apiFetch("ingest/analytics/session/update", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${token}`,
			},
			body: HttpService.JSONEncode({
				userId: tostring(player.UserId),
				device: data.device,
				locale: data.locale,
			}),
			apiBase: options.apiBase as string,
		}).andThen((response) => {
			if (response.ok) {
				return true;
			} else {
				return false;
			}
		});
	};

	Players.PlayerAdded.Connect(async (player) => {
		const dataStore = DataStoreService.GetDataStore("metrik_sdk_data");
		const [success, hasPlayed] = pcall(() => dataStore.GetAsync(`played/${tostring(player.UserId)}`));

		if (!success) {
			log.error(`Failed to get played data for ${player.Name}`);
			return;
		}

		if (!hasPlayed) {
			if (options.debug) {
				log.info(`${player.Name} has not played before, setting played data`);
			}

			const [success, _] = pcall(() => dataStore.SetAsync(`played/${tostring(player.UserId)}`, true));

			if (!success) {
				log.error(`Failed to set played data for ${player.Name}`);
				return;
			}
		} else {
			if (options.debug) {
				log.info(`${player.Name} has played before, not setting played data`);
			}
		}

		const banned = await isBanned(player.UserId, token, options);
		if (banned) {
			if (options.debug) {
				log.info(`${player.Name} is banned, kicking`);
			}

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
					voiceChatEnabled: VoiceChatService.IsVoiceEnabledForUserIdAsync(player.UserId),
					newPlayer: !hasPlayed,
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
