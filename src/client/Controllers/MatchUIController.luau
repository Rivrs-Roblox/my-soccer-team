local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages:WaitForChild("Knit"))

local MatchConstants = require(ReplicatedStorage.Shared.Data.Match.MatchConstants)
local TeamLogoConfig = require(ReplicatedStorage.Shared.Data.TeamLogoConfig)
local PlayerTeamIdentity = require(script.Parent.Parent.Helpers.PlayerTeamIdentity)
local UIJuice = require(script.Parent.Parent.Helpers.UIJuice)

local helpers =  ReplicatedStorage.Shared.Helpers
local formatnumber = require(helpers.Numbers.FormatNumber)

local LocalPlayer = Players.LocalPlayer

local PLAYER_TEAM_NAME = "Player"
local PLAYER_TEAM_LOGO = "rbxassetid://81212587492189"
local BROADCAST_HUD_ENABLED = true
local BROADCAST_CLOCK_REAL_SECONDS_PER_MATCH_MINUTE = 5
local BROADCAST_CLOCK_START_MINUTE = 85
local QTE_RESULT_BANNER_HOLD = 0.7
local QTE_BROADCAST_CLOCK_TIME_SCALE = 0.1
local GOAL_SCORER_PANEL_HOLD_SECONDS = 3.2

local MIDDLE_START = 0.18
local MIDDLE_END = 0.82

local EXCELLENT_CAMERA_EFFECT_DURATION = 0.95
local EXCELLENT_CAMERA_EFFECT_FADE_IN = 0.08
local EXCELLENT_CAMERA_EFFECT_FADE_OUT = 0.24
local TRANSITION_OVERLAY_ZINDEX = 100000

local EXCELLENT_CAMERA_EFFECT_SHAKE_CONFIG = {
	Fast_1 = { X = 0.018, Y = 0.008, Rotation = 1.6, Speed = 18.0, Phase = 0.00 },
	Fast_2 = { X = 0.012, Y = 0.014, Rotation = -2.4, Speed = 23.0, Phase = 1.35 },
	Fast_3 = { X = 0.024, Y = 0.006, Rotation = 3.0, Speed = 15.5, Phase = 2.60 },
	Default = { X = 0.014, Y = 0.010, Rotation = 1.8, Speed = 20.0, Phase = 0.75 },
}

local GREEN_WIDTH_BY_STEP = {
	[1] = 0.22,
	[2] = 0.18,
	[3] = 0.14,
	[4] = 0.115,
	[5] = 0.10,
}

local MatchUIController = Knit.CreateController({
	Name = "MatchUIController",
})

local function GetPingPongAlpha(elapsed, duration)
	if duration <= 0 then
		return 0.5
	end

	local loopValue = (elapsed / duration) % 2
	if loopValue > 1 then
		return 2 - loopValue
	end

	return loopValue
end

local function Clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function RaiseGuiObjectTreeZIndex(root: Instance?, zIndex: number)
	if not root then
		return
	end

	if root:IsA("GuiObject") then
		root.ZIndex = zIndex
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = zIndex + 1
		end
	end
end

local function ConfigureQteInputLayer(layer: Instance?)
	if not layer then
		return
	end

	if layer:IsA("GuiObject") then
		layer.BackgroundTransparency = 1
		layer.BorderSizePixel = 0
		layer.Active = false
	end

	if layer:IsA("GuiButton") then
		layer.AutoButtonColor = false
		layer.Selectable = false
	end
end

local function SetGuiObjectBackgroundTransparency(instance: Instance?, transparency: number)
	if instance and instance:IsA("GuiObject") then
		instance.BackgroundTransparency = transparency
		instance.BorderSizePixel = 0
	end
end

