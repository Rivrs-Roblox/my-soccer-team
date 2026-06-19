local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local EnemyBillboardFactory = require(script.Parent.Parent.Modules.Match.EnemyBillboardFactory)
local Sound = require(Packages:WaitForChild("Sound"))
local formatnumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)
local MatchCharacterPropVisibility =
	require(script.Parent.Parent.Helpers.Match.Presentation.MatchCharacterPropVisibility)
local MatchActionFxHelper = require(script.Parent.Parent.Helpers.Match.Presentation.MatchActionFxHelper)
local MatchShootTargetResolver = require(script.Parent.Parent.Helpers.Match.Presentation.MatchShootTargetResolver)

local LocalPlayer = Players.LocalPlayer

local BLOCK_ACTION_NAME = "MatchController_BlockMovement"
local LEAVE_ACTION_NAME = "MatchController_LeaveMatch"
local QTE_CONFIRM_ACTION_NAME = "MatchController_QteConfirm"
local QTE_TEST_CHEAT_ACTION_NAME = "MatchController_TestCheatAutoPerfectCenter"
local ENABLE_TEST_QTE_CHEATS = false

local MatchService = nil
local NotificationController = nil
local MatchUIController = nil
local UIController = nil
local SoccerCharactersController = nil
local MatchCompanionVisualController = nil
local CoachesController = nil
local MatchPresentationController = nil

local ENEMY_BILLBOARD_OFFSETS = {
	[1] = Vector3.new(-1.25, 2.6, 0),
	[2] = Vector3.new(0, 2.6, 0),
	[3] = Vector3.new(1.25, 2.6, 0),
	[4] = Vector3.new(0, 2.8, 0),
}

local RETURN_OVERLAY_RELEASE_DELAY = 0.35
local RETURN_OVERLAY_MIN_HOLD = 0.30

--| Match Controller |--
local MatchController = Knit.CreateController({
	Name = "MatchController",
})

--| Local Functions |--
local function ResolveRemoteResult(remoteResult)
	if type(remoteResult) == "table" and remoteResult.await then
		local ok, value = remoteResult:await()
		if ok then
			return value
		end
		return false
	end
	return remoteResult
end

local function ForceHideLocalCharacterTrophy()
	local ok, err = pcall(function()
		MatchCharacterPropVisibility.ForceHideKnownRuntimeTrophies(LocalPlayer)
	end)

	if not ok then
		warn("[MatchController] Failed to hide trophy props:", err)
	end
end

local function ForceStopLingeringMatchActionFx()
	local roots = {
		workspace:FindFirstChild("LocalMatchPresentationRuntime"),
	}

	for _, root in ipairs(roots) do
		if root then
			pcall(function()
				MatchActionFxHelper.StopAllEffectsIn(root)
			end)
		end
	end
end

local function IsShootAction(actionName)
	return string.lower(tostring(actionName or "")) == "shoot"
end

local function IsLegContinuationPayload(payload)
	local tournament = payload and payload.Tournament
	local currentLeg = tournament and tonumber(tournament.CurrentLeg)
	return currentLeg ~= nil and currentLeg > 1
end

--| Client Functions |--
function MatchController:_notify(message, notificationType)
	-- Komentari baris di bawah ini untuk menyembunyikan notifikasi popup
	--[[
	if NotificationController and NotificationController.Notify then
		NotificationController:Notify({
			tag = "MatchFlow",
			text = message,
			type = notificationType or "INFO",
		})
	else
		warn("[MatchController]", message)
	end
	--]]

	if notificationType == "ERROR" then
		warn("[MatchController]", message)
	end
end

function MatchController:_blockLobbyUiForMatch()
	if UIController and UIController.CloseAllPanelsForMatch then
		UIController:CloseAllPanelsForMatch()
	end

	if NotificationController and NotificationController.ClearQueueForMatch then
		NotificationController:ClearQueueForMatch()
	end
end

function MatchController:_unblockLobbyUiAfterMatch()
	if UIController and UIController.SetMatchUiBlocked then
		UIController:SetMatchUiBlocked(false)
	end
end

function MatchController:_cancelMatchIntro(reason)
	if not self._introActive then
		return
	end

	local sessionId = self._introSessionId
	self._introActive = false
	self._introToken += 1

	if self._matchIntroCancelledEvent then
		self._matchIntroCancelledEvent:Fire({
			SessionId = sessionId,
			Token = self._introToken,
			Reason = reason or "Cancelled",
		})
	end
