local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local PackCard = require(script.Parent.PackCard)

local function Champion(_, hooks)
	return Roact.createElement("Frame", {
		LayoutOrder = 8,
		Position = UDim2.fromScale(0, -0.088),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1.181),
	}, {
		["7"] = Roact.createElement(PackCard, {
			PackId = "7",
			Category = "SoccerCharacters",
			LayoutOrder = 1,
			GradientColor0 = Color3.fromHex("e677ff"),
			GradientColor1 = Color3.fromHex("b9338e"),
			StrokeColor = Color3.fromHex("7825ab"),
		}),
		["8"] = Roact.createElement(PackCard, {
			PackId = "8",
			Category = "SoccerCharacters",
			LayoutOrder = 2,
			GradientColor0 = Color3.fromHex("e677ff"),
			GradientColor1 = Color3.fromHex("b9338e"),
			StrokeColor = Color3.fromHex("7825ab"),
		}),
		List = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.03, 0),
		}),
	})
end

Champion = RoactHooks.new(Roact)(Champion)
return Champion
