--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Text = require(Components.Text)
local AspectRatio = require(Components.AspectRatio)
local Blue_Background = require(Components.Main.Blue_Background)

-- Frames
local Frames = script.Parent.Frames
local Row = require(Frames.Row)
local MultiplierIcons = require(Frames.MultiplierIcons)

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local MonetizationController = Knit.GetController("MonetizationController")
local StoreController = Knit.GetController("StoreController")
local RebirthController = Knit.GetController("RebirthController")

-- UI
local Template = DataCacheController:GetFile("Template")
local RebirthTable = DataCacheController:GetFile("RebirthTable")
local UI = DataCacheController:GetFile("Images")

local function getRebirthRequirement(rebirth: number)
	if rebirth < #RebirthTable then
		return RebirthTable[rebirth]
	end

	return RebirthTable[#RebirthTable] * math.pow(1.3, rebirth - #RebirthTable)
end

local function BlueButton(params: {})
	setmetatable(params, {
		__index = {
			text = "Button",
			price = "",
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.45, 1),
			layoutOrder = 1,
			action = function() end,
		},
	})

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Position = params.position,
		Size = params.size,
		LayoutOrder = params.layoutOrder,
		AutoButtonColor = true,
		ZIndex = 5,
		[Roact.Event.MouseButton1Click] = function()
			Sound:PlaySound("UI_Click")
			params.action()
		end,
	}, {
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("377df4")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("1f44b6")),
			}),
			Rotation = 90,
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("334695"),
			Thickness = 2,
		}),
		ButtonText = Text({
			text = params.text,
			color = Color3.fromHex("fafafa"),
			position = UDim2.fromScale(0.05, 0.5),
			size = UDim2.fromScale(0.5, 0.45),
			anchorPoint = Vector2.new(0, 0.5),
			align = Enum.TextXAlignment.Left,
			stroke = 1.5,
			strokeColor = Color3.fromHex("15284c"),
			index = 6,
		}),
		PriceText = Text({
			text = params.price,
			color = Color3.fromHex("ffffff"),
			position = UDim2.fromScale(0.95, 0.5),
			size = UDim2.fromScale(0.5, 0.45),
			anchorPoint = Vector2.new(1, 0.5),
			align = Enum.TextXAlignment.Right,
			stroke = 1.5,
			strokeColor = Color3.fromHex("15284c"),
			index = 6,
		}),
	})
end

local function RebirthButton(params: {})
	setmetatable(params, {
		__index = {
			text = "Rebirth",
			action = function() end,
			layoutOrder = 3,
		},
	})

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.3, 0.6),
		LayoutOrder = params.layoutOrder,
		AutoButtonColor = true,
		ZIndex = 5,
		[Roact.Event.MouseButton1Click] = function()
			Sound:PlaySound("UI_Click")
			params.action()
		end,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("334695"),
			Thickness = 2,
		}),
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("3699ef")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("103db0")),
			}),
			Rotation = 90,
		}),
		ButtonText = Text({
			text = params.text,
			color = Color3.fromHex("fafafa"),
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.9, 0.55),
			stroke = 0,
			strokeColor = Color3.fromHex("15284c"),
			index = 6,
		}),
	})
end

