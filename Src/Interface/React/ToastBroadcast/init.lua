local TextService = game:GetService("TextService")

local React = require(script.Parent.Parent.Parent.Packages.React)
local State = require(script.Parent.Parent.Parent.Packages.State)
local ReactSpring = require(script.Parent.Parent.Parent.Packages.ReactSpring)

local InterfaceTheme = require(script.Parent.Parent.Parent.Data.InterfaceTheme)

local TextLabel = require(script.Parent.Parent.Components.TextLabel)

local RemoveRichTextSizeAttribute = require(script.Parent.Parent.Parent.Util.RemoveRichTextSizeAttribute)
local RemoveRichTextAttributes = require(script.Parent.Parent.Parent.Util.RemoveRichTextAttributes)

local VIEWPORT_SIZE = workspace.CurrentCamera.ViewportSize

local BASE_BROADCAST_SIZE = UDim2.fromOffset(50, 75)
local BASE_POSITION_UDIM = UDim2.new(
	0,
	InterfaceTheme.Padding,
	0,
	VIEWPORT_SIZE.Y - (BASE_BROADCAST_SIZE.Y.Offset + InterfaceTheme.Padding)
)

local BROADCAST_TEXT_SIZE = 22
local BROADCAST_TEXT_PADDING = 12

local function ToastBroadcast(properties: {
	message: string,

	positionalState: typeof(State.new()),

	onMessageShown: () -> ()
})
	local message = RemoveRichTextSizeAttribute(properties.message)

	local position, setPosition = React.useState(BASE_POSITION_UDIM)

	local hasAnimatedOut = false
	local hasAnimatedIn = false

	local inAnimationHook, inAnimationApi = ReactSpring.useSpring(function()
		return {
			from = { progress = 0 },
			to = { progress = 0 },
		}
	end)

	local textSize = TextService:GetTextSize(
		RemoveRichTextAttributes(message),
		BROADCAST_TEXT_SIZE,
		string.match(InterfaceTheme.TextFont.Family, "/.+/(%S+).json"),
		Vector2.new(math.huge, math.huge)
	)

	local sizeXOffset = textSize.X

	local function animationIn()
		if hasAnimatedIn then
			return
		end

		hasAnimatedIn = true

		inAnimationApi.start({
			progress = 1,
	
			config = {
				easing = ReactSpring.easings.easeOutBack,
	
				duration = 0.4,
			}
		})
	end

	local function animationOut()
		if hasAnimatedOut then
			return
		end

		hasAnimatedOut = true

		inAnimationApi.start({
			progress = 0,
	
			config = {
				easing = ReactSpring.easings.easeOutBack,
	
				duration = 1,
			}
		})

		task.delay(1, function()
			if not properties.onMessageShown then
				return
			end

			properties.onMessageShown()
		end)
	end

	properties.positionalState.Changed:Connect(function(value)
		if value > 5 then
			animationOut()
		else
			setPosition(BASE_POSITION_UDIM - UDim2.fromOffset(0, (BASE_BROADCAST_SIZE.Height.Offset + InterfaceTheme.Padding) * (value - 1)))
		end
	end)

	animationIn()

	return React.createElement("Frame", {
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),

		Size = BASE_BROADCAST_SIZE + UDim2.fromOffset(sizeXOffset, 0),
		Position = inAnimationHook.progress:map(function(value)
			return position - UDim2.fromScale(1 - value, 0)
		end),
	}, {
		UIPadding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, InterfaceTheme.Padding)
		}),

		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, InterfaceTheme.Padding)
		}),

		titleMessage = React.createElement(TextLabel, {
			Size = UDim2.fromScale(1, 0.4),
			Text = "Alert",
			FontFace = InterfaceTheme.TextFont,
			BackgroundColor3 = InterfaceTheme.Secondary.LightBlack,
			TextScaled = true,
			RichText = true,
			Position = UDim2.fromScale(0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,

			AnchorPoint = Vector2.new(0, 0),
		}, {
			uiPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, BROADCAST_TEXT_PADDING),
				PaddingRight = UDim.new(0, BROADCAST_TEXT_PADDING),
				PaddingTop = UDim.new(0, BROADCAST_TEXT_PADDING),
			}),
		}),

		Label = React.createElement(TextLabel, {
			Text = message,
			FontFace = InterfaceTheme.TextFont,
			Size = UDim2.fromScale(1, 0.6),
			Position = UDim2.fromScale(0.5, 0.65),
			RichText = true,
			TextScaled = false,
			TextSize = BROADCAST_TEXT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, {
			UIPadding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, BROADCAST_TEXT_PADDING),
				PaddingRight = UDim.new(0, BROADCAST_TEXT_PADDING),
				PaddingTop = UDim.new(0, BROADCAST_TEXT_PADDING),
				PaddingBottom = UDim.new(0, BROADCAST_TEXT_PADDING)
			}),
		})
	})
end

return ToastBroadcast