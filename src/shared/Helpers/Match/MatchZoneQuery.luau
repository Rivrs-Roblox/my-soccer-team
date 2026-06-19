local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)

local MatchZoneQuery = {}

local ZONE_NAME_BY_STEP = {
	[1] = "Zone01",
	[2] = "Zone02",
	[3] = "Zone03",
	[4] = "Zone04",
	[5] = "ShootZone",
}

local ENEMY_ZONE_STEP_BY_SLOT = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
}

local ENEMY_APPROACH_MARKERS_BY_SLOT = {
	[3] = { "EnemyApproachPoint" },
	[4] = { "EnemyApproachPoint" },
}

local ENEMY_SPAWN_MARKERS_BY_SLOT = {
	[3] = { "EnemySpawnPointLeft", "EnemySpawnPoint", "EnemyApproachPoint", "Area" },
	[4] = { "EnemySpawnPointRight", "EnemySpawnPoint", "EnemyApproachPoint", "Area" },
}

local RECEIVE_MARKERS = {
	"ReceivePoint",
	"PassReceivePoint",
	"ForwardReceivePoint",
	"CarrierPoint",
	"Area",
}

local SUPPORT_ADVANCE_MARKERS = {
	"SupportAdvancePoint",
	"ForwardRunnerPoint",
	"ReceivePoint",
	"CarrierPoint",
	"Area",
}

local function GetBasePart(instance)
	if instance and instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function FindFirstMarker(stepIndexOrName, markerNames)
	for _, markerName in ipairs(markerNames) do
		local marker = MatchZoneQuery.GetZoneMarker(stepIndexOrName, markerName)
		if marker then
			return marker
		end
	end

	return nil
end

local function ResolveZoneName(stepIndexOrName): string?
	local zoneName = stepIndexOrName
	if typeof(stepIndexOrName) == "number" then
		zoneName = ZONE_NAME_BY_STEP[stepIndexOrName]
	end

	if typeof(zoneName) ~= "string" or zoneName == "" then
		return nil
	end

	return zoneName
end

local function AppendZoneFolderCandidate(candidates, zoneName, zonesRoot)
	local zoneFolder = zonesRoot and zonesRoot:FindFirstChild(zoneName)
	if zoneFolder then
		table.insert(candidates, zoneFolder)
	end
end

local function GetZoneFolderCandidates(zoneName: string): { Instance }
	local candidates = {}
	local activeVariationId = MatchSceneQuery.GetActiveZoneVariationId and MatchSceneQuery.GetActiveZoneVariationId() or nil
	local activeZonesRoot = MatchSceneQuery.GetZoneVariationChild and MatchSceneQuery.GetZoneVariationChild("Zones", activeVariationId)
	AppendZoneFolderCandidate(candidates, zoneName, activeZonesRoot)

	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	AppendZoneFolderCandidate(candidates, zoneName, runtimeRoot and runtimeRoot:FindFirstChild("Zones"))

	local availableVariationIds = MatchSceneQuery.GetAvailableZoneVariationIds and MatchSceneQuery.GetAvailableZoneVariationIds() or {}
	for _, variationId in ipairs(availableVariationIds) do
		if variationId ~= activeVariationId then
			local fallbackZonesRoot = MatchSceneQuery.GetZoneVariationChild("Zones", variationId)
			AppendZoneFolderCandidate(candidates, zoneName, fallbackZonesRoot)
		end
	end

	return candidates
end

function MatchZoneQuery.GetZoneNameByStep(stepIndex: number): string?
	return ZONE_NAME_BY_STEP[tonumber(stepIndex or 0)]
end

function MatchZoneQuery.GetZoneStepByEnemySlot(enemySlot: number): number
	return ENEMY_ZONE_STEP_BY_SLOT[tonumber(enemySlot or 1)] or 1
end

function MatchZoneQuery.GetZonesRoot(): Instance?
	local variationZonesRoot = MatchSceneQuery.GetZoneVariationChild("Zones")
	if variationZonesRoot then
		return variationZonesRoot
	end

	local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
	local zonesRoot = runtimeRoot and runtimeRoot:FindFirstChild("Zones")
	if zonesRoot then
		return zonesRoot
	end

	local availableVariationIds = MatchSceneQuery.GetAvailableZoneVariationIds and MatchSceneQuery.GetAvailableZoneVariationIds() or {}
	for _, variationId in ipairs(availableVariationIds) do
		local fallbackZonesRoot = MatchSceneQuery.GetZoneVariationChild("Zones", variationId)
		if fallbackZonesRoot then
			return fallbackZonesRoot
		end
	end

	return nil
