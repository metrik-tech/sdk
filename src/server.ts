import { Options } from ".";
import { LogService, Chat, Players, DataStoreService } from "@rbxts/services";

export interface Data {
	players: {
		[player: string]: {
			userId: number;
			chatMessages: number;
			sessionStart: number;
		};
	};
}

export function startServer(token: string, options: Options) {
	const data: Data = {
		players: {},
	} satisfies Data;

	Players.PlayerAdded.Connect((player) => {
		// start a session
	});

	Players.PlayerRemoving.Connect((player) => {
		// end a session
	});

	LogService.MessageOut.Connect((message, type) => {
		// log a log
	});

	Chat.Chatted.Connect((message, player) => {
		const storedPlayer = data.players[player];

		if (storedPlayer) {
			if (storedPlayer.chatMessages === undefined) {
				storedPlayer.chatMessages = 1;
			} else {
				storedPlayer.chatMessages++;
			}
		}
	});

	print("startServer");
}
