return function(helpers, services)
	local warn = helpers.warn
	
	warn("Loading Admin Menu")
	local Players = services.Players
	local ReplicatedStorage = services.ReplicatedStorage
	local UserInputService = services.UserInputService

	local ClientCore = script.Parent.Parent.Parent

	local function ResolveHelper(HelperSource: ModuleScript, ...)
		if typeof(HelperSource) == "Instance" and HelperSource:IsA("ModuleScript") then
			HelperSource = require(HelperSource)
		end

		if type(HelperSource) == "function" then
			return HelperSource(...)
		end

		return HelperSource
	end

	local Theme = ResolveHelper(helpers.Theme, helpers, services)
		or require(ClientCore.Helpers.Theme)(helpers, services)
	local UI = ResolveHelper(helpers.UIBase, helpers, services, Theme)
		or require(ClientCore.Helpers.UIBase)(helpers, services, Theme)

	local AdminMenu = {}
	AdminMenu.__index = AdminMenu

	local WeatherPresets = { "Clear", "Cloudy", "LightRain", "HeavyRain", "Storm" }

	local LiveControls = {
		{ Name = "RainPercent", Label = "Rain", Min = 0, Max = 1, Step = 0.01 },
		{ Name = "WindPower", Label = "Wind", Min = 0, Max = 1, Step = 0.01 },
		{ Name = "CloudCover", Label = "Cloud cover", Min = 0, Max = 1, Step = 0.01 },
		{ Name = "CloudDensity", Label = "Cloud density", Min = 0, Max = 1, Step = 0.01 },
		{ Name = "AtmosphereDensity", Label = "Atmosphere density", Min = 0.25, Max = 1, Step = 0.01 },
		{ Name = "AtmosphereGlare", Label = "Glare", Min = 0, Max = 10, Step = 0.1 },
		{ Name = "AtmosphereHaze", Label = "Haze", Min = 0, Max = 10, Step = 0.1 },
	}

	function AdminMenu.new()
		local RemoteFolder = ReplicatedStorage:WaitForChild("AdminMenuRemotes")
		warn("Admin Initalizing")
		return setmetatable({
			Player = Players.LocalPlayer,
			Request = RemoteFolder:WaitForChild("Request"),
			Command = RemoteFolder:WaitForChild("Command"),
			GlobalWeather = ReplicatedStorage:WaitForChild("GlobalWeather"),
			Gui = nil,
			Visible = false,
			IsAdmin = false,
			TimeInput = nil,
			TimeSpeedInput = nil,
			FreezeButton = nil,
			StatusLabel = nil,
			InputConnection = nil,
			ValueConnections = {},
			LiveControls = {},
		}, AdminMenu)
	end

	function AdminMenu:Send(Action, Payload)
		Payload = Payload or {}
		Payload.Action = Action
		self.Command:FireServer(Payload)
	end

	function AdminMenu:CreateLiveControl(Parent, Config)
		local ValueObject = self.GlobalWeather:FindFirstChild(Config.Name)
		local Control = UI:LiveControl(Parent, Config, ValueObject and ValueObject.Value or Config.Min, function(Value)
			self:Send("SetLiveValue", {
				Name = Config.Name,
				Value = Value,
			})
		end)

		self.LiveControls[Config.Name] = Control

		if ValueObject then
			table.insert(self.ValueConnections, ValueObject.Changed:Connect(Control.SetValue))
		end
	end

	function AdminMenu:Build()
		local Gui = Instance.new("ScreenGui")
		Gui.Name = "AdminMenu"
		Gui.ResetOnSpawn = false
		Gui.Enabled = false
		Gui.Parent = self.Player:WaitForChild("PlayerGui")
		self.Gui = Gui

		local Panel = UI:Panel(Gui)
		local _, StatusLabel = UI:Header(Panel, "Admin control", "Live weather and time", function()
			self:SetVisible(false)
		end)
		self.StatusLabel = StatusLabel

		local Body = UI:ScrollBody(Panel)
		self:BuildWeatherSection(Body)
		self:BuildLiveSection(Body)
		self:BuildTimeSection(Body)
	end

	function AdminMenu:BuildWeatherSection(Parent)
		local Section = UI:Section(Parent, "Weather")
		local PresetGrid = UI:Grid(Section, 2, 3)

		for _, WeatherName in ipairs(WeatherPresets) do
			UI:Button(PresetGrid, WeatherName, function()
				self:Send("SetWeather", {
					WeatherName = WeatherName,
				})
			end)
		end

		UI:Button(Section, "Resume forecast", function()
			self:Send("ResumeForecast")
		end, Theme.Colors.ButtonSuccess)
	end

	function AdminMenu:BuildLiveSection(Parent)
		local Section = UI:Section(Parent, "Live values")

		for _, Config in ipairs(LiveControls) do
			self:CreateLiveControl(Section, Config)
		end
	end

	function AdminMenu:BuildTimeSection(Parent)
		local Section = UI:Section(Parent, "Time")

		self.TimeInput = UI:Input(Section, "14.5 or 14:30", "")
		self.TimeInput.FocusLost:Connect(function(EnterPressed)
			if EnterPressed then
				self:Send("SetTime", {
					Time = self.TimeInput.Text,
				})
			end
		end)

		local TimeButtons = UI:Grid(Section, 1, 3)
		UI:Button(TimeButtons, "+1 hour", function()
			self:Send("AdvanceTime", {
				Hours = 1,
			})
		end)

		UI:Button(TimeButtons, "+6 hours", function()
			self:Send("AdvanceTime", {
				Hours = 6,
			})
		end)

		self.FreezeButton = UI:Button(TimeButtons, "Freeze", function()
			local Frozen = self.FreezeButton.Text ~= "Unfreeze"
			self:Send("SetTimeFrozen", {
				Frozen = Frozen,
			})
			self.FreezeButton.Text = Frozen and "Unfreeze" or "Freeze"
		end)

		self.TimeSpeedInput = UI:Input(Section, "Time speed", "1")
		self.TimeSpeedInput.FocusLost:Connect(function(EnterPressed)
			if EnterPressed then
				self:Send("SetTimeSpeed", {
					Speed = self.TimeSpeedInput.Text,
				})
			end
		end)
	end

	function AdminMenu:Refresh()
		local Result = self.Request:InvokeServer()
		self.IsAdmin = Result and Result.IsAdmin == true

		if not self.IsAdmin then
			return false
		end

		local Snapshot = Result.Snapshot
		if Snapshot then
			self.TimeInput.Text = UI:FormatNumber(Snapshot.ClockTime)
			self.TimeSpeedInput.Text = tostring(Snapshot.TimeSpeed or 1)
			self.FreezeButton.Text = Snapshot.TimeFrozen and "Unfreeze" or "Freeze"
			self.StatusLabel.Text = string.format(
				"Weather: %s  Forecast: %s",
				Snapshot.Weather or "Unknown",
				Snapshot.ForecastWeather or "Unknown"
			)
		end

		return true
	end

	function AdminMenu:SetVisible(Visible)
		self.Visible = Visible
		self.Gui.Enabled = Visible

		if Visible then
			self:Refresh()
		end
	end

	function AdminMenu:Start()
		local Result = self.Request:InvokeServer()
		self.IsAdmin = Result and Result.IsAdmin == true

		if not self.IsAdmin then
			return
		end

		self:Build()
		self:Refresh()

		self.InputConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
			if GameProcessed then
				return
			end

			if Input.KeyCode == Enum.KeyCode.RightShift then
				self:SetVisible(not self.Visible)
			end
		end)
	end

	function AdminMenu:Destroy()
		if self.InputConnection then
			self.InputConnection:Disconnect()
			self.InputConnection = nil
		end

		for _, Connection in ipairs(self.ValueConnections) do
			Connection:Disconnect()
		end

		table.clear(self.ValueConnections)

		if self.Gui then
			self.Gui:Destroy()
			self.Gui = nil
		end
	end

	return AdminMenu
end
