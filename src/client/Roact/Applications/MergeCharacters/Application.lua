--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Knit Controllers
local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")
local SoccerCharactersService = Knit.GetService("SoccerCharactersService")

local Template = DataCacheController:GetFile("Template")
local UI = DataCacheController:GetFile("Images")
local MergeRequirements = Template.MergeRequirements

local Helpers = ReplicatedStorage.Shared.Helpers
local GetStats = require(Helpers.SoccerCharacters.GetStats)

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Constants
local FramesConstants = require(StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Frames
local Frames = script.Parent.Frames
local SoccerCharacterCard = require(Frames.SoccerCharacterCard)

function MergeCharactersApp(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)
	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)

	local selectedIds, setSelectedIds = hooks.useState({})
	local searchText, setSearchText = hooks.useState("")

	-- Calculate currently selected info
	local selectedCount = 0
	local targetName = nil
	local targetLevel = nil
	for id, _ in pairs(selectedIds) do
		local char = InventoryReducer.SoccerCharacters[id]
		if char then
			selectedCount = selectedCount + 1
			targetName = char.Name
			targetLevel = char.Level
		end
	end

	hooks.useEffect(function()
		local changed = false
		local newSelected = table.clone(selectedIds)
		for id, _ in pairs(selectedIds) do
			if not InventoryReducer.SoccerCharacters[id] then
				newSelected[id] = nil
				changed = true
			end
		end
		if changed then
			setSelectedIds(newSelected)
		end
	end, { InventoryReducer.SoccerCharacters, selectedIds })

	local requiredAmount = targetLevel and MergeRequirements.REQUIREMENTS[targetLevel] or math.huge

	local equippedIds = {}
	if TeamReducer and TeamReducer.EquippedSoccerCharacters then
		for _, id in pairs(TeamReducer.EquippedSoccerCharacters) do
			equippedIds[tostring(id)] = true
		end
	end

	-- Filter and map characters
	local sortedChars = {}
	for id, char in pairs(InventoryReducer.SoccerCharacters) do
		if char.Level < MergeRequirements.MAX_LEVEL and not equippedIds[tostring(id)] then
			if searchText == "" or string.find(string.lower(char.Name), string.lower(searchText)) then
				local templateData = Template.SoccerCharacters[char.Name]
				if templateData then
					table.insert(sortedChars, { id = id, char = char, template = templateData })
				end
			end
		end
	end

	table.sort(sortedChars, function(a, b)
		local rarityA = Template.RarityPriority[a.template.Rarity or "Common"] or 100
		local rarityB = Template.RarityPriority[b.template.Rarity or "Common"] or 100

		if rarityA ~= rarityB then
			return rarityA < rarityB
		end

		if a.char.Name == b.char.Name then
			if a.char.Level == b.char.Level then
				return a.id < b.id
			end
			return a.char.Level > b.char.Level
		end
		return a.char.Name < b.char.Name
	end)

	local numCards = #sortedChars
	local rows = math.max(1, math.ceil(numCards / 5))
	local desiredCellHeight = 0.6
	local desiredCellPadding = -0.18
	local canvasScaleY = math.max(1, (rows * desiredCellHeight) + ((rows - 1) * desiredCellPadding) + 0.04)

	local children = {
		UIGridLayout = Roact.createElement("UIGridLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.fromScale(0.18, desiredCellHeight / canvasScaleY),
			CellPadding = UDim2.fromScale(0.02, desiredCellPadding / canvasScaleY),
			FillDirectionMaxCells = 5,
		}),
		UIPadding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
		}),
	}

	for i, data in ipairs(sortedChars) do
		local id = data.id
		local char = data.char
		local templateData = data.template

		local stats = GetStats(char, InventoryReducer.Accessories)

		local isSelected = selectedIds[id] ~= nil
		local canSelect = false
		if isSelected then
			canSelect = true
		elseif selectedCount == 0 then
			canSelect = true
		elseif char.Name == targetName and char.Level == targetLevel and selectedCount < requiredAmount then
			canSelect = true
		end

		children[id] = Roact.createElement(SoccerCharacterCard, {
			id = id,
			name = templateData.Name,
			shoot = stats.Shoot,
			dribble = stats.Dribble,
			pass = stats.Pass,
			rarity = templateData.Rarity or "Common",
			image = UI[templateData.Name] or "",
			level = char.Level,
			card = UI["Card_" .. string.gsub(templateData.Rarity or "Common", " ", "_")],
			cardMask = UI["Card_" .. string.gsub(templateData.Rarity or "Common", " ", "_") .. "_Mask"],
			equipped = isSelected,
			order = i,
			nationality = templateData.Nationality,
			onClick = function()
				if isSelected then
					Sound:PlaySound("UI_Click")
					local newSelected = table.clone(selectedIds)
					newSelected[id] = nil
					setSelectedIds(newSelected)
				elseif canSelect then
					Sound:PlaySound("UI_Click")
					local newSelected = table.clone(selectedIds)
					newSelected[id] = true
					setSelectedIds(newSelected)
				else
					Sound:PlaySound("UI_Error")
				end
			end,
		})
	end

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentUI == FramesConstants.MergeCharacters,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromHex("000000"),
		Size = UDim2.fromScale(1, 1),
	}, {
		Popup = Blue_Background({
			title = "Merge Players",
			titleIcon = "rbxassetid://76558147588196",
			size = UDim2.fromScale(0.7, 0.7),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
			action = function()
				UIController:HideFrame()
			end,
		}, {
			Bottom = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.941),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.9, 0.077),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					FillDirection = 0,
				}),
				SearchBar = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.219, 0.5),
					LayoutOrder = 1,
					ZIndex = 10,
					BackgroundColor3 = Color3.fromHex("254167"),
					Size = UDim2.fromScale(0.57, 1),
				}, {
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
						Size = UDim2.fromScale(0.7, 0.5),
						ZIndex = 11,
						ClearTextOnFocus = false,
						[Roact.Change.Text] = function(rbx)
							setSearchText(rbx.Text)
						end,
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
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
				}),
				Merge = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.2, 1),
					Position = UDim2.fromScale(0.786, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,
					[Roact.Event.MouseButton1Click] = function()
						if selectedCount == requiredAmount then
							Sound:PlaySound("UI_Click")
							local idsToMerge = {}
							for id, _ in pairs(selectedIds) do
								table.insert(idsToMerge, id)
							end
							SoccerCharactersService:MergeCharacters(idsToMerge)
								:andThen(function()
									setSelectedIds({})
								end)
								:catch(function(err)
									warn("Merge failed:", err)
									setSelectedIds({})
								end)
						else
							Sound:PlaySound("UI_Error")
						end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("04da01"),
						Thickness = 2,
					}),
					UIGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("00d921")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("0e820e")),
						}),
						Rotation = 90,
					}),
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = selectedCount > 0 and `Merge ({selectedCount}/{requiredAmount})` or "Merge",
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						TextSize = 14,
						ZIndex = 5,
						TextScaled = true,
						Size = UDim2.fromScale(0.9, 0.5),
					}),
				}),
			}),
			InfoText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Select players of the same name and level to merge!",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.86),
				TextSize = 14,
				ZIndex = 2,
				TextScaled = true,
				Size = UDim2.fromScale(0.9, 0.057),
			}),
			Scroll = Roact.createElement("ScrollingFrame", {
				CanvasSize = UDim2.fromScale(0, canvasScaleY),
				ScrollBarThickness = 8,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.49),
				ScrollingDirection = 2,
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.95, 0.64),
			}, children),
		}),
	})
end

MergeCharactersApp = RoactHooks.new(Roact)(MergeCharactersApp)
return MergeCharactersApp
