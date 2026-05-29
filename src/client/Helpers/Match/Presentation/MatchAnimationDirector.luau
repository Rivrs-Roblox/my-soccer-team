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
	local DEFAULT_TIME_SCALE = Constants.DEFAULT_TIME_SCALE
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

function MatchPresentationController:_playCompanionResultAnimations(success, mainSlot)
	for slotNum = 2, 4 do
		if slotNum ~= tonumber(mainSlot) then
			local companionModel = self:_getControlledActorModel(slotNum)
			if companionModel then
				self:_playRigAnimation(companionModel, success and "Win" or "Lose", 1.0)
			end
		end
	end
end

function MatchPresentationController:_isModelFrozenForQte(model)
	return self.IsPreQteFrozen == true
		and model ~= nil
		and self.FrozenRigModels ~= nil
		and self.FrozenRigModels[model] == true
end

function MatchPresentationController:_playRigAnimation(model, animationName, speed, fadeTime)
	if self:_isModelFrozenForQte(model) then
		self:_pauseRigAnimation(model)
		return nil
	end

	return MatchAnimationHelper.Play(self.AnimationStates, model, animationName, {
		speed = self:_getScaledAnimationSpeed(speed),
		fadeTime = fadeTime,
	})
end

function MatchPresentationController:_playMotionAnimation(model, requestedName, speed)
	if not model then
		return nil
	end

	if self:_isModelFrozenForQte(model) then
		self:_pauseRigAnimation(model)
		return nil
	end

	local helperTrack = self:_playRigAnimation(model, requestedName, speed or 1.0)
	if helperTrack then
		return helperTrack
	end

	local fallbackName = requestedName

	if requestedName == "StrafeLeft" or requestedName == "StrafeRight" or requestedName == "Dribble" then
		fallbackName = "Run"
	elseif requestedName ~= "Run" and requestedName ~= "Idle" then
		fallbackName = "Idle"
	end

	local fallbackTrack = self:_playRigAnimation(model, fallbackName, speed or 1.0)
	if fallbackTrack then
		return fallbackTrack
	end

	return nil
end

function MatchPresentationController:_pauseRigAnimation(model)
	if not model then
		return
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		-- Hold the current animation pose for QTE.
		-- Do not Stop(0), because stopping resets many rigs back to idle/T-pose.
		track:AdjustSpeed(0)
	end
end

function MatchPresentationController:_resumeRigAnimation(model)
	if not model then return end
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then return end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:AdjustSpeed(1)
	end
end

function MatchPresentationController:_stopAllRigAnimations()
	MatchAnimationHelper.StopAll(self.AnimationStates)
	table.clear(self.AnimationStates)
end

function MatchPresentationController:_playPassBlockedReaction(enemyModel, lookAtPosition)
	if not enemyModel then
		return
	end

	local enemyRoot = GetRootPart(enemyModel)
	if enemyRoot and lookAtPosition then
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(enemyRoot.Position, lookAtPosition))
	end

	-- Immediate upper-body style block reaction.
	self:_playRigAnimation(enemyModel, "Jump", 0.92)
end

function MatchPresentationController:_schedulePassBlockedReaction(payload, enemyModel, lookAtPosition, delaySeconds)
	if not enemyModel then
		return
	end

	task.delay(math.max(delaySeconds or 0, 0), function()
		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		local liveLookAt = lookAtPosition
		if self.MatchBallController and self.MatchBallController.GetBallPosition then
			local liveBallPos = self.MatchBallController:GetBallPosition()
			if liveBallPos then
				liveLookAt = liveBallPos
			end
		end

		self:_playPassBlockedReaction(enemyModel, liveLookAt)
	end)
end
end
