local React = require(script.Parent.Parent.Parent.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Parent.Parent.Parent.Packages.ReactRoblox)

local component = require(script.Parent)

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(React.createElement(component, {
		message = "Hello, World! <i><b> BOLD! </b></i> <font size=\"200\">Size?</font> AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	}))

	return function()
		root:unmount()
	end
end
