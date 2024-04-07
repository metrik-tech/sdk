opt server_output = "Src/Network/Server.lua"
opt client_output = "Src/Network/Client.lua"

event LogError = {
	from: Client,
	type: Reliable,
	call: SingleSync,
	data: map {
		[i16]: struct {
			message: string,
			trace: string,
			filePath: string,
		}
	},
}

event BroadcastTopbarMessage = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: string,
}

event BroadcastPopupMessage = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: string,
}