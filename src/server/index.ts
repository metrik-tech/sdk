import { Options } from "../";
import {
	LogService,
	Chat,
	Players,
	DataStoreService,
	HttpService,
	LocalizationService,
	VoiceChatService,
	Stats,
	RunService,
	Workspace,
} from "@rbxts/services";
import { fetch, apiFetch } from "../lib/http";
import { isBanned } from "../lib/moderation";
import log from "../lib/log";
import { average, percentile } from "../lib/math";

export interface Data {
	players: {
		[player: string]:
			| {
					clientInited: boolean;
					userId: number;
					chatMessages: number;
					sessionStart: number;
			  }
			| undefined;
	};
	playerCounts: number[];
	heartbeats: number[];
	physicsStepTimes: number[];
	dataReceiveKbps: number[];
	dataSendKbps: number[];
	ramUsage: number[];
	serverFps: number[];
}

interface RemoteFunctionData {
	device: "console" | "mobile" | "vr" | "tablet" | "desktop" | "unknown";
	locale: string;
}

export function startServer(token: string, options: Options) {
	const data: Data = {
		players: {},
		playerCounts: [],
		heartbeats: [],
		physicsStepTimes: [],
		dataReceiveKbps: [],
		dataSendKbps: [],
		ramUsage: [],
		serverFps: [],
	} satisfies Data;

	const region = apiFetch("ip/location", {
		method: "GET",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
		apiBase: options.apiBase as string,
	}).andThen((response) => {
		if (response.ok) {
			const body = HttpService.JSONDecode(response.body) as {
				region: string;
			};

			return body.region;
		} else {
			return "XX";
		}
	});

	apiFetch("ingest/analytics/server/start", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
		body: HttpService.JSONEncode({
			universeId: tostring(game.GameId),
			jobId: game.JobId,
			placeId: tostring(game.PlaceId),
			timestamp: os.time(),
			region: region,
			privateServer: game.PrivateServerId !== "",
			playerCount: Players.GetPlayers().size(),
			heartbeat: Stats.HeartbeatTimeMs,
			physicsStepTime: Stats.PhysicsStepTimeMs,
			dataRecieveKbps: Stats.DataReceiveKbps,
			dataSendKbps: Stats.DataSendKbps,
			ramUsage: Stats.GetTotalMemoryUsageMb(),
			serverFps: Workspace.GetRealPhysicsFPS(),
		}),
		apiBase: options.apiBase as string,
	});

	game.BindToClose(() => {
		apiFetch("ingest/analytics/server/stop", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${token}`,
			},
			body: HttpService.JSONEncode({
				jobId: game.JobId,
				timestamp: os.time(),
				playerCount: data.playerCounts,
				heartbeat: data.heartbeats,
				physicsStepTime: data.physicsStepTimes,
				dataRecieveKbps: data.dataReceiveKbps,
				dataSendKbps: data.dataSendKbps,
				ramUsage: data.ramUsage,
				serverFps: data.serverFps,
			}),
			apiBase: options.apiBase as string,
		});
	});

	let currentPeriod = math.floor(os.time() / 60);
	let lastPeriod = currentPeriod - 1;

	RunService.Heartbeat.Connect(() => {
		currentPeriod = math.floor(os.time() / 60);

		if (currentPeriod > lastPeriod) {
			lastPeriod = currentPeriod;

			data.playerCounts.push(Players.GetPlayers().size());
			data.heartbeats.push(Stats.HeartbeatTimeMs);
			data.physicsStepTimes.push(Stats.PhysicsStepTimeMs);
			data.dataReceiveKbps.push(Stats.DataReceiveKbps);
			data.dataSendKbps.push(Stats.DataSendKbps);
			data.ramUsage.push(Stats.GetTotalMemoryUsageMb());
			data.serverFps.push(Workspace.GetRealPhysicsFPS());

			apiFetch("ingest/analytics/server/update", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: HttpService.JSONEncode({
					jobId: game.JobId,
					playerCount: Players.GetPlayers().size(),
					heartbeat: Stats.HeartbeatTimeMs,
					physicsStepTime: Stats.PhysicsStepTimeMs,
					dataRecieveKbps: Stats.DataReceiveKbps,
					dataSendKbps: Stats.DataSendKbps,
					ramUsage: Stats.GetTotalMemoryUsageMb(),
					serverFps: Workspace.GetRealPhysicsFPS(),
				}),
				apiBase: options.apiBase as string,
			});
		}
	});

	const remoteFunction = new Instance("RemoteFunction");

	remoteFunction.Name = "MetrikClientBoundary";
	remoteFunction.Parent = game.GetService("ReplicatedStorage");

	remoteFunction.OnServerInvoke = (player, ...args) => {
		const { device, locale } = args[0] as RemoteFunctionData;

		if (!data.players[player.Name]?.clientInited) {
			apiFetch("ingest/analytics/session/update", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: HttpService.JSONEncode({
					userId: tostring(player.UserId),
					device: device,
					locale: locale,
				}),
				apiBase: options.apiBase as string,
			}).andThen((response) => {
				if (response.ok) {
					return true;
				} else {
					return false;
				}
			});

			data.players[player.Name]!.clientInited = true;
		} else {
			if (options.debug) {
				log.info(`${player.Name} has already been initialized, not updating`);
			}
		}
	};

	Players.PlayerAdded.Connect(async (player) => {
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

		const banned = await isBanned(player.UserId, token, options);
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
		if (messageTypes.find((mt) => mt.messageType === messageType)) {
			if (!options.logMetrikMessages && string.match(message, "^[METRIK]")[0]) {
				return;
			} else if (
				(options.logMetrikMessages && string.match(message, "^[METRIK]")[0]) ||
				!string.match(message, "^[METRIK]")[0]
			) {
				apiFetch("ingest/log/new", {
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

	if (options.debug) log.info("Started SDK server.");
}
