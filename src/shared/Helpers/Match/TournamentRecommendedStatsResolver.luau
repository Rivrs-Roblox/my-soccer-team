--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchAreaConfig = require(ReplicatedStorage.Shared.Data.Match.MatchAreaConfig)

local TournamentRecommendedStatsResolver = {}

local DEFAULT_AREA_ID = "Area01"
local FINAL_ROUND_ID = "Final"
local FIELD_STEP_INDEX = 4
local SHOOT_STEP_INDEX = 5

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

function TournamentRecommendedStatsResolver.GetFinalAreaStats(area: any): RecommendedStats
	local areaId = getAreaId(area)
	local areaConfig = MatchAreaConfig[areaId] or MatchAreaConfig[DEFAULT_AREA_ID]
	local roundEnemySteps = areaConfig and areaConfig.RoundEnemySteps
	local finalSteps = if isTable(roundEnemySteps) then roundEnemySteps[FINAL_ROUND_ID] else nil
	finalSteps = finalSteps or (areaConfig and areaConfig.EnemySteps)

	local fieldValue = getStepValue(finalSteps, FIELD_STEP_INDEX) or 0
	local shootValue = getStepValue(finalSteps, SHOOT_STEP_INDEX) or fieldValue

	return {
		AreaId = areaId,
		Passing = fieldValue,
		Dribbling = fieldValue,
		Shooting = shootValue,
	}
end

return table.freeze(TournamentRecommendedStatsResolver)
