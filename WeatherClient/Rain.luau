return function(helpers, services)
	local RunService = services.RunService
	local SoundService = services.SoundService
	local Workspace = services.Workspace
	local Player = services.Players

	local RainClient = {}
	RainClient.__index = RainClient

	local MinSpawnInterval = 0.003
	local MaxSpawnInterval = 0.03
	local SplashSpawnMultiplier = 2.5

	local function DelayTask(Duration, Callback)
		if task and task.delay then
			task.delay(Duration, Callback)
		else
			delay(Duration, Callback)
		end
	end

	local function AddTimedItem(Queue, Item, ExpireAt)
		table.insert(Queue, {
			Item = Item,
			ExpireAt = ExpireAt,
		})
	end

	local function PopExpiredItem(Queue, Now)
		for Index, Entry in ipairs(Queue) do
			if Entry.ExpireAt <= Now then
				table.remove(Queue, Index)
				return Entry.Item
			end
		end

		return nil
	end

	local function GetGroundCFrame(Position, Normal)
		local Tangent = Normal:Cross(Normal.Y == 0 and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0))
		return CFrame.fromMatrix(Position, Tangent, Normal)
	end

	function RainClient.new()
		local Terrain = Workspace.Terrain
		local IgnoreFolder = Workspace:FindFirstChild("Ignore")

		if not IgnoreFolder then
			IgnoreFolder = Instance.new("Folder")
			IgnoreFolder.Name = "Ignore"
			IgnoreFolder.Parent = Workspace
		end

		local DropletTemplate = script:WaitForChild("Droplet")
		local GroundSplashTemplate = script:WaitForChild("GroundSplash")
		GroundSplashTemplate.Enabled = false

		local RainSound = Instance.new("Sound")
		RainSound.Name = "RainSound"
		RainSound.Looped = true
		RainSound.Volume = 0.3
		RainSound.Parent = SoundService

		local FilteredInstances = { IgnoreFolder }
		local RaycastParameters = RaycastParams.new()
		RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
		RaycastParameters.FilterDescendantsInstances = FilteredInstances

		local EQ = script:FindFirstChild("EqualizerSoundEffect")
		if not EQ then
			EQ = Instance.new("EqualizerSoundEffect")
			EQ.HighGain = -42.2
			EQ.LowGain = -58.4
			
		end
		EQ.Parent = RainSound
		EQ.Enabled = false
		
		return setmetatable({
			Camera = Workspace.CurrentCamera,
			Terrain = Terrain,
			DropletTemplate = DropletTemplate,
			GroundSplashTemplate = GroundSplashTemplate,
			RainVelocity = DropletTemplate.TextureSpeed * DropletTemplate.TextureLength,
			RainSound = RainSound :: Sound,
			RaycastParameters = RaycastParameters,
			FilteredInstances = FilteredInstances,
			FilterIndex = 2,
			Enabled = false,
			SpawnAccumulator = 0,
			SplashAccumulator = 0,
			SpawnInterval = MaxSpawnInterval,
			RainDirection = Vector3.new(5, -30, 5).Unit,
			RandomGenerator = Random.new(),
			FreeDrops = {},
			ActiveDrops = {},
			SplashQueue = {},
			RecycleQueue = {},
			CachedVolume = 0,
			LastVolumeUpdate = 0,
			CleanupDelayFrames = 0,
			HeartbeatConnection = nil,
			
		}, RainClient)
	end

	function RainClient:Start()
		if self.HeartbeatConnection then
			return
		end

		self.HeartbeatConnection = RunService.Heartbeat:Connect(function(DeltaTime)
			self:Update(DeltaTime)
		end)
	end

	function RainClient:Destroy()
		if self.HeartbeatConnection then
			self.HeartbeatConnection:Disconnect()
			self.HeartbeatConnection = nil
		end

		self.RainSound:Destroy()

		for _, Drop in ipairs(self.FreeDrops) do
			Drop.Attachment0:Destroy()
			Drop.Attachment1:Destroy()
		end
	end

	function RainClient:GetDrop()
		local Drop = table.remove(self.FreeDrops)
		if Drop then
			return Drop
		end

		local Attachment0 = Instance.new("Attachment")
		local Attachment1 = Instance.new("Attachment")
		local Droplet = self.DropletTemplate:Clone()
		local GroundSplash = self.GroundSplashTemplate:Clone()

		Attachment0.Parent = self.Terrain
		Attachment1.Parent = self.Terrain
		Droplet.Attachment0 = Attachment0
		Droplet.Attachment1 = Attachment1
		Droplet.Parent = Attachment0
		GroundSplash.Parent = Attachment1

		return {
			Attachment0 = Attachment0,
			Attachment1 = Attachment1,
			Droplet = Droplet,
			GroundSplash = GroundSplash,
		}
	end

	function RainClient:RecycleDrop(Drop)
		self.ActiveDrops[Drop] = nil
		Drop.Droplet.Enabled = false
		table.insert(self.FreeDrops, Drop)
	end

	function RainClient:AddTransparentHitToFilter(InstanceHit)
		if not InstanceHit or InstanceHit.CanCollide then
			return false
		end

		self.FilteredInstances[#self.FilteredInstances + 1] = InstanceHit
		self.RaycastParameters.FilterDescendantsInstances = self.FilteredInstances
		return true
	end

	function RainClient:RaycastPastTransparent(StartPosition, Direction)
		local Result

		for _ = 1, 2 do
			Result = Workspace:Raycast(StartPosition, Direction, self.RaycastParameters)
			local InstanceHit = Result and Result.Instance

			if not self:AddTransparentHitToFilter(InstanceHit) then
				break
			end
		end

		return Result
	end

	function RainClient:RotateFilteredInstances()
		if #self.FilteredInstances < 2 then
			return
		end

		self.FilteredInstances[self.FilterIndex] = self.FilteredInstances[#self.FilteredInstances]
		self.FilteredInstances[#self.FilteredInstances] = nil
		self.FilterIndex += 1

		if #self.FilteredInstances < self.FilterIndex then
			self.FilterIndex = 2
		end

		self.RaycastParameters.FilterDescendantsInstances = self.FilteredInstances
	end

	function RainClient:SpawnRainDrop(CameraCFrame, StartOffset, EndOffset)
		local DropOrigin = CameraCFrame.Position
			+ Vector3.new(self.RandomGenerator:NextNumber(-20, 20), 0, self.RandomGenerator:NextNumber(-20, 20))
		local RayStart = DropOrigin + StartOffset
		local RayResult = self:RaycastPastTransparent(RayStart, EndOffset)

		if RayResult and (RayResult.Position - DropOrigin):Dot(self.RainDirection) < -15 then
			RayResult = nil
		end

		local HitPosition = RayResult and RayResult.Position or RayStart + EndOffset
		local DropStart = HitPosition - self.RainDirection * self.RandomGenerator:NextNumber(30, 70)
		local Drop = self:GetDrop()

		Drop.Attachment0.Position = DropStart
		Drop.Droplet:SetTextureOffset(0)
		Drop.Droplet.Enabled = true

		local LandAt = os.clock() + (HitPosition - DropStart).Magnitude / self.RainVelocity
		if RayResult then
			Drop.Attachment1.CFrame = GetGroundCFrame(HitPosition, RayResult.Normal)
			AddTimedItem(self.SplashQueue, Drop, LandAt)
		else
			Drop.Attachment1.Position = HitPosition
		end

		self.ActiveDrops[Drop] = HitPosition
		AddTimedItem(self.RecycleQueue, Drop, LandAt + 0.1)
	end

	function RainClient:EmitLooseSplash(CameraCFrame, StartOffset, EndOffset)
		local Angle = self.RandomGenerator:NextNumber(-1, 1)
		local Distance = self.RandomGenerator:NextNumber(15, 50)
		local RayStart = CameraCFrame * Vector3.new(math.sin(Angle) * Distance, 0, -math.cos(Angle) * Distance) + StartOffset
		local RayResult = self:RaycastPastTransparent(RayStart, EndOffset)

		if not RayResult then
			return
		end

		local Attachment = Instance.new("Attachment")
		Attachment.CFrame = GetGroundCFrame(RayResult.Position, RayResult.Normal)
		Attachment.Parent = self.Terrain

		local GroundSplash = self.GroundSplashTemplate:Clone()
		GroundSplash.Parent = Attachment
		GroundSplash:Emit(1)

		DelayTask(1, function()
			Attachment:Destroy()
		end)
	end

	function RainClient:UpdateRainVolume(CameraCFrame)
		local CameraPosition = CameraCFrame.Position
		local DirectionX = self.RainDirection.X
		local DirectionY = self.RainDirection.Y
		local DirectionZ = self.RainDirection.Z
		local ClosestDistanceSquared = 1000

		for _, Position in pairs(self.ActiveDrops) do
			local ProjectedDistance = DirectionX * (Position.X - CameraPosition.X)
				+ DirectionY * (Position.Y - CameraPosition.Y)
				+ DirectionZ * (Position.Z - CameraPosition.Z)
			local DistanceSquared = (Position.X - ProjectedDistance * DirectionX - CameraPosition.X) ^ 2
				+ (Position.Y - ProjectedDistance * DirectionY - CameraPosition.Y) ^ 2
				+ (Position.Z - ProjectedDistance * DirectionZ - CameraPosition.Z) ^ 2

			if DistanceSquared < ClosestDistanceSquared then
				ClosestDistanceSquared = DistanceSquared
			end
		end

		self.CachedVolume = (1 - math.clamp(ClosestDistanceSquared ^ 0.5 / 60, 0, 1) ^ 0.5) * 0.5
	end

	function RainClient:Update(DeltaTime)
		if not self.Camera then
			self.Camera = Workspace.CurrentCamera
		end

		if self.Enabled and self.Camera then
			local ClampedDeltaTime = math.clamp(DeltaTime, 0, 1 / 60)
			local CameraCFrame = self.Camera.CFrame
			local StartOffset = self.RainDirection * -400
			local EndOffset = self.RainDirection * 500
			local StartedAt = os.clock()

			self.SpawnAccumulator += ClampedDeltaTime / self.SpawnInterval
			self.SplashAccumulator += (ClampedDeltaTime / self.SpawnInterval) * SplashSpawnMultiplier
			self:RotateFilteredInstances()

			while self.SpawnAccumulator >= 1 and os.clock() - StartedAt < 0.00035 do
				self.SpawnAccumulator -= 1
				self:SpawnRainDrop(CameraCFrame, StartOffset, EndOffset)
			end

			while os.clock() - StartedAt < 0.0005 do
				local Drop = PopExpiredItem(self.SplashQueue, os.clock())
				if not Drop then
					break
				end

				if self.SplashAccumulator >= 1 then
					self.SplashAccumulator -= 1
					Drop.GroundSplash:Emit(1)
				end
			end

			while self.SplashAccumulator >= 1 and os.clock() - StartedAt < 0.0007 do
				self.SplashAccumulator -= 1
				self:EmitLooseSplash(CameraCFrame, StartOffset, EndOffset)
			end

			self.SpawnAccumulator %= 1
			self.SplashAccumulator %= 1

			if tick() - self.LastVolumeUpdate > 0.1 then
				self.LastVolumeUpdate = tick()
				self:UpdateRainVolume(CameraCFrame)
			end

			self.RainSound.Volume = self.RainSound.Volume * 0.95 + self.CachedVolume * 0.05
			if self.RainSound.Volume > 0 and not self.RainSound.IsPlaying then
				self.RainSound:Resume()
			end
		end

		local CleanupEndsAt = os.clock() + 0.00005
		while os.clock() < CleanupEndsAt do
			local Drop = PopExpiredItem(self.RecycleQueue, os.clock())
			if not Drop then
				break
			end

			self:RecycleDrop(Drop)
		end

		local TargetFreeDropCount = self.Enabled and 10 or 0
		if TargetFreeDropCount < #self.FreeDrops then
			if self.CleanupDelayFrames < 5 then
				self.CleanupDelayFrames += 1
				return
			end

			for _ = 1, 3 do
				local Drop = table.remove(self.FreeDrops)
				if not Drop then
					break
				end

				Drop.Attachment0:Destroy()
				Drop.Attachment1:Destroy()
			end
		else
			self.CleanupDelayFrames = 0
		end
	end

	function RainClient:Enable()
		self.Enabled = true
		self.RainSound.Volume = 0
		self.CachedVolume = 0
	end

	function RainClient:Disable()
		self.Enabled = false
		self.RainSound:Stop()
	end

	function RainClient:SetEQ(bool)
		if not self.RainSound then
			return
		end
		
		if not self.EQ then
			return
		end
		
		--local RainSound: Sound = self.RainSound
		
		if bool then
			self.EQ.Enabled = bool
		else
			self.EQ.Enabled = not self.EQ.Enabled
		end
		if self.Sound.Playing then
			self.RainSound:Stop()
			task.wait(0.1)
			self.RainSound:Play()
		end
	end

	function RainClient:SetSoundId(SoundId)
		if self.RainSound.SoundId == SoundId then
			return
		end

		self.RainSound:Stop()
		self.RainSound.SoundId = SoundId
	end

	function RainClient:SetDirection(Direction)
		self.RainDirection = Direction.Unit
	end

	function RainClient:SetIntensity(Intensity)
		self.SpawnInterval = MaxSpawnInterval + (MinSpawnInterval - MaxSpawnInterval) * (1 - (1 - Intensity) ^ 3)
	end

	return RainClient
end
