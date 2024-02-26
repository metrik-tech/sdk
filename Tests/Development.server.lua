local ServerStorage = game:GetService("ServerStorage")

local MetrikSDK = require(ServerStorage.MetrikSDK)

MetrikSDK:SetAuthenticationToken(ServerStorage.__Secret_Key.Value)
MetrikSDK:InitializeAsync():andThen(function()
	warn("Metrik SDK loaded!")

	local SDKTest0 = MetrikSDK.Action.new({
		Name = "Test Action 0",
		Uuid = "test-action-0",
	})

	function SDKTest0:OnRun(...)
		warn(...)
	end

	local SDKTest1 = MetrikSDK.Action.new({
		Name = "Test Action 1",
		Uuid = "test-action-1",

		Arguments = {
			{
				Name = "message",
				IsRequired = true,
				Type = "String",
				Default = "Default Message!",
			},
		},
	})

	function SDKTest1:OnRun(...)
		warn(...)
	end
end)
