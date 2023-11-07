local Action = require(script.Parent.Parent.API.Action)

return function()
	local ExampleAction = Action.new({
		Name = "Example Development Action",
		Uuid = "example-development-action"
	})
	
	function ExampleAction:OnRun(...)
		warn("Example Development Action, invoked with:", ...)
	end
	
	return ExampleAction
end