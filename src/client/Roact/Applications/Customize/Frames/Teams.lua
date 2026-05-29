local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local DataCacheController = Knit.GetController("DataCacheController")
local TeamController = Knit.GetController("TeamController")
local UIController = Knit.GetController("UIController")

local UI = DataCacheController:GetFile("Images")
local Template = DataCacheController:GetFile("Template")
local Colors = DataCacheController:GetFile("Colors")

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local TeamActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.TeamActions)

function Teams(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	local function getSlotData(slotIndex)
		local charId = TeamReducer.EquippedSoccerCharacters
			and (
				TeamReducer.EquippedSoccerCharacters[slotIndex]
				or TeamReducer.EquippedSoccerCharacters[tostring(slotIndex)]
			)
		local charData = charId
			and InventoryReducer.SoccerCharacters
			and (InventoryReducer.SoccerCharacters[charId] or InventoryReducer.SoccerCharacters[tostring(charId)])
		local templateData = charData and Template.SoccerCharacters[charData.Name]

		if not charData or not templateData then
			return {
				Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
				Pass = "0.0",
				Shoot = "0.0",
				Dribble = "0.0",
				Name = "Empty",
				Stars = 1,
				Color = Color3.fromHex("4688eb"),
				FieldStrokeColor = Color3.fromHex("49b9ff"),
				RarityColor = Color3.fromHex("ffffff"),
			}
		end
		return {
			Image = UI[charData.Name] or "rbxasset://textures/ui/GuiImagePlaceholder.png",
			Pass = string.format("%.1f", templateData.Multipliers.Pass),
			Shoot = string.format("%.1f", templateData.Multipliers.Shoot),
			Dribble = string.format("%.1f", templateData.Multipliers.Dribble),
			Name = templateData.Name,
			Stars = charData.Level or 1,
			Color = Color3.fromHex("4688eb"),
			FieldStrokeColor = Color3.fromHex("49b9ff"),
			RarityColor = Colors[templateData.Rarity] or Color3.fromHex("ffffff"),
		}
	end

	local s1 = getSlotData(1)
	local s2 = getSlotData(2)
	local s3 = getSlotData(3)

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentCustomizeUI == CustomizeConstants.Teams,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BorderColor3 = Color3.fromHex("000000"),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		Players = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.8,
			Position = UDim2.fromScale(0.292, 0.62),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.491, 0.68),
			ZIndex = 2,
		}, {
			UICorner = Roact.createElement("UICorner", {}),
			EquipBest = Roact.createElement("ImageButton", {
				LayoutOrder = 3,
				Size = UDim2.fromScale(0.6, 0.12),
				Position = UDim2.fromScale(0.5, 0.9),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,

				[Roact.Event.MouseButton1Click] = function()
					Sound:PlaySound("UI_Click")
					TeamController:EquipBest()
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("3b9dda"),
					Thickness = 2,
				}),
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("30b6ef")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("143eb0")),
					}),
					Rotation = 90,
				}),
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Equip Best",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.9, 0.6),
				}),
			}),
			Choose = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.05),
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.92, 0.75),
			}, {
				["1"] = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 0.3),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(TeamActions.setSelectedSlot(1))
						UIController:ShowFrame({ frame = FramesConstants.SelectCharacter })
					end,
				}, {
					Stats = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.65),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.55, 0.23),
					}, {
						UIListLayout = Roact.createElement("UIListLayout", {
							FillDirection = 0,
							HorizontalAlignment = 2,
							SortOrder = 2,
						}),
						Passing = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "PAS",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s1.Pass,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Shooting = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "SHO",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s1.Shoot,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Dribble = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "DRI",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s1.Dribble,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					Mask = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						Position = UDim2.fromScale(0, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 3,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.25, 1),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
							}),
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0, 0),
								NumberSequenceKeypoint.new(0.413, 0, 0),
								NumberSequenceKeypoint.new(1, 1, 0),
							}),
						}),
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 6),
						}),
					}),
					NumberText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "1",
						TextScaled = true,
						AnchorPoint = Vector2.new(0, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.02, 0.5),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.1, 0.7),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = s1.Color,
							Thickness = 2,
						}),
					}),
					Stars = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.2),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.123, 0.3),
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
							ScaleType = 3,
							Size = UDim2.fromScale(1, 1),
							ZIndex = 2,
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						NumberText = Roact.createElement("TextLabel", {
							LayoutOrder = 2,
							TextWrapped = true,
							TextColor3 = Color3.fromHex("ffffff"),
							Text = tostring(s1.Stars),
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							TextScaled = true,
							Position = UDim2.fromScale(0.5, 0.5),
							TextSize = 14,
							Size = UDim2.fromScale(0.3, 1),
							ZIndex = 2,
						}, {
							UIStroke = Roact.createElement("UIStroke", {
								Color = Color3.fromHex("191919"),
								Thickness = 1.5,
							}),
						}),
					}),
					Player = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s1.Image,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.258, 0.7),
						ScaleType = 3,
						Size = UDim2.fromScale(1.7, 1.7),
						ZIndex = 2,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
						}),
						Rotation = 90,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = s1.Color,
						Thickness = 2,
					}),
					NameText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = s1.RarityColor,
						Text = s1.Name,
						TextScaled = true,
						AnchorPoint = Vector2.new(1, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						Position = UDim2.fromScale(0.86, 0.2),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.457, 0.25),
					}),
				}),
				["2"] = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 0.3),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(TeamActions.setSelectedSlot(2))
						UIController:ShowFrame({ frame = FramesConstants.SelectCharacter })
					end,
				}, {
					Stats = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.65),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.55, 0.23),
					}, {
						UIListLayout = Roact.createElement("UIListLayout", {
							FillDirection = 0,
							HorizontalAlignment = 2,
							SortOrder = 2,
						}),
						Passing = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "PAS",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s2.Pass,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Shooting = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "SHO",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s2.Shoot,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Dribble = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "DRI",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s2.Dribble,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					Mask = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						Position = UDim2.fromScale(0, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 3,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.25, 1),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
							}),
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0, 0),
								NumberSequenceKeypoint.new(0.413, 0, 0),
								NumberSequenceKeypoint.new(1, 1, 0),
							}),
						}),
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 6),
						}),
					}),
					NumberText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "2",
						TextScaled = true,
						AnchorPoint = Vector2.new(0, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.02, 0.5),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.1, 0.7),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = s2.Color,
							Thickness = 2,
						}),
					}),
					Stars = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.2),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.123, 0.3),
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
							ScaleType = 3,
							Size = UDim2.fromScale(1, 1),
							ZIndex = 2,
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						NumberText = Roact.createElement("TextLabel", {
							LayoutOrder = 2,
							TextWrapped = true,
							TextColor3 = Color3.fromHex("ffffff"),
							Text = tostring(s2.Stars),
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							TextScaled = true,
							Position = UDim2.fromScale(0.5, 0.5),
							TextSize = 14,
							Size = UDim2.fromScale(0.3, 1),
							ZIndex = 2,
						}, {
							UIStroke = Roact.createElement("UIStroke", {
								Color = Color3.fromHex("191919"),
								Thickness = 1.5,
							}),
						}),
					}),
					Player = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s2.Image,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.258, 0.7),
						ScaleType = 3,
						Size = UDim2.fromScale(1.7, 1.7),
						ZIndex = 2,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
						}),
						Rotation = 90,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = s2.Color,
						Thickness = 2,
					}),
					NameText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = s2.RarityColor,
						Text = s2.Name,
						TextScaled = true,
						AnchorPoint = Vector2.new(1, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						Position = UDim2.fromScale(0.86, 0.2),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.457, 0.25),
					}),
				}),
				["3"] = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					ClipsDescendants = true,
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(1, 0.3),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(TeamActions.setSelectedSlot(3))
						UIController:ShowFrame({ frame = FramesConstants.SelectCharacter })
					end,
				}, {
					Stats = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.65),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.55, 0.23),
					}, {
						UIListLayout = Roact.createElement("UIListLayout", {
							FillDirection = 0,
							HorizontalAlignment = 2,
							SortOrder = 2,
						}),
						Passing = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "PAS",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s3.Pass,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Shooting = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "SHO",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s3.Shoot,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
						Dribble = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.3, 0.4),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("ffffff"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(0.33, 1),
						}, {
							UIListLayout = Roact.createElement("UIListLayout", {
								FillDirection = 0,
								HorizontalAlignment = 0,
								SortOrder = 2,
							}),
							StatText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = "DRI",
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.5, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
							NumberText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								TextStrokeColor3 = Color3.fromHex("ffffff"),
								Text = s3.Dribble,
								BorderColor3 = Color3.fromHex("000000"),
								Size = UDim2.fromScale(0.4, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Font = 45,
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0),
								TextScaled = true,
								TextSize = 14,
								BorderSizePixel = 0,
								BackgroundColor3 = Color3.fromHex("ffffff"),
								ZIndex = 2,
							}),
						}),
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					Mask = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						Position = UDim2.fromScale(0, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 3,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.25, 1),
					}, {
						UIGradient = Roact.createElement("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
							}),
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0, 0),
								NumberSequenceKeypoint.new(0.413, 0, 0),
								NumberSequenceKeypoint.new(1, 1, 0),
							}),
						}),
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 6),
						}),
					}),
					NumberText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = "3",
						TextScaled = true,
						AnchorPoint = Vector2.new(0, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.02, 0.5),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.1, 0.7),
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = s3.Color,
							Thickness = 2,
						}),
					}),
					Stars = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.99, 0.2),
						BorderColor3 = Color3.fromHex("000000"),
						ZIndex = 10,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(0.123, 0.3),
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
							ScaleType = 3,
							Size = UDim2.fromScale(1, 1),
							ZIndex = 2,
						}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
						NumberText = Roact.createElement("TextLabel", {
							LayoutOrder = 2,
							TextWrapped = true,
							TextColor3 = Color3.fromHex("ffffff"),
							Text = tostring(s3.Stars),
							AnchorPoint = Vector2.new(0.5, 0.5),
							FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
							BackgroundTransparency = 1,
							TextXAlignment = 0,
							TextScaled = true,
							Position = UDim2.fromScale(0.5, 0.5),
							TextSize = 14,
							Size = UDim2.fromScale(0.3, 1),
							ZIndex = 2,
						}, {
							UIStroke = Roact.createElement("UIStroke", {
								Color = Color3.fromHex("191919"),
								Thickness = 1.5,
							}),
						}),
					}),
					Player = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s3.Image,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.258, 0.7),
						ScaleType = 3,
						Size = UDim2.fromScale(1.7, 1.7),
						ZIndex = 2,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2a4568")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("0a0e27")),
						}),
						Rotation = 90,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = s3.Color,
						Thickness = 2,
					}),
					NameText = Roact.createElement("TextLabel", {
						LayoutOrder = 1,
						TextWrapped = true,
						TextColor3 = s3.RarityColor,
						Text = s3.Name,
						TextScaled = true,
						AnchorPoint = Vector2.new(1, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 1,
						Position = UDim2.fromScale(0.86, 0.2),
						ZIndex = 10,
						TextSize = 14,
						Size = UDim2.fromScale(0.457, 0.25),
					}),
				}),
				List = Roact.createElement("UIListLayout", {
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.04, 0),
				}),
			}),
		}),
		Title = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.04, 0.08),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.55, 0.09),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				FillDirection = 0,
				Padding = UDim.new(0.02, 0),
				SortOrder = 2,
			}),
			TitleText = Roact.createElement(
				"TextLabel",
				{
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Team Management",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 1),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 0,
					Position = UDim2.fromScale(0.588, 1),
					ZIndex = 5,
					TextSize = 14,
					Size = UDim2.fromScale(0.891, 1),
					LayoutOrder = 2,
				},
				{
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(20, 55, 88),
						Thickness = 2,
					}),
				}
			),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = UI.Teams,
				Size = UDim2.fromScale(1.2, 1.2),
				LayoutOrder = 1,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Position = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.8,
			Position = UDim2.fromScale(0.752, 0.62),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.405, 0.68),
			ZIndex = 2,
		}, {
			UICorner = Roact.createElement("UICorner", {}),
			Field = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://93920580421880",
				Size = UDim2.fromScale(0.92, 0.92),
			}, {
				["1"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.8),
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 0.05),
				}, {
					["1"] = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s1.Image,
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("818181"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1.2, 1.2),
					}, {
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
						Player = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("1d59b3"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1.5, 1.5),
							ZIndex = 2,
						}, {
							UICorner = Roact.createElement("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
							Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
							UIStroke = Roact.createElement("UIStroke", {
								Color = s1.FieldStrokeColor,
								Thickness = 3,
							}),
							NumberText = Roact.createElement("TextLabel", {
								LayoutOrder = 1,
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								Text = "1",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0.5),
								TextScaled = true,
								ZIndex = 10,
								TextSize = 14,
								Size = UDim2.fromScale(0.9, 0.9),
							}, {
								UIStroke = Roact.createElement("UIStroke", {
									Thickness = 2,
								}),
							}),
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("ffffff"),
							Thickness = 3,
						}),
					}),
					List = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.1, 0),
						FillDirection = 0,
					}),
				}),
				TitleText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Enemy Goalie",
					AnchorPoint = Vector2.new(0.5, 0),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.918),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.5, 0.08),
				}, { UIStroke = Roact.createElement("UIStroke", {
					Thickness = 2,
				}) }),
				["3"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.45),
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 0.05),
				}, {
					["3"] = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s3.Image,
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1.2, 1.2),
					}, {
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
						Player = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("1d59b3"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1.5, 1.5),
							ZIndex = 2,
						}, {
							UICorner = Roact.createElement("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
							Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
							UIStroke = Roact.createElement("UIStroke", {
								Color = s3.FieldStrokeColor,
								Thickness = 3,
							}),
							NumberText = Roact.createElement("TextLabel", {
								LayoutOrder = 1,
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								Text = "3",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0.5),
								TextScaled = true,
								ZIndex = 10,
								TextSize = 14,
								Size = UDim2.fromScale(0.9, 0.9),
							}, { UIStroke = Roact.createElement("UIStroke", {
								Thickness = 2,
							}) }),
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("ffffff"),
							Thickness = 3,
						}),
					}),
					List = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.1, 0),
						FillDirection = 0,
					}),
				}),
				["2"] = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.67),
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 0.05),
				}, {
					["2"] = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = s2.Image,
						BorderColor3 = Color3.fromHex("000000"),
						BackgroundColor3 = Color3.fromHex("818181"),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1.2, 1.2),
					}, {
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
						Player = Roact.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BorderColor3 = Color3.fromHex("000000"),
							BackgroundColor3 = Color3.fromHex("1d59b3"),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1.5, 1.5),
							ZIndex = 2,
						}, {
							UICorner = Roact.createElement("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
							Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
							UIStroke = Roact.createElement("UIStroke", {
								Color = s2.FieldStrokeColor,
								Thickness = 3,
							}),
							NumberText = Roact.createElement("TextLabel", {
								LayoutOrder = 1,
								TextWrapped = true,
								TextColor3 = Color3.fromHex("ffffff"),
								Text = "2",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.5, 0.5),
								TextScaled = true,
								ZIndex = 10,
								TextSize = 14,
								Size = UDim2.fromScale(0.9, 0.9),
							}, {
								UIStroke = Roact.createElement("UIStroke", {
									Thickness = 2,
								}),
							}),
						}),
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromHex("ffffff"),
							Thickness = 3,
						}),
					}),
					List = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.1, 0),
						FillDirection = 0,
					}),
				}),
				Ratio = Roact.createElement("UIAspectRatioConstraint", {
					AspectRatio = 0.7,
				}),
			}),
		}),
	})
end

Teams = RoactHooks.new(Roact)(Teams)
return Teams
