-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")
local Templates = DataCacheController:GetFile("Template")

local AccessoryItem = require(script.Parent.AccessoryItem)

local function Accessories(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 6,
		Position = UDim2.fromScale(-0, -0.038),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.16),
	}, {
		Grid = Roact.createElement("UIGridLayout", {
			SortOrder = 2,
			CellSize = UDim2.fromScale(0.465, 0.45),
			FillDirectionMaxCells = 2,
			CellPadding = UDim2.fromScale(0.02, 0),
			HorizontalAlignment = 0,
		}),
		ClutchMascot = Roact.createElement(AccessoryItem, {
			name = "Clutch Mascot",
			image = UI["Clutch Mascot"],
			pass = Templates.Accessories["Clutch Mascot"].Additions.Pass,
			shoot = Templates.Accessories["Clutch Mascot"].Additions.Shoot,
			dribble = Templates.Accessories["Clutch Mascot"].Additions.Dribble,
			rarity = Templates.Accessories["Clutch Mascot"].Rarity,
			order = 1,
		}),
		AngelWings = Roact.createElement(AccessoryItem, {
			name = "Angel Wings",
			image = UI["Angel Wings"],
			pass = Templates.Accessories["Angel Wings"].Additions.Pass,
			shoot = Templates.Accessories["Angel Wings"].Additions.Shoot,
			dribble = Templates.Accessories["Angel Wings"].Additions.Dribble,
			rarity = Templates.Accessories["Angel Wings"].Rarity,
			order = 2,
		}),
		Gauntlet = Roact.createElement(AccessoryItem, {
			name = "Gauntlet",
			image = UI["Gauntlet"],
			pass = Templates.Accessories["Gauntlet"].Additions.Pass,
			shoot = Templates.Accessories["Gauntlet"].Additions.Shoot,
			dribble = Templates.Accessories["Gauntlet"].Additions.Dribble,
			rarity = Templates.Accessories["Gauntlet"].Rarity,
			order = 3,
		}),
		GoatShoes = Roact.createElement(AccessoryItem, {
			name = "GOAT Shoes",
			image = UI["GOAT Shoes"],
			pass = Templates.Accessories["GOAT Shoes"].Additions.Pass,
			shoot = Templates.Accessories["GOAT Shoes"].Additions.Shoot,
			dribble = Templates.Accessories["GOAT Shoes"].Additions.Dribble,
			rarity = Templates.Accessories["GOAT Shoes"].Rarity,
			order = 4,
		}),
	})
end

return RoactHooks.new(Roact)(Accessories)
