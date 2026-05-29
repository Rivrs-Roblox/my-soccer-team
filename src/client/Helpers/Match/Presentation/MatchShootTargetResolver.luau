local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)

local MatchShootTargetResolver = {}

local SHOOT_ZONE_NAME = "ShootZone"
local SHOT_TARGETS_FOLDER_NAME = "ShotTargets"
local KEEPER_SAVE_TARGETS_FOLDER_NAME = "KeeperSaveTargets"
local KEEPER_LANDING_TARGETS_FOLDER_NAME = "KeeperLandingTargets"

local SHOOT_POSITION_NAMES = { "Left", "Center", "Right" }
local SHOOT_POSITIONS_FOLDER_NAME = "ShootPositions"

local TARGET_ORDER = {
	"Center",
	"HighLeft",
	"HighRight",
}

-- V4 keeper-save stabilization: avoid low-corner targets for now.
-- Low side saves are the most clipping-prone with the current blocky keeper rig.
-- Green shots favor upper side targets plus occasional center breakthrough.
local GREEN_TARGET_ORDER = {
	"HighLeft",
	"HighRight",
	"HighLeft",
	"HighRight",
	"Center",
}

local debugForcedTargetId = nil

local function asBasePart(instance)
	if instance and instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function getZoneMarker(markerName)
	if MatchZoneQuery.GetZoneMarker then
		return MatchZoneQuery.GetZoneMarker(SHOOT_ZONE_NAME, markerName)
	end

	local shootZone = MatchShootTargetResolver.GetShootZone()
	return shootZone and asBasePart(shootZone:FindFirstChild(markerName)) or nil
end

