local Workspace = game:GetService("Workspace")

local ZoneUtils = require(script.Parent.ZoneUtils)
local Settings = require(script.Parent.Settings)

local StaminaTrainingRuntime = {}
StaminaTrainingRuntime.StatType = "Stamina"
StaminaTrainingRuntime.Mode = "StaminaTraining"

local function GetPivotData(zone: BasePart, pivotName: string)
	local pivot = zone:FindFirstChild(pivotName)
	if not pivot or not pivot:IsA("BasePart") then
		return nil
	end

	return {
		Name = pivotName,
		Pivot = pivot,
	}
end

function StaminaTrainingRuntime.GetLayout(zone: BasePart, totalCount: number)
	local pivots = {}
	for i = 1, math.max(4, totalCount) do
		local pivotData = GetPivotData(zone, "Pivot" .. tostring(i))
		if pivotData then
			pivots[i] = pivotData
		end
	end

	if not pivots[1] then
		local singlePivot = GetPivotData(zone, "Pivot")
		if singlePivot then
			pivots[1] = singlePivot
		end
	end

	return {
		Zone = zone,
		Pivots = pivots,
		Coach = ZoneUtils.GetCoachPoint(zone),
	}
end

function StaminaTrainingRuntime.GetCycleData(totalCount: number, visualState)
	if not visualState or totalCount <= 0 or visualState.Mode ~= "StaminaTraining" then
		return nil
	end

	local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
	if not zone then
		return nil
	end

	local layout = StaminaTrainingRuntime.GetLayout(zone, totalCount)
	if not layout then
		return nil
	end

	return {
		Layout = layout,
		CycleIndex = 1,
		PhaseName = "Training",
		PhaseElapsed = 0,
		PhaseDuration = 1,
		PhaseProgress = 0,
	}
end

function StaminaTrainingRuntime.GetState(actorIndex: number, totalCount: number, visualState)
	local cycle = StaminaTrainingRuntime.GetCycleData(totalCount, visualState)
	if not cycle then
		return nil
	end

	local targetPart = cycle.Layout.Zone
	local pivotData = cycle.Layout.Pivots[actorIndex]

	if pivotData and pivotData.Pivot then
		targetPart = pivotData.Pivot
	elseif cycle.Layout.Pivots[1] and cycle.Layout.Pivots[1].Pivot then
		targetPart = cycle.Layout.Pivots[1].Pivot
	end

	return {
		Mode = "StaminaTraining",
		ActorIndex = actorIndex,
		TargetPart = targetPart,
		ExpectedAnimation = "Run",
		LookAtPosition = targetPart.Position + targetPart.CFrame.RightVector * 10,
		FacingMode = "Goal",
		PhaseName = cycle.PhaseName,
		PhaseElapsed = cycle.PhaseElapsed,
		PhaseDuration = cycle.PhaseDuration,
		PhaseProgress = cycle.PhaseProgress,
		CycleIndex = cycle.CycleIndex,
		Layout = cycle.Layout,
	}
end

return StaminaTrainingRuntime
