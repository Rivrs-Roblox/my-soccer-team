local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local DataCacheController = Knit.GetController("DataCacheController")
local AutoController = Knit.GetController("AutoController")

local UI = DataCacheController:GetFile("Images")

function BottomFrame(_, hooks)
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.99),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.2, 0.117),
	}, {
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.05, 0),
				FillDirection = 0,
			}),
			AutoPass = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderColor3 = Color3.fromHex("000000"),
				LayoutOrder = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.8, 0.8),
			}, {
				Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
				Pass = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 1),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),

					[Roact.Event.MouseButton1Down] = function()
						AutoController:RequestAutoTraining("Pass")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Pass",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					Notification = Roact.createElement("Frame", {
						Visible = false,
						Position = UDim2.fromScale(0.95, 0.1),
						BackgroundColor3 = Color3.fromHex("ff0000"),
						ZIndex = 10000,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromScale(0.35, 0.35),
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
							Thickness = 1.5,
						}),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("a53838")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("3d1212")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("d92c2c"),
						Thickness = 2,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.4),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = UI.Pass,
						Size = UDim2.fromScale(0.7, 0.7),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				}),
				Shadow = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("000000"),
					BackgroundTransparency = 0.7,
					Position = UDim2.fromScale(0.5, 0.6),
					BorderColor3 = Color3.fromHex("000000"),
					ZIndex = 0,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1.05, 1.05),
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				}),
			}),
			AutoDribble = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderColor3 = Color3.fromHex("000000"),
				LayoutOrder = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.8, 0.8),
			}, {
				Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
				Dribble = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 1),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),

					[Roact.Event.MouseButton1Down] = function()
						AutoController:RequestAutoTraining("Dribble")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Dribble",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					Notification = Roact.createElement("Frame", {
						Visible = false,
						Position = UDim2.fromScale(0.95, 0.1),
						BackgroundColor3 = Color3.fromHex("ff0000"),
						ZIndex = 10000,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromScale(0.35, 0.35),
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
							Thickness = 1.5,
						}),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("a53838")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("3d1212")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("d92c2c"),
						Thickness = 2,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.4),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = UI.Dribble,
						Size = UDim2.fromScale(0.7, 0.7),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				}),
				Shadow = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("000000"),
					BackgroundTransparency = 0.7,
					Position = UDim2.fromScale(0.5, 0.6),
					BorderColor3 = Color3.fromHex("000000"),
					ZIndex = 0,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1.05, 1.05),
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				}),
			}),
			AutoShoot = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderColor3 = Color3.fromHex("000000"),
				LayoutOrder = 2,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.8, 0.8),
			}, {
				Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
				Shoot = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 1),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),

					[Roact.Event.MouseButton1Down] = function()
						AutoController:RequestAutoTraining("Shoot")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Shoot",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					Notification = Roact.createElement("Frame", {
						Visible = false,
						Position = UDim2.fromScale(0.95, 0.1),
						BackgroundColor3 = Color3.fromHex("ff0000"),
						ZIndex = 10000,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromScale(0.35, 0.35),
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
							Thickness = 1.5,
						}),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("a53838")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("3d1212")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("d92c2c"),
						Thickness = 2,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.4),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = UI.Shoot,
						Size = UDim2.fromScale(0.7, 0.7),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				}),
				Shadow = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("000000"),
					BackgroundTransparency = 0.7,
					Position = UDim2.fromScale(0.5, 0.6),
					BorderColor3 = Color3.fromHex("000000"),
					ZIndex = 0,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1.05, 1.05),
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				}),
			}),
		}),
		Text = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("fafafa"),
			Text = "Auto (Free!)",
			AnchorPoint = Vector2.new(0.5, 1),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, -0.05),
			TextSize = 14,
			ZIndex = 1,
			TextScaled = true,
			Size = UDim2.fromScale(0.85, 0.3),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("8a1616"),
				Thickness = 1.5,
			}),
		}),
	})
end

BottomFrame = RoactHooks.new(Roact)(BottomFrame)
return BottomFrame
