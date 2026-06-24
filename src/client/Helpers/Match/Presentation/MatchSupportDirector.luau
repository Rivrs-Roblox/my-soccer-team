return function(MatchPresentationController, Context)
	local Services = Context.Services
	local RunService = Services.RunService

	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath

	local Constants = Context.Constants
	local Utils = Context.Utils

	
	local ALLY_PATROL_SPEED = Constants.ALLY_PATROL_SPEED
	local POST_PHASE_ADVANCE_SPEED = Constants.POST_PHASE_ADVANCE_SPEED
	local POST_PHASE_ADVANCE_STOP_BUFFER = Constants.POST_PHASE_ADVANCE_STOP_BUFFER
	local POST_PHASE_ADVANCE_MIN_DISTANCE = Constants.POST_PHASE_ADVANCE_MIN_DISTANCE
	local RECEIVER_CATCH_UP_SPEED = Constants.RECEIVER_CATCH_UP_SPEED
	local RECEIVER_NEXT_QTE_BUFFER = Constants.RECEIVER_NEXT_QTE_BUFFER
	local PASS_RECEIVE_LANE_OFFSET = Constants.PASS_RECEIVE_LANE_OFFSET
	local OFF_BALL_RUNNER_FORWARD_DISTANCE = Constants.OFF_BALL_RUNNER_FORWARD_DISTANCE
	local OFF_BALL_RUNNER_LANE_OFFSET = Constants.OFF_BALL_RUNNER_LANE_OFFSET
	local THROUGH_PASS_DISTANCE_STEP_1 = Constants.THROUGH_PASS_DISTANCE_STEP_1
	local THROUGH_PASS_DISTANCE_STEP_2 = Constants.THROUGH_PASS_DISTANCE_STEP_2
	local THROUGH_PASS_DISTANCE_STEP_3 = Constants.THROUGH_PASS_DISTANCE_STEP_3
	local THROUGH_PASS_MAX_OVERSHOOT_STEP_3 = Constants.THROUGH_PASS_MAX_OVERSHOOT_STEP_3
	local ApplyPivot = Utils.ApplyPivot
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local StepFlatTowards = Utils.StepFlatTowards
	local BuildStableOffset = Utils.BuildStableOffset
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook
	local ClampTargetAhead = Utils.ClampTargetAhead
	local GetBallFocusPosition = Utils.GetBallFocusPosition
	local ResolveSupportLookPosition = Utils.ResolveSupportLookPosition

	local COMPACT_PASS_MAX_STEP_INDEX = 1
	local COMPACT_PASS_BASE_FORWARD = 5.0
	local COMPACT_PASS_FORWARD_PER_ORDER = 0.65
	local COMPACT_PASS_MAX_LANE_DISTANCE = 0.55
	local COMPACT_PASS_LANE_PER_ORDER = 0.10
	local COMPACT_PASS_SIDE_PUSH = 0.22
	local COMPACT_PASS_FORWARD_PUSH = 1.15
	local COMPACT_PASS_STABLE_OFFSET_SCALE = 0.15

	local function shouldUseCompactPassClearLane(payload)
		return payload
			and payload.Action == "Pass"
			and (tonumber(payload.StepIndex) or 0) <= COMPACT_PASS_MAX_STEP_INDEX
	end

	local function getFlatLateralDirection(forwardDirection: Vector3): Vector3
		local lateralDirection = forwardDirection:Cross(Vector3.new(0, 1, 0))
		if lateralDirection.Magnitude <= 0.001 then
			return Vector3.new(1, 0, 0)
		end

		return lateralDirection.Unit
	end

	local function resolveSupportSideSign(slotNumber, mainSlot, currentPos, carrierPos, lateralDirection)
		if carrierPos then
			local relativeToCarrier = Vector3.new(
				currentPos.X - carrierPos.X,
				0,
				currentPos.Z - carrierPos.Z
			)

			local currentSide = relativeToCarrier:Dot(lateralDirection)
			if math.abs(currentSide) >= 0.20 then
				return currentSide >= 0 and 1 or -1
			end
		end

		if tonumber(slotNumber) == 4 then
			return 1
		end

		if tonumber(slotNumber) == 3 then
			return -1
		end

		if tonumber(mainSlot) == 3 then
			return 1
		end

		return -1
	end

	local function resolveDirectionalMotionAnimation(currentPos: Vector3, targetPos: Vector3, lookTarget: Vector3?)
		local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, targetPos)
		if moveDirection.Magnitude <= 0.001 then
			return "Idle"
		end

		if not lookTarget then
			return "Run"
		end

		local faceDirection = MatchMotionMath.GetFlatDirection(currentPos, lookTarget)
		if faceDirection.Magnitude <= 0.001 then
			return "Run"
		end

		local forwardAmount = moveDirection:Dot(faceDirection.Unit)
		local lateralDirection = getFlatLateralDirection(faceDirection.Unit)
		local lateralAmount = moveDirection:Dot(lateralDirection)

		-- Use side-walk only when the actor is mostly moving sideways while facing ball/goal.
		-- Diagonal football runs stay as Run to avoid a dragged/sliding look.
		if math.abs(lateralAmount) >= 0.42 and forwardAmount < 0.45 then
			return lateralAmount >= 0 and "StrafeRight" or "StrafeLeft"
		end

		return "Run"
	end

	local function isSupportLocomotionAnimation(animationName: string?): boolean
		return animationName == "Run"
			or animationName == "StrafeLeft"
			or animationName == "StrafeRight"
	end

	function MatchPresentationController:_getSupportAdvanceSpeed(currentStepIndex, targetStepIndex, actionName)
		local stepGap = math.max((tonumber(targetStepIndex) or 0) - (tonumber(currentStepIndex) or 0), 0)

		if actionName == "Shoot" then
			return 0
		end

		-- Off-ball runners must keep follow-up pressure without looking slow-motion.
		if actionName == "Dribble" then
			if stepGap <= 1 then
				return 12.0
			elseif stepGap == 2 then
				return 9.5
			else
				return 7.5
			end
		end

		if stepGap <= 1 then
			return 11.0
		elseif stepGap == 2 then
			return 8.5
		else
			return 6.8
		end
	end

	function MatchPresentationController:_getSupportAdvanceProfile(actionName, stepGap)
		local gap = math.max(tonumber(stepGap) or 1, 1)

		if actionName == "Dribble" then
			if gap == 1 then
				return 12.5, 11.0
			elseif gap == 2 then
				return 10.0, 8.5
			else
				return 8.0, 6.5
			end
		end

		if actionName == "Pass" then
			if gap == 1 then
				return 11.5, 10.0
			elseif gap == 2 then
				return 9.0, 7.5
			else
				return 7.0, 6.0
			end
		end

		if gap == 1 then
			return 10.0, 8.5
		elseif gap == 2 then
			return 8.0, 6.8
		else
			return 6.5, 5.5
		end
	end

	function MatchPresentationController:_animateIdleAllies(sessionId)
	self.AllyPatrolMotionToken += 1
	local motionToken = self.AllyPatrolMotionToken

	task.spawn(function()
		while self:_isSessionActive(sessionId) and motionToken == self.AllyPatrolMotionToken do
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

			if self.IsPreQteFrozen or self.IsPostActionBusy then
				continue
			end

			for slotNumber = 2, 4 do
				if tonumber(self.ActiveActorSlot) == slotNumber then
					continue
				end

				local allyModel = self:_getControlledActorModel(slotNumber)
				if not allyModel or not allyModel.Parent then
					continue
				end

				self:_setEmbeddedBallVisualsHidden(allyModel, true)

				local currentCFrame = self:_getActorCurrentCFrame(slotNumber, allyModel)
				if not currentCFrame then
					continue
				end

				local currentPos = GetGroundedPosition(currentCFrame.Position, allyModel)
				local phaseIndex = self:_getAllyPhaseForSlot(slotNumber)

				local nextPos = currentPos
				local lookTarget = GetBallFocusPosition(self, currentPos + currentCFrame.LookVector)
				local moveSpeed = ALLY_PATROL_SPEED
				local expectedAnimation = "Run"

				if self:_hasPhasePassed(phaseIndex) then
					local isMoving = false
					nextPos, lookTarget, isMoving = self:_stepSupportAdvance(
						allyModel,
						currentPos,
						phaseIndex,
						POST_PHASE_ADVANCE_SPEED,
						scaledDeltaTime
					)

					lookTarget = ResolveSupportLookPosition(self, nextPos, lookTarget or nextPos, {
						ForceForward = true,
					})

					moveSpeed = POST_PHASE_ADVANCE_SPEED
					expectedAnimation = isMoving and "Run" or "Idle"
				else
					local patrolStep = self:_getPatrolStepForSlot(slotNumber)
					local patrolTargetPos = self:_buildVerticalLanePatrolPosition(
						patrolStep,
						allyModel,
						sessionId,
						slotNumber,
						os.clock(),
						currentPos
					)

					if patrolTargetPos then
						nextPos = select(1, StepFlatTowards(
							currentPos,
							patrolTargetPos,
							ALLY_PATROL_SPEED,
							scaledDeltaTime
						))

						nextPos = GetGroundedPosition(nextPos, allyModel)

						local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, nextPos)
						if moveDirection.Magnitude <= 0.001 then
							moveDirection = MatchMotionMath.GetFlatDirection(currentPos, patrolTargetPos)
						end

						local moveFallback = moveDirection.Magnitude > 0.001
							and (nextPos + moveDirection)
							or (nextPos + currentCFrame.LookVector)

						lookTarget = ResolveSupportLookPosition(self, nextPos, moveFallback)
					end

					expectedAnimation = resolveDirectionalMotionAnimation(currentPos, nextPos, lookTarget or nextPos)
					if expectedAnimation == "Idle" then
						expectedAnimation = "Run"
					end
				end

				local targetCFrame = MatchMotionMath.BuildFlatLookAtCFrame(nextPos, lookTarget or nextPos)
				local usedRuntime = self:_applyActorCFrame(
					slotNumber,
					allyModel,
					targetCFrame,
					{
						ExpectedAnimation = expectedAnimation,
						MoveSpeed = moveSpeed,
						LookAtPosition = lookTarget or nextPos,
						FacingMode = "LookAtPosition",

						-- Important:
						-- Keep StrafeLeft / StrafeRight too.
						-- If this is false, runtime will convert strafe locomotion back to Idle after reaching target.
						KeepAnimationWhenReached = isSupportLocomotionAnimation(expectedAnimation),
					}
				)

				if not usedRuntime then
					self:_playMotionAnimation(allyModel, expectedAnimation, 1.0)
				end
			end
		end
	end)
