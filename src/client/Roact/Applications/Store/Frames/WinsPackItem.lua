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
			amountText = "" :: string,
			icon = "" :: string,
			iconScale = 1 :: number,
			gradientColors = { "ffffff", "ffffff" } :: table,
			strokeColor = "ffffff" :: string,
			buyBgColor = "ffffff" :: string,
			buyStrokeColor = "ffffff" :: string,
			buyStrokeThickness = 2 :: number,
			priceTextColor = "000000" :: string,
			order = 0 :: number,
		},
	})

	local buyItemName = params.buyName ~= "" and params.buyName or "Wins Pack - " .. params.name

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		LayoutOrder = params.order,
		ZIndex = 2,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Size = UDim2.fromScale(0.223, 1),
	}, {
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.65,
		}),
		ValueText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.amountText,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Font = 45,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.71),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.1),
		}),
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.28),
			ZIndex = 2,
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Size = UDim2.fromScale(0.8, 0.45),
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
				Size = UDim2.fromScale(params.iconScale, params.iconScale),
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
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex(params.strokeColor),
			Thickness = 3,
		}),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.6),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.11),
		}),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.87),
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
				Thickness = params.buyStrokeThickness,
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
