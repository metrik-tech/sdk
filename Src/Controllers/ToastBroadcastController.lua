local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network.Client)

local Console = require(script.Parent.Parent.Packages.Console)
local Promise = require(script.Parent.Parent.Packages.Promise)
local State = require(script.Parent.Parent.Packages.State)
local ReactRoblox = require(script.Parent.Parent.Packages.ReactRoblox)
local React = require(script.Parent.Parent.Packages.React)

local ToastBroadcast = require(script.Parent.Parent.Interface.React.ToastBroadcast)

local TOAST_EXPIRE_AFTER = 5

local ToastBroadcastController = { }

ToastBroadcastController.Priority = 0
ToastBroadcastController.Reporter = Console.new(`{script.Name}`)

ToastBroadcastController.Queue = { } :: { string }
ToastBroadcastController.PositionalStates = { } :: { typeof(State.new()) }
ToastBroadcastController.QueueCycling = false

function ToastBroadcastController.RenderToastAsync(self: ToastBroadcastController, message: string)
	return Promise.new(function(resolve)
		local rootInstance = Instance.new("Folder")
		local root = ReactRoblox.createRoot(rootInstance)

		local state = State.new(1)

		self.Reporter:Debug(`Displaying toast message for: '{message}'`)

		table.insert(self.PositionalStates, 1, state)

		task.delay(TOAST_EXPIRE_AFTER, function()
			state:Set(10)
		end)

		root:render(ReactRoblox.createPortal({
			React.createElement("ScreenGui", {
				IgnoreGuiInset = true,
				Enabled = true,
				DisplayOrder = math.huge,
				ResetOnSpawn = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				Name = `MetrikSDK<'ToastBroadcast'>`
			}, {
				React.createElement(ToastBroadcast, {
					message = message,

					positionalState = state,

					onMessageShown = function()
						local stateIndex = table.find(self.PositionalStates, state)

						if stateIndex then
							table.remove(self.PositionalStates, stateIndex)
						end

						root:unmount()
						rootInstance:Destroy()

						state:Destroy()

						resolve()
					end
				})
			})
		}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	end)
end

function ToastBroadcastController.CycleQueue(self: ToastBroadcastController)
	if self.QueueCycling then
		return
	end

	self.QueueCycling = true

	repeat
		local object = table.remove(self.Queue)

		for _, stateObject in self.PositionalStates do
			stateObject:Increment(1)
		end

		self:RenderToastAsync(object)
	until #self.Queue == 0

	self.QueueCycling = false
end

function ToastBroadcastController.OnStart(self: ToastBroadcastController)
	Network.BroadcastToastMessage.SetCallback(function(message: string)
		table.insert(self.Queue, message)

		self:CycleQueue()
	end)
end

export type ToastBroadcastController = typeof(ToastBroadcastController)

return ToastBroadcastController