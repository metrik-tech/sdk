opt server_output = "Src/Network/Server.luau"
opt client_output = "Src/Network/Client.luau"
opt remote_scope = "METRIK_SDK"

event LogError = {
	from: Client,
	type: Reliable,
	call: SingleSync,
	data: map {
		[i16]: struct {
			message: string,
			trace: string
		}
	},
}

event CreateContext = {
	from: Client,
	type: Reliable,
	call: SingleSync,
	data: struct {
		contextJSON: string,
		sourcePath: string,
	}
}

event CreateBreadcrumb = {
	from: Client,
	type: Unreliable,
	call: SingleSync,
	data: struct {
		message: string(..512),
		sourcePath: string(..256),
	}
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