local Players = game:GetService("Players")

local Console = require(script.Parent.Parent.Packages.Console)

local GetScriptFromFullName = require(script.Parent.Parent.Util.GetScriptFromFullName)

local Network = require(script.Parent.Parent.Network.Server)

local BreadcrumbService = { }

BreadcrumbService.Store = { } :: { [Instance]: Breadcrumb }
BreadcrumbService.PlayerStore = { } :: { [Player]: typeof(BreadcrumbService.Store) }

BreadcrumbService.Priority = 0
BreadcrumbService.Reporter = Console.new(`{script.Name}`)

function BreadcrumbService.GetBreadcrumbsFor(self: BreadcrumbService, player: Player?, sourcePath: string): { Breadcrumb }
    local source = GetScriptFromFullName(sourcePath)
    local store = player and self.PlayerStore[player] or self.Store

    if not source then
        return { }
    end

	if not store[source] then
        return { }
    end

    return store[source]
end

function BreadcrumbService.CreateBreadcrumbFor(self: BreadcrumbService, player: Player?, sourcePath: string, message: string)
    local source = GetScriptFromFullName(sourcePath)
    local store = player and self.PlayerStore[player] or self.Store
    local breadcrumbObject = {
        message = message,
        timestamp = DateTime.now():ToIsoDate()
    }

    if not source then
        return
    end

    if not store[source] then
        store[source] = { }
    end

    table.insert(store[source], breadcrumbObject)
end

function BreadcrumbService.OnStart(self: BreadcrumbService)
    Network.CreateBreadcrumb.SetCallback(function(player: Player, breadcrumb: { message: string, sourcePath: string })
        if not BreadcrumbService.PlayerStore[player] then
            BreadcrumbService.PlayerStore[player] = { }
        end

        self:CreateBreadcrumbFor(player, breadcrumb.sourcePath, breadcrumb.message)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        BreadcrumbService.PlayerStore[player] = nil
    end)
end

export type BreadcrumbService = typeof(BreadcrumbService)
export type Breadcrumb = {
    timestamp: string,
    message: string
}

return BreadcrumbService