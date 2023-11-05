local Action = require(script.Parent.Parent.API.Action)

return function()
	local ActionA = Action.new({
		Name = "Test Action A",
		Uuid = "test-action-a"
	})
	
	function ActionA:OnRun(...)
		warn("Test Action A, invoked with:", ...)
	end
	
	return ActionA
end