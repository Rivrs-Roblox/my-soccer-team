--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- InventoryReducer
local InventoryReducer = Rodux.createReducer({
	Inventory = "SoccerCharacters",

	DeletingCharacters = false,
	DeletedCharacters = {},

	DeletingAccessories = false,
	DeletedAccessories = {},

	MaxStored = 75,
	SoccerCharacters = {},
	Accessories = {},
}, {
	setInventory = function(state, action)
		local newState = table.clone(state)
		newState.Inventory = action.value
		return newState
	end,

	setDeletingCharacters = function(state, action)
		local newState = table.clone(state)
		newState.DeletingCharacters = action.value
		if action.value == false then
			newState.DeletedCharacters = {}
		end
		return newState
	end,

	addDeletedCharacter = function(state, action)
		local newState = table.clone(state)
		newState.DeletedCharacters = table.clone(state.DeletedCharacters)
		newState.DeletedCharacters[tostring(action.value)] = true
		return newState
	end,

	removeDeletedCharacter = function(state, action)
		local newState = table.clone(state)
		newState.DeletedCharacters = table.clone(state.DeletedCharacters)
		newState.DeletedCharacters[tostring(action.value)] = nil
		return newState
	end,

	setDeletingAccessories = function(state, action)
		local newState = table.clone(state)
		newState.DeletingAccessories = action.value
		if action.value == false then
			newState.DeletedAccessories = {}
		end
		return newState
	end,

	addDeletedAccessory = function(state, action)
		local newState = table.clone(state)
		newState.DeletedAccessories = table.clone(state.DeletedAccessories)
		newState.DeletedAccessories[tostring(action.value)] = true
		return newState
	end,

	removeDeletedAccessory = function(state, action)
		local newState = table.clone(state)
		newState.DeletedAccessories = table.clone(state.DeletedAccessories)
		newState.DeletedAccessories[tostring(action.value)] = nil
		return newState
	end,

	setMaxStored = function(state, action)
		local newState = table.clone(state)
		newState.MaxStored = action.value
		return newState
	end,

	setSoccerCharacters = function(state, action)
		local newState = table.clone(state)
		local normalized = {}
		for id, data in pairs(action.value or {}) do
			normalized[tostring(id)] = data
		end
		newState.SoccerCharacters = normalized
		return newState
	end,

	setAccessories = function(state, action)
		local newState = table.clone(state)
		local normalized = {}
		for id, data in pairs(action.value or {}) do
			normalized[tostring(id)] = data
		end
		newState.Accessories = normalized
		return newState
	end,
})

return InventoryReducer
