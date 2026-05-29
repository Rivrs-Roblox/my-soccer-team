--[=[
 	Owner: CategoryTheory
 	Version: 0.0.1
 	Contact owner if any question, concern or feedback
 ]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Rodux = require(ReplicatedStorage.Packages.rodux)

local TeamActions = {
	setEquippedCharacters = Rodux.makeActionCreator("setEquippedCharacters", function(value)
		return {
			value = value,
		}
	end),

	setSelectedSlot = Rodux.makeActionCreator("setSelectedSlot", function(value)
		return {
			value = value,
		}
	end),
}

return TeamActions
