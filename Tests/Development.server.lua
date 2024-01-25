local ServerStorage = game:GetService("ServerStorage")

local MetrikSDK = require(ServerStorage.MetrikSDK)

MetrikSDK:SetAuthenticationToken(ServerStorage.__Secret_Key.Value)
MetrikSDK:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")

	-- local MetrikSDKTestAction = MetrikSDK.Action.new({
	-- 	Name = "Test Action",
	-- 	Uuid = "testAction",

	-- 	-- Arguments = {
	-- 	-- 	{
	-- 	-- 		Name = "test",
	-- 	-- 		IsRequired = true,
	-- 	-- 		Type = "String",
	-- 	-- 		Default = "",
	-- 	-- 	},
	-- 	-- },
	-- })

	-- function MetrikSDKTestAction:OnRun(...)
	-- 	warn(...)
	-- end
end)
