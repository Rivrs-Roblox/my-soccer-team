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
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local DataCacheController = nil
local NotificationController = nil
local StoreController = nil
local UIController = nil
local MatchController = nil

-- Services
local SpinService = nil

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local BUSY_NOTIFY_COOLDOWN = 1.5
local BUSY_NOTIFY_SPAM_RESET_CLICKS = 5

-- SpinController
local SpinController = Knit.CreateController({
	Name = "SpinController",

	Template = {},
	Spinning = {},
	BusyNotifyCount = {},
	BusyNotifyLastShownAt = {},
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

local function IsMatchUiBlocked()
	if not MatchController then
		pcall(function()
			MatchController = Knit.GetController("MatchController")
		end)
	end

	if MatchController and MatchController.IsPlayingMatch then
		local ok, isPlaying = pcall(function()
			return MatchController:IsPlayingMatch()
		end)
		return ok and isPlaying == true
	end

	if UIController and UIController.IsUiBlockedForMatch then
		local ok, isBlocked = pcall(function()
			return UIController:IsUiBlockedForMatch()
		end)
		return ok and isBlocked == true
	end

	return false
end

--|| Functions ||--
function SpinController:Spin(wheel: string)
	if IsMatchUiBlocked() then
		return
	end

	local spinAmount = 0
	local state = Store:getState()
	if state and state.SpinsReducer and state.SpinsReducer.Spins then
		spinAmount = state.SpinsReducer.Spins[wheel] or 0
	end

	if spinAmount <= 0 then
		self.BusyNotifyCount[wheel] = (self.BusyNotifyCount[wheel] or 0) + 1
		local now = os.clock()
		local lastShownAt = self.BusyNotifyLastShownAt[wheel] or 0

		if lastShownAt <= 0 or now - lastShownAt >= BUSY_NOTIFY_COOLDOWN then
			NotificationController:Notify({
				tag = `SpinNoSpins_{wheel}`,
				text = self.Template.Messages.Notifications.No_More_Spins(wheel),
				type = "ERROR",
			})
			self.BusyNotifyLastShownAt[wheel] = now
			self.BusyNotifyCount[wheel] = 0
		elseif self.BusyNotifyCount[wheel] >= BUSY_NOTIFY_SPAM_RESET_CLICKS then
			self.BusyNotifyLastShownAt[wheel] = now
			self.BusyNotifyCount[wheel] = 0
		end

		return
	end

	if self.Spinning[wheel] then
		self.BusyNotifyCount[wheel] = (self.BusyNotifyCount[wheel] or 0) + 1
		local now = os.clock()
		local lastShownAt = self.BusyNotifyLastShownAt[wheel] or 0

		if lastShownAt <= 0 or now - lastShownAt >= BUSY_NOTIFY_COOLDOWN then
			NotificationController:Notify({
				tag = `SpinBusy_{wheel}`,
				text = self.Template.Messages.Notifications.Already_Spining,
				type = "ERROR",
			})
			self.BusyNotifyLastShownAt[wheel] = now
			self.BusyNotifyCount[wheel] = 0
		elseif self.BusyNotifyCount[wheel] >= BUSY_NOTIFY_SPAM_RESET_CLICKS then
			self.BusyNotifyLastShownAt[wheel] = now
			self.BusyNotifyCount[wheel] = 0
		end

		return
	end
	self.Spinning[wheel] = true
	self.BusyNotifyCount[wheel] = 0
	self.BusyNotifyLastShownAt[wheel] = nil

	local Wheel = getWheelGui(wheel)
	if not Wheel then
		self.Spinning[wheel] = nil
		self.BusyNotifyCount[wheel] = nil
		self.BusyNotifyLastShownAt[wheel] = nil
		return NotificationController:Notify({
			text = self.Template.Messages.Notifications.Wheel_Not_Found(wheel),
			type = "ERROR",
		})
	end

	local Rewards = self.Template.Spins[wheel]
	if not Rewards then
		self.Spinning[wheel] = nil
		self.BusyNotifyCount[wheel] = nil
		self.BusyNotifyLastShownAt[wheel] = nil
		return NotificationController:Notify({
			text = self.Template.Messages.Notifications.Wheel_Not_Found(wheel),
			type = "ERROR",
		})
	end

	local promise, targetRotation, notif = SpinService:Spin(wheel):await()
	if promise == false then
		self.Spinning[wheel] = nil
		self.BusyNotifyCount[wheel] = nil
		self.BusyNotifyLastShownAt[wheel] = nil
		return warn("[SPIN CONTROLLER] An internal error occured while performing server side spin.")
	end

	if type(targetRotation) == "table" then
		self.Spinning[wheel] = nil
		self.BusyNotifyCount[wheel] = nil
		self.BusyNotifyLastShownAt[wheel] = nil
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
	self.Spinning[wheel] = nil
	self.BusyNotifyCount[wheel] = nil
	self.BusyNotifyLastShownAt[wheel] = nil
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
	pcall(function()
		MatchController = Knit.GetController("MatchController")
	end)

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
