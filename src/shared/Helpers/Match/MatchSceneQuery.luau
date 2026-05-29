local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchConstants = require(ReplicatedStorage.Shared.Data.Match.MatchConstants)

local MatchSceneQuery = {}

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

function MatchSceneQuery.GetPlayerSpawn(): BasePart?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	local playerSpawn = runtimeRoot and runtimeRoot:FindFirstChild(MatchConstants.PLAYER_SPAWN_NAME)

	if playerSpawn and playerSpawn:IsA("BasePart") then
		return playerSpawn
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

function MatchSceneQuery.GetCompanionPivotsRoot(): Instance?
	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	return runtimeRoot and runtimeRoot:FindFirstChild(MatchConstants.COMPANION_PIVOTS_FOLDER_NAME)
end

function MatchSceneQuery.GetCompanionPivot(slotNumber: number): BasePart?
	local pivotsRoot = MatchSceneQuery.GetCompanionPivotsRoot()
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
	local playerSpawn = runtime and runtime:FindFirstChild(MatchConstants.PLAYER_SPAWN_NAME)

	return {
		MapRoot = mapRoot ~= nil,
		BattleZone = battleZone ~= nil,
		Runtime = runtime ~= nil,
		PlayerSpawn = playerSpawn ~= nil,
		PlayerSpawnIsPart = if playerSpawn then playerSpawn:IsA("BasePart") else false,
	}
end

return MatchSceneQuery
