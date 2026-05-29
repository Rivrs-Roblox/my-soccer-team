local MatchSequenceBuilder = {}

local PRE_SHOT_ACTIONS = { "Pass", "Dribble" }

local FIRST_SLOT = 1
local LAST_SLOT = 4

local PRE_SHOT_STEP_COUNT = 4
local SHOOT_STEP_INDEX = 5
local ZONE3_RUNNER_SLOT = 3

local STRICT_PASS_TARGET_BY_STEP = {
	[1] = 2,
	[2] = 3,
	[3] = 4,
}

local function isRosterSlotUsable(roster, slotNumber: number): boolean
	if slotNumber == FIRST_SLOT then
		return true
	end

	local entry = roster and roster[slotNumber]
	if not entry then
		return false
	end

	if entry.TemplateName == nil then
		return false
	end

	if tonumber(entry.Level) == nil or tonumber(entry.Level) <= 0 then
		return false
	end

	if entry.DisplayName == "Empty" then
		return false
	end

	return true
end

local function buildUsableSlots(roster)
	local usableSlots = {}

	for slotNumber = FIRST_SLOT, LAST_SLOT do
		usableSlots[slotNumber] = isRosterSlotUsable(roster, slotNumber)
	end

	usableSlots[FIRST_SLOT] = true
	return usableSlots
end

local function getStrictPassTargetForStep(stepIndex: number, currentOwnerSlot: number, usableSlots): number?
	local strictTargetSlot = STRICT_PASS_TARGET_BY_STEP[stepIndex]

	if strictTargetSlot then
		if usableSlots[strictTargetSlot] and strictTargetSlot ~= currentOwnerSlot then
			return strictTargetSlot
		end

		return nil
	end

	if stepIndex == 4 then
		-- QTE4 pass should be a return through-ball to the Zone03 runner.
		-- Do not pick a random backward slot here.
		if usableSlots[ZONE3_RUNNER_SLOT] and ZONE3_RUNNER_SLOT ~= currentOwnerSlot then
			return ZONE3_RUNNER_SLOT
		end

		return nil
	end

	return nil
end

local function buildPreShotStep(stepIndex: number, currentOwnerSlot: number, usableSlots, rng: Random)
	local chosenAction = PRE_SHOT_ACTIONS[rng:NextInteger(1, #PRE_SHOT_ACTIONS)]

	local fromSlot = currentOwnerSlot
	local toSlot = currentOwnerSlot
	local action = chosenAction
	local nextOwnerSlot = currentOwnerSlot

	if chosenAction == "Pass" then
		local passTargetSlot = getStrictPassTargetForStep(stepIndex, currentOwnerSlot, usableSlots)

		if passTargetSlot ~= nil and passTargetSlot ~= currentOwnerSlot then
			toSlot = passTargetSlot
			nextOwnerSlot = passTargetSlot
		else
			-- Never fallback to a backward/random pass.
			-- If the correct forward target is not available, keep the play as dribble.
			action = "Dribble"
			toSlot = currentOwnerSlot
			nextOwnerSlot = currentOwnerSlot
		end
	end

	local targetSlot = nil
	local targetReceiveStep = nil
	local passMode = nil

	if action == "Pass" then
		targetSlot = toSlot
		targetReceiveStep = math.clamp(stepIndex + 1, 2, SHOOT_STEP_INDEX)

		if stepIndex == 4 then
			passMode = "ReturnThroughBall"
			targetReceiveStep = SHOOT_STEP_INDEX
		end
	end

	local payload = {
		Step = stepIndex,
		StepIndex = stepIndex,
		Action = action,
		EnemyStep = stepIndex,
		FromSlot = fromSlot,
		ToSlot = toSlot,
		TargetSlot = targetSlot,
		TargetReceiveStep = targetReceiveStep,

		-- Zone03 runner is a tactical role, not a second map marker.
		-- Slot3 must keep advancing so QTE4 can return a through-ball to him.
		Zone3RunnerSlot = ZONE3_RUNNER_SLOT,
		PassMode = passMode,
		UseZone3RunnerSlot = stepIndex == 4 and action == "Pass" or nil,
		UseZone3RunnerTarget = stepIndex == 4 and action == "Pass" or nil,
		StartZone3RunnerAfterResolve = stepIndex == 2 and true or nil,
		StartZone3RunnerOverlapOnPass = stepIndex == 3 and action == "Pass" or nil,
	}

	if stepIndex == 2 then
		payload.AdvanceRunnerSlot = ZONE3_RUNNER_SLOT
	end

	if stepIndex == 3 then
		payload.Qte3ForwardRunnerSlot = ZONE3_RUNNER_SLOT
		payload.AdvanceRunnerSlot = ZONE3_RUNNER_SLOT
	end

	if stepIndex == 4 then
		payload.RequireAdvancedRunner = action == "Pass"
	end

	return payload, nextOwnerSlot
end

function MatchSequenceBuilder.Build(seed: number?, roster)
	local rng = seed and Random.new(seed) or Random.new()
	local usableSlots = buildUsableSlots(roster)

	local sequence = {}
	local currentOwnerSlot = FIRST_SLOT

	for stepIndex = 1, PRE_SHOT_STEP_COUNT do
		local stepPayload
		stepPayload, currentOwnerSlot = buildPreShotStep(stepIndex, currentOwnerSlot, usableSlots, rng)
		sequence[stepIndex] = stepPayload
	end

	sequence[SHOOT_STEP_INDEX] = {
		Step = SHOOT_STEP_INDEX,
		StepIndex = SHOOT_STEP_INDEX,
		Action = "Shoot",
		EnemyStep = SHOOT_STEP_INDEX,
		FromSlot = currentOwnerSlot,
		ToSlot = nil,
		TargetSlot = nil,
		TargetReceiveStep = nil,
		Zone3RunnerSlot = ZONE3_RUNNER_SLOT,
	}

	return sequence
end

return MatchSequenceBuilder
