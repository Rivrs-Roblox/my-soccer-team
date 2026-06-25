-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Knit Controllers
local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Constants
local FramesConstants = require(StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Frames
local Frames = script.Parent.Frames
local SoccerCharacterCard = require(Frames.SoccerCharacterCard)
local GetStats = require(ReplicatedStorage.Shared.Helpers.SoccerCharacters.GetStats)

local Template = DataCacheController:GetFile("Template")
local UI = DataCacheController:GetFile("Images")
local ROW_HEIGHT = 0.45

function SelectCharacter(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	local equippedCharacters = TeamReducer.EquippedSoccerCharacters or {}
	local equippedIds = {}
	for _, id in pairs(equippedCharacters) do
		equippedIds[tostring(id)] = true
	end

	local SoccerCharacters = {}
	local index = 0

	for id, charData in pairs(InventoryReducer.SoccerCharacters or {}) do
		if equippedIds[tostring(id)] then
			continue
		end

		local templateData = Template.SoccerCharacters[charData.Name]
		if templateData then
			index += 1
			local stats = GetStats(charData, InventoryReducer.Accessories)

			SoccerCharacters[id] = SoccerCharacterCard({
				id = id,
				name = templateData.DisplayName or templateData.Name,
				shoot = stats.Shoot,
				dribble = stats.Dribble,
				pass = stats.Pass,
				rarity = templateData.Rarity or "Common",
				image = UI[templateData.Name] or "",
				level = charData.Level,
				card = UI["Card_" .. string.gsub(templateData.Rarity, " ", "_")],
				cardMask = UI["Card_" .. string.gsub(templateData.Rarity, " ", "_") .. "_Mask"],
				order = (Template.RarityPriority[templateData.Rarity] or 100) * 1000 + index,
				selectedSlot = TeamReducer.SelectedSlot,
				nationality = templateData.Nationality,
			})
		end
	end

	local rows = math.ceil(index / 4)
	local canvasHeight = rows * ROW_HEIGHT

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentUI == FramesConstants.SelectCharacter,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Content = Blue_Background({
			title = "Select Player",
			titleIcon = "rbxassetid://93727895914262",
			size = UDim2.fromScale(0.7, 0.7),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
		}, {
			Scroll = Roact.createElement("ScrollingFrame", {
				AutomaticCanvasSize = 3,
				ScrollBarThickness = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.56),
				Size = UDim2.fromScale(0.95, 0.79),
				ScrollBarImageTransparency = 0.32,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromScale(0, 1),
			}, {
				UIPadding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0.05, 0),
					PaddingRight = UDim.new(0.05, 0),
				}),
				Grid = Roact.createElement("UIGridLayout", {
					FillDirectionMaxCells = 6,
					SortOrder = 2,
					CellSize = UDim2.fromScale(0.15, 0.5),
					CellPadding = UDim2.fromScale(0, -0.03),
				}),
				Roact.createFragment(SoccerCharacters),
			}),
		}),
	})
end

SelectCharacter = RoactHooks.new(Roact)(SelectCharacter)
return SelectCharacter
