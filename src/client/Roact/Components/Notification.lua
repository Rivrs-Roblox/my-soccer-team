--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Roact = require(ReplicatedStorage.Packages.roact)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Text = require(Components.Text)
local AspectRatio = require(Components.AspectRatio)
local Stroke = require(Components.Stroke)
local Corner = require(Components.Corner)

return function(params: table)
	setmetatable(params, {
		__index = {
			number = 0,
		},
	})

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(if type(params.number) == "number" then 0.95 else 0.8, 0.05),
		Size = UDim2.fromScale(if type(params.number) == "number" then 0.4 else 0.8, 0.4),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),

		Visible = if type(params.number) == "number" then params.number > 0 else true,
		ZIndex = 10000,
	}, {
		AspectRatio = AspectRatio({ radio = 1 }),
		Corner = Corner({ radius = 1 }),
		Stroke = Stroke({ thick = 1.5 }),

		Text = Text({
			text = tostring(params.number),
			color = Color3.fromRGB(255, 255, 255),
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.99, 0.99),
			stroke = 2,
			index = 10001,
		}),
	})
end
