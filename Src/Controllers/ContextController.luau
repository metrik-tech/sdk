local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)

local Network = require(script.Parent.Parent.Network.Client)

local ContextController = { }

ContextController.Store = { } :: { [Instance]: Context }

ContextController.Priority = 0
ContextController.Reporter = Console.new(`{script.Name}`)

function ContextController.CreateContextFor(self: ContextController, sourcePath: string, context: Context)
    Network.CreateContext.Fire({
        contextJSON = HttpService:JSONEncode(context),
        sourcePath = sourcePath,
    })
end

export type ContextController = typeof(ContextController)
export type Context = { [string]: any }

return ContextController