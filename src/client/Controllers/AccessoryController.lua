-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

local Helpers = ReplicatedStorage.Shared.Helpers
local GetModel = require(Helpers.SoccerCharacters.GetModel)
local EquipAccessory = require(Helpers.SoccerCharacters.EquipAccessory)
local FormatNumber = require(Helpers.Numbers.FormatNumber)
local SetInterval = require(Helpers.SetInterval)
local Tween = require(Helpers.Tween)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

-- Knit Services
local AccessoryService

-- Knit Controllers
local NotificationController
local DataCacheController
local GachaController

-- Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local accessoryGui = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GUIs"):WaitForChild("AccessoryGui")

local blockAccessoryAction = false

local viewportAssets = ReplicatedStorage.Assets.Viewport

local AccessoryController = Knit.CreateController({
	Name = "AccessoryController",
})

--|| Functions ||--
function AccessoryController:UpdateChestUI(instance: Model)
	local type = instance:GetAttribute("Type")

	if not type then
		return
	end

	local packData = self.Template.Gacha.Accessories and self.Template.Gacha.Accessories[tostring(type)]
	if not packData then
		return
	end

	local priceText = self.ChestUI:FindFirstChild("PriceText", true)
	if priceText then
		priceText.Text = FormatNumber(packData.Price)
	end

	if not self.ListContainer or not self.TemplateRarity then
		return
	end

	local order = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Gold Legendary",
	}

	-- Clear previous items
	for _, child in ipairs(self.ListContainer:GetChildren()) do
		if table.find(order, child.Name) then
			child:Destroy()
		end
	end

	for i, rarity in ipairs(order) do
		local chance = packData.Chances[rarity]
		if chance and chance > 0 then
			local newRarity = self.TemplateRarity:Clone()
			newRarity.Name = rarity
			newRarity.LayoutOrder = i
			newRarity.Number.Text = `{chance}%`
			newRarity.Rarity.Text = rarity
			newRarity.Parent = self.ListContainer

			if self.Colors[rarity] then
				newRarity.Rarity.TextColor3 = self.Colors[rarity]
			end

			local templateContent = newRarity:FindFirstChild("TemplateContent", true)
			if templateContent then
				local contentContainer = templateContent.Parent
				local layoutOrderContent = 1

				for _, itemName in ipairs(packData.Items) do
					local itemData = self.Template.Accessories and self.Template.Accessories[itemName]
					if itemData and itemData.Rarity == rarity then
						local newContent = templateContent:Clone()
						newContent.Name = itemName
						newContent.LayoutOrder = layoutOrderContent

						local viewport = newContent:FindFirstChild("Viewport", true)
						if viewport then
							viewport.Image = self.UI[itemName] or ""
						end

						if self.Colors[rarity] then
							newContent.BackgroundColor3 = self.Colors[rarity]
						end

						newContent.Visible = true
						newContent.Parent = contentContainer
						layoutOrderContent += 1
					end
				end

				templateContent:Destroy()
			end

			newRarity.Visible = true
		end
	end

	-- Button connections moved to KnitStart to prevent memory leaks
end

function AccessoryController:EquipAccessory(charId: any, accessoryId: any)
	if blockAccessoryAction then
		NotificationController:Notify({ tag = "Accessory", text = "Processing...", type = "ERROR" })
		return
	end

	blockAccessoryAction = true
	return AccessoryService:EquipAccessory(charId, accessoryId)
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Accessory", text = result.text, type = result.type })
			end
			blockAccessoryAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockAccessoryAction = false
		end)
end

function AccessoryController:UnequipAccessory(charId: any, slot: string)
	if blockAccessoryAction then
		NotificationController:Notify({ tag = "Accessory", text = "Processing...", type = "ERROR" })
		return
	end

	blockAccessoryAction = true
	return AccessoryService:UnequipAccessory(charId, slot)
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Accessory", text = result.text, type = result.type })
			end
			blockAccessoryAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockAccessoryAction = false
		end)
end

function AccessoryController:EquipBest(charId: any)
	if blockAccessoryAction then
		NotificationController:Notify({ tag = "Accessory", text = "Processing...", type = "ERROR" })
		return
	end

	blockAccessoryAction = true
	return AccessoryService:EquipBest(charId)
		:andThen(function(result)
			if result then
				NotificationController:Notify({ tag = "Accessory", text = result.text, type = result.type })
			end
			blockAccessoryAction = false
			return result
		end)
		:catch(function(err)
			warn(err)
			blockAccessoryAction = false
		end)
