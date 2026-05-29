--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

--Services
local DataService = nil
local TeleportService = nil

--Controllers
local DataCacheController = nil
local NotificationController = nil
local MatchController = nil

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)
local NotificationActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.NotificationActions)

-- Helpers
local FormatNumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)
local UIJuice = require(StarterPlayer.StarterPlayerScripts.Client.Helpers.UIJuice)

---Cache
local TopFrameSizeInit = false
local TopFrameSize = nil

local BottomFrameSizeInit = false
local BottomFrameSize = nil
local isUIShown = false
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local PANEL_ANIMATION_TARGET_NAME = "__UIPanelRoot"
local PANEL_OPEN_OPTIONS = {
	StartScale = 0.86,
	OvershootScale = 1.035,
	Duration = 0.14,
	SettleDuration = 0.08,
}
local PANEL_CLOSE_OPTIONS = {
	EndScale = 0.86,
	Duration = 0.1,
	HideOnComplete = true,
}

-- UIController
local UIController = Knit.CreateController({
	Name = "UIController",
	Template = {},
	Images = {},
	ActiveTweens = {
		impactTweens = {},
		displaySizeTweens = {},
	},
})
--|| Local Functions ||--
local function IsPlayerOnMobile()
	return UserInputService.TouchEnabled
end

local function GetGameScreenGui()
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	return playerGui:FindFirstChild("GameScreenGui")
end

local function FindFirstGuiObjectByName(root: Instance, names: { string }): GuiObject?
	for _, name in ipairs(names) do
		local candidate = root:FindFirstChild(name)
		if candidate and candidate:IsA("GuiObject") then
			return candidate
		end
	end

	return nil
end

local function ResolvePanelAnimationTarget(frameName: any): GuiObject?
	local gameScreenGui = GetGameScreenGui()
	if not gameScreenGui then
		return nil
	end

	local frameRoot = gameScreenGui:FindFirstChild(tostring(frameName or ""))
	if not frameRoot then
		return nil
	end

	local explicitTarget = frameRoot:FindFirstChild(PANEL_ANIMATION_TARGET_NAME, true)
	if explicitTarget and explicitTarget:IsA("GuiObject") then
		return explicitTarget
	end

	local namedTarget = FindFirstGuiObjectByName(frameRoot, {
		"Popup",
		"Content",
		"Main",
		"Center",
		"Container",
		"Panel",
		"Window",
	})
	if namedTarget then
		return namedTarget
	end

	if frameRoot:IsA("GuiObject") then
		return frameRoot
	end

	return nil
end

local function GetCurrentUI()
	local state = Store:getState()
	local uiReducer = state and state.UIReducer
	return uiReducer and uiReducer.CurrentUI
end

local function IsEmptyFrameName(frameName: any): boolean
	return frameName == nil or tostring(frameName) == ""
end

--|| Functions ||--
function UIController:_nextPanelAnimationToken()
	self._panelAnimationToken = (self._panelAnimationToken or 0) + 1
	return self._panelAnimationToken
end

function UIController:_resetCurrentFrame(resetSections: boolean?)
	Store:dispatch(UIActions.resetCurrentUI())

	if resetSections ~= false then
		Store:dispatch(UIActions.resetCurrentStoreSectionUI())
	end
end

function UIController:_playFrameOpen(frameName: string)
	local token = self:_nextPanelAnimationToken()

	task.defer(function()
		task.wait()

		if token ~= self._panelAnimationToken then
			return
		end

		local target = ResolvePanelAnimationTarget(frameName)
		if target then
			UIJuice.PopIn(target, PANEL_OPEN_OPTIONS)
		end
	end)
end

