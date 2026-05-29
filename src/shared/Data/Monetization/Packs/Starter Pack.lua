local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Helpers = ReplicatedStorage.Shared.Helpers
local GetTableLength = require(Helpers.GetTableLength)

local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService = Knit.GetService("DataService")
local DataCacheService = Knit.GetService("DataCacheService")
local GachaService = Knit.GetService("GachaService")

return table.freeze({
	[3586805657] = {
		["Name"] = "Starter Pack",
		["BeforeCheck"] = function(self, userId)
			local template = DataCacheService:GetFile("Template")
			local data = DataService:GetData(Players:GetPlayerByUserId(userId))
			if GetTableLength(data.Inventory.SoccerCharacters) + 3 >= data.Inventory.Storage.Stored then
				return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
			end

			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			local player = Players:GetPlayerByUserId(userId)

			GachaService:OpenGacha(player, "SoccerCharacters", "3", 1)
			GachaService:OpenGacha(player, "SoccerCharacters", "5", 1)
			GachaService:OpenGacha(player, "SoccerCharacters", "8", 1)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
	-- [3586805845] = {
	-- 	["Name"] = "Pro Pack",
	-- 	["BeforeCheck"] = function(self, userId)
	-- 		local template = DataCacheService:GetFile("Template")
	-- 		local data = DataService:GetData(Players:GetPlayerByUserId(userId))
	-- 		if GetTableLength(data.Inventory.SoccerCharacters) + 1 >= data.Inventory.Storage.Stored then
	-- 			return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
	-- 		end

	-- 		return { status = true, message = "" }
	-- 	end,
	-- 	["Purchased"] = function(self, userId)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Money2", 250_000, true)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Wins", 8000, true)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Rebirth", 10, true)
	-- 		SoccerCharactersService:AddCharacter(Players:GetPlayerByUserId(userId), "Lautario Martinezzo")
	-- 	end,
	-- 	["RestrictedRegionCanBuy"] = true,
	-- },
	-- [3586806064] = {
	-- 	["Name"] = "Master Pack",
	-- 	["BeforeCheck"] = function(self, userId)
	-- 		local template = DataCacheService:GetFile("Template")
	-- 		local data = DataService:GetData(Players:GetPlayerByUserId(userId))
	-- 		if GetTableLength(data.Inventory.SoccerCharacters) + 1 >= data.Inventory.Storage.Stored then
	-- 			return { status = false, message = template.Messages.Notifications.Not_Enough_Storage_Space }
	-- 		end

	-- 		return { status = true, message = "" }
	-- 	end,
	-- 	["Purchased"] = function(self, userId)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Money2", 1_000_000, true)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Wins", 20_000, true)
	-- 		DataService:ChangeValue(Players:GetPlayerByUserId(userId), "Rebirth", 20, true)
	-- 		SoccerCharactersService:AddCharacter(Players:GetPlayerByUserId(userId), "Ousmana Dembala")
	-- 	end,
	-- 	["RestrictedRegionCanBuy"] = true,
	-- },
})
