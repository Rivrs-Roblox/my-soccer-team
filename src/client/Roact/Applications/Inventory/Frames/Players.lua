local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local InventoryConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.InventoryConstants)
local InventoryActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.InventoryActions)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

local SoccerCharactersService = Knit.GetService("SoccerCharactersService")

local DataCacheController = Knit.GetController("DataCacheController")
local NotificationController = Knit.GetController("NotificationController")
local UIController = Knit.GetController("UIController")

local Template = DataCacheController:GetFile("Template")
local UI = DataCacheController:GetFile("Images")

local Helpers = ReplicatedStorage.Shared.Helpers
local GetStats = require(Helpers.SoccerCharacters.GetStats)

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

local SoccerCharacterCard = require(script.Parent.SoccerCharacterCard)

function Players(_, hooks)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)
	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)
	local currentUI = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer.CurrentUI
	end)

	local searchText, setSearchText = hooks.useState("")

	hooks.useEffect(function()
		if currentUI ~= FramesConstants.Inventory or InventoryReducer.Inventory ~= InventoryConstants.SoccerCharacters then
			setSearchText("")
			Store:dispatch(InventoryActions.setDeletingCharacters(false))
		end
	end, { currentUI or "", InventoryReducer.Inventory })

	local equippedIds = hooks.useMemo(function()
		local ids = {}
		if TeamReducer and TeamReducer.EquippedSoccerCharacters then
			for _, id in pairs(TeamReducer.EquippedSoccerCharacters) do
				ids[tostring(id)] = true
			end
		end
		return ids
	end, { TeamReducer and TeamReducer.EquippedSoccerCharacters })

	local memoizedData = hooks.useMemo(function()
		local cards = {}
		local count = 0
		local owned = 0

		if InventoryReducer.SoccerCharacters then
			for id, charData in pairs(InventoryReducer.SoccerCharacters) do
				local templateData = Template.SoccerCharacters[charData.Name]
				if templateData then
					owned += 1

					if searchText ~= "" then
						if not string.find(string.lower(templateData.Name), string.lower(searchText), 1, true) then
							continue
						end
					end

					count += 1
					local stats = GetStats(charData, InventoryReducer.Accessories)

					local isEquipped = equippedIds[tostring(id)] or false

					cards[id] = Roact.createElement(SoccerCharacterCard, {
						id = id,
						name = templateData.DisplayName or templateData.Name,
						shoot = stats.Shoot,
						dribble = stats.Dribble,
						pass = stats.Pass,
						rarity = templateData.Rarity or "Common",
						image = UI[templateData.Name] or "",
						level = charData.Level,
						card = UI["Card_" .. string.gsub(templateData.Rarity or "Common", " ", "_")],
						cardMask = UI["Card_" .. string.gsub(templateData.Rarity or "Common", " ", "_") .. "_Mask"],
						order = (isEquipped and 0 or 1000000)
							+ (Template.RarityPriority[templateData.Rarity or "Common"] or 100) * 1000
							+ count,
						equipped = isEquipped,
						deleting = InventoryReducer.DeletedCharacters[tostring(id)] ~= nil,
						nationality = templateData.Nationality,
						onClick = function()
							if InventoryReducer.DeletingCharacters then
								if isEquipped then
									NotificationController:Notify({
										text = "Cannot delete equipped characters.",
										type = "ERROR",
										tag = "Inventory",
									})
									return
								end
								if InventoryReducer.DeletedCharacters[tostring(id)] then
									Store:dispatch(InventoryActions.removeDeletedCharacter(id))
								else
									Store:dispatch(InventoryActions.addDeletedCharacter(id))
								end
							end
						end,
					})
				end
			end
		end
		
		return { cards = cards, count = count, owned = owned }
	end, {
		InventoryReducer.SoccerCharacters,
		InventoryReducer.Accessories,
		InventoryReducer.DeletingCharacters,
		InventoryReducer.DeletedCharacters,
		equippedIds,
		searchText
	})

	local SoccerCharactersCards = memoizedData.cards
	local numCards = memoizedData.count
	local totalOwned = memoizedData.owned
	local rows = math.max(1, math.ceil(numCards / 5))
	local desiredCellHeight = 0.43
	local desiredCellPadding = 0
	local canvasScaleY = math.max(1, (rows * desiredCellHeight) + ((rows - 1) * desiredCellPadding) + 0.04)

	return Roact.createElement("Frame", {
		Visible = InventoryReducer.Inventory == InventoryConstants.SoccerCharacters,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Scroll = Roact.createElement("ScrollingFrame", {
			CanvasSize = UDim2.fromScale(0, canvasScaleY),
			ScrollBarThickness = 8,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.559),
			ScrollingDirection = 2,
			ZIndex = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.95, 0.568),
		}, {
			Grid = Roact.createElement("UIGridLayout", {
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.18, desiredCellHeight / canvasScaleY),
				FillDirectionMaxCells = 5,
				CellPadding = UDim2.fromScale(0.01, desiredCellPadding / canvasScaleY),
				HorizontalAlignment = 0,
			}),
			Roact.createFragment(SoccerCharactersCards),
		}),
		EmptyText = Roact.createElement("TextLabel", {
			Visible = numCards == 0,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(20, 55, 88),
			TextTransparency = 0.3,
			Text = "You have nothing to show here yet ):",
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.55),
			TextSize = 14,
			ZIndex = 2,
			TextScaled = true,
			Size = UDim2.fromScale(0.8, 0.2),
		}),
		Bottom = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.93),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.9, 0.1),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.02, 0),
				FillDirection = 0,
			}),
			Delete = Roact.createElement("ImageButton", {
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.2, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,

				[Roact.Event.MouseButton1Down] = function()
					Sound:PlaySound("UI_Click")
					if InventoryReducer.DeletingCharacters then
						local deletedCount = 0
						for id, _ in pairs(InventoryReducer.DeletedCharacters or {}) do
							SoccerCharactersService:DeleteCharacter(id)
							deletedCount += 1
						end
						Store:dispatch(InventoryActions.setDeletingCharacters(false))
					else
						Store:dispatch(InventoryActions.setDeletingCharacters(true))
					end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("da5b5d"),
					Thickness = 2,
				}),
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("ff3134")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("822b2d")),
					}),
					Rotation = 90,
				}),
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = InventoryReducer.DeletingCharacters and "Confirm" or "Delete",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.9, 0.55),
				}),
			}),
			SearchBar = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.67, 0),
				LayoutOrder = 1,
				ZIndex = 10,
				BackgroundColor3 = Color3.fromHex("254167"),
				Size = UDim2.fromScale(0.78, 1),
			}, {
				Storage = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(0.95, 0.5),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.2, 1),
				}, {
					Corner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(2, 0),
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.02, 0),
						FillDirection = 0,
					}),
					Plus = Roact.createElement("ImageButton", {
						LayoutOrder = 3,
						ScaleType = 3,
						BorderColor3 = Color3.fromHex("000000"),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = "rbxassetid://98999428594161",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.983, 0.5),
						Size = UDim2.fromScale(0.6, 0.6),
						ImageColor3 = Color3.fromHex("c4d6ff"),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 11,

						[Roact.Event.MouseButton1Click] = function()
							Sound:PlaySound("UI_Click")
							UIController:ShowFrame({ frame = FramesConstants.Store })
						end,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = "rbxassetid://96088986090549",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.186, 0.5),
						LayoutOrder = 1,
						ScaleType = 3,
						Size = UDim2.fromScale(0.7, 0.7),
						ZIndex = 11,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					AmoutText = Roact.createElement("TextLabel", {
						LayoutOrder = 2,
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						Text = `{totalOwned}/{InventoryReducer.MaxStored or 75}`,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.612, 0.5),
						TextScaled = true,
						TextSize = 14,
						Size = UDim2.fromScale(0.7, 0.5),
						ZIndex = 11,
					}),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("1d243b"),
					Thickness = 2,
				}),
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = "rbxassetid://108045196460145",
					BackgroundTransparency = 1,
					ImageTransparency = 0.5,
					Position = UDim2.fromScale(0.06, 0.5),
					ScaleType = 3,
					Size = UDim2.fromScale(0.6, 0.6),
					ZIndex = 11,
				}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
				TextBox = Roact.createElement("TextBox", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					TextTransparency = 0.5,
					Text = searchText,
					PlaceholderColor3 = Color3.fromHex("ffffff"),
					AnchorPoint = Vector2.new(0, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 0,
					Position = UDim2.fromScale(0.12, 0.5),
					PlaceholderText = "Search players...",
					TextScaled = true,
					Size = UDim2.fromScale(0.424, 0.5),
					ZIndex = 11,
					[Roact.Change.Text] = function(rbx)
						setSearchText(rbx.Text)
					end,
				}),
			}),
		}),
	})
end

Players = RoactHooks.new(Roact)(Players)
return Players
