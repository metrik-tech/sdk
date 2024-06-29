local Metrik = require(script.Parent.Parent)

Metrik.Client:InitializeAsync():andThen(function()
	script.Parent:Destroy()
end)