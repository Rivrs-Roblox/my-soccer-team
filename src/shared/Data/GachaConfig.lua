local GachaConfig = {
	General = {
		InitialBlur = { Intensity = 5, Duration = 0.2 },
		CleanupBlurDuration = 0.2,
		RefillInterval = 60 * 3,
	},
	Characters = {
		DepthOfField = { Intensity = 0.75, Duration = 0.5 },
		Pack = {
			Spawn = {
				Position = CFrame.new(0, -7, -5),
				Rotation = CFrame.Angles(0, math.rad(180), 0),
			},
			Reveal = {
				Position = CFrame.new(0, 0, -9),
				Duration = 0.6,
			},
			Dismiss = {
				Duration = 0.8,
				CardOffset = CFrame.new(0, 15, 0),
				PackOffset = CFrame.new(0, -15, 0),
			},
		},
		Cards = {
			EntranceDuration = 0.6,
			Roll = {
				Duration = 1,
				Interval = 0.05,
			},
			RevealBounce = {
				ZoomInZ = -7,
				ZoomOutZ = -8,
				InDuration = 0.35,
				OutDuration = 0.4,
			},
			Shake = {
				Intensity = 3.5,
				Magnitude = 4.5,
				Duration = 0.45,
			},
			Exit = {
				Duration = 0.6,
				Offset = Vector3.new(30, 0, 0),
			},
		},
	},
	Accessories = {
		Chest = {
			InitialSize = UDim2.fromScale(0.7, 0.7),
			ExpandedSize = UDim2.fromScale(0.85, 0.85),
			Shake = {
				Duration = 1,
				Speed = 0.07,
				Rotation = 10,
			},
		},
		Effect = {
			InitialSize = UDim2.fromScale(1.5, 1.5),
			RotationDuration = 10,
		},
		Item = {
			InitialSize = UDim2.fromScale(0.5, 1.5),
			RevealDuration = 0.6,
			WaitDuration = 1,
		},
		Transition = {
			WaitAfterChestOpen = 1,
			CloseDuration = 0.4,
			FinalCleanupWait = 0.4,
		},
	},
}

return GachaConfig
