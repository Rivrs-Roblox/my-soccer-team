local MatchAnimationConfig = {
	FadeTime = 0.12,

	RunSpeed = {
		-- Decouple locomotion animation from tactical movement speed.
		-- Low movement speed should still look like a normal run, not slow motion.
		ReferenceMoveSpeed = 16,
		Min = 1.0,
		Max = 1.18,
		Sprint = 1.12,
	},

	Candidates = {
		Idle = {
			"Idle",
			"Idle1",
			"Stand",
		},

		Run = {
			"Run",
			"Running",
			"Jogging",
			"Jog",
			"Walk",
			"Sprint",
		},

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

		Dribble = {
			"Dribble",
			"Run",
		},

		Jump = {
			"Jump",
			"Fall",
		},

		Fall = {
			"Fall",
			"Jump",
		},

		Shoot = {
			"Shoot",
			"Shoot - Training",
			"Shoot - Penalty",
			"Shoot - Special",
			"Pass",
		},

		Pass = {
			-- Pass wind-up uses shoot variants first because most characters already have these.
			"Shoot",
			"Shoot - Training",
			"Shoot - Penalty",
			"Shoot - Special",
			"Pass",
		},

		Win = {
			"Win1",
			"Win2",
			"Win",
		},

		Lose = {
			"Lose1",
			"Lose2",
			"Lose",
		},
	},

	FallbackIds = {
		Idle = "rbxassetid://507766388",
		Run = "rbxassetid://105106002784990",

		StrafeLeft = "rbxassetid://126267460286881",
		StrafeRight = "rbxassetid://98650605890669",

		Dribble = "rbxassetid://105106002784990",
		Jump = "rbxassetid://507765000",
		Fall = "rbxassetid://507767968",
		Shoot = "rbxassetid://90962989306225",
		Pass = "rbxassetid://90962989306225",
	},

	Looped = {
		Idle = true,
		Idle1 = true,
		Stand = true,

		Run = true,
		Running = true,
		Jogging = true,
		Jog = true,
		Walk = true,
		Sprint = true,

		StrafeLeft = true,
		StrafeRight = true,
		["Walk - Left"] = true,
		["Walk - Right"] = true,
		WalkLeft = true,
		WalkRight = true,
		LeftWalk = true,
		RightWalk = true,

		Dribble = true,
		Jump = false,
		Fall = true,

		Shoot = false,
		["Shoot - Training"] = false,
		["Shoot - Penalty"] = false,
		["Shoot - Special"] = false,
		Pass = false,

		Win = false,
		Win1 = false,
		Win2 = false,

		Lose = false,
		Lose1 = false,
		Lose2 = false,
	},
}

return MatchAnimationConfig
