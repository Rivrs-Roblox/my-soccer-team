--[=[
 	Owner: rompionyoann
 	Version: 0.0.1
 	Contact owner if any question, concern or feedback
 ]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- Reducer
local OfflineFarmReducer = Rodux.createReducer({
	statsEarned = 0,
}, {
	setStatsEarned = function(state, action)
		local newState = table.clone(state)
		newState.statsEarned = action.value
		return newState
	end,
})

return OfflineFarmReducer