local function SetTextVisible(instance: Instance?)
	if instance and (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
		instance.TextTransparency = 0
	end
end

local function ConfigureQteVisualTree(layer: Instance?)
	if not layer then
		return
	end

	ConfigureQteInputLayer(layer)

	local barBack = layer:FindFirstChild("BarBack")
	SetGuiObjectBackgroundTransparency(barBack, 1)

	for _, name in ipairs({ "RedLeft", "YellowLeft", "Green", "YellowRight", "RedRight" }) do
		local segment = barBack and barBack:FindFirstChild(name)
		SetGuiObjectBackgroundTransparency(segment, 0)
	end

	SetTextVisible(layer:FindFirstChild("StepLabel"))
	SetTextVisible(layer:FindFirstChild("ActionLabel"))
	SetTextVisible(layer:FindFirstChild("HintLabel"))
	SetTextVisible(layer:FindFirstChild("TargetLabel"))
end

local function NormalizeAssetId(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end

	if type(value) ~= "string" or value == "" then
		return ""
	end

	if string.find(value, "rbxassetid://", 1, true) then
		return value
	end

	if tonumber(value) ~= nil then
		return "rbxassetid://" .. value
	end

	return value
end

local function GetIntroDataFromPayload(payload)
	payload = typeof(payload) == "table" and payload or {}
	local introData = payload.IntroData
	if typeof(introData) == "table" then
		return introData
	end

	local tournament = payload.Tournament
	if typeof(tournament) == "table" and typeof(tournament.Intro) == "table" then
		return tournament.Intro
	end

	return {}
end

local function ResolveTeamCode(areaId, teamName, fallback, isPlayer)
	if isPlayer then
		return PlayerTeamIdentity.GetShortName(fallback)
	end

	if TeamLogoConfig and TeamLogoConfig.GetTeamShortName then
		local code = TeamLogoConfig.GetTeamShortName(tostring(areaId or "Area01"), tostring(teamName or ""))
		if type(code) == "string" and code ~= "" then
			return code
		end
	end

	return tostring(fallback or "TBD")
end

local function ResolveTeamLogo(areaId, teamName, providedLogo, isPlayer)
	if isPlayer then
		return PlayerTeamIdentity.GetThumbnail(PLAYER_TEAM_LOGO)
	end

	local logo = NormalizeAssetId(providedLogo)
	local isPlaceholder = logo == "" or logo == "rbxassetid://0" or string.find(logo, "000000", 1, true)
	if not isPlaceholder then
		return logo
	end

	if TeamLogoConfig and TeamLogoConfig.GetTeamLogo then
		local configLogo = TeamLogoConfig.GetTeamLogo(tostring(areaId or "Area01"), tostring(teamName or ""))
		if type(configLogo) == "string" and configLogo ~= "" then
			return configLogo
		end
	end

	return logo
end

local function FormatBroadcastClock(minute, second)
	return string.format("%02d:%02d", tonumber(minute) or 0, tonumber(second) or 0)
end

local function FormatGoalMinute(totalSeconds)
	local minute = math.max(0, math.floor((tonumber(totalSeconds) or 0) / 60))
	return string.format("%d'", minute)
end

local function SetImageIfFound(instance, imageId)
	local image = NormalizeAssetId(imageId)
	if image == "" then
		return
	end

	if instance and (instance:IsA("ImageLabel") or instance:IsA("ImageButton")) then
		instance.Image = image
		instance.Visible = true
		instance.ImageTransparency = 0
	end
end

local function ApplyBasicStroke(root, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = root
	return stroke
end

local function ApplyBasicCorner(root, radius)
	local corner = Instance.new("UICorner")
	corner.Name = "Corner"
	corner.CornerRadius = radius
	corner.Parent = root
	return corner
end

local function FindDescendantByName(root, name)
	if not root then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == name then
			return descendant
		end
	end

	return nil
end

local function FindFirstTextLabel(root, names)
	if not root then
		return nil
	end

	for _, name in ipairs(names) do
		local direct = root:FindFirstChild(name, true)
		if direct and direct:IsA("TextLabel") then
			return direct
		end
	end

	return nil
end

local function FindFirstImageObject(root, names)
	if not root then
		return nil
	end

	for _, name in ipairs(names) do
		local direct = root:FindFirstChild(name, true)
		if direct and (direct:IsA("ImageLabel") or direct:IsA("ImageButton")) then
			return direct
		end
	end

	return nil
end

local function SetGuiVisible(instance, visible)
	if instance and instance:IsA("GuiObject") then
		instance.Visible = visible
	end
end

local function SetTextIfFound(instance, text)
	if instance and instance:IsA("TextLabel") then
		instance.Text = tostring(text or "")
		instance.Visible = true
		instance.TextTransparency = 0
	end
end

local function SetImageFromSource(target, source)
	if not (target and source) then
		return
	end

	if not (target:IsA("ImageLabel") or target:IsA("ImageButton")) then
		return
	end

	if not (source:IsA("ImageLabel") or source:IsA("ImageButton")) then
		return
	end

	if source.Image ~= "" then
		target.Image = source.Image
		target.Visible = true
		target.ImageTransparency = 0
	end
end

local function SetPlayerImageIfMissing(target)
	if target and (target:IsA("ImageLabel") or target:IsA("ImageButton")) then
		target.Image = PlayerTeamIdentity.GetThumbnail(PLAYER_TEAM_LOGO)
		target.Visible = true
		target.ImageTransparency = 0
	end
end

local function ResolvePlayerTeamName(value)
	local text = tostring(value or "")
	if text == "" or text == "FC Rivrs" or text == "Rivrs FC" then
		return PlayerTeamIdentity.GetName(PLAYER_TEAM_NAME)
	end

	return text
end

local function IsExcellentTier(qteTier)
	local tierName = string.upper(tostring(qteTier or ""))
	return tierName == "GREEN" or tierName == "PERFECT" or tierName == "EXCELLENT"
end

local function IsShootAction(actionName)
	return string.lower(tostring(actionName or "")) == "shoot"
end

local function FormatQteMultiplier(multiplier)
	local value = tonumber(multiplier) or 1
	if math.abs(value - math.floor(value + 0.5)) < 0.001 then
		return string.format("x%d", math.floor(value + 0.5))
	end
	return string.format("x%.1f", value)
end

local function ResolveQteTierColor(qteTier)
	local tierName = string.lower(tostring(qteTier or ""))
	if tierName == "green" or tierName == "perfect" or tierName == "excellent" then
		return Color3.fromRGB(106, 255, 138)
	elseif tierName == "red" or tierName == "miss" or tierName == "failed" then
		return Color3.fromRGB(255, 110, 110)
	end

	return Color3.fromRGB(255, 238, 45)
end

local function ResolveQteFeedback(qteTier, suppliedMultiplier)
	local tierName = string.upper(tostring(qteTier or "YELLOW"))
	local normalizedTier = "Yellow"
	local label = "GOOD"
	local color = Color3.fromRGB(255, 221, 58)

	if tierName == "GREEN" or tierName == "PERFECT" or tierName == "EXCELLENT" then
		normalizedTier = "Green"
		label = "PERFECT"
		color = Color3.fromRGB(80, 255, 91)
	elseif tierName == "RED" or tierName == "BAD" or tierName == "MISS" or tierName == "FAILED" then
		normalizedTier = "Red"
		label = "BAD"
		color = Color3.fromRGB(255, 70, 70)
	end

	local fallbackMultiplier = MatchConstants.QTE_TIER_MULTIPLIERS[normalizedTier] or 1
	return label, color, tonumber(suppliedMultiplier) or fallbackMultiplier
end

local function SetImageTransparencySafe(guiObject, transparency)
	pcall(function()
		guiObject.ImageTransparency = transparency
	end)
end

local function GetImageTransparencySafe(guiObject)
	local ok, value = pcall(function()
		return guiObject.ImageTransparency
	end)
	if ok and typeof(value) == "number" then
		return value
	end
	return nil
end

local function ReadNumericText(label, fallback)
	if label and label:IsA("TextLabel") then
		local raw = tostring(label.Text or "")
		local numberText = string.match(raw, "%-?%d+%.?%d*")
		local value = tonumber(numberText)
		if value ~= nil then
			return value
		end
	end

	return tonumber(fallback) or 0
end

local function GetPayloadWins(payload)
	payload = typeof(payload) == "table" and payload or {}

	local candidates = {
		payload.AwardedWins,
		payload.MatchRewardPreviewWins,
		payload.RewardWins,
		payload.WinsReward,
		payload.WinReward,
		payload.RewardAmount,
	}

	for _, value in ipairs(candidates) do
		local numericValue = tonumber(value)
		if numericValue and numericValue > 0 then
			return numericValue
		end
	end

	return 0
end

local function GetPayloadSessionId(payload)
	if typeof(payload) ~= "table" then
		return nil
	end

	local sessionId = payload.SessionId
	if sessionId == nil then
		return nil
	end

	return tostring(sessionId)
end

function MatchUIController:_buildRandomQteConfig(stepIndex)
	local greenWidth = GREEN_WIDTH_BY_STEP[tonumber(stepIndex) or 1] or 0.14
	local minStart = MIDDLE_START
	local maxStart = MIDDLE_END - greenWidth

	local rng = Random.new(math.floor(os.clock() * 1000000) + (tonumber(stepIndex) or 0) * 97)
	local greenStart = rng:NextNumber(minStart, maxStart)
	local greenEnd = greenStart + greenWidth

	return {
		RedLeft = { Position = 0.00, Width = MIDDLE_START },
		YellowLeft = { Position = MIDDLE_START, Width = greenStart - MIDDLE_START },
		Green = { Position = greenStart, Width = greenWidth },
		YellowRight = { Position = greenEnd, Width = MIDDLE_END - greenEnd },
		RedRight = { Position = MIDDLE_END, Width = 1 - MIDDLE_END },
		GreenStart = greenStart,
		GreenEnd = greenEnd,
	}
end

function MatchUIController:_resolveTierFromAlpha(alpha)
	local layout = self._currentQteLayout
	if not layout then
		return "Yellow"
	end

	if alpha >= layout.GreenStart and alpha <= layout.GreenEnd then
		return "Green"
	end

	if alpha >= MIDDLE_START and alpha <= MIDDLE_END then
		return "Yellow"
	end

	return "Red"
end

function MatchUIController:_getPlayerGui()
	return LocalPlayer:WaitForChild("PlayerGui", 10)
end

function MatchUIController:_ensureGui()
	if self._guiInitialized then
		return
	end

	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	local matchGui = playerGui:WaitForChild("RoactTree", 10)
	if not matchGui then
		warn("[MatchUIController] Could not find RoactTree in PlayerGui")
		return
	end

	self._matchGui = matchGui
	self._matchGui.Enabled = true

	self._blackoutFrame = matchGui:WaitForChild("Blackout")
	self._statusTextLabel = self._blackoutFrame:WaitForChild("StatusText")
	RaiseGuiObjectTreeZIndex(self._blackoutFrame, TRANSITION_OVERLAY_ZINDEX)

	self._centerPopupLabel = matchGui:WaitForChild("CenterPopup")
	self._centerPopupLabel.Visible = false
	self._centerPopupLabel.Text = ""
	-- Keep action result text below the TV scoreboard so it does not stack with
	-- the broadcast scoreboard or action banner.
	if self._centerPopupLabel:IsA("GuiObject") then
		self._centerPopupLabel.AnchorPoint = Vector2.new(0.5, 0)
		self._centerPopupLabel.Position = UDim2.fromScale(0.5, 0.185)
		self._centerPopupLabel.Size = UDim2.fromScale(0.58, 0.075)
		self._centerPopupLabel.ZIndex = 730
	end

	self._resultPopupGroup = matchGui:WaitForChild("ResultPopup")
	self._resultPopupGroup.Visible = false
	self._resultLoseLabel = self._resultPopupGroup:FindFirstChild("Lose") or self._resultPopupGroup:FindFirstChild("Title")
	self._resultWinLabel = self._resultPopupGroup:FindFirstChild("Win") or self._resultPopupGroup:FindFirstChild("Title")
	self._resultRewardsLabel = self._resultPopupGroup:WaitForChild("Rewards")

	self._comparePillFrame = matchGui:WaitForChild("ComparePill")
	self._compareLabel = self._comparePillFrame:WaitForChild("Label")

	self._exitButton = matchGui:WaitForChild("ExitButton")
	
	self._goalsPillFrame = matchGui:WaitForChild("GoalsPill")
	self._goalsLabel = self._goalsPillFrame:WaitForChild("GoalsLabel")

	self._qteLayerButton = matchGui:WaitForChild("QteLayer")
	ConfigureQteVisualTree(self._qteLayerButton)
	self._qteLayerButton.Visible = false
	self._qteStepLabel = self._qteLayerButton:WaitForChild("StepLabel")
	self._qteActionLabel = self._qteLayerButton:WaitForChild("ActionLabel")
	self._qteTargetLabel = self._qteLayerButton:WaitForChild("TargetLabel")

	local barBack = self._qteLayerButton:WaitForChild("BarBack")
	self._qteRedLeft = barBack:WaitForChild("RedLeft")
	self._qteYellowLeft = barBack:WaitForChild("YellowLeft")
	self._qteGreen = barBack:WaitForChild("Green")
	self._qteYellowRight = barBack:WaitForChild("YellowRight")
	self._qteRedRight = barBack:WaitForChild("RedRight")
	self._qtePointer = barBack:WaitForChild("Pointer")

	self._exitButton.Activated:Connect(function()
		if self._exitCallback then
			self._exitCallback()
		end
	end)

	

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not self._activeQte or self._activeQte.Locked then
			return
		end

		local isPointerSubmit = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		local isKeyboardSubmit = input.KeyCode == Enum.KeyCode.Space

		if isPointerSubmit or isKeyboardSubmit then
			if gameProcessed then
				if not isPointerSubmit then
					return
				end

				local exitButton = self._exitButton
				if exitButton and exitButton.Visible then
					local pos = input.Position
					local absPos = exitButton.AbsolutePosition
					local absSize = exitButton.AbsoluteSize
					if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and
					   pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
						return
					end
				end
			end

			if self._qteConfirmCallback then
				self._qteConfirmCallback()
			end
		end
	end)

	self._guiInitialized = true
end

function MatchUIController:_getBlackoutFrame()
	return self._blackoutFrame
end

function MatchUIController:_getStatusLabel()
	return self._statusTextLabel
end

function MatchUIController:_getExitButton()
	return self._exitButton
end

function MatchUIController:_getGoalsPill()
	return self._goalsPillFrame
end

function MatchUIController:_getGoalsLabel()
	return self._goalsLabel
end

function MatchUIController:_getCenterPopup()
	return self._centerPopupLabel
end

function MatchUIController:_getComparePill()
	return self._comparePillFrame
end

function MatchUIController:_getCompareLabel()
	return self._compareLabel
end

function MatchUIController:_getQteLayer()
	return self._qteLayerButton
end

function MatchUIController:_raiseTransitionOverlay()
	RaiseGuiObjectTreeZIndex(self:_getBlackoutFrame(), TRANSITION_OVERLAY_ZINDEX)
end

function MatchUIController:_suppressMatchHudForTransition()
	local qteLayer = self:_getQteLayer()
	if qteLayer then
		qteLayer.Visible = false
	end

	self._activeQte = nil
	self._currentCursorAlpha = 0.5
	self._currentQteLayout = nil
	self:SetQteConfirmCallback(nil)

	local resultPopup = self._resultPopupGroup
	if resultPopup then
		resultPopup.Visible = false
	end

	local centerPopup = self:_getCenterPopup()
	if centerPopup then
		centerPopup.Visible = false
		centerPopup.Text = ""
	end

	if self.HideActionBannerNow then
		self:HideActionBannerNow()
	elseif self.HideActionBanner then
		self:HideActionBanner(0)
	end
end

function MatchUIController:_getQteStepLabel()
	return self._qteStepLabel
end

function MatchUIController:_getQteActionLabel()
	return self._qteActionLabel
end

function MatchUIController:_getQteTargetLabel()
	return self._qteTargetLabel
end

function MatchUIController:_getQtePointer()
	return self._qtePointer
end

function MatchUIController:_getQteRedLeft()
	return self._qteRedLeft
end

function MatchUIController:_getQteYellowLeft()
	return self._qteYellowLeft
end

function MatchUIController:_getQteGreen()
	return self._qteGreen
end

function MatchUIController:_getQteYellowRight()
	return self._qteYellowRight
end

function MatchUIController:_getQteRedRight()
	return self._qteRedRight
end

function MatchUIController:_applyQteLayout(layout)
	local redLeft = self:_getQteRedLeft()
	local yellowLeft = self:_getQteYellowLeft()
	local green = self:_getQteGreen()
	local yellowRight = self:_getQteYellowRight()
	local redRight = self:_getQteRedRight()

	if redLeft then
		redLeft.Position = UDim2.fromScale(layout.RedLeft.Position, 0)
		redLeft.Size = UDim2.fromScale(layout.RedLeft.Width, 1)
	end

	if yellowLeft then
		yellowLeft.Position = UDim2.fromScale(layout.YellowLeft.Position, 0)
		yellowLeft.Size = UDim2.fromScale(layout.YellowLeft.Width, 1)
	end

	if green then
		green.Position = UDim2.fromScale(layout.Green.Position, 0)
		green.Size = UDim2.fromScale(layout.Green.Width, 1)
	end

	if yellowRight then
		yellowRight.Position = UDim2.fromScale(layout.YellowRight.Position, 0)
		yellowRight.Size = UDim2.fromScale(layout.YellowRight.Width, 1)
	end

	if redRight then
		redRight.Position = UDim2.fromScale(layout.RedRight.Position, 0)
		redRight.Size = UDim2.fromScale(layout.RedRight.Width, 1)
	end
end

function MatchUIController:_setPointerAlpha(alpha)
	self._currentCursorAlpha = Clamp(alpha, 0, 1)

	local pointer = self:_getQtePointer()
	if pointer then
		pointer.Position = UDim2.fromScale(self._currentCursorAlpha, 0.5)
	end
end

function MatchUIController:_startCursorLoop()
	if self._cursorConnection then
		return
	end

	self._cursorConnection = RunService.RenderStepped:Connect(function()
		if not self._activeQte then
			return
		end

		if self._activeQte.Locked then
			return
		end

		local elapsed = os.clock() - self._activeQte.StartedAt
		local alpha = GetPingPongAlpha(elapsed, MatchConstants.QTE_CURSOR_TRAVEL_TIME)
		self:_setPointerAlpha(alpha)
	end)
end

function MatchUIController:_stopCursorLoop()
	if not self._cursorConnection then
		return
	end

	self._cursorConnection:Disconnect()
	self._cursorConnection = nil
end

function MatchUIController:_resolveCameraEffectRefs()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local cameraEffect = playerGui:FindFirstChild("CameraEffect")
	if not cameraEffect then
		return nil
	end

	local fastImages = {}
	for _, name in ipairs({ "Fast_1", "Fast_2", "Fast_3" }) do
		local fast = cameraEffect:FindFirstChild(name, true)
		if fast and fast:IsA("GuiObject") then
			table.insert(fastImages, fast)
		end
	end

	if #fastImages == 0 then
		return nil
	end

	return {
		Root = cameraEffect,
		FastImages = fastImages,
	}
end

function MatchUIController:_stopExcellentCameraEffect()
	self._excellentEffectToken = (self._excellentEffectToken or 0) + 1

	for _, tween in ipairs(self._excellentEffectTweens or {}) do
		pcall(function()
			tween:Cancel()
		end)
	end
	self._excellentEffectTweens = {}

	if self._excellentEffectConnection then
		self._excellentEffectConnection:Disconnect()
		self._excellentEffectConnection = nil
	end

	local records = self._excellentEffectRecords
	if records then
		for guiObject, record in pairs(records) do
			if guiObject and guiObject.Parent then
				guiObject.Visible = record.Visible
				guiObject.Position = record.Position
				guiObject.Rotation = record.Rotation
				if record.ImageTransparency ~= nil then
					SetImageTransparencySafe(guiObject, record.ImageTransparency)
				end
			end
		end
	end
	self._excellentEffectRecords = nil

	local root = self._excellentEffectRoot
	if root and root.Parent then
		local rootVisible = self._excellentEffectRootVisible
		local rootEnabled = self._excellentEffectRootEnabled
		if root:IsA("ScreenGui") then
			if rootEnabled ~= nil then
				root.Enabled = rootEnabled
			end
		elseif root:IsA("GuiObject") then
			if rootVisible ~= nil then
				root.Visible = rootVisible
			end
		end
	end
	self._excellentEffectRoot = nil
	self._excellentEffectRootVisible = nil
	self._excellentEffectRootEnabled = nil
end

function MatchUIController:_playExcellentCameraEffect(options)
	self:_ensureGui()
	self:_stopExcellentCameraEffect()

	local refs = self:_resolveCameraEffectRefs()
	if not refs then
		return
	end

	options = typeof(options) == "table" and options or {}
	local duration = math.max(tonumber(options.Duration) or EXCELLENT_CAMERA_EFFECT_DURATION, 0.25)
	local fadeOutDelay = math.max(duration - EXCELLENT_CAMERA_EFFECT_FADE_OUT, 0.05)

	self._excellentEffectToken = (self._excellentEffectToken or 0) + 1
	local token = self._excellentEffectToken
	self._excellentEffectRoot = refs.Root
	self._excellentEffectTweens = {}
	self._excellentEffectRecords = {}

	if refs.Root:IsA("ScreenGui") then
		self._excellentEffectRootEnabled = refs.Root.Enabled
		refs.Root.Enabled = true
		pcall(function()
			refs.Root.DisplayOrder = math.max(refs.Root.DisplayOrder, 640)
		end)
	elseif refs.Root:IsA("GuiObject") then
		self._excellentEffectRootVisible = refs.Root.Visible
		refs.Root.Visible = true
	end

	local activeImages = {}
	for index, fast in ipairs(refs.FastImages) do
		self._excellentEffectRecords[fast] = {
			Visible = fast.Visible,
			Position = fast.Position,
			Rotation = fast.Rotation,
			ImageTransparency = GetImageTransparencySafe(fast),
		}

		fast.Visible = true
		fast.ZIndex = math.max(fast.ZIndex, 640)
		SetImageTransparencySafe(fast, 1)

		local fadeIn = TweenService:Create(
			fast,
			TweenInfo.new(EXCELLENT_CAMERA_EFFECT_FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ ImageTransparency = 0.02 }
		)
		table.insert(self._excellentEffectTweens, fadeIn)
		fadeIn:Play()

		local config = EXCELLENT_CAMERA_EFFECT_SHAKE_CONFIG[fast.Name]
			or EXCELLENT_CAMERA_EFFECT_SHAKE_CONFIG.Default
		activeImages[#activeImages + 1] = {
			Gui = fast,
			BasePosition = fast.Position,
			BaseRotation = fast.Rotation,
			Config = config,
			Index = index,
		}

		task.delay(fadeOutDelay, function()
			if token ~= self._excellentEffectToken or not fast.Parent then
				return
			end

			local fadeOut = TweenService:Create(
				fast,
				TweenInfo.new(EXCELLENT_CAMERA_EFFECT_FADE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }
			)
			table.insert(self._excellentEffectTweens, fadeOut)
			fadeOut:Play()
		end)
	end

	local startedAt = os.clock()
	self._excellentEffectConnection = RunService.RenderStepped:Connect(function()
		if token ~= self._excellentEffectToken then
			return
		end

		local elapsed = os.clock() - startedAt
		local lifeAlpha = math.clamp(elapsed / duration, 0, 1)
		local strength = math.sin(math.pi * lifeAlpha)

		for _, imageData in ipairs(activeImages) do
			local gui = imageData.Gui
			if gui and gui.Parent then
				local config = imageData.Config
				local t = elapsed * config.Speed + config.Phase
				local x = math.sin(t) * config.X * strength
				local y = math.cos(t * 1.31) * config.Y * strength
				local rotation = math.sin(t * 1.17) * config.Rotation * strength

				gui.Position = imageData.BasePosition + UDim2.fromScale(x, y)
				gui.Rotation = imageData.BaseRotation + rotation
			end
		end
	end)

	task.delay(duration, function()
		if token ~= self._excellentEffectToken then
			return
		end

		self:_stopExcellentCameraEffect()
	end)
end

function MatchUIController:PlayExcellentSpeedEffect(options)
	self:_playExcellentCameraEffect(options)
end

function MatchUIController:StopExcellentSpeedEffect()
	self:_stopExcellentCameraEffect()
end

function MatchUIController:_showCenterPopup(text, color, duration)
	self:_ensureGui()

	self._centerPopupToken += 1
	local myToken = self._centerPopupToken

	local popup = self:_getCenterPopup()
	if not popup then
		return
	end

	self:_closeQteResultReveal(true)

	-- Save the original Size and Position if not already saved
	if not self._centerPopupOriginalSize then
		self._centerPopupOriginalSize = popup.Size
		self._centerPopupOriginalPosition = popup.Position
		self._centerPopupOriginalFont = popup.Font
		self._centerPopupOriginalTextScaled = popup.TextScaled
	end

	if text == nil or text == "" then
		local oldText = popup.Text
		if oldText == "" or not popup.Visible then
			popup.Visible = false
			popup.Text = ""
			UIJuice.Cancel(popup)
			-- Restore original scale
			if self._centerPopupOriginalSize then
				popup.Size = self._centerPopupOriginalSize
				popup.Position = self._centerPopupOriginalPosition
				popup.AnchorPoint = Vector2.new(0.5, 0)
				popup.Rotation = 0
				popup.Font = self._centerPopupOriginalFont
				popup.TextScaled = self._centerPopupOriginalTextScaled
			end
			return
		end

		UIJuice.PopOut(popup, {
			Duration = 0.10,
			EndScale = 0.78,
		}, function()
			if myToken ~= self._centerPopupToken then
				return
			end

			popup.Text = ""
			-- Restore original scale
			if self._centerPopupOriginalSize then
				popup.Size = self._centerPopupOriginalSize
				popup.Position = self._centerPopupOriginalPosition
				popup.AnchorPoint = Vector2.new(0.5, 0)
				popup.Rotation = 0
				popup.Font = self._centerPopupOriginalFont
				popup.TextScaled = self._centerPopupOriginalTextScaled
			end
		end)
		return
	end

	local popupColor = color or Color3.fromRGB(255, 255, 255)
	popup.Text = text
	popup.TextColor3 = popupColor
	popup.TextStrokeColor3 = Color3.fromRGB(12, 18, 40)
	popup.TextStrokeTransparency = 0.12
	popup.Visible = true

	local isQteResultPopup = string.match(text, "^PERFECT%s+x%d+%.%d$") ~= nil
		or string.match(text, "^GOOD%s+x%d+%.%d$") ~= nil
		or string.match(text, "^BAD%s+x%d+%.%d$") ~= nil

	if text == "GOAL!" then
		-- Make it 2.8x bigger and shift position slightly to stay centered
		popup.Size = UDim2.fromScale(
			self._centerPopupOriginalSize.X.Scale * 2.8,
			self._centerPopupOriginalSize.Y.Scale * 2.8
		)
		popup.Position = UDim2.new(
			0.5, 0,
			self._centerPopupOriginalPosition.Y.Scale + 0.05, 0
		)
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Rotation = -6 -- Dynamic tilt
		popup.Font = Enum.Font.GothamBlack
		popup.TextScaled = true

		-- Spawn UI particles/confetti!
		self:_spawnUiGoalParticles(popup)

		-- Second confetti burst after 0.8s for a sustained celebration feel
		local goalBurstToken = myToken
		task.delay(0.8, function()
			if goalBurstToken ~= self._centerPopupToken then return end
			if popup and popup.Visible then
				self:_spawnUiGoalParticles(popup)
			end
		end)
	elseif isQteResultPopup then
		popup.Size = UDim2.fromScale(
			self._centerPopupOriginalSize.X.Scale * 1.85,
			self._centerPopupOriginalSize.Y.Scale * 1.85
		)
		popup.Position = UDim2.fromScale(0.5, 0.19)
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.Rotation = string.find(text, "BAD", 1, true) and 3 or -3
		popup.Font = Enum.Font.GothamBlack
		popup.TextScaled = true

		self:_openQteResultReveal(popup, popupColor)
		self:_spawnUiQteTierParticles(popup, popupColor, 40)
		local qteBurstToken = myToken
		task.delay(0.22, function()
			if qteBurstToken ~= self._centerPopupToken then
				return
			end
			if popup and popup.Visible then
				self:_spawnUiQteTierParticles(popup, popupColor, 24)
			end
		end)
	else
		-- Reset to original size for other popups (PERFECT, GOOD, etc.)
		popup.Size = self._centerPopupOriginalSize
		popup.Position = self._centerPopupOriginalPosition
		popup.AnchorPoint = Vector2.new(0.5, 0)
		popup.Rotation = 0
		popup.Font = self._centerPopupOriginalFont
		popup.TextScaled = self._centerPopupOriginalTextScaled
	end

	-- Some artist labels contain UIGradient/UIStroke descendants. Force them to
	-- follow the result color so SUCCESS does not stay dark green/purple.
	for _, descendant in ipairs(popup:GetDescendants()) do
		if descendant:IsA("UIGradient") then
			if text == "GOAL!" then
				-- A gorgeous orange-gold-yellow gradient sequence for a festive feel
				descendant.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 0)),    -- Orange/Dark Gold
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 225, 30)),  -- Bright Gold
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 180))   -- Light Gold
				})
			else
				descendant.Color = ColorSequence.new(popupColor)
			end
		elseif descendant:IsA("UIStroke") then
			if text == "GOAL!" then
				if not descendant:GetAttribute("OrigThickness") then
					descendant:SetAttribute("OrigThickness", descendant.Thickness)
				end
				if not descendant:GetAttribute("OrigTransparency") then
					descendant:SetAttribute("OrigTransparency", descendant.Transparency)
				end
				descendant.Color = Color3.fromRGB(12, 18, 40)
				descendant.Thickness = 6 -- Thicker border for GOAL!
				descendant.Transparency = 0
			else
				local origThickness = descendant:GetAttribute("OrigThickness")
				local origTransparency = descendant:GetAttribute("OrigTransparency")
				descendant.Color = Color3.fromRGB(12, 18, 40)
				descendant.Thickness = origThickness or 3
				descendant.Transparency = origTransparency or 0.12
			end
		end
	end

	-- GOAL! gets a dramatic, bouncy pop-in. Other popups keep the snappy default.
	if text == "GOAL!" then
		UIJuice.PopIn(popup, {
			StartScale = 0.50,
			OvershootScale = 1.30,
			Duration = 0.20,
			SettleDuration = 0.22,
		})
	else
		UIJuice.PopIn(popup, {
			StartScale = 0.68,
			OvershootScale = 1.12,
			Duration = 0.15,
			SettleDuration = 0.16,
		})
	end

	task.delay(duration or 0.9, function()
		if myToken ~= self._centerPopupToken then
			return
		end

		if popup then
			if isQteResultPopup then
				self:_closeQteResultReveal(false)
			end

			-- GOAL! fades out slower and larger for a dramatic exit
			local popOutDuration = (text == "GOAL!") and 0.35 or 0.12
			local popOutEndScale = (text == "GOAL!") and 0.90 or 0.80
			UIJuice.PopOut(popup, {
				Duration = popOutDuration,
				EndScale = popOutEndScale,
			}, function()
				if myToken ~= self._centerPopupToken then
					return
				end

				popup.Text = ""
				-- Restore original scale
				if self._centerPopupOriginalSize then
					popup.Size = self._centerPopupOriginalSize
					popup.Position = self._centerPopupOriginalPosition
					popup.AnchorPoint = Vector2.new(0.5, 0)
					popup.Rotation = 0
					popup.Font = self._centerPopupOriginalFont
					popup.TextScaled = self._centerPopupOriginalTextScaled
				end
			end)
		end
	end)
