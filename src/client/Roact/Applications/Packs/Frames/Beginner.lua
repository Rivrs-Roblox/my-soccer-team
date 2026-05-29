local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local PackCard = require(script.Parent.PackCard)

local function Beginner(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 2,
		Position = UDim2.fromScale(0, -0.088),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.181),
	}, {
		["1"] = Roact.createElement(PackCard, { PackId = "1", Category = "SoccerCharacters", LayoutOrder = 1 }),
		["2"] = Roact.createElement(PackCard, { PackId = "2", Category = "SoccerCharacters", LayoutOrder = 2 }),
		List = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Beginner = RoactHooks.new(Roact)(Beginner)
return Beginner
