local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local DataCacheController = Knit.GetController("DataCacheController")
local StoreController = Knit.GetController("StoreController")
local TooltipController = Knit.GetController("TooltipController")
local MonetizationController = Knit.GetController("MonetizationController")

local Helpers = ReplicatedStorage.Shared.Helpers
local CreateHoverDescription = require(Helpers.CreateHoverDescription)

local Template = DataCacheController:GetFile("Template")
local UI = DataCacheController:GetFile("Images")

function Elite(_, hooks)
	local MonetizationReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.MonetizationReducer
	end)

	return Roact.createElement("Frame", {
		LayoutOrder = 12,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.5),
	}, {
		["10"] = Roact.createElement("Frame", {
			LayoutOrder = 1,
			Position = UDim2.fromScale(0.025, 0.12),
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Size = UDim2.fromScale(0.95, 0.5),
			ZIndex = 2,
		}, {
			Rarity = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.98, 0.175),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.5, 0.08),
			}, {
				RarityText2 = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffc800"),
					Text = "Legendary 95%",
					TextScaled = true,
					AnchorPoint = Vector2.new(1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					Position = UDim2.fromScale(1, 0),
					ZIndex = 5,
					TextSize = 14,
					Size = UDim2.fromScale(0.38, 1),
				}, { UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("791111"),
				}) }),
				RarityText1 = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Gold Legendary 5%",
					TextScaled = true,
					AnchorPoint = Vector2.new(1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					Position = UDim2.fromScale(0.56, 0),
					ZIndex = 5,
					TextSize = 14,
					Size = UDim2.fromScale(0.455, 1),
				}, {
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("ffed66")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("dd4244")),
						}),
						Rotation = 90,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("540c0c"),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					FillDirection = 0,
					HorizontalAlignment = 2,
					SortOrder = 2,
				}),
			}),
			Showcase = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.65, 0.511),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.65, 0.476),
			}, {
				["1"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 1,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Messy",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.552, 0.798),
						ZIndex = 2,
						Image = "rbxassetid://99459346957924",
						Size = UDim2.fromScale(2.014, 1.806),
					}),
					UICorner = Roact.createElement("UICorner", {}),
				}),
				["3"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 3,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.325, 0.697),
						ZIndex = 2,
						Image = "rbxassetid://73261438983442",
						Size = UDim2.fromScale(2.132, 1.774),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Ronaldinyo",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				["5"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 5,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.472, 0.694),
						ZIndex = 2,
						Image = "rbxassetid://108803557836911",
						Size = UDim2.fromScale(2.162, 1.634),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Lewandosky",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				["4"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 4,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.496, 0.722),
						ZIndex = 2,
						Image = "rbxassetid://72571611025819",
						Size = UDim2.fromScale(2.002, 1.959),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Hery Ken",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				["2"] = Roact.createElement("Frame", {
					LayoutOrder = 2,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0.65,
					Position = UDim2.fromScale(0.334, 0.328),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.251, 0.873),
						ZIndex = 2,
						Image = "rbxassetid://87948833803599",
						Size = UDim2.fromScale(2.14, 1.903),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Mbape",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
			}),
			UICorner = Roact.createElement("UICorner", {}),
			Effect = Roact.createElement("ImageLabel", {
				ImageColor3 = Color3.fromHex("ffee00"),
				Image = "rbxassetid://106335669168445",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.147, 0.64),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				Size = UDim2.fromScale(0.635, 1.795),
				ZIndex = 2,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Item = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Elite_Contract_Pack_Full,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.14, 0.768),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.335, 1.322),

				[Roact.Event.MouseEnter] = function()
					TooltipController:SetSize(UDim2.fromScale(0.2, 0.28))
					TooltipController:SetText(
						string.format("%s", CreateHoverDescription(Template.Gacha["SoccerCharacters"]["10"]))
					)
				end,

				[Roact.Event.MouseLeave] = function()
					TooltipController:SetText(nil)
				end,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.6,
			}) }),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3,
			}),
			NameText = Roact.createElement("TextLabel", {
				LayoutOrder = 1,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Elite Contract Pack",
				TextScaled = true,
				AnchorPoint = Vector2.new(1, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 1,
				Position = UDim2.fromScale(0.98, 0.05),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(0.5, 0.12),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 3,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("ff9500")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("672c04")),
					}),
					Rotation = 90,
				}),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffea00")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("ff8000")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("ff0000")),
				}),
				Rotation = 90,
			}),
			Buttons = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.646, 0.96),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 4,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.67, 0.17),
			}, {
				Buy10 = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ff7b23"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x10 Elite Contract Pack" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("ffb625"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x10 -  {MonetizationController:GetPrice("x10 Elite Contract Pack")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				Buy = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffba81"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x1 Elite Contract Pack" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("ffe149"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x1 -  {MonetizationController:GetPrice("x1 Elite Contract Pack")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				Buy5 = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffc73a"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x5 Elite Contract Pack" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("fff569"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x5 -  {MonetizationController:GetPrice("x5 Elite Contract Pack")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					Padding = UDim.new(0.03, 0),
					FillDirection = 0,
					HorizontalAlignment = 0,
					SortOrder = 2,
				}),
			}),
		}),
		["11"] = Roact.createElement("Frame", {
			LayoutOrder = 2,
			Position = UDim2.fromScale(0.025, 0.12),
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Size = UDim2.fromScale(0.95, 0.5),
			ZIndex = 2,
		}, {
			Rarity = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.98, 0.175),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.5, 0.08),
			}, {
				RarityText2 = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffc800"),
					Text = "Legendary 95%",
					TextScaled = true,
					AnchorPoint = Vector2.new(1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					Position = UDim2.fromScale(1, 0),
					ZIndex = 5,
					TextSize = 14,
					Size = UDim2.fromScale(0.38, 1),
				}, { UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("791111"),
				}) }),
				RarityText1 = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Gold Legendary 5%",
					TextScaled = true,
					AnchorPoint = Vector2.new(1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 1,
					Position = UDim2.fromScale(0.56, 0),
					ZIndex = 5,
					TextSize = 14,
					Size = UDim2.fromScale(0.455, 1),
				}, {
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("ffed66")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("dd4244")),
						}),
						Rotation = 90,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("540c0c"),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					FillDirection = 0,
					HorizontalAlignment = 2,
					SortOrder = 2,
				}),
			}),
			Showcase = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.65, 0.511),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.65, 0.476),
			}, {
				["1"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 1,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Ronalde",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.37, 0.641),
						ZIndex = 2,
						Image = "rbxassetid://125143934207344",
						Size = UDim2.fromScale(2.014, 1.806),
					}),
					UICorner = Roact.createElement("UICorner", {}),
				}),
				["3"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 3,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.457, 0.789),
						ZIndex = 2,
						Image = "rbxassetid://94690768578334",
						Size = UDim2.fromScale(2.063, 1.545),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Bekam",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				["5"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 5,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.472, 0.784),
						ZIndex = 2,
						Image = "rbxassetid://140613468384529",
						Size = UDim2.fromScale(2.162, 1.634),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Haland",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				["4"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BackgroundTransparency = 0.65,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					LayoutOrder = 4,
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.528, 0.736),
						ZIndex = 2,
						Image = "rbxassetid://124760856293952",
						Size = UDim2.fromScale(1.769, 1.685),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Dembala",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
				["2"] = Roact.createElement("Frame", {
					LayoutOrder = 2,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0.65,
					Position = UDim2.fromScale(0.334, 0.328),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.8, 0.9),
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.8,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.461, 0.786),
						ZIndex = 2,
						Image = "rbxassetid://131731419877425",
						Size = UDim2.fromScale(2.14, 1.584),
					}),
					NameText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "Naymar",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.95),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.95, 0.15),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("ffef10")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("ff9500")),
							}),
							Rotation = 90,
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("875e00"),
							Thickness = 1.5,
						}),
					}),
				}),
			}),
			UICorner = Roact.createElement("UICorner", {}),
			Effect = Roact.createElement("ImageLabel", {
				ImageColor3 = Color3.fromHex("ffee00"),
				Image = "rbxassetid://106335669168445",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.147, 0.64),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				Size = UDim2.fromScale(0.635, 1.795),
				ZIndex = 2,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Item = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Superstar_Vault_Full,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.14, 0.768),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.335, 1.322),

				[Roact.Event.MouseEnter] = function()
					TooltipController:SetSize(UDim2.fromScale(0.2, 0.28))
					TooltipController:SetText(
						string.format("%s", CreateHoverDescription(Template.Gacha["SoccerCharacters"]["11"]))
					)
				end,

				[Roact.Event.MouseLeave] = function()
					TooltipController:SetText(nil)
				end,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.6,
			}) }),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 3,
			}),
			NameText = Roact.createElement("TextLabel", {
				LayoutOrder = 1,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Superstar Vault Pack",
				TextScaled = true,
				AnchorPoint = Vector2.new(1, 0),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 1,
				Position = UDim2.fromScale(0.98, 0.05),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(0.5, 0.12),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 3,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("ff9500")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("672c04")),
					}),
					Rotation = 90,
				}),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffea00")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("ff8000")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("ff0000")),
				}),
				Rotation = 90,
			}),
			Buttons = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.646, 0.96),
				BorderColor3 = Color3.fromHex("000000"),
				ZIndex = 4,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.67, 0.17),
			}, {
				Buy10 = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ff7b23"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x10 Superstar Vault" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("ffb625"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x10 -  {MonetizationController:GetPrice("x10 Superstar Vault")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				Buy = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffba81"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x1 Superstar Vault" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("ffe149"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x1 -  {MonetizationController:GetPrice("x1 Superstar Vault")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				Buy5 = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					Position = UDim2.fromScale(0.26, 0.82),
					Size = UDim2.fromScale(0.3, 1),
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffc73a"),

					[Roact.Event.MouseButton1Click] = function()
						StoreController:BuyItem({ name = "x5 Superstar Vault" })
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("fff569"),
						Thickness = 2,
					}),
					PriceText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `x5 -  {MonetizationController:GetPrice("x5 Superstar Vault")}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 3,
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.6),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("a3690c"),
							Thickness = 1.5,
						}),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					Padding = UDim.new(0.03, 0),
					FillDirection = 0,
					HorizontalAlignment = 0,
					SortOrder = 2,
				}),
			}),
		}),
		List = Roact.createElement("UIListLayout", {
			SortOrder = 2,
			HorizontalAlignment = 0,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Elite = RoactHooks.new(Roact)(Elite)
return Elite
