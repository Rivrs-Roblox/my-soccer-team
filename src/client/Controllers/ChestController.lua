--[=[
	Owner: JustStop__
	Version: v0.0.1
	Contact owner if any question, concern or feedback
]=]

-- Game Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)
local Zone = require(ReplicatedStorage.ZonePlus)

-- Controllers
local DataCacheController = nil
local NotificationController = nil

-- Services
local ChestService = nil

local player = Players.LocalPlayer

-- ChestController
local ChestController = Knit.CreateController({
	Name = "ChestController",

	Template = {},
	FirstRun = true,
	Debounce = false,
})

--|| Local Functions ||--
local function setupGroupChest(instance: BasePart, self)
	local zone = Zone.new(instance)
	zone:setDetection("Centre")

	zone.playerEntered:Connect(function(p)
		if p == player then
			if self.Debounce == false then
				self.Debounce = true

				self:ClaimGroupChest()

				task.delay(2, function()
					self.Debounce = false
				end)
			end
		end
	end)
end

--|| Functions ||--
function ChestController:ClaimGroupChest()
	local success, result = ChestService:Claim("Group Chest"):await()
	if success == false then
		return warn("[CHEST CONTROLLER] An internal error occured while claiming chest.")
	end

	NotificationController:Notify({
		tag = "Chest",
		text = result.text,
		type = result.type,
	})
	if result.type == "SUCCESS" then
		Sound:PlaySound("UI_Chest_Open")
	end
end

--|| Knit Lifecycle ||--
function ChestController:KnitInit()
	DataCacheController = Knit.GetController("DataCacheController")
	NotificationController = Knit.GetController("NotificationController")

	ChestService = Knit.GetService("ChestService")

	self.Template = DataCacheController:GetFile("Template")

	print("[CHEST CONTROLLER] Controller loaded successfully.")
end

function ChestController:KnitStart()
	-- Setup group chests
	local existingGroupChests = CollectionService:GetTagged("GroupChest")
	for _, instance in pairs(existingGroupChests) do
		setupGroupChest(instance, self)
	end

	CollectionService:GetInstanceAddedSignal("GroupChest"):Connect(function(instance)
		setupGroupChest(instance, self)
	end)
end

return ChestController
