local Workspace = game:GetService("Workspace")
local ZoneUtils = require(script.Parent.Parent.Training.ZoneUtils)
local Settings = require(script.Parent.Settings)

local PassTrainingRuntime = {}
PassTrainingRuntime.StatType = "Pass"
PassTrainingRuntime.Mode = "PassTraining"
PassTrainingRuntime.SupportsWorldBallPass = true



local function GetPivotData(zone: BasePart, pivotName: string)
	local pivot = zone:FindFirstChild(pivotName)
	if not pivot or not pivot:IsA("BasePart") then
		return nil
	end

	local ballArea = pivot:FindFirstChild("BallArea")
	local football = ballArea and ballArea:FindFirstChild("Football")

	local ballRoot = nil
	local ballPart = nil

	if football then
		local mesh = football:FindFirstChild("Mesh")

		if mesh and mesh:IsA("BasePart") then
			ballRoot = mesh
			ballPart = mesh
		elseif football:IsA("BasePart") then
			ballRoot = football
			ballPart = football
		else
			ballPart = ZoneUtils.FindFirstBasePart(football)
			ballRoot = ballPart
		end
	end

	return {
		Name = pivotName,
		Pivot = pivot,
		BallArea = ballArea,
		BallRoot = ballRoot,
		BallPart = ballPart,
	}
end

function PassTrainingRuntime.GetLayout(zone: BasePart)
	local pivots = {
		[1] = GetPivotData(zone, "Pivot1"),
		[2] = GetPivotData(zone, "Pivot2"),
		[3] = GetPivotData(zone, "Pivot3"),
		[4] = GetPivotData(zone, "Pivot4"),
	}

	for index = 1, 4 do
		local pivotData = pivots[index]
		if not pivotData or not pivotData.Pivot then
			return nil
		end
	end

	-- carrier balls only:
	-- ball A seeded at Pivot2 and loops 2 <-> 4
	-- ball B seeded at Pivot3 and loops 3 <-> 1
	local lanes = {
		{
			Id = "Lane24",
			CarrierIndex = 2,
			ForwardFromIndex = 2,
			ForwardToIndex = 4,
			BackwardFromIndex = 4,
			BackwardToIndex = 2,
		},
		{
			Id = "Lane31",
			CarrierIndex = 3,
			ForwardFromIndex = 3,
			ForwardToIndex = 1,
			BackwardFromIndex = 1,
			BackwardToIndex = 3,
		},
	}

	return {
		Zone = zone,
		Pivots = pivots,
		Lanes = lanes,
		Coach = ZoneUtils.GetCoachPoint(zone),
	}
end

local function GetPartnerIndex(actorIndex: number): number?
	if actorIndex == 1 then
		return 3
	elseif actorIndex == 3 then
		return 1
	elseif actorIndex == 2 then
		return 4
	elseif actorIndex == 4 then
		return 2
	end

	return nil
end

function PassTrainingRuntime.GetCycleData(totalCount: number, visualState)
	if not visualState or visualState.Mode ~= "PassTraining" then
		return nil
	end

	if totalCount < 1 then
		return nil
	end

	local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
	if not zone then
		return nil
	end
	
	local layout = PassTrainingRuntime.GetLayout(zone)
	if not layout then
		return nil
	end

	local now = Workspace:GetServerTimeNow()
	local startTime = visualState.ServerStartTime or now
	local elapsed = math.max(0, now - startTime) * (visualState.Level or 1)

	local s = Settings.Pass
	local startDelay = s.StartDelay or 0
	
	if elapsed < startDelay then
		return {
			Layout = layout,
			CycleIndex = -1,
			PhaseName = "Preparing",
			PhaseElapsed = elapsed,
			PhaseDuration = startDelay,
			PhaseProgress = math.clamp(elapsed / math.max(startDelay, 0.001), 0, 1),
			Token = "Preparing",
		}
	end

	local effectiveElapsed = elapsed - startDelay
	local cycleDuration = s.PassDuration + s.SettleDuration + s.PassDuration + s.SettleDuration
	local cycleIndex = math.floor(effectiveElapsed / cycleDuration)
	local phaseTime = effectiveElapsed % cycleDuration

	local phaseName = "ForwardPass"
	local phaseElapsed = 0
	local phaseDuration = s.PassDuration

	if phaseTime < s.PassDuration then
		phaseName = "ForwardPass"
		phaseElapsed = phaseTime
		phaseDuration = s.PassDuration
	elseif phaseTime < (s.PassDuration + s.SettleDuration) then
		phaseName = "ForwardSettle"
		phaseElapsed = phaseTime - s.PassDuration
		phaseDuration = s.SettleDuration
	elseif phaseTime < (s.PassDuration + s.SettleDuration + s.PassDuration) then
		phaseName = "BackwardPass"
		phaseElapsed = phaseTime - s.PassDuration - s.SettleDuration
		phaseDuration = s.PassDuration
	else
		phaseName = "BackwardSettle"
		phaseElapsed = phaseTime - s.PassDuration - s.SettleDuration - s.PassDuration
		phaseDuration = s.SettleDuration
	end

	return {
		Layout = layout,
		CycleIndex = cycleIndex,
		PhaseName = phaseName,
		PhaseElapsed = phaseElapsed,
		PhaseDuration = phaseDuration,
		PhaseProgress = math.clamp(phaseElapsed / math.max(phaseDuration, 0.001), 0, 1),
		Token = string.format("%d:%s", cycleIndex, phaseName),
	}
end

function PassTrainingRuntime.GetState(actorIndex: number, totalCount: number, visualState)
	local cycle = PassTrainingRuntime.GetCycleData(totalCount, visualState)
	if not cycle then
		return nil
	end

	local layout = cycle.Layout
	local pivotData = layout.Pivots[actorIndex]
	if not pivotData then
		return nil
	end

	local partnerIndex = GetPartnerIndex(actorIndex)
	local partnerPivot = partnerIndex and layout.Pivots[partnerIndex]
	local lookAtPosition = partnerPivot and partnerPivot.Pivot.Position or pivotData.Pivot.Position

	local expectedAnimation = "Idle"

	if cycle.PhaseName == "ForwardPass" then
		if actorIndex == 2 or actorIndex == 3 then
			expectedAnimation = "Shoot"
		end
	elseif cycle.PhaseName == "BackwardPass" then
		if actorIndex == 4 or actorIndex == 1 then
			expectedAnimation = "Shoot"
		end
	end

	return {
		Mode = "PassTraining",
		ActorIndex = actorIndex,
		TargetPart = pivotData.Pivot,
		ExpectedAnimation = expectedAnimation,
		LookAtPosition = lookAtPosition,
		FacingMode = "Goal",
		PhaseName = cycle.PhaseName,
		PhaseElapsed = cycle.PhaseElapsed,
		PhaseDuration = cycle.PhaseDuration,
		PhaseProgress = cycle.PhaseProgress,
		CycleIndex = cycle.CycleIndex,
		Layout = layout,
	}
end

return PassTrainingRuntime
