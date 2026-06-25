return function(MatchPresentationController, Context)
	local Services = Context.Services
	local Players = Services.Players
	local ReplicatedStorage = Services.ReplicatedStorage
	local RunService = Services.RunService
	local Workspace = Services.Workspace
	local Debris = Services.Debris
	local PhysicsService = Services.PhysicsService

	local Knit = Context.Knit
	local LocalPlayer = Context.LocalPlayer

	local MatchActorResolver = Context.MatchActorResolver
	local MatchSceneQuery = Context.MatchSceneQuery
	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath
	local MatchBallConfig = Context.MatchBallConfig
	local MatchAnimationHelper = Context.MatchAnimationHelper

	local Constants = Context.Constants
	local Utils = Context.Utils

	local PLAYER_PROXY_NAME = Constants.PLAYER_PROXY_NAME
	local PRESENTATION_FOLDER_NAME = Constants.PRESENTATION_FOLDER_NAME
	local ACTION_SPEEDS = Constants.ACTION_SPEEDS
	local THRESHOLDS = Constants.THRESHOLDS
	local PRE_QTE_READY_SETTLE_FRAMES = Constants.PRE_QTE_READY_SETTLE_FRAMES
	local PRE_QTE_READY_EXTRA_EPSILON = Constants.PRE_QTE_READY_EXTRA_EPSILON
	local MOVEMENT_TUNING = Constants.MOVEMENT_TUNING
	local BALL_TRAVEL = Constants.BALL_TRAVEL
	local CUTSCENE_ACTOR_COLLISION_GROUP = Constants.CUTSCENE_ACTOR_COLLISION_GROUP
	local APPROACH_FORWARD_PUSH_DISTANCE = Constants.APPROACH_FORWARD_PUSH_DISTANCE
	local APPROACH_MIN_FORWARD_DISTANCE = Constants.APPROACH_MIN_FORWARD_DISTANCE
	local APPROACH_NEAR_TARGET_THRESHOLD = Constants.APPROACH_NEAR_TARGET_THRESHOLD
	local CONTINUOUS_APPROACH_TARGET_DISTANCE = Constants.CONTINUOUS_APPROACH_TARGET_DISTANCE
	local SHADOW_MARK_SPEED = Constants.SHADOW_MARK_SPEED
	local THREAT_ZONE_FALLBACK_RADIUS = Constants.THREAT_ZONE_FALLBACK_RADIUS
	local QTE_TRIGGER_DISTANCE = Constants.QTE_TRIGGER_DISTANCE
	local QTE_TRIGGER_DISTANCE_BUFFER = Constants.QTE_TRIGGER_DISTANCE_BUFFER
	local QTE_FORCE_BOUNDARY_BUFFER = Constants.QTE_FORCE_BOUNDARY_BUFFER
	local QTE_FORCE_BOUNDARY_STEP3_BUFFER = Constants.QTE_FORCE_BOUNDARY_STEP3_BUFFER
	local QTE_FORCE_BOUNDARY_SETTLE_DISTANCE = Constants.QTE_FORCE_BOUNDARY_SETTLE_DISTANCE
	local QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET = Constants.QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET
	local PRESS_CHASE_STOP_DISTANCE = Constants.PRESS_CHASE_STOP_DISTANCE
	local PRESS_CHASE_INTERCEPT_LEAD = Constants.PRESS_CHASE_INTERCEPT_LEAD or 2.75
	local APPROACH_SEQUENCE_MAX_SECONDS = Constants.APPROACH_SEQUENCE_MAX_SECONDS
	local PRESSURE_SWITCH_DISTANCE = Constants.PRESSURE_SWITCH_DISTANCE
	local PRESSURE_SWITCH_DISTANCE_STEP_1 = Constants.PRESSURE_SWITCH_DISTANCE_STEP_1
	local GOALKEEPER_RUNTIME_SLOT = Constants.GOALKEEPER_RUNTIME_SLOT
	local RECOVERY_CHASE_SPEED = Constants.RECOVERY_CHASE_SPEED
	local RECOVERY_CHASE_STOP_BUFFER = Constants.RECOVERY_CHASE_STOP_BUFFER
	local RECOVERY_CHASE_FACE_TIMEOUT = Constants.RECOVERY_CHASE_FACE_TIMEOUT
	local DEFEATED_ENEMY_RECOVERY_SPEED = Constants.DEFEATED_ENEMY_RECOVERY_SPEED
	local DEFEATED_ENEMY_RECOVERY_DISTANCE = Constants.DEFEATED_ENEMY_RECOVERY_DISTANCE
	local DEFEATED_ENEMY_COVER_FRONT_DISTANCE = Constants.DEFEATED_ENEMY_COVER_FRONT_DISTANCE
	local DEFEATED_ENEMY_MIN_RECOVERY_FORWARD = Constants.DEFEATED_ENEMY_MIN_RECOVERY_FORWARD
	local IDLE_ENEMY_RETREAT_SPEED = Constants.IDLE_ENEMY_RETREAT_SPEED
	local IDLE_ENEMY_RUN_SPEED = Constants.IDLE_ENEMY_RUN_SPEED
	local ALLY_PATROL_SPEED = Constants.ALLY_PATROL_SPEED
	local ALLY_PATROL_SWAY_DISTANCE = Constants.ALLY_PATROL_SWAY_DISTANCE
	local ALLY_PATROL_OSCILLATION_SPEED = Constants.ALLY_PATROL_OSCILLATION_SPEED
	local ENEMY_PATROL_SPEED = Constants.ENEMY_PATROL_SPEED
	local ENEMY_PATROL_SWAY_DISTANCE = Constants.ENEMY_PATROL_SWAY_DISTANCE
	local ENEMY_PATROL_OSCILLATION_SPEED = Constants.ENEMY_PATROL_OSCILLATION_SPEED
	local SHADOW_FOLLOW_DISTANCE = Constants.SHADOW_FOLLOW_DISTANCE
	local SHADOW_LATE_UPDATE_SPEED = Constants.SHADOW_LATE_UPDATE_SPEED
	local SHADOW_LATERAL_OFFSET = Constants.SHADOW_LATERAL_OFFSET
	local POST_PHASE_ADVANCE_SPEED = Constants.POST_PHASE_ADVANCE_SPEED
	local POST_PHASE_ADVANCE_STOP_BUFFER = Constants.POST_PHASE_ADVANCE_STOP_BUFFER
	local POST_PHASE_ADVANCE_MIN_DISTANCE = Constants.POST_PHASE_ADVANCE_MIN_DISTANCE
	local RECEIVER_CATCH_UP_SPEED = Constants.RECEIVER_CATCH_UP_SPEED
	local RECEIVER_MIN_FORWARD_DISTANCE = Constants.RECEIVER_MIN_FORWARD_DISTANCE
	local RECEIVER_NEXT_QTE_BUFFER = Constants.RECEIVER_NEXT_QTE_BUFFER
	local PASS_RECEIVE_LANE_OFFSET = Constants.PASS_RECEIVE_LANE_OFFSET
	local OFF_BALL_RUNNER_FORWARD_DISTANCE = Constants.OFF_BALL_RUNNER_FORWARD_DISTANCE
	local OFF_BALL_RUNNER_LANE_OFFSET = Constants.OFF_BALL_RUNNER_LANE_OFFSET
	local FALLBACK_RUN_ANIMATION_ID = Constants.FALLBACK_RUN_ANIMATION_ID
	local FALLBACK_IDLE_ANIMATION_ID = Constants.FALLBACK_IDLE_ANIMATION_ID
	local MOTION_ANIMATION_CANDIDATES = Constants.MOTION_ANIMATION_CANDIDATES

	local GetRootPart = Utils.GetRootPart
	local ApplyPivot = Utils.ApplyPivot
	local ForceModelVisible = Utils.ForceModelVisible
	local IsEmbeddedBallVisual = Utils.IsEmbeddedBallVisual
	local GetSafeGroundOffset = Utils.GetSafeGroundOffset
	local GetGroundedY = Utils.GetGroundedY
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local StepFlatTowards = Utils.StepFlatTowards
	local MoveTowardsFlat = Utils.MoveTowardsFlat
	local ComputeBallTravelDuration = Utils.ComputeBallTravelDuration
	local BuildStableShootTarget = Utils.BuildStableShootTarget
	local GetActorAdaptiveSpeed = Utils.GetActorAdaptiveSpeed
	local GetEnemyAdaptiveSpeed = Utils.GetEnemyAdaptiveSpeed
	local BuildStableSeed = Utils.BuildStableSeed
	local BuildStableOffset = Utils.BuildStableOffset
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook
	local ClampTargetAhead = Utils.ClampTargetAhead
	local GetBallFocusPosition = Utils.GetBallFocusPosition

	local MatchShootTargetResolver = require(script.Parent.MatchShootTargetResolver)

	local PLAYER2_BRANCH_SOFT_BLOCK_SPEED = 10.0
	local PLAYER2_BRANCH_ENGAGE_SPEED = 20.0
	local PLAYER2_BRANCH_SOFT_BLOCK_BACK_OFFSET = 5.75
	local PLAYER2_BRANCH_INTERCEPT_LEAD = 5.25
	local PLAYER2_BRANCH_RELEASE_PROGRESS_RATIO = 0.62
	local PLAYER2_BRANCH_QTE_TRIGGER_DISTANCE = 7.5

