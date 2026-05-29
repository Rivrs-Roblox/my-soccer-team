--[=[
    Owner: JustStop__
    Version: 0.0.2
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local StoreController = Knit.GetController("StoreController")

-- Constants
local SeasonConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.SeasonConstants)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Grid = require(Components.Grid)

-- Frames
local Item = require(script.Parent.Parent.Components.Item)

-- Panels
local Panels = script.Parent.Parent
local Ticket = require(Panels.Rewards.Ticket)
local TotalXpSlider = require(Panels.Rewards.TotalXpSlider)

-- UI
local Template = DataCacheController:GetFile("Template")

local function createHoverDescription(exclusiveEgg)
    local hoverDescription = ""
    if exclusiveEgg and exclusiveEgg.Pets then
        for i, pet in ipairs(exclusiveEgg.Pets) do
            hoverDescription ..= pet.Name .. " - " .. pet.Chance .. "%"
            if i < #exclusiveEgg.Pets then
                hoverDescription ..= "\n"
            end
        end
    end
    return hoverDescription
end

local function toNum(v)
    local n = tonumber(v)
    return n or 0
end

-- Rewards
return function(hooks)
    -- Satu kali selector → parent yang subscribe
    local sel = RoduxHooks.useSelector(hooks, function(state)
        local s = state.SeasonReducer
        return {
            rewards = s.Rewards,
            level = s.Level,
            premium = s.Premium,
            claimedRewards = s.Claimed_Rewards,
            claimedPremiumRewards = s.Claimed_Premium_Rewards,
            currentSeasonPassUI = state.UIReducer.CurrentSeasonPassUI,
        }
    end)

    -- Bangun list dan urutkan berdasarkan Level (number)
    local list = {}
    local rewardsCount = 0
    for id, data in pairs(sel.rewards or {}) do
        rewardsCount += 1
        table.insert(list, {
            id = tostring(id),
            data = data,
            levelNum = toNum(data.Level),
        })
    end
    table.sort(list, function(a, b) return a.levelNum < b.levelNum end)

    -- Children sebagai dictionary dengan key stabil
    local Items = {}
    if rewardsCount == 30 then
        for _, item in ipairs(list) do
            local id = item.id
            local data = item.data
            local levelNum = item.levelNum
            local key = ("SeasonItem_%d_%s"):format(levelNum, id)

            local hover =
                (data.Title == "Brainrot Egg" and createHoverDescription(Template.Shop.BrainrotEgg))
                or (data.Title == "Crewmate Egg" and createHoverDescription(Template.Shop.CrewmateEgg))
                or nil

            Items[key] = Roact.createElement(Item, {
                id = id,
                title = data.Title,
                image = data.Image,
                level = levelNum or 0,                    -- level item (number)
                locked = (sel.level or 0) < (levelNum or 0),       -- status lock
                -- ↓ semua state penting dipass via props
                premium = sel.premium,
                claimedRewards = sel.claimedRewards,
                claimedPremiumRewards = sel.claimedPremiumRewards,
                hover = hover,
            })
        end
    end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = sel.currentSeasonPassUI == SeasonConstants.Rewards,
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        BorderColor3 = Color3.fromHex("000000"),
        BackgroundColor3 = Color3.fromHex("ffffff"),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
    }, {
        UnlockAll = Roact.createElement("ImageButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.795, 1.12),
            BorderColor3 = Color3.fromHex("000000"),
            Size = UDim2.fromScale(0.393, 0.174),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromHex("e5ff00"),
            [Roact.Event.MouseButton1Click] = function()
                Sound:PlaySound("UI_Click")
                StoreController:BuyItem({ name = "Season Pass - Skip All" })
            end,
        }, {
            UIGradient = Roact.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("ffffff")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("27d400")),
                }),
                Rotation = 90,
            }),
            Stroke = Roact.createElement("UIStroke", {
                Color = Color3.fromHex("245d00"),
                Thickness = 5,
            }),
            Corner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0.3, 0),
            }),
            Label = Roact.createElement("TextLabel", {
                TextWrapped = true,
                TextColor3 = Color3.fromHex("ffffff"),
                BorderColor3 = Color3.fromHex("000000"),
                Text = "Unlock All!",
                Size = UDim2.fromScale(0.9, 0.9),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Font = 26,
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                TextScaled = true,
                TextSize = 14,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromHex("ffffff"),
            }, {
                Stroke = Roact.createElement("UIStroke", {
                    Color = Color3.fromHex("245d00"),
                    Thickness = 3,
                }),
            }),
        }),
        Ticket = Roact.createElement(Ticket),
        ScrollingFrame = Roact.createElement("ScrollingFrame", {
            ScrollBarImageColor3 = Color3.fromHex("000000"),
            MidImage = "rbxassetid://95591733073455",
            Active = true,
            ScrollBarImageTransparency = 0.5,
            ScrollBarThickness = 5,
            BorderColor3 = Color3.fromHex("000000"),
            Size = UDim2.fromScale(0.73, 0.8),
            CanvasSize = UDim2.fromScale(7, 1),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.602, 0.52),
            TopImage = "",
            ScrollingDirection = 1,
            HorizontalScrollBarInset = 1,
            BottomImage = "",
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromHex("ffd3f7"),
        }, {
            Rewards = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
            }, {
                UIPadding = Roact.createElement("UIPadding", {
                    PaddingLeft = UDim.new(0.005, 0),
                    PaddingRight = UDim.new(-0.015, 0),
                }),
                Grid = Grid({
                    cellPadding = UDim2.new(0.01, 0),
                    cellSize = UDim2.fromScale(0.023, 0.77),
                    fillDirection = Enum.FillDirection.Vertical,
                    horizontalAlignment = Enum.HorizontalAlignment.Left,
                    verticalAlignment = Enum.VerticalAlignment.Top,
                    fillDirectionMaxCells = 1,
                }),
                Roact.createFragment(Items),
            }),
            Corner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0.04, 0),
            }),
            Stroke = Roact.createElement("UIStroke", {
                Color = Color3.fromHex("191919"),
                Thickness = 3,
            }),
            UIGradient = Roact.createElement("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("ffffff")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("ce82d5")),
                }),
                Rotation = 90,
            }),
            TotalXpSlider = Roact.createElement(TotalXpSlider),
        }),
    })
end
