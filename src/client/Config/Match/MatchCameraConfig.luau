local MatchCameraConfig = {
	-- Single camera profile for the entire match.
	-- No per-zone switching. Camera follows the ball smoothly.
	Follow = {
		Height = 10,
		BehindDistance = 15,
		SideOffset = 3,
		ForwardLook = 16,
		LookHeight = 4,
		BallLookAlpha = 0.35,
		BallHeightAlpha = 0.15,
		BallSubjectAlpha = 0.85,
	},

	ShootPushIn = {
		Height = 8,
		BehindDistance = 12,
		SideOffset = 2,
		ForwardLook = 24,
		LookHeight = 4.5,
		BallLookAlpha = 0.40,
		BallHeightAlpha = 0.22,
		BallSubjectAlpha = 0.72,
	},

	BallTrackingEnabled = true,
	TrackingLerpSpeed = 0.13,
	QteTrackingLerpSpeed = 0.055,
	ShootSlowMoLerpMultiplier = 1.55,

	PerfectActionBoost = {
		Enabled = true,

		Pass = {
			Yellow = {
				Duration = 0.28,
				FovKick = 2.4,
				DollyForward = 0.55,
				LeadDistance = 0,
				SideSway = 0,
				Lift = 0,
				LookAhead = 0,
				LookBlend = 0,
				LookHeight = 2.8,
			},

			Green = {
				Duration = 0.38,
				FovKick = 4.4,
				DollyForward = 0.95,
				LeadDistance = 0,
				SideSway = 0,
				Lift = 0.03,
				LookAhead = 0,
				LookBlend = 0,
				LookHeight = 2.8,
			},
		},

		Dribble = {
			Yellow = {
				Duration = 0.24,
				FovKick = 2.8,
				DollyForward = 0.75,
				LeadDistance = 0.35,
				SideSway = 0.05,
				Lift = 0.03,
				LookAhead = 1.2,
				LookBlend = 0.05,
				LookHeight = 3,
			},

			Green = {
				Duration = 0.36,
				FovKick = 7,
				DollyForward = 1.6,
				LeadDistance = 1.2,
				SideSway = 0.35,
				Lift = 0.08,
				LookAhead = 4,
				LookBlend = 0.14,
				LookHeight = 3,
			},
		},
	},

	SideTrackingClamp = 6,

	GoalShake = {
		Intensity = 4.5,
		Duration = 1.5,
	},
}

return MatchCameraConfig
