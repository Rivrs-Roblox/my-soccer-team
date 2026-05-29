local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

local UIController = Knit.GetController("UIController")
local GachaController = Knit.GetController("GachaController")
local MonetizationController = Knit.GetController("MonetizationController")
local StoreController = Knit.GetController("StoreController")

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)
local PackConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.PackConstants)

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local UIActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.UIActions)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

local Frames = script.Parent.Frames
local PlayerPacks = require(Frames.PlayerPacks)
local AccessoryPacks = require(Frames.AccessoryPacks)

function Packs(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	local timeLeftText, setTimeLeftText = hooks.useState("00:00")

	local function formatTime(seconds)
		if seconds <= 0 then
			return "00:00"
		end
		local minutes = math.floor(seconds / 60)
		local secs = math.floor(seconds % 60)
		return string.format("%02d:%02d", minutes, secs)
	end

	hooks.useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				local nextRefill = GachaController.NextRefillTime or 0
				local now = workspace:GetServerTimeNow()
				local diff = nextRefill - now
				setTimeLeftText(formatTime(diff))
				task.wait(1)
			end
		end)

		local conn = GachaController.RefillTimeUpdated:Connect(function(nextRefill)
			local now = workspace:GetServerTimeNow()
			local diff = nextRefill - now
			setTimeLeftText(formatTime(diff))
		end)

		return function()
			running = false
			conn:Disconnect()
		end
	end, {})

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentUI == FramesConstants.Packs,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 2,
		BackgroundColor3 = Color3.fromHex("000000"),
		Size = UDim2.fromScale(1, 1),
	}, {
		Popup = Blue_Background({
			size = UDim2.fromScale(0.7, 0.7),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
			action = function()
				UIController:HideFrame()
			end,
		}, {
			-- AccessoryPacks = Roact.createElement(AccessoryPacks),
			PlayerPacks = Roact.createElement(PlayerPacks),
			-- Panels = Roact.createElement("Frame", {
			-- 	AnchorPoint = Vector2.new(0.5, 0.5),
			-- 	BackgroundTransparency = 1,
			-- 	Position = UDim2.fromScale(0.5, 0.195),
			-- 	BorderColor3 = Color3.fromHex("000000"),
			-- 	BackgroundColor3 = Color3.fromHex("ffffff"),
			-- 	BorderSizePixel = 0,
			-- 	Size = UDim2.fromScale(0.91, 0.08),
			-- }, {
			-- 	UIListLayout = Roact.createElement("UIListLayout", {
			-- 		VerticalAlignment = 0,
			-- 		SortOrder = 2,
			-- 		HorizontalAlignment = 0,
			-- 		Padding = UDim.new(0.012, 0),
			-- 		FillDirection = 0,
			-- 	}),
			-- 	AccessoryPacks = Roact.createElement("ImageButton", {
			-- 		LayoutOrder = 4,
			-- 		Size = UDim2.fromScale(0.5, 1),
			-- 		Position = UDim2.fromScale(0.5, 0.5),
			-- 		BorderColor3 = Color3.fromHex("000000"),
			-- 		AnchorPoint = Vector2.new(0.5, 0.5),
			-- 		BorderSizePixel = 0,
			-- 		BackgroundColor3 = if UIReducer.CurrentPacksUI == PackConstants.Accessories
			-- 			then Color3.fromHex("ff6734")
			-- 			else Color3.fromHex("2c4c79"),
			-- 		ZIndex = 2,

			-- 		[Roact.Event.MouseButton1Click] = function()
			-- 			Sound:PlaySound("UI_Click")
			-- 			Store:dispatch(UIActions.setCurrentPacksUI(PackConstants.Accessories))
			-- 		end,
			-- 	}, {
			-- 		ButtonText = Roact.createElement("TextLabel", {
			-- 			TextWrapped = true,
			-- 			TextColor3 = Color3.fromHex("fafafa"),
			-- 			Text = "Accessory Packs",
			-- 			TextScaled = true,
			-- 			AnchorPoint = Vector2.new(0.5, 0.5),
			-- 			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			-- 			BackgroundTransparency = 1,
			-- 			TextXAlignment = 0,
			-- 			Position = UDim2.fromScale(0.554, 0.5),
			-- 			ZIndex = 5,
			-- 			TextSize = 14,
			-- 			Size = UDim2.fromScale(0.518, 0.5),
			-- 			LayoutOrder = 2,
			-- 		}),
			-- 		UIListLayout = Roact.createElement("UIListLayout", {
			-- 			VerticalAlignment = 0,
			-- 			SortOrder = 2,
			-- 			HorizontalAlignment = 0,
			-- 			Padding = UDim.new(0.05, 0),
			-- 			FillDirection = 0,
			-- 		}),
			-- 		Icon = Roact.createElement("ImageLabel", {
			-- 			AnchorPoint = Vector2.new(0.5, 0.5),
			-- 			ScaleType = 3,
			-- 			BackgroundTransparency = 1,
			-- 			Position = UDim2.fromScale(0.5, 0.37),
			-- 			BackgroundColor3 = Color3.fromHex("ffffff"),
			-- 			ZIndex = 2,
			-- 			Image = "rbxassetid://124847512307439",
			-- 			Size = UDim2.fromScale(0.8, 0.8),
			-- 			LayoutOrder = 1,
			-- 		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			-- 		UICorner = Roact.createElement("UICorner", {
			-- 			CornerRadius = UDim.new(0, 2),
			-- 		}),
			-- 	}),
			-- 	PlayerPacks = Roact.createElement("ImageButton", {
			-- 		LayoutOrder = 1,
			-- 		Size = UDim2.fromScale(0.5, 1),
			-- 		Position = UDim2.fromScale(0.5, 0.5),
			-- 		BorderColor3 = Color3.fromHex("000000"),
			-- 		AnchorPoint = Vector2.new(0.5, 0.5),
			-- 		BorderSizePixel = 0,
			-- 		BackgroundColor3 = if UIReducer.CurrentPacksUI == PackConstants.SoccerCharacters
			-- 			then Color3.fromHex("ff6734")
			-- 			else Color3.fromHex("2c4c79"),
			-- 		ZIndex = 2,

			-- 		[Roact.Event.MouseButton1Click] = function()
			-- 			Sound:PlaySound("UI_Click")
			-- 			Store:dispatch(UIActions.setCurrentPacksUI(PackConstants.SoccerCharacters))
			-- 		end,
			-- 	}, {
			-- 		ButtonText = Roact.createElement("TextLabel", {
			-- 			TextWrapped = true,
			-- 			TextColor3 = Color3.fromHex("fafafa"),
			-- 			Text = "Player Packs",
			-- 			TextScaled = true,
			-- 			AnchorPoint = Vector2.new(0.5, 0.5),
			-- 			FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
			-- 			BackgroundTransparency = 1,
			-- 			TextXAlignment = 0,
			-- 			Position = UDim2.fromScale(0.586, 0.5),
			-- 			ZIndex = 5,
			-- 			TextSize = 14,
			-- 			Size = UDim2.fromScale(0.414, 0.5),
			-- 			LayoutOrder = 2,
			-- 		}),
			-- 		UIListLayout = Roact.createElement("UIListLayout", {
			-- 			VerticalAlignment = 0,
			-- 			SortOrder = 2,
			-- 			HorizontalAlignment = 0,
			-- 			Padding = UDim.new(0.05, 0),
			-- 			FillDirection = 0,
			-- 		}),
			-- 		Icon = Roact.createElement("ImageLabel", {
			-- 			AnchorPoint = Vector2.new(0.5, 0.5),
			-- 			ScaleType = 3,
			-- 			BackgroundTransparency = 1,
			-- 			Position = UDim2.fromScale(0.5, 0.37),
			-- 			BackgroundColor3 = Color3.fromHex("ffffff"),
			-- 			ZIndex = 2,
			-- 			Image = "rbxassetid://123525764637746",
			-- 			Size = UDim2.fromScale(0.8, 0.8),
			-- 			LayoutOrder = 1,
			-- 		}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
			-- 		UICorner = Roact.createElement("UICorner", {
			-- 			CornerRadius = UDim.new(0, 2),
			-- 		}),
			-- 	}),
			-- }),

			PacksRefill = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.61, 0.08),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.202, 0.09),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				}),
				Title = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffea00"),
					Text = "New packs in:",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 2,
					TextSize = 14,
					Size = UDim2.fromScale(1, 0.5),
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("143758"),
						Thickness = 2,
					}),
				}),
				Timer = Roact.createElement("TextLabel", {
					LayoutOrder = 2,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffea00"),
					Text = timeLeftText,
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 2,
					TextSize = 14,
					Size = UDim2.fromScale(1, 0.5),
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("143758"),
						Thickness = 2,
					}),
				}),
			}),
			Refill = Roact.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.812, 0.08),
				ZIndex = 100,
				Size = UDim2.fromScale(0.164, 0.09),
				BackgroundColor3 = Color3.fromHex("ffffff"),

				[Roact.Event.MouseButton1Click] = function()
					Sound:PlaySound("UI_Click")
					StoreController:BuyItem({ name = "Refill Pack" })
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("34588f"),
					Thickness = 2,
				}),
				UIGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("26c5ff")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("1e5ab9")),
					}),
					Rotation = 90,
				}),
				Text = Roact.createElement("TextLabel", {
					LayoutOrder = 2,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = `Refill ( {MonetizationController:GetPrice("Refill Pack")})`,
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					TextXAlignment = 0,
					Position = UDim2.fromScale(0.5, 0.5),
					ZIndex = 101,
					TextSize = 14,
					Size = UDim2.fromScale(0.85, 0.7),
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("143758"),
						Thickness = 2,
					}),
				}),
			}),
		}),
	})
end

Packs = RoactHooks.new(Roact)(Packs)
return Packs