end

function MatchController:_beginMatchIntro(payload)
	if not payload or not payload.IntroData then
		return
	end

	self:_cancelMatchIntro("NewIntro")

	self._introToken += 1
	self._introActive = true
	self._introSessionId = tostring(payload.SessionId or "")
	self._introCompleted = false

	local introData = payload.IntroData
	if introData and not introData.AreaId then
		introData.AreaId = payload.AreaId
	end
	if introData and payload.Tournament and tonumber(payload.Tournament.CurrentLeg) and tonumber(payload.Tournament.CurrentLeg) > 1 then
		introData.MatchTitle = introData.MatchTitle or "MATCH CONTINUES"
	end

	if self._matchIntroRequestedEvent then
		self._matchIntroRequestedEvent:Fire({
			SessionId = self._introSessionId,
			Token = self._introToken,
			IntroData = introData,
		})
	end
end



function MatchController:IsPlayingMatch()
	return self._inMatch or self._transitionBusy or self._championCeremonyActive
end

function MatchController:CompleteMatchIntro(sessionId, token, didComplete)
	if tostring(sessionId or "") ~= tostring(self._introSessionId or "") then
		return false
	end

	if tonumber(token) ~= tonumber(self._introToken) then
		return false
	end

	if not self._introActive then
		return false
	end

	self._introActive = false
	self._introCompleted = didComplete == true

	if not self._introCompleted then
		return false
	end

	local ok = ResolveRemoteResult(MatchService:NotifyMatchIntroCompleted(sessionId))
	if not ok then
		warn(string.format("[MatchIntro] failed to notify server intro complete session=%s", tostring(sessionId)))
	end

	return ok == true
end

function MatchController:_getControls()
	if self._controls then
		return self._controls
	end

	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return nil
	end

	local ok, playerModule = pcall(function()
		return require(playerScripts:WaitForChild("PlayerModule"))
	end)

	if not ok or not playerModule then
		return nil
	end

	self._controls = playerModule:GetControls()
	return self._controls
end

function MatchController:_disableControls()
	local controls = self:_getControls()
	if controls then
		controls:Disable()
	end

	ContextActionService:BindActionAtPriority(
		BLOCK_ACTION_NAME,
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.LeftShift
	)
end

function MatchController:_enableControls()
	local controls = self:_getControls()
	if controls then
		controls:Enable()
	end
	ContextActionService:UnbindAction(BLOCK_ACTION_NAME)
end

function MatchController:_destroyBillboards()
	for _, billboard in ipairs(self._enemyBillboards) do
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end
	table.clear(self._enemyBillboards)
	table.clear(self._enemyBillboardsByStep)
end

function MatchController:_applyEnemyBillboards(payload)
	self:_destroyBillboards()

	for stepIndex, stepData in ipairs(payload.EnemySteps or {}) do
		local enemyInstance = MatchSceneQuery.GetEnemyByStep(stepIndex)
		if enemyInstance then
			local billboard = EnemyBillboardFactory.Create(
				enemyInstance,
				stepData.Value or 0,
				stepIndex,
				ENEMY_BILLBOARD_OFFSETS[stepIndex]
			)

			if billboard then
				billboard.Parent = enemyInstance
				table.insert(self._enemyBillboards, billboard)
				self._enemyBillboardsByStep[stepIndex] = billboard
				EnemyBillboardFactory.SetText(
					billboard,
					("QTE %d"):format(stepIndex),
					formatnumber(stepData.Value or 0)
				)
				EnemyBillboardFactory.SetActive(billboard, false)
			end
		end
	end
end

function MatchController:_setActiveEnemyBillboard(enemyStep, actionName, enemyValue)
	for stepIndex, billboard in pairs(self._enemyBillboardsByStep) do
		local isActive = stepIndex == enemyStep
		EnemyBillboardFactory.SetActive(billboard, isActive)

		if isActive then
			EnemyBillboardFactory.SetText(
				billboard,
				string.upper(actionName or ("QTE " .. tostring(stepIndex))),
				formatnumber(enemyValue or 0)
			)
		else
			local payload = self._currentPayload
			local stepData = payload and payload.EnemySteps and payload.EnemySteps[stepIndex]
			EnemyBillboardFactory.SetText(
				billboard,
				("QTE %d"):format(stepIndex),
				formatnumber(stepData and stepData.Value or 0)
			)
		end
	end
end

function MatchController:RequestExitMatch(reason)
	return self:_requestExit(reason)
end

