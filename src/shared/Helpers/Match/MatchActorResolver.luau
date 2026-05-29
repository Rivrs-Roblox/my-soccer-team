local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)

local LocalPlayer = Players.LocalPlayer

local MatchActorResolver = {}

local function GetCharacterRoot(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		local head = instance:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then
			return head
		end

		local hrp = instance:FindFirstChild("HumanoidRootPart", true)
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end

		if instance.PrimaryPart then
			return instance.PrimaryPart
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	if instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function GetOwnedCompanionFolder()
	local root = Workspace:FindFirstChild("SoccerCharacters")
	if not root then
		return nil
	end

	local folder = root:FindFirstChild("CompanionModels")
	if folder and folder:IsA("Folder") then
		return folder
	end

	return nil
end

function MatchActorResolver.GetOwnedCompanionModels()
	local folder = GetOwnedCompanionFolder()
	local results = {}

	if not folder then
		return results
	end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("Owner") == LocalPlayer.Name then
			table.insert(results, child)
		end
	end

	table.sort(results, function(a, b)
		return a.Name < b.Name
	end)

	return results
end

function MatchActorResolver.GetActorModelBySlot(slotNumber, playerProxy)
	if tonumber(slotNumber) == 1 then
		return playerProxy or LocalPlayer.Character
	end

	local companions = MatchActorResolver.GetOwnedCompanionModels()
	local index = math.max(1, tonumber(slotNumber or 2) - 1)

	return companions[index]
end

function MatchActorResolver.GetActorRootBySlot(slotNumber, playerProxy)
	local model = MatchActorResolver.GetActorModelBySlot(slotNumber, playerProxy)
	return GetCharacterRoot(model), model
end

function MatchActorResolver.GetTargetModelBySlot(slotNumber, playerProxy)
	return MatchActorResolver.GetActorModelBySlot(slotNumber, playerProxy)
end

function MatchActorResolver.GetEnemyModelByStep(stepIndex)
	local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder(false)
	if not enemiesFolder then
		return nil
	end

	local nameMap = {
		[1] = "Enemy01",
		[2] = "Enemy02",
		[3] = "Enemy03",
		[4] = "Enemy04",
		[5] = "GoalKeeper",
	}

	local enemyName = nameMap[tonumber(stepIndex or 1)] or "Enemy01"
	local enemy = enemiesFolder:FindFirstChild(enemyName)

	if enemy then
		return enemy
	end

	if tonumber(stepIndex) == 5 then
		return enemiesFolder:FindFirstChild("Keeper")
	end

	return nil
end

function MatchActorResolver.GetEnemyRootByStep(stepIndex)
	local model = MatchActorResolver.GetEnemyModelByStep(stepIndex)
	return GetCharacterRoot(model), model
end

function MatchActorResolver.GetAttackDirection()
	local playerSpawn = MatchSceneQuery.GetPlayerSpawn()
	local goalTarget = MatchZoneQuery.GetGoalTarget() or MatchZoneQuery.GetSaveTarget()

	if playerSpawn and goalTarget then
		local direction = goalTarget.Position - playerSpawn.Position
		if direction.Magnitude > 0.001 then
			return direction.Unit
		end
	end

	if playerSpawn then
		local look = playerSpawn.CFrame.LookVector
		if look.Magnitude > 0.001 then
			return look.Unit
		end
	end

	local goalPivot = MatchSceneQuery.GetEnemyPivotByName("GoalKeeper") or MatchSceneQuery.GetEnemyPivotByName("Keeper")
	if playerSpawn and goalPivot then
		local direction = goalPivot.Position - playerSpawn.Position
		if direction.Magnitude > 0.001 then
			return direction.Unit
		end
	end

	return Vector3.new(0, 0, -1)
end

function MatchActorResolver.GetEnemyInterceptPoint(stepIndex)
	local enemyRoot = MatchActorResolver.GetEnemyRootByStep(stepIndex)
	if enemyRoot then
		return enemyRoot.Position
	end

	local approachPoint = MatchZoneQuery.GetEnemyApproachPoint(stepIndex)
	if approachPoint then
		return approachPoint.Position
	end

	local spawnPoint = MatchZoneQuery.GetEnemySpawnPoint(stepIndex)
	if spawnPoint then
		return spawnPoint.Position
	end

	local pivot = MatchSceneQuery.GetEnemyPivot(stepIndex)
	if pivot then
		return pivot.Position
	end

	return nil
end

return MatchActorResolver