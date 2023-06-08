import { Options } from "..";
import { apiFetch } from "./http";
import { Http } from "./http";

export async function validateToken(http: typeof Http.prototype) {
	const response = http.apiFetch("token/validate", {
		method: "GET",
		headers: {
			"Content-Type": "application/json",
		},
	});

	return response.then((response) => {
		if (response.ok) {
			return true;
		} else {
			return false;
		}
	});
}
