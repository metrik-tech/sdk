local React = require(script.Parent.Parent.Parent.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Parent.Parent.Parent.Packages.ReactRoblox)

local component = require(script.Parent)

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(React.createElement(component, {
		message = "START: Hello, World?! Hello, World?! Hello, World?! Hello, World?! Hello, World?! :END"
	}))

	return function()
		root:unmount()
	end
end
