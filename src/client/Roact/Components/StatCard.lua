local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)

local function StatCard(props)
	local hasPlus = props.OnPlusClick ~= nil

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromHex("111f39"),
		BorderColor3 = Color3.fromHex("000000"),
		LayoutOrder = props.LayoutOrder,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.6, 0.5),
	}, {
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("e8e8e8"),
			Thickness = 2,
		}),
		Plus = hasPlus and Roact.createElement("ImageButton", {
			LayoutOrder = 3,
			ScaleType = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://98999428594161",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.9, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			ImageColor3 = Color3.fromHex("b0b0b0"),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = props.OnPlusClick,
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		BottomText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = props.Title,
			AnchorPoint = Vector2.new(0.5, 0),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 1.05),
			TextSize = 14,
			ZIndex = 2,
			TextScaled = true,
			Size = UDim2.fromScale(0.8, 0.4),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("191919"),
				Thickness = 1.5,
			}),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 3.5,
		}),
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			ScaleType = 3,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.13, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 2,
			Image = props.Icon,
			Size = UDim2.fromScale(0.3, 0.7),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		MainText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = props.Value,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.52, 0.5),
			TextSize = 14,
			ZIndex = 2,
			TextScaled = true,
			Size = UDim2.fromScale(0.55, 0.5),
		}),
	})
end

return StatCard
