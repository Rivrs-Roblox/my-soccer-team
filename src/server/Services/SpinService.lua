--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local RandomTable = require(Helpers.Table.Random)

-- Services
local DataCacheService = nil
local DataService = nil

-- Contants
local RewardDegrees = {
	Free = 72,
	Premium = 45,
}

local Signals = {
	Free = "FreeSpinsUpdated",
	Premium = "PremiumSpinsUpdated",
}

-- SpinService
local SpinService = Knit.CreateService({
	Name = "SpinService",

	Template = {},
	Spining = {
		Free = {},
		Premium = {},
	},

	tasks = {},

	Client = {
		FreeSpinsUpdated = Knit.CreateSignal(),
		PremiumSpinsUpdated = Knit.CreateSignal(),
		LastFreeSpinUpdated = Knit.CreateSignal(),
		FreeSpin = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function SpinService.Client:Spin(player: Player, wheel: string)
	return self.Server:Spin(player, wheel)
end

--|| Functions ||--
function SpinService:Spin(player: Player, wheel: string)
	if self.Spining[wheel][player] then
		return { text = self.Template.Messages.Notifications.Already_Spining, type = "ERROR" }
	end

	local data = DataService:GetData(player)
	if data == nil then
		return warn("[SPIN SERVICE] Player has no data: " .. player.Name)
	end

	if data.Spins[wheel] <= 0 then
		return { text = self.Template.Messages.Notifications.No_More_Spins(wheel), type = "ERROR" }
	end

	data.Spins[wheel] -= 1
	self.Client[Signals[wheel]]:Fire(player, data.Spins[wheel])

	self.Spining[wheel][player] = true
	local Rewards = self.Template.Spins[wheel]

	local rewardIndex = RandomTable(Rewards)
	local exactAngle = (rewardIndex - 1) * RewardDegrees[wheel]
	local offset = Random.new():NextInteger(-(RewardDegrees[wheel] / 2) + 1, (RewardDegrees[wheel] / 2) - 1)
	local targetRotation = (360 - exactAngle) + offset

	task.delay(5, function()
		self.Spining[wheel][player] = nil

		local Reward = Rewards[rewardIndex]

		if Reward.Reward == "Boost" then
			local BoostService = Knit.GetService("BoostService")
			local data = DataService:GetData(player)
			local boostId = Reward.Boost
			if data and data.Inventory and data.Inventory.Boosts then
				for id, boostData in pairs(data.Inventory.Boosts) do
					if boostData.Name == Reward.Boost then
						boostId = id
						break
					end
				end
			end
			BoostService:AddBoost(player, boostId, Reward.Amount)
		elseif Reward.Reward == "Gacha" then
			local GachaService = Knit.GetService("GachaService")
			GachaService:OpenGacha(player, Reward.Category, Reward.Type, Reward.Amount)
		elseif Reward.Reward == "Premium_Spin" then
			data.Spins["Premium"] += Reward.Amount
			self.Client.PremiumSpinsUpdated:Fire(player, data.Spins.Premium)
		else
			DataService:ChangeValue(player, Reward.Reward, Reward.Amount, true)
		end
	end)

	return targetRotation,
		{
			text = self.Template.Messages.Notifications.Wheel_Won(
				Rewards[rewardIndex].Name
					:gsub("MONEY_1", self.Template.Economy.Money1)
					:gsub("MONEY_2", self.Template.Economy.Money2)
			),
			type = "SUCCESS",
		}
end

function SpinService:FreeSpin(player: Player)
	if self.tasks[player] then
		return
	end

	self.tasks[player] = task.spawn(function()
		local data = DataService:GetData(player)
		if data == nil then
			return warn("[SPIN SERVICE] Player has no data: " .. player.Name)
		end
		self.Client.LastFreeSpinUpdated:Fire(player, os.time())

		while task.wait(60 * 15) do
			data.Spins.Free += 1

			self.Client.FreeSpin:Fire(player)
			self.Client.FreeSpinsUpdated:Fire(player, data.Spins.Free)
			self.Client.LastFreeSpinUpdated:Fire(player, os.time())
		end
	end)
end

--|| Knit Lifecycle ||--
function SpinService:KnitInit()
	DataCacheService = Knit.GetService("DataCacheService")
	DataService = Knit.GetService("DataService")

	self.Template = DataCacheService:GetFile("Template")

	for _, player in Players:GetPlayers() do
		self:FreeSpin(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:FreeSpin(player)
	end)

	print("[SPIN SERVICE] Service loaded successfully.")
end

return SpinService
