local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)

local MatchGrounding = {}

local FOOTBALL_FLOOR_NAME = "FootballFloor"
local FOOTBALL_FLOOR_RETRY_SECONDS = 1.0
local FOOTBALL_FLOOR_BOUNDS_PADDING = 4.0

local cachedFootballFloor: BasePart? = nil
local cachedFootballFloorTopY: number? = nil
local cachedFootballFloorCFrame: CFrame? = nil
local cachedFootballFloorHalfX: number? = nil
local cachedFootballFloorHalfZ: number? = nil
local lastFootballFloorLookupAt = -math.huge

local excludeActorsRayParams = RaycastParams.new()
excludeActorsRayParams.FilterType = Enum.RaycastFilterType.Exclude

local reusableExcludeList = {}
local reusableIgnoreFolderNames = {
	"LocalMatchPresentationRuntime",
	"SoccerCharacterInstances",
	"SoccerCharacters",
	"Coaches",
}

local function ResolveFootballFloorInfo(): (number?, CFrame?, number?, number?)
	if
		cachedFootballFloor
		and cachedFootballFloor.Parent
		and cachedFootballFloorTopY ~= nil
		and cachedFootballFloorCFrame ~= nil
		and cachedFootballFloorHalfX ~= nil
		and cachedFootballFloorHalfZ ~= nil
	then
		return cachedFootballFloorTopY, cachedFootballFloorCFrame, cachedFootballFloorHalfX, cachedFootballFloorHalfZ
	end

	local now = os.clock()
	if now - lastFootballFloorLookupAt < FOOTBALL_FLOOR_RETRY_SECONDS then
		return nil
	end

	lastFootballFloorLookupAt = now

	local footballFloor = Workspace:FindFirstChild(FOOTBALL_FLOOR_NAME, true)
	if footballFloor and footballFloor:IsA("BasePart") then
		cachedFootballFloor = footballFloor
		cachedFootballFloorTopY = footballFloor.Position.Y + (footballFloor.Size.Y * 0.5)
		cachedFootballFloorCFrame = footballFloor.CFrame
		cachedFootballFloorHalfX = footballFloor.Size.X * 0.5
		cachedFootballFloorHalfZ = footballFloor.Size.Z * 0.5
		return cachedFootballFloorTopY, cachedFootballFloorCFrame, cachedFootballFloorHalfX, cachedFootballFloorHalfZ
	end

	cachedFootballFloor = nil
	cachedFootballFloorTopY = nil
	cachedFootballFloorCFrame = nil
	cachedFootballFloorHalfX = nil
	cachedFootballFloorHalfZ = nil
	return nil, nil, nil, nil
end

local function IsInsideFootballFloorBounds(worldPos: Vector3, floorCFrame: CFrame, halfX: number, halfZ: number): boolean
	local localPos = floorCFrame:PointToObjectSpace(worldPos)
	return math.abs(localPos.X) <= halfX + FOOTBALL_FLOOR_BOUNDS_PADDING
		and math.abs(localPos.Z) <= halfZ + FOOTBALL_FLOOR_BOUNDS_PADDING
end

function MatchGrounding.GetCharacterRootGroundClearance(character: Model?): number
	if not character then
		return 3.0
	end

	-- Owned SoccerCharacter models are authored with their model pivot at foot
	-- level. Their normal overworld updater also PivotTo()s the ground hit
	-- directly, without a Humanoid/root clearance. Keep the same contract in a
	-- match; adding a calculated clearance here makes companions float.
	if character:GetAttribute("Owner") ~= nil and character:GetAttribute("SoccerCharacter") ~= nil then
		character:SetAttribute("CachedGroundClearance", 0)
		return 0
	end

	--
	local cached = character:GetAttribute("CachedGroundClearance")
	if cached then
		return cached
	end

	local clearance = nil

	-- Only use HipHeight method for real player characters or the local player proxy
	-- to prevent standard players from sinking due to active locomotion animations.
	-- For custom NPCs, enemies, and keepers, we fall back to the visual lowestY method,
	-- because custom rigs often have incorrect or arbitrary HipHeight values.
	local isPlayer = false
	if Players:GetPlayerFromCharacter(character) then
		isPlayer = true
	elseif
		character.Name == "LocalMatchPlayerProxy"
		or character.Name == "PLAYER_PROXY"
		or character.Name == "PlayerProxy"
	then
		isPlayer = true
	end

	if isPlayer then
		local root = character:FindFirstChild("HumanoidRootPart", true) or character.PrimaryPart
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if root and humanoid then
			if humanoid.RigType == Enum.HumanoidRigType.R6 then
				clearance = 2.0 + (root.Size.Y * 0.5) + 0.03
			else
				local hipHeight = math.max(tonumber(humanoid.HipHeight) or 0, 0)
				clearance = hipHeight + (root.Size.Y * 0.5) + 0.03
			end
		end
	end

	if not clearance then
		local pivot = character:GetPivot()
		local lowestY = math.huge

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Transparency < 1 then
				-- Using the static base pose from when this is first called (usually Idle)
				local bottomY = descendant.Position.Y - (descendant.Size.Y * 0.5)
				if bottomY < lowestY then
					lowestY = bottomY
				end
			end
		end

		if lowestY ~= math.huge then
			clearance = math.max(0, pivot.Position.Y - lowestY) + 0.03
		else
			clearance = 3.0
		end
	end

	character:SetAttribute("CachedGroundClearance", clearance)
	return clearance
