-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)
local FindValue = require(Helpers.Table.FindValue)

-- Knit Services
local DataService
local DataCacheService
local GachaService
local AccessoryService

local SoccerCharactersService = Knit.CreateService({
	Name = "SoccerCharactersService",
	Client = {
		SoccerCharactersUpdated = Knit.CreateSignal(),
		MergeCompleted = Knit.CreateSignal(),
	},
})

--|| Client Functions ||--
function SoccerCharactersService.Client:DeleteCharacter(player: Player, id: any)
	return self.Server:DeleteCharacter(player, id)
end

function SoccerCharactersService.Client:MergeCharacters(player: Player, ids: { any })
	return self.Server:MergeCharacters(player, ids)
end

--|| Functions ||--
function SoccerCharactersService:MergeCharacters(player: Player, ids: { any })
	if not ids or #ids < 2 then
		return { text = "Select at least 2 characters to merge.", type = "ERROR" }
	end

	local playerData = DataService:GetData(player)
	if not playerData then
		return { text = "Player data not found.", type = "ERROR" }
	end

	local inventory = playerData.Inventory.SoccerCharacters
	local equipped = playerData.Inventory.EquippedSoccerCharacters

	local characters = {}
	local firstChar = nil

	-- Validation
	for i, id in ipairs(ids) do
		local numId = tonumber(id)
		local char = inventory[id] or inventory[tostring(id)] or (numId and inventory[numId])
		if not char then
			return { text = "One or more characters not found in inventory.", type = "ERROR" }
		end

		if not firstChar then
			firstChar = char
		else
			if char.Name ~= firstChar.Name or char.Level ~= firstChar.Level then
				return { text = "All characters must be of the same name and level.", type = "ERROR" }
			end
		end

		table.insert(characters, { id = id, data = char })
	end

	local mergeData = self.Template.MergeRequirements
	local currentLevel = firstChar.Level

	if currentLevel >= mergeData.MAX_LEVEL then
		return { text = "Character is already at max level (" .. mergeData.MAX_LEVEL .. ").", type = "ERROR" }
	end

	local requiredAmount = mergeData.REQUIREMENTS[currentLevel]
	if not requiredAmount then
		return { text = "No merge requirements defined for level " .. currentLevel .. ".", type = "ERROR" }
	end

	if #ids ~= requiredAmount then
		return {
			text = "To reach level "
				.. (currentLevel + 1)
				.. ", you need exactly "
				.. requiredAmount
				.. " level "
				.. currentLevel
				.. " characters.",
			type = "ERROR",
		}
	end

	-- Check if any are equipped
	for _, char in ipairs(characters) do
		for slot, equippedId in pairs(equipped) do
			if tostring(equippedId) == tostring(char.id) then
				return { text = "Cannot merge equipped characters. Please unequip them first.", type = "ERROR" }
			end
		end
	end

	-- Execute Merge
	local targetId = characters[1].id
	local targetChar = characters[1].data

	-- Level up the first one
	targetChar.Level += 1

	-- Delete the others
	for i = 2, #characters do
		local idToDelete = characters[i].id
		inventory[idToDelete] = nil
		inventory[tostring(idToDelete)] = nil
		local numId = tonumber(idToDelete)
		if numId then
			inventory[numId] = nil
		end
	end

	-- Sync
	self.Client.SoccerCharactersUpdated:Fire(player, inventory)
	self.Client.MergeCompleted:Fire(player, targetChar.Name, targetChar.Level)

	return { text = "Successfully merged into level " .. targetChar.Level .. "!", type = "SUCCESS" }
end

function SoccerCharactersService:AddCharacter(player: Player, name: string, charData: table?)
	if player == nil or name == nil then
		return
	end

	local soccerCharacterData = self.Template.SoccerCharacters[name]
	if soccerCharacterData == nil then
		return { text = self.Template.Messages.Notifications.SoccerCharacter_Not_Exists(name), type = "ERROR" }
	end

	local data = DataService:GetData(player)
	if not data then
		return warn("[SOCCER CHARACTERS SERVICE] Player has no data: " .. player.Name)
	end

	if GetTableLength(data.Inventory.SoccerCharacters) >= data.Inventory.Storage.Stored then
		return {
			text = self.Template.Messages.Notifications.Max_SoccerCharacter_Stored(data.Inventory.Storage.Stored),
			type = "ERROR",
		}
	end

	local maxId = -1
	for id, _ in pairs(data.Inventory.SoccerCharacters) do
		local numericId = tonumber(id)
		if numericId and numericId > maxId then
			maxId = numericId
		end
	end
	local id = tostring(maxId + 1)

	data.Inventory.SoccerCharacters[id] = charData or {
		Name = name,
		Level = 1,
		Accessories = {},
	}

	local legendaryCount = 0
	for _, char in pairs(data.Inventory.SoccerCharacters) do
		local charTemplate = self.Template.SoccerCharacters[char.Name]
		if charTemplate and string.find(charTemplate.Rarity, "Legendary") then
			legendaryCount += 1
		end
	end

	if legendaryCount >= 5 then
		if self.Template.Badges and self.Template.Badges.SoccerCharacter then
			DataService:GiveBadge(player, self.Template.Badges.SoccerCharacter)
		end
	end

	self.Client.SoccerCharactersUpdated:Fire(player, data.Inventory.SoccerCharacters)

	return true
end

function SoccerCharactersService:DeleteCharacter(player: Player, id: any)
	id = tonumber(id)
	if player == nil or id == nil then
		return
	end

	local data = DataService:GetData(player)
	if not data then
		return warn("[SOCCER CHARACTERS SERVICE] Player has no data: " .. player.Name)
	end

	local characterEntry = data.Inventory.SoccerCharacters[id] or data.Inventory.SoccerCharacters[tostring(id)]
	if characterEntry == nil then
		print("[SOCCER CHARACTERS SERVICE] Character not found: " .. tostring(id))
		return
	end

	local characterName = characterEntry.Name

	if
		FindValue(data.Inventory.EquippedSoccerCharacters, id)
		or FindValue(data.Inventory.EquippedSoccerCharacters, tostring(id))
	then
		return {
			text = self.Template.Messages.Notifications.SoccerCharacter_Equipped(characterName),
			type = "ERROR",
		}
	end

	data.Inventory.SoccerCharacters[id] = nil
	data.Inventory.SoccerCharacters[tostring(id)] = nil

	self.Client.SoccerCharactersUpdated:Fire(player, data.Inventory.SoccerCharacters)

	return {
		text = self.Template.Messages.Notifications.SoccerCharacter_Deleted(characterName),
		type = "SUCCESS",
	}
end

--|| Knit Lifecycle ||--
function SoccerCharactersService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	GachaService = Knit.GetService("GachaService")
	AccessoryService = Knit.GetService("AccessoryService")

	self.Template = DataCacheService:GetFile("Template")

	print("[SOCCER CHARACTERS SERVICE] Service loaded successfully.")
end

function SoccerCharactersService:KnitStart()
	GachaService.GachaOpened:Connect(function(player, items, type, category)
		if category == "SoccerCharacters" then
			for _, itemName in ipairs(items) do
				self:AddCharacter(player, itemName)
			end
		end
	end)

	AccessoryService.SoccerCharactersChanged:Connect(function(player, soccerCharacters)
		self.Client.SoccerCharactersUpdated:Fire(player, soccerCharacters)
	end)
end

return SoccerCharactersService
