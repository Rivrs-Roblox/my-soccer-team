--[=[
 	Owner: CategoryTheory
 	Version: 0.0.1
 	Contact owner if any question, concern or feedback
 ]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Rodux = require(ReplicatedStorage.Packages.rodux)

local AccessoryActions = {
	setSelectedSlot = Rodux.makeActionCreator("setSelectedSlot", function(value)
		return {
			value = value,
		}
	end),
}

return AccessoryActions