end

function MatchGrounding.GetGroundedY(worldPos: Vector3, model: Model?, options): number
	options = options or {}
	local clearance = options.Clearance or MatchGrounding.GetCharacterRootGroundClearance(model)
	local pitchTopY, pitchCFrame, pitchHalfX, pitchHalfZ = ResolveFootballFloorInfo()

	if
		pitchTopY ~= nil
		and pitchCFrame ~= nil
		and pitchHalfX ~= nil
		and pitchHalfZ ~= nil
		and IsInsideFootballFloorBounds(worldPos, pitchCFrame, pitchHalfX, pitchHalfZ)
	then
		return pitchTopY + clearance
	end

	table.clear(reusableExcludeList)
	if model then
		table.insert(reusableExcludeList, model)
	end
	if MatchSceneQuery.GetRuntimeRoot then
		local runtimeRoot = MatchSceneQuery.GetRuntimeRoot()
		if runtimeRoot then
			table.insert(reusableExcludeList, runtimeRoot)
		end
	end
	if MatchSceneQuery.GetSpawnedEnemiesFolder then
		local spawnedEnemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder(false)
		if spawnedEnemiesFolder then
			table.insert(reusableExcludeList, spawnedEnemiesFolder)
		end
	end
	if options.ExtraIgnoreInstances then
		for _, instance in ipairs(options.ExtraIgnoreInstances) do
			if instance then
				table.insert(reusableExcludeList, instance)
			end
		end
	end

	-- Exclude all player characters to prevent grounding onto players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(reusableExcludeList, player.Character)
		end
	end

	-- Exclude common folders containing other characters or proxies to avoid grounding on them
	for _, folderName in ipairs(reusableIgnoreFolderNames) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			table.insert(reusableExcludeList, folder)
		end
	end

	excludeActorsRayParams.FilterDescendantsInstances = reusableExcludeList

	-- Start raycast from a fixed height above the pitch (15.0) down to avoid hitting goals if not using Include
	local origin = Vector3.new(worldPos.X, 15.0, worldPos.Z)
	local result = Workspace:Raycast(origin, Vector3.new(0, -30, 0), excludeActorsRayParams)

	if result then
		return result.Position.Y + clearance
	end

	if options.FallbackY ~= nil then
		return options.FallbackY
	end

	return worldPos.Y
end

function MatchGrounding.GetGroundedPosition(worldPos: Vector3, model: Model?, options): Vector3
	return Vector3.new(worldPos.X, MatchGrounding.GetGroundedY(worldPos, model, options), worldPos.Z)
end

function MatchGrounding.GetGroundedCFrame(model: Model?, targetCFrame: CFrame, options): CFrame
	if not targetCFrame then
		return targetCFrame
	end
	local pos = MatchGrounding.GetGroundedPosition(targetCFrame.Position, model, options)
	return CFrame.new(pos) * (targetCFrame - targetCFrame.Position)
end

function MatchGrounding.GetGroundedCharacterRootCFrame(character: Model?, targetCFrame: CFrame, options): CFrame
	options = table.clone(options or {})
	options.Clearance = options.Clearance or MatchGrounding.GetCharacterRootGroundClearance(character)
	return MatchGrounding.GetGroundedCFrame(character, targetCFrame, options)
end

return MatchGrounding
