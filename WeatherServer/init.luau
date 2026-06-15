return function(helpers, services)
	local ReplicatedStorage = services.ReplicatedStorage
	local ServerScriptService = services.ServerScriptService

	local WeatherScheduler = require(script.WeatherScheduler)(helpers, services)
	local ChatCommands = require(script.ChatCommands)(helpers, services)
	local TimeOfDay = require(script.TimeOfDay)(helpers, services)
	local AdminMenu = require(script.AdminMenu)(helpers, services)

	local GlobalWeather = ReplicatedStorage:FindFirstChild("GlobalWeather")
	if not GlobalWeather then
		GlobalWeather = Instance.new("Folder")
		GlobalWeather.Name = "GlobalWeather"
		GlobalWeather.Parent = ReplicatedStorage
	end
	
	local SetWeatherEvent = ServerScriptService:FindFirstChild("SetWeather")
	if not SetWeatherEvent then
		SetWeatherEvent = Instance.new("BindableEvent")
		SetWeatherEvent.Name = "SetWeather"
		SetWeatherEvent.Parent = ServerScriptService
	end

	local function GetValue(Name, ClassName, DefaultValue)
		local Value = GlobalWeather:FindFirstChild(Name)

		if not Value then
			Value = Instance.new(ClassName)
			Value.Name = Name
			Value.Value = DefaultValue
			Value.Parent = GlobalWeather
		end

		return Value
	end

	local RainPercent = GetValue("RainPercent", "NumberValue", 0)
	local WeatherEvent = GetValue("WeatherEvent", "StringValue", "Clear")
	local ForecastWeather = GetValue("ForecastWeather", "StringValue", "Clear")
	local ForecastEndsAt = GetValue("ForecastEndsAt", "NumberValue", 0)
	local ForecastOverridden = GetValue("ForecastOverridden", "BoolValue", false)
	local WindPower = GetValue("WindPower", "NumberValue", 0)
	local WindDirection = GetValue("WindDirection", "Vector3Value", Vector3.new(1, 0, 0))

	local CloudCover = GetValue("CloudCover", "NumberValue", 0.25)
	local CloudDensity = GetValue("CloudDensity", "NumberValue", 0.2)
	local AtmosphereDensity = GetValue("AtmosphereDensity", "NumberValue", 0.25)
	local AtmosphereGlare = GetValue("AtmosphereGlare", "NumberValue", 1)
	local AtmosphereHaze = GetValue("AtmosphereHaze", "NumberValue", 0.89)
	
	
	local Scheduler = WeatherScheduler.new({
		RainPercent = RainPercent,
		WeatherEvent = WeatherEvent,
		ForecastWeather = ForecastWeather,
		ForecastEndsAt = ForecastEndsAt,
		ForecastOverridden = ForecastOverridden,
		WindPower = WindPower,
		WindDirection = WindDirection,
		CloudCover = CloudCover,
		CloudDensity = CloudDensity,
		AtmosphereDensity = AtmosphereDensity,
		AtmosphereGlare = AtmosphereGlare,
		AtmosphereHaze = AtmosphereHaze,
	})

	local TimeController = TimeOfDay.new()
	local Commands = ChatCommands.new(Scheduler, SetWeatherEvent, TimeController)
	local AdminControls = AdminMenu.new(Scheduler, TimeController, GlobalWeather)

	Scheduler:Start()
	TimeController:Start()
	AdminControls:Start()

	Commands:Start()

	SetWeatherEvent.Event:Connect(function(WeatherName, OverrideForecast)
		Scheduler:SetWeather(WeatherName, OverrideForecast == true)
	end)


	return {
		SetWeather = function(_, WeatherName)
			Scheduler:SetWeather(WeatherName)
		end,

		GetWeather = function()
			return WeatherEvent.Value
		end,
	}
end