function MatchPresentationController:_getZoneForward(stepIndex, fallbackPosition)
	local carrierPoint = MatchZoneQuery.GetCarrierPoint(stepIndex)
	local zoneArea = MatchZoneQuery.GetZoneArea(stepIndex)
	local goalTarget = MatchZoneQuery.GetGoalTarget() or MatchZoneQuery.GetSaveTarget()
	local origin = carrierPoint and carrierPoint.Position or (zoneArea and zoneArea.Position) or fallbackPosition

	if origin and goalTarget then
		local forward = MatchMotionMath.GetFlatDirection(origin, goalTarget.Position)
		if forward.Magnitude > 0.001 then
			return forward
		end
	end

	return Vector3.new(0, 0, -1)
end

function MatchPresentationController:_buildContinuousApproachTarget(payload, actorModel, currentPos, fallbackTargetPos, fallbackLookPos)
	if not currentPos then
		return fallbackTargetPos
	end

	local stepIndex = tonumber(payload and payload.StepIndex) or 1
	local goalTarget = MatchZoneQuery.GetGoalTarget() or MatchZoneQuery.GetSaveTarget()

	local forwardDirection = nil

	if goalTarget then
		forwardDirection = MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
	end

	if not forwardDirection or forwardDirection.Magnitude <= 0.001 then
		if fallbackLookPos then
			forwardDirection = MatchMotionMath.GetFlatDirection(currentPos, fallbackLookPos)
		end
	end

	if not forwardDirection or forwardDirection.Magnitude <= 0.001 then
		forwardDirection = self:_getZoneForward(stepIndex, currentPos)
	end

	if not forwardDirection or forwardDirection.Magnitude <= 0.001 then
		forwardDirection = Vector3.new(0, 0, -1)
	end

	local dynamicTargetPos = currentPos + (forwardDirection.Unit * CONTINUOUS_APPROACH_TARGET_DISTANCE)
	return GetGroundedPosition(dynamicTargetPos, actorModel)
end

function MatchPresentationController:_getZoneLateral(stepIndex, fallbackPosition)
	local forward = self:_getZoneForward(stepIndex, fallbackPosition)
	local right = forward:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude <= 0.001 then
		return Vector3.new(1, 0, 0)
	end
	return right.Unit
end

function MatchPresentationController:_buildFrontBlockPosition(actorTargetPos, goalTarget, enemyModel, actionName)
	local goalDirection = MatchMotionMath.GetFlatDirection(
		actorTargetPos,
		goalTarget and goalTarget.Position or (actorTargetPos + Vector3.new(0, 0, -1))
	)

	local blockDistance = 2.6
	if actionName == "Dribble" then
		blockDistance = 1.9
	elseif actionName == "Shoot" then
		blockDistance = 0.0
	end

	local closePos = actorTargetPos + (goalDirection * blockDistance)
	closePos = Vector3.new(closePos.X, actorTargetPos.Y, closePos.Z)

	return GetGroundedPosition(closePos, enemyModel)
end

