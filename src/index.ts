import { HttpService, RunService } from "@rbxts/services";
import { startServer } from "./server";
import log from "./lib/log";
import { startClient } from "./client";
import { $package } from "rbxts-transform-debug";
import { validateToken } from "./lib/token";
import { Http } from "./lib/http";
import { baseLog } from "./lib/base-log";

export interface IRequiredOptions {
	debug: boolean;
	sendMetrikLogs: boolean;
	sendClientLogs: boolean;
	clientLogTypes?: ("info" | "warn" | "error")[];
	apiBase: string;
}

export interface IOptions {
	debug?: boolean;
	sendMetrikLogs?: boolean;
	sendClientLogs?: boolean;
	clientLogTypes?: ("info" | "warn" | "error")[];
	apiBase?: string;
}

const defaults: IOptions = {
	debug: false,
	sendMetrikLogs: false,
	sendClientLogs: false,
	apiBase: "https://api.metrik.app",
};

export default class SDK {
	public VERSION = $package.version;
	public API_BASE = "https://api.metrik.app";

	private token: string | undefined;
	private options: IRequiredOptions;

	constructor({ token, options }: { token?: string; options?: IOptions }) {
		this.token = token;

		this.options = defaults as IRequiredOptions;
		if (options) {
			pairs(options)().forEach((optionsValue) => {
				const [key, value] = optionsValue as unknown as [key: keyof IOptions, value: IOptions[keyof IOptions]];

				if (!value) {
					const result: IOptions[keyof IOptions] = defaults[key] as IOptions[keyof IOptions];
					this.options[key] = result as never;
				} else {
					this.options[key] = value as never;
				}
			});
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
		return baseLog("info", this.token as string, message, this.options, data);
	}

	async error(message: string, data: unknown): Promise<void> {
		return baseLog("error", this.token as string, message, this.options, data);
	}

	async warn(message: string, data: unknown): Promise<void> {
		return baseLog("warn", this.token as string, message, this.options, data);
	}
}
