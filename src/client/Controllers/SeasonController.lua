--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local SeasonService = nil

-- Controllers
local NotificationController = nil
local DataCacheController = nil

-- SeasonController
local SeasonController = Knit.CreateController({
	Name = "SeasonController",
	Template = {},
})

--|| Functions ||--
function SeasonController:ClaimQuest(id: string)
	local promise, res = SeasonService:ClaimQuest(id):await()
	if promise == false then
		return warn("[SEASON CONTROLLER] An internal occured while claiming quest.")
	end

	NotificationController:Notify(res)
end

function SeasonController:ClaimReward(id: number)
	local promise, res = SeasonService:ClaimReward(id):await()
	if promise == false then
		return warn("[SEASON CONTROLLER] An internal occured while claiming reward.")
	end
	NotificationController:Notify(res)
end

function SeasonController:PremiumClaimReward(id: number)
	local promise, res = SeasonService:PremiumClaimReward(id):await()
	if promise == false then
		return warn("[SEASON CONTROLLER] An internal occured while claiming premium reward.")
	end
	NotificationController:Notify(res)
end

--|| Knit Lifecycle ||--
function SeasonController:KnitInit()
	NotificationController = Knit.GetController("NotificationController")
	DataCacheController = Knit.GetController("DataCacheController")
	SeasonService = Knit.GetService("SeasonService")

	self.Template = DataCacheController:GetFile("Template")
	print("[SEASON CONTROLLER] Controller loaded successfully.")
end

return SeasonController
