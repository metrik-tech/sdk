local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)

local GetScriptFromFullName = require(script.Parent.Parent.Util.GetScriptFromFullName)

local Network = require(script.Parent.Parent.Network.Server)

local ContextService = { }

ContextService.Store = { } :: { [Instance]: Context }
ContextService.PlayerStore = { } :: { [Player]: typeof(ContextService.Store) }

ContextService.Priority = 0
ContextService.Reporter = Console.new(`{script.Name}`)

function ContextService.GetContextFor(self: ContextService, player: Player?, sourcePath: string)
    local source = GetScriptFromFullName(sourcePath)

    if not source then
        return { }
    end

    return self.Store[source]
end

function ContextService.CreateContextFor(self: ContextService, player: Player?, sourcePath: string, context: Context)
    local source = GetScriptFromFullName(sourcePath)

    if not source then
        return
    end

    local success, response = pcall(HttpService.JSONEncode, HttpService, context)

    if not success then
        self.Reporter:Error(`Failed to encode context to JSON: {response}`)

        return
    end

    self.Store[source] = context
end

function ContextService.OnStart(self: ContextService)
    Network.CreateContext.SetCallback(function(player: Player, context: { contextJSON: string, sourcePath: string })
        if not ContextService.PlayerStore[player] then
            ContextService.PlayerStore[player] = { }
        end

        self:CreateContextFor(player, context.sourcePath, HttpService:JSONDecode(context.contextJSON))
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        ContextService.PlayerStore[player] = nil
    end)
end
export type ContextService = typeof(ContextService)
export type Context = { [string]: any }

return ContextService