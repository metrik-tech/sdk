import { Options } from "..";
import { fetch } from "./http";
import { apiFetch } from "./http";

export function validateToken(token: string, options: Options) {
	const response = apiFetch("https://api.metrik.app/token/validate", {
		method: "GET",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
		apiBase: options.apiBase as string,
	});

	return response.andThen((response) => {
		if (response.ok) {
			return true;
		} else {
			return false;
		}
	});
}
