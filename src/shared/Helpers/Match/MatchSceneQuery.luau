local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchConstants = require(ReplicatedStorage.Shared.Data.Match.MatchConstants)

local MatchSceneQuery = {}

local activeZoneVariationId = nil
local ZONE_VARIATION_FOLDER_NAMES = { "ZoneVariation", "ZoneVariations" }

local function FindFirstChildByNames(parent: Instance?, names: { string }): Instance?
	if not parent then
		return nil
	end

	for _, name in ipairs(names) do
		local found = parent:FindFirstChild(name)
		if found then
			return found
		end
	end

	return nil
end

local function NormalizeVariationId(variationId): string?
	local normalized = tostring(variationId or "")
	if normalized == "" then
		return nil
	end

	return normalized
end

function MatchSceneQuery.GetMapRoot(): Instance?
	return Workspace:FindFirstChild(MatchConstants.MAP_ROOT_NAME)
end

function MatchSceneQuery.GetBattleZoneRoot(): Instance?
	local mapRoot = MatchSceneQuery.GetMapRoot()
	return mapRoot and mapRoot:FindFirstChild(MatchConstants.BATTLE_ZONE_ROOT_NAME)
end

function MatchSceneQuery.GetRuntimeRoot(): Instance?
	local battleZoneRoot = MatchSceneQuery.GetBattleZoneRoot()
	return battleZoneRoot and battleZoneRoot:FindFirstChild(MatchConstants.RUNTIME_FOLDER_NAME)
end

function MatchSceneQuery.GetZoneVariationRoot(): Instance?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	return FindFirstChildByNames(runtimeRoot, ZONE_VARIATION_FOLDER_NAMES)
end

function MatchSceneQuery.GetAvailableZoneVariationIds(): { string }
	local variationRoot = MatchSceneQuery.GetZoneVariationRoot()
	local ids = {}
	if not variationRoot then
		return ids
	end

	for _, child in ipairs(variationRoot:GetChildren()) do
		if child:IsA("Folder") then
			table.insert(ids, child.Name)
		end
	end
	table.sort(ids)

	return ids
end

function MatchSceneQuery.GetZoneVariationFolder(variationId): Instance?
	local variationRoot = MatchSceneQuery.GetZoneVariationRoot()
	local normalized = NormalizeVariationId(variationId)
	if not variationRoot or not normalized then
		return nil
	end

	return variationRoot:FindFirstChild(normalized)
end

function MatchSceneQuery.SetActiveZoneVariationId(variationId): string?
	local normalized = NormalizeVariationId(variationId)
	if normalized and MatchSceneQuery.GetZoneVariationFolder(normalized) then
		activeZoneVariationId = normalized
	else
		activeZoneVariationId = nil
	end

	return activeZoneVariationId
end

function MatchSceneQuery.GetActiveZoneVariationId(): string?
	return activeZoneVariationId
end

function MatchSceneQuery.GetActiveZoneVariationFolder(): Instance?
	return MatchSceneQuery.GetZoneVariationFolder(activeZoneVariationId)
end

function MatchSceneQuery.GetZoneVariationChild(childName: string, variationId): Instance?
	local variationFolder = MatchSceneQuery.GetZoneVariationFolder(variationId or activeZoneVariationId)
	return variationFolder and variationFolder:FindFirstChild(childName) or nil
end

function MatchSceneQuery.GetPlayerSpawn(variationId): BasePart?
	local variationSpawn = MatchSceneQuery.GetZoneVariationChild(MatchConstants.PLAYER_SPAWN_NAME, variationId)
	if variationSpawn and variationSpawn:IsA("BasePart") then
		return variationSpawn
	end

	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	local playerSpawn = runtimeRoot and runtimeRoot:FindFirstChild(MatchConstants.PLAYER_SPAWN_NAME)

	if playerSpawn and playerSpawn:IsA("BasePart") then
		return playerSpawn
	end

	if variationId == nil and activeZoneVariationId == nil then
		local availableVariationIds = MatchSceneQuery.GetAvailableZoneVariationIds()
		for _, fallbackVariationId in ipairs(availableVariationIds) do
			local fallbackSpawn = MatchSceneQuery.GetZoneVariationChild(MatchConstants.PLAYER_SPAWN_NAME, fallbackVariationId)
			if fallbackSpawn and fallbackSpawn:IsA("BasePart") then
				return fallbackSpawn
			end
		end
	end

	return nil
end

function MatchSceneQuery.GetEnemiesRoot(): Instance?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()

	return FindFirstChildByNames(runtimeRoot, {
		"Enemies",
		"SpawnedEnemies",
		MatchConstants.ENEMIES_FOLDER_NAME,
	})
end

function MatchSceneQuery.GetEnemyByStep(stepIndex: number): Instance?
	local enemiesRoot = MatchSceneQuery.GetEnemiesRoot()
	if not enemiesRoot then
		return nil
	end

	local slotNameMap = {
		[1] = "Enemy01",
		[2] = "Enemy02",
		[3] = "Enemy03",
		[4] = "Enemy04",
		[5] = "GoalKeeper",
	}

	local enemyName = slotNameMap[stepIndex]
	if not enemyName then
		return nil
	end

	local enemyInstance = enemiesRoot:FindFirstChild(enemyName)
	if enemyInstance then
		return enemyInstance
	end

	if stepIndex == 5 then
		return enemiesRoot:FindFirstChild("Keeper")
	end

	return nil
