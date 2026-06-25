--!strict
-- TournamentRewardConfig.luau
-- Central reward tuning for tournament match rewards.
-- Pure data only. Server is the authority for granting the result.

local TournamentRewardConfig = {}

TournamentRewardConfig.LeagueBaseByAreaId = table.freeze({
	Area01 = 125, -- Street
	Area02 = 11200, -- Amateur
	Area03 = 187000, -- Pro
	Area04 = 2500000, -- World
	Area05 = 37300000, -- Legend
})

TournamentRewardConfig.LeagueBaseByKey = table.freeze({
	Street = 125,
	Amateur = 11200,
	Pro = 187000,
	World = 2500000,
	Legend = 37300000,
})

TournamentRewardConfig.QteMultiplierByStep = table.freeze({
	[1] = 1,
	[2] = 1,
	[3] = 1,
	[4] = 1,
	[5] = 1,
})

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
