--!strict

--[[
	MatchActorLookConfig

	Client-only visual configuration for procedural upper-body/head look-at
	during match presentation.

	Important:
	- This must not rotate HumanoidRootPart.
	- This must not affect path movement.
	- This must not affect match result logic.
	- This is visual polish only.
]]

local MatchActorLookConfig = {
	Enabled = true,

	Debug = false,

	-- Keep keeper excluded for now to avoid conflicting with keeper save/dive presentation.
	ExcludeKeeper = true,

	-- If the look direction is reversed in-game, flip this value to -1 or 1.
	-- Default is -1 because Roblox character rigs often need inverted local yaw
	-- depending on how C0/C1 is authored.
	YawSign = -1,

	-- Maximum horizontal look rotation in degrees.
	MaxUpperBodyYawDegrees = 45,
	MaxHeadYawDegrees = 90,

	-- Optional pitch limits. Kept small to avoid ugly neck bending.
	MaxHeadPitchDegrees = 12,
	MaxUpperBodyPitchDegrees = 5,

	-- Smoothing speed. Higher = faster response, lower = smoother.
	SmoothSpeed = 20,

	-- If target is too close, skip to avoid unstable rotation.
	MinTargetDistance = 3,

	-- If target is too far, still allow look-at but clamp normally.
	MaxTargetDistance = 300,

	-- How much of the yaw goes to upper body first.
	-- Remaining yaw is handled by the head.
	UpperBodyYawWeight = 0.45,

	-- Pitch weight distribution.
	UpperBodyPitchWeight = 0.25,
	HeadPitchWeight = 0.75,

	-- Natural idle return speed when no valid target exists.
	ReturnToNeutralSpeed = 10,

	-- Target preferences.
	Targeting = {
		-- For MVP, most actors can track the match ball.
		UseBallAsPrimaryTarget = true,

		-- Ball carrier should not over-twist backward because it can look weird
		-- while dribbling/running forward.
		CarrierLookStrength = 0.0,

		-- Companions can look more clearly toward the ball.
		CompanionLookStrength = 0.85,

		-- Enemies can look clearly toward the carrier/ball.
		EnemyLookStrength = 0.85,

		-- Keeper is disabled by ExcludeKeeper for now.
		KeeperLookStrength = 0.0,
	},

	-- Joint names used by R15 rigs.
	R15 = {
		UpperTorsoName = "UpperTorso",
		LowerTorsoName = "LowerTorso",
		HeadName = "Head",

		WaistMotorName = "Waist",
		NeckMotorName = "Neck",
	},

	-- Fallback search settings for custom rigs.
	Fallback = {
		SearchDescendants = true,
		AllowedWaistMotorNames = {
			"Waist",
			"Root",
			"RootJoint",
		},
		AllowedNeckMotorNames = {
			"Neck",
		},
	},
}

return MatchActorLookConfig
