--[=[
    Owner: JustStop__
    Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Frames
local Frames = script.Parent.Frames
local Item = require(Frames.Item)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Controllers
local TradeController = Knit.GetController("TradeController")
local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

-- Trading
function Trading(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	local PlayersItems = {}
	local order = 1

	for _, Player in ipairs(Players:GetPlayers()) do
		if Player.UserId ~= Players.LocalPlayer.UserId then
			PlayersItems[tostring(Player.UserId)] = Item({
				Name = Player.Name,
				UserId = Player.UserId,
				Value = "Trade",
				LayoutOrder = order,
				Action = function()
					UIController:HideFrame()
					TradeController:Request(Player)
				end,
				hooks = hooks,
			})

			order += 1
		end
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = UIReducer.CurrentUI == FramesConstants.TradeList,
		ZIndex = 2,
	}, {
		Popup = Blue_Background({
			title = "Trading",
			titleIcon = UI.Trade,
			size = UDim2.fromScale(0.6, 0.6),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.3,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
		}, {
			Scroll = Roact.createElement("ScrollingFrame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.573),
				BackgroundTransparency = 1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 8,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(0.95, 0.807),
				ZIndex = 3,
			}, {
				UIPadding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0.01, 0),
					PaddingBottom = UDim.new(0.03, 0),
				}),

				List = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.05, 0),
				}),

				Roact.createFragment(PlayersItems),
			}),
		}),
	})
end

Trading = RoactHooks.new(Roact)(Trading)
return Trading
