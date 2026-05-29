-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Knit Services
local TeamService

-- TeamController
local TeamController = Knit.CreateController({
	Name = "TeamController",
})

--|| Functions ||--
function TeamController:SetSlot(slot: number, characterId: number)
	return TeamService:SetSlot(slot, characterId)
end

function TeamController:EquipBest()
	return TeamService:EquipBest()
end

--|| Knit Lifecycle ||--
function TeamController:KnitInit()
	TeamService = Knit.GetService("TeamService")
end

function TeamController:KnitStart() end

return TeamController
