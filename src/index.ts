import { HttpService, RunService } from "@rbxts/services";
import { startServer } from "./server";
import log from "./lib/log";
import { startClient } from "./client";
import { $package } from "rbxts-transform-debug";
import { validateToken } from "./lib/token";

export interface Options {
	debug?: boolean;
	logMetrikMessages?: boolean;
	apiBase?: string;
}

export default class SDK {
	public VERSION = $package.version;
	public API_BASE = "https://api.metrik.app";

	private token: string | undefined;
	private options: Options;

	constructor({ token, options }: { token?: string; options?: Options }) {
		this.token = token;
		this.options = options || {};

		if (!this.options.apiBase) {
			this.options.apiBase = this.API_BASE;
		}

		if (!this.options.logMetrikMessages) {
			this.options.logMetrikMessages = false;
		}

		if (!RunService.IsStudio()) {
			if (!token) {
				if (RunService.IsClient()) {
					startClient();
				} else if (RunService.IsServer()) {
					log.error("No token provided, cannot start SDK.");

					return;
				}
			} else if (token) {
				if (RunService.IsServer()) {
					startServer(token, this.options);
				} else if (RunService.IsClient()) {
					log.error(
						"Do not pass a token on the client. We do not internally use it when you construct the SDK from the client, and puts your token at risk of being stolen or leaked. Be careful!",
					);

					return;
				}
			}
		} else {
			log.warn("Running in Roblox Studio, skipping SDK initialization.");
		}
	}
}
