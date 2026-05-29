local Workspace = game:GetService("Workspace")

local ZoneUtils = require(script.Parent.Parent.Training.ZoneUtils)
local Settings = require(script.Parent.Settings)

local ShootTrainingRuntime = {}
ShootTrainingRuntime.StatType = "Shoot"
ShootTrainingRuntime.Mode = "ShootTraining"
ShootTrainingRuntime.SupportsWorldBallShot = true

local function GetIntervalDuration()
	local s = Settings.Shoot
	return s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration
end

local function GetTotalJourneyDuration()
	local s = Settings.Shoot
	return s.MoveToShootDuration
		+ s.ReadyToShootDuration
		+ s.ShootDuration
		+ s.ExitRightDuration
		+ s.ReturnBackDuration
		+ s.RejoinDuration
		+ s.SettleDuration
end

function ShootTrainingRuntime.GetLayout(zone: BasePart, totalCount: number)
	local folder = zone:FindFirstChild("CompanionPoints")
	if not folder then
		return nil
	end

	local shootPoint = folder:FindFirstChild("ShootPoint")
	local exitRight = folder:FindFirstChild("ExitRight")
	local returnBack = folder:FindFirstChild("ReturnBack")
	local rejoin03 = folder:FindFirstChild("Rejoin_03")

	if not shootPoint then
		warn("[ShootTraining] Missing ShootPoint in " .. zone:GetFullName())
	end
	if not exitRight then
		warn("[ShootTraining] Missing ExitRight in " .. zone:GetFullName())
	end
	if not returnBack then
		warn("[ShootTraining] Missing ReturnBack in " .. zone:GetFullName())
	end
	if not rejoin03 then
		warn("[ShootTraining] Missing Rejoin_03 in " .. zone:GetFullName())
	end

	if
		not shootPoint
		or not shootPoint:IsA("BasePart")
		or not exitRight
		or not exitRight:IsA("BasePart")
		or not returnBack
		or not returnBack:IsA("BasePart")
		or not rejoin03
		or not rejoin03:IsA("BasePart")
	then
		return nil
	end

	local queuePoints = {}
	local queueNeeded = math.max(0, totalCount - 1)

	for i = 1, queueNeeded do
		local point = folder:FindFirstChild(string.format("Queue_%02d", i))
			or folder:FindFirstChild("Queue_" .. tostring(i))

		if not point or not point:IsA("BasePart") then
			return nil
		end

		queuePoints[i] = point
	end

	local goalTargetPart = ZoneUtils.GetShootZoneTarget(zone)
	local ballSpawnPart = ZoneUtils.GetShootZoneBall(zone)

	local lookAtPosition = goalTargetPart and goalTargetPart.Position
		or (shootPoint.Position + shootPoint.CFrame.LookVector * 20)

	return {
		Zone = zone,
		ShootPoint = shootPoint,
		QueuePoints = queuePoints,
		ExitRight = exitRight,
		ReturnBack = returnBack,
		Rejoin03 = rejoin03,
		BallSpawnPart = ballSpawnPart,
		GoalTargetPart = goalTargetPart,
		LookAtPosition = lookAtPosition,
		Coach = ZoneUtils.GetCoachPoint(zone),
	}
end

function ShootTrainingRuntime.GetCycleData(totalCount: number, visualState)
	if not visualState or totalCount <= 0 or visualState.Mode ~= "ShootTraining" then
		return nil
	end

	local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
	if not zone then
		return nil
	end

	local layout = ShootTrainingRuntime.GetLayout(zone, totalCount)
	if not layout then
		return nil
	end

	local s = Settings.Shoot
	local intervalDuration = GetIntervalDuration()
	local localTime = (visualState.ServerStartTime and (Workspace:GetServerTimeNow() - visualState.ServerStartTime))
		or 0

	local cycleIndex = math.floor(localTime / intervalDuration)
	local shooterIndex = (cycleIndex % totalCount) + 1
	
	-- Calculate shooter's phase for TrainingController ball shot logic
	local cycleElapsed = localTime % intervalDuration
	local phaseName = "MovingToShoot"
	local phaseElapsed = 0
	local phaseDuration = s.MoveToShootDuration
	local currentTotal = 0

	if cycleElapsed < (currentTotal + s.MoveToShootDuration) then
		phaseName = "MovingToShoot"
		phaseElapsed = cycleElapsed - currentTotal
		phaseDuration = s.MoveToShootDuration
	elseif cycleElapsed < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration) then
		currentTotal = currentTotal + s.MoveToShootDuration
		phaseName = "ReadyToShoot"
		phaseElapsed = cycleElapsed - currentTotal
		phaseDuration = s.ReadyToShootDuration
	else
		currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration
		phaseName = "Shooting"
		phaseElapsed = cycleElapsed - currentTotal
		phaseDuration = s.ShootDuration
	end

	return {
		Layout = layout,
		LocalTime = localTime,
		IntervalDuration = intervalDuration,
		CycleIndex = cycleIndex,
		ShooterIndex = shooterIndex,
		PhaseName = phaseName,
		PhaseElapsed = phaseElapsed,
		PhaseDuration = phaseDuration,
		PhaseProgress = math.clamp(phaseElapsed / math.max(phaseDuration, 0.001), 0, 1),
		LookAtPosition = layout.LookAtPosition,
	}