end

function MatchSceneQuery.GetAllBattleZonePrompts(): { ProximityPrompt }
	local battleZoneRoot = MatchSceneQuery.GetBattleZoneRoot()
	local prompts = {}

	if not battleZoneRoot then
		return prompts
	end

	for _, descendant in ipairs(battleZoneRoot:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			table.insert(prompts, descendant)
		end
	end

	return prompts
end

function MatchSceneQuery.GetCompanionPivotsRoot(variationId): Instance?
	local variationPivotsRoot = MatchSceneQuery.GetZoneVariationChild(MatchConstants.COMPANION_PIVOTS_FOLDER_NAME, variationId)
	if variationPivotsRoot then
		return variationPivotsRoot
	end

	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	local pivotsRoot = runtimeRoot and runtimeRoot:FindFirstChild(MatchConstants.COMPANION_PIVOTS_FOLDER_NAME)
	if pivotsRoot then
		return pivotsRoot
	end

	if variationId == nil and activeZoneVariationId == nil then
		local availableVariationIds = MatchSceneQuery.GetAvailableZoneVariationIds()
		for _, fallbackVariationId in ipairs(availableVariationIds) do
			local fallbackPivotsRoot = MatchSceneQuery.GetZoneVariationChild(
				MatchConstants.COMPANION_PIVOTS_FOLDER_NAME,
				fallbackVariationId
			)
			if fallbackPivotsRoot then
				return fallbackPivotsRoot
			end
		end
	end

	return nil
end

function MatchSceneQuery.GetCompanionPivot(slotNumber: number, variationId): BasePart?
	local pivotsRoot = MatchSceneQuery.GetCompanionPivotsRoot(variationId)
	if not pivotsRoot then
		return nil
	end

	local pivot = pivotsRoot:FindFirstChild("Slot" .. tostring(slotNumber))
	if pivot and pivot:IsA("BasePart") then
		return pivot
	end

	return nil
end

function MatchSceneQuery.GetPlayerPivotsRoot(): Instance?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()

	return FindFirstChildByNames(runtimeRoot, {
		"PlayerPivots",
		"PlayersPivots",
	})
end

function MatchSceneQuery.GetEnemyPivotsRoot(): Instance?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()

	return FindFirstChildByNames(runtimeRoot, {
		"EnemiesPivots",
		"EnemyPivots",
	})
end

function MatchSceneQuery.GetEnemyPivotByName(pivotName: string): BasePart?
	local pivotsRoot = MatchSceneQuery.GetEnemyPivotsRoot()
	if not pivotsRoot then
		return nil
	end

	local pivot = pivotsRoot:FindFirstChild(pivotName)
	if pivot and pivot:IsA("BasePart") then
		return pivot
	end

	return nil
end

function MatchSceneQuery.GetEnemyPivot(slotNumber: number): BasePart?
	local nameMap = {
		[1] = "Enemy01",
		[2] = "Enemy02",
		[3] = "Enemy03",
		[4] = "Enemy04",
		[5] = "GoalKeeper",
	}

	local pivotName = nameMap[slotNumber]
	if not pivotName then
		return nil
	end

	local pivot = MatchSceneQuery.GetEnemyPivotByName(pivotName)
	if pivot then
		return pivot
	end

	if slotNumber == 5 then
		return MatchSceneQuery.GetEnemyPivotByName("Keeper")
	end

	return nil
end

function MatchSceneQuery.GetSpawnedEnemiesFolder(createIfMissing: boolean?): Folder?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	if not runtimeRoot then
		return nil
	end

	local folder = runtimeRoot:FindFirstChild("SpawnedEnemies")
	if folder and folder:IsA("Folder") then
		return folder
	end

	if not createIfMissing then
		return nil
	end

	folder = Instance.new("Folder")
	folder.Name = "SpawnedEnemies"
	folder.Parent = runtimeRoot

	return folder
end

function MatchSceneQuery.GetPathValidation(): { [string]: boolean }
	local mapRoot = Workspace:FindFirstChild(MatchConstants.MAP_ROOT_NAME)
	local battleZone = mapRoot and mapRoot:FindFirstChild(MatchConstants.BATTLE_ZONE_ROOT_NAME)
	local runtime = battleZone and battleZone:FindFirstChild(MatchConstants.RUNTIME_FOLDER_NAME)
	local playerSpawn = MatchSceneQuery.GetPlayerSpawn()

	return {
		MapRoot = mapRoot ~= nil,
		BattleZone = battleZone ~= nil,
		Runtime = runtime ~= nil,
		ZoneVariation = MatchSceneQuery.GetZoneVariationRoot() ~= nil,
		PlayerSpawn = playerSpawn ~= nil,
		PlayerSpawnIsPart = if playerSpawn then playerSpawn:IsA("BasePart") else false,
	}
end

return MatchSceneQuery
