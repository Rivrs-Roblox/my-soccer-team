--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- UIReducer
local UIReducer = Rodux.createReducer({
	CurrentUI = "",
	CurrentStoreSectionUI = "Featured",
	CurrentSeasonPassUI = "Quests",
	CurrentPacksUI = "SoccerCharacters",
	CurrentCustomizeUI = "Teams",
	CurrentAccessoriesUI = "All",
}, {
	setCurrentUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentUI = action.value
		return newState
	end,

	resetCurrentUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentUI = nil
		return newState
	end,

	setCurrentStoreSectionUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentStoreSectionUI = action.value
		return newState
	end,

	resetCurrentStoreSectionUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentStoreSectionUI = "Featured"
		return newState
	end,

	setCurrentSeasonPassUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentSeasonPassUI = action.value
		return newState
	end,

	resetCurrentSeasonPassUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentSeasonPassUI = "Quests"
		return newState
	end,

	setCurrentPacksUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentPacksUI = action.value
		return newState
	end,

	resetCurrentPacksUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentPacksUI = "SoccerCharacters"
		return newState
	end,

	setCurrentCustomizeUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentCustomizeUI = action.value
		return newState
	end,

	resetCurrentCustomizeUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentCustomizeUI = "Teams"
		return newState
	end,

	setCurrentAccessoriesUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentAccessoriesUI = action.value
		return newState
	end,

	resetCurrentAccessoriesUI = function(state, action)
		local newState = table.clone(state)
		newState.CurrentAccessoriesUI = "All"
		return newState
	end,
})

return UIReducer
