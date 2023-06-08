import { getDevice } from "../lib/device-type";
import { LocalizationService, LogService, Players } from "@rbxts/services";

export function startClient() {
	const initClient = game.GetService("ReplicatedStorage").WaitForChild("MetrikClientBoundary") as RemoteFunction;
	const messageOutEvent = game
		.GetService("ReplicatedStorage")
		.WaitForChild("MetrikClientMessageOut") as RemoteFunction;

	const device = getDevice();
	const locale = LocalizationService.SystemLocaleId;

	initClient.InvokeServer({
		device,
		locale,
	});

	LogService.MessageOut.Connect((message, messageType) => {
		messageOutEvent.InvokeServer({
			message,
			messageType,
		});
	});
}
