local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local BoostService = Knit.GetService("BoostService")

return table.freeze({
	[3605436240] = {
		["Name"] = "x2 Endurance Boost",
		["BeforeCheck"] = function(self, userId)
			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			BoostService:AddBoost(Players:GetPlayerByUserId(userId), "8", 1)
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
