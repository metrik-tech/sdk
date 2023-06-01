import { apiFetch } from "./http";
import { HttpService } from "@rbxts/services";
import { Options } from "..";

export async function isBanned(userId: number, token: string, options: Options) {
	return apiFetch("ingest/moderation/check", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
		body: HttpService.JSONEncode({
			userId: userId,
		}),
		apiBase: options.apiBase as string,
	}).andThen((response) => {
		if (response.ok) {
			return undefined;
		} else {
			return {
				reason: "You are banned",
				timestamp: os.time(),
				permanent: false,
				timeRemaining: 24, // hours
			};
		}
	});
}
