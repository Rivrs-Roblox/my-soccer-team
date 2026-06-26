--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchAreaConfig = require(ReplicatedStorage.Shared.Data.Match.MatchAreaConfig)

local TournamentRecommendedStatsResolver = {}

local DEFAULT_AREA_ID = "Area01"
local FIELD_STEP_INDEX = 4
local SHOOT_STEP_INDEX = 5

local ROUND_PROGRESSION = table.freeze({
	"RoundOf16",
	"QuarterFinal",
	"SemiFinal",
	"Final",
})

export type RecommendedStats = {
	AreaId: string,
	Passing: number,
	Dribbling: number,
	Shooting: number,
}

local function isTable(value: any): boolean
	return type(value) == "table"
end

local function getAreaId(area: any): string
	if isTable(area) then
		local value = area.Id or area.AreaId or area.Name
		if MatchAreaConfig[tostring(value or "")] then
			return tostring(value)
		end
	end

	local areaId = tostring(area or "")
	if MatchAreaConfig[areaId] then
		return areaId
	end

	return DEFAULT_AREA_ID
end

local function getStepValue(steps: any, index: number): number?
	if not isTable(steps) then
		return nil
	end

	local step = steps[index]
	if isTable(step) then
		return tonumber(step.Value or step.RequiredPower or step.Power)
	end

	return tonumber(step)
end

function TournamentRecommendedStatsResolver.GetFinalAreaStats(area: any, playerData: any?): RecommendedStats
	local areaId = getAreaId(area)
	local areaConfig = MatchAreaConfig[areaId] or MatchAreaConfig[DEFAULT_AREA_ID]

	local targetRoundId = "RoundOf16"
	if playerData and playerData.HighestRoundsWon then
		local highestWon = playerData.HighestRoundsWon[areaId]
		print("[StatsResolver DEBUG] areaId:", areaId, "highestWon:", highestWon)
		if highestWon then
			local index = table.find(ROUND_PROGRESSION, highestWon)
			if index then
				targetRoundId = ROUND_PROGRESSION[index + 1] or "Final"
			end
		end
	else
		print("[StatsResolver DEBUG] No playerData or HighestRoundsWon map provided for area:", areaId)
	end

	print("[StatsResolver DEBUG] targetRoundId:", targetRoundId)

	local roundEnemySteps = areaConfig and areaConfig.RoundEnemySteps
	local targetSteps = if isTable(roundEnemySteps) then roundEnemySteps[targetRoundId] else nil
	targetSteps = targetSteps or (areaConfig and areaConfig.EnemySteps)

	local fieldValue = getStepValue(targetSteps, FIELD_STEP_INDEX) or 0
	local shootValue = getStepValue(targetSteps, SHOOT_STEP_INDEX) or fieldValue

	return {
		AreaId = areaId,
		Passing = fieldValue,
		Dribbling = fieldValue,
		Shooting = shootValue,
	}
end

return table.freeze(TournamentRecommendedStatsResolver)
