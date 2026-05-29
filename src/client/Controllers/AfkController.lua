-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local AfkService = nil
local AutoController = nil
local DataCacheController = nil

-- AfkController
local AfkController = Knit.CreateController({
	Name = "AfkController",
	IsTeleporting = false,
})

--|| Knit Lifecycle ||--
function AfkController:KnitInit()
	AfkService = Knit.GetService("AfkService")
	AutoController = Knit.GetController("AutoController")
	DataCacheController = Knit.GetController("DataCacheController")

	self.Config = DataCacheController:GetFile("AfkConfig")
end

function AfkController:KnitStart()
	local localPlayer = Players.LocalPlayer

	localPlayer.Idled:Connect(function(timeIdled)
		if timeIdled >= self.Config.IdleTime and not self.IsTeleporting then
			self.IsTeleporting = true

			local isAutoTraining = false
			local autoTrainType = nil
			if AutoController then
				isAutoTraining = AutoController.IsTraining or false
				autoTrainType = AutoController.CurrentStatType
			end

			AfkService:RequestRejoin(isAutoTraining, autoTrainType)
				:andThen(function(success)
					if success then
						print("[AFK CONTROLLER] Rejoin request approved, teleporting...")
					else
						warn("[AFK CONTROLLER] Server failed to process teleport request.")
						self.IsTeleporting = false -- allow retry
					end
				end)
				:catch(function(err)
					warn("[AFK CONTROLLER] Error requesting teleport:", err)
					self.IsTeleporting = false -- allow retry
				end)
		end
	end)
end

return AfkController
