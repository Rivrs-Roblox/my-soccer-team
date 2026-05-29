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

function MatchPresentationController:_beginBallFollow(actorModel)
	self:_hideNonCarrierEmbeddedBalls(self.ActiveActorSlot)

	if self.MatchBallController then
		task.spawn(function()
			self.MatchBallController:FollowActor(actorModel)
		end)
	end
end

function MatchPresentationController:_getBallStartPosition(actorRoot)
	if self.MatchBallController and self.MatchBallController.GetBallPosition then
		local position = self.MatchBallController:GetBallPosition()
		if position then
			return position
		end
	end

	return actorRoot.Position + Vector3.new(0, -2.5, 0)
end

function MatchPresentationController:_holdBallAtFinalPose(finalWorldPosition)
	if not self.MatchBallController or not finalWorldPosition then
		return
	end

	if self.MatchBallController.StopFollow then
		self.MatchBallController:StopFollow()
	end

	if self.MatchBallController.ClearTrail then
		self.MatchBallController:ClearTrail()
	end

	if self.MatchBallController.SetBallWorldPosition then
		self.MatchBallController:SetBallWorldPosition(finalWorldPosition)
	end
end
end
