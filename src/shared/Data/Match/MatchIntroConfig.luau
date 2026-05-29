local MatchIntroConfig = {
	Enabled = true,
	DebugMatchIntro = false,
	ServerMaxWaitSeconds = 12.0,

	Timings = {
		VsFadeIn = 0.25,
		VsHold = 3.0,
		VsFadeOut = 0.25,
		CountdownStep = 0.85,
		MatchStartVeilFadeIn = 0.08,
		MatchStartVeilHold = 0.30,
		MatchStartVeilTransparency = 0.08,
		PostReleaseVeilHold = 0.18,
		FinalFadeOut = 0.2,
	},

	DefaultIntroData = {
		HomeTeamName = "FC Rivrs",
		AwayTeamName = "FC Roblox",
		HomeScore = 1,
		AwayScore = 1,
		MatchMinute = 86,
		LeagueName = "Youth League",
		RoundName = "Final Attack",
		HomeLogo = "",
		AwayLogo = "",
	},
}

return MatchIntroConfig