end

function MatchUIController:_spawnUiGoalParticles(popup)
	local parent = popup.Parent
	if not parent then return end

	local colors = {
		Color3.fromRGB(255, 215, 0),    -- Gold
		Color3.fromRGB(255, 140, 0),    -- Dark Orange
		Color3.fromRGB(255, 255, 120),   -- Pale Yellow
		Color3.fromRGB(255, 75, 75),     -- Red
		Color3.fromRGB(75, 255, 75),     -- Green
		Color3.fromRGB(75, 220, 255),    -- Cyan
		Color3.fromRGB(255, 105, 180),   -- Hot Pink
		Color3.fromRGB(186, 85, 211),    -- Medium Orchid
	}

	local basePosition = popup.Position
	local startXScale = basePosition.X.Scale
	local startYScale = basePosition.Y.Scale
	local startXOffset = basePosition.X.Offset
	local startYOffset = basePosition.Y.Offset

	local particleCount = 45 -- More particles for a festive feel!
	for i = 1, particleCount do
		local particle = Instance.new("Frame")
		particle.Name = "ConfettiParticle"
		particle.AnchorPoint = Vector2.new(0.5, 0.5)

		-- Diverse particle shapes (Circle, Square, Diamond, Ribbon)
		local shapeType = math.random(1, 4)
		local startWidth = math.random(12, 24)
		local startHeight = startWidth
		
		if shapeType == 1 then
			-- Circle
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(0.5, 0)
			uiCorner.Parent = particle
		elseif shapeType == 3 then
			-- Diamond
			particle.Rotation = 45
		elseif shapeType == 4 then
			-- Ribbon / Strip
			startHeight = math.random(18, 32)
			startWidth = math.random(6, 12)
			particle.Rotation = math.random(0, 360)
		end

		particle.Size = UDim2.fromOffset(startWidth, startHeight)
		particle.BackgroundColor3 = colors[math.random(1, #colors)]
		particle.BorderSizePixel = 0
		
		-- Spawn around the text bounds
		particle.Position = UDim2.new(
			startXScale,
			startXOffset + math.random(-150, 150),
			startYScale,
			startYOffset + math.random(-30, 30)
		)
		
		particle.ZIndex = popup.ZIndex - 1 -- behind text
		particle.Parent = parent

		-- Calculate outward velocity vector
		local angle = (i / particleCount) * math.pi * 2 + (math.random() - 0.5) * 0.3
		local distance = math.random(100, 380)
		local targetXOffset = math.cos(angle) * distance
		-- Y movement has a downward gravity pull
		local targetYOffset = math.sin(angle) * distance + math.random(60, 140)
		local targetRotation = particle.Rotation + math.random(-720, 720)

		local duration = math.random(100, 200) / 100 -- 1.0 to 2.0 seconds

		-- Play size, position, rotation, and transparency tweens
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tween = TweenService:Create(
			particle,
			tweenInfo,
			{
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				Rotation = targetRotation,
				Position = UDim2.new(
					startXScale,
					particle.Position.X.Offset + targetXOffset,
					startYScale,
					particle.Position.Y.Offset + targetYOffset
				)
			}
		)

		tween:Play()
		task.delay(duration + 0.1, function()
			particle:Destroy()
		end)
	end
end

function MatchUIController:_closeQteResultReveal(immediate)
	local reveal = self._qteResultReveal
	if not reveal then
		return
	end

	self._qteResultReveal = nil
	if immediate or not reveal.Root.Parent then
		reveal.Root:Destroy()
		return
	end

	local closeInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, panel in ipairs({ reveal.LeftPanel, reveal.RightPanel }) do
		TweenService:Create(panel, closeInfo, {
			Size = UDim2.fromScale(0, 1),
			BackgroundTransparency = 1,
		}):Play()
	end
	task.delay(0.16, function()
		if reveal.Root then
			reveal.Root:Destroy()
		end
	end)
end

function MatchUIController:_openQteResultReveal(popup, tierColor)
	local parent = popup.Parent
	if not parent then
		return
	end

	local root = Instance.new("Frame")
	root.Name = "__QteResultReveal"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = popup.Position
	root.Size = UDim2.fromScale(0.86, 0.18)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ZIndex = math.max(1, popup.ZIndex - 3)
	root.Parent = parent

	local function createPanel(name, anchorPoint)
		local panel = Instance.new("Frame")
		panel.Name = name
		panel.AnchorPoint = anchorPoint
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.Size = UDim2.fromScale(0, 1)
		panel.BackgroundColor3 = tierColor
		panel.BackgroundTransparency = 1
		panel.BorderSizePixel = 0
		panel.ClipsDescendants = true
		panel.ZIndex = root.ZIndex
		panel.Parent = root

		return panel
	end

	local leftPanel = createPanel("LeftReveal", Vector2.new(1, 0.5))
	local rightPanel = createPanel("RightReveal", Vector2.new(0, 0.5))

	self._qteResultReveal = {
		Root = root,
		LeftPanel = leftPanel,
		RightPanel = rightPanel,
	}

	local openInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, panel in ipairs({ leftPanel, rightPanel }) do
		TweenService:Create(panel, openInfo, {
			Size = UDim2.fromScale(0.5, 1),
			BackgroundTransparency = 1,
		}):Play()
	end
end

function MatchUIController:_spawnUiQteTierParticles(popup, tierColor, particleCount)
	local parent = popup.Parent
	if not parent then
		return
	end

	local basePosition = popup.Position
	local count = particleCount or 36
	for i = 1, count do
		local particle = Instance.new("Frame")
		particle.Name = "QteResultParticle"
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BorderSizePixel = 0
		particle.BackgroundColor3 = (i % 5 == 0) and Color3.fromRGB(255, 255, 255) or tierColor
		particle.BackgroundTransparency = 0.05
		particle.ZIndex = math.max(1, popup.ZIndex - 1)

		local width = math.random(7, 16)
		local height = math.random(7, 20)
		particle.Size = UDim2.fromOffset(width, height)
		particle.Rotation = math.random(0, 359)
		particle.Position = UDim2.new(
			basePosition.X.Scale,
			basePosition.X.Offset + math.random(-110, 110),
			basePosition.Y.Scale,
			basePosition.Y.Offset + math.random(-20, 20)
		)

		if i % 3 == 0 then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = particle
		end

		particle.Parent = parent

		local angle = ((i - 1) / count) * math.pi * 2 + (math.random() - 0.5) * 0.28
		local distance = math.random(115, 290)
		local duration = math.random(65, 105) / 100
		local targetPosition = UDim2.new(
			basePosition.X.Scale,
			particle.Position.X.Offset + math.cos(angle) * distance,
			basePosition.Y.Scale,
			particle.Position.Y.Offset + math.sin(angle) * distance + math.random(25, 75)
		)

		local tween = TweenService:Create(
			particle,
			TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Position = targetPosition,
				Rotation = particle.Rotation + math.random(-540, 540),
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
			}
		)
		tween:Play()
		task.delay(duration + 0.05, function()
			particle:Destroy()
		end)
	end
end


function MatchUIController:_newBroadcastText(parent, name, text, size, position, anchorPoint, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.35
	label.Font = font or Enum.Font.GothamBlack
	label.TextScaled = true
	label.Position = position or UDim2.fromScale(0, 0)
	label.AnchorPoint = anchorPoint or Vector2.zero
	label.Size = size or UDim2.fromScale(1, 1)
	label.ZIndex = 710
	label.Parent = parent
	return label
end

function MatchUIController:_newBroadcastLogo(parent, name, position, anchorPoint)
	local image = Instance.new("ImageLabel")
	image.Name = name
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Position = position
	image.AnchorPoint = anchorPoint or Vector2.new(0.5, 0.5)
	image.Size = UDim2.fromOffset(32, 32)
	image.ZIndex = 710
	image.Parent = parent
	return image
end

function MatchUIController:_ensureBroadcastHud()
	if self._broadcastHudRoot and self._broadcastHudRoot.Parent then
		return
	end

	self:_ensureGui()
	if not self._matchGui then
		return
	end

	local root = Instance.new("Frame")
	root.Name = "__MatchBroadcastHud"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Position = UDim2.fromScale(0, 0)
	root.Size = UDim2.fromScale(1, 1)
	root.Visible = false
	root.ZIndex = 690
	root.Parent = self._matchGui

	local scoreboardContainer = Instance.new("Frame")
	scoreboardContainer.Name = "ScoreboardContainer"
	scoreboardContainer.AnchorPoint = Vector2.new(0.5, 0)
	scoreboardContainer.Position = UDim2.new(0.5, 0, 0, 12)
	scoreboardContainer.Size = UDim2.fromOffset(424, 42)
	scoreboardContainer.BackgroundTransparency = 1
	scoreboardContainer.BorderSizePixel = 0
	scoreboardContainer.ZIndex = 700
	scoreboardContainer.Parent = root

	local responsiveScale = Instance.new("UIScale")
	responsiveScale.Name = "__MatchResponsiveScale"
	responsiveScale.Scale = 1
	responsiveScale.Parent = scoreboardContainer
	self._broadcastScoreboardScale = responsiveScale

	local scoreboard = Instance.new("Frame")
	scoreboard.Name = "Scoreboard"
	scoreboard.AnchorPoint = Vector2.new(0, 0)
	scoreboard.Position = UDim2.new(0, 0, 0, 0)
	scoreboard.Size = UDim2.fromOffset(340, 42)
	scoreboard.BackgroundColor3 = Color3.fromRGB(14, 23, 46)
	scoreboard.BackgroundTransparency = 0.08
	scoreboard.BorderSizePixel = 0
	scoreboard.ZIndex = 700
	scoreboard.Parent = scoreboardContainer
	ApplyBasicCorner(scoreboard, UDim.new(0, 8))
	ApplyBasicStroke(scoreboard, Color3.fromRGB(245, 245, 245), 2, 0.08)

	local clock = Instance.new("Frame")
	clock.Name = "ClockPanel"
	clock.AnchorPoint = Vector2.new(0, 0)
	clock.Position = UDim2.new(1, 6, 0, 0)
	clock.Size = UDim2.fromOffset(78, 42)
	clock.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	clock.BackgroundTransparency = 0.05
	clock.BorderSizePixel = 0
	clock.ZIndex = 705
	clock.Parent = scoreboard
	ApplyBasicCorner(clock, UDim.new(0, 8))
	ApplyBasicStroke(clock, Color3.fromRGB(14, 23, 46), 2, 0.1)

	local actionBannerContainer = Instance.new("Frame")
	actionBannerContainer.Name = "ActionBannerContainer"
	actionBannerContainer.AnchorPoint = Vector2.new(0.5, 0)
	actionBannerContainer.Position = UDim2.fromScale(0.5, 0.19)
	actionBannerContainer.Size = UDim2.fromOffset(500, 46)
	actionBannerContainer.BackgroundTransparency = 1
	actionBannerContainer.BorderSizePixel = 0
	actionBannerContainer.ZIndex = 704
	actionBannerContainer.Parent = root

	local actionBannerScale = Instance.new("UIScale")
	actionBannerScale.Name = "__MatchActionBannerScale"
	actionBannerScale.Scale = 1
	actionBannerScale.Parent = actionBannerContainer
	self._broadcastActionBannerScale = actionBannerScale

	local actionBanner = Instance.new("Frame")
	actionBanner.Name = "ActionBanner"
	actionBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	actionBanner.Position = UDim2.fromScale(0.5, 0.5)
	actionBanner.Size = UDim2.fromOffset(500, 44)
	actionBanner.BackgroundColor3 = Color3.fromRGB(9, 48, 92)
	actionBanner.BackgroundTransparency = 0.08
	actionBanner.BorderSizePixel = 0
	actionBanner.Visible = false
	actionBanner.ZIndex = 704
	actionBanner.Parent = actionBannerContainer
	ApplyBasicCorner(actionBanner, UDim.new(0, 10))	
	ApplyBasicStroke(actionBanner, Color3.fromRGB(255, 255, 255), 2, 0.12)

	local goalScorerContainer = Instance.new("Frame")
	goalScorerContainer.Name = "GoalScorerContainer"
	goalScorerContainer.AnchorPoint = Vector2.new(0, 0.5)
	goalScorerContainer.Position = UDim2.new(0, -250, 0.72, 0)
	goalScorerContainer.Size = UDim2.fromOffset(250, 76)
	goalScorerContainer.BackgroundTransparency = 1
	goalScorerContainer.BorderSizePixel = 0
	goalScorerContainer.Visible = false
	goalScorerContainer.ZIndex = 720
	goalScorerContainer.Parent = root

	local goalScorerScale = Instance.new("UIScale")
	goalScorerScale.Name = "__MatchGoalScorerScale"
	goalScorerScale.Scale = 1
	goalScorerScale.Parent = goalScorerContainer
	self._broadcastGoalScorerScale = goalScorerScale

	local minutePanel = Instance.new("Frame")
	minutePanel.Name = "MinutePanel"
	minutePanel.Position = UDim2.fromOffset(0, 0)
	minutePanel.Size = UDim2.fromOffset(62, 28)
	minutePanel.BackgroundColor3 = Color3.fromRGB(9, 36, 52)
	minutePanel.BackgroundTransparency = 0.02
	minutePanel.BorderSizePixel = 0
	minutePanel.ZIndex = 721
	minutePanel.Parent = goalScorerContainer
	ApplyBasicCorner(minutePanel, UDim.new(0, 3))

	local scorerPanel = Instance.new("Frame")
	scorerPanel.Name = "ScorerPanel"
	scorerPanel.Position = UDim2.fromOffset(0, 30)
	scorerPanel.Size = UDim2.fromOffset(250, 46)
	scorerPanel.BackgroundColor3 = Color3.fromRGB(246, 248, 255)
	scorerPanel.BackgroundTransparency = 0
	scorerPanel.BorderSizePixel = 0
	scorerPanel.ZIndex = 721
	scorerPanel.Parent = goalScorerContainer
	ApplyBasicCorner(scorerPanel, UDim.new(0, 3))
	ApplyBasicStroke(scorerPanel, Color3.fromRGB(255, 255, 255), 1, 0.2)

	self._broadcastGoalMinuteText = self:_newBroadcastText(minutePanel, "MinuteText", "37'", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.new(0, 0), Enum.Font.GothamBlack)
	self._broadcastGoalMinuteText.TextColor3 = Color3.fromRGB(255, 255, 255)
	self._broadcastGoalMinuteText.TextStrokeTransparency = 1
	self._broadcastGoalScorerText = self:_newBroadcastText(scorerPanel, "ScorerText", "Player", UDim2.fromScale(0.88, 0.82), UDim2.fromScale(0.06, 0.08), Vector2.new(0, 0), Enum.Font.GothamBlack)
	self._broadcastGoalScorerText.TextColor3 = Color3.fromRGB(39, 54, 158)
	self._broadcastGoalScorerText.TextStrokeTransparency = 1
	self._broadcastGoalScorerText.TextXAlignment = Enum.TextXAlignment.Left

	self._broadcastHudRoot = root
	self._broadcastScoreboard = scoreboard
	self._broadcastClockPanel = clock
	self._broadcastActionBanner = actionBanner
	self._broadcastGoalScorerContainer = goalScorerContainer
	self._broadcastMinutePanel = minutePanel
	self._broadcastScorerPanel = scorerPanel

	self._broadcastHomeLogo = self:_newBroadcastLogo(scoreboard, "HomeLogo", UDim2.fromScale(0.09, 0.5))
	self._broadcastAwayLogo = self:_newBroadcastLogo(scoreboard, "AwayLogo", UDim2.fromScale(0.91, 0.5))
	self._broadcastHomeCode = self:_newBroadcastText(scoreboard, "HomeCode", "RIV", UDim2.fromOffset(60, 28), UDim2.fromScale(0.22, 0.5), Vector2.new(0.5, 0.5))
	self._broadcastAwayCode = self:_newBroadcastText(scoreboard, "AwayCode", "OPP", UDim2.fromOffset(60, 28), UDim2.fromScale(0.78, 0.5), Vector2.new(0.5, 0.5))
	self._broadcastHomeScore = self:_newBroadcastText(scoreboard, "HomeScore", "0", UDim2.fromOffset(30, 36), UDim2.fromScale(0.41, 0.5), Vector2.new(0.5, 0.5))
	self._broadcastDash = self:_newBroadcastText(scoreboard, "Dash", "-", UDim2.fromOffset(20, 36), UDim2.fromScale(0.50, 0.5), Vector2.new(0.5, 0.5))
	self._broadcastAwayScore = self:_newBroadcastText(scoreboard, "AwayScore", "0", UDim2.fromOffset(30, 36), UDim2.fromScale(0.59, 0.5), Vector2.new(0.5, 0.5))
	self._broadcastClockText = self:_newBroadcastText(clock, "ClockText", "85:00", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Vector2.new(0, 0), Enum.Font.GothamBold)
	self._broadcastClockText.TextColor3 = Color3.fromRGB(14, 23, 46)
	self._broadcastClockText.TextStrokeTransparency = 1
	self._broadcastActionText = self:_newBroadcastText(actionBanner, "ActionText", "PASS", UDim2.fromScale(0.36, 1), UDim2.fromScale(0.03, 0), Vector2.new(0, 0), Enum.Font.GothamBlack)
	self._broadcastActionText.TextXAlignment = Enum.TextXAlignment.Left
	self._broadcastStatText = self:_newBroadcastText(actionBanner, "StatText", "RIV 0 vs OPP 0", UDim2.fromScale(0.58, 1), UDim2.fromScale(0.40, 0), Vector2.new(0, 0), Enum.Font.GothamBold)
	self._broadcastStatText.TextXAlignment = Enum.TextXAlignment.Right

	self:_updateAllResponsiveScales()
end

local function GetMatchHudScale(viewportSize)
	local scale = viewportSize.Y / 720
	return math.clamp(scale, 0.45, 1.6)
end

function MatchUIController:_updateAllResponsiveScales()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local viewportSize = camera.ViewportSize
	local scaleFactor = GetMatchHudScale(viewportSize)

	if self._broadcastScoreboardScale then
		self._broadcastScoreboardScale.Scale = scaleFactor
	end

	if self._broadcastActionBannerScale then
		self._broadcastActionBannerScale.Scale = scaleFactor
	end

	if self._broadcastGoalScorerScale then
		self._broadcastGoalScorerScale.Scale = scaleFactor
	end
end

function MatchUIController:_advanceBroadcastClock(now)
	local state = self._broadcastClockState
	if not state then
		return nil
	end

	local currentTime = tonumber(now) or os.clock()
	state.LastTickAt = tonumber(state.LastTickAt) or currentTime
	state.TotalSeconds = tonumber(state.TotalSeconds) or 0

	if state.IsPaused ~= true then
		local delta = math.max(0, currentTime - state.LastTickAt)
		local timeScale = tonumber(state.TimeScale) or 1
		state.TotalSeconds += delta * timeScale * (60 / BROADCAST_CLOCK_REAL_SECONDS_PER_MATCH_MINUTE)
	end

	state.LastTickAt = currentTime
	return state.TotalSeconds
end

function MatchUIController:_renderBroadcastClock(totalSeconds)
	if not self._broadcastClockText then
		return
	end

	local safeSeconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))
	local minute = math.floor(safeSeconds / 60)
	local second = safeSeconds % 60
	self._broadcastClockText.Text = FormatBroadcastClock(minute, second)
