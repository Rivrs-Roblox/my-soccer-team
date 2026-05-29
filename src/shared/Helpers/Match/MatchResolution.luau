local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchConstants = require(ReplicatedStorage.Shared.Data.Match.MatchConstants)

local MatchResolution = {}

local ACTION_TO_STAT = {
	Pass = "Pass",
	Dribble = "Dribble",
	Shoot = "Shoot",
}

local function GetNumeric(value, fallback)
	local parsed = tonumber(value)
	if parsed == nil then
		return fallback
	end

	return parsed
end

function MatchResolution.GetActionStatName(actionName)
	return ACTION_TO_STAT[actionName] or actionName
end

function MatchResolution.GetActorEntry(payload, actorSlot)
	local roster = payload and payload.Roster
	if not roster then
		return nil
	end

	return roster[actorSlot]
end

function MatchResolution.GetEnemyEntry(payload, enemyStep)
	local enemySteps = payload and payload.EnemySteps
	if not enemySteps then
		return nil
	end

	return enemySteps[enemyStep]
end

function MatchResolution.GetPreviewValue(payload, stepData)
	local actionName = stepData.Action
	local statName = MatchResolution.GetActionStatName(actionName)
	local actorSlot = stepData.FromSlot or 1
	local actorEntry = MatchResolution.GetActorEntry(payload, actorSlot)

	local stats = payload and payload.Stats or {}
	local baseStat = GetNumeric(stats[statName], 0)
	local actorMultipliers = actorEntry and actorEntry.Multipliers or nil
	local actorMultiplier = GetNumeric(actorMultipliers and actorMultipliers[statName], 1)

	return math.floor((baseStat * actorMultiplier) + 0.5)
end

function MatchResolution.ResolveStep(payload, stepData, qteTier)
	local actionName = stepData.Action
	local statName = MatchResolution.GetActionStatName(actionName)
	local actorSlot = stepData.FromSlot or 1
	local actorEntry = MatchResolution.GetActorEntry(payload, actorSlot)
	local enemyEntry = MatchResolution.GetEnemyEntry(payload, stepData.EnemyStep)
	local qteTierName = qteTier or "Yellow"
	local qteMultiplier = GetNumeric(MatchConstants.QTE_TIER_MULTIPLIERS[qteTierName], 1)

	local stats = payload and payload.Stats or {}
	local baseStat = GetNumeric(stats[statName], 0)
	local actorMultipliers = actorEntry and actorEntry.Multipliers or nil
	local actorMultiplier = GetNumeric(actorMultipliers and actorMultipliers[statName], 1)
	local enemyValue = GetNumeric(enemyEntry and enemyEntry.Value, 0)
	local previewValue = math.floor((baseStat * actorMultiplier) + 0.5)
	local finalValue = math.floor((baseStat * actorMultiplier * qteMultiplier) + 0.5)

	return {
		Action = actionName,
		StepIndex = stepData.Step,
		ActorSlot = actorSlot,
		TargetSlot = stepData.ToSlot,
		EnemyStep = stepData.EnemyStep,
		EnemyRole = enemyEntry and enemyEntry.Role or "Defender",
		EnemyValue = enemyValue,
		BaseStat = baseStat,
		ActorMultiplier = actorMultiplier,
		PreviewValue = previewValue,
		QteTier = qteTierName,
		QteMultiplier = qteMultiplier,
		FinalValue = finalValue,
		Succeeded = finalValue >= enemyValue,
		ActorDisplayName = actorEntry and actorEntry.DisplayName or "Player",
	}
end

return MatchResolution