end

	function MatchPresentationController:_getPatrolStepForSlot(slotNumber)
		local numericSlot = tonumber(slotNumber) or 1

		if numericSlot == 2 then
			return 2
		end

		if numericSlot == 3 or numericSlot == 4 then
			return 3
		end

		return math.clamp(numericSlot, 1, 3)
	end

	function MatchPresentationController:_getAllyPhaseForSlot(slotNumber)
		local numericSlot = tonumber(slotNumber) or 1

		if numericSlot == 2 then
			return 2
		end

		if numericSlot == 3 or numericSlot == 4 then
			return 2
		end

		return nil
	end

	function MatchPresentationController:_hasPhasePassed(phaseIndex)
		local currentStepIndex = tonumber(self.CurrentPresentationStepIndex) or 0
		return phaseIndex ~= nil and currentStepIndex >= phaseIndex
	end

	function MatchPresentationController:_buildPostPhaseAdvancePosition(phaseIndex, model, currentPos)
		if not phaseIndex or not currentPos then
			return currentPos
		end

		local nextStepIndex = math.clamp(phaseIndex + 1, 1, 4)
		local nextMarker = MatchZoneQuery.GetCarrierPoint(nextStepIndex)
			or MatchZoneQuery.GetZoneArea(nextStepIndex)
			or MatchZoneQuery.GetGoalTarget()

		if not nextMarker then
			return currentPos
		end

		local nextMarkerPos = nextMarker.Position
		local advanceDirection = MatchMotionMath.GetFlatDirection(currentPos, nextMarkerPos)
		if advanceDirection.Magnitude <= 0.001 then
			return currentPos
		end

		local stopBeforeNext = nextMarkerPos - (advanceDirection * POST_PHASE_ADVANCE_STOP_BUFFER)
		local distanceToLimit = GetFlatDistance(currentPos, stopBeforeNext)

		if distanceToLimit <= POST_PHASE_ADVANCE_MIN_DISTANCE then
			return currentPos
		end

		return GetGroundedPosition(stopBeforeNext, model)
	end

	function MatchPresentationController:_stepSupportAdvance(model, currentPos, phaseIndex, speed, deltaTime)
		local targetPos = self:_buildPostPhaseAdvancePosition(phaseIndex, model, currentPos)

		if not targetPos or GetFlatDistance(currentPos, targetPos) <= POST_PHASE_ADVANCE_MIN_DISTANCE then
			return currentPos, currentPos, false
		end

		local nextPos = select(1, StepFlatTowards(
			currentPos,
			targetPos,
			speed or POST_PHASE_ADVANCE_SPEED,
			deltaTime
		))

		nextPos = GetGroundedPosition(nextPos, model)

		local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, nextPos)
		local moveFallback = moveDirection.Magnitude > 0.001
			and (nextPos + moveDirection)
			or targetPos

		local lookTarget = ResolveSupportLookPosition(self, nextPos, moveFallback, {
			ForceForward = true,
		})

		return nextPos, lookTarget, true
	end

	function MatchPresentationController:_moveOtherLaneRunnerForward(payload, receiverSlot, actorCFrame)
	if not payload or not actorCFrame then
		return
	end

	local numericReceiverSlot = tonumber(receiverSlot)
	if numericReceiverSlot ~= 3 and numericReceiverSlot ~= 4 then
		return
	end

	local runnerSlot = numericReceiverSlot == 3 and 4 or 3
	if tonumber(self.ActiveActorSlot) == runnerSlot then
		return
	end

	local runnerModel = self:_getControlledActorModel(runnerSlot)
	local goalTarget = MatchZoneQuery.GetGoalTarget()
	if not runnerModel or not goalTarget then
		return
	end

	local runnerCFrame = self:_getActorCurrentCFrame(runnerSlot, runnerModel) or runnerModel:GetPivot()
	local runnerPos = GetGroundedPosition(runnerCFrame.Position, runnerModel)
	local actorPos = GetGroundedPosition(actorCFrame.Position, nil)
	local attackDirection = MatchMotionMath.GetFlatDirection(actorPos, goalTarget.Position)

	if attackDirection.Magnitude <= 0.001 then
		attackDirection = GetFlatUnitFromLook(actorCFrame.LookVector)
	end

	local lateral = getFlatLateralDirection(attackDirection)
	local sideSign = runnerSlot == 4 and 1 or -1

	local desiredPos = runnerPos
		+ (attackDirection * OFF_BALL_RUNNER_FORWARD_DISTANCE)
		+ (lateral * sideSign * OFF_BALL_RUNNER_LANE_OFFSET)

	local runnerProgressFromCarrier = Vector3.new(
		runnerPos.X - actorPos.X,
		0,
		runnerPos.Z - actorPos.Z
	):Dot(attackDirection)

	if runnerProgressFromCarrier < 7.0 then
		desiredPos = actorPos
			+ (attackDirection * (OFF_BALL_RUNNER_FORWARD_DISTANCE + 3.0))
			+ (lateral * sideSign * OFF_BALL_RUNNER_LANE_OFFSET)
	end

	desiredPos = GetGroundedPosition(desiredPos, runnerModel)

	local forwardLookTarget = ResolveSupportLookPosition(self, desiredPos, desiredPos + attackDirection, {
		ForceForward = true,
	})

	local targetCFrame = MatchMotionMath.BuildFlatLookAtCFrame(desiredPos, forwardLookTarget)

	local expectedAnimation = "Run"

	local usedRuntime = self:_applyActorCFrame(
		runnerSlot,
		runnerModel,
		targetCFrame,
		{
			ExpectedAnimation = expectedAnimation,
			MoveSpeed = RECEIVER_CATCH_UP_SPEED,
			LookAtPosition = forwardLookTarget,
			FacingMode = "LookAtPosition",
			KeepAnimationWhenReached = isSupportLocomotionAnimation(expectedAnimation),
		}
	)

	if not usedRuntime then
		self:_playMotionAnimation(runnerModel, expectedAnimation, 1.0)
	end