-- Rebirth
function Rebirth(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local PlayerReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.PlayerReducer
	end)

	local currentRebirth = PlayerReducer.Rebirth or 0
	local nextRebirth = currentRebirth + 1
	local rebirthRequirement = getRebirthRequirement(nextRebirth)

	local currentShoot = PlayerReducer.Shoot or 0
	local currentPass = PlayerReducer.Pass or 0
	local currentDribble = PlayerReducer.Dribble or 0

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = UIReducer.CurrentUI == FramesConstants.Rebirth,
	}, {
		Content = Blue_Background({
			title = "Rebirth",
			titleIcon = UI.Rebirth,
			size = UDim2.fromScale(0.7, 0.7),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.3,
			condition = UIReducer.CurrentUI == FramesConstants.Rebirth,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
		}, {

			Top = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.638, 0.08),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.49, 0.09),
			}, {
				Skip1 = BlueButton({
					text = "Skip 1",
					price = `{Template.Messages.Robux_Icon} {MonetizationController:GetPrice("Rebirth - Skip 1")}`,
					layoutOrder = 2,
					action = function()
						StoreController:BuyItem({ name = "Rebirth - Skip 1" })
					end,
				}),
				Skip5 = BlueButton({
					text = "Skip 5",
					price = `{Template.Messages.Robux_Icon} {MonetizationController:GetPrice("Rebirth - Skip 5")}`,
					layoutOrder = 3,
					action = function()
						StoreController:BuyItem({ name = "Rebirth - Skip 5" })
					end,
				}),
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 2,
					Padding = UDim.new(0.03, 0),
					FillDirection = 0,
				}),
			}),

			Center = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.335),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.9, 0.3),
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("ffffff")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("91acde")),
					}),
					Rotation = 90,
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
				InfoText = Text({
					text = "Complete all training to rebirth",
					color = Color3.fromHex("fafafa"),
					stroke = 2,
					position = UDim2.fromScale(0.5, 0.12),
					size = UDim2.fromScale(0.9, 0.14),
					order = 5,
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Thickness = 2,
					Transparency = 0.5,
				}),
				RebirthStats = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.42),
					LayoutOrder = 1,
					BackgroundColor3 = Color3.fromHex("c7c7c7"),
					Size = UDim2.fromScale(1, 0.25),
				}, {
					CurrentText = Text({
						text = `Lv. {currentRebirth}`,
						color = Color3.fromHex("ffffff"),
						stroke = 2,
						position = UDim2.fromScale(0.27, 0.5),
						size = UDim2.fromScale(0.35, 1),
						index = 2,
						order = 1,
						align = Enum.TextXAlignment.Right,
					}),
					NextText = Text({
						text = `Lv. {nextRebirth}`,
						color = Color3.fromHex("1aff00"),
						stroke = 2,
						position = UDim2.fromScale(0.831, 0.5),
						size = UDim2.fromScale(0.35, 1),
						index = 2,
						order = 4,
						align = Enum.TextXAlignment.Left,
					}),
					Arrow = Roact.createElement("ImageLabel", {
						ImageColor3 = Color3.fromHex("ffcc00"),
						ScaleType = 3,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = "rbxassetid://80017826073371",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						LayoutOrder = 2,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						Size = UDim2.fromScale(1, 1),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.03, 0),
						FillDirection = 0,
					}),
				}),
				MultiplierStats = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.75),
					LayoutOrder = 1,
					BackgroundColor3 = Color3.fromHex("c7c7c7"),
					Size = UDim2.fromScale(1, 0.25),
				}, {
					CurrentText = Text({
						text = "+" .. tostring(currentRebirth * 20) .. "%",
						color = Color3.fromHex("ffffff"),
						stroke = 2,
						position = UDim2.fromScale(0.27, 0.5),
						size = UDim2.fromScale(0.13, 1),
						index = 2,
						order = 2,
					}),
					NextText = Text({
						text = "+" .. tostring(nextRebirth * 20) .. "%",
						color = Color3.fromHex("1aff00"),
						stroke = 2,
						position = UDim2.fromScale(0.831, 0.5),
						size = UDim2.fromScale(0.13, 1),
						index = 2,
						order = 5,
					}),
					Arrow = Roact.createElement("ImageLabel", {
						ImageColor3 = Color3.fromHex("ffcc00"),
						ScaleType = 3,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = "rbxassetid://80017826073371",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						LayoutOrder = 3,
						BackgroundColor3 = Color3.fromHex("ffffff"),
						Size = UDim2.fromScale(1, 1),
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
					NextIcons = MultiplierIcons({
						order = 4,
					}),
					CurrentIcons = MultiplierIcons({
						order = 1,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.03, 0),
						FillDirection = 0,
					}),
				}),
			}),

			Stats = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.655),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.9, 0.3),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					FillDirection = 0,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.02, 0),
					SortOrder = 2,
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("8999c7"),
					Thickness = 2,
				}),
				Shooting = Row({
					name = "Shooting",
					image = UI.Shoot,
					currentValue = currentShoot,
					nextValue = rebirthRequirement,
					layoutOrder = 2,
				}),
				Passing = Row({
					name = "Passing",
					image = UI.Pass,
					currentValue = currentPass,
					nextValue = rebirthRequirement,
					layoutOrder = 1,
				}),
				Dribbling = Row({
					name = "Dribbling",
					image = UI.Dribble,
					currentValue = currentDribble,
					nextValue = rebirthRequirement,
					layoutOrder = 3,
				}),
			}),

			Bottom = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.902),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.9, 0.145),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = 0,
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.1, 0),
				}),
				RebirthButton = RebirthButton({
					text = "Rebirth",
					layoutOrder = 1,
					action = function()
						RebirthController:Rebirth()
					end,
				}),
				WarningText = Text({
					text = "Warning: Rebirth will reset your training stats",
					color = Color3.fromHex("ffd900"),
					stroke = 2,
					strokeColor = Color3.fromHex("000000"),
					position = UDim2.fromScale(0.623, 0.25),
					size = UDim2.fromScale(0.9, 0.24),
					index = 2,
					order = 2,
				}),
			}),
		}),
	})
end

Rebirth = RoactHooks.new(Roact)(Rebirth)
return Rebirth
