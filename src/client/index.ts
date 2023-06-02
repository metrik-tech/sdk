import { getDevice } from "./device-type";
import { LocalizationService, Players } from "@rbxts/services";

export function startClient() {
	const remoteFunction = game.GetService("ReplicatedStorage").WaitForChild("MetrikClientBoundary") as RemoteFunction;

	const device = getDevice();
	const locale = LocalizationService.SystemLocaleId;

	remoteFunction.InvokeServer({
		userId: Players.LocalPlayer.UserId,
		device,
		locale,
	});
}
