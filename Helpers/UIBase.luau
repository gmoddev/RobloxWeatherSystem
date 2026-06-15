return function(helpersOrServices, servicesOrTheme, ThemeOverride)
	local helpers = {}
	local services = helpersOrServices

	if not services.UserInputService then
		helpers = helpersOrServices or {}
		services = servicesOrTheme
	else
		ThemeOverride = servicesOrTheme
	end

	local UserInputService = services.UserInputService

	local function ResolveTheme(ThemeSource: any?)
		if typeof(ThemeSource) == "Instance" and ThemeSource:IsA("ModuleScript") then
			ThemeSource = require(ThemeSource)
		end

		if type(ThemeSource) == "function" then
			return ThemeSource(helpers, services)
		end

		return ThemeSource
	end

	local Theme = ResolveTheme(ThemeOverride or helpers.Theme)
	if not Theme then
		local ThemeModule = script.Parent:FindFirstChild("Theme") or script.Parent.Parent:FindFirstChild("Theme")
		Theme = ResolveTheme(ThemeModule)
	end

	local UIBase = {
		Theme = Theme,
	}

	local function CreateCorner(Parent, Radius)
		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, Radius)
		Corner.Parent = Parent
		return Corner
	end

	local function CreateStroke(Parent, Color, Transparency)
		local Stroke = Instance.new("UIStroke")
		Stroke.Color = Color
		Stroke.Transparency = Transparency or 0
		Stroke.Parent = Parent
		return Stroke
	end

	local function FormatNumber(Value)
		return string.format("%.2f", Value)
	end

	function UIBase:FormatNumber(Value)
		return FormatNumber(Value)
	end

	function UIBase:Corner(Parent, Radius)
		return CreateCorner(Parent, Radius)
	end

	function UIBase:Stroke(Parent, Color, Transparency)
		return CreateStroke(Parent, Color, Transparency)
	end

	function UIBase:Label(Parent, Text, Size, Color)
		local Label = Instance.new("TextLabel")
		Label.BackgroundTransparency = 1
		Label.Font = Theme.Fonts.Medium
		Label.Text = Text
		Label.TextColor3 = Color or Theme.Colors.Text
		Label.TextSize = Size or Theme.TextSize.Body
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.TextYAlignment = Enum.TextYAlignment.Center
		Label.Parent = Parent
		return Label
	end

	function UIBase:Button(Parent, Text, Callback, Color)
		local Button = Instance.new("TextButton")
		Button.AutoButtonColor = true
		Button.BackgroundColor3 = Color or Theme.Colors.Button
		Button.BorderSizePixel = 0
		Button.Font = Theme.Fonts.Medium
		Button.Size = UDim2.new(1, 0, 0, Theme.Layout.ControlHeight)
		Button.Text = Text
		Button.TextColor3 = Theme.Colors.Text
		Button.TextSize = Theme.TextSize.Body
		Button.Parent = Parent
		CreateCorner(Button, Theme.Radius.Control)

		if Callback then
			Button.Activated:Connect(Callback)
		end

		return Button
	end

	function UIBase:Input(Parent, Placeholder, Text)
		local Input = Instance.new("TextBox")
		Input.BackgroundColor3 = Theme.Colors.Surface
		Input.BorderSizePixel = 0
		Input.ClearTextOnFocus = false
		Input.Font = Theme.Fonts.Regular
		Input.PlaceholderColor3 = Theme.Colors.Placeholder
		Input.PlaceholderText = Placeholder
		Input.Size = UDim2.new(1, 0, 0, Theme.Layout.ControlHeight)
		Input.Text = Text or ""
		Input.TextColor3 = Theme.Colors.Text
		Input.TextSize = Theme.TextSize.Body
		Input.Parent = Parent
		CreateCorner(Input, Theme.Radius.Control)
		CreateStroke(Input, Theme.Colors.InputStroke, 0.25)
		return Input
	end

	function UIBase:Section(Parent, Title)
		local Section = Instance.new("Frame")
		Section.AutomaticSize = Enum.AutomaticSize.Y
		Section.BackgroundTransparency = 1
		Section.Size = UDim2.new(1, 0, 0, 0)
		Section.Parent = Parent

		local Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, Theme.Layout.SectionGap)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Section

		if Title then
			local Header = self:Label(Section, Title, Theme.TextSize.Caption, Theme.Colors.TextMuted)
			Header.Size = UDim2.new(1, 0, 0, 20)
		end

		return Section
	end

	function UIBase:Panel(Gui, Options)
		Options = Options or {}

		local Panel = Instance.new("Frame")
		Panel.AnchorPoint = Options.AnchorPoint or Vector2.new(1, 0.5)
		Panel.BackgroundColor3 = Theme.Colors.Panel
		Panel.BorderSizePixel = 0
		Panel.Position = Options.Position or UDim2.new(1, -24, 0.5, 0)
		Panel.Size = Options.Size or UDim2.new(0, Theme.Layout.PanelWidth, 0, Theme.Layout.PanelHeight)
		Panel.Parent = Gui
		CreateCorner(Panel, Theme.Radius.Panel)
		CreateStroke(Panel, Theme.Colors.PanelStroke, 0.35)

		local Padding = Instance.new("UIPadding")
		Padding.PaddingBottom = UDim.new(0, Theme.Layout.PanelPadding)
		Padding.PaddingLeft = UDim.new(0, Theme.Layout.PanelPadding)
		Padding.PaddingRight = UDim.new(0, Theme.Layout.PanelPadding)
		Padding.PaddingTop = UDim.new(0, Theme.Layout.PanelPadding)
		Padding.Parent = Panel

		local Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, Theme.Layout.Gap)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Panel

		return Panel
	end

	function UIBase:Header(Parent, TitleText, SubtitleText, CloseCallback)
		local Header = Instance.new("Frame")
		Header.BackgroundTransparency = 1
		Header.Size = UDim2.new(1, 0, 0, Theme.Layout.HeaderHeight)
		Header.Parent = Parent

		local Title = self:Label(Header, TitleText, Theme.TextSize.Title, Theme.Colors.TextStrong)
		Title.Size = UDim2.new(1, -40, 0, 24)

		local Subtitle = self:Label(Header, SubtitleText or "", Theme.TextSize.Caption, Theme.Colors.TextMuted)
		Subtitle.Position = UDim2.new(0, 0, 0, 24)
		Subtitle.Size = UDim2.new(1, -40, 0, 18)

		local Close = self:Button(Header, "X", CloseCallback, Theme.Colors.SurfaceRaised)
		Close.AnchorPoint = Vector2.new(1, 0)
		Close.Position = UDim2.new(1, 0, 0, 0)
		Close.Size = UDim2.new(0, 32, 0, 32)

		return Header, Subtitle, Close
	end

	function UIBase:ScrollBody(Parent)
		local Body = Instance.new("ScrollingFrame")
		Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Body.BackgroundTransparency = 1
		Body.BorderSizePixel = 0
		Body.CanvasSize = UDim2.new(0, 0, 0, 0)
		Body.ScrollBarImageColor3 = Theme.Colors.Accent
		Body.ScrollBarThickness = 4
		Body.Size = UDim2.new(1, 0, 1, -(Theme.Layout.HeaderHeight + Theme.Layout.Gap))
		Body.Parent = Parent

		local Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, Theme.Layout.Gap)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Body

		return Body
	end

	function UIBase:Grid(Parent, Rows, Columns)
		local Grid = Instance.new("Frame")
		Grid.BackgroundTransparency = 1
		Grid.Size = UDim2.new(1, 0, 0, Rows * Theme.Layout.ControlHeight + math.max(Rows - 1, 0) * 6)
		Grid.Parent = Parent

		local Layout = Instance.new("UIGridLayout")
		Layout.CellPadding = UDim2.new(0, 6, 0, 6)
		Layout.CellSize = UDim2.new(1 / Columns, -5, 0, Theme.Layout.ControlHeight - 1)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.Parent = Grid

		return Grid
	end

	function UIBase:List(Parent, Options)
		Options = Options or {}

		local IsHorizontal = Options.Direction == "Horizontal"
		local Container

		if Options.Scroll == true then
			Container = Instance.new("ScrollingFrame")
			Container.AutomaticCanvasSize = IsHorizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
			Container.CanvasSize = UDim2.new(0, 0, 0, 0)
			Container.ScrollBarImageColor3 = Theme.Colors.Accent
			Container.ScrollBarThickness = Options.ScrollBarThickness or 4
			Container.ScrollingDirection = IsHorizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
		else
			Container = Instance.new("Frame")
		end

		Container.BackgroundTransparency = 1
		Container.BorderSizePixel = 0
		Container.ClipsDescendants = Options.ClipsDescendants == true
		Container.Size = Options.Size or UDim2.new(1, 0, 1, 0)
		Container.Parent = Parent

		local Layout = Instance.new("UIListLayout")
		Layout.FillDirection = IsHorizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		Layout.HorizontalAlignment = Options.HorizontalAlignment or Enum.HorizontalAlignment.Left
		Layout.Padding = Options.PaddingUDim or UDim.new(Options.PaddingScale or 0, Options.Padding or Theme.Layout.Gap)
		Layout.SortOrder = Enum.SortOrder.LayoutOrder
		Layout.VerticalAlignment = Options.VerticalAlignment or Enum.VerticalAlignment.Top
		Layout.Parent = Container

		return Container, Layout
	end

	function UIBase:ImageCard(Parent, Options)
		Options = Options or {}

		local Card = Instance.new("TextButton")
		Card.AutoButtonColor = true
		Card.BackgroundColor3 = Options.BackgroundColor or Theme.Colors.Card
		Card.BorderSizePixel = 0
		Card.ClipsDescendants = true
		Card.Size = Options.Size or UDim2.new(0.24, 0, 1, 0)
		Card.Text = ""
		Card.Parent = Parent
		CreateCorner(Card, Theme.Radius.Control)
		CreateStroke(Card, Options.StrokeColor or Theme.Colors.Text, Options.StrokeTransparency or 0.15)

		local Image = Instance.new("ImageLabel")
		Image.BackgroundTransparency = 1
		if string.find(Options.Image,"http://") or string.find(Options.Image,"rbxassetid://") then
			Image.Image = tostring(Options.Image or 0)
		else
			Image.Image = "rbxassetid://" .. tostring(Options.Image or 0)	
		end
		
		Image.ImageTransparency = Options.Locked and 0.35 or 0
		Image.Position = UDim2.new(0, 0, 0.18, 0)
		Image.ScaleType = Enum.ScaleType.Crop
		Image.Size = UDim2.new(1, 0, 0.82, 0)
		Image.Parent = Card

		local Overlay = Instance.new("Frame")
		Overlay.BackgroundColor3 = Theme.Colors.CardOverlay
		Overlay.BackgroundTransparency = Options.Locked and 0.45 or 0.82
		Overlay.BorderSizePixel = 0
		Overlay.Size = UDim2.new(1, 0, 1, 0)
		Overlay.Parent = Card

		local Title = self:Label(Card, string.upper(Options.Title or ""), Theme.TextSize.Title, Theme.Colors.TextStrong)
		Title.Font = Theme.Fonts.Medium
		Title.Position = UDim2.new(0, 10, 0, 8)
		Title.Size = UDim2.new(1, -20, 0, 24)

		local Description = self:Label(Card, Options.Description or "", Theme.TextSize.Caption, Theme.Colors.TextMuted)
		Description.Font = Theme.Fonts.Regular
		Description.Position = UDim2.new(0, 10, 0, 34)
		Description.Size = UDim2.new(1, -20, 0, 44)
		Description.TextWrapped = true
		Description.TextYAlignment = Enum.TextYAlignment.Top

		local FooterText = Options.Locked and "LOCKED" or (Options.ActionText or "SELECT")
		local Footer = self:Label(Card, FooterText, Theme.TextSize.Body, Options.Locked and Theme.Colors.Danger or Theme.Colors.TextStrong)
		Footer.AnchorPoint = Vector2.new(0.5, 1)
		Footer.Font = Theme.Fonts.Medium
		Footer.Position = UDim2.new(0.5, 0, 1, -34)
		Footer.Size = UDim2.new(1, -20, 0, 22)
		Footer.TextXAlignment = Enum.TextXAlignment.Center

		if Options.Locked and Options.LockText then
			local LockReason = self:Label(Card, Options.LockText, Theme.TextSize.Caption, Theme.Colors.Text)
			LockReason.AnchorPoint = Vector2.new(0.5, 1)
			LockReason.Font = Theme.Fonts.Regular
			LockReason.Position = UDim2.new(0.5, 0, 1, -10)
			LockReason.Size = UDim2.new(1, -20, 0, 34)
			LockReason.TextWrapped = true
			LockReason.TextXAlignment = Enum.TextXAlignment.Center
			LockReason.TextYAlignment = Enum.TextYAlignment.Top
		end

		if Options.Callback then
			Card.Activated:Connect(Options.Callback)
		end

		return Card
	end

	function UIBase:LiveControl(Parent, Config, InitialValue, CommitCallback)
		local Row = Instance.new("Frame")
		Row.BackgroundTransparency = 1
		Row.Size = UDim2.new(1, 0, 0, 54)
		Row.Parent = Parent

		local Label = self:Label(Row, Config.Label, Theme.TextSize.Body)
		Label.Position = UDim2.new(0, 0, 0, 0)
		Label.Size = UDim2.new(1, -82, 0, 22)

		local Input = self:Input(Row, FormatNumber(Config.Min) .. "-" .. FormatNumber(Config.Max), "")
		Input.Position = UDim2.new(1, -74, 0, 0)
		Input.Size = UDim2.new(0, 74, 0, 28)

		local Track = Instance.new("TextButton")
		Track.AutoButtonColor = false
		Track.BackgroundColor3 = Theme.Colors.Track
		Track.BorderSizePixel = 0
		Track.Position = UDim2.new(0, 0, 0, 34)
		Track.Size = UDim2.new(1, 0, 0, 12)
		Track.Text = ""
		Track.Parent = Row
		CreateCorner(Track, Theme.Radius.Control)

		local Fill = Instance.new("Frame")
		Fill.BackgroundColor3 = Theme.Colors.Accent
		Fill.BorderSizePixel = 0
		Fill.Size = UDim2.new(0, 0, 1, 0)
		Fill.Parent = Track
		CreateCorner(Fill, Theme.Radius.Control)

		local function SetValue(Value)
			local Alpha = math.clamp((Value - Config.Min) / (Config.Max - Config.Min), 0, 1)
			Fill.Size = UDim2.new(Alpha, 0, 1, 0)
			Input.Text = FormatNumber(Value)
		end

		local function Commit(Value)
			Value = tonumber(Value)
			if not Value then
				return
			end

			Value = math.clamp(math.floor(Value / Config.Step + 0.5) * Config.Step, Config.Min, Config.Max)
			SetValue(Value)

			if CommitCallback then
				CommitCallback(Value)
			end
		end

		Track.Activated:Connect(function()
			local MousePosition = UserInputService:GetMouseLocation()
			local Alpha = math.clamp((MousePosition.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
			Commit(Config.Min + (Config.Max - Config.Min) * Alpha)
		end)

		Input.FocusLost:Connect(function(EnterPressed)
			if EnterPressed then
				Commit(Input.Text)
			end
		end)

		SetValue(InitialValue or Config.Min)

		return {
			Row = Row,
			Input = Input,
			SetValue = SetValue,
		}
	end

	return UIBase
end
