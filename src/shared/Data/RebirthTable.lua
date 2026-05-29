--[=[
	Generated Exponential Rebirth Table
	Adjusted using MatchAreaConfig.luau stats as a reference, tuned to be ~40% of the final goalkeeper stats 
	requirements for smoother gameplay and progression. Minimum starts at 75 stats for level 1:
	- Area 1 (Brazil Zone): Stats requirement scaling from 75 to 6,000 (Final Keeper is 15,000)
	- Area 2 (Japan Zone): Stats requirement scaling from 8,000 to 4,000,000 (Final Keeper is 10,000,000)
	- Area 3 (USA Zone): Stats requirement scaling from 5,500,000 to 3,000,000,000 (Final Keeper is 7,500,000,000)
	- Area 4 (Italy Zone): Stats requirement scaling from 4,000,000,000 to 2,200,000,000,000 (Final Keeper is 5,500,000,000,000)
	- Area 5 (England Zone): Stats requirement scaling from 3,000,000,000,000 to 1,600,000,000,000,000 (Final Keeper is 4,000,000,000,000,000)
]=]
return table.freeze({
	-- Area 01 (Brazil Zone: expected level 1 to 14)
	[1] = 75,
	[2] = 105,
	[3] = 150,
	[4] = 210,
	[5] = 300,
	[6] = 420,
	[7] = 600,
	[8] = 840,
	[9] = 1_180,
	[10] = 1_650,
	[11] = 2_300,
	[12] = 3_200,
	[13] = 4_400,
	[14] = 6_000,

	-- Area 02 (Japan Zone: expected level 15 to 27)
	[15] = 8_000,
	[16] = 13_000,
	[17] = 22_000,
	[18] = 37_000,
	[19] = 60_000,
	[20] = 100_000,
	[21] = 170_000,
	[22] = 280_000,
	[23] = 460_000,
	[24] = 770_000,
	[25] = 1_300_000,
	[26] = 2_200_000,
	[27] = 4_000_000,

	-- Area 03 (USA Zone: expected level 28 to 44)
	[28] = 5_500_000,
	[29] = 8_000_000,
	[30] = 12_000_000,
	[31] = 18_000_000,
	[32] = 27_000_000,
	[33] = 40_000_000,
	[34] = 60_000_000,
	[35] = 90_000_000,
	[36] = 130_000_000,
	[37] = 200_000_000,
	[38] = 300_000_000,
	[39] = 440_000_000,
	[40] = 660_000_000,
	[41] = 980_000_000,
	[42] = 1_400_000_000,
	[43] = 2_000_000_000,
	[44] = 3_000_000_000,

	-- Area 04 (Italy Zone: expected level 45 to 65)
	[45] = 4_000_000_000,
	[46] = 5_500_000_000,
	[47] = 7_500_000_000,
	[48] = 10_000_000_000,
	[49] = 14_000_000_000,
	[50] = 20_000_000_000,
	[51] = 28_000_000_000,
	[52] = 38_000_000_000,
	[53] = 52_000_000_000,
	[54] = 72_000_000_000,
	[55] = 100_000_000_000,
	[56] = 140_000_000_000,
	[57] = 190_000_000_000,
	[58] = 260_000_000_000,
	[59] = 360_000_000_000,
	[60] = 500_000_000_000,
	[61] = 700_000_000_000,
	[62] = 950_000_000_000,
	[63] = 1_300_000_000_000,
	[64] = 1_700_000_000_000,
	[65] = 2_200_000_000_000,

	-- Area 05 (England Zone: expected level 66 to 70)
	[66] = 3_000_000_000_000,
	[67] = 14_000_000_000_000,
	[68] = 68_000_000_000_000,
	[69] = 330_000_000_000_000,
	[70] = 1_600_000_000_000_000,
})
