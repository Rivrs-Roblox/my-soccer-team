local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchEnemyAreaConfig = require(ReplicatedStorage.Shared.Data.Match.MatchEnemyAreaConfig)
local MatchGrounding = require(ReplicatedStorage.Shared.Helpers.Match.MatchGrounding)
local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)
local GetMatchEnemyModel = require(ReplicatedStorage.Shared.Helpers.Match.GetMatchEnemyModel)

local LocalPlayer = Players.LocalPlayer
local MatchService = nil

local GOALKEEPER_SLOT = 5
local LAST_DEFENDER_SLOT = 4

local DEFENDER_LATERAL_SPAWN_DISTANCE = 30
local DEFENDER_BACK_OFFSET = 6
local DEFENDER_FORWARD_JITTER = 6
local DEFENDER_EXTRA_RANDOM_RADIUS = 2

local MatchEnemyController = Knit.CreateController({
	Name = "MatchEnemyController",
	ActiveSessionId = nil,
	SpawnedModels = {},
	HiddenPivotBillboards = {},
})

local function GetPrimaryPartOrRoot(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		model.PrimaryPart = root
		return root
	end

	local fallback = model:FindFirstChildWhichIsA("BasePart", true)
	if fallback then
		model.PrimaryPart = fallback
		return fallback
	end

	return nil
end

local function StripScripts(instance: Instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end
end


local function ResetRuntimeRagdollResidue(model: Model)
	if not model then
		return
	end

	model:SetAttribute("IsCinematicReacting", nil)
	model:SetAttribute("IsPowerBreakthroughRagdoll", nil)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = false
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			descendant.Enabled = true
		elseif descendant:IsA("BallSocketConstraint") and string.find(descendant.Name, "_Ragdoll") then
			descendant:Destroy()
		elseif descendant:IsA("Attachment") and string.find(descendant.Name, "_Att") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function MakeVisualOnly(model: Model)
	local primaryPart = GetPrimaryPartOrRoot(model)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true

			-- Penting:
			-- jangan anchor semua part rig, nanti animasi Run/Idle tidak kelihatan.
			descendant.Anchored = false
		end
	end

	if primaryPart then
		model.PrimaryPart = primaryPart
		primaryPart.Anchored = true
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
	end
end

local function GetRuntimeEnemyName(slotNumber: number): string
	if tonumber(slotNumber) == GOALKEEPER_SLOT then
		return "GoalKeeper"
	end

	return string.format("Enemy%02d", tonumber(slotNumber) or 1)
end

local function IsGoalkeeperSlot(slotNumber: number): boolean
	return tonumber(slotNumber) == GOALKEEPER_SLOT
end

local function GetZoneStepForEnemySlot(slotNumber: number): number
	local numericSlot = tonumber(slotNumber) or 1

	if numericSlot == GOALKEEPER_SLOT then
		return 5
	end

	return math.clamp(numericSlot, 1, 4)
end

local function GetGroundedCFrame(model: Model, targetCFrame: CFrame, options): CFrame
	options = table.clone(options or {})
	options.IgnoreMatchRuntimeRoot = options.IgnoreMatchRuntimeRoot ~= false
	options.FallbackY = options.FallbackY or targetCFrame.Position.Y

	return MatchGrounding.GetGroundedCFrame(model, targetCFrame, options)
end

local function GetSessionSeed(sessionId: string, slotNumber: number): number
	local seed = 0

	for index = 1, #sessionId do
		seed += string.byte(sessionId, index)
	end

	return seed + (slotNumber * 101)
end

local function GetFlatDirection(fromPosition: Vector3, toPosition: Vector3): Vector3
	local direction = toPosition - fromPosition
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)

	if flatDirection.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return flatDirection.Unit
end

local function GetRightVector(forward: Vector3): Vector3
	local right = forward:Cross(Vector3.new(0, 1, 0))

	if right.Magnitude <= 0.001 then
		return Vector3.new(1, 0, 0)
	end

	return right.Unit
end

local function GetRandomUnitOffset(rng: Random, radius: number): Vector3
	if radius <= 0 then
		return Vector3.zero
	end

	local angle = rng:NextNumber(0, math.pi * 2)
	local distance = rng:NextNumber(0, radius)

	return Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)
