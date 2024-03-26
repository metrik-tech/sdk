local Console = require(script.Parent.Parent.Packages.Console)

local ExampleController = { }

ExampleController.Priority = 0
ExampleController.Reporter = Console.new(`{script.Name}`)

function ExampleController.OnStart(self: ExampleController)
	self.Reporter:Debug(`Hello from '{script.Name}::OnStart'`)
end

function ExampleController.OnInit(self: ExampleController)
	self.Reporter:Debug(`Hello from '{script.Name}::OnInit'`)
end

export type ExampleController = typeof(ExampleController)

return ExampleController