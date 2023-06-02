import { VRService, UserInputService, GuiService, Workspace } from "@rbxts/services";

function getViewportSize(): Vector2 {
	if (typeOf(Workspace.CurrentCamera) === "Instance") {
		return Workspace.CurrentCamera?.ViewportSize ?? new Vector2();
	} else {
		return new Vector2();
	}
}

export function getDevice() {
	const hasGamepad = UserInputService.GamepadEnabled;
	const hasTouch = UserInputService.TouchEnabled;
	const hasKeyboard = UserInputService.KeyboardEnabled;

	if (hasGamepad && GuiService.IsTenFootInterface()) {
		return "console";
	} else if (VRService.VREnabled) {
		return "vr";
	} else if (hasTouch && !hasKeyboard) {
		const size = getViewportSize();

		if (size.X >= 1023 && size.Y >= 767) {
			return "tablet";
		} else {
			return "mobile";
		}
	} else if (hasKeyboard) {
		return "desktop";
	}

	return "unknown";
}
