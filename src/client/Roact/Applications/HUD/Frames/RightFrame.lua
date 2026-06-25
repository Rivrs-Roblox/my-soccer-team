local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local DataCacheController = Knit.GetController("DataCacheController")
local StoreController = Knit.GetController("StoreController")
local UIController = Knit.GetController("UIController")

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

local UI = DataCacheController:GetFile("Images")

local Button = require(script.Parent.Button)
local StoreButton = require(script.Parent.StoreButton)

local function hasClaimableTimeReward(rewardsReducer)
	if typeof(rewardsReducer) ~= "table" or typeof(rewardsReducer.rewards) ~= "table" then
		return 0
	end

	local playerTime = rewardsReducer.time or 0

	for _, reward in pairs(rewardsReducer.rewards) do
		if typeof(reward) == "table" then
			local requiredTime = tonumber(reward.Time) or math.huge

			if reward.Claimed ~= true and playerTime >= requiredTime then
				return 1
			end
		end
	end

	return 0
end

function RightFrame(_, hooks)
	local StarterPacksReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.StarterPacksReducer
	end)
	local NotificationReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.NotificationReducer
	end)
	local SpinsReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.SpinsReducer
	end)
	local RewardsReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.RewardsReducer
	end)

	local DailyRewardsNotif = NotificationReducer.Notifications["DailyRewards"]
	local SpinsNotif = SpinsReducer.Spins.Free + SpinsReducer.Spins.Premium
	local TimedRewardsNotif = hasClaimableTimeReward(RewardsReducer)

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.99, 0.42),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.134, 0.2),
	}, {
		Store = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 1.7),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.877, 0.382),
		}, {
			UIGridLayout = Roact.createElement("UIGridLayout", {
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.32, 1),
				FillDirectionMaxCells = 3,
				CellPadding = UDim2.fromScale(0.01, 0.1),
				HorizontalAlignment = 2,
			}),
			VipBtn = Roact.createElement(StoreButton, {
				image = UI.VIP_Icon,
				onClick = function()
					StoreController:BuyItem({ name = "VIP" })
				end,
				order = 1,
			}),
			Rebirth2xBtn = Roact.createElement(StoreButton, {
				image = UI.Rebirth,
				onClick = function()
					StoreController:BuyItem({ name = "x2 Rebirths" })
				end,
				order = 2,
				value = "x2",
			}),
			Open5xBtn = Roact.createElement(StoreButton, {
				image = UI.Packs,
				onClick = function()
					StoreController:BuyItem({ name = "x5 Open" })
				end,
				order = 3,
				value = "x5",
			}),
		}),
		StarterPack = Roact.createElement("ImageButton", {
			Visible = StarterPacksReducer.BoughtStarterPacks < 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.55, -0.5),
			BorderColor3 = Color3.fromHex("000000"),
			Size = UDim2.fromScale(0.8, 0.8),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("ffffff"),

			[Roact.Event.MouseButton1Click] = function()
				Sound:PlaySound("UI_Click")
				UIController:ShowFrame({ frame = FramesConstants.StarterPack })
			end,
		}, {
			ButtonText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Starter Pack!",
				AnchorPoint = Vector2.new(0.5, 1),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.98),
				TextSize = 14,
				ZIndex = 5,
				TextScaled = true,
				Size = UDim2.fromScale(1.3, 0.35),
			}, { UIStroke = Roact.createElement("UIStroke", {
				Thickness = 1.5,
			}) }),
			Effect = Roact.createElement("ImageLabel", {
				ImageColor3 = Color3.fromHex("ff5e00"),
				Image = "rbxassetid://106335669168445",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				Size = UDim2.fromScale(1.5, 1.5),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			Ratio = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.9,
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://110518086056999",
				Size = UDim2.fromScale(1, 1),
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			LimitedText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fac800"),
				Text = "LIMITED!",
				TextSize = 14,
				Rotation = 20,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.65, 0.15),
				AnchorPoint = Vector2.new(0.5, 1),
				ZIndex = 5,
				TextScaled = true,
				Size = UDim2.fromScale(1, 0.183),
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("ff1111"),
					Thickness = 1.5,
				}),
			}),
		}),
		Main = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			UIGridLayout = Roact.createElement("UIGridLayout", {
				SortOrder = 2,
				CellSize = UDim2.fromScale(0.45, 0.45),
				FillDirectionMaxCells = 2,
				CellPadding = UDim2.fromScale(0, 0.1),
				HorizontalAlignment = 2,
			}),
			RewardsBtn = Roact.createElement(Button, {
				name = "Rewards",
				image = UI.TimedRewards,
				order = 1,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Rewards })
				end,
				notification = TimedRewardsNotif,
			}),
			SpinsBtn = Roact.createElement(Button, {
				name = "Spins",
				image = UI.Spins,
				order = 2,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Spins })
				end,
				notification = SpinsNotif,
			}),
			DailyBtn = Roact.createElement(Button, {
				name = "Daily",
				image = UI.DailyRewards,
				order = 3,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.DailyRewards })
				end,
				notification = DailyRewardsNotif,
			}),
			InviteBtn = Roact.createElement(Button, {
				name = "Invite",
				image = UI.Invite,
				order = 4,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Friends })
				end,
			}),
			TradingBtn = Roact.createElement(Button, {
				name = "Trading",
				image = UI.Trade,
				order = 5,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.TradeList })
				end,
			}),
			SettingsBtn = Roact.createElement(Button, {
				name = "Settings",
				image = UI.Settings,
				order = 6,
				onClick = function()
					UIController:ShowFrame({ frame = FramesConstants.Settings })
				end,
			}),
		}),
	})
end

RightFrame = RoactHooks.new(Roact)(RightFrame)
return RightFrame
