local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")

-- UI
local UI = DataCacheController:GetFile("Images")
local Colors = DataCacheController:GetFile("Colors")

return function(params: table)
	setmetatable(params, {
		__index = {
			id = 0 :: number,
			name = "" :: string,
			image = "" :: string,
			equipped = false :: boolean,
			rarity = "" :: string,
			pass = 0 :: number,
			shoot = 0 :: number,
			dribble = 0 :: number,
			type = "" :: string,
			deleting = false :: boolean,
			onClick = function() end :: any,
			order = 0 :: number,
		},
	})

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		ZIndex = 2,
		LayoutOrder = params.order,
	}, {
		TouchTarget = Roact.createElement("ImageButton", {
			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 20,

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				if params.onClick then
					params.onClick()
				end
			end,
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.7,
		}),
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Colors.Gradients[params.rarity].startColor),
				ColorSequenceKeypoint.new(1, Colors.Gradients[params.rarity].endColor),
			}),
			Rotation = 90,
		}),
		Stats = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.98),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.9, 0.4),
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
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Pass,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 1,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 2,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.pass}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextScaled = true,
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 3,
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
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Shoot,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 1,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 2,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.shoot}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextScaled = true,
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 3,
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
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Dribble,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					LayoutOrder = 1,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ScaleType = 3,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				NumberText = Roact.createElement("TextLabel", {
					LayoutOrder = 2,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `x{params.dribble}`,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextScaled = true,
					TextSize = 14,
					Size = UDim2.fromScale(0.7, 1),
					ZIndex = 3,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("191919"),
						Thickness = 1.5,
					}),
				}),
			}),
		}),
		Deleting = Roact.createElement("ImageLabel", {
			Visible = params.deleting,
			ScaleType = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://76931062937616",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 12,
			ImageColor3 = Color3.fromHex("ff0000"),
			Size = UDim2.fromScale(0.7, 0.7),
		}),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.12),
			TextSize = 14,
			ZIndex = 10,
			TextScaled = true,
			Size = UDim2.fromScale(0.85, 0.2),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Thickness = 1.5,
			}),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Colors.Stroke[params.rarity],
			Thickness = 3,
		}),
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = params.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.4),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ScaleType = 3,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Equipped = Roact.createElement("ImageLabel", {
			Visible = params.equipped,
			ScaleType = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://93840956317609",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 11,
			ImageColor3 = Color3.fromHex("00fa00"),
			Size = UDim2.fromScale(0.7, 0.7),
		}),
	})
end
