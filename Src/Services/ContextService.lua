local HttpService = game:GetService("HttpService")

local Console = require(script.Parent.Parent.Packages.Console)

local GetScriptFromFullName = require(script.Parent.Parent.Util.GetScriptFromFullName)

local ContextService = { }

ContextService.Store = { } :: { [Instance]: Context }

ContextService.Priority = 0
ContextService.Reporter = Console.new(`{script.Name}`)

function ContextService.GetContextFor(self: ContextService, sourcePath: string)
    local source = GetScriptFromFullName(sourcePath)

    if not source then
        return { }
    end

    return self.Store[source]
end

function ContextService.CreateContextFor(self: ContextService, sourcePath: string, context: Context)
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

export type ContextService = typeof(ContextService)
export type Context = { [string]: any }

return ContextService