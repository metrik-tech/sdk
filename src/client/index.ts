import { getDevice } from "../lib/device-type";
import { LocalizationService, Players } from "@rbxts/services";

export function startClient() {
	const remoteFunction = game.GetService("ReplicatedStorage").WaitForChild("MetrikClientBoundary") as RemoteFunction;

	const device = getDevice();
	const locale = LocalizationService.SystemLocaleId;

	remoteFunction.InvokeServer({
		device,
		locale,
	});
}
