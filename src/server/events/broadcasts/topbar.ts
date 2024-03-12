import { IBroadcast, IData } from "../..";
import { Http } from "../../../lib/http";
import Icon from "@rbxts/topbar-plus";

export function broadcastTopbar(broadcast: IBroadcast) {
	const icon = new Icon();

	icon.setLabel(broadcast.message);
	icon.setMid();

	task.wait(broadcast.duration / 1000);

	icon.destroy();
}
