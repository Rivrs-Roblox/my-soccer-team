--!strict
-- TournamentRewardConfig.luau
-- Central reward tuning for tournament match rewards.
-- Pure data only. Server is the authority for granting the result.

local TournamentRewardConfig = {}

TournamentRewardConfig.LeagueBaseByAreaId = table.freeze({
	Area01 = 100, -- Street
	Area02 = 4000, -- Amateur
	Area03 = 80000, -- Pro
	Area04 = 1200000, -- World
	Area05 = 13300000, -- Legend
})

TournamentRewardConfig.LeagueBaseByKey = table.freeze({
	Street = 100,
	Amateur = 4000,
	Pro = 80000,
	World = 1200000,
	Legend = 13300000,
})

-- TournamentRewardConfig.QteMultiplierByStep = table.freeze({
-- 	[1] = 1,
-- 	[2] = 2,
-- 	[3] = 4,
-- 	[4] = 8,
-- 	[5] = 16,
-- })

TournamentRewardConfig.RoundMultiplierById = table.freeze({
	RoundOf16 = 1,
	QuarterFinal = 2,
	SemiFinal = 4,
	Final = 8,
})

TournamentRewardConfig.RoundMultiplierByIndex = table.freeze({
	[1] = 1,
	[2] = 1,
	[3] = 1,
	[4] = 1,
})

TournamentRewardConfig.MaxQteStep = 5

return table.freeze(TournamentRewardConfig)
