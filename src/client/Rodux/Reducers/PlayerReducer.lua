--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- PlayerReducer
local PlayerReducer = Rodux.createReducer({
    Money1 = 0,
    Money2 = 0,
    Rebirth = 0,
    Wins = 0,
    Verified = false,
    Shoot = 0,
    Pass = 0,
    Dribble = 0,
}, {
    addMoney1 = function(state, action)
        local newState = table.clone(state)
        newState.Money1 += action.value
        return newState
    end,

    addMoney2 = function(state, action)
        local newState = table.clone(state)
        newState.Money2 += action.value
        return newState
    end,

    addRebirth = function(state, action)
        local newState = table.clone(state)
        newState.Rebirth += action.value
        return newState
    end,

    addWins = function(state, action)
        local newState = table.clone(state)
        newState.Wins += action.value
        return newState
    end,
    
    setVerified = function(state, action)
        local newState = table.clone(state)
        newState.Verified = action.value
        return newState
    end,

    addShoot = function(state, action)
        local newState = table.clone(state)
        newState.Shoot += action.value
        return newState
    end,

    setShoot = function(state, action)
        local newState = table.clone(state)
        newState.Shoot = action.value
        return newState
    end,

    addPass = function(state, action)
        local newState = table.clone(state)
        newState.Pass += action.value
        return newState
    end,

    setPass = function(state, action)
        local newState = table.clone(state)
        newState.Pass = action.value
        return newState
    end,

    addDribble = function(state, action)
        local newState = table.clone(state)
        newState.Dribble += action.value
        return newState
    end,

    setDribble = function(state, action)
        local newState = table.clone(state)
        newState.Dribble = action.value
        return newState
    end,
})

return PlayerReducer