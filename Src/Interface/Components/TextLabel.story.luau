local React = require(script.Parent.Parent.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Parent.Parent.Packages.ReactRoblox)

local component = require(script.Parent.TextLabel)

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(React.createElement(component, {
		Text = "Hello, World!",
		Size = UDim2.fromScale(1, 1)
	}))

	return function()
		root:unmount()
	end
end
