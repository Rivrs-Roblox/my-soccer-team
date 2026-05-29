-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local GachaConfig = require(ReplicatedStorage.Shared.Data.GachaConfig)

-- Services
local DataService
local DataCacheService
local MonetizationService

-- Initialize a dedicated random number generator for better distribution
local RNG = Random.new()
math.randomseed(tick())

local GachaService = Knit.CreateService({
	Name = "GachaService",
	Client = {
		GachaOpened = Knit.CreateSignal(),
		StockUpdated = Knit.CreateSignal(),
	},
	GachaOpened = Signal.new(),
	GachaStock = {},
})

--|| Client Functions ||--
function GachaService.Client:BuyGacha(player: Player, category: string, type: string, currency: string, amount: number)
	return self.Server:BuyGacha(player, category, type, currency, amount)
end

function GachaService.Client:GetStock(player: Player)
	return self.Server.GachaStock
end

function GachaService.Client:GetNextRefillTime(player: Player)
	return self.Server.NextRefillTime
end

--|| Functions ||--
function GachaService:BuyGacha(player: Player, category: string, type: string, currency: string, amount: number)
	local data = DataService:GetData(player)
	if not data then
		return warn("[GACHA SERVICE] Player has no data: " .. player.Name)
	end

	if not currency or data[currency] == nil then
		return warn("[GACHA SERVICE] Invalid currency: " .. tostring(currency))
	end

	local gacha = self.Template.Gacha[category][type]
	if gacha == nil then
		return warn("[GACHA SERVICE] Gacha not found: " .. category .. " " .. type)
	end

	if gacha.Stock then
		local currentStock = self.GachaStock[category] and self.GachaStock[category][type]
		if not currentStock or currentStock < amount then
			return { text = "Out of Stock! Please wait for refill.", type = "ERROR" }
		end
	end

	if gacha.Prerequisite then
		for key, reqValue in pairs(gacha.Prerequisite) do
			if (data[key] or 0) < reqValue then
				return {
					text = self.Template.Messages.Notifications.Prerequisite_Not_Met(reqValue, key),
					type = "ERROR",
				}
			end
		end
	end

	local currentCount = 0
	for _ in pairs(data.Inventory[category] or {}) do
		currentCount += 1
	end

	if currentCount + amount > data.Inventory.Storage.Stored then
		return { text = self.Template.Messages.Notifications.Not_Enough_Storage_Space, type = "ERROR" }
	end

	if data[currency] < gacha.Price * amount then
		-- Prompt player to purchase Wins pack
		return { text = self.Template.Messages.Notifications.Not_Enough_Money(currency), type = "ERROR" }
	end

	DataService:ChangeValue(player, currency, -gacha.Price * amount)
	
	if gacha.Stock then
		self.GachaStock[category][type] -= amount
		self.Client.StockUpdated:FireAll(self.GachaStock)
	end
	
	self:OpenGacha(player, category, type, amount)

	return { text = "", type = "SUCCESS" }
end

function GachaService:_getLuckMultiplier(player: Player)
	local multiplier = 1

	for passName, bonus in pairs(self.GlobalConfig.LuckMultipliers) do
		if MonetizationService:HasGamepass(player, passName) then
			multiplier += bonus
		end
	end

	return multiplier
end

function GachaService:OpenGacha(player: Player, category: string, type: string, amount: number)
	local gacha = self.Template.Gacha[category][type]
	if not gacha then
		return
	end

	local Items = {}
	local itemsTemplate = self.Template[category]

	local data = DataService:GetData(player)
	if data then
		if not data.PacksOpened then data.PacksOpened = 0 end
		data.PacksOpened += amount
		
		if data.PacksOpened >= 100 then
			if self.Template.Badges and self.Template.Badges.Pack then
				DataService:GiveBadge(player, self.Template.Badges.Pack)
			end
		end
	end

	local luckMultiplier = self:_getLuckMultiplier(player)

	for _ = 1, amount do
		-- Roll Rarity
		local totalWeight = 0
		local chances = {}

		for rarity, weight in pairs(gacha.Chances) do
			local modifiedWeight = weight
			if rarity ~= "Common" then
				modifiedWeight *= luckMultiplier
			end

			chances[rarity] = modifiedWeight
			totalWeight += modifiedWeight
		end

		if totalWeight == 0 then
			warn("[GACHA SERVICE] Total weight is 0 for gacha type: " .. type)
			break
		end

		local roll = RNG:NextNumber() * totalWeight
		local currentWeight = 0
		local rolledRarity

		for rarity, weight in pairs(chances) do
			currentWeight += weight
			if roll <= currentWeight then
				rolledRarity = rarity
				break
			end
		end

		-- Filter items by rarity
		local possibleItems = {}
		for _, itemName in ipairs(gacha.Items) do
			local itemData = itemsTemplate[itemName]
			if itemData and itemData.Rarity == rolledRarity then
				table.insert(possibleItems, itemName)
			end
		end

		if #possibleItems == 0 then
			warn(`[GACHA SERVICE] No items found for rarity {rolledRarity} in gacha {type}`)
			continue
		end

		local chosenItemName = possibleItems[RNG:NextInteger(1, #possibleItems)]
		table.insert(Items, chosenItemName)
	end

	if #Items > 0 then
		self.Client.GachaOpened:Fire(player, Items, type, category)
		self.GachaOpened:Fire(player, Items, type, category)
	end

	return Items
end

function GachaService:Restock()
	self.NextRefillTime = workspace:GetServerTimeNow() + GachaConfig.General.RefillInterval

	for category, packs in pairs(self.Template.Gacha) do
		if not self.GachaStock[category] then
			self.GachaStock[category] = {}
		end
		for type, gachaData in pairs(packs) do
			if gachaData.Stock then
				self.GachaStock[category][type] = gachaData.Stock
			end
		end
	end

	self.Client.StockUpdated:FireAll(self.GachaStock, self.NextRefillTime)
end

--|| Knit Lifecycle ||--
function GachaService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	MonetizationService = Knit.GetService("MonetizationService")

	self.Template = DataCacheService:GetFile("Template")
	self.GlobalConfig = DataCacheService:GetFile("GlobalConfig")
end

function GachaService:KnitStart()
	self:Restock()

	task.spawn(function()
		while true do
			task.wait(GachaConfig.General.RefillInterval)
			self:Restock()
		end
	end)
end

return GachaService
