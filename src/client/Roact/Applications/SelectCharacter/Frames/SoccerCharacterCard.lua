--[=[
   Owner: JustStop__
   Version: 0.0.1
   Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local UIController = Knit.GetController("UIController")
local TeamController = Knit.GetController("TeamController")

-- UI
local UI = DataCacheController:GetFile("Images")

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

return function(params: table)
	setmetatable(params, {
		__index = {
			id = "" :: string,
			name = "" :: string,
			shoot = 0 :: number,
			dribble = 0 :: number,
			pass = 0 :: number,
			rarity = "" :: string,
			image = "" :: string,
			level = 0 :: number,
			card = "" :: string,
			cardMask = "" :: string,
			order = 0 :: number,
			selectedSlot = nil,
			nationality = "Roblox" :: string,
		},
	})

	local selectedSlot = params.selectedSlot

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = 3,
		BackgroundTransparency = 1,
		Image = params.card,
		LayoutOrder = params.order,
		BackgroundColor3 = Color3.fromHex("fcfaff"),
		ZIndex = 2,

		[Roact.Event.MouseButton1Down] = function()
			Sound:PlaySound("UI_Click")
			if selectedSlot then
				TeamController:SetSlot(selectedSlot, params.id):andThen(function(result)
					if result then
						UIController:ShowFrame({ frame = FramesConstants.Customize })
					end
				end)
			end
		end,
	}, {
		Stars = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.1),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.5, 0.15),
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
				Image = UI.Stars,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 10,
				ScaleType = 3,
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			NumberText = Roact.createElement("TextLabel", {
				LayoutOrder = 2,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = tostring(params.level),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 10,
				TextSize = 14,
				Size = UDim2.fromScale(0.25, 1),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 2,
				}),
			}),
			Flag = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI[params.nationality] or UI.Roblox,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 3,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ScaleType = 3,
				Size = UDim2.fromScale(0.9, 0.9),
				ZIndex = 3,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.4,
			}) }),
		}),
		Player = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.42),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 2,
			ClipsDescendants = true,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.7, 0.7),
		}, {
			Image = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = params.image,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1.7, 1),
			}),
		}),
		Deleting = Roact.createElement("ImageLabel", {
			Visible = false,
			ScaleType = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://76931062937616",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.65),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 12,
			ImageColor3 = Color3.fromHex("ff0000"),
			Size = UDim2.fromScale(0.5, 0.5),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		CardMask = Roact.createElement("ImageLabel", {
			ScaleType = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = params.cardMask,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.6,
		}),
		Equipped = Roact.createElement("ImageLabel", {
			Visible = false,
			ScaleType = 3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://93840956317609",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.65),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 11,
			ImageColor3 = Color3.fromHex("00fa00"),
			Size = UDim2.fromScale(0.5, 0.5),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Stats = Roact.createElement("Frame", {
			ClipsDescendants = true,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.76),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.68, 0.4),
		}, {
			NameText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("000000"),
				TextStrokeColor3 = Color3.fromHex("ffffff"),
				Text = params.name,
				BorderColor3 = Color3.fromHex("000000"),
				Size = UDim2.fromScale(0.95, 0.25),
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0),
				TextScaled = true,
				ZIndex = 10,
				TextSize = 14,
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),
			}),
			Group = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.25),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.75),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					HorizontalAlignment = 0,
					SortOrder = 2,
				}),
				Passing = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.3, 0.4),
					BorderColor3 = Color3.fromHex("000000"),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.85, 0.22),
				}, {
					UIListLayout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
						HorizontalAlignment = 0,
						SortOrder = 2,
					}),
					StatText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = "PAS",
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 2,
					}),
					NumberText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = tostring(params.pass),
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 1,
					}),
				}),
				Shooting = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.3, 0.4),
					BorderColor3 = Color3.fromHex("000000"),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.85, 0.22),
				}, {
					UIListLayout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
						HorizontalAlignment = 0,
						SortOrder = 2,
					}),
					StatText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = "SHO",
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 2,
					}),
					NumberText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = tostring(params.shoot),
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 1,
					}),
				}),
				Dribble = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.3, 0.4),
					BorderColor3 = Color3.fromHex("000000"),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.85, 0.22),
				}, {
					UIListLayout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
						HorizontalAlignment = 0,
						SortOrder = 2,
					}),
					StatText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = "DRI",
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 2,
					}),
					NumberText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						BorderColor3 = Color3.fromHex("000000"),
						TextColor3 = Color3.fromHex("000000"),
						TextStrokeColor3 = Color3.fromHex("ffffff"),
						Text = tostring(params.dribble),
						Size = UDim2.fromScale(0.45, 1),
						Position = UDim2.fromScale(0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Font = 40,
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						TextScaled = true,
						ZIndex = 10,
						TextSize = 14,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						LayoutOrder = 1,
					}),
				}),
			}),
		}),
	})
end
