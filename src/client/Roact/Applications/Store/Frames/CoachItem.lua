local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

local StoreController = Knit.GetController("StoreController")
local MonetizationController = Knit.GetController("MonetizationController")
local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")

return function(params: table)
	setmetatable(params, {
		__index = {
			name = "" :: string,
			buyName = "" :: string,
			image = "" :: string,
			multiplier = "" :: string,
			bought = false :: boolean,
			order = 0 :: number,
		},
	})

	local buyItemName = params.buyName ~= "" and params.buyName or "Coach - " .. params.name

	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		Position = UDim2.fromScale(0.022, 0.104),
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromHex("fff67c"),
		Size = UDim2.fromScale(0.46, 0.89),
		ZIndex = 2,
	}, {
		Pic = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.05, 0.58),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.75, 0.75),
			ZIndex = 2,
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffcc00")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("ff8239")),
				}),
				Rotation = 90,
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("7d4d15"),
				Thickness = 2,
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = params.image,
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Sparkle = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://106466414055348",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1.3, 1.3),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		Bought = Roact.createElement("Frame", {
			Visible = params.bought,
			BackgroundTransparency = 0.2,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			UICorner = Roact.createElement("UICorner", {}),
			BoughtText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Bought!",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				TextSize = 14,
				ZIndex = 11,
				TextScaled = true,
				Size = UDim2.fromScale(0.7, 0.3),
			}),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1.75,
		}),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			TextScaled = true,
			AnchorPoint = Vector2.new(1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			TextXAlignment = 1,
			Position = UDim2.fromScale(0.97, 0.028),
			ZIndex = 4,
			TextSize = 14,
			Size = UDim2.fromScale(0.554, 0.37),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 2,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("ff6326")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("591b00")),
					}),
					Rotation = 90,
				}),
			}),
		}),
		Value = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.97, 0.45),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.554, 0.2),
		}, {
			ValueText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffca2c"),
				Text = params.multiplier,
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 1,
				Position = UDim2.fromScale(0.761, 0.383),
				ZIndex = 3,
				TextSize = 14,
				Size = UDim2.fromScale(0.4, 0.8),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("313131"),
					Thickness = 2,
				}),
			}),
			Icon = Roact.createElement("ImageLabel", {
				LayoutOrder = 1,
				ScaleType = 3,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Multiplier,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.849, 0.15),
				ZIndex = 5,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			List = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 2,
				Padding = UDim.new(0.02, 0),
				ItemLineAlignment = 2,
				FillDirection = 0,
			}),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("ffffff"),
			Thickness = 2,
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ff6326")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("591b00")),
				}),
				Rotation = 90,
			}),
		}),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.716, 0.844),
			Size = UDim2.fromScale(0.509, 0.216),
			ZIndex = 3,
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				StoreController:BuyItem({ name = buyItemName })
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("fcffc4"),
				Thickness = 2,
			}),
			PriceText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = ` {MonetizationController:GetPrice(buyItemName)}`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				TextSize = 18,
				ZIndex = 3,
				TextScaled = true,
				Size = UDim2.fromScale(0.85, 0.7),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("313131"),
					Thickness = 1.5,
				}),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("3dff27")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("23a617")),
				}),
				Rotation = 90,
			}),
		}),
	})
end
