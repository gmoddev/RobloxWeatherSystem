return function(helpers, services)
	local RunService = services.RunService
	local Lighting = services.Lighting

	local TimeOfDay = {}
	TimeOfDay.__index = TimeOfDay

	local DayLengthSeconds = 1800
	local DefaultTimeSpeed = 1

	local function NormalizeTime(ClockTime)
		return ClockTime % 24
	end

	local function FormatTime(ClockTime)
		local TotalSeconds = math.floor(NormalizeTime(ClockTime) * 3600 + 0.5) % 86400
		local Hours = math.floor(TotalSeconds / 3600)
		local Minutes = math.floor((TotalSeconds % 3600) / 60)
		local Seconds = TotalSeconds % 60

		return string.format("%02d:%02d:%02d", Hours, Minutes, Seconds)
	end

	local function ParseTime(TimeText)
		local NumericTime = tonumber(TimeText)
		if NumericTime then
			return NormalizeTime(NumericTime)
		end

		local Hours, Minutes, Seconds = string.match(TimeText, "^(%d+):(%d+):?(%d*)$")
		if not Hours or not Minutes then
			return nil
		end

		Hours = tonumber(Hours)
		Minutes = tonumber(Minutes)
		Seconds = tonumber(Seconds) or 0

		if not Hours or not Minutes or not Seconds or Minutes >= 60 or Seconds >= 60 then
			return nil
		end

		return NormalizeTime(Hours + Minutes / 60 + Seconds / 3600)
	end

	function TimeOfDay.new()
		return setmetatable({
			Lighting = Lighting,
			Running = false,
			Frozen = false,
			TimeSpeed = DefaultTimeSpeed,
			HeartbeatConnection = nil,
		}, TimeOfDay)
	end

	function TimeOfDay:SetClockTime(ClockTime)
		self.Lighting.TimeOfDay = FormatTime(ClockTime)
	end

	function TimeOfDay:SetTime(TimeText)
		local ClockTime = ParseTime(TimeText)
		if not ClockTime then
			return false
		end

		self:SetClockTime(ClockTime)
		return true
	end

	function TimeOfDay:AdvanceTime(Hours)
		local Amount = tonumber(Hours)
		if not Amount then
			return false
		end

		self:SetClockTime(self.Lighting.ClockTime + Amount)
		return true
	end

	function TimeOfDay:SetTimeSpeed(Speed)
		local Amount = tonumber(Speed)
		if not Amount or Amount < 0 then
			return false
		end

		self.TimeSpeed = Amount
		return true
	end

	function TimeOfDay:ResetTimeSpeed()
		self.TimeSpeed = DefaultTimeSpeed
	end

	function TimeOfDay:SetFrozen(Frozen)
		self.Frozen = Frozen == true
	end

	function TimeOfDay:ToggleFrozen()
		self.Frozen = not self.Frozen
		return self.Frozen
	end

	function TimeOfDay:Start()
		if self.HeartbeatConnection then
			return
		end

		self.Running = true
		self.HeartbeatConnection = RunService.Heartbeat:Connect(function(DeltaTime)
			if self.Frozen then
				return
			end

			self:SetClockTime(self.Lighting.ClockTime + (DeltaTime / DayLengthSeconds) * 24 * self.TimeSpeed)
		end)
	end

	function TimeOfDay:Stop()
		self.Running = false

		if self.HeartbeatConnection then
			self.HeartbeatConnection:Disconnect()
			self.HeartbeatConnection = nil
		end
	end

	return TimeOfDay
end
