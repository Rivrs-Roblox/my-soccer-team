local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchSpawnConfig = require(script.Parent.Parent.Config.Match.MatchSpawnConfig)
local MatchRegionSampler = require(script.Parent.Parent.Helpers.Match.MatchRegionSampler)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)

local MatchSpawnLayoutController = Knit.CreateController({
	Name = "MatchSpawnLayoutController",
	ActiveSessionId = nil,
	SessionCache = {},
	CurrentSeed = 0,
	DebugLayout = false,
})

local MAX_STEP_COUNT = 4
local MAX_ALLY_POINTS = 4
local MAX_ENEMY_POINTS = 4

local function GetAreaCenter(stepIndex)
	local area = MatchZoneQuery.GetZoneArea(stepIndex)
	return area and area.Position or nil
end

local function BuildStepSeed(baseSeed, stepIndex, salt)
	return (tonumber(baseSeed) or 0) + (stepIndex * 1009) + (salt * 7919)
end

function MatchSpawnLayoutController:_debug(message)
	if not self.DebugLayout then
		return
	end

	print(string.format("[MatchSpawnLayout] %s", tostring(message)))
end

function MatchSpawnLayoutController:_buildFallbackPoints(areaCenter, count, radius)
	if not areaCenter then
		return nil
	end

	local result = {}
	local safeRadius = math.max(radius or 6, 2)

	for index = 1, count do
		local angle = ((index - 1) / math.max(count, 1)) * math.pi * 2
		local distanceScale = (index % 2 == 0) and 0.55 or 0.85
		local offset = Vector3.new(
			math.cos(angle) * safeRadius * distanceScale,
			0,
			math.sin(angle) * safeRadius * distanceScale
		)

		result[index] = areaCenter + offset
	end

	return result
end

function MatchSpawnLayoutController:_sampleWorldPointsAroundArea(stepIndex, count, spacing, radiusScale, seedSalt)
	local area = MatchZoneQuery.GetZoneArea(stepIndex)
	if not area then
		self:_debug(string.format("step=%d missing zone area", stepIndex))
		return nil
	end

	local radius = (MatchSpawnConfig.RandomSamplingRadius or 6) * (radiusScale or 1)
	local seed = BuildStepSeed(self.CurrentSeed, stepIndex, seedSalt)

	local points = MatchRegionSampler.SampleRandomPoints(
		area.Position,
		count,
		radius,
		spacing,
		seed
	)

	if not points or #points == 0 then
		self:_debug(string.format("step=%d sampler returned empty, using fallback", stepIndex))
		return self:_buildFallbackPoints(area.Position, count, radius * 0.7)
	end

	if #points < count then
		self:_debug(string.format("step=%d sampler returned partial (%d/%d), padding fallback", stepIndex, #points, count))
		local fallbackPoints = self:_buildFallbackPoints(area.Position, count, radius * 0.7)
		for i = #points + 1, count do
			points[i] = fallbackPoints[i]
		end
	end

	return points
end

function MatchSpawnLayoutController:BeginSession(payload)
	self.SessionCache = {}
	self.CurrentSeed = payload.Seed or os.time()

	for step = 1, MAX_STEP_COUNT do
		self.SessionCache[step] = {
			AllyWorldPositions = self:_sampleWorldPointsAroundArea(
				step,
				MAX_ALLY_POINTS,
				MatchSpawnConfig.MinAllySpacing or 3,
				1.35,
				11
			),
			EnemyWorldPositions = self:_sampleWorldPointsAroundArea(
				step,
				MAX_ENEMY_POINTS,
				MatchSpawnConfig.MinEnemySpacing or MatchSpawnConfig.MinAllySpacing or 3,
				1.65,
				29
			),
			ResolveWorldPositions = self:_sampleWorldPointsAroundArea(
				step,
				MAX_ALLY_POINTS,
				MatchSpawnConfig.MinAllySpacing or 3,
				1.95,
				41
			),
		}
	end

	self:_debug(string.format("BeginSession seed=%s", tostring(self.CurrentSeed)))
end

function MatchSpawnLayoutController:_getWorldPosition(stepIndex, actorIndex, bucketName)
	local stepCache = self.SessionCache[stepIndex]
	if not stepCache then
		return nil
	end

	local bucket = stepCache[bucketName]
	if not bucket then
		return nil
	end

	return bucket[actorIndex]
end

function MatchSpawnLayoutController:GetAllyWorldPosition(stepIndex, actorIndex)
	return self:_getWorldPosition(stepIndex, actorIndex, "AllyWorldPositions")
end

function MatchSpawnLayoutController:GetEnemyWorldPosition(stepIndex, actorIndex)
	return self:_getWorldPosition(stepIndex, actorIndex, "EnemyWorldPositions")
end

function MatchSpawnLayoutController:GetResolveWorldPosition(stepIndex, actorIndex)
	return self:_getWorldPosition(stepIndex, actorIndex, "ResolveWorldPositions")
end

function MatchSpawnLayoutController:GetRandomOffset(stepIndex, actorIndex)
	local worldPosition = self:GetAllyWorldPosition(stepIndex, actorIndex)
	local areaCenter = GetAreaCenter(stepIndex)

	if worldPosition and areaCenter then
		return worldPosition - areaCenter
	end

	return Vector3.zero
end

function MatchSpawnLayoutController:EndSession()
	self.SessionCache = {}
end

function MatchSpawnLayoutController:KnitStart()
	local MatchService = Knit.GetService("MatchService")

	MatchService.MatchSessionStarted:Connect(function(payload)
		self.ActiveSessionId = tostring(payload and payload.SessionId or "")
		self:BeginSession(payload)
	end)

	MatchService.MatchSessionEnded:Connect(function(_, sessionId)
		local endedSessionId = tostring(sessionId or "")
		if endedSessionId ~= "" and self.ActiveSessionId ~= nil and tostring(self.ActiveSessionId) ~= endedSessionId then
			return
		end

		self.ActiveSessionId = nil
		self:EndSession()
	end)
end

return MatchSpawnLayoutController