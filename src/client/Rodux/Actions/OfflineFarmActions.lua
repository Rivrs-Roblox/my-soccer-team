--[=[
 	Owner: CategoryTheory
 	Version: 0.0.1
 	Contact owner if any question, concern or feedback
 ]=]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Rodux = require(ReplicatedStorage.Packages.rodux)

local OfflineFarmActions = {
	setStatsEarned = Rodux.makeActionCreator("setStatsEarned", function(value)
		return {
			value = value,
		}
	end),
}

return OfflineFarmActions
