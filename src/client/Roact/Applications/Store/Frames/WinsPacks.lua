-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")
local Template = DataCacheController:GetFile("Template")

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

local WinsPackItem = require(script.Parent.WinsPackItem)

local function calculateWinPackAmount(zone, pack)
	return FormatNumber(Template.WinsPacks[zone][pack])
end

-- Featured
local function WinsPacks(_, hooks)
	local AreaReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.AreaReducer
	end)

	local currentZone = AreaReducer.Areas[table.maxn(AreaReducer.Areas)] or "Area01"

	local packData = {
		{
			name = "Small",
			amountText = `+ {calculateWinPackAmount(currentZone, "SMALL")} Wins`,
			icon = UI.Small_Wins_Pack,
			iconScale = 0.6,
			gradientColors = { "497fca", "203758" },
			strokeColor = "4c9dff",
			buyBgColor = "67caff",
			buyStrokeColor = "b7e3ff",
			buyStrokeThickness = 2,
			priceTextColor = "214995",
			order = 1,
		},
		{
			name = "Regular",
			amountText = `+ {calculateWinPackAmount(currentZone, "REGULAR")} Wins`,
			icon = UI.Regular_Wins_Pack,
			iconScale = 0.8,
			gradientColors = { "57bcff", "316c90" },
			strokeColor = "52e2ff",
			buyBgColor = "7eeeff",
			buyStrokeColor = "e7fffd",
			buyStrokeThickness = 2,
			priceTextColor = "214995",
			order = 2,
		},
		{
			name = "Big",
			amountText = `+ {calculateWinPackAmount(currentZone, "BIG")} Wins`,
			icon = UI.Big_Wins_Pack,
			iconScale = 1,
			gradientColors = { "c98bff", "5437c6" },
			strokeColor = "a869ff",
			buyBgColor = "d4b7ff",
			buyStrokeColor = "e9d3ff",
			buyStrokeThickness = 3,
			priceTextColor = "5f3490",
			order = 3,
		},
		{
			name = "Huge",
			amountText = `+ {calculateWinPackAmount(currentZone, "HUGE")} Wins`,
			icon = UI.Huge_Wins_Pack,
			iconScale = 1,
			gradientColors = { "ffcc33", "b83c0c" },
			strokeColor = "ffbf00",
			buyBgColor = "fff239",
			buyStrokeColor = "fff5cf",
			buyStrokeThickness = 2,
			priceTextColor = "903c00",
			order = 4,
		},
	}

	local children = {
		List = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0.02, 0),
			FillDirection = 0,
			HorizontalAlignment = 0,
			SortOrder = 2,
		}),
	}

	for _, item in ipairs(packData) do
		children[tostring(item.order)] = Roact.createElement(WinsPackItem, {
			name = item.name,
			amountText = item.amountText,
			icon = item.icon,
			iconScale = item.iconScale,
			gradientColors = item.gradientColors,
			strokeColor = item.strokeColor,
			buyBgColor = item.buyBgColor,
			buyStrokeColor = item.buyStrokeColor,
			buyStrokeThickness = item.buyStrokeThickness,
			priceTextColor = item.priceTextColor,
			order = item.order,
		})
	end

	return Roact.createElement("Frame", {
		LayoutOrder = 10,
		Position = UDim2.fromScale(-0, -0.022),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.81),
	}, children)
end

return RoactHooks.new(Roact)(WinsPacks)
