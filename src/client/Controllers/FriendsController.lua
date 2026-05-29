-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local SocialService = game:GetService("SocialService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local FriendsActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.FriendsActions)

local FriendsService

local NotificationController

-- FriendsController
local FriendsController = Knit.CreateController({
	Name = "FriendsController",
})

--|| Local Functions ||--

--|| Functions ||--
function FriendsController:BuyReward(rewardId)
	local _, result = FriendsService:BuyReward(rewardId):await()

	if result then
		NotificationController:Notify({
			text = result.text,
			type = result.type,
		})
	end
end

function FriendsController:SetFriendList()
	local friendPages = Players:GetFriendsAsync(player.UserId)
	local friends = {}

	while friendPages do
		for _, item in pairs(friendPages:GetCurrentPage()) do
			item["AvatarUrl"] =
				Players:GetUserThumbnailAsync(item.Id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			table.insert(friends, item)
		end
		if friendPages.IsFinished then
			break
		end
		friendPages:AdvanceToNextPageAsync()
	end

	Store:dispatch(FriendsActions.setFriends(friends))

	-- Set online friends
	local onlineFriends = player:GetFriendsOnline()

	if not onlineFriends then
		onlineFriends = {}
	end

	Store:dispatch(FriendsActions.setOnlineFriends(onlineFriends))
end

function FriendsController:InviteFriend(friendId)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(Players.LocalPlayer)
	end)

	if success and canSend then
		local inviteOptions = Instance.new("ExperienceInviteOptions")
		inviteOptions.InviteUser = friendId

		local success, errorMessage = pcall(function()
			SocialService:PromptGameInvite(Players.LocalPlayer, inviteOptions)
		end)

		if not success then
			NotificationController:Notify({
				text = "Failed to send invite: " .. errorMessage,
				type = "ERROR",
			})
		end
	else
		NotificationController:Notify({
			text = "You cannot send game invites at this time.",
			type = "ERROR",
		})
	end
end

function FriendsController:KnitStart()
	FriendsService = Knit.GetService("FriendsService")

	NotificationController = Knit.GetController("NotificationController")

	self:SetFriendList()

	FriendsService.RewardGiven:Connect(function(invitesTable)
		NotificationController:Notify({
			text = "You have been rewarded for inviting a friend!",
			type = "SUCCESS",
		})
	end)
end

return FriendsController
