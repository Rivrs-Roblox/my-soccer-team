local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local DataCacheController = Knit.GetController("DataCacheController")

local Template = DataCacheController:GetFile("Template")

local CustomizeConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.CustomizeConstants)

local CoachCard = require(script.Parent.CoachCard)

function Coaches(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)
	local CoachReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.CoachReducer
	end)

	local CoachesCards = {}
	if Template and Template.Coaches then
		for index, coach in pairs(Template.Coaches) do
			CoachesCards[index] = CoachCard({
				id = index,
				name = coach.DisplayName or coach.Name,
				image = coach.Image,
				price = coach.Price or 0,
				multiplier = coach.Multiplier or 1,
				order = coach.Order or index,
				equipped = (CoachReducer.CurrentCoach == index),
				owned = (CoachReducer.Coaches and table.find(CoachReducer.Coaches, index) ~= nil) or false,
				vip = coach.VIP or false,
				chest = coach.Chest or false,
			})
		end
	end

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentCustomizeUI == CustomizeConstants.Coaches,
		BorderColor3 = Color3.fromHex("000000"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		ZIndex = 2,
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
				VerticalAlignment = 0,
				FillDirection = 0,
				Padding = UDim.new(0.02, 0),
				SortOrder = 2,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://115335335147337",
				Size = UDim2.fromScale(1.2, 1.2),
				LayoutOrder = 1,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			ButtonText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Coaches",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				Position = UDim2.fromScale(0.549, 1),
				ZIndex = 5,
				TextSize = 14,
				Size = UDim2.fromScale(0.8, 1),
				LayoutOrder = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(20, 55, 88),
					Thickness = 2,
				}),
			}),
		}),
		Scroll = Roact.createElement("ScrollingFrame", {
			AutomaticCanvasSize = 3,
			ScrollBarThickness = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.98),
			Size = UDim2.fromScale(0.95, 0.705),
			ScrollBarImageTransparency = 0.32,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromScale(0, 2.8),
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0.03, 0),
			}),
			Grid = Roact.createElement("UIGridLayout", {
				FillDirectionMaxCells = 4,
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.245, 0.58),
				CellPadding = UDim2.fromScale(0, 0.04),
			}),
			Roact.createFragment(CoachesCards),
		}),
	})
end

Coaches = RoactHooks.new(Roact)(Coaches)
return Coaches
