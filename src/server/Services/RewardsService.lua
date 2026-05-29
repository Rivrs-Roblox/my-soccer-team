--[=[
	Owner: JustStop__
	Version: v.0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Service
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local SetInterval = require(Helpers.SetInterval)
local DeepCopy = require(Helpers.Table.DeepCopy)

-- Services
local DataService = nil
local DataCacheService = nil
local PlayerStatsService = nil
local SoccerCharactersService = nil
local BoostService = nil

-- RewardsService
local RewardsService = Knit.CreateService({
	Name = "RewardsService",

	Template = {},

	Rewards = {},
	Timers = {},

	TimersThreads = {},

	Client = {
		RewardsUpdated = Knit.CreateSignal(),
		TimerSet = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function RewardsService.Client:ClaimReward(player: Player, id: number)
	return self.Server:ClaimReward(player, id)
end

function RewardsService.Client:ResetGifts(player: Player)
	return self.Server:ResetGifts(player)
end

function RewardsService.Client:GetRewards(player: Player)
	return self.Server:GetRewards(player)
end

function RewardsService.Client:GetTimer(player: Player)
	return self.Server:GetTimer(player)
end

--|| Functions ||--
function RewardsService:ClaimReward(player: Player, id: number, bypassTimer: boolean?)
	local Reward = self.Rewards[player][id]
	if Reward == nil then
		return { text = self.Template.Messages.Notifications.Reward_Not_Exists(id), type = "ERROR" }
	end

	local data = DataService:GetData(player)
	if data == nil then
		return warn("[REWARDS SERVICE] Player has no data: " .. player.Name)
	end

	if Reward.Claimed == true then
		return { text = self.Template.Messages.Notifications.Reward_Already_Claimed, type = "ERROR" }
	end
	if self.Timers[player] < Reward.Time and not bypassTimer then
		return { text = self.Template.Messages.Notifications.Reward_Not_Ready, type = "ERROR" }
	end

	if Reward.Reward == "Characters" then
		local currentCount = 0
		for _ in pairs(data.Inventory.SoccerCharacters or {}) do
			currentCount += 1
		end
		if currentCount + (Reward.Amount or 1) > data.Inventory.Storage.Stored then
			return {
				text = self.Template.Messages.Notifications.Not_Enough_Storage_Space or "Not enough storage space.",
				type = "ERROR",
			}
		end
	end

	self.Rewards[player][id].Claimed = true
	if Reward.Reward == "Currency" and table.find({ "Money1", "Money2", "Wins", "Rebirth" }, Reward.Currency) then
		DataService:ChangeValue(
			player,
			Reward.Currency,
			Reward.Areas[data.Areas.Unlocked[table.maxn(data.Areas.Unlocked)]][2],
			true
		)
	elseif Reward.Reward == "Stats" then
		local statValue = Reward.Areas[data.Areas.Unlocked[table.maxn(data.Areas.Unlocked)]][2]
		PlayerStatsService:SetStat(player, Reward.Stat, data.Stats[Reward.Stat] + statValue)
	elseif Reward.Reward == "Characters" then
		local characterName = Reward.Areas[data.Areas.Unlocked[table.maxn(data.Areas.Unlocked)]][2]
		for i = 1, Reward.Amount or 1 do
			SoccerCharactersService:AddCharacter(player, characterName)
		end
	elseif Reward.Reward == "Boost" then
		local boostId = Reward.Areas[data.Areas.Unlocked[table.maxn(data.Areas.Unlocked)]][2]
		BoostService:AddBoost(player, boostId, Reward.Amount or 1)
	end

	self.Client.RewardsUpdated:Fire(player, { rewards = self.Rewards[player] })

	return { text = self.Template.Messages.Notifications.Reward_Claimed_Success, type = "SUCCESS" }
end

function RewardsService:ResetGifts(player: Player)
	self.Timers[player] = 0

	local newRewards = DeepCopy(self.Template.Rewards)
	self.Rewards[player] = newRewards

	self.Client.RewardsUpdated:Fire(player, { rewards = self.Rewards[player] })

	return { text = self.Template.Messages.Notifications.Reward_Reseted, type = "SUCCESS" }
end

function RewardsService:UpdateTimer(player: Player)
	self.TimersThreads[player] = SetInterval(function()
		if self.Timers[player] == nil then
			self.Timers[player] = 0
		end
		self.Timers[player] += 1
	end, 1)
end

function RewardsService:GetRewards(player: Player)
	return self.Rewards[player]
end

function RewardsService:GetTimer(player: Player)
	return self.Timers[player]
end

function RewardsService:SetTimer(player: Player, value: number)
	self.Timers[player] = value
end

--|| Knit Lifecycle ||--
function RewardsService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	PlayerStatsService = Knit.GetService("PlayerStatsService")
	SoccerCharactersService = Knit.GetService("SoccerCharactersService")
	BoostService = Knit.GetService("BoostService")

	self.Template = DataCacheService:GetFile("Template")

	local function _playerAdded(player: Player)
		local joinData = player:GetJoinData()

		self.Rewards[player] = DeepCopy(self.Template.Rewards)
		self:UpdateTimer(player)

		if joinData and joinData.TeleportData then
			self:SetTimer(player, joinData.TeleportData.timers[tostring(player.UserId)])
			self.Client.TimerSet:Fire(player, self.Timers[player])

			self.Rewards[player] = joinData.TeleportData.rewards[tostring(player.UserId)]
		end

		self.Client.RewardsUpdated:Fire(player, { rewards = self.Rewards[player] })
	end

	for _, player in ipairs(Players:GetPlayers()) do
		_playerAdded(player)
	end

	Players.PlayerAdded:Connect(_playerAdded)

	Players.PlayerRemoving:Connect(function(player: Player)
		task.cancel(self.TimersThreads[player])

		self.TimersThreads[player] = nil
		self.Rewards[player] = nil
		self.Timers[player] = nil
	end)

	print("[REWARDS SERVICE] Service started successfully.")
end

return RewardsService
