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
	[2]  = table.freeze({ A = 444,         B = 554,          C = 665           }),
	[3]  = table.freeze({ A = 517,         B = 647,          C = 776           }),
	[4]  = table.freeze({ A = 591,         B = 739,          C = 887           }),
	[5]  = table.freeze({ A = 665,         B = 832,          C = 998           }),
	[6]  = table.freeze({ A = 739,         B = 924,          C = 1_109         }),
	[7]  = table.freeze({ A = 813,         B = 1_016,        C = 1_220         }),
	[8]  = table.freeze({ A = 887,         B = 1_109,        C = 1_331         }),
	[9]  = table.freeze({ A = 961,         B = 1_201,        C = 1_441         }),
	[10] = table.freeze({ A = 1_035,       B = 1_294,        C = 1_552         }),

	-- Japan Zone (Rebirth #10-19)
	[11] = table.freeze({ A = 33_264,      B = 41_580,       C = 49_896        }),
	[12] = table.freeze({ A = 35_482,      B = 44_352,       C = 53_222        }),
	[13] = table.freeze({ A = 37_699,      B = 47_124,       C = 56_549        }),
	[14] = table.freeze({ A = 39_917,      B = 49_896,       C = 59_875        }),
	[15] = table.freeze({ A = 42_134,      B = 52_668,       C = 63_202        }),
	[16] = table.freeze({ A = 44_352,      B = 55_440,       C = 66_528        }),
	[17] = table.freeze({ A = 46_570,      B = 58_212,       C = 69_854        }),
	[18] = table.freeze({ A = 48_787,      B = 60_984,       C = 73_181        }),
	[19] = table.freeze({ A = 51_005,      B = 63_756,       C = 76_507        }),
	[20] = table.freeze({ A = 53_222,      B = 66_528,       C = 79_834        }),

	-- USA Zone (Rebirth #20-29)
	[21] = table.freeze({ A = 1_585_584,   B = 1_981_980,    C = 2_378_376     }),
	[22] = table.freeze({ A = 1_649_007,   B = 2_061_259,    C = 2_473_511     }),
	[23] = table.freeze({ A = 1_712_431,   B = 2_140_538,    C = 2_568_646     }),
	[24] = table.freeze({ A = 1_775_854,   B = 2_219_818,    C = 2_663_781     }),
	[25] = table.freeze({ A = 1_839_277,   B = 2_299_097,    C = 2_758_916     }),
	[26] = table.freeze({ A = 1_902_701,   B = 2_378_376,    C = 2_854_051     }),
	[27] = table.freeze({ A = 1_966_124,   B = 2_457_655,    C = 2_949_186     }),
	[28] = table.freeze({ A = 2_029_548,   B = 2_536_934,    C = 3_044_321     }),
	[29] = table.freeze({ A = 2_092_971,   B = 2_616_214,    C = 3_139_456     }),
	[30] = table.freeze({ A = 2_156_394,   B = 2_695_493,    C = 3_234_591     }),

	-- Italy Zone (Rebirth #30-39)
	[31] = table.freeze({ A = 178_930_752, B = 223_663_440,  C = 268_396_128   }),
	[32] = table.freeze({ A = 184_043_059, B = 230_053_824,  C = 276_064_589   }),
	[33] = table.freeze({ A = 189_155_366, B = 236_444_208,  C = 283_733_050   }),
	[34] = table.freeze({ A = 194_267_674, B = 242_834_592,  C = 291_401_510   }),
	[35] = table.freeze({ A = 199_379_981, B = 249_224_976,  C = 299_069_971   }),
	[36] = table.freeze({ A = 204_492_288, B = 255_615_360,  C = 306_738_432   }),
	[37] = table.freeze({ A = 209_604_595, B = 262_005_744,  C = 314_406_893   }),
	[38] = table.freeze({ A = 214_716_902, B = 268_396_128,  C = 322_075_354   }),
	[39] = table.freeze({ A = 219_829_210, B = 274_786_512,  C = 329_743_814   }),
	[40] = table.freeze({ A = 224_941_517, B = 281_176_896,  C = 337_412_275   }),

	-- England Zone (Rebirth #40-49)
	[41] = table.freeze({ A = 12_350_257_920,  B = 15_437_822_400,  C = 18_525_386_880  }),
	[42] = table.freeze({ A = 12_624_708_096,  B = 15_780_885_120,  C = 18_937_062_144  }),
	[43] = table.freeze({ A = 12_899_158_272,  B = 16_123_947_840,  C = 19_348_737_408  }),
	[44] = table.freeze({ A = 13_173_608_448,  B = 16_467_010_560,  C = 19_760_412_672  }),
	[45] = table.freeze({ A = 13_448_058_624,  B = 16_810_073_280,  C = 20_172_087_936  }),
	[46] = table.freeze({ A = 13_722_508_800,  B = 17_153_136_000,  C = 20_583_763_200  }),
	[47] = table.freeze({ A = 13_996_958_976,  B = 17_496_198_720,  C = 20_995_438_464  }),
	[48] = table.freeze({ A = 14_271_409_152,  B = 17_839_261_440,  C = 21_407_113_728  }),
	[49] = table.freeze({ A = 14_545_859_328,  B = 18_182_324_160,  C = 21_818_788_992  }),
	[50] = table.freeze({ A = 14_820_309_504,  B = 18_525_386_880,  C = 22_230_464_256  }),
})
