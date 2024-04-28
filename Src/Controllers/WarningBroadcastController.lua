local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network.Client)

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)
local ReactRoblox = require(script.Parent.Parent.Packages.ReactRoblox)
local React = require(script.Parent.Parent.Packages.React)

local WarningBroadcast = require(script.Parent.Parent.Interface.React.WarningBroadcast)

local WarningBroadcastController = { }

WarningBroadcastController.Priority = 0
WarningBroadcastController.Reporter = Console.new(`{script.Name}`)

WarningBroadcastController.Root = ReactRoblox.createRoot(Instance.new("Folder"))

WarningBroadcastController.Queue = { } :: { string }
WarningBroadcastController.QueueCycling = false

function WarningBroadcastController.RenderNotificationAsync(self: WarningBroadcastController, message: string)
	return Promise.new(function(resolve)
		self.Reporter:Debug(`Displaying warning message for: '{message}'`)

		local rootInstance = Instance.new("Folder")
		local root = ReactRoblox.createRoot(rootInstance)

		root:render(ReactRoblox.createPortal({
			React.createElement("ScreenGui", {
				IgnoreGuiInset = true,
				Enabled = true,
				DisplayOrder = math.huge,
				ResetOnSpawn = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Name = `MetrikSDK<'WarningBroadcastToast'>`
			}, {
				React.createElement(WarningBroadcast, {
					message = message,

					onMessageShown = function()
						rootInstance:Destroy()
						root:unmount()

						resolve()
					end
				})
			})
		}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	end)
end

function WarningBroadcastController.CycleQueue(self: WarningBroadcastController)
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

function WarningBroadcastController.OnStart(self: WarningBroadcastController)
	Network.BroadcastWarningMessage.SetCallback(function(message: string)
		table.insert(self.Queue, message)

		self:CycleQueue()
	end)
end

export type WarningBroadcastController = typeof(WarningBroadcastController)

return WarningBroadcastController