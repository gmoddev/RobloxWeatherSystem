return function(helpers, services)
	return {
		Colors = {
			Panel = Color3.fromRGB(12, 15, 20),
			PanelStroke = Color3.fromRGB(80, 90, 105),
			Surface = Color3.fromRGB(18, 22, 28),
			SurfaceRaised = Color3.fromRGB(28, 33, 41),
			Card = Color3.fromRGB(42, 48, 58),-- 35 35 35
			CardOverlay = Color3.fromRGB(0, 0, 0),
			Button = Color3.fromRGB(42, 48, 58),
			ButtonSuccess = Color3.fromRGB(32, 74, 58),
			Danger = Color3.fromRGB(255, 90, 90),
			Track = Color3.fromRGB(26, 31, 39),
			Accent = Color3.fromRGB(92, 164, 255),
			Text = Color3.fromRGB(240, 244, 248),
			TextStrong = Color3.fromRGB(248, 250, 252),
			TextMuted = Color3.fromRGB(145, 155, 170),
			Placeholder = Color3.fromRGB(116, 126, 139),
			InputStroke = Color3.fromRGB(56, 64, 76),
		},

		Fonts = {
			Regular = Enum.Font.Gotham,
			Medium = Enum.Font.GothamMedium,
		},

		Radius = {
			Panel = 8,
			Control = 6,
		},

		TextSize = {
			Title = 18,
			Body = 13,
			Caption = 12,
		},

		Layout = {
			PanelWidth = 360,
			PanelHeight = 620,
			PanelPadding = 14,
			Gap = 12,
			SectionGap = 8,
			ControlHeight = 32,
			HeaderHeight = 44,
		},
	}
end