end

function AccessoryController:UpdateViewportCharacter()
	if not self.Viewport then
		return
	end

	local state = Store:getState()
	local selectedSlot = state.AccessoryReducer.SelectedSlot
	local charId = state.TeamReducer.EquippedSoccerCharacters[selectedSlot]
		or state.TeamReducer.EquippedSoccerCharacters[tostring(selectedSlot)]
	local accessoriesData = state.InventoryReducer.Accessories

	local newHash = ""
	local charData = nil
	if charId then
		charData = state.InventoryReducer.SoccerCharacters[charId]
			or state.InventoryReducer.SoccerCharacters[tostring(charId)]
		if charData and charData.Accessories then
			for slotName, id in pairs(charData.Accessories) do
				newHash = newHash .. slotName .. tostring(id)
			end
		end
	end

	if selectedSlot ~= self.CurrentSlot or self.CurrentAccessoriesHash ~= newHash or self.CurrentCharId ~= charId then
		self.CurrentSlot = selectedSlot
		self.CurrentAccessoriesHash = newHash
		self.CurrentCharId = charId

		local pivot = self.Viewport:FindFirstChild("Pivot", true)
		local pivotCFrame = nil
		local pivotParent = self.Viewport
		if pivot then
			pivotCFrame = pivot:GetPivot()
			pivotParent = pivot.Parent
			pivot:Destroy()
		end

		if charData then
			local originalModel = GetModel(charData)
			if originalModel then
				local clone = originalModel:Clone()
				clone.Name = "Pivot"
				if pivotCFrame then
					clone:PivotTo(pivotCFrame)
				end

				EquipAccessory(clone, charData, accessoriesData)
				clone.Parent = pivotParent
			end
		end
	end
end

function AccessoryController:GetClosestChest()
	local ClosestChest = nil
	local ClosestDistance = math.huge

	for _, Chest in self.ChestsModels do
		local Distance = Players.LocalPlayer:DistanceFromCharacter(Chest.PrimaryPart.Position)
		if Distance < ClosestDistance then
			ClosestChest = Chest
			ClosestDistance = Distance
		end
	end

	return ClosestChest, ClosestDistance
end

function AccessoryController:UpdateUI()
	local Chest, Distance = self:GetClosestChest()
	local ValidDistance = Distance < 10
	local Valid = ValidDistance and not GachaController.Opening

	if Valid then
		local packType = Chest:GetAttribute("Type")
		if packType then
			local packData = self.Template.Gacha.Accessories and self.Template.Gacha.Accessories[tostring(packType)]
			if packData then
				local wins = Store:getState().PlayerReducer.Wins or 0
				self.HasEnoughWins = wins >= packData.Price

				local buttonsContainer = self.ChestUI:FindFirstChild("Buttons", true)
				if buttonsContainer then
					local disableOverlay = buttonsContainer:FindFirstChild("Disable")
					if disableOverlay then
						disableOverlay.Visible = not self.HasEnoughWins
					end
					for _, button in ipairs(buttonsContainer:GetChildren()) do
						if button:IsA("ImageButton") then
							button.Visible = self.HasEnoughWins
						end
					end
				end
			end
		end
	else
		self.HasEnoughWins = false
	end

	if Valid and self.CurrentChest ~= Chest then
		self.Debounce = true
		self.CurrentChest = Chest

		self.ChestUI.Adornee = Chest.PrimaryPart
		self:UpdateChestUI(Chest)

		if self.EUIScale then
			Tween(self.EUIScale, { Scale = 1 }, 0.2)
		end
	elseif not Valid and self.CurrentChest then
		self.Debounce = false
		self.CurrentChest = nil

		if self.EUIScale then
			Tween(self.EUIScale, { Scale = 0 }, 0.2)
		end

		task.delay(0.2, function()
			if not self.CurrentChest and self.ChestUI then
				self.ChestUI.Adornee = nil
			end
		end)
	end
end