end

function MatchZoneQuery.GetZoneFolder(stepIndexOrName): Instance?
	local zoneName = ResolveZoneName(stepIndexOrName)
	if not zoneName then
		return nil
	end

	local candidates = GetZoneFolderCandidates(zoneName)
	return candidates[1]
end

function MatchZoneQuery.GetZoneMarker(stepIndexOrName, markerName: string): BasePart?
	local zoneName = ResolveZoneName(stepIndexOrName)
	if not zoneName then
		return nil
	end

	for _, zoneFolder in ipairs(GetZoneFolderCandidates(zoneName)) do
		local marker = GetBasePart(zoneFolder:FindFirstChild(markerName))
		if marker then
			return marker
		end
	end

	return nil
end

function MatchZoneQuery.GetZoneArea(stepIndexOrName): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndexOrName, "Area")
end

function MatchZoneQuery.GetCarrierPoint(stepIndex): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndex, "CarrierPoint")
end

function MatchZoneQuery.GetReceivePoint(stepIndex, receiveIndex: number?): BasePart?
	local numericStep = tonumber(stepIndex)
	local numericIndex = tonumber(receiveIndex)

	-- Zone03 has two explicit receive markers for the tiki-taka flow:
	-- ReceivePoint1 = QTE2 -> Zone03 first receive.
	-- ReceivePoint2 = QTE4 return pass receive.
	if numericStep == 3 then
		if numericIndex == 2 then
			return MatchZoneQuery.GetZoneMarker(3, "ReceivePoint2")
				or MatchZoneQuery.GetZoneMarker(3, "ReturnPassPoint")
				or MatchZoneQuery.GetZoneMarker(3, "ReceivePoint1")
				or FindFirstMarker(3, RECEIVE_MARKERS)
		end

		return MatchZoneQuery.GetZoneMarker(3, "ReceivePoint1")
			or MatchZoneQuery.GetZoneMarker(3, "ReceivePoint")
			or MatchZoneQuery.GetZoneMarker(3, "PassReceivePoint")
			or MatchZoneQuery.GetZoneMarker(3, "ForwardReceivePoint")
			or MatchZoneQuery.GetZoneMarker(3, "CarrierPoint")
			or MatchZoneQuery.GetZoneMarker(3, "Area")
	end

	if numericIndex then
		local indexedMarker = MatchZoneQuery.GetZoneMarker(stepIndex, "ReceivePoint" .. tostring(numericIndex))
		if indexedMarker then
			return indexedMarker
		end
	end

	return FindFirstMarker(stepIndex, RECEIVE_MARKERS)
end

function MatchZoneQuery.GetCarryPoint(stepIndex, carryIndex: number?): BasePart?
	local numericStep = tonumber(stepIndex)
	local numericIndex = tonumber(carryIndex)

	if numericStep == 3 and numericIndex == 2 then
		return MatchZoneQuery.GetZoneMarker(3, "CarrierPoint2")
			or MatchZoneQuery.GetZoneMarker(3, "CarryPoint2")
			or MatchZoneQuery.GetZoneMarker(3, "ReceivePoint2")
			or MatchZoneQuery.GetZoneMarker(3, "CarrierPoint")
	end

	if numericIndex then
		local indexedMarker = MatchZoneQuery.GetZoneMarker(stepIndex, "CarryPoint" .. tostring(numericIndex))
		if indexedMarker then
			return indexedMarker
		end
	end

	return MatchZoneQuery.GetZoneMarker(stepIndex, "CarryPoint")
		or MatchZoneQuery.GetCarrierPoint(stepIndex)
end

function MatchZoneQuery.GetSupportAdvancePoint(stepIndex): BasePart?
	return FindFirstMarker(stepIndex, SUPPORT_ADVANCE_MARKERS)
end

function MatchZoneQuery.GetEnemySpawnPoint(stepIndex): BasePart?
	if tonumber(stepIndex) == 5 then
		return MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperStartPoint")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperPoint")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "GoalTarget")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "Area")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "SaveTarget")
	end

	return MatchZoneQuery.GetZoneMarker(stepIndex, "EnemySpawnPoint")
		or MatchZoneQuery.GetZoneMarker(stepIndex, "Area")
		or MatchZoneQuery.GetZoneMarker(stepIndex, "EnemyApproachPoint")
