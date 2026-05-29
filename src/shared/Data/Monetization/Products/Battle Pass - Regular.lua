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
	[3566408014] = {
		["Name"] = "Battle Pass - Regular",
		["BeforeCheck"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local data = DataService:GetData(Players:GetPlayerByUserId(userId))

			if data.Season.Premium then
				return { status = false, message = "You already have Battle Pass Plus." }
				-- return { status = false, message = "You already have Brainrot Pass." }
			elseif GetTableLength(data.Inventory.SoccerCharacters) + 8 > data.Inventory.Storage.Stored then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			end

			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			local player = Players:GetPlayerByUserId(userId)
			local data = DataService:GetData(player)

			data.Season.Premium = true
			SeasonService.Client.PremiumUpdated:Fire(player, data.Season.Premium)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
