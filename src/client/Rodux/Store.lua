--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.rodux)

-- Variables
local Reducers = StarterPlayer.StarterPlayerScripts.Client.Rodux.Reducers

-- Reducers
local PlayerReducer = require(Reducers.PlayerReducer)
local UIReducer = require(Reducers.UIReducer)
local AreaReducer = require(Reducers.AreaReducer)
local InventoryReducer = require(Reducers.InventoryReducer)
local FriendsReducer = require(Reducers.FriendsReducer)
local SettingsReducer = require(Reducers.SettingsReducer)
local RewardsReducer = require(Reducers.RewardsReducer)
local DailyRewardsReducer = require(Reducers.DailyRewardsReducer)
local StarterPacksReducer = require(Reducers.StarterPacksReducer)
local SeasonReducer = require(Reducers.SeasonReducer)
local BoostsReducer = require(Reducers.BoostsReducer)
local UpdateReducer = require(Reducers.UpdateReducer)
local NotificationReducer = require(Reducers.NotificationReducer)
local TutorialReducer = require(Reducers.TutorialReducer)
local SpinsReducer = require(Reducers.SpinsReducer)
local MonetizationReducer = require(Reducers.MonetizationReducer)
local ChestsReducer = require(Reducers.ChestsReducer)
local AutoReducer = require(Reducers.AutoReducer)
local OfflineFarmReducer = require(Reducers.OfflineFarmReducer)
local TeamReducer = require(Reducers.TeamReducer)
local TradeReducer = require(Reducers.TradeReducer)
local CoachReducer = require(Reducers.CoachReducer)
local AccessoryReducer = require(Reducers.AccessoryReducer)
local RejoinReducer = require(Reducers.RejoinReducer)

-- Store
local StoreReducer = Rodux.combineReducers({
	PlayerReducer = PlayerReducer,
	UIReducer = UIReducer,
	AreaReducer = AreaReducer,
	InventoryReducer = InventoryReducer,
	FriendsReducer = FriendsReducer,
	SettingsReducer = SettingsReducer,
	RewardsReducer = RewardsReducer,
	DailyRewardsReducer = DailyRewardsReducer,
	StarterPacksReducer = StarterPacksReducer,
	SeasonReducer = SeasonReducer,
	BoostsReducer = BoostsReducer,
	UpdateReducer = UpdateReducer,
	NotificationReducer = NotificationReducer,
	TutorialReducer = TutorialReducer,
	SpinsReducer = SpinsReducer,
	MonetizationReducer = MonetizationReducer,
	ChestsReducer = ChestsReducer,
	AutoReducer = AutoReducer,
	OfflineFarmReducer = OfflineFarmReducer,
	TeamReducer = TeamReducer,
	TradeReducer = TradeReducer,
	CoachReducer = CoachReducer,
	AccessoryReducer = AccessoryReducer,
	RejoinReducer = RejoinReducer,
})

local Store = Rodux.Store.new(StoreReducer, nil, {})

return Store
