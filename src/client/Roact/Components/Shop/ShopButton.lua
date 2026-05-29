--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Components
local Components = StarterPlayerScripts.Client.Roact.Components
local Text = require(Components.Text)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local Size = require(Helpers.Size)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local StoreController = Knit.GetController("StoreController")
local UIController = Knit.GetController("UIController")

-- UI
local UI = DataCacheController:GetFile("Images")
local Colors = DataCacheController:GetFile("Colors")

-- ShopIcon
return function(params: table)
	setmetatable(params, {
		__index = {
			text = "" :: string,
			position = UDim2.fromScale(0.5, 0.5) :: UDim2,
			size = UDim2.fromScale(1, 1) :: UDim2,
			color = Color3.fromRGB(255, 255, 255) :: Color3,
			gradient = "Green" :: string,
			buy = "" :: string,
			disabled = false :: boolean,
			hooks = nil,
			children = {} :: table,
		},
	})

	local styles, api = RoactSpring.useSpring(params.hooks, function()
		return {
			sizeAlpha = 1,
		}
	end)

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = params.position,
		Size = Size(styles, { X = params.size.X.Scale, Y = params.size.Y.Scale }),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),

		[Roact.Event.MouseButton1Click] = function()
			if params.disabled == false then
				Sound:PlaySound("UI_Click")
				--SoundController:CreateSound(Players.LocalPlayer.Character, "UI_Click")
				StoreController:BuyItem({ name = params.buy })
				UIController:HideFrame()
			end
		end,

		[Roact.Event.MouseEnter] = function()
			api.start({ sizeAlpha = 1.1 })
		end,

		[Roact.Event.MouseLeave] = function()
			api.start({ sizeAlpha = 1 })
		end,

		[Roact.Event.MouseButton1Down] = function()
			api.start({ sizeAlpha = 0.8 })
		end,

		[Roact.Event.MouseButton1Up] = function()
			api.start({ sizeAlpha = 1 })
		end,
	}, {
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Colors.Gradients[params.gradient].startColor),
				ColorSequenceKeypoint.new(1, Colors.Gradients[params.gradient].endColor),
			}),
			Rotation = 90,
		}),

		BottomText = Text({
			text = params.text,
			position = UDim2.fromScale(0.5, 0.45),
			size = UDim2.fromScale(0.75, 0.75),
			color = Color3.fromRGB(255, 255, 255),
			backgroundTransparency = 1,
			stroke = 1.5,
			index = 3,
		}),

		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromHex("ffffff"),
			Thickness = 3,
		}),
		Block = Roact.createElement("ImageLabel", {
			ImageTransparency = 0.5,
			BorderColor3 = Color3.fromHex("000000"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://100383249081617",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
		}),

		Roact.createFragment(params.children),
	})
end