end

function MatchUIController:_startBroadcastClockLoop()
	if self._broadcastClockConnection then
		return
	end

	self._broadcastClockConnection = RunService.RenderStepped:Connect(function()
		if not self._broadcastHudActive or not self._broadcastClockText then
			return
		end

		local totalSeconds = self:_advanceBroadcastClock(os.clock())
		if totalSeconds ~= nil then
			self:_renderBroadcastClock(totalSeconds)
		end
	end)
end

function MatchUIController:_getBroadcastGoalMinuteText()
	local state = self._broadcastClockState
	if not state then
		return FormatGoalMinute(BROADCAST_CLOCK_START_MINUTE * 60)
	end

	local totalSeconds = self:_advanceBroadcastClock(os.clock()) or state.TotalSeconds or 0
	return FormatGoalMinute(totalSeconds)
end

function MatchUIController:_hideGoalScorerPanel(animate)
	self._goalScorerPanelToken = (self._goalScorerPanelToken or 0) + 1
	local panel = self._broadcastGoalScorerContainer
	if not panel then
		return
	end

	local hiddenPosition = UDim2.new(0, -260, 0.72, 0)
	if animate == false or not panel.Visible then
		panel.Visible = false
		panel.Position = hiddenPosition
		return
	end

	local token = self._goalScorerPanelToken
	TweenService:Create(
		panel,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = hiddenPosition }
	):Play()
	task.delay(0.2, function()
		if token ~= self._goalScorerPanelToken then
			return
		end
		panel.Visible = false
	end)
