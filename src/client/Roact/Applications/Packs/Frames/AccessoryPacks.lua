local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local PackConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.PackConstants)
local PackCard = require(script.Parent.PackCard)

local function AccessoryPacks(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = UIReducer.CurrentPacksUI == PackConstants.Accessories,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BorderColor3 = Color3.fromHex("000000"),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		Title = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.04, 0.08),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.55, 0.09),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Top,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.02, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			TitleText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Accessory Packs",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromScale(0.549, 1),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(0.8, 1),
				LayoutOrder = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://124847512307439",
				Size = UDim2.fromScale(1.2, 1.2),
				LayoutOrder = 1,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Center = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.98),
			LayoutOrder = 2,
			Size = UDim2.fromScale(0.95, 0.723),
		}, {
			["1"] = Roact.createElement(PackCard, { PackId = "1", Category = "Accessories", LayoutOrder = 1 }),
			["2"] = Roact.createElement(PackCard, { PackId = "2", Category = "Accessories", LayoutOrder = 2 }),
			List = Roact.createElement("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0.04, 0),
			}),
		}),
	})
end

AccessoryPacks = RoactHooks.new(Roact)(AccessoryPacks)
return AccessoryPacks
