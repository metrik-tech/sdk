local Console = require(script.Parent.Parent.Packages.Console)

local GetScriptFromFullName = require(script.Parent.Parent.Util.GetScriptFromFullName)

local BreadcrumbService = { }

BreadcrumbService.Store = { } :: { [Instance]: Breadcrumb }

BreadcrumbService.Priority = 0
BreadcrumbService.Reporter = Console.new(`{script.Name}`)

function BreadcrumbService.GetBreadcrumbsFor(self: BreadcrumbService, sourcePath: string): { Breadcrumb }
    local source = GetScriptFromFullName(sourcePath)

    if not source then
        return { }
    end

	if not self.Store[source] then
        return { }
    end

    return self.Store[source]
end

function BreadcrumbService.CreateBreadcrumbFor(self: BreadcrumbService, sourcePath: string, message: string)
    local source = GetScriptFromFullName(sourcePath)
    local breadcrumbObject = {
        message = message,
        timestamp = DateTime.now():ToIsoDate()
    }

    if not source then
        return
    end

    if not self.Store[source] then
        self.Store[source] = { }
    end

    table.insert(self.Store[source], breadcrumbObject)
end

export type BreadcrumbService = typeof(BreadcrumbService)
export type Breadcrumb = {
    timestamp: string,
    message: string
}

return BreadcrumbService