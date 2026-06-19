local MatchKeeperConfig = {
	ReadyAdvance = 0,
	ReadyTweenDuration = 0.14,

	-- Keeper-only visual timing. Ball timing stays owned by MatchShootDirector.
	DiveDuration = 0.34,
	FallDuration = 0.22,
	RecoverDuration = 0.38,
	WrongGuessDelay = 0.10,
	ResultPoseDuration = 0.58,

	-- Artist scaled keeper to 1.3 in Workspace.
	-- We compensate only the keeper root movement, not the shot ball timing.
	KeeperVisualScale = 1.30,
	KeeperScaleCompensationEnabled = true,
	KeeperScaleCompensationStrength = 0.45,

	-- Save timing starts after the ball has visibly travelled.
	-- Contact moment is finalized by animation markers when available.
	SaveReactionDelay = 0.22,
	SaveContactHold = 0.10,

	-- Animation marker names for keeper v1 contact sync.
	CatchContactMarkerName = "CatchContact",
	SaveContactMarkerName = "SaveContact",
	CatchBallHoldDuration = 5.00,
	CatchShakeStrength = 1.35,
	CatchShakeDuration = 0.35,
	CatchKeeperPoseHold = 1.10,
	KeeperContactFallbackPadding = 0.35,

	-- V4 keeper save stabilization.
	-- All successful keeper saves are catch-locks first: the ball attaches to the keeper grip
	-- after contact instead of using a free parry/rebound. This prevents ghost rebounds,
	-- second dive corrections, and floating ball/keeper race conditions.
	CatchLockAllKeeperWins = true,
	KeeperCatchLockContactMinDelayAlpha = 0.82,
	KeeperCatchLockContactMinDelayPadding = 0.03,
	KeeperCatchLockFallbackTravelAlpha = 1.08,
	KeeperCenterCatchUseMovingMidpoint = true,
	ForceCenterSaveDefendFront = true,
	DisableLowKeeperSaveTargets = true,

	-- Center player-win power breakthrough.
	-- Keeper catches the center ball at the hands, then physics ragdolls from the impact
	-- as the ball continues into goal.
	PowerBreakthroughEnabled = true,
	PowerBreakthroughTiers = {
		Red = true,
		Yellow = true,
		Green = true,
	},
	PowerBreakthroughContactMarkerName = "CatchContact",
	PowerBreakthroughFallbackFreezeAlpha = 0.82,
	PowerBreakthroughBallHoldDuration = 0.40,
	PowerBreakthroughContinueDelay = 0.44,
	PowerBreakthroughContinueAfterRagdollDelay = 0.04,
	PowerBreakthroughContinueDuration = 0.42,
	PowerBreakthroughContinueArcHeight = 0.36,
	PowerBreakthroughCarryToShotTargetEnabled = false,
	PowerBreakthroughCarryToShotTargetDuration = 0.36,
	PowerBreakthroughInterceptLift = 0.05,
	PowerBreakthroughCarryTargetBackoff = 0.55,
	PowerBreakthroughCarryTargetMaxDistance = 5.5,
	PowerBreakthroughCarryLeanAngle = math.rad(5),
	PowerBreakthroughKnockbackDistance = 3.85,
	PowerBreakthroughKnockbackLift = 0.00,
	PowerBreakthroughKnockbackDuration = 0.34,
	PowerBreakthroughKeeperHoldAfterContact = 0.00,
	PowerBreakthroughFallbackDelay = 0.42,
	PowerBreakthroughFallbackTravelAlpha = 1.08,
	PowerBreakthroughHoldReleasePadding = 0.04,
	PowerBreakthroughKnockdownHoldDuration = 0.15,
	PowerBreakthroughRagdollEnabled = true,
	PowerBreakthroughRagdollDirectionSign = -1,
	PowerBreakthroughRagdollUseGoalTargetDirection = true,
	PowerBreakthroughUsePhysicsRagdoll = true,
	PowerBreakthroughAnchorAllRagdollParts = false,
	PowerBreakthroughRagdollCanCollide = false,
	PowerBreakthroughRagdollApplyVelocity = true,
	PowerBreakthroughRagdollHorizontalSpeed = 0.3,
	PowerBreakthroughRagdollSideSpeed = 0.1,
	PowerBreakthroughRagdollUpwardSpeed = 0.00,
	PowerBreakthroughRagdollAngularSpeed = 0.1,
	PowerBreakthroughRagdollCeilingHeight = 0.35,
	PowerBreakthroughRagdollMaxPartLift = 0.65,
	PowerBreakthroughRagdollCeilingGuardDuration = 0.15,
	PowerBreakthroughRagdollRootMinY = -0.04,
	PowerBreakthroughRagdollRootMaxY = 0.24,
	PowerBreakthroughRagdollMaxVerticalLift = 0.05,
	PowerBreakthroughGroundedFallDuration = 0.24,
	PowerBreakthroughGroundedFallPitch = math.rad(82),
	PowerBreakthroughGroundedFallRoll = math.rad(5),
	PowerBreakthroughRagdollPreDriftEnabled = false,
	PowerBreakthroughRagdollPreDriftDistance = 0.0,
	PowerBreakthroughRagdollPreDriftDuration = 0.0,
	PowerBreakthroughRagdollPreDriftLeanAngle = math.rad(0),
	PowerBreakthroughFallBackAngle = math.rad(0),
	PowerBreakthroughFallSideAngle = math.rad(0),
	PowerBreakthroughBallSpinWhileHeld = true,
	PowerBreakthroughUseExactGripTarget = true,
	PowerBreakthroughBallGripLiftOffset = 0.00,
	PowerBreakthroughBallHoldSpinSpeed = 54.0,
	PowerBreakthroughContactImpactEmitCount = 1,
	PowerBreakthroughContactImpactLifetime = 0.15,
	PowerBreakthroughPerfectRagdollDelay = 0.00,
	PowerBreakthroughShakeStrength = 0.15,
	PowerBreakthroughShakeDuration = 0.10,
	PowerBreakthroughGoalImpactShakeStrength = 0.12,
	PowerBreakthroughGoalImpactShakeDuration = 0.10,
	PowerBreakthroughCarryExtraHold = 0.00,
	PowerBreakthroughNoRecover = true,
	PowerBreakthroughKnockbackSign = -1,
	PowerBreakthroughControlledLeanBackAngle = math.rad(10),
	PowerBreakthroughBallForwardOffset = 0.62,
	PowerBreakthroughBallLiftOffset = 0.00,
	PowerBreakthroughDisableKeeperCollision = true,
	PowerBreakthroughCollisionEnabled = false,
	PowerBreakthroughTouchEnabled = false,

	-- Distance gate prevents the ball from teleporting to the keeper hand if the marker fires early.
	KeeperContactSnapMaxDistance = 2.35,
	KeeperContactBlendMaxDistance = 6.50,
	KeeperContactBlendDuration = 0.10,


	-- Goal target impact fall. This remains separate from center breakthrough contact ragdoll.
	GoalImpactRagdollEnabled = true,
	GoalImpactUsePhysicsRagdoll = true,
	GoalImpactRagdollUseFacingDirection = true,
	GoalImpactRagdollHorizontalSpeed = 16.0,
	GoalImpactRagdollSideSpeed = 5.5,
	GoalImpactRagdollUpwardSpeed = 0.00,
	GoalImpactRagdollAngularSpeed = 5.5,
	GoalImpactRagdollMaxPartLift = 0.70,
	GoalImpactRagdollRootMinY = -0.04,
	GoalImpactRagdollRootMaxY = 0.30,
	GoalImpactRagdollHoldDuration = 8.00,
	GoalImpactEmitCount = 96,
	GoalImpactLifetime = 1.00,
	GoalImpactShakeStrength = 3.20,
	GoalImpactShakeDuration = 0.75,
	GoalImpactSideHorizontalSpeedScale = 0.62,
	GoalImpactSideSideSpeedScale = 0.58,
	GoalImpactSideAngularSpeedScale = 0.58,
	GoalImpactSideMaxUpwardSpeed = 0.35,
	GoalImpactSideEmitCount = 42,
	GoalImpactSideLifetime = 0.62,
	GoalImpactSideShakeStrength = 1.85,
	GoalImpactSideShakeDuration = 0.42,
	GoalImpactSideLandingNeutralizeDuration = 0.30,
	GoalImpactSideLandingShakeStrength = 0.85,
	GoalImpactSideLandingShakeDuration = 0.18,

	-- Goal finish polish: after reaching the goal target, the ball falls/bounces down instead of freezing mid-air.
	GoalBallDropEnabled = true,
	GoalBallDropDelay = 0.04,
	GoalBallDropDuration = 0.42,
	GoalBallDropDistance = 5.20,
	GoalBallDropBounceHeight = 0.35,


	SaveForwardAdvance = 2.20,
	SaveCenterForwardAdvance = 1.45,
	SaveCenterWidth = 1.15,
	SaveCenterLift = 0.72,
	SaveCenterContactLift = 0.62,
	SaveHighCenterThreshold = 2.05,
	SaveSideMin = 1.15,
	SaveSideMax = 10.50,
	SaveTierLateralScale = {
		Red = 1.00,
		Yellow = 1.00,
		Green = 1.00,
	},

	-- From your latest debug: +1 matches this map/keeper orientation for ROOT MOVEMENT.
	DiveLateralSign = 1,

	-- Animation side can be flipped independently from movement because the keeper rig
	-- faces the opposite direction from the attacker in this map. If root movement is
	-- correct but DefendLeft/DefendRight looks visually reversed, keep this at -1.
	DiveAnimationLateralSign = -1,

	-- V29: root movement and animation choice are already correct. Only the physical
	-- roll/tilt direction was visually reversed on side saves, so flip roll separately.
	SideSaveRollLateralSign = -1,
	GoalDiveRollLateralSign = -1,

	-- After a successful keeper save/parry, hold the final dive pose instead of
	-- recovering to the center. Cleanup/teleport will reset the keeper later.
	KeepSavePoseUntilCleanup = true,
	SavePoseHoldDuration = 6.00,
	SaveFreezeAnimationAtLanded = true,

	-- Scale-aware root reach. Do not move root to the raw ball point; the 1.3x body/arms provide reach.
	SaveRootLateralScale = 0.84,
	SaveRootLateralMin = 0.90,
	SaveRootLateralMax = 5.25,
	SaveRootForwardScale = 0.62,
	SaveForwardMin = 0.70,
	SaveForwardMax = 2.35,

	-- Goal case: keeper under-reaches but still follows the shot side.
	GoalRootLateralScale = {
		Red = 0.70,
		Yellow = 0.58,
		Green = 0.46,
	},

	-- Lift / roll tuned for large keeper. Lower lift prevents floaty saves.
	SaveLift = 0.88,
	SaveLowLift = 0.38,
	SaveMidLift = 0.72,
	SaveHighLift = 1.20,
	SaveRollAngle = math.pi / 2.28,
	SaveLandedRollScale = 1.00,

	SaveInterceptDistance = 1.15,
	SaveReboundDistance = 5.5,

	-- Kept for compatibility with MatchShootDirector block/rebound calculation.
	SaveBlockLateralMax = 5.20,
	SaveBlockForward = 1.75,
	SaveBlockHeightLow = 1.05,
	SaveBlockHeightCenter = 1.40,
	SaveBlockHeightHigh = 2.20,
	SaveBlockHeightMax = 2.65,
	SaveReboundHeight = 0.55,
	SaveReboundSideMin = 2.8,
	SaveReboundSideMax = 7.2,
	SaveReboundBackMin = 2.4,
	SaveReboundBackMax = 6.4,
	SaveReboundArcHeight = 0.75,
	SaveReboundDuration = 0.62,
	SaveReboundDelayPadding = 0.00,

	GoalSameSideMin = 0.42,
	GoalSameSideMax = 2.35,
	GoalWrongSide = 2.00,
	GoalForwardAdvance = 0.55,
	GoalLift = 0.90,
	GoalRollAngle = math.pi / 3.25,

	-- V24: explicit keeper save markers and grip-based catch tuning.
	UseKeeperSaveTargets = true,
	UseKeeperLandingTargets = true,
	KeeperLandingTargetFolderName = "KeeperLandingTargets",
	KeeperSaveTargetGripRootEnabled = true,
	KeeperSaveTargetGripRootAlpha = 1.00,
	KeeperSaveTargetRootMaxDistance = 14.00,
	KeeperSaveTargetRootMinLift = 0.00,
	KeeperSaveTargetRootMaxLift = 5.00,
	KeeperSaveTargetFolderName = "KeeperSaveTargets",
	KeeperUseGripAttachmentsForCatch = true,
	KeeperCenterCatchPreferGrip = true,
	KeeperSaveTargetLateralRootScale = 0.92,
	KeeperSaveTargetForwardRootScale = 0.82,
	KeeperSaveTargetLiftScale = 0.92,
	CenterCatchHoldUntilCleanup = true,

	-- V27: side-save contact correction. Movement already goes to KeeperSaveTargets;
	-- this final correction is disabled to prevent snapping or "racing" when the keeper catches the ball.
	KeeperSaveTargetContactGripCorrectionEnabled = false,
	KeeperSaveTargetContactCorrectionAlpha = 1.00,
	KeeperSaveTargetContactMaxCorrection = 7.50,

	-- V30 keeper stability: center/front saves should not float above the goal
	-- or release physics before the match cleanup. These are visual-only guards.
	KeeperSafePoseHoldUntilCleanup = true,
	KeeperSafetyMaxRootLift = 2.40,
	KeeperSafetyMaxDistanceFromBase = 18.00,
	CenterSaveGroundedKnockdownEnabled = true,
	CenterSaveGroundedKnockdownUseRagdoll = true,
	CenterSaveRootMaxLift = 1.10,
	CenterSaveKnockdownBackDistance = 1.25,
	CenterSaveKnockdownLift = 0.04,
	CenterSaveKnockdownDuration = 0.18,
	CenterSaveKnockdownBackAngle = math.rad(76),
	CenterSaveKnockdownSideAngle = math.rad(6),
	ParryContactMinDelayScale = 0.94,
	CatchContactMinDelayScale = 0.72,
	ParryHoldAtContactPose = true,
	FreezeSaveAnimationAtContact = true,
	SaveAnimationFreezeMinTimePosition = 0.28,
	SideSaveLandedLift = 0.85,

	-- PBS-style keeper tracking for GoalHold.
	-- Keeper stays idle until ball is within this radius (studs), then starts dive.
	GoalHoldKeeperReactRadius = 12,
	GoalHoldFallbackFreezeAlpha = 0.72,
	-- How far (studs) in front of KeeperSaveTarget the ball stops at holdPos.
	-- Must be > GoalForwardAdvance (0.55) so ball lands in front of keeper body, not behind.
	GoalHoldForwardOffset = 1.75,
	-- At actual keeper contact, snap the held ball from the authored holdPos to the
	-- resolved hand/grip position. Small forward offset keeps the ball readable in
	-- front of the palm instead of being buried in the hand mesh.
	GoalHoldBallHandForwardOffset = 0.22,
	GoalHoldCenterBallHandForwardOffset = 0.42,
	GoalHoldCenterHandForwardOffset = 0.90,
	GoalHoldCenterHandLiftOffset = 0.08,
	GoalHoldHandSnapMaxDistance = 12.0,
	GoalHoldHandSnapBlendDuration = 0.22,
	GoalHoldHandRetargetMinDuration = 0.16,
	GoalHoldHandRetargetMaxDuration = 0.32,
	GoalHoldExtraHoldDuration = 0.25,

	GoalFxEmitCount = 28,
	DebugReaction = false,

	IdleAnimId = "rbxassetid://113017315265290",
	DiveLeftAnimId = "rbxassetid://136718124207643",
	DiveRightAnimId = "rbxassetid://123312152720841",
	DefendFrontAnimId = "rbxassetid://90411393987746",
	DefendUpAnimId = "rbxassetid://116365709224220",
	WinAnimId = "rbxassetid://507766388",
	LoseAnimId = "rbxassetid://507766388",
}

return MatchKeeperConfig
