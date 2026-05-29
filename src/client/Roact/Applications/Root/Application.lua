--[=[
	Owner: JustStop__
	Version: 0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Constants
local Applications = StarterPlayer.StarterPlayerScripts.Client.Roact.Applications
local Contexts = StarterPlayer.StarterPlayerScripts.Client.Roact.Contexts

-- Modules
local Roact = require(ReplicatedStorage.Packages.roact)
local AllowedApplicationsContext = require(Contexts.AllowedApplicationsContext)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local ContextStack = require(Contexts.ContextStack)

local function Root(props, hooks)
	return Roact.createElement(ContextStack, {
		providers = {
			AllowedApplicationsContext.Provider,
		},
	}, Roact.createFragment(props[Roact.Children]))
end
Root = RoactHooks.new(Roact)(Root)

local Frames = {
	Hud = Roact.createElement(require(Applications.HUD.Application)),
	Store = Roact.createElement(require(Applications.Store.Application)),
	Inventory = Roact.createElement(require(Applications.Inventory.Application)),
	Travel = Roact.createElement(require(Applications.Travel.Application)),
	Rebirth = Roact.createElement(require(Applications.Rebirth.Application)),
	Codes = Roact.createElement(require(Applications.Codes.Application)),
	Friends = Roact.createElement(require(Applications.Friends.Application)),
	Settings = Roact.createElement(require(Applications.Settings.Application)),
	Rewards = Roact.createElement(require(Applications.Rewards.Application)),
	DailyRewards = Roact.createElement(require(Applications.DailyRewards.Application)),
	Spins = Roact.createElement(require(Applications.Spins.Application)),
	Season = Roact.createElement(require(Applications.Season.Application)),
	Update = Roact.createElement(require(Applications.Update.Application)),
	StarterPack = Roact.createElement(require(Applications.StarterPack.Application)),
	OfflineFarm = Roact.createElement(require(Applications.OfflineFarm.Application)),
	OfflineNotification = Roact.createElement(require(Applications.OfflineNotification.Application)),
	UpdateLog = Roact.createElement(require(Applications.UpdateLog.Application)),
	ExitGift = Roact.createElement(require(Applications.ExitGift.Application)),
	SelectCharacter = Roact.createElement(require(Applications.SelectCharacter.Application)),
	MergeCharacters = Roact.createElement(require(Applications.MergeCharacters.Application)),
	TradeRequest = Roact.createElement(require(Applications.Trade.Request.Application)),
	TradeList = Roact.createElement(require(Applications.Trade.List.Application)),
	Trade = Roact.createElement(require(Applications.Trade.Trading.Application)),
	Packs = Roact.createElement(require(Applications.Packs.Application)),
	Customize = Roact.createElement(require(Applications.Customize.Application)),
	Rejoin = Roact.createElement(require(Applications.Rejoin.Application)),
}

-- Component
local function StoryFrame()
	return Roact.createElement(Root, {}, Frames)
end

local function GameFrame()
	return Roact.createElement(Root, {}, {
		GameScreenGui = Roact.createElement("ScreenGui", {
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Global,
			ResetOnSpawn = false,
			--VirtualCursorMode = Enum.VirtualCursorMode.Enabled
		}, Frames),
	})
end

return {
	Story = StoryFrame,
	Game = GameFrame,
}
