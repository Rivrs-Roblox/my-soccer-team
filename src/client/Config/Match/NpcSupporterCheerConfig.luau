local NpcSupporterCheerConfig = {
	Debug = false,

	-- Runtime area visual is cloned from ReplicatedStorage.Assets.MapAreas.AreaXX
	-- into Workspace by AreaVisual. These paths intentionally support both the
	-- current project layout and the older reference layout from another project.
	AreaFolderNamePattern = "Area%02d",
	ResolveFolderTimeout = 8,
	ResolveFolderPollInterval = 0.1,

	-- Ambient cheer runs only on animated supporter folders while a match session
	-- is active. Static NPC folders must stay idle outside goal celebration.
	AmbientEnabled = true,
	AmbientFolderPaths = {
		{ "NPCAnim" },
		{ "Environments", "NPCAnim" },
	},
	AmbientMaxActiveNpcs = 95,
	AmbientJumpHeight = 1.5,
	AmbientJumpHeightVariation = 0.4,
	AmbientUpDuration = 0.28,
	AmbientDownDuration = 0.32,
	AmbientDurationVariation = 0.25,
	AmbientStartOffsetStep = 0.18,
	AmbientStartOffsetRandom = 0.35,
	AmbientRestTimeMin = 0.15,
	AmbientRestTimeMax = 0.45,

	-- Goal cheer is a one-shot burst for both animated and static supporter
	-- folders. Static NPCs return to their original pivot and stay idle after it.
	GoalEnabled = true,
	GoalFolderPaths = {
		{ "NPCAnim" },
		{ "NPC" },
		{ "Environments", "NPCAnim" },
		{ "Environments", "NPC" },
	},
	GoalMaxActiveNpcs = 400,
	GoalJumpCount = 3,
	GoalJumpHeight = 2.15,
	GoalJumpHeightVariation = 0.28,
	GoalUpDuration = 0.18,
	GoalDownDuration = 0.22,
	GoalDurationVariation = 0.18,
	GoalStartOffsetStep = 0.006,
	GoalStartOffsetRandom = 0.08,
	GoalRestTimeMin = 0.035,
	GoalRestTimeMax = 0.09,
	GoalStopAmbientBeforeBurst = true,
	ResumeAmbientAfterGoal = false,

	-- Champion ceremony: semua NPC loncat non-stop selama upacara berlangsung.
	-- Semua folder (NPCAnim + NPC) ikut serta, tidak ada batas jumlah NPC.
	ChampionEnabled = true,
	ChampionFolderPaths = {
		{ "NPCAnim" },
		{ "NPC" },
		{ "Environments", "NPCAnim" },
		{ "Environments", "NPC" },
	},
	ChampionMaxActiveNpcs = 9999, -- paksa semua NPC aktif
	ChampionJumpHeight = 3.2, -- lebih tinggi dari goal
	ChampionJumpHeightVariation = 0.35,
	ChampionUpDuration = 0.16,
	ChampionDownDuration = 0.20,
	ChampionDurationVariation = 0.20,
	ChampionStartOffsetStep = 0.004, -- wave effect antar NPC sangat rapat
	ChampionStartOffsetRandom = 0.06,
	ChampionRestTimeMin = 0.02,
	ChampionRestTimeMax = 0.06,
	ChampionStopAmbientBeforeBurst = true,
	ChampionStopGoalBeforeBurst = true,

	-- Suara tepuk tangan besar saat awal ceremony champion
	-- Ganti SoundId dengan ID asset suara applause yang dipakai di game ini.
	ChampionApplauseSoundId = "rbxassetid://4612415472",  -- big crowd applause / roar
	ChampionApplauseVolume = 1.0,
	ChampionApplauseLooped = false,

	-- Model safety. Supporter models are local presentation assets, so anchoring
	-- them during tweened PivotTo keeps the crowd stable and prevents physics
	-- jitter/collision push during cinematic match flow.
	ForceAnchorDuringJump = true,
	DisableCollisionDuringJump = false,
	ResetToOriginOnStop = true,
}

return NpcSupporterCheerConfig
