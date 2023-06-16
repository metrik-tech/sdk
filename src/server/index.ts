import { IOptions } from "../";
import {
	LogService,
	Chat,
	Players,
	DataStoreService,
	HttpService,
	LocalizationService,
	VoiceChatService,
	Stats as IStats,
	RunService,
	Workspace,
} from "@rbxts/services";
import { fetch, apiFetch } from "../lib/http";
import log from "../lib/log";
import { Http } from "../lib/http";

import {
	onServerStart,
	onServerClose,
	onCronCheckModeration,
	onServerInvoke,
	onPlayerAdded,
	onPlayerRemoving,
	onMessageOut,
	onClientMessageOut,
} from "./events";
import { validateToken } from "../lib/token";

export interface IBroadcast {
	message: string;
	type: "chat" | "topbar" | "toast";
	duration: number;
}

export interface IStatsItem {
	data: number;
	timestamp: number;
}

export interface IPlayers {
	[player: string]: IPlayer | undefined;
}

export interface IPlayer {
	hasPlayed: boolean;
	clientInited: boolean;
	userId: number;
	chatMessages: number;
	sessionStart: number;
}

interface IStats {
	timestamp: number;
	playerCounts: number;
	heartbeats: number;
	instanceCounts: number;
	primitivesCounts: number;
	contactsCounts: number;
	movingPrimitivesCounts: number;
	physicsStepTimes: number;
	physicsReceiveKbps: number;
	physicsSendKbps: number;
	dataReceiveKbps: number;
	dataSendKbps: number;
	ramUsage: number;
	serverFps: number;
}

export interface IData {
	players:
		| {
				[player: string]: IPlayer | undefined;
		  }
		| undefined;
	stats: IStats[];
}

interface IRemoteFunctionData {
	device: "console" | "mobile" | "vr" | "tablet" | "desktop" | "unknown";
	locale: string;
}

export async function startServer(token: string, options: IOptions) {
	const data = {
		players: {},
		stats: [],
	} satisfies IData;

	const http = new Http(token, { apiBase: options.apiBase as string });

	const validToken = await validateToken(http);

	if (!validToken) {
		log.error("Invalid token provided, exiting.");
		return;
	}

	onServerStart(http);

	game.BindToClose(() => {
		onServerClose(http, data);
	});

	let currentPeriod = math.floor(os.time() / 60);
	let lastPeriod = currentPeriod - 1;

	RunService.Heartbeat.Connect(() => {
		currentPeriod = math.floor(os.time() / 60);

		if (currentPeriod > lastPeriod) {
			lastPeriod = currentPeriod;

			onCronCheckModeration(http, data);

			const stats = {
				timestamp: os.time(),
				playerCounts: Players.GetPlayers().size(),
				contactsCounts: IStats.ContactsCount,
				instanceCounts: IStats.InstanceCount,
				primitivesCounts: IStats.PrimitivesCount,
				movingPrimitivesCounts: IStats.MovingPrimitivesCount,
				heartbeats: IStats.HeartbeatTimeMs,
				physicsStepTimes: IStats.PhysicsStepTimeMs,
				physicsReceiveKbps: IStats.PhysicsReceiveKbps,
				physicsSendKbps: IStats.PhysicsSendKbps,
				dataReceiveKbps: IStats.DataReceiveKbps,
				dataSendKbps: IStats.DataSendKbps,
				ramUsage: IStats.GetTotalMemoryUsageMb(),
				serverFps: Workspace.GetRealPhysicsFPS(),
			};

			data.stats.push(stats as never);

			http.apiFetch("ingest/analytics/server/update", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: HttpService.JSONEncode({
					jobId: game.JobId,
					timestamp: os.time(),
					stats,
				}),
			});
		}
	});

	const clientInit = new Instance("RemoteFunction");

	clientInit.Name = "MetrikClientBoundary";
	clientInit.Parent = game.GetService("ReplicatedStorage");

	clientInit.OnServerInvoke = async (player, ...args) => {
		const [success, clientInited] = await onServerInvoke(
			http,
			data,
			player,
			args[0] as IRemoteFunctionData,
			options,
		);

		if (!success) {
			log.error("Failed to add player to Metrik, kicking player.");
			player.Kick("Failed to add player to Metrik.");
		}

		(data.players as IPlayers)[player.Name]!.clientInited = clientInited;
	};

	const clientMessageOut = new Instance("RemoteFunction");

	clientMessageOut.Name = "MetrikClientMessageOut";
	clientMessageOut.Parent = game.GetService("ReplicatedStorage");

	clientMessageOut.OnServerInvoke = (player, ...args) => {
		onClientMessageOut(http, player, args[0] as string, args[1] as Enum.MessageType, data, options);
	};

	Players.PlayerAdded.Connect(async (player) => {
		const [success, hasPlayed] = await onPlayerAdded(http, player, options);

		if (success) {
			(data.players as IPlayers)[player.Name] = {
				hasPlayed,
				clientInited: false,
				userId: player.UserId,
				chatMessages: 0,
				sessionStart: os.time(),
			};
		} else {
			log.error("Failed to add player to Metrik, kicking player.");
			player.Kick("Failed to add player to Metrik.");
		}
	});

	Players.PlayerRemoving.Connect(async (player) => {
		const success = await onPlayerRemoving(http, data, player);

		if (success) {
			(data.players as IPlayers)[player.Name] = undefined;
		}
	});

	LogService.MessageOut.Connect((message, messageType) => {
		onMessageOut(http, message, messageType, data, options);
	});

	Chat.Chatted.Connect((_, player) => {
		const storedPlayer = (data.players as IPlayers)[player];

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
