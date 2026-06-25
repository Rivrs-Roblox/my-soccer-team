--!strict
-- TournamentRewardCalculator.luau
-- Pure reward math for tournament matches.
-- Reward = LeagueBase * RoundMultiplier.

local TournamentRewardConfig = require(script.Parent.Parent.Parent.Data.Tournament.TournamentRewardConfig)
local TournamentConfig = require(script.Parent.TournamentConfig)

local TournamentRewardCalculator = {}

local function IsTable(value): boolean
	return type(value) == "table"
end

local function ResolveLeagueBase(context): number
	local areaId = IsTable(context) and tostring(context.AreaId or "") or ""
	local leagueKey = IsTable(context) and tostring(context.LeagueKey or context.LeagueId or "") or ""

	local byArea = TournamentRewardConfig.LeagueBaseByAreaId[areaId]
	if byArea then
		return byArea
	end

	local byKey = TournamentRewardConfig.LeagueBaseByKey[leagueKey]
	if byKey then
		return byKey
	end

	return TournamentRewardConfig.LeagueBaseByAreaId.Area01
end

local function ResolveRoundMultiplier(context): number
	local roundId = IsTable(context) and tostring(context.RoundId or "") or ""
	local roundIndex = IsTable(context) and tonumber(context.RoundIndex) or nil

	local byId = TournamentRewardConfig.RoundMultiplierById[roundId]
	if byId then
		return byId
	end

	local byIndex = roundIndex and TournamentRewardConfig.RoundMultiplierByIndex[roundIndex]
	if byIndex then
		return byIndex
	end

	return TournamentRewardConfig.RoundMultiplierByIndex[1]
end

local function ResolveTotalRewardMultiplier(context): number
	local hasDoubleWins = IsTable(context) and context.HasDoubleWins == true
	local hasVipBattlePass = IsTable(context) and context.HasVipBattlePass == true

	local winsMultiplier = hasDoubleWins and 2 or 1
	local vipMultiplier = hasVipBattlePass and 2 or 1

	return winsMultiplier * vipMultiplier
end

local function ResolveRequiredPlayerGoals(context): number
	local requiredGoals = IsTable(context) and tonumber(context.RequiredPlayerGoals) or nil
	if requiredGoals then
		return math.max(1, math.floor(requiredGoals))
	end

	local roundId = IsTable(context) and tostring(context.RoundId or "") or ""
	local roundGoalTargets = TournamentConfig.LiveMatch.RoundGoalTargets
	local target = roundGoalTargets and roundGoalTargets[roundId]
	if target then
		return math.max(1, math.floor(tonumber(target.RequiredPlayerGoals) or 1))
	end

	return 1
end

function TournamentRewardCalculator.GetLeagueBase(context): number
	return ResolveLeagueBase(context)
end

function TournamentRewardCalculator.GetRoundMultiplier(context): number
	return ResolveRoundMultiplier(context)
end

function TournamentRewardCalculator.CalculateTotalReward(context): number
	local base = ResolveLeagueBase(context)
	local roundMultiplier = ResolveRoundMultiplier(context)
	local totalRewardMultiplier = ResolveTotalRewardMultiplier(context)

	return math.max(0, math.floor(base * roundMultiplier * totalRewardMultiplier))
end

function TournamentRewardCalculator.GetRequiredPlayerGoals(context): number
	return ResolveRequiredPlayerGoals(context)
end

function TournamentRewardCalculator.CalculatePerGoalReward(context): number
	local total = TournamentRewardCalculator.CalculateTotalReward(context)
	local requiredGoals = ResolveRequiredPlayerGoals(context)

	return math.max(0, math.floor(total / requiredGoals))
end

function TournamentRewardCalculator.BuildRoundPreview(context)
	local total = TournamentRewardCalculator.CalculateTotalReward({
		AreaId = IsTable(context) and context.AreaId or nil,
		LeagueKey = IsTable(context) and context.LeagueKey or nil,
		LeagueId = IsTable(context) and context.LeagueId or nil,
		RoundId = IsTable(context) and context.RoundId or nil,
		RoundIndex = IsTable(context) and context.RoundIndex or nil,
		RequiredPlayerGoals = IsTable(context) and context.RequiredPlayerGoals or nil,
		HasDoubleWins = IsTable(context) and context.HasDoubleWins or false,
		HasVipBattlePass = IsTable(context) and context.HasVipBattlePass or false,
	})
	local requiredGoals = ResolveRequiredPlayerGoals(context)
	local rewardPerGoal = math.max(0, math.floor(total / requiredGoals))

	return {
		RewardWins = total,
		RewardPerGoalWins = rewardPerGoal,
		RequiredPlayerGoals = requiredGoals,
		RewardText = tostring(total) .. " Wins",
		Formula = "LeagueBase x RoundMultiplier",
	}
end

return TournamentRewardCalculator
