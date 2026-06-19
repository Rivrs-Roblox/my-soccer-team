--[=[
    Owner: JustStop__
	Version: 0.0.1
    Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.ZonePlus)
local MonetizationService

-- Controllers
local DataCacheController = nil
local UIController = nil

-- MonetizationController
local MonetizationController = Knit.CreateController({
	Name = "MonetizationController",

	Monetization = {},

	IDs = {},
	Prices = {},
	PurchasePromptActive = false,
	_purchasePromptToken = 0,
})

--|| Functions ||--
function MonetizationController:MarkPurchasePromptStarted()
	self._purchasePromptToken += 1
	local token = self._purchasePromptToken
	self.PurchasePromptActive = true
	if self.PromptStateChanged then
		self.PromptStateChanged:Fire(true)
	end

	task.delay(120, function()
		if self._purchasePromptToken == token then
			self.PurchasePromptActive = false
			if self.PromptStateChanged then
				self.PromptStateChanged:Fire(false)
			end
		end
	end)
end

function MonetizationController:MarkPurchasePromptFinished()
	self._purchasePromptToken += 1
	self.PurchasePromptActive = false
	if self.PromptStateChanged then
		self.PromptStateChanged:Fire(false)
	end
end

function MonetizationController:IsPurchasePromptActive(): boolean
	return self.PurchasePromptActive == true
end

function MonetizationController:_SetupMonetizationArea(instance: BasePart)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	local product = instance:GetAttribute("Product")
	local type = instance:GetAttribute("Type")

	-- Handle player entering the zone
	zone.playerEntered:Connect(function(player)
		if player == Players.LocalPlayer then
			if UIController and UIController.IsPanelOpenBlocked and UIController:IsPanelOpenBlocked() then
				return
			end

			self:MarkPurchasePromptStarted()
			MonetizationService:PromptPurchase(product, type)
		end
	end)

	local priceText = instance.Parent:FindFirstChild("PriceText", true)

	if priceText then
		priceText.Text = `{self:GetPrice(product)}`
	end
end

function MonetizationController:GetID(name: string)
	if self.IDs[name] ~= nil then
		return self.IDs[name]
	end

	for typeName, type in pairs(self.Monetization) do
		for id, item in pairs(type) do
			if item.Name == name then
				self.IDs[name] = { ID = id, Type = typeName }
				return { ID = id, Type = typeName }
			end
		end
	end

	return nil
end

function MonetizationController:GetPrice(name: string)
	if self.Prices[name] ~= nil then
		return self.Prices[name]
	end

	local data = self:GetID(name)
	if data == nil then
		return 0
	end

	local success, result = pcall(function()
		return MarketplaceService:GetProductInfoAsync(
			data.ID,
			data.Type == "GamePasses" and Enum.InfoType.GamePass or Enum.InfoType.Product
		)
	end)
	if not success then
		warn("Failed to get price for " .. name)
		return 0
	end

	self.Prices[name] = result.PriceInRobux
	if result.PriceInRobux then
		return result.PriceInRobux
	end
	return 0
end

--|| Knit Lifecycle ||--
function MonetizationController:KnitInit()
	self.PromptStateChanged = Instance.new("BindableEvent")
	MonetizationService = Knit.GetService("MonetizationService")

	local originalPromptPurchase = MonetizationService.PromptPurchase
	if originalPromptPurchase then
		MonetizationService.PromptPurchase = function(serviceSelf, ...)
			self:MarkPurchasePromptStarted()
			return originalPromptPurchase(serviceSelf, ...)
		end
	end

	DataCacheController = Knit.GetController("DataCacheController")
	UIController = Knit.GetController("UIController")

	self.Monetization = DataCacheController:GetFile("Monetization")

	task.wait(0.5)

	task.spawn(function()
		for type, data in pairs(self.Monetization) do
			for id, item in pairs(data) do
				task.spawn(function()
					self:GetPrice(item.Name)
				end)
			end
		end
	end)

	print("[MONETIZATION CONTROLLER] Controller loaded successfully.")
end

function MonetizationController:KnitStart()
	pcall(function()
		MarketplaceService.PromptProductPurchaseFinished:Connect(function()
			self:MarkPurchasePromptFinished()
		end)
	end)

	pcall(function()
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function()
			self:MarkPurchasePromptFinished()
		end)
	end)

	pcall(function()
		MarketplaceService.PromptPurchaseFinished:Connect(function()
			self:MarkPurchasePromptFinished()
		end)
	end)

	local existingAreas = CollectionService:GetTagged("MonetizationArea")
	for _, instance in pairs(existingAreas) do
		self:_SetupMonetizationArea(instance)
	end

	CollectionService:GetInstanceAddedSignal("MonetizationArea"):Connect(function(instance)
		self:_SetupMonetizationArea(instance)
	end)
end

return MonetizationController