end

function MatchUIController:_showGoalScorerPanel(payload)
	if not BROADCAST_HUD_ENABLED then
		return
	end

	self:_ensureBroadcastHud()
	local panel = self._broadcastGoalScorerContainer
	if not panel then
		return
	end

	payload = typeof(payload) == "table" and payload or {}
	local scorerName = tostring(payload.ScorerDisplayName or payload.ActorDisplayName or "Player")
	if scorerName == "" then
		scorerName = "Player"
	end

	self._goalScorerPanelToken = (self._goalScorerPanelToken or 0) + 1
	local token = self._goalScorerPanelToken
	local hiddenPosition = UDim2.new(0, -260, 0.72, 0)
	local shownPosition = UDim2.new(0, 18, 0.72, 0)

	if self._broadcastGoalMinuteText then
		self._broadcastGoalMinuteText.Text = self:_getBroadcastGoalMinuteText()
	end
	if self._broadcastGoalScorerText then
		self._broadcastGoalScorerText.Text = scorerName
	end

	local scorerPanel = self._broadcastScorerPanel or panel:FindFirstChild("ScorerPanel")

	panel.Visible = true
	panel.Position = hiddenPosition
	
	if scorerPanel then
		scorerPanel.Visible = false
		scorerPanel.Position = UDim2.new(0, -180, 0, 30)
	end

	local containerTween = TweenService:Create(
		panel,
		TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = shownPosition }
	)
	containerTween:Play()

	if scorerPanel then
		task.delay(0.40, function()
			if token ~= self._goalScorerPanelToken then
				return
			end
			scorerPanel.Visible = true
			local scorerTween = TweenService:Create(
				scorerPanel,
				TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0, 0, 0, 30) }
			)
			scorerTween:Play()
		end)
	end

	task.delay(GOAL_SCORER_PANEL_HOLD_SECONDS, function()
		if token ~= self._goalScorerPanelToken then
			return
		end
		self:_hideGoalScorerPanel(true)
	end)
