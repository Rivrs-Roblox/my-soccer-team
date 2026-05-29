--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

-- Controllers
local UIController = Knit.GetController("UIController")

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local White_Background = require(Components.Main.White_Background)
local ColorableButton = require(Components.Buttons.ColorableButton)
local CloseButton = require(Components.CloseButton)

-- Constants
local FramesConstants = require(StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local SeasonConstants = require(StarterPlayerScripts.Client.Roact.Constants.SeasonConstants)

-- Store
local Store = require(StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayerScripts.Client.Rodux.Actions.UIActions)

-- Panels
local Panels = script.Parent.Panels
local Quests = require(Panels.Quests.Application)
local Rewards = require(Panels.Rewards.Application)
local PremiumRewards = require(Panels.PremiumRewards.Application)
local Top = require(Panels.Top.Application)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")

-- UI
local UI = DataCacheController:GetFile("Images")

-- Contstants
local Colors = {
	Quests = Color3.fromRGB(172, 215, 255),
	Rewards = Color3.fromRGB(197, 252, 179),
	PremiumRewards = Color3.fromRGB(249, 234, 185),
}

-- Season
function Season(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.53),
		BorderColor3 = Color3.fromHex("000000"),
		BackgroundColor3 = Color3.fromHex("585858"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.6, 0.6),
		Visible = UIReducer.CurrentUI == FramesConstants.Season,
	}, {
		Content = Roact.createElement("ImageLabel", {
			ImageColor3 = Color3.fromHex("d967ff"),
			Image = "rbxassetid://16877397722",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			-- Egg = Roact.createElement(require(FramesFolder.Egg)),
			Ticket = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://83800486022690",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.004, 0.015),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.2, 0.4),
			}),
			Close = CloseButton(function()
				UIController:HideFrame()
			end, hooks, { pos = UDim2.fromScale(0.931, -0.041) }),
			TitleShadow = Roact.createElement("TextLabel", {
				TextWrapped = true,
				AutoLocalize = false,
				TextColor3 = Color3.fromHex("191919"),
				Text = "Battle Pass!",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Font = 26,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.25, -0.006),
				Rotation = -3,
				ZIndex = 100,
				TextSize = 14,
				Size = UDim2.fromScale(0.5, 0.13),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 2.487,
				}),
			}),
			Top = Roact.createElement(Top),
			TextTitle = Roact.createElement("TextLabel", {
				TextWrapped = true,
				AutoLocalize = false,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Battle Pass!",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Font = 26,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.25, -0.011),
				Rotation = -3,
				ZIndex = 101,
				TextSize = 14,
				Size = UDim2.fromScale(0.5, 0.13),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 2.487,
				}),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffffff")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("764cff")),
				}),
				Rotation = 90,
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.7,
			}),
			Premium = PremiumRewards(hooks),
			Quests = Quests(hooks),
			Rewards = Rewards(hooks),
		}),
	})
end

Season = RoactHooks.new(Roact)(Season)
return Season
