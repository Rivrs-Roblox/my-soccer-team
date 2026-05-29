local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local RewardsService

local AfkService = Knit.CreateService({
	Name = "AfkService",
	Client = {},
})

--|| Client Functions ||--
function AfkService.Client:RequestRejoin(player: Player, isAutoTraining: boolean, autoTrainType: string?)
	return self.Server:RejoinPlayer(player, isAutoTraining, autoTrainType)
end

--|| Server Functions ||--
function AfkService:RejoinPlayer(player: Player, isAutoTraining: boolean, autoTrainType: string?)
	local timer = RewardsService and RewardsService:GetTimer(player) or 0
	local rewards = RewardsService and RewardsService:GetRewards(player) or {}

	local TeleportOptions = Instance.new("TeleportOptions")
	TeleportOptions:SetTeleportData({
		timers = {
			[tostring(player.UserId)] = timer,
		},
		rewards = {
			[tostring(player.UserId)] = rewards,
		},
		isAutoTraining = isAutoTraining,
		autoTrainType = autoTrainType,
	})

	local success, result = pcall(function()
		return TeleportService:TeleportAsync(game.PlaceId, { player }, TeleportOptions)
	end)

	if not success then
		warn(("[AFK SERVICE] Failed to teleport player %s: %s"):format(player.Name, tostring(result)))
		return false
	end

	return true
end

--| Knit Lifecycle |--
function AfkService:KnitInit()
	RewardsService = Knit.GetService("RewardsService")
end

function AfkService:KnitStart()
	print("[AFK SERVICE] Service loaded successfully.")
end

return AfkService
