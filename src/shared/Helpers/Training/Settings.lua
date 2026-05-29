return {
	XSpacing = 5,
	ZSpacing = 3,
	PlayerSpacing = 1.5,
	RaycastSpeed = 25,

	GroundSpeed = 10,
	GroundMaxHeight = 0.5,
	GroundForwardAngle = math.rad(10),
	GroundBackwardAngle = math.rad(-10),

	Shoot = {
		MoveToShootDuration = 0.38,
		ReadyToShootDuration = 0.26,
		ShootDuration = 0.68,
		ImpactProgress = 0.68, -- Progress (0-1) in Shooting phase when the ball is launched
		ExitRightDuration = 0.28,
		ReturnBackDuration = 0.34,
		RejoinDuration = 0.30,
		SettleDuration = 0.18,
	},

	Dribble = {
		StartHoldDuration = 0.50,
		NodeDuration = 0.70,
		Exit01Duration = 0.20,
		Exit02Duration = 4.00,
		RejoinDuration = 3.00,
	},

	Pass = {
		StartDelay = 1.5, -- Wait for characters to walk to position before starting
		PassDuration = 0.60,
		SettleDuration = 0.65,
		ImpactProgress = 0.68, -- Progress (0-1) in Pass phase when the ball is launched
	},
}