--|| Knit Lifecycle ||--
function AccessoryController:KnitInit()
	AccessoryService = Knit.GetService("AccessoryService")

	NotificationController = Knit.GetController("NotificationController")
	DataCacheController = Knit.GetController("DataCacheController")
	GachaController = Knit.GetController("GachaController")

	self.Template = DataCacheController:GetFile("Template")
	self.Colors = DataCacheController:GetFile("Colors")
	self.UI = DataCacheController:GetFile("Images")
	self.ViewportCameraSettings = DataCacheController:GetFile("ViewportCameraSettings")

	self.CurrentSlot = nil
	self.CurrentRenderedCharacter = nil
	self.CurrentAccessoriesHash = nil
	self.CurrentCharId = nil
end

function AccessoryController:KnitStart()
	local gameScreenGui = playerGui:WaitForChild("GameScreenGui")
	self.Viewport = gameScreenGui:FindFirstChild("Viewport", true)

	local worldModel = self.Viewport:FindFirstChildOfClass("WorldModel")
	if not worldModel then
		worldModel = Instance.new("WorldModel")
		worldModel.Parent = self.Viewport
	end

	for _, viewportAsset in ipairs(viewportAssets:GetChildren()) do
		local clone = viewportAsset:Clone()
		clone.Parent = worldModel
	end

	local viewportCamera = Instance.new("Camera")
	viewportCamera.Parent = self.Viewport
	viewportCamera.CFrame = CFrame.new(self.ViewportCameraSettings.CFrame.Position)
		* CFrame.fromOrientation(
			math.rad(self.ViewportCameraSettings.CFrame.Rotation.X),
			math.rad(self.ViewportCameraSettings.CFrame.Rotation.Y),
			math.rad(self.ViewportCameraSettings.CFrame.Rotation.Z)
		)
	viewportCamera.Focus = CFrame.new(self.ViewportCameraSettings.Focus.Position)
		* CFrame.fromOrientation(
			math.rad(self.ViewportCameraSettings.Focus.Rotation.X),
			math.rad(self.ViewportCameraSettings.Focus.Rotation.Y),
			math.rad(self.ViewportCameraSettings.Focus.Rotation.Z)
		)
	self.Viewport.CurrentCamera = viewportCamera

	Store.changed:connect(function(newState, oldState)
		if newState.UIReducer.CurrentCustomizeUI == "Accessories" then
			self:UpdateViewportCharacter()
		end
	end)

	if Store:getState().UIReducer.CurrentCustomizeUI == "Accessories" then
		self:UpdateViewportCharacter()
	end

	self.ChestsModels = CollectionService:GetTagged("AccessoryChest")

	CollectionService:GetInstanceAddedSignal("AccessoryChest"):Connect(function(chest)
		table.insert(self.ChestsModels, chest)
	end)

	CollectionService:GetInstanceRemovedSignal("AccessoryChest"):Connect(function(chest)
		local index = table.find(self.ChestsModels, chest)
		if index then
			table.remove(self.ChestsModels, index)
		end
	end)

	self.ChestUI = accessoryGui:Clone()
	self.ChestUI.Parent = playerGui
	self.ChestUI.Adornee = nil

	self.EUIScale = self.ChestUI:FindFirstChild("Scale", true)
	if self.EUIScale then
		self.EUIScale.Scale = 0
	end

	self.TemplateRarity = self.ChestUI:FindFirstChild("TemplateRarity", true)
	if self.TemplateRarity then
		self.TemplateRarity.Visible = false
		self.ListContainer = self.TemplateRarity.Parent
	end

	local buttonsContainer = self.ChestUI:FindFirstChild("Buttons", true)
	if buttonsContainer then
		for _, button in ipairs(buttonsContainer:GetChildren()) do
			if button:IsA("ImageButton") then
				button.MouseButton1Click:Connect(function()
					if self.CurrentChest then
						local packType = self.CurrentChest:GetAttribute("Type")
						if packType then
							GachaController:Buy("Accessories", packType, "Wins", 1)
						end
					end
				end)
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			if self.CurrentChest and not GachaController.Opening then
				local packType = self.CurrentChest:GetAttribute("Type")
				if packType then
					GachaController:Buy("Accessories", packType, "Wins", 1)
				end
			end
		end
	end)

	local disable = buttonsContainer:WaitForChild("Disable")

	SetInterval(function()
		self:UpdateUI()
	end, 0.2)

	print("[ACCESSORY CONTROLLER] Controller loaded successfully.")
end

return AccessoryController
