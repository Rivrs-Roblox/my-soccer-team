local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local PackCard = require(script.Parent.PackCard)

local function Goat(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 10,
		Position = UDim2.fromScale(0, -0.088),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.59),
	}, {
		["9"] = Roact.createElement(PackCard, {
			PackId = "9",
			Category = "SoccerCharacters",
			LayoutOrder = 1,
			GradientColor0 = Color3.fromHex("fff395"),
			GradientColor1 = Color3.fromHex("ffbf3e"),
			StrokeColor = Color3.fromHex("985900"),
		}),
		List = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Goat = RoactHooks.new(Roact)(Goat)
return Goat
