local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local PackCard = require(script.Parent.PackCard)

local function Pro(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 6,
		Position = UDim2.fromScale(0, -0.088),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.181),
	}, {
		["5"] = Roact.createElement(PackCard, {
			PackId = "5",
			Category = "SoccerCharacters",
			LayoutOrder = 1,
			GradientColor0 = Color3.fromHex("55c3ff"),
			GradientColor1 = Color3.fromHex("296f9d"),
			StrokeColor = Color3.fromHex("286ba6"),
		}),
		["6"] = Roact.createElement(PackCard, {
			PackId = "6",
			Category = "SoccerCharacters",
			LayoutOrder = 2,
			GradientColor0 = Color3.fromHex("55c3ff"),
			GradientColor1 = Color3.fromHex("296f9d"),
			StrokeColor = Color3.fromHex("286ba6"),
		}),
		List = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Pro = RoactHooks.new(Roact)(Pro)
return Pro
