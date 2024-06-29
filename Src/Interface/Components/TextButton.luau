local React = require(script.Parent.Parent.Parent.Packages.React)
local Sift = require(script.Parent.Parent.Parent.Packages.Sift)

local InterfaceTheme = require(script.Parent.Parent.Parent.Data.InterfaceTheme)

local function TextButton(props)
	return React.createElement("TextButton", Sift.Dictionary.merge({
		FontFace = InterfaceTheme.TextFontItalic,
		TextColor3 = InterfaceTheme.Secondary.White,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.5,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, props))
end

return TextButton
