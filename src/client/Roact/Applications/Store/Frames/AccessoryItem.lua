local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

local DataCacheController = Knit.GetController("DataCacheController")
local StoreController = Knit.GetController("StoreController")
local MonetizationController = Knit.GetController("MonetizationController")

local UI = DataCacheController:GetFile("Images")
local Colors = DataCacheController:GetFile("Colors")

return function(params: table)
	setmetatable(params, {
		__index = {
			name = "" :: string,
			image = "" :: string,
			shoot = 0 :: number,
			pass = 0 :: number,
			dribble = 0 :: number,
			order = 0 :: number,
			rarity = "Exclusive" :: string,
		},
	})

	local gradient = Colors.Gradients[params.rarity] or Colors.Gradients.Exclusive or Colors.Gradients.Legendary
	local strokeColor = Colors.Stroke[params.rarity] or Color3.fromHex("b9861b")

	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		Position = UDim2.fromScale(0.022, 0.104),
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromScale(0.22, 0.89),
		ZIndex = 2,
	}, {
		BackgroundGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, gradient.startColor),
				ColorSequenceKeypoint.new(1, gradient.endColor),
			}),
			Rotation = 90,
		}),
		Stats = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.97, 0.43),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.541, 0.459),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.02, 0),
			}),
			Passing = Roact.createElement("Frame", {
				LayoutOrder = 1,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.8),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 10,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.33),
			}, {
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 2,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Pass,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 2,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.pass}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					TextScaled = true,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 2,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("191919"),
						Thickness = 1.5,
					}),
				}),
			}),
			Shooting = Roact.createElement("Frame", {
				LayoutOrder = 2,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.8),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 10,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.33),
			}, {
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 2,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Shoot,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 2,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.shoot}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					TextScaled = true,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 2,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("191919"),
						Thickness = 1.5,
					}),
				}),
			}),
			Dribbling = Roact.createElement("Frame", {
				LayoutOrder = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.8),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 10,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.33),
			}, {
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 2,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Dribble,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 2,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.dribble}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					TextScaled = true,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 2,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("191919"),
						Thickness = 1.5,
					}),
				}),
			}),
		}),
		Effect = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://106335669168445",
			BackgroundTransparency = 1,
			ImageTransparency = 0.4,
			ImageColor3 = gradient.startColor,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Position = UDim2.fromScale(0.25, 0.5),
			ScaleType = 3,
			Size = UDim2.fromScale(0.928, 1.598),
			ZIndex = 2,
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Sparkle = Roact.createElement("ImageLabel", {
			ScaleType = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = UI.Sparkle,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.25, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1.2, 1.2),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			TextScaled = true,
			ZIndex = 4,
			AnchorPoint = Vector2.new(1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			TextXAlignment = 1,
			Position = UDim2.fromScale(0.97, 0.028),
			TextYAlignment = 0,
			TextSize = 14,
			Size = UDim2.fromScale(0.554, 0.15),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 2,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, gradient.startColor),
						ColorSequenceKeypoint.new(1, strokeColor),
					}),
					Rotation = 90,
				}),
			}),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 2.1,
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("ffffff"),
			Thickness = 2,
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, gradient.startColor),
					ColorSequenceKeypoint.new(1, strokeColor),
				}),
				Rotation = 90,
			}),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			ScaleType = 3,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.25, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 2,
			Image = params.image,
			Size = UDim2.fromScale(1, 1),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.716, 0.844),
			Size = UDim2.fromScale(0.509, 0.216),
			ZIndex = 3,
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				StoreController:BuyItem({ name = `Accessory - {params.name}` })
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("fcffc4"),
				Thickness = 2,
			}),
			PriceText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = ` {MonetizationController:GetPrice(`Accessory - {params.name}`)}`,
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
