local Roact = require(script.Parent.Parent.Parent.Parent.Packages.Roact)
local Sift = require(script.Parent.Parent.Parent.Parent.Packages.Sift)

local InterfaceTheme = require(script.Parent.Parent.Data.InterfaceTheme)

local TextLabel = Roact.Component:extend("TextLabel")

TextLabel.defaultProps = {
	FontFace = InterfaceTheme.Primary.TextFontItalic,
	TextColor3 = InterfaceTheme.Secondary.White,
	TextScaled = true,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
}

function TextLabel:render()
	local shallowProps = Sift.Dictionary.copy(self.props)

	shallowProps[Roact.Children] = nil

	return Roact.createElement("TextLabel", shallowProps, self.props[Roact.Children])
end

return TextLabel
