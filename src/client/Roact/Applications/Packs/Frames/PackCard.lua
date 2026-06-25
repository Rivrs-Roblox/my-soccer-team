local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local DataCacheController = Knit.GetController("DataCacheController")
local GachaController = Knit.GetController("GachaController")
local StoreController = Knit.GetController("StoreController")
local TooltipController = Knit.GetController("TooltipController")
local MonetizationController = Knit.GetController("MonetizationController")

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)
local CreateHoverDescription = require(Helpers.CreateHoverDescription)

local Colors = require(ReplicatedStorage.Shared.Data.Colors)

local Template = DataCacheController:GetFile("Template")
local UI = DataCacheController:GetFile("Images")

local function PackCard(props, hooks)
	local MonetizationReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.MonetizationReducer
	end)

	local packId = props.PackId
	local category = props.Category
	local layoutOrder = props.LayoutOrder
	local gradientColor0 = props.GradientColor0
	local gradientColor1 = props.GradientColor1
	local strokeColor = props.StrokeColor

	local packData = Template.Gacha[category][packId]

	local stockCount, setStockCount = hooks.useState(packData.Stock or 0)

	hooks.useEffect(function()
		local function updateStock()
			local currentStock = GachaController.CurrentStock
			if currentStock and currentStock[category] and currentStock[category][packId] then
				setStockCount(currentStock[category][packId])
			end
		end

		updateStock()

		local conn = GachaController.StockUpdated:Connect(updateStock)

		return function()
			conn:Disconnect()
		end
	end, { category, packId })

	local rarityElements = {}
	local order = 1

	-- Define an explicit order for rarities
	local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Gold Legendary" }
	for _, rarity in ipairs(rarityOrder) do
		local chance = packData.Chances[rarity]
		if chance and chance > 0 then
			local rarityText = rarity .. " " .. chance .. "%"
			local textLength = string.len(rarityText)

			rarityElements[rarity] = Roact.createElement("TextLabel", {
				LayoutOrder = order,
				TextWrapped = true,
				TextColor3 = Colors.Stroke[rarity] or Colors[rarity] or Color3.fromHex("ffffff"),
				Text = rarityText,
				TextScaled = true,
				AnchorPoint = Vector2.new(1, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 1,
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(textLength * 0.028, 1),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Thickness = 1.5,
				}),
			})
			order += 1
		end
	end

	rarityElements["List"] = Roact.createElement("UIListLayout", {
		VerticalAlignment = 0,
		SortOrder = 2,
		HorizontalAlignment = 2,
		Padding = UDim.new(0.01, 0),
		FillDirection = 0,
	})

	local priceText = FormatNumber(packData.Price)
	local currencyIcon = packData.Robux and UI.Robux or UI.Wins

	if category == "Accessories" then
		currencyIcon = "rbxassetid://77287416173962"
	end

	if packData.Robux then
		priceText = ` {MonetizationController:GetPrice(packData.Name)}`
	end

	local rawName = string.gsub(packData.Name, " ", "_")
	rawName = string.gsub(rawName, "%-", "_")
	local imageName = rawName .. "_Full"
	local packImage = UI[imageName]

	if not packImage then
		if packData.Name == "Drip Pack" then
			packImage = "rbxassetid://133517110442332"
		elseif packData.Name == "Fresh Pack" then
			packImage = "rbxassetid://108112383336023"
		else
			packImage = UI.Street_Kick_Pack_Full
		end
	end

	local isRobux = packData.Robux

	local function getButton(label, layout, size, purchaseFunc, isRobuxButton)
		if isRobuxButton then
			return Roact.createElement("ImageButton", {
				LayoutOrder = layout,
				Position = UDim2.fromScale(0.26, 0.82),
				Size = size,
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffba81"),
				[Roact.Event.MouseButton1Click] = purchaseFunc,
			}, {
				UICorner = Roact.createElement("UICorner", {}),
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("ffe149"), Thickness = 2 }),
				PriceText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = label,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 3,
					TextScaled = true,
					Size = UDim2.fromScale(0.8, 0.6),
				}, {
					UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("a3690c"), Thickness = 1.5 }),
				}),
			})
		else
			return Roact.createElement("ImageButton", {
				LayoutOrder = layout,
				Position = UDim2.fromScale(0.26, 0.82),
				Size = size,
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				[Roact.Event.MouseButton1Click] = purchaseFunc,
			}, {
				UICorner = Roact.createElement("UICorner", {}),
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("71fe59"), Thickness = 2 }),
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("3ae83a")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("33aa3d")),
					}),
					Rotation = 90,
				}),
				AmountText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = label,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 3,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.75),
				}, {
					UIStroke = Roact.createElement("UIStroke", { Thickness = 1.5 }),
				}),
			})
		end
	end

	local buttons = {}
	if isRobux then
		buttons.Buy = getButton(`x1 - {priceText}`, 1, UDim2.fromScale(0.3, 1), function()
			StoreController:BuyItem({ name = "x1 " .. packData.Name })
		end, true)
		buttons.Buy5 = getButton(
			`x5 -  {MonetizationController:GetPrice("x5 " .. packData.Name)}`,
			2,
			UDim2.fromScale(0.3, 1),
			function()
				StoreController:BuyItem({ name = "x5 " .. packData.Name })
			end,
			true
		)
		buttons.Buy10 = getButton(
			`x10 -  {MonetizationController:GetPrice("x10 " .. packData.Name)}`,
			3,
			UDim2.fromScale(0.3, 1),
			function()
				StoreController:BuyItem({ name = "x10 " .. packData.Name })
			end,
			true
		)
	else
		buttons.Buy = getButton("x1 Open", 1, UDim2.fromScale(0.3, 1), function()
			GachaController:Buy(category, packId, "Wins", 1)
		end, false)
		buttons.Buy5 = getButton("x5 Open", 2, UDim2.fromScale(0.3, 1), function()
			if MonetizationReducer.Gamepasses and not table.find(MonetizationReducer.Gamepasses, "x5 Open") then
				StoreController:BuyItem({ name = "x5 Open" })
			else
				GachaController:Buy(category, packId, "Wins", 5)
			end
		end, false)

		if category == "SoccerCharacters" then
			buttons.Buy10 = getButton("x10 Open", 3, UDim2.fromScale(0.3, 1), function()
				if MonetizationReducer.Gamepasses and not table.find(MonetizationReducer.Gamepasses, "x10 Open") then
					StoreController:BuyItem({ name = "x10 Open" })
				else
					GachaController:Buy(category, packId, "Wins", 10)
				end
			end, false)
		end
	end

	buttons.List = Roact.createElement("UIListLayout", {
		Padding = UDim.new(0.03, 0),
		FillDirection = 0,
		HorizontalAlignment = 0,
		SortOrder = 2,
	})

	return Roact.createElement("Frame", {
		LayoutOrder = layoutOrder,
		Position = UDim2.fromScale(0.079, 0),
		ClipsDescendants = true,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Size = UDim2.fromScale(0.95, 0.95),
		ZIndex = 2,
	}, {
		Rarity = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.98, 0.4),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.7, 0.15),
		}, rarityElements),

		Buttons = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.721, 0.78),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.536, 0.242),
		}, buttons),

		UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),

		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, gradientColor0 or Color3.fromHex("3d6aa8")),
				ColorSequenceKeypoint.new(1, gradientColor1 or Color3.fromHex("203758")),
			}),
			Rotation = 90,
		}),

		Price = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.27, 0.78),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.178, 0.25),
			Visible = not isRobux,
		}, {
			PriceText = Roact.createElement("TextLabel", {
				LayoutOrder = 2,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = priceText,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(-0.618, 0.337),
				TextSize = 14,
				Size = UDim2.fromScale(0.659, 1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = currencyIcon,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ScaleType = 3,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			List = Roact.createElement("UIListLayout", { VerticalAlignment = 0, FillDirection = 0, SortOrder = 2 }),
		}),

		Prerequisite = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.27, 0.13),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.18, 0.2),
			Visible = (packData.Prerequisite and packData.Prerequisite.Rebirth or 0) > 0,
		}, {
			PriceText = Roact.createElement("TextLabel", {
				LayoutOrder = 3,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = FormatNumber(packData.Prerequisite and packData.Prerequisite.Rebirth or 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(-0.618, 0.337),
				TextSize = 14,
				Size = UDim2.fromScale(0.659, 1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Rebirth,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 2,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ScaleType = 3,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			NeedText = Roact.createElement("TextLabel", {
				LayoutOrder = 1,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Prerequisite: ",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(-0.618, 0.337),
				TextSize = 14,
				Size = UDim2.fromScale(0.659, 1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
			}),
			List = Roact.createElement("UIListLayout", { VerticalAlignment = 0, FillDirection = 0, SortOrder = 2 }),
		}),

		-- Prerequisite = Roact.createElement("Frame", {
		-- 	AnchorPoint = Vector2.new(0, 0.5),
		-- 	BackgroundColor3 = Color3.fromHex("ffffff"),
		-- 	BackgroundTransparency = 1,
		-- 	Position = UDim2.fromScale(0.27, 0.13),
		-- 	BorderColor3 = Color3.fromHex("000000"),
		-- 	ZIndex = 10,
		-- 	BorderSizePixel = 0,
		-- 	Size = UDim2.fromScale(0.18, 0.2),
		-- 	Visible = (packData.Prerequisite and packData.Prerequisite.Area or "") ~= "",
		-- }, {
		-- 	PriceText = Roact.createElement("TextLabel", {
		-- 		LayoutOrder = 3,
		-- 		TextWrapped = true,
		-- 		TextColor3 = Color3.fromHex("ffffff"),
		-- 		Text = if (packData.Prerequisite and packData.Prerequisite.Area)
		-- 			then "Unlock " .. Template.Areas[packData.Prerequisite.Area].Name
		-- 			else "",
		-- 		AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
		-- 		BackgroundTransparency = 1,
		-- 		TextXAlignment = 0,
		-- 		TextScaled = true,
		-- 		Position = UDim2.fromScale(-0.618, 0.337),
		-- 		TextSize = 14,
		-- 		Size = UDim2.fromScale(0.659, 1),
		-- 		ZIndex = 2,
		-- 	}, {
		-- 		UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
		-- 	}),
		-- 	NeedText = Roact.createElement("TextLabel", {
		-- 		LayoutOrder = 1,
		-- 		TextWrapped = true,
		-- 		TextColor3 = Color3.fromHex("ffffff"),
		-- 		Text = "Prerequisite: ",
		-- 		AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
		-- 		BackgroundTransparency = 1,
		-- 		TextXAlignment = 0,
		-- 		TextScaled = true,
		-- 		Position = UDim2.fromScale(-0.618, 0.337),
		-- 		TextSize = 14,
		-- 		Size = UDim2.fromScale(0.659, 1),
		-- 		ZIndex = 2,
		-- 	}, {
		-- 		UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
		-- 	}),
		-- 	List = Roact.createElement("UIListLayout", { VerticalAlignment = 0, FillDirection = 0, SortOrder = 2 }),
		-- }),

		Stock = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.27, 0.31),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.18, 0.13),
			Visible = packData.Stock ~= nil,
		}, {
			StockText = Roact.createElement("TextLabel", {
				LayoutOrder = 1,
				TextWrapped = true,
				TextColor3 = stockCount == 0 and Color3.fromHex("aaaaaa") or Color3.fromHex("ffffff"),
				Text = `x{stockCount} in stock`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(-0.618, 0.337),
				TextSize = 14,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("191919"), Thickness = 1.5 }),
			}),
			List = Roact.createElement("UIListLayout", { VerticalAlignment = 0, FillDirection = 0, SortOrder = 2 }),
		}),

		Ratio = Roact.createElement("UIAspectRatioConstraint", { AspectRatio = 4.5 }),

		UIStroke = Roact.createElement("UIStroke", { Color = strokeColor or Color3.fromHex("2f7dc5"), Thickness = 2 }),

		Item = Roact.createElement("ImageLabel", {
			ScaleType = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = packImage,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.147, 0.931),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 2,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1.8, 1.8),
			[Roact.Event.MouseEnter] = function()
				TooltipController:SetSize(UDim2.fromScale(0.2, 0.28))
				TooltipController:SetText(string.format("%s", CreateHoverDescription(packData)))
			end,
			[Roact.Event.MouseLeave] = function()
				TooltipController:SetText(nil)
			end,
		}, {
			Ratio = Roact.createElement("UIAspectRatioConstraint", { AspectRatio = 0.6 }),
		}),

		NameText = Roact.createElement("TextLabel", {
			LayoutOrder = 1,
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = packData.Name,
			TextScaled = true,
			AnchorPoint = Vector2.new(1, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			TextXAlignment = 1,
			Position = UDim2.fromScale(0.98, 0.21),
			ZIndex = 5,
			TextSize = 14,
			Size = UDim2.fromScale(0.657, 0.26),
		}, {
			UIStroke = Roact.createElement("UIStroke", { Color = Color3.fromHex("133451"), Thickness = 2 }),
		}),
	})
end

PackCard = RoactHooks.new(Roact)(PackCard)
return PackCard
