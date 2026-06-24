--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback

	Used to initialiaze all the used data in DataTemplate of DataService. 
	Also initialiaze different data connection between reducer and DataChanged signal in various services. 
]=]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local Sound = require(ReplicatedStorage.Packages.Sound)
local player = Players.LocalPlayer

-- Actions
local Actions = StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions
local PlayerActions = require(Actions.PlayerActions)
local AreaActions = require(Actions.AreaActions)
local FriendsActions = require(Actions.FriendsActions)
local InventoryActions = require(Actions.InventoryActions)
local SettingsActions = require(Actions.SettingsActions)
local RewardsActions = require(Actions.RewardsActions)
local DailyRewardsActions = require(Actions.DailyRewardsActions)
local StarterPacksActions = require(Actions.StarterPacksActions)
local UIActions = require(Actions.UIActions)
local SeasonActions = require(Actions.SeasonActions)
local BoostsActions = require(Actions.BoostsActions)
local UpdateActions = require(Actions.UpdateActions)
local NotificationActions = require(Actions.NotificationActions)
local SpinsActions = require(Actions.SpinsActions)
local MonetizationActions = require(Actions.MonetizationActions)
local ChestsActions = require(Actions.ChestsActions)
local TeamActions = require(Actions.TeamActions)
local TradeActions = require(Actions.TradeActions)
local CoachActions = require(Actions.CoachActions)
local RejoinActions = require(Actions.RejoinActions)

local Data = {}

