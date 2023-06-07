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
} from "./events";
import { validateToken } from "../lib/token";

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

export async function startServer(token: string, options: Options) {
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

			data.playerCounts.push(Players.GetPlayers().size());
			data.heartbeats.push(Stats.HeartbeatTimeMs);
			data.physicsStepTimes.push(Stats.PhysicsStepTimeMs);
			data.dataReceiveKbps.push(Stats.DataReceiveKbps);
			data.dataSendKbps.push(Stats.DataSendKbps);
			data.ramUsage.push(Stats.GetTotalMemoryUsageMb());
			data.serverFps.push(Workspace.GetRealPhysicsFPS());

			http.apiFetch("ingest/analytics/server/update", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
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
			});
		}
	});

	const remoteFunction = new Instance("RemoteFunction");

	remoteFunction.Name = "MetrikClientBoundary";
	remoteFunction.Parent = game.GetService("ReplicatedStorage");

	remoteFunction.OnServerInvoke = (player, ...args) => {
		data.players[player.Name]!.clientInited = onServerInvoke(http, data, player, args[0] as RemoteFunctionData);
	};

	Players.PlayerAdded.Connect(async (player) => {
		const success = await onPlayerAdded(http, data, player, options);

		if (success) {
			data.players[player.Name] = {
				clientInited: false,
				userId: player.UserId,
				chatMessages: 0,
				sessionStart: os.time(),
			};
		}
	});

	Players.PlayerRemoving.Connect(async (player) => {
		const success = await onPlayerRemoving(http, data, player);

		if (success) {
			data.players[player.Name] = undefined;
		}
	});

	LogService.MessageOut.Connect((message, messageType) => {
		onMessageOut(http, message, messageType, options);
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
