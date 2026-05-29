--[=[
	Owner: Shakthi
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService = nil
local DataCacheService = nil

local FindValue = require(ReplicatedStorage.Shared.Helpers.Table.FindValue)

local PlayerStatsService = Knit.CreateService({
	Name = "PlayerStatsService",
	Client = {
		StatUpdated = Knit.CreateSignal(),
		StatChanged = Knit.CreateSignal(),
	},
})

local DEFAULT_STATS = {
	Shoot = 0,
	Pass = 0,
	Dribble = 0,
}

function PlayerStatsService:_normalizeAreaId(areaId: string?): string?
	if not areaId then
		return nil
	end

	if self.Template.Areas[areaId] then
		return areaId
	end

	local zoneNumber = string.match(areaId, "^Zone(%d+)$")
	if zoneNumber then
		return string.format("Area%02d", tonumber(zoneNumber))
	end

	local areaNumber = string.match(areaId, "^Area(%d+)$")
	if areaNumber then
		return string.format("Area%02d", tonumber(areaNumber))
	end

	return areaId
end

function PlayerStatsService.Client:GetInitialStats(player: Player)
	print("[PlayerStatsService] GetInitialStats from", player.Name)
	return self.Server:GetStats(player)
end

function PlayerStatsService:GetStats(player: Player)
	local playerData = DataService:GetData(player)
	if playerData and playerData.Stats then
		print("[PlayerStatsService] Returning stats for", player.Name, playerData.Stats)
		return playerData.Stats
	end

	warn("[PlayerStatsService] Stats missing for", player.Name, "using defaults")
	return table.clone(DEFAULT_STATS)
end

function PlayerStatsService:GetRewardPerTick(areaId: string, statType: string): number?
	local normalizedAreaId = self:_normalizeAreaId(areaId)
	local areaData = normalizedAreaId and self.Template.Areas[normalizedAreaId]
	local trainingData = areaData and areaData.Training
	local statData = trainingData and trainingData[statType]

	if not statData then
		warn(
			string.format(
				"[PlayerStatsService] Missing reward config for raw area '%s', normalized area '%s', stat '%s'",
				tostring(areaId),
				tostring(normalizedAreaId),
				tostring(statType)
			)
		)
		return nil
	end

	return statData.RewardPerTick
end

function PlayerStatsService:GetTotalMultiplier(player: Player, statType: string)
	local playerData = DataService:GetData(player)
	if not playerData then
		return 1
	end

	local multiplier = 1

	-- Rebirth & Coach
	local rebirthMultiplier = 1 + (playerData.Rebirth * 0.2)
	local coachMultiplier = 1

	if playerData.Coaches and playerData.Coaches.Current ~= 0 then
		local coachId = playerData.Coaches.Current
		local coachData = self.Template.Coaches[coachId]
		if coachData and coachData.Multiplier then
			coachMultiplier = coachData.Multiplier
		end
	end
	
	multiplier *= rebirthMultiplier * coachMultiplier

	-- Gamepasses
	if FindValue(playerData.Gamepasses, "VIP") then
		multiplier *= 2
	end

	local gamepassName = nil
	if statType == "Shoot" then gamepassName = "x2 Shoot"
	elseif statType == "Pass" then gamepassName = "x2 Pass"
	elseif statType == "Dribble" then gamepassName = "x2 Dribble" end

	if gamepassName and FindValue(playerData.Gamepasses, gamepassName) then
		multiplier *= 2
	end

	-- Potions / Item Boosts
	local Template = DataCacheService:GetFile("Template")
	local Boosts = Template.Boosts

	if Boosts then
		for _, item in pairs(playerData.Inventory.ActiveFruits or {}) do
			local itemName = (typeof(item) == "table" and item.Name) or item
			local itemData = Template.Fruits and Template.Fruits[itemName]
			if itemData and statType == itemData.Type then
				multiplier *= 1 + (itemData.Boost or 0)
			end
		end

		for _, item in pairs(playerData.Inventory.ActiveBoosts or {}) do
			local itemName = (typeof(item) == "table" and item.Name) or item
			local itemData = Boosts[itemName]
			if itemData and statType == itemData.Type then
				multiplier *= 2
			end
		end
	end

	return multiplier
end

function PlayerStatsService:AddStat(player: Player, statType: string, areaId: string)
	local playerData = DataService:GetData(player)
	if not playerData or not playerData.Stats or playerData.Stats[statType] == nil then
		warn("[PlayerStatsService] Invalid player data or stat for", player.Name, statType)
		return
	end

	local rewardPerTick = self:GetRewardPerTick(areaId, statType)
	if not rewardPerTick then
		warn(
			string.format(
				"[PlayerStatsService] Missing training reward for %s / %s",
				tostring(areaId),
				tostring(statType)
			)
		)
		return
	end

	local multiplier = self:GetTotalMultiplier(player, statType)
	local totalReward = math.round(rewardPerTick * multiplier)

	playerData.Stats[statType] += totalReward

	self.Client.StatChanged:Fire(player, statType, totalReward)
	self.Client.StatUpdated:Fire(player, statType, playerData.Stats[statType])
end

function PlayerStatsService:SetStat(player: Player, statType: string, value: number)
	local playerData = DataService:GetData(player)
	if not playerData or not playerData.Stats or playerData.Stats[statType] == nil then
		warn("[PlayerStatsService] Invalid player data or stat for", player.Name, statType)
		return
	end

	playerData.Stats[statType] = value

	self.Client.StatUpdated:Fire(player, statType, value)
end

--|| Knit Lifecycle ||--

function PlayerStatsService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")

	self.Template = DataCacheService:GetFile("Template")
end

function PlayerStatsService:KnitStart() end

return PlayerStatsService
