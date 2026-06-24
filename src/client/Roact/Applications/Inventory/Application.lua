local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")

local FrameConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local InventoryConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.InventoryConstants)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local InventoryActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.InventoryActions)

-- UI
local UI = DataCacheController:GetFile("Images")

local Frames = script.Parent.Frames
local Players = require(Frames.Players)
local Accessories = require(Frames.Accessories)
local Boosts = require(Frames.Boosts)

function Inventory(_, hooks)
	local currentUI = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer.CurrentUI
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	hooks.useEffect(function()
		if currentUI ~= FrameConstants.Inventory then
			Store:dispatch(InventoryActions.setDeletingCharacters(false))
			Store:dispatch(InventoryActions.setDeletingAccessories(false))
		end
	end, { currentUI or "" })

	return Roact.createElement("Frame", {
		Visible = currentUI == FrameConstants.Inventory,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromHex("000000"),
		Size = UDim2.fromScale(1, 1),
	}, {
		Popup = Blue_Background({
			title = "Inventory",
			titleIcon = UI.Inventory,
			size = UDim2.fromScale(0.7, 0.7),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
			action = function()
				UIController:HideFrame()
			end,
		}, {
			Players = Roact.createElement(Players),
			Boosts = Roact.createElement(Boosts),
			Panels = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.2),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.91, 0.1),
			}, {
				Players = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					Size = UDim2.fromScale(0.33, 1),
					Position = UDim2.fromScale(0.126, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if InventoryReducer.Inventory == InventoryConstants.SoccerCharacters
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(InventoryActions.setInventory(InventoryConstants.SoccerCharacters))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Players",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.684, 0.5),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.419, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://76558147588196",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
				Boosts = Roact.createElement("ImageButton", {
					LayoutOrder = 4,
					Size = UDim2.fromScale(0.33, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if InventoryReducer.Inventory == InventoryConstants.Boosts
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(InventoryActions.setInventory(InventoryConstants.Boosts))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Boosts",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.648, 0.5),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.4, 0.5),
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://132232460054998",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
				Accessories = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.33, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if InventoryReducer.Inventory == InventoryConstants.Accessories
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(InventoryActions.setInventory(InventoryConstants.Accessories))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Accessories",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.672, 0.5),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.656, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://124847512307439",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.012, 0),
					FillDirection = 0,
				}),
			}),
			Accessories = Roact.createElement(Accessories),
		}),
	})
end

Inventory = RoactHooks.new(Roact)(Inventory)
return Inventory
