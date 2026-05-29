-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Knit packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Knit Services
local GachaPacksService
local GachaService

-- Knit Controllers
local DataCacheController

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Player
local player = Players.LocalPlayer

-- Variables
local GachaPacksTemplates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GachaPacks"):GetChildren()
local conveyors
local pool = {}
local poolFolder
local config

-- GachaPacksController
local GachaPacksController = Knit.CreateController({
	Name = "GachaPacksController",
})

--|| Local Functions ||--

-- Helper functions for object pooling
local function returnToPool(pack)
	local packId = pack:GetAttribute("PackId")
	if not packId then
		pack:Destroy()
		return
	end

	local prompt = pack:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Enabled = false
	end

	if not pool[packId] then
		pool[packId] = {}
	end

	table.insert(pool[packId], pack)
	pack.Parent = poolFolder
end

local function getFromPool(packId, template)
	local subPool = pool[packId]
	local pack

	if subPool and #subPool > 0 then
		pack = table.remove(subPool)
		local prompt = pack:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.Enabled = true
		end
	else
		pack = template:Clone()
		pack:SetAttribute("PackId", packId)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = `Buy {GachaPacksController.Template.Gacha.SoccerCharacters[packId].Name}`
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = if pack:IsA("Model")
			then (pack.PrimaryPart or pack:FindFirstChildWhichIsA("BasePart"))
			else pack

		prompt.Triggered:Connect(function()
			local NotificationController = Knit.GetController("NotificationController")
			GachaService:BuyGacha("SoccerCharacters", packId, "Wins", 1):andThen(function(result)
				if result and result.type == "SUCCESS" then
					returnToPool(pack)
				end

				if result and result.text ~= "" then
					NotificationController:Notify({
						text = result.text,
						type = result.type,
					})
				end
			end)
		end)
	end

	-- Update Prompt Text
	local prompt = pack:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		local gachaData = DataCacheController:GetFile("Template").Gacha.SoccerCharacters[packId]
		if gachaData then
			local text = `{FormatNumber(gachaData.Price)} Wins`
			for key, value in pairs(gachaData.Prerequisite or {}) do
				if value > 0 then
					text ..= ` | {key}: {FormatNumber(value)}+`
				end
			end
			prompt.ObjectText = text
		else
			prompt.ObjectText = "Pack"
		end
	end

	return pack
end

--|| Functions ||--

--|| Knit Lifecycle ||--
function GachaPacksController:KnitInit()
	GachaPacksService = Knit.GetService("GachaPacksService")
	GachaService = Knit.GetService("GachaService")

	DataCacheController = Knit.GetController("DataCacheController")

	self.Template = DataCacheController:GetFile("Template")

	poolFolder = Instance.new("Folder")
	poolFolder.Name = "GachaPacksPool"
	poolFolder.Parent = ReplicatedStorage
end

function GachaPacksController:KnitStart()
	-- GachaPacksService:GetConfig(player):andThen(function(serverConfig)
	-- 	config = serverConfig
	-- end)

	-- conveyors = CollectionService:GetTagged("Conveyor")

	-- CollectionService:GetInstanceAddedSignal("Conveyor"):Connect(function(instance: BasePart)
	-- 	table.insert(conveyors, instance)
	-- end)

	-- CollectionService:GetInstanceRemovedSignal("Conveyor"):Connect(function(instance: BasePart)
	-- 	local index = table.find(conveyors, instance)
	-- 	if index then
	-- 		table.remove(conveyors, index)
	-- 	end
	-- end)

	-- GachaPacksService.PackSpawned:Connect(function(packId)
	-- 	packId = tostring(packId)
	-- 	local template
	-- 	for _, t in ipairs(GachaPacksTemplates) do
	-- 		if t.Name == packId then
	-- 			template = t
	-- 			break
	-- 		end
	-- 	end

	-- 	if not template then
	-- 		return warn("[GACHA PACKS CONTROLLER] No template found for packId: " .. packId)
	-- 	end

	-- 	for _, conveyor in ipairs(conveyors) do
	-- 		local startPivot = conveyor:FindFirstChild("Start")
	-- 		local endPivot = conveyor:FindFirstChild("End")

	-- 		if startPivot and endPivot then
	-- 			local pack = getFromPool(packId, template)
	-- 			pack.Parent = workspace

	-- 			local packSize = if pack:IsA("Model") then pack:GetExtentsSize() else pack.Size
	-- 			local heightOffset = CFrame.new(0, packSize.Y / 2, 0)

	-- 			local startCF = startPivot.CFrame * heightOffset
	-- 			local endCF = endPivot.CFrame * heightOffset
	-- 			local distance = (endCF.Position - startCF.Position).Magnitude
	-- 			local duration = distance / config.CONVEYOR_SPEED

	-- 			local startTime = os.clock()

	-- 			local connection
	-- 			connection = RunService.Heartbeat:Connect(function()
	-- 				if pack.Parent ~= workspace then
	-- 					connection:Disconnect()
	-- 					return
	-- 				end

	-- 				local elapsed = os.clock() - startTime
	-- 				local alpha = math.clamp(elapsed / duration, 0, 1)

	-- 				local bobOffset = CFrame.new(0, math.sin(elapsed * 2) * 0.5, 0)
	-- 				local currentCF = startCF:Lerp(endCF, alpha) * bobOffset
	-- 				local rotationCF = CFrame.Angles(0, elapsed * config.ROTATION_SPEED, 0)

	-- 				pack:PivotTo(currentCF * rotationCF)

	-- 				if alpha >= 1 then
	-- 					connection:Disconnect()
	-- 					returnToPool(pack)
	-- 				end
	-- 			end)
	-- 		end
	-- 	end
	-- end)
end

return GachaPacksController
