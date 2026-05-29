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

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Text = require(Components.Text)
local AspectRatio = require(Components.AspectRatio)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")

-- UI
local UI = DataCacheController:GetFile("Images")

local function formatValue(value)
	return if type(value) == "number" then FormatNumber(value) else value
end

local function getIcon(name: string)
	local icon = UI[name]
	if icon and string.sub(icon, 1, 10) == "rbxassetid" then
		return icon
	end

	return UI[icon or name]
end

-- Row
return function(params: {})
	setmetatable(params, {
		__index = {
			name = "" :: string,
			image = "" :: string,
			currentValue = 0,
			nextValue = 0,
			layoutOrder = 1,
		},
	})

	local ratio = if params.nextValue > 0 then math.clamp(params.currentValue / params.nextValue, 0, 1) else 0
	local percentage = math.round(ratio * 100)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.361),
		LayoutOrder = params.layoutOrder,
		BackgroundColor3 = Color3.fromHex("ffffff"),
		Size = UDim2.fromScale(0.32, 1),
	}, {
		Completed = Roact.createElement("Frame", {
			Visible = params.currentValue >= params.nextValue,
			LayoutOrder = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 9,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("60ff60")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("00a71c")),
				}),
				Rotation = 90,
			}),
			CompletedText = Text({
				text = "Completed",
				color = Color3.fromHex("ffffff"),
				stroke = 2,
				strokeColor = Color3.fromHex("000000"),
				position = UDim2.fromScale(0.5, 0.65),
				size = UDim2.fromScale(0.85, 0.3),
				index = 10,
			}),
		}),
		Line = Roact.createElement("Frame", {
			LayoutOrder = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.3),
			BackgroundColor3 = Color3.fromHex("000000"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 4),
		}),
		Title = Roact.createElement("Frame", {
			LayoutOrder = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.05),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 10,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0.2),
		}, {
			TitleText = Text({
				text = params.name,
				color = Color3.fromHex("ffffff"),
				stroke = 2,
				strokeColor = Color3.fromHex("000000"),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(0.5, 0.85),
				index = 11,
				order = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = params.image,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ScaleType = 3,
				ZIndex = 11,
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			List = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.02, 0),
				FillDirection = 0,
			}),
		}),
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Thickness = 2,
			Transparency = 0.5,
		}),
		ProgressBar = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromScale(0.5, 0.75),
			BackgroundColor3 = Color3.fromHex("000000"),
			Size = UDim2.fromScale(0.85, 0.25),
		}, {
			ProgressText = Text({
				text = formatValue(params.currentValue) .. " / " .. formatValue(params.nextValue),
				color = Color3.fromHex("ffd900"),
				stroke = 2,
				strokeColor = Color3.fromHex("000000"),
				position = UDim2.fromScale(0.5, -0.2),
				size = UDim2.fromScale(1, 0.6),
				index = 2,
				anchorPoint = Vector2.new(0.5, 1),
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("296a17"),
				Thickness = 2,
			}),
			PercentageText = Text({
				text = `{percentage}%`,
				color = Color3.fromHex("ffffff"),
				stroke = 2,
				strokeColor = Color3.fromHex("000000"),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(0.8, 0.6),
				index = 2,
			}),
			Bar = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(ratio, 1),
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
				Gradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("32e900")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("188318")),
					}),
					Rotation = 90,
				}),
			}),
		}),
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("ffffff")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("91acde")),
			}),
			Rotation = 90,
		}),
	})
end
