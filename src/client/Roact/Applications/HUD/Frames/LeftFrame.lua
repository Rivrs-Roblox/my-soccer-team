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

local UI = DataCacheController:GetFile("Images")

local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)
local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)

local Button = require(script.Parent.Button)

function LeftFrame(_, hooks)
	local NotificationReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.NotificationReducer
	end)
	local RejoinReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.RejoinReducer
	end)

	local RebirthNotif = NotificationReducer.Notifications["Rebirth"]
	local AreaNotif = NotificationReducer.Notifications["Areas"]
	local CoachNotif = NotificationReducer.Notifications["Coaches"] or 0
	local StoreNotif = NotificationReducer.Notifications["Store"]

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.01, 0.42),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.134, 0.2),
	}, {
		Main = Roact.createElement("Frame", {
			ZIndex = 2,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			UIGridLayout = Roact.createElement("UIGridLayout", {
				FillDirectionMaxCells = 2,
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.45, 0.45),
				CellPadding = UDim2.fromScale(0, 0.1),
			}),
			StoreBtn = Roact.createElement(Button, {
				name = "Store",
				image = UI.Store,
				order = 1,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Store })
				end,
				notification = StoreNotif,
			}),
			PacksBtn = Roact.createElement(Button, {
				name = "Packs",
				image = UI.Packs,
				order = 2,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Packs })
				end,
			}),
			RebirthBtn = Roact.createElement(Button, {
				name = "Rebirth",
				image = UI.Rebirth,
				order = 3,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Rebirth })
				end,
				notification = RebirthNotif,
			}),
			TeamBtn = Roact.createElement(Button, {
				name = "Team",
				image = UI.Teams,
				order = 4,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Customize })
					Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Teams))
				end,
			}),
			CoachesBtn = Roact.createElement(Button, {
				name = "Coaches",
				image = UI.Coaches,
				order = 5,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Customize })
					Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Coaches))
				end,
				notification = CoachNotif,
			}),
			AccessoriesBtn = Roact.createElement(Button, {
				name = "Accessories",
				image = UI.Accessories,
				order = 6,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Customize })
					Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Accessories))
				end,
			}),
			TravelBtn = Roact.createElement(Button, {
				name = "Travel",
				image = UI.Travel,
				order = 7,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Travel })
				end,
				notification = AreaNotif,
			}),
			InventoryBtn = Roact.createElement(Button, {
				name = "Inventory",
				image = UI.Inventory,
				order = 8,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Inventory })
				end,
			}),
		}),
		Rejoin = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.45, -0.5),
			BorderColor3 = Color3.fromHex("000000"),
			Size = UDim2.fromScale(0.8, 0.8),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Visible = not RejoinReducer.ClaimedRejoinReward,

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				UIController:ShowFrame({ frame = FramesConstants.Rejoin })
			end,
		}, {
			ButtonText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Rejoin Pack!",
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.98),
				TextSize = 14,
				ZIndex = 5,
				TextScaled = true,
				Size = UDim2.fromScale(1.3, 0.35),
			}, { UIStroke = Roact.createElement("UIStroke", {
				Thickness = 1.5,
			}) }),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.9,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://77407958918252",
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Effect = Roact.createElement("ImageLabel", {
				ImageColor3 = Color3.fromHex("ff5e00"),
				Image = "rbxassetid://106335669168445",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				Size = UDim2.fromScale(1.5, 1.5),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
	})
end

LeftFrame = RoactHooks.new(Roact)(LeftFrame)
return LeftFrame
