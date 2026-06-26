local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)

local Helpers = ReplicatedStorage.Shared.Helpers
local Size = require(Helpers.Size)

local Colors = require(ReplicatedStorage.Shared.Data.Colors)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local AutoController = Knit.GetController("AutoController")

local function AutoButton(props, hooks)
	local actionName = props.ActionName
	local layoutOrder = props.LayoutOrder
	local icon = props.Icon
	
	local styles, api = RoactSpring.useSpring(hooks, function()
		return {
			sizeAlpha = 1,
			rotation2 = 0,
		}
	end)

	local AutoReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.AutoReducer
	end)

	local isAutoTrainingOn = AutoReducer.AutoTraining and AutoReducer.AutoTrainingCurrent == actionName

	local gradientColors = isAutoTrainingOn and Colors.Gradients.AutoTrainOn or Colors.Gradients.AutoTrainOff
	local strokeColor = isAutoTrainingOn and Colors.Stroke.AutoTrainOn or Colors.Stroke.AutoTrainOff

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderColor3 = Color3.fromHex("000000"),
		LayoutOrder = layoutOrder,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.8, 0.8),
	}, {
		Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
		Button = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BorderColor3 = Color3.fromHex("000000"),
			Size = Size(styles, { X = 1, Y = 1 }),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				if isAutoTrainingOn then
					AutoController:RequestStopTraining()
				else
					AutoController:RequestAutoTraining(actionName)
				end
			end,

			[Roact.Event.MouseEnter] = function()
				api.start({ sizeAlpha = 1.05, rotation2 = 35, config = { mass = 1, tension = 1000, friction = 50 } })
			end,

			[Roact.Event.MouseLeave] = function()
				api.start({ sizeAlpha = 1, rotation2 = 0, config = { mass = 1, tension = 1000, friction = 50 } })
			end,

			[Roact.Event.MouseButton1Down] = function()
				api.start({ sizeAlpha = 0.95 })
			end,

			[Roact.Event.MouseButton1Up] = function()
				api.start({ sizeAlpha = 1 })
			end,
		}, {
			ButtonText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = actionName,
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
				Visible = false,
				Position = UDim2.fromScale(0.95, 0.1),
				BackgroundColor3 = Color3.fromHex("ff0000"),
				ZIndex = 10000,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.35, 0.35),
			}, {
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					ScaleType = 3,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					ZIndex = 2,
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
					ColorSequenceKeypoint.new(0, gradientColors.startColor),
					ColorSequenceKeypoint.new(1, gradientColors.endColor),
				}),
				Rotation = 90,
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = strokeColor,
				Thickness = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.4),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = icon,
				Rotation = styles.rotation2,
				Size = UDim2.fromScale(0.7, 0.7),
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

return RoactHooks.new(Roact)(AutoButton)