end

	function MatchPresentationController:_getActorWorldPositionBySlot(slotNumber, fallbackPosition)
		local actorModel = self:_getControlledActorModel(slotNumber)
		local actorCFrame = actorModel and self:_getActorCurrentCFrame(slotNumber, actorModel)

		if actorCFrame then
			return GetGroundedPosition(actorCFrame.Position, actorModel)
		end

		return fallbackPosition
	end

	function MatchPresentationController:_moveCompanionsForward(payload, mainSlot)
	local goalTarget = MatchZoneQuery.GetGoalTarget()
	if not goalTarget or not payload then
		return
	end

	if payload.Action == "Shoot" then
		self:_stopSupportMotion()
		return
	end

	self:_stopSupportMotion()

	local motionToken = self.SupportMotionToken
	local currentStepIndex = tonumber(payload.StepIndex) or 1
	local compactPassClearLane = shouldUseCompactPassClearLane(payload)

	-- Important:
	-- QTE2 -> QTE3 must keep every non-carrier companion alive.
	-- They should continue the attack even if they do not receive the ball.
	local forceAttackFollowUp = currentStepIndex >= 2
		and (payload.Action == "Dribble" or payload.Action == "Pass")

	local supportSlots = {}
	for slotNum = 2, 4 do
		if slotNum ~= tonumber(mainSlot) then
			table.insert(supportSlots, slotNum)
		end
	end

	table.sort(supportSlots, function(a, b)
		return a < b
	end)

	for orderIndex, slotNum in ipairs(supportSlots) do
		local supportModel = self:_getControlledActorModel(slotNum)
		if not supportModel then
			continue
		end

		if self.ActiveForwardRunners and self.ActiveForwardRunners[slotNum] then
			if self:_hasActorReachedRuntimeTarget(slotNum) then
				self.ActiveForwardRunners[slotNum] = nil
			else
				continue
			end
		end

		local targetStepIndex = math.min(currentStepIndex + orderIndex, 4)
		local moveSpeed, maxForwardDrift = self:_getSupportAdvanceProfile(
			payload.Action,
			targetStepIndex - currentStepIndex
		)

		if compactPassClearLane then
			maxForwardDrift = math.min(maxForwardDrift, 3.25 + (orderIndex * 0.25))
		elseif forceAttackFollowUp then
			maxForwardDrift = math.max(maxForwardDrift, 11.0 + (orderIndex * 1.75))
			moveSpeed = math.max(moveSpeed, 14.0 + (orderIndex * 0.75))
		end

		if moveSpeed <= 0 then
			self:_playRigAnimation(supportModel, "Idle", 1.0)
			continue
		end

		local initialCFrame = self:_getActorCurrentCFrame(slotNum, supportModel) or supportModel:GetPivot()
		local initialPos = GetGroundedPosition(initialCFrame.Position, supportModel)
		local goalDirection = MatchMotionMath.GetFlatDirection(initialPos, goalTarget.Position)

		if goalDirection.Magnitude <= 0.001 then
			goalDirection = GetFlatUnitFromLook(initialCFrame.LookVector)
		end

		local baseTargetPos = nil

		if not compactPassClearLane
			and not forceAttackFollowUp
			and self.MatchSpawnLayoutController
			and self.MatchSpawnLayoutController.GetAllyWorldPosition
		then
			baseTargetPos = self.MatchSpawnLayoutController:GetAllyWorldPosition(targetStepIndex, slotNum)
		end

		if compactPassClearLane then
			baseTargetPos = initialPos + (goalDirection * (COMPACT_PASS_BASE_FORWARD + (orderIndex * COMPACT_PASS_FORWARD_PER_ORDER)))
		elseif forceAttackFollowUp then
			-- Do not wait for next QTE layout. Push the support forward immediately.
			baseTargetPos = initialPos + (goalDirection * (8.0 + (orderIndex * 1.5)))
		elseif baseTargetPos then
			baseTargetPos = GetGroundedPosition(baseTargetPos, supportModel)

			local baseDir = MatchMotionMath.GetFlatDirection(initialPos, baseTargetPos)
			if baseDir.Magnitude <= 0.001 or baseDir:Dot(goalDirection) < 0 then
				baseTargetPos = initialPos + (goalDirection * (4 + (orderIndex * 1.75)))
			end
		else
			baseTargetPos = initialPos + (goalDirection * (4 + (orderIndex * 1.75)))
		end

		baseTargetPos = GetGroundedPosition(baseTargetPos, supportModel)

		local stableOffsetX = compactPassClearLane and COMPACT_PASS_STABLE_OFFSET_SCALE or 1
		local stableOffsetZ = compactPassClearLane and COMPACT_PASS_STABLE_OFFSET_SCALE or 1

		if forceAttackFollowUp then
			stableOffsetX *= 0.35
			stableOffsetZ *= 0.35
		end

		local laneOffset = BuildStableOffset(
			payload.SessionId,
			currentStepIndex,
			slotNum,
			1.4 * stableOffsetX,
			1.2 * stableOffsetZ,
			197
		)

		task.spawn(function()
			local forwardDrift = 0
			local manualPos = initialPos

			while self:_isSessionActive(payload.SessionId) and motionToken == self.SupportMotionToken do
				local dt = RunService.RenderStepped:Wait()

				if self.IsPreQteFrozen then
					break
				end

				local scaledDt = self:_getScaledDeltaTime(dt)

				if tonumber(self.ActiveActorSlot) == tonumber(slotNum) then
					self:_playRigAnimation(supportModel, "Idle", 1.0)
					break
				end

				if not supportModel.Parent then
					break
				end

				local currentCFrame = self:_getActorCurrentCFrame(slotNum, supportModel) or supportModel:GetPivot()
				local currentPos = GetGroundedPosition(currentCFrame.Position, supportModel)

				local liveGoalDir = MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
				if liveGoalDir.Magnitude <= 0.001 then
					liveGoalDir = Vector3.new(0, 0, -1)
				end

				forwardDrift = math.min(
					forwardDrift + (moveSpeed * 0.46 * scaledDt),
					maxForwardDrift
				)

				local lateralDir = getFlatLateralDirection(liveGoalDir)
				local carrierPos = self:_getActorWorldPositionBySlot(self.ActiveActorSlot, currentPos)

				local preferredSideSign = resolveSupportSideSign(
					slotNum,
					mainSlot,
					currentPos,
					carrierPos,
					lateralDir
				)

				local supportLaneDistance = OFF_BALL_RUNNER_LANE_OFFSET + (orderIndex * 0.35)

				if compactPassClearLane then
					supportLaneDistance = math.min(
						supportLaneDistance,
						COMPACT_PASS_MAX_LANE_DISTANCE + (orderIndex * COMPACT_PASS_LANE_PER_ORDER)
					)
				elseif forceAttackFollowUp then
					-- Enough to avoid the carrier lane, but not too wide.
					supportLaneDistance = math.min(supportLaneDistance, 4.25 + (orderIndex * 0.25))
				end

				local dynamicTargetPos = baseTargetPos
					+ Vector3.new(laneOffset.X, 0, laneOffset.Z)
					+ (liveGoalDir * forwardDrift)
					+ (lateralDir * preferredSideSign * supportLaneDistance)

				local openLaneDistance = math.max(
					OFF_BALL_RUNNER_LANE_OFFSET * 0.85,
					compactPassClearLane and 0.65 or 1.0
				)

				if carrierPos and GetFlatDistance(dynamicTargetPos, carrierPos) < openLaneDistance then
					local sidePush = compactPassClearLane
						and COMPACT_PASS_SIDE_PUSH
						or (forceAttackFollowUp and 1.25 or (OFF_BALL_RUNNER_LANE_OFFSET * 0.75))

					local forwardPush = compactPassClearLane
						and COMPACT_PASS_FORWARD_PUSH
						or (forceAttackFollowUp and 2.25 or 3.0)

					dynamicTargetPos += lateralDir * preferredSideSign * sidePush
					dynamicTargetPos += liveGoalDir * forwardPush
				end

				dynamicTargetPos = GetGroundedPosition(dynamicTargetPos, supportModel)

				local moveDir = MatchMotionMath.GetFlatDirection(currentPos, dynamicTargetPos)
				local moveFallback = moveDir.Magnitude > 0.001
					and (dynamicTargetPos + moveDir)
					or goalTarget.Position

				local lookTarget = ResolveSupportLookPosition(self, dynamicTargetPos, moveFallback, {
					ForceForward = compactPassClearLane
						or forceAttackFollowUp
						or payload.Action == "Dribble"
						or payload.Action == "Pass",
				})

				local isMoving = GetFlatDistance(currentPos, dynamicTargetPos) > 0.12

				if self:_isCompanionSlot(slotNum) then
					local expectedAnimation = isMoving and resolveDirectionalMotionAnimation(
						currentPos,
						dynamicTargetPos,
						lookTarget
					) or "Idle"

					if expectedAnimation == "Idle" and isMoving then
						expectedAnimation = "Run"
					end

					local usedRuntime = self:_applyActorCFrame(
						slotNum,
						supportModel,
						MatchMotionMath.BuildFlatLookAtCFrame(dynamicTargetPos, lookTarget),
						{
							ExpectedAnimation = expectedAnimation,
							MoveSpeed = moveSpeed,
							LookAtPosition = lookTarget,
							FacingMode = "LookAtPosition",
							KeepAnimationWhenReached = isSupportLocomotionAnimation(expectedAnimation),
						}
					)

					if not usedRuntime then
						self:_playMotionAnimation(supportModel, expectedAnimation, 1.0)
					end
				else
					local nextPos = select(1, StepFlatTowards(
						manualPos,
						dynamicTargetPos,
						moveSpeed,
						scaledDt
					))

					nextPos = GetGroundedPosition(nextPos, supportModel)
					manualPos = nextPos

					ApplyPivot(
						supportModel,
						MatchMotionMath.BuildFlatLookAtCFrame(nextPos, lookTarget)
					)

					local manualAnimation = isMoving and resolveDirectionalMotionAnimation(
						currentPos,
						dynamicTargetPos,
						lookTarget
					) or "Idle"

					if manualAnimation == "Idle" and isMoving then
						manualAnimation = "Run"
					end

					self:_playMotionAnimation(
						supportModel,
						manualAnimation,
						1.0
					)
				end
			end
		end)
	end
