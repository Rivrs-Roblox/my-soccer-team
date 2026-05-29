local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

return function(params: table)
	setmetatable(params, {
		__index = {
			id = 0 :: number,
			name = "" :: string,
			image = "" :: string,
			notification = 0 :: number,
			onClick = function() end :: any,
			order = 0 :: number,
		},
	})

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderColor3 = Color3.fromHex("000000"),
		LayoutOrder = params.order,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.8, 0.8),
	}, {
		Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
		Store = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BorderColor3 = Color3.fromHex("000000"),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Down] = function()
				Sound:PlaySound("UI_Click")
				if params.onClick then
					params.onClick()
				end
			end,
		}, {
			ButtonText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = params.name,
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.96),
				TextSize = 14,
				ZIndex = 5,
				TextScaled = true,
				Size = UDim2.fromScale(0.91, 0.25),
			}),
			Notification = Roact.createElement("Frame", {
				Visible = (tonumber(params.notification) or 0) > 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.95, 0.1),
				ZIndex = 10000,
				BackgroundColor3 = Color3.fromHex("ff0000"),
				Size = UDim2.fromScale(0.35, 0.35),
			}, {
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					ScaleType = 3,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 10001,
					Image = "rbxassetid://125311831710765",
					Size = UDim2.fromScale(0.8, 0.8),
				}),
				Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("ffffff"),
					Thickness = 1.5,
				}),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("2f37a5")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("13133d")),
				}),
				Rotation = 90,
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("1e88d9"),
				Thickness = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = params.image,
				Size = UDim2.fromScale(0.65, 0.65),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Shadow = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("000000"),
			BackgroundTransparency = 0.7,
			Position = UDim2.fromScale(0.5, 0.6),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1.05, 1.05),
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
	})
end
