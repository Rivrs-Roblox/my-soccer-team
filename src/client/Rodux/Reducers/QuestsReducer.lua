--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- QuestsReducer
local QuestsReducer = Rodux.createReducer({
    -- Free Character
    Clicks = 0,
    BattlesWon = 0,
    PlayTime = 0,

    ClaimableCharacters = 0,
}, {
    -- Free Character
    addClicks = function(state, action)
        local newState = table.clone(state)
        newState.Clicks += action.value
        return newState
    end,

    setClicks = function(state, action)
        local newState = table.clone(state)
        newState.Clicks = action.value
        return newState
    end,

    addBattlesWon = function(state, action)
        local newState = table.clone(state)
        newState.BattlesWon += action.value
        return newState
    end,

    setBattlesWon = function(state, action)
        local newState = table.clone(state)
        newState.BattlesWon = action.value
        return newState
    end,

    addPlayTime = function(state, action)
        local newState = table.clone(state)
        newState.PlayTime += action.value
        return newState
    end,

    setPlayTime = function(state, action)
        local newState = table.clone(state)
        newState.PlayTime = action.value
        return newState
    end,

    addClaimableCharacters = function(state, action)
        local newState = table.clone(state)
        newState.ClaimableCharacters += action.value
        return newState
    end,

    setClaimableCharacters = function(state, action)
        local newState = table.clone(state)
        newState.ClaimableCharacters = action.value
        return newState
    end,
})

return QuestsReducer