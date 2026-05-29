--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

local InventoryActions = {
    setInventory = Rodux.makeActionCreator("setInventory", function(value)
        return { value = value }
    end),

    setDeletingCharacters = Rodux.makeActionCreator("setDeletingCharacters", function(value)
        return { value = value }
    end),

    addDeletedCharacter = Rodux.makeActionCreator("addDeletedCharacter", function(value)
        return { value = value }
    end),

    removeDeletedCharacter = Rodux.makeActionCreator("removeDeletedCharacter", function(value)
        return { value = value }
    end),

    setDeletingAccessories = Rodux.makeActionCreator("setDeletingAccessories", function(value)
        return { value = value }
    end),

    addDeletedAccessory = Rodux.makeActionCreator("addDeletedAccessory", function(value)
        return { value = value }
    end),

    removeDeletedAccessory = Rodux.makeActionCreator("removeDeletedAccessory", function(value)
        return { value = value }
    end),

    setMaxStored = Rodux.makeActionCreator("setMaxStored", function(value)
        return { value = value }
    end),

    setSoccerCharacters = Rodux.makeActionCreator("setSoccerCharacters", function(value)
        return { value = value }
    end),

    setAccessories = Rodux.makeActionCreator("setAccessories", function(value)
        return { value = value }
    end),
}

return InventoryActions