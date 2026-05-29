local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local GachaService = Knit.GetService("GachaService")

return table.freeze({
	[3596050790] = {
		["Name"] = "Refill Pack",
		["BeforeCheck"] = function(self, userId)
			return { status = true, message = "" }
		end,
		["Purchased"] = function(self, userId)
			GachaService:Restock()
		end,
		["RestrictedRegionCanBuy"] = true,
	},
})
