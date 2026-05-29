local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

return function(params: table)
	setmetatable(params, {
		__index = {
			order = 1 :: number,
		},
	})

	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromHex("000000"),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.15, 1),
	}, {
		Icon2 = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = UI.Shoot,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			LayoutOrder = 2,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ScaleType = 3,
			Size = UDim2.fromScale(1, 1),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Icon1 = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = UI.Pass,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			LayoutOrder = 1,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ScaleType = 3,
			Size = UDim2.fromScale(1, 1),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Icon3 = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = UI.Dribble,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			LayoutOrder = 3,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ScaleType = 3,
			Size = UDim2.fromScale(1, 1),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		UIListLayout = Roact.createElement("UIListLayout", {
			VerticalAlignment = 0,
			FillDirection = 0,
			HorizontalAlignment = 0,
			SortOrder = 2,
		}),
	})
end