function MatchPresentationController:_stepActorMovement(payload, actorModel, actorState, actorTargetPos, actorLookPos, actorSpeed, deltaTime, keepActorAdvancing, actorRunAnimation)
	local moveSpeed = GetActorAdaptiveSpeed(
		actorSpeed,
		actorState.Position,
		actorTargetPos,
		actorState.AllowSprint == true
	)
	local movingAnimation = actorRunAnimation or "Run"

	if actorState.IsDirectDriven then
		if not actorState.Reached then
			actorState.Position, actorState.Reached = StepFlatTowards(
				actorState.Position,
				actorTargetPos,
				moveSpeed,
				deltaTime
			)

			actorState.Position = GetGroundedPosition(actorState.Position, actorModel)

			self:_alignActorToLook(
				payload.ActorSlot,
				actorModel,
				actorState.Position,
				actorLookPos,
				movingAnimation,
				moveSpeed
			)

			if GetFlatDistance(actorState.Position, actorTargetPos) <= THRESHOLDS.ActorArrive then
				actorState.Position = GetGroundedPosition(actorTargetPos, actorModel)
				actorState.Reached = true
			end
		else
			actorState.Position = GetGroundedPosition(actorTargetPos, actorModel)

			local reachedAnimation = keepActorAdvancing and movingAnimation
				or ((payload.Action == "Shoot" or payload.Action == "Dribble") and movingAnimation or "Idle")

			self:_alignActorToLook(
				payload.ActorSlot,
				actorModel,
				actorState.Position,
				actorLookPos,
				reachedAnimation,
				moveSpeed
			)
			actorState.RuntimeReached = true
		end

		return
	end

	local shouldIssueTarget = not actorState.TargetIssued
	if keepActorAdvancing then
		local lastIssuedTarget = actorState.LastIssuedTargetPos
		local targetChanged = lastIssuedTarget == nil
			or GetFlatDistance(lastIssuedTarget, actorTargetPos) > 0.65
		local issueCooldownPassed = os.clock() - (actorState.LastTargetIssuedAt or 0) >= 0.08

		shouldIssueTarget = shouldIssueTarget
			or actorState.RuntimeReached == true
			or (targetChanged and issueCooldownPassed)
	end

	if shouldIssueTarget then
		self:_alignActorToLook(
			payload.ActorSlot,
			actorModel,
			GetGroundedPosition(actorTargetPos, actorModel),
			actorLookPos,
			movingAnimation,
			moveSpeed
		)
		actorState.TargetIssued = true
		actorState.LastIssuedTargetPos = actorTargetPos
		actorState.LastTargetIssuedAt = os.clock()
	end

	local runtimeCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
	if runtimeCFrame then
		actorState.Position = GetGroundedPosition(runtimeCFrame.Position, actorModel)
	end

	actorState.RuntimeReached = self:_hasActorReachedRuntimeTarget(payload.ActorSlot)
	actorState.Reached = actorState.RuntimeReached

	if actorState.RuntimeReached then
		if keepActorAdvancing then
			actorState.Reached = false
			actorState.RuntimeReached = false
			actorState.TargetIssued = false
			self:_playMotionAnimation(actorModel, movingAnimation, 1.0)
		else
			actorState.Position = GetGroundedPosition(actorTargetPos, actorModel)
			local reachedAnimation = (payload.Action == "Shoot" or payload.Action == "Dribble") and movingAnimation or "Idle"
			self:_alignActorToLook(
				payload.ActorSlot,
				actorModel,
				actorState.Position,
				actorLookPos,
				reachedAnimation,
				moveSpeed
			)
		end
	end
end

function MatchPresentationController:_stepEnemyMovement(enemyModel, enemyState, enemyTargetPos, lookAtPosition, enemySpeed, deltaTime)
	if not enemyModel then
		enemyState.Reached = true
		return
	end

	-- Keeper dikelola sepenuhnya oleh KeeperPresentationController.
	-- Skip semua animation override di sini agar idle/standby loop keeper tidak ditimpa.
	local enemyRuntimeSlot = self:_getEnemyRuntimeSlotFromModel(enemyModel)
	if enemyRuntimeSlot == GOALKEEPER_RUNTIME_SLOT
		or enemyModel.Name == "GoalKeeper"
		or enemyModel.Name == "Keeper"
	then
		enemyState.Reached = true
		return
	end

	enemyState.Position = GetGroundedPosition(enemyState.Position, enemyModel)

	if not enemyState.CanMove and enemyState.ShadowTargetResolver then
		local currentPos = enemyState.Position
		local shadowTargetPos, shadowLookPos = enemyState.ShadowTargetResolver()

		if shadowTargetPos then
			enemyState.Position = select(1, StepFlatTowards(
				enemyState.Position,
				shadowTargetPos,
				enemyState.ShadowSpeed or SHADOW_LATE_UPDATE_SPEED,
				deltaTime
			))

			enemyState.Position = GetGroundedPosition(enemyState.Position, enemyModel)
		end

		local shouldRun = shadowTargetPos ~= nil
		local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, enemyState.Position)
		local moveFallback = moveDirection.Magnitude > 0.001
			and (enemyState.Position + moveDirection)
			or (shadowLookPos or lookAtPosition or enemyState.Position)
		local finalLook = GetBallFocusPosition(self, moveFallback)

		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyState.Position, finalLook))

		self:_playMotionAnimation(enemyModel, shouldRun and "Run" or "Idle", 1.0)
		return
	end

	if enemyTargetPos == nil then
		enemyState.Reached = true
		local ballLookTarget = GetBallFocusPosition(self, lookAtPosition)
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyState.Position, ballLookTarget))
		return
	end

	local moveSpeed = GetEnemyAdaptiveSpeed(
		enemySpeed,
		enemyState.Position,
		enemyTargetPos,
		enemyState.AllowAdaptiveSprint == true
	)

	if enemyState.CanMove and not enemyState.Reached then
		local previousPos = enemyState.Position
		enemyState.Position, enemyState.Reached = StepFlatTowards(
			enemyState.Position,
			enemyTargetPos,
			moveSpeed,
			deltaTime
		)

		enemyState.Position = GetGroundedPosition(enemyState.Position, enemyModel)

		if GetFlatDistance(enemyState.Position, enemyTargetPos) <= THRESHOLDS.EnemyArrive then
			enemyState.Position = GetGroundedPosition(enemyTargetPos, enemyModel)
			enemyState.Reached = true
		end

		local moveDirection = MatchMotionMath.GetFlatDirection(previousPos, enemyState.Position)
		local moveFallback = moveDirection.Magnitude > 0.001
			and (enemyState.Position + moveDirection)
			or (lookAtPosition or enemyTargetPos)

		-- Pressing defenders should visually track the ball carrier, not only their own path.
		local liveLookTarget = lookAtPosition or GetBallFocusPosition(self, moveFallback) or moveFallback
		if enemyState.Reached then
			liveLookTarget = lookAtPosition or GetBallFocusPosition(self, enemyTargetPos) or enemyTargetPos
		end

		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyState.Position, liveLookTarget))

		local runSpeed = 1.0
		if moveSpeed >= 70 then
			runSpeed = 2.0
		elseif moveSpeed >= 50 then
			runSpeed = 1.75
		elseif moveSpeed >= 35 then
			runSpeed = 1.45
		elseif moveSpeed >= 20 then
			runSpeed = 1.20
		elseif moveSpeed >= 14 then
			runSpeed = 1.10
		end

		self:_playMotionAnimation(enemyModel, "Run", runSpeed)
	else
		local ballLookTarget = GetBallFocusPosition(self, lookAtPosition)
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyState.Position, ballLookTarget))
		self:_playMotionAnimation(enemyModel, enemyState.CanMove and "Run" or "Idle", enemyState.CanMove and 0.98 or 1.0)
	end