end

function MatchZoneQuery.GetEnemySpawnPointBySlot(enemySlot: number): BasePart?
	local numericSlot = tonumber(enemySlot or 1) or 1
	local zoneStep = MatchZoneQuery.GetZoneStepByEnemySlot(numericSlot)

	if zoneStep == 5 then
		return MatchZoneQuery.GetEnemySpawnPoint(5)
	end

	local markerNames = ENEMY_SPAWN_MARKERS_BY_SLOT[numericSlot]
	if markerNames then
		return FindFirstMarker(zoneStep, markerNames)
	end

	return MatchZoneQuery.GetEnemySpawnPoint(zoneStep)
end

function MatchZoneQuery.GetEnemyApproachPoint(stepIndex): BasePart?
	if tonumber(stepIndex) == 5 then
		return MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperEngagePoint")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperPoint")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "SaveTarget")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "GoalTarget")
			or MatchZoneQuery.GetZoneMarker("ShootZone", "CarrierPoint")
	end

	return MatchZoneQuery.GetZoneMarker(stepIndex, "EnemyApproachPoint")
		or MatchZoneQuery.GetZoneMarker(stepIndex, "Area")
		or MatchZoneQuery.GetZoneMarker(stepIndex, "CarrierPoint")
end

function MatchZoneQuery.GetEnemyApproachPointBySlot(enemySlot: number): BasePart?
	local numericSlot = tonumber(enemySlot or 1) or 1
	local zoneStep = MatchZoneQuery.GetZoneStepByEnemySlot(numericSlot)

	if zoneStep == 5 then
		return MatchZoneQuery.GetEnemyApproachPoint(5)
	end

	local markerNames = ENEMY_APPROACH_MARKERS_BY_SLOT[numericSlot]
	if markerNames then
		return FindFirstMarker(zoneStep, markerNames)
	end

	return MatchZoneQuery.GetEnemyApproachPoint(zoneStep)
end

function MatchZoneQuery.GetDribbleCurveLeft(stepIndex): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndex, "DribbleCurveLeft")
end

function MatchZoneQuery.GetDribbleCurveRight(stepIndex): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndex, "DribbleCurveRight")
end

function MatchZoneQuery.GetExitPoint(stepIndex): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndex, "ExitPoint")
end

function MatchZoneQuery.GetPlayer2BranchTarget(): BasePart?
	return MatchZoneQuery.GetZoneMarker(4, "Player2Target")
		or MatchZoneQuery.GetZoneMarker(2, "Player2Target")
		or MatchZoneQuery.GetCarrierPoint(4)
end

function MatchZoneQuery.GetPlayer4BranchTarget(): BasePart?
	return MatchZoneQuery.GetZoneMarker(4, "Player4Target")
		or MatchZoneQuery.GetZoneMarker(4, "ReceiveTarget")
		or MatchZoneQuery.GetReceivePoint(4)
		or MatchZoneQuery.GetCarrierPoint(4)
end

function MatchZoneQuery.GetPlayer4BranchReceiveTarget(): BasePart?
	return MatchZoneQuery.GetZoneMarker(4, "ReceiveTarget")
		or MatchZoneQuery.GetZoneMarker(4, "Player4Target")
		or MatchZoneQuery.GetReceivePoint(4)
		or MatchZoneQuery.GetCarrierPoint(4)
end

function MatchZoneQuery.GetQteForceLine(stepIndex): BasePart?
	return MatchZoneQuery.GetZoneMarker(stepIndex, "QteForceLine")
		or MatchZoneQuery.GetExitPoint(stepIndex)
end

function MatchZoneQuery.GetGoalTarget(): BasePart?
	return MatchZoneQuery.GetZoneMarker("ShootZone", "GoalTarget")
end

function MatchZoneQuery.GetSaveTarget(): BasePart?
	return MatchZoneQuery.GetZoneMarker("ShootZone", "SaveTarget")
end

function MatchZoneQuery.GetKeeperPoint(): BasePart?
	return MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperPoint")
end

function MatchZoneQuery.GetKeeperEngagePoint(): BasePart?
	return MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperEngagePoint")
		or MatchZoneQuery.GetZoneMarker("ShootZone", "KeeperPoint")
		or MatchZoneQuery.GetZoneMarker("ShootZone", "SaveTarget")
		or MatchZoneQuery.GetZoneMarker("ShootZone", "GoalTarget")
end

return MatchZoneQuery