end

function MatchUIController:PauseBroadcastClock()
	local state = self._broadcastClockState
	if not state or state.IsPaused == true then
		return
	end

	self:_advanceBroadcastClock(os.clock())
	state.IsPaused = true
end

function MatchUIController:StopBroadcastClock()
	local state = self._broadcastClockState
	if not state then
		return
	end

	self:_advanceBroadcastClock(os.clock())
	state.IsPaused = true
	self._broadcastClockLocked = true
end

function MatchUIController:ResumeBroadcastClock()
	if self._broadcastClockLocked then
		return
	end

	local state = self._broadcastClockState
	if not state or state.IsPaused ~= true then
		return
	end

	state.LastTickAt = os.clock()
	state.IsPaused = false
end

function MatchUIController:SetBroadcastClockTimeScale(scale)
	local state = self._broadcastClockState
	if not state then
		return
	end

	self:_advanceBroadcastClock(os.clock())
	state.TimeScale = math.max(tonumber(scale) or 1, 0)
	state.LastTickAt = os.clock()
	state.IsPaused = false
end

function MatchUIController:SetBroadcastScore(homeScore, awayScore)
	self:_ensureBroadcastHud()

	self._broadcastHomeScoreValue = math.max(0, tonumber(homeScore) or 0)
	self._broadcastAwayScoreValue = math.max(0, tonumber(awayScore) or 0)

	if self._broadcastHomeScore then
		self._broadcastHomeScore.Text = tostring(self._broadcastHomeScoreValue)
	end
	if self._broadcastAwayScore then
		self._broadcastAwayScore.Text = tostring(self._broadcastAwayScoreValue)
	end
end

function MatchUIController:IncrementBroadcastHomeScore(amount)
	if not self._broadcastHudActive then
		return
	end
	self:SetBroadcastScore((self._broadcastHomeScoreValue or 0) + (tonumber(amount) or 1), self._broadcastAwayScoreValue or 0)
end

function MatchUIController:IncrementBroadcastAwayScore(amount)
	if not self._broadcastHudActive then
		return
	end
	self:SetBroadcastScore(self._broadcastHomeScoreValue or 0, (self._broadcastAwayScoreValue or 0) + (tonumber(amount) or 1))
end

function MatchUIController:ShowBroadcastHud(payload)
	if not BROADCAST_HUD_ENABLED then
		return
	end

	self:_ensureBroadcastHud()
	if not self._broadcastHudRoot then
		return
	end

	local introData = GetIntroDataFromPayload(payload)
	local areaId = tostring(introData.AreaId or (payload and payload.AreaId) or "Area01")
	local homeName = ResolvePlayerTeamName(introData.HomeTeamName)
	local awayName = tostring(introData.AwayTeamName or "Opponent FC")
	local homeCode = ResolveTeamCode(areaId, homeName, "RIV", true)
	local awayCode = ResolveTeamCode(areaId, awayName, "OPP", false)
	local homeLogo = ResolveTeamLogo(areaId, homeName, introData.HomeLogo, true)
	local awayLogo = ResolveTeamLogo(areaId, awayName, introData.AwayLogo, false)
	local homeScore = tonumber(introData.HomeScore) or 0
	local awayScore = tonumber(introData.AwayScore) or 0
	local startMinute = math.max(0, math.floor(tonumber(introData.MatchMinute) or BROADCAST_CLOCK_START_MINUTE))

	self._broadcastHudActive = true
	self._broadcastClockLocked = false
	self._broadcastHudRoot.Visible = true
	self._broadcastActionBanner.Visible = false
	self:_hideGoalScorerPanel(false)
	self._broadcastHomeCode.Text = homeCode
	self._broadcastAwayCode.Text = awayCode
	SetImageIfFound(self._broadcastHomeLogo, homeLogo)
	SetImageIfFound(self._broadcastAwayLogo, awayLogo)
	self:SetBroadcastScore(homeScore, awayScore)

	self._broadcastClockState = {
		TotalSeconds = startMinute * 60,
		LastTickAt = os.clock(),
		IsPaused = false,
		TimeScale = 1,
	}
	self:_renderBroadcastClock(startMinute * 60)
	self:_startBroadcastClockLoop()
end

function MatchUIController:HideBroadcastHud()
	self:_stopExcellentCameraEffect()
	self._broadcastHudActive = false
	self._broadcastClockLocked = false
	self._broadcastClockState = nil
	self._actionBannerToken = (self._actionBannerToken or 0) + 1
	if self._broadcastHudRoot then
		self._broadcastHudRoot.Visible = false
	end
	if self._broadcastActionBanner then
		self._broadcastActionBanner.Visible = false
	end
	self:_hideGoalScorerPanel(false)
end

function MatchUIController:ShowActionBanner(stepPayload)
	if not BROADCAST_HUD_ENABLED then
		return
	end

	self:_ensureBroadcastHud()
	return false
end

function MatchUIController:ShowActionResultBanner(resultPayload)
	return false
end

function MatchUIController:HideActionBanner(delaySeconds)
	local delayValue = tonumber(delaySeconds) or 0
	self._actionBannerToken = (self._actionBannerToken or 0) + 1
	local token = self._actionBannerToken

	task.delay(delayValue, function()
		if token ~= self._actionBannerToken then
			return
		end
		if self._broadcastActionBanner then
			UIJuice.PopOut(self._broadcastActionBanner, {
				Duration = 0.10,
				EndScale = 0.88,
			})
		end
	end)
end

function MatchUIController:HideActionBannerNow()
	self._actionBannerToken = (self._actionBannerToken or 0) + 1
	if self._broadcastActionBanner then
		UIJuice.Cancel(self._broadcastActionBanner)
		self._broadcastActionBanner.Visible = false
	end
end

function MatchUIController:SetExitCallback(callbackFn)
	self._exitCallback = callbackFn
end

function MatchUIController:SetQteConfirmCallback(callbackFn)
	self._qteConfirmCallback = callbackFn
end

function MatchUIController:ShowExitButton()
	self:_ensureGui()

	local exitButton = self:_getExitButton()
	if exitButton then
		exitButton.Visible = true
	end
end

function MatchUIController:HideExitButton()
	self:_ensureGui()

	local exitButton = self:_getExitButton()
	if exitButton then
		exitButton.Visible = false
	end
end

function MatchUIController:ShowGoalsPill()
	self:_ensureGui()
	if BROADCAST_HUD_ENABLED then
		self:HideGoalsPill()
		return
	end

	local goalsPill = self:_getGoalsPill()
	if goalsPill then
		goalsPill.Visible = true
	end
end

function MatchUIController:HideGoalsPill()
	self:_ensureGui()

	local goalsPill = self:_getGoalsPill()
	if goalsPill then
		goalsPill.Visible = false
	end
end

function MatchUIController:SetGoalsValue(value)
	self:_ensureGui()

	self._currentGoalsValue = tonumber(value) or 0

	local goalsLabel = self:_getGoalsLabel()
	if goalsLabel then
		goalsLabel.Text = string.format("Goals: %s", formatnumber(self._currentGoalsValue))
	end
end

function MatchUIController:IncrementGoals(amount)
	self:SetGoalsValue((self._currentGoalsValue or 0) + (tonumber(amount) or 0))
end

function MatchUIController:IncrementMatchScore(amount, payload)
	self:IncrementGoals(amount)
	self:IncrementBroadcastHomeScore(amount)
	self:_showGoalScorerPanel(payload)
	self:StopBroadcastClock()

	-- Show "GOAL!" popup at the exact moment the ball hits the net for all goals
	-- Hold longer (4.0s) so the player can savor the climax
	self:_showCenterPopup("GOAL!", Color3.fromRGB(255, 206, 10), 4.0)
	self._goalPopupShowedAt = os.clock()
	self._goalPopupDuration = 4.0
end

function MatchUIController:ShowComparePill()
	self:_ensureGui()
	if BROADCAST_HUD_ENABLED then
		self:HideComparePill()
		return
	end

	local comparePill = self:_getComparePill()
	if comparePill then
		comparePill.Visible = true
	end
end

function MatchUIController:HideComparePill()
	self:_ensureGui()

	local comparePill = self:_getComparePill()
	if comparePill then
		comparePill.Visible = false
	end
end

function MatchUIController:SetCompareText(text)
	self:_ensureGui()

	local compareLabel = self:_getCompareLabel()
	if compareLabel then
		compareLabel.Text = text or ""
	end
end

function MatchUIController:SetActiveMatchSession(sessionId)
	self._activeMatchSessionId = sessionId ~= nil and tostring(sessionId) or nil
	self._resultUiGeneration = (self._resultUiGeneration or 0) + 1
	self:HideResultPopup()
end

function MatchUIController:ClearActiveMatchSession(sessionId)
	if sessionId ~= nil and self._activeMatchSessionId ~= nil and tostring(sessionId) ~= tostring(self._activeMatchSessionId) then
		return
	end

	self._activeMatchSessionId = nil
	self._resultUiGeneration = (self._resultUiGeneration or 0) + 1
	self:HideResultPopup()
end

function MatchUIController:_isResultPayloadCurrent(payload)
	local payloadSessionId = GetPayloadSessionId(payload)
	if payloadSessionId == nil then
		return self._activeMatchSessionId ~= nil
	end

	return self._activeMatchSessionId ~= nil and tostring(self._activeMatchSessionId) == payloadSessionId
