-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

return {
	[1] = {
		Time = 60,

		Image = "Pass",

		Reward = "Stats",
		Stat = "Pass",

		Areas = {
			Area01 = { `x{FormatNumber(300)} Pass`, 300 },
			Area02 = { `x{FormatNumber(15000)} Pass`, 15000 },
			Area03 = { `x{FormatNumber(2250000)} Pass`, 2250000 },
			Area04 = { `x{FormatNumber(132000000)} Pass`, 132000000 },
			Area05 = { `x{FormatNumber(7800000000)} Pass`, 7800000000 },
		},

		Claimed = false,
	},

	[2] = {
		Time = 60 * 3,

		Image = "Wins",

		Reward = "Currency",
		Currency = "Wins",

		Areas = {
			Area01 = { `x{FormatNumber(2000)} Wins`, 2000 },
			Area02 = { `x{FormatNumber(20000000)} Wins`, 20000000 },
			Area03 = { `x{FormatNumber(200000000000)} Wins`, 200000000000 },
			Area04 = { `x{FormatNumber(2000000000000000)} Wins`, 2000000000000000 },
			Area05 = { `x{FormatNumber(20000000000000000)} Wins`, 20000000000000000 },
		},

		Claimed = false,
	},

	[3] = {
		Time = 60 * 5,

		Image = "Shoot",

		Reward = "Stats",
		Stat = "Shoot",

		Areas = {
			Area01 = { `x{FormatNumber(1500)} Shoot`, 1500 },
			Area02 = { `x{FormatNumber(75000)} Shoot`, 75000 },
			Area03 = { `x{FormatNumber(11250000)} Shoot`, 11250000 },
			Area04 = { `x{FormatNumber(660000000)} Shoot`, 660000000 },
			Area05 = { `x{FormatNumber(39000000000)} Shoot`, 39000000000 },
		},

		Claimed = false,
	},

	[4] = {
		Time = 60 * 8,

		Image = "Antonni",

		Reward = "Characters",
		Amount = 1,

		Rarity = "Uncommon",

		Areas = {
			Area01 = { "x1 Antonni", "Antonni" },
			Area02 = { "x1 Antonni", "Antonni" },
			Area03 = { "x1 Antonni", "Antonni" },
			Area04 = { "x1 Antonni", "Antonni" },
			Area05 = { "x1 Antonni", "Antonni" },
		},

		Claimed = false,
	},

	[5] = {
		Time = 60 * 10,

		Image = "Wins",

		Reward = "Currency",
		Currency = "Wins",

		Areas = {
			Area01 = { `x{FormatNumber(5000)} Wins`, 5000 },
			Area02 = { `x{FormatNumber(50000000)} Wins`, 50000000 },
			Area03 = { `x{FormatNumber(500000000000)} Wins`, 500000000000 },
			Area04 = { `x{FormatNumber(5000000000000000)} Wins`, 5000000000000000 },
			Area05 = { `x{FormatNumber(50000000000000000)} Wins`, 50000000000000000 },
		},

		Claimed = false,
	},

	[6] = {
		Time = 60 * 15,

		Image = "Martin Odegard",

		Reward = "Characters",
		Amount = 1,

		Rarity = "Rare",

		Areas = {
			Area01 = { "x1 Martin Odegard", "Martin Odegard" },
			Area02 = { "x1 Martin Odegard", "Martin Odegard" },
			Area03 = { "x1 Martin Odegard", "Martin Odegard" },
			Area04 = { "x1 Martin Odegard", "Martin Odegard" },
			Area05 = { "x1 Martin Odegard", "Martin Odegard" },
		},

		Claimed = false,
	},

	[7] = {
		Time = 60 * 20,

		Image = "x2_Wins_Boost",

		Reward = "Boosts",
		Amount = 1,

		Rarity = "Legendary",

		Areas = {
			Area01 = { "x2 Wins Boost", "x2_Wins_Boost" },
			Area02 = { "x2 Wins Boost", "x2_Wins_Boost" },
			Area03 = { "x2 Wins Boost", "x2_Wins_Boost" },
			Area04 = { "x2 Wins Boost", "x2_Wins_Boost" },
			Area05 = { "x2 Wins Boost", "x2_Wins_Boost" },
		},

		Claimed = false,
	},

	[8] = {
		Time = 60 * 25,

		Image = "Wins",

		Reward = "Currency",
		Currency = "Wins",

		Areas = {
			Area01 = { `x{FormatNumber(15000)} Wins`, 15000 },
			Area02 = { `x{FormatNumber(150000000)} Wins`, 150000000 },
			Area03 = { `x{FormatNumber(1500000000000)} Wins`, 1500000000000 },
			Area04 = { `x{FormatNumber(15000000000000000)} Wins`, 15000000000000000 },
			Area05 = { `x{FormatNumber(150000000000000000)} Wins`, 150000000000000000 },
		},

		Claimed = false,
	},

	[9] = {
		Time = 60 * 30,

		Image = "Dribble",

		Reward = "Stats",
		Stat = "Dribble",

		Areas = {
			Area01 = { `x{FormatNumber(9000)} Dribble`, 9000 },
			Area02 = { `x{FormatNumber(450000)} Dribble`, 450000 },
			Area03 = { `x{FormatNumber(67500000)} Dribble`, 67500000 },
			Area04 = { `x{FormatNumber(3960000000)} Dribble`, 3960000000 },
			Area05 = { `x{FormatNumber(234000000000)} Dribble`, 234000000000 },
		},

		Claimed = false,
	},

	[10] = {
		Time = 60 * 45,

		Image = "Bakayo Sakko",

		Reward = "Characters",
		Amount = 1,

		Rarity = "Epic",

		Areas = {
			Area01 = { "x1 Bakayo Sakko", "Bakayo Sakko" },
			Area02 = { "x1 Bakayo Sakko", "Bakayo Sakko" },
			Area03 = { "x1 Bakayo Sakko", "Bakayo Sakko" },
			Area04 = { "x1 Bakayo Sakko", "Bakayo Sakko" },
			Area05 = { "x1 Bakayo Sakko", "Bakayo Sakko" },
		},

		Claimed = false,
	},

	[11] = {
		Time = 60 * 60 * 1.5,

		Image = "Wins",

		Reward = "Currency",
		Currency = "Wins",

		Areas = {
			Area01 = { `x{FormatNumber(50000)} Wins`, 50000 },
			Area02 = { `x{FormatNumber(500000000)} Wins`, 500000000 },
			Area03 = { `x{FormatNumber(5000000000000)} Wins`, 5000000000000 },
			Area04 = { `x{FormatNumber(50000000000000000)} Wins`, 50000000000000000 },
			Area05 = { `x{FormatNumber(500000000000000000)} Wins`, 500000000000000000 },
		},

		Claimed = false,
	},

	[12] = {
		Time = 60 * 60 * 2,

		Image = "Kilian Mbape",

		Reward = "Characters",
		Amount = 1,

		Rarity = "Legendary",

		Areas = {
			Area01 = { "x1 Kilian Mbape", "Kilian Mbape" },
			Area02 = { "x1 Kilian Mbape", "Kilian Mbape" },
			Area03 = { "x1 Kilian Mbape", "Kilian Mbape" },
			Area04 = { "x1 Kilian Mbape", "Kilian Mbape" },
			Area05 = { "x1 Kilian Mbape", "Kilian Mbape" },
		},

		Claimed = false,
	},
}
