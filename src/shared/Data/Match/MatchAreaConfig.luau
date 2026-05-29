--!strict
-- MatchAreaConfig.luau
-- Difficulty curve per Area -> Tournament Round -> Enemy Step.
-- EnemySteps remains as a RoundOf16 fallback for legacy consumers.

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
		RoundOf16 = Steps({ 5, 15, 25, 35, 45 }),
		QuarterFinal = Steps({ 100, 200, 350, 500, 750 }),
		SemiFinal = Steps({ 1100, 1600, 2300, 3200, 4500 }),
		Final = Steps({ 6000, 8000, 10000, 12500, 15000 }),
	}),

	-- Area02 RoundOf16 Step01 intentionally starts above Area01 Final Keeper.
	Area02 = Area("Japan Zone", {
		RoundOf16 = Steps({ 20_000, 28_000, 40_000, 55_000, 75_000 }),
		QuarterFinal = Steps({ 100_000, 140_000, 200_000, 280_000, 400_000 }),
		SemiFinal = Steps({ 550_000, 750_000, 1_000_000, 1_400_000, 2_000_000 }),
		Final = Steps({ 2_800_000, 4_000_000, 5_500_000, 7_500_000, 10_000_000 }),
	}),

	-- Area03 RoundOf16 Step01 intentionally starts above Area02 Final Keeper.
	Area03 = Area("USA Zone", {
		RoundOf16 = Steps({ 14_000_000, 20_000_000, 28_000_000, 40_000_000, 55_000_000 }),
		QuarterFinal = Steps({ 75_000_000, 100_000_000, 140_000_000, 200_000_000, 280_000_000 }),
		SemiFinal = Steps({ 400_000_000, 550_000_000, 750_000_000, 1_000_000_000, 1_400_000_000 }),
		Final = Steps({ 2_000_000_000, 2_800_000_000, 4_000_000_000, 5_500_000_000, 7_500_000_000 }),
	}),

	-- Area04 RoundOf16 Step01 intentionally starts above Area03 Final Keeper.
	Area04 = Area("Italy Zone", {
		RoundOf16 = Steps({ 10_000_000_000, 14_000_000_000, 20_000_000_000, 28_000_000_000, 40_000_000_000 }),
		QuarterFinal = Steps({ 55_000_000_000, 75_000_000_000, 100_000_000_000, 140_000_000_000, 200_000_000_000 }),
		SemiFinal = Steps({ 280_000_000_000, 400_000_000_000, 550_000_000_000, 750_000_000_000, 1_000_000_000_000 }),
		Final = Steps({ 1_400_000_000_000, 2_000_000_000_000, 2_800_000_000_000, 4_000_000_000_000, 5_500_000_000_000 }),
	}),

	-- Area05 RoundOf16 Step01 intentionally starts above Area04 Final Keeper.
	Area05 = Area("England Zone", {
		RoundOf16 = Steps({ 7_500_000_000_000, 10_000_000_000_000, 14_000_000_000_000, 20_000_000_000_000, 28_000_000_000_000 }),
		QuarterFinal = Steps({ 40_000_000_000_000, 55_000_000_000_000, 75_000_000_000_000, 100_000_000_000_000, 140_000_000_000_000 }),
		SemiFinal = Steps({ 200_000_000_000_000, 280_000_000_000_000, 400_000_000_000_000, 550_000_000_000_000, 750_000_000_000_000 }),
		Final = Steps({ 1_000_000_000_000_000, 1_400_000_000_000_000, 2_000_000_000_000_000, 2_800_000_000_000_000, 4_000_000_000_000_000 }),
	}),
}

return table.freeze(MatchAreaConfig)