end

function ShootTrainingRuntime.GetState(actorIndex: number, totalCount: number, visualState)
	local cycle = ShootTrainingRuntime.GetCycleData(totalCount, visualState)
	if not cycle then
		return nil
	end

	local layout = cycle.Layout
	local s = Settings.Shoot
	local intervalDuration = cycle.IntervalDuration
	local totalJourneyDuration = GetTotalJourneyDuration()
	local totalLoopDuration = math.max(totalCount * intervalDuration, totalJourneyDuration)

	-- Calculate this specific actor's progress in the staggered timeline
	local actorOffset = (actorIndex - 1) * intervalDuration
	local rawActorTime = cycle.LocalTime - actorOffset
	local actorLocalTime = rawActorTime % totalLoopDuration
	local actorCycleIndex = math.floor(rawActorTime / totalLoopDuration)

	if rawActorTime >= 0 and actorLocalTime < totalJourneyDuration then
		-- Actor is currently in their active journey (shooting or returning)
		local phaseName = "MovingToShoot"
		local phaseElapsed = 0
		local phaseDuration = s.MoveToShootDuration
		local currentTotal = 0

		if actorLocalTime < (currentTotal + s.MoveToShootDuration) then
			phaseName = "MovingToShoot"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.MoveToShootDuration
		elseif actorLocalTime < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration) then
			currentTotal = currentTotal + s.MoveToShootDuration
			phaseName = "ReadyToShoot"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.ReadyToShootDuration
		elseif actorLocalTime < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration) then
			currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration
			phaseName = "Shooting"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.ShootDuration
		elseif actorLocalTime < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration) then
			currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration
			phaseName = "ExitingRight"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.ExitRightDuration
		elseif actorLocalTime < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration + s.ReturnBackDuration) then
			currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration
			phaseName = "ReturningBack"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.ReturnBackDuration
		elseif actorLocalTime < (currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration + s.ReturnBackDuration + s.RejoinDuration) then
			currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration + s.ReturnBackDuration
			phaseName = "RejoiningQueue"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.RejoinDuration
		else
			currentTotal = currentTotal + s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration + s.ExitRightDuration + s.ReturnBackDuration + s.RejoinDuration
			phaseName = "SettlingQueue"
			phaseElapsed = actorLocalTime - currentTotal
			phaseDuration = s.SettleDuration
		end

		local targetPart = layout.ShootPoint
		local expectedAnimation = "Run"
		local lookAtPosition = nil
		local facingMode = "Move"

		if phaseName == "MovingToShoot" then
			targetPart = layout.ShootPoint
			expectedAnimation = "Run"
			lookAtPosition = nil
			facingMode = "Move"
		elseif phaseName == "ReadyToShoot" then
			targetPart = layout.ShootPoint
			expectedAnimation = "Idle"
			lookAtPosition = cycle.LookAtPosition
			facingMode = "Goal"
		elseif phaseName == "Shooting" then
			targetPart = layout.ShootPoint
			expectedAnimation = "Shoot"
			lookAtPosition = cycle.LookAtPosition
			facingMode = "Goal"
		elseif phaseName == "ExitingRight" then
			targetPart = layout.ExitRight
			expectedAnimation = "Run"
			lookAtPosition = nil
			facingMode = "Move"
		elseif phaseName == "ReturningBack" then
			targetPart = layout.ReturnBack
			expectedAnimation = "Run"
			lookAtPosition = nil
			facingMode = "Move"
		elseif phaseName == "RejoiningQueue" then
			targetPart = layout.Rejoin03
			expectedAnimation = "Run"
			lookAtPosition = nil
			facingMode = "Move"
		elseif phaseName == "SettlingQueue" then
			targetPart = layout.QueuePoints[totalCount - 1] or layout.ShootPoint
			expectedAnimation = "Idle"
			lookAtPosition = nil
			facingMode = "Move"
		end

		return {
			Mode = "ShootTraining",
			ActorIndex = actorIndex,
			TargetPart = targetPart,
			ExpectedAnimation = expectedAnimation,
			LookAtPosition = lookAtPosition,
			FacingMode = facingMode,
			PhaseName = phaseName,
			PhaseElapsed = phaseElapsed,
			PhaseDuration = phaseDuration,
			PhaseProgress = math.clamp(phaseElapsed / math.max(phaseDuration, 0.001), 0, 1),
			CycleIndex = actorCycleIndex,
			ShooterIndex = cycle.ShooterIndex,
			Layout = layout,
		}
	end

	-- Actor is currently waiting in the queue
	local queueSlot = ((actorIndex - cycle.ShooterIndex - 1) % totalCount) + 1
	local targetPart = layout.QueuePoints[queueSlot]
	if not targetPart then
		return nil
	end

	return {
		Mode = "ShootTraining",
		ActorIndex = actorIndex,
		TargetPart = targetPart,
		ExpectedAnimation = "Idle",
		LookAtPosition = nil,
		FacingMode = "Move",
		PhaseName = "Queued",
		PhaseElapsed = 0,
		PhaseDuration = 1,
		PhaseProgress = 0,
		CycleIndex = actorCycleIndex,
		ShooterIndex = cycle.ShooterIndex,
		Layout = layout,
	}
end

return ShootTrainingRuntime
