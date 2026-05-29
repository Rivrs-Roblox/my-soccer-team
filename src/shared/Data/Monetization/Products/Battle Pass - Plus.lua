local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService = Knit.GetService("DataService")
local SeasonService = Knit.GetService("SeasonService")
local DataCacheService = Knit.GetService("DataCacheService")

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)

return table.freeze({
	[3566407941] = {
		["Name"] = "Battle Pass - Plus",
		["BeforeCheck"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local data = DataService:GetData(Players:GetPlayerByUserId(userId))

			if data.Season.Plus then
				return { status = false, message = "You already have Battle Pass Plus." }
				-- return { status = false, message = "You already have Brainrot Pass Plus." }
			elseif
				not data.Season.Premium and GetTableLength(data.Inventory.SoccerCharacters) + 38 > data.Inventory.Storage.Stored
			then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			elseif GetTableLength(data.Inventory.SoccerCharacters) + 30 > data.Inventory.Storage.Stored then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			end

			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local player = Players:GetPlayerByUserId(userId)
			local data = DataService:GetData(player)

			data.Season.Level = 30
			SeasonService.Client.LevelUpdated:Fire(player, data.Season.Level)

			local targetExp = 0

			for i = 1, data.Season.Level do
				targetExp += template.SeasonPass[i]
			end

			data.Season.Exp = targetExp
			SeasonService.Client.ExpUpdated:Fire(player, data.Season.Exp)

			data.SeasonPassCompleted += 1

			if not data.Season.Premium then
				data.Season.Premium = true
				SeasonService.Client.PremiumUpdated:Fire(player, data.Season.Premium)
			end

			data.Season.Plus = true

			if player then
			end

			DataService:GiveBadge(player, 779221074987376)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
