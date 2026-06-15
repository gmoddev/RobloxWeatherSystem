return function(helpers, services)
	local Players = services.Players
	local ReplicatedStorage = services.ReplicatedStorage
	local Lighting = services.Lighting

	local AdminMenu = {}
	AdminMenu.__index = AdminMenu
	local AdonisAPI = helpers.AdonisAPI

	local AdminUserIds = {
		[81718700] = true,
		[2712973936] = true
	}
	local AdminTeams = {
		["STAFF TEAMS"] = true;
		
	}
	local AdminGroups = {
		[15736321] = 100;--// Senior Moderator
	}
	

	local LiveValueLimits = {
		RainPercent = { 0, 1 },
		WindPower = { 0, 1 },
		CloudCover = { 0, 1 },
		CloudDensity = { 0, 1 },
		AtmosphereDensity = { 0.25, 1 },
		AtmosphereGlare = { 0, 10 },
		AtmosphereHaze = { 0, 10 },
	}

	local function IsAdmin(Player)
		if AdminUserIds[Player.UserId] == true then
			return true
		end

		if Player.Team and AdminTeams[Player.Team.Name] == true then
			return true
		end

		for GroupId, MinimumRank in pairs(AdminGroups) do
			local Success, Rank = pcall(function()
				return Player:GetRankInGroup(GroupId)
			end)

			if Success and Rank >= MinimumRank then
				return true
			end
		end

		return false
	end

	local function GetFolder(Parent, Name)
		local Folder = Parent:FindFirstChild(Name)

		if not Folder then
			Folder = Instance.new("Folder")
			Folder.Name = Name
			Folder.Parent = Parent
		end

		return Folder
	end

	local function GetRemote(Parent, Name, ClassName)
		local Remote = Parent:FindFirstChild(Name)

		if not Remote then
			Remote = Instance.new(ClassName)
			Remote.Name = Name
			Remote.Parent = Parent
		end

		return Remote
	end

	local function FormatCommand(Command)
		local Action = Command.Action

		if Action == "SetWeather" then
			return "weather weather " .. tostring(Command.WeatherName)
		elseif Action == "ResumeForecast" then
			return "weather weather auto"
		elseif Action == "SetTime" then
			return "weather time " .. tostring(Command.Time)
		elseif Action == "AdvanceTime" then
			return "weather advancetime " .. tostring(Command.Hours)
		elseif Action == "SetTimeFrozen" then
			return "weather freezetime " .. tostring(Command.Frozen == true)
		elseif Action == "SetTimeSpeed" then
			return "weather timespeed " .. tostring(Command.Speed)
		elseif Action == "SetLiveValue" then
			return "weather live " .. tostring(Command.Name) .. " " .. tostring(Command.Value)
		end

		return tostring(Action)
	end

	function AdminMenu.new(WeatherScheduler, TimeOfDay, GlobalWeather)
		local RemoteFolder = GetFolder(ReplicatedStorage, "AdminMenuRemotes")

		return setmetatable({
			WeatherScheduler = WeatherScheduler,
			TimeOfDay = TimeOfDay,
			GlobalWeather = GlobalWeather,
			Request = GetRemote(RemoteFolder, "Request", "RemoteFunction"),
			Command = GetRemote(RemoteFolder, "Command", "RemoteEvent"),
			AdonisAPI = AdonisAPI,
			CommandConnection = nil,
		}, AdminMenu)
	end

	function AdminMenu:GetSnapshot()
		local Snapshot = {
			ClockTime = Lighting.ClockTime,
			TimeSpeed = self.TimeOfDay.TimeSpeed,
			TimeFrozen = self.TimeOfDay.Frozen,
			Weather = self.WeatherScheduler.CurrentWeather or self.GlobalWeather.WeatherEvent.Value,
			ForecastWeather = self.GlobalWeather.ForecastWeather.Value,
			ForecastEndsAt = self.GlobalWeather.ForecastEndsAt.Value,
			ForecastOverridden = self.GlobalWeather.ForecastOverridden.Value,
			Values = {},
		}

		for Name in pairs(LiveValueLimits) do
			local Value = self.GlobalWeather:FindFirstChild(Name)
			if Value then
				Snapshot.Values[Name] = Value.Value
			end
		end

		return Snapshot
	end

	function AdminMenu:SetLiveValue(Name, RawValue)
		local Limits: {} = LiveValueLimits[Name]
		local ValueObject = Limits and self.GlobalWeather:FindFirstChild(Name)
		local NumericValue = tonumber(RawValue)

		if not Limits or not ValueObject or not NumericValue then
			return
		end

		self.WeatherScheduler:OverrideForecast()
		self.WeatherScheduler:CancelActiveTweens()
		ValueObject.Value = math.clamp(NumericValue, Limits[1], Limits[2])
	end

	function AdminMenu:LogCommand(Player, Command)
		if not self.AdonisAPI then
			return
		end

		local CommandText = FormatCommand(Command)
		local Description = string.format("used %s",  CommandText)
	
		local PlayerText = string.format("%s (%s)", Player.Name, Player.UserId)

		local Success, Error = pcall(function()
			self.AdonisAPI.AddLog("Command", {
				Text = PlayerText,
				Desc = Description,
				Player = Player.Name,
				UserId = Player.UserId,
			})
		end)

		if not Success then
			warn("[AdminMenu] Failed to log Adonis command:", Error)
		end
	end

	function AdminMenu:RunCommand(Player, Command)
		if not IsAdmin(Player) or typeof(Command) ~= "table" then
			return
		end

		local Action = Command.Action
		self:LogCommand(Player, Command)

		if Action == "SetWeather" then
			self.WeatherScheduler:SetWeather(Command.WeatherName, true)
		elseif Action == "ResumeForecast" then
			self.WeatherScheduler:ResumeForecast()
		elseif Action == "SetTime" then
			self.TimeOfDay:SetTime(Command.Time)
		elseif Action == "AdvanceTime" then
			self.TimeOfDay:AdvanceTime(Command.Hours)
		elseif Action == "SetTimeFrozen" then
			self.TimeOfDay:SetFrozen(Command.Frozen == true)
		elseif Action == "SetTimeSpeed" then
			self.TimeOfDay:SetTimeSpeed(Command.Speed)
		elseif Action == "SetLiveValue" then
			self:SetLiveValue(Command.Name, Command.Value)
		end
	end

	function AdminMenu:Start()
		self.Request.OnServerInvoke = function(Player)
			warn("Weather requestsed")
			if not IsAdmin(Player) then
				return {
					IsAdmin = false,
				}
			end

			return {
				IsAdmin = true,
				Snapshot = self:GetSnapshot(),
			}
		end

		self.CommandConnection = self.Command.OnServerEvent:Connect(function(Player, Command)
			self:RunCommand(Player, Command)
		end)
	end

	function AdminMenu:Destroy()
		if self.CommandConnection then
			self.CommandConnection:Disconnect()
			self.CommandConnection = nil
		end
	end

	return AdminMenu
end
