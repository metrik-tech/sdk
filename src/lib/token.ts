import { Options } from "..";
import { apiFetch } from "./http";

export function validateToken(token: string, options: Options) {
	const response = apiFetch("token/validate", {
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
