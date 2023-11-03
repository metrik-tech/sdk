local Action = require(script.Parent.Parent.Parent.API.Action)

return function()
	local ActionA = Action.new({
		Name = "Test Action A"
	})
	
	function ActionA:OnActivated()
	
	end
	
	return ActionA
end