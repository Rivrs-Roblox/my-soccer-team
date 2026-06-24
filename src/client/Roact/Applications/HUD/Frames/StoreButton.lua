local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Sound = require(ReplicatedStorage.Packages.Sound)

local Helpers = ReplicatedStorage.Shared.Helpers
local Size = require(Helpers.Size)

local function StoreButton(params: table, hooks)
	setmetatable(params, {
		__index = {
			image = "" :: string,
			onClick = function() end :: any,
			order = 0 :: number,
			value = "" :: string,
		},
	})

	local styles, api = RoactSpring.useSpring(hooks, function()
		return {
			sizeAlpha = 1,
			rotation2 = 0,
		}
	end)

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
		Vip = Roact.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BorderColor3 = Color3.fromHex("000000"),
			Size = Size(styles, { X = 1, Y = 1 }),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				if params.onClick then
					params.onClick()
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
			ValueText = Roact.createElement("TextLabel", {
				Visible = true,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffea00"),
				Text = params.value,
				AnchorPoint = Vector2.new(1, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.95, 0.95),
				TextSize = 14,
				ZIndex = 3,
				TextScaled = true,
				Size = UDim2.fromScale(0.45, 0.4),
			}, { UIStroke = Roact.createElement("UIStroke", {
				Thickness = 2,
			}) }),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffc800")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("8f0000")),
				}),
				Rotation = 90,
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffd900"),
				Thickness = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = params.image,
				Rotation = styles.rotation2,
				Size = UDim2.fromScale(0.85, 0.85),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
	})
end

StoreButton = RoactHooks.new(Roact)(StoreButton)
return StoreButton
