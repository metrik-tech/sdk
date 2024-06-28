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

event BroadcastWarningMessage = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: string,
}

event BroadcastToastMessage = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: string,
}

event BroadcastChatMessage = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: string,
}

funct FetchFlagsAsync = {
    call: Sync,
    rets: struct {
		StaticFlags: map {
			[u16]: struct {
				Id: string,
				Name: string,
				Value: string
			}
		},
		DynamicFlags: map {
			[u16]: struct {
				Id: string,
				Name: string,
				Value: string,
				Rules: struct {
					Type: string,
					Parameter: string,
					Operator: string,
					Operand: string,
					Value: string
				}
			}
		}
	}
}