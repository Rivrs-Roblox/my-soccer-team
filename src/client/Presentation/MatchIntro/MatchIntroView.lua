local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Trove = require(ReplicatedStorage.Packages.Trove)
local PlayerTeamIdentity = require(script.Parent.Parent.Parent.Helpers.PlayerTeamIdentity)
local MatchIntroConfig = require(ReplicatedStorage.Shared.Data.Match.MatchIntroConfig)
local TeamLogoConfig = require(ReplicatedStorage.Shared.Data.TeamLogoConfig)
local FormatNumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)

local MatchIntroView = {}
MatchIntroView.__index = MatchIntroView

-- Artist-authored intro overlay.
-- Runtime path:
-- PlayerGui.MatchIntroOverlayGui
--   DimFrame
--   VsPanel
--     Rewards.RewardWin.NumberText
--     VersusRow.RIVRSLogoBadge.Logo
--     VersusRow.RBXLogoBadge.Logo
--     VersusRow.ScoreBlock.ScoreLabel
--     VersusRow.ScoreBlock.TeamsLabel
--     LeagueLabel
--     MinuteLabel
--     RoundLabel
--     CountdownLabel
local OVERLAY_GUI_NAME = "MatchIntroOverlayGui"
local BLUEPRINTS_GUI_NAME = "Blueprints"
local MATCH_BATTLE_GUI_NAME = "GUIMatchBattle"
local TOURNAMENT_ROOT_NAME = "Tournament"
local LEGACY_MATCH_START_NAME = "MatchStart"
local MATCH_START_POPUP_NAME = "Popup"

local DISPLAY_ORDER = 275

local BASE_Z_INDEX = 900
local DIM_Z_INDEX = BASE_Z_INDEX
local PANEL_Z_INDEX = BASE_Z_INDEX + 40
local CONTENT_Z_INDEX = BASE_Z_INDEX + 60

local DEFAULT_REWARD_TEXT = "0"
local MATCH_START_BLUR_NAME = "__MatchStartBackgroundBlur"
local MATCH_START_BLUR_SIZE = 12
local FADE_ORIGINAL_ATTRIBUTE_PREFIX = "MatchIntroOriginal"

local COLORS = {
	Dim = Color3.fromRGB(0, 0, 0),
	White = Color3.fromRGB(255, 255, 255),
}

local function getTiming(name, fallback)
	local timings = MatchIntroConfig.Timings or {}
	local value = tonumber(timings[name])
	if value == nil then
		return fallback
	end
	return value
end

local function safeText(value, fallback)
	if value == nil then
		return fallback
	end

	local text = tostring(value)
	if text == "" then
		return fallback
	end

	return text
end

local function resolvePlayerTeamName(value)
	local text = safeText(value, "")
	if text == "" or text == "FC Rivrs" or text == "Rivrs FC" then
		return PlayerTeamIdentity.GetName("Player")
	end

	return text
end

