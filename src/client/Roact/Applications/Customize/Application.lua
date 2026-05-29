local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")

local FrameConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)

local Frames = script.Parent.Frames
local Teams = require(Frames.Teams)
local Coaches = require(Frames.Coaches)
local Accessories = require(Frames.Accessories)

function Customize(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentUI == FrameConstants.Customize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromHex("000000"),
		Size = UDim2.fromScale(1, 1),
	}, {
		Popup = Blue_Background({
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
			Coaches = Roact.createElement(Coaches),
			Panels = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.2),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.91, 0.1),
			}, {
				Teams = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					Size = UDim2.fromScale(0.325, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if UIReducer.CurrentCustomizeUI == CustomizeConstants.Teams
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Teams))
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					Center = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}, {
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
							Image = UI.Teams,
							Size = UDim2.fromScale(0.8, 0.8),
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						ButtonText = Roact.createElement("TextLabel", {
							TextWrapped = true,
							TextColor3 = Color3.fromHex("fafafa"),
							Text = "Teams",
							TextScaled = true,
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							Position = UDim2.fromScale(0.741, 0.5),
							ZIndex = 5,
							TextSize = 14,
							Size = UDim2.fromScale(0.563, 0.5),
						}),
					}),
				}),
				Coaches = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.325, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if UIReducer.CurrentCustomizeUI == CustomizeConstants.Coaches
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Coaches))
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					Notification = Roact.createElement("Frame", {
						Visible = false,
						Position = UDim2.fromScale(0.97, 0.1),
						BackgroundColor3 = Color3.fromHex("ff0000"),
						ZIndex = 10000,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromScale(0.5, 0.5),
					}, {
						Icon = Roact.createElement("ImageLabel", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							ScaleType = 3,
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.5, 0.5),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							ZIndex = 2,
							Image = "rbxassetid://125311831710765",
							Size = UDim2.fromScale(0.8, 0.8),
						}),
						Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
						Corner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						Stroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("ffffff"),
							Thickness = 2,
						}),
					}),
					Center = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}, {
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
							Image = UI.Coaches,
							Size = UDim2.fromScale(0.8, 0.8),
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						ButtonText = Roact.createElement("TextLabel", {
							TextWrapped = true,
							TextColor3 = Color3.fromHex("fafafa"),
							Text = "Coaches",
							TextScaled = true,
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							Position = UDim2.fromScale(0.741, 0.5),
							ZIndex = 5,
							TextSize = 14,
							Size = UDim2.fromScale(0.563, 0.5),
						}),
					}),
				}),
				Accessories = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.325, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = if UIReducer.CurrentCustomizeUI == CustomizeConstants.Accessories
						then Color3.fromHex("e23e3e")
						else Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(UIActions.setCurrentCustomizeUI(CustomizeConstants.Accessories))
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					Center = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					}, {
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
							Image = UI.Accessories,
							Size = UDim2.fromScale(0.8, 0.8),
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						ButtonText = Roact.createElement("TextLabel", {
							TextWrapped = true,
							TextColor3 = Color3.fromHex("fafafa"),
							Text = "Accessories",
							TextScaled = true,
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							Position = UDim2.fromScale(0.741, 0.5),
							ZIndex = 5,
							TextSize = 14,
							Size = UDim2.fromScale(0.563, 0.5),
						}),
					}),
				}),
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.01, 0),
					FillDirection = 0,
				}),
			}),
			Accessories = Roact.createElement(Accessories),
			Teams = Roact.createElement(Teams),
		}),
	})
end

Customize = RoactHooks.new(Roact)(Customize)
return Customize
