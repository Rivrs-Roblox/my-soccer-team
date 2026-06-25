-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Formula:
--   Stats = ArenaReward × Time_seconds          (save X seconds of training)
--   Wins  = (BaseWins × 8/30) × Time_seconds × 0.1   (10% of Final farming for X seconds)
--
-- Property: claiming slots 2+5+8 (3/10/25min) = ~61% of Coach1 cost in every world

return {
	[1] = {
		Time = 60,
		Image = "Pass",
		Reward = "Stats",
		Stat = "Pass",
		-- AR × 60s
		Areas = {
			Area01 = { `x{FormatNumber(420)} Pass`,        420         },
			Area02 = { `x{FormatNumber(4620)} Pass`,       4_620       },
			Area03 = { `x{FormatNumber(60060)} Pass`,      60_060      },
			Area04 = { `x{FormatNumber(1261260)} Pass`,    1_261_260   },
			Area05 = { `x{FormatNumber(42882840)} Pass`,   42_882_840  },
		},
		Claimed = false,
	},

	[2] = {
		Time = 60 * 3,
		Image = "Wins",
		Reward = "Currency",
		Currency = "Wins",
		-- (BW×8/30) × 180s × 0.1
		Areas = {
			Area01 = { `x{FormatNumber(120)} Wins`,                       120                         },
			Area02 = { `x{FormatNumber(1200000)} Wins`,                   7_000                      },
			Area03 = { `x{FormatNumber(12000000000)} Wins`,               200_000                     },
			Area04 = { `x{FormatNumber(120000000000000)} Wins`,           3_000_000                  },
			Area05 = { `x{FormatNumber(1200000000000000)} Wins`,          30_000_000                  },
		},
		Claimed = false,
	},

	[3] = {
		Time = 60 * 5,
		Image = "Shoot",
		Reward = "Stats",
		Stat = "Shoot",
		-- AR × 300s
		Areas = {
			Area01 = { `x{FormatNumber(2100)} Shoot`,      500         },
			Area02 = { `x{FormatNumber(23100)} Shoot`,     2_100       },
			Area03 = { `x{FormatNumber(300300)} Shoot`,    3_000_000   },
			Area04 = { `x{FormatNumber(6306300)} Shoot`,   15_000_000   },
			Area05 = { `x{FormatNumber(214414200)} Shoot`, 120_000_000 },
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
			Area01 = { "x1 Antony", "Antonni" },
			Area02 = { "x1 Antony", "Antonni" },
			Area03 = { "x1 Antony", "Antonni" },
			Area04 = { "x1 Antony", "Antonni" },
			Area05 = { "x1 Antony", "Antonni" },
		},
		Claimed = false,
	},

	[5] = {
		Time = 60 * 10,
		Image = "Wins",
		Reward = "Currency",
		Currency = "Wins",
		-- (BW×8/30) × 600s × 0.1
		Areas = {
			Area01 = { `x{FormatNumber(400)} Wins`,                       500                         },
			Area02 = { `x{FormatNumber(4000000)} Wins`,                   10_000                   },
			Area03 = { `x{FormatNumber(40000000000)} Wins`,               300_000              },
			Area04 = { `x{FormatNumber(400000000000000)} Wins`,           5_000_000         },
			Area05 = { `x{FormatNumber(4000000000000000)} Wins`,          50_000_000       },
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
			Area01 = { "x1 Martin Odegaard", "Martin Odegard" },
			Area02 = { "x1 Martin Odegaard", "Martin Odegard" },
			Area03 = { "x1 Martin Odegaard", "Martin Odegard" },
			Area04 = { "x1 Martin Odegaard", "Martin Odegard" },
			Area05 = { "x1 Martin Odegaard", "Martin Odegard" },
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
		-- (BW×8/30) × 1500s × 0.1
		Areas = {
			Area01 = { `x{FormatNumber(1000)} Wins`,                      800             },
			Area02 = { `x{FormatNumber(10000000)} Wins`,                  15_000          },
			Area03 = { `x{FormatNumber(100000000000)} Wins`,              400_000         },
			Area04 = { `x{FormatNumber(1000000000000000)} Wins`,          7_000_000       },
			Area05 = { `x{FormatNumber(10000000000000000)} Wins`,         70_000_000      },
		},
		Claimed = false,
	},

	[9] = {
		Time = 60 * 30,
		Image = "Dribble",
		Reward = "Stats",
		Stat = "Dribble",
		-- AR × 1800s
		Areas = {
			Area01 = { `x{FormatNumber(12600)} Dribble`,      800           },
			Area02 = { `x{FormatNumber(138600)} Dribble`,     10_000       },
			Area03 = { `x{FormatNumber(1801800)} Dribble`,    80_000     },
			Area04 = { `x{FormatNumber(37837800)} Dribble`,   1_500_000    },
			Area05 = { `x{FormatNumber(1286485200)} Dribble`, 50_000_000 },
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
			Area01 = { "x1 Bukayo Saka", "Bakayo Sakko" },
			Area02 = { "x1 Bukayo Saka", "Bakayo Sakko" },
			Area03 = { "x1 Bukayo Saka", "Bakayo Sakko" },
			Area04 = { "x1 Bukayo Saka", "Bakayo Sakko" },
			Area05 = { "x1 Bukayo Saka", "Bakayo Sakko" },
		},
		Claimed = false,
	},

	[11] = {
		Time = 60 * 60 * 1.5,
		Image = "Wins",
		Reward = "Currency",
		Currency = "Wins",
		-- (BW×8/30) × 5400s × 0.1
		Areas = {
			Area01 = { `x{FormatNumber(3600)} Wins`,                      2_000                       },
			Area02 = { `x{FormatNumber(36000000)} Wins`,                  25_000                  },
			Area03 = { `x{FormatNumber(360000000000)} Wins`,              600_000             },
			Area04 = { `x{FormatNumber(3600000000000000)} Wins`,          10_000_000       },
			Area05 = { `x{FormatNumber(36000000000000000)} Wins`,         100_000_000      },
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
			Area01 = { "x1 Kylian Mbappe", "Kilian Mbape" },
			Area02 = { "x1 Kylian Mbappe", "Kilian Mbape" },
			Area03 = { "x1 Kylian Mbappe", "Kilian Mbape" },
			Area04 = { "x1 Kylian Mbappe", "Kilian Mbape" },
			Area05 = { "x1 Kylian Mbappe", "Kilian Mbape" },
		},
		Claimed = false,
	},
}
