--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local DataService = nil
local DataCacheService = nil
local PlayerStatsService = nil

--local BattleService = nil

-- RebirthService
local RebirthService = Knit.CreateService({
	Name = "RebirthService",

	Template = {} :: table,
	RebirthTable = {} :: table,
})

function RebirthService.Client:Rebirth(player: Player)
	return self.Server:Rebirth(player)
end

function RebirthService.Client:RebirthWithoutMoney(player: Player)
	return self.Server:RebirthWithoutMoney(player)
end

--|| Functions ||--
-- Skipt rebirth
function RebirthService:Skip(player: Player, howMuch: number)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[REBIRTH SERVICE] Player has no data: " .. player.Name)
	end

	DataService:ChangeValue(player, "Rebirth", howMuch, true)
	return true
end

-- Rebirth
function RebirthService:Rebirth(player: Player)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[REBIRTH SERVICE] Player has no data: " .. player.Name)
	end

	local nextRebirth = self.RebirthTable[data.Rebirth + 1]

	if nextRebirth == nil then
		if data.Rebirth + 1 < 2000 then
			local sizeOfArray = #self.RebirthTable

			if data.Rebirth + 1 < #self.RebirthTable then
				nextRebirth = self.RebirthTable[data.Rebirth + 1]
			else
				nextRebirth = self.RebirthTable[sizeOfArray] * math.pow(1.3, ((data.Rebirth + 1) - sizeOfArray))
			end
		else
			return { text = self.Template.Messages.Notifications.No_More_Rebirth, type = "ERROR" }
		end
	end

	if data.Stats.Shoot < nextRebirth or data.Stats.Pass < nextRebirth or data.Stats.Dribble < nextRebirth then
		return { text = self.Template.Messages.Notifications.Not_Enough_Money("Shoot, Pass, and Dribble stats"), type = "ERROR" }
	end

	local value = DataService:ChangeValueRebirth(player)

	PlayerStatsService:SetStat(player, "Shoot", 0)
	PlayerStatsService:SetStat(player, "Pass", 0)
	PlayerStatsService:SetStat(player, "Dribble", 0)

	return {
		text = self.Template.Messages.Notifications.Rebirth_Successfull(data.Rebirth),
		type = "SUCCESS",
		value = value,
	}
end

function RebirthService:RebirthWithoutMoney(player: Player)
	local data = DataService:GetData(player)
	if data == nil then
		return warn("[REBIRTH SERVICE] Player has no data: " .. player.Name)
	end

	local nextRebirth = self.RebirthTable[data.Rebirth + 1]
	if nextRebirth == nil then
		if data.Rebirth + 1 < 2000 then
			local sizeOfArray = #self.RebirthTable
			nextRebirth = self.RebirthTable[sizeOfArray] * math.pow(1.3, (data.Rebirth + 1 - sizeOfArray))
		else
			return { text = self.Template.Messages.Notifications.No_More_Rebirth, type = "ERROR" }
		end
	end

	if data.Stats.Shoot < nextRebirth or data.Stats.Pass < nextRebirth or data.Stats.Dribble < nextRebirth then
		return { text = self.Template.Messages.Notifications.Not_Enough_Money("Shoot, Pass, and Dribble stats"), type = "ERROR" }
	end

	local value = DataService:ChangeValueRebirth(player)
	PlayerStatsService:SetStat(player, "Shoot", 0)
	PlayerStatsService:SetStat(player, "Pass", 0)
	PlayerStatsService:SetStat(player, "Dribble", 0)
	return {
		text = self.Template.Messages.Notifications.Rebirth_Successfull(data.Rebirth),
		type = "SUCCESS",
		value = value,
	}
end

--|| Knit Lifecycle ||--
function RebirthService:KnitInit()
	DataService = Knit.GetService("DataService")
	DataCacheService = Knit.GetService("DataCacheService")
	PlayerStatsService = Knit.GetService("PlayerStatsService")

	self.Template = DataCacheService:GetFile("Template")
	self.RebirthTable = DataCacheService:GetFile("RebirthTable")

	print("[REBIRTH SERVICE] Service loaded successfully.")
end

return RebirthService
