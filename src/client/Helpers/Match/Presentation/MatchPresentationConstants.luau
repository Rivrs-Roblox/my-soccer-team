local Constants = {
	PLAYER_PROXY_NAME = "LocalMatchPlayerProxy",
	PRESENTATION_FOLDER_NAME = "LocalMatchPresentationRuntime",
	DEBUG_SPAWN_HANDOFF = false,

	ACTION_SPEEDS = {
		Approach = {
			-- Keep attacks fast and defenders visibly pressing.
			Dribble = { Actor = 23.0, Enemy = 20.5 },
			Pass = { Actor = 18.0, Enemy = 21.0 },
			Shoot = { Actor = 11.8, Enemy = 10.8 },
			Default = { Actor = 17.0, Enemy = 19.0 },
		},

		Resolve = {
			Dribble = { Actor = 25.0, Enemy = 14.0 },
			Default = { Actor = 16.0, Enemy = 13.5 },
		},
	},

	THRESHOLDS = {
		ActorArrive = 0.45,
		EnemyArrive = 0.70,
	},

	PRE_QTE_READY_SETTLE_FRAMES = 4,
	PRE_QTE_READY_EXTRA_EPSILON = 0.08,

	MOVEMENT_TUNING = {
		ActorSprintFarThreshold = 9.0,
		ActorSprintFarMultiplier = 1.55,

		EnemySprintFarThreshold = 16.0,
		EnemySprintFarMultiplier = 2.10,
		EnemySprintMidThreshold = 7.0,
		EnemySprintMidMultiplier = 1.55,

		EnemyPressureSlowdownDistance = 3.6,
		EnemyPressureCloseMultiplier = 1.0,
		EnemyPressureMaxSpeed = 36.0,
	},

	BALL_TRAVEL = {
		PassStudsPerSecond = 28,
		PassMinDuration = 0.68,
		PassMaxDuration = 1.10,
	},

	CUTSCENE_ACTOR_COLLISION_GROUP = "CutsceneActors",
	DEFAULT_TIME_SCALE = 1.0,

	-- // [ APPROACH / QTE ] // --

	APPROACH_FORWARD_PUSH_DISTANCE = 1.35,
	APPROACH_MIN_FORWARD_DISTANCE = 0.85,
	APPROACH_NEAR_TARGET_THRESHOLD = 2.5,
	CONTINUOUS_APPROACH_TARGET_DISTANCE = 18.0,

	QTE_TRIGGER_DISTANCE = 5.0,
	QTE_TRIGGER_DISTANCE_BUFFER = 0.85,
	QTE_FORCE_BOUNDARY_BUFFER = 5.5,
	QTE_FORCE_BOUNDARY_STEP3_BUFFER = 10.0,
	QTE_FORCE_BOUNDARY_SETTLE_DISTANCE = 2.35,
	QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET = 0.35,

	PRESS_CHASE_STOP_DISTANCE = 2.05,
	PRESS_CHASE_INTERCEPT_LEAD = 2.75,
	APPROACH_SEQUENCE_MAX_SECONDS = 6.0,

	PRESSURE_SWITCH_DISTANCE = 21.0,
	PRESSURE_SWITCH_DISTANCE_STEP_1 = 24.0,

	-- // [ RUNTIME SLOTS ] // --

	GOALKEEPER_RUNTIME_SLOT = 5,

	-- // [ ENEMY PRESSURE / RECOVERY ] // --

	SHADOW_MARK_SPEED = 12.5,
	THREAT_ZONE_FALLBACK_RADIUS = 8.0,

	RECOVERY_CHASE_SPEED = 15.0,
	RECOVERY_CHASE_STOP_BUFFER = 1.80,
	RECOVERY_CHASE_FACE_TIMEOUT = 2.00,

	DEFEATED_ENEMY_RECOVERY_SPEED = 13.5,
	DEFEATED_ENEMY_RECOVERY_DISTANCE = 16.0,
	DEFEATED_ENEMY_COVER_FRONT_DISTANCE = 6.5,
	DEFEATED_ENEMY_MIN_RECOVERY_FORWARD = 9.0,

	-- Enemy that has been beaten must keep visual recovery,
	-- but cannot chase close enough to erase the QTE result.
	-- Only movement speed is reduced; locomotion animation stays normal.
	BEATEN_ENEMY_SPEED_FACTOR = 0.62,
	BEATEN_ENEMY_MAX_SPEED = 10.25,
	BEATEN_ENEMY_MIN_GAP = 11.5,
	BEATEN_ENEMY_SIDE_RECOVERY = 7.25,
	BEATEN_ENEMY_CARRIER_LEASH_DISTANCE = 9.25,

	IDLE_ENEMY_RETREAT_SPEED = 7.5,
	IDLE_ENEMY_RUN_SPEED = 10.5,

	ENEMY_PATROL_SPEED = 8.8,
	ENEMY_PATROL_SWAY_DISTANCE = 2.4,
	ENEMY_PATROL_OSCILLATION_SPEED = 1.25,

	SHADOW_FOLLOW_DISTANCE = 10.0,
	SHADOW_LATE_UPDATE_SPEED = 9.5,
	SHADOW_LATERAL_OFFSET = 1.75,

	-- // [ ALLY PATROL / SUPPORT ] // --

	ALLY_PATROL_SPEED = 7.5,
	ALLY_PATROL_SWAY_DISTANCE = 2.6,
	ALLY_PATROL_OSCILLATION_SPEED = 1.15,

	POST_PHASE_ADVANCE_SPEED = 9.5,
	POST_PHASE_ADVANCE_STOP_BUFFER = 9.0,
	POST_PHASE_ADVANCE_MIN_DISTANCE = 0.35,

	RECEIVER_CATCH_UP_SPEED = 25.5,
	RECEIVER_MIN_FORWARD_DISTANCE = 13.5,
	RECEIVER_NEXT_QTE_BUFFER = 4.0,

	PASS_RECEIVE_LANE_OFFSET = 5.0,
	OFF_BALL_RUNNER_FORWARD_DISTANCE = 18.5,
	OFF_BALL_RUNNER_LANE_OFFSET = 7.0,

	-- // [ THROUGH PASS ] // --

	-- All successful passes are treated as lead passes so the receiver
	-- sprints into space instead of waiting flat-footed.
	THROUGH_PASS_DISTANCE_STEP_1 = 14.0,
	THROUGH_PASS_DISTANCE_STEP_2 = 18.0,
	THROUGH_PASS_DISTANCE_STEP_3 = 28.0,
	THROUGH_PASS_MAX_OVERSHOOT_STEP_3 = 3.0,

	-- Support faces the ball only when the ball is still behind.
	-- When opening lane or receiving a through pass, support faces goal-side.
	SUPPORT_FACE_BALL_BEHIND_BUFFER = 0.75,

	-- // [ CLEAR LANE / STRAFE ] // --

	-- Balanced clear-lane values.
	-- QTE1 pass widening is controlled inside MatchSupportDirector,
	-- so these values can stay readable without making actors leave the field.
	DRIBBLE_CLEAR_LANE_WIDTH = 8.0,
	DRIBBLE_CLEAR_FORWARD_PUSH = 15.0,
	DRIBBLE_CLEAR_SPEED = 20.0,
	DRIBBLE_CARRIER_CORRIDOR_RADIUS = 8.0,

	PASS_CLEAR_LANE_WIDTH = 8.5,
	PASS_CLEAR_FORWARD_PUSH = 17.0,
	PASS_CLEAR_SPEED = 20.5,
	PASS_RECEIVER_READY_LEAD = 3.0,

	SUPPORT_CLEAR_LANE_REACHED_DISTANCE = 0.75,
	SUPPORT_CLEAR_FORWARD_STEP = 7.0,
	SUPPORT_CLEAR_SIDE_KEEP_THRESHOLD = 2.0,
	SUPPORT_CLEAR_QTE3_LANE_BONUS = 1.5,
	SUPPORT_CLEAR_STABLE_OFFSET_X = 0.35,
	SUPPORT_CLEAR_STABLE_OFFSET_Z = 0.35,

	-- Used by idle / phase-passed support actors that still need to open space
	-- between QTE transitions, especially before QTE3.
	SUPPORT_CLEAR_IDLE_LANE_WIDTH = 7.5,
	SUPPORT_CLEAR_IDLE_FORWARD_STEP = 7.0,
	SUPPORT_CLEAR_SIDE_PUSH_STEP = 2.5,
	SUPPORT_CLEAR_MIN_OPEN_LANE_DISTANCE = 4.0,
	SUPPORT_CLEAR_IDLE_SPEED = 16.5,

	-- Defender reaction delay after a through pass.
	-- Receiver starts sprinting first, then defender turns/chases.
	PASS_DEFENDER_REACTION_DELAY = 0.10,
	PASS_DEFENDER_TURN_SECONDS = 0.06,
	PASS_DEFENDER_PRESS_AFTER_REACTION_SPEED = 22.5,
	PASS_DEFENDER_EARLY_PRESS_STOP_GAP = 3.25,
	PASS_DEFENDER_EARLY_PRESS_INTERCEPT_LEAD = 4.25,

	-- // [ ZONE 3 DEFENSIVE LINE ] // --




	-- // [ FALLBACK ANIMATION ] // --
-- // [ FALLBACK ANIMATION ] // --

FALLBACK_RUN_ANIMATION_ID = "rbxassetid://507767714",
FALLBACK_IDLE_ANIMATION_ID = "rbxassetid://507766666",

FALLBACK_STRAFE_LEFT_ANIMATION_ID = "rbxassetid://126267460286881",
FALLBACK_STRAFE_RIGHT_ANIMATION_ID = "rbxassetid://98650605890669",

MOTION_ANIMATION_CANDIDATES = {
	Run = { "Run", "Running", "Jogging", "Jog", "Walk", "Sprint" },
	Idle = { "Idle", "Idle1", "Stand" },

	StrafeLeft = {
		"Walk - Left",
		"WalkLeft",
		"StrafeLeft",
		"LeftWalk",
	},

	StrafeRight = {
		"Walk - Right",
		"WalkRight",
		"StrafeRight",
		"RightWalk",
	},
},
}

return Constants
