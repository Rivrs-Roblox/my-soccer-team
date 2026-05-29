local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

local StoreController = Knit.GetController("StoreController")
local MonetizationController = Knit.GetController("MonetizationController")

return function(params: table)
	setmetatable(params, {
		__index = {
			name = "" :: string,
			buyName = "" :: string,
			description = "" :: string,
			icon = "" :: string,
			gradientColors = { "ffffff", "ffffff" } :: table,
			strokeColors = { "ffffff", "ffffff" } :: table,
			bought = false :: boolean,
			order = 0 :: number,
			value = "" :: string,
		},
	})

	local buyItemName = params.buyName ~= "" and params.buyName or params.name

	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		Position = UDim2.fromScale(0.022, 0.104),
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Size = UDim2.fromScale(1, 0.45),
		ZIndex = 2,
	}, {
		DescriptionText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.description,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Font = 45,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.697, 0.449),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.539, 0.313),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("313131"),
				Thickness = 1.5,
			}),
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
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
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
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex(params.gradientColors[1])),
				ColorSequenceKeypoint.new(1, Color3.fromHex(params.gradientColors[2])),
			}),
		}),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.691, 0.156),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.528, 0.199),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 2,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex(params.strokeColors[1])),
						ColorSequenceKeypoint.new(1, Color3.fromHex(params.strokeColors[2])),
					}),
					Rotation = 90,
				}),
			}),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("ffffff"),
			Thickness = 2,
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex(params.strokeColors[1])),
					ColorSequenceKeypoint.new(1, Color3.fromHex(params.strokeColors[2])),
				}),
				Rotation = 90,
			}),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 2.1,
		}),
		Item = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromScale(0.21, 0.5),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.75, 0.75),
			ZIndex = 2,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = params.icon,
				Size = UDim2.fromScale(0.9, 0.9),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			ValueText = Roact.createElement("TextLabel", {
				Visible = true,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffea00"),
				Text = params.value,
				AnchorPoint = Vector2.new(1, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.98, 0.98),
				TextSize = 14,
				ZIndex = 3,
				TextScaled = true,
				Size = UDim2.fromScale(0.4, 0.35),
			}, { UIStroke = Roact.createElement("UIStroke", {
				Thickness = 2,
			}) }),
		}),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.697, 0.8),
			Size = UDim2.fromScale(0.539, 0.251),
			ZIndex = 2,
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				StoreController:BuyItem({ name = buyItemName })
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
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