end

function MatchUIController:ClearTransitionOverlay()
	self:_ensureGui()

	self._fadeToken += 1
	if self._activeFadeTween then
		pcall(function()
			self._activeFadeTween:Cancel()
		end)
		self._activeFadeTween = nil
	end

	local blackout = self:_getBlackoutFrame()
	if blackout then
		blackout.BackgroundTransparency = 1
		blackout.Visible = false
	end

	local label = self:_getStatusLabel()
	if label then
		label.Text = ""
	end
end

function MatchUIController:BeginMatchUi(callbackFn)
	self:_ensureGui()
	self:SetExitCallback(callbackFn)
	self:HideExitButton()
	self:HideGoalsPill()
	self:HideComparePill()
	self:HideBroadcastHud()
	if self.HideActionBannerNow then
		self:HideActionBannerNow()
	else
		self:HideActionBanner(0)
	end
	self:HideQte()
	self:HideResultPopup()
end

function MatchUIController:EndMatchUi(options)
	local preserveTransitionOverlay = options == true
		or (type(options) == "table" and options.PreserveTransitionOverlay == true)

	self._activeMatchSessionId = nil
	self._resultUiGeneration = (self._resultUiGeneration or 0) + 1
	self:HideExitButton()
	self:HideGoalsPill()
	self:HideComparePill()
	self:HideBroadcastHud()
	self:HideActionBanner(0)
	self:HideQte()
	self:HideResultPopup()
	self:SetExitCallback(nil)
	self:SetQteConfirmCallback(nil)
	self:SetGoalsValue(0)
	self:SetCompareText("")
	self:_showCenterPopup(nil, nil, 0)

	if not preserveTransitionOverlay then
		self:ClearTransitionOverlay()
	end
end

function MatchUIController:FadeToBlack(statusText)
	self:_ensureGui()
	self:_raiseTransitionOverlay()
	self:_suppressMatchHudForTransition()

	local blackout = self:_getBlackoutFrame()
	local label = self:_getStatusLabel()

	if not blackout then
		return
	end

	blackout.Visible = true
	self._fadeToken += 1
	local myToken = self._fadeToken

	if self._activeFadeTween then
		pcall(function()
			self._activeFadeTween:Cancel()
		end)
		self._activeFadeTween = nil
	end

	if label then
		label.Text = statusText or ""
	end

	local tween = TweenService:Create(
		blackout,
		TweenInfo.new(MatchConstants.TRANSITION_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	)

	self._activeFadeTween = tween
	tween:Play()
	tween.Completed:Wait()

	if self._fadeToken == myToken then
		self._activeFadeTween = nil
	end
end

function MatchUIController:CutToBlack(statusText)
	self:_ensureGui()
	self:_raiseTransitionOverlay()
	self:_suppressMatchHudForTransition()

	local blackout = self:_getBlackoutFrame()
	local label = self:_getStatusLabel()

	self._fadeToken += 1
	if self._activeFadeTween then
		pcall(function()
			self._activeFadeTween:Cancel()
		end)
		self._activeFadeTween = nil
	end

	if blackout then
		blackout.Visible = true
		blackout.BackgroundTransparency = 0
	end

	if label then
		label.Text = statusText or ""
	end
end

function MatchUIController:FadeFromBlack()
	self:_ensureGui()

	local blackout = self:_getBlackoutFrame()
	local label = self:_getStatusLabel()

	if not blackout then
		return
	end

	self._fadeToken += 1
	local myToken = self._fadeToken

	if self._activeFadeTween then
		pcall(function()
			self._activeFadeTween:Cancel()
		end)
		self._activeFadeTween = nil
	end

	local tween = TweenService:Create(
		blackout,
		TweenInfo.new(MatchConstants.TRANSITION_FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	self._activeFadeTween = tween
	tween:Play()
	tween.Completed:Wait()

	if self._fadeToken ~= myToken then
		return
	end

	self._activeFadeTween = nil

	if label then
		label.Text = ""
	end

	if blackout then
		blackout.Visible = false
	end
end

function MatchUIController:ShowQte(stepPayload, confirmCallback)
	self:_ensureGui()
	self:SetBroadcastClockTimeScale(QTE_BROADCAST_CLOCK_TIME_SCALE)
	self:SetQteConfirmCallback(confirmCallback)

	local qteLayer = self:_getQteLayer()
	if not qteLayer then
		-- Wait for Roact refs to populate if this is the first mount
		RunService.Heartbeat:Wait()
		qteLayer = self:_getQteLayer()
	end

	if qteLayer then
		ConfigureQteVisualTree(qteLayer)
		qteLayer.Visible = true
	end

	local stepLabel = self:_getQteStepLabel()
	local actionLabel = self:_getQteActionLabel()
	local targetLabel = self:_getQteTargetLabel()

	if stepLabel then
		stepLabel.Text = string.format("STEP %d / %d", stepPayload.StepIndex or 1, stepPayload.TotalSteps or 5)
	end

	if actionLabel then
		actionLabel.Text = string.upper(stepPayload.Action or "ACTION")
	end

	if targetLabel then
		targetLabel.Text = string.format("Target: %s", formatnumber(stepPayload.EnemyValue or 0))
	end

	self._currentQteLayout = self:_buildRandomQteConfig(stepPayload.StepIndex or 1)
	self:_applyQteLayout(self._currentQteLayout)
	ConfigureQteVisualTree(qteLayer)

	self._activeQte = {
		Locked = false,
		StartedAt = os.clock(),
		Action = stepPayload.Action,
		StepIndex = stepPayload.StepIndex,
	}

	self:_startCursorLoop()
	self:_setPointerAlpha(0.5)
end

function MatchUIController:ConfirmQte()
	if not self._activeQte then
		return nil
	end

	if self._activeQte.Locked then
		return nil
	end

	self._activeQte.Locked = true

	local alpha = self._currentCursorAlpha or 0.5
	local tier = self:_resolveTierFromAlpha(alpha)

	-- Cache for presentation systems (e.g. shoot curve logic)
	self._lastConfirmedTier = tier

	return {
		Tier = tier,
		CursorAlpha = alpha,
	}
end

function MatchUIController:ActivateCheatAutoPerfect()
	print("[CHEAT] MatchUIController:ActivateCheatAutoPerfect called!")
	if not self._activeQte or self._activeQte.Locked then
		print("[CHEAT] Failed: activeQte is nil or locked", tostring(self._activeQte ~= nil), tostring(self._activeQte and self._activeQte.Locked))
		return
	end

	local layout = self._currentQteLayout
	if layout and layout.Green then
		local greenCenter = layout.Green.Position + (layout.Green.Width / 2)
		print(("[CHEAT] Snapping pointer to GreenCenter: %f (Green range: %f to %f)"):format(greenCenter, layout.GreenStart, layout.GreenEnd))
		self:_setPointerAlpha(greenCenter)
	else
		print("[CHEAT] No layout or green zone! Snapping to 0.5")
		self:_setPointerAlpha(0.5)
	end
end

local function ResolveActionResultText(action, succeeded, qteTier)
	local actionName = string.upper(tostring(action or "ACTION"))
	if not succeeded then
		return string.format("%s FAILED", actionName), Color3.fromRGB(255, 110, 110)
	end

	if IsExcellentTier(qteTier) then
		return string.format("%s EXCELLENT", actionName), Color3.fromRGB(255, 238, 45)
	end

	return string.format("%s SUCCESS", actionName), Color3.fromRGB(88, 184, 255)
end

function MatchUIController:ShowQteResult(resultPayload)
	self:_ensureGui()
	self:HideComparePill()

	resultPayload = typeof(resultPayload) == "table" and resultPayload or {}
	local resultBannerShown = self:ShowActionResultBanner(resultPayload)
	if resultBannerShown then
		self:HideActionBanner(QTE_RESULT_BANNER_HOLD)
	else
		self:HideActionBannerNow()
	end

	local qteTier = resultPayload.QteTier or resultPayload.Tier or self._lastConfirmedTier or "Yellow"
	local feedbackLabel, feedbackColor, feedbackMultiplier = ResolveQteFeedback(qteTier, resultPayload.QteMultiplier)
	self:_showCenterPopup(
		string.format("%s x%.1f", feedbackLabel, feedbackMultiplier),
		feedbackColor,
		1.25
	)

	if IsExcellentTier(qteTier) then
		self:_playExcellentCameraEffect()
	end

	if IsShootAction(resultPayload.Action) then
		-- Score increment is deferred to MatchShootDirector which will call
		-- IncrementMatchScore exactly when the ball reaches the net.

		return
	end

	if resultPayload.Succeeded then
		if (resultPayload.AwardedGoals or 0) > 0 then
			self:IncrementBroadcastHomeScore(resultPayload.AwardedGoals or 1)
			self:StopBroadcastClock()
		end
	end
end


function MatchUIController:_resolveArtistMatchFinishedRefs()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local matchBattleGui = playerGui:FindFirstChild("GUIMatchBattle")
	if not (matchBattleGui and matchBattleGui:IsA("ScreenGui")) then
		return nil
	end

	local matchFinished = matchBattleGui:FindFirstChild("MatchFinished")
	local popup = matchFinished and matchFinished:FindFirstChild("Popup")
	if not (matchFinished and matchFinished:IsA("GuiObject") and popup and popup:IsA("GuiObject")) then
		return nil
	end

	local versus = popup:FindFirstChild("Versus")
	local playerFrame = versus and versus:FindFirstChild("Player")
	local enemyFrame = versus and versus:FindFirstChild("Enemy")
	local rewardsRoot = popup:FindFirstChild("Rewards") or popup

	return {
		Gui = matchBattleGui,
		Root = matchFinished,
		Popup = popup,
		Versus = versus,
		PlayerFrame = playerFrame,
		EnemyFrame = enemyFrame,
		PlayerLogo = playerFrame and FindFirstImageObject(playerFrame, { "Logo" }),
		EnemyLogo = enemyFrame and FindFirstImageObject(enemyFrame, { "Logo" }),
		PlayerNameText = playerFrame and FindFirstTextLabel(playerFrame, { "NameText", "Name", "TeamName" }),
		EnemyNameText = enemyFrame and FindFirstTextLabel(enemyFrame, { "NameText", "Name", "TeamName" }),
		PlayerScoreText = popup:FindFirstChild("PlayerScoreText") or FindDescendantByName(popup, "PlayerScoreText"),
		EnemyScoreText = popup:FindFirstChild("EnemyScoreText") or FindDescendantByName(popup, "EnemyScoreText"),
		TitleText = popup:FindFirstChild("TitleText"),
		ResultText = popup:FindFirstChild("ResultText"),
		RewardText = FindFirstTextLabel(rewardsRoot, {
			"Reward Text",
			"RewardText",
			"Reward Tex",
			"Reward",
			"NumberText",
			"Text",
		}),
		Tournament = matchBattleGui:FindFirstChild("Tournament"),
		MatchStart = matchBattleGui:FindFirstChild("MatchStart"),
	}
end

function MatchUIController:_resolveArtistMatchStartRefsForResult()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local matchBattleGui = playerGui:FindFirstChild("GUIMatchBattle")
	local matchStart = matchBattleGui and matchBattleGui:FindFirstChild("MatchStart")
	local popup = matchStart and matchStart:FindFirstChild("Popup")
	local versus = popup and popup:FindFirstChild("Versus")
	local playerFrame = versus and versus:FindFirstChild("Player")
	local enemyFrame = versus and versus:FindFirstChild("Enemy")

	if not popup then
		return nil
	end

	return {
		PlayerLogo = playerFrame and FindFirstImageObject(playerFrame, { "Logo" }),
		EnemyLogo = enemyFrame and FindFirstImageObject(enemyFrame, { "Logo" }),
		PlayerNameText = playerFrame and FindFirstTextLabel(playerFrame, { "NameText", "Name", "TeamName" }),
		EnemyNameText = enemyFrame and FindFirstTextLabel(enemyFrame, { "NameText", "Name", "TeamName" }),
		PlayerScoreText = popup:FindFirstChild("PlayerScoreText") or FindDescendantByName(popup, "PlayerScoreText"),
		EnemyScoreText = popup:FindFirstChild("EnemyScoreText") or FindDescendantByName(popup, "EnemyScoreText"),
	}
end

function MatchUIController:_showArtistMatchFinished(success, payload)
	local refs = self:_resolveArtistMatchFinishedRefs()
	if not refs then
		return false
	end

	self._resultPopupToken = (self._resultPopupToken or 0) + 1
	local introRefs = self:_resolveArtistMatchStartRefsForResult()
	payload = typeof(payload) == "table" and payload or {}

	local homeScore = ReadNumericText(introRefs and introRefs.PlayerScoreText, payload.HomeScore)
	local awayScore = ReadNumericText(introRefs and introRefs.EnemyScoreText, payload.AwayScore)
	local awardedGoals = tonumber(payload.AwardedGoals) or 0
	if success and awardedGoals <= 0 then
		awardedGoals = 1
	end

	local finalHomeScore = self._broadcastHomeScoreValue or (homeScore + (success and awardedGoals or 0))
	local finalAwayScore = self._broadcastAwayScoreValue or awayScore
	local wins = GetPayloadWins(payload)

	if refs.Gui and refs.Gui:IsA("ScreenGui") then
		refs.Gui.Enabled = true
	end

	SetGuiVisible(refs.Tournament, false)
	SetGuiVisible(refs.MatchStart, false)
	SetGuiVisible(refs.Root, true)
	SetGuiVisible(refs.Popup, true)
	SetGuiVisible(refs.Versus, true)
	UIJuice.Cancel(refs.Popup)

	SetImageFromSource(refs.PlayerLogo, introRefs and introRefs.PlayerLogo)
	if not (introRefs and introRefs.PlayerLogo) then
		SetPlayerImageIfMissing(refs.PlayerLogo)
	end
	SetImageFromSource(refs.EnemyLogo, introRefs and introRefs.EnemyLogo)
	SetTextIfFound(refs.PlayerNameText, introRefs and introRefs.PlayerNameText and introRefs.PlayerNameText.Text or PlayerTeamIdentity.GetName(PLAYER_TEAM_NAME))
	SetTextIfFound(refs.EnemyNameText, introRefs and introRefs.EnemyNameText and introRefs.EnemyNameText.Text or "Opponent FC")
	SetTextIfFound(refs.PlayerScoreText, tostring(finalHomeScore))
	SetTextIfFound(refs.EnemyScoreText, tostring(finalAwayScore))

	if refs.TitleText then
		refs.TitleText.Visible = true
	end

	-- Set up win/lose result text
	local winTitle = refs.Popup:FindFirstChild("Win", true) 
		or refs.Popup:FindFirstChild("YouWin", true) 
		or refs.Popup:FindFirstChild("Victory", true)
	local loseTitle = refs.Popup:FindFirstChild("Lose", true) 
		or refs.Popup:FindFirstChild("YouLose", true) 
		or refs.Popup:FindFirstChild("Defeat", true)

	if winTitle and loseTitle then
		winTitle.Visible = success
		loseTitle.Visible = not success
	elseif refs.ResultText then
		refs.ResultText.Text = success and "YOU WIN!" or "YOU LOSE!"
		refs.ResultText.Visible = true
	elseif refs.TitleText then
		refs.TitleText.Text = success and "YOU WIN!" or "YOU LOSE!"
	end

	if success then
		SetTextIfFound(refs.RewardText, string.format("+%s Wins", formatnumber(wins)))
	else
		SetTextIfFound(refs.RewardText, "Try again!")
	end

	pcall(function()
		refs.Popup.GroupTransparency = 1
		TweenService:Create(
			refs.Popup,
			TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ GroupTransparency = 0 }
		):Play()
	end)
	UIJuice.PopIn(refs.Popup, {
		StartScale = 0.74,
		OvershootScale = 1.08,
		Duration = 0.18,
		SettleDuration = 0.16,
	})

	return true
end

function MatchUIController:ShowMatchResult(success, payload)
	self:_stopExcellentCameraEffect()
	if not self:_isResultPayloadCurrent(payload) then
		return
	end

	-- Multi-leg: check if this is an intermediate leg win (leg continuation)
	local MatchController = Knit.GetController("MatchController")
	local currentPayload = MatchController and MatchController._currentPayload
	local tournament = currentPayload and currentPayload.Tournament
	local isLegContinuation = false
	if success and tournament and tournament.AggregatePlayer ~= nil then
		local newAggregatePlayer = (tournament.AggregatePlayer or 0) + 1
		local gap = newAggregatePlayer - (tournament.AggregateOpponent or 0)
		if gap < 1 then
			isLegContinuation = true
		end
	end

	if isLegContinuation then
		-- Already shown at net impact via IncrementMatchScore. Just return.
		return
	end

	-- If this is a winning goal (success == true), wait for the "GOAL!" popup to finish displaying
	if success and self._goalPopupShowedAt then
		local elapsed = os.clock() - self._goalPopupShowedAt
		local remaining = (self._goalPopupDuration or 2.5) - elapsed
		if remaining > 0 then
			task.wait(remaining)
			-- Double check if the payload is still current after yielding
			if not self:_isResultPayloadCurrent(payload) then
				return
			end
		end
	end

	self:HideComparePill()
	self:HideActionBannerNow()
	self:_showCenterPopup(nil, nil, 0)
	self:StopBroadcastClock()
	self._resultPopupToken = (self._resultPopupToken or 0) + 1

	-- A failed action ends the comeback attempt; it is not an opponent goal.
	-- Preserve the authoritative score shown when the action was resolved.

	-- Prefer the artist-authored GUIMatchBattle.MatchFinished popup. The Roact
	-- ResultPopup remains only as a compatibility fallback for old test places.
	if self:_showArtistMatchFinished(success, payload) then
		return
	end

	self:_ensureGui()
	
	local popup = self._resultPopupGroup
	local winLabel = self._resultWinLabel
	local loseLabel = self._resultLoseLabel
	local rewards = self._resultRewardsLabel
	
	if not popup or not rewards then return end
	
	if winLabel and loseLabel and winLabel ~= loseLabel then
		if success then
			winLabel.Visible = true
			loseLabel.Visible = false
		else
			winLabel.Visible = false
			loseLabel.Visible = true
		end
	else
		local title = winLabel
		if title then
			title.Text = ""
			title.Visible = false
		end
	end
	
	local wins = GetPayloadWins(payload)
	rewards.Text = success and string.format("+%s Wins", formatnumber(wins)) or "Try again!"
	
	popup.Visible = true
	popup.GroupTransparency = 1
	UIJuice.Cancel(popup)
	
	TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
	UIJuice.PopIn(popup, {
		StartScale = 0.74,
		OvershootScale = 1.08,
		Duration = 0.18,
		SettleDuration = 0.16,
	})
end

function MatchUIController:HideResultPopup()
	self:_stopExcellentCameraEffect()
	self._resultPopupToken = (self._resultPopupToken or 0) + 1
	local token = self._resultPopupToken
	local playerGui = self:_getPlayerGui()
	local matchBattleGui = playerGui and playerGui:FindFirstChild("GUIMatchBattle")
	local matchFinished = matchBattleGui and matchBattleGui:FindFirstChild("MatchFinished")
	if matchFinished and matchFinished:IsA("GuiObject") then
		local popup = matchFinished:FindFirstChild("Popup")
		if matchFinished.Visible and popup and popup:IsA("GuiObject") then
			pcall(function()
				TweenService:Create(
					popup,
					TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ GroupTransparency = 1 }
				):Play()
			end)
			UIJuice.PopOut(popup, {
				Duration = 0.14,
				EndScale = 0.86,
			}, function()
				if token ~= self._resultPopupToken then
					return
				end
				matchFinished.Visible = false
				popup.Visible = false
			end)
		else
			matchFinished.Visible = false
		end
	end

	self:_ensureGui()
	local popup = self._resultPopupGroup
	if popup then
		if popup.Visible then
			pcall(function()
				TweenService:Create(
					popup,
					TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ GroupTransparency = 1 }
				):Play()
			end)
			UIJuice.PopOut(popup, {
				Duration = 0.14,
				EndScale = 0.86,
			}, function()
				if token ~= self._resultPopupToken then
					return
				end
				popup.Visible = false
			end)
		else
			popup.Visible = false
		end
	end
