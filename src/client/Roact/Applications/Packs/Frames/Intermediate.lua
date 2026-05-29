local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local PackCard = require(script.Parent.PackCard)

local function Intermediate(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 4,
		Position = UDim2.fromScale(0, -0.088),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.181),
	}, {
		["3"] = Roact.createElement(PackCard, { PackId = "3", Category = "SoccerCharacters", LayoutOrder = 1 }),
		["4"] = Roact.createElement(PackCard, { PackId = "4", Category = "SoccerCharacters", LayoutOrder = 2 }),
		List = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Intermediate = RoactHooks.new(Roact)(Intermediate)
return Intermediate
