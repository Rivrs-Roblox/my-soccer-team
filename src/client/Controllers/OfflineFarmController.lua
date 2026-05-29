-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local GuiService = game:GetService("GuiService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player

-- Services
local OfflineFarmService
local DataService

-- Controllers
local UIController

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local OfflineFarmActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.OfflineFarmActions)

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- OfflineFarmController
local OfflineFarmController = Knit.CreateController({
	Name = "OfflineFarmController",
})

--|| Functions ||--

function OfflineFarmController:GetStatsEarned()
	OfflineFarmService:GetStatsEarned()
end

-- Knit Lifecycle
function OfflineFarmController:KnitStart()
	OfflineFarmService = Knit.GetService("OfflineFarmService")
	DataService = Knit.GetService("DataService")

	UIController = Knit.GetController("UIController")

	OfflineFarmService:CheckStatsEarned():andThen(function(statsEarned)
		if statsEarned > 0 then
			Store:dispatch(OfflineFarmActions.setStatsEarned(statsEarned))
			UIController:ShowFrame({ frame = FramesConstants.OfflineFarm })
		end
	end)

	local currentData = nil
	DataService:GetData():andThen(function(data)
		currentData = data
	end)

	GuiService.MenuOpened:Connect(function()
		if not currentData or not currentData.ExitGiftClaimed then
			return
		end

		UIController:ShowFrame({ frame = FramesConstants.OfflineNotification })
	end)
end

return OfflineFarmController