function Data:Init()
	local CodesService = Knit.GetService("CodesService")
	local SettingsService = Knit.GetService("SettingsService")
	local RewardsService = Knit.GetService("RewardsService")
	local DailyRewardsService = Knit.GetService("DailyRewardsService")
	local SpinService = Knit.GetService("SpinService")
	local SeasonService = Knit.GetService("SeasonService")
	local BoostService = Knit.GetService("BoostService")
	local MonetizationService = Knit.GetService("MonetizationService")
	local ChestService = Knit.GetService("ChestService")
	local SoftShutdownService = Knit.GetService("SoftShutdownService")
	local DataService = Knit.GetService("DataService")
	local FriendsService = Knit.GetService("FriendsService")
	local TeamService = Knit.GetService("TeamService")
	local SoccerCharactersService = Knit.GetService("SoccerCharactersService")
	local TradeService = Knit.GetService("TradeService")
	local AccessoryService = Knit.GetService("AccessoryService")
	local CoachesService = Knit.GetService("CoachesService")
	local PlayerStatsService = Knit.GetService("PlayerStatsService")
	local RejoinService = Knit.GetService("RejoinService")

	local DataCacheController = Knit.GetController("DataCacheController")
	local UIController = Knit.GetController("UIController")

	DataService:GetData():andThen(function(data)
		Store:dispatch(PlayerActions.addMoney1(data.Money1))
		Store:dispatch(PlayerActions.addMoney2(data.Money2))
		Store:dispatch(PlayerActions.addWins(data.Wins))
		Store:dispatch(PlayerActions.addRebirth(data.Rebirth))
		Store:dispatch(PlayerActions.setShoot(data.Stats.Shoot))
		Store:dispatch(PlayerActions.setPass(data.Stats.Pass))
		Store:dispatch(PlayerActions.setDribble(data.Stats.Dribble))
		Store:dispatch(PlayerActions.setStamina(data.Stats.Stamina))

		Store:dispatch(SpinsActions.setSpins("Free", data.Spins.Free))
		Store:dispatch(SpinsActions.setSpins("Premium", data.Spins.Premium))

		Store:dispatch(MonetizationActions.setGamepasses(data.Gamepasses))

		Store:dispatch(ChestsActions.setChests(data.Chests))
		Store:dispatch(ChestsActions.setVerified(data.Codes.Verified))

		Store:dispatch(AreaActions.setAreas(data.Areas.Unlocked))
		Store:dispatch(AreaActions.setArea(DataCacheController:GetFile("Template").Config.First_Area_Name))

		Store:dispatch(InventoryActions.setMaxStored(data.Inventory.Storage.Stored))

		Store:dispatch(BoostsActions.setBoosts(data.Inventory.Boosts))
		Store:dispatch(BoostsActions.setActiveBoosts(data.Inventory.ActiveBoosts))

		Store:dispatch(FriendsActions.setStars(data.Invites.Stars))
		Store:dispatch(FriendsActions.setInvitedFriends(data.Invites.Invited_Friends))

		Store:dispatch(SettingsActions.setTrade(data.Settings.Trade))

		Store:dispatch(StarterPacksActions.setBoughtStarterPacks(data.BoughtStarterPacks))

		Store:dispatch(DailyRewardsActions.setLastRedeemedTimestamp(data.LastDailyRewarded))
		Store:dispatch(DailyRewardsActions.setLastRedeemedId(data.LastRedeemedId))
		Store:dispatch(DailyRewardsActions.setDailyRewards(data.DailyRewards))

		Store:dispatch(SeasonActions.setSeasonQuests(data.Season.DailyQuests, data.Season.WeeklyQuests))
		Store:dispatch(SeasonActions.setSeason(data.Season.Completed))
		Store:dispatch(SeasonActions.setFreeRewards(DataCacheController:GetFile("Template").Season.Rewards))
		Store:dispatch(
			SeasonActions.setPremiumRewards(DataCacheController:GetFile("Template").Season["Premium Rewards"])
		)
		Store:dispatch(SeasonActions.setClaimedRewards(data.Season.Claimed))
		Store:dispatch(SeasonActions.setClaimedPremiumRewards(data.Season["Premium Claimed"]))
		Store:dispatch(SeasonActions.setLevel(data.Season.Level))
		Store:dispatch(SeasonActions.setExp(data.Season.Exp))
		Store:dispatch(SeasonActions.setPremium(data.Season.Premium))

		Store:dispatch(NotificationActions.setNotification("Store", "NEW!"))

		Store:dispatch(SpinsActions.setLastFreeSpin(os.time()))

		Store:dispatch(TeamActions.setEquippedCharacters(data.Inventory.EquippedSoccerCharacters))
		Store:dispatch(InventoryActions.setSoccerCharacters(data.Inventory.SoccerCharacters))
		Store:dispatch(InventoryActions.setAccessories(data.Inventory.Accessories))

		Store:dispatch(CoachActions.setCoaches(data.Coaches.Unlocked))
		Store:dispatch(CoachActions.setCoach(data.Coaches.Current))

		Store:dispatch(RejoinActions.setFirstConnection(data.FirstConnection))
		Store:dispatch(RejoinActions.setClaimedRejoinReward(data.ClaimedRejoinReward))
	end)

	DataService.Money1Updated:Connect(function(value)
		Store:dispatch(PlayerActions.addMoney1(value))
	end)

	DataService.Money2Updated:Connect(function(value)
		Store:dispatch(PlayerActions.addMoney2(value))
	end)

	DataService.RebirthsUpdated:Connect(function(value)
		Store:dispatch(PlayerActions.addRebirth(value))
	end)

	DataService.WinsUpdated:Connect(function(value)
		Store:dispatch(PlayerActions.addWins(value))
	end)

	DataService.AreasUpdated:Connect(function(value)
		Store:dispatch(AreaActions.setAreas(value))
	end)

	DataService.AreaUpdated:Connect(function(value)
		Store:dispatch(AreaActions.setArea(value))
	end)

	BoostService.BoostsUpdated:Connect(function(boosts: table)
		Store:dispatch(BoostsActions.setBoosts(boosts.boosts))
		Store:dispatch(BoostsActions.setActiveBoosts(boosts.activeBoosts))
	end)

	CodesService.PlayerVerified:Connect(function(state: boolean)
		Store:dispatch(ChestsActions.setVerified(state))
	end)

	SettingsService.SettingsUpdated:Connect(function(settings: table)
		Store:dispatch(SettingsActions.setTrade(settings.Trade))
	end)

	RewardsService.RewardsUpdated:Connect(function(rewards: table)
		Store:dispatch(RewardsActions.setRewards(rewards.rewards))
	end)

	RewardsService.TimerSet:Connect(function(timer: number)
		Store:dispatch(RewardsActions.setTime(timer))
	end)

	MonetizationService.StarterPacksUpdated:Connect(function(packs)
		Store:dispatch(StarterPacksActions.setBoughtStarterPacks(packs))
	end)

	DailyRewardsService.DailyRewardsUpdated:Connect(function(rewards)
		Store:dispatch(DailyRewardsActions.setDailyRewards(rewards.rewards))
		Store:dispatch(DailyRewardsActions.setLastRedeemedTimestamp(rewards.lastRedeemedTimestamp))
		Store:dispatch(DailyRewardsActions.setLastRedeemedId(rewards.lastRedeemedId))
	end)

	SpinService.FreeSpinsUpdated:Connect(function(spins)
		Store:dispatch(SpinsActions.setSpins("Free", spins))
	end)

	SpinService.PremiumSpinsUpdated:Connect(function(spins)
		Store:dispatch(SpinsActions.setSpins("Premium", spins))
	end)

	SpinService.LastFreeSpinUpdated:Connect(function(time)
		Store:dispatch(SpinsActions.setLastFreeSpin(time))
	end)

	SeasonService.QuestsUpdated:Connect(
		function(dailyQuests: table, weeklyQuests: table, dayTimer: number, weekTimer: number)
			Store:dispatch(SeasonActions.setSeasonQuests(dailyQuests, weeklyQuests))

			if dayTimer then
				Store:dispatch(SeasonActions.setRemainingDayTime(dayTimer))
			end
			if weekTimer then
				Store:dispatch(SeasonActions.setRemainingWeekTime(weekTimer))
			end
		end
	)

	SeasonService.ClaimedRewardsUpdate:Connect(function(params: table)
		Store:dispatch(SeasonActions.setClaimedRewards(params.free))
		Store:dispatch(SeasonActions.setClaimedPremiumRewards(params.premium))
	end)

	SeasonService.SeasonUpdated:Connect(function(season: number)
		Store:dispatch(SeasonActions.setSeason(season))
	end)

	SeasonService.RemainingDayTimeUpdated:Connect(function(remainingSeconds: number)
		Store:dispatch(SeasonActions.setRemainingDayTime(remainingSeconds))
	end)

	SeasonService.RemainingWeekTimeUpdated:Connect(function(remainingSeconds: number)
		Store:dispatch(SeasonActions.setRemainingWeekTime(remainingSeconds))
	end)

	SeasonService.LevelUpdated:Connect(function(newLevel: number)
		Store:dispatch(SeasonActions.setLevel(newLevel))
	end)

	SeasonService.ExpUpdated:Connect(function(newExp: number)
		Store:dispatch(SeasonActions.setExp(newExp))
	end)

	SeasonService.PremiumUpdated:Connect(function(premium: boolean)
		Store:dispatch(SeasonActions.setPremium(premium))
	end)

	ChestService.ChestsUpdated:Connect(function(chests)
		Store:dispatch(ChestsActions.setChests(chests.chests))
	end)

	MonetizationService.GamepassesUpdate:Connect(function(passes: table)
		Store:dispatch(MonetizationActions.setGamepasses(passes))
	end)

	SoftShutdownService.Update:Connect(function(updating, timer)
		UIController:RemoveHUD({ ignoreTopFrame = false })

		Store:dispatch(UpdateActions.setUpdating(updating))
		Store:dispatch(UpdateActions.setTimer(timer))
	end)

	--[[TeleportationService.AreaUpdated:Connect(function(area)
		Store:dispatch(AreaActions.setArea(area))
	end)]]

	MonetizationService.UpdateData:Connect(function(data)
		Store:dispatch(SpinsActions.setSpins("Free", data.Spins.Free))
		Store:dispatch(SpinsActions.setSpins("Premium", data.Spins.Premium))

		Store:dispatch(MonetizationActions.setGamepasses(data.Gamepasses))
		Store:dispatch(ChestsActions.setVerified(data.Codes.Verified))

		Store:dispatch(AreaActions.setAreas(data.Areas.Unlocked))
		Store:dispatch(AreaActions.setArea(data.Areas.Current))
		Store:dispatch(InventoryActions.setMaxStored(data.Inventory.Storage.Stored))

		Store:dispatch(BoostsActions.setBoosts(data.Inventory.Boosts))
		Store:dispatch(BoostsActions.setActiveBoosts(data.Inventory.ActiveBoosts))

		Store:dispatch(FriendsActions.setStars(data.Invites.Stars))
		Store:dispatch(FriendsActions.setInvitedFriends(data.Invites.Invited_Friends))

		Store:dispatch(StarterPacksActions.setBoughtStarterPacks(data.BoughtStarterPacks))

		Store:dispatch(DailyRewardsActions.setLastRedeemedTimestamp(data.LastDailyRewarded))
		Store:dispatch(DailyRewardsActions.setLastRedeemedId(data.LastRedeemedId))
		Store:dispatch(DailyRewardsActions.setDailyRewards(data.DailyRewards))

		Store:dispatch(SeasonActions.setSeasonQuests(data.Season.DailyQuests, data.Season.WeeklyQuests))
		Store:dispatch(SeasonActions.setSeason(data.Season.Completed))
		Store:dispatch(SeasonActions.setFreeRewards(DataCacheController:GetFile("Template").Season.Rewards))
		Store:dispatch(
			SeasonActions.setPremiumRewards(DataCacheController:GetFile("Template").Season["Premium Rewards"])
		)
		Store:dispatch(SeasonActions.setClaimedRewards(data.Season.Claimed))
		Store:dispatch(SeasonActions.setClaimedPremiumRewards(data.Season["Premium Claimed"]))
		Store:dispatch(SeasonActions.setLevel(data.Season.Level))
		Store:dispatch(SeasonActions.setExp(data.Season.Exp))
		Store:dispatch(SeasonActions.setPremium(data.Season.Premium))
	end)

	FriendsService.RewardGiven:Connect(function(invitesTable)
		Store:dispatch(FriendsActions.setStars(invitesTable.Stars))
		Store:dispatch(FriendsActions.setInvitedFriends(invitesTable.Invited_Friends))
	end)

	FriendsService.RewardBought:Connect(function(stars)
		Store:dispatch(FriendsActions.setStars(stars))
	end)

	TeamService.TeamSlotSet:Connect(function(p, equippedCharacters)
		if p == player then
			Store:dispatch(TeamActions.setEquippedCharacters(equippedCharacters))
		end
	end)

	SoccerCharactersService.SoccerCharactersUpdated:Connect(function(soccerCharacters)
		Store:dispatch(InventoryActions.setSoccerCharacters(soccerCharacters))
	end)

	AccessoryService.AccessoriesUpdated:Connect(function(accessories)
		Store:dispatch(InventoryActions.setAccessories(accessories))
	end)

	TradeService.RequestSent:Connect(function(receiver: Player)
		Store:dispatch(UIActions.resetCurrentUI())
		Store:dispatch(TradeActions.setOutgoingRequest(receiver))
	end)

	TradeService.RequestReceived:Connect(function(sender: Player)
		Store:dispatch(UIActions.resetCurrentUI())
		Store:dispatch(TradeActions.setIncomingRequest(sender))
		Sound:PlaySound("UI_Trade_Requested")
	end)

	TradeService.RequestDeclined:Connect(function()
		Store:dispatch(TradeActions.setMySoccerCharacters({}))
		Store:dispatch(TradeActions.setHisSoccerCharacters({}))

		Store:dispatch(TradeActions.setIncomingRequest(nil))
		Store:dispatch(TradeActions.setOutgoingRequest(nil))

		Store:dispatch(TradeActions.setReady(false))
		Store:dispatch(TradeActions.setOtherReady(false))

		Store:dispatch(TradeActions.setTrading(false))
	end)

	TradeService.RequestAccepted:Connect(function()
		Store:dispatch(TradeActions.setMySoccerCharacters({}))
		Store:dispatch(TradeActions.setHisSoccerCharacters({}))
		Store:dispatch(TradeActions.setTrading(true))
	end)

	TradeService.TradeCanceled:Connect(function()
		Store:dispatch(TradeActions.setMySoccerCharacters({}))
		Store:dispatch(TradeActions.setHisSoccerCharacters({}))

		Store:dispatch(TradeActions.setIncomingRequest(nil))
		Store:dispatch(TradeActions.setOutgoingRequest(nil))

		Store:dispatch(TradeActions.setReady(false))
		Store:dispatch(TradeActions.setOtherReady(false))

		Store:dispatch(TradeActions.setTrading(false))
	end)

	TradeService.TradeCompleted:Connect(function()
		Store:dispatch(TradeActions.setMySoccerCharacters({}))
		Store:dispatch(TradeActions.setHisSoccerCharacters({}))

		Store:dispatch(TradeActions.setIncomingRequest(nil))
		Store:dispatch(TradeActions.setOutgoingRequest(nil))

		Store:dispatch(TradeActions.setReady(false))
		Store:dispatch(TradeActions.setOtherReady(false))

		Store:dispatch(TradeActions.setTrading(false))
	end)

	TradeService.MySoccerCharactersChanged:Connect(function(soccerCharacters: table)
		Store:dispatch(TradeActions.setMySoccerCharacters(soccerCharacters))
	end)

	TradeService.HisSoccerCharactersChanged:Connect(function(soccerCharacters: table)
		Store:dispatch(TradeActions.setHisSoccerCharacters(soccerCharacters))
	end)

	TradeService.PlayerReady:Connect(function(state: boolean)
		Store:dispatch(TradeActions.setReady(state))
	end)

	TradeService.OtherReady:Connect(function(state: boolean)
		Store:dispatch(TradeActions.setOtherReady(state))
	end)

	TradeService.Timer:Connect(function(time: number)
		Store:dispatch(TradeActions.setTimer(time))
	end)

	CoachesService.CoachesUpdated:Connect(function(coaches: table)
		if coaches.Unlocked ~= nil or coaches.Current ~= nil then
			Store:dispatch(CoachActions.setCoaches(coaches.Unlocked or {}))
			Store:dispatch(CoachActions.setCoach(coaches.Current or 0))
		end
	end)

	PlayerStatsService.StatUpdated:Connect(function(statType: string, statValue: number)
		if statType == "Shoot" then
			Store:dispatch(PlayerActions.setShoot(statValue))
		elseif statType == "Pass" then
			Store:dispatch(PlayerActions.setPass(statValue))
		elseif statType == "Dribble" then
			Store:dispatch(PlayerActions.setDribble(statValue))
		elseif statType == "Stamina" then
			Store:dispatch(PlayerActions.setStamina(statValue))
		end
	end)

	RejoinService.RejoinUpdated:Connect(function(date)
		Store:dispatch(RejoinActions.setFirstConnection(date.FirstConnection))
		Store:dispatch(RejoinActions.setClaimedRejoinReward(date.ClaimedRejoinReward))
	end)

	SeasonService:RequestSync()

	-- Continuous sync
	task.spawn(function()
		while true do
			task.wait(1)

			DataService:GetData(player):andThen(function(playerData)
				Store:dispatch(BoostsActions.setBoosts(playerData.Inventory.Boosts))
				Store:dispatch(BoostsActions.setActiveBoosts(playerData.Inventory.ActiveBoosts))
			end)
		end
	end)
end

return Data
