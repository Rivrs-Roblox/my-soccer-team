--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Controllers
local SettingsController = Knit.GetController("SettingsController")
local SoundController = Knit.GetController("SoundController")
local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Frames
local Frames = script.Parent.Frames
local VolumeSlider = require(Frames.Slider)
local Item = require(Frames.Item)

local UI = DataCacheController:GetFile("Images")

function Settings(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	local SettingsReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.SettingsReducer
	end)

	local isOpen = UIReducer.CurrentUI == FramesConstants.Settings

	local SettingsItems = {}

	SettingsItems["UI_Volume"] = Item({
		Name = "UI",
		Icon = UI.Ui,
		Value = SettingsReducer.UI_Volume > 0,
		Action = function()
			SoundController:ToggleGlobalVolume("UI")
		end,
		hooks = hooks,
		Order = 3,
	})

	SettingsItems["Music_Volume"] = Item({
		Name = "Music",
		Icon = UI.Music,
		Value = SettingsReducer.Music_Volume > 0,
		Action = function()
			SoundController:ToggleGlobalVolume("MUSIC")
		end,
		hooks = hooks,
		Order = 1,
	})

	SettingsItems["Effects_Volume"] = Item({
		Name = "Sound Effects",
		Icon = UI.Sfx,
		Value = SettingsReducer.MISC_Volume > 0,
		Action = function()
			SoundController:ToggleGlobalVolume("MISC")
		end,
		hooks = hooks,
		Order = 2,
	})

	SettingsItems["Trade"] = Item({
		Name = "Trade",
		Icon = UI.TradeSettings,
		Value = SettingsReducer.Trade,
		Action = function()
			SettingsController:Toggle("Trade")
		end,
		hooks = hooks,
		Order = 4,
	})

	return Roact.createElement("Frame", {
		Visible = isOpen,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromHex("000000"),
		ZIndex = 2,
	}, {
		Popup = Blue_Background({
			title = "Settings",
			titleIcon = UI.Settings,
			size = UDim2.fromScale(0.6, 0.6),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
		}, {
			Center = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.564),
				Size = UDim2.fromScale(0.9, 0.803),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					Padding = UDim.new(0.03, 0),
				}),

				Roact.createFragment(SettingsItems),
			}),
		}),
	})
end

Settings = RoactHooks.new(Roact)(Settings)
return Settings
