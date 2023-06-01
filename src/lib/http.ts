import { HttpRequest, HttpQueue, HttpRequestPriority } from "@rbxts/http-queue";
import { HttpService } from "@rbxts/services";

type StringDictionary = { [k: string]: string };

interface RequestOptions {
	method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
	headers?: StringDictionary;
	body?: string;
}

const httpQueue = new HttpQueue({
	retryAfter: {
		cooldown: 30,
	},
	maxSimultaneousSendOperations: 10,
});

export async function fetch(url: string, options: RequestOptions) {
	const request = new HttpRequest(url, options.method, options.body, undefined, options.headers);

	const response = await httpQueue.Push(request);

	return {
		status: response.StatusCode,
		statusCode: response.StatusCode,
		ok: response.StatusCode >= 200 && response.StatusCode < 300,
		body: response.Body,
		headers: response.Headers,
		statusText: response.StatusMessage,
	};
}

export async function httpEnabled() {
	// xpcall to https://google.com to see if connected to internet

	const response = await fetch("https://google.com", {
		method: "GET",
	});

	return response.ok;
}
