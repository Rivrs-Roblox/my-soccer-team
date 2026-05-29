-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

local GamepassItem = require(script.Parent.GamepassItem)

local function Gamepasses(_, hooks)
	local MonetizationReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.MonetizationReducer
	end)

	local gamepassData = {
		{
			name = "VIP",
			description = "Access to the VIP features!",
			icon = UI.VIP,
			gradientColors = { "ffb700", "ee6b00" },
			strokeColors = { "ff7700", "000000" },
			order = 1,
		},
		{
			name = "x2 Passing",
			buyName = "x2 Pass",
			description = "Receive a x2 Passing multiplier while training!",
			icon = UI.Pass,
			gradientColors = { "65ff6a", "21df00" },
			strokeColors = { "0ecb00", "000000" },
			value = "x2",
			order = 2,
		},
		{
			name = "x2 Shooting",
			buyName = "x2 Shoot",
			description = "Receive a x2 Shooting multiplier while training!",
			icon = UI.Shoot,
			gradientColors = { "ffe270", "ee9700" },
			strokeColors = { "ff8c00", "000000" },
			value = "x2",
			order = 3,
		},
		{
			name = "x2 Dribbling",
			buyName = "x2 Dribble",
			description = "Receive a x2 Dribbling multiplier while training!",
			icon = UI.Dribble,
			gradientColors = { "ff7777", "ee0000" },
			strokeColors = { "ff0000", "000000" },
			value = "x2",
			order = 4,
		},
		{
			name = "x2 Wins",
			description = "Receive a x2 Wins multiplier while fighting!",
			icon = UI.Wins,
			gradientColors = { "fff58a", "eed200" },
			strokeColors = { "ff9500", "000000" },
			value = "x2",
			order = 5,
		},
		{
			name = "x2 Rebirth",
			buyName = "x2 Rebirths",
			description = "Receive a x2 multiplier while rebirthing!",
			icon = UI.Rebirth,
			gradientColors = { "ff7ee3", "ee3095" },
			strokeColors = { "d833c2", "000000" },
			value = "x2",
			order = 6,
		},
		{
			name = "+25 Storage",
			description = "Expand inventory storage by 25!",
			icon = UI.Storage,
			gradientColors = { "3b65a3", "254066" },
			strokeColors = { "1e40b9", "000000" },
			value = "+25",
			order = 7,
		},
		{
			name = "+50 Storage",
			description = "Expand inventory storage by 50!",
			icon = UI.Storage,
			gradientColors = { "3b65a3", "254066" },
			strokeColors = { "1e40b9", "000000" },
			value = "+50",
			order = 8,
		},
		{
			name = "x5 Open",
			description = "Open 5 packs at once!",
			icon = UI.Pack,
			gradientColors = { "3b65a3", "254066" },
			strokeColors = { "1e40b9", "000000" },
			value = "x5",
			order = 9,
		},
		{
			name = "x10 Open",
			description = "Open 10 packs at once!",
			icon = UI.Pack,
			gradientColors = { "3b65a3", "254066" },
			strokeColors = { "1e40b9", "000000" },
			value = "x10",
			order = 10,
		},
		{
			name = "Lucky",
			description = "x2 boost when opening packs!",
			icon = UI.Lucky,
			gradientColors = { "3ce86a", "2aa34c" },
			strokeColors = { "19ac2a", "000000" },
			value = "x2",
			order = 11,
		},
		{
			name = "Super Lucky",
			description = "x3 boost when opening packs!",
			icon = UI.Super_Lucky,
			gradientColors = { "d460e8", "a924b3" },
			strokeColors = { "9930ac", "000000" },
			value = "x3",
			order = 12,
		},
		{
			name = "Ultra Lucky",
			description = "x5 boost when opening packs!",
			icon = UI.Ultra_Lucky,
			gradientColors = { "ffb700", "ee6b00" },
			strokeColors = { "ff7700", "000000" },
			value = "x5",
			order = 13,
		},
	}

	local children = {
		Grid = Roact.createElement("UIGridLayout", {
			SortOrder = 2,
			CellSize = UDim2.fromScale(0.47, 0.127),
			FillDirectionMaxCells = 2,
			CellPadding = UDim2.fromScale(0.02, 0.015),
			HorizontalAlignment = 0,
		}),
	}

	for _, item in ipairs(gamepassData) do
		local buyItemName = item.buyName or item.name
		local isBought = MonetizationReducer.Gamepasses
			and table.find(MonetizationReducer.Gamepasses, buyItemName) ~= nil

		children[tostring(item.order)] = Roact.createElement(GamepassItem, {
			name = item.name,
			buyName = buyItemName,
			description = item.description,
			icon = item.icon,
			gradientColors = item.gradientColors,
			strokeColors = item.strokeColors,
			bought = isBought,
			order = item.order,
			value = item.value,
		})
	end

	return Roact.createElement("Frame", {
		LayoutOrder = 8,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 3.9),
	}, children)
end

Gamepasses = RoactHooks.new(Roact)(Gamepasses)
return Gamepasses
