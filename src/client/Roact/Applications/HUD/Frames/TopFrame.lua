local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local DataCacheController = Knit.GetController("DataCacheController")
local UIController = Knit.GetController("UIController")

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

local UI = DataCacheController:GetFile("Images")
local StatCard = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Components.StatCard)

function TopFrame(_, hooks)
	local playerReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.PlayerReducer
	end)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0),
		BackgroundColor3 = Color3.fromHex("142184"),
		Size = UDim2.fromScale(0.98, 0.12),
	}, {
		UIPadding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0.1, 0),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0.15, 0),
		}),
		Wins = Roact.createElement(StatCard, {
			LayoutOrder = 1,
			Title = "Wins",
			Icon = UI.Wins,
			Value = FormatNumber(playerReducer.Wins),
			OnPlusClick = function()
				if UIController:IsPanelOpenBlocked() then
					return
				end
				Sound:PlaySound("UI_Click")
				Store:dispatch(UIActions.setCurrentStoreSectionUI("WinPacks"))
				UIController:ShowFrame({ frame = FramesConstants.Store })
			end,
		}),
		Rebirths = Roact.createElement(StatCard, {
			LayoutOrder = 2,
			Title = "Rebirths",
			Icon = UI.Rebirth,
			Value = FormatNumber(playerReducer.Rebirth),
			OnPlusClick = function()
				if UIController:IsPanelOpenBlocked() then
					return
				end
				Sound:PlaySound("UI_Click")
				UIController:ShowFrame({ frame = FramesConstants.Rebirth })
			end,
		}),
		UIListLayout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0.01, 0),
			FillDirection = 0,
			HorizontalAlignment = 0,
			SortOrder = 2,
		}),
		Passing = Roact.createElement(StatCard, {
			LayoutOrder = 3,
			Title = "Passing",
			Icon = UI.Pass,
			Value = FormatNumber(playerReducer.Pass),
		}),
		Shooting = Roact.createElement(StatCard, {
			LayoutOrder = 4,
			Title = "Shooting",
			Icon = UI.Shoot,
			Value = FormatNumber(playerReducer.Shoot),
		}),
		Dribbling = Roact.createElement(StatCard, {
			LayoutOrder = 5,
			Title = "Dribbling",
			Icon = UI.Dribble,
			Value = FormatNumber(playerReducer.Dribble),
		}),
		--[[ Stamina = Roact.createElement(StatCard, {
			LayoutOrder = 6,
			Title = "Stamina",
			Icon = UI.Stamina,
			Value = FormatNumber(playerReducer.Stamina),
		}), ]]
	})
end

TopFrame = RoactHooks.new(Roact)(TopFrame)
return TopFrame
