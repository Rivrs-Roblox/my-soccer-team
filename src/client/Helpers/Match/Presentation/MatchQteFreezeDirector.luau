return function(MatchPresentationController, Context)
	local RunService = Context.Services.RunService
	local LocalPlayer = Context.LocalPlayer

	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath
	local MatchBallConfig = Context.MatchBallConfig

	local Constants = Context.Constants
	local Utils = Context.Utils

	local THREAT_ZONE_FALLBACK_RADIUS = Constants.THREAT_ZONE_FALLBACK_RADIUS
	local QTE_TRIGGER_DISTANCE = Constants.QTE_TRIGGER_DISTANCE
	local QTE_TRIGGER_DISTANCE_BUFFER = Constants.QTE_TRIGGER_DISTANCE_BUFFER
	local QTE_FORCE_BOUNDARY_BUFFER = Constants.QTE_FORCE_BOUNDARY_BUFFER
	local QTE_FORCE_BOUNDARY_STEP3_BUFFER = Constants.QTE_FORCE_BOUNDARY_STEP3_BUFFER
	local QTE_FORCE_BOUNDARY_SETTLE_DISTANCE = Constants.QTE_FORCE_BOUNDARY_SETTLE_DISTANCE
	local QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET = Constants.QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET
	local PRESSURE_SWITCH_DISTANCE = Constants.PRESSURE_SWITCH_DISTANCE
	local PRESSURE_SWITCH_DISTANCE_STEP_1 = Constants.PRESSURE_SWITCH_DISTANCE_STEP_1
	local DEFAULT_TIME_SCALE = Constants.DEFAULT_TIME_SCALE or 1.0
	local QTE_SLOWMO_TIME_SCALE = Constants.QTE_SLOWMO_TIME_SCALE or 0.1
	local QTE_SLOWMO_ANIMATION_SPEED = Constants.QTE_SLOWMO_ANIMATION_SPEED or QTE_SLOWMO_TIME_SCALE

	local GetRootPart = Utils.GetRootPart
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook

	local PRE_QTE_READY_FRAMES = 2

	local PRE_QTE_ACTION_POSES = {
		Shoot = {
			-- Shoot cinematic owns the real Shoot animation after QTE click.
			-- Pre-QTE must not sample/play Shoot because it causes a fast kick before slowmo.
			SkipActionPose = true,
			Animations = { "Run" },
			PoseTime = 0,
			FadeTime = 0.05,
			BallOffset = MatchBallConfig.ShootOffset,
			EnemyAnimation = "Run",
			EnemySpeed = 1.0,
			CameraHook = "OnShootAnticipation",
			KeeperReady = true,
		},

		Pass = {
			-- Pass resolve owns the real kick. Pre-QTE should not show a slowmo kick first.
			SkipActionPose = true,
			Animations = { "Run" },
			PoseTime = 0,
			FadeTime = 0.05,
			BallOffset = MatchBallConfig.PassOffset,
			EnemyAnimation = "Run",
			EnemySpeed = 1.0,
		},

		Dribble = {
			SkipActionPose = true,
			Animations = { "Run" },
			PoseTime = 0,
			FadeTime = 0.02,
			BallOffset = MatchBallConfig.DribbleOffset,
			EnemyAnimation = "Run",
			EnemySpeed = 1.0,
		},

		Default = {
			Animations = { "Run" },
			PoseTime = 0.12,
			FadeTime = 0.02,
			BallOffset = MatchBallConfig.ReceiveOffset,
			EnemyAnimation = "Run",
			EnemySpeed = 1.0,
		},
	}

	local SHOOT_ANIMATION_NAMES = {
		["Shoot"] = true,
		["Shoot - Training"] = true,
		["Shoot - Penalty"] = true,
		["Shoot - Special"] = true,
	}

	local ACTION_POSE_ANIMATION_NAMES = {
		["Pass"] = true,
		["Shoot"] = true,
		["Shoot - Training"] = true,
		["Shoot - Penalty"] = true,
		["Shoot - Special"] = true,
	}

	local function getPreQtePoseKey(payload)
		if not payload then
			return nil
		end

		return table.concat({
			tostring(payload.SessionId),
			tostring(payload.StepIndex),
			tostring(payload.ActorSlot),
			tostring(payload.Action),
		}, "::")
	end

	local function getActionPoseConfig(actionName)
		return PRE_QTE_ACTION_POSES[actionName] or PRE_QTE_ACTION_POSES.Default
	end

	local function shouldSkipActionPose(payload)
		local actionConfig = getActionPoseConfig(payload and payload.Action)
		return actionConfig and actionConfig.SkipActionPose == true
	end

	local function safeSetTrackTimePosition(track, timePosition)
		if not track then
			return
		end

		local targetTime = tonumber(timePosition) or 0
		local length = tonumber(track.Length) or 0

		if length > 0.05 then
			targetTime = math.clamp(targetTime, 0, math.max(length - 0.03, 0))
		else
			targetTime = math.max(targetTime, 0)
		end

		pcall(function()
			track.TimePosition = targetTime
		end)
	end

	local function stopShootTracks(model)
		if not model then
			return
		end

		local animator = model:FindFirstChildWhichIsA("Animator", true)
		if not animator then
			return
		end

		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			local animation = track.Animation
			local animationName = animation and animation.Name or ""

			if SHOOT_ANIMATION_NAMES[animationName] then
				track:Stop(0)
			end
		end
	end

	local function stopActionPoseTracks(model)
		if not model then
			return
		end

		local animator = model:FindFirstChildWhichIsA("Animator", true)
		if not animator then
			return
		end

		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			local animation = track.Animation
			local animationName = animation and animation.Name or ""

			if ACTION_POSE_ANIMATION_NAMES[animationName] or animationName == "Idle" or animationName == "idle" or animationName == "Animation1" then
				track:Stop(0)
			end
		end
	end

	function MatchPresentationController:_hideAllEmbeddedMatchBalls()
		if self.PlayerProxy then
			self:_setEmbeddedBallVisualsHidden(self.PlayerProxy, true)
		end

		for slotNumber = 1, 4 do
			local actorModel = self:_getControlledActorModel(slotNumber)
			if actorModel then
				self:_setEmbeddedBallVisualsHidden(actorModel, true)
			end
		end

		if self._forEachEnemyModel then
			self:_forEachEnemyModel(function(enemyModel)
				if enemyModel then
					self:_setEmbeddedBallVisualsHidden(enemyModel, true)
				end
			end)
		end
	end

	function MatchPresentationController:_isActorInsideThreatZone(stepIndex, actorPosition)
		if not actorPosition then
			return false
		end

		local zoneArea = MatchZoneQuery.GetZoneArea(stepIndex)
		if zoneArea then
			local localPos = zoneArea.CFrame:PointToObjectSpace(actorPosition)

			return math.abs(localPos.X) <= ((zoneArea.Size.X * 0.5) + 1.0)
				and math.abs(localPos.Z) <= ((zoneArea.Size.Z * 0.5) + 1.0)
		end

		local fallbackPart = MatchZoneQuery.GetCarrierPoint(stepIndex)
			or MatchZoneQuery.GetEnemyApproachPoint(stepIndex)

		return fallbackPart ~= nil
			and GetFlatDistance(actorPosition, fallbackPart.Position) <= THREAT_ZONE_FALLBACK_RADIUS
	end

	function MatchPresentationController:_isConfrontationClose(actorPosition, enemyPosition, triggerDistance)
		if not actorPosition or not enemyPosition then
			return false
		end

		return GetFlatDistance(actorPosition, enemyPosition) <= (triggerDistance or QTE_TRIGGER_DISTANCE)
	end

	function MatchPresentationController:_getQteForceBoundaryBuffer(stepIndex)
		if tonumber(stepIndex) == 3 then
			return QTE_FORCE_BOUNDARY_STEP3_BUFFER
		end

		return QTE_FORCE_BOUNDARY_BUFFER
	end

	function MatchPresentationController:_isBoundaryQteBlockerReady(payload, actorPosition)
		if not payload or not actorPosition then
			return false
		end

		local stepIndex = tonumber(payload.StepIndex) or 1
		if stepIndex ~= 3 then
			return true
		end

		local activeEnemyModel = nil
		if self._getActiveEnemyModelForPayload then
			activeEnemyModel = self:_getActiveEnemyModelForPayload(payload)
		end

		local enemyRoot = GetRootPart(activeEnemyModel)
		if not enemyRoot then
			return false
		end

		local enemyPos = GetGroundedPosition(enemyRoot.Position, activeEnemyModel)
		local maxBoundaryDistance = math.max(QTE_TRIGGER_DISTANCE + QTE_TRIGGER_DISTANCE_BUFFER + 4.5, 10.5)

		return GetFlatDistance(actorPosition, enemyPos) <= maxBoundaryDistance
	end

	function MatchPresentationController:_shouldForceQteByZoneBoundary(payload, actorPosition)
		if not payload or not actorPosition then
			return false
		end

		if payload.Action == "Shoot" then
			return false
		end

		local stepIndex = tonumber(payload.StepIndex) or 1
		if stepIndex < 1 or stepIndex > 4 then
			return false
		end

		local nextStepIndex = math.clamp(stepIndex + 1, 1, 5)
		local currentMarker = MatchZoneQuery.GetCarrierPoint(stepIndex)
			or MatchZoneQuery.GetZoneArea(stepIndex)

		local nextMarker = MatchZoneQuery.GetCarrierPoint(nextStepIndex)
			or MatchZoneQuery.GetZoneArea(nextStepIndex)
			or MatchZoneQuery.GetGoalTarget()

		local forceLine = nil
		if MatchZoneQuery.GetQteForceLine then
			forceLine = MatchZoneQuery.GetQteForceLine(stepIndex)
		elseif MatchZoneQuery.GetExitPoint then
			forceLine = MatchZoneQuery.GetExitPoint(stepIndex)
		end

		if not currentMarker or (not nextMarker and not forceLine) then
			return false
		end

		local origin = currentMarker.Position
		local forward = nil

		if nextMarker then
			forward = MatchMotionMath.GetFlatDirection(origin, nextMarker.Position)
		end

		if not forward or forward.Magnitude <= 0.001 then
			forward = self:_getZoneForward(stepIndex, actorPosition)
		end

		if not forward or forward.Magnitude <= 0.001 then
			return false
		end

		local boundaryPosition = nil
		if forceLine then
			boundaryPosition = forceLine.Position
		else
			boundaryPosition = nextMarker.Position - (forward.Unit * self:_getQteForceBoundaryBuffer(stepIndex))
		end

		local actorProgress = Vector3.new(actorPosition.X - origin.X, 0, actorPosition.Z - origin.Z):Dot(forward.Unit)
		local boundaryProgress = Vector3.new(boundaryPosition.X - origin.X, 0, boundaryPosition.Z - origin.Z):Dot(forward.Unit)

		if boundaryProgress <= 1 or actorProgress + 0.05 < boundaryProgress then
			return false
		end

		if forceLine then
			return true
		end

		return self:_isBoundaryQteBlockerReady(payload, actorPosition)
	end

	function MatchPresentationController:_buildForcedQteEnemyPosition(payload, actorModel, enemyModel, actorPosition, enemyPosition)
		if not actorPosition then
			return enemyPosition
		end

		local goalTarget = MatchZoneQuery.GetGoalTarget() or MatchZoneQuery.GetSaveTarget()
		local forward = nil

		if goalTarget then
			forward = MatchMotionMath.GetFlatDirection(actorPosition, goalTarget.Position)
		end

		if not forward or forward.Magnitude <= 0.001 then
			forward = MatchMotionMath.GetFlatDirection(enemyPosition or actorPosition, actorPosition)
		end

		if not forward or forward.Magnitude <= 0.001 then
			forward = self:_getZoneForward(payload and payload.StepIndex or 1, actorPosition)
		end

		if not forward or forward.Magnitude <= 0.001 then
			forward = Vector3.new(0, 0, -1)
		end

		local lateral = forward.Unit:Cross(Vector3.new(0, 1, 0))
		if lateral.Magnitude <= 0.001 then
			lateral = Vector3.new(1, 0, 0)
		else
			lateral = lateral.Unit
		end

		local sideSign = 0
		local activeEnemyRuntimeSlot = tonumber(self.ActiveEnemyRuntimeSlot)

		if activeEnemyRuntimeSlot == 3 then
			sideSign = -1
		elseif activeEnemyRuntimeSlot == 4 then
			sideSign = 1
		end

		local forcedEnemyPos = actorPosition
			+ (forward.Unit * QTE_FORCE_BOUNDARY_SETTLE_DISTANCE)
			+ (lateral * sideSign * QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET)

		return GetGroundedPosition(forcedEnemyPos, enemyModel)
	end

	function MatchPresentationController:_shouldReleaseEnemyPressure(payload, actorPosition, enemyModel)
		if not payload or not actorPosition then
			return false
		end

		if payload.Action == "Shoot" then
			return true
		end

		local stepIndex = tonumber(payload.StepIndex) or 1

		if stepIndex == 1 then
			if self:_isActorInsideThreatZone(stepIndex, actorPosition) then
				return true
			end

			local carrierPoint = MatchZoneQuery.GetCarrierPoint(1)
			if carrierPoint and GetFlatDistance(actorPosition, carrierPoint.Position) <= PRESSURE_SWITCH_DISTANCE_STEP_1 then
				return true
			end

			return false
		end

		if self:_isActorInsideThreatZone(stepIndex, actorPosition) then
			return true
		end

		local enemyRoot = GetRootPart(enemyModel)
		if enemyRoot then
			local enemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)

			if GetFlatDistance(actorPosition, enemyPos) <= PRESSURE_SWITCH_DISTANCE then
				return true
			end
		end

		return false
	end

	function MatchPresentationController:_shouldKeepModelLiveDuringQte(model)
		return false
	end

	function MatchPresentationController:_invalidateAllAsyncMotionForQte()
		self.QteLiveRunnerSlot = nil
		self.QteLiveShadowEnemySlot = nil
		self.IdleEnemyMotionToken = (self.IdleEnemyMotionToken or 0) + 1
		self.AllyPatrolMotionToken = (self.AllyPatrolMotionToken or 0) + 1

		if self._cancelDribbleContinuation then
			self:_cancelDribbleContinuation("qte-freeze")
		else
			self.DribbleContinuationToken = (self.DribbleContinuationToken or 0) + 1
		end

		if self._stopSupportMotion then
			self:_stopSupportMotion()
		end

		if self.ForwardRunnerTokens then
			for runnerSlot in pairs(self.ForwardRunnerTokens) do
				self.ForwardRunnerTokens[runnerSlot] += 1
			end
		end

		if self.PassPressTokens then
			for enemyModel in pairs(self.PassPressTokens) do
				self.PassPressTokens[enemyModel] += 1
			end
		end

		if self.DefeatedEnemyRecoveryTokens then
			table.clear(self.DefeatedEnemyRecoveryTokens)
		end

		if self._resetEnemyMotionLocks then
			self:_resetEnemyMotionLocks()
		end
	end

	function MatchPresentationController:_resumeFrozenRigAnimations()
		for model in pairs(self.FrozenRigModels) do
			if model and model.Parent then
				self:_resumeRigAnimation(model)
				local animate = model:FindFirstChild("Animate")
				if animate and animate:IsA("BaseScript") then
					animate.Enabled = true
				end
			end
		end

		table.clear(self.FrozenRigModels)
	end

	function MatchPresentationController:_startQteFreezeAnimationGuard()
		self.QteFreezeToken = (self.QteFreezeToken or 0) + 1
		local freezeToken = self.QteFreezeToken

		task.spawn(function()
			while self.IsPreQteFrozen
				and freezeToken == self.QteFreezeToken
				and self.CurrentSessionId ~= nil
			do
				for model in pairs(self.FrozenRigModels) do
					if model and model.Parent then
						self:_pauseRigAnimation(model, QTE_SLOWMO_ANIMATION_SPEED)
					end
				end

				self:_forEachEnemyModel(function(enemyModel)
					if enemyModel and enemyModel.Parent and not self:_shouldKeepModelLiveDuringQte(enemyModel) then
						self.FrozenRigModels[enemyModel] = true
						self:_pauseRigAnimation(enemyModel, QTE_SLOWMO_ANIMATION_SPEED)
					end
				end)

				RunService.RenderStepped:Wait()
			end
		end)
	end

	local function debugPrintPlayingAnimations(model, prefix)
		if not model then return end
		local animator = model:FindFirstChildWhichIsA("Animator", true)
		if not animator then return end
		local tracks = animator:GetPlayingAnimationTracks()
		print("----- [QTE ANIM DEBUG]", prefix, model.Name, "-----")
		if #tracks == 0 then
			print("   -> (No tracks playing)")
		end
		for _, track in ipairs(tracks) do
			local animName = track.Animation and track.Animation.Name or "Unknown"
			print(string.format("   -> Anim: %s | Speed: %.2f | Weight: %.2f | TimePos: %.2f | Priority: %s",
				animName, track.Speed, track.WeightCurrent, track.TimePosition, tostring(track.Priority)))
		end
	end

	function MatchPresentationController:_freezeActorsForPreQte(actorModel, enemyModel, payload)
		if self.IsPreQteFrozen then
			return
		end

		local posePayload = payload or self.PendingPreQtePosePayload
		local poseActorModel = actorModel or self.PendingPreQtePoseActorModel
		local poseEnemyModel = enemyModel or self.PendingPreQtePoseEnemyModel

		self:_invalidateAllAsyncMotionForQte()

		if posePayload and poseActorModel and not shouldSkipActionPose(posePayload) then
			self:_applyPreQteHoldPose(posePayload, poseActorModel, poseEnemyModel, true)
		elseif posePayload and poseActorModel and shouldSkipActionPose(posePayload) then
			local actionConfig = getActionPoseConfig(posePayload.Action)
			stopActionPoseTracks(poseActorModel)
			
			local animToPlay = actionConfig.Animations[1] or "Run"
			local runTrack = self:_playRigAnimation(poseActorModel, animToPlay, 1.0, 0)
			
			if runTrack and animToPlay == "Run" then
				pcall(function()
					runTrack.TimePosition = math.random() * 0.4 + 0.1
				end)
			end
			if poseEnemyModel then
				stopActionPoseTracks(poseEnemyModel)
				local enemyRuntimeSlot = self._getEnemyRuntimeSlotFromModel and self:_getEnemyRuntimeSlotFromModel(poseEnemyModel)
				local isKeeper = enemyRuntimeSlot == Constants.GOALKEEPER_RUNTIME_SLOT
					or poseEnemyModel.Name == "GoalKeeper"
					or poseEnemyModel.Name == "Keeper"
				self:_playRigAnimation(
					poseEnemyModel,
					isKeeper and "Idle" or (actionConfig.EnemyAnimation or "Run"),
					isKeeper and 1.0 or (actionConfig.EnemySpeed or 1.0),
					0
				)
			end
		end

		-- The passer model's animation will be handled by freezeModel loop below.

		self.IsPreQteFrozen = true

		table.clear(self.FrozenRigModels)

		local function freezeModel(model, isTeammate)
			if self:_shouldKeepModelLiveDuringQte(model) then
				return
			end

			if model and model.Parent and not self.FrozenRigModels[model] then
				local animate = model:FindFirstChild("Animate")
				if animate and animate:IsA("BaseScript") then
					animate.Enabled = false
				end
				
				local isKeeper = false
				if self._getEnemyRuntimeSlotFromModel then
					isKeeper = self:_getEnemyRuntimeSlotFromModel(model) == Constants.GOALKEEPER_RUNTIME_SLOT
				end
				if not isKeeper and (model.Name == "GoalKeeper" or model.Name == "Keeper") then
					isKeeper = true
				end

				if isKeeper then
					stopActionPoseTracks(model)
					self:_playRigAnimation(model, "Idle", 1.0, 0)
				elseif model ~= poseActorModel and model ~= poseEnemyModel then
					stopActionPoseTracks(model)
					local runSpeed = isTeammate and 1 or 1
					local runTrack = self:_playRigAnimation(model, "Run", runSpeed, 0)
					if runTrack then
						pcall(function()
							runTrack.TimePosition = math.random() * 0.4 + 0.1
						end)
					end
				end

				self.FrozenRigModels[model] = true
				self:_pauseRigAnimation(model, QTE_SLOWMO_ANIMATION_SPEED)
			end
		end

		freezeModel(actorModel, true)
		freezeModel(enemyModel, false)
		freezeModel(self.PlayerProxy, true)

		for slotNumber = 1, 4 do
			freezeModel(self:_getControlledActorModel(slotNumber), true)
		end

		self:_forEachEnemyModel(function(spawnedEnemy)
			freezeModel(spawnedEnemy, false)

			if self._acquireEnemyMotionLock and not self:_shouldKeepModelLiveDuringQte(spawnedEnemy) then
				self:_acquireEnemyMotionLock(spawnedEnemy, "Frozen", { Force = true })
			end
		end)

		self:_hideAllEmbeddedMatchBalls()
		self:_startQteFreezeAnimationGuard()

		if self.MatchActorRuntimeController and self.MatchActorRuntimeController.SetLocalMatchAnimationFrozen then
			self.MatchActorRuntimeController:SetLocalMatchAnimationFrozen(LocalPlayer, true)
		end

		task.spawn(function()
			RunService.Heartbeat:Wait()
			if not self.IsPreQteFrozen then return end

			self:_setTimeScale(QTE_SLOWMO_TIME_SCALE)

			debugPrintPlayingAnimations(actorModel, "ACTOR")
			debugPrintPlayingAnimations(enemyModel, "ENEMY")

			if self.MatchActorRuntimeController and self.MatchActorRuntimeController.SetLocalMatchTimeScale then
				self.MatchActorRuntimeController:SetLocalMatchTimeScale(LocalPlayer, QTE_SLOWMO_TIME_SCALE, QTE_SLOWMO_ANIMATION_SPEED)
			end

			if self.MatchBattleCameraController and self.MatchBattleCameraController.StartQteSoftFollow then
				self.MatchBattleCameraController:StartQteSoftFollow()
			elseif self.MatchBattleCameraController and self.MatchBattleCameraController.PauseQteCamera then
				self.MatchBattleCameraController:PauseQteCamera()
			end
		end)
	end

	local function forceResumeModelTracks(model)
		if not model or not model.Parent then
			return
		end

		local animator = model:FindFirstChildWhichIsA("Animator", true)
		if not animator then
			return
		end

		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function()
				local baseSpeed = track:GetAttribute("BaseSpeed") or 1.0
				track:AdjustSpeed(baseSpeed)
			end)
		end
	end

	function MatchPresentationController:_resumeKnownMatchRigAnimations()
		forceResumeModelTracks(self.PlayerProxy)

		for slotNumber = 1, 4 do
			forceResumeModelTracks(self:_getControlledActorModel(slotNumber))
		end

		self:_forEachEnemyModel(function(enemyModel)
			forceResumeModelTracks(enemyModel)
		end)
	end

	function MatchPresentationController:_resumeActorsAfterPreQte()
		if not self.IsPreQteFrozen then
			if self._resumeKnownMatchRigAnimations then
				self:_resumeKnownMatchRigAnimations()
			end
			return
		end

		local pendingPayload = self.PendingPreQtePosePayload
		local pendingActorModel = self.PendingPreQtePoseActorModel

		self.IsPreQteFrozen = false
		self:_setTimeScale(DEFAULT_TIME_SCALE)
		self.QteLiveRunnerSlot = nil
		self.QteLiveShadowEnemySlot = nil

		self.PendingPreQtePosePayload = nil
		self.PendingPreQtePoseActorModel = nil
		self.PendingPreQtePoseEnemyModel = nil
		self.PendingPreQtePasserModel = nil

		if self._resetEnemyMotionLocks then
			self:_resetEnemyMotionLocks()
		end

		self.QteFreezeToken = (self.QteFreezeToken or 0) + 1
		self.LastPreQtePoseKey = nil

		if pendingPayload and pendingActorModel and shouldSkipActionPose(pendingPayload) then
			stopActionPoseTracks(pendingActorModel)
		end

		self:_resumeFrozenRigAnimations()
		self:_resumeKnownMatchRigAnimations()

		if self.MatchActorRuntimeController and self.MatchActorRuntimeController.SetLocalMatchTimeScale then
			self.MatchActorRuntimeController:SetLocalMatchTimeScale(LocalPlayer, DEFAULT_TIME_SCALE, DEFAULT_TIME_SCALE)
		end

		if self.MatchActorRuntimeController and self.MatchActorRuntimeController.SetLocalMatchAnimationFrozen then
			self.MatchActorRuntimeController:SetLocalMatchAnimationFrozen(LocalPlayer, false)
		end

		if self.MatchBattleCameraController and self.MatchBattleCameraController.ResumeQteCamera then
			self.MatchBattleCameraController:ResumeQteCamera()
		end
	end

	function MatchPresentationController:_waitForPreQteReady(payload, actorModel, actorTargetPos, enemyModel, enemyTargetPos, forceReady)
		local stableFrames = 0

		while self.CurrentSessionId == tostring(payload.SessionId) do
			RunService.RenderStepped:Wait()

			if forceReady == true then
				stableFrames += 1
			elseif payload.Action == "Shoot" then
				stableFrames += 1
			else
				local actorCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
				local enemyRoot = GetRootPart(enemyModel)

				local actorPosition = actorCFrame and actorCFrame.Position or actorTargetPos
				local enemyPosition = enemyRoot and enemyRoot.Position or enemyTargetPos

				local isClose = self:_isConfrontationClose(
					actorPosition,
					enemyPosition,
					QTE_TRIGGER_DISTANCE + QTE_TRIGGER_DISTANCE_BUFFER
				)

				if isClose then
					stableFrames += 1
				else
					stableFrames = 0
				end
			end

			if stableFrames >= PRE_QTE_READY_FRAMES then
				break
			end
		end
	end

	function MatchPresentationController:_preparePreQtePresentation(payload, actorModel, enemyModel)
		if not payload or not actorModel then
			return
		end

		local currentCarrier = self.MatchBallController and self.MatchBallController.CurrentFollowActor
		if currentCarrier and currentCarrier ~= actorModel then
			self.PendingPreQtePasserModel = currentCarrier
		else
			local passerSlot = payload and tonumber(payload.FromSlot)
			self.PendingPreQtePasserModel = passerSlot and self:_getControlledActorModel(passerSlot)
		end

		self.PendingPreQtePosePayload = payload
		self.PendingPreQtePoseActorModel = actorModel
		self.PendingPreQtePoseEnemyModel = enemyModel

		self:_hideAllEmbeddedMatchBalls()
		self:_hideNonCarrierEmbeddedBalls(payload.ActorSlot or self.ActiveActorSlot)

		local actionConfig = getActionPoseConfig(payload.Action)
		local ballOffset = actionConfig.BallOffset or MatchBallConfig.ReceiveOffset

		if payload.Action == "Shoot" then
			stopShootTracks(actorModel)

			if self.MatchKeeperPresentationController then
				self.MatchKeeperPresentationController:SetReady()
			end

			if self.MatchBattleCameraController then
				self.MatchBattleCameraController:OnShootAnticipation()
			end
		end

		if self.MatchBallController then
			self.MatchBallController:AttachToActor(actorModel, ballOffset)
			self:_hideAllEmbeddedMatchBalls()
		end

		if actionConfig.SkipActionPose == true then
			stopActionPoseTracks(actorModel)
			self:_playRigAnimation(actorModel, actionConfig.Animations[1] or "Run", 1.0, 0)

			if enemyModel then
				local enemyRuntimeSlot = self._getEnemyRuntimeSlotFromModel and self:_getEnemyRuntimeSlotFromModel(enemyModel)
				local isKeeper = enemyRuntimeSlot == Constants.GOALKEEPER_RUNTIME_SLOT
					or enemyModel.Name == "GoalKeeper"
					or enemyModel.Name == "Keeper"
				self:_playRigAnimation(
					enemyModel,
					isKeeper and "Idle" or (actionConfig.EnemyAnimation or "Run"),
					isKeeper and 1.0 or (actionConfig.EnemySpeed or 1.0),
					0
				)
			end

			return
		end

		self:_applyPreQteHoldPose(payload, actorModel, enemyModel, true)
	end

	function MatchPresentationController:_waitForSessionFrames(sessionId, frameCount)
		local remainingFrames = math.max(tonumber(frameCount) or 0, 0)

		while remainingFrames > 0 and self:_isSessionActive(sessionId) do
			RunService.RenderStepped:Wait()
			remainingFrames -= 1
		end
	end

	function MatchPresentationController:_playPreQteActionPose(model, animationNames, speed, fade)
		if not model then
			return nil
		end

		local candidates = animationNames
		if type(animationNames) == "string" then
			candidates = { animationNames }
		end

		if type(candidates) ~= "table" then
			candidates = { "Run" }
		end

		for _, animationName in ipairs(candidates) do
			local track = self:_playRigAnimation(model, animationName, speed or 1.0, 0)
			if track then
				pcall(function()
					track:Stop(0)
					track.TimePosition = 0
					track:Play(0)
					track:AdjustSpeed(1)
					track:AdjustWeight(1, 0)
				end)

				return track
			end
		end

		return nil
	end

	function MatchPresentationController:_applyPreQteHoldPose(payload, actorModel, enemyModel, forceRestart)
		if not payload or not actorModel then
			return
		end

		local actionConfig = getActionPoseConfig(payload.Action)

		if actionConfig.SkipActionPose == true then
			stopActionPoseTracks(actorModel)
			self:_playMotionAnimation(actorModel, actionConfig.Animations[1] or "Run", 1.0)

			if enemyModel then
				local isKeeper = false
				if self._getEnemyRuntimeSlotFromModel then
					isKeeper = self:_getEnemyRuntimeSlotFromModel(enemyModel) == Constants.GOALKEEPER_RUNTIME_SLOT
				end
				if not isKeeper and (enemyModel.Name == "GoalKeeper" or enemyModel.Name == "Keeper") then
					isKeeper = true
				end

				self:_playMotionAnimation(
					enemyModel,
					isKeeper and "Idle" or (actionConfig.EnemyAnimation),
					isKeeper and 1.0 or (actionConfig.EnemySpeed or 1.0)
				)
			end

			return
		end

		local poseKey = getPreQtePoseKey(payload)

		if not forceRestart and poseKey and self.LastPreQtePoseKey == poseKey then
			return
		end

		self.LastPreQtePoseKey = poseKey

		self:_hideAllEmbeddedMatchBalls()

		local actorTrack = self:_playPreQteActionPose(
			actorModel,
			actionConfig.Animations,
			1.0,
			actionConfig.FadeTime
		)

		if actorTrack then
			safeSetTrackTimePosition(actorTrack, actionConfig.PoseTime or 0.16)
			actorTrack:AdjustSpeed(QTE_SLOWMO_ANIMATION_SPEED)

			RunService.RenderStepped:Wait()

			if self:_isSessionActive(payload.SessionId) then
				safeSetTrackTimePosition(actorTrack, actionConfig.PoseTime or 0.16)
				actorTrack:AdjustSpeed(QTE_SLOWMO_ANIMATION_SPEED)
				self:_pauseRigAnimation(actorModel, QTE_SLOWMO_ANIMATION_SPEED)
			end
		end

		if enemyModel then
			self:_playMotionAnimation(
				enemyModel,
				actionConfig.EnemyAnimation or "Run",
				actionConfig.EnemySpeed or 1.0
			)
		end
	end
end
