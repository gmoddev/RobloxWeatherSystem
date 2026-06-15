return function(helpers, services)
	local Players = services.Players
	local TextChatService = services.TextChatService

	local ChatCommands = {}
	ChatCommands.__index = ChatCommands

	local AdminUserIds = {
		[81718700] = true,
	}

	local function IsAdmin(Player)
		return AdminUserIds[Player.UserId] == true
	end

	local function GetPlayerFromTextSource(TextSource)
		if not TextSource then
			return nil
		end

		return Players:GetPlayerByUserId(TextSource.UserId)
	end

	local function GetCommand(Name, PrimaryAlias, SecondaryAlias)
		local Command = TextChatService:FindFirstChild(Name)

		if not Command then
			Command = Instance.new("TextChatCommand")
			Command.Name = Name
			Command.Parent = TextChatService
		end

		Command.PrimaryAlias = PrimaryAlias
		Command.SecondaryAlias = SecondaryAlias or ""

		return Command
	end

	function ChatCommands.new(WeatherScheduler, SetWeatherEvent, TimeOfDay)
		return setmetatable({
			WeatherScheduler = WeatherScheduler,
			SetWeatherEvent = SetWeatherEvent,
			TimeOfDay = TimeOfDay,
			Connections = {},
		}, ChatCommands)
	end

	function ChatCommands:RunWeatherCommand(TextSource, Message, WeatherName)
		local Player = GetPlayerFromTextSource(TextSource)

		if not Player or not IsAdmin(Player) then
			return
		end

		self.SetWeatherEvent:Fire(WeatherName, true)
	end

	function ChatCommands:RunTimeCommand(TextSource, Callback)
		local Player = GetPlayerFromTextSource(TextSource)

		if not Player or not IsAdmin(Player) then
			return
		end

		Callback()
	end

	function ChatCommands:Start()
		local ClearCommand = GetCommand("ClearWeatherCommand", "/clearweather")
		local RainCommand = GetCommand("RainWeatherCommand", "/rain")
		local HeavyRainCommand = GetCommand("HeavyRainWeatherCommand", "/heavyrain")
		local StormCommand = GetCommand("StormWeatherCommand", "/storm")
		local WeatherCommand = GetCommand("SetWeatherCommand", "/weather")
		local TimeCommand = GetCommand("SetTimeCommand", "/time", "/settime")
		local FreezeTimeCommand = GetCommand("FreezeTimeCommand", "/freezetime", "/timefreeze")
		local AdvanceTimeCommand = GetCommand("AdvanceTimeCommand", "/advancetime", "/addtime")
		local TimeSpeedCommand = GetCommand("SetTimeSpeedCommand", "/timespeed", "/settimespeed")

		table.insert(self.Connections, ClearCommand.Triggered:Connect(function(TextSource, Message)
			self:RunWeatherCommand(TextSource, Message, "Clear")
		end))

		table.insert(self.Connections, RainCommand.Triggered:Connect(function(TextSource, Message)
			self:RunWeatherCommand(TextSource, Message, "LightRain")
		end))

		table.insert(self.Connections, HeavyRainCommand.Triggered:Connect(function(TextSource, Message)
			self:RunWeatherCommand(TextSource, Message, "HeavyRain")
		end))

		table.insert(self.Connections, StormCommand.Triggered:Connect(function(TextSource, Message)
			self:RunWeatherCommand(TextSource, Message, "Storm")
		end))

		table.insert(self.Connections, WeatherCommand.Triggered:Connect(function(TextSource, Message)
			local Player = GetPlayerFromTextSource(TextSource)

			if not Player or not IsAdmin(Player) then
				return
			end

			local Args = string.split(Message, " ")
			local WeatherName = Args[2]

			if not WeatherName then
				warn("Usage: /weather Clear, Cloudy, LightRain, HeavyRain, Storm, Auto")
				return
			end

			if string.lower(WeatherName) == "auto" then
				self.WeatherScheduler:ResumeForecast()
				return
			end

			self.SetWeatherEvent:Fire(WeatherName, true)
		end))

		table.insert(self.Connections, TimeCommand.Triggered:Connect(function(TextSource, Message)
			self:RunTimeCommand(TextSource, function()
				local Args = string.split(Message, " ")
				local TimeText = Args[2]

				if not TimeText or not self.TimeOfDay:SetTime(TimeText) then
					warn("Usage: /time 14.5 or /time 14:30")
				end
			end)
		end))

		table.insert(self.Connections, FreezeTimeCommand.Triggered:Connect(function(TextSource, Message)
			self:RunTimeCommand(TextSource, function()
				local Args = string.split(Message, " ")
				local State = Args[2] and string.lower(Args[2]) or nil

				if State == "on" or State == "true" or State == "freeze" then
					self.TimeOfDay:SetFrozen(true)
				elseif State == "off" or State == "false" or State == "unfreeze" then
					self.TimeOfDay:SetFrozen(false)
				elseif State then
					warn("Usage: /freezetime, /freezetime on, or /freezetime off")
				else
					self.TimeOfDay:ToggleFrozen()
				end
			end)
		end))

		table.insert(self.Connections, AdvanceTimeCommand.Triggered:Connect(function(TextSource, Message)
			self:RunTimeCommand(TextSource, function()
				local Args = string.split(Message, " ")
				local Hours = Args[2]

				if not Hours or not self.TimeOfDay:AdvanceTime(Hours) then
					warn("Usage: /advancetime 1.5")
				end
			end)
		end))

		table.insert(self.Connections, TimeSpeedCommand.Triggered:Connect(function(TextSource, Message)
			self:RunTimeCommand(TextSource, function()
				local Args = string.split(Message, " ")
				local Speed = Args[2]

				if Speed and string.lower(Speed) == "reset" then
					self.TimeOfDay:ResetTimeSpeed()
					return
				end

				if not Speed or not self.TimeOfDay:SetTimeSpeed(Speed) then
					warn("Usage: /timespeed 1, /timespeed 2, /timespeed 0.5, or /timespeed reset")
				end
			end)
		end))
	end

	function ChatCommands:Destroy()
		for _, Connection in ipairs(self.Connections) do
			Connection:Disconnect()
		end

		table.clear(self.Connections)
	end

	return ChatCommands
end
