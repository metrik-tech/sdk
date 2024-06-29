--[[
	Given "Hello: <font size="22"> World! </font>", the output will be: "Hello: <font > World! </font>"
]]

return function(message: string)
	message = string.gsub(message, "\\?<[^<>]->", function(source)
		source = string.gsub(source, "%S+=\"%d+\"", "")

		return source
	end)

	return message
end