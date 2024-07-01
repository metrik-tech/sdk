local Console = require(script.Parent.Parent.Packages.Console)

local Network = require(script.Parent.Parent.Network.Client)

local MAX_MESSAGE_LENGTH = 512
local MAX_SOURCE_LENGTH = 256

local BreadcrumbController = { }

BreadcrumbController.Store = { } :: { [Instance]: Breadcrumb }

BreadcrumbController.Priority = 0
BreadcrumbController.Reporter = Console.new(`{script.Name}`)

function BreadcrumbController.CreateBreadcrumbFor(self: BreadcrumbController, sourcePath: string, message: string)
    assert(#message < MAX_MESSAGE_LENGTH, `Message is too long (max length is ${MAX_MESSAGE_LENGTH})`)
    assert(#sourcePath < MAX_SOURCE_LENGTH, `Source path is too long (max length is ${MAX_SOURCE_LENGTH})`)

    Network.CreateBreadcrumb.Fire({
        message = message,
        sourcePath = sourcePath,
    })
end

export type BreadcrumbController = typeof(BreadcrumbController)
export type Breadcrumb = {
    timestamp: string,
    message: string
}

return BreadcrumbController