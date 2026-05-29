local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local CloseButton = require(Components.CloseButton)

local Knit = require(ReplicatedStorage.Packages.Knit)
local ExitGiftController = Knit.GetController("ExitGiftController")

function ExitGift(_, hooks)
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 1.35),
		LayoutOrder = 1,
		Size = UDim2.fromScale(0.7, 0.7),
		ZIndex = 50,
	}, {
		Close = CloseButton(function()
			ExitGiftController:HideFrame()
		end, hooks, { pos = UDim2.fromScale(1, 0.3) }),
		Label = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = "Open your FREE Gift!",
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.744),
			TextSize = 17,
			ZIndex = 6,
			TextScaled = true,
			Size = UDim2.fromScale(0.85, 0.15),
		}, {
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("ffffff"),
				Thickness = 4,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("59ff00")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("00360d")),
					}),
					Rotation = 90,
				}),
			}),
		}),
		Star = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://106335669168445",
			BackgroundTransparency = 1,
			ImageTransparency = 0.1,
			ZIndex = 2,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.1, 1.1),
		}, {
			UIGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("ffff00")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("ffc800")),
				}),
			}),
		}),
		Sparkle = Roact.createElement("ImageLabel", {
			ScaleType = 3,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://106466414055348",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			ZIndex = 4,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {}),
		Gift = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://135619375841555",
			BackgroundTransparency = 1,
			ImageTransparency = 0.1,
			ZIndex = 3,
			Position = UDim2.fromScale(0.5, 0.6),
			Size = UDim2.fromScale(0.7, 0.7),
		}),
	})
end

ExitGift = RoactHooks.new(Roact)(ExitGift)
return ExitGift