end
function MatchPresentationController:_glideEnemyToForcedQtePosition(payload, enemyModel, enemyState, forcedEnemyPos, actorPosition)
	if not enemyModel or not enemyState or not forcedEnemyPos or not actorPosition then
		return false
	end

	-- Keeper dikelola KeeperPresentationController, jangan override posisi/animasinya
	local enemyRuntimeSlotGlide = self:_getEnemyRuntimeSlotFromModel(enemyModel)
	if enemyRuntimeSlotGlide == GOALKEEPER_RUNTIME_SLOT
		or enemyModel.Name == "GoalKeeper"
		or enemyModel.Name == "Keeper"
	then 	 
		return false
	end

	local enemyRoot = GetRootPart(enemyModel)
	if not enemyRoot then
		return false
	end

	local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
	local maxSettleSeconds = 0.22
	local settleSpeed = math.max(QTE_FORCE_BOUNDARY_SETTLE_DISTANCE * 10, 22)
	local startedAt = os.clock()

	self:_playMotionAnimation(enemyModel, "Run", 1.0)

	while self:_isSessionActive(payload.SessionId)
		and enemyModel.Parent
		and not self.IsPreQteFrozen
		and os.clock() - startedAt < maxSettleSeconds
		and GetFlatDistance(currentPos, forcedEnemyPos) > THRESHOLDS.EnemyArrive
	do
		local deltaTime = RunService.RenderStepped:Wait()
		local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
		local nextPos = select(1, StepFlatTowards(currentPos, forcedEnemyPos, settleSpeed, scaledDeltaTime))
		nextPos = GetGroundedPosition(nextPos, enemyModel)

		local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, nextPos)
		local lookTarget = moveDirection.Magnitude > 0.001 and (nextPos + moveDirection) or actorPosition
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, lookTarget))
		currentPos = nextPos
	end

	enemyState.Position = GetGroundedPosition(currentPos, enemyModel)
	enemyState.CanMove = true
	enemyState.Reached = true

	ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyState.Position, actorPosition))
	return true
end

function MatchPresentationController:_runMovementSequence(payload, params)
	local speeds = self:_getSpeedConfig(params.SpeedGroupName, params.SpeedActionName or payload.Action)
	local actorMovementSpeed = tonumber(params.ActorMoveSpeed) or speeds.Actor

	local actorStartPos = GetGroundedPosition(params.ActorStartCFrame.Position, params.ActorModel)
	local enemyStartPos = GetGroundedPosition(
		params.EnemyStartPos or params.ActorStartCFrame.Position,
		params.EnemyModel
	)

	local actorState = {
		Position = actorStartPos,
		Reached = false,
		RuntimeReached = false,
		TargetIssued = false,
		LastIssuedTargetPos = nil,
		LastTargetIssuedAt = 0,
		IsDirectDriven = self:_isDirectDrivenActor(payload.ActorSlot),
		AllowSprint = params.ActorSprintAfterBeat == true,
	}

	local enemyState = {
		Position = enemyStartPos,
		CanMove = not (params.HoldEnemyUntilActorReady or params.EnemyReleaseResolver or params.ShadowTargetResolver),
		Reached = params.EnemyTargetPos == nil
			or GetFlatDistance(enemyStartPos, params.EnemyTargetPos) <= THRESHOLDS.EnemyArrive,
		AllowAdaptiveSprint = params.EnemyAdaptiveSprint == true,
		ShadowTargetResolver = params.ShadowTargetResolver,
		ShadowSpeed = params.ShadowSpeed,
	}

	if tonumber(payload.ActorSlot) == 1 then
		self:_playRigAnimation(
			params.ActorModel,
			params.ActorRunAnimation or "Run",
			params.ActorRunSpeed or 0.92
		)
	end

	if params.EnemyModel then
		local enemyRuntimeSlot = self._getEnemyRuntimeSlotFromModel and self:_getEnemyRuntimeSlotFromModel(params.EnemyModel)
		local isKeeper = enemyRuntimeSlot == GOALKEEPER_RUNTIME_SLOT
			or params.EnemyModel.Name == "GoalKeeper"
			or params.EnemyModel.Name == "Keeper"

		self:_playRigAnimation(
			params.EnemyModel,
			isKeeper and "Idle"
				or (enemyState.CanMove and (params.EnemyRunAnimation or "Run")
				or ((params.ShadowTargetResolver and (params.EnemyRunAnimation or "Run")) or (params.EnemyIdleAnimation or "Idle"))),
			isKeeper and 1.0
				or (enemyState.CanMove and (params.EnemyRunSpeed or 0.95)
				or ((params.ShadowTargetResolver and (params.ShadowRunSpeed or IDLE_ENEMY_RUN_SPEED)) or 1))
		)
	end

	if params.FollowBall then
		self:_beginBallFollow(params.ActorModel)
	end

	local startTime = os.clock()
	local qteTriggerDistance = params.QteTriggerDistance or QTE_TRIGGER_DISTANCE
	local forcedQteByBoundary = false

	while self:_isSessionActive(payload.SessionId) do
		local deltaTime = RunService.RenderStepped:Wait()

		if self.IsPreQteFrozen then
			break
		end

		local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

		local actorTargetPos = params.ActorTargetPos

		-- CarrierPoint is only a lane guide during confrontation approach.
		-- The current carrier, including companion receivers, must keep advancing
		-- until enemy pressure is close enough or the zone boundary forces QTE.
		local keepActorAdvancingUntilQte = params.KeepActorAdvancingUntilQte == true
			or (params.BreakOnConfrontation == true and payload.Action ~= "Shoot")

		if keepActorAdvancingUntilQte then
			actorTargetPos = self:_buildContinuousApproachTarget(
				payload,
				params.ActorModel,
				actorState.Position,
				params.ActorTargetPos,
				params.ActorLookPos
			)

			actorState.Reached = false
			actorState.RuntimeReached = false
		end

		self:_stepActorMovement(
			payload,
			params.ActorModel,
			actorState,
			actorTargetPos,
			params.ActorLookPos,
			actorMovementSpeed,
			scaledDeltaTime,
			keepActorAdvancingUntilQte,
			params.ActorRunAnimation or "Run"
		)

		if not enemyState.CanMove then
			local shouldReleaseEnemy = false

			if params.EnemyReleaseResolver then
				shouldReleaseEnemy = params.EnemyReleaseResolver(actorState.Position, actorState, enemyState) == true
			elseif params.HoldEnemyUntilActorReady then
				shouldReleaseEnemy = actorState.Reached and actorState.RuntimeReached
			end

			if shouldReleaseEnemy then
				enemyState.CanMove = true
				enemyState.Reached = false

				if params.EnemyModel then
					self:_playRigAnimation(
						params.EnemyModel,
						params.EnemyRunAnimation or "Run",
						params.EnemyRunSpeed or 0.95
					)
				end
			end
		end

		local liveEnemyTargetPos = params.EnemyTargetPos

		if params.EnemyTargetPosResolver then
			liveEnemyTargetPos = params.EnemyTargetPosResolver(actorState.Position, enemyState)
		end

		if params.EnemyTargetPosResolver and liveEnemyTargetPos then
			if GetFlatDistance(enemyState.Position, liveEnemyTargetPos) > (THRESHOLDS.EnemyArrive + 0.15) then
				enemyState.Reached = false
			end
		end

		local liveEnemySpeed = speeds.Enemy
		if params.EnemySpeedResolver then
			liveEnemySpeed = tonumber(params.EnemySpeedResolver(actorState.Position, enemyState, liveEnemyTargetPos))
				or liveEnemySpeed
		end

		self:_stepEnemyMovement(
			params.EnemyModel,
			enemyState,
			liveEnemyTargetPos,
			params.EnemyLookPosResolver and params.EnemyLookPosResolver(actorState.Position, enemyState) or actorState.Position,
			liveEnemySpeed,
			scaledDeltaTime
		)

		if params.BreakOnConfrontation then
			local enemyRoot = GetRootPart(params.EnemyModel)
			local enemyPosition = enemyRoot and enemyRoot.Position or enemyState.Position
			local confrontationAllowed = true
			if params.ConfrontationAllowedResolver then
				confrontationAllowed = params.ConfrontationAllowedResolver(actorState.Position, enemyState, enemyPosition) == true
			end

			local isClose = confrontationAllowed
				and enemyState.CanMove
				and self:_isConfrontationClose(actorState.Position, enemyPosition, qteTriggerDistance)
			local isBoundaryForced = confrontationAllowed
				and self:_shouldForceQteByZoneBoundary(payload, actorState.Position)

			if isClose or isBoundaryForced then
				forcedQteByBoundary = isBoundaryForced and not isClose

				if forcedQteByBoundary and params.EnemyModel then
					local forcedEnemyPos = self:_buildForcedQteEnemyPosition(
						payload,
						params.ActorModel,
						params.EnemyModel,
						actorState.Position,
						enemyPosition
					)

					if forcedEnemyPos then
						self:_glideEnemyToForcedQtePosition(
							payload,
							params.EnemyModel,
							enemyState,
							forcedEnemyPos,
							actorState.Position
						)
					end
				end

				break
			end
		else
			if actorState.Reached and actorState.RuntimeReached then
				if params.BreakOnActorReached or enemyState.Reached then
					break
				end
			end
		end

		if os.clock() - startTime >= (params.MaxDuration or APPROACH_SEQUENCE_MAX_SECONDS) then
			if params.BreakOnConfrontation then
				local timeoutConfrontationAllowed = true
				if params.ConfrontationAllowedResolver then
					timeoutConfrontationAllowed = params.ConfrontationAllowedResolver(actorState.Position, enemyState, enemyState.Position) == true
				end

				if not timeoutConfrontationAllowed then
					-- Player2 branch soft-blocking may intentionally last longer than the
					-- default approach duration while the carrier is still leaving the
					-- skipped lane. Do not force QTE before the authored release line.
					startTime = os.clock()
					continue
				end

				forcedQteByBoundary = true

				local enemyRoot = GetRootPart(params.EnemyModel)
				local enemyPosition = enemyRoot and enemyRoot.Position or enemyState.Position
				local forcedEnemyPos = self:_buildForcedQteEnemyPosition(
					payload,
					params.ActorModel,
					params.EnemyModel,
					actorState.Position,
					enemyPosition
				)

				if forcedEnemyPos and params.EnemyModel then
					self:_glideEnemyToForcedQtePosition(
						payload,
						params.EnemyModel,
						enemyState,
						forcedEnemyPos,
						actorState.Position
					)
				end

				break
			else
				break
			end
		end
	end

	return actorState.Position, enemyState.Position, forcedQteByBoundary
