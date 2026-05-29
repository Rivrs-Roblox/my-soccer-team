local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

return function(params: table)
	setmetatable(params, {
		__index = {
			id = 0 :: number,
			name = "" :: string,
			image = "" :: string,
			amount = 0 :: number,
			onClick = function() end :: any,
			order = 0 :: number,
		},
	})

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = 3,
		LayoutOrder = 8,
		BackgroundColor3 = Color3.fromHex("fcfaff"),
		ZIndex = 2,

		[Roact.Event.MouseButton1Click] = function()
			Sound:PlaySound("SoundClick")
			if params.onClick then
				params.onClick()
			end
		end,
	}, {
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.88),
			TextSize = 14,
			ZIndex = 10,
			TextScaled = true,
			Size = UDim2.fromScale(0.88, 0.25),
		}, { UIStroke = Roact.createElement("UIStroke", {
			Thickness = 1.5,
		}) }),
		ValueText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = `x{params.amount}`,
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			TextXAlignment = 1,
			Position = UDim2.fromScale(0.5, 0.15),
			ZIndex = 10,
			TextSize = 14,
			Size = UDim2.fromScale(0.9, 0.25),
		}, { UIStroke = Roact.createElement("UIStroke", {
			Thickness = 1.5,
		}) }),
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("d5d5d5")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("8c8c8c")),
			}),
			Rotation = 90,
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("e6e6e6"),
			Thickness = 3,
		}),
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = params.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ScaleType = 3,
			Size = UDim2.fromScale(0.9, 0.75),
			ZIndex = 2,
		}),
	})
end
