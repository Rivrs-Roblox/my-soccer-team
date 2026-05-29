--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local CloseButton = require(Components.CloseButton)
local AspectRatio = require(Components.AspectRatio)
local Title = require(Components.Main.Title)

-- UI
local DataCacheController = Knit.GetController("DataCacheController")
local UIController = Knit.GetController("UIController")
local UI = DataCacheController:GetFile("Images")

return function(params: table, children)
	setmetatable(params, {
		__index = {
			title = "" :: string,
			condition = false :: boolean,
			size = UDim2.fromScale(0.5, 0.5),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.2,
			align = Enum.TextXAlignment.Center,
			color = Color3.fromRGB(255, 255, 255),
			action = function()
				UIController:HideFrame()
			end,
		},
	})

	return Roact.createElement("ImageLabel", {
		Name = "__UIPanelRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = params.pos,
		Size = params.size,
		Visible = params.condition,
		BackgroundTransparency = 1,
	}, {
		Ratio = AspectRatio({ ratio = params.ratio }),
		Close = CloseButton(params.action, params.hooks, { pos = UDim2.fromScale(0.95, -0.08) }),

		TitleShadow = Title({ title = params.title, shadow = true, align = params.align }),
		TextTitle = Title({ title = params.title, align = params.align }),

		Background = Roact.createElement("Frame", {
			ClipsDescendants = true,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0.03, 0),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("232323"),
				Thickness = 4,
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.1, 0),
					NumberSequenceKeypoint.new(1, 0.1, 0),
				}),
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("000000")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("2b2b2b")),
				}),
			}),
			Stripes = Roact.createElement("ImageLabel", {
				ImageColor3 = Color3.fromHex("000000"),
				Image = "rbxassetid://126987589003079",
				BackgroundTransparency = 1,
				ImageTransparency = 0.8,
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(2, 2),
			}),
		}),

		Children = Roact.createFragment(children),
	})
end