end

-- Returns "Green", "Yellow", or "Red" for the last confirmed QTE press.
function MatchUIController:GetLastConfirmedTier()
	return self._lastConfirmedTier or "Yellow"
end

function MatchUIController:HideQte(options)
	self:_ensureGui()
	options = typeof(options) == "table" and options or {}

	if options.ResumeBroadcastClock ~= false and self._broadcastHudActive then
		self:SetBroadcastClockTimeScale(1)
		self:ResumeBroadcastClock()
	end

	local qteLayer = self:_getQteLayer()
	if qteLayer then
		qteLayer.Visible = false
	end

	self._activeQte = nil
	self._currentCursorAlpha = 0.5
	self._currentQteLayout = nil
	self:SetQteConfirmCallback(nil)
	self:_stopCursorLoop()
end

function MatchUIController:KnitInit()
	self._guiInitialized = false
	self._matchGui = nil
	
	self._exitCallback = nil
	self._qteConfirmCallback = nil
	self._activeQte = nil
	self._currentCursorAlpha = 0.5
	self._cursorConnection = nil
	self._currentGoalsValue = 0
	self._centerPopupToken = 0
	self._currentQteLayout = nil
	self._lastConfirmedTier = nil
	self._fadeToken = 0
	self._activeFadeTween = nil
	self._activeMatchSessionId = nil
	self._resultUiGeneration = 0
	self._broadcastHudRoot = nil
	self._broadcastHudActive = false
	self._broadcastClockLocked = false
	self._broadcastClockState = nil
	self._broadcastClockConnection = nil
	self._broadcastHomeScoreValue = 0
	self._broadcastAwayScoreValue = 0
	self._actionBannerToken = 0
	self._goalScorerPanelToken = 0
	self._excellentEffectToken = 0
	self._excellentEffectTweens = {}
	self._excellentEffectRecords = nil
	self._excellentEffectRoot = nil
	self._excellentEffectRootVisible = nil
	self._excellentEffectRootEnabled = nil
end

function MatchUIController:KnitStart()
	local function connectCamera(camera)
		if not camera then return end
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:_updateAllResponsiveScales()
		end)
		self:_updateAllResponsiveScales()
	end

	if workspace.CurrentCamera then
		connectCamera(workspace.CurrentCamera)
	end

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		connectCamera(workspace.CurrentCamera)
	end)
end

return MatchUIController
