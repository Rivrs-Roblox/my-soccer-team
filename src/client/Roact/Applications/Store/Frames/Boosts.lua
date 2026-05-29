-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

local BoostItem = require(script.Parent.BoostItem)

-- Featured
local function Boosts(_, hooks)
	local boostData = {
		{
			name = "x2 Passing Boost",
			duration = "30 Min",
			icon = UI.x2_Pass_Boost,
			gradientColors = { "2fb6ff", "4740a6" },
			strokeColor = "25edff",
			buyBgColor = "22daff",
			buyStrokeColor = "00fbff",
			priceTextColor = "0a508c",
			order = 1,
		},
		{
			name = "x2 Shooting Boost",
			duration = "30 Min",
			icon = UI.x2_Shoot_Boost,
			gradientColors = { "2fb6ff", "4740a6" },
			strokeColor = "25edff",
			buyBgColor = "22daff",
			buyStrokeColor = "00fbff",
			priceTextColor = "0a508c",
			order = 2,
		},
		{
			name = "x2 Dribbling Boost",
			duration = "30 Min",
			icon = UI.x2_Dribble_Boost,
			gradientColors = { "2fb6ff", "4740a6" },
			strokeColor = "25edff",
			buyBgColor = "22daff",
			buyStrokeColor = "00fbff",
			priceTextColor = "0a508c",
			order = 3,
		},
		{
			name = "x2 Wins Boost",
			duration = "30 Min",
			icon = UI.x2_Wins_Boost,
			gradientColors = { "2fb6ff", "4740a6" },
			strokeColor = "25edff",
			buyBgColor = "22daff",
			buyStrokeColor = "00fbff",
			priceTextColor = "0a508c",
			order = 4,
		},
		{
			name = "Boost Bundle",
			duration = "All x10",
			icon = UI.Bundle_Boost,
			gradientColors = { "ff9326", "c14b14" },
			strokeColor = "ffbf00",
			buyBgColor = "ffd500",
			buyStrokeColor = "fbff00",
			priceTextColor = "903c00",
			order = 5,
		},
	}

	local children = {
		Grid = Roact.createElement("UIGridLayout", {
			SortOrder = 2,
			CellSize = UDim2.fromScale(0.3, 0.45),
			FillDirectionMaxCells = 3,
			CellPadding = UDim2.fromScale(0.02, 0.03),
			HorizontalAlignment = 0,
		}),
	}

	for _, item in ipairs(boostData) do
		children[tostring(item.order)] = Roact.createElement(BoostItem, {
			name = item.name,
			duration = item.duration,
			icon = item.icon,
			gradientColors = item.gradientColors,
			strokeColor = item.strokeColor,
			buyBgColor = item.buyBgColor,
			buyStrokeColor = item.buyStrokeColor,
			priceTextColor = item.priceTextColor,
			order = item.order,
		})
	end

	return Roact.createElement("Frame", {
		LayoutOrder = 12,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.65),
	}, children)
end

return RoactHooks.new(Roact)(Boosts)
