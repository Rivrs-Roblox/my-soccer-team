local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.rodux)

local AutoReducer = Rodux.createReducer({
	AutoTraining = false,
	AutoTrainingCurrent = nil,
}, {
	setAutoTraining = function(state, action)
		local newState = table.clone(state)
		newState.AutoTraining = action.value
		return newState
	end,

	setAutoTrainingCurrent = function(state, action)
		local newState = table.clone(state)
		newState.AutoTrainingCurrent = action.value
		return newState
	end,
})

return AutoReducer