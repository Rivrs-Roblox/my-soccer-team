return function(MatchPresentationController, Context)
	local Services = Context.Services
	local RunService = Services.RunService
	local Workspace = Services.Workspace

	local Knit = Context.Knit
	local LocalPlayer = Context.LocalPlayer

	local Constants = Context.Constants
	local Utils = Context.Utils

	local DEFAULT_TIME_SCALE = Constants.DEFAULT_TIME_SCALE
	local ForceModelVisible = Utils.ForceModelVisible

	local MatchShootCinematicDirector = require(script.Parent.MatchShootCinematicDirector)
	local MatchActionFxHelper = require(script.Parent.MatchActionFxHelper)

	local function formatDistance(distance)
		if distance == nil then
			return "nil"
		end

		return string.format("%.2f", distance)
	end


	local function stopLingeringMatchActionEffects(self)
		local stoppedCount = 0

		local function stopIn(root)
			local ok, count = pcall(function()
				return MatchActionFxHelper.StopAllEffectsIn(root)
			end)
			if ok and type(count) == "number" then
				stoppedCount += count
			end
		end

		stopIn(LocalPlayer.Character)
		stopIn(self.PlayerProxy)

		local runtimeFolder = Workspace:FindFirstChild("LocalMatchPresentationRuntime")
		stopIn(runtimeFolder)

		local soccerCharactersController = nil
		pcall(function()
			soccerCharactersController = Knit.GetController("SoccerCharactersController")
		end)

		local instancesFolder = soccerCharactersController and soccerCharactersController.SoccerCharacterInstances
		if instancesFolder then
			for _, model in ipairs(instancesFolder:GetChildren()) do
				if model:IsA("Model") then
					local ownerName = model:GetAttribute("Owner")
					local ownerUserId = model:GetAttribute("OwnerUserId")
					if ownerName == LocalPlayer.Name or ownerUserId == LocalPlayer.UserId then
						stopIn(model)
					end
				end
			end
		end

		local coachesController = nil
		pcall(function()
			coachesController = Knit.GetController("CoachesController")
		end)

		local coachFolder = coachesController and coachesController.CoachInstances
		if coachFolder then
			for _, model in ipairs(coachFolder:GetChildren()) do
				if model:IsA("Model") then
					local ownerName = model:GetAttribute("Owner")
					local ownerUserId = model:GetAttribute("OwnerUserId")
					if ownerName == LocalPlayer.Name or ownerUserId == LocalPlayer.UserId then
						stopIn(model)
					end
				end
			end
		end

		if self.DebugReturnAttendance == true and stoppedCount > 0 then
			print(string.format("[MatchReturn][ClientPresentation] lingering match action FX disabled count=%d", stoppedCount))
		end
	end

	local function restartCharacterAnimateScript(character)
		if not character then
			return false
		end

		local animateScript = character:FindFirstChild("Animate")
		if not animateScript or not animateScript:IsA("LocalScript") then
			return false
		end

		pcall(function()
			animateScript.Disabled = true
		end)

		task.defer(function()
			if animateScript and animateScript.Parent then
				pcall(function()
					animateScript.Disabled = false
				end)
			end
		end)

		task.delay(0.12, function()
			if animateScript and animateScript.Parent then
				pcall(function()
					animateScript.Disabled = false
				end)
			end
		end)

		return true
	end

	local function stopCharacterTracksHard(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return 0
		end

		local stoppedCount = 0
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			stoppedCount += 1
			pcall(function()
				track:AdjustSpeed(1)
				track:Stop(0)
			end)
		end

		return stoppedCount
	end

	local function recoverHumanoidLobbyState(humanoid)
		if not humanoid then
			return
		end

		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true

		pcall(function()
			humanoid:Move(Vector3.zero, false)
		end)

		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)

		task.defer(function()
			if humanoid and humanoid.Parent then
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
		end)
	end

	local function getAnimatorFromModel(model)
		if not model or typeof(model) ~= "Instance" then
			return nil
		end

		return model:FindFirstChildWhichIsA("Animator", true)
	end

	local function stopModelTracksHard(model)
		local animator = getAnimatorFromModel(model)
		if not animator then
			return 0
		end

		local stoppedCount = 0
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			stoppedCount += 1
			pcall(function()
				track:AdjustSpeed(1)
				track:Stop(0)
			end)
		end

		return stoppedCount
	end

	local function restoreModelPhysicsForLobby(model)
		if not model or typeof(model) ~= "Instance" then
			return
		end

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = false

				pcall(function()
					descendant.AssemblyLinearVelocity = Vector3.zero
					descendant.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		recoverHumanoidLobbyState(humanoid)
	end

	local function resetGridAnimationCache(grid)
		if type(grid) ~= "table" then
			return false
		end

		local lastInfo = grid.LastInformation
		if type(lastInfo) ~= "table" then
			lastInfo = {}
			grid.LastInformation = lastInfo
		end

		lastInfo.Animations = nil
		lastInfo.CurrentAnimation = nil
		lastInfo.Animation = nil
		lastInfo.AnimationPosition = nil
		lastInfo.AnimationRotation = nil
		lastInfo.AnimationHeight = nil
		lastInfo.Distance = nil
		lastInfo.Position = nil
		lastInfo.Raycast = nil
		lastInfo.Orientation = nil

		if type(grid.Information) == "table" then
			grid.Information.Arrived = false
		end

		grid.TimeElapsed = 0
		return true
	end

	function MatchPresentationController:_restoreLocalCharacterForLobby()
		local character = LocalPlayer.Character
		if not character then
			return false
		end

		local stoppedTrackCount = stopCharacterTracksHard(character)

		local collisionRecords = self.CutsceneCollisionRecords or {}
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local record = collisionRecords[descendant]
				descendant.LocalTransparencyModifier = self.PlayerHiddenParts[descendant] or 0
				descendant.Anchored = false

				if record then
					pcall(function()
						descendant.CollisionGroup = record.CollisionGroup or "Default"
					end)
					descendant.CanCollide = record.CanCollide == true
					descendant.CanTouch = record.CanTouch ~= false
					descendant.CanQuery = record.CanQuery ~= false
					descendant.Massless = record.Massless == true
				else
					pcall(function()
						descendant.CollisionGroup = "Default"
					end)
					descendant.CanTouch = true
					descendant.CanQuery = true
				end

				pcall(function()
					descendant.AssemblyLinearVelocity = Vector3.zero
					descendant.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		recoverHumanoidLobbyState(humanoid)
		local animateRestarted = restartCharacterAnimateScript(character)

		if self.DebugReturnAttendance == true then
			print(string.format(
				"[MatchReturn][ClientPresentation] local character animation restored stoppedTracks=%d animateRestarted=%s",
				stoppedTrackCount,
				tostring(animateRestarted)
			))
		end

		table.clear(self.PlayerHiddenParts)
		if self.CutsceneCollisionRecords then
			for part in pairs(self.CutsceneCollisionRecords) do
				if part and part:IsDescendantOf(character) then
					self.CutsceneCollisionRecords[part] = nil
				end
			end
		end
		return true
	end

	function MatchPresentationController:_resetLocalSoccerCharactersForLobby(skipPivots: boolean?)
		local ok, soccerCharactersController = pcall(function()
			return Knit.GetController("SoccerCharactersController")
		end)

		if not ok or not soccerCharactersController then
			return 0, 0
		end

		local resetGridCount = 0
		local stoppedTrackCount = 0
		local seenModels = {}

		local session = soccerCharactersController.SoccerCharactersInSession
			and soccerCharactersController.SoccerCharactersInSession[LocalPlayer]

		if type(session) == "table" then
			if not skipPivots and soccerCharactersController.RestorePreMatchPivots then
				soccerCharactersController:RestorePreMatchPivots(LocalPlayer)
			end

			for _, grid in pairs(session) do
				if resetGridAnimationCache(grid) then
					resetGridCount += 1
				end

				local model = grid.Model
				if typeof(model) == "Instance" and model:IsA("Model") then
					seenModels[model] = true
					stoppedTrackCount += stopModelTracksHard(model)
					restoreModelPhysicsForLobby(model)
				end
			end
		end

		local instancesFolder = soccerCharactersController.SoccerCharacterInstances
		if instancesFolder then
			for _, model in ipairs(instancesFolder:GetChildren()) do
				if model:IsA("Model") then
					local ownerName = model:GetAttribute("Owner")
					local ownerUserId = model:GetAttribute("OwnerUserId")

					if ownerName == LocalPlayer.Name or ownerUserId == LocalPlayer.UserId then
						if not seenModels[model] then
							stoppedTrackCount += stopModelTracksHard(model)
							restoreModelPhysicsForLobby(model)
							seenModels[model] = true
						end
					end
				end
			end
		end

		task.defer(function()
			if type(session) == "table" then
				for _, grid in pairs(session) do
					resetGridAnimationCache(grid)
				end
			end
		end)

		if self.DebugReturnAttendance == true then
			print(string.format(
				"[MatchReturn][ClientPresentation] soccer character animation cache reset grids=%d stoppedTracks=%d",
				resetGridCount,
				stoppedTrackCount
			))
		end

		return resetGridCount, stoppedTrackCount
	end

	function MatchPresentationController:_printReturnAttendance(reason)
		if self.DebugReturnAttendance ~= true then
			return
		end

		local character = LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		print(string.format(
			"[MatchReturn][ClientPresentation] player character=%s root=%s anchored=%s humanoid=%s reason=%s",
			tostring(character ~= nil),
			tostring(rootPart ~= nil),
			tostring(rootPart and rootPart.Anchored == true or false),
			tostring(humanoid ~= nil),
			tostring(reason or "MatchSessionEnded")
		))

		if self.PlayerProxy then
			print("[MatchReturn][ClientPresentation][WARN] PlayerProxy still exists after cleanup:", self.PlayerProxy:GetFullName())
		end

		if self.MatchCompanionVisualController and self.MatchCompanionVisualController.GetOwnedCompanionModels then
			local companions = self.MatchCompanionVisualController:GetOwnedCompanionModels(LocalPlayer)
			for index, companionModel in ipairs(companions) do
				local modelRoot = companionModel and companionModel:FindFirstChild("HumanoidRootPart")
				local distance = nil
				if rootPart and modelRoot then
					distance = (modelRoot.Position - rootPart.Position).Magnitude
				end

				print(string.format(
					"[MatchReturn][ClientPresentation] companionIndex=%d model=%s root=%s anchored=%s distanceToPlayer=%s",
					index,
					companionModel and companionModel.Name or "nil",
					tostring(modelRoot ~= nil),
					tostring(modelRoot and modelRoot.Anchored == true or false),
					formatDistance(distance)
				))
			end
		end
	end

	function MatchPresentationController:_finalizeReturnCleanup(reason)
		if self._resumeKnownMatchRigAnimations then
			self:_resumeKnownMatchRigAnimations()
		end
		stopLingeringMatchActionEffects(self)
		self:_destroyPlayerProxy()
		self:_restoreLocalCharacterForLobby()
		self:_resetLocalSoccerCharactersForLobby()

		if self.MatchKeeperPresentationController and self.MatchKeeperPresentationController.StopAll then
			pcall(function()
				self.MatchKeeperPresentationController:StopAll()
			end)
		end

		if self.MatchBattleCameraController and self.MatchBattleCameraController._restoreCamera then
			pcall(function()
				self.MatchBattleCameraController:_restoreCamera()
			end)
		end

		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()

		self:_destroyPlayerProxy()
		self:_restoreLocalCharacterForLobby()
		self:_resetLocalSoccerCharactersForLobby()

		task.defer(function()
			RunService.Heartbeat:Wait()
			self:_restoreLocalCharacterForLobby()
			self:_resetLocalSoccerCharactersForLobby()
			stopLingeringMatchActionEffects(self)
		end)

		task.delay(0.75, function()
			stopLingeringMatchActionEffects(self)
		end)

		self:_printReturnAttendance(reason)
	end

	function MatchPresentationController:_beginSession(payload)
		local serverSpawnCFrame = payload and payload.PlayerSpawnCFrame
		self.CurrentPlayerSpawnRootCFrame = if typeof(serverSpawnCFrame) == "CFrame"
			then serverSpawnCFrame
			else nil

		-- Since streaming (StreamingEnabled) or replication latency can delay
		-- the creation/streaming of map instances on the client, wait/poll
		-- for the spawnPart to exist up to a reasonable timeout before initializing.
		local MatchSceneQuery = Context.MatchSceneQuery
		if self.CurrentPlayerSpawnRootCFrame == nil and MatchSceneQuery and MatchSceneQuery.GetPlayerSpawn then
			local startTime = os.clock()
			while os.clock() - startTime < 4.0 do
				local spawnPart = MatchSceneQuery.GetPlayerSpawn()
				if spawnPart then
					break
				end
				RunService.RenderStepped:Wait()
			end
		end

		self.CurrentSessionId = tostring(payload and payload.SessionId or "")
		if self._clearIntroVisualReady then
			self:_clearIntroVisualReady(self.CurrentSessionId)
		end
		if self._destroyStalePlayerProxies then
			self:_destroyStalePlayerProxies(nil)
		end

		self.IsApproachBusy = false
		self.IsPostActionBusy = false
		self.LastPreparedPreQteStepIndex = 0
		self.LastCompletedPostActionStepIndex = 0
		self.CurrentSessionWins = 0
		self.CurrentSessionGoals = 0
		self.DebugReturnAttendance = self.DebugReturnAttendance == true

		self:_setTimeScale(DEFAULT_TIME_SCALE)
		stopLingeringMatchActionEffects(self)
		if self._resumeKnownMatchRigAnimations then
			self:_resumeKnownMatchRigAnimations()
		end

		if self.ActiveShooterResultAnimationCleanup then
			self.ActiveShooterResultAnimationCleanup()
			self.ActiveShooterResultAnimationCleanup = nil
		end
		self.ActiveShooterResultTrack = nil

		if MatchShootCinematicDirector and MatchShootCinematicDirector.Stop then
			MatchShootCinematicDirector.Stop()
		end

		self.ActiveActorSlot = nil
		self.ActiveEnemyRuntimeSlot = nil
		self.CurrentPresentationStepIndex = 0
		self.IdleEnemyMotionToken = 0
		self.AllyPatrolMotionToken = 0
		self.SupportMotionToken = 0
		self.CutsceneCollisionGroupReady = false
		table.clear(self.DefeatedEnemyRecoveryTokens)
		self.QteFreezeToken = 0
		self.EmbeddedBallGuardToken = (self.EmbeddedBallGuardToken or 0) + 1
		self.PostShotLockToken = 0
		self.ShootCinematicFreezeToken = (self.ShootCinematicFreezeToken or 0) + 1
		self.IsShootCinematicFrozen = false
		self.ActiveShootSessionLock = nil
		self.ShooterResultAnimationToken = (self.ShooterResultAnimationToken or 0) + 1

		self:_ensureRuntimeFolder()
		if self._debugSpawnHandoff then
			self:_debugSpawnHandoff("begin-session-before-proxy")
		end
		self:_ensurePlayerProxy()
		if self._resetPlayerProxyToSpawn then
			self:_resetPlayerProxyToSpawn()
		end
		if self._debugSpawnHandoff then
			self:_debugSpawnHandoff("begin-session-after-proxy-reset")
		end
		self.ActiveActorSlot = 1
		self:_hideNonCarrierEmbeddedBalls(self.ActiveActorSlot)

		if self.MatchBallController then
			self.MatchBallController:BeginMatchSession({
				StartHidden = payload and payload.IntroData ~= nil,
			})
		end

		if self.MatchBattleCameraController then
			self.MatchBattleCameraController:ApplyMatchIntroCamera()
		end

		if self.MatchActorRuntimeController then
			self.MatchActorRuntimeController:BeginLocalMatchIsolation(LocalPlayer, payload and payload.CompanionPivotOrder)
		end
		if self._preloadShootAnimationAssets then
			self:_preloadShootAnimationAssets()
		end

		if self._startMatchActorLookAt then
			self:_startMatchActorLookAt(self.CurrentSessionId)
		end

		self:_startEmbeddedBallVisualGuard(self.CurrentSessionId)
		self:_refreshCutsceneCollisionGroups()

		if not (payload and payload.IntroData) then
			self:_animateIdleAllies(self.CurrentSessionId)
		end

		if self.UIController then
			self.UIController:RemoveHUD({ ignoreTopFrame = false })
		end

		local readySessionId = self.CurrentSessionId
		if self:_isSessionActive(readySessionId) and self._stabilizePlayerProxy then
			self:_stabilizePlayerProxy()
		end

		if self:_isSessionActive(readySessionId) then
			if self.PlayerProxy then
				if self._debugSpawnHandoff then
					self:_debugSpawnHandoff("intro-ready-before-force-visible", self.PlayerProxy)
				end
				ForceModelVisible(self.PlayerProxy)
				if self._debugSpawnHandoff then
					self:_debugSpawnHandoff("intro-ready-after-force-visible", self.PlayerProxy)
				end
			end
			self:_setCharacterHidden(true)
		end

		if self:_isSessionActive(readySessionId) and self._markIntroVisualReady then
			if self._debugSpawnHandoff then
				self:_debugSpawnHandoff("intro-ready-mark")
			end
			self:_markIntroVisualReady(readySessionId)
		end
	end

	function MatchPresentationController:_endSession(reason)
		local reasonText = tostring(reason or "")
		local isTournamentContinuation = reasonText == "VictoryContinuation"
		local isChampionCeremony = reasonText == "ChampionCeremony"
		local isInPlaceTournamentEnd = isTournamentContinuation or isChampionCeremony

		if isInPlaceTournamentEnd and self.MatchUIController then
			pcall(function()
				local statusText = if isChampionCeremony then "" else "Next Round..."
				if self.MatchUIController.CutToBlack then
					self.MatchUIController:CutToBlack(statusText)
				elseif self.MatchUIController.FadeToBlack then
					self.MatchUIController:FadeToBlack(statusText)
				end
			end)
			task.wait(0.15)
		end

		self:_clearIntroVisualReady(nil)
		self.CurrentSessionId = nil
		self.CurrentPlayerSpawnRootCFrame = nil

		self:_resumeActorsAfterPreQte()
		self:_setTimeScale(DEFAULT_TIME_SCALE)
		if self._resumeKnownMatchRigAnimations then
			self:_resumeKnownMatchRigAnimations()
		end

		if self.ActiveShooterResultAnimationCleanup then
			self.ActiveShooterResultAnimationCleanup()
			self.ActiveShooterResultAnimationCleanup = nil
		end
		self.ActiveShooterResultTrack = nil

		if MatchShootCinematicDirector and MatchShootCinematicDirector.Stop then
			MatchShootCinematicDirector.Stop()
		end

		if self.MatchActorRuntimeController and self.ActiveActorSlot then
			pcall(function()
				self.MatchActorRuntimeController:SetSlotControlOverride(LocalPlayer, tonumber(self.ActiveActorSlot), false)
			end)
		end

		self.ActiveActorSlot = nil
		self.ActiveEnemyRuntimeSlot = nil
		self.CurrentPresentationStepIndex = 0
		self.IsApproachBusy = false
		self.IsPreQteFrozen = false
		self.QteLiveRunnerSlot = nil
		self.QteLiveShadowEnemySlot = nil
		self.IdleEnemyMotionToken += 1
		self.AllyPatrolMotionToken += 1
		self.DribbleContinuationToken = (self.DribbleContinuationToken or 0) + 1
		self.DribbleContinuationOwnerSlot = nil
		self.DribbleContinuationSessionId = nil
		if self.ForwardRunnerTokens then
			for runnerSlot in pairs(self.ForwardRunnerTokens) do
				self.ForwardRunnerTokens[runnerSlot] = (self.ForwardRunnerTokens[runnerSlot] or 0) + 1
			end
		end
		if self.ActiveForwardRunners then
			table.clear(self.ActiveForwardRunners)
		end
		if self.PassPressTokens then
			for enemyModel in pairs(self.PassPressTokens) do
				self.PassPressTokens[enemyModel] = (self.PassPressTokens[enemyModel] or 0) + 1
			end
		end
		table.clear(self.DefeatedEnemyRecoveryTokens)
		self.QteFreezeToken = (self.QteFreezeToken or 0) + 1
		self.EmbeddedBallGuardToken = (self.EmbeddedBallGuardToken or 0) + 1
		self.PostShotLockToken = (self.PostShotLockToken or 0) + 1
		self.ShootCinematicFreezeToken = (self.ShootCinematicFreezeToken or 0) + 1
		self.IsShootCinematicFrozen = false
		self.ActiveShootSessionLock = nil
		self.ShooterResultAnimationToken = (self.ShooterResultAnimationToken or 0) + 1

		self:_stopSupportMotion()

		if self._stopMatchActorLookAt then
			self:_stopMatchActorLookAt("MatchSessionEnded")
		end

		self:_clearKeeperFocusWorldPosition()
		self:_destroyPlayerProxy()
		if isInPlaceTournamentEnd then
			self:_restoreLocalCharacterForLobby()
		end
		self:_restoreEmbeddedBallVisuals()
		self:_stopAllRigAnimations()
		stopLingeringMatchActionEffects(self)

		if self.MatchBallController then
			self.MatchBallController:EndMatchSession({
				ResetMode = "DeferredSilent",
				ResetDelay = 0.35,
			})
		end

		if self.MatchActorRuntimeController then
			self.MatchActorRuntimeController:EndLocalMatchIsolation(LocalPlayer)
		end

		stopLingeringMatchActionEffects(self)

		if not isInPlaceTournamentEnd then
			self:_finalizeReturnCleanup("MatchSessionEnded")

			if self.UIController then
				self.UIController:ShowHUD()
			end
		else
			if isChampionCeremony then
				self:_resetLocalSoccerCharactersForLobby(true)
			end

			-- Tournament continuation stays inside the match world and immediately
			-- opens the bracket interstitial. Do not run lobby-only companion grid
			-- reset here; its deferred reset can race with the next MatchSessionStarted
			-- and make companion actors/keeper setup disappear in the next round.
			if self.UIController then
				self.UIController:RemoveHUD({ ignoreTopFrame = false })
			end
		end
	end

	function MatchPresentationController:_resolveDependencies()
		Context.DepsResolver.Resolve(self, Context)
	end

	function MatchPresentationController:_bindMatchSignals()
		self.MatchService.MatchSessionStarted:Connect(function(payload)
			self:_beginSession(payload)
		end)

		self.MatchService.MatchSessionEnded:Connect(function(reason, sessionId)
			local endedSessionId = tostring(sessionId or "")
			if endedSessionId ~= "" and self.CurrentSessionId ~= nil and tostring(self.CurrentSessionId) ~= endedSessionId then
				return
			end

			self:_endSession(reason)
		end)

		if self.MatchService.ChampionCeremonyEnded then
			self.MatchService.ChampionCeremonyEnded:Connect(function(payload)
				self:_finalizeReturnCleanup("ChampionCeremonyEnded")
				if self.UIController then
					self.UIController:ShowHUD()
				end
			end)
		end

		self.MatchService.MatchApproachStarted:Connect(function(payload)
			if self:_isSessionActive(payload.SessionId) then
				self:_handleApproachStarted(payload)
			end
		end)

		self.MatchService.MatchStepStarted:Connect(function(payload)
			if self:_isSessionActive(payload.SessionId) then
				self:_handleStepStarted(payload)
			end
		end)

		self.MatchService.MatchStepResolved:Connect(function(payload)
			if self:_isSessionActive(payload.SessionId) then
				self:_handleStepResolved(payload)
			end
		end)

		LocalPlayer.CharacterRemoving:Connect(function()
			self:_endSession()
		end)
	end

	function MatchPresentationController:KnitStart()
		self:_resolveDependencies()
		self:_bindMatchSignals()
	end
end