end

local function ResolveDefenderSpawnSide(slotConfig, rng: Random): number
	if typeof(slotConfig) == "table" then
		local spawnSide = tostring(slotConfig.SpawnSide or "")

		if spawnSide == "Left" then
			return -1
		end

		if spawnSide == "Right" then
			return 1
		end
	end

	return rng:NextInteger(0, 1) == 0 and -1 or 1
end

function MatchEnemyController:_hideOldPivotBillboards()
	self.HiddenPivotBillboards = {}

	local pivotsRoot = MatchSceneQuery.GetEnemyPivotsRoot()
	if not pivotsRoot then
		return
	end

	for _, descendant in ipairs(pivotsRoot:GetDescendants()) do
		if descendant:IsA("BillboardGui") then
			self.HiddenPivotBillboards[descendant] = descendant.Enabled
			descendant.Enabled = false
		end
	end
end

function MatchEnemyController:_restoreOldPivotBillboards()
	for billboard, oldEnabled in pairs(self.HiddenPivotBillboards) do
		if billboard and billboard.Parent then
			billboard.Enabled = oldEnabled
		end
	end

	table.clear(self.HiddenPivotBillboards)
end

function MatchEnemyController:_clearSpawnedEnemies(expectedSessionId: string?)
	local expected = tostring(expectedSessionId or "")
	if expected ~= "" and self.ActiveSessionId ~= nil and tostring(self.ActiveSessionId) ~= expected then
		warn(string.format(
			"[MatchEnemyController] Ignored stale enemy cleanup endedSession=%s activeSession=%s",
			expected,
			tostring(self.ActiveSessionId)
		))
		return
	end

	for _, model in ipairs(self.SpawnedModels) do
		if model and model.Parent then
			model:Destroy()
		end
	end

	table.clear(self.SpawnedModels)
	self.ActiveSessionId = nil
	self:_restoreOldPivotBillboards()
end

function MatchEnemyController:_buildGoalkeeperSpawnCFrame(slotNumber: number): CFrame?
	local spawnPoint = nil
	local approachPoint = nil

	if MatchZoneQuery.GetEnemySpawnPointBySlot then
		spawnPoint = MatchZoneQuery.GetEnemySpawnPointBySlot(slotNumber)
	end

	if MatchZoneQuery.GetEnemyApproachPointBySlot then
		approachPoint = MatchZoneQuery.GetEnemyApproachPointBySlot(slotNumber)
	end

	spawnPoint = spawnPoint or MatchZoneQuery.GetEnemySpawnPoint(5)
	approachPoint = approachPoint or MatchZoneQuery.GetEnemyApproachPoint(5)

	local carrierPoint = MatchZoneQuery.GetCarrierPoint(5)
	local goalTarget = MatchZoneQuery.GetGoalTarget()

	local basePart = spawnPoint or approachPoint or carrierPoint or goalTarget
	if not basePart then
		return nil
	end

	local spawnPosition = basePart.Position

	local markerLook = basePart.CFrame.LookVector
	local flatLook = Vector3.new(markerLook.X, 0, markerLook.Z)

	if flatLook.Magnitude <= 0.001 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	return CFrame.lookAt(spawnPosition, spawnPosition + flatLook)
end

