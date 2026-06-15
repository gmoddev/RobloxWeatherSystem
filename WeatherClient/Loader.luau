return function(helpers, services)
	local Players = services.Players
	local ReplicatedStorage = services.ReplicatedStorage
	local RunService = services.RunService

	local WeatherClient = require(script.Parent.Module)(helpers, services)
	local AdminMenu = require(script.Parent.AdminMenu)(helpers, services)
	local Weather = WeatherClient.new()
	local AdminControls = AdminMenu.new()
	local HeartbeatConnection = nil

	local function CharacterAdded(Character)
		return Character
	end

	local function PlayerAdded(Player)
		if Player.Character then
			CharacterAdded(Player.Character)
		end

		Player.CharacterAdded:Connect(CharacterAdded)
	end

	local Loader = {
		Weather = Weather,
		AdminControls = AdminControls,
		CharacterAdded = CharacterAdded,
		PlayerAdded = PlayerAdded,
	}

	function Loader:Start()
		Weather:Start()
		AdminControls:Start()

		if HeartbeatConnection then
			return
		end

		HeartbeatConnection = RunService.Heartbeat:Connect(function(DeltaTime)
			Weather:Update(DeltaTime)
		end)

		for _, Player in ipairs(Players:GetPlayers()) do
			PlayerAdded(Player)
		end

		Players.PlayerAdded:Connect(PlayerAdded)
	end

	function Loader:Destroy()
		if HeartbeatConnection then
			HeartbeatConnection:Disconnect()
			HeartbeatConnection = nil
		end

		Weather:Destroy()
		AdminControls:Destroy()
	end

	return Loader
end
