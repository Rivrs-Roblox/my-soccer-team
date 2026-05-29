--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Packages
local Roact = require(ReplicatedStorage.Packages.roact)
local Knit = require(ReplicatedStorage.Packages.Knit)
-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local AspectRatio = require(Components.AspectRatio)
local Text = require(Components.Text)

local DataCacheController = Knit.GetController("DataCacheController")

local Colors = DataCacheController:GetFile("Colors")

-- Controller
-- ShopIcon
return function(params: table)
	setmetatable(params, {
		__index = {
			icon = "" :: string,
			text = "" :: string,
			topText = "" :: string,
			position = UDim2.fromScale(0.5, 0.5) :: UDim2,
			size = UDim2.fromScale(1, 1) :: UDim2,
			tooltip = nil,
			rarity = "Common" :: string,
		},
	})

	return Roact.createElement("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = params.position,
		Size = params.size,
		ZIndex = 2,
	}, {
		Image = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Image = params.icon,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			AspectRatio = AspectRatio({ ratio = 1 }),
		}),

		Effect = Roact.createElement("ImageLabel", {
			ImageColor3 = Colors[params.rarity],
			Image = "rbxassetid://12363773089",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1.5, 1.5),
		}, { AspectRatio = Roact.createElement("UIAspectRatioConstraint", {}) }),

		AspectRatio = AspectRatio({ ratio = 1 }),
		BottomText = Text({
			text = params.text,
			position = UDim2.fromScale(0.5, 0.911),
			size = UDim2.fromScale(1, 0.35),
			color = Color3.fromRGB(255, 255, 255),
			backgroundTransparency = 1,
			stroke = 2,
			index = 3,
		}),
		TopText = Text({
			text = params.topText,
			position = UDim2.fromScale(0.5, 0.089),
			size = UDim2.fromScale(1, 0.35),
			color = Color3.fromRGB(255, 255, 255),
			backgroundTransparency = 1,
			stroke = 2,
			index = 3,
		}),
	})
end
