--!strict
-- GetMatchEnemyModel.luau
-- Resolves match enemy models from ReplicatedStorage.Assets.MatchEnemies.
-- Supports both legacy AreaXX/Enemy01 and new AreaXX/TeamYY/Enemy01 structures.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local SoccerCharactersAssets = Assets:WaitForChild("SoccerCharacters")
local MatchEnemiesAssets = Assets:WaitForChild("MatchEnemies")

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

local function ResolveAreaFolder(areaFolderName: string?): Instance?
	if not areaFolderName or areaFolderName == "" then
		return nil
	end

	return MatchEnemiesAssets:FindFirstChild(areaFolderName)
end

local function ResolveTeamFolder(areaFolder: Instance?, teamFolderName: string?): Instance?
	if not areaFolder or not teamFolderName or teamFolderName == "" then
		return nil
	end

	return areaFolder:FindFirstChild(teamFolderName)
end

local function FindModelInFolder(folder: Instance?, modelName: string): Instance?
	if not folder or modelName == "" then
		return nil
	end

	return folder:FindFirstChild(modelName)
end

local function FindFallbackModel(modelName: string): Instance?
	if modelName == "" then
		return nil
	end

	local sourceModel = SoccerCharactersAssets:FindFirstChild(modelName, true)

	return sourceModel
end

return function(data)
	if typeof(data) ~= "table" then
		warn("GetMatchEnemyModel: invalid data payload")
		return nil
	end

	local areaFolderName = tostring(data.AssetFolderName or "")
	local teamFolderName = tostring(data.TeamAssetFolderName or data.TeamFolderName or "")
	local modelName = tostring(data.ModelName or "")
	local fallbackModelName = tostring(data.FallbackModelName or "")

	if modelName == "" then
		warn("GetMatchEnemyModel: missing ModelName")
		return nil
	end

	local areaFolder = ResolveAreaFolder(areaFolderName)
	if not areaFolder then
		warn("GetMatchEnemyModel: missing area folder:", areaFolderName)
	end

	local teamFolder = ResolveTeamFolder(areaFolder, teamFolderName)
	local sourceModel = FindModelInFolder(teamFolder, modelName)

	if not sourceModel and fallbackModelName ~= "" then
		sourceModel = FindModelInFolder(teamFolder, fallbackModelName)
	end

	-- Legacy fallback: AreaXX/Enemy01
	if not sourceModel then
		sourceModel = FindModelInFolder(areaFolder, modelName)
	end

	if not sourceModel and fallbackModelName ~= "" then
		sourceModel = FindModelInFolder(areaFolder, fallbackModelName)
	end

	if not sourceModel then
		sourceModel = FindFallbackModel(modelName)
	end

	if not sourceModel and fallbackModelName ~= "" then
		sourceModel = FindFallbackModel(fallbackModelName)
	end

	if sourceModel == nil then
		warn("GetMatchEnemyModel: can't find enemy model:", areaFolderName, teamFolderName, modelName)
		return nil
	end

	local clone = sourceModel:Clone()
	PrepareModel(clone)

	return clone
end
