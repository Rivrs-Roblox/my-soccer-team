local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local DataCacheController = Knit.GetController("DataCacheController")
local AccessoryController = Knit.GetController("AccessoryController")

local Template = DataCacheController:GetFile("Template")

local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)
local AccessoryConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.AccessoryConstants)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)
local AccessoryActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.AccessoryActions)

local UI = DataCacheController:GetFile("Images")

local AccessoryCard = require(script.Parent.AccessoryCard)

function Accessories(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)
	local AccessoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.AccessoryReducer
	end)

	local selectedSlot = AccessoryReducer.SelectedSlot
	local charId
	if selectedSlot and TeamReducer.EquippedSoccerCharacters then
		charId = TeamReducer.EquippedSoccerCharacters[selectedSlot]
			or TeamReducer.EquippedSoccerCharacters[tostring(selectedSlot)]
	end

	local currentCharacterData
	if charId and InventoryReducer.SoccerCharacters then
		currentCharacterData = InventoryReducer.SoccerCharacters[charId]
			or InventoryReducer.SoccerCharacters[tostring(charId)]
	end

	local AccessoriesCards = {}
	local numCards = 0
	if InventoryReducer.Accessories then
		for id, accessory in pairs(InventoryReducer.Accessories) do
			local templateData = Template.Accessories[accessory.Name]
			if templateData then
				local shouldShow = true
				local isEquippedToCurrent = false

				if accessory.Equipped then
					shouldShow = false
					if currentCharacterData and currentCharacterData.Accessories then
						for _, equippedAccessoryId in pairs(currentCharacterData.Accessories) do
							if tostring(equippedAccessoryId) == tostring(id) then
								shouldShow = true
								isEquippedToCurrent = true
								break
							end
						end
					end
				end

				if shouldShow then
					if
						UIReducer.CurrentAccessoriesUI == AccessoryConstants.All
						or templateData.Type == UIReducer.CurrentAccessoriesUI
					then
						local shoot = templateData.Additions and templateData.Additions.Shoot or 0
						local dribble = templateData.Additions and templateData.Additions.Dribble or 0
						local pass = templateData.Additions and templateData.Additions.Pass or 0
						local totalStat = shoot + dribble + pass
						local statScore = math.round(totalStat * 100)
						local statOffset = (10000 - statScore) * 100
						local rarityPriority = Template.RarityPriority[templateData.Rarity or "Common"] or 100

						local order = (isEquippedToCurrent and 0 or 10000000)
							+ statOffset
							+ rarityPriority
							+ (tonumber(id) or 0)

						AccessoriesCards[id] = AccessoryCard({
							id = id,
							name = templateData.Name,
							type = templateData.Type,
							image = templateData.Image or UI[templateData.Name] or "",
							equipped = isEquippedToCurrent,
							rarity = templateData.Rarity or "Common",
							pass = pass,
							shoot = shoot,
							dribble = dribble,
							order = order,
						})
						numCards += 1
					end
				end
			end
		end
	end

	local rows = math.max(1, math.ceil(numCards / 3))
	local canvasY = math.max(1, rows * 0.45 + 0.05)

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentCustomizeUI == CustomizeConstants.Accessories,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BorderColor3 = Color3.fromHex("000000"),
		ZIndex = 3,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
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
			TitleText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Accessories",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				Position = UDim2.fromScale(0.549, 1),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(0.8, 1),
				LayoutOrder = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(20, 55, 88),
					Thickness = 2,
				}),
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://124847512307439",
				Size = UDim2.fromScale(1.2, 1.2),
				LayoutOrder = 1,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.625),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.95, 0.699),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.02, 0),
				FillDirection = 0,
			}),
			Viewport = Roact.createElement("ViewportFrame", {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.721, 0.007),
				BorderColor3 = Color3.fromHex("000000"),
				Size = UDim2.fromScale(0.35, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
			}, {
				["1"] = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.15, 0.89),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(0.25, 0.25),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(AccessoryActions.setSelectedSlot(1))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "1",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2f37a5")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("13133d")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1e88d9"),
						Thickness = 2,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://76558147588196",
						Size = UDim2.fromScale(0.65, 0.65),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 10),
				}),
				["3"] = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.85, 0.89),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(0.25, 0.25),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(AccessoryActions.setSelectedSlot(3))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "3",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2f37a5")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("13133d")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://76558147588196",
						Size = UDim2.fromScale(0.65, 0.65),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1e88d9"),
						Thickness = 2,
					}),
				}),
				["2"] = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.89),
					BorderColor3 = Color3.fromHex("000000"),
					Size = UDim2.fromScale(0.25, 0.25),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Down] = function()
						Sound:PlaySound("UI_Click")
						Store:dispatch(AccessoryActions.setSelectedSlot(2))
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "2",
						AnchorPoint = Vector2.new(0.5, 1),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.96),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.91, 0.25),
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2f37a5")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("13133d")),
						}),
						Rotation = 90,
					}),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://76558147588196",
						Size = UDim2.fromScale(0.65, 0.65),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1e88d9"),
						Thickness = 2,
					}),
				}),
			}),
			Wardrobe = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("000000"),
				BackgroundTransparency = 0.6,
				Position = UDim2.fromScale(0.292, 0.62),
				BorderColor3 = Color3.fromHex("000000"),
				LayoutOrder = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.58, 1),
				ZIndex = 2,
			}, {
				Scroll = Roact.createElement("ScrollingFrame", {
					AutomaticCanvasSize = Enum.AutomaticSize.None,
					ScrollBarThickness = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.497),
					Size = UDim2.fromScale(0.95, 0.712),
					ScrollBarImageTransparency = 0.32,
					BorderSizePixel = 0,
					CanvasSize = UDim2.fromScale(0, canvasY),
				}, {
					Padding = Roact.createElement("UIPadding", {
						PaddingTop = UDim.new(0.03, 0),
						PaddingLeft = UDim.new(0.03, 0),
					}),
					Grid = Roact.createElement("UIGridLayout", {
						FillDirectionMaxCells = 3,
						SortOrder = 2,
						CellSize = UDim2.fromScale(0.3, 0.4 / canvasY),
						CellPadding = UDim2.fromScale(0.03, 0.05 / canvasY),
					}),
					Roact.createFragment(AccessoriesCards),
				}),
				UICorner = Roact.createElement("UICorner", {}),
				Top = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.02),
					BorderColor3 = Color3.fromHex("000000"),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.95, 0.1),
				}, {
					Foot = Roact.createElement("ImageButton", {
						LayoutOrder = 4,
						Size = UDim2.fromScale(0.195, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,
						BackgroundColor3 = if UIReducer.CurrentAccessoriesUI == AccessoryConstants.Foot
							then Color3.fromHex("ff6734")
							else Color3.fromHex("3b65a3"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							Store:dispatch(UIActions.setCurrentAccessoriesUI(AccessoryConstants.Foot))
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
							ButtonText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("fafafa"),
								Text = "Foot",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.576, 0.5),
								TextSize = 14,
								ZIndex = 5,
								TextScaled = true,
								Size = UDim2.fromScale(0.85, 0.5),
							}),
						}),
					}),
					Head = Roact.createElement("ImageButton", {
						LayoutOrder = 1,
						Size = UDim2.fromScale(0.195, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,
						BackgroundColor3 = if UIReducer.CurrentAccessoriesUI == AccessoryConstants.Head
							then Color3.fromHex("ff6734")
							else Color3.fromHex("3b65a3"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							Store:dispatch(UIActions.setCurrentAccessoriesUI(AccessoryConstants.Head))
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
							ButtonText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("fafafa"),
								Text = "Head",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.576, 0.5),
								TextSize = 14,
								ZIndex = 5,
								TextScaled = true,
								Size = UDim2.fromScale(0.85, 0.5),
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
					All = Roact.createElement("ImageButton", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						Size = UDim2.fromScale(0.195, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = if UIReducer.CurrentAccessoriesUI == AccessoryConstants.All
							then Color3.fromHex("ff6734")
							else Color3.fromHex("3b65a3"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							Store:dispatch(UIActions.setCurrentAccessoriesUI(AccessoryConstants.All))
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
							ButtonText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("fafafa"),
								Text = "All",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.576, 0.5),
								TextSize = 14,
								ZIndex = 5,
								TextScaled = true,
								Size = UDim2.fromScale(0.85, 0.5),
							}),
						}),
					}),
					Hand = Roact.createElement("ImageButton", {
						LayoutOrder = 3,
						Size = UDim2.fromScale(0.195, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,
						BackgroundColor3 = if UIReducer.CurrentAccessoriesUI == AccessoryConstants.Hand
							then Color3.fromHex("ff6734")
							else Color3.fromHex("3b65a3"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							Store:dispatch(UIActions.setCurrentAccessoriesUI(AccessoryConstants.Hand))
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
							ButtonText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("fafafa"),
								Text = "Hand",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.576, 0.5),
								TextSize = 14,
								ZIndex = 5,
								TextScaled = true,
								Size = UDim2.fromScale(0.85, 0.5),
							}),
						}),
					}),
					Body = Roact.createElement("ImageButton", {
						LayoutOrder = 2,
						Size = UDim2.fromScale(0.195, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,
						BackgroundColor3 = if UIReducer.CurrentAccessoriesUI == AccessoryConstants.Body
							then Color3.fromHex("ff6734")
							else Color3.fromHex("3b65a3"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							Store:dispatch(UIActions.setCurrentAccessoriesUI(AccessoryConstants.Body))
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
							ButtonText = Roact.createElement("TextLabel", {
								TextWrapped = true,
								TextColor3 = Color3.fromHex("fafafa"),
								Text = "Body",
								AnchorPoint = Vector2.new(0.5, 0.5),
								FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.576, 0.5),
								TextSize = 14,
								ZIndex = 5,
								TextScaled = true,
								Size = UDim2.fromScale(0.85, 0.5),
							}),
						}),
					}),
				}),
				Bottom = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.98),
					BorderColor3 = Color3.fromHex("000000"),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(0.95, 0.1),
				}, {
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.02, 0),
						FillDirection = 0,
					}),
					EquipBest = Roact.createElement("ImageButton", {
						LayoutOrder = 3,
						Size = UDim2.fromScale(0.4, 1),
						Position = UDim2.fromScale(0.348, 0.93),
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,

						[Roact.Event.MouseButton1Down] = function()
							Sound:PlaySound("UI_Click")
							local selectedSlot = Store:getState().AccessoryReducer.SelectedSlot
							local charId = Store:getState().TeamReducer.EquippedSoccerCharacters[selectedSlot]
								or Store:getState().TeamReducer.EquippedSoccerCharacters[tostring(selectedSlot)]
							if charId then
								AccessoryController:EquipBest(charId)
							end
						end,
					}, {
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 2),
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
				}),
			}),
		}),
	})
end

Accessories = RoactHooks.new(Roact)(Accessories)
return Accessories