function MatchController:_requestExit(reason)
	if self._transitionBusy then
		return false
	end
	local ok = ResolveRemoteResult(MatchService:RequestLeaveMatch(reason))
	if not ok then
		self:_notify("Cannot leave match right now.", "ERROR")
		return false
	end
	return true
end

function MatchController:_submitCurrentQte(options)
	options = typeof(options) == "table" and options or {}

	if not self._inMatch or self._transitionBusy or not self._qteOpen then
		return false
	end
	if not MatchUIController or not MatchUIController.ConfirmQte then
		return false
	end

	local result = MatchUIController:ConfirmQte()
	if not result then
		return false
	end

	local isShootQte = IsShootAction(self._currentStepPayload and self._currentStepPayload.Action)
	if isShootQte and MatchShootTargetResolver then
		if options.DebugForceCenterTarget == true and MatchShootTargetResolver.SetDebugForcedTargetId then
			MatchShootTargetResolver.SetDebugForcedTargetId("Center")
		elseif MatchShootTargetResolver.ClearDebugForcedTargetId then
			MatchShootTargetResolver.ClearDebugForcedTargetId()
		end
	end

	if isShootQte then
		-- Shoot uses a dedicated cinematic after the server resolves the step.
		-- Hide only the timing UI immediately so the local input feels responsive,
		-- but keep ball release/result authority on MatchStepResolved.
		self._qteOpen = false

		if MatchUIController.HideQte then
			MatchUIController:HideQte({
				ResumeBroadcastClock = false,
			})
		end
	end

	local ok = ResolveRemoteResult(MatchService:SubmitQteResult(result))
	if not ok and MatchShootTargetResolver and MatchShootTargetResolver.ClearDebugForcedTargetId then
		MatchShootTargetResolver.ClearDebugForcedTargetId()
	end

	return ok
end

function MatchController:_waitForIntroVisualReady(payload)
	local sessionId = payload and payload.SessionId
	if MatchPresentationController and MatchPresentationController.WaitForIntroVisualReady then
		local ok, ready = pcall(function()
			return MatchPresentationController:WaitForIntroVisualReady(sessionId, 1.0)
		end)

		if ok and ready == true then
			return true
		end
	end

	-- Fallback only. Keeps the fade closed for a couple of frames if the presentation
	-- controller is late or unavailable, without blocking the match indefinitely.
	for _ = 1, 2 do
		RunService.RenderStepped:Wait()
	end

	return false
end

function MatchController:RequestFinishChampionCeremony(sessionId)
	if not MatchService or not MatchService.RequestFinishChampionCeremony then
		return false
	end

	return ResolveRemoteResult(MatchService:RequestFinishChampionCeremony(sessionId)) == true
end

function MatchController:_applySessionEndedFade(isTournamentContinuation, isChampionCeremony, reasonText)
	-- Called SYNCHRONOUSLY (before task.spawn) so the fade starts on the same
	-- frame the MatchSessionEnded signal fires — before MatchPresentationCleanup
	-- ._endSession moves any actors/proxies into their reset positions.
	if not MatchUIController then
		return
	end

	if reasonText == "LegContinuation" then
		return
	end

	if isTournamentContinuation then
		-- Black screen hides actor/proxy cleanup. FadeFromBlack happens later
		-- after the bracket interstitial has rendered or when the next round begins.
		if MatchUIController.CutToBlack then
			MatchUIController:CutToBlack("Next Round...")
		else
			MatchUIController:FadeToBlack("Next Round...")
		end
	elseif isChampionCeremony then
		-- Final win also cleans match actors before the ceremony stage is ready.
		-- Keep that teleport/clone handoff behind the same transition cover.
		if MatchUIController.CutToBlack then
			MatchUIController:CutToBlack()
		else
			MatchUIController:FadeToBlack()
		end
	end
	-- Normal return: _handleReturnStarted already called FadeToBlack via MatchReturnStarted.
end

-- Normal return: _handleReturnStarted already called FadeToBlack via MatchReturnStarted.
function MatchController:_bindLeaveInput()
	ContextActionService:BindAction(LEAVE_ACTION_NAME, function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if not self._inMatch or self._transitionBusy then
			return Enum.ContextActionResult.Pass
		end
		self:_requestExit("ManualExit")
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
end

function MatchController:_bindQteKeyboardInput()
	ContextActionService:BindActionAtPriority(QTE_CONFIRM_ACTION_NAME, function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if not self._inMatch or self._transitionBusy or not self._qteOpen then
			return Enum.ContextActionResult.Pass
		end
		local ok = self:_submitCurrentQte()
		if ok then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.ContextActionPriority.High.Value + 5, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	-- TEST ONLY CHEAT: Press O during QTE to auto-perfect.
	-- If the active action is Shoot, also force the visual shot target to Center.
	-- Keep this behind ENABLE_TEST_QTE_CHEATS so it is easy to disable before release.
	if ENABLE_TEST_QTE_CHEATS then
		ContextActionService:BindActionAtPriority(QTE_TEST_CHEAT_ACTION_NAME, function(_, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			if not self._inMatch or self._transitionBusy or not self._qteOpen then
				return Enum.ContextActionResult.Pass
			end

			if MatchUIController and MatchUIController.ActivateCheatAutoPerfect then
				MatchUIController:ActivateCheatAutoPerfect()
			end

			local ok = self:_submitCurrentQte({
				DebugForceCenterTarget = IsShootAction(self._currentStepPayload and self._currentStepPayload.Action),
			})
			if ok then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.O)
	end
end

--| Functions untuk match service |--
function MatchController:_handleTransitionRequested(mode, transitionData)
	if self._transitionBusy then
		return
	end
	self._transitionBusy = true
	local isLegContinuation = transitionData and transitionData.IsLegContinuation == true

	if mode == "Enter" then
		self:_blockLobbyUiForMatch()
	end

	task.spawn(function()
		self:_disableControls()

		if mode == "Enter" and SoccerCharactersController and SoccerCharactersController.RecordPreMatchPivots then
			SoccerCharactersController:RecordPreMatchPivots(LocalPlayer)
		end

		if MatchUIController then
			MatchUIController:BeginMatchUi(function()
				self:_requestExit("ManualExit")
			end)
			if mode == "Enter" and not isLegContinuation then
				MatchUIController:FadeToBlack("Entering Match...")
			elseif mode ~= "Enter" then
				MatchUIController:FadeToBlack("Returning...")
			end
		end

		if mode == "Enter" and MatchPresentationController and MatchPresentationController.PrepareLocalCharacterForMatchTransition then
			MatchPresentationController:PrepareLocalCharacterForMatchTransition()
		end

		local ok = ResolveRemoteResult(MatchService:ConfirmTransitionReady(transitionData.SessionId))
		if not ok then
			self._transitionBusy = false
			self:_enableControls()
			if mode == "Enter" and MatchPresentationController and MatchPresentationController.CancelLocalCharacterMatchTransition then
				MatchPresentationController:CancelLocalCharacterMatchTransition()
			end
			if MatchUIController then
				MatchUIController:FadeFromBlack()
				MatchUIController:EndMatchUi()
			end
			self:_notify("Match transition failed.", "ERROR")
		end
	end)
end

function MatchController:_handleSessionStarted(payload)
	task.spawn(function()
		self:_blockLobbyUiForMatch()

		self._currentSessionId = payload.SessionId
		if MatchUIController and MatchUIController.SetActiveMatchSession then
			MatchUIController:SetActiveMatchSession(payload.SessionId)
		end
		ForceHideLocalCharacterTrophy()
		self._currentPayload = payload
		self._inMatch = true
		self._qteOpen = false

		local isLegContinuation = IsLegContinuationPayload(payload)

		if not isLegContinuation then
			Sound:StopSound("MUSIC_Background")
			Sound:PlaySound("MUSIC_Fight")
		end

		self:_applyEnemyBillboards(payload)

		if not isLegContinuation then
			self:_waitForIntroVisualReady(payload)
		end
		if MatchUIController then
			MatchUIController:SetGoalsValue(payload.CurrentGoals or 0)
			MatchUIController:ShowExitButton()
			MatchUIController:HideGoalsPill()
			MatchUIController:HideComparePill()
			if MatchUIController.ShowBroadcastHud then
				MatchUIController:ShowBroadcastHud(payload)
			end
		end

		if not isLegContinuation and not (payload and payload.IntroData) then
			warn("[MatchController] No IntroData found in payload for session", payload and payload.SessionId)
		end

		if not isLegContinuation then
			self:_beginMatchIntro(payload)
		else
			self:_cancelMatchIntro("LegContinuation")
		end

		if not isLegContinuation and payload and payload.IntroData then
			-- Give the intro overlay one render frame to mount before releasing the global transition blackout.
			-- This prevents a one-frame reveal of the proxy/original character handoff.
			RunService.RenderStepped:Wait()
		end

		if MatchUIController then
			MatchUIController:FadeFromBlack()
		end

		self:_disableControls()
		self._transitionBusy = false
		if not isLegContinuation then
			self:_notify(("Match ready for %s."):format(payload.AreaId), "SUCCESS")
		end
	end)
end

function MatchController:_handleChampionCeremonyStarted(payload)
	task.spawn(function()
		self._championCeremonyActive = true
		self._transitionBusy = true
		self._qteOpen = false
		ForceHideLocalCharacterTrophy()

		if MatchUIController then
			if MatchUIController.ClearActiveMatchSession then
				MatchUIController:ClearActiveMatchSession(payload and payload.SessionId)
			end
			MatchUIController:HideQte()
			MatchUIController:HideExitButton()
			MatchUIController:HideGoalsPill()
			MatchUIController:HideComparePill()
			if MatchUIController.HideBroadcastHud then
				MatchUIController:HideBroadcastHud()
			end
		end
																
		-- Fade to black before the ceremony event fires so the champion
		-- stage clone setup and actor cleanup are hidden behind the transition.
		if MatchUIController then
			MatchUIController:FadeToBlack()
		end
		-- Give the black frame a moment to render before staging clones.
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()

		if self._championCeremonyStartedEvent then
			self._championCeremonyStartedEvent:Fire(payload)
		end

		-- Reveal the champion stage after clones have had time to be positioned.
		-- 0.5s is enough for PrepareClone + PivotTo + camera setup in TournamentChampionView.
		task.delay(0.5, function()
			if MatchUIController then
				MatchUIController:FadeFromBlack()
			end
		end)
	end)
end

function MatchController:_handleReturnStarted(payload)
	local payloadSessionId = payload and payload.SessionId
	if payloadSessionId ~= nil and self._currentSessionId ~= nil and tostring(payloadSessionId) ~= tostring(self._currentSessionId) then
		return
	end

	task.spawn(function()
		if MatchUIController and MatchUIController.ClearActiveMatchSession then
			MatchUIController:ClearActiveMatchSession(payloadSessionId)
		end

		self._transitionBusy = true
		self._returningFromMatch = true
		self._returnOverlayStartedAt = os.clock()
		self._qteOpen = false

		self:_cancelMatchIntro(payload and payload.Reason or "ReturnStarted")

		self:_disableControls()

		if MatchUIController then
			MatchUIController:HideQte()
			MatchUIController:HideExitButton()
			MatchUIController:HideComparePill()
			if MatchUIController.HideBroadcastHud then
				MatchUIController:HideBroadcastHud()
			end
			MatchUIController:FadeToBlack("Returning to Lobby...")
		end
	end)
end

function MatchController:_handleReturnAttendance(payload)
end

function MatchController:_restoreLobbyPresentationAfterMatch(reasonText)
	ForceHideLocalCharacterTrophy()
	ForceStopLingeringMatchActionFx()
	task.delay(0.35, ForceStopLingeringMatchActionFx)
	task.delay(0.85, ForceStopLingeringMatchActionFx)
	task.delay(1.5, ForceStopLingeringMatchActionFx)

	if MatchPresentationController and MatchPresentationController._finalizeReturnCleanup then
		pcall(function()
			MatchPresentationController:_finalizeReturnCleanup(reasonText or "MatchSessionEnded")
		end)
	end

	if UIController and UIController.ShowHUD then
		UIController:ShowHUD()
	end

	if MatchCompanionVisualController and MatchCompanionVisualController.RestoreCompanionsBehindOwner then
		pcall(function()
			MatchCompanionVisualController:RestoreCompanionsBehindOwner(LocalPlayer)
		end)
	end

	if CoachesController and CoachesController.RestoreCoachesBehindOwner then
		pcall(function()
			CoachesController:RestoreCoachesBehindOwner(LocalPlayer)
		end)
	end
end

function MatchController:_handleSessionEnded(reason, sessionId)
	local reasonText = tostring(reason or "")
	local endedSessionId = tostring(sessionId or "")
	if
		endedSessionId ~= ""
		and self._currentSessionId ~= nil
		and tostring(self._currentSessionId) ~= endedSessionId
	then
		return
	end

	local isTournamentContinuation = reasonText == "VictoryContinuation" or reasonText == "LegContinuation"
	local isChampionCeremony = reasonText == "ChampionCeremony"

	if MatchUIController and MatchUIController.ClearActiveMatchSession then
		MatchUIController:ClearActiveMatchSession(endedSessionId ~= "" and endedSessionId or nil)
	end

	self:_applySessionEndedFade(isTournamentContinuation, isChampionCeremony, reasonText)

	task.spawn(function()
		self._currentSessionId = nil
		self._currentPayload = nil
		self._currentStepPayload = nil
		self._inMatch = false
		self._qteOpen = false

		if MatchShootTargetResolver and MatchShootTargetResolver.ClearDebugForcedTargetId then
			MatchShootTargetResolver.ClearDebugForcedTargetId()
		end

		self:_cancelMatchIntro(reason or "SessionEnded")
		ForceStopLingeringMatchActionFx()

		if not isTournamentContinuation and not isChampionCeremony then
			Sound:StopSound("MUSIC_Fight")
			Sound:PlaySound("MUSIC_Background")
		end

		if SoccerCharactersController and SoccerCharactersController.ResetCollisionGroups then
			SoccerCharactersController:ResetCollisionGroups()
		end

		self:_destroyBillboards()

		if MatchUIController then
			MatchUIController:HideQte()
			MatchUIController:HideExitButton()
			MatchUIController:HideGoalsPill()
			MatchUIController:HideComparePill()
			if MatchUIController.HideBroadcastHud then
				MatchUIController:HideBroadcastHud()
			end
			MatchUIController:SetCompareText("")

			if not isTournamentContinuation and not isChampionCeremony then
				-- Normal lobby return: wait for the overlay that MatchReturnStarted started.
				local startedAt = self._returnOverlayStartedAt
				local elapsed = startedAt and (os.clock() - startedAt) or RETURN_OVERLAY_MIN_HOLD
				local waitTime = math.max(RETURN_OVERLAY_RELEASE_DELAY, RETURN_OVERLAY_MIN_HOLD - elapsed)
				if waitTime > 0 then
					task.wait(waitTime)
				end
				MatchUIController:FadeFromBlack()
			end

			MatchUIController:EndMatchUi({
				PreserveTransitionOverlay = isTournamentContinuation or isChampionCeremony,
			})
		end

		if not isTournamentContinuation and not isChampionCeremony then
			self:_unblockLobbyUiAfterMatch()
			self:_restoreLobbyPresentationAfterMatch(reasonText ~= "" and reasonText or "MatchSessionEnded")
		end

		self._returningFromMatch = false
		self._returnOverlayStartedAt = nil

		if isChampionCeremony then
			self:_disableControls()
			self._transitionBusy = true
		else
			self:_enableControls()
			self._transitionBusy = false
		end

		if reasonText == "LegContinuation" then
			-- Mid-match goals continue directly in-game; no popup/toast here.
		elseif isTournamentContinuation or reason == "Victory" then
			self:_notify("Goal! Match won.", "SUCCESS")
		elseif isChampionCeremony then
			self:_notify("Champion! Trophy ceremony started.", "SUCCESS")
		elseif reason == "Defeat" then
			self:_notify("You lost the match.", "ERROR")
		elseif reason == "ManualExit" then
			self:_notify("Exited match.", "INFO")
		else
			self:_notify("Returned from match.", "INFO")
		end
	end)
end

function MatchController:_handleChampionCeremonyEnded(payload)
	task.spawn(function()
		self._championCeremonyActive = false
		ForceHideLocalCharacterTrophy()
		ForceStopLingeringMatchActionFx()
		task.delay(0.25, ForceStopLingeringMatchActionFx)
		task.delay(0.85, ForceStopLingeringMatchActionFx)
		-- BUG C FIX: A deferred StartActorEffects restore() closure from a Green QTE
		-- fires up to ~1.35s after the QTE, which can outlast the 0.85s sweep above.
		-- This final sweep at 1.5s ensures any late restore() is overridden.
		task.delay(1.5, ForceStopLingeringMatchActionFx)
		if self._championCeremonyEndedEvent then
			self._championCeremonyEndedEvent:Fire(payload)
		end

		if SoccerCharactersController and SoccerCharactersController.ResetCollisionGroups then
			SoccerCharactersController:ResetCollisionGroups()
		end

		RunService.Heartbeat:Wait()
		if MatchPresentationController and MatchPresentationController._finalizeReturnCleanup then
			pcall(function()
				MatchPresentationController:_finalizeReturnCleanup("ChampionCeremonyEnded")
			end)
		end
		self._returningFromMatch = false
		self._returnOverlayStartedAt = nil
		self._transitionBusy = false

		if MatchUIController then
			MatchUIController:FadeFromBlack()
			MatchUIController:EndMatchUi()
		end

		self:_unblockLobbyUiAfterMatch()

		if UIController and UIController.ShowHUD then
			UIController:ShowHUD()
		end

		if MatchCompanionVisualController and MatchCompanionVisualController.RestoreCompanionsBehindOwner then
			pcall(function()
				MatchCompanionVisualController:RestoreCompanionsBehindOwner(LocalPlayer)
			end)
		end

		if CoachesController and CoachesController.RestoreCoachesBehindOwner then
			pcall(function()
				CoachesController:RestoreCoachesBehindOwner(LocalPlayer)
			end)
		end

		self:_enableControls()
		self:_notify("Returned to lobby.", "INFO")
	end)
end

function MatchController:FinalizeTournamentPreviewReturn(reason)
	local reasonText = tostring(reason or "TournamentPreviewClosed")

	task.spawn(function()
		self._currentSessionId = nil
		self._currentPayload = nil
		self._currentStepPayload = nil
		self._inMatch = false
		self._qteOpen = false
		self._championCeremonyActive = false

		self:_cancelMatchIntro(reasonText)
		ForceStopLingeringMatchActionFx()
		task.delay(0.35, ForceStopLingeringMatchActionFx)

		Sound:StopSound("MUSIC_Fight")
		Sound:PlaySound("MUSIC_Background")

		if SoccerCharactersController and SoccerCharactersController.ResetCollisionGroups then
			SoccerCharactersController:ResetCollisionGroups()
		end

		self:_destroyBillboards()

		if MatchUIController then
			if MatchUIController.ClearActiveMatchSession then
				MatchUIController:ClearActiveMatchSession()
			end
			MatchUIController:HideQte()
			MatchUIController:HideExitButton()
			MatchUIController:HideGoalsPill()
			MatchUIController:HideComparePill()
			if MatchUIController.HideBroadcastHud then
				MatchUIController:HideBroadcastHud()
			end
			MatchUIController:SetCompareText("")
			MatchUIController:EndMatchUi({
				PreserveTransitionOverlay = true,
			})
		end

		if MatchPresentationController and MatchPresentationController._finalizeReturnCleanup then
			pcall(function()
				MatchPresentationController:_finalizeReturnCleanup(reasonText)
			end)
		end

		self._returningFromMatch = false
		self._returnOverlayStartedAt = nil
		self._transitionBusy = false

		if MatchUIController then
			MatchUIController:FadeFromBlack()
			MatchUIController:EndMatchUi()
		end

		self:_unblockLobbyUiAfterMatch()

		if UIController and UIController.ShowHUD then
			UIController:ShowHUD()
		end

		if MatchCompanionVisualController and MatchCompanionVisualController.RestoreCompanionsBehindOwner then
			pcall(function()
				MatchCompanionVisualController:RestoreCompanionsBehindOwner(LocalPlayer)
			end)
		end

		if CoachesController and CoachesController.RestoreCoachesBehindOwner then
			pcall(function()
				CoachesController:RestoreCoachesBehindOwner(LocalPlayer)
			end)
		end

		self:_enableControls()
		self:_notify("Returned to lobby.", "INFO")
	end)

	return true
end

function MatchController:_handleStepStarted(stepPayload)
	ForceHideLocalCharacterTrophy()
	self._currentStepPayload = stepPayload
	self._qteOpen = true

	self:_setActiveEnemyBillboard(stepPayload.EnemyStep, stepPayload.Action, stepPayload.EnemyValue)

	if MatchUIController then
		MatchUIController:SetCompareText("")
		MatchUIController:HideComparePill()
		if MatchUIController.ShowActionBanner then
			MatchUIController:ShowActionBanner(stepPayload)
		end
		MatchUIController:ShowQte(stepPayload, function()
			self:_submitCurrentQte()
		end)
	end
end

function MatchController:_handleStepResolved(resultPayload)
	ForceHideLocalCharacterTrophy()
	self._qteOpen = false

	resultPayload = typeof(resultPayload) == "table" and resultPayload or {}
	local isShootResult = IsShootAction(resultPayload.Action)

	if MatchUIController then
		MatchUIController:SetCompareText("")
		MatchUIController:HideComparePill()
		MatchUIController:ShowQteResult(resultPayload)
		if (resultPayload.AwardedGoals or 0) > 0 and not isShootResult then
			MatchUIController:IncrementGoals(resultPayload.AwardedGoals)
		end
		if isShootResult then
			-- Shoot cinematic/result presentation owns the next visual beat.
			-- Do not leave the timing UI up for the generic post-QTE delay.
			MatchUIController:HideQte({
				ResumeBroadcastClock = false,
			})
		end
	end

	if isShootResult then
		return
	end

	task.delay(0.55, function()
		if not self._inMatch then
			return
		end
		if MatchUIController then
			MatchUIController:HideQte()
		end
	end)
end

--| Knit Startup |--
function MatchController:KnitInit()
	self._controls = nil
	self._enemyBillboards = {}
	self._enemyBillboardsByStep = {}
	self._inMatch = false
	self._transitionBusy = false
	self._qteOpen = false
	self._returningFromMatch = false
	self._returnOverlayStartedAt = nil

	self._introToken = 0
	self._introActive = false
	self._introCompleted = false
	self._introSessionId = nil

	self._matchIntroRequestedEvent = Instance.new("BindableEvent")
	self._matchIntroCancelledEvent = Instance.new("BindableEvent")
	self._championCeremonyStartedEvent = Instance.new("BindableEvent")
	self._championCeremonyEndedEvent = Instance.new("BindableEvent")
	self.MatchIntroRequested = self._matchIntroRequestedEvent.Event
	self.MatchIntroCancelled = self._matchIntroCancelledEvent.Event
	self.ChampionCeremonyStarted = self._championCeremonyStartedEvent.Event
	self.ChampionCeremonyEnded = self._championCeremonyEndedEvent.Event
end

function MatchController:KnitStart()
	MatchService = Knit.GetService("MatchService")

	pcall(function()
		NotificationController = Knit.GetController("NotificationController")
	end)
	pcall(function()
		MatchUIController = Knit.GetController("MatchUIController")
	end)
	pcall(function()
		UIController = Knit.GetController("UIController")
	end)
	pcall(function()
		SoccerCharactersController = Knit.GetController("SoccerCharactersController")
	end)
	pcall(function()
		MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
	end)
	pcall(function()
		CoachesController = Knit.GetController("CoachesController")
	end)
	pcall(function()
		MatchPresentationController = Knit.GetController("MatchPresentationController")
	end)

	self:_bindLeaveInput()
	self:_bindQteKeyboardInput()

	MatchService.MatchFeedback:Connect(function(feedbackType, message)
		self:_notify(message, feedbackType)
	end)
	MatchService.MatchTransitionRequested:Connect(function(mode, transitionData)
		self:_handleTransitionRequested(mode, transitionData)
	end)
	MatchService.MatchSessionStarted:Connect(function(payload)
		self:_handleSessionStarted(payload)
	end)
	MatchService.MatchReturnStarted:Connect(function(payload)
		self:_handleReturnStarted(payload)
	end)
	MatchService.MatchReturnAttendance:Connect(function(payload)
		self:_handleReturnAttendance(payload)
	end)
	MatchService.MatchSessionEnded:Connect(function(reason, sessionId)
		self:_handleSessionEnded(reason, sessionId)
	end)
	if MatchService.ChampionCeremonyStarted then
		MatchService.ChampionCeremonyStarted:Connect(function(payload)
			self:_handleChampionCeremonyStarted(payload)
		end)
	end
	if MatchService.ChampionCeremonyEnded then
		MatchService.ChampionCeremonyEnded:Connect(function(payload)
			self:_handleChampionCeremonyEnded(payload)
		end)
	end
	MatchService.MatchStepStarted:Connect(function(stepPayload)
		self:_handleStepStarted(stepPayload)
	end)
	MatchService.MatchStepResolved:Connect(function(resultPayload)
		self:_handleStepResolved(resultPayload)
	end)

	ForceHideLocalCharacterTrophy()
	LocalPlayer.CharacterAdded:Connect(function(character)
		task.defer(function()
			ForceHideLocalCharacterTrophy()
		end)
		character.DescendantAdded:Connect(function(descendant)
			if descendant.Name == "Trophy" or descendant:FindFirstAncestor("Trophy") then
				task.defer(ForceHideLocalCharacterTrophy)
			end
		end)
	end)

	task.spawn(function()
		while true do
			if self._inMatch or self._transitionBusy or self._championCeremonyActive then
				ForceHideLocalCharacterTrophy()
				task.wait(0.25)
			else
				task.wait(2.0)
			end
		end
	end)
end

return MatchController
