--[=[
	Rebirth stat requirements.
	Formula: A = AR * CoachRef * Rate(i) * TimeA,  B = A * 1.25,  C = A * 1.5
	Rate(i) = 1 + i * 0.2

	RebirthTable[data.Rebirth + 1] returns the requirement for the next rebirth.
	  A = required Shoot stat
	  B = required Pass stat
	  C = required Dribble stat

	-- Brazil  (Rebirth 0-9)  : AR=7,      CoachRef=1.10, TimeA=48s
	-- Japan   (Rebirth 10-19): AR=77,     CoachRef=1.50, TimeA=96s
	-- USA     (Rebirth 20-29): AR=1001,   CoachRef=1.65, TimeA=192s
	-- Italy   (Rebirth 30-39): AR=21021,  CoachRef=1.90, TimeA=640s
	-- England (Rebirth 40-49): AR=714714, CoachRef=2.00, TimeA=960s
]=]
return table.freeze({
	-- Rebirth #0 (tutorial)
	[1]  = table.freeze({ A = 1,           B = 1,            C = 1             }),

	-- Brazil Zone (Rebirth #1-9)
	[2]  = table.freeze({ A = 1_955,             B = 1_857,             C = 1_662 }),
	[3]  = table.freeze({ A = 3_461,             B = 3_288,             C = 2_942 }),
	[4]  = table.freeze({ A = 4_966,             B = 4_718,             C = 4_221 }),
	[5]  = table.freeze({ A = 6_472,             B = 6_148,             C = 5_501 }),
	[6]  = table.freeze({ A = 7_977,             B = 7_578,             C = 6_780 }),
	[7]  = table.freeze({ A = 9_483,             B = 9_009,             C = 8_061 }),
	[8]  = table.freeze({ A = 10_988,            B = 10_438,            C = 9_340 }),
	[9]  = table.freeze({ A = 12_494,            B = 11_869,            C = 10_620 }),
	[10] = table.freeze({ A = 14_000,            B = 13_300,            C = 11_900 }),

	-- Japan Zone (Rebirth #10-19)
	[11] = table.freeze({ A = 60_000,            B = 57_000,            C = 51_000 }),
	[12] = table.freeze({ A = 275_500,           B = 261_725,           C = 234_175 }),
	[13] = table.freeze({ A = 491_100,           B = 466_545,           C = 417_435 }),
	[14] = table.freeze({ A = 706_000,           B = 670_700,           C = 600_100 }),
	[15] = table.freeze({ A = 922_000,           B = 875_900,           C = 783_700 }),
	[16] = table.freeze({ A = 1_130_000,         B = 1_073_500,         C = 960_500 }),
	[17] = table.freeze({ A = 1_350_000,         B = 1_282_500,         C = 1_147_500 }),
	[18] = table.freeze({ A = 1_568_000,         B = 1_489_600,         C = 1_332_800 }),
	[19] = table.freeze({ A = 1_780_000,         B = 1_691_000,         C = 1_513_000 }),
	[20] = table.freeze({ A = 2_000_000,         B = 1_900_000,         C = 1_700_000 }),

	-- USA Zone (Rebirth #20-29)
	[21] = table.freeze({ A = 6_000_000,         B = 5_700_000,         C = 5_100_000 }),
	[22] = table.freeze({ A = 48_000_000,        B = 45_600_000,        C = 40_800_000 }),
	[23] = table.freeze({ A = 91_000_000,        B = 86_450_000,        C = 77_350_000 }),
	[24] = table.freeze({ A = 134_000_000,       B = 127_300_000,       C = 113_900_000 }),
	[25] = table.freeze({ A = 176_000_000,       B = 167_200_000,       C = 149_600_000 }),
	[26] = table.freeze({ A = 219_000_000,       B = 208_050_000,       C = 186_150_000 }),
	[27] = table.freeze({ A = 262_000_000,       B = 248_900_000,       C = 222_700_000 }),
	[28] = table.freeze({ A = 304_000_000,       B = 288_800_000,       C = 258_400_000 }),
	[29] = table.freeze({ A = 347_000_000,       B = 329_650_000,       C = 294_950_000 }),
	[30] = table.freeze({ A = 390_000_000,       B = 370_500_000,       C = 331_500_000 }),

	-- Italy Zone (Rebirth #30-39)
	[31] = table.freeze({ A = 800_000_000,       B = 760_000_000,       C = 680_000_000 }),
	[32] = table.freeze({ A = 5_150_000_000,     B = 4_892_500_000,     C = 4_377_500_000 }),
	[33] = table.freeze({ A = 9_510_000_000,     B = 9_034_500_000,     C = 8_083_500_000 }),
	[34] = table.freeze({ A = 13_800_000_000,    B = 13_110_000_000,    C = 11_730_000_000 }),
	[35] = table.freeze({ A = 18_220_000_000,    B = 17_309_000_000,    C = 15_487_000_000 }),
	[36] = table.freeze({ A = 22_500_000_000,    B = 21_375_000_000,    C = 19_125_000_000 }),
	[37] = table.freeze({ A = 26_900_000_000,    B = 25_555_000_000,    C = 22_865_000_000 }),
	[38] = table.freeze({ A = 31_200_000_000,    B = 29_640_000_000,    C = 26_520_000_000 }),
	[39] = table.freeze({ A = 35_600_000_000,    B = 33_820_000_000,    C = 30_260_000_000 }),
	[40] = table.freeze({ A = 40_000_000_000,    B = 38_000_000_000,    C = 34_000_000_000 }),

	-- England Zone (Rebirth #40-49)
	[41] = table.freeze({ A = 85_000_000_000,    B = 80_750_000_000,    C = 72_250_000_000 }),
	[42] = table.freeze({ A = 386_000_000_000,   B = 366_700_000_000,   C = 328_100_000_000 }),
	[43] = table.freeze({ A = 688_300_000_000,   B = 653_885_000_000,   C = 585_055_000_000 }),
	[44] = table.freeze({ A = 990_000_000_000,   B = 940_500_000_000,   C = 841_500_000_000 }),
	[45] = table.freeze({ A = 1_290_000_000_000, B = 1_225_500_000_000, C = 1_096_500_000_000 }),
	[46] = table.freeze({ A = 1_590_000_000_000, B = 1_510_500_000_000, C = 1_351_500_000_000 }),
	[47] = table.freeze({ A = 1_895_000_000_000, B = 1_800_250_000_000, C = 1_610_750_000_000 }),
	[48] = table.freeze({ A = 2_190_000_000_000, B = 2_080_500_000_000, C = 1_861_500_000_000 }),
	[49] = table.freeze({ A = 2_490_000_000_000, B = 2_365_500_000_000, C = 2_116_500_000_000 }),
	[50] = table.freeze({ A = 2_800_000_000_000, B = 2_660_000_000_000, C = 2_380_000_000_000 }),
})
