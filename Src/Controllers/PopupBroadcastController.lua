local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network.Client)

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)
local ReactRoblox = require(script.Parent.Parent.Packages.ReactRoblox)
local React = require(script.Parent.Parent.Packages.React)

local PopupBroadcast = require(script.Parent.Parent.Interface.React.PopupBroadcast)

local PopupBroadcastController = { }

PopupBroadcastController.Priority = 0
PopupBroadcastController.Reporter = Console.new(`{script.Name}`)

PopupBroadcastController.Root = ReactRoblox.createRoot(Instance.new("Folder"))

PopupBroadcastController.Queue = { } :: { string }
PopupBroadcastController.QueueCycling = false

function PopupBroadcastController.RenderNotificationAsync(self: PopupBroadcastController, message: string)
	return Promise.new(function(resolve)
		self.Root:render(ReactRoblox.createPortal({
			React.createElement("ScreenGui", {
				IgnoreGuiInset = true,
				Enabled = true,
				DisplayOrder = math.huge,
				ResetOnSpawn = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Name = `MetrikSDK<'PopupBroadcastToast'>`
			}, {
				React.createElement(PopupBroadcast, {
					message = message,

					onMessageShown = function()
						resolve()
					end
				})
			})
		}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	end)
end

function PopupBroadcastController.CycleQueue(self: PopupBroadcastController)
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

function PopupBroadcastController.OnStart(self: PopupBroadcastController)
	Network.BroadcastPopupMessage.SetCallback(function(message: string)
		table.insert(self.Queue, message)

		self:CycleQueue()
	end)
end

export type PopupBroadcastController = typeof(PopupBroadcastController)

return PopupBroadcastController