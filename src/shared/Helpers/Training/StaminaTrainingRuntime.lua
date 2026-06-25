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
	local exitPivots = {}
	for i = 1, math.max(4, totalCount) do
		local pivotData = GetPivotData(zone, "Pivot" .. tostring(i))
		if pivotData then
			pivots[i] = pivotData
		end

		local exitPivotData = GetPivotData(zone, "ExitPivot" .. tostring(i))
		if exitPivotData then
			exitPivots[i] = exitPivotData
		end
	end

	if not pivots[1] then
		local singlePivot = GetPivotData(zone, "Pivot")
		if singlePivot then
			pivots[1] = singlePivot
		end
	end

	if not exitPivots[1] then
		local singleExitPivot = GetPivotData(zone, "ExitPivot")
		if singleExitPivot then
			exitPivots[1] = singleExitPivot
		end
	end

	return {
		Zone = zone,
		Pivots = pivots,
		ExitPivots = exitPivots,
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
	local isDraining = visualState.IsDraining == true
	local phaseName = cycle.PhaseName
	local phaseProgress = cycle.PhaseProgress
	local expectedAnimation = "Run"
	local previousTargetPart = nil

	local pivotData = cycle.Layout.Pivots[actorIndex]
	local defaultPivot = pivotData and pivotData.Pivot or (cycle.Layout.Pivots[1] and cycle.Layout.Pivots[1].Pivot)

	if isDraining then
		local exitPivotData = cycle.Layout.ExitPivots[actorIndex]
		if exitPivotData and exitPivotData.Pivot then
			targetPart = exitPivotData.Pivot
		elseif cycle.Layout.ExitPivots[1] and cycle.Layout.ExitPivots[1].Pivot then
			targetPart = cycle.Layout.ExitPivots[1].Pivot
		end

		local elapsed = Workspace:GetServerTimeNow() - (visualState.DrainStartTime or 0)
		local totalTime = visualState.DrainTotalTime or 1
		local progress = math.clamp(elapsed / math.max(totalTime, 0.001), 0, 1)

		phaseName = "NodeRun"
		phaseProgress = progress
		previousTargetPart = defaultPivot
		expectedAnimation = "Walk"
	else
		if defaultPivot then
			targetPart = defaultPivot
		end
	end

	local lookAtPosition = targetPart.Position + targetPart.CFrame.RightVector * 10
	if defaultPivot then
		lookAtPosition = targetPart.Position + defaultPivot.CFrame.RightVector * 10
	end

	return {
		Mode = "StaminaTraining",
		ActorIndex = actorIndex,
		TargetPart = targetPart,
		PreviousTargetPart = previousTargetPart,
		ExpectedAnimation = expectedAnimation,
		LookAtPosition = lookAtPosition,
		FacingMode = "Goal",
		PhaseName = phaseName,
		PhaseElapsed = cycle.PhaseElapsed,
		PhaseDuration = cycle.PhaseDuration,
		PhaseProgress = phaseProgress,
		CycleIndex = cycle.CycleIndex,
		Layout = cycle.Layout,
	}
end

return StaminaTrainingRuntime
