local Workspace = game:GetService("Workspace")
local Settings = require(script.Parent.Settings)
local ZoneUtils = require(script.Parent.Parent.Training.ZoneUtils)

local DribbleTrainingRuntime = {}
DribbleTrainingRuntime.StatType = "Dribble"
DribbleTrainingRuntime.Mode = "DribbleTraining"
DribbleTrainingRuntime.SupportsWorldBallDribble = true

local NODE_NAMES = {
	"Node01",
	"Node02",
	"Node03",
	"Node04",
	"Node05",
}

local function FindRuntimePoint(zone: Instance, pointName: string): BasePart?
	local direct = zone:FindFirstChild(pointName)
	if direct and direct:IsA("BasePart") then
		return direct
	end

	local runtimeFolder = zone:FindFirstChild("RuntimePoints")
	if runtimeFolder then
		local nested = runtimeFolder:FindFirstChild(pointName)
		if nested and nested:IsA("BasePart") then
			return nested
		end
	end

	return nil
end

local function GetQueuePoint(zone: Instance, slotIndex: number): BasePart?
	local padded = FindRuntimePoint(zone, string.format("Queue_%02d", slotIndex))
	if padded then
		return padded
	end

	return FindRuntimePoint(zone, "Queue_" .. tostring(slotIndex))
end

function DribbleTrainingRuntime.GetLayout(zone: Instance)
	local startPoint = FindRuntimePoint(zone, "StartPoint")
	local exit01 = FindRuntimePoint(zone, "Exit01") or FindRuntimePoint(zone, "ExitBack")
	local exit02 = FindRuntimePoint(zone, "Exit02") or exit01

	if not startPoint then
		warn("[DribbleTrainingRuntime] StartPoint not found:", zone:GetFullName())
		return nil
	end

	if not exit01 then
		warn("[DribbleTrainingRuntime] Exit01 / ExitBack not found:", zone:GetFullName())
		return nil
	end

	if not exit02 then
		warn("[DribbleTrainingRuntime] Exit02 not found:", zone:GetFullName())
		return nil
	end

	local nodes = {}
	for _, nodeName in ipairs(NODE_NAMES) do
		local node = FindRuntimePoint(zone, nodeName)
		if not node then
			warn("[DribbleTrainingRuntime] Missing node:", nodeName, "zone:", zone:GetFullName())
			return nil
		end
		table.insert(nodes, node)
	end

	local queuePoints = {
		GetQueuePoint(zone, 1),
		GetQueuePoint(zone, 2),
		GetQueuePoint(zone, 3),
	}

	for i = 1, 3 do
		if not queuePoints[i] then
			warn("[DribbleTrainingRuntime] Missing Queue_0" .. i .. " in zone:", zone:GetFullName())
			return nil
		end
	end

	local ballArea = zone:FindFirstChild("BallArea", true)

	return {
		Zone = zone,
		StartPoint = startPoint,
		Nodes = nodes,
		Exit01 = exit01,
		Exit02 = exit02,
		QueuePoints = queuePoints,
		BallArea = ballArea,
		Coach = ZoneUtils.GetCoachPoint(zone),
	}
end

