local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local m = {}
m.__index = m

local CurrentOpen = nil
local Locked = false
local MenuFolder = nil

local TweenInfoOpen = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoClose = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- Button animation tweens
local HoverTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ClickTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function m.new()
	local self = setmetatable({}, m)

	local function Setup()
		local PlayerGui = Player:WaitForChild("PlayerGui")
		local Hud = PlayerGui:FindFirstChild("HUD")
		if not Hud then
			Hud = Instance.new("ScreenGui")
			Hud.Name = "HUD"
			Hud.ResetOnSpawn = false
			Hud.Parent = PlayerGui
		end

		MenuFolder = Hud:FindFirstChild("Menu")
		if not MenuFolder then
			MenuFolder = Instance.new("Frame")
			
			MenuFolder.Size = UDim2.new(1,0,1,0)
			MenuFolder.BackgroundTransparency = 1
			MenuFolder.Name = "Menu"
			MenuFolder.Parent = Hud
		end

		CurrentOpen = nil

		self:Initialize()
	end

	if Player.Character then
		Setup()
	end

	Player.CharacterAdded:Connect(Setup)

	return self
end

function m:Initialize()
	if not MenuFolder then return end


	

	for _, Item in ipairs(MenuFolder:GetChildren()) do
		if not Item:IsA("Frame") then continue end
		Item.Visible = false

		local TopBar = Item:FindFirstChild("Topbar")
		if not TopBar then continue end

		local CloseButton = TopBar:FindFirstChildWhichIsA("TextButton")
		if not CloseButton then continue end

		-- Prevent rebinding
		if CloseButton:GetAttribute("Bound") then continue end
		CloseButton:SetAttribute("Bound", true)

		CloseButton.MouseEnter:Connect(function()
			TweenService:Create(CloseButton, HoverTweenInfo, {
				BackgroundTransparency = 0.8
			}):Play()
		end)

		CloseButton.MouseLeave:Connect(function()
			TweenService:Create(CloseButton, HoverTweenInfo, {
				BackgroundTransparency = 0.9
			}):Play()
		end)

		CloseButton.MouseButton1Click:Connect(function()
			local ClickTween = TweenService:Create(CloseButton, ClickTweenInfo, {
				Size = CloseButton.Size - UDim2.new(0, 2, 0, 2)
			})
			ClickTween:Play()

			ClickTween.Completed:Once(function()
				TweenService:Create(CloseButton, ClickTweenInfo, {
					Size = CloseButton.Size
				}):Play()
			end)

			self:Close(Item)
		end)
	end
end

function m:Lock()
	Locked = true
	if CurrentOpen then
		self:Close(CurrentOpen)
		CurrentOpen = nil
	end
end

function m:Unlock()
	Locked = false
end

function m:IsOpen(Name)
	if not CurrentOpen then
		return false
	end
	
	return CurrentOpen.Name == Name or false

end

function m:Open(Item)
	if Locked or not Item or CurrentOpen == Item then
		return
	end

	if CurrentOpen and CurrentOpen ~= Item then
		self:Close(CurrentOpen)
	end

	Item.Position = UDim2.new(-1, 0, 0.25, 0)
	Item.Visible = true

	TweenService:Create(Item, TweenInfoOpen, {
		Position = UDim2.new(0.25, 0, 0.25, 0)
	}):Play()

	CurrentOpen = Item
end

function m:Close(Item)
	if not Item or not Item.Visible then
		return
	end

	local Tween = TweenService:Create(Item, TweenInfoClose, {
		Position = UDim2.new(1, 0, 0.25, 0)
	})
	Tween:Play()

	Tween.Completed:Once(function()
		if Item then
			Item.Visible = false
		end
	end)

	if CurrentOpen == Item then
		CurrentOpen = nil
	end
end

function m:Toggle(ItemName)
	if Locked or not MenuFolder then
		return
	end

	local Item = MenuFolder:FindFirstChild(ItemName)
	if not Item then
		warn("Menu item not found:", ItemName)
		return
	end

	if CurrentOpen == Item then
		self:Close(Item)
	else
		self:Open(Item)
	end
end

function m:Get(ItemName)
	if not MenuFolder then
		return nil
	end
	
	local Item = MenuFolder:FindFirstChild(ItemName)
	if not Item then
		warn("Menu item not found:", ItemName)
		return nil
	end

	return Item
end

return m.new()
