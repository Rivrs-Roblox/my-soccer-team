--!strict
-- MatchAreaConfig.luau
-- Difficulty curve per Area -> Tournament Round -> Enemy Step.
-- EnemySteps remains as a RoundOf16 fallback for legacy consumers.
--
-- Formula: Enemy = ArenaReward * K * RoundMult * StepMult
--   RoundMults = { 1, 5, 25, 125 }          (R16 / QF / SF / Final)
--   StepMults  = { 1.0, 1.4, 2.0, 2.8, 4.0 } (S1..S5)
--
-- Area01 (Brazil):  AR=7,      K=0.8
-- Area02 (Japan):   AR=77,     K=5
-- Area03 (USA):     AR=1001,   K=16
-- Area04 (Italy):   AR=21021,  K=82
-- Area05 (England): AR=714714, K=162

local ACTION_FIELD = table.freeze({ "Pass", "Dribble" })
local ACTION_SHOOT = table.freeze({ "Shoot" })

local function Defender(value: number)
	return table.freeze({
		Value = value,
		AllowedActions = ACTION_FIELD,
		Role = "Defender",
	})
end

local function Keeper(value: number)
	return table.freeze({
		Value = value,
		AllowedActions = ACTION_SHOOT,
		Role = "GoalKeeper",
	})
end

local function Steps(values: { number })
	return table.freeze({
		Defender(values[1]),
		Defender(values[2]),
		Defender(values[3]),
		Defender(values[4]),
		Keeper(values[5]),
	})
end

local function Area(displayName: string, rounds)
	return table.freeze({
		DisplayName = displayName,
		RoundEnemySteps = table.freeze(rounds),
		EnemySteps = rounds.RoundOf16,
	})
end

local MatchAreaConfig = {
	Area01 = Area("Brazil Zone", {
		RoundOf16    = Steps({ 6,         9,         14,       20,       20       }),
		QuarterFinal = Steps({ 770,         980,         1_570,       1_670,       1_800       }),
		SemiFinal    = Steps({ 3_400,       4_500,       6_400,       7_200,      6_500      }),
		Final        = Steps({ 7_100,      10_100,      14_500,      14_600,      15_300      }),
	}),

	Area02 = Area("Japan Zone", {
		RoundOf16    = Steps({ 60_000,      85_000,      120_000,     125_600,     105_000      }),
		QuarterFinal = Steps({ 140_000,       205_000,       285_000,       295_000,     310_000     }),
		SemiFinal    = Steps({ 480_000,       720_000,      950_000,      990_000,     960_000     }),
		Final        = Steps({ 1_100_000,      1_600_000,      2_000_000,      2_130_000,   2_150_000   }),
	}),

	Area03 = Area("USA Zone", {
		RoundOf16    = Steps({ 6_300_000,      8_800_000,      12_750_000,     12_900_000,      13_000_000   }),
		QuarterFinal = Steps({ 20_000_000,      33_000_000,     40_000_000,     41_000_000,     45_000_000   }),
		SemiFinal    = Steps({ 65_000_000,     85_000_000,     128_000_000,     130_000_000,     135_000_000   }),
		Final        = Steps({ 180_000_000,   240_000_000,   392_000_000,   394_000_000,    400_000_000  }),
	}),

	Area04 = Area("Italy Zone", {
		RoundOf16    = Steps({ 750_000_000,   1_050_000_000,   1_500_000_000,   1_550_000_000,  1_650_000_000    }),
		QuarterFinal = Steps({ 2_300_000_000,   3_400_000_000,  4_650_000_000,  4_680_000_000,  4_800_000_000    }),
		SemiFinal    = Steps({ 7_100_000_000,  9_900_000_000,  14_250_000_000,  14_300_000_000,  14_800_000_000    }),
		Final        = Steps({ 20_000_000_000, 29_950_000_000, 40_500_000_000, 41_000_000_000, 45_500_000_000   }),
	}),

	Area05 = Area("England Zone", {
		RoundOf16    = Steps({ 80_000_000_000,    110_000_000_000,    163_000_000_000,    165_000_000_000,   170_000_000_000    }),
		QuarterFinal = Steps({ 195_000_000,    250_000_000_000,    390_000_000_000,  393_000_000_000,  400_300_000_000    }),
		SemiFinal    = Steps({ 550_000_000_000,  830_000_000_000,  1_115_000_000_000,  1_120_000_000_000,  1_125_000_000_000    }),
		Final        = Steps({ 1_350_000_000_000, 1_900_000_000_000, 2_700_000_000_000, 2_750_000_000_000, 2_800_000_000_000    }),
	}),
}

return table.freeze(MatchAreaConfig)
