local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

local StoreController = Knit.GetController("StoreController")
local MonetizationController = Knit.GetController("MonetizationController")
local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")

return function(params: table)
	setmetatable(params, {
		__index = {
			name = "" :: string,
			buyName = "" :: string,
			duration = "" :: string,
			icon = "" :: string,
			gradientColors = { "ffffff", "ffffff" } :: table,
			strokeColor = "ffffff" :: string,
			buyBgColor = "ffffff" :: string,
			buyStrokeColor = "ffffff" :: string,
			priceTextColor = "000000" :: string,
			order = 0 :: number,
		},
	})

	local buyItemName = params.buyName ~= "" and params.buyName or params.name

	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		Position = UDim2.fromScale(0.022, 0.104),
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Size = UDim2.fromScale(1, 0.45),
		ZIndex = 2,
	}, {
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.632),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.11),
		}),
		ValueText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.duration,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.737),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.09),
		}),
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex(params.gradientColors[1])),
				ColorSequenceKeypoint.new(1, Color3.fromHex(params.gradientColors[2])),
			}),
			Rotation = 90,
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.3),
			ZIndex = 2,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Size = UDim2.fromScale(0.7, 0.5),
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 3,
				Image = params.icon,
				Size = UDim2.fromScale(0.9, 0.9),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Sparkle = Roact.createElement("ImageLabel", {
				ScaleType = 3,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Sparkle,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1.2, 1.2),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.9,
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex(params.strokeColor),
			Thickness = 3,
		}),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.89),
			Size = UDim2.fromScale(0.75, 0.15),
			ZIndex = 2,
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromHex(params.buyBgColor),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				StoreController:BuyItem({ name = buyItemName })
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex(params.buyStrokeColor),
				Thickness = 2,
			}),
			PriceText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex(params.priceTextColor),
				Text = ` {MonetizationController:GetPrice(buyItemName)}`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				TextSize = 18,
				ZIndex = 3,
				TextScaled = true,
				Size = UDim2.fromScale(0.85, 0.7),
			}),
		}),
	})
end
