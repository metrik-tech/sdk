return {
	Primary = {},

	Secondary = {
		Black = Color3.fromRGB(0, 0, 0),
		LightBlack = Color3.fromRGB(20, 20, 20),
		White = Color3.fromRGB(255, 255, 255),
		Pastel = Color3.fromRGB(236, 232, 216),

		Red = Color3.fromRGB(255, 91, 91),
		Orange = Color3.fromRGB(255, 114, 71)
	},

	Padding = 6,
	CornerRadius = 8,
	OldTopbarCornerRadius = 6,

	HeaderFont = Font.new("rbxassetid://12187375716", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),

	LegacyChatFont = Enum.Font.SourceSansBold,
	LegacyChatFontColor = Color3.fromRGB(255, 255, 255),
	LegacyChatFontSize = 18,

	TextFont = Font.fromName(Enum.Font.BuilderSans.Name, Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	TextFontBold = Font.fromName(Enum.Font.BuilderSans.Name, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	TextFontExtraBold = Font.fromName(Enum.Font.BuilderSans.Name, Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
	TextFontItalic = Font.fromName(Enum.Font.BuilderSans.Name, Enum.FontWeight.Medium, Enum.FontStyle.Italic),
	TextFontBoldItalic = Font.fromName(Enum.Font.BuilderSans.Name, Enum.FontWeight.Bold, Enum.FontStyle.Italic),
}
