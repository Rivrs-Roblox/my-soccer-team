local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)

local Helpers = ReplicatedStorage.Shared.Helpers
local Size = require(Helpers.Size)

local DataCacheController = Knit.GetController("DataCacheController")

local UI = DataCacheController:GetFile("Images")
local AutoButton = require(script.Parent.Parent.Components.AutoButton)

function BottomFrame(_, hooks)
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.99),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.2, 0.117),
	}, {
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.05, 0),
				FillDirection = 0,
			}),
			AutoPass = Roact.createElement(AutoButton, {
				ActionName = "Pass",
				LayoutOrder = 1,
				Icon = UI.Pass,
			}),
			AutoShoot = Roact.createElement(AutoButton, {
				ActionName = "Shoot",
				LayoutOrder = 2,
				Icon = UI.Shoot,
			}),
			AutoDribble = Roact.createElement(AutoButton, {
				ActionName = "Dribble",
				LayoutOrder = 3,
				Icon = UI.Dribble,
			}),
			AutoStamina = Roact.createElement(AutoButton, {
				ActionName = "Stamina",
				LayoutOrder = 4,
				Icon = UI.Stamina,
			}),
		}),
		Text = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("fafafa"),
			Text = "Auto (Free!)",
			AnchorPoint = Vector2.new(0.5, 1),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, -0.05),
			TextSize = 14,
			ZIndex = 1,
			TextScaled = true,
			Size = UDim2.fromScale(0.85, 0.3),
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("8a1616"),
				Thickness = 1.5,
			}),
		}),
	})
end

BottomFrame = RoactHooks.new(Roact)(BottomFrame)
return BottomFrame
