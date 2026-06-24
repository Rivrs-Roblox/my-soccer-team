local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactHooks = require(ReplicatedStorage.Packages.hooks)
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Blue_Background = require(Components.Main.Blue_Background)

local UIController = Knit.GetController("UIController")
local DataCacheController = Knit.GetController("DataCacheController")
local UI = DataCacheController:GetFile("Images")

local FramesConstants = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Constants.FramesConstants)

local Frames = script.Parent.Frames
local WinsPacks = require(Frames.WinsPacks)
local Boosts = require(Frames.Boosts)
local Coaches = require(Frames.Coaches)
local Accessories = require(Frames.Accessories)
local Gamepasses = require(Frames.Gamepasses)
local Featured = require(Frames.Featured)

function Store(_, hooks)
	local UIReducer = RoduxHooks.useSelector(hooks, function(state)
		return state.UIReducer
	end)

	local scrollRef = hooks.useValue(Roact.createRef())
	local activeSection, setActiveSection = hooks.useState("Featured")

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

	hooks.useEffect(function()
		if UIReducer.CurrentUI == FramesConstants.Store then
			if UIReducer.CurrentStoreSectionUI and UIReducer.CurrentStoreSectionUI ~= "Featured" then
				task.delay(0.05, function()
					scrollToSection(UIReducer.CurrentStoreSectionUI)
				end)
			end
		end
	end, { UIReducer.CurrentUI, UIReducer.CurrentStoreSectionUI })

	return Roact.createElement("Frame", {
		Visible = UIReducer.CurrentUI == FramesConstants.Store,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("000000"),
		ZIndex = 2,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Popup = Blue_Background({
			title = "Store",
			titleIcon = UI.Store,
			size = UDim2.fromScale(0.6, 0.6),
			pos = UDim2.fromScale(0.5, 0.5),
			ratio = 1.6,
			condition = true,
			align = Enum.TextXAlignment.Left,
			hooks = hooks,
		}, {
			Scroll = Roact.createElement("ScrollingFrame", {
				AutomaticCanvasSize = 2,
				ScrollBarThickness = 8,
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				ScrollingDirection = 2,
				Size = UDim2.fromScale(0.95, 0.705),
				Position = UDim2.fromScale(0.5, 0.98),
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromScale(0, 8.2),
				[Roact.Ref] = scrollRef.value,
				[Roact.Change.CanvasPosition] = function(rbx)
					local closest = activeSection
					local minDistance = math.huge
					local sections = { "Featured", "Gamepasses", "WinPacks", "Boosts" }
					for _, name in ipairs(sections) do
						local child = rbx:FindFirstChild(name)
						if child then
							local distance = math.abs(child.AbsolutePosition.Y - rbx.AbsolutePosition.Y)
							if distance < minDistance then
								minDistance = distance
								closest = name
							end
						end
					end
					if closest ~= activeSection then
						setActiveSection(closest)
					end
				end,
			}, {
				WinPacks = Roact.createElement(WinsPacks),
				UIPadding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0.005, 0),
				}),
				CoachesText = Roact.createElement("TextLabel", {
					LayoutOrder = 3,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Coaches",
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
				WinPacksText = Roact.createElement("TextLabel", {
					LayoutOrder = 9,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Win Packs",
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
				Boosts = Roact.createElement(Boosts),
				Featured = Roact.createElement(Featured),
				AccessoriesText = Roact.createElement("TextLabel", {
					LayoutOrder = 5,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Accessories",
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
				Coaches = Roact.createElement(Coaches),
				Accessories = Roact.createElement(Accessories),
				List = Roact.createElement("UIListLayout", {
					SortOrder = 2,
					HorizontalAlignment = 0,
					Padding = UDim.new(0.05, 0),
				}),
				BoostsText = Roact.createElement("TextLabel", {
					LayoutOrder = 11,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Boosts",
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
				GamepassesText = Roact.createElement("TextLabel", {
					LayoutOrder = 7,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Gamepasses",
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
				FeaturedText = Roact.createElement("TextLabel", {
					LayoutOrder = 1,
					TextWrapped = true,
					TextColor3 = Color3.fromHex("ffffff"),
					Text = "Featured",
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
				Gamepasses = Roact.createElement(Gamepasses),
			}),
			Panels = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.2),
				BorderColor3 = Color3.fromHex("000000"),
				BackgroundColor3 = Color3.fromHex("ffffff"),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(0.91, 0.1),
			}, {
				Boosts = Roact.createElement("ImageButton", {
					LayoutOrder = 4,
					Size = UDim2.fromScale(0.245, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = activeSection == "Boosts" and Color3.fromHex("e23e3e")
						or Color3.fromHex("3b65a3"),
					ZIndex = 2,

					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						scrollToSection("Boosts")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Boosts",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.5, 0.96),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.4, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://132232460054998",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
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
				Wins = Roact.createElement("ImageButton", {
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.245, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = activeSection == "WinPacks" and Color3.fromHex("e23e3e")
						or Color3.fromHex("3b65a3"),
					ZIndex = 2,
					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						scrollToSection("WinPacks")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Wins",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.5, 0.96),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.3, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://108499802754420",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
				Gamepass = Roact.createElement("ImageButton", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.245, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = activeSection == "Gamepasses" and Color3.fromHex("e23e3e")
						or Color3.fromHex("3b65a3"),
					ZIndex = 2,
					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						scrollToSection("Gamepasses")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Gamepass",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.5, 0.96),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.55, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://129498566640257",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
				Featured = Roact.createElement("ImageButton", {
					LayoutOrder = 1,
					Size = UDim2.fromScale(0.245, 1),
					Position = UDim2.fromScale(0.5, 0.5),
					BorderColor3 = Color3.fromHex("000000"),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = activeSection == "Featured" and Color3.fromHex("e23e3e")
						or Color3.fromHex("3b65a3"),
					ZIndex = 2,
					[Roact.Event.MouseButton1Click] = function()
						Sound:PlaySound("UI_Click")
						scrollToSection("Featured")
					end,
				}, {
					ButtonText = Roact.createElement("TextLabel", {
						TextWrapped = true,
						TextColor3 = Color3.fromHex("fafafa"),
						Text = "Featured",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold),
						BackgroundTransparency = 1,
						TextXAlignment = 0,
						Position = UDim2.fromScale(0.5, 0.96),
						ZIndex = 5,
						TextSize = 14,
						Size = UDim2.fromScale(0.55, 0.5),
						LayoutOrder = 2,
					}),
					UIListLayout = Roact.createElement("UIListLayout", {
						VerticalAlignment = 0,
						SortOrder = 2,
						HorizontalAlignment = 0,
						Padding = UDim.new(0.05, 0),
						FillDirection = 0,
					}),
					Icon = Roact.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						ScaleType = 3,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.37),
						BackgroundColor3 = Color3.fromHex("ffffff"),
						ZIndex = 2,
						Image = "rbxassetid://114922899800997",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
					}, { Ratio = Roact.createElement("UIAspectRatioConstraint", {}) }),
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 2),
					}),
				}),
			}),
		}),
	})
end

Store = RoactHooks.new(Roact)(Store)
return Store
