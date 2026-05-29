--[=[
	Owner: Shakthi
	Version: v0.0.1
	Purpose:
	- Roact notification for occupied / training feedback
	- no dependency on manual BusyPopup hierarchy
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Knit Services
local TrainingService

-- Knit Controllers
local NotificationController

local TrainingNotificationController = Knit.CreateController({
	Name = "TrainingNotificationController",
})

--|| Knit Lifecycle ||--
function TrainingNotificationController:KnitInit()
	TrainingService = Knit.GetService("TrainingService")

	NotificationController = Knit.GetController("NotificationController")
end

function TrainingNotificationController:KnitStart()
	TrainingService.TrainingFeedback:Connect(function(code: string, message: string)
		if code == "Occupied" then
			NotificationController:Notify({
				tag = "Training",
				text = message or "Player is using the equipment.",
				type = "ERROR",
			})
		elseif code == "AlreadyTraining" then
			NotificationController:Notify({
				tag = "Training",
				text = message or "You are already training.",
				type = "ERROR",
			})
		elseif code == "InvalidCharacter" then
			NotificationController:Notify({
				tag = "Training",
				text = message or "Character is not ready.",
				type = "ERROR",
			})
		elseif code == "NoAvailableSlot" then
			NotificationController:Notify({
				tag = "Training",
				text = message or "All training slots are currently full.",
				type = "ERROR",
			})
		else
			NotificationController:Notify({
				tag = "Training",
				text = message or "Training unavailable.",
				type = "ERROR",
			})
		end
	end)
end

return TrainingNotificationController
