--!strict
-- TournamentRewardConfig.luau
-- Central reward tuning for tournament match rewards.
-- Pure data only. Server is the authority for granting the result.

local TournamentRewardConfig = {}

TournamentRewardConfig.LeagueBaseByAreaId = table.freeze({
	Area01 = 25, -- Street
	Area02 = 250000, -- Amateur
	Area03 = 2500000000, -- Pro
	Area04 = 25000000000000, -- World
	Area05 = 250000000000000, -- Legend
})

TournamentRewardConfig.LeagueBaseByKey = table.freeze({
	Street = 25,
	Amateur = 250000,
	Pro = 2500000000,
	World = 25000000000000,
	Legend = 250000000000000,
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
	[2] = 2,
	[3] = 4,
	[4] = 8,
})

TournamentRewardConfig.MaxQteStep = 5

return table.freeze(TournamentRewardConfig)
