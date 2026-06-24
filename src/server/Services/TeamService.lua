-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Helpers
local GetStats = require(ReplicatedStorage.Shared.Helpers.SoccerCharacters.GetStats)

-- Knit Services
local DataService
local DataCacheService

local TeamService = Knit.CreateService({
	Name = "TeamService",
	Client = {
		TeamSlotSet = Knit.CreateSignal(),
	},
	CharacterRemovedFromTeam = Signal.new(),
})

--|| Client Functions ||--

function TeamService.Client:SetSlot(player: Player, slot: number, characterId: number)
	return self.Server:SetSlot(player, slot, characterId)
end

function TeamService.Client:EquipBest(player: Player)
	return self.Server:EquipBest(player)
end

--|| Functions ||--

function TeamService:SetSlot(player: Player, slot: number, characterId: number)
	local playerData = DataService:GetData(player)

	if not playerData then
		return false
	end

	local previousId = playerData.Inventory.EquippedSoccerCharacters[slot]
	if previousId and previousId ~= characterId then
		if characterId then
			local AccessoryService = Knit.GetService("AccessoryService")
			AccessoryService:TransferAccessories(player, previousId, characterId)
		else
			self.CharacterRemovedFromTeam:Fire(player, previousId)
		end
	end

	playerData.Inventory.EquippedSoccerCharacters[slot] = characterId

	self.Client.TeamSlotSet:FireAll(player, playerData.Inventory.EquippedSoccerCharacters)

	return true
end

function TeamService:EquipBest(player: Player)
	local playerData = DataService:GetData(player)

	if not playerData then
		return false
	end

	local inventory = playerData.Inventory.SoccerCharacters
	local equipped = playerData.Inventory.EquippedSoccerCharacters

	local previousEquipped = table.clone(equipped)
	local slotAccessories = {}

	-- Extract accessories for each slot and clear them from the characters
	for slot, id in pairs(previousEquipped) do
		local char = inventory[id] or inventory[tostring(id)] or inventory[tonumber(id)]
		if char and char.Accessories then
			slotAccessories[slot] = table.clone(char.Accessories)
			char.Accessories = {}
		end
	end

	-- Reset equipped slots
	table.clear(equipped)

	local usedIds = {}

	local function getBestForStat(...)
		local statNames = { ... }
		local bestId = nil
		local bestValue = -1

		for id, charData in pairs(inventory) do
			if usedIds[id] then
				continue
			end

			local stats = GetStats(charData)
			if stats then
				local totalValue = 0
				for _, statName in ipairs(statNames) do
					totalValue += (stats[statName] or 0)
				end

				if totalValue > bestValue then
					bestValue = totalValue
					bestId = id
				end
			end
		end

		if bestId then
			usedIds[bestId] = true
		end
		return bestId
	end

	local newEquipped = {}
	-- Slot 1: Highest Shoot
	newEquipped[1] = getBestForStat("Shoot")

	-- Slot 2: Highest Dribble + Pass
	newEquipped[2] = getBestForStat("Dribble", "Pass")

	-- Slot 3: Highest Dribble + Pass
	newEquipped[3] = getBestForStat("Dribble", "Pass")

	local changedAccessories = false

	for slot = 1, 3 do
		local newId = newEquipped[slot]
		local newChar = nil
		if newId then
			newChar = inventory[newId] or inventory[tostring(newId)] or inventory[tonumber(newId)]
		end
		
		local accessoriesToApply = slotAccessories[slot]
		
		if newChar then
			-- Unequip whatever the new character had
			if newChar.Accessories then
				for _, aid in pairs(newChar.Accessories) do
					local invItem = playerData.Inventory.Accessories[aid] or playerData.Inventory.Accessories[tostring(aid)] or playerData.Inventory.Accessories[tonumber(aid)]
					if invItem then invItem.Equipped = false end
					changedAccessories = true
				end
			end
			
			newChar.Accessories = {}
			
			-- Equip the cached slot accessories
			if accessoriesToApply then
				for accSlot, aid in pairs(accessoriesToApply) do
					newChar.Accessories[accSlot] = tostring(aid)
					local invItem = playerData.Inventory.Accessories[aid] or playerData.Inventory.Accessories[tostring(aid)] or playerData.Inventory.Accessories[tonumber(aid)]
					if invItem then invItem.Equipped = true end
					changedAccessories = true
				end
			end
		else
			-- If slot is empty, mark cached accessories as unequipped
			if accessoriesToApply then
				for accSlot, aid in pairs(accessoriesToApply) do
					local invItem = playerData.Inventory.Accessories[aid] or playerData.Inventory.Accessories[tostring(aid)] or playerData.Inventory.Accessories[tonumber(aid)]
					if invItem then invItem.Equipped = false end
					changedAccessories = true
				end
			end
		end
		
		if newId then
			equipped[slot] = newId
		end
	end

	if changedAccessories then
		local AccessoryService = Knit.GetService("AccessoryService")
		AccessoryService.Client.AccessoriesUpdated:Fire(player, playerData.Inventory.Accessories)
		AccessoryService.SoccerCharactersChanged:Fire(player, inventory)
	end

	self.Client.TeamSlotSet:FireAll(player, equipped)
	return true
end

--|| Knit Lifecycle ||--
function TeamService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")
end

function TeamService:KnitStart() end

return TeamService
