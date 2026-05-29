local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)

local DataService = Knit.GetService("DataService")
local DataCacheService = Knit.GetService("DataCacheService")
local AccessoryService = Knit.GetService("AccessoryService")

return table.freeze({
	[3582699147] = {
		["Name"] = "Accessory - Clutch Mascot",
		["BeforeCheck"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local data = DataService:GetData(Players:GetPlayerByUserId(userId))
			if GetTableLength(data.Inventory.Accessories) + 1 >= data.Inventory.Storage.Stored then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			end

			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			local player = Players:GetPlayerByUserId(userId)
			AccessoryService:AddAccessory(player, "Clutch Mascot")
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