local function getFlatDistanceSquared(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return (dx * dx) + (dz * dz)
end

local function hashString(value)
	local hash = 0
	local text = tostring(value or "")

	for index = 1, #text do
		hash = (hash * 31 + string.byte(text, index)) % 2147483647
	end

	return hash
end

local function buildStableIndex(context, count)
	if count <= 1 then
		return 1
	end

	local seed = table.concat({
		tostring(context and context.SessionId or ""),
		tostring(context and context.StepIndex or ""),
		tostring(context and context.ActorSlot or ""),
		tostring(context and context.ShootTier or ""),
		tostring(context and context.IsGoal or ""),
	}, "|")

	return (hashString(seed) % count) + 1
end

local function buildSmallOffset(targetId, context)
	if not targetId or targetId == "Center" then
		return Vector3.zero
	end

	local seed = hashString(table.concat({
		tostring(targetId),
		tostring(context and context.SessionId or ""),
		tostring(context and context.ActorSlot or ""),
		tostring(context and context.ShootTier or ""),
	}, "|"))

	local horizontal = ((seed % 81) - 40) / 100
	local vertical = (((math.floor(seed / 81)) % 61) - 30) / 100

	return Vector3.new(horizontal, vertical, 0)
end

local function getTargetOrderForContext(context)
	local tier = tostring(context and context.ShootTier or "")
	if tier == "Green" then
		return GREEN_TARGET_ORDER
	end

	return TARGET_ORDER
end

function MatchShootTargetResolver.GetShootZone()
	if MatchZoneQuery.GetZoneFolder then
		return MatchZoneQuery.GetZoneFolder(SHOOT_ZONE_NAME)
	end

	return nil
end

function MatchShootTargetResolver.GetShootPositionCandidates()
	local shootZone = MatchShootTargetResolver.GetShootZone()
	local candidates = {}
	if not shootZone then
		return candidates
	end

	local positionsFolder = shootZone:FindFirstChild(SHOOT_POSITIONS_FOLDER_NAME)
	for _, markerName in ipairs(SHOOT_POSITION_NAMES) do
		local marker = nil

		if positionsFolder then
			marker = asBasePart(positionsFolder:FindFirstChild(markerName))
		end

		marker = marker or asBasePart(shootZone:FindFirstChild(markerName))
		if marker then
			table.insert(candidates, {
				Id = markerName,
				Part = marker,
			})
		end
	end

	return candidates
end

function MatchShootTargetResolver.GetNearestShootPosition(originPosition: Vector3?)
	local candidates = MatchShootTargetResolver.GetShootPositionCandidates()
	if #candidates == 0 then
		return nil
	end

	if not originPosition then
		return candidates[1].Part, candidates[1].Id
	end

	local best = candidates[1]
	local bestDistance = getFlatDistanceSquared(originPosition, best.Part.Position)

	for index = 2, #candidates do
		local candidate = candidates[index]
		local distance = getFlatDistanceSquared(originPosition, candidate.Part.Position)
		if distance < bestDistance then
			best = candidate
			bestDistance = distance
		end
	end

	return best.Part, best.Id
end

function MatchShootTargetResolver.GetCarrierPoint(originPosition: Vector3?)
	local nearestShootPosition = MatchShootTargetResolver.GetNearestShootPosition(originPosition)
	if nearestShootPosition then
		return nearestShootPosition
	end

	return getZoneMarker("CarrierPoint")
		or getZoneMarker("Area")
		or MatchZoneQuery.GetCarrierPoint(5)
end

function MatchShootTargetResolver.GetKeeperPoint()
	return getZoneMarker("KeeperPoint")
		or getZoneMarker("SaveTarget")
		or getZoneMarker("GoalTarget")
end

function MatchShootTargetResolver.GetGoalTarget()
	return getZoneMarker("GoalTarget") or MatchZoneQuery.GetGoalTarget()
end

function MatchShootTargetResolver.GetSaveTarget()
	return getZoneMarker("SaveTarget") or MatchZoneQuery.GetSaveTarget()
end

function MatchShootTargetResolver.GetShotTargetsFolder()
	local shootZone = MatchShootTargetResolver.GetShootZone()
	return shootZone and shootZone:FindFirstChild(SHOT_TARGETS_FOLDER_NAME) or nil
end

function MatchShootTargetResolver.GetShotTarget(targetId)
	local folder = MatchShootTargetResolver.GetShotTargetsFolder()
	if not folder then
		return nil
	end

	return asBasePart(folder:FindFirstChild(tostring(targetId or "")))
end


function MatchShootTargetResolver.GetKeeperSaveTargetsFolder()
	local shootZone = MatchShootTargetResolver.GetShootZone()
	local folder = shootZone and shootZone:FindFirstChild(KEEPER_SAVE_TARGETS_FOLDER_NAME)
	if folder then
		return folder
	end

	-- Defensive fallback for Studio hierarchy variations during map iteration.
	local map = Workspace:FindFirstChild("Map")
	local battleZone = map and map:FindFirstChild("BattleZone")
	local runtime = battleZone and battleZone:FindFirstChild("Runtime")
	local zones = runtime and runtime:FindFirstChild("Zones")
	local shootZoneFolder = zones and zones:FindFirstChild(SHOOT_ZONE_NAME)
	return shootZoneFolder and shootZoneFolder:FindFirstChild(KEEPER_SAVE_TARGETS_FOLDER_NAME) or nil
end

function MatchShootTargetResolver.GetKeeperSaveTarget(targetId)
	local folder = MatchShootTargetResolver.GetKeeperSaveTargetsFolder()
	if folder then
		local saveTarget = asBasePart(folder:FindFirstChild(tostring(targetId or ""), true))
		if saveTarget then
			return saveTarget
		end
	end

	-- Fallback keeps older maps working while new KeeperSaveTargets are being placed.
	return MatchShootTargetResolver.GetShotTarget(targetId)
		or MatchShootTargetResolver.GetCenterTarget()
end

function MatchShootTargetResolver.GetKeeperLandingTargetsFolder()
	local shootZone = MatchShootTargetResolver.GetShootZone()
	local folder = shootZone and shootZone:FindFirstChild(KEEPER_LANDING_TARGETS_FOLDER_NAME)
	if folder then
		return folder
	end

	-- Defensive fallback for Studio hierarchy variations during map iteration.
	local map = Workspace:FindFirstChild("Map")
	local battleZone = map and map:FindFirstChild("BattleZone")
	local runtime = battleZone and battleZone:FindFirstChild("Runtime")
	local zones = runtime and runtime:FindFirstChild("Zones")
	local shootZoneFolder = zones and zones:FindFirstChild(SHOOT_ZONE_NAME)
	return shootZoneFolder and shootZoneFolder:FindFirstChild(KEEPER_LANDING_TARGETS_FOLDER_NAME) or nil
end

function MatchShootTargetResolver.GetKeeperLandingTarget(targetId)
	local folder = MatchShootTargetResolver.GetKeeperLandingTargetsFolder()
	if not folder then
		return nil
	end

	return asBasePart(folder:FindFirstChild(tostring(targetId or ""), true))
end

function MatchShootTargetResolver.GetCenterTarget()
	return MatchShootTargetResolver.GetShotTarget("Center")
		or MatchShootTargetResolver.GetGoalTarget()
		or MatchShootTargetResolver.GetSaveTarget()
end

function MatchShootTargetResolver.GetAvailableShotTargets(context)
	local available = {}
	local targetOrder = getTargetOrderForContext(context)

	for _, targetId in ipairs(targetOrder) do
		local targetPart = MatchShootTargetResolver.GetShotTarget(targetId)
		if targetPart then
			table.insert(available, {
				Id = targetId,
				Part = targetPart,
			})
		end
	end

	-- Fallback to the full order if a map does not have the green-specific targets.
	if #available == 0 and targetOrder ~= TARGET_ORDER then
		for _, targetId in ipairs(TARGET_ORDER) do
			local targetPart = MatchShootTargetResolver.GetShotTarget(targetId)
			if targetPart then
				table.insert(available, {
					Id = targetId,
					Part = targetPart,
				})
			end
		end
	end

	if #available == 0 then
		local fallback = MatchShootTargetResolver.GetCenterTarget()
		if fallback then
			table.insert(available, {
				Id = "Center",
				Part = fallback,
			})
		end
	end

	return available
end

function MatchShootTargetResolver.ResolveShootLookPosition()
	local centerTarget = MatchShootTargetResolver.GetCenterTarget()
	if centerTarget then
		return centerTarget.Position
	end

	local carrierPoint = MatchShootTargetResolver.GetCarrierPoint()
	return carrierPoint and (carrierPoint.Position + carrierPoint.CFrame.LookVector * 12) or nil
end

function MatchShootTargetResolver.SetDebugForcedTargetId(targetId)
	local normalized = tostring(targetId or "")
	if normalized == "" then
		debugForcedTargetId = nil
		return
	end

	debugForcedTargetId = normalized
end

function MatchShootTargetResolver.ClearDebugForcedTargetId()
	debugForcedTargetId = nil
end

function MatchShootTargetResolver.BuildCarrierCFrame(originPosition: Vector3?)
	local carrierPoint = MatchShootTargetResolver.GetCarrierPoint(originPosition)
	if not carrierPoint then
		return nil
	end

	local lookPosition = MatchShootTargetResolver.ResolveShootLookPosition()
	if not lookPosition then
		return carrierPoint.CFrame
	end

	local carrierPosition = carrierPoint.Position
	return CFrame.lookAt(
		carrierPosition,
		Vector3.new(lookPosition.X, carrierPosition.Y, lookPosition.Z)
	)
end

function MatchShootTargetResolver.SelectShotTarget(context)
	local available = MatchShootTargetResolver.GetAvailableShotTargets(context)
	if #available == 0 then
		return nil
	end

	local forcedTargetId = debugForcedTargetId
	debugForcedTargetId = nil

	local requestedTargetId = forcedTargetId or (context and context.TargetId)
	if requestedTargetId then
		for _, targetInfo in ipairs(available) do
			if targetInfo.Id == requestedTargetId then
				local offset = buildSmallOffset(targetInfo.Id, context)
				return {
					Id = targetInfo.Id,
					Part = targetInfo.Part,
					Position = targetInfo.Part.Position + offset,
				}
			end
		end
	end

	local selected = available[buildStableIndex(context, #available)]
	local offset = buildSmallOffset(selected.Id, context)

	return {
		Id = selected.Id,
		Part = selected.Part,
		Position = selected.Part.Position + offset,
	}
end

return MatchShootTargetResolver
