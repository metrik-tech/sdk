return function(message: string)
	message = string.gsub(message, "(\\?)<[^<>]->", { [""] = "" })

	return message
end