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
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local Roact = require(ReplicatedStorage.Packages.roact)
local roactSpring = require(ReplicatedStorage.Packages.RoactSpring)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local UIController = Knit.GetController("UIController")

-- UI
local UI = DataCacheController:GetFile("Images")

local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Components
local TextButton = require(script.Parent.TextButton)
local Gradient = require(script.Parent.Gradient)
local Image = require(script.Parent.Image)
local Text = require(script.Parent.Text)

local function TopLargeDisplay(props, hooks)
	setmetatable(props, {
		__index = {
			image = "",
			mainText = "",
			bottomText = "",
			order = 1,
			numScrollAdjust = 1,
			hooks = nil,
			noButton = false,
		},
	})

	if hooks then
		local springApiState, setSpringApiState = hooks.useState(nil)

		-- Initialize spring
		local styles, api = roactSpring.useSpring(hooks, function()
			return {
				nbToDisplay = props.mainText,
			}
		end)

		-- Store the api reference when it's created
		--[[hooks.useEffect(function()
            if not springApiState then
                setSpringApiState(api)
            end

            return function()
                if springApiState then
                    springApiState.stop()
                end
            end
        end, {})]]

		-- Consolidated animation function
		local function animate(props)
			if springApiState then
				springApiState.start(props)
			end
		end

		-- Update number display when mainText changes
		--[[hooks.useEffect(function()
            --[[animate({
                nbToDisplay = props.mainText,
                config = { tension = 300, friction = 20 }
            })
        end, { props.mainText })]]

		return Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.7, 1),
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = props.order,
		}, {
			Frame = Roact.createElement("Frame", {
				BackgroundTransparency = 0.3,
				ClipsDescendants = true,
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("1f1f1f"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("282828"),
					Thickness = 2,
				}),
				Stripes = Roact.createElement("ImageLabel", {
					ImageTransparency = 0.95,
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Image = UI.Stripes,
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundColor3 = Color3.fromHex("ffffff"),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
				}),
			}),

			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 4,
				AspectType = Enum.AspectType.FitWithinMaxSize,
				DominantAxis = Enum.DominantAxis.Width,
			}),

			Button = if not props.noButton
				then TextButton({
					text = "+",
					pos = UDim2.fromScale(0.902, 0.439),
					size = UDim2.fromScale(0.1, 0.8),
					index = 4,
					children = {
						UIGradient = Gradient({ endColor = Color3.fromRGB(255, 206, 10), roatation = 0 }),
					},
					action = function()
						if props.bottomText ~= "Rebirths" then
							UIController:ShowFrame({ frame = "Store" })
							UIController:RemoveHUD({ ignoreTopFrame = true })
							UIController:ChangeShopCanvaPosition(props.numScrollAdjust)
						else
							UIController:ShowFrame({ frame = "Rebirth" })
							UIController:RemoveHUD({ ignoreTopFrame = true })
						end
					end,
				})
				else nil,

			Icon = Image({
				image = props.image,
				position = UDim2.fromScale(0.074, 0.496),
				size = UDim2.fromScale(0.282, 1.2),
				backgroundTransparency = 1,
				children = {
					Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 1,
						AspectType = Enum.AspectType.FitWithinMaxSize,
						DominantAxis = Enum.DominantAxis.Width,
					}),
				},
			}),

			mainText = Text({
				text = FormatNumber(math.round(props.mainText)),
				position = UDim2.fromScale(0.541, 0.484),
				size = UDim2.fromScale(0.494, 0.462),
				stroke = 1.75,
				color = Color3.fromRGB(255, 255, 255),
				children = {
					UIGradient = Gradient({
						startColor = Color3.fromRGB(255, 200, 0),
						endColor = Color3.fromRGB(255, 255, 0),
						roatation = 90,
					}),
				},
				index = 2,
			}),

			bottomText = Text({
				text = props.bottomText,
				position = UDim2.fromScale(0.497, 1.294),
				size = UDim2.fromScale(0.4, 0.5),
				stroke = 1.5,
				color = Color3.fromRGB(255, 255, 255),
				visible = props.bottomText ~= "",
			}),
		})
	end
end

TopLargeDisplay = RoactHooks.new(Roact)(TopLargeDisplay)
return TopLargeDisplay
