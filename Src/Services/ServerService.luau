local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)

local ServerAction = require(script.Parent.Parent.Enums.ServerAction)

local MessageReceiveService = require(script.Parent.MessageReceiveService)
local ApiService = require(script.Parent.ApiService)

local ServerService = { }

ServerService.Priority = 0
ServerService.Reporter = Console.new(`{script.Name}`)

function ServerService.ShutdownLocalServer(self: ServerService)
    self.Reporter:Log(`Shutdown requested on the Local server, reserving server...`)

    local reservedServerAccessCode = TeleportService:ReserveServer(game.PlaceId)
            
    local teleportOptions = Instance.new("TeleportOptions")
    local teleportGroups = {}

    local players = Players:GetPlayers()

    self.Reporter:Log(`Server '{reservedServerAccessCode}' reserved, teleporting players...`)

    for _, player: Player in players do
        if not teleportGroups[#teleportGroups] then
            teleportGroups[#teleportGroups] = {}
        end

        if teleportGroups[#teleportGroups] + 1 > 50 then
            teleportGroups[#teleportGroups + 1] = {}
        end

        table.insert(teleportGroups[#teleportGroups], player)
    end

    teleportOptions.ReservedServerAccessCode = reservedServerAccessCode
    teleportOptions:SetTeleportData({ IS_METRIK_TELEPORT = true })

    for _, playerTeleportGroup in teleportGroups do
        TeleportService:TeleportAsync(game.PlaceId, playerTeleportGroup, teleportOptions)
    end

    self.Reporter:Log(`All players teleported, adding '.PlayerAdded' hook for teleporting new players.`)

    Players.PlayerAdded:Connect(function(player: Player)
        TeleportService:TeleportAsync(game.PlaceId, { player }, teleportOptions)
    end)
end

function ServerService.OnStart(self: ServerService)
	MessageReceiveService.OnServers:Connect(function(data: ServerPacket)
        if data.action == ServerAction.Shutdown then
            if data.serverId ~= ApiService.JobId then
                return
            end

            self:ShutdownLocalServer()
        else
            self.Reporter:Warn(`Unknown action type for Server: {data.action}`)
        end
    end)
end

function ServerService.OnInit(self: ServerService)
    local isReservedServer = game.VIPServerId ~= ""

    if not isReservedServer then
        return
    end

    self.Reporter:Log(`Server is reserved, Metrik will re-direct players who teleport in with a specific JoinData.`)
    
    Players.PlayerAdded:Connect(function(player: Player)
        local playerJoinData = player:GetJoinData()
        local playerTeleportData = playerJoinData.TeleportData
        
        if playerTeleportData.IS_METRIK_TELEPORT then
            self.Reporter:Log(`Player '{player.Name}' is a Metrik teleporter, teleporting them to an updated server...`)

            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end

export type ServerService = typeof(ServerService)
export type ServerPacket = {
    action: string,
    serverId: string?,
}

return ServerService