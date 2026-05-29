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
local TeamReducer = Rodux.createReducer({
	EquippedSoccerCharacters = {},
	SelectedSlot = nil,
}, {
	setEquippedCharacters = function(state, action)
		local newState = table.clone(state)
		local normalized = {}
		for slot, id in pairs(action.value or {}) do
			normalized[slot] = tostring(id)
		end
		newState.EquippedSoccerCharacters = normalized
		return newState
	end,

	setSelectedSlot = function(state, action)
		local newState = table.clone(state)
		newState.SelectedSlot = action.value
		return newState
	end,
})

return TeamReducer
