local ShootTrainingRuntime = require(script.Parent.ShootTrainingRuntime)
local PassTrainingRuntime = require(script.Parent.PassTrainingRuntime)
local DribbleTrainingRuntime = require(script.Parent.DribbleTrainingRuntime)

local runtimesByStatType = {
	Shoot = ShootTrainingRuntime,
	Pass = PassTrainingRuntime,
	Dribble = DribbleTrainingRuntime,
}

local TrainingRuntimeRegistry = {}

function TrainingRuntimeRegistry.GetRuntimeByStatType(statType: string?)
	if type(statType) ~= "string" then
		return nil
	end

	return runtimesByStatType[statType]
end

function TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	if not visualState then
		return nil
	end

	return TrainingRuntimeRegistry.GetRuntimeByStatType(visualState.StatType)
end

function TrainingRuntimeRegistry.IsRuntimeVisualState(visualState): boolean
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	return runtime ~= nil
end

function TrainingRuntimeRegistry.GetCycleData(totalCount: number, visualState)
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	if not runtime or type(runtime.GetCycleData) ~= "function" then
		return nil
	end

	return runtime.GetCycleData(totalCount, visualState)
end

function TrainingRuntimeRegistry.GetActorState(actorIndex: number, totalCount: number, visualState)
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	if not runtime or type(runtime.GetState) ~= "function" then
		return nil
	end

	return runtime.GetState(actorIndex, totalCount, visualState)
end

function TrainingRuntimeRegistry.SupportsWorldBallShot(visualState): boolean
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	return runtime ~= nil and runtime.SupportsWorldBallShot == true
end

function TrainingRuntimeRegistry.SupportsWorldBallPass(visualState): boolean
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	return runtime ~= nil and runtime.SupportsWorldBallPass == true
end

function TrainingRuntimeRegistry.SupportsWorldBallDribble(visualState): boolean
	local runtime = TrainingRuntimeRegistry.GetRuntimeForVisualState(visualState)
	return runtime ~= nil and runtime.SupportsWorldBallDribble == true
end

return TrainingRuntimeRegistry