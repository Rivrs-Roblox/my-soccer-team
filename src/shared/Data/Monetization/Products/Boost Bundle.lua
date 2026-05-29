local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BoostService = Knit.GetService("BoostService")

return table.freeze({
	[3582677029] = {
		["Name"] = "Boost Bundle",
		["BeforeCheck"] = function(self, userId)
			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "3", 10)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "4", 10)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "5", 10)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "6", 10)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