end

function MatchPresentationController:_buildApproachTargets(payload, actorModel, enemyModel, actorCurrentCFrame, enemyCurrentCFrame)
	local stepIndex = tonumber(payload.StepIndex) or 1
	local isShootAction = payload and payload.Action == "Shoot"
	local carrierPoint = isShootAction and MatchShootTargetResolver.GetCarrierPoint(actorCurrentCFrame and actorCurrentCFrame.Position or nil)
		or MatchZoneQuery.GetCarrierPoint(stepIndex)
	local goalTarget = isShootAction and MatchShootTargetResolver.GetCenterTarget()
		or MatchZoneQuery.GetGoalTarget()

	local allyOffset = isShootAction and Vector3.zero or self:_getCombinedSpawnOffset(
		payload.SessionId,
		stepIndex,
		payload.ActorSlot,
		1.10,
		1.20,
		1.10,
		11
	)

	local actorStartPos = actorCurrentCFrame.Position
	local actorTargetPos = actorStartPos

	if carrierPoint then
		actorTargetPos = carrierPoint.Position + allyOffset
	else
		local fallbackForward = MatchMotionMath.GetFlatDirection(
			actorStartPos,
			goalTarget and goalTarget.Position or (actorStartPos + Vector3.new(0, 0, -1))
		)

		actorTargetPos = actorStartPos + (fallbackForward * 8)
	end

	actorTargetPos = GetGroundedPosition(actorTargetPos, actorModel)

	local isPlayer2BranchPass = payload.Player2Branch == true or payload.PassMode == "Player2BranchPass"
	if isPlayer2BranchPass then
		local player2Target = MatchZoneQuery.GetPlayer2BranchTarget and MatchZoneQuery.GetPlayer2BranchTarget()
			or MatchZoneQuery.GetZoneMarker(4, "Player2Target")
			or MatchZoneQuery.GetCarrierPoint(4)

		if player2Target then
			actorTargetPos = GetGroundedPosition(player2Target.Position, actorModel)
		end
	end

	local preferredForward = MatchMotionMath.GetFlatDirection(
		actorStartPos,
		goalTarget and goalTarget.Position or (actorStartPos + Vector3.new(0, 0, -1))
	)

	if preferredForward.Magnitude <= 0.001 then
		preferredForward = self:_getZoneForward(stepIndex, actorStartPos)
	end

	if isPlayer2BranchPass then
		-- Keep the passer at the authored Zone04.Player2Target so the QTE4 defender
		-- can press the correct carrier instead of chasing the old continuous lane.
	elseif isShootAction and carrierPoint then
		actorTargetPos = GetGroundedPosition(carrierPoint.Position, actorModel)
	else
		-- Do not use actorCurrentCFrame.LookVector here.
		-- PlayerSpawn orientation can face the wrong way and cause the player to run in place.
		actorTargetPos = ClampTargetAhead(
			actorStartPos,
			actorTargetPos,
			preferredForward,
			APPROACH_MIN_FORWARD_DISTANCE
		)

		local currentToTargetDistance = GetFlatDistance(actorStartPos, actorTargetPos)
		if currentToTargetDistance <= APPROACH_NEAR_TARGET_THRESHOLD then
			actorTargetPos = actorTargetPos + (preferredForward * APPROACH_FORWARD_PUSH_DISTANCE)
		end

		actorTargetPos = GetGroundedPosition(actorTargetPos, actorModel)
	end

	local enemyHoldPos = GetGroundedPosition(enemyCurrentCFrame.Position, enemyModel)

	local enemyClosePos = nil
	if payload.Action == "Shoot" then
		enemyClosePos = enemyHoldPos
	else
		enemyClosePos = self:_buildFrontBlockPosition(
			actorTargetPos,
			goalTarget,
			enemyModel,
			payload.Action
		)
	end

	local actorLookPos = goalTarget and goalTarget.Position or (actorTargetPos + (preferredForward * 10))
	-- Commented out to face the enemy goal/keeper during QTE3 approach instead of the pass receiver
	--[[
	if isPlayer2BranchPass then
		local receiveTarget = MatchZoneQuery.GetPlayer4BranchReceiveTarget and MatchZoneQuery.GetPlayer4BranchReceiveTarget()
			or MatchZoneQuery.GetZoneMarker(4, "ReceiveTarget")
			or MatchZoneQuery.GetZoneMarker(4, "Player4Target")
		if receiveTarget then
			actorLookPos = receiveTarget.Position
		end
	end
	--]]
	actorLookPos = Vector3.new(actorLookPos.X, actorTargetPos.Y, actorLookPos.Z)

	return {
		ActorTargetPos = actorTargetPos,
		EnemyHoldPos = enemyHoldPos,
		EnemyClosePos = enemyClosePos,
		ActorLookPos = actorLookPos,
	}