function UIController:_playCurrentFrameClose(options)
	options = options or {}

	local frameName = GetCurrentUI()
	local token = self:_nextPanelAnimationToken()

	local function finishClose()
		if token ~= self._panelAnimationToken then
			return
		end

		self:_resetCurrentFrame(options.ResetSections)
	end

	if IsEmptyFrameName(frameName) then
		finishClose()
		return
	end

	local target = ResolvePanelAnimationTarget(frameName)
	if not target then
		finishClose()
		return
	end

	local tween = UIJuice.PopOut(target, PANEL_CLOSE_OPTIONS, finishClose)
	if not tween then
		finishClose()
	end
end

function UIController:RemoveHUD(params: {})
	setmetatable(params, { __index = { ignoreTopFrame = true } })
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)

	task.delay(0.2, function()
		isUIShown = false
	end)
	local GameScreenGui = Players.LocalPlayer.PlayerGui:FindFirstChild("GameScreenGui", true)
	if not GameScreenGui then
		return
	end

	local LeftTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.LeftFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(-0.165, 0.42) }
	)
	local RightTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.RightFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(1.584, 0.42) }
	)
	local TopFrame = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.TopFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0, -1.075) }
	)
	local BottomFrame = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.BottomFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.5, 1.25) }
	)

	LeftTween:Play()
	RightTween:Play()
	BottomFrame:Play()
	if params.ignoreTopFrame == false then
		TopFrame:Play()
	end
end

function UIController:ShowHUD()
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)

	task.delay(0.2, function()
		isUIShown = true
	end)
	local GameScreenGui = Players.LocalPlayer.PlayerGui:FindFirstChild("GameScreenGui", true)
	if not GameScreenGui then
		return
	end

	local LeftTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.LeftFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.01, 0.42) }
	)
	local RightTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.RightFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.99, 0.42) }
	)
	local TopFrame = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.TopFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.5, 0) }
	)
	local BottomFrame = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.BottomFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.5, 0.99) }
	)

	LeftTween:Play()
	RightTween:Play()
	TopFrame:Play()
	BottomFrame:Play()
end

function UIController:HideBottomFrame()
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)
	local GameScreenGui = Players.LocalPlayer.PlayerGui:FindFirstChild("GameScreenGui", true)
	if not GameScreenGui then
		return
	end
	local BottomFrame =
		TweenService:Create(GameScreenGui.HUD.BottomFrame, Info, { ["Position"] = UDim2.fromScale(0.5, 1.25) })
	BottomFrame:Play()
	BottomFrame.Completed:Connect(function()
		BottomFrame:Destroy()
	end)
end

function UIController:ShowBottomFrame()
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)

	local GameScreenGui = Players.LocalPlayer.PlayerGui:FindFirstChild("GameScreenGui", true)
	if not GameScreenGui then
		return
	end
	local BottomFrame = TweenService:Create(
		GameScreenGui.HUD.BottomFrame,
		Info,
		{ ["Position"] = if IsPlayerOnMobile() then UDim2.fromScale(0.5, 0.85) else UDim2.fromScale(0.5, 0.895) }
	)
	BottomFrame:Play()
	BottomFrame.Completed:Connect(function()
		BottomFrame:Destroy()
	end)
end

function UIController:HideFrame()
	if not MatchController:IsPlayingMatch() then
		self:ShowHUD()
	end
	--:ResetCamera()
	self:_playCurrentFrameClose({
		ResetSections = true,
	})
end

function UIController:JustHideFrame()
	self:_playCurrentFrameClose({
		ResetSections = true,
	})
end

function UIController:ShowFrame(params: {})
	setmetatable(params, { __index = { frame = nil } })
	if params.frame == nil then
		return print("Frame", params.frame, "is NULL")
	end

	if MatchController:IsPlayingMatch() then
		return
	end

	Store:dispatch(UIActions.setCurrentUI(params.frame))
	self:_playFrameOpen(params.frame)

	if params.frame == "Store" then
		Store:dispatch(NotificationActions.setNotification("Store", nil))
	end
end

