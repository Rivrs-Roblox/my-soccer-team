local MatchBallConfig = {
	ReceiveOffset = CFrame.new(0, -1.96, -2.1),
	PassOffset = CFrame.new(0, -1.96, -1.85),
	ShootOffset = CFrame.new(0, -1.96, -1.95),

	PassLandingHeight = 0.95,
	PassArcHeightSuccess = 2,
	PassArcHeightFail = 3,

	PassFlight = {
		StartHeight = 1.15,
		EndHeight = 1.15,
		MinArcHeight = 1.25,
		MaxArcHeight = 2.25,
		ArcDistanceScale = 0.12,
		LateralArcMultiplier = 0.85,
		TrailLinger = 0.25,
	},

	Dribble = {
		Forward = 1.55,
		Side = 0.42,
		Height = -2.4,
		WaveSpeedSide = 4.4,
		WaveSpeedHeight = 6.2,
		WaveBob = 0.05,
		FollowLerpSpeed = 40.0,
		SnapDistance = 1.5,
		LookBlendSpeed = 6.0,
	},

	EpicShot = {
	DurationPhase1 = 1.0,
	DurationPhase2 = 0.5,
	HeightPhase1 = 2.35,
	HeightPhase2 = 0.25,
	SlowmoScale = 0.2,
},

	GoalFx = {
		EmitCount = 24,
	},

	HoldEffectEmitCount = 28,
}

return MatchBallConfig
