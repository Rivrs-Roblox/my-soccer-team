--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local Size = require(Helpers.Size)
local SetInterval = require(Helpers.SetInterval)

-- Controllers
local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")

-- Components
local Image = require(script.Parent.Image)
local Text = require(script.Parent.Text)
local Notification = require(script.Parent.Notification)
local NotificationNoText = require(script.Parent.NotificationNoText)

local gradients = {
	Green = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("8dd389")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("26a200")),
	}),

	Blue = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("7db9e8")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("2a75bb")),
	}),
}

return function(params: table)
	setmetatable(params, {
		__index = {
			icon = "",
			text = "",
			textLabelSize = UDim2.fromScale(0.985, 0.278),
			textLabelPos = UDim2.fromScale(0.5, 0.925),
			pos = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(1, 1),
			order = 1,
			frame = "",
			visible = true,
			hooks = nil,
			notifs = 0,
			hover = true,
			aspectRatio = 1,
			animate = false,
			color = "Green",
		},
	})
	local styles, api = RoactSpring.useSpring(params.hooks, function()
		return {
			sizeAlpha = 1,
			rotation = 0,
			rotation2 = 0,
		}
	end)

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = params.pos,
		Size = params.size,
		LayoutOrder = params.order,
		Visible = params.visible,
	}, {
		Roact.createElement("ImageButton", {
			BackgroundColor3 = Color3.fromHex("ffffff"),
			Position = params.pos,
			Size = Size(styles, { X = 1, Y = 1 }),
			LayoutOrder = params.order,
			Visible = params.visible,
			[Roact.Event.MouseButton1Click] = function()
				if params.frame == "" then
					return
				end
				UIController:ShowFrame({ frame = params.frame })
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
				Sound:PlaySound("UI_Open")
			end,
		}, {

			Block = Roact.createElement("ImageLabel", {
				ImageTransparency = 0.7,
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = UI.Block,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			}),

			UIGradient = Roact.createElement("UIGradient", {
				Color = gradients[params.color] or gradients.Green,
				Rotation = 90,
			}),

			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("144414"),
				Thickness = 2,
			}),

			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = params.aspectRatio or 1,
			}),

			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),

			Icon = Image({
				image = params.icon,
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(0.75, 0.75),
				backgroundTransparency = 1,
				rotation = if params.animate == true then styles.rotation else styles.rotation2,
				children = {
					UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 1,
					}),
				},
				index = 3,
			}),

			Notification = if type(params.notifs) == "number"
				then NotificationNoText({ number = params.notifs })
				else Notification({ number = params.notifs }),

			Text = Text({
				text = params.text,
				position = params.textLabelPos,
				size = params.textLabelSize,
				color = Color3.fromRGB(250, 250, 250),
				stroke = 1.5,
				index = 5,
			}),
		}),
	})
end
