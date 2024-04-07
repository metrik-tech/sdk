local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

local React = require(script.Parent.Parent.Parent.Packages.React)
local ReactSpring = require(script.Parent.Parent.Parent.Packages.ReactSpring)

local InterfaceTheme = require(script.Parent.Parent.Parent.Data.InterfaceTheme)

local TextLabel = require(script.Parent.Parent.Components.TextLabel)

local RemoveRichTextSizeAttribute = require(script.Parent.Parent.Parent.Util.RemoveRichTextSizeAttribute)
local RemoveRichTextAttributes = require(script.Parent.Parent.Parent.Util.RemoveRichTextAttributes)

local MAX_SIZE_X = 450

local function lerp(a, b, t)
	return (a + (b - a) * t);
end

local function TopbarBroadcast(properties: {
	message: string,

	onMessageShown: () -> ()
})
	local message = RemoveRichTextSizeAttribute(properties.message)
	local insetSizeY = math.max(GuiService:GetGuiInset().Y, 36)
	local isOldTopbar = insetSizeY == 36

	local topbarPositionPadding = isOldTopbar and 4 or 12

	local textSizeY = insetSizeY == 36 and 20 or insetSizeY - 36
	local textSizeX = TextService:GetTextSize(
		RemoveRichTextAttributes(message),
		textSizeY,
		string.match(InterfaceTheme.TextFont.Family, "/.+/(%S+).json"),
		Vector2.new(math.huge, math.huge)
	).X

	local backgroundSizeX = textSizeX > MAX_SIZE_X and MAX_SIZE_X or textSizeX + InterfaceTheme.Padding * 2

	local inAnimationHook, inAnimationApi = ReactSpring.useSpring(function()
		return {
			from = { progress = 0 },
			to = { progress = 0 },
		}
	end)

	local scrollingAnimationHook, scrollingAnimationApi = ReactSpring.useSpring(function()
		return {
			from = { progress = 0 },
			to = { progress = 0 },
		}
	end)

	local function animationIn()
		inAnimationApi.start({
			progress = 1,
	
			config = {
				easing = ReactSpring.easings.easeInOutBack,
	
				duration = 1,
			}
		})
	end

	local function animationOut()
		inAnimationApi.start({
			progress = 0,
	
			config = {
				easing = ReactSpring.easings.easeInBack,
	
				duration = 1,
			}
		})

		task.wait(1)

		if properties.onMessageShown then
			properties.onMessageShown()
		end
	end

	if textSizeX > MAX_SIZE_X then
		task.delay(5, function()
			-- after 5 seconds, start panning to the right-hand side!

			local messageDuration = #message * 0.025

			scrollingAnimationApi.start({
				progress = 1,

				config = {
					easing = ReactSpring.easings.easeInOutQuad,

					duration = messageDuration,
				}
			})

			task.wait(messageDuration + 2.5)

			animationOut()
		end)
	else
		task.delay(5, animationOut)
	end

	animationIn()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,

		Size = UDim2.new(1, 0, 0, insetSizeY - topbarPositionPadding),
		Position = UDim2.new(0, 0, 0, topbarPositionPadding)
	}, {
		backgroundFrame = React.createElement("Frame", {
			Size = inAnimationHook.progress:map(function(value)
				return UDim2.new(0, backgroundSizeX * value, 1  * math.min(value + 0.75, 1), 0) 
			end),

			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = InterfaceTheme.Secondary.Black,
			BackgroundTransparency = inAnimationHook.progress:map(function(value)
				return 1 - (0.7 * value)
			end)
		}, {
			UICorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(isOldTopbar and 0 or 1, InterfaceTheme.Padding)
			}),

			canvasGroupFrame = React.createElement("CanvasGroup", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				uiGradient = React.createElement("UIGradient", {
					Transparency = inAnimationHook.progress:map(function(value)
						return NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.05, lerp(1, 0, value)),
							NumberSequenceKeypoint.new(0.95, lerp(1, 0, value)),
							NumberSequenceKeypoint.new(1, 1),
						})
					end),
				}),

				contentScrollFrame = React.createElement("ScrollingFrame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollingEnabled = false,
					CanvasSize = UDim2.fromScale(0, 0),
					ScrollBarThickness = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.X,
					CanvasPosition = scrollingAnimationHook.progress:map(function(value)
						return Vector2.new((textSizeX + (InterfaceTheme.Padding * 2) - backgroundSizeX) * value, 0)
					end),
				}, {
					uiPadding = React.createElement("UIPadding", {
						PaddingRight = UDim.new(0, InterfaceTheme.Padding),
						PaddingLeft = UDim.new(0, InterfaceTheme.Padding)
					}),
	
					textContent = React.createElement(TextLabel, {
						Text = message,
						Size = UDim2.new(0, textSizeX, 1, 0),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0, 0),
						AnchorPoint = Vector2.new(0, 0),
						FontFace = InterfaceTheme.TextFont,
						TextColor3 = InterfaceTheme.Secondary.White,
						TextSize = textSizeY,
						RichText = true,
						TextXAlignment = Enum.TextXAlignment.Center
					})
				})
			}),
		})
	})
end

return TopbarBroadcast