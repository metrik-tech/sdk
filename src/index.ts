import { HttpService, RunService } from "@rbxts/services";
import { startServer } from "./server";
import log from "./lib/log";
import { startClient } from "./client";
import { $package } from "rbxts-transform-debug";
import { validateToken } from "./lib/token";
import { Http } from "./lib/http";

export interface IOptions {
	debug?: boolean;
	logMetrikMessages?: boolean;
	apiBase?: string;
}

export default class SDK {
	public VERSION = $package.version;
	public API_BASE = "https://api.metrik.app";

	private token: string | undefined;
	private options: IOptions;

	constructor({ token, options }: { token?: string; options?: IOptions }) {
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

	async log(message: string, data: unknown): Promise<void> {
		if (!this.token) {
			return;
		}

		const http = new Http(this.token, { apiBase: this.options.apiBase as string });

		const response = await http.apiFetch("ingest/logs/new", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				universeId: tostring(game.GameId),
				placeId: tostring(game.PlaceId),
				env: "server",
				jobId: game.JobId,

				message,
				data: data ? HttpService.JSONEncode(data) : undefined,
				level: "info",
				timestamp: os.time(),
			}),
		});

		if (!response.ok) {
			log.error(`Failed to log message: ${message}`);
		}

		print(message, data);

		return;
	}

	async error(message: string, data: unknown): Promise<void> {
		if (!this.token) {
			return;
		}

		const http = new Http(this.token, { apiBase: this.options.apiBase as string });

		const response = await http.apiFetch("ingest/logs/new", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				universeId: tostring(game.GameId),
				placeId: tostring(game.PlaceId),
				env: "server",
				jobId: game.JobId,

				message,
				data: data ? HttpService.JSONEncode(data) : undefined,
				level: "error",
				timestamp: os.time(),
			}),
		});

		if (!response.ok) {
			log.error(`Failed to log message: ${message}`);
		}

		warn(message, data);

		return;
	}

	async crash(message: string, data: unknown): Promise<void> {
		if (!this.token) {
			return;
		}

		const http = new Http(this.token, { apiBase: this.options.apiBase as string });

		const response = await http.apiFetch("ingest/logs/new", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				universeId: tostring(game.GameId),
				placeId: tostring(game.PlaceId),
				env: "server",
				jobId: game.JobId,
				message,
				data: data ? HttpService.JSONEncode(data) : undefined,
				level: "crash",
				timestamp: os.time(),
			}),
		});

		if (!response.ok) {
			log.error(`Failed to log message: ${message}`);
		}

		error(`${message} ${HttpService.JSONEncode(data)}`, 2);

		return;
	}

	async warn(message: string, data: unknown): Promise<void> {
		warn(message, data);

		if (!this.token) {
			return;
		}

		const http = new Http(this.token, { apiBase: this.options.apiBase as string });

		const response = await http.apiFetch("ingest/logs/new", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				universeId: tostring(game.GameId),
				placeId: tostring(game.PlaceId),
				env: "server",
				jobId: game.JobId,
				message,
				data: data ? HttpService.JSONEncode(data) : undefined,
				level: "warn",
				timestamp: os.time(),
			}),
		});

		if (!response.ok) {
			log.error(`Failed to log message: ${message}`);
		}

		return;
	}
}
