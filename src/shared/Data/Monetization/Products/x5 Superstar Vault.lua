local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)

local DataService = Knit.GetService("DataService")
local DataCacheService = Knit.GetService("DataCacheService")
local GachaService = Knit.GetService("GachaService")

return table.freeze({
	[3579687415] = { -- REPLACE WITH ACTUAL PRODUCT ID
		["Name"] = "x5 Superstar Vault",
		["BeforeCheck"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local data = DataService:GetData(Players:GetPlayerByUserId(userId))
			if GetTableLength(data.Inventory.SoccerCharacters) + 5 >= data.Inventory.Storage.Stored then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			end

			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			local player = Players:GetPlayerByUserId(userId)
			GachaService:OpenGacha(player, "SoccerCharacters", "11", 5)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
