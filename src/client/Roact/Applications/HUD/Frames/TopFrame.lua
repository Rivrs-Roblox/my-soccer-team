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
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

local UI = DataCacheController:GetFile("Images")

function TopFrame(_, hooks)
	local playerReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.PlayerReducer
	end)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0),
		BackgroundColor3 = Color3.fromHex("142184"),
		Size = UDim2.fromScale(0.98, 0.12),
	}, {
		UIPadding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0.1, 0),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0.15, 0),
		}),
		Shooting = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromHex("111f39"),
			BorderColor3 = Color3.fromHex("000000"),
			LayoutOrder = 4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.6, 0.5),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("e8e8e8"),
				Thickness = 2,
			}),
			-- Plus = Roact.createElement("ImageButton", {
			-- 	LayoutOrder = 3,
			-- 	ScaleType = 3,
			-- 	BorderColor3 = Color3.fromHex("000000"),
			-- 	AnchorPoint = Vector2.new(0.5, 0.5),
			-- 	Image = "rbxassetid://98999428594161",
			-- 	BackgroundTransparency = 1,
			-- 	Position = UDim2.fromScale(0.9, 0.5),
			-- 	Size = UDim2.fromScale(0.5, 0.5),
			-- 	ImageColor3 = Color3.fromHex("b0b0b0"),
			-- 	BorderSizePixel = 0,
			-- 	BackgroundColor3 = Color3.fromHex("ffffff"),
			-- }, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			BottomText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Shooting",
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1.05),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.8, 0.4),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 1.5,
				}),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.5,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.13, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Shoot,
				Size = UDim2.fromScale(0.3, 0.7),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			MainText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(playerReducer.Shoot),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.52, 0.5),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.55, 0.5),
			}),
		}),
		Wins = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromHex("111f39"),
			BorderColor3 = Color3.fromHex("000000"),
			LayoutOrder = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.6, 0.5),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("e8e8e8"),
				Thickness = 2,
			}),
			Plus = Roact.createElement("ImageButton", {
				LayoutOrder = 3,
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://98999428594161",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.9, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				ImageColor3 = Color3.fromHex("b0b0b0"),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),

				[Roact.Event.MouseButton1Click] = function()
					Sound:PlaySound("UI_Click")
					Store:dispatch(UIActions.setCurrentStoreSectionUI("WinPacks"))
					UIController:ShowFrame({ frame = FramesConstants.Store })
				end,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			BottomText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Wins",
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1.05),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.8, 0.4),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 1.5,
				}),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.5,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.13, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Wins,
				Size = UDim2.fromScale(0.3, 0.7),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			MainText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(playerReducer.Wins),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.52, 0.5),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.55, 0.5),
			}),
		}),
		UIListLayout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0.01, 0),
			FillDirection = 0,
			HorizontalAlignment = 0,
			SortOrder = 2,
		}),
		Passing = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromHex("111f39"),
			BorderColor3 = Color3.fromHex("000000"),
			LayoutOrder = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.6, 0.5),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("e8e8e8"),
				Thickness = 2,
			}),
			-- Plus = Roact.createElement("ImageButton", {
			-- 	LayoutOrder = 3,
			-- 	ScaleType = 3,
			-- 	BorderColor3 = Color3.fromHex("000000"),
			-- 	AnchorPoint = Vector2.new(0.5, 0.5),
			-- 	Image = "rbxassetid://98999428594161",
			-- 	BackgroundTransparency = 1,
			-- 	Position = UDim2.fromScale(0.9, 0.5),
			-- 	Size = UDim2.fromScale(0.5, 0.5),
			-- 	ImageColor3 = Color3.fromHex("b0b0b0"),
			-- 	BorderSizePixel = 0,
			-- 	BackgroundColor3 = Color3.fromHex("ffffff"),
			-- }, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			BottomText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Passing",
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1.05),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.8, 0.4),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 1.5,
				}),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.5,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.13, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Pass,
				Size = UDim2.fromScale(0.3, 0.7),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			MainText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(playerReducer.Pass),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.52, 0.5),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.55, 0.5),
			}),
		}),
		Rebirths = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromHex("111f39"),
			BorderColor3 = Color3.fromHex("000000"),
			LayoutOrder = 2,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.6, 0.5),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("e8e8e8"),
				Thickness = 2,
			}),
			Plus = Roact.createElement("ImageButton", {
				LayoutOrder = 3,
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxassetid://98999428594161",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.9, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				ImageColor3 = Color3.fromHex("b0b0b0"),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),

				[Roact.Event.MouseButton1Click] = function()
					Sound:PlaySound("UI_Click")
					UIController:ShowFrame({ frame = FramesConstants.Rebirth })
				end,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			BottomText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Rebirths",
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1.05),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.8, 0.4),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 1.5,
				}),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.5,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.13, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Rebirth,
				Size = UDim2.fromScale(0.3, 0.7),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			MainText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(playerReducer.Rebirth),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.52, 0.5),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.55, 0.5),
			}),
		}),
		Dribbling = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromHex("111f39"),
			BorderColor3 = Color3.fromHex("000000"),
			LayoutOrder = 5,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.6, 0.5),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("e8e8e8"),
				Thickness = 2,
			}),
			-- Plus = Roact.createElement("ImageButton", {
			-- 	LayoutOrder = 3,
			-- 	ScaleType = 3,
			-- 	BorderColor3 = Color3.fromHex("000000"),
			-- 	AnchorPoint = Vector2.new(0.5, 0.5),
			-- 	Image = "rbxassetid://98999428594161",
			-- 	BackgroundTransparency = 1,
			-- 	Position = UDim2.fromScale(0.9, 0.5),
			-- 	Size = UDim2.fromScale(0.5, 0.5),
			-- 	ImageColor3 = Color3.fromHex("b0b0b0"),
			-- 	BorderSizePixel = 0,
			-- 	BackgroundColor3 = Color3.fromHex("ffffff"),
			-- }, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			BottomText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Dribbling",
				AnchorPoint = Vector2.new(0.5, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 1.05),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.8, 0.4),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("191919"),
					Thickness = 1.5,
				}),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3.5,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.13, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Dribble,
				Size = UDim2.fromScale(0.3, 0.7),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			MainText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(playerReducer.Dribble),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.52, 0.5),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.55, 0.5),
			}),
		}),
	})
end

TopFrame = RoactHooks.new(Roact)(TopFrame)
return TopFrame
