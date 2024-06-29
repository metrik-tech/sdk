local StarterGui = game:GetService("StarterGui")

local Promise = require(script.Parent.Parent.Packages.Promise)

return function(...)
	local setCoreParameters = { ... }

	return Promise.new(function(resolve)
		local success
		local response

		while not success do
			success, response = pcall(StarterGui.SetCore, StarterGui, table.unpack(setCoreParameters))

			if not success then
				warn(response)
			end

			task.wait(0.5)
		end

		return resolve()
	end)
end