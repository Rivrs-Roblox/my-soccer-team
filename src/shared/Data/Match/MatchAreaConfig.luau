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
		SemiFinal    = Steps({ 3_100,       4_250,       6_500,       6_900,      6_100      }),
		Final        = Steps({ 6_900,      9_500,      14_000,      14_300,      15_000      }),
	}),

	Area02 = Area("Japan Zone", {
		RoundOf16    = Steps({ 385,         539,         770,         105_600,     95_000      }),
		QuarterFinal = Steps({ 1_925,       2_695,       3_850,       264_000,     243_000     }),
		SemiFinal    = Steps({ 9_625,       13_475,      19_250,      590_000,     660_000     }),
		Final        = Steps({ 48_125,      67_375,      96_250,      1_440_000,   1_650_000   }),
	}),

	Area03 = Area("USA Zone", {
		RoundOf16    = Steps({ 16_016,      22_422,      32_032,      9_300_000,      10_000_000   }),
		QuarterFinal = Steps({ 80_080,      112_112,     160_160,     28_000_000,     30_000_000   }),
		SemiFinal    = Steps({ 400_400,     560_560,     800_800,     80_000_000,     90_000_000   }),
		Final        = Steps({ 2_002_000,   2_802_800,   4_004_000,   255_000_000,    270_000_000  }),
	}),

	Area04 = Area("Italy Zone", {
		RoundOf16    = Steps({ 1_723_722,   2_413_211,   3_447_444,   1_000_000_000,  1_100_000_000    }),
		QuarterFinal = Steps({ 8_618_610,   12_066_054,  17_237_220,  2_850_000_000,  3_000_000_000    }),
		SemiFinal    = Steps({ 43_093_050,  60_330_270,  86_186_100,  9_850_000_000,  9_000_000_000    }),
		Final        = Steps({ 215_465_250, 301_651_350, 430_930_500, 26_850_000_000, 27_500_000_000   }),
	}),

	Area05 = Area("England Zone", {
		RoundOf16    = Steps({ 115_783_668,    162_097_135,    231_567_336,    95_000_000_000,   100_000_000_000    }),
		QuarterFinal = Steps({ 578_918_340,    810_485_676,    1_157_836_680,  250_620_971_352,  235_300_000_000    }),
		SemiFinal    = Steps({ 2_894_591_700,  4_052_428_380,  5_789_183_400,  600_000_000_000,  625_000_000_000    }),
		Final        = Steps({ 14_472_958_500, 20_262_141_900, 28_945_917_000, 1_400_000_000_000, 1_560_000_000_000    }),
	}),
}

return table.freeze(MatchAreaConfig)
