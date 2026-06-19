--[=[
	TrainingBillboardGuiController
	- update billboard training world berdasarkan area aktif player
	- hanya UI local, tidak mengubah logic training
	- source value dari Areas.lua
]=]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local FormatNumber = require(ReplicatedStorage.Shared.Helpers.Numbers.FormatNumber)

local DataService
local TeleportService

local DataCacheController

local TrainingBillboardGuiController = Knit.CreateController({
	Name = "TrainingBillboardGuiController",
})

local function FindFirstTextLabel(root: Instance): TextLabel?
	if root:IsA("TextLabel") then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			return descendant
		end
	end

	return nil
end

local function ResolveBillboardText(zoneFolderName: string): TextLabel?
	local map = Workspace:FindFirstChild("Map")
	if not map then
		warn("[TrainingBillboardGuiController] Map not found")
		return nil
	end

	local trainingAreas = map:FindFirstChild("TrainingAreas")
	if not trainingAreas then
		warn("[TrainingBillboardGuiController] TrainingAreas not found")
		return nil
	end

	local zoneFolder = trainingAreas:FindFirstChild(zoneFolderName)
	if not zoneFolder then
		warn("[TrainingBillboardGuiController] Zone folder not found:", zoneFolderName)
		return nil
	end

	local valuePart = zoneFolder:FindFirstChild("Value")
	if not valuePart then
		warn("[TrainingBillboardGuiController] Value part not found in:", zoneFolderName)
		return nil
	end

	local billboard = valuePart:FindFirstChildWhichIsA("BillboardGui")
	if not billboard then
		warn("[TrainingBillboardGuiController] BillboardGui not found in:", valuePart:GetFullName())
		return nil
	end

	local textLabel = FindFirstTextLabel(billboard)
	if not textLabel then
		warn("[TrainingBillboardGuiController] TextLabel not found in:", billboard:GetFullName())
		return nil
	end

	return textLabel
end

function TrainingBillboardGuiController:GetRewardPerTick(areaId: string, statType: string): number
	if not self.Template or not self.Template.Areas then
		warn("[TrainingBillboardGuiController] Template or Areas config not found")
		return 0
	end

	local areaData = self.Template.Areas[areaId]
	if not areaData then
		warn("[TrainingBillboardGuiController] Missing area config:", areaId)
		return 0
	end

	local trainingData = areaData.Training
	if not trainingData then
		warn("[TrainingBillboardGuiController] Missing training config for:", areaId)
		return 0
	end

	local statData = trainingData[statType]
	if not statData then
		warn("[TrainingBillboardGuiController] Missing stat config:", areaId, statType)
		return 0
	end

	return statData.RewardPerTick or 0
end

local function FormatRewardText(value: number): string
	return string.format("+%s / sec", FormatNumber(value))
end

function TrainingBillboardGuiController:ApplyAreaToBillboards(areaId: string)
	local shootLabel = ResolveBillboardText("ShootZone")
	local passLabel = ResolveBillboardText("PassZone")
	local dribbleLabel = ResolveBillboardText("DribbleZone")

	local shootValue = self:GetRewardPerTick(areaId, "Shoot")
	local passValue = self:GetRewardPerTick(areaId, "Pass")
	local dribbleValue = self:GetRewardPerTick(areaId, "Dribble")

	if shootLabel then
		shootLabel.Text = FormatRewardText(shootValue)
	end

	if passLabel then
		passLabel.Text = FormatRewardText(passValue)
	end

	if dribbleLabel then
		dribbleLabel.Text = FormatRewardText(dribbleValue)
	end
end

function TrainingBillboardGuiController:ResolveCurrentAreaId(dataService): string
	local success, data = dataService:GetData():await()

	if not success or not data then
		warn("[TrainingBillboardGuiController] Failed to get player data, fallback Area01")
		return "Area01"
	end

	if data.Areas and data.Areas.Current then
		return data.Areas.Current
	end

	if data.Area then
		return data.Area
	end

	return "Area01"
end

function TrainingBillboardGuiController:KnitInit()
	DataService = Knit.GetService("DataService")
	TeleportService = Knit.GetService("TeleportService")

	DataCacheController = Knit.GetController("DataCacheController")

	self.Template = DataCacheController:GetFile("Template")
end

function TrainingBillboardGuiController:KnitStart()
	-- -- initial sync dari data player
	-- local currentAreaId = self:ResolveCurrentAreaId(DataService)
	-- self:ApplyAreaToBillboards(currentAreaId)

	-- -- update saat area pindah dari teleport service
	-- TeleportService.AreaUpdated:Connect(function(newAreaId: string)
	-- 	self:ApplyAreaToBillboards(newAreaId)
	-- end)
end

return TrainingBillboardGuiController