function UIController:ShowNewClickUnlock()
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)

	local NewClickFrameTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.NewClickFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(0.08, 0.70) }
	)

	NewClickFrameTween:Play()

	task.delay(15, function()
		NewClickFrameTween = TweenService:Create(
			Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.NewClickFrame,
			Info,
			{ ["Position"] = UDim2.fromScale(-0.3, 0.70) }
		)
		NewClickFrameTween:Play()
	end)
end

function UIController:InitTopFrameSize(size)
	if not TopFrameSizeInit then
		TopFrameSize = size
		TopFrameSizeInit = true
	end
end

function UIController:InitBottomFrameSize(size)
	if not BottomFrameSizeInit then
		BottomFrameSize = size
		BottomFrameSizeInit = true
	end
end

function UIController:HideNewClickFrame()
	local Info = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)
	local NewClickFrameTween = TweenService:Create(
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.NewClickFrame,
		Info,
		{ ["Position"] = UDim2.fromScale(-0.3, 0.70) }
	)
	NewClickFrameTween:Play()
end

function UIController:IsCurrentFrame(name)
	return Store:getState()["UIReducer"].CurrentUI == name
end

function UIController:MakeImpactRectangleClickButton()
	-- Cancel and destroy any existing impact tweens
	for _, tween in pairs(self.ActiveTweens.impactTweens) do
		if tween.Instance then
			tween:Cancel()
			tween:Destroy()
		end
	end
	-- Clear the tweens table
	table.clear(self.ActiveTweens.impactTweens)

	local BottomFrame = Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.BottomFrame
	local ImpactFrame = Instance.new("Frame", Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui"))
	ImpactFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ImpactFrame.BackgroundColor3 = Color3.fromRGB(136, 206, 250)
	ImpactFrame.BackgroundTransparency = 0.7
	ImpactFrame.Size = BottomFrame.Size - UDim2.fromScale(0, 0.14)
	ImpactFrame.Position = BottomFrame.Position - UDim2.fromScale(0.01, 0)

	local UICorner = Instance.new("UICorner", ImpactFrame)
	UICorner.CornerRadius = UDim.new(0.25, 0)

	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint", ImpactFrame)
	UIAspectRatioConstraint.AspectRatio = 1

	local TweenInf = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0)
	local TweenImpact = TweenService:Create(
		ImpactFrame,
		TweenInf,
		{ Size = BottomFrame.Size + UDim2.fromScale(0.08, 0.08), BackgroundTransparency = 1 }
	)

	self.ActiveTweens.impactTweens[1] = TweenImpact

	TweenImpact:Play()
	TweenImpact.Completed:Connect(function()
		ImpactFrame:Destroy()
	end)
end

function UIController:TweenTopDisplaySize(currency)
	-- Cancel and destroy any existing display size tweens
	for _, tween in pairs(self.ActiveTweens.displaySizeTweens) do
		if tween.Instance then
			tween:Cancel()
			tween:Destroy()
		end
	end
	-- Clear the tweens table
	table.clear(self.ActiveTweens.displaySizeTweens)

	local TopFrame = Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.TopFrame
	local FrameToTween = TopFrame:FindFirstChild(currency)

	self:InitTopFrameSize(FrameToTween.Size)

	local TweenInf2 = TweenInfo.new(0.14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	local TweenInf1 = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)

	local TweenSizeUp =
		TweenService:Create(FrameToTween, TweenInf1, { Size = TopFrameSize + UDim2.fromScale(0.15, 0.15) })

	local TweenSizeDown = TweenService:Create(FrameToTween, TweenInf2, { Size = TopFrameSize })

	self.ActiveTweens.displaySizeTweens[1] = TweenSizeUp
	self.ActiveTweens.displaySizeTweens[2] = TweenSizeDown

	TweenSizeDown.Completed:Connect(function()
		TweenSizeDown:Destroy()
	end)

	TweenSizeUp:Play()
	TweenSizeUp.Completed:Connect(function()
		TweenSizeDown:Play()
		TweenSizeUp:Destroy()
	end)
end

