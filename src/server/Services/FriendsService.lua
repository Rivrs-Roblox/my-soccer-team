-- Knit Packages
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ProfileService = require(game.ServerScriptService.Server.Modules.ProfileService)

local profileTemplate = require(game.ReplicatedStorage.Shared.Data.Player)

-- Ambil store yang sama dengan di DataService
local profileStore = ProfileService.GetProfileStore("1", profileTemplate)

-- Services
local Players = game:GetService("Players")
local DataService
local DataCacheService

local FriendsService = Knit.CreateService({
	Name = "FriendsService",
	Template = {},
	Client = {
		RewardGiven = Knit.CreateSignal(),
		RewardBought = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function FriendsService.Client:BuyReward(player, rewardId)
	return self.Server:BuyReward(player, rewardId)
end

-- || Server Functions ||--
function FriendsService:BuyReward(player, rewardId)
	local data = DataService:GetData(player)
	if not data then
		return warn("[FRIENDS SERVICE] Player has no data: " .. player.Name)
	end

	local reward = self.Template.Friends.Rewards[rewardId]

	if not reward then
		return { text = "Reward does not exist", type = "ERROR" }
	end

	if data.Invites.Stars < reward.Price then
		return { text = "Not enough stars!", type = "ERROR" }
	end

	if table.find({ "Wins", "Money2" }, reward.RewardType) then
		DataService:ChangeValue(player, reward.RewardType, reward.Reward, true)
	end

	data.Invites.Stars -= reward.Price
	self.Client.RewardBought:Fire(player, data.Invites.Stars)

	return { text = "Reward purchased successfully!", type = "SUCCESS" }
end

function FriendsService:GiveRewards(rewardedPlayerId, invitedPlayer)
	local rewardedPlayer = Players:GetPlayerByUserId(rewardedPlayerId)
	if rewardedPlayer then -- Jika pemain yang diberi reward masih ada/online
		local data = DataService:GetData(rewardedPlayer)
		if not data then
			return warn("[FRIENDS SERVICE] Player has no data: " .. rewardedPlayer.Name)
		end

		-- Check if the invited player is already in the list
		if table.find(data.Invites.Invited_Friends, invitedPlayer.UserId) then
			return warn(
				"[FRIENDS SERVICE] Player has already been rewarded for inviting this friend: " .. invitedPlayer.Name
			)
		end

		data.Invites.Stars += 1
		table.insert(data.Invites.Invited_Friends, invitedPlayer.UserId)

		self.Client.RewardGiven:Fire(rewardedPlayer, data.Invites)
	else
		local profile = profileStore:LoadProfileAsync("FinalData_1" .. rewardedPlayerId, "ForceLoad")

		if not profile then
			return warn("[FRIENDS SERVICE] Player has no data: " .. rewardedPlayerId)
		end

		local data = profile.Data

		-- Check if the invited player is already in the list
		if table.find(data.Invites.Invited_Friends, invitedPlayer.UserId) then
			return warn(
				"[FRIENDS SERVICE] Player has already been rewarded for inviting this friend: " .. invitedPlayer.Name
			)
		end

		data.Invites.Stars += 1
		table.insert(data.Invites.Invited_Friends, invitedPlayer.UserId)

		profile:Release()
	end
end

-- KNIT START
function FriendsService:KnitStart()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")

	Players.PlayerAdded:Connect(function(player)
		local joinData = player:GetJoinData()

		if joinData.ReferredByPlayerId then
			self:GiveRewards(joinData.ReferredByPlayerId, player)
		end
	end)
end

return FriendsService
