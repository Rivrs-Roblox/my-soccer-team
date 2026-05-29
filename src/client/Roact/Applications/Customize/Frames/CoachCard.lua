local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local CoachesController = Knit.GetController("CoachesController")
local StoreController = Knit.GetController("StoreController")
local MonetizationController = Knit.GetController("MonetizationController")

-- UI
local UI = DataCacheController:GetFile("Images")

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

return function(params: table)
	setmetatable(params, {
		__index = {
			id = 0 :: number,
			name = "" :: string,
			image = "" :: string,
			price = 0 :: number,
			multiplier = 0 :: number,
			order = 0 :: number,
			equipped = false :: boolean,
			owned = false :: boolean,
			vip = false :: boolean,
			chest = false :: boolean,
		},
	})
	return Roact.createElement("Frame", {
		LayoutOrder = params.order,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Position = UDim2.fromScale(0.02, 0.1),
		Size = UDim2.fromScale(0.96, 0.96),
		ZIndex = 2,
	}, {
		Effect = Roact.createElement("ImageLabel", {
			Visible = params.vip,
			ImageColor3 = Color3.fromHex("ffea74"),
			Image = "rbxassetid://106335669168445",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.4),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ScaleType = 3,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.7),
			TextSize = 14,
			ZIndex = 3,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.12),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = if params.vip
					then Color3.fromHex("833f20")
					elseif params.chest then Color3.fromRGB(35, 59, 139)
					else Color3.fromHex("2a6727"),
				Thickness = 2,
			}),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = if params.vip or params.chest then Color3.fromHex("ffffff") else Color3.fromHex("64ff35"),
			Thickness = 3,
		}),
		UIGradient = Roact.createElement("UIGradient", {
			Color = if params.vip
				then ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffe66b")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("ff491c")),
				})
				elseif params.chest then ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 119, 221)),
				})
				else ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("41c23a")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("246f25")),
				}),
			Rotation = 90,
		}),
		UICorner = Roact.createElement("UICorner", {}),
		Value = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(1, -0.053),
			BorderColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.9, 0.213),
		}, {
			ValueText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffd500"),
				Text = "x" .. params.multiplier,
				TextScaled = true,
				ZIndex = 3,
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 1,
				Position = UDim2.fromScale(0.761, 0.383),
				TextYAlignment = 2,
				TextSize = 14,
				Size = UDim2.fromScale(0.5, 0.65),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("313131"),
					Thickness = 2,
				}),
			}),
			Icon = Roact.createElement("ImageLabel", {
				LayoutOrder = 1,
				ScaleType = 3,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Multiplier,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.849, 0.15),
				ZIndex = 10,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			List = Roact.createElement("UIListLayout", {
				VerticalAlignment = 2,
				SortOrder = 2,
				HorizontalAlignment = 2,
				Padding = UDim.new(0.02, 0),
				ItemLineAlignment = 2,
				FillDirection = 0,
			}),
		}),
		Ratio = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.85,
		}),
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			ScaleType = 3,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.4),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 2,
			Image = params.image,
			Size = UDim2.fromScale(0.9, 0.9),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		Buy = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.88),
			Size = UDim2.fromScale(0.8, 0.18),
			ZIndex = 8,
			ClipsDescendants = true,
			BackgroundColor3 = if params.vip
				then Color3.fromHex("ffe13a")
				elseif params.chest then Color3.fromRGB(70, 196, 255)
				else Color3.fromHex("6cde46"),
			[Roact.Event.MouseButton1Down] = function()
				Sound:PlaySound("UI_Click")
				if params.equipped then
					CoachesController:UnequipCoach()
				elseif params.owned then
					CoachesController:EquipCoach(params.id)
				else
					if params.vip then
						StoreController:BuyItem({ name = "Coach - " .. params.name })
					elseif params.chest then
						-- do nothing
					else
						CoachesController:BuyCoach(params.id)
					end
				end
			end,
		}, {
			List = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.02, 0),
				FillDirection = 0,
			}),
			UICorner = Roact.createElement("UICorner", {}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = if params.vip
					then Color3.fromHex("fcffc4")
					elseif params.chest then Color3.fromRGB(187, 222, 255)
					else Color3.fromHex("c6f9c2"),
				Thickness = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				Visible = not params.owned and not params.vip and not params.chest,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Wins,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ScaleType = 3,
				Size = UDim2.fromScale(0.85, 0.85),
				ZIndex = 10,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			PriceText = Roact.createElement("TextLabel", {
				LayoutOrder = 2,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = if params.equipped
					then "Unequip"
					elseif params.owned then "Equip"
					elseif params.vip then ` {MonetizationController:GetPrice("Coach - " .. params.name)}`
					elseif params.chest then "Chest Exclusive"
					else FormatNumber(params.price),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				TextScaled = true,
				TextSize = 14,
				Size = UDim2.fromScale(0.588, 0.7),
				ZIndex = 10,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("313131"),
					Thickness = 1.5,
				}),
			}),
		}),
	})
end
