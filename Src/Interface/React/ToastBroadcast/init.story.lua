local React = require(script.Parent.Parent.Parent.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Parent.Parent.Parent.Packages.ReactRoblox)
local State = require(script.Parent.Parent.Parent.Parent.Packages.State)

local component = require(script.Parent)

return function(target)
	local root = ReactRoblox.createRoot(target)
	local notificationPositionState = State.new(1)

	root:render(React.createElement(component, {
		message = "Hello, World! Hello, World! <i>Hello, World!</i> Hello, World! Hello, World! <b>Hello, World!</b>",

		positionalState = notificationPositionState
	}))

	local thread = task.delay(5, function()
		notificationPositionState:Set(6)
	end)

	return function()
		root:unmount()

		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
	end
end
