--!strict
-- GetMatchEnemyModel.luau
-- Resolves match enemy models from ReplicatedStorage.Assets.Enemies.
-- New structure: Stage1-4/Team01-15/Enemy01-03/Keeper.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local EnemiesAssets = Assets:WaitForChild("Enemies")

local function PrepareModel(instance: Instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
end

local function ResolveStageFolder(stageFolderName: string?): Instance?
	if not stageFolderName or stageFolderName == "" then
		return nil
	end

	return EnemiesAssets:FindFirstChild(stageFolderName)
end

local function ResolveChildFolder(parent: Instance?, childName: string?): Instance?
	if not parent or not childName or childName == "" then
		return nil
	end

	return parent:FindFirstChild(childName)
end

local function FindModelInFolder(folder: Instance?, modelName: string): Instance?
	if not folder or modelName == "" then
		return nil
	end

	return folder:FindFirstChild(modelName)
end

return function(data)
	if typeof(data) ~= "table" then
		warn("GetMatchEnemyModel: invalid data payload")
		return nil
	end

	local stageFolderName = tostring(data.EnemyStageName or data.StageFolderName or "")
	local teamFolderName = tostring(data.TeamAssetFolderName or data.TeamFolderName or "")
	local modelName = tostring(data.ModelName or "")
	local fallbackModelName = tostring(data.FallbackModelName or "")

	if modelName == "" then
		warn("GetMatchEnemyModel: missing ModelName")
		return nil
	end

	local stageFolder = ResolveStageFolder(stageFolderName)
	local teamFolder = ResolveChildFolder(stageFolder, teamFolderName)
	local sourceModel = FindModelInFolder(teamFolder, modelName)

	if not sourceModel and fallbackModelName ~= "" then
		sourceModel = FindModelInFolder(teamFolder, fallbackModelName)
	end

	if not sourceModel then
		sourceModel = FindModelInFolder(stageFolder, modelName)
	end

	if not sourceModel and fallbackModelName ~= "" then
		sourceModel = FindModelInFolder(stageFolder, fallbackModelName)
	end

	if sourceModel == nil then
		warn("GetMatchEnemyModel: can't find enemy model:", stageFolderName, teamFolderName, modelName)
		return nil
	end

	local clone = sourceModel:Clone()
	PrepareModel(clone)

	return clone
end