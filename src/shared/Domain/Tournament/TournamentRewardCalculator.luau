--!strict
-- TournamentRewardCalculator.luau
-- Pure reward math for tournament matches.
-- Reward = LeagueBase * QteMultiplier * RoundMultiplier.

local TournamentRewardConfig = require(script.Parent.Parent.Parent.Data.Tournament.TournamentRewardConfig)

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

local function ResolveQteMultiplier(stepIndex: number): number
	return TournamentRewardConfig.QteMultiplierByStep[stepIndex] or 0
end

local function HasSuccessfulStep(successfulSteps, stepIndex: number): boolean
	if successfulSteps == nil then
		return true
	end

	if type(successfulSteps) ~= "table" then
		return false
	end

	local directValue = successfulSteps[stepIndex]
	if directValue == true then
		return true
	end

	if tonumber(directValue) == stepIndex then
		return true
	end

	for _, value in pairs(successfulSteps) do
		if value == true and tonumber(_) == stepIndex then
			return true
		end

		if tonumber(value) == stepIndex then
			return true
		end
	end

	return false
end

function TournamentRewardCalculator.GetLeagueBase(context): number
	return ResolveLeagueBase(context)
end

function TournamentRewardCalculator.GetRoundMultiplier(context): number
	return ResolveRoundMultiplier(context)
end

function TournamentRewardCalculator.GetQteMultiplier(stepIndex: number): number
	return ResolveQteMultiplier(stepIndex)
end

function TournamentRewardCalculator.CalculateStepReward(context, stepIndex: number): number
	local base = ResolveLeagueBase(context)
	local qteMultiplier = ResolveQteMultiplier(stepIndex)
	local roundMultiplier = ResolveRoundMultiplier(context)

	return math.max(0, math.floor(base * qteMultiplier * roundMultiplier))
end

function TournamentRewardCalculator.CalculateTotalReward(context): number
	local total = 0
	local successfulSteps = IsTable(context) and context.SuccessfulQteSteps or nil
	local maxStep = TournamentRewardConfig.MaxQteStep

	for stepIndex = 1, maxStep do
		if HasSuccessfulStep(successfulSteps, stepIndex) then
			total += TournamentRewardCalculator.CalculateStepReward(context, stepIndex)
		end
	end

	return total
end

function TournamentRewardCalculator.BuildRoundPreview(context)
	local total = TournamentRewardCalculator.CalculateTotalReward({
		AreaId = IsTable(context) and context.AreaId or nil,
		LeagueKey = IsTable(context) and context.LeagueKey or nil,
		LeagueId = IsTable(context) and context.LeagueId or nil,
		RoundId = IsTable(context) and context.RoundId or nil,
		RoundIndex = IsTable(context) and context.RoundIndex or nil,
		SuccessfulQteSteps = nil, -- nil means full 5-QTE clear preview.
	})

	return {
		RewardWins = total,
		RewardText = tostring(total) .. " Wins",
		Formula = "LeagueBase x QteMultiplier x RoundMultiplier",
	}
end

return TournamentRewardCalculator
