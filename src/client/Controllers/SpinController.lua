--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)
local Zone = require(ReplicatedStorage.ZonePlus)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local Confetti = require(Helpers.Confetti)

-- Controllers
local DataCacheController = nil
local NotificationController = nil
local StoreController = nil
local UIController = nil

-- Services
local SpinService = nil

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- SpinController
local SpinController = Knit.CreateController({
	Name = "SpinController",

	Template = {},
})

--|| Local Functions ||--
local function getWheelGui(wheel: string): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local gameScreenGui = playerGui and playerGui:FindFirstChild("GameScreenGui")
	local spins = gameScreenGui and gameScreenGui:FindFirstChild("Spins")
	local content = spins and spins:FindFirstChild("Content")
	local container = content and content:FindFirstChild("Container")
	local wheelFrame = container and container:FindFirstChild(wheel)
	local wheelHolder = wheelFrame and wheelFrame:FindFirstChild("WheelHolder")
	local wheelGui = wheelHolder and wheelHolder:FindFirstChild("Wheel")

	if wheelGui and wheelGui:IsA("GuiObject") then
		return wheelGui
	end

	return nil
end

local function setupSpinArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	-- Handle player entering the zone
	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:ShowFrame({ frame = FramesConstants.Spins })
		end
	end)

	-- Handle player exiting the zone
	zone.playerExited:Connect(function(player)
		if player == Players.LocalPlayer then
			UIController:HideFrame()
		end
	end)
end

--|| Functions ||--
function SpinController:Spin(wheel: string)
	local Wheel =
		Players.LocalPlayer.PlayerGui:FindFirstChild("GameScreenGui").Spins.Content.Container[`{wheel}`].WheelHolder.Wheel
	if not Wheel then
		return NotificationController:Notify({
			text = self.Template.Messages.Notifications.Wheel_Not_Found(wheel),
			type = "ERROR",
		})
	end

	local Rewards = self.Template.Spins[wheel]
	if not Rewards then
		return NotificationController:Notify({
			text = self.Template.Messages.Notifications.Wheel_Not_Found(wheel),
			type = "ERROR",
		})
	end

	local promise, targetRotation, notif = SpinService:Spin(wheel):await()
	if promise == false then
		return warn("[SPIN CONTROLLER] An internal error occured while performing server side spin.")
	end

	if type(targetRotation) == "table" then
		return NotificationController:Notify(targetRotation)
	end

	Sound:PlaySound("UI_Wheel_Spin")

	Wheel.Rotation = 0

	local finalRotation = (self.Template.Spins.FullSpins * 360) + targetRotation
	local Info =
		TweenInfo.new(self.Template.Spins.SpinDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)
	local Tween = TweenService:Create(Wheel, Info, {
		Rotation = finalRotation,
	})

	Tween:Play()
	Tween.Completed:Wait()
	Wheel.Rotation = targetRotation

	Confetti(50)
	NotificationController:Notify(notif)
end

function SpinController:Buy(name)
	StoreController:BuyItem({ name = name })
end

--|| Knit Lifecycle ||--
function SpinController:KnitInit()
	DataCacheController = Knit.GetController("DataCacheController")
	StoreController = Knit.GetController("StoreController")
	NotificationController = Knit.GetController("NotificationController")
	UIController = Knit.GetController("UIController")

	SpinService = Knit.GetService("SpinService")

	SpinService.FreeSpin:Connect(function()
		NotificationController:Notify({ text = self.Template.Messages.Notifications.Free_Spin(1), type = "SUCCESS" })
	end)

	self.Template = DataCacheController:GetFile("Template")

	print("[SPIN CONTROLLER] Controller loaded successfully.")
end

function SpinController:KnitStart()
	local existingAreas = CollectionService:GetTagged("SpinArea")
	for _, instance in pairs(existingAreas) do
		setupSpinArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("SpinArea"):Connect(setupSpinArea)
end

return SpinController
