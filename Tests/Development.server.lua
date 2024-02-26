local ServerStorage = game:GetService("ServerStorage")

local MetrikSDK = require(ServerStorage.MetrikSDK)

MetrikSDK:SetAuthenticationToken(ServerStorage.__Secret_Key.Value)
MetrikSDK:InitializeAsync():andThen(function()

end)
