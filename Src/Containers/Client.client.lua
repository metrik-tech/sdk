local Metrik = require(script.Parent.Parent)

Metrik.Client:InitializeAsync()

return task.defer(script.Parent.Destroy, script.Parent)