local function GetCycleDuration()
	local s = Settings.Dribble
	return s.StartHoldDuration + (#NODE_NAMES * s.NodeDuration)
end

local function GetRunnerIndex(cycleIndex: number, totalCount: number): number
	return (cycleIndex % totalCount) + 1
end

local function GetPreviousRunnerIndex(cycleIndex: number, totalCount: number): number?
	if cycleIndex <= 0 then
		return nil
	end

	return ((cycleIndex - 1) % totalCount) + 1
end

local function GetQueueActorIndex(
	cycleIndex: number,
	runnerIndex: number,
	queueSlot: number,
	totalCount: number
): number?
	if queueSlot < 1 or queueSlot > 3 then
		return nil
	end

	local previousRunnerIndex = GetPreviousRunnerIndex(cycleIndex, totalCount)
	local queueActors = {}

	for offset = 1, totalCount - 1 do
		local actorIndex = ((runnerIndex + offset - 1) % totalCount) + 1
		if actorIndex ~= previousRunnerIndex then
			table.insert(queueActors, actorIndex)
		end
	end

	return queueActors[queueSlot]
end

local function GetExitingTarget(layout, exitElapsed: number)
	local s = Settings.Dribble
	if exitElapsed < s.Exit01Duration then
		return layout.Exit01, "Run"
	end

	if exitElapsed < (s.Exit01Duration + s.Exit02Duration) then
		return layout.Exit02, "Run"
	end

	if exitElapsed < (s.Exit01Duration + s.Exit02Duration + s.RejoinDuration) then
		return layout.QueuePoints[3], "Run"
	end

	return layout.QueuePoints[3], "Idle"
end

function DribbleTrainingRuntime.GetCycleData(totalCount: number, visualState)
	if not visualState or visualState.Mode ~= "DribbleTraining" then
		return nil
	end

	if totalCount < 1 then
		return nil
	end

	local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
	if not zone then
		warn("[DribbleTrainingRuntime] Zone not found for key:", visualState.ZoneKey)
		return nil
	end

	local layout = DribbleTrainingRuntime.GetLayout(zone)
	if not layout then
		return nil
	end

	local now = Workspace:GetServerTimeNow()
	local startTime = visualState.ServerStartTime or now
	local elapsed = math.max(0, now - startTime)

	local cycleDuration = GetCycleDuration()
	local cycleIndex = math.floor(elapsed / cycleDuration)
	local phaseTime = elapsed % cycleDuration

	local runnerIndex = GetRunnerIndex(cycleIndex, totalCount)
	local previousRunnerIndex = GetPreviousRunnerIndex(cycleIndex, totalCount)

	local s = Settings.Dribble
	local phaseName = "StartHold"
	local phaseElapsed = 0
	local phaseDuration = s.StartHoldDuration
	local activeTargetPart = layout.StartPoint
	local activeNodeIndex = 0

	if phaseTime < s.StartHoldDuration then
		phaseName = "StartHold"
		phaseElapsed = phaseTime
		phaseDuration = s.StartHoldDuration
		activeTargetPart = layout.StartPoint
		activeNodeIndex = 0
	else
		local nodeWindow = phaseTime - s.StartHoldDuration
		local nodeIndex = math.floor(nodeWindow / s.NodeDuration) + 1
		nodeIndex = math.clamp(nodeIndex, 1, #layout.Nodes)

		phaseName = "NodeRun"
		phaseElapsed = nodeWindow % s.NodeDuration
		phaseDuration = s.NodeDuration
		activeTargetPart = layout.Nodes[nodeIndex]
		activeNodeIndex = nodeIndex
	end

	return {
		Layout = layout,
		CycleIndex = cycleIndex,
		RunnerIndex = runnerIndex,
		PreviousRunnerIndex = previousRunnerIndex,
		PhaseName = phaseName,
		PhaseElapsed = phaseElapsed,
		PhaseDuration = phaseDuration,
		PhaseProgress = math.clamp(phaseElapsed / math.max(phaseDuration, 0.001), 0, 1),
		PhaseTime = phaseTime,
		ActiveTargetPart = activeTargetPart,
		ActiveNodeIndex = activeNodeIndex,
		Token = string.format("%d:%s:%d", cycleIndex, phaseName, activeNodeIndex),
	}
end

function DribbleTrainingRuntime.GetState(actorIndex: number, totalCount: number, visualState)
	local cycle = DribbleTrainingRuntime.GetCycleData(totalCount, visualState)
	if not cycle then
		return nil
	end

	local s = Settings.Dribble

	local layout = cycle.Layout
	local runnerIndex = cycle.RunnerIndex
	local previousRunnerIndex = cycle.PreviousRunnerIndex

	if actorIndex == runnerIndex then
		local lookAtPosition = cycle.ActiveTargetPart.Position

		if cycle.PhaseName == "StartHold" and layout.Nodes[1] then
			lookAtPosition = layout.Nodes[1].Position
		end

		local expectedAnimation = cycle.PhaseName == "StartHold" and "Idle" or "Dribble"

		return {
			Mode = "DribbleTraining",
			ActorIndex = actorIndex,
			TargetPart = cycle.ActiveTargetPart,
			ExpectedAnimation = expectedAnimation,
			LookAtPosition = lookAtPosition,
			FacingMode = "Move",
			PhaseName = cycle.PhaseName,
			PhaseElapsed = cycle.PhaseElapsed,
			PhaseDuration = cycle.PhaseDuration,
			PhaseProgress = cycle.PhaseProgress,
			ActiveNodeIndex = cycle.ActiveNodeIndex,
			CycleIndex = cycle.CycleIndex,
			RunnerIndex = runnerIndex,
			Layout = layout,
		}
	end

	if previousRunnerIndex and actorIndex == previousRunnerIndex then
		local exitElapsed = cycle.PhaseTime
		local exitingTarget, exitingAnimation = GetExitingTarget(layout, exitElapsed)

		return {
			Mode = "DribbleTraining",
			ActorIndex = actorIndex,
			TargetPart = exitingTarget,
			ExpectedAnimation = exitingAnimation,
			LookAtPosition = layout.QueuePoints[3].Position,
			FacingMode = "Move",
			PhaseName = "Exiting",
			PhaseElapsed = exitElapsed,
			PhaseDuration = s.Exit01Duration + s.Exit02Duration + s.RejoinDuration,
			PhaseProgress = math.clamp(
				exitElapsed / math.max(s.Exit01Duration + s.Exit02Duration + s.RejoinDuration, 0.001),
				0,
				1
			),
			CycleIndex = cycle.CycleIndex,
			RunnerIndex = runnerIndex,
			Layout = layout,
		}
	end

	for queueSlot = 1, 3 do
		local queueActorIndex = GetQueueActorIndex(cycle.CycleIndex, runnerIndex, queueSlot, totalCount)
		if queueActorIndex == actorIndex then
			local queuePoint = layout.QueuePoints[queueSlot]
			if not queuePoint then
				return nil
			end

			return {
				Mode = "DribbleTraining",
				ActorIndex = actorIndex,
				TargetPart = queuePoint,
				ExpectedAnimation = "Idle",
				LookAtPosition = layout.StartPoint.Position,
				FacingMode = "Goal",
				PhaseName = "Queued",
				PhaseElapsed = cycle.PhaseElapsed,
				PhaseDuration = cycle.PhaseDuration,
				PhaseProgress = cycle.PhaseProgress,
				CycleIndex = cycle.CycleIndex,
				RunnerIndex = runnerIndex,
				Layout = layout,
			}
		end
	end

	return nil
end

return DribbleTrainingRuntime
