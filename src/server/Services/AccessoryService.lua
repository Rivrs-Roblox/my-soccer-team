local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Knit Services
local DataService
local GachaService
local DataCacheService

local AccessoryService = Knit.CreateService({
	Name = "AccessoryService",
	Client = {
		AccessoriesUpdated = Knit.CreateSignal(),
	},
	SoccerCharactersChanged = Signal.new(),
})

--|| Client Functions ||--
function AccessoryService.Client:EquipAccessory(player: Player, charId: any, itemName: string)
	return self.Server:EquipAccessory(player, charId, itemName)
end

function AccessoryService.Client:UnequipAccessory(player: Player, charId: any, slot: string)
	return self.Server:UnequipAccessory(player, charId, slot)
end

function AccessoryService.Client:EquipBest(player: Player, charId: any)
	return self.Server:EquipBest(player, charId)
end

function AccessoryService.Client:DeleteAccessory(player: Player, id: any)
	return self.Server:DeleteAccessory(player, id)
end

--|| Local Functions ||--
local function internalUnequip(data, char, slot)
	local accessoryId = char.Accessories[slot]
	if not accessoryId then return nil end

	local inventoryItem = data.Inventory.Accessories[accessoryId]
		or data.Inventory.Accessories[tostring(accessoryId)]
		or data.Inventory.Accessories[tonumber(accessoryId)]

	local itemName = if inventoryItem then inventoryItem.Name else "Accessory"

	if inventoryItem then
		inventoryItem.Equipped = false
	end

	char.Accessories[slot] = nil

	return itemName
end

--|| Functions ||--
function AccessoryService:EquipAccessory(player: Player, charId: any, accessoryId: any)
	local data = DataService:GetData(player)
	if not data then
		return warn("[ACCESSORY SERVICE] Player has no data: " .. player.Name)
	end

	local char = data.Inventory.SoccerCharacters[charId]
		or data.Inventory.SoccerCharacters[tostring(charId)]
		or data.Inventory.SoccerCharacters[tonumber(charId)]
	if not char then
		return {
			text = self.Template.Messages.Notifications.SoccerCharacter_Not_Yours(tostring(charId)),
			type = "ERROR",
		}
	end

	if not char.Accessories then
		char.Accessories = {}
	end

	local inventoryItem = data.Inventory.Accessories[accessoryId]
		or data.Inventory.Accessories[tostring(accessoryId)]
		or data.Inventory.Accessories[tonumber(accessoryId)]
	if not inventoryItem then
		return { text = "This accessory was not found in your inventory.", type = "ERROR" }
	end

	local itemName = inventoryItem.Name
	local accessoryTemplate = self.Template.Accessories[itemName]
	if not accessoryTemplate then
		return { text = self.Template.Messages.Notifications.Accessory_Not_Exists(itemName), type = "ERROR" }
	end

	local slot = accessoryTemplate.Type
	if not slot then
		return { text = "This accessory has no assigned slot type in the template.", type = "ERROR" }
	end

	if char.Accessories[slot] == tostring(accessoryId) then
		return { text = "This specific accessory is already equipped on this slot.", type = "ERROR" }
	end

	-- Check if THIS SPECIFIC ID is equipped on ANY OTHER character or ANY OTHER slot
	for cid, cdata in pairs(data.Inventory.SoccerCharacters) do
		for cslot, aid in pairs(cdata.Accessories or {}) do
			if tostring(aid) == tostring(accessoryId) then
				if tostring(cid) == tostring(charId) and cslot == slot then
					continue -- Same slot, already handled above
				end
				return { text = "This accessory is already equipped on another character or slot.", type = "ERROR" }
			end
		end
	end

	-- Use internal unequip for previous item in the slot
	internalUnequip(data, char, slot)

	-- Equip new one
	char.Accessories[slot] = tostring(accessoryId)
	inventoryItem.Equipped = true

	self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
	self.SoccerCharactersChanged:Fire(player, data.Inventory.SoccerCharacters)

	return { text = `Equipped {itemName} to {char.Name}!`, type = "SUCCESS" }
end

