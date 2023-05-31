import { Options } from ".";

export function startServer(token: string, options: Options) {
	const file = script.Parent?.FindFirstChild("server");

	const newFolder = new Instance("Folder", game.GetService("ServerScriptService"));
	newFolder.Name = "MetrikSDK";

	if (file) {
		file.Parent = newFolder;
	}

	print("startServer");
}