end

	-- // [ DAY 2D: ZONE3 RUNNER / RETURN THROUGH BALL ] // --

	function MatchPresentationController:_resolveZone3RunnerSlot(payload)
		local configuredRunner = tonumber(payload and payload.Zone3RunnerSlot)
		if configuredRunner and configuredRunner >= 2 and configuredRunner <= 4 then
			return configuredRunner
		end

		local rememberedRunner = tonumber(self.Zone3RunnerSlot)
		if rememberedRunner and rememberedRunner >= 2 and rememberedRunner <= 4 then
			return rememberedRunner
		end

		return 3
	end

	function MatchPresentationController:_rememberZone3RunnerSlot(payload)
		local runnerSlot = self:_resolveZone3RunnerSlot(payload)
		self.Zone3RunnerSlot = runnerSlot
		return runnerSlot
	end

	function MatchPresentationController:_resolveQte3ForwardRunnerSlot(payload)
		return self:_resolveZone3RunnerSlot(payload)
	end

	function MatchPresentationController:_buildForwardReceiveCFrame(payload, actorModel, targetModel, actorCFrame, targetCFrame)
		if not payload or not actorCFrame or not targetCFrame then
			return nil
		end

		if payload.Action ~= "Pass" then
			return nil
		end

		local stepIndex = tonumber(payload.StepIndex) or tonumber(payload.Step) or 1
		local targetSlot = tonumber(payload.TargetSlot) or tonumber(payload.ToSlot)
		local isPlayer2BranchPass = payload.Player2Branch == true or payload.PassMode == "Player2BranchPass"

		if isPlayer2BranchPass then
			targetSlot = 4
		elseif payload.PassMode == "ReturnThroughBall" or payload.UseZone3RunnerTarget then
			targetSlot = self:_resolveZone3RunnerSlot(payload)
		end

		if not targetSlot or targetSlot <= 1 then
			return nil
		end

		local goalTarget = MatchZoneQuery.GetGoalTarget()
		if not goalTarget then
			return nil
		end

		local actorPos = GetGroundedPosition(actorCFrame.Position, actorModel)
		local attackDirection = MatchMotionMath.GetFlatDirection(actorPos, goalTarget.Position)

		if attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook(actorCFrame.LookVector)
		end

		if attackDirection.Magnitude <= 0.001 then
			return nil
		end

		local receiveStepIndex = tonumber(payload.TargetReceiveStep) or math.clamp(stepIndex + 1, 2, 5)
		receiveStepIndex = math.clamp(receiveStepIndex, 2, 5)

		local isReturnThroughBall = payload.PassMode == "ReturnThroughBall"
			or payload.UseZone3RunnerTarget
			or stepIndex >= 4

		local receiveMarker = nil
		if isPlayer2BranchPass then
			receiveMarker = MatchZoneQuery.GetPlayer4BranchReceiveTarget and MatchZoneQuery.GetPlayer4BranchReceiveTarget()
				or MatchZoneQuery.GetZoneMarker(4, "ReceiveTarget")
				or MatchZoneQuery.GetZoneMarker(4, "Player4Target")
		elseif isReturnThroughBall then
			-- Map-driven return pass: QTE4 sends Slot3 to Zone03.ReceivePoint2.
			-- This is intentionally visible/tunable in Studio.
			if MatchZoneQuery.GetReceivePoint then
				receiveMarker = MatchZoneQuery.GetReceivePoint(3, 2)
			end
		else
			local receiveIndex = receiveStepIndex == 3 and 1 or nil
			if MatchZoneQuery.GetReceivePoint then
				receiveMarker = MatchZoneQuery.GetReceivePoint(receiveStepIndex, receiveIndex)
			end
		end

		receiveMarker = receiveMarker
			or MatchZoneQuery.GetCarrierPoint(receiveStepIndex)
			or MatchZoneQuery.GetZoneArea(receiveStepIndex)
			or goalTarget

		if not receiveMarker then
			return nil
		end

		local desiredPos = receiveMarker.Position
		desiredPos = GetGroundedPosition(desiredPos, targetModel)

		local carryMarker = nil
		if isPlayer2BranchPass then
			carryMarker = MatchZoneQuery.GetZoneMarker and MatchZoneQuery.GetZoneMarker("ShootZone", "Center")
				or MatchZoneQuery.GetGoalTarget()
		elseif isReturnThroughBall and MatchZoneQuery.GetCarryPoint then
			carryMarker = MatchZoneQuery.GetCarryPoint(3, 2)
		end

		local lookTarget = carryMarker and carryMarker.Position or (desiredPos + attackDirection)
		lookTarget = Vector3.new(lookTarget.X, desiredPos.Y, lookTarget.Z)

		return MatchMotionMath.BuildFlatLookAtCFrame(desiredPos, lookTarget)
	end

	function MatchPresentationController:_buildZone3RunnerCarrySprintTarget(runnerSlot, runnerModel, actorCFrame)
		if not runnerModel then
			return nil, nil
		end

		local carryMarker = MatchZoneQuery.GetCarryPoint and MatchZoneQuery.GetCarryPoint(3, 2)
		if not carryMarker then
			return nil, nil
		end

		local runnerCFrame = self:_getActorCurrentCFrame(runnerSlot, runnerModel) or runnerModel:GetPivot()
		local runnerPos = GetGroundedPosition(runnerCFrame.Position, runnerModel)
		local targetPos = GetGroundedPosition(carryMarker.Position, runnerModel)
		local attackDirection = MatchMotionMath.GetFlatDirection(runnerPos, targetPos)

		if attackDirection.Magnitude <= 0.001 and actorCFrame then
			attackDirection = GetFlatUnitFromLook(actorCFrame.LookVector)
		end

		if attackDirection.Magnitude <= 0.001 then
			local goalTarget = MatchZoneQuery.GetGoalTarget()
			attackDirection = goalTarget and MatchMotionMath.GetFlatDirection(runnerPos, goalTarget.Position) or Vector3.new(0, 0, -1)
		end

		return targetPos, attackDirection
	end

	function MatchPresentationController:_buildZone4ForwardSprintTarget(runnerSlot, runnerModel, actorCFrame)
		local goalTarget = MatchZoneQuery.GetGoalTarget()
		if not goalTarget or not runnerModel then
			return nil, nil
		end

		local runnerCFrame = self:_getActorCurrentCFrame(runnerSlot, runnerModel) or runnerModel:GetPivot()
		local runnerPos = GetGroundedPosition(runnerCFrame.Position, runnerModel)
		local attackDirection = MatchMotionMath.GetFlatDirection(runnerPos, goalTarget.Position)

		if attackDirection.Magnitude <= 0.001 and actorCFrame then
			attackDirection = GetFlatUnitFromLook(actorCFrame.LookVector)
		end

		if attackDirection.Magnitude <= 0.001 then
			attackDirection = Vector3.new(0, 0, -1)
		end

		local zone4Marker = nil
		if MatchZoneQuery.GetSupportAdvancePoint then
			zone4Marker = MatchZoneQuery.GetSupportAdvancePoint(4)
		end

		zone4Marker = zone4Marker
			or MatchZoneQuery.GetCarrierPoint(4)
			or MatchZoneQuery.GetZoneArea(4)
			or goalTarget

		if not zone4Marker then
			return nil, nil
		end

		local lateralDirection = getFlatLateralDirection(attackDirection)
		local sideSign = runnerSlot == 4 and 1 or -1
		local laneDistance = math.max(OFF_BALL_RUNNER_LANE_OFFSET or 4.0, 3.5)

		local targetPos = zone4Marker.Position
			+ (attackDirection * 7.5)
			+ (lateralDirection * sideSign * laneDistance)

		if GetFlatDistance(runnerPos, targetPos) <= 5.0 then
			targetPos = runnerPos
				+ (attackDirection * 14.0)
				+ (lateralDirection * sideSign * laneDistance)
		end

		targetPos = GetGroundedPosition(targetPos, runnerModel)
		return targetPos, attackDirection
	end

	function MatchPresentationController:_startFastForwardRunnerSprint(payload, runnerSlot, actorCFrame, speedOverride, durationOverride, options)
		if not payload or not runnerSlot then
			return nil
		end

		local runnerModel = self:_getControlledActorModel(runnerSlot)
		if not runnerModel then
			return nil
		end

		local targetPos = nil
		local attackDirection = nil

		if options and options.TargetBuilder then
			targetPos, attackDirection = options.TargetBuilder(runnerSlot, runnerModel, actorCFrame)
		elseif options and options.TargetMarker then
			targetPos = GetGroundedPosition(options.TargetMarker.Position, runnerModel)
			local currentCFrame = self:_getActorCurrentCFrame(runnerSlot, runnerModel) or runnerModel:GetPivot()
			attackDirection = MatchMotionMath.GetFlatDirection(currentCFrame.Position, targetPos)
		else
			targetPos, attackDirection = self:_buildZone4ForwardSprintTarget(runnerSlot, runnerModel, actorCFrame)
		end

		if not targetPos or not attackDirection or attackDirection.Magnitude <= 0.001 then
			warn("[ZONE3 RUNNER] missing target for slot", runnerSlot)
			return nil
		end
		self.ForwardRunnerTokens = self.ForwardRunnerTokens or {}
		self.ForwardRunnerTokens[runnerSlot] = (self.ForwardRunnerTokens[runnerSlot] or 0) + 1
		local runnerToken = self.ForwardRunnerTokens[runnerSlot]
		local sprintSpeed = speedOverride or 44.0

		self.ActiveForwardRunners = self.ActiveForwardRunners or {}
		self.ActiveForwardRunners[runnerSlot] = true

		if self:_isCompanionSlot(runnerSlot) then
			local actualTargetPos = targetPos
			if not (options and options.StopAtTarget == true) then
				actualTargetPos = GetGroundedPosition(targetPos + (attackDirection * 20.0), runnerModel)
			end

			local lookTarget = actualTargetPos + attackDirection
			local targetCFrame = MatchMotionMath.BuildFlatLookAtCFrame(actualTargetPos, lookTarget)

			local usedRuntime = self:_applyActorCFrame(
				runnerSlot,
				runnerModel,
				targetCFrame,
				{
					ExpectedAnimation = "Run",
					MoveSpeed = sprintSpeed,
					LookAtPosition = lookTarget,
					FacingMode = "LookAtPosition",
					KeepAnimationWhenReached = true,
				}
			)

			if usedRuntime then
				return runnerSlot
			end
		end

		task.spawn(function()
			local maxDuration = durationOverride or 1.85
			local startedAt = os.clock()

			while self:_isSessionActive(payload.SessionId)
				and runnerModel.Parent
				and self.ForwardRunnerTokens
				and self.ForwardRunnerTokens[runnerSlot] == runnerToken
				and not self.IsPreQteFrozen
				and os.clock() - startedAt <= maxDuration
			do
				local dt = RunService.RenderStepped:Wait()
				local scaledDt = self:_getScaledDeltaTime(dt)
				local currentCFrame = self:_getActorCurrentCFrame(runnerSlot, runnerModel) or runnerModel:GetPivot()
				local currentPos = GetGroundedPosition(currentCFrame.Position, runnerModel)

				if GetFlatDistance(currentPos, targetPos) <= 1.1 then
					if options and options.StopAtTarget == true then
						break
					end

					targetPos = GetGroundedPosition(currentPos + (attackDirection * 10.0), runnerModel)
				end

				local nextPos = select(1, StepFlatTowards(currentPos, targetPos, sprintSpeed, scaledDt))
				nextPos = GetGroundedPosition(nextPos, runnerModel)

				local lookTarget = ResolveSupportLookPosition(self, nextPos, nextPos + attackDirection, {
					ForceForward = true,
				})

				ApplyPivot(runnerModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, lookTarget))
				self:_playMotionAnimation(runnerModel, "Run", 1.0)
			end

			if self.ActiveForwardRunners then
				self.ActiveForwardRunners[runnerSlot] = nil
			end
		end)

		return runnerSlot
	end

	function MatchPresentationController:_startStep2NonReceiverArea3Sprint(payload, receiverSlot, actorCFrame)
		if not payload or tonumber(payload.StepIndex or payload.Step) ~= 2 then
			return nil
		end

		if payload.Action == "Dribble" and tonumber(payload.ActorSlot or payload.FromSlot) == 2 then
			return nil
		end

		local runnerSlot = self:_rememberZone3RunnerSlot(payload)
		if not runnerSlot then
			return nil
		end

		local numericReceiverSlot = tonumber(receiverSlot)
		local activeSlot = tonumber(payload.ActorSlot) or tonumber(payload.FromSlot) or tonumber(self.ActiveActorSlot)

		if runnerSlot == numericReceiverSlot or runnerSlot == activeSlot then
			return runnerSlot
		end

		return self:_startFastForwardRunnerSprint(payload, runnerSlot, actorCFrame, 44.0, 2.5)
	end

	function MatchPresentationController:_startStep3PasserOverlapSprint(payload, passerSlot, actorCFrame)
		if not payload or tonumber(payload.StepIndex or payload.Step) ~= 3 or payload.Action ~= "Pass" then
			return nil
		end

		local runnerSlot = self:_rememberZone3RunnerSlot(payload)
		local numericPasserSlot = tonumber(passerSlot)

		if numericPasserSlot ~= runnerSlot then
			return nil
		end

		return self:_startFastForwardRunnerSprint(payload, numericPasserSlot, actorCFrame, 20.0, 1.25, {
			TargetBuilder = function(slotNumber, runnerModel, sourceCFrame)
				return self:_buildZone3RunnerCarrySprintTarget(slotNumber, runnerModel, sourceCFrame)
			end,
			StopAtTarget = true,
		})
	end

	function MatchPresentationController:_startQte3ForwardRunner(payload, actorCFrame)
		local runnerSlot = self:_rememberZone3RunnerSlot(payload)
		self.QteLiveRunnerSlot = nil
		self.QteLiveShadowEnemySlot = nil
		return runnerSlot
	end

end
