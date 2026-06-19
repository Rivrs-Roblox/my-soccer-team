local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)

local MatchWorldService = Knit.CreateService({
	Name = "MatchWorldService",
	Client = {},
})

-- Cache is intentionally NOT used as the primary source for spawn CFrame.
-- The Part is always re-read live so that its position reflects the current
-- Workspace state, not a potentially stale boot-time snapshot.
local cachedPlayerSpawnCFrame = nil

local FOOTBALL_FLOOR_NAMES = {
	FootballFloor = true,
}

local function FindPlayerSpawnDeep(zoneVariationId): BasePart?
	local battleZoneRoot = MatchSceneQuery.GetBattleZoneRoot()
	if not battleZoneRoot then
		warn("[MatchWorld] FindPlayerSpawnDeep: BattleZone root not found (Workspace.Map.BattleZone)")
		return nil
	end

	local directSpawn = MatchSceneQuery.GetPlayerSpawn(zoneVariationId)
	if directSpawn then
		return directSpawn
	end

	if zoneVariationId ~= nil then
		return nil
	end

	-- Fallback: deep scan of BattleZone descendants
	local found = nil
	for _, descendant in ipairs(battleZoneRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "PlayerSpawn" then
			if found then
				-- Multiple PlayerSpawn parts found – warn so the developer knows
				warn(string.format(
					"[MatchWorld] Multiple PlayerSpawn parts found! Using first: %s. Duplicate: %s",
					found:GetFullName(),
					descendant:GetFullName()
				))
			else
				found = descendant
			end
		end
	end

	return found
end

local function FindFootballFloorDeep(): BasePart?
	local battleZoneRoot = MatchSceneQuery.GetBattleZoneRoot()
	if not battleZoneRoot then
		return nil
	end

	for _, descendant in ipairs(battleZoneRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and FOOTBALL_FLOOR_NAMES[descendant.Name] == true then
			return descendant
		end
	end

	return nil
end

local function ConfigureFootballFloor(floorPart: BasePart?)
	if not floorPart then
		return false
	end

	floorPart.Anchored = true
	floorPart.CanCollide = true
	floorPart.CanQuery = true
	floorPart.CanTouch = false
	floorPart.Transparency = 1
	floorPart.CastShadow = false

	return true
end

function MatchWorldService:GetBattleZonePrompts(): { ProximityPrompt }
	return MatchSceneQuery.GetAllBattleZonePrompts()
end

function MatchWorldService:GetBattleZoneRoot(): Instance?
	return MatchSceneQuery.GetBattleZoneRoot()
end

function MatchWorldService:GetPlayerSpawnCFrame(zoneVariationId): CFrame?
	ConfigureFootballFloor(FindFootballFloorDeep())

	-- Always read the Part live – never silently return a stale cached CFrame.
	local playerSpawn = FindPlayerSpawnDeep(zoneVariationId)
	if playerSpawn then
		local freshCFrame = playerSpawn.CFrame
		cachedPlayerSpawnCFrame = freshCFrame
		return freshCFrame
	end

	-- Part tidak ditemukan. Log path validation untuk membantu debug.
	local validation = MatchSceneQuery.GetPathValidation and MatchSceneQuery.GetPathValidation() or {}
	warn(string.format(
		"[MatchWorld] PlayerSpawn Part NOT FOUND. Path check: MapRoot=%s, BattleZone=%s, Runtime=%s, PlayerSpawn=%s, IsPart=%s",
		tostring(validation.MapRoot),
		tostring(validation.BattleZone),
		tostring(validation.Runtime),
		tostring(validation.PlayerSpawn),
		tostring(validation.PlayerSpawnIsPart)
	))

	-- Fallback terakhir: gunakan cache dari boot time jika masih valid.
	-- Ini mencegah match gagal total akibat transient replication lag
	-- atau streaming gap sementara. Tetap warn agar mudah dideteksi.
	if cachedPlayerSpawnCFrame then
		warn("[MatchWorld] Using CACHED PlayerSpawn CFrame as fallback - verify PlayerSpawn part exists in Workspace.Map.BattleZone.Runtime")
		return cachedPlayerSpawnCFrame
	end

	return nil
end

function MatchWorldService:ValidateSetup(): (boolean, { string })
	local errors = {}

	local function RequireZoneMarker(zoneName: string, markerName: string)
		local marker = MatchZoneQuery.GetZoneMarker(zoneName, markerName)
		if not marker then
			table.insert(errors, string.format("Missing zone marker: %s.%s", zoneName, markerName))
		end
	end

	if not MatchSceneQuery.GetBattleZoneRoot() then
		table.insert(errors, "Workspace.Map.BattleZone is missing.")
	end

	if not MatchSceneQuery.GetRuntimeRoot() then
		table.insert(errors, "Workspace.Map.BattleZone.Runtime is missing.")
	end

	if not FindPlayerSpawnDeep() then
		table.insert(errors, "Workspace.Map.BattleZone.Runtime.PlayerSpawn or Runtime.ZoneVariation.*.PlayerSpawn is missing or is not a BasePart.")
	end

	if not FindFootballFloorDeep() then
		table.insert(errors, "Workspace.Map.BattleZone.*.FootballFloor is missing or is not a BasePart.")
	end

	local companionPivotsRoot = MatchSceneQuery.GetCompanionPivotsRoot()
	if not companionPivotsRoot then
		table.insert(errors, "Workspace.Map.BattleZone.Runtime.CompanionPivots or Runtime.ZoneVariation.*.CompanionPivots is missing.")
	else
		for slotNumber = 2, 4 do
			if MatchSceneQuery.GetCompanionPivot(slotNumber) == nil then
				table.insert(errors, string.format("Missing companion pivot: Slot%d", slotNumber))
			end
		end
	end

	local zonesRoot = MatchZoneQuery.GetZonesRoot()
	if not zonesRoot then
		table.insert(errors, "Workspace.Map.BattleZone.Runtime.Zones or Runtime.ZoneVariation.*.Zones is missing.")
	else
		for _, zoneName in ipairs({ "Zone01", "Zone02", "Zone03" }) do
			RequireZoneMarker(zoneName, "Area")
			RequireZoneMarker(zoneName, "CarrierPoint")
			RequireZoneMarker(zoneName, "EnemyApproachPoint")
			RequireZoneMarker(zoneName, "ExitPoint")
		end

		RequireZoneMarker("ShootZone", "Area")
		RequireZoneMarker("ShootZone", "CarrierPoint")
		RequireZoneMarker("ShootZone", "GoalTarget")
		RequireZoneMarker("ShootZone", "SaveTarget")
	end

	return #errors == 0, errors
end

function MatchWorldService:KnitStart()
	local spawn = FindPlayerSpawnDeep()
	if spawn then
		cachedPlayerSpawnCFrame = spawn.CFrame
	end
	ConfigureFootballFloor(FindFootballFloorDeep())
	local isValid, errors = self:ValidateSetup()

	if not isValid then
		for _, message in ipairs(errors) do
			warn("[MatchWorldService] " .. message)
		end
	end
end

return MatchWorldService
