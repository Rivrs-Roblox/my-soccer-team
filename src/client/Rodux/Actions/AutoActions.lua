local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.rodux)

local AutoActions = {
	setAutoTraining = Rodux.makeActionCreator("setAutoTraining", function(value)
		return { value = value }
	end),

	setAutoTrainingCurrent = Rodux.makeActionCreator("setAutoTrainingCurrent", function(value)
		return { value = value }
	end),
}

return AutoActions