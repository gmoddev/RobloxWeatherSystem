return function(helpers, services)
	local TweenService = services.TweenService

	local WeatherScheduler = {}
	WeatherScheduler.__index = WeatherScheduler

	local WeatherPresets = {
		Clear = {
			RainPercent = 0,
			WindPower = 0.05,
			CloudCover = 0.2,
			CloudDensity = 0.15,
			AtmosphereDensity = 0.25,
			AtmosphereGlare = 1,
			AtmosphereHaze = 0.89,
			WeatherEvent = "Clear",
			Duration = { 180, 420 },
		},

		Cloudy = {
			RainPercent = 0,
			WindPower = 0.2,
			CloudCover = 0.65,
			CloudDensity = 0.35,
			AtmosphereDensity = 0.32,
			AtmosphereGlare = 0.65,
			AtmosphereHaze = 1.4,
			WeatherEvent = "Cloudy",
			Duration = { 180, 360 },
		},

		LightRain = {
			RainPercent = 0.25,
			WindPower = 0.25,
			CloudCover = 0.8,
			CloudDensity = 0.45,
			AtmosphereDensity = 0.42,
			AtmosphereGlare = 0.35,
			AtmosphereHaze = 2.5,
			WeatherEvent = "Rain",
			Duration = { 120, 300 },
		},

		HeavyRain = {
			RainPercent = 0.75,
			WindPower = 0.45,
			CloudCover = 0.9,
			CloudDensity = 0.6,
			AtmosphereDensity = 0.55,
			AtmosphereGlare = 0.15,
			AtmosphereHaze = 4,
			WeatherEvent = "Rain",
			Duration = { 90, 240 },
		},

		Storm = {
			RainPercent = 1,
			WindPower = 0.85,
			CloudCover = 1,
			CloudDensity = 0.75,
			AtmosphereDensity = 0.7,
			AtmosphereGlare = 0,
			AtmosphereHaze = 6,
			WeatherEvent = "Storm",
			Duration = { 60, 180 },
		},
	}

	local WeatherWeights = {
		Clear = 45,
		Cloudy = 25,
		LightRain = 18,
		HeavyRain = 9,
		Storm = 3,
	}

	local function PickWeighted(Weights)
		local Total = 0

		for _, Weight in pairs(Weights) do
			Total += Weight
		end

		local Roll = math.random() * Total
		local Current = 0

		for Name, Weight in pairs(Weights) do
			Current += Weight

			if Roll <= Current then
				return Name
			end
		end

		return "Clear"
	end

	local function RandomWindDirection()
		local X = math.random(-100, 100) / 100
		local Z = math.random(-100, 100) / 100
		local Direction = Vector3.new(X, 0, Z)

		if Direction.Magnitude <= 0 then
			return Vector3.new(1, 0, 0)
		end

		return Direction.Unit
	end

	local function RandomDuration(Range)
		return math.random(Range[1], Range[2])
	end

	local function GetServerTime()
		return os.time()
	end

	function WeatherScheduler.new(Values)
		return setmetatable({
			Values = Values,
			Running = false,
			ForecastOverridden = false,
			CurrentWeather = nil,
			ActiveTweens = {},
		}, WeatherScheduler)
	end

	function WeatherScheduler:TweenValue(ValueObject, TargetValue, Duration)
		local Tween = TweenService:Create(
			ValueObject,
			TweenInfo.new(Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Value = TargetValue }
		)

		Tween:Play()
		table.insert(self.ActiveTweens, Tween)

		return Tween
	end

	function WeatherScheduler:CancelActiveTweens()
		for _, Tween in ipairs(self.ActiveTweens) do
			Tween:Cancel()
		end

		table.clear(self.ActiveTweens)
	end

	function WeatherScheduler:PublishForecast(WeatherName, Duration)
		self.Values.ForecastWeather.Value = WeatherName
		self.Values.ForecastEndsAt.Value = GetServerTime() + Duration
		self.Values.ForecastOverridden.Value = self.ForecastOverridden
	end

	function WeatherScheduler:OverrideForecast(WeatherName)
		self.ForecastOverridden = true
		self.Values.ForecastWeather.Value = WeatherName or self.CurrentWeather or self.Values.WeatherEvent.Value
		self.Values.ForecastEndsAt.Value = 0
		self.Values.ForecastOverridden.Value = true
	end

	function WeatherScheduler:SetWeather(WeatherName, OverrideForecast)
		local Preset = WeatherPresets[WeatherName]
		if not Preset then
			warn("Invalid weather preset:", WeatherName)
			return
		end

		if OverrideForecast then
			self:OverrideForecast(WeatherName)
		end

		self:CancelActiveTweens()

		self.CurrentWeather = WeatherName
		self.Values.WeatherEvent.Value = Preset.WeatherEvent

		local TransitionTime = 15

		self:TweenValue(self.Values.RainPercent, Preset.RainPercent, TransitionTime)
		self:TweenValue(self.Values.WindPower, Preset.WindPower, TransitionTime)
		self:TweenValue(self.Values.WindDirection, RandomWindDirection(), TransitionTime)
		self:TweenValue(self.Values.CloudCover, Preset.CloudCover, TransitionTime)
		self:TweenValue(self.Values.CloudDensity, Preset.CloudDensity, TransitionTime)
		self:TweenValue(self.Values.AtmosphereDensity, Preset.AtmosphereDensity, TransitionTime)
		self:TweenValue(self.Values.AtmosphereGlare, Preset.AtmosphereGlare, TransitionTime)
		self:TweenValue(self.Values.AtmosphereHaze, Preset.AtmosphereHaze, TransitionTime)
	end

	function WeatherScheduler:ResumeForecast()
		self.ForecastOverridden = false
		self.Values.ForecastOverridden.Value = false
	end

	function WeatherScheduler:Start()
		if self.Running then
			return
		end

		self.Running = true

		task.spawn(function()
			local ForecastWeather = PickWeighted(WeatherWeights)
			local ForecastDuration = RandomDuration(WeatherPresets[ForecastWeather].Duration)
			self:PublishForecast(ForecastWeather, ForecastDuration)

			while self.Running do
				if self.ForecastOverridden then
					task.wait(1)
					continue
				end

				local NextWeather = self.Values.ForecastWeather.Value
				local Preset = WeatherPresets[NextWeather]

				if not Preset then
					NextWeather = "Clear"
					Preset = WeatherPresets[NextWeather]
				end

				self:SetWeather(NextWeather, false)

				local NextForecastWeather = PickWeighted(WeatherWeights)
				local NextForecastDuration = RandomDuration(Preset.Duration)
				self:PublishForecast(NextForecastWeather, NextForecastDuration)

				task.wait(NextForecastDuration)
			end
		end)
	end

	function WeatherScheduler:Stop()
		self.Running = false
		self:CancelActiveTweens()
	end

	return WeatherScheduler
end
