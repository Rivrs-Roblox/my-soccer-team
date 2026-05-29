--[=[
	Owner: JustStop__
	Version: v.0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Service
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService = nil
local DataCacheService = nil
local SeasonService = nil
local AccessoryService = nil
local SoccerCharactersService = nil

-- DailyRewardsService
local DailyRewardsService = Knit.CreateService({
	Name = "DailyRewardsService",

	Template = {},

	Client = {
		DailyRewardsUpdated = Knit.CreateSignal(),
		UpgradeClaimed = Knit.CreateSignal(),
		CharacterClaimed = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function DailyRewardsService.Client:ClaimReward(player: Player, id: number)
	return self.Server:ClaimReward(player, id)
end

--|| Functions ||--
function DailyRewardsService:ClaimReward(player: Player, id: number, bypassTime: boolean?)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[DAILY REWARD SERVICE] Player has no data: " .. player.Name)
	end

	local Reward = data.DailyRewards[id]
	if Reward == nil then
		return { text = self.Template.Messages.Notifications.Reward_Not_Exists(id), type = "ERROR" }
	end

	if Reward.Claimed == true then
		return { text = self.Template.Messages.Notifications.Reward_Already_Claimed, type = "ERROR" }
	end
	if os.time() - data.LastDailyRewarded < 86400 and (bypassTime == nil or bypassTime == false) then
		return { text = self.Template.Messages.Notifications.Reward_Not_Ready, type = "ERROR" }
	end

	if Reward.Reward == "Accessory" then
		local currentCount = 0
		for _ in pairs(data.Inventory.Accessories or {}) do
			currentCount += 1
		end
		if currentCount + Reward.Amount > data.Inventory.Storage.Stored then
			return { text = self.Template.Messages.Notifications.Not_Enough_Storage_Space, type = "ERROR" }
		end
	elseif Reward.Reward == "Character" then
		local currentCount = 0
		for _ in pairs(data.Inventory.SoccerCharacters or {}) do
			currentCount += 1
		end
		if currentCount + Reward.Amount > data.Inventory.Storage.Stored then
			return { text = self.Template.Messages.Notifications.Not_Enough_Storage_Space, type = "ERROR" }
		end
	end

	if id == 1 then
		pcall(function()
			return HttpService:PostAsync(
				"https://rivrs.juststop.dev/api/users",
				HttpService:JSONEncode({
					["user_id"] = player.UserId,
					["universe_id"] = game.GameId,
				}),
				Enum.HttpContentType.ApplicationJson,
				false,
				{
					["x-api-key"] = "532NZEF3LyVGhSQN8GhebSmpRNHq7xNjHNcUv3v5dLhtTGCBzoCkktIDm0iKeabIDXvAqbx4iUSdt5qwsRWY9H7Ihtt0Z4eHs19foDteaKyRXVyXM7RtF4xh68ampuZm",
				}
			)
		end)
	end

	data.DailyRewards[id].Claimed = true
	data.LastDailyRewarded = os.time()
	data.LastRedeemedId = id

	if Reward.Reward == "Currency" and table.find({ "Money1", "Money2", "Wins", "Rebirth" }, Reward.Currency) then
		DataService:ChangeValue(player, Reward.Currency, Reward.Amount, true)
	elseif Reward.Reward == "Character" then
		for i = 1, Reward.Amount do
			SoccerCharactersService:AddCharacter(player, Reward.Character)
		end
		self.Client.CharacterClaimed:Fire(player, Reward.Character, Reward.Amount)
	elseif Reward.Reward == "Accessory" then
		for i = 1, Reward.Amount do
			AccessoryService:AddAccessory(player, Reward.Accessory)
		end
	end

	SeasonService:Increase(player, "Daily Rewards", 1)

	self.Client.DailyRewardsUpdated:Fire(player, {
		lastRedeemedTimestamp = data.LastDailyRewarded,
		rewards = data.DailyRewards,
		lastRedeemedId = data.LastRedeemedId,
	})

	return { text = self.Template.Messages.Notifications.Reward_Claimed_Success, type = "SUCCESS" }
end

--|| Knit Lifecycle ||--
function DailyRewardsService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	SeasonService = Knit.GetService("SeasonService")
	AccessoryService = Knit.GetService("AccessoryService")
	SoccerCharactersService = Knit.GetService("SoccerCharactersService")

	self.Template = DataCacheService:GetFile("Template")

	print("[DAILY REWARDS SERVICE] Service started successfully.")
end

return DailyRewardsService