end

function MatchPresentationController:_handleApproachStarted(payload)
	local actorModel = self:_getControlledActorModel(payload.ActorSlot)
	local enemyModel = nil

	if self._getActiveEnemyModelForPayload then
		enemyModel = self:_getActiveEnemyModelForPayload(payload)
	end

	enemyModel = enemyModel or MatchActorResolver.GetEnemyModelByStep(payload.EnemyStep)

	if not actorModel or not enemyModel then
		return
	end

	ForceModelVisible(actorModel)

	self:_waitForPreviousVisualStep(payload)

	if not self:_isSessionActive(payload.SessionId) then
		return
	end

	local stepIndex = tonumber(payload.StepIndex) or 0
	if stepIndex <= (tonumber(self.LastPreparedPreQteStepIndex) or 0) then
		return
	end

	self.ActiveActorSlot = tonumber(payload.ActorSlot) or 1
	if self._getActiveEnemyRuntimeSlotForPayload then
		self.ActiveEnemyRuntimeSlot = self:_getActiveEnemyRuntimeSlotForPayload(payload)
	end


	self.CurrentPresentationStepIndex = stepIndex

	-- New approach owns carrier movement from this point.
	-- Cancel the post-dribble bridge so two RenderStepped loops do not fight over the same actor.
	if self._cancelDribbleContinuation then
		self:_cancelDribbleContinuation("approach-start")
	end

	self:_refreshCutsceneCollisionGroups()
	self:_stopSupportMotion()
	self:_animateIdleEnemies(payload.SessionId)
	self:_animateIdleAllies(payload.SessionId)
	self:_hideNonCarrierEmbeddedBalls(self.ActiveActorSlot)

	self.IsApproachBusy = true

	local actorRoot = GetRootPart(actorModel)
	local enemyRoot = GetRootPart(enemyModel)

	if self.MatchBallController and self.MatchBallController.BeginPresentationStep then
		self.MatchBallController:BeginPresentationStep(payload.StepIndex)
	end

	if not actorRoot or not enemyRoot then
		self.IsApproachBusy = false
		return
	end

	local actorCurrentCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel) or actorRoot.CFrame
	local enemyCurrentCFrame = enemyRoot.CFrame


	local targets = self:_buildApproachTargets(
		payload,
		actorModel,
		enemyModel,
		actorCurrentCFrame,
		enemyCurrentCFrame
	)

	local groundedActorStartPos = GetGroundedPosition(actorCurrentCFrame.Position, actorModel)
	self:_alignActorToLook(
		payload.ActorSlot,
		actorModel,
		groundedActorStartPos,
		targets.ActorLookPos,
		"Idle",
		0
	)
	self:_playMotionAnimation(actorModel, "Idle", 1.0)
	for _ = 1, 2 do
		if not self:_isSessionActive(payload.SessionId) then
			self.IsApproachBusy = false
			return
		end
		RunService.RenderStepped:Wait()
	end
	actorCurrentCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel) or actorCurrentCFrame

	local enemyRuntimeSlot = self.ActiveEnemyRuntimeSlot
	local enemyStepIndex = tonumber(payload.EnemyStep) or tonumber(payload.StepIndex) or 1


	local shouldFirstEnemyPatrol = payload.Action ~= "Shoot" and stepIndex == 1
	local shouldShadowBeforePress = payload.Action ~= "Shoot" and stepIndex > 1

	local function resolveShadowTarget()
		local liveEnemyRoot = GetRootPart(enemyModel)
		local fallbackPos = liveEnemyRoot and liveEnemyRoot.Position or enemyCurrentCFrame.Position

		return self:_buildShadowMarkPosition(
			tonumber(payload.StepIndex) or enemyStepIndex,
			enemyModel,
			tonumber(payload.ActorSlot),
			payload.SessionId,
			enemyRuntimeSlot or enemyStepIndex,
			os.clock(),
			fallbackPos
		)
	end

	local function resolveFirstEnemyPatrolTarget()
		local liveEnemyRoot = GetRootPart(enemyModel)
		local currentPos = liveEnemyRoot and GetGroundedPosition(liveEnemyRoot.Position, enemyModel)
			or GetGroundedPosition(enemyCurrentCFrame.Position, enemyModel)

		local targetPos = self:_buildVerticalLanePatrolPosition(
			1,
			enemyModel,
			payload.SessionId,
			1,
			os.clock(),
			currentPos
		)

		if not targetPos then
			return currentPos, currentPos + enemyCurrentCFrame.LookVector
		end

		local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, targetPos)
		local lookTarget = moveDirection.Magnitude > 0.001
			and (currentPos + moveDirection)
			or (currentPos + enemyCurrentCFrame.LookVector)

		return targetPos, lookTarget
	end

	local function resolveWaitingTarget()
		return resolveShadowTarget()
	end

	local isPlayer2BranchPass = payload.Player2Branch == true
		or payload.PassMode == "Player2BranchPass"

	local player2BranchTarget = nil
	local player2BranchReleasePoint = nil
	local player2BranchPathDirection = nil
	local player2BranchReleaseProgress = nil
	local player2BranchSoftBlockPos = nil
	local player2BranchStartPos = GetGroundedPosition(actorCurrentCFrame.Position, actorModel)

	if isPlayer2BranchPass then
		player2BranchTarget = MatchZoneQuery.GetPlayer2BranchTarget
			and MatchZoneQuery.GetPlayer2BranchTarget()
			or MatchZoneQuery.GetZoneMarker(4, "Player2Target")
			or MatchZoneQuery.GetCarrierPoint(4)

		player2BranchReleasePoint = MatchZoneQuery.GetZoneMarker(4, "EntryPoint")
			or MatchZoneQuery.GetZoneArea(4)
			or MatchZoneQuery.GetZoneMarker(4, "Player2Target")
			or player2BranchTarget

		if player2BranchTarget then
			player2BranchPathDirection = MatchMotionMath.GetFlatDirection(
				player2BranchStartPos,
				player2BranchTarget.Position
			)
		end

		if not player2BranchPathDirection or player2BranchPathDirection.Magnitude <= 0.001 then
			local goalTarget = MatchZoneQuery.GetGoalTarget()
			player2BranchPathDirection = goalTarget
				and MatchMotionMath.GetFlatDirection(player2BranchStartPos, goalTarget.Position)
				or GetFlatUnitFromLook(actorCurrentCFrame.LookVector)
		end

		if not player2BranchPathDirection or player2BranchPathDirection.Magnitude <= 0.001 then
			player2BranchPathDirection = Vector3.new(0, 0, -1)
		end

		local pathUnit = player2BranchPathDirection.Unit
		local pathLength = player2BranchTarget
			and GetFlatDistance(player2BranchStartPos, player2BranchTarget.Position)
			or 0

		local releaseProgressFromMarker = nil
		if player2BranchReleasePoint then
			local releaseDelta = Vector3.new(
				player2BranchReleasePoint.Position.X - player2BranchStartPos.X,
				0,
				player2BranchReleasePoint.Position.Z - player2BranchStartPos.Z
			)

			releaseProgressFromMarker = releaseDelta:Dot(pathUnit)
		end

		local releaseProgressFromPath = pathLength > 0
			and (pathLength * PLAYER2_BRANCH_RELEASE_PROGRESS_RATIO)
			or nil

		if releaseProgressFromMarker and releaseProgressFromPath then
			player2BranchReleaseProgress = math.min(releaseProgressFromMarker, releaseProgressFromPath)
		else
			player2BranchReleaseProgress = releaseProgressFromMarker or releaseProgressFromPath
		end

		local softBlockAnchor = player2BranchReleasePoint or player2BranchTarget
		if softBlockAnchor then
			local blockPos = softBlockAnchor.Position - (pathUnit * PLAYER2_BRANCH_SOFT_BLOCK_BACK_OFFSET)
			player2BranchSoftBlockPos = GetGroundedPosition(blockPos, enemyModel)
		end
	end

	local function hasPlayer2BranchReachedRelease(currentActorPos)
		if not isPlayer2BranchPass or not currentActorPos then
			return true
		end

		if player2BranchPathDirection
			and player2BranchPathDirection.Magnitude > 0.001
			and player2BranchReleaseProgress ~= nil
		then
			local actorDelta = Vector3.new(
				currentActorPos.X - player2BranchStartPos.X,
				0,
				currentActorPos.Z - player2BranchStartPos.Z
			)

			if actorDelta:Dot(player2BranchPathDirection.Unit) >= (player2BranchReleaseProgress - 0.75) then
				return true
			end
		end

		if player2BranchReleasePoint
			and GetFlatDistance(currentActorPos, player2BranchReleasePoint.Position) <= 6.5
		then
			return true
		end

		if player2BranchTarget then
			return GetFlatDistance(currentActorPos, player2BranchTarget.Position) <= 9.0
		end

		return self:_shouldReleaseEnemyPressure(payload, currentActorPos, enemyModel)
	end

	local function resolveLiveEnemyChaseTarget(currentActorPos, enemyState)
		if not currentActorPos then
			return targets.EnemyClosePos
		end

		local currentEnemyPos = enemyState and enemyState.Position
			or (GetRootPart(enemyModel) and GetRootPart(enemyModel).Position)
			or enemyCurrentCFrame.Position

		if isPlayer2BranchPass then
			if not hasPlayer2BranchReachedRelease(currentActorPos) then
				-- Soft-block mode: enemy 4 moves into an authored blocking lane,
				-- but does not chase Player2 directly and cannot open QTE yet.
				return player2BranchSoftBlockPos or targets.EnemyHoldPos
			end

			local interceptForward = nil
			if player2BranchTarget then
				interceptForward = MatchMotionMath.GetFlatDirection(currentActorPos, player2BranchTarget.Position)
			end

			if not interceptForward or interceptForward.Magnitude <= 0.001 then
				local goalTarget = MatchZoneQuery.GetGoalTarget()
				interceptForward = goalTarget
					and MatchMotionMath.GetFlatDirection(currentActorPos, goalTarget.Position)
					or GetFlatUnitFromLook(actorCurrentCFrame.LookVector)
			end

			if not interceptForward or interceptForward.Magnitude <= 0.001 then
				interceptForward = Vector3.new(0, 0, -1)
			end

			local interceptPos = currentActorPos + (interceptForward.Unit * PLAYER2_BRANCH_INTERCEPT_LEAD)
			return GetGroundedPosition(interceptPos, enemyModel)
		end

		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local attackDirection = goalTarget
			and MatchMotionMath.GetFlatDirection(currentActorPos, goalTarget.Position)
			or GetFlatUnitFromLook(actorCurrentCFrame.LookVector)

		local toActor = MatchMotionMath.GetFlatDirection(currentEnemyPos, currentActorPos)
		if toActor.Magnitude <= 0.001 then
			return GetGroundedPosition(currentActorPos, enemyModel)
		end

		if attackDirection.Magnitude > 0.001 and toActor:Dot(attackDirection) >= -0.15 then
			return GetGroundedPosition(
				currentActorPos + (attackDirection * PRESS_CHASE_INTERCEPT_LEAD),
				enemyModel
			)
		end

		local chasePos = currentActorPos - (toActor * PRESS_CHASE_STOP_DISTANCE)
		return GetGroundedPosition(chasePos, enemyModel)
	end

	local isShootAction = payload.Action == "Shoot"

	local enemyTargetPosResolver = nil
	local enemyReleaseResolver = nil
	local shadowTargetResolver = nil
	local shadowSpeed = SHADOW_MARK_SPEED
	if not isShootAction then
		enemyTargetPosResolver = function(currentActorPos, enemyState)
			if enemyState and enemyState.CanMove then
				return resolveLiveEnemyChaseTarget(currentActorPos, enemyState)
			end

			return targets.EnemyHoldPos
		end

		if isPlayer2BranchPass then
			-- Start soft-blocking immediately, but gate the actual QTE trigger
			-- until Player2 reaches the Zone04 release line.
			enemyReleaseResolver = nil
			shadowTargetResolver = nil
		else
			enemyReleaseResolver = function(currentActorPos)
				return self:_shouldReleaseEnemyPressure(payload, currentActorPos, enemyModel)
			end

			if shouldFirstEnemyPatrol then
				shadowTargetResolver = resolveFirstEnemyPatrolTarget
				shadowSpeed = ENEMY_PATROL_SPEED
			elseif shouldShadowBeforePress then
				shadowTargetResolver = resolveWaitingTarget
				shadowSpeed = SHADOW_MARK_SPEED
			end
		end
	end

	local finalActorPos, finalEnemyPos, forcedQteByBoundary = self:_runMovementSequence(payload, {
		SpeedGroupName = "Approach",
		SpeedActionName = payload.Action,

		ActorModel = actorModel,
		EnemyModel = enemyModel,

		ActorStartCFrame = actorCurrentCFrame,
		ActorTargetPos = targets.ActorTargetPos,
		ActorLookPos = targets.ActorLookPos,

		EnemyStartPos = targets.EnemyHoldPos,
		EnemyTargetPos = targets.EnemyClosePos,

		EnemyTargetPosResolver = enemyTargetPosResolver,
		EnemyReleaseResolver = enemyReleaseResolver,
		ShadowTargetResolver = shadowTargetResolver,
		ShadowSpeed = shadowSpeed,
		EnemySpeedResolver = isPlayer2BranchPass and function(currentActorPos)
			return hasPlayer2BranchReachedRelease(currentActorPos)
				and PLAYER2_BRANCH_ENGAGE_SPEED
				or PLAYER2_BRANCH_SOFT_BLOCK_SPEED
		end or nil,
		ConfrontationAllowedResolver = isPlayer2BranchPass and function(currentActorPos)
			return hasPlayer2BranchReachedRelease(currentActorPos)
		end or nil,

		FollowBall = true,
		ActorRunAnimation = payload.Action == "Dribble" and "Dribble" or "Run",
		ActorRunSpeed = payload.Action == "Dribble" and 1.0 or nil,
		EnemyIdleAnimation = "Idle",
		EnemyRunAnimation = "Run",
		EnemyAdaptiveSprint = true,

		BreakOnConfrontation = payload.Action ~= "Shoot",
		KeepActorAdvancingUntilQte = payload.Action ~= "Shoot",
		QteTriggerDistance = isPlayer2BranchPass
			and math.max(QTE_TRIGGER_DISTANCE, PLAYER2_BRANCH_QTE_TRIGGER_DISTANCE)
			or QTE_TRIGGER_DISTANCE,
		MaxDuration = isPlayer2BranchPass
			and math.max(APPROACH_SEQUENCE_MAX_SECONDS, 3.15)
			or APPROACH_SEQUENCE_MAX_SECONDS,
	})

	finalActorPos = GetGroundedPosition(finalActorPos, actorModel)
	finalEnemyPos = GetGroundedPosition(finalEnemyPos, enemyModel)

	if payload.Action == "Shoot" then
		local fixedShootCarrierPoint = MatchShootTargetResolver.GetCarrierPoint(finalActorPos)
		local fixedShootLookPosition = MatchShootTargetResolver.ResolveShootLookPosition()
		if fixedShootCarrierPoint then
			finalActorPos = GetGroundedPosition(fixedShootCarrierPoint.Position, actorModel)
		end
		if fixedShootLookPosition then
			targets.ActorLookPos = Vector3.new(fixedShootLookPosition.X, finalActorPos.Y, fixedShootLookPosition.Z)
		end
	end

	local postApproachActorAnimation = payload.Action == "Shoot" and "Run"
		or (payload.Action == "Dribble" and "Dribble")
		or "Run"

	self:_alignActorToLook(
		payload.ActorSlot,
		actorModel,
		finalActorPos,
		targets.ActorLookPos,
		postApproachActorAnimation,
		payload.Action == "Shoot" and 0.06 or 1.0
	)

	self:_setKeeperFocusWorldPosition(finalActorPos)

	ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(finalEnemyPos, finalActorPos))

	-- Do not force Idle here. The pre-QTE freeze director will hold the current pose.
	-- Forcing Idle before QTE creates the perceived post-dribble pause.

	self:_waitForPreQteReady(
		payload,
		actorModel,
		finalActorPos,
		enemyModel,
		finalEnemyPos,
		forcedQteByBoundary == true or isPlayer2BranchPass
	)

	if not self:_isSessionActive(payload.SessionId) then
		self.IsApproachBusy = false
		return
	end

	local settledActorCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
	if settledActorCFrame then
		finalActorPos = settledActorCFrame.Position
	end

	local settledEnemyRoot = GetRootPart(enemyModel)
	if settledEnemyRoot then
		finalEnemyPos = settledEnemyRoot.Position
	end

	finalActorPos = GetGroundedPosition(finalActorPos, actorModel)
	finalEnemyPos = GetGroundedPosition(finalEnemyPos, enemyModel)

	if payload.Action == "Shoot" then
		local fixedShootCarrierPoint = MatchShootTargetResolver.GetCarrierPoint(finalActorPos)
		local fixedShootLookPosition = MatchShootTargetResolver.ResolveShootLookPosition()
		if fixedShootCarrierPoint then
			finalActorPos = GetGroundedPosition(fixedShootCarrierPoint.Position, actorModel)
		end
		if fixedShootLookPosition then
			targets.ActorLookPos = Vector3.new(fixedShootLookPosition.X, finalActorPos.Y, fixedShootLookPosition.Z)
		end
	end

	self:_setKeeperFocusWorldPosition(finalActorPos)

	self:_applyActorCFrame(
		payload.ActorSlot,
		actorModel,
		MatchMotionMath.BuildFlatLookAtCFrame(finalActorPos, targets.ActorLookPos),
		{
			ExpectedAnimation = postApproachActorAnimation,
			FacingMode = "Idle",
			LookAtPosition = targets.ActorLookPos,
		}
	)

	ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(finalEnemyPos, finalActorPos))

	self:_preparePreQtePresentation(payload, actorModel, enemyModel)
	self:_applyPreQteHoldPose(payload, actorModel, enemyModel)
	self:_waitForSessionFrames(payload.SessionId, 2)

	-- QTE enters slow motion here. Step3 overlap/shadow motion starts only after resolve,
	-- never while the QTE UI is waiting for player input.
	self.QteLiveRunnerSlot = nil
	self.QteLiveShadowEnemySlot = nil

	self:_freezeActorsForPreQte(actorModel, enemyModel, payload)

	self.LastPreparedPreQteStepIndex = math.max(
		tonumber(self.LastPreparedPreQteStepIndex) or 0,
		stepIndex
	)

	self:_notifyPresentationReady(payload.StepIndex, "PreQte")

	self.IsApproachBusy = false
end
end
