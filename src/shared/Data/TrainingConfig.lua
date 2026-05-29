--[=[
	Owner: Shakthi
	Version: v1.0.0
	Description: Configuration for training visuals and logic.
]=]

local TrainingConfig = {
	-- Animation IDs
	Animations = {
		DefaultIdle = "rbxassetid://507766388",
		DefaultRun = "rbxassetid://105106002784990",
		DefaultJump = "rbxassetid://507765000",
		DefaultFall = "rbxassetid://507767968",
		DefaultShoot = "rbxassetid://90962989306225",
	},

	-- Visual Parameters
	Visuals = {
		TrailLifetime = 0.22,
		TrailMinLength = 0.05,
		BallTweenTime = 0.55,
		GoalBurstEmitCount = 20,
	},

	-- Proxy Movement
	Proxy = {
		MoveSpeed = 16,
		RunThreshold = 0.08,
	},

	-- Training Logic Thresholds
	Thresholds = {
		ShootReadyDistance = 0.45,
		PassTriggerProgress = 0.20,
		PassBallTweenTime = 0.30,
		DribbleNodeSwitchDistance = 0.90,
	}
}

return TrainingConfig
