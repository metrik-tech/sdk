local TextService = game:GetService("TextService")

local React = require(script.Parent.Parent.Parent.Packages.React)
local ReactSpring = require(script.Parent.Parent.Parent.Packages.ReactSpring)

local InterfaceTheme = require(script.Parent.Parent.Parent.Data.InterfaceTheme)

local TextButton = require(script.Parent.Parent.Components.TextButton)
local TextLabel = require(script.Parent.Parent.Components.TextLabel)

local RemoveRichTextSizeAttribute = require(script.Parent.Parent.Parent.Util.RemoveRichTextSizeAttribute)
local RemoveRichTextAttributes = require(script.Parent.Parent.Parent.Util.RemoveRichTextAttributes)

local PROMPT_MIN_SIZE_X_OFFSET = 200
local PROMPT_SIZE_X_SCALE = 0.5
local BUTTON_SIZE_Y_OFFSET = 30
local PROMPT_TEXT_SIZE = 22

local function PopupBroadcast(properties: {
	message: string,

	onMessageShown: () -> ()
})
	local message = RemoveRichTextSizeAttribute(properties.message)
	local viewportSize = workspace.CurrentCamera.ViewportSize

	local textSize = TextService:GetTextSize(
		RemoveRichTextAttributes(message),
		PROMPT_TEXT_SIZE,
		string.match(InterfaceTheme.TextFont.Family, "/.+/(%S+).json"),
		Vector2.new((viewportSize.X * PROMPT_SIZE_X_SCALE) - (InterfaceTheme.Padding * 2), math.huge)
	)

	if textSize.X < PROMPT_MIN_SIZE_X_OFFSET then
		textSize += Vector2.new(PROMPT_MIN_SIZE_X_OFFSET - textSize.X, 0)
	end

	local rawLineCount = math.ceil(textSize.Y / PROMPT_TEXT_SIZE) + 1
	local lineCount = math.min(rawLineCount, 10)


	local rawSizeY = (rawLineCount * (PROMPT_TEXT_SIZE + 2)) - InterfaceTheme.Padding
	local sizeY = (lineCount * (PROMPT_TEXT_SIZE + 2)) + InterfaceTheme.Padding

	local isAnimatingOut = false

	local buttonTransparencyHook, buttonTransparencyApi = ReactSpring.useSpring(function()
		return {
			from = { progress = 0.75 },
			to = { progress = 0.75 },
		}
	end)

	local inAnimationHook, inAnimationApi = ReactSpring.useSpring(function()
		return {
			from = { progress = 0 },
			to = { progress = 0 },
		}
	end)

	local function animationIn()
		inAnimationApi.start({
			progress = 1,
	
			config = {
				easing = ReactSpring.easings.easeOutBack,
	
				duration = 0.3,
			}
		})
	end

	local function animationOut()
		if isAnimatingOut then
			return
		end

		isAnimatingOut = true

		inAnimationApi.start({
			progress = 0,
	
			config = {
				easing = ReactSpring.easings.easeInBack,
	
				duration = 0.3,
			}
		})

		task.wait(0.3)

		if properties.onMessageShown then
			properties.onMessageShown()
		end
	end

	animationIn()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = inAnimationHook.progress:map(function(value)
			return UDim2.fromOffset(textSize.X * value, sizeY + (BUTTON_SIZE_Y_OFFSET + InterfaceTheme.Padding))
		end),
	}, {
		backgroundFrame = React.createElement("CanvasGroup", {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = InterfaceTheme.Secondary.Black,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.5
		}, {
			uiGradient = React.createElement("UIGradient", {
				Transparency = inAnimationHook.progress:map(function(value)
					return NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1 - value),
						NumberSequenceKeypoint.new(1, 1 - value),
					})
				end),
			}),

			uiCorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, InterfaceTheme.Padding)
			}),

			uiPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, InterfaceTheme.Padding),
				PaddingRight = UDim.new(0, InterfaceTheme.Padding),
				PaddingTop = UDim.new(0, InterfaceTheme.Padding),
				PaddingBottom = UDim.new(0, InterfaceTheme.Padding)
			}),

			closeButton = React.createElement(TextButton, {
				Text = "CLOSE",
				FontFace = InterfaceTheme.TextFontBold,
				BackgroundColor3 = InterfaceTheme.Secondary.LightBlack,
				Size = UDim2.new(1, 0, 0, BUTTON_SIZE_Y_OFFSET),
				Position = UDim2.new(0, 0, 1, -BUTTON_SIZE_Y_OFFSET),
				AnchorPoint = Vector2.new(0, 0),
				AutoButtonColor = false,
				BorderSizePixel = 0,
				BackgroundTransparency = buttonTransparencyHook.progress:map(function(value)
					return value
				end),
				
				[React.Event.MouseEnter] = function()
					buttonTransparencyApi.start({
						progress = 0.45,
				
						config = {
							easing = ReactSpring.easings.easeInQuad,
				
							duration = 0.1,
						}
					})
				end,

				[React.Event.MouseLeave] = function()
					buttonTransparencyApi.start({
						progress = 0.75,
				
						config = {
							easing = ReactSpring.easings.easeInQuad,
				
							duration = 0.1,
						}
					})
				end,

				[React.Event.MouseButton1Down] = function()
					buttonTransparencyApi.start({
						progress = 0.3,
				
						config = {
							easing = ReactSpring.easings.easeInQuad,
				
							duration = 0.05,
						}
					})
				end,

				[React.Event.MouseButton1Up] = function()
					buttonTransparencyApi.start({
						progress = 0.45,
				
						config = {
							easing = ReactSpring.easings.easeInQuad,
				
							duration = 0.05,
						}
					})
				end,

				[React.Event.Activated] = function()
					animationOut()
				end
			}, {
				uiCorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, InterfaceTheme.Padding - 2)
				}),

				uiPadding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, InterfaceTheme.Padding),
					PaddingRight = UDim.new(0, InterfaceTheme.Padding),
					PaddingTop = UDim.new(0, InterfaceTheme.Padding),
					PaddingBottom = UDim.new(0, InterfaceTheme.Padding)
				}),
			}),

			promptScrollbar = React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -BUTTON_SIZE_Y_OFFSET - InterfaceTheme.Padding),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				CanvasSize = UDim2.fromScale(0, 0),
				BorderSizePixel = 0,
				ScrollBarThickness = InterfaceTheme.Padding - 2,
				ScrollBarImageColor3 = InterfaceTheme.Secondary.LightBlack,
				ScrollBarImageTransparency = 0.5,
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				AutomaticCanvasSize = Enum.AutomaticSize.Y
			}, {
				promptMessage = React.createElement(TextLabel, {
					Text = message,
					FontFace = InterfaceTheme.TextFont,
					BackgroundColor3 = InterfaceTheme.Secondary.LightBlack,
					TextScaled = false,
					TextSize = PROMPT_TEXT_SIZE,
					RichText = true,
					Size = UDim2.new(1, 0, 0, rawSizeY),
					Position = UDim2.fromScale(0, 0),
					BorderSizePixel = 0,
					BackgroundTransparency = 0.75, 
	
					AnchorPoint = Vector2.new(0, 0),
				}, {
					UICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, InterfaceTheme.Padding - 2)
					})
				})
			}),
		})
	})
end

return PopupBroadcast