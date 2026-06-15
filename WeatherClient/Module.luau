return function(helpers, services)
	local Lighting = services.Lighting
	local CollectionService = services.CollectionService
	local ReplicatedStorage = services.ReplicatedStorage
	local SoundService = services.SoundService
	local TweenService = services.TweenService
	local Workspace = services.Workspace
	local Players = services.Players
	
	local Player = Players.LocalPlayer

	local RainClient = require(script.Parent.Rain)(helpers, services)
	local Lightning = require(script.Parent.Lightning)(helpers, services)

	local WeatherClient = {}
	WeatherClient.__index = WeatherClient

	local ClearTint = Color3.new(1, 1, 1)
	local StormTintColor = Color3.fromRGB(140, 150, 170)
	local StormContrast = 0.15
	local StormSaturation = -0.3
	local MinAtmosphereDensity = 0.25
	local MaxAtmosphereGlare = 10
	local MaxAtmosphereHaze = 10
	local MaxGlobalWindSpeed = 50
	local FireRainThreshold = 0.2

	local RainSoundIds = {
		Light = "rbxassetid://124007901087065",
		Medium = "rbxassetid://103159144411790",
		Heavy = "rbxassetid://89749550663593",
	}

	local WindSoundSettings = {
		Medium = {
			Id = "rbxassetid://2262900876",
			Volume = 0.4,
			From = 0.4,
			To = 0.75,
		},
		Heavy = {
			Id = "rbxassetid://98321225628218",
			Volume = 0.2,
			From = 0.4,
			To = 1,
		},
	}



	local function Lerp(StartValue, EndValue, Alpha)
		return StartValue + (EndValue - StartValue) * Alpha
	end

	local function LerpVector(StartVector, EndVector, Alpha)
		local Result = StartVector:Lerp(EndVector, Alpha)

		if Result.Magnitude == 0 then
			return EndVector
		end

		return Result.Unit
	end

	local function PercentBetween(Value, MinValue, MaxValue)
		if MaxValue == MinValue then
			return 1
		end

		return math.clamp((Value - MinValue) / (MaxValue - MinValue), 0, 1)
	end

	local function GetWindSoundSetting(WindPower)
		if WindSoundSettings.Heavy.From <= WindPower then
			return WindSoundSettings.Heavy
		end

		if WindSoundSettings.Medium.From <= WindPower then
			return WindSoundSettings.Medium
		end

		return nil
	end

	local function GetRainType(RainPercent)
		if RainPercent > 0.75 then
			return "Heavy"
		end

		if RainPercent > 0.4 then
			return "Medium"
		end

		return "Light"
	end

	function WeatherClient.new()
		local GlobalWeather = ReplicatedStorage:WaitForChild("GlobalWeather",100)
		local WindDirectionValue = GlobalWeather:WaitForChild("WindDirection")
		local WindPowerValue = GlobalWeather:WaitForChild("WindPower")
		local RainPercentValue = GlobalWeather:WaitForChild("RainPercent")
		local WeatherEventValue = GlobalWeather:WaitForChild("WeatherEvent")
		local StormTint = Lighting:FindFirstChild("StormTint")
		local Rain = RainClient.new()

		local StormLoop = Instance.new("Sound")
		StormLoop.Name = "StormLoop"
		StormLoop.SoundId = "rbxassetid://2265975479"
		StormLoop.Looped = true
		StormLoop.Volume = 0.05
		StormLoop.Parent = SoundService

		local WindSoundGroup = Instance.new("SoundGroup")
		WindSoundGroup.Name = "WindSounds"
		WindSoundGroup.Parent = SoundService

		local WindSoundTemplate = Instance.new("Sound")
		WindSoundTemplate.Name = "WindSound"
		WindSoundTemplate.SoundGroup = WindSoundGroup
		WindSoundTemplate.Looped = true
		WindSoundTemplate.Volume = 0

		local CloudCoverValue = GlobalWeather:WaitForChild("CloudCover")
		local CloudDensityValue = GlobalWeather:WaitForChild("CloudDensity")
		local AtmosphereDensityValue = GlobalWeather:WaitForChild("AtmosphereDensity")
		local AtmosphereGlareValue = GlobalWeather:WaitForChild("AtmosphereGlare")
		local AtmosphereHazeValue = GlobalWeather:WaitForChild("AtmosphereHaze")

		local Clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
		if not Clouds then
			Clouds = Instance.new("Clouds")
			Clouds.Name = "Clouds"
			Clouds.Parent = Workspace.Terrain
		end

		local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not Atmosphere then
			Atmosphere = Instance.new("Atmosphere")
			Atmosphere.Name = "Atmosphere"
			Atmosphere.Parent = Lighting
		end

		local AtmosphereDensity = math.max(AtmosphereDensityValue.Value, MinAtmosphereDensity)
		local AtmosphereGlare = math.clamp(AtmosphereGlareValue.Value, 0, MaxAtmosphereGlare)
		local AtmosphereHaze = math.clamp(AtmosphereHazeValue.Value, 0, MaxAtmosphereHaze)

		Atmosphere.Density = AtmosphereDensity
		Atmosphere.Glare = AtmosphereGlare
		Atmosphere.Haze = AtmosphereHaze
		Workspace.GlobalWind = WindDirectionValue.Value * (WindPowerValue.Value * MaxGlobalWindSpeed)

		if StormTint then
			StormTint.TintColor = ClearTint
			StormTint.Contrast = 0
			StormTint.Saturation = 0
		end


		local function CharacterAdded(char: Model)
			char:GetAttributeChangedSignal("Inside"):Connect(function(bool)
				if bool then
					Rain:SetEQ(true)
				else
					Rain:SetEQ(false)
				end
			end)
			
		end
		
		if Player.Character then
			CharacterAdded(Player.Character)
		end
		Player.CharacterAdded:Connect(CharacterAdded)

		return setmetatable({
			GlobalWeather = GlobalWeather,
			WindDirectionValue = WindDirectionValue,
			WindPowerValue = WindPowerValue,
			RainPercentValue = RainPercentValue,
			WeatherEventValue = WeatherEventValue,
			StormTint = StormTint,
			Terrain = Workspace.Terrain,
			Rain = Rain,
			Lightning = Lightning,
			StormLoop = StormLoop,
			WindSoundGroup = WindSoundGroup,
			WindSoundTemplate = WindSoundTemplate,
			RainPercent = RainPercentValue.Value,
			WindPower = WindPowerValue.Value,
			WindDirection = WindDirectionValue.Value,
			WeatherEvent = WeatherEventValue.Value,
			WindSoundType = nil,
			WindSound = nil,
			IsRaining = false,
			RainType = nil,
			RainIntensity = "High",
			FireParts = {},
			FirePartConnections = {},
			FireSuppressedInstances = {},
			IsSuppressingFire = false,
			FireTagAddedConnection = nil,
			FireTagRemovedConnection = nil,
			
			Clouds = Clouds,
			CloudCoverValue = CloudCoverValue,
			CloudDensityValue = CloudDensityValue,
			CloudCover = CloudCoverValue.Value,
			CloudDensity = CloudDensityValue.Value,
			Atmosphere = Atmosphere,
			AtmosphereDensityValue = AtmosphereDensityValue,
			AtmosphereGlareValue = AtmosphereGlareValue,
			AtmosphereHazeValue = AtmosphereHazeValue,
			AtmosphereDensity = AtmosphereDensity,
			AtmosphereGlare = AtmosphereGlare,
			AtmosphereHaze = AtmosphereHaze,
		}, WeatherClient)
	end

	function WeatherClient:Start()
		self.Rain:Start()
		self:StartFireCache()
	end

	function WeatherClient:Destroy()
		self:SetFireSuppression(false)
		self:StopFireCache()
		self.Rain:Destroy()
		self.StormLoop:Destroy()
		self.WindSoundGroup:Destroy()
	end

	function WeatherClient:SetRainIntensity(RainIntensity)
		self.RainIntensity = RainIntensity or "High"
	end

	function WeatherClient:SetStormTint(TintColor, Contrast, Saturation, Alpha)
		if not self.StormTint then
			return
		end

		self.StormTint.TintColor = self.StormTint.TintColor:Lerp(TintColor, Alpha)
		self.StormTint.Contrast = Lerp(self.StormTint.Contrast, Contrast, Alpha)
		self.StormTint.Saturation = Lerp(self.StormTint.Saturation, Saturation, Alpha)
	end

	function WeatherClient:StopSoundAfterTween(Sound, Tween)
		task.spawn(function()
			Tween.Completed:Wait()
			Sound:Stop()
		end)
	end

	function WeatherClient:UpdateClouds(DeltaTime)
		if not self.Clouds then
			return
		end

		local Alpha = math.clamp(DeltaTime / 5, 0, 1)

		self.CloudCover = Lerp(self.CloudCover, self.CloudCoverValue.Value, Alpha)
		self.CloudDensity = Lerp(self.CloudDensity, self.CloudDensityValue.Value, Alpha)

		self.Clouds.Cover = self.CloudCover
		self.Clouds.Density = self.CloudDensity

		if self.WeatherEvent == "Storm" then
			self.Clouds.Color = self.Clouds.Color:Lerp(Color3.fromRGB(90, 95, 110), Alpha)
		elseif self.WeatherEvent == "Rain" then
			self.Clouds.Color = self.Clouds.Color:Lerp(Color3.fromRGB(130, 135, 145), Alpha)
		else
			self.Clouds.Color = self.Clouds.Color:Lerp(Color3.fromRGB(255, 255, 255), Alpha)
		end
	end

	function WeatherClient:UpdateAtmosphere(DeltaTime)
		if not self.Atmosphere then
			return
		end

		local Alpha = math.clamp(DeltaTime / 5, 0, 1)
		local TargetDensity = math.max(self.AtmosphereDensityValue.Value, MinAtmosphereDensity)
		local TargetGlare = math.clamp(self.AtmosphereGlareValue.Value, 0, MaxAtmosphereGlare)
		local TargetHaze = math.clamp(self.AtmosphereHazeValue.Value, 0, MaxAtmosphereHaze)

		self.AtmosphereDensity = Lerp(self.AtmosphereDensity, TargetDensity, Alpha)
		self.AtmosphereGlare = Lerp(self.AtmosphereGlare, TargetGlare, Alpha)
		self.AtmosphereHaze = Lerp(self.AtmosphereHaze, TargetHaze, Alpha)

		self.Atmosphere.Density = self.AtmosphereDensity
		self.Atmosphere.Glare = self.AtmosphereGlare
		self.Atmosphere.Haze = self.AtmosphereHaze
	end

	function WeatherClient:UpdateStormSound(PreviousWeatherEvent, CurrentWeatherEvent)
		if CurrentWeatherEvent == "Storm" and PreviousWeatherEvent ~= "Storm" then
			self.StormLoop.Volume = 0
			self.StormLoop:Play()
			TweenService:Create(self.StormLoop, TweenInfo.new(5), { Volume = 0.15 }):Play()
		elseif PreviousWeatherEvent == "Storm" and CurrentWeatherEvent ~= "Storm" then
			local FadeOutTween = TweenService:Create(self.StormLoop, TweenInfo.new(5), { Volume = 0 })
			FadeOutTween:Play()
			self:StopSoundAfterTween(self.StormLoop, FadeOutTween)
		end
	end

	function WeatherClient:UpdateWindSound(DeltaTime)
		local WindSoundSetting = GetWindSoundSetting(self.WindPower)

		if WindSoundSetting ~= self.WindSoundType then
			self.WindSoundType = WindSoundSetting

			if self.WindSound then
				local OldWindSound = self.WindSound
				self.WindSound = nil
				local FadeOutTween = TweenService:Create(OldWindSound, TweenInfo.new(10), { Volume = 0 })
				FadeOutTween:Play()
				task.spawn(function()
					FadeOutTween.Completed:Wait()
					OldWindSound:Destroy()
				end)
			end

			if WindSoundSetting then
				local NewWindSound = self.WindSoundTemplate:Clone()
				NewWindSound.SoundId = WindSoundSetting.Id
				NewWindSound.Parent = self.WindSoundGroup
				NewWindSound:Play()
				self.WindSound = NewWindSound
			end
		end

		if self.WindSound and self.WindSoundType then
			local TargetVolume = self.WindSoundType.Volume
				* PercentBetween(self.WindPower, self.WindSoundType.From - 0.1, self.WindSoundType.To)
			self.WindSound.Volume = Lerp(self.WindSound.Volume, TargetVolume, math.clamp(DeltaTime / 10, 0, 1))
		end
	end

	function WeatherClient:UpdateGlobalWind()
		Workspace.GlobalWind = self.WindDirection * (self.WindPower * MaxGlobalWindSpeed)
	end

	function WeatherClient:CacheFirePart(InstanceTagged)
		if self.FireParts[InstanceTagged] then
			return
		end

		self.FireParts[InstanceTagged] = true
		self.FirePartConnections[InstanceTagged] = InstanceTagged.DescendantAdded:Connect(function(Object)
			if self.IsSuppressingFire then
				self:SuppressFireObject(Object)
			end
		end)

		if self.IsSuppressingFire then
			self:SuppressFirePart(InstanceTagged)
		end
	end

	function WeatherClient:RemoveFirePart(InstanceTagged)
		self.FireParts[InstanceTagged] = nil

		if self.FirePartConnections[InstanceTagged] then
			self.FirePartConnections[InstanceTagged]:Disconnect()
			self.FirePartConnections[InstanceTagged] = nil
		end
	end

	function WeatherClient:StartFireCache()
		for _, InstanceTagged in ipairs(CollectionService:GetTagged("FirePart")) do
			self:CacheFirePart(InstanceTagged)
		end

		self.FireTagAddedConnection = CollectionService:GetInstanceAddedSignal("FirePart"):Connect(function(InstanceTagged)
			self:CacheFirePart(InstanceTagged)
		end)

		self.FireTagRemovedConnection = CollectionService:GetInstanceRemovedSignal("FirePart"):Connect(function(InstanceTagged)
			self:RemoveFirePart(InstanceTagged)
		end)
	end

	function WeatherClient:StopFireCache()
		if self.FireTagAddedConnection then
			self.FireTagAddedConnection:Disconnect()
			self.FireTagAddedConnection = nil
		end

		if self.FireTagRemovedConnection then
			self.FireTagRemovedConnection:Disconnect()
			self.FireTagRemovedConnection = nil
		end

		table.clear(self.FireParts)

		for FirePart, Connection in pairs(self.FirePartConnections) do
			Connection:Disconnect()
			self.FirePartConnections[FirePart] = nil
		end
	end

	function WeatherClient:SuppressFireObject(Object)
		if self.FireSuppressedInstances[Object] ~= nil then
			return
		end

		if Object:IsA("Sound") then
			if Object.IsPlaying then
				self.FireSuppressedInstances[Object] = "Playing"
				Object:Stop()
			end

			return
		end

		local Success, Enabled = pcall(function()
			return Object.Enabled
		end)

		if Success and Enabled == true then
			self.FireSuppressedInstances[Object] = true
			pcall(function()
				Object.Enabled = false
			end)
		end
	end

	function WeatherClient:SuppressFirePart(FirePart)
		for _, Object in ipairs(FirePart:GetDescendants()) do
			self:SuppressFireObject(Object)
		end
	end

	function WeatherClient:RestoreSuppressedFire()
		for Object, State in pairs(self.FireSuppressedInstances) do
			if Object.Parent then
				if State == "Playing" and Object:IsA("Sound") then
					Object:Play()
				elseif State == true then
					pcall(function()
						Object.Enabled = true
					end)
				end
			end
		end

		table.clear(self.FireSuppressedInstances)
	end

	function WeatherClient:SetFireSuppression(ShouldSuppress)
		if ShouldSuppress == self.IsSuppressingFire then
			return
		end

		self.IsSuppressingFire = ShouldSuppress

		if ShouldSuppress then
			for FirePart in pairs(self.FireParts) do
				if FirePart.Parent then
					self:SuppressFirePart(FirePart)
				else
					self:RemoveFirePart(FirePart)
				end
			end
		else
			self:RestoreSuppressedFire()
		end
	end

	function WeatherClient:UpdateRain()
		local ShouldRain = self.RainPercent > 0.05 and self.RainIntensity ~= "Off"
		self:SetFireSuppression(self.RainPercent >= FireRainThreshold and self.RainIntensity ~= "Off")

		if ShouldRain then
			if not self.IsRaining then
				self.IsRaining = true
				self.Rain:Enable()
			end

			local RainType = GetRainType(self.RainPercent)
			if self.RainType ~= RainType then
				self.RainType = RainType
				self.Rain:SetSoundId(RainSoundIds[RainType])
			end

			local WindDirection = self.WindDirection * (self.WindPower * 0.5)
			local IntensityScale = self.RainIntensity == "Low" and 0.2 or 1
			self.Rain:SetDirection(Vector3.new(WindDirection.X, -1, WindDirection.Z).Unit)
			self.Rain:SetIntensity(self.RainPercent * IntensityScale)
		elseif self.IsRaining then
			self.IsRaining = false
			self.RainType = nil
			self.Rain:Disable()
		end
	end

	function WeatherClient:CreateLightning(StartPosition, EndPosition, Options)
		Options = Options or {}

		return self.Lightning.Strike(
			StartPosition,
			EndPosition,
			Options.BendFactor,
			Options.Jaggedness,
			Options.Thickness,
			Options.PartCount,
			Options.Color
		)
	end

	function WeatherClient:Update(DeltaTime)
		local Alpha = math.clamp(DeltaTime / 0.5, 0, 1)
		local PreviousWeatherEvent = self.WeatherEvent

		self.RainPercent = Lerp(self.RainPercent, self.RainPercentValue.Value, Alpha)
		self.WindPower = Lerp(self.WindPower, self.WindPowerValue.Value, Alpha)
		self.WindDirection = LerpVector(self.WindDirection, self.WindDirectionValue.Value, Alpha)
		self.WeatherEvent = self.WeatherEventValue.Value

		self.Terrain.WaterWaveSize = 0.1
		self.Terrain.WaterWaveSpeed = Lerp(4, 45, self.WindPower)

		local TargetTint = ClearTint
		local TargetContrast = 0
		local TargetSaturation = 0

		if self.WeatherEvent == "Storm" then
			TargetTint = StormTintColor
			TargetContrast = StormContrast
			TargetSaturation = StormSaturation
		end

		self:UpdateStormSound(PreviousWeatherEvent, self.WeatherEvent)
		self:SetStormTint(TargetTint, TargetContrast, TargetSaturation, math.clamp(DeltaTime / 5, 0, 1))
		self:UpdateGlobalWind()
		self:UpdateWindSound(DeltaTime)
		self:UpdateRain()
		self:UpdateClouds(DeltaTime)
		self:UpdateAtmosphere(DeltaTime)
	end

	return WeatherClient
end