function MatchEnemyController:_buildDefenderSpawnCFrame(slotNumber: number, slotConfig, seed: number): CFrame?
	local zoneStep = GetZoneStepForEnemySlot(slotNumber)

	local approachPoint = nil
	local fallbackSpawn = nil

	if MatchZoneQuery.GetEnemyApproachPointBySlot then
		approachPoint = MatchZoneQuery.GetEnemyApproachPointBySlot(slotNumber)
	end

	if MatchZoneQuery.GetEnemySpawnPointBySlot then
		fallbackSpawn = MatchZoneQuery.GetEnemySpawnPointBySlot(slotNumber)
	end

	approachPoint = approachPoint or MatchZoneQuery.GetEnemyApproachPoint(zoneStep)
	fallbackSpawn = fallbackSpawn or MatchZoneQuery.GetEnemySpawnPoint(zoneStep)

	local carrierPoint = MatchZoneQuery.GetCarrierPoint(zoneStep)
	local basePart = approachPoint or fallbackSpawn or carrierPoint

	if not basePart then
		return nil
	end

	local basePosition = basePart.Position
	local referenceTarget = carrierPoint and carrierPoint.Position or (basePosition + basePart.CFrame.LookVector)
	local flatForward = GetFlatDirection(basePosition, referenceTarget)
	local right = GetRightVector(flatForward)

	local rng = Random.new(seed)
	local sideSign = ResolveDefenderSpawnSide(slotConfig, rng)

	local lateralDistance = tonumber(slotConfig and slotConfig.LateralSpawnDistance) or DEFENDER_LATERAL_SPAWN_DISTANCE
	local backOffset = tonumber(slotConfig and slotConfig.BackOffset) or DEFENDER_BACK_OFFSET
	local forwardJitterMax = tonumber(slotConfig and slotConfig.ForwardJitter) or DEFENDER_FORWARD_JITTER
	local extraRadius = tonumber(slotConfig and slotConfig.RandomRadius) or DEFENDER_EXTRA_RANDOM_RADIUS

	local forwardJitter = rng:NextNumber(-forwardJitterMax, forwardJitterMax)
	local randomOffset = GetRandomUnitOffset(rng, extraRadius)

	local spawnPosition = basePosition

	if approachPoint then
		-- Authored approach markers are the source of truth for variation layouts.
		spawnPosition = basePosition + randomOffset
	else
		spawnPosition = basePosition
			+ (right * sideSign * lateralDistance)
			- (flatForward * backOffset)
			+ (flatForward * forwardJitter)
			+ randomOffset
	end

	local lookTarget = basePosition
	if carrierPoint and (carrierPoint.Position - spawnPosition).Magnitude > 0.001 then
		lookTarget = carrierPoint.Position
	end

	return CFrame.lookAt(spawnPosition, lookTarget)
end

function MatchEnemyController:_buildSpawnCFrame(slotNumber: number, slotConfig, sessionId: string): CFrame?
	local seed = GetSessionSeed(sessionId, slotNumber)
	local cf = nil

	if IsGoalkeeperSlot(slotNumber) then
		cf = self:_buildGoalkeeperSpawnCFrame(slotNumber)
	else
		cf = self:_buildDefenderSpawnCFrame(slotNumber, slotConfig, seed)
	end

	if cf then
		return cf
	end

	return nil
end

function MatchEnemyController:_prepareEnemyModel(model: Model, areaId: string, sessionId: string, slotNumber: number, slotConfig, opponentTeam)
	StripScripts(model)
	ResetRuntimeRagdollResidue(model)
	MakeVisualOnly(model)

	local runtimeName = GetRuntimeEnemyName(slotNumber)
	model.Name = runtimeName
	model:SetAttribute("MatchEnemyAreaId", areaId)
	model:SetAttribute("MatchEnemySlot", slotNumber)
	model:SetAttribute("MatchEnemyRole", slotConfig.Role or "Defender")
	model:SetAttribute("SessionId", sessionId)

	if typeof(opponentTeam) == "table" then
		model:SetAttribute("MatchEnemyTeamId", tostring(opponentTeam.TeamId or ""))
		model:SetAttribute("MatchEnemyTeamName", tostring(opponentTeam.DisplayName or ""))
		model:SetAttribute("MatchEnemyTeamAssetFolder", tostring(opponentTeam.AssetFolderName or ""))
	end
end

function MatchEnemyController:_resolveEnemyModel(areaConfig, slotConfig, opponentTeam)
	local teamAssetFolderName = ""
	if typeof(opponentTeam) == "table" then
		teamAssetFolderName = tostring(opponentTeam.AssetFolderName or opponentTeam.TeamId or "")
	end

	local model = GetMatchEnemyModel({
		AssetFolderName = areaConfig.AssetFolderName,
		TeamAssetFolderName = teamAssetFolderName,
		ModelName = slotConfig.ModelName,
		FallbackModelName = slotConfig.FallbackModelName,
	})

	if not model then
		return nil, "Failed to resolve enemy model"
	end

	if not model:IsA("Model") then
		local fullName = model:GetFullName()
		model:Destroy()
		return nil, string.format("Resolved instance is not a Model: %s", fullName)
	end

	return model, nil
end

function MatchEnemyController:_spawnEnemySlot(areaConfig, areaId: string, sessionId: string, slotNumber: number, slotConfig, folder: Folder, opponentTeam)
	local model, resolveError = self:_resolveEnemyModel(areaConfig, slotConfig, opponentTeam)
	if not model then
		warn("[MatchEnemyController]", resolveError, "area=", areaId, "slot=", slotNumber)
		return
	end

	self:_prepareEnemyModel(model, areaId, sessionId, slotNumber, slotConfig, opponentTeam)

	local spawnCFrame = self:_buildSpawnCFrame(slotNumber, slotConfig, sessionId)
	if not spawnCFrame then
		warn("[MatchEnemyController] Missing zone-based spawn markers for slot:", slotNumber)
		model:Destroy()
		return
	end

	model.Parent = folder
	model:PivotTo(GetGroundedCFrame(model, spawnCFrame, {
		IgnoreGoalAssemblies = IsGoalkeeperSlot(slotNumber),
	}))

	table.insert(self.SpawnedModels, model)
end

function MatchEnemyController:_spawnEnemiesForSession(payload)
	if typeof(payload) ~= "table" then
		warn("[MatchEnemyController] Invalid payload")
		return
	end

	local areaId = tostring(payload.AreaId or "")
	local sessionId = tostring(payload.SessionId or "")
	local opponentTeam = nil
	if typeof(payload.Tournament) == "table" and typeof(payload.Tournament.OpponentTeam) == "table" then
		opponentTeam = payload.Tournament.OpponentTeam
	end

	if areaId == "" or sessionId == "" then
		warn("[MatchEnemyController] Missing areaId or sessionId")
		return
	end

	local areaConfig = MatchEnemyAreaConfig[areaId]
	if not areaConfig then
		warn("[MatchEnemyController] No area config found for", areaId)
		return
	end

	local folder = MatchSceneQuery.GetSpawnedEnemiesFolder(true)
	if not folder then
		warn("[MatchEnemyController] SpawnedEnemies folder is missing and could not be created")
		return
	end

	self:_clearSpawnedEnemies()
	self:_hideOldPivotBillboards()

	self.ActiveSessionId = sessionId

	for slotNumber = 1, GOALKEEPER_SLOT do
		local slotConfig = areaConfig.Slots and areaConfig.Slots[slotNumber]
		if slotConfig then
			self:_spawnEnemySlot(areaConfig, areaId, sessionId, slotNumber, slotConfig, folder, opponentTeam)
		else
			warn("[MatchEnemyController] Missing slot config for slot", slotNumber, "area", areaId)
		end
	end
end

function MatchEnemyController:KnitStart()
	MatchService = Knit.GetService("MatchService")

	MatchService.MatchSessionStarted:Connect(function(payload)
		self:_spawnEnemiesForSession(payload)
	end)

	MatchService.MatchSessionEnded:Connect(function(_, sessionId)
		local endedSessionId = tostring(sessionId or "")
		if endedSessionId == "" and self.ActiveSessionId ~= nil then
			warn(string.format(
				"[MatchEnemyController] Ignored session end without SessionId while activeSession=%s",
				tostring(self.ActiveSessionId)
			))
			return
		end

		self:_clearSpawnedEnemies(endedSessionId)
	end)

	LocalPlayer.CharacterRemoving:Connect(function()
		self:_clearSpawnedEnemies()
	end)
end

return MatchEnemyController
