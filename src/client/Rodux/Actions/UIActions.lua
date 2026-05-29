--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

local UIActions = {
	setCurrentUI = Rodux.makeActionCreator("setCurrentUI", function(value)
		return { value = value }
	end),

	resetCurrentUI = Rodux.makeActionCreator("resetCurrentUI", function(value)
		return { value = value }
	end),

	setCurrentStoreSectionUI = Rodux.makeActionCreator("setCurrentStoreSectionUI", function(value)
		return { value = value }
	end),

	resetCurrentStoreSectionUI = Rodux.makeActionCreator("resetCurrentStoreSectionUI", function(value)
		return { value = value }
	end),

	setCurrentSeasonPassUI = Rodux.makeActionCreator("setCurrentSeasonPassUI", function(value)
		return { value = value }
	end),

	resetCurrentSeasonPassUI = Rodux.makeActionCreator("resetCurrentSeasonPassUI", function(value)
		return { value = value }
	end),

	setCurrentPacksUI = Rodux.makeActionCreator("setCurrentPacksUI", function(value)
		return { value = value }
	end),

	resetCurrentPacksUI = Rodux.makeActionCreator("resetCurrentPacksUI", function(value)
		return { value = value }
	end),

	setCurrentCustomizeUI = Rodux.makeActionCreator("setCurrentCustomizeUI", function(value)
		return { value = value }
	end),

	resetCurrentCustomizeUI = Rodux.makeActionCreator("resetCurrentCustomizeUI", function(value)
		return { value = value }
	end),

	setCurrentAccessoriesUI = Rodux.makeActionCreator("setCurrentAccessoriesUI", function(value)
		return { value = value }
	end),

	resetCurrentAccessoriesUI = Rodux.makeActionCreator("resetCurrentAccessoriesUI", function(value)
		return { value = value }
	end),
}

return UIActions
