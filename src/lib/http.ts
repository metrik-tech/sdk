import { HttpRequest, HttpQueue, HttpRequestPriority } from "@rbxts/http-queue";
import { HttpService } from "@rbxts/services";

type StringDictionary = { [k: string]: string };

interface RequestOptions {
	method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
	headers?: StringDictionary;
	body?: string;
}

interface RequestAsyncResponse {
	Success: boolean;
	StatusCode: number;
	StatusMessage: string;
	Headers: Record<string, string>;
	Body: string;
}

const httpQueue = new HttpQueue({
	retryAfter: {
		cooldown: 30,
	},
	maxSimultaneousSendOperations: 10,
});

export async function fetchQueue(url: string, options: RequestOptions) {
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

export async function fetch(url: string, options: RequestOptions) {
	const [success, response] = pcall(() =>
		HttpService.RequestAsync({
			Url: url,
			Method: options.method || "GET",
			Headers: options.headers,
			Body: options.body,
		}),
	);

	if (success) {
		return {
			status: response.StatusCode,
			statusCode: response.StatusCode,
			ok: response.StatusCode >= 200 && response.StatusCode < 300,
			body: response.Body,
			headers: response.Headers,
			statusText: response.StatusMessage,
		};
	} else {
		return {
			ok: false,
			statusText: "Request failed",
			status: 0,
			statusCode: 0,
			body: "",
			headers: {},
		};
	}
}

export async function apiFetch(url: string, options: RequestOptions & { apiBase: string }) {
	if (string.match(url, "^/")[0]) {
		url = url.sub(1);
	}

	if (options.apiBase.sub(-1, -1) === "/") {
		options.apiBase = options.apiBase.sub(1);
	}

	const response = await fetch(`${options.apiBase}/${url}`, options);

	return response;
}

export async function httpEnabled() {
	// xpcall to https://google.com to see if connected to internet

	const response = await fetch("https://google.com", {
		method: "GET",
	});

	return response.ok;
}
