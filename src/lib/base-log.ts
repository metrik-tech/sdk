import { IOptions } from "..";
import { Http } from "./http";
import { HttpService, RunService } from "@rbxts/services";
import log from "./log";

type LogLevel = "info" | "error" | "warn";
const logLevels = ["info", "error", "warn"];

export async function baseLog(level: LogLevel, token: string, message: string, options: IOptions, data?: unknown) {
	if (token) {
		return;
	}

	if (RunService.IsClient()) {
		return;
	}

	if (!logLevels.find((l) => l === level)) {
		return;
	}

	const http = new Http(token, { apiBase: options.apiBase as string });

	const response = await http.apiFetch("ingest/logs/new", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: HttpService.JSONEncode({
			placeId: tostring(game.PlaceId),
			env: "server",
			jobId: game.JobId,

			message,
			data: data ? HttpService.JSONEncode(data) : undefined,
			level: level,
			timestamp: os.time(),
		}),
	});

	if (!response.ok) {
		log.error(`Failed to log message: ${message}`);
	}

	if (level === "info") {
		print(message, HttpService.JSONEncode(data));
	} else if (level === "error") {
		error(`${message} ${HttpService.JSONEncode(data)}`, 2);
	} else if (level === "warn") {
		warn(message, HttpService.JSONEncode(data));
	}

	return;
}
