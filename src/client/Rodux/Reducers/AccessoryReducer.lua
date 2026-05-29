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
local AccessoryReducer = Rodux.createReducer({
	SelectedSlot = 1,
}, {
	setSelectedSlot = function(state, action)
		local newState = table.clone(state)
		newState.SelectedSlot = action.value
		return newState
	end,
})

return AccessoryReducer
