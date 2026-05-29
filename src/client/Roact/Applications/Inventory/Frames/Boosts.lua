local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local InventoryConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.InventoryConstants)
local BoostCard = require(script.Parent.BoostCard)

local BoostService = Knit.GetService("BoostService")

local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

function Boosts(_, hooks)
	local BoostsReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.BoostsReducer
	end)
	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	local BoostCards = {}
	local numCards = 0

	if BoostsReducer and BoostsReducer.Boosts then
		for id, data in pairs(BoostsReducer.Boosts) do
			if data.Number and data.Number > 0 then
				numCards += 1
				local name = string.gsub(data.Name or "", "_", " ")

				BoostCards[tostring(id)] = BoostCard({
					id = id,
					name = name,
					amount = data.Number,
					image = UI[data.Name] or "rbxassetid://75217127752263",
					order = numCards,
					onClick = function()
						BoostService:Consume(id)
					end,
				})
			end
		end
	end

	local rows = math.max(1, math.ceil(numCards / 5))
	local canvasScaleY = (rows * 0.4) + ((rows - 1) * 0.07) + 0.03

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Visible = InventoryReducer.Inventory == InventoryConstants.Boosts,
		Size = UDim2.fromScale(1, 1),
	}, {
		Scroll = Roact.createElement("ScrollingFrame", {
			CanvasSize = UDim2.fromScale(0, math.max(1, canvasScaleY)),
			ScrollBarThickness = 8,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.98),
			ScrollingDirection = 2,
			ZIndex = 3,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.95, 0.705),
		}, {
			UIPadding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0.03, 0),
			}),
			Grid = Roact.createElement("UIGridLayout", {
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.2, 0.4),
				FillDirectionMaxCells = 5,
				CellPadding = UDim2.fromScale(0.02, 0.07),
				HorizontalAlignment = 0,
			}),
			Roact.createFragment(BoostCards),
		}),
		EmptyText = Roact.createElement("TextLabel", {
			Visible = numCards == 0,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(20, 55, 88),
			TextTransparency = 0.3,
			Text = "You have no boosts!",
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.6),
			TextSize = 14,
			ZIndex = 2,
			TextScaled = true,
			Size = UDim2.fromScale(0.8, 0.2),
		}),
	})
end

Boosts = RoactHooks.new(Roact)(Boosts)
return Boosts
