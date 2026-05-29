-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local CoachItem = require(script.Parent.CoachItem)

local function Coaches(_, hooks)
	local CoachReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.CoachReducer
	end)

	local coachesData = {
		{
			id = 1,
			name = "Jos Morningho",
			image = "rbxassetid://132492458278010",
			multiplier = "x1.8",
			order = 1,
		},
		{
			id = 2,
			name = "Saar Alex Ferguyon",
			image = "rbxassetid://93124647412669",
			multiplier = "x3",
			order = 2,
		},
	}

	local children = {
		List = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0.03, 0),
			FillDirection = 0,
			HorizontalAlignment = 0,
			SortOrder = 2,
		}),
	}

	for _, coach in ipairs(coachesData) do
		local isBought = CoachReducer.Coaches and table.find(CoachReducer.Coaches, coach.id) ~= nil

		children[tostring(coach.id)] = Roact.createElement(CoachItem, {
			name = coach.name,
			image = coach.image,
			multiplier = coach.multiplier,
			bought = isBought,
			order = coach.order,
		})
	end

	return Roact.createElement("Frame", {
		LayoutOrder = 4,
		Position = UDim2.fromScale(0, 0.013),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.66),
	}, children)
end

return RoactHooks.new(Roact)(Coaches)
