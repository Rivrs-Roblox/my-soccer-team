--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Roact = require(ReplicatedStorage.Packages.roact)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Store
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local InventoryActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.InventoryActions)

-- Components
local Components = StarterPlayer.StarterPlayerScripts.Client.Roact.Components
local Text = require(Components.Text)
local Image = require(Components.Image)
local AspectRatio = require(Components.AspectRatio)
local Corner = require(Components.Corner)
local Stroke = require(Components.Stroke)

-- Services
local PetsService = Knit.GetService("PetsService")

-- Controllers
local DataCacheController = Knit.GetController("DataCacheController")
local NotificationController = Knit.GetController("NotificationController")

-- UI
local UI = DataCacheController:GetFile("Images")
local Colors = DataCacheController:GetFile("Colors")

return function(invReducer, params: table)
	setmetatable(params, {
		__index = {
			hooks = nil,

			equipped = false,
			deleting = false,

			id = 0,
			power = 0,

			name = "",
			icon = "",
			rarity = "",

			order = 1,
			actions = true,
		},
	})

	local styles, api = RoactSpring.useSpring(params.hooks, function()
		return {
			transparency = 1,
			config = {
				duration = 0.1,
			},
		}
	end)

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = UI.Inventory_Item_Background,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Colors[params.rarity],
		LayoutOrder = params.order,
		Position = params.position,
		Size = params.size,

		[Roact.Event.MouseButton1Click] = function()
			if params.actions then
				Sound:PlaySound("UI_Click")
				--SoundController:CreateSound(Players.LocalPlayer.Character, "UI_Click")

				if invReducer.DeletingPets then
					if params.deleting then
						Store:dispatch(InventoryActions.removeDeletedPet(tostring(params.id)))
					else
						Store:dispatch(InventoryActions.addDeletedPet(tostring(params.id)))
					end
				else
					local _, res
					if params.equipped then
						_, res = PetsService:UnequipPet({ id = params.id, name = params.name }, false):await()
					else
						_, res = PetsService:EquipPet({ id = params.id, name = params.name }, false):await()
					end
					NotificationController:Notify(res)
				end
			end
		end,

		[Roact.Event.MouseEnter] = function()
			api.start({ transparency = 0 })
		end,

		[Roact.Event.MouseLeave] = function()
			api.start({ transparency = 1 })
		end,
	}, {
		AspectRatio = AspectRatio({ ratio = 1 }),
		Deleting = Image({
			image = UI.Cross,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.5, 0.5),
			backgroundTransparency = 1,
			visible = params.deleting,
			index = 12,
		}),
		Equipped = Image({
			image = UI.Check,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.5, 0.5),
			backgroundTransparency = 1,
			visible = params.equipped,
			index = 11,
		}),
		Icon = Image({
			image = params.icon,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.75, 0.75),
			backgroundTransparency = 1,
		}),
		Power = Text({
			text = `x{params.power}`,
			position = UDim2.fromScale(0.5, 0.855),
			size = UDim2.fromScale(0.83, 0.264),
			backgroundTransparency = 1,
			color = Color3.fromRGB(255, 255, 255),
			stroke = 2,
			index = 10,
		}),

		Tooltip = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 1.6),
			Size = UDim2.fromScale(1.6, 1.6),
			Visible = if styles.transparency
				then styles.transparency:map(function(transparency)
					return if transparency == 0 then true else false
				end)
				else false,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			ZIndex = 15,
		}, {
			Corner = Corner({ radius = 0.2 }),
			Stroke = Stroke({
				thick = 2,
				color = Colors[params.rarity],
			}),

			Name = Text({
				text = params.name,
				position = UDim2.fromScale(0.5, 0.125),
				size = UDim2.fromScale(0.83, 0.2),
				backgroundTransparency = 1,
				color = if string.find(params.name, "Rainbow")
					then Colors["Rainbow"]
					elseif string.find(params.name, "Gold") then Colors["Gold"]
					else Color3.fromRGB(255, 255, 255),
				stroke = 2,
				index = 16,
			}),

			Rarity = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.35),
				Size = UDim2.fromScale(0.5, 0.2),
				BackgroundColor3 = Colors[params.rarity],
				ZIndex = 16,
			}, {
				Corner = Corner({ radius = 0.3 }),
				Text = Text({
					text = params.rarity,
					position = UDim2.fromScale(0.5, 0.5),
					size = UDim2.fromScale(0.83, 1),
					backgroundTransparency = 1,
					color = Color3.fromRGB(255, 255, 255),
					stroke = 2,
					index = 17,
				}),
			}),

			Multiplier = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.6),
				Size = UDim2.fromScale(1, 0.2),
				BackgroundTransparency = 1,
				ZIndex = 16,
			}, {
				DiscoBall = Image({
					image = UI.Money2,
					position = UDim2.fromScale(0.3, 0.5),
					size = UDim2.fromScale(1, 1),
					backgroundTransparency = 1,
					index = 17,
				}),

				MultiplierText = Text({
					text = `x{params.power}`,
					position = UDim2.fromScale(0.7, 0.5),
					size = UDim2.fromScale(0.5, 1),
					backgroundTransparency = 1,
					color = Color3.fromRGB(255, 255, 255),
					stroke = 2,
					index = 17,
				}),
			}),

			Exists = Text({
				text = "79 exists.",
				color = Color3.fromRGB(180, 180, 180),
				stroke = 2,
				position = UDim2.fromScale(0.5, 0.85),
				size = UDim2.fromScale(0.83, 0.15),
				index = 16,
			}),
		}),
	})
end
