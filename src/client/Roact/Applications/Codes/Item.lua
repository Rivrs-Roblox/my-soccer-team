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

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Corner = require(Components.Corner)
local Gradient = require(Components.Gradient)
local Stroke = require(Components.Stroke)
local Text = require(Components.Text)
local GreenButton = require(Components.Buttons.GreenButton)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local CodesController = Knit.GetController("CodesController")

-- UI
local UI = DataCacheController:GetFile("Images")

-- Item
return function(params: table)
    setmetatable(params, {
        __index = {
            text = "" :: string,
            buttonText = "" :: string,
            placeholder = "" :: string,
            img = "" :: string,
            type = "" :: string,
            hooks = nil,
            order = 0,
            gradient = {
                startC = Color3.fromRGB(255, 255, 255),
                endC = Color3.fromRGB(255, 255, 255)
            }
        }
    })

    local ref = params.hooks.useValue(Roact.createRef())
    local text, setText = params.hooks.useState("")

    params.hooks.useEffect(function()
        local search = ref.value:getValue()

        local codesConnection = search:GetPropertyChangedSignal("Text"):Connect(function() setText(string.lower(search.Text)) end)
        
        return function()
            codesConnection:Disconnect()
        end
    end, {})

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromScale(0.95, 0.357),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        LayoutOrder = params.order
    }, {
        Gradient = Gradient({ startColor = params.gradient.startC, endColor = params.gradient.endC, rotation = 90 }),
        Corner = Corner({ radius = 0.1 }),
        Stroke = Stroke({ thick = 3.5 }),

        SearchBar = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = UI.Background,
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.767, 0.712),
            Size = UDim2.fromScale(0.431, 0.465)
        }, {
            TextBox = Roact.createElement("TextBox", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                CursorPosition = -1,
                Position = UDim2.fromScale(0.6, 0.45),
                Size = UDim2.fromScale(0.676, 0.433),
                PlaceholderText = params.placeholder,
                Text = "",
                TextEditable = true,
                FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"),
                TextScaled = true,
                TextTransparency = 0.75,
                TextXAlignment = Enum.TextXAlignment.Left,

                [Roact.Ref] = ref.value
            }),

            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = UI[params.img],
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.14, 0.486),
                Size = UDim2.fromScale(0.144, 0.678),
                ImageTransparency = 0.88,
                ImageColor3 = Color3.fromRGB(0, 0, 0),
                ScaleType = Enum.ScaleType.Fit
            })
        }),

        Button = GreenButton({ text = params.buttonText, pos = UDim2.fromScale(0.804, 0.252), size = UDim2.fromScale(0.355, 0.411), action = function()
            if params.type == "Codes" then
                CodesController:Redeem(text)
            elseif params.type == "Verify" then
                CodesController:Verify(text)
            end
        end, hooks = params.hooks }),

        Text = Text({ text = params.text, backgroundTransparency = 1, color = Color3.fromRGB(255, 255, 255), position = UDim2.fromScale(0.23, 0.478), size = UDim2.fromScale(0.403, 0.792), align = Enum.TextXAlignment.Left, stroke = 2.2 })
    })
end