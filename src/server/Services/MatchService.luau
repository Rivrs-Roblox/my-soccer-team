local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchConstants = require(ReplicatedStorage.Shared.Data.Match.MatchConstants)
local MatchAreaConfig = require(ReplicatedStorage.Shared.Data.Match.MatchAreaConfig)
local MatchIntroConfig = require(ReplicatedStorage.Shared.Data.Match.MatchIntroConfig)
local MatchGrounding = require(ReplicatedStorage.Shared.Helpers.Match.MatchGrounding)
local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchRosterBuilder = require(ReplicatedStorage.Shared.Helpers.Match.MatchRosterBuilder)
local MatchSequenceBuilder = require(ReplicatedStorage.Shared.Helpers.Match.MatchSequenceBuilder)
local MatchResolution = require(ReplicatedStorage.Shared.Helpers.Match.MatchResolution)
local MatchFlowRules = require(ReplicatedStorage.Shared.Helpers.Match.MatchFlowRules)
local TournamentRewardCalculator = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentRewardCalculator)
local TournamentConfig = require(ReplicatedStorage.Shared.Domain.Tournament.TournamentConfig)
local SoccerCharactersTemplate = require(ReplicatedStorage.Shared.Data.Template.SoccerCharacters)

local DataService = nil
local TrainingService = nil
local MatchWorldService = nil
local TournamentService = nil
local TradeService = nil

local registeredPrompts = {}
local registeredTouchParts = {}
local touchDebounces = {}
local activeSessions = {}
local pendingTransitions = {}
local pendingTournamentSources = {}
local tournamentContinuationReturnCFrames = {}
local tournamentContinuationReturnSources = {}
local activeChampionCeremonies = {}
-- Token per player to guard leg-continuation task.delay callbacks.
-- Cleared on defeat/exit so a stale delayed callback cannot restart the match.
local legContinuationTokens = {}
-- A QTE defeat is terminal regardless of the current aggregate score. The next
-- match may only start after the player explicitly confirms a fresh preview.
local defeatRestartLocks = {}
-- Auto battle gates are edge-triggered after defeat: the player must leave the
-- trigger before it can open another preview.
local defeatGateRearmRequired = {}
local nextZoneVariationIndex = 1

local AUTO_BATTLE_TOUCH_DEBOUNCE = 0.85
local AUTO_BATTLE_TOUCH_PART_NAMES = {
	BattleGate = true,
	BattleTrigger = true,
	EnterArea = true,
	MatchGate = true,
	MatchTrigger = true,
	MatchStart = true,
	StartMatch = true,
	StartMatchTrigger = true,
}

local BATTLE_RETURN_POINT_NAMES = {
	BattleReturnPoint = true,
	MatchReturnPoint = true,
	LobbyReturnPoint = true,
	MatchLobbyReturnPoint = true,
	BattleExitPoint = true,
}

local BATTLE_RETURN_POINT_ATTRIBUTES = {
	BattleReturnPoint = true,
	MatchReturnPoint = true,
	LobbyReturnPoint = true,
	BattleExitPoint = true,
}

local RETURN_CLIENT_FADE_LEAD_SECONDS = 0.18
local RETURN_ATTENDANCE_DISTANCE_TOLERANCE = 3.25
local CHAMPION_CEREMONY_DURATION_SECONDS = 20
local CHAMPION_CEREMONY_START_DELAY_SECONDS = 0.30
local AUTO_BATTLE_ZONE_SCAN_INTERVAL = 0.30
local MATCH_INTRO_ACK_MAX_WAIT = tonumber(MatchIntroConfig.ServerMaxWaitSeconds) or 8.0

--| Match Service |--
local MatchService = Knit.CreateService({
	Name = "MatchService",

	Client = {
		MatchFeedback = Knit.CreateSignal(),
		MatchTransitionRequested = Knit.CreateSignal(),
		MatchSessionStarted = Knit.CreateSignal(),
		MatchSessionEnded = Knit.CreateSignal(),
		ChampionCeremonyStarted = Knit.CreateSignal(),
		ChampionCeremonyEnded = Knit.CreateSignal(),
		MatchReturnStarted = Knit.CreateSignal(),
		MatchReturnAttendance = Knit.CreateSignal(),
		MatchApproachStarted = Knit.CreateSignal(),
		MatchStepStarted = Knit.CreateSignal(),
		MatchStepResolved = Knit.CreateSignal(),
	},
})

--| Local Functions |--

local function SendFeedback(service, player, feedbackType, message)
	service.Client.MatchFeedback:Fire(player, feedbackType, message)
end

local function GetPlayerAreaId(playerData)
	if playerData.Areas and playerData.Areas.Current then
		return playerData.Areas.Current
	end
	return MatchConstants.DEFAULT_AREA_ID
end

local function GetPlayerStats(playerData)
	local stats = playerData.Stats or {}
	return {
		Shoot = tonumber(stats.Shoot) or 0,
		Pass = tonumber(stats.Pass) or 0,
		Dribble = tonumber(stats.Dribble) or 0,
	}
end

local function CloneEnemySteps(areaId, roundId)
	local config = MatchAreaConfig[areaId] or MatchAreaConfig[MatchConstants.DEFAULT_AREA_ID]
	local resolvedRoundId = tostring(roundId or "RoundOf16")
	local sourceSteps = nil

	if config and config.RoundEnemySteps then
		sourceSteps = config.RoundEnemySteps[resolvedRoundId]
	end

	sourceSteps = sourceSteps or (config and config.EnemySteps) or {}

	local result = {}
	for stepIndex, stepData in ipairs(sourceSteps) do
		result[stepIndex] = {
			Step = stepIndex,
			Value = stepData.Value or 0,
			Role = stepData.Role or "Defender",
			AllowedActions = table.clone(stepData.AllowedActions or {}),
		}
	end
	return result
end

local function ResolveEnemyStageName(roundId, roundIndex)
	local normalizedRoundId = tostring(roundId or "")
	if normalizedRoundId == "RoundOf16" then
		return "Stage1"
	elseif normalizedRoundId == "QuarterFinal" then
		return "Stage2"
	elseif normalizedRoundId == "SemiFinal" then
		return "Stage3"
	elseif normalizedRoundId == "Final" then
		return "Stage4"
	end

	local numericRoundIndex = tonumber(roundIndex)
	if numericRoundIndex then
		return string.format("Stage%d", math.clamp(numericRoundIndex, 1, 4))
	end

	return "Stage1"
end

local function SelectEnemyTeamFolderName(seed)
	local rng = Random.new(tonumber(seed) or 0)
	return string.format("Team%02d", rng:NextInteger(1, 15))
end

local function BuildDefaultIntroData()
	local source = MatchIntroConfig.DefaultIntroData or {}

	return {
		HomeTeamName = tostring(source.HomeTeamName or "FC Rivrs"),
		AwayTeamName = tostring(source.AwayTeamName or "FC Roblox"),
		HomeScore = tonumber(source.HomeScore) or 1,
		AwayScore = tonumber(source.AwayScore) or 1,
		MatchMinute = tonumber(source.MatchMinute) or 86,
		LeagueName = tostring(source.LeagueName or "Youth League"),
		RoundName = tostring(source.RoundName or "Final Attack"),
		HomeLogo = tostring(source.HomeLogo or ""),
		AwayLogo = tostring(source.AwayLogo or ""),
	}
end

local function BuildTournamentIntroData(tournamentContext)
	local introData = BuildDefaultIntroData()
	local tournamentIntro = tournamentContext and tournamentContext.Intro

	if typeof(tournamentIntro) == "table" then
		introData.HomeTeamName = tostring(tournamentIntro.HomeTeamName or introData.HomeTeamName)
		introData.AwayTeamName = tostring(tournamentIntro.AwayTeamName or introData.AwayTeamName)
		introData.HomeScore = tonumber(tournamentIntro.HomeScore) or introData.HomeScore
		introData.AwayScore = tonumber(tournamentIntro.AwayScore) or introData.AwayScore
		introData.MatchMinute = tonumber(tournamentIntro.MatchMinute) or introData.MatchMinute
		introData.LeagueName = tostring(tournamentIntro.LeagueName or introData.LeagueName)
		introData.RoundName = tostring(tournamentIntro.RoundName or introData.RoundName)
		introData.HomeLogo = tostring(tournamentIntro.HomeLogo or introData.HomeLogo or "")
		introData.AwayLogo = tostring(tournamentIntro.AwayLogo or introData.AwayLogo or "")
		introData.RewardPreview = tournamentIntro.RewardPreview
		introData.RewardWins = tonumber(tournamentIntro.RewardWins)
		introData.RewardPerGoalWins = tonumber(tournamentIntro.RewardPerGoalWins)
		introData.RequiredPlayerGoals = tonumber(tournamentIntro.RequiredPlayerGoals)
		introData.RewardText = tournamentIntro.RewardText
	end

	-- Multi-leg: aggregate scores are now set by TournamentQuery.BuildMatchContext
	-- and passed through the Intro table. No need for old DrawScores randomization.
	-- Only fall back to CurrentScore / DrawScores for legacy non-aggregate matches.
	local hasAggregate = tournamentContext and tournamentContext.AggregatePlayer ~= nil
	if not hasAggregate then
		-- Keep bracket and intro scores on one server-side source of truth.
		local currentScore = tournamentContext and tournamentContext.CurrentScore
		if typeof(currentScore) == "table" then
			introData.HomeScore = tonumber(currentScore.Home) or introData.HomeScore
			introData.AwayScore = tonumber(currentScore.Away) or introData.AwayScore
		end

		-- Legacy: randomize initial gameplay score for non-aggregate matches
		if tournamentContext and introData.HomeScore == 0 and introData.AwayScore == 0 then
			local drawScores = TournamentConfig.LiveMatch.DrawScores
			if drawScores and #drawScores > 0 then
				local seedValue = math.floor(os.clock() * 1000)
				local index = (seedValue % #drawScores) + 1
				local score = drawScores[index]
				introData.HomeScore = score.Home or 0
				introData.AwayScore = score.Away or 0
			end
		end
	end

	if tournamentContext then
		introData.RewardPreview = introData.RewardPreview or tournamentContext.RewardPreview
		introData.RewardWins = tonumber(introData.RewardWins) or tonumber(tournamentContext.RewardWins)
		introData.RewardPerGoalWins = tonumber(introData.RewardPerGoalWins) or tonumber(tournamentContext.RewardPerGoalWins)
		introData.RequiredPlayerGoals = tonumber(introData.RequiredPlayerGoals) or tonumber(tournamentContext.RequiredPlayerGoals)
		introData.RewardText = introData.RewardText or tournamentContext.RewardText
	end

	return introData
end

local function SelectZoneVariationId()
	local variationIds = MatchSceneQuery.GetAvailableZoneVariationIds and MatchSceneQuery.GetAvailableZoneVariationIds() or {}
	if #variationIds == 0 then
		return nil
	end

	local index = ((nextZoneVariationIndex - 1) % #variationIds) + 1
	nextZoneVariationIndex += 1
	return variationIds[index]
end

local function GetCharacterPivot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:GetPivot()
end

local function SafeRequestStreamAround(player, position)
	if not Workspace.StreamingEnabled then
		return
	end
	pcall(function()
		player:RequestStreamAroundAsync(position)
	end)
end

local function GetPlayerFromTouchedPart(hit)
	if not hit then
		return nil
	end

	local current = hit
	while current and current ~= Workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)
			if player then
				return player
			end
		end

		current = current.Parent
	end

	return nil
end

local function GetTouchPartFromPrompt(prompt)
	if not prompt then
		return nil
	end

	local parent = prompt.Parent
	while parent and parent ~= Workspace do
		if parent:IsA("BasePart") then
			return parent
		end

		parent = parent.Parent
	end

	return nil
end

local function ShouldRegisterAutoBattleTouchPart(instance)
	if not instance or not instance:IsA("BasePart") then
		return false
	end

	if
		instance:GetAttribute("MatchBattleTrigger") == true
		or instance:GetAttribute("BattleGate") == true
		or instance:GetAttribute("AutoStartMatch") == true
	then
		return true
	end

	if AUTO_BATTLE_TOUCH_PART_NAMES[instance.Name] == true then
		return true
	end

	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("ProximityPrompt") then
			return true
		end
	end

	return false
end

local function IsBattleReturnPoint(instance)
	if not instance or not instance:IsA("BasePart") then
		return false
	end

	if BATTLE_RETURN_POINT_NAMES[instance.Name] == true then
		return true
	end

	for attributeName in pairs(BATTLE_RETURN_POINT_ATTRIBUTES) do
		if instance:GetAttribute(attributeName) == true then
			return true
		end
	end

	return false
end

local function FindBattleReturnPointInRoot(root)
	if not root then
		return nil
	end

	for _, child in ipairs(root:GetChildren()) do
		if IsBattleReturnPoint(child) then
			return child
		end
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if IsBattleReturnPoint(descendant) then
			return descendant
		end
	end

	return nil
end

local function ResolveBattleReturnCFrame(source)
	local battleZoneRoot = MatchWorldService and MatchWorldService:GetBattleZoneRoot() or nil
	local visited = {}
	local roots = {}

	local function AddRoot(root)
		if root and not visited[root] then
			visited[root] = true
			table.insert(roots, root)
		end
	end

	local current = source and source.Parent or nil
	while current and current ~= Workspace do
		AddRoot(current)
		if current == battleZoneRoot then
			break
		end
		current = current.Parent
	end

	AddRoot(battleZoneRoot)

	for _, root in ipairs(roots) do
		local returnPoint = FindBattleReturnPointInRoot(root)
		if returnPoint then
			return returnPoint.CFrame, returnPoint:GetFullName()
		end
	end

	return nil, nil
end

local function ResolveCharacterTeleportCFrame(player, targetCFrame)
	if not targetCFrame then
		return nil
	end

	local character = player and player.Character
	if not character then
		return targetCFrame + MatchConstants.TELEPORT_OFFSET
	end

	return MatchGrounding.GetGroundedCharacterRootCFrame(character, targetCFrame, {
		IgnoreMatchRuntimeRoot = true,
		FallbackY = targetCFrame.Position.Y + MatchConstants.TELEPORT_OFFSET.Y,
	})
end

local function GetExpectedTeleportPosition(player, targetCFrame)
	local resolvedCFrame = ResolveCharacterTeleportCFrame(player, targetCFrame)
	return resolvedCFrame and resolvedCFrame.Position or nil
end

local function StopCharacterAnimationTracks(character)
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		pcall(function()
			track:AdjustSpeed(1)
			track:Stop(0)
		end)
	end
end

local function RestoreCharacterServerState(player, options)
	local character = player and player.Character
	if not character then
		return false
	end

	options = options or {}
	if options.StopAnimations == true then
		StopCharacterAnimationTracks(character)
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			pcall(function()
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true
		pcall(function()
			humanoid:Move(Vector3.zero, false)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	return rootPart ~= nil
end

local function SetCharacterRootLocked(player, locked: boolean)
	local character = player and player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = not locked
		pcall(function()
			humanoid:Move(Vector3.zero, false)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	rootPart.Anchored = locked == true
	pcall(function()
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end)

	return true
end

local function ResolveChampionCeremonyCFrame(player)
	local ceremonyCFrame = nil

	if MatchWorldService and MatchWorldService.GetPlayerSpawnCFrame then
		local ok, result = pcall(function()
			return MatchWorldService:GetPlayerSpawnCFrame()
		end)

		if ok and typeof(result) == "CFrame" then
			ceremonyCFrame = result
		end
	end

	return ceremonyCFrame or GetCharacterPivot(player)
end

local function BuildReturnAttendance(player, targetCFrame, returned, reason)
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local distance = nil

	local expectedPosition = GetExpectedTeleportPosition(player, targetCFrame)
	if rootPart and expectedPosition then
		distance = (rootPart.Position - expectedPosition).Magnitude
	end

	return {
		Reason = reason or "Unknown",
		Returned = returned == true,
		CharacterExists = character ~= nil,
		RootExists = rootPart ~= nil,
		HumanoidExists = humanoid ~= nil,
		RootAnchored = rootPart and rootPart.Anchored == true or false,
		DistanceToOrigin = distance,
		Position = rootPart and rootPart.Position or nil,
	}
end

local function TeleportCharacterToCFrame(player, targetCFrame, options)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end

	options = options or {}
	local finalCFrame = ResolveCharacterTeleportCFrame(player, targetCFrame)
	if not finalCFrame then
		return false
	end

	RestoreCharacterServerState(player, { StopAnimations = options.StopAnimations == true })

	rootPart.Anchored = true
	pcall(function()
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end)

	-- Keep this intentionally similar to the stable training teleport style:
	-- snap the HumanoidRootPart directly, then pivot the whole character, then snap
	-- the root again. This avoids delayed character drift after match cleanup.
	rootPart.CFrame = finalCFrame
	character:PivotTo(finalCFrame)
	rootPart.CFrame = finalCFrame
	SafeRequestStreamAround(player, targetCFrame.Position)
	task.wait(MatchConstants.POST_TELEPORT_DELAY)
	rootPart.CFrame = finalCFrame

	RestoreCharacterServerState(player, { StopAnimations = options.StopAnimations == true })
	if options.KeepRootLocked == true then
		SetCharacterRootLocked(player, true)
	else
		rootPart.Anchored = false
	end
	return true, finalCFrame
end

local function ReturnCharacterToOrigin(player, targetCFrame)
	if not targetCFrame then
		return false
	end

	SafeRequestStreamAround(player, targetCFrame.Position)

	local ok = TeleportCharacterToCFrame(player, targetCFrame, { StopAnimations = true })
	if not ok then
		task.wait(0.1)
		ok = TeleportCharacterToCFrame(player, targetCFrame, { StopAnimations = true })
	end

	if ok then
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local expectedPosition = GetExpectedTeleportPosition(player, targetCFrame)
		if
			rootPart
			and expectedPosition
			and (rootPart.Position - expectedPosition).Magnitude > RETURN_ATTENDANCE_DISTANCE_TOLERANCE
		then
			task.wait(0.08)
			TeleportCharacterToCFrame(player, targetCFrame, { StopAnimations = true })
		end
	end

	return ok
end

local function ForceCharacterReturn(player, targetCFrame)
	if not targetCFrame then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end

	RestoreCharacterServerState(player, { StopAnimations = true })

	local finalCFrame = ResolveCharacterTeleportCFrame(player, targetCFrame)
	if not finalCFrame then
		return false
	end

	rootPart.Anchored = true
	pcall(function()
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end)
	rootPart.CFrame = finalCFrame
	character:PivotTo(finalCFrame)
	task.wait()
	rootPart.CFrame = finalCFrame
	character:PivotTo(finalCFrame)
	rootPart.CFrame = finalCFrame
	rootPart.Anchored = false

	RestoreCharacterServerState(player, { StopAnimations = true })

	return true
end

local AUTO_RETURN_MAX_RETRIES = 4
local AUTO_RETURN_RETRY_DELAY = 0.20
local AUTO_RETURN_DISTANCE_TOLERANCE = 3.25

local FAILED_STEP_FINISH_DELAY = 0.75
-- How long after defeatRestartLocks is SET do we wait before teleporting.
-- Safe to be long because the lock is stamped BEFORE this delay fires,
-- so _tryStartMatch cannot re-enter during the hold window.
local DEFEAT_UI_HOLD_DELAY = 3.2
local PRE_QTE_APPROACH_DURATION = 1.20
local PRE_QTE_PAUSE = 1.25

local PRE_QTE_ACK_FALLBACK_BUFFER = 0.40
local POST_ACTION_ACK_FALLBACK_BUFFER = 0.35
local POST_ACTION_QTE_PAUSE = 0.50

local PRESENTATION_WATCHDOG_FORCE_RELEASE = true
local PRE_QTE_ACK_MAX_WAIT = 8.00
local POST_ACTION_ACK_MAX_WAIT = 10.00
local SHOOT_POST_ACTION_ACK_MAX_WAIT = 14.00

local FINAL_SHOT_FINISH_DELAY = 2.00

local DRIBBLE_PRESENTATION_DELAY_SUCCESS = 1.18
local DRIBBLE_PRESENTATION_DELAY_FAIL = 0.58

local PASS_PRESENTATION_DELAY_SUCCESS = 1.12
local PASS_PRESENTATION_DELAY_FAIL = 0.62

local SHOOT_PRESENTATION_DELAY_SUCCESS = 0.95
local SHOOT_PRESENTATION_DELAY_FAIL = 0.82

local function GetPresentationDelayForAction(actionName, succeeded)
	if actionName == "Dribble" then
		return succeeded and DRIBBLE_PRESENTATION_DELAY_SUCCESS or DRIBBLE_PRESENTATION_DELAY_FAIL
	end

	if actionName == "Pass" then
		return succeeded and PASS_PRESENTATION_DELAY_SUCCESS or PASS_PRESENTATION_DELAY_FAIL
	end

	if actionName == "Shoot" then
		return succeeded and SHOOT_PRESENTATION_DELAY_SUCCESS or SHOOT_PRESENTATION_DELAY_FAIL
	end

	return 0.80
end

local function GetPostActionFallbackDelay(resultPayload)
	local actionName = resultPayload and resultPayload.Action or ""
	local succeeded = resultPayload and resultPayload.Succeeded == true

	local baseDelay = GetPresentationDelayForAction(actionName, succeeded)
	local extraDelay = POST_ACTION_QTE_PAUSE + POST_ACTION_ACK_FALLBACK_BUFFER

	if actionName == "Dribble" then
		extraDelay += 0.35
	elseif actionName == "Pass" then
		extraDelay += 0.30
	elseif actionName == "Shoot" then
		extraDelay += 0.55
	else
		extraDelay += 0.25
	end

	return baseDelay + extraDelay
end

local function IsCharacterNearCFrame(player, targetCFrame, tolerance)
	if not targetCFrame then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end

	local expectedPosition = GetExpectedTeleportPosition(player, targetCFrame)
	if not expectedPosition then
		return false
	end

	return (rootPart.Position - expectedPosition).Magnitude <= (tolerance or AUTO_RETURN_DISTANCE_TOLERANCE)
end

local function BuildRandomCompanionPivotOrder(seed)
	return { 2, 3, 4 }
end

local function IsLegContinuationPayload(payload)
	local tournament = payload and payload.Tournament
	local currentLeg = tournament and tonumber(tournament.CurrentLeg)
	return currentLeg ~= nil and currentLeg > 1
end

--| Client Functions |--
function MatchService.Client:StartFtueMatch(player, options)
	return MatchService:StartFtueMatch(player, options)
end

function MatchService.Client:NotifyMatchIntroCompleted(player, sessionId)
	return MatchService:NotifyMatchIntroCompleted(player, sessionId)
end

function MatchService.Client:NotifyPresentationReady(player, sessionId, stepIndex, phase)
	return MatchService:NotifyPresentationReady(player, sessionId, stepIndex, phase)
end

function MatchService.Client:ConfirmTransitionReady(player, sessionId)
	return MatchService:ConfirmTransitionReady(player, sessionId)
end

function MatchService.Client:RequestLeaveMatch(player, reason)
	return MatchService:RequestLeaveMatch(player, reason)
end

function MatchService.Client:SubmitQteResult(player, qtePayload)
	return MatchService:SubmitQteResult(player, qtePayload)
end

function MatchService.Client:RequestFinishChampionCeremony(player, sessionId)
	return MatchService:RequestFinishChampionCeremony(player, sessionId)
end

function MatchService.Client:NotifyGoalCinematicClimax(player, sessionId)
	return MatchService:NotifyGoalCinematicClimax(player, sessionId)
end

--| Server Functions |--

function MatchService:CancelPendingTournamentStart(player, options)
	options = options or {}
	local source = pendingTournamentSources[player]
	pendingTournamentSources[player] = nil

	-- Hapus pending transition agar IsPlayerTransitioning() kembali false
	-- dan player bisa start ulang setelah cancel.
	pendingTransitions[player] = nil

	-- Set debounce ke waktu sekarang (bukan nil) agar BattleGate auto-scanner
	-- tidak langsung re-trigger saat player baru di-return ke dekat gate.
	touchDebounces[player] = os.clock()

	if TournamentService and TournamentService.SetPendingStart then
		TournamentService:SetPendingStart(player, false)
	end

	if options.TeleportToReturnPoint == true then
		local returnCFrame = nil
		returnCFrame = ResolveBattleReturnCFrame(source)

		if returnCFrame then
			ReturnCharacterToOrigin(player, returnCFrame)
		else
			RestoreCharacterServerState(player, { StopAnimations = true })
			warn("[MatchReturn][TournamentClose] BattleReturnPoint not found; pending start cleared only.")
		end
	else
		RestoreCharacterServerState(player, { StopAnimations = true })
	end

	return true
end

function MatchService:IsPlayerInMatch(player)
	return activeSessions[player] ~= nil
end

function MatchService:IsPlayerTransitioning(player)
	return pendingTransitions[player] ~= nil
end

function MatchService:_getActiveSession(player)
	return activeSessions[player]
end

function MatchService:_cancelSessionQte(session)
	if not session then
		return
	end

	session.AwaitingQte = false
	session.CurrentStepData = nil
	session.QteToken = (session.QteToken or 0) + 1

	self:_clearPendingPresentation(session)
end

function MatchService:BuildSessionPayload(player)
	local playerData = DataService:GetData(player)
	if not playerData then
		return nil, "Player data is not ready yet."
	end

	local areaId = GetPlayerAreaId(playerData)
	local config = MatchAreaConfig[areaId] or MatchAreaConfig[MatchConstants.DEFAULT_AREA_ID]
	local seed = math.floor(os.clock() * 1000) + player.UserId
	local zoneVariationId = SelectZoneVariationId()

	local tournamentContext = nil
	if TournamentService and TournamentService.GetCurrentMatchContext then
		local ok, result = pcall(function()
			return TournamentService:GetCurrentMatchContext(player, areaId)
		end)

		if ok then
			tournamentContext = result
		else
			warn("[MatchService] Failed to build tournament context:", result)
		end
	end

	local roundId = tournamentContext and tournamentContext.RoundId or "RoundOf16"
	local roundIndex = tournamentContext and tournamentContext.RoundIndex or nil
	local enemyStageName = ResolveEnemyStageName(roundId, roundIndex)
	-- Bug fix: use a round-stable seed so the enemy team stays the same for the
	-- entire round (all legs). Only changes when RoundIndex advances.
	-- Previously used the time-based `seed` which caused enemy re-gacha every leg.
	local roundStableSeed = player.UserId + ((tonumber(roundIndex) or 1) * 31337)
	local enemyTeamFolderName = SelectEnemyTeamFolderName(roundStableSeed)

	local roster = MatchRosterBuilder.Build(player, playerData, SoccerCharactersTemplate)
	local sequence = MatchSequenceBuilder.Build(seed, roster)

	local payload = {
		SessionId = string.format("%d_%d", player.UserId, os.time()),
		AreaId = areaId,
		Seed = seed,
		EnemySteps = CloneEnemySteps(areaId, roundId),
		EnemyStageName = enemyStageName,
		EnemyTeamFolderName = enemyTeamFolderName,
		Stats = GetPlayerStats(playerData),
		Roster = roster,
		Sequence = sequence,
		Config = config,
		Tournament = tournamentContext,
		CompanionPivotOrder = BuildRandomCompanionPivotOrder(seed),
		ZoneVariationId = zoneVariationId,
		CurrentGoals = tonumber(playerData.Goals) or 0,
		CurrentWins = tonumber(playerData.Wins) or 0,
		IntroData = BuildTournamentIntroData(tournamentContext),
	}

	return payload, nil
end

function MatchService:_buildStepStartedPayload(session, stepData)
	local enemyData = session.Payload.EnemySteps[stepData.EnemyStep]
	local actorEntry = session.Payload.Roster and session.Payload.Roster[stepData.FromSlot]
	local targetEntry = session.Payload.Roster and session.Payload.Roster[stepData.ToSlot]
	local previewValue = MatchResolution.GetPreviewValue(session.Payload, stepData)

	return {
		SessionId = session.SessionId,
		StepIndex = stepData.Step,
		TotalSteps = #session.Payload.Sequence,
		Action = stepData.Action,
		ActorSlot = stepData.FromSlot,
		ActorDisplayName = actorEntry and actorEntry.DisplayName or "Player",
		TargetSlot = stepData.ToSlot,
		TargetDisplayName = targetEntry and targetEntry.DisplayName or nil,
		EnemyStep = stepData.EnemyStep,
		EnemyValue = enemyData and enemyData.Value or 0,
		EnemyRole = enemyData and enemyData.Role or "Defender",
		PreviewValue = previewValue,
		Timeout = MatchConstants.QTE_RESPONSE_TIMEOUT,
		ApproachDuration = PRE_QTE_APPROACH_DURATION,
		PreQtePause = PRE_QTE_PAUSE,
		PassMode = stepData.PassMode,
		Player2Branch = stepData.Player2Branch == true,
		AutoSkipped = stepData.AutoSkipped == true,
		SkipReason = stepData.SkipReason,
	}
end

function MatchService:_beginNextStep(player)
	local session = self:_getActiveSession(player)
	if not session or self:IsPlayerTransitioning(player) or session.IsFinishing then
		return
	end

	local nextIndex = (session.CurrentStepIndex or 0) + 1
	local stepData = session.Payload.Sequence[nextIndex]
	if not stepData then
		return
	end

	if session.SkipQte3AfterStep2 == true then
		MatchFlowRules.SyncUpcomingStepOwner(session.Payload.Sequence, nextIndex, session.CurrentBallOwnerSlot)
	end

	session.CurrentStepIndex = nextIndex
	session.CurrentStepData = stepData
	session.AwaitingQte = false
	session.QteToken = (session.QteToken or 0) + 1

	local qteToken = session.QteToken
	local stepPayload = self:_buildStepStartedPayload(session, stepData)

	session.PendingPresentationPhase = "PreQte"
	session.PendingPresentationStepIndex = stepData.Step
	session.PendingPresentationToken = (session.PendingPresentationToken or 0) + 1
	session.PendingStepPayload = stepPayload
	session.PendingQteToken = qteToken

	local presentationToken = session.PendingPresentationToken

	self.Client.MatchApproachStarted:Fire(player, stepPayload)

	-- Normal flow must wait for client ack via NotifyPresentationReady(..., "PreQte").
	-- This watchdog exists only to recover from deadlock / missing ack.
	self:_armPresentationWatchdog(player, session, "PreQte", stepData.Step, presentationToken, PRE_QTE_ACK_MAX_WAIT)
end

-- c:\Users\akama\wkspaces\RIVRS Indonesia-MySoccerTeam\Environments\Development\src\server\Services\MatchService.luau

function MatchService:_calculateMatchRewardPreview(player, session)
	local payload = session and session.Payload or {}
	local tournamentContext = payload.Tournament or {}
	local successfulSteps = session and session.SuccessfulQteSteps or {}

	local data = player and DataService:GetData(player)
	local gamepasses = data and type(data.Gamepasses) == "table" and data.Gamepasses or {}
	
	local hasVip = false
	local hasDoubleWins = false
	for _, v in pairs(gamepasses) do
		if v == "VIP" then hasVip = true end
		if v == "x2 Wins" then hasDoubleWins = true end
	end

	if not hasDoubleWins and data and data.Inventory and type(data.Inventory.ActiveBoosts) == "table" then
		for _, item in pairs(data.Inventory.ActiveBoosts) do
			local itemName = (typeof(item) == "table" and item.Name) or item
			if itemName == "x2 Wins Boost" then
				hasDoubleWins = true
				break
			end
		end
	end

	local rewardWins = TournamentRewardCalculator.CalculateTotalReward({
		AreaId = tournamentContext.AreaId or payload.AreaId,
		LeagueKey = tournamentContext.LeagueKey or tournamentContext.LeagueId,
		RoundId = tournamentContext.RoundId,
		RoundIndex = tournamentContext.RoundIndex,
		RequiredPlayerGoals = tournamentContext.RequiredPlayerGoals,
		SuccessfulQteSteps = successfulSteps,
		HasDoubleWins = hasDoubleWins,
		HasVipBattlePass = hasVip,
	})

	return math.max(0, math.floor(tonumber(rewardWins) or 0))
end

function MatchService:_calculateGoalReward(player, session)
	local payload = session and session.Payload or {}
	local tournamentContext = payload.Tournament or {}
	local successfulSteps = session and session.SuccessfulQteSteps or {}

	local data = player and DataService:GetData(player)
	local gamepasses = data and type(data.Gamepasses) == "table" and data.Gamepasses or {}
	
	local hasVip = false
	local hasDoubleWins = false
	for _, v in pairs(gamepasses) do
		if v == "VIP" then hasVip = true end
		if v == "x2 Wins" then hasDoubleWins = true end
	end

	if not hasDoubleWins and data and data.Inventory and type(data.Inventory.ActiveBoosts) == "table" then
		for _, item in pairs(data.Inventory.ActiveBoosts) do
			local itemName = (typeof(item) == "table" and item.Name) or item
			if itemName == "x2 Wins Boost" then
				hasDoubleWins = true
				break
			end
		end
	end

	local rewardWins = TournamentRewardCalculator.CalculatePerGoalReward({
		AreaId = tournamentContext.AreaId or payload.AreaId,
		LeagueKey = tournamentContext.LeagueKey or tournamentContext.LeagueId,
		RoundId = tournamentContext.RoundId,
		RoundIndex = tournamentContext.RoundIndex,
		RequiredPlayerGoals = tournamentContext.RequiredPlayerGoals,
		SuccessfulQteSteps = successfulSteps,
		HasDoubleWins = hasDoubleWins,
		HasVipBattlePass = hasVip,
	})

	print(`[MatchService DEBUG] _calculateGoalReward -> hasVip: {hasVip}, hasDoubleWins: {hasDoubleWins}, rewardWins: {rewardWins}`)
	return math.max(0, math.floor(tonumber(rewardWins) or 0))
end

function MatchService:_usesPerGoalTournamentReward(session): boolean
	local tournamentContext = session and session.Payload and session.Payload.Tournament
	return type(tournamentContext) == "table" and tonumber(tournamentContext.RequiredPlayerGoals) ~= nil
end

function MatchService:_awardStepProgress(player, session, resultPayload)
	resultPayload.AwardedWins = 0
	resultPayload.AwardedGoals = 0

	if not resultPayload.Succeeded then
		return
	end

	session.SuccessfulQteSteps = session.SuccessfulQteSteps or {}
	local stepIndex = tonumber(resultPayload.StepIndex or resultPayload.Step or session.CurrentStepIndex)
	if stepIndex then
		session.SuccessfulQteSteps[stepIndex] = true
	end

	-- Wins and Goals are granted only when the successful action is the final Shoot.
	-- Tournament Wins are paid per goal, using the round target as the divisor.
	if resultPayload.Action == "Shoot" then
		local payload = session and session.Payload or {}
		local actorSlot = tonumber(resultPayload.ActorSlot)
		local actorEntry = actorSlot and payload.Roster and payload.Roster[actorSlot] or nil
		local introData = payload.IntroData

		resultPayload.AreaId = payload.AreaId
		resultPayload.ScorerDisplayName = tostring(resultPayload.ActorDisplayName or (actorEntry and actorEntry.DisplayName) or player.Name)
		resultPayload.ScorerActorType = actorEntry and actorEntry.ActorType or nil
		resultPayload.MatchStartMinute = introData and tonumber(introData.MatchMinute) or nil
		resultPayload.MatchRewardPreviewWins = self:_calculateMatchRewardPreview(player, session)
		local goalRewardWins = if self:_usesPerGoalTournamentReward(session) then self:_calculateGoalReward(player, session) else 0
		resultPayload.GoalRewardWins = goalRewardWins

		resultPayload.AwardedWins = goalRewardWins
		session.AwardedWins = (session.AwardedWins or 0) + goalRewardWins

		resultPayload.AwardedGoals = 1
		session.MatchGoals = (session.MatchGoals or 0) + 1

		session.PendingGoalRewardWins = (session.PendingGoalRewardWins or 0) + goalRewardWins
		session.PendingGoalRewardGoals = (session.PendingGoalRewardGoals or 0) + 1
	end
end

function MatchService:_grantPendingGoalReward(player, session)
	if not session then return end
	
	local winsToGrant = session.PendingGoalRewardWins or 0
	local goalsToGrant = session.PendingGoalRewardGoals or 0
	
	session.PendingGoalRewardWins = 0
	session.PendingGoalRewardGoals = 0

	if winsToGrant > 0 then
		local successWins = pcall(function()
			return DataService:ChangeValue(player, "Wins", winsToGrant, true)
		end)
		print(`[MatchService] Granting {winsToGrant} Wins for Goal!`)
		if not successWins then
			warn("[MatchService] Failed to grant pending goal reward Wins=" .. tostring(winsToGrant))
		end
	end

	if goalsToGrant > 0 then
		local successGoals, err = pcall(function()
			return DataService:ChangeValue(player, "Goals", goalsToGrant, true)
		end)
		if not successGoals then
			warn("[MatchService] ChangeValue for pending Goals failed:", err)
		end
	end
end

function MatchService:_grantMatchReward(player, session, reason)
	if not session or session.RewardGranted == true then
		return 0
	end

	if self:_usesPerGoalTournamentReward(session) then
		session.RewardGranted = true
		return math.max(0, math.floor(tonumber(session.AwardedWins) or 0))
	end

	session.RewardGranted = true

	local rewardWins = self:_calculateMatchRewardPreview(session)
	session.AwardedWins = rewardWins

	if rewardWins <= 0 then
		return 0
	end

	print(`[MatchService] Granting {rewardWins} Wins for Match Completion!`)
	local successWins = pcall(function()
		return DataService:ChangeValue(player, "Wins", rewardWins, false)
	end)

	if not successWins then
		warn(
			string.format(
				"[MatchService] Failed to grant tournament reward Wins=%d player=%s reason=%s",
				rewardWins,
				player and player.Name or "nil",
				tostring(reason)
			)
		)
		return 0
	end

	return rewardWins
end

function MatchService:_openTournamentContinuationPreview(player, session)
	if not player or not session then
		return
	end

	if session.OriginalCFrame then
		tournamentContinuationReturnCFrames[player] = session.OriginalCFrame
	end

	tournamentContinuationReturnSources[player] = session.ReturnTargetSource
	pendingTournamentSources[player] = nil

	if TournamentService and TournamentService.OpenContinuationPreview then
		local ok, err = pcall(function()
			TournamentService:OpenContinuationPreview(player)
		end)

		if not ok then
			warn("[MatchService] Failed to open tournament continuation preview:", err)
		end
	end
end

function MatchService:_completeVictoryForTournamentContinuation(player, session)
	local liveSession = activeSessions[player]
	if liveSession ~= session then
		return
	end

	self:_cancelSessionQte(session)
	RestoreCharacterServerState(player, { StopAnimations = true })

	touchDebounces[player] = nil
	player:SetAttribute("IsInMatch", false)
	activeSessions[player] = nil
	pendingTransitions[player] = nil

	-- End the current match presentation without physically returning to the
	-- lobby gate. The next Start button uses the stored lobby return CFrame.
	self.Client.MatchSessionEnded:Fire(player, "VictoryContinuation", session.SessionId)

	task.delay(0.35, function()
		if activeSessions[player] or pendingTransitions[player] then
			return
		end

		self:_openTournamentContinuationPreview(player, session)
	end)
end

-- Multi-leg: seamless continuation to next leg within the same round.
-- Skips bracket preview and directly starts the next match.
function MatchService:_completeVictoryForLegContinuation(player, session)
	local liveSession = activeSessions[player]
	if liveSession ~= session then
		return
	end

	self:_cancelSessionQte(session)
	RestoreCharacterServerState(player, { StopAnimations = true })

	-- Store return CFrame for post-tournament return
	if session.OriginalCFrame then
		tournamentContinuationReturnCFrames[player] = session.OriginalCFrame
	end
	tournamentContinuationReturnSources[player] = session.ReturnTargetSource

	-- Race-condition fix: stamp debounce (NOT nil) so the auto-battle-zone scanner
	-- cannot trigger _requestTournamentPreview in the ~0.50s window between leg N
	-- ending (activeSessions=nil) and leg N+1 starting programmatically.
	touchDebounces[player] = os.clock()
	player:SetAttribute("IsInMatch", false)
	activeSessions[player] = nil
	pendingTransitions[player] = nil

	-- Generate a unique token for this leg transition.
	-- The task.delay callback checks this token before starting the next match.
	-- If the player loses and _completeSessionNow runs first, it clears the token
	-- so this delayed callback becomes a no-op.
	local continuationToken = (legContinuationTokens[player] or 0) + 1
	legContinuationTokens[player] = continuationToken

	-- Signal client that this is a leg continuation (no bracket preview)
	self.Client.MatchSessionEnded:Fire(player, "LegContinuation", session.SessionId)

	-- Auto-start the next leg after a short delay
	task.delay(0.50, function()
		-- Token check: if cleared by defeat/exit, do NOT start the next match.
		if legContinuationTokens[player] ~= continuationToken then
			return
		end
		legContinuationTokens[player] = nil

		if activeSessions[player] or pendingTransitions[player] then
			return
		end

		-- Set pending start so _tryStartMatch can proceed
		if TournamentService and TournamentService.SetPendingStart then
			TournamentService:SetPendingStart(player, true)
		end

		-- Directly start the next match (same as StartConfirmedTournamentMatch but inline)
		local returnCFrameOverride = tournamentContinuationReturnCFrames[player]
		local returnTargetSourceOverride = tournamentContinuationReturnSources[player]
		tournamentContinuationReturnCFrames[player] = nil
		tournamentContinuationReturnSources[player] = nil

		if TournamentService and TournamentService.SetPendingStart then
			TournamentService:SetPendingStart(player, false)
		end

		self:_tryStartMatch(player, nil, {
			SilentBusy = false,
			FromTournament = true,
			ReturnCFrameOverride = returnCFrameOverride,
			ReturnTargetSourceOverride = returnTargetSourceOverride,
		})
	end)
end

function MatchService:RequestFinishChampionCeremony(player, sessionId)
	return self:_finishChampionCeremony(player, sessionId, "Skip")
end

function MatchService:_completeVictoryForTournamentChampion(player, session)
	local liveSession = activeSessions[player]
	if liveSession ~= session then
		return
	end

	self:_cancelSessionQte(session)
	RestoreCharacterServerState(player, { StopAnimations = true })

	local ceremonyCFrame = ResolveChampionCeremonyCFrame(player)
	local fallbackReturnCFrame = nil
	if not session.OriginalCFrame then
		fallbackReturnCFrame = select(1, ResolveBattleReturnCFrame(session.ReturnTargetSource))
	end
	local record = {
		SessionId = session.SessionId,
		Session = session,
		ReturnCFrame = session.OriginalCFrame or fallbackReturnCFrame or GetCharacterPivot(player),
		Finished = false,
	}

	activeChampionCeremonies[player] = record
	tournamentContinuationReturnCFrames[player] = nil
	tournamentContinuationReturnSources[player] = nil
	pendingTournamentSources[player] = nil
	touchDebounces[player] = nil
	player:SetAttribute("IsInMatch", false)
	activeSessions[player] = nil
	pendingTransitions[player] = nil

	-- Final win is not a bracket continuation. End battle presentation in-place,
	-- clear enemies, then run the championship ceremony before returning.
	self.Client.MatchSessionEnded:Fire(player, "ChampionCeremony", session.SessionId)

	task.delay(CHAMPION_CEREMONY_START_DELAY_SECONDS, function()
		local liveRecord = activeChampionCeremonies[player]
		if liveRecord ~= record or record.Finished == true or not player.Parent then
			return
		end

		if typeof(ceremonyCFrame) == "CFrame" then
			TeleportCharacterToCFrame(player, ceremonyCFrame, { StopAnimations = true })
			SetCharacterRootLocked(player, true)
		end

		self.Client.ChampionCeremonyStarted:Fire(player, {
			SessionId = session.SessionId,
			AreaId = session.Payload and session.Payload.AreaId or "Area01",
			DurationSeconds = CHAMPION_CEREMONY_DURATION_SECONDS,
			CeremonyCFrame = ceremonyCFrame,
			CupName = session.Payload and session.Payload.Tournament and session.Payload.Tournament.CupName
				or "Tournament Cup",
			Message = "CHAMPIONS!",
		})
	end)

	task.delay(CHAMPION_CEREMONY_START_DELAY_SECONDS + CHAMPION_CEREMONY_DURATION_SECONDS, function()
		self:_finishChampionCeremony(player, session.SessionId, "Auto")
	end)
end

function MatchService:_beginReturnOverlay(player, session, reason)
	if not player or not session then
		return
	end

	if session.ReturnOverlayStarted == true then
		return
	end

	session.ReturnOverlayStarted = true

	self.Client.MatchReturnStarted:Fire(player, {
		SessionId = session.SessionId,
		Reason = reason or "ManualExit",
	})

	task.wait(RETURN_CLIENT_FADE_LEAD_SECONDS)
end

function MatchService:_fireReturnAttendance(player, session, returned, reason)
	local origin = session and session.OriginalCFrame or nil
	local payload = BuildReturnAttendance(player, origin, returned, reason)
	if session then
		payload.SessionId = session.SessionId
	end

	self.Client.MatchReturnAttendance:Fire(player, payload)
end

function MatchService:_finishChampionCeremony(player, sessionId, finishReason)
	local record = activeChampionCeremonies[player]
	if not record then
		return false
	end

	if tostring(record.SessionId or "") ~= tostring(sessionId or "") then
		return false
	end

	if record.Finished == true then
		return false
	end

	record.Finished = true
	activeChampionCeremonies[player] = nil

	local session = record.Session or {
		SessionId = record.SessionId,
		OriginalCFrame = record.ReturnCFrame,
	}

	self:_beginReturnOverlay(player, session, "ChampionCeremony")
	RestoreCharacterServerState(player, { StopAnimations = true })
	SetCharacterRootLocked(player, false)

	local returned = true
	if typeof(record.ReturnCFrame) == "CFrame" then
		returned = false
		for attempt = 1, AUTO_RETURN_MAX_RETRIES do
			for _ = 1, 2 do
				returned = ReturnCharacterToOrigin(player, record.ReturnCFrame)
				if returned and IsCharacterNearCFrame(player, record.ReturnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE) then
					break
				end
				returned = false
				task.wait(0.08)
			end

			if
				not returned
				or not IsCharacterNearCFrame(player, record.ReturnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE + 4)
			then
				returned = ForceCharacterReturn(player, record.ReturnCFrame)
				if
					returned
					and not IsCharacterNearCFrame(player, record.ReturnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE + 4)
				then
					task.wait(0.05)
					returned = ForceCharacterReturn(player, record.ReturnCFrame)
				end
			end

			if returned and IsCharacterNearCFrame(player, record.ReturnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE + 4) then
				break
			end

			returned = false
			if attempt < AUTO_RETURN_MAX_RETRIES then
				task.wait(AUTO_RETURN_RETRY_DELAY * attempt)
			end
		end
	end

	RestoreCharacterServerState(player, { StopAnimations = true })
	SetCharacterRootLocked(player, false)
	self:_fireReturnAttendance(player, session, returned, "ChampionCeremony")
	self.Client.ChampionCeremonyEnded:Fire(player, {
		SessionId = record.SessionId,
		Returned = returned,
		Reason = "ChampionCeremony",
		FinishReason = finishReason or "Auto",
	})

	return true
end

function MatchService:_completeSessionNow(player, reason)
	local session = self:_getActiveSession(player)
	if not session then
		return
	end

	self:_cancelSessionQte(session)
	self:_beginReturnOverlay(player, session, reason)
	RestoreCharacterServerState(player, { StopAnimations = true })

	session.ReturnAttemptCount = (session.ReturnAttemptCount or 0) + 1
	local currentAttempt = session.ReturnAttemptCount
	local returned = false
	local returnCFrame = session.OriginalCFrame

	if typeof(returnCFrame) ~= "CFrame" then
		local fallbackReturnCFrame = ResolveBattleReturnCFrame(session.ReturnTargetSource)
		if typeof(fallbackReturnCFrame) == "CFrame" then
			returnCFrame = fallbackReturnCFrame
			session.OriginalCFrame = fallbackReturnCFrame
		else
			warn("[MatchService] Missing return CFrame; cannot auto-return player:", player.Name)
		end
	end

	if typeof(returnCFrame) == "CFrame" then
		for _ = 1, 2 do
			returned = ReturnCharacterToOrigin(player, returnCFrame)
			if returned and IsCharacterNearCFrame(player, returnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE) then
				break
			end
			returned = false
			task.wait(0.08)
		end

		if not returned then
			returned = ForceCharacterReturn(player, returnCFrame)
			if
				returned
				and not IsCharacterNearCFrame(player, returnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE + 4)
			then
				task.wait(0.05)
				returned = ForceCharacterReturn(player, returnCFrame)
			end
		end

		if
			returned and not IsCharacterNearCFrame(player, returnCFrame, AUTO_RETURN_DISTANCE_TOLERANCE + 4)
		then
			returned = false
		end
	end

	if returned then
		RestoreCharacterServerState(player, { StopAnimations = true })
		self:_fireReturnAttendance(player, session, true, reason or "ManualExit")
		-- Invalidate any pending leg-continuation so its task.delay becomes a no-op.
		legContinuationTokens[player] = nil
		-- Stamp debounce so scanner cannot re-trigger match immediately.
		touchDebounces[player] = os.clock()
		player:SetAttribute("IsInMatch", false)
		activeSessions[player] = nil
		pendingTransitions[player] = nil
		if reason == "Defeat" then
			defeatGateRearmRequired[player] = os.clock()
		end
		self.Client.MatchSessionEnded:Fire(player, reason or "ManualExit", session.SessionId)
		return
	end

	if currentAttempt < AUTO_RETURN_MAX_RETRIES then
		warn(
			string.format(
				"[MatchService] Auto return retry %d/%d for %s",
				currentAttempt,
				AUTO_RETURN_MAX_RETRIES,
				player.Name
			)
		)
		task.delay(AUTO_RETURN_RETRY_DELAY * currentAttempt, function()
			local liveSession = activeSessions[player]
			if liveSession == session and liveSession.IsFinishing then
				self:_completeSessionNow(player, reason)
			end
		end)
		return
	end

	warn("[MatchService] Auto return exhausted retries, forcing session end:", player.Name)
	RestoreCharacterServerState(player, { StopAnimations = true })
	self:_fireReturnAttendance(player, session, false, reason or "ManualExit")
	-- Invalidate any pending leg-continuation so its task.delay becomes a no-op.
	legContinuationTokens[player] = nil
	-- Bug 2B fix: same debounce stamp to block gate re-trigger on forced return.
	touchDebounces[player] = os.clock()
	player:SetAttribute("IsInMatch", false)
	activeSessions[player] = nil
	pendingTransitions[player] = nil
	if reason == "Defeat" then
		defeatGateRearmRequired[player] = os.clock()
	end
	self.Client.MatchSessionEnded:Fire(player, reason or "ManualExit", session.SessionId)
end

function MatchService:_finishMatch(player, reason)
	local session = self:_getActiveSession(player)
	if not session or session.IsFinishing then
		return
	end

	session.IsFinishing = true
	self:_cancelSessionQte(session)

	if reason ~= "Victory" then
		-- Defeat/exit is terminal for the current tournament attempt. Invalidate a
		-- queued leg continuation immediately, before result UI and return teleport
		-- delays, so no stale callback can start another match in that window.
		legContinuationTokens[player] = nil
		tournamentContinuationReturnCFrames[player] = nil
		tournamentContinuationReturnSources[player] = nil
	end

	if reason == "Defeat" then
		defeatRestartLocks[player] = true
		pendingTournamentSources[player] = nil
		if TournamentService and TournamentService.SetPendingStart then
			TournamentService:SetPendingStart(player, false)
		end
	end

	if reason ~= "Victory" then
		SendFeedback(self, player, "ERROR", "Possession lost.")
	end

	local tournamentPayload = nil
	if TournamentService and (reason == "Victory" or reason == "Defeat") then
		local introData = session.Payload and session.Payload.IntroData
		local initHomeScore = introData and tonumber(introData.HomeScore) or 0
		local initAwayScore = introData and tonumber(introData.AwayScore) or 0
		local playerGoals = initHomeScore + (session.MatchGoals or 0)
		-- Bug fix: do NOT add +1 to opponentGoals on Defeat.
		-- initAwayScore already contains the aggregate opponent score (e.g. 3 for RoundOf16).
		-- Adding 1 produced an incorrect score of 4 in the bracket.
		local opponentGoals = initAwayScore
		local ok, result = pcall(function()
			return TournamentService:ApplyMatchResult(player, reason == "Victory", playerGoals, opponentGoals)
		end)

		if ok then
			tournamentPayload = result
		else
			warn("[MatchService] Failed to apply tournament result:", result)
		end
	end

	-- Multi-leg: check if this was a leg win (round not yet complete).
	-- Bug fix: isLegWin hanya valid jika reason == "Victory". Jika player kalah
	-- setelah ngegolin, TournamentService bisa return LegResult="LegWin" berdasarkan
	-- skor, tapi kita TIDAK boleh auto-restart match — player harus balik lobby dulu.
	local isLegWin = reason == "Victory" and type(tournamentPayload) == "table" and tournamentPayload.LegResult == "LegWin"

	if reason == "Victory" and not isLegWin then
		SendFeedback(self, player, "SUCCESS", "Goal! Match won.")
	end

	-- Legacy match reward is still granted at the end; tournament target rounds
	-- already pay Wins per successful goal.
	if not isLegWin then
		self:_grantMatchReward(player, session, reason)
	end

	local tournamentStatus = type(tournamentPayload) == "table" and tostring(tournamentPayload.Status or "Active") or ""
	local tournamentContext = session.Payload and session.Payload.Tournament or nil
	local sessionRoundId = type(tournamentContext) == "table" and tostring(tournamentContext.RoundId or "") or ""
	local sessionRoundIndex = type(tournamentContext) == "table" and tonumber(tournamentContext.RoundIndex) or nil
	local isFinalRoundSession = sessionRoundId == "Final" or sessionRoundIndex == 4

	-- Champion ceremony is only valid after the actual Final match. This protects
	-- the final stage from stale/incorrect champion payloads after R16/QF/SF wins.
	local shouldStartChampionCeremony = reason == "Victory" and tournamentStatus == "Champion" and isFinalRoundSession
	local shouldContinueTournament = reason == "Victory"
		and not isLegWin
		and (tournamentStatus == "Active" or (tournamentStatus == "Champion" and not isFinalRoundSession))

	if reason == "Victory" and tournamentStatus == "Champion" and not isFinalRoundSession then
		warn(
			string.format(
				"[MatchService] Ignored non-final Champion payload for session=%s roundId=%s roundIndex=%s",
				tostring(session.SessionId),
				tostring(sessionRoundId),
				tostring(sessionRoundIndex)
			)
		)
	end

	-- For Defeat: give client time to display the lose popup.
	-- defeatRestartLocks is ALREADY set above, so extending this delay
	-- does NOT open a race-condition window for gate re-triggers.
	local finishTransitionDelay = (reason == "Defeat")
		and (MatchConstants.MATCH_FINISH_DELAY + DEFEAT_UI_HOLD_DELAY)
		or MatchConstants.MATCH_FINISH_DELAY
	task.delay(finishTransitionDelay, function()
		local liveSession = activeSessions[player]
		if liveSession ~= session then
			return
		end

		if isLegWin then
			self:_completeVictoryForLegContinuation(player, session)
		elseif shouldStartChampionCeremony then
			self:_completeVictoryForTournamentChampion(player, session)
		elseif shouldContinueTournament then
			self:_completeVictoryForTournamentContinuation(player, session)
		else
			tournamentContinuationReturnCFrames[player] = nil
			tournamentContinuationReturnSources[player] = nil
			self:_completeSessionNow(player, reason)
		end
	end)
end

function MatchService:SubmitQteResult(player, qtePayload)
	local session = self:_getActiveSession(player)
	if not session or not session.AwaitingQte or self:IsPlayerTransitioning(player) or session.IsFinishing then
		return false
	end

	local stepData = session.CurrentStepData
	if not stepData then
		return false
	end

	local qteTier = "Yellow"
	local cursorAlpha = nil

	if typeof(qtePayload) == "table" then
		qteTier = tostring(qtePayload.Tier or "Yellow")
		cursorAlpha = tonumber(qtePayload.CursorAlpha)
	elseif typeof(qtePayload) == "string" then
		qteTier = qtePayload
	end

	session.AwaitingQte = false

	local resultPayload = MatchResolution.ResolveStep(session.Payload, stepData, qteTier)
	resultPayload.QteTier = qteTier
	resultPayload.SessionId = session.SessionId
	resultPayload.TotalSteps = #session.Payload.Sequence
	resultPayload.CursorAlpha = cursorAlpha
	resultPayload.PassMode = stepData.PassMode
	resultPayload.Player2Branch = stepData.Player2Branch == true
	resultPayload.AutoSkipped = stepData.AutoSkipped == true
	resultPayload.SkipReason = stepData.SkipReason

	self:_awardStepProgress(player, session, resultPayload)
	self.Client.MatchStepResolved:Fire(player, resultPayload)

	if resultPayload.Succeeded then
		if resultPayload.Action == "Pass" and resultPayload.TargetSlot then
			session.CurrentBallOwnerSlot = resultPayload.TargetSlot
		elseif resultPayload.Action == "Dribble" then
			session.CurrentBallOwnerSlot = resultPayload.ActorSlot
		elseif resultPayload.Action == "Shoot" then
			session.CurrentBallOwnerSlot = resultPayload.ActorSlot
		end
	end

	session.PendingPresentationPhase = "PostAction"
	session.PendingPresentationStepIndex = resultPayload.StepIndex
	session.PendingPresentationToken = (session.PendingPresentationToken or 0) + 1
	session.PendingResultPayload = resultPayload

	local presentationToken = session.PendingPresentationToken

	-- Normal flow must wait for client ack via NotifyPresentationReady(..., "PostAction").
	-- This watchdog exists only to recover from deadlock / missing ack.
	local postActionAckMaxWait = if resultPayload.Action == "Shoot"
		then SHOOT_POST_ACTION_ACK_MAX_WAIT
		else POST_ACTION_ACK_MAX_WAIT

	self:_armPresentationWatchdog(
		player,
		session,
		"PostAction",
		resultPayload.StepIndex,
		presentationToken,
		postActionAckMaxWait
	)

	return true
end

function MatchService:_applyPostStepFlowRules(session, resultPayload)
	if not session or not resultPayload or resultPayload.Succeeded ~= true then
		return
	end

	if MatchFlowRules.ShouldSkipQte3AfterStep2(resultPayload) then
		session.SuccessfulQteSteps = session.SuccessfulQteSteps or {}
		session.SuccessfulQteSteps[3] = true
		session.CurrentStepIndex = math.max(tonumber(session.CurrentStepIndex) or 0, 3)
		session.CurrentBallOwnerSlot = tonumber(resultPayload.ActorSlot) or tonumber(session.CurrentBallOwnerSlot) or 2
		session.SkipQte3AfterStep2 = true

		MatchFlowRules.ApplyPlayer2Qte3Skip(session.Payload and session.Payload.Sequence, session.CurrentBallOwnerSlot)

		return
	end

	if session.SkipQte3AfterStep2 == true then
		local nextStepIndex = (tonumber(session.CurrentStepIndex) or 0) + 1
		MatchFlowRules.SyncUpcomingStepOwner(
			session.Payload and session.Payload.Sequence,
			nextStepIndex,
			session.CurrentBallOwnerSlot
		)
	end
end

function MatchService:_clearPendingPresentation(session)
	if not session then
		return
	end

	session.PendingPresentationPhase = nil
	session.PendingPresentationStepIndex = nil
	session.PendingPresentationToken = nil
	session.PendingStepPayload = nil
	session.PendingQteToken = nil
	session.PendingResultPayload = nil
end

function MatchService:_armPresentationWatchdog(player, session, phase, stepIndex, token, maxWait)
	task.delay(maxWait, function()
		local liveSession = activeSessions[player]
		if not liveSession or liveSession ~= session or liveSession.IsFinishing then
			return
		end

		if self:IsPlayerTransitioning(player) then
			return
		end

		if liveSession.PendingPresentationPhase ~= phase then
			return
		end

		if liveSession.PendingPresentationStepIndex ~= stepIndex then
			return
		end

		if liveSession.PendingPresentationToken ~= token then
			return
		end

		warn(
			string.format(
				"[MatchService] Presentation watchdog reached phase=%s step=%s for %s",
				tostring(phase),
				tostring(stepIndex),
				player.Name
			)
		)

		if not PRESENTATION_WATCHDOG_FORCE_RELEASE then
			return
		end

		if phase == "PreQte" then
			self:_openQteNow(player, liveSession, liveSession.PendingStepPayload, liveSession.PendingQteToken)
			return
		end

		if phase == "PostAction" then
			self:_handlePostActionReady(player, liveSession, liveSession.PendingResultPayload)
			return
		end
	end)
end

function MatchService:_openQteNow(player, session, stepPayload, qteToken)
	if not player or not session or not stepPayload then
		return false
	end

	local liveSession = activeSessions[player]
	if liveSession ~= session or liveSession.IsFinishing then
		return false
	end

	if self:IsPlayerTransitioning(player) then
		return false
	end

	if liveSession.AwaitingQte then
		return false
	end

	if liveSession.QteToken ~= qteToken then
		return false
	end

	if liveSession.PendingPresentationPhase ~= "PreQte" then
		return false
	end

	self:_clearPendingPresentation(liveSession)

	liveSession.AwaitingQte = true
	self.Client.MatchStepStarted:Fire(player, stepPayload)

	task.delay(MatchConstants.QTE_RESPONSE_TIMEOUT, function()
		local currentSession = activeSessions[player]
		if not currentSession or currentSession ~= session or currentSession.IsFinishing then
			return
		end

		if not currentSession.AwaitingQte then
			return
		end

		if currentSession.QteToken ~= qteToken then
			return
		end

		self:SubmitQteResult(player, {
			Tier = "Red",
			Source = "Timeout",
			CursorAlpha = 0,
		})
	end)

	return true
end

function MatchService:_handlePostActionReady(player, session, resultPayload)
	if not player or not session or not resultPayload then
		return false
	end

	local liveSession = activeSessions[player]
	if liveSession ~= session or liveSession.IsFinishing then
		return false
	end

	if liveSession.PendingPresentationPhase ~= "PostAction" then
		return false
	end

	self:_clearPendingPresentation(liveSession)

	if resultPayload.Succeeded then
		self:_grantPendingGoalReward(player, liveSession)
		self:_applyPostStepFlowRules(liveSession, resultPayload)

		if liveSession.CurrentStepIndex >= #liveSession.Payload.Sequence then
			task.delay(FINAL_SHOT_FINISH_DELAY, function()
				if
					activeSessions[player] == liveSession
					and not self:IsPlayerTransitioning(player)
					and not liveSession.IsFinishing
				then
					self:_finishMatch(player, "Victory")
				end
			end)
		else
			self:_beginNextStep(player)
		end
	else
		local finishDelay = FAILED_STEP_FINISH_DELAY
		if resultPayload.Action == "Shoot" then
			finishDelay = FINAL_SHOT_FINISH_DELAY
		end

		task.delay(finishDelay, function()
			if
				activeSessions[player] == liveSession
				and not self:IsPlayerTransitioning(player)
				and not liveSession.IsFinishing
			then
				self:_finishMatch(player, "Defeat")
			end
		end)
	end

	return true
end

function MatchService:_releaseIntroGate(player, session, source)
	if not player or not session then
		return false
	end

	local liveSession = activeSessions[player]
	if liveSession ~= session or liveSession.IsFinishing then
		return false
	end

	if not liveSession.WaitingForIntro then
		return false
	end

	if self:IsPlayerTransitioning(player) then
		return false
	end

	liveSession.WaitingForIntro = false
	liveSession.IntroCompleted = true
	liveSession.IntroReleaseToken = (liveSession.IntroReleaseToken or 0) + 1

	task.defer(function()
		if activeSessions[player] == liveSession and not liveSession.IsFinishing then
			self:_beginNextStep(player)
		end
	end)

	return true
end

function MatchService:NotifyMatchIntroCompleted(player, sessionId)
	local session = self:_getActiveSession(player)
	if not session then
		return false
	end

	if tostring(session.SessionId) ~= tostring(sessionId) then
		return false
	end

	return self:_releaseIntroGate(player, session, "Client")
end

function MatchService:NotifyGoalCinematicClimax(player, sessionId)
	local session = self:_getActiveSession(player)
	if not session then
		return false
	end

	if tostring(session.SessionId) ~= tostring(sessionId) then
		return false
	end

	self:_grantPendingGoalReward(player, session)
	return true
end

function MatchService:NotifyPresentationReady(player, sessionId, stepIndex, phase)
	local session = self:_getActiveSession(player)
	if not session then
		return false
	end

	if tostring(session.SessionId) ~= tostring(sessionId) then
		return false
	end

	if session.IsFinishing then
		return false
	end

	local numericStepIndex = tonumber(stepIndex)
	if numericStepIndex == nil then
		return false
	end

	if session.PendingPresentationStepIndex ~= numericStepIndex then
		return false
	end

	if session.PendingPresentationPhase ~= phase then
		return false
	end

	if phase == "PreQte" then
		return self:_openQteNow(player, session, session.PendingStepPayload, session.PendingQteToken)
	end

	if phase == "PostAction" then
		return self:_handlePostActionReady(player, session, session.PendingResultPayload)
	end

	return false
end

function MatchService:RegisterBattleZoneTouchPart(part)
	if not part or not part:IsA("BasePart") then
		return
	end

	if registeredTouchParts[part] then
		return
	end

	registeredTouchParts[part] = true

	pcall(function()
		part.CanTouch = true
	end)

	part.Touched:Connect(function(hit)
		local player = GetPlayerFromTouchedPart(hit)
		if not player then
			return
		end

		self:HandleBattleGateTouched(player, part)
	end)
end

function MatchService:RegisterPrompt(prompt)
	if registeredPrompts[prompt] then
		return
	end
	registeredPrompts[prompt] = true
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false

	-- Battle starts from entering the gate now. Keep the old prompt callback as a
	-- safe fallback, but hide the prompt so players do not need to press E.
	prompt.Enabled = false

	local touchPart = GetTouchPartFromPrompt(prompt)
	if touchPart then
		self:RegisterBattleZoneTouchPart(touchPart)
	end

	prompt.Triggered:Connect(function(player)
		self:HandlePromptTriggered(player, prompt)
	end)
end

function MatchService:RegisterBattleZoneTouchParts()
	local battleZoneRoot = MatchWorldService:GetBattleZoneRoot()
	if not battleZoneRoot then
		return
	end

	for _, descendant in ipairs(battleZoneRoot:GetDescendants()) do
		if ShouldRegisterAutoBattleTouchPart(descendant) then
			self:RegisterBattleZoneTouchPart(descendant)
		end
	end
end

function MatchService:RegisterBattleZonePrompts()
	local prompts = MatchWorldService:GetBattleZonePrompts()
	for _, prompt in ipairs(prompts) do
		self:RegisterPrompt(prompt)
	end

	self:RegisterBattleZoneTouchParts()

	local battleZoneRoot = MatchWorldService:GetBattleZoneRoot()
	if not battleZoneRoot then
		return
	end

	if self._descendantAddedConnection then
		self._descendantAddedConnection:Disconnect()
		self._descendantAddedConnection = nil
	end

	self._descendantAddedConnection = battleZoneRoot.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			self:RegisterPrompt(descendant)
		elseif ShouldRegisterAutoBattleTouchPart(descendant) then
			self:RegisterBattleZoneTouchPart(descendant)
		end
	end)
end

function MatchService:_scanAutoBattleTouchPartsOnce()
	local touchingPlayers = {}

	for part in pairs(registeredTouchParts) do
		if not part or not part.Parent then
			registeredTouchParts[part] = nil
			continue
		end

		local ok, touchingParts = pcall(function()
			return Workspace:GetPartsInPart(part)
		end)

		if ok and type(touchingParts) == "table" then
			local seenPlayers = {}
			for _, hit in ipairs(touchingParts) do
				local player = GetPlayerFromTouchedPart(hit)
				if player and not seenPlayers[player] then
					seenPlayers[player] = true
					touchingPlayers[player] = true
					self:HandleBattleGateTouched(player, part)
				end
			end
		end
	end

	for player, rearmStartedAt in pairs(defeatGateRearmRequired) do
		local hasObservedPostReturnScan = os.clock() - (tonumber(rearmStartedAt) or 0) >= AUTO_BATTLE_ZONE_SCAN_INTERVAL
		if
			hasObservedPostReturnScan
			and not touchingPlayers[player]
			and not activeSessions[player]
			and not pendingTransitions[player]
		then
			defeatGateRearmRequired[player] = nil
		end
	end
end

function MatchService:_startAutoBattleZoneScanner()
	if self._autoBattleZoneScannerStarted then
		return
	end

	self._autoBattleZoneScannerStarted = true

	task.spawn(function()
		while self._autoBattleZoneScannerStarted do
			task.wait(AUTO_BATTLE_ZONE_SCAN_INTERVAL)
			self:_scanAutoBattleTouchPartsOnce()
		end
	end)
end

function MatchService:_validateTournamentPreviewRequest(player, silentBusy)
	if self:IsPlayerInMatch(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "You are already inside the match.")
		end
		return nil, nil, false
	end

	if self:IsPlayerTransitioning(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Match transition is already in progress.")
		end
		return nil, nil, false
	end

	if TrainingService and TrainingService.IsPlayerTraining and TrainingService:IsPlayerTraining(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Stop training first before entering the match.")
		end
		return nil, nil, false
	end

	local playerData = DataService and DataService:GetData(player)
	if not playerData then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Player data is not ready yet.")
		end
		return nil, nil, false
	end

	return playerData, GetPlayerAreaId(playerData), true
end

function MatchService:_requestTournamentPreview(player, source, options)
	local silentBusy = options and options.SilentBusy == true

	if not TournamentService or not TournamentService.PrepareTournamentForPlayer then
		return self:_tryStartMatch(player, source, options)
	end

	local _, areaId, canPreview = self:_validateTournamentPreviewRequest(player, silentBusy)
	if not canPreview then
		return false
	end

	if TournamentService.IsPendingStart and TournamentService:IsPendingStart(player) then
		return false
	end

	pendingTournamentSources[player] = source

	if TournamentService.SetPendingStart then
		TournamentService:SetPendingStart(player, true)
	end

	local ok, err = pcall(function()
		TournamentService:PrepareTournamentForPlayer(player, areaId)
	end)

	if not ok then
		pendingTournamentSources[player] = nil
		if TournamentService.SetPendingStart then
			TournamentService:SetPendingStart(player, false)
		end

		warn("[MatchService] Failed to prepare tournament preview:", err)
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Failed to open tournament bracket.")
		end
		return false
	end

	return true
end

function MatchService:StartFtueMatch(player, options)
	return self:_tryStartMatch(player, "Tutorial", options)
end

function MatchService:StartConfirmedTournamentMatch(player)
	if
		not TournamentService
		or not TournamentService.IsPendingStart
		or not TournamentService:IsPendingStart(player)
	then
		return false
	end

	local source = pendingTournamentSources[player]
	pendingTournamentSources[player] = nil

	local returnCFrameOverride = tournamentContinuationReturnCFrames[player]
	local returnTargetSourceOverride = tournamentContinuationReturnSources[player]
	tournamentContinuationReturnCFrames[player] = nil
	tournamentContinuationReturnSources[player] = nil

	if TournamentService.SetPendingStart then
		TournamentService:SetPendingStart(player, false)
	end

	return self:_tryStartMatch(player, source, {
		SilentBusy = false,
		FromTournament = true,
		ExplicitPlayerStart = true,
		ReturnCFrameOverride = returnCFrameOverride,
		ReturnTargetSourceOverride = returnTargetSourceOverride,
	})
end

function MatchService:_tryStartMatch(player, source, options)
	local silentBusy = options and options.SilentBusy == true
	local isExplicitPlayerStart = options and options.ExplicitPlayerStart == true

	if defeatRestartLocks[player] and not isExplicitPlayerStart then
		return false
	end

	if self:IsPlayerInMatch(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "You are already inside the match.")
		end
		return false
	end

	if self:IsPlayerTransitioning(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Match transition is already in progress.")
		end
		return false
	end

	if TrainingService and TrainingService.IsPlayerTraining and TrainingService:IsPlayerTraining(player) then
		if not silentBusy then
			SendFeedback(self, player, "ERROR", "Stop training first before entering the match.")
		end
		return false
	end

	local payload, errorMessage = self:BuildSessionPayload(player)
	if not payload then
		SendFeedback(self, player, "ERROR", errorMessage or "Failed to create match session.")
		return false
	end

	if TradeService and TradeService.CancelPlayerActivityForMatch then
		pcall(function()
			TradeService:CancelPlayerActivityForMatch(player)
		end)
	end

	local returnCFrame = nil
	local returnSource = nil

	local overrideCFrame = options and options.ReturnCFrameOverride
	if typeof(overrideCFrame) == "CFrame" then
		returnCFrame = overrideCFrame
		returnSource = options and options.ReturnTargetSourceOverride or nil
	else
		returnCFrame, returnSource = ResolveBattleReturnCFrame(source)
		returnCFrame = returnCFrame or GetCharacterPivot(player)
	end

	pendingTransitions[player] = {
		Mode = "Enter",
		SessionId = payload.SessionId,
		Payload = payload,
		OriginalCFrame = returnCFrame,
		StartedAt = os.clock(),
		Confirmed = false,
		Source = source and source.Name or "Unknown",
		ReturnTargetSource = returnSource,
	}

	if isExplicitPlayerStart then
		defeatRestartLocks[player] = nil
		defeatGateRearmRequired[player] = nil
	end

	self.Client.MatchTransitionRequested:Fire(
		player,
		"Enter",
		{
			SessionId = payload.SessionId,
			AreaId = payload.AreaId,
			IsLegContinuation = IsLegContinuationPayload(payload),
		}
	)

	task.delay(MatchConstants.ENTER_TRANSITION_TIMEOUT, function()
		local transition = pendingTransitions[player]
		if transition and transition.SessionId == payload.SessionId and not transition.Confirmed then
			self:ConfirmTransitionReady(player, payload.SessionId)
		end
	end)

	return true
end

function MatchService:HandleBattleGateTouched(player, touchPart)
	if not player then
		return false
	end

	if defeatGateRearmRequired[player] then
		return false
	end

	local now = os.clock()
	local lastTouch = touchDebounces[player]
	if lastTouch and (now - lastTouch) < AUTO_BATTLE_TOUCH_DEBOUNCE then
		return false
	end

	local started = self:_requestTournamentPreview(player, touchPart, { SilentBusy = true })
	if started then
		touchDebounces[player] = now
	end

	return started
end

function MatchService:HandlePromptTriggered(player, prompt)
	return self:_requestTournamentPreview(player, prompt, { SilentBusy = false })
end

function MatchService:ConfirmTransitionReady(player, sessionId)
	local transition = pendingTransitions[player]
	if not transition or transition.SessionId ~= sessionId then
		return false
	end
	transition.Confirmed = true

	if transition.Mode == "Enter" then
		local zoneVariationId = transition.Payload and transition.Payload.ZoneVariationId or nil
		local playerSpawnCFrame = MatchWorldService:GetPlayerSpawnCFrame(zoneVariationId)
		if not playerSpawnCFrame then
			pendingTransitions[player] = nil
			SendFeedback(self, player, "ERROR", "PlayerSpawn is missing.")
			return false
		end

		transition.OriginalCFrame = transition.OriginalCFrame or GetCharacterPivot(player)
		player:SetAttribute("IsInMatch", true)

		local teleported, resolvedPlayerSpawnCFrame = TeleportCharacterToCFrame(player, playerSpawnCFrame, {
			KeepRootLocked = true,
		})
		if not teleported then
			player:SetAttribute("IsInMatch", false)
			pendingTransitions[player] = nil
			SendFeedback(self, player, "ERROR", "Character is not ready for teleport.")
			return false
		end

		transition.Payload.PlayerSpawnCFrame = resolvedPlayerSpawnCFrame or playerSpawnCFrame

		local shouldWaitForIntro = MatchIntroConfig.Enabled ~= false
			and not IsLegContinuationPayload(transition.Payload)

		activeSessions[player] = {
			SessionId = transition.SessionId,
			Payload = transition.Payload,
			OriginalCFrame = transition.OriginalCFrame,
			ReturnTargetSource = transition.ReturnTargetSource,
			StartedAt = os.clock(),
			CurrentStepIndex = 0,
			CurrentStepData = nil,
			AwaitingQte = false,
			QteToken = 0,
			CurrentBallOwnerSlot = 1,
			IsFinishing = false,
			MatchGoals = 0,

			PendingPresentationPhase = nil,
			PendingPresentationStepIndex = nil,
			PendingPresentationToken = 0,
			PendingStepPayload = nil,
			PendingQteToken = nil,
			PendingResultPayload = nil,

			WaitingForIntro = shouldWaitForIntro,
			IntroCompleted = not shouldWaitForIntro,
			IntroReleaseToken = 0,
		}

		pendingTransitions[player] = nil
		self.Client.MatchSessionStarted:Fire(player, transition.Payload)

		local session = activeSessions[player]
		if session and session.WaitingForIntro then
			local introToken = (session.IntroReleaseToken or 0) + 1
			session.IntroReleaseToken = introToken

			task.delay(MATCH_INTRO_ACK_MAX_WAIT, function()
				local liveSession = activeSessions[player]
				if liveSession ~= session or liveSession.IsFinishing then
					return
				end

				if liveSession.IntroReleaseToken ~= introToken or not liveSession.WaitingForIntro then
					return
				end

				warn(
					string.format(
						"[MatchIntro] intro watchdog releasing presentation session=%s",
						tostring(liveSession.SessionId)
					)
				)
				self:_releaseIntroGate(player, liveSession, "Watchdog")
			end)
		else
			task.defer(function()
				if activeSessions[player] then
					self:_beginNextStep(player)
				end
			end)
		end
		return true
	end

	if transition.Mode == "Leave" then
		local session = activeSessions[player]
		local leaveReason = transition.Reason or "ManualExit"
		pendingTransitions[player] = nil

		if not session then
			player:SetAttribute("IsInMatch", false)
			self.Client.MatchSessionEnded:Fire(player, leaveReason, transition.SessionId)
			return true
		end

		self:_cancelSessionQte(session)
		session.IsFinishing = true

		if TournamentService and (leaveReason == "ManualExit" or leaveReason == "Defeat") then
			local ok, result = pcall(function()
				return TournamentService:ApplyMatchResult(player, false, session.MatchGoals, nil)
			end)
			if not ok then
				warn("[MatchService] Failed to apply tournament defeat on leave:", result)
			end
		end

		self:_completeSessionNow(player, leaveReason)
		return true
	end
	return false
end

function MatchService:BeginLeaveTransition(player, reason)
	local session = activeSessions[player]
	if not session or self:IsPlayerTransitioning(player) then
		return false
	end

	local leaveReason = reason or "ManualExit"
	self:_cancelSessionQte(session)

	pendingTransitions[player] = {
		Mode = "Leave",
		SessionId = session.SessionId,
		StartedAt = os.clock(),
		Confirmed = false,
		Reason = leaveReason,
	}

	self.Client.MatchTransitionRequested:Fire(player, "Leave", {
		SessionId = session.SessionId,
		AreaId = session.Payload and session.Payload.AreaId or MatchConstants.DEFAULT_AREA_ID,
		Reason = leaveReason,
	})

	task.delay(MatchConstants.LEAVE_TRANSITION_TIMEOUT, function()
		local transition = pendingTransitions[player]
		if transition and transition.SessionId == session.SessionId and not transition.Confirmed then
			self:ConfirmTransitionReady(player, session.SessionId)
		end
	end)
	return true
end

function MatchService:RequestLeaveMatch(player, reason)
	return self:BeginLeaveTransition(player, reason or "ManualExit")
end

function MatchService:ForceEndMatch(player, reason)
	return self:BeginLeaveTransition(player, reason or "Defeat")
end

--| Knit Startup |--
function MatchService:KnitInit()
	self._descendantAddedConnection = nil
	self._autoBattleZoneScannerStarted = false
end

function MatchService:KnitStart()
	DataService = Knit.GetService("DataService")
	MatchWorldService = Knit.GetService("MatchWorldService")

	local ok, service = pcall(function()
		return Knit.GetService("TrainingService")
	end)
	if ok then
		TrainingService = service
	end

	local tournamentOk, tournamentService = pcall(function()
		return Knit.GetService("TournamentService")
	end)
	if tournamentOk then
		TournamentService = tournamentService
	end

	local tradeOk, tradeService = pcall(function()
		return Knit.GetService("TradeService")
	end)
	if tradeOk then
		TradeService = tradeService
	end

	self:RegisterBattleZonePrompts()
	self:_startAutoBattleZoneScanner()

	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("IsInMatch", false)
	end

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("IsInMatch", false)
	end)

	Players.PlayerRemoving:Connect(function(player)
		player:SetAttribute("IsInMatch", false)
		activeSessions[player] = nil
		pendingTransitions[player] = nil
		touchDebounces[player] = nil
		pendingTournamentSources[player] = nil
		tournamentContinuationReturnCFrames[player] = nil
		tournamentContinuationReturnSources[player] = nil
		activeChampionCeremonies[player] = nil
		legContinuationTokens[player] = nil
		defeatRestartLocks[player] = nil
		defeatGateRearmRequired[player] = nil
	end)
end

return MatchService
