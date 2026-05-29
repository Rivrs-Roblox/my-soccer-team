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

-- Helpers
local FormatNumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)

-- Controllers
local TradeController = Knit.GetController("TradeController")
local DataCacheController = Knit.GetController("DataCacheController")

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

-- Frames
local Frames = script.Parent.Frames
local Scroll = require(Frames.Scroll)
local SoccerCharacter = require(Frames.SoccerCharacter)

-- UI
local UI = DataCacheController:GetFile("Images")
local Colors = DataCacheController:GetFile("Colors")
local Template = DataCacheController:GetFile("Template")

local SEARCH_ICON = "rbxassetid://108045196460145"
local READY_ICON = "rbxassetid://93840956317609"
local DEFAULT_SOCCER_CHARACTER_TEMPLATE = {
	Rarity = "Common",
}

local function getSoccerCharacterIcon(soccerCharacterName: string)
	local icon = UI[soccerCharacterName]
	if icon == nil then
		icon = UI[soccerCharacterName:gsub("GOLD ", "")]
	end

	return icon or ""
end

local function getSoccerCharacterColor(rarity: string)
	return Colors[rarity] or Color3.fromHex("e1e1e1")
end

local function getSoccerCharacterTemplate(soccerCharacterName: string)
	local soccerCharacters = Template and Template.SoccerCharacters
	if not soccerCharacters then
		return DEFAULT_SOCCER_CHARACTER_TEMPLATE
	end

	return soccerCharacters[soccerCharacterName] or DEFAULT_SOCCER_CHARACTER_TEMPLATE
end

local function countItems(items: table)
	local amount = 0
	for _ in pairs(items) do
		amount += 1
	end
	return amount
end

local function GradientButton(params)
	return Roact.createElement("ImageButton", {
		LayoutOrder = params.LayoutOrder,
		Size = params.Size or UDim2.fromScale(0.19, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		ZIndex = 6,
		AutoButtonColor = true,

		[Roact.Event.MouseButton1Click] = params.Action,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		UIStroke = Roact.createElement("UIStroke", {
			Color = params.StrokeColor,
			Thickness = 2,
		}),

		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, params.GradientA),
				ColorSequenceKeypoint.new(1, params.GradientB),
			}),
			Rotation = 90,
		}),

		ButtonText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("fafafa"),
			Text = params.Text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 7,
			TextScaled = true,
			Size = UDim2.fromScale(0.9, 0.55),
		}),
	})
end

local function PlayerPanel(params)
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0.5,
		LayoutOrder = params.LayoutOrder,
		BackgroundColor3 = Color3.fromHex("606393"),
		Size = UDim2.fromScale(0.5, 1),
		ZIndex = 3,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),

		NameText = Roact.createElement("TextLabel", {
			TextWrapped = true,
			TextColor3 = Color3.fromHex("ffffff"),
			Text = params.Title,
			AnchorPoint = Vector2.new(0.5, 0),
			FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.02),
			ZIndex = 4,
			TextScaled = true,
			Size = UDim2.fromScale(0.85, 0.08),
		}),

		EmptyText = Roact.createElement("TextLabel", {
			Visible = params.Count <= 0,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(20, 55, 88),
			TextTransparency = 0.8,
			Text = params.EmptyText,
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.52),
			ZIndex = 4,
			TextScaled = true,
			Size = UDim2.fromScale(0.8, 0.2),
		}),

		Scroll = Scroll({
			soccerCharacters = params.SoccerCharacters,
			pos = UDim2.fromScale(0.5, 0.96),
			size = UDim2.fromScale(0.94, 0.8),
		}),

		Ready = Roact.createElement("ImageLabel", {
			Visible = params.Ready,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = UI.Check or READY_ICON,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.55),
			ZIndex = 20,
			ImageColor3 = Color3.fromHex("00fa00"),
			Size = UDim2.fromScale(0.35, 0.35),
		}),
	})
end

-- Trading
function Trading(_, hooks)
	local TradeReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TradeReducer
	end)

	local InventoryReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.InventoryReducer
	end)

	local TeamReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.TeamReducer
	end)

	local equippedCharacters = TeamReducer.EquippedSoccerCharacters or {}
	local equippedIds = {}
	for _, id in pairs(equippedCharacters) do
		equippedIds[tostring(id)] = true
	end

	local SearchText, SetSearchText = hooks.useState("")

	local index = 0
	local MySoccerCharacters = {}

	for id, charData in pairs(TradeReducer.MySoccerCharacters) do
		if SearchText == "" or string.find(string.lower(charData.Name), SearchText, 1, true) then
			local templateData = getSoccerCharacterTemplate(charData.Name)

			MySoccerCharacters[id] = SoccerCharacter({
				trading = true,
				icon = getSoccerCharacterIcon(charData.Name),
				name = charData.Name,
				id = id,
				power = `{charData.Level} ⭐`,
				bg_color = getSoccerCharacterColor(templateData.Rarity),
				rarity = templateData.Rarity,
				my_side = true,
				order = index,
			})

			index += 1
		end
	end

	for id, charData in pairs(InventoryReducer.SoccerCharacters or {}) do
		if equippedIds[tostring(id)] then
			continue
		end

		if MySoccerCharacters[id] == nil then
			if SearchText == "" or string.find(string.lower(charData.Name), SearchText, 1, true) then
				local templateData = getSoccerCharacterTemplate(charData.Name)

				MySoccerCharacters[id] = SoccerCharacter({
					trading = false,
					icon = getSoccerCharacterIcon(charData.Name),
					name = charData.Name,
					id = id,
					power = `{charData.Level} ⭐`,
					bg_color = getSoccerCharacterColor(templateData.Rarity),
					rarity = templateData.Rarity,
					my_side = true,
					order = index,
				})

				index += 1
			end
		end
	end

	local HisSoccerCharacters = {}
	index = 0
	for id, charData in pairs(TradeReducer.HisSoccerCharacters) do
		local templateData = getSoccerCharacterTemplate(charData.Name)

		HisSoccerCharacters[id] = SoccerCharacter({
			trading = true,
			icon = getSoccerCharacterIcon(charData.Name),
			name = charData.Name,
			id = id,
			power = `{charData.Level} ⭐`,
			bg_color = getSoccerCharacterColor(templateData.Rarity),
			rarity = templateData.Rarity,
			my_side = false,
			order = index,
		})

		index += 1
	end

	local otherPlayerName = "Other"
	if TradeReducer.IncomingRequest then
		otherPlayerName = TradeReducer.IncomingRequest.Name
	elseif TradeReducer.OutgoingRequest then
		otherPlayerName = TradeReducer.OutgoingRequest.Name
	end

	local acceptButtonText = "Accept"
	local acceptButtonAction = function()
		TradeController:Ready(true)
	end
	local acceptStroke = Color3.fromHex("04da01")
	local acceptGradientA = Color3.fromHex("00d921")
	local acceptGradientB = Color3.fromHex("0e820e")

	if TradeReducer.Ready and TradeReducer.OtherReady then
		acceptButtonText = "Cancel"
		acceptButtonAction = function()
			TradeController:Ready(false)
		end
		acceptStroke = Color3.fromHex("da5b5d")
		acceptGradientA = Color3.fromHex("ff3134")
		acceptGradientB = Color3.fromHex("822b2d")
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Visible = TradeReducer.Trading == true,
	}, {
		Content = Blue_Background({
			title = "Trading",
			titleIcon = UI.Trade,
			size = UDim2.fromScale(0.6, 0.6),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
			action = function()
				TradeController:CancelTrade()
			end,
		}, {
			Center = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.88, 0.65),
				ZIndex = 3,
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.015, 0),
					FillDirection = Enum.FillDirection.Horizontal,
				}),

				Player = PlayerPanel({
					LayoutOrder = 1,
					Title = "Your Players",
					EmptyText = "You have nothing to show here yet ):",
					SoccerCharacters = MySoccerCharacters,
					Count = countItems(MySoccerCharacters),
					Ready = TradeReducer.Ready,
				}),

				OtherPlayer = PlayerPanel({
					LayoutOrder = 2,
					Title = `{otherPlayerName}'s Players`,
					EmptyText = "They have nothing to show here yet ):",
					SoccerCharacters = HisSoccerCharacters,
					Count = countItems(HisSoccerCharacters),
					Ready = TradeReducer.OtherReady,
				}),
			}),

			Timer = Roact.createElement("TextLabel", {
				Visible = TradeReducer.Ready and TradeReducer.OtherReady,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = tostring(TradeReducer.Timer),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				TextScaled = true,
				Size = UDim2.fromScale(0.35, 0.22),
				ZIndex = 30,
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.fromHex("000000"),
			}),

			Bottom = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.93),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.9, 0.1),
				ZIndex = 5,
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.02, 0),
					FillDirection = Enum.FillDirection.Horizontal,
				}),

				SearchBar = Roact.createElement("Frame", {
					LayoutOrder = 1,
					ZIndex = 10,
					BackgroundColor3 = Color3.fromHex("254167"),
					Size = UDim2.fromScale(0.57, 1),
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 6),
					}),

					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1d243b"),
						Thickness = 2,
					}),

					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Image = SEARCH_ICON,
						BackgroundTransparency = 1,
						ImageTransparency = 0.5,
						Position = UDim2.fromScale(0.06, 0.5),
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(0.6, 0.6),
						ZIndex = 11,
					}, {
						Ratio = Roact.createElement("UIAspectRatioConstraint", {}),
					}),

					TextBox = Roact.createElement("TextBox", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("ffffff"),
						TextTransparency = 0.5,
						Text = SearchText,
						PlaceholderColor3 = Color3.fromHex("ffffff"),
						AnchorPoint = Vector2.new(0, 0.5),
						FontFace = Font.fromName("Ubuntu", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.fromScale(0.12, 0.5),
						PlaceholderText = "Search players...",
						TextScaled = true,
						Size = UDim2.fromScale(0.8, 0.5),
						ZIndex = 11,
						ClearTextOnFocus = false,

						[Roact.Change.Text] = function(rbx)
							SetSearchText(string.lower(rbx.Text))
						end,
					}),
				}),

				Decline = GradientButton({
					LayoutOrder = 2,
					Text = "Decline",
					StrokeColor = Color3.fromHex("da5b5d"),
					GradientA = Color3.fromHex("ff3134"),
					GradientB = Color3.fromHex("822b2d"),
					Action = function()
						TradeController:CancelTrade()
					end,
				}),

				Accept = GradientButton({
					LayoutOrder = 3,
					Text = acceptButtonText,
					StrokeColor = acceptStroke,
					GradientA = acceptGradientA,
					GradientB = acceptGradientB,
					Action = acceptButtonAction,
				}),
			}),
		}),
	})
end

Trading = RoactHooks.new(Roact)(Trading)
return Trading
