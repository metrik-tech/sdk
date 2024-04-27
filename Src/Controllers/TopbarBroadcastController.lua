local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network.Client)

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)
local ReactRoblox = require(script.Parent.Parent.Packages.ReactRoblox)
local React = require(script.Parent.Parent.Packages.React)

local TopbarBroadcast = require(script.Parent.Parent.Interface.React.TopbarBroadcast)

local TopbarBroadcastController = { }

TopbarBroadcastController.Priority = 0
TopbarBroadcastController.Reporter = Console.new(`{script.Name}`)

TopbarBroadcastController.Root = ReactRoblox.createRoot(Instance.new("Folder"))

TopbarBroadcastController.Queue = { } :: { string }
TopbarBroadcastController.QueueCycling = false

function TopbarBroadcastController.RenderNotificationAsync(self: TopbarBroadcastController, message: string)
	return Promise.new(function(resolve)
		self.Reporter:Debug(`Displaying topbar message for: '{message}'`)

		self.Root:render(ReactRoblox.createPortal({
			React.createElement("ScreenGui", {
				IgnoreGuiInset = true,
				Enabled = true,
				DisplayOrder = math.huge,
				ResetOnSpawn = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Name = `MetrikSDK<'TopbarBroadcastToast'>`
			}, {
				React.createElement(TopbarBroadcast, {
					message = message,
		
					onMessageShown = function()
						task.wait(0.5)
		
						self.Root:unmount()
		
						resolve()
					end
				})
			})
		}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	end)
end

function TopbarBroadcastController.CycleQueue(self: TopbarBroadcastController)
	if self.QueueCycling then
		return
	end

	self.QueueCycling = true

	repeat
		local object = table.remove(self.Queue)

		self:RenderNotificationAsync(object):await()
	until #self.Queue == 0

	self.QueueCycling = false
end

function TopbarBroadcastController.OnStart(self: TopbarBroadcastController)
	Network.BroadcastTopbarMessage.SetCallback(function(message: string)
		table.insert(self.Queue, message)

		self:CycleQueue()
	end)
end

export type TopbarBroadcastController = typeof(TopbarBroadcastController)

return TopbarBroadcastController