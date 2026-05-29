local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)

local PackConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.PackConstants)

local Beginner = require(script.Parent.Beginner)
local Intermediate = require(script.Parent.Intermediate)
local Pro = require(script.Parent.Pro)
local Champion = require(script.Parent.Champion)
local Goat = require(script.Parent.Goat)
local Elite = require(script.Parent.Elite)

function PlayerPacks(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	local scrollRef = hooks.useValue(Roact.createRef())
	local activeSection, setActiveSection = hooks.useState("BeginnerText")

	local onScroll = hooks.useCallback(function(rbx)
		local minDist = math.huge
		local active = activeSection

		local sections = { "BeginnerText", "IntermediateText", "ProText", "ChampionText", "GOATText", "EliteText" }
		for _, sectionName in ipairs(sections) do
			local frame = rbx:FindFirstChild(sectionName)
			if frame then
				-- We want to find the section closest to the top of the scroll view
				local dist = math.abs(frame.AbsolutePosition.Y - rbx.AbsolutePosition.Y)
				if dist < minDist then
					minDist = dist
					active = sectionName
				end
			end
		end

		if activeSection ~= active then
			setActiveSection(active)
		end
	end, { activeSection })

	local function scrollToSection(sectionName)
		local scroll = scrollRef.value:getValue()
		if scroll then
			local targetFrame = scroll:FindFirstChild(sectionName)
			if targetFrame then
				local targetY = targetFrame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
				targetY = math.max(0, targetY - 10)

				local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(scroll, tweenInfo, { CanvasPosition = Vector2.new(0, targetY) }):Play()
			end
		end
	end

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentPacksUI == PackConstants.SoccerCharacters,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BorderColor3 = Color3.fromHex("000000"),
		BackgroundColor3 = Color3.fromHex("ffffff"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		Scroll = Roact.createElement("ScrollingFrame", {
			AutomaticCanvasSize = 2,
			ScrollBarThickness = 8,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			ScrollingDirection = 2,
			Size = UDim2.fromScale(0.95, 0.71),
			Position = UDim2.fromScale(0.5, 0.98),
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromScale(0, 5.6),
			[Roact.Ref] = scrollRef.value,
			[Roact.Change.CanvasPosition] = onScroll,
		}, {
			List = Roact.createElement("UIListLayout", {
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.05, 0),
			}),
			IntermediateText = Roact.createElement("TextLabel", {
				LayoutOrder = 3,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Intermediate Pack",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.125, 0.037),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			Pro = Roact.createElement(Pro),
			GOAT = Roact.createElement(Goat),
			GOATText = Roact.createElement("TextLabel", {
				LayoutOrder = 9,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Greatest of All Time  Pack",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.125, 0.037),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			Beginner = Roact.createElement(Beginner),
			Elite = Roact.createElement(Elite),
			EliteText = Roact.createElement("TextLabel", {
				LayoutOrder = 11,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Elite Pack",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.125, 0.037),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			Intermediate = Roact.createElement(Intermediate),
			ChampionText = Roact.createElement("TextLabel", {
				LayoutOrder = 7,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Champion Pack",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.125, 0.037),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			Champion = Roact.createElement(Champion),
			BeginnerText = Roact.createElement("TextLabel", {
				LayoutOrder = 1,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Beginner Pack",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.478, 0.022),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			ProText = Roact.createElement("TextLabel", {
				LayoutOrder = 5,
				TextWrapped = true,
				TextColor3 = Color3.fromHex("ffffff"),
				Text = "Pro Packs",
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
				BackgroundTransparency = 1,
				TextXAlignment = 0,
				TextScaled = true,
				Position = UDim2.fromScale(0.125, 0.037),
				TextSize = 14,
				Size = UDim2.fromScale(0.95, 0.1),
				ZIndex = 2,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
		}),
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
			TitleText = Roact.createElement("TextLabel", {
				TextWrapped = true,
				TextColor3 = Color3.fromHex("fafafa"),
				Text = "Player Packs",
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
					Color = Color3.fromHex("143758"),
					Thickness = 2,
				}),
			}),
			Icon = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = 3,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.37),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				ZIndex = 2,
				Image = "rbxassetid://103335348086847",
				Size = UDim2.fromScale(1.2, 1.2),
				LayoutOrder = 1,
			}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
		}),
		Panels = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.21),
			BorderColor3 = Color3.fromHex("000000"),
			BackgroundColor3 = Color3.fromHex("ffffff"),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.91, 0.08),
		}, {
			Elite = Roact.createElement("ImageButton", {
				LayoutOrder = 6,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "EliteText" and Color3.fromHex("ff6734")
					or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("EliteText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Elite",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = 0,
				SortOrder = 2,
				HorizontalAlignment = 0,
				Padding = UDim.new(0.012, 0),
				FillDirection = 0,
			}),
			Pro = Roact.createElement("ImageButton", {
				LayoutOrder = 3,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "ProText" and Color3.fromHex("ff6734") or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("ProText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Pro",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
			GOAT = Roact.createElement("ImageButton", {
				LayoutOrder = 5,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "GOATText" and Color3.fromHex("ff6734") or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("GOATText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "GOAT",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
			Champion = Roact.createElement("ImageButton", {
				LayoutOrder = 4,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "ChampionText" and Color3.fromHex("ff6734")
					or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("ChampionText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Champion",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
			Intermediate = Roact.createElement("ImageButton", {
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "IntermediateText" and Color3.fromHex("ff6734")
					or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("IntermediateText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Intermediate",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
			Beginner = Roact.createElement("ImageButton", {
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.159, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				BorderColor3 = Color3.fromHex("000000"),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				BackgroundColor3 = activeSection == "BeginnerText" and Color3.fromHex("ff6734")
					or Color3.fromHex("3e6baa"),
				ZIndex = 2,
				[Roact.Event.MouseButton1Click] = function()
					scrollToSection("BeginnerText")
				end,
			}, {
				ButtonText = Roact.createElement("TextLabel", {
					TextWrapped = true,
					TextColor3 = Color3.fromHex("fafafa"),
					Text = "Beginner",
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					TextSize = 14,
					ZIndex = 5,
					TextScaled = true,
					Size = UDim2.fromScale(0.85, 0.5),
				}),
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
		}),
	})
end

PlayerPacks = RoactHooks.new(Roact)(PlayerPacks)
return PlayerPacks
