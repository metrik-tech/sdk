import { fetch } from "./http";
import { apiFetch } from "./http";

export function validateToken(token: string) {
	const response = fetch("https://api.metrik.app/ingest/session/start", {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${token}`,
		},
	});
}