function AccessoryService:UnequipAccessory(player: Player, charId: any, slot: string)
	local data = DataService:GetData(player)
	if not data then
		return
	end

	local char = data.Inventory.SoccerCharacters[charId]
		or data.Inventory.SoccerCharacters[tostring(charId)]
		or data.Inventory.SoccerCharacters[tonumber(charId)]
	if not char or not char.Accessories then
		return
	end

	local itemName = internalUnequip(data, char, slot)
	if not itemName then return end

	self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
	self.SoccerCharactersChanged:Fire(player, data.Inventory.SoccerCharacters)

	return { text = `Unequipped {itemName} from {char.Name}!`, type = "SUCCESS" }
end

function AccessoryService:UnequipAllFromCharacter(player: Player, charId: any)
	local data = DataService:GetData(player)
	if not data then
		return
	end

	local char = data.Inventory.SoccerCharacters[charId]
		or data.Inventory.SoccerCharacters[tostring(charId)]
		or data.Inventory.SoccerCharacters[tonumber(charId)]
	if not char or not char.Accessories then
		return
	end

	local changed = false
	for slot, _ in pairs(char.Accessories) do
		internalUnequip(data, char, slot)
		changed = true
	end

	if changed then
		self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
		self.SoccerCharactersChanged:Fire(player, data.Inventory.SoccerCharacters)
	end
end

function AccessoryService:TransferAccessories(player: Player, fromCharId: any, toCharId: any)
	local data = DataService:GetData(player)
	if not data then return end

	local fromChar = data.Inventory.SoccerCharacters[fromCharId]
		or data.Inventory.SoccerCharacters[tostring(fromCharId)]
		or data.Inventory.SoccerCharacters[tonumber(fromCharId)]

	local toChar = data.Inventory.SoccerCharacters[toCharId]
		or data.Inventory.SoccerCharacters[tostring(toCharId)]
		or data.Inventory.SoccerCharacters[tonumber(toCharId)]

	if not fromChar or not toChar then return end

	local sourceAccessories = fromChar.Accessories or {}

	-- Unequip any existing accessories from the destination character
	if toChar.Accessories then
		for slot, _ in pairs(toChar.Accessories) do
			internalUnequip(data, toChar, slot)
		end
	end

	toChar.Accessories = {}
	local changed = false

	for slot, aid in pairs(sourceAccessories) do
		-- Mark as equipped for the destination character
		local invItem = data.Inventory.Accessories[aid]
			or data.Inventory.Accessories[tostring(aid)]
			or data.Inventory.Accessories[tonumber(aid)]

		if invItem then
			toChar.Accessories[slot] = tostring(aid)
			invItem.Equipped = true
			changed = true
		end
	end

	-- Clear source character's accessories, but do NOT unequip them 
	-- from the inventory because they are now on the destination character
	fromChar.Accessories = {}

	if changed then
		self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
		self.SoccerCharactersChanged:Fire(player, data.Inventory.SoccerCharacters)
	end
end

function AccessoryService:EquipBest(player: Player, charId: any)
	local data = DataService:GetData(player)
	if not data then return end

	local char = data.Inventory.SoccerCharacters[charId]
		or data.Inventory.SoccerCharacters[tostring(charId)]
		or data.Inventory.SoccerCharacters[tonumber(charId)]
	if not char then return { text = "Character not found.", type = "ERROR" } end

	if not char.Accessories then
		char.Accessories = {}
	end

	local availableAccessories = {}
	for aid, invItem in pairs(data.Inventory.Accessories) do
		local isEquippedByOther = false
		for cid, cdata in pairs(data.Inventory.SoccerCharacters) do
			if tostring(cid) ~= tostring(charId) then
				for _, eqAid in pairs(cdata.Accessories or {}) do
					if tostring(eqAid) == tostring(aid) then
						isEquippedByOther = true
						break
					end
				end
			end
			if isEquippedByOther then break end
		end

		if not isEquippedByOther then
			local templateData = self.Template.Accessories[invItem.Name]
			if templateData and templateData.Type then
				table.insert(availableAccessories, {
					id = aid,
					invItem = invItem,
					templateData = templateData,
					priority = self.Template.RarityPriority[templateData.Rarity or "Common"] or 100,
				})
			end
		end
	end

	local bestByType = {}
	for _, acc in ipairs(availableAccessories) do
		local slotType = acc.templateData.Type
		local currentBest = bestByType[slotType]

		if not currentBest then
			bestByType[slotType] = acc
		else
			local accScore = (acc.templateData.Additions and ((acc.templateData.Additions.Shoot or 0) + (acc.templateData.Additions.Pass or 0) + (acc.templateData.Additions.Dribble or 0))) or 0
			local bestScore = (currentBest.templateData.Additions and ((currentBest.templateData.Additions.Shoot or 0) + (currentBest.templateData.Additions.Pass or 0) + (currentBest.templateData.Additions.Dribble or 0))) or 0

			if accScore > bestScore then
				bestByType[slotType] = acc
			elseif accScore == bestScore then
				if acc.priority < currentBest.priority then
					bestByType[slotType] = acc
				elseif acc.priority == currentBest.priority then
					local aidNum = tonumber(acc.id)
					local bestIdNum = tonumber(currentBest.id)
					if aidNum and bestIdNum and aidNum > bestIdNum then
						bestByType[slotType] = acc
					end
				end
			end
		end
	end

	local changed = false
	for slotType, bestAcc in pairs(bestByType) do
		if char.Accessories[slotType] ~= tostring(bestAcc.id) then
			internalUnequip(data, char, slotType)
			char.Accessories[slotType] = tostring(bestAcc.id)
			bestAcc.invItem.Equipped = true
			changed = true
		end
	end

	if changed then
		self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
		self.SoccerCharactersChanged:Fire(player, data.Inventory.SoccerCharacters)
		return { text = `Equipped best accessories!`, type = "SUCCESS" }
	else
		return { text = `Best accessories are already equipped!`, type = "SUCCESS" }
	end
