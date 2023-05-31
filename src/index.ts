import { HttpService, RunService } from "@rbxts/services";
import { startServer } from "./server";
import log from "./lib/log";
import { startClient } from "./client";

export interface Options {
	debug: boolean;
}

class SDK {
	public VERSION = "0.0.1";

	private token: string;
	private options: Options;

	constructor(token: string, options: Options) {
		print("init", token, options);
		this.token = token;
		this.options = options;

		if (!RunService.IsStudio()) {
			if (RunService.IsServer()) {
				startServer(token, options);
			} else if (RunService.IsClient()) {
				startClient(options);
			}
		} else {
			log.warn("Running in Roblox Studio, skipping SDK initialization.");
		}
	}
}