function UIController:ChangeShopCanvaPosition(number: number)
	local ShopScrollFrame =
		Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").Store.Content.Container.ShopScroll
	local Info = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)
	local TweenCanva = TweenService:Create(ShopScrollFrame, Info, {
		["CanvasPosition"] = Vector2.new(
			math.abs((ShopScrollFrame.CanvasSize.Y.Offset - ShopScrollFrame.AbsoluteSize.Y) * number),
			0
		),
	})
	TweenCanva:Play()
end

function UIController:TweenBottomButtomSize()
	local BottomFrame = Players.LocalPlayer.PlayerGui:WaitForChild("GameScreenGui").HUD.BottomFrame
	local BottomButtom = BottomFrame.Click

	self:InitBottomFrameSize(BottomButtom.Size)

	local TweenInf2 = TweenInfo.new(0.14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	local TweenInf1 = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	local TweenSizeUp =
		TweenService:Create(BottomButtom, TweenInf1, { Size = BottomFrameSize + UDim2.fromScale(0.15, 0.15) })

	local TweenSizeDown = TweenService:Create(BottomButtom, TweenInf2, { Size = BottomFrameSize })
	TweenSizeUp:Play()
	TweenSizeUp.Completed:Connect(function()
		UIController:MakeImpactRectangleClickButton()
		TweenSizeDown:Play()
	end)
end

function UIController:BuyArea(area)
	DataService:GetData(Players.LocalPlayer):andThen(function(data)
		local unlockedZones = data.Areas and data.Areas.Unlocked or { "Area01" }
		local lastUnlocked = unlockedZones[#unlockedZones]
		local lastUnlockedNumber = tonumber(string.match(lastUnlocked, "%d+"))
		local zoneNumber = tonumber(string.match(area.Id, "%d+"))

		if (zoneNumber - 1) ~= lastUnlockedNumber then
			NotificationController:Notify({
				text = "You must unlock previous zone first!",
				type = "ERROR",
				tag = "BuyArea",
			})
			return
		end

		if data.Wins >= area.Price then
			TeleportService:BuyTeleporter(area.Id)
			NotificationController:Notify({
				text = "You unlocked " .. area.Name .. "!",
				type = "SUCCESS",
				tag = "BuyArea",
			})
		else
			NotificationController:Notify({
				text = "You need " .. FormatNumber(area.Price - data.Wins) .. " more Wins!",
				type = "ERROR",
				tag = "BuyArea",
			})
		end
	end)
end

--|| Knit Lifecycle ||--
function UIController:KnitInit()
	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")

	DataCacheController = Knit.GetController("DataCacheController")
	NotificationController = Knit.GetController("NotificationController")
	MatchController = Knit.GetController("MatchController")

	self.Images = DataCacheController:GetFile("Images")

	task.delay(60 * 6, function()
		repeat
			task.wait()
		until isUIShown

		DataService:GetData():andThen(function(data)
			if data.TutorialComplete == false and data.TutorialStep == 1 then
				return
			end

			if Store:getState().StarterPacksReducer.BoughtStarterPacks < 1 then
				UIController:ShowFrame({ frame = FramesConstants.StarterPack })
				self.ShowHUD()
			end
		end)
	end)

	--[[task.delay(120, function()
		repeat
			task.wait()
		until isUIShown
		UIController:ShowFrame({ frame = FramesConstants.StarterPack })
		self.ShowHUD()
	end)

	task.delay(20 * 60, function()
		local StarterPack = Players.LocalPlayer.PlayerGui:FindFirstChild("StarterPack", true)
		if StarterPack ~= nil and StarterPack.Visible == true then
			self:HideFrame()
		end

		local HUD = Players.LocalPlayer.PlayerGui:FindFirstChild("HUD", true)
		if HUD ~= nil then
			local StarterPackUI = HUD:FindFirstChild("StarterPack", true)
			if StarterPackUI ~= nil then
				StarterPackUI:Destroy()
			end
		end
	end)]]
	print("[TELEPORT CONTROLLER] Controller loaded successfully.")
end

return UIController
