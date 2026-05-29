local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

--local FreePetService = Knit.GetService("FreePetService")

return table.freeze({
    [2669646641] = {
        ["Name"] = "x10 Free Pet",
        ["BeforeCheck"] = function(self, userId)
        end,
        ["Purchased"] = function(self, userId)
            --FreePetService:ChangeClaimable(Players:GetPlayerByUserId(userId), 10)
        end,
        ["RestrictedRegionCanBuy"] = true,
    }
})