import { apiFetch } from "./http";
import { HttpService } from "@rbxts/services";
import { Options } from "..";
import { Http } from "./http";

export async function isBanned(userId: number, http: typeof Http.prototype, options: Options) {
	return http
		.apiFetch("moderation/check", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
			},
			body: HttpService.JSONEncode({
				userId: userId,
			}),
		})
		.then((response) => {
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
