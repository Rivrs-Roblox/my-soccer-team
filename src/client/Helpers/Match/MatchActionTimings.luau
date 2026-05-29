local MatchActionTimings = {
	Pass = {
		Anticipation = 0.38,
		Commit = 0.88,
		CommitMin = 0.72,
		CommitMax = 1.10,
		StudsPerSecond = 18,
	},

	Dribble = {
		Anticipation = 0.36,
		Commit = 1.10,
		CommitMin = 0.95,
		CommitMax = 1.45,
		StudsPerSecond = 14,
	},

	Shoot = {
		Anticipation = 0.50,
		Commit = 0.68,
		CommitMin = 0.56,
		CommitMax = 0.80,
		StudsPerSecond = 26,
	},
}

return MatchActionTimings