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
local Template = require(ReplicatedStorage.Shared.Data.Template)

local FriendsService
local NotificationController

-- FriendsController
local FriendsController = Knit.CreateController({
	Name = "FriendsController",
	InviteDebounce = {},
	BuyDebounce = {},
})

--|| Local Functions ||--

--|| Functions ||--
function FriendsController:BuyReward(rewardId)
	local now = os.clock()
	local lastBuy = self.BuyDebounce[rewardId] or 0
	if now - lastBuy < 1.5 then
		return
	end
	self.BuyDebounce[rewardId] = now

	-- Client-side validation for stars
	local state = Store:getState()
	local stars = 0
	if state and state.FriendsReducer then
		stars = state.FriendsReducer.Stars or 0
	end

	local reward = Template.Friends.Rewards[rewardId]
	if not reward then
		self.BuyDebounce[rewardId] = nil
		return
	end

	if stars < reward.Price then
		NotificationController:Notify({
			tag = `StarNotEnough_{rewardId}`,
			text = "Not enough stars!",
			type = "ERROR",
		})
		self.BuyDebounce[rewardId] = nil
		return
	end

	local _, result = FriendsService:BuyReward(rewardId):await()

	if result then
		NotificationController:Notify({
			tag = `StarNotEnough_{rewardId}`,
			text = result.text,
			type = result.type,
		})
	end
	self.BuyDebounce[rewardId] = nil
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
	local now = os.clock()
	local lastInvite = self.InviteDebounce[friendId] or 0
	if now - lastInvite < 3 then
		return
	end
	self.InviteDebounce[friendId] = now

	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(Players.LocalPlayer)
	end)

	if success and canSend then
		local inviteOptions = Instance.new("ExperienceInviteOptions")
		inviteOptions.InviteUser = friendId

		task.wait(1) -- Workaround: beri delay agar invite prompt stabil

		local success, errorMessage = pcall(function()
			SocialService:PromptGameInvite(Players.LocalPlayer, inviteOptions)
		end)

		if not success then
			NotificationController:Notify({
				tag = `InviteError_{friendId}`,
				text = "Failed to send invite: " .. errorMessage,
				type = "ERROR",
			})
		end
	else
		NotificationController:Notify({
			tag = `InviteError_{friendId}`,
			text = "You cannot send game invites at this time.",
			type = "ERROR",
		})
	end
end

function FriendsController:KnitStart()
	FriendsService = Knit.GetService("FriendsService")

	NotificationController = Knit.GetController("NotificationController")

	self:SetFriendList()

	-- Track invite result dari Roblox prompt
	SocialService.GameInvitePromptClosed:Connect(function(player, recipientIds)
		if recipientIds and #recipientIds > 0 then
			NotificationController:Notify({
				text = "Invite sent successfully!",
				type = "SUCCESS",
			})
		end
	end)

	FriendsService.RewardGiven:Connect(function(invitesTable)
		NotificationController:Notify({
			text = "You have been rewarded for inviting a friend!",
			type = "SUCCESS",
		})
	end)
end

return FriendsController
