local MatchFlowRules = {}

local PLAYER2_SLOT = 2
local STEP2_INDEX = 2
local STEP3_INDEX = 3
local STEP4_INDEX = 4
local SHOOT_STEP_INDEX = 5

local function getStepIndex(payload)
	return tonumber(payload and (payload.StepIndex or payload.Step))
end

local function getActorSlot(payload)
	return tonumber(payload and (payload.ActorSlot or payload.FromSlot))
end

function MatchFlowRules.ShouldSkipQte3AfterStep2(resultPayload): boolean
	return resultPayload ~= nil
		and resultPayload.Succeeded == true
		and getStepIndex(resultPayload) == STEP2_INDEX
		and tostring(resultPayload.Action or "") == "Dribble"
		and getActorSlot(resultPayload) == PLAYER2_SLOT
end

local function normalizeStepForOwner(stepData, ownerSlot: number)
	if not stepData or not ownerSlot then
		return
	end

	stepData.FromSlot = ownerSlot

	if stepData.Action == "Shoot" then
		stepData.ToSlot = nil
		stepData.TargetSlot = nil
		stepData.TargetReceiveStep = nil
		return
	end

	if stepData.Action == "Dribble" then
		stepData.ToSlot = ownerSlot
		stepData.TargetSlot = nil
		stepData.TargetReceiveStep = nil
		return
	end

	if stepData.Action == "Pass" and tonumber(stepData.ToSlot) == ownerSlot then
		stepData.Action = "Dribble"
		stepData.ToSlot = ownerSlot
		stepData.TargetSlot = nil
		stepData.TargetReceiveStep = nil
		stepData.PassMode = nil
		stepData.UseZone3RunnerTarget = nil
		stepData.UseZone3RunnerSlot = nil
		stepData.RequireAdvancedRunner = nil
		return
	end

	if stepData.Action == "Pass" then
		stepData.TargetSlot = stepData.ToSlot
		stepData.TargetReceiveStep = stepData.TargetReceiveStep or math.clamp((tonumber(stepData.StepIndex or stepData.Step) or 1) + 1, 2, SHOOT_STEP_INDEX)
	end
end

function MatchFlowRules.ApplyPlayer2Qte3Skip(sequence, currentOwnerSlot: number?)
	local ownerSlot = tonumber(currentOwnerSlot) or PLAYER2_SLOT
	if type(sequence) ~= "table" then
		return
	end

	local skippedStep = sequence[STEP3_INDEX]
	if skippedStep then
		skippedStep.AutoSkipped = true
		skippedStep.SkipReason = "Player2DribbleQte2"
		normalizeStepForOwner(skippedStep, ownerSlot)
	end

	local qte4Step = sequence[STEP4_INDEX]
	if qte4Step then
		qte4Step.Action = "Pass"
		qte4Step.FromSlot = PLAYER2_SLOT
		qte4Step.ToSlot = 4
		qte4Step.TargetSlot = 4
		qte4Step.TargetReceiveStep = SHOOT_STEP_INDEX
		qte4Step.PassMode = "Player2BranchPass"
		qte4Step.Player2Branch = true
		qte4Step.UseZone3RunnerTarget = nil
		qte4Step.UseZone3RunnerSlot = nil
		qte4Step.RequireAdvancedRunner = nil
		qte4Step.StartZone3RunnerAfterResolve = nil
		qte4Step.StartZone3RunnerOverlapOnPass = nil
	end

	local shootStep = sequence[SHOOT_STEP_INDEX]
	if shootStep then
		shootStep.FromSlot = 4
		shootStep.ToSlot = nil
		shootStep.TargetSlot = nil
		shootStep.TargetReceiveStep = nil
	end
end

function MatchFlowRules.SyncUpcomingStepOwner(sequence, nextStepIndex: number, currentOwnerSlot: number?)
	local ownerSlot = tonumber(currentOwnerSlot)
	if type(sequence) ~= "table" or not ownerSlot then
		return
	end

	if tonumber(nextStepIndex) == SHOOT_STEP_INDEX then
		normalizeStepForOwner(sequence[SHOOT_STEP_INDEX], ownerSlot)
	end
end

return MatchFlowRules
