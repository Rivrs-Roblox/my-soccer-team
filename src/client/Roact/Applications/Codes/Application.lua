--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local White_Background = require(Components.Main.White_Background)
local Text = require(Components.Text)
local AspectRatio = require(Components.AspectRatio)
local List = require(Components.List)

-- Frames
local Frames = script.Parent
local Item = require(Frames.Item)

-- Constants
local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

-- Codes
function Codes(_, hooks)
    local UIReducer = RoduxHooks.useSelector(hooks, function(state) return state.UIReducer end)

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1
    }, {
        Content = White_Background({
            title = "Verification",
            size = UDim2.fromScale(0.5, 0.5),
            pos = UDim2.fromScale(0.5, 0.5),
            ratio = 1.5,
            condition = UIReducer.CurrentUI == FramesConstants.Codes,
            align = Enum.TextXAlignment.Left,
            hooks = hooks
        }, {
            Container = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.52),
                Size = UDim2.fromScale(0.95, 0.87),
                BackgroundTransparency = 1
            }, {
                AspectRatio = AspectRatio({ ratio = 1.65 }),
                List = List({ padding = UDim.new(0.03), fillDirection = Enum.FillDirection.Vertical, horizontalAlignment = Enum.HorizontalAlignment.Center, verticalAlignment = Enum.VerticalAlignment.Top }),

                CodesTitle = Text({ text = "Codes", color = Color3.fromRGB(255, 255, 255), size = UDim2.fromScale(0.174, 0.076), backgroundTransparency = 1, stroke = 2.487, order = 1 }),
                Codes = Item({ text = "Follow our socials for limited time codes & rewards!", buttonText = "Redeem", placeholder = "Enter Codes", img = "Pets", type = "Codes", hooks = hooks, order = 2, gradient = { startC = Color3.fromRGB(0, 170, 255), endC = Color3.fromRGB(0, 170, 255) } }),

                VerifyTitle = Text({ text = "Verify", color = Color3.fromRGB(255, 255, 255), size = UDim2.fromScale(0.174, 0.076), backgroundTransparency = 1, stroke = 2.487, order = 3 }),
                Verify = Item({ text = "Follow our socials for a +100% Power Boost: @RivrsGames", buttonText = "Verify", placeholder = "Enter Name", img = "Cross", type = "Verify", hooks = hooks, order = 4, gradient = { startC = Color3.fromRGB(255, 200, 0), endC = Color3.fromRGB(255, 255, 0) } })
            })
        })
    })
end

Codes = RoactHooks.new(Roact)(Codes)
return Codes