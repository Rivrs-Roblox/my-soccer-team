local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BoostService = Knit.GetService("BoostService")

return table.freeze({
	[3582676401] = {
		["Name"] = "x2 Shooting Boost",
		["BeforeCheck"] = function(self, userId)
			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "4", 1)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
