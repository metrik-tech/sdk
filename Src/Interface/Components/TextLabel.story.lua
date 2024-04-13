local Roact = require(script.Parent.Parent.Parent.Parent.Packages.Roact)

local TextLabel = require(script.Parent.TextLabel)

return function(target)
	local handle = Roact.mount(Roact.createElement(TextLabel), target)

	return function()
		Roact.unmount(handle)
	end
end