end


function AccessoryService:AddAccessory(player: Player, itemName: string)
	local data = DataService:GetData(player)
	if not data then
		return warn("[ACCESSORY SERVICE] Player has no data: " .. player.Name)
	end

	local accessoryTemplate = self.Template.Accessories[itemName]
	if not accessoryTemplate then
		return warn("[ACCESSORY SERVICE] Accessory not found: " .. itemName)
	end

	local currentCount = 0
	for _ in pairs(data.Inventory.Accessories or {}) do
		currentCount += 1
	end

	if currentCount + 1 > data.Inventory.Storage.Stored then
		return { text = self.Template.Messages.Notifications.Not_Enough_Storage_Space, type = "ERROR" }
	end

	local maxId = 0
	for id, _ in pairs(data.Inventory.Accessories or {}) do
		local numericId = tonumber(id)
		if numericId and numericId > maxId then
			maxId = numericId
		end
	end
	local newId = tostring(maxId + 1)

	data.Inventory.Accessories[newId] = {
		Name = itemName,
		Equipped = false,
	}

	self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)
end

function AccessoryService:DeleteAccessory(player: Player, id: any)
	local data = DataService:GetData(player)
	if not data then
		return warn("[ACCESSORY SERVICE] Player has no data: " .. player.Name)
	end

	local inventoryItem = data.Inventory.Accessories[id] or data.Inventory.Accessories[tostring(id)]
	if not inventoryItem then
		return { text = "Accessory not found in inventory.", type = "ERROR" }
	end

	local itemName = inventoryItem.Name

	-- Check if equipped by any character
	for cid, character in pairs(data.Inventory.SoccerCharacters) do
		for _, equippedId in pairs(character.Accessories or {}) do
			if tostring(equippedId) == tostring(id) then
				return { text = self.Template.Messages.Notifications.Accessory_Equipped(itemName), type = "ERROR" }
			end
		end
	end

	data.Inventory.Accessories[tostring(id)] = nil
	local numId = tonumber(id)
	if numId then
		data.Inventory.Accessories[numId] = nil
	end

	self.Client.AccessoriesUpdated:Fire(player, data.Inventory.Accessories)

	return { text = self.Template.Messages.Notifications.Accessory_Deleted(itemName), type = "SUCCESS" }
end

--|| Knit Lifecycle ||--
function AccessoryService:KnitInit()
	DataService = Knit.GetService("DataService")
	GachaService = Knit.GetService("GachaService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")
end

function AccessoryService:KnitStart()
	local TeamService = Knit.GetService("TeamService")

	TeamService.CharacterRemovedFromTeam:Connect(function(player, charId)
		self:UnequipAllFromCharacter(player, charId)
	end)

	GachaService.GachaOpened:Connect(function(player, items, type, category)
		if category == "Accessories" then
			for _, itemName in ipairs(items) do
				self:AddAccessory(player, itemName)
			end
		end
	end)
end

return AccessoryService