local function normalizeAssetId(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end

	if type(value) ~= "string" or value == "" then
		return nil
	end

	if string.find(value, "rbxassetid://", 1, true) then
		return value
	end

	if tonumber(value) ~= nil then
		return "rbxassetid://" .. value
	end

	return value
end

local function findChild(parent, name)
	if not parent then
		return nil
	end

	return parent:FindFirstChild(name)
end

local function findPath(root, path)
	local current = root

	for _, name in ipairs(path) do
		current = findChild(current, name)
		if not current then
			return nil
		end
	end

	return current
end

local function asGuiObject(instance)
	if instance and instance:IsA("GuiObject") then
		return instance
	end

	return nil
end

local function asTextLabel(instance)
	if instance and instance:IsA("TextLabel") then
		return instance
	end

	return nil
end

local function asImageObject(instance)
	if instance and (instance:IsA("ImageLabel") or instance:IsA("ImageButton")) then
		return instance
	end

	return nil
end

local function setVisible(instance, visible)
	local object = asGuiObject(instance)
	if object then
		object.Visible = visible
	end
end

local function setEnabled(instance, enabled)
	if instance and instance:IsA("ScreenGui") then
		instance.Enabled = enabled
	end
end

local function setText(instance, text)
	local label = asTextLabel(instance)
	if label then
		label.Text = tostring(text or "")
	end
end

local function setImageIfProvided(instance, imageId)
	local image = normalizeAssetId(imageId)
	if not image then
		return
	end

	local imageObject = asImageObject(instance)
	if imageObject then
		imageObject.Image = image
		imageObject.Visible = true
	end
end

local function formatMinute(value)
	local minute = tonumber(value) or 86
	return string.format("%dth Minute", minute)
end

local function formatMinuteShort(value)
	local minute = tonumber(value) or 86
	return string.format("%d'", minute)
end

local function formatRoundOf(value)
	local text = safeText(value, "ROUND OF 16")
	return string.upper(text)
end

local function resolveDrawScore(introData)
	local currentScore = introData.CurrentScore
	if typeof(currentScore) == "table" then
		local home = tonumber(currentScore.Home)
		local away = tonumber(currentScore.Away)
		if home ~= nil and away ~= nil then
			return home, away
		end
	end

	local rawHome = tonumber(introData.HomeScore)
	local rawAway = tonumber(introData.AwayScore)
	if rawHome ~= nil and rawAway ~= nil then
		return rawHome, rawAway
	end

	return 0, 0
end

local function resolveRewardText(introData)
	local numericCandidates = {
		introData.RewardWins,
		introData.WinsReward,
		introData.RewardAmount,
		introData.WinReward,
	}

	for _, value in ipairs(numericCandidates) do
		local numberValue = tonumber(value)
		if numberValue ~= nil then
			return FormatNumber(numberValue)
		end
	end

	local textCandidates = {
		introData.RewardText,
		introData.MatchRewardText,
		introData.WinRewardText,
	}

	for _, value in ipairs(textCandidates) do
		if value ~= nil and tostring(value) ~= "" then
			local numericText = string.match(tostring(value), "%d+%.?%d*")
			local numberValue = tonumber(numericText)
			if numberValue ~= nil then
				return FormatNumber(numberValue)
			end
			return tostring(value)
		end
	end

	return DEFAULT_REWARD_TEXT
end

local function resolveTeamLogo(introData, teamName, providedLogo)
	local rawHomeTeamName = introData and safeText(introData.HomeTeamName, "FC Rivrs") or ""
	if introData and (teamName == rawHomeTeamName or teamName == resolvePlayerTeamName(rawHomeTeamName)) then
		return PlayerTeamIdentity.GetThumbnail()
	end

	local logo = normalizeAssetId(providedLogo)
	local isPlaceholder = not logo or logo == "" or logo == "rbxassetid://0" or string.find(logo, "000000")

	if not isPlaceholder then
		return logo
	end

	if introData and introData.AreaId and teamName then
		local configLogo = TeamLogoConfig.GetTeamLogo(introData.AreaId, teamName)
		if configLogo ~= "" then
			return configLogo
		end
	end

	return logo
end

local function normalizeOverlayLayering(overlayGui, refs)
	if overlayGui and overlayGui:IsA("ScreenGui") then
		overlayGui.DisplayOrder = math.max(overlayGui.DisplayOrder, DISPLAY_ORDER)
		overlayGui.IgnoreGuiInset = true
		overlayGui.ResetOnSpawn = false
		overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	end

	local dim = refs and refs.DimFrame
	if dim then
		dim.ZIndex = DIM_Z_INDEX
	end

	local panel = refs and refs.VsPanel
	if panel then
		panel.ZIndex = PANEL_Z_INDEX
	end

	if panel then
		for _, descendant in ipairs(panel:GetDescendants()) do
			local object = asGuiObject(descendant)
			if object then
				if object:IsA("TextLabel") or object:IsA("ImageLabel") or object:IsA("ImageButton") then
					object.ZIndex = math.max(object.ZIndex, CONTENT_Z_INDEX)
				else
					object.ZIndex = math.max(object.ZIndex, PANEL_Z_INDEX + 1)
				end
			end
		end
	end
end

local function getFadeAttributeName(propertyName)
	return FADE_ORIGINAL_ATTRIBUTE_PREFIX .. tostring(propertyName)
end

local function readOriginalFadeValue(instance, propertyName, fallback)
	local attributeName = getFadeAttributeName(propertyName)
	local stored = instance:GetAttribute(attributeName)
	
	-- Force recovery for corrupted BackgroundTransparency/TextTransparency 
	-- that might have been saved as 1 (invisible) during previous buggy sessions
	if typeof(stored) == "number" then
		if stored >= 0.99 and propertyName ~= "BackgroundTransparency" then
			stored = 0
			instance:SetAttribute(attributeName, 0)
		end
		return stored
	end

	local value = fallback

	if propertyName == "TextTransparency" or propertyName == "ImageTransparency" or propertyName == "Transparency" then
		if typeof(value) ~= "number" or value >= 0.99 then
			value = 0
		end
	end

	pcall(function()
		instance:SetAttribute(attributeName, value)
	end)

	return value
end

local function collectFadeTargets(root)
	local targets = {}

	local function addTarget(instance, propertyName, fallbackValue)
		local targetValue = readOriginalFadeValue(instance, propertyName, fallbackValue)

		table.insert(targets, {
			Instance = instance,
			PropertyName = propertyName,
			TargetValue = targetValue,
		})
	end

	local function scan(instance)
		if instance:IsA("Frame") or instance:IsA("TextButton") or instance:IsA("ImageButton") then
			addTarget(instance, "BackgroundTransparency", instance.BackgroundTransparency)
		end

		if instance:IsA("TextLabel") or instance:IsA("TextButton") then
			addTarget(instance, "TextTransparency", instance.TextTransparency)
		end

		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			addTarget(instance, "ImageTransparency", instance.ImageTransparency)
		end

		if instance:IsA("UIStroke") then
			addTarget(instance, "Transparency", instance.Transparency)
		end

		for _, child in ipairs(instance:GetChildren()) do
			scan(child)
		end
	end

	if root then
		scan(root)
	end

	return targets
end

function MatchIntroView.new()
	local self = setmetatable({}, MatchIntroView)

	self._trove = Trove.new()
	self._overlayTrove = nil
	self._activePlayId = 0
	self._activeTweens = {}
	self._overlayGui = nil
	self._suppressedGuiStates = {}
	self._usesArtistMatchStart = false
	self._visibilityGuardConnection = nil
	self._artistRefs = nil
	self._activeFadeTargets = nil
	self._activeBlurEffect = nil
	self._previousBlurSize = nil

	return self
end

function MatchIntroView:_getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	return player:WaitForChild("PlayerGui", 5)
end


function MatchIntroView:_enableMatchStartBackgroundBlur()
	local blur = Lighting:FindFirstChild(MATCH_START_BLUR_NAME)
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = MATCH_START_BLUR_NAME
		blur.Size = 0
		blur.Parent = Lighting
	end

	if not blur:IsA("BlurEffect") then
		return
	end

	self._activeBlurEffect = blur
	self._previousBlurSize = blur.Size
	self:_createTween(blur, 0.25, { Size = MATCH_START_BLUR_SIZE }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
end

function MatchIntroView:_disableMatchStartBackgroundBlur()
	local blur = self._activeBlurEffect or Lighting:FindFirstChild(MATCH_START_BLUR_NAME)
	self._activeBlurEffect = nil

	if not (blur and blur:IsA("BlurEffect")) then
		return
	end

	local targetSize = tonumber(self._previousBlurSize) or 0
	self._previousBlurSize = nil

	local tween = TweenService:Create(
		blur,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = targetSize }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if blur.Parent and blur.Name == MATCH_START_BLUR_NAME and blur.Size <= 0.05 then
			blur:Destroy()
		end
	end)
end

function MatchIntroView:_cancelTweens()
	for _, tween in ipairs(self._activeTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(self._activeTweens)
end

function MatchIntroView:_createTween(instance, duration, properties, easingStyle, easingDirection)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
		properties
	)

	table.insert(self._activeTweens, tween)
	return tween
end

function MatchIntroView:_isActive(playId)
	return self._activePlayId == playId and self._overlayTrove ~= nil
end

function MatchIntroView:_waitActive(playId, duration)
	local deadline = os.clock() + math.max(tonumber(duration) or 0, 0)

	while self:_isActive(playId) and os.clock() < deadline do
		task.wait(math.min(0.05, math.max(deadline - os.clock(), 0)))
	end

	return self:_isActive(playId)
end

function MatchIntroView:_getStarterOverlayTemplate()
	return StarterGui:FindFirstChild(OVERLAY_GUI_NAME)
end

function MatchIntroView:_destroyRuntimeOverlay(reason)
	self:_stopVisibilityGuard()

	local root = self._overlayGui
	self._overlayGui = nil
	self._artistRefs = nil

	if self._usesArtistMatchStart then
		self._usesArtistMatchStart = false
		local playerGui = self:_getPlayerGui()
		local matchBattleGui = playerGui and playerGui:FindFirstChild(MATCH_BATTLE_GUI_NAME)
		local matchStart = matchBattleGui and matchBattleGui:FindFirstChild(LEGACY_MATCH_START_NAME)
		local popup = matchStart and matchStart:FindFirstChild(MATCH_START_POPUP_NAME)

		local matchStartObject = asGuiObject(matchStart)
		if matchStartObject then
			matchStartObject.BackgroundTransparency = 1
			matchStartObject.Visible = false
		end

		setVisible(popup, true)
		return
	end

	if root and root.Parent then
		root:Destroy()
	end
end

function MatchIntroView:_createFreshOverlayGui()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local existing = playerGui:FindFirstChild(OVERLAY_GUI_NAME)
	local template = self:_getStarterOverlayTemplate()

	local fallbackClone = nil
	if not template and existing then
		fallbackClone = existing:Clone()
		template = fallbackClone
	end

	if existing then
		existing:Destroy()
	end

	if not template then
		warn(string.format("[MatchIntro] Missing StarterGui.%s template.", OVERLAY_GUI_NAME))
		return nil
	end

	local freshRoot = template:Clone()
	freshRoot.Name = OVERLAY_GUI_NAME
	freshRoot.Parent = playerGui

	if not freshRoot:IsA("ScreenGui") then
		warn(string.format("[MatchIntro] %s must be a ScreenGui.", OVERLAY_GUI_NAME))
		freshRoot:Destroy()
		return nil
	end

	freshRoot.Enabled = false
	freshRoot.IgnoreGuiInset = true
	freshRoot.ResetOnSpawn = false
	freshRoot.DisplayOrder = math.max(freshRoot.DisplayOrder, DISPLAY_ORDER)
	freshRoot.ZIndexBehavior = Enum.ZIndexBehavior.Global
	self._overlayGui = freshRoot

	return freshRoot
end

function MatchIntroView:_rememberGuiState(instance, propertyName, value)
	table.insert(self._suppressedGuiStates, {
		Instance = instance,
		PropertyName = propertyName,
		Value = value,
	})
end

function MatchIntroView:_restoreSuppressedGui()
	for index = #self._suppressedGuiStates, 1, -1 do
		local state = self._suppressedGuiStates[index]
		local instance = state.Instance

		if instance and instance.Parent then
			pcall(function()
				instance[state.PropertyName] = state.Value
			end)
		end
	end

	table.clear(self._suppressedGuiStates)
end

function MatchIntroView:_forceTournamentHidden()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	local blueprints = playerGui:FindFirstChild(BLUEPRINTS_GUI_NAME)
	if blueprints then
		local tournament = blueprints:FindFirstChild(TOURNAMENT_ROOT_NAME)
		setVisible(tournament, false)
		local legacyMatchStart = blueprints:FindFirstChild(LEGACY_MATCH_START_NAME)
		setVisible(legacyMatchStart, false)
	end

	local matchBattleGui = playerGui:FindFirstChild(MATCH_BATTLE_GUI_NAME)
	if matchBattleGui then
		local tournament = matchBattleGui:FindFirstChild(TOURNAMENT_ROOT_NAME)
		setVisible(tournament, false)
	end
end

function MatchIntroView:_suppressOtherGui(overlayGui)
	self:_restoreSuppressedGui()

	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	for _, child in ipairs(playerGui:GetChildren()) do
		if child == overlayGui then
			continue
		end

		if child:IsA("ScreenGui") then
			local restoreEnabled = child.Name == OVERLAY_GUI_NAME and false or child.Enabled
			self:_rememberGuiState(child, "Enabled", restoreEnabled)
			child.Enabled = false
		elseif child:IsA("GuiObject") then
			self:_rememberGuiState(child, "Visible", child.Visible)
			child.Visible = false
		end
	end
end

function MatchIntroView:_setFadeTargets(targets, mode)
	for _, target in ipairs(targets) do
		local instance = target.Instance
		if instance and instance.Parent then
			local value = mode == "hidden" and 1 or target.TargetValue
			pcall(function()
				instance[target.PropertyName] = value
			end)
		end
	end
end

function MatchIntroView:_tweenFadeTargets(targets, duration, mode)
	for _, target in ipairs(targets) do
		local instance = target.Instance
		if instance and instance.Parent then
			local value = mode == "hidden" and 1 or target.TargetValue
			self:_createTween(instance, duration, {
				[target.PropertyName] = value,
			}):Play()
		end
	end
end


function MatchIntroView:_resolveArtistMatchStartRefs()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local matchBattleGui = playerGui:FindFirstChild(MATCH_BATTLE_GUI_NAME)
	if not (matchBattleGui and matchBattleGui:IsA("ScreenGui")) then
		return nil
	end

	local matchStart = asGuiObject(matchBattleGui:FindFirstChild(LEGACY_MATCH_START_NAME))
	local popup = asGuiObject(matchStart and matchStart:FindFirstChild(MATCH_START_POPUP_NAME))
	if not (matchStart and popup) then
		return nil
	end

	local versus = popup:FindFirstChild("Versus")
	local playerFrame = versus and versus:FindFirstChild("Player")
	local enemyFrame = versus and versus:FindFirstChild("Enemy")
	
	-- Function to find a child either in popup directly, or inside Versus frame
	local function findInPopupOrVersus(name)
		return popup:FindFirstChild(name) or (versus and versus:FindFirstChild(name))
	end

	return {
		OverlayGui = matchBattleGui,
		Root = matchStart,
		DimFrame = matchStart,
		VsPanel = popup,
		PlayerLogo = playerFrame and playerFrame:FindFirstChild("Logo"),
		EnemyLogo = enemyFrame and enemyFrame:FindFirstChild("Logo"),
		PlayerNameText = playerFrame and playerFrame:FindFirstChild("NameText"),
		EnemyNameText = enemyFrame and enemyFrame:FindFirstChild("NameText"),
		PlayerScoreText = findInPopupOrVersus("PlayerScoreText"),
		EnemyScoreText = findInPopupOrVersus("EnemyScoreText"),
		VsText = findInPopupOrVersus("VsText"),
		TitleText = findInPopupOrVersus("TitleText"),
		RoundOf = findInPopupOrVersus("RoundOf") or findInPopupOrVersus("RoundText") or findInPopupOrVersus("RoundLabel"),
		Time = findInPopupOrVersus("Time") or findInPopupOrVersus("TimeText") or findInPopupOrVersus("TimeLabel") or findInPopupOrVersus("MinuteText") or findInPopupOrVersus("MinuteLabel"),
		Tournament = matchBattleGui:FindFirstChild(TOURNAMENT_ROOT_NAME),
	}
end

function MatchIntroView:_startVisibilityGuard(refs)
	self:_stopVisibilityGuard()
	self._artistRefs = refs

	self._visibilityGuardConnection = RunService.RenderStepped:Connect(function()
		local guardRefs = self._artistRefs
		if not guardRefs then
			return
		end

		setEnabled(guardRefs.OverlayGui, true)
		setVisible(guardRefs.Root, true)
		setVisible(guardRefs.VsPanel, true)
		setVisible(guardRefs.Tournament, false)
	end)
end

function MatchIntroView:_stopVisibilityGuard()
	if self._visibilityGuardConnection then
		self._visibilityGuardConnection:Disconnect()
		self._visibilityGuardConnection = nil
	end
	self._artistRefs = nil
end

function MatchIntroView:_bindArtistMatchStartData(refs, introData)
	local roundName = safeText(introData.RoundName, "ROUND OF 16")
	local titleText = safeText(introData.MatchTitle or introData.TitleText, "MATCH START")
	local homeTeam = resolvePlayerTeamName(introData.HomeTeamName)
	local awayTeam = safeText(introData.AwayTeamName, "FC Roblox")
	local homeScore, awayScore = resolveDrawScore(introData)

	setText(refs.TitleText, titleText)
	setText(refs.RoundOf, formatRoundOf(roundName))
	setText(refs.Time, formatMinuteShort(introData.MatchMinute))
	setText(refs.PlayerNameText, homeTeam)
	setText(refs.EnemyNameText, awayTeam)
	setText(refs.PlayerScoreText, tostring(homeScore))
	setText(refs.EnemyScoreText, tostring(awayScore))
	
	if refs.PlayerScoreText then
		refs.PlayerScoreText.Visible = true
		refs.PlayerScoreText.TextTransparency = 0
	end
	if refs.EnemyScoreText then
		refs.EnemyScoreText.Visible = true
		refs.EnemyScoreText.TextTransparency = 0
	end
	
	setText(refs.VsText, "VS")
	setImageIfProvided(refs.PlayerLogo, resolveTeamLogo(introData, homeTeam, introData.HomeLogo))
	setImageIfProvided(refs.EnemyLogo, resolveTeamLogo(introData, awayTeam, introData.AwayLogo))
end

function MatchIntroView:_buildArtistMatchStartOverlay(introData)
	local refs = self:_resolveArtistMatchStartRefs()
	if not refs then
		return nil
	end

	local overlayTrove = Trove.new()
	self._overlayTrove = overlayTrove
	self._overlayGui = refs.OverlayGui
	self._usesArtistMatchStart = true

	self:_forceTournamentHidden()
	self:_suppressOtherGui(refs.OverlayGui)
	self:_forceTournamentHidden()
	self:_enableMatchStartBackgroundBlur()

	setEnabled(refs.OverlayGui, true)
	setVisible(refs.Root, true)
	setVisible(refs.VsPanel, true)
	setVisible(refs.Tournament, false)
		
	normalizeOverlayLayering(refs.OverlayGui, refs)

	self:_bindArtistMatchStartData(refs, introData)

	local panelScale = refs.VsPanel:FindFirstChild("PanelScale") or refs.VsPanel:FindFirstChildOfClass("UIScale")
	if not (panelScale and panelScale:IsA("UIScale")) then
		panelScale = Instance.new("UIScale")
		panelScale.Name = "PanelScale"
		panelScale.Parent = refs.VsPanel
		overlayTrove:Add(panelScale)
	end

	local fadeTargets = collectFadeTargets(refs.VsPanel)
	self._activeFadeTargets = fadeTargets
	self:_setFadeTargets(fadeTargets, "hidden")
	panelScale.Scale = 0.88
	refs.Root.BackgroundColor3 = COLORS.Dim
	refs.Root.BackgroundTransparency = 1

	self:_startVisibilityGuard(refs)

	return {
		OverlayGui = refs.OverlayGui,
		DimFrame = refs.Root,
		VsPanel = refs.VsPanel,
		PanelScale = panelScale,
		FadeTargets = fadeTargets,
		CountdownLabel = nil,
	}
end

function MatchIntroView:_resolveRefs(overlayGui)
	local vsPanel = asGuiObject(findChild(overlayGui, "VsPanel"))
	local dimFrame = asGuiObject(findChild(overlayGui, "DimFrame"))

	if not vsPanel then
		warn("[MatchIntro] Missing MatchIntroOverlayGui.VsPanel.")
		return nil
	end

	if not dimFrame then
		warn("[MatchIntro] Missing MatchIntroOverlayGui.DimFrame.")
		return nil
	end

	local refs = {
		OverlayGui = overlayGui,
		DimFrame = dimFrame,
		VsPanel = vsPanel,
		Rewards = findChild(vsPanel, "Rewards"),
		RewardWin = findPath(vsPanel, { "Rewards", "RewardWin" }),
		VersusRow = findChild(vsPanel, "VersusRow"),
		RivrsLogo = findPath(vsPanel, { "VersusRow", "RIVRSLogoBadge", "Logo" }),
		EnemyLogo = findPath(vsPanel, { "VersusRow", "RBXLogoBadge", "Logo" }),
		ScoreLabel = findPath(vsPanel, { "VersusRow", "ScoreBlock", "ScoreLabel" }),
		TeamsLabel = findPath(vsPanel, { "VersusRow", "ScoreBlock", "TeamsLabel" }),
		LeagueLabel = findChild(vsPanel, "LeagueLabel"),
		MinuteLabel = findChild(vsPanel, "MinuteLabel"),
		RoundLabel = findChild(vsPanel, "RoundLabel"),
		CountdownLabel = findChild(vsPanel, "CountdownLabel"),
		RewardNumberText = findPath(vsPanel, { "Rewards", "RewardWin", "NumberText" }),
	}

	return refs
end

function MatchIntroView:_bindOverlayData(refs, introData)
	local leagueName = safeText(introData.LeagueName or introData.CupName, "Youth League")
	local roundName = safeText(introData.RoundName, "Final Attack")
	local minuteText = formatMinute(introData.MatchMinute)

	local homeTeam = resolvePlayerTeamName(introData.HomeTeamName)
	local awayTeam = safeText(introData.AwayTeamName, "FC Roblox")
	local homeScore, awayScore = resolveDrawScore(introData)

	setText(refs.LeagueLabel, string.upper(leagueName))
	setText(refs.RoundLabel, roundName)
	setText(refs.MinuteLabel, minuteText)
	setText(refs.TeamsLabel, string.format("%s   VS   %s", homeTeam, awayTeam))
	setText(refs.ScoreLabel, string.format("%d - %d", homeScore, awayScore))
	setText(refs.RewardNumberText, resolveRewardText(introData))

	setImageIfProvided(refs.RivrsLogo, resolveTeamLogo(introData, homeTeam, introData.HomeLogo))
	setImageIfProvided(refs.EnemyLogo, resolveTeamLogo(introData, awayTeam, introData.AwayLogo))

	local countdownLabel = asTextLabel(refs.CountdownLabel)
	if countdownLabel then
		countdownLabel.Text = ""
		countdownLabel.Visible = false
		countdownLabel.TextTransparency = 1
	end
end

function MatchIntroView:_buildOverlay(introData)
	local artistRefs = self:_buildArtistMatchStartOverlay(introData)
	if artistRefs then
		return artistRefs
	end

	local overlayGui = self:_createFreshOverlayGui()
	if not overlayGui then
		return nil
	end

	local refs = self:_resolveRefs(overlayGui)
	if not refs then
		return nil
	end

	local overlayTrove = Trove.new()
	self._overlayTrove = overlayTrove

	self:_forceTournamentHidden()
	self:_suppressOtherGui(overlayGui)
	self:_forceTournamentHidden()

	overlayGui.Enabled = true
	refs.DimFrame.Visible = true
	refs.VsPanel.Visible = true
	setVisible(refs.CountdownLabel, false)

	normalizeOverlayLayering(overlayGui, refs)
	self:_bindOverlayData(refs, introData)

	local panelScale = refs.VsPanel:FindFirstChild("PanelScale")
	local createdPanelScale = false
	if not (panelScale and panelScale:IsA("UIScale")) then
		panelScale = Instance.new("UIScale")
		panelScale.Name = "PanelScale"
		panelScale.Parent = refs.VsPanel
		createdPanelScale = true
	end
	if createdPanelScale then
		overlayTrove:Add(panelScale)
	end

	local fadeTargets = collectFadeTargets(refs.VsPanel)
	self._activeFadeTargets = fadeTargets
	self:_setFadeTargets(fadeTargets, "hidden")
	panelScale.Scale = 0.88
	refs.DimFrame.BackgroundTransparency = 1

	return {
		OverlayGui = overlayGui,
		DimFrame = refs.DimFrame,
		VsPanel = refs.VsPanel,
		PanelScale = panelScale,
		FadeTargets = fadeTargets,
		CountdownLabel = asTextLabel(refs.CountdownLabel),
	}
end

function MatchIntroView:_playVsIntro(playId, refs)
	local fadeIn = getTiming("VsFadeIn", 0.25)
	local hold = getTiming("VsHold", 3.0)
	local fadeOut = getTiming("VsFadeOut", 0.25)

	local shownDimTransparency = math.max(getTiming("VsDimTransparency", 0.9), 0.86)
	if self._usesArtistMatchStart then
		shownDimTransparency = math.min(shownDimTransparency, 0.78)
	end
	local popDuration = math.min(fadeIn * 0.72, 0.18)
	local settleDuration = math.max(fadeIn - popDuration, 0.08)
	self:_createTween(refs.DimFrame, fadeIn, { BackgroundTransparency = shownDimTransparency }):Play()
	self:_createTween(refs.PanelScale, popDuration, { Scale = 1.08 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
	task.delay(popDuration, function()
		if self:_isActive(playId) and refs.PanelScale and refs.PanelScale.Parent then
			self:_createTween(refs.PanelScale, settleDuration, { Scale = 1.0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
		end
	end)
	self:_tweenFadeTargets(refs.FadeTargets, fadeIn, "shown")

	if not self:_waitActive(playId, fadeIn + hold) then
		return false
	end

	self:_createTween(refs.PanelScale, fadeOut, { Scale = 0.78 }, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
	self:_tweenFadeTargets(refs.FadeTargets, fadeOut, "hidden")

	if not self:_waitActive(playId, fadeOut) then
		return false
	end

	refs.VsPanel.Visible = false
	return true
end

function MatchIntroView:_playCountdown(playId, refs)
	local stepDuration = getTiming("CountdownStep", 0.85)
	local countdownLabel = refs.CountdownLabel

	if not countdownLabel then
		return true
	end

	countdownLabel.Visible = true
	countdownLabel.TextTransparency = 1

	local countdownScale = countdownLabel:FindFirstChildOfClass("UIScale")
	if not countdownScale then
		countdownScale = Instance.new("UIScale")
		countdownScale.Name = "CountdownScale"
		countdownScale.Parent = countdownLabel
	end

	for value = 3, 1, -1 do
		if not self:_isActive(playId) then
			return false
		end

		countdownLabel.Text = tostring(value)
		countdownLabel.TextColor3 = COLORS.White
		countdownLabel.TextTransparency = 1
		countdownScale.Scale = 0.62

		self:_createTween(countdownLabel, stepDuration * 0.20, { TextTransparency = 0 }):Play()
		self:_createTween(countdownScale, stepDuration * 0.24, { Scale = 1.1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

		if not self:_waitActive(playId, stepDuration * 0.55) then
			return false
		end

		self:_createTween(countdownLabel, stepDuration * 0.22, { TextTransparency = 1 }):Play()
		self:_createTween(countdownScale, stepDuration * 0.22, { Scale = 1.32 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()

		if not self:_waitActive(playId, stepDuration * 0.23) then
			return false
		end
	end

	countdownLabel.Visible = false
	return true
end

local function getStartVeilTransparency()
	local timings = MatchIntroConfig.Timings or {}
	local configured = tonumber(timings.MatchStartVeilTransparency)

	-- Older builds used a very transparent veil (around 0.9). For the current
	-- match handoff we need a real black cover so the character/proxy spawn frame
	-- is hidden. Cap the value so even stale config cannot make the veil too clear.
	return math.clamp(configured or 0.05, 0, 0.15)
end

function MatchIntroView:_releasePresentationBehindStartVeil(playId, refs, _onCountdownComplete)
	local veilFadeIn = getTiming("MatchStartVeilFadeIn", 0.10)
	local veilHold = math.max(getTiming("MatchStartVeilHold", 0.55), 0.45)
	local veilTransparency = getStartVeilTransparency()

	-- Hide the last overlay handoff frame behind a short black veil.
	-- Do not release the server presentation gate here; otherwise the first
	-- approach can complete while the veil is still covering the screen.
	refs.DimFrame.Visible = true
	refs.DimFrame.BackgroundColor3 = COLORS.Dim
	refs.DimFrame.ZIndex = math.max(refs.DimFrame.ZIndex, CONTENT_Z_INDEX + 20)

	self:_createTween(refs.DimFrame, veilFadeIn, { BackgroundTransparency = veilTransparency }):Play()
	if not self:_waitActive(playId, veilFadeIn) then
		return false
	end

	if veilHold > 0 then
		return self:_waitActive(playId, veilHold)
	end

	return self:_isActive(playId)
end

function MatchIntroView:PlayIntro(introData, token, onCountdownComplete)
	introData = type(introData) == "table" and introData or {}

	self:Cancel("Restart")

	local playId = self._activePlayId + 1
	self._activePlayId = playId

	local refs = self:_buildOverlay(introData)
	if not refs then
		warn("[MatchIntro] artist overlay could not be resolved; releasing presentation.")
		return true
	end

	local ok = self:_playVsIntro(playId, refs)
	if ok then
		ok = self:_playCountdown(playId, refs)
	end

	if ok and self:_isActive(playId) then
		ok = self:_releasePresentationBehindStartVeil(playId, refs, onCountdownComplete)
	end

	if ok and self:_isActive(playId) then
		if type(onCountdownComplete) == "function" then
			local releaseOk, releaseResult = pcall(onCountdownComplete)
			if not releaseOk then
				warn("[MatchIntro] release callback failed: " .. tostring(releaseResult))
				ok = false
			elseif releaseResult ~= true then
				ok = false
			end
		end
	end

	if ok and self:_isActive(playId) then
		local postReleaseHold = math.max(getTiming("PostReleaseVeilHold", 0.18), 0)
		if postReleaseHold > 0 then
			ok = self:_waitActive(playId, postReleaseHold)
		end
	end

	if ok and self:_isActive(playId) then
		local finalFade = getTiming("FinalFadeOut", 0.2)
		self:_createTween(refs.DimFrame, finalFade, { BackgroundTransparency = 1 }):Play()
		self:_waitActive(playId, finalFade)
	end

	local completed = ok and self:_isActive(playId)
	self:Cancel(completed and "Completed" or "Interrupted")
	return completed == true
end

function MatchIntroView:Cancel(_reason)
	self._activePlayId += 1
	self:_cancelTweens()
	self:_disableMatchStartBackgroundBlur()
	self:_stopVisibilityGuard()
	if self._activeFadeTargets then
		self:_setFadeTargets(self._activeFadeTargets, "shown")
		self._activeFadeTargets = nil
	end
	self:_restoreSuppressedGui()
	self:_forceTournamentHidden()
	self:_destroyRuntimeOverlay(tostring(_reason))

	if self._overlayTrove then
		self._overlayTrove:Destroy()
		self._overlayTrove = nil
	end
end

function MatchIntroView:Destroy()
	self:Cancel("Destroy")
	self._trove:Destroy()
end

return MatchIntroView
