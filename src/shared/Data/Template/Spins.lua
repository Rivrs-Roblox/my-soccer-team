return table.freeze({
	FullSpins = 4,
	SpinDuration = 5.5,
	FreeSpinInterval = 60 * 15,
	["Free"] = {
		[1] = {
			Name = "+100 Win",
			Reward = "Wins",
			Amount = 100,
			Chance = 50,
		},

		[2] = {
			Name = "+300 Win",
			Reward = "Wins",
			Amount = 300,
			Chance = 40,
		},

		[3] = {
			Name = "+1 Rebirth",
			Reward = "Rebirth",
			Amount = 1,
			Chance = 5,
		},

		[4] = {
			Name = "+1 Premium Spin",
			Reward = "Premium_Spin",
			Amount = 1,
			Chance = 4,
		},

		[5] = {
			Name = "+2 Premium Spins",
			Reward = "Premium_Spin",
			Amount = 2,
			Chance = 1,
		},
	},

	["Premium"] = {
		[1] = {
			Name = "+5000 Wins",
			Reward = "Wins",
			Amount = 5000,
			Chance = 10,
		},

		[2] = {
			Name = "+1 Rebirth",
			Reward = "Rebirth",
			Amount = 1,
			Chance = 15,
		},

		[3] = {
			Name = "+2500 Wins",
			Reward = "Wins",
			Amount = 150,
			Chance = 15,
		},

		[4] = {
			Name = "+2 Rebirths",
			Reward = "Rebirth",
			Amount = 2,
			Chance = 5,
		},

		[5] = {
			Name = "+500 Wins",
			Reward = "Wins",
			Amount = 500,
			Chance = 30,
		},

		[6] = {
			Name = "+3 Premium Spin",
			Reward = "Premium_Spin",
			Amount = 3,
			Chance = 4,
		},

		[7] = {
			Name = "x3 x2_Wins_Boost",
			Reward = "Boost",
			Boost = "x2_Wins_Boost",
			Amount = 3,
			Chance = 3,
		},

		[8] = {
			Name = "x1 GOAT Pack",
			Reward = "Gacha",
			Category = "SoccerCharacters",
			Type = "9",
			Amount = 1,
			Chance = 3,
		},
	},
})
