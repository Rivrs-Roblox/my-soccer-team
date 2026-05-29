-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

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
		self.CharacterRemovedFromTeam:Fire(player, previousId)
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

	-- Unequip accessories from previously equipped characters
	for _, id in pairs(equipped) do
		if id then
			self.CharacterRemovedFromTeam:Fire(player, id)
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

			local template = self.Template.SoccerCharacters[charData.Name]
			if template then
				local totalMultiplier = 0
				for _, statName in ipairs(statNames) do
					totalMultiplier += (template.Multipliers[statName] or 0)
				end
				local totalValue = totalMultiplier * charData.Level

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

	-- Slot 1: Highest Shoot
	equipped[1] = getBestForStat("Shoot")

	-- Slot 2: Highest Dribble + Pass
	equipped[2] = getBestForStat("Dribble", "Pass")

	-- Slot 3: Highest Dribble + Pass
	equipped[3] = getBestForStat("Dribble", "Pass")

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
