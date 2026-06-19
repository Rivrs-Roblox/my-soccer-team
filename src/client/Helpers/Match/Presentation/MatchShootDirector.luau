return function(MatchPresentationController, Context)
	local Services = Context.Services
	local Players = Services.Players
	local ReplicatedStorage = Services.ReplicatedStorage
	local RunService = Services.RunService
	local Workspace = Services.Workspace
	local Debris = Services.Debris
	local PhysicsService = Services.PhysicsService
	local ContentProvider = Services.ContentProvider or game:GetService("ContentProvider")

	local Knit = Context.Knit
	local LocalPlayer = Context.LocalPlayer

	local MatchActorResolver = Context.MatchActorResolver
	local MatchSceneQuery = Context.MatchSceneQuery
	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath
	local MatchBallConfig = Context.MatchBallConfig
	local MatchAnimationHelper = Context.MatchAnimationHelper

	local Constants = Context.Constants
	local Utils = Context.Utils

	local PLAYER_PROXY_NAME = Constants.PLAYER_PROXY_NAME
	local PRESENTATION_FOLDER_NAME = Constants.PRESENTATION_FOLDER_NAME
	local ACTION_SPEEDS = Constants.ACTION_SPEEDS
	local THRESHOLDS = Constants.THRESHOLDS
	local PRE_QTE_READY_SETTLE_FRAMES = Constants.PRE_QTE_READY_SETTLE_FRAMES
	local PRE_QTE_READY_EXTRA_EPSILON = Constants.PRE_QTE_READY_EXTRA_EPSILON
	local MOVEMENT_TUNING = Constants.MOVEMENT_TUNING
	local BALL_TRAVEL = Constants.BALL_TRAVEL
	local CUTSCENE_ACTOR_COLLISION_GROUP = Constants.CUTSCENE_ACTOR_COLLISION_GROUP
	local DEFAULT_TIME_SCALE = Constants.DEFAULT_TIME_SCALE
	local APPROACH_FORWARD_PUSH_DISTANCE = Constants.APPROACH_FORWARD_PUSH_DISTANCE
	local APPROACH_MIN_FORWARD_DISTANCE = Constants.APPROACH_MIN_FORWARD_DISTANCE
	local APPROACH_NEAR_TARGET_THRESHOLD = Constants.APPROACH_NEAR_TARGET_THRESHOLD
	local CONTINUOUS_APPROACH_TARGET_DISTANCE = Constants.CONTINUOUS_APPROACH_TARGET_DISTANCE
	local SHADOW_MARK_SPEED = Constants.SHADOW_MARK_SPEED
	local THREAT_ZONE_FALLBACK_RADIUS = Constants.THREAT_ZONE_FALLBACK_RADIUS
	local QTE_TRIGGER_DISTANCE = Constants.QTE_TRIGGER_DISTANCE
	local QTE_TRIGGER_DISTANCE_BUFFER = Constants.QTE_TRIGGER_DISTANCE_BUFFER
	local QTE_FORCE_BOUNDARY_BUFFER = Constants.QTE_FORCE_BOUNDARY_BUFFER
	local QTE_FORCE_BOUNDARY_STEP3_BUFFER = Constants.QTE_FORCE_BOUNDARY_STEP3_BUFFER
	local QTE_FORCE_BOUNDARY_SETTLE_DISTANCE = Constants.QTE_FORCE_BOUNDARY_SETTLE_DISTANCE
	local QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET = Constants.QTE_FORCE_BOUNDARY_SETTLE_LATERAL_OFFSET
	local PRESS_CHASE_STOP_DISTANCE = Constants.PRESS_CHASE_STOP_DISTANCE
	local APPROACH_SEQUENCE_MAX_SECONDS = Constants.APPROACH_SEQUENCE_MAX_SECONDS
	local PRESSURE_SWITCH_DISTANCE = Constants.PRESSURE_SWITCH_DISTANCE
	local PRESSURE_SWITCH_DISTANCE_STEP_1 = Constants.PRESSURE_SWITCH_DISTANCE_STEP_1
	local GOALKEEPER_RUNTIME_SLOT = Constants.GOALKEEPER_RUNTIME_SLOT
	local RECOVERY_CHASE_SPEED = Constants.RECOVERY_CHASE_SPEED
	local RECOVERY_CHASE_STOP_BUFFER = Constants.RECOVERY_CHASE_STOP_BUFFER
	local RECOVERY_CHASE_FACE_TIMEOUT = Constants.RECOVERY_CHASE_FACE_TIMEOUT
	local DEFEATED_ENEMY_RECOVERY_SPEED = Constants.DEFEATED_ENEMY_RECOVERY_SPEED
	local DEFEATED_ENEMY_RECOVERY_DISTANCE = Constants.DEFEATED_ENEMY_RECOVERY_DISTANCE
	local DEFEATED_ENEMY_COVER_FRONT_DISTANCE = Constants.DEFEATED_ENEMY_COVER_FRONT_DISTANCE
	local DEFEATED_ENEMY_MIN_RECOVERY_FORWARD = Constants.DEFEATED_ENEMY_MIN_RECOVERY_FORWARD
	local IDLE_ENEMY_RETREAT_SPEED = Constants.IDLE_ENEMY_RETREAT_SPEED
	local IDLE_ENEMY_RUN_SPEED = Constants.IDLE_ENEMY_RUN_SPEED
	local ALLY_PATROL_SPEED = Constants.ALLY_PATROL_SPEED
	local ALLY_PATROL_SWAY_DISTANCE = Constants.ALLY_PATROL_SWAY_DISTANCE
	local ALLY_PATROL_OSCILLATION_SPEED = Constants.ALLY_PATROL_OSCILLATION_SPEED
	local ENEMY_PATROL_SPEED = Constants.ENEMY_PATROL_SPEED
	local ENEMY_PATROL_SWAY_DISTANCE = Constants.ENEMY_PATROL_SWAY_DISTANCE
	local ENEMY_PATROL_OSCILLATION_SPEED = Constants.ENEMY_PATROL_OSCILLATION_SPEED
	local SHADOW_FOLLOW_DISTANCE = Constants.SHADOW_FOLLOW_DISTANCE
	local SHADOW_LATE_UPDATE_SPEED = Constants.SHADOW_LATE_UPDATE_SPEED
	local SHADOW_LATERAL_OFFSET = Constants.SHADOW_LATERAL_OFFSET
	local POST_PHASE_ADVANCE_SPEED = Constants.POST_PHASE_ADVANCE_SPEED
	local POST_PHASE_ADVANCE_STOP_BUFFER = Constants.POST_PHASE_ADVANCE_STOP_BUFFER
	local POST_PHASE_ADVANCE_MIN_DISTANCE = Constants.POST_PHASE_ADVANCE_MIN_DISTANCE
	local RECEIVER_CATCH_UP_SPEED = Constants.RECEIVER_CATCH_UP_SPEED
	local RECEIVER_MIN_FORWARD_DISTANCE = Constants.RECEIVER_MIN_FORWARD_DISTANCE
	local RECEIVER_NEXT_QTE_BUFFER = Constants.RECEIVER_NEXT_QTE_BUFFER
	local PASS_RECEIVE_LANE_OFFSET = Constants.PASS_RECEIVE_LANE_OFFSET
	local OFF_BALL_RUNNER_FORWARD_DISTANCE = Constants.OFF_BALL_RUNNER_FORWARD_DISTANCE
	local OFF_BALL_RUNNER_LANE_OFFSET = Constants.OFF_BALL_RUNNER_LANE_OFFSET
	local FALLBACK_RUN_ANIMATION_ID = Constants.FALLBACK_RUN_ANIMATION_ID
	local FALLBACK_IDLE_ANIMATION_ID = Constants.FALLBACK_IDLE_ANIMATION_ID
	local MOTION_ANIMATION_CANDIDATES = Constants.MOTION_ANIMATION_CANDIDATES

	local GetRootPart = Utils.GetRootPart
	local ApplyPivot = Utils.ApplyPivot
	local ForceModelVisible = Utils.ForceModelVisible
	local IsEmbeddedBallVisual = Utils.IsEmbeddedBallVisual
	local GetSafeGroundOffset = Utils.GetSafeGroundOffset
	local GetGroundedY = Utils.GetGroundedY
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local StepFlatTowards = Utils.StepFlatTowards
	local MoveTowardsFlat = Utils.MoveTowardsFlat
	local ComputeBallTravelDuration = Utils.ComputeBallTravelDuration
	local BuildStableShootTarget = Utils.BuildStableShootTarget
	local GetActorAdaptiveSpeed = Utils.GetActorAdaptiveSpeed
	local GetEnemyAdaptiveSpeed = Utils.GetEnemyAdaptiveSpeed
	local BuildStableSeed = Utils.BuildStableSeed
	local BuildStableOffset = Utils.BuildStableOffset
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook
	local ClampTargetAhead = Utils.ClampTargetAhead

	local MatchShootTargetResolver = require(script.Parent.MatchShootTargetResolver)
	local MatchShootCinematicDirector = require(script.Parent.MatchShootCinematicDirector)
	local MatchActionFxHelper = require(script.Parent.MatchActionFxHelper)
	local MatchAudioHelper = require(script.Parent.MatchAudioHelper)

	local ClientRootFromPresentation = script.Parent.Parent.Parent.Parent
	local MatchKeeperConfig = require(
		ClientRootFromPresentation
			:WaitForChild("Config")
			:WaitForChild("Match")
			:WaitForChild("MatchKeeperConfig")
	)

function MatchPresentationController:_emitGoalParticles(options)
	options = options or {}
	local useGoldFireworks = options.GoldFireworks == true

	local map = Workspace:FindFirstChild("Map")
	local battleZone = map and map:FindFirstChild("BattleZone")
	if not battleZone then
		return
	end

	local vfxRoot = battleZone:FindFirstChild("GoalVFX")
		or battleZone:FindFirstChild("GoalFx")
		or MatchZoneQuery.GetGoalTarget()

	if not vfxRoot then
		return
	end

	local goldColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 190)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 214, 64)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 20)),
	})

	for _, descendant in ipairs(vfxRoot:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			local emitCount = descendant:GetAttribute("EmitCount")
				or (MatchBallConfig.GoalFx and MatchBallConfig.GoalFx.EmitCount)
				or 24

			if useGoldFireworks then
				local originalColor = descendant.Color
				local originalLightEmission = descendant.LightEmission
				local originalLightInfluence = descendant.LightInfluence

				descendant.Color = goldColor
				descendant.LightEmission = 1
				descendant.LightInfluence = 0
				descendant:Emit(math.max(math.floor(emitCount * 1.8), emitCount + 8))

				task.delay(1.2, function()
					if descendant and descendant.Parent then
						descendant.Color = originalColor
						descendant.LightEmission = originalLightEmission
						descendant.LightInfluence = originalLightInfluence
					end
				end)
			else
				descendant:Emit(emitCount)
			end
		end
	end
end
function MatchPresentationController:_idleAllEnemiesAfterShot()
	self:_forEachEnemyModel(function(spawnedEnemy)
		local enemyRoot = GetRootPart(spawnedEnemy)
		if not enemyRoot then
			return
		end

		local groundedPos = GetGroundedPosition(enemyRoot.Position, spawnedEnemy)
		local lookVector = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
		local lookTarget = groundedPos + lookVector

		ApplyPivot(
			spawnedEnemy,
			MatchMotionMath.BuildFlatLookAtCFrame(groundedPos, lookTarget)
		)

		self:_playMotionAnimation(spawnedEnemy, "Idle", 1.0)
	end)
end

function MatchPresentationController:_startPostShotIdleGuard(durationSeconds)
	self.PostShotLockToken = (self.PostShotLockToken or 0) + 1
	local lockToken = self.PostShotLockToken
	local deadline = os.clock() + math.max(durationSeconds or 1.0, 0.1)

	task.spawn(function()
		while self.CurrentSessionId ~= nil
			and self.PostShotLockToken == lockToken
			and os.clock() < deadline
		do
			self:_idleAllEnemiesAfterShot()
			RunService.RenderStepped:Wait()
		end
	end)
end

function MatchPresentationController:_stopAllFieldMovementAfterShot(actorSlot, shooterModel)
	self.IdleEnemyMotionToken += 1
	self.AllyPatrolMotionToken += 1
	self.PostShotLockToken = (self.PostShotLockToken or 0) + 1
	self:_stopSupportMotion()

	table.clear(self.DefeatedEnemyRecoveryTokens)

	local shooterSlot = tonumber(actorSlot)

	for slotNumber = 2, 4 do
		if slotNumber ~= shooterSlot then
			local actorModel = self:_getControlledActorModel(slotNumber)
			if actorModel and actorModel ~= shooterModel then
				local actorCFrame = self:_getActorCurrentCFrame(slotNumber, actorModel)
				if actorCFrame then
					self:_applyActorCFrame(
						slotNumber,
						actorModel,
						actorCFrame,
						{
							ExpectedAnimation = "Idle",
							FacingMode = "Idle",
							LookAtPosition = actorCFrame.Position + actorCFrame.LookVector,
							MoveSpeed = 0,
						}
					)
					self:_playMotionAnimation(actorModel, "Idle", 1.0)
				end
			end
		end
	end

	self:_idleAllEnemiesAfterShot()
	self:_startPostShotIdleGuard(1.25)
end

function MatchPresentationController:_getEpicShotTravelDuration()
	local epicShotConfig = MatchBallConfig and MatchBallConfig.EpicShot

	if not epicShotConfig then
		return 0.6
	end

	local phase1 = tonumber(epicShotConfig.DurationPhase1) or 0.4
	local phase2 = tonumber(epicShotConfig.DurationPhase2) or 0.2

	return math.max(phase1 + phase2, 0.1)
end


-- Shoot animation is manually directed during cinematic.
-- Do not multiply by global TimeScale here; the camera owns slow-motion timing.
local SHOOT_WINDUP_PLAYBACK_SPEED = 0.20
local SHOOT_FOLLOW_THROUGH_PLAYBACK_SPEED = 0.95
local SHOOT_FOLLOW_THROUGH_SECONDS = 0.42
local SPECIAL_SHOOT_FOLLOW_THROUGH_SECONDS = 0.72
local POST_IMPACT_IDLE_FADE_TIME = 0.04

local SPECIAL_SHOOT_ANIMATION_NAME = "Shoot - Special"
local SPECIAL_SHOOT_MARKER_NAME = "BallRelease"
local SHOOT_RELEASE_MARKER_NAMES = { "BallRelease", "Kick", "Impact", "Shoot", "Hit" }
local NORMAL_SHOOT_MARKER_FALLBACK_SECONDS = 1.35
local SPECIAL_SHOOT_MARKER_FALLBACK_SECONDS = 3.85
local SPECIAL_SHOOT_PROXY_NAME = "MatchSpecialShootEmbeddedBallProxy"
local SPECIAL_SHOOT_PROXY_RENDER_BIND = "MatchSpecialShootEmbeddedBallProxyGuard"
local SPECIAL_SHOOT_PLAYBACK_SPEED = 1.0
local SPECIAL_SHOOT_FALLBACK_MIN_SECONDS = 0.65
local SPECIAL_SHOOT_FALLBACK_MAX_SECONDS = 3.85

local POST_KICK_IDLE_GUARD_DURATION = 1.85
local POST_KICK_IDLE_REFRESH_SECONDS = 0.05
local POST_SHOT_SETTLE_DELAY = 0.20
local RESULT_UI_DELAY = 0.45
local RESULT_FREEZE_FINAL_POSE_OFFSET = 0.04
local RESULT_FREEZE_FALLBACK_SECONDS = 1.15
local SHOOT_CINEMATIC_FREEZE_GUARD_DURATION = 3.5
local KICK_SOUND_ID = "KickHard"
local GOAL_SOUND_ID = "Goal"

-- Goal climax: extra celebration hold before result popup appears
local GOAL_CELEBRATION_EXTRA_HOLD = 1.5
local GOAL_CAMERA_SHAKE_STRENGTH = 1.65
local GOAL_CAMERA_SHAKE_DURATION = 0.55

local SHOOT_ANIMATION_NAMES = {
	["Shoot"] = true,
	["Shoot - Training"] = true,
	["Shoot - Penalty"] = true,
	["Shoot - Special"] = true,
	["CinematicShoot"] = true,
}

local SHOOT_PRELOAD_ANIMATION_NAMES = {
	"Shoot",
	"Shoot - Training",
	"Shoot - Penalty",
	"Shoot - Special",
	"Win1",
	"Win2",
	"Win",
	"Lose1",
	"Lose2",
	"Lose",
}

local function playOneShotSound(soundId, volume, lifetime, worldPosition)
	return MatchAudioHelper.PlaySoundId(soundId, {
		Volume = volume or 1,
		Lifetime = lifetime or 3,
		WorldPosition = worldPosition,
	})
end

local function playMatchSound(key, options)
	return MatchAudioHelper.PlayKey(key, options or {})
end

local function getAnimationFromFolder(model, animationName)
	local animFolder = model and (model:FindFirstChild("Animations") or model:FindFirstChild("Animations", true))
	if not animFolder then
		return nil
	end

	local anim = animFolder:FindFirstChild(animationName)
	if anim and anim:IsA("Animation") then
		return anim
	end

	return nil
end

local function getShootAnimationObject(model, preferSpecial)
	if preferSpecial then
		local specialAnim = getAnimationFromFolder(model, SPECIAL_SHOOT_ANIMATION_NAME)
		if specialAnim then
			return specialAnim, SPECIAL_SHOOT_ANIMATION_NAME, true
		end
	end

	local normalAnim = getAnimationFromFolder(model, "Shoot")
	if normalAnim then
		return normalAnim, "Shoot", false
	end
	
	-- Fallback hardcoded ID if folder missing
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://90962989306225"
	return anim, "FallbackShoot", false
end

local function hasSpecialShootAnimation(model)
	return getAnimationFromFolder(model, SPECIAL_SHOOT_ANIMATION_NAME) ~= nil
end

local function addAnimationAsset(assets, seenAssets, animationObject)
	if not animationObject or not animationObject:IsA("Animation") then
		return
	end

	local animationId = tostring(animationObject.AnimationId or "")
	local key = if animationId ~= "" then animationId else animationObject
	if seenAssets[key] then
		return
	end

	seenAssets[key] = true
	table.insert(assets, animationObject)
end

function MatchPresentationController:_preloadShootAnimationAssets()
	local assets = {}
	local seenAssets = {}

	for slotNumber = 1, 4 do
		local model = self:_getControlledActorModel(slotNumber)
		if model then
			for _, animationName in ipairs(SHOOT_PRELOAD_ANIMATION_NAMES) do
				addAnimationAsset(assets, seenAssets, getAnimationFromFolder(model, animationName))
			end
		end
	end

	if #assets <= 0 then
		return
	end

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
	end)
end

local function getSpecialShootFallbackImpactDelay(track)
	local length = 0
	local deadline = os.clock() + 0.35

	while os.clock() < deadline do
		pcall(function()
			length = tonumber(track and track.Length) or 0
		end)

		if length > 0 then
			break
		end

		RunService.RenderStepped:Wait()
	end

	-- Special shoot must be marker-owned. This fallback is emergency only.
	-- If first-run asset/marker loading is late, never release during the early foot plant.
	if length <= 0 then
		return SPECIAL_SHOOT_FALLBACK_MAX_SECONDS
	end

	return math.clamp(
		length + 0.25,
		SPECIAL_SHOOT_FALLBACK_MIN_SECONDS,
		SPECIAL_SHOOT_FALLBACK_MAX_SECONDS
	)
end

local RESULT_ANIMATION_NAMES = {
	Win = true,
	Win1 = true,
	Win2 = true,
	Lose = true,
	Lose1 = true,
	Lose2 = true,
	ForcedMatchWin = true,
	ForcedMatchLose = true,
}

local IDLE_ANIMATION_NAMES = {
	Idle = true,
	Idle1 = true,
	Stand = true,
	ForcedPostKickIdle = true,
}

local RESULT_CANDIDATES = {
	Win = { "Win1", "Win2", "Win" },
	Lose = { "Lose1", "Lose2", "Lose" },
}

local FALLBACK_ANIMATION_IDS = {
	Idle = "rbxassetid://507766388",
}

local function getTrackIdentity(track)
	local animation = track and track.Animation
	local trackName = track and tostring(track.Name or "") or ""
	local animationName = animation and tostring(animation.Name or "") or ""
	local animationId = animation and tostring(animation.AnimationId or "") or ""
	local lower = string.lower(table.concat({ trackName, animationName, animationId }, "|"))

	return trackName, animationName, animationId, lower
end

local function isTrackPriorityAtLeast(track, minimumPriority)
	if not track or not track.Priority or not minimumPriority then
		return false
	end

	return track.Priority.Value >= minimumPriority.Value
end

local function isIdleTrack(track)
	local trackName, animationName, _, lower = getTrackIdentity(track)

	return IDLE_ANIMATION_NAMES[trackName] == true
		or IDLE_ANIMATION_NAMES[animationName] == true
		or lower:find("idle") ~= nil
		or lower:find("stand") ~= nil
end

local function isResultTrack(track)
	local trackName, animationName, _, lower = getTrackIdentity(track)

	return RESULT_ANIMATION_NAMES[trackName] == true
		or RESULT_ANIMATION_NAMES[animationName] == true
		or lower:find("win") ~= nil
		or lower:find("lose") ~= nil
end

local function isShootTrack(track)
	local trackName, animationName, animationId, lower = getTrackIdentity(track)

	return SHOOT_ANIMATION_NAMES[trackName] == true
		or SHOOT_ANIMATION_NAMES[animationName] == true
		or lower:find("shoot") ~= nil
		or lower:find("cinematic") ~= nil
		or trackName == "CinematicShoot"
		or animationId == "rbxassetid://90962989306225"
end

local function hardStopTrack(track, fadeTime)
	if not track then
		return
	end

	pcall(function()
		track.Looped = false
	end)

	pcall(function()
		track:AdjustSpeed(0)
	end)

	pcall(function()
		track:Stop(fadeTime or 0)
	end)
end

local function stopShootAnimationTracks(actorModel, fadeTime)
	if not actorModel then
		return 0
	end

	local animator = actorModel:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return 0
	end

	local stopFadeTime = tonumber(fadeTime)
	if stopFadeTime == nil then
		stopFadeTime = 0
	end

	local stoppedCount = 0

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if isShootTrack(track) then
			hardStopTrack(track, stopFadeTime)
			stoppedCount += 1
		end
	end

	return stoppedCount
end

local function stopNonIdleShooterTracks(actorModel, fadeTime, keepResult)
	if not actorModel then
		return 0
	end

	local animator = actorModel:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return 0
	end

	local stoppedCount = 0
	local stopFadeTime = tonumber(fadeTime) or 0

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		local shouldKeep = false

		if keepResult and isResultTrack(track) then
			shouldKeep = true
		elseif isIdleTrack(track) and not isTrackPriorityAtLeast(track, Enum.AnimationPriority.Action) then
			shouldKeep = true
		end

		if not shouldKeep then
			-- For post-shoot cleanup we intentionally kill all non-idle action tracks,
			-- not only named Shoot tracks. Some imported rigs expose generic track names,
			-- so name-based stop alone can miss the real kick animation.
			hardStopTrack(track, stopFadeTime)
			stoppedCount += 1
		end
	end

	return stoppedCount
end

local function resetAnimationStateForModel(self, actorModel)
	if self.AnimationStates and actorModel then
		self.AnimationStates[actorModel] = nil
	end
end

local function resolveAnimationObject(actorModel, candidates, fallbackAnimationId)
	local animFolder = actorModel and (actorModel:FindFirstChild("Animations") or actorModel:FindFirstChild("Animations", true))

	if animFolder then
		for _, candidateName in ipairs(candidates or {}) do
			local animationObject = animFolder:FindFirstChild(candidateName)
			if animationObject and animationObject:IsA("Animation") then
				return animationObject, candidateName, false
			end
		end
	end

	if type(fallbackAnimationId) == "string" and fallbackAnimationId ~= "" then
		local animationObject = Instance.new("Animation")
		animationObject.AnimationId = fallbackAnimationId
		return animationObject, "Fallback", true
	end

	return nil, nil, false
end

local function playDirectRigAnimation(actorModel, candidates, fallbackAnimationId, trackName, priority, looped, speed, fadeTime)
	if not actorModel then
		return nil
	end

	local animator = actorModel:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return nil
	end

	local animationObject, resolvedName, shouldDestroy = resolveAnimationObject(actorModel, candidates, fallbackAnimationId)
	if not animationObject then
		return nil
	end

	local ok, track = pcall(function()
		return animator:LoadAnimation(animationObject)
	end)

	if shouldDestroy then
		animationObject:Destroy()
	end

	if not ok or not track then
		return nil
	end

	track.Name = trackName or resolvedName or "ForcedMatchAnimation"

	pcall(function()
		track.Priority = priority or Enum.AnimationPriority.Action
	end)

	track.Looped = looped == true
	track:Play(fadeTime or 0.03)
	track:AdjustSpeed(speed or 1.0)

	return track
end

local function stopForcedPostKickIdleTrack(self)
	local track = self.ForcedPostKickIdleTrack
	self.ForcedPostKickIdleTrack = nil

	if track then
		hardStopTrack(track, 0)
	end
end

local function forceShooterIdleNow(self, actorModel)
	if not actorModel then
		return
	end

	stopShootAnimationTracks(actorModel, 0)
	stopNonIdleShooterTracks(actorModel, 0, false)

	resetAnimationStateForModel(self, actorModel)
	stopForcedPostKickIdleTrack(self)

	local idleTrack = playDirectRigAnimation(
		actorModel,
		{ "Idle", "Idle1", "Stand" },
		FALLBACK_ANIMATION_IDS.Idle,
		"ForcedPostKickIdle",
		Enum.AnimationPriority.Action3,
		true,
		1.0,
		0.02
	)

	self.ForcedPostKickIdleTrack = idleTrack
end

local function startShooterPostKickIdleGuard(self, sessionId, actorModel)
	if not actorModel then
		return nil
	end

	self.ShooterPostKickIdleToken = (self.ShooterPostKickIdleToken or 0) + 1
	local idleToken = self.ShooterPostKickIdleToken
	local deadline = os.clock() + POST_KICK_IDLE_GUARD_DURATION

	forceShooterIdleNow(self, actorModel)

	task.spawn(function()
		local nextRefreshAt = 0

		while self:_isSessionActive(sessionId)
			and self.ShooterPostKickIdleToken == idleToken
			and actorModel.Parent ~= nil
			and os.clock() < deadline
		do
			if os.clock() >= nextRefreshAt then
				forceShooterIdleNow(self, actorModel)
				nextRefreshAt = os.clock() + POST_KICK_IDLE_REFRESH_SECONDS
			end

			RunService.RenderStepped:Wait()
		end
	end)

	return function()
		if self.ShooterPostKickIdleToken == idleToken then
			self.ShooterPostKickIdleToken += 1
		end
	end
end

local function requestNpcSupporterGoalCheer(self, payload, reason)
	if not self or not self.NpcSupporterCheerController then
		return
	end

	if type(payload) ~= "table" then
		return
	end

	if payload.Action ~= "Shoot" or payload.Succeeded ~= true then
		return
	end

	local cheerPayload = {
		Action = "Shoot",
		Succeeded = true,
		IsGoal = true,
		SessionId = payload.SessionId,
		StepIndex = payload.StepIndex,
		ActorSlot = payload.ActorSlot,
		AreaId = payload.AreaId,
		QteTier = payload.QteTier,
		Reason = reason or "ShootResultAnimationGoal",
	}

	local ok, err = pcall(function()
		self.NpcSupporterCheerController:RequestGoalCheer(cheerPayload)
	end)

	if not ok then
		warn("[NpcSupporterCheer] Failed to request goal cheer:", err)
	end

	-- Delay the UI score increment until this moment (when the ball actually reaches the net)
	if self.MatchUIController and self.MatchUIController.IncrementMatchScore then
		self.MatchUIController:IncrementMatchScore(payload.AwardedGoals or 1, payload)
	end

	if self.MatchService and self.MatchService.NotifyGoalCinematicClimax then
		self.MatchService:NotifyGoalCinematicClimax(payload.SessionId)
	end
end

local function playForcedResultAnimation(self, actorModel, success, shouldLoop)
	if not actorModel then
		return nil
	end

	stopForcedPostKickIdleTrack(self)
	stopShootAnimationTracks(actorModel, 0)
	stopNonIdleShooterTracks(actorModel, 0, false)
	resetAnimationStateForModel(self, actorModel)

	local resultName = success and "Win" or "Lose"
	local resultTrack = playDirectRigAnimation(
		actorModel,
		RESULT_CANDIDATES[resultName],
		nil,
		success and "ForcedMatchWin" or "ForcedMatchLose",
		Enum.AnimationPriority.Action4,
		shouldLoop == true,
		1.0,
		0.03
	)

	if not resultTrack then
		resultTrack = self:_playRigAnimation(actorModel, resultName, 1.0, 0.03)
	end

	if resultTrack then
		pcall(function()
			resultTrack.Looped = shouldLoop == true
		end)

		pcall(function()
			resultTrack.Priority = Enum.AnimationPriority.Action4
		end)

		pcall(function()
			resultTrack:AdjustSpeed(1.0)
		end)
	end

	return resultTrack
end

local function freezeResultTrackAtFinalPose(self, sessionId, resultTrack)
	if not resultTrack then
		return
	end

	task.spawn(function()
		local length = 0
		local lengthDeadline = os.clock() + 0.45

		while os.clock() < lengthDeadline do
			pcall(function()
				length = tonumber(resultTrack.Length) or 0
			end)

			if length > 0 then
				break
			end

			RunService.RenderStepped:Wait()
		end

		local freezeDelay = RESULT_FREEZE_FALLBACK_SECONDS
		if length > 0 then
			freezeDelay = math.max(length - RESULT_FREEZE_FINAL_POSE_OFFSET, 0.08)
		end

		local startedAt = os.clock()
		while self:_isSessionActive(sessionId)
			and self.ActiveShooterResultTrack == resultTrack
			and os.clock() - startedAt < freezeDelay
		do
			RunService.RenderStepped:Wait()
		end

		if not self:_isSessionActive(sessionId) then
			return
		end

		if self.ActiveShooterResultTrack ~= resultTrack then
			return
		end

		pcall(function()
			resultTrack.Looped = false
			resultTrack:AdjustSpeed(0)

			if length > 0 then
				resultTrack.TimePosition = math.max(length - RESULT_FREEZE_FINAL_POSE_OFFSET, 0)
			end
		end)
	end)
end

local function playShooterResultOneShot(self, sessionId, actorModel, success)
	if not actorModel then
		return nil
	end

	if self.ActiveShooterResultAnimationCleanup then
		self.ActiveShooterResultAnimationCleanup()
		self.ActiveShooterResultAnimationCleanup = nil
	end

	local resultTrack = playForcedResultAnimation(self, actorModel, success, false)
	self.ActiveShooterResultTrack = resultTrack

	if resultTrack then
		freezeResultTrackAtFinalPose(self, sessionId, resultTrack)
	end

	local function cleanupResultAnimationGuard()
		if resultTrack then
			pcall(function()
				if resultTrack.IsPlaying then
					resultTrack:Stop(0.08)
				end
			end)
		end

		if self.ActiveShooterResultTrack == resultTrack then
			self.ActiveShooterResultTrack = nil
		end

		if self.ActiveShooterResultAnimationCleanup == cleanupResultAnimationGuard then
			self.ActiveShooterResultAnimationCleanup = nil
		end
	end

	self.ActiveShooterResultAnimationCleanup = cleanupResultAnimationGuard

	return cleanupResultAnimationGuard
end

local function getAnimationReleaseMarkers(_, candidateNames, _)
	local results = {}
	for _, markerName in ipairs(candidateNames or {}) do
		local name = tostring(markerName or "")
		if name ~= "" and not table.find(results, name) then
			table.insert(results, name)
		end
	end

	return results
end

local function playShootAnimation(self, actorModel, speedMultiplier, options)
	if not actorModel then
		return nil
	end

	options = options or {}

	if self.FrozenRigModels then
		self.FrozenRigModels[actorModel] = nil
	end

	if self.AnimationStates then
		self.AnimationStates[actorModel] = nil
	end

	stopShootAnimationTracks(actorModel, 0)

	local animator = actorModel:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return nil
	end

	local animObj, resolvedName, isSpecialShoot = getShootAnimationObject(actorModel, options.UseSpecial == true)
	if not animObj then
		return nil
	end

	if isSpecialShoot then
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({ animObj })
			end)
		end)
	end

	local ok, track = pcall(function()
		return animator:LoadAnimation(animObj)
	end)

	if not ok or not track then
		return nil
	end

	track.Name = isSpecialShoot and "CinematicSpecialShoot" or "CinematicShoot"
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false

	local markerConnections = {}
	local markerConnected = false
	local markerFired = false
	local onMarker = options.OnImpactMarker or options.OnSpecialImpactMarker

	if type(onMarker) == "function" then
		local markerNames = isSpecialShoot
			and getAnimationReleaseMarkers(animObj, { SPECIAL_SHOOT_MARKER_NAME }, true)
			or getAnimationReleaseMarkers(animObj, SHOOT_RELEASE_MARKER_NAMES, false)

		local function connectMarker(markerName)
			local signalOk, markerSignal = pcall(function()
				return track:GetMarkerReachedSignal(markerName)
			end)

			if signalOk and markerSignal then
				local connection = markerSignal:Connect(function(parameter)
					if markerFired then
						return
					end

					markerFired = true
					onMarker(parameter)
				end)

				table.insert(markerConnections, connection)
				markerConnected = true
			end
		end

		for _, markerName in ipairs(markerNames) do
			connectMarker(markerName)
		end
	end

	-- Marker connection must be established before Play().
	track:Play(0.04)

	if isSpecialShoot then
		track:AdjustSpeed(SPECIAL_SHOOT_PLAYBACK_SPEED)
		pcall(function()
			track.TimePosition = 0
		end)

		return {
			Track = track,
			AnimationName = resolvedName,
			IsSpecialShoot = true,
			ImpactMarkerName = SPECIAL_SHOOT_MARKER_NAME,
			MarkerConnected = markerConnected,
			MarkerConnection = markerConnections,
			WaitForExternalImpact = markerConnected,
			ExpectedImpactDelay = math.max(getSpecialShootFallbackImpactDelay(track), SPECIAL_SHOOT_MARKER_FALLBACK_SECONDS),
		}
	end

	local windupSpeed = SHOOT_WINDUP_PLAYBACK_SPEED * (speedMultiplier or 1.0)
	track:AdjustSpeed(windupSpeed)

	pcall(function()
		track.TimePosition = 0.05
	end)

	return {
		Track = track,
		AnimationName = resolvedName,
		IsSpecialShoot = false,
		MarkerConnected = markerConnected,
		MarkerConnection = markerConnections,
		WaitForExternalImpact = false,
		ExpectedImpactDelay = nil,
	}
end

local function setOfficialBallAtPosition(self, worldPosition)
	if typeof(worldPosition) ~= "Vector3" then
		return
	end

	if not self.MatchBallController then
		return
	end

	if self.MatchBallController._spawnBallIfNeeded then
		pcall(function()
			self.MatchBallController:_spawnBallIfNeeded()
		end)
	end

	if self.MatchBallController.SetBallWorldPosition then
		self.MatchBallController:SetBallWorldPosition(worldPosition)
	end
end

local function getOfficialBallPosition(self, fallbackPosition)
	if self.MatchBallController and self.MatchBallController.GetBallPosition then
		local ok, ballPosition = pcall(function()
			return self.MatchBallController:GetBallPosition()
		end)

		if ok and typeof(ballPosition) == "Vector3" then
			return ballPosition
		end
	end

	return fallbackPosition
end

local function isActorEmbeddedFootballPart(part)
	if not part or not part:IsA("BasePart") then
		return false
	end

	local loweredPartName = string.lower(part.Name)
	if loweredPartName == "football" or loweredPartName == "soccerball" or loweredPartName == "matchball" then
		return true
	end

	local current = part
	while current do
		local loweredName = string.lower(current.Name)
		if loweredName == "football" or loweredName == "ballroot" then
			return true
		end
		current = current.Parent
	end

	-- Final compatibility fallback for older character rigs.
	return IsEmbeddedBallVisual and IsEmbeddedBallVisual(part) == true
end

local function forEachActorEmbeddedBallPart(actorModel, callback)
	if not actorModel or type(callback) ~= "function" then
		return 0
	end

	local visited = {}
	local count = 0

	local function visitPart(part)
		if not part or not part:IsA("BasePart") or visited[part] then
			return
		end

		visited[part] = true
		count += 1
		callback(part)
	end

	-- Preferred path used by the current character assets:
	-- CharacterModel/Football/BallRoot/Ball
	local footballRoot = actorModel:FindFirstChild("Football", true)
	if footballRoot then
		if footballRoot:IsA("BasePart") then
			visitPart(footballRoot)
		end

		for _, descendant in ipairs(footballRoot:GetDescendants()) do
			if descendant:IsA("BasePart") then
				visitPart(descendant)
			end
		end
	end

	-- Fallback scan. This covers older rigs where the ball is directly named Ball.
	for _, descendant in ipairs(actorModel:GetDescendants()) do
		if descendant:IsA("BasePart") and isActorEmbeddedFootballPart(descendant) then
			visitPart(descendant)
		end
	end

	return count
end

local function setActorEmbeddedBallVisualsHidden(actorModel, hidden)
	local hiddenFlag = hidden == true
	local changedCount = forEachActorEmbeddedBallPart(actorModel, function(part)
		part.LocalTransparencyModifier = hiddenFlag and 1 or 0
		part.Transparency = hiddenFlag and 1 or 0
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = hiddenFlag ~= true
	end)

	return changedCount
end

local function getActorEmbeddedBallPrimaryPart(actorModel)
	local selectedPart = nil

	forEachActorEmbeddedBallPart(actorModel, function(part)
		if selectedPart then
			return
		end

		local loweredName = string.lower(part.Name)
		if loweredName == "ball" or loweredName == "football" or loweredName == "soccerball" or loweredName == "matchball" then
			selectedPart = part
		end
	end)

	if not selectedPart then
		forEachActorEmbeddedBallPart(actorModel, function(part)
			if not selectedPart then
				selectedPart = part
			end
		end)
	end

	return selectedPart
end

local function getActorEmbeddedBallWorldPosition(actorModel)
	local selectedPart = getActorEmbeddedBallPrimaryPart(actorModel)
	return selectedPart and selectedPart.Position or nil
end

local function destroySpecialEmbeddedBallProxy(self)
	RunService:UnbindFromRenderStep(SPECIAL_SHOOT_PROXY_RENDER_BIND)

	if self.SpecialShootEmbeddedBallProxy and self.SpecialShootEmbeddedBallProxy.Parent then
		self.SpecialShootEmbeddedBallProxy:Destroy()
	end

	self.SpecialShootEmbeddedBallProxy = nil
	self.SpecialShootEmbeddedBallSourcePart = nil
end

local function stripProxyRuntimeObjects(proxyPart)
	for _, descendant in ipairs(proxyPart:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("JointInstance")
			or descendant:IsA("Constraint")
		then
			descendant:Destroy()
		end
	end
end

local function createSpecialEmbeddedBallProxy(self, sourcePart)
	destroySpecialEmbeddedBallProxy(self)

	if not sourcePart or not sourcePart:IsA("BasePart") then
		return nil
	end

	local proxyPart = sourcePart:Clone()
	proxyPart.Name = SPECIAL_SHOOT_PROXY_NAME
	stripProxyRuntimeObjects(proxyPart)

	proxyPart.Anchored = true
	proxyPart.CanCollide = false
	proxyPart.CanTouch = false
	proxyPart.CanQuery = false
	proxyPart.Massless = true
	proxyPart.CastShadow = true
	proxyPart.Transparency = 0
	proxyPart.LocalTransparencyModifier = 0
	proxyPart.CFrame = sourcePart.CFrame
	proxyPart:SetAttribute("MatchSpecialEmbeddedBallProxy", true)

	-- Parent outside BattleZone so MatchBallController world-ball hiding never sees it.
	proxyPart.Parent = Workspace.CurrentCamera or Workspace

	self.SpecialShootEmbeddedBallProxy = proxyPart
	self.SpecialShootEmbeddedBallSourcePart = sourcePart

	return proxyPart
end

local function getSpecialEmbeddedBallReleaseCFrame(self, actorModel)
	local proxyPart = self.SpecialShootEmbeddedBallProxy
	if proxyPart and proxyPart.Parent then
		return proxyPart.CFrame
	end

	local sourcePart = self.SpecialShootEmbeddedBallSourcePart
	if sourcePart and sourcePart.Parent then
		return sourcePart.CFrame
	end

	local embeddedPart = getActorEmbeddedBallPrimaryPart(actorModel)
	return embeddedPart and embeddedPart.CFrame or nil
end

local function getSpecialEmbeddedBallReleasePosition(self, actorModel)
	local releaseCFrame = getSpecialEmbeddedBallReleaseCFrame(self, actorModel)
	return releaseCFrame and releaseCFrame.Position or getActorEmbeddedBallWorldPosition(actorModel)
end

local function startSpecialEmbeddedBallVisibilityGuard(self, sessionId, actorModel)
	self.SpecialShootEmbeddedBallToken = (self.SpecialShootEmbeddedBallToken or 0) + 1
	local visibilityToken = self.SpecialShootEmbeddedBallToken

	local sourcePart = getActorEmbeddedBallPrimaryPart(actorModel)
	local proxyPart = createSpecialEmbeddedBallProxy(self, sourcePart)

	-- Source ball is still animated by the artist track, but stays hidden.
	-- The proxy copies its CFrame after other character-update systems run.
	setActorEmbeddedBallVisualsHidden(actorModel, true)

	RunService:UnbindFromRenderStep(SPECIAL_SHOOT_PROXY_RENDER_BIND)
	RunService:BindToRenderStep(
		SPECIAL_SHOOT_PROXY_RENDER_BIND,
		Enum.RenderPriority.Last.Value + 1000,
		function()
			if not self:_isSessionActive(sessionId)
				or self.SpecialShootEmbeddedBallToken ~= visibilityToken
				or not actorModel
				or not actorModel.Parent
				or not sourcePart
				or not sourcePart.Parent
				or not proxyPart
				or not proxyPart.Parent
			then
				destroySpecialEmbeddedBallProxy(self)
				return
			end

			-- Win the visibility race against SoccerCharacters Update/world-ball hiding.
			setActorEmbeddedBallVisualsHidden(actorModel, true)

			proxyPart.CFrame = sourcePart.CFrame
			proxyPart.Size = sourcePart.Size
			proxyPart.Color = sourcePart.Color
			proxyPart.Material = sourcePart.Material
			proxyPart.Transparency = 0
			proxyPart.LocalTransparencyModifier = 0
			proxyPart.CanCollide = false
			proxyPart.CanTouch = false
			proxyPart.CanQuery = false
		end
	)

	return function(shouldHide)
		if self.SpecialShootEmbeddedBallToken == visibilityToken then
			self.SpecialShootEmbeddedBallToken += 1
		end

		destroySpecialEmbeddedBallProxy(self)

		if shouldHide ~= false then
			setActorEmbeddedBallVisualsHidden(actorModel, true)
		end
	end
end

local function setOfficialBallVisible(self, isVisible)
	local ballController = self.MatchBallController
	if not ballController then
		return
	end

	-- Important: do not spawn the official runtime ball while hiding it.
	-- Spawning can trigger world-ball hiding and re-hide the embedded Football/BallRoot prop.
	if isVisible == true then
		if (not ballController.BallInstance or not ballController.BallInstance.Parent)
			and ballController._spawnBallIfNeeded
		then
			pcall(function()
				ballController:_spawnBallIfNeeded()
			end)
		end
	end

	if ballController._setBallVisible then
		pcall(function()
			ballController:_setBallVisible(isVisible == true)
		end)
	end
end

local function hideActorEmbeddedBall(self, actorModel)
	if not actorModel then
		return
	end

	if self._setEmbeddedBallVisualsHidden then
		self:_setEmbeddedBallVisualsHidden(actorModel, true)
		return
	end

	setActorEmbeddedBallVisualsHidden(actorModel, true)
end

local function getShootTier(self)
	if self.MatchUIController and self.MatchUIController.GetLastConfirmedTier then
		return self.MatchUIController:GetLastConfirmedTier() or "Yellow"
	end

	return "Yellow"
end

local function resolveShotTarget(payload, success, shootTier)
	local selectedShotTarget = MatchShootTargetResolver.SelectShotTarget({
		SessionId = payload.SessionId,
		StepIndex = payload.StepIndex,
		ActorSlot = payload.ActorSlot,
		ShootTier = shootTier,
		IsGoal = success,
	})

	if selectedShotTarget and typeof(selectedShotTarget.Position) == "Vector3" then
		return selectedShotTarget, selectedShotTarget.Position
	end

	local fallbackTargetPart = success
		and (MatchZoneQuery.GetGoalTarget() or MatchZoneQuery.GetSaveTarget())
		or (MatchZoneQuery.GetSaveTarget() or MatchZoneQuery.GetGoalTarget())

	return nil, BuildStableShootTarget(fallbackTargetPart, success, shootTier)
end

local function getShotTargetSideSign(shotTargetId, startPos, shotTargetPos)
	local targetId = string.lower(tostring(shotTargetId or ""))
	if targetId:find("left") then
		return -1
	end

	if targetId:find("right") then
		return 1
	end

	local goalDirection = MatchMotionMath.GetFlatDirection(startPos, shotTargetPos)
	if goalDirection.Magnitude <= 0.001 then
		return 0
	end

	local right = goalDirection:Cross(Vector3.yAxis)
	if right.Magnitude <= 0.001 then
		return 0
	end

	local toTarget = shotTargetPos - startPos
	local dot = toTarget:Dot(right.Unit)
	if math.abs(dot) <= 0.25 then
		return 0
	end

	return dot < 0 and -1 or 1
end

local function resolveKeeperBaseCFrame()
	local keeperPoint = MatchShootTargetResolver.GetKeeperPoint and MatchShootTargetResolver.GetKeeperPoint()
		or MatchZoneQuery.GetKeeperEngagePoint()
		or MatchZoneQuery.GetSaveTarget()
		or MatchZoneQuery.GetGoalTarget()

	return keeperPoint and keeperPoint.CFrame or nil
end

local function buildSaveInterceptPosition(startPos, shotTargetPos, shotTargetId)
	-- Explicit map-authored keeper save points are the source of truth for failed shots.
	-- This keeps the ball, keeper dive, and hand contact on the same marker instead of
	-- relying on estimated block offsets.
	if MatchShootTargetResolver.GetKeeperSaveTarget then
		local keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
		if keeperSaveTarget and typeof(keeperSaveTarget.Position) == "Vector3" then
			return keeperSaveTarget.Position
		end
	end

	local keeperCFrame = resolveKeeperBaseCFrame()
	if not keeperCFrame then
		local toTarget = shotTargetPos - startPos
		if toTarget.Magnitude <= 0.001 then
			return shotTargetPos
		end

		local interceptDistance = MatchBallConfig.SaveInterceptDistance
			or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveInterceptDistance)
			or 1.15

		return shotTargetPos - (toTarget.Unit * interceptDistance)
	end

	local keeperPos = keeperCFrame.Position
	local forward = MatchMotionMath.GetFlatDirection(keeperPos, startPos)
	if forward.Magnitude <= 0.001 then
		forward = MatchMotionMath.GetFlatDirection(keeperPos, shotTargetPos)
	end
	if forward.Magnitude <= 0.001 then
		forward = Vector3.new(0, 0, -1)
	end

	local right = forward:Cross(Vector3.yAxis)
	if right.Magnitude <= 0.001 then
		right = Vector3.xAxis
	else
		right = right.Unit
	end

	local sideSign = getShotTargetSideSign(shotTargetId, startPos, shotTargetPos)
	local toRawTarget = shotTargetPos - keeperPos
	local rawLateral = toRawTarget:Dot(right)
	local lateralMagnitude = math.abs(rawLateral)

	local lateralMax = MatchBallConfig.SaveBlockLateralMax
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockLateralMax)
		or 6.75

	local sideMagnitude = math.clamp(lateralMagnitude, 0, lateralMax)
	if sideSign == 0 then
		sideMagnitude = 0
	else
		sideMagnitude = math.max(sideMagnitude, MatchBallConfig.SaveSideMin or 1.15)
	end

	local forwardDistance = MatchBallConfig.SaveBlockForward
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockForward)
		or 2.15

	local targetId = string.lower(tostring(shotTargetId or ""))
	local lowHeight = MatchBallConfig.SaveBlockHeightLow
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockHeightLow)
		or 1.2
	local centerHeight = MatchBallConfig.SaveBlockHeightCenter
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockHeightCenter)
		or 1.55
	local highHeight = MatchBallConfig.SaveBlockHeightHigh
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockHeightHigh)
		or 2.45
	local maxHeight = MatchBallConfig.SaveBlockHeightMax
		or (MatchBallConfig.EpicShot and MatchBallConfig.EpicShot.SaveBlockHeightMax)
		or 2.85

	local blockHeight = centerHeight
	if targetId:find("high") then
		blockHeight = highHeight
	elseif targetId:find("low") then
		blockHeight = lowHeight
	else
		blockHeight = math.clamp(toRawTarget.Y, lowHeight, maxHeight)
	end

	return keeperPos
		+ (right * sideSign * sideMagnitude)
		+ (forward * forwardDistance)
		+ Vector3.new(0, blockHeight, 0)
end

local function getNestedConfigValue(primaryKey, nestedKey, fallback)
	if MatchBallConfig[primaryKey] ~= nil then
		return MatchBallConfig[primaryKey]
	end

	local epicShotConfig = MatchBallConfig.EpicShot
	if type(epicShotConfig) == "table" and epicShotConfig[nestedKey or primaryKey] ~= nil then
		return epicShotConfig[nestedKey or primaryKey]
	end

	return fallback
end


local function isCenterShotTarget(shotTargetId)
	local targetId = string.lower(tostring(shotTargetId or ""))

	return targetId == ""
		or targetId == "center"
		or targetId:find("center") ~= nil
		or (not targetId:find("left") and not targetId:find("right"))
end

local function shouldCatchSavedShot(_shootTier, _shotTargetId)
	-- V4: keeper win is always catch-lock first. Side saves still use SaveContact
	-- animation timing, but the ball attaches to the keeper hand instead of using
	-- a free parry/rebound. This removes ghost rebounds and race-condition snaps.
	return MatchKeeperConfig.CatchLockAllKeeperWins ~= false
end

local function shouldUsePowerBreakthrough(success, shootTier, shotTargetId)
	if success ~= true then
		return false
	end

	if not MatchKeeperConfig or MatchKeeperConfig.PowerBreakthroughEnabled == false then
		return false
	end

	local tierMap = MatchKeeperConfig.PowerBreakthroughTiers or { Green = true }
	if tierMap[tostring(shootTier or "")] ~= true then
		return false
	end

	return isCenterShotTarget(shotTargetId)
end

local function playExcellentSpeedEffect(self, duration)
	if self.MatchUIController and self.MatchUIController.PlayExcellentSpeedEffect then
		pcall(function()
			self.MatchUIController:PlayExcellentSpeedEffect({
				Duration = duration or 1.8,
			})
		end)
	end
end

local function stopExcellentSpeedEffect(self)
	if self.MatchUIController and self.MatchUIController.StopExcellentSpeedEffect then
		pcall(function()
			self.MatchUIController:StopExcellentSpeedEffect()
		end)
	end
end

local function getContactCFrame(contactPayload, fallbackPosition)
	if type(contactPayload) == "table" and typeof(contactPayload.ContactCFrame) == "CFrame" then
		return contactPayload.ContactCFrame
	end

	if type(contactPayload) == "table" and typeof(contactPayload.ContactPosition) == "Vector3" then
		return CFrame.new(contactPayload.ContactPosition)
	end

	return CFrame.new(fallbackPosition)
end

local function getCurrentOfficialBallPosition(self)
	if self.MatchBallController and self.MatchBallController.GetBallPosition then
		local ok, position = pcall(function()
			return self.MatchBallController:GetBallPosition()
		end)

		if ok and typeof(position) == "Vector3" then
			return position
		end
	end

	return nil
end

local function getDistanceGatedContactCFrame(self, contactCFrame)
	local currentBallPosition = getCurrentOfficialBallPosition(self)
	if not currentBallPosition or typeof(contactCFrame) ~= "CFrame" then
		return contactCFrame, 0
	end

	local distance = (currentBallPosition - contactCFrame.Position).Magnitude
	local snapMaxDistance = tonumber(MatchKeeperConfig.KeeperContactSnapMaxDistance) or 2.35
	local blendMaxDistance = tonumber(MatchKeeperConfig.KeeperContactBlendMaxDistance) or 6.5

	-- If the marker fires while the ball is still too far from the hand, avoid visual teleport.
	-- Use the current ball position for parry / fallback; catch and breakthrough can still blend in.
	if distance > blendMaxDistance then
		return CFrame.lookAt(currentBallPosition, contactCFrame.Position), distance
	end

	if distance > snapMaxDistance then
		return contactCFrame, distance
	end

	return contactCFrame, distance
end

local function triggerKeeperGoalImpactRagdoll(self, payload, impactPosition, shotTargetId)
	if not self or not self.MatchKeeperPresentationController then
		return
	end

	if not payload or not self:_isSessionActive(payload.SessionId) then
		return
	end

	local keeperController = self.MatchKeeperPresentationController
	if keeperController.TriggerGoalImpactRagdoll then
		keeperController:TriggerGoalImpactRagdoll(impactPosition, shotTargetId, {
			Reason = "goal-target-impact",
		})
		return
	end

	if keeperController.ForcePowerBreakthroughPushback then
		keeperController:ForcePowerBreakthroughPushback({
			ContactCFrame = CFrame.new(impactPosition),
			ContactPosition = impactPosition,
			ShotTargetId = shotTargetId,
		}, {
			ReactionData = {
				PowerBreakthroughCarryTargetPosition = impactPosition,
			},
		})
	end
end

local function holdKeeperContactBall(self, contactPayload, contactCFrame, holdDuration, options)
	options = options or {}

	if not self.MatchBallController then
		return nil
	end

	local targetInstance = type(contactPayload) == "table" and contactPayload.TargetInstance or nil
	local gatedContactCFrame, contactDistance = getDistanceGatedContactCFrame(self, contactCFrame)
	local snapMaxDistance = tonumber(MatchKeeperConfig.KeeperContactSnapMaxDistance) or 2.35
	local baseBlendDuration = tonumber(MatchKeeperConfig.KeeperContactBlendDuration) or 0.12
	local blendDuration = math.clamp(baseBlendDuration + (math.max(contactDistance - snapMaxDistance, 0) * 0.018), baseBlendDuration, 0.22)

	if targetInstance and self.MatchBallController.BlendToMovingTarget and contactDistance > snapMaxDistance then
		return self.MatchBallController:BlendToMovingTarget(targetInstance, blendDuration, {
			WorldCFrame = gatedContactCFrame,
			HoldDuration = holdDuration,
			HoldEffects = options.HoldEffects == true,
			SpinWhileHeld = options.SpinWhileHeld == true,
			SpinSpeed = options.SpinSpeed,
		})
	end

	if targetInstance and self.MatchBallController.HoldAtMovingTarget then
		return self.MatchBallController:HoldAtMovingTarget(targetInstance, holdDuration, {
			WorldCFrame = gatedContactCFrame,
			HoldEffects = options.HoldEffects == true,
			SpinWhileHeld = options.SpinWhileHeld == true,
			SpinSpeed = options.SpinSpeed,
		})
	end

	if self.MatchBallController.BlendToWorldCFrame and contactDistance > snapMaxDistance then
		return self.MatchBallController:BlendToWorldCFrame(gatedContactCFrame, blendDuration, {
			HoldDuration = holdDuration,
			HoldEffects = options.HoldEffects == true,
			SpinWhileHeld = options.SpinWhileHeld == true,
			SpinSpeed = options.SpinSpeed,
		})
	end

	if self.MatchBallController.HoldAtWorldCFrame then
		return self.MatchBallController:HoldAtWorldCFrame(gatedContactCFrame, holdDuration, {
			HoldEffects = options.HoldEffects == true,
			SpinWhileHeld = options.SpinWhileHeld == true,
			SpinSpeed = options.SpinSpeed,
		})
	end

	if self.MatchBallController.SetHoldEffectEnabled then
		self.MatchBallController:SetHoldEffectEnabled(options.HoldEffects == true)
	end
	self:_holdBallAtFinalPose(gatedContactCFrame.Position)
	return nil
end

local function buildRandomSaveReboundPosition(startPos, blockPos, actorModel, seedText)
	local shotDirection = MatchMotionMath.GetFlatDirection(startPos, blockPos)
	if shotDirection.Magnitude <= 0.001 then
		shotDirection = Vector3.new(0, 0, -1)
	end

	local right = shotDirection:Cross(Vector3.yAxis)
	if right.Magnitude <= 0.001 then
		right = Vector3.xAxis
	else
		right = right.Unit
	end

	local seed = 0
	local seedString = tostring(seedText or "")
	for index = 1, #seedString do
		seed = (seed + string.byte(seedString, index) * index) % 2147483647
	end
	if seed <= 0 then
		seed = math.floor(os.clock() * 100000) % 2147483647
	end

	local rng = Random.new(seed)
	local sideSign = rng:NextNumber() < 0.5 and -1 or 1
	local sideMin = getNestedConfigValue("SaveReboundSideMin", nil, 2.8)
	local sideMax = getNestedConfigValue("SaveReboundSideMax", nil, 7.2)
	local backMin = getNestedConfigValue("SaveReboundBackMin", nil, 2.4)
	local backMax = getNestedConfigValue("SaveReboundBackMax", nil, 6.4)
	local reboundHeight = getNestedConfigValue("SaveReboundHeight", nil, MatchBallConfig.PassLandingHeight or 0.55)

	local sideDistance = rng:NextNumber(sideMin, math.max(sideMin, sideMax))
	local backDistance = rng:NextNumber(backMin, math.max(backMin, backMax))

	local rawRebound = blockPos
		- (shotDirection * backDistance)
		+ (right * sideSign * sideDistance)

	return GetGroundedPosition(rawRebound, actorModel) + Vector3.new(0, reboundHeight, 0)
end

local function isGoalkeeperModel(model)
	if not model then
		return false
	end

	local name = string.lower(model.Name)
	if name:find("keeper") or name:find("goalkeeper") or name == "gk" then
		return true
	end

	local role = model:GetAttribute("MatchEnemyRole") or model:GetAttribute("Role")
	return role == "GoalKeeper" or role == "Keeper" or role == "Goalkeeper"
end

local function freezeModelAtCurrentPose(self, model)
	if not model or not model.Parent then
		return
	end

	local root = GetRootPart(model)
	if not root then
		return
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local groundedPos = GetGroundedPosition(root.Position, model)
	local lookVector = GetFlatUnitFromLook(root.CFrame.LookVector)
	local lookTarget = groundedPos + lookVector

	ApplyPivot(model, MatchMotionMath.BuildFlatLookAtCFrame(groundedPos, lookTarget))
	self:_playMotionAnimation(model, "Idle", 1.0)
end

local function startShootCinematicFreezeGuard(self, sessionId, shooterSlot, shooterModel)
	self.ShootCinematicFreezeToken = (self.ShootCinematicFreezeToken or 0) + 1
	local freezeToken = self.ShootCinematicFreezeToken
	self.IsShootCinematicFrozen = true

	self.IdleEnemyMotionToken = (self.IdleEnemyMotionToken or 0) + 1
	self.AllyPatrolMotionToken = (self.AllyPatrolMotionToken or 0) + 1
	self.PostShotLockToken = (self.PostShotLockToken or 0) + 1

	if self._stopSupportMotion then
		self:_stopSupportMotion()
	end

	if type(self.DefeatedEnemyRecoveryTokens) == "table" then
		table.clear(self.DefeatedEnemyRecoveryTokens)
	end


	if self._resetEnemyMotionLocks then
		self:_resetEnemyMotionLocks()
	end

	local lockedEnemies = {}
	self:_forEachEnemyModel(function(enemyModel)
		if enemyModel and enemyModel.Parent and not isGoalkeeperModel(enemyModel) then
			if self._acquireEnemyMotionLock then
				self:_acquireEnemyMotionLock(enemyModel, "ShootCinematic", { Force = true })
				lockedEnemies[enemyModel] = true
			end

			freezeModelAtCurrentPose(self, enemyModel)
		end
	end)

	-- Freeze controlled actors immediately once before the RenderStepped guard starts.
	-- This removes one-frame running-in-place artifacts from non-shooter companions.
	for slotNumber = 1, 4 do
		if slotNumber ~= tonumber(shooterSlot) then
			local controlledModel = self:_getControlledActorModel(slotNumber)
			if controlledModel and controlledModel ~= shooterModel then
				freezeModelAtCurrentPose(self, controlledModel)
			end
		end
	end

	task.spawn(function()
		local deadline = os.clock() + SHOOT_CINEMATIC_FREEZE_GUARD_DURATION

		while self:_isSessionActive(sessionId)
			and self.ShootCinematicFreezeToken == freezeToken
			and os.clock() < deadline
		do
			for slotNumber = 1, 4 do
				if slotNumber ~= tonumber(shooterSlot) then
					local controlledModel = self:_getControlledActorModel(slotNumber)
					if controlledModel and controlledModel ~= shooterModel then
						freezeModelAtCurrentPose(self, controlledModel)
					end
				end
			end

			self:_forEachEnemyModel(function(enemyModel)
				if enemyModel and enemyModel.Parent and not isGoalkeeperModel(enemyModel) then
					freezeModelAtCurrentPose(self, enemyModel)
				end
			end)

			RunService.RenderStepped:Wait()
		end
	end)

	return function()
		if self.ShootCinematicFreezeToken == freezeToken then
			self.ShootCinematicFreezeToken += 1
			self.IsShootCinematicFrozen = false
		end

		if self._releaseEnemyMotionLock then
			for enemyModel in pairs(lockedEnemies) do
				if enemyModel and enemyModel.Parent then
					self:_releaseEnemyMotionLock(enemyModel, "ShootCinematic")
				end
			end
		end
	end
end

function MatchPresentationController:_handleShootResolved(payload, actorModel, enemyModel, actorRoot, success, notifyPostActionReady)
	local successCrowdAudioPlayed = false
	local goalNetImpactTriggered = false
	local function notifyShootPostActionReady(reason)
		if type(notifyPostActionReady) == "function" then
			notifyPostActionReady(reason)
		end
	end

	if not payload or not actorModel or not actorRoot then
		notifyShootPostActionReady("shoot post-action ready missing actor")
		return
	end

	local sessionId = tostring(payload.SessionId)
	if self.ActiveShootSessionLock == sessionId then
		notifyShootPostActionReady("shoot post-action ready duplicate")
		return
	end
	
	self.ActiveShootSessionLock = sessionId

	-- During shoot cinematic, MatchShootDirector owns all local actor slots.
	-- If only the shooter is locked, non-shooter companions can keep their old
	-- runtime Run/Support targets and appear to run in place while the freeze guard
	-- tries to hold them idle.
	local shootRuntimeOverrideSlots = {}

	local function setShootRuntimeOverride(slotNumber, locked)
		local numericSlot = tonumber(slotNumber)
		if not numericSlot then
			return
		end

		if not self.MatchActorRuntimeController or not self.MatchActorRuntimeController.SetSlotControlOverride then
			return
		end

		local ok = pcall(function()
			self.MatchActorRuntimeController:SetSlotControlOverride(LocalPlayer, numericSlot, locked == true)
		end)

		if ok then
			if locked == true then
				shootRuntimeOverrideSlots[numericSlot] = true
			else
				shootRuntimeOverrideSlots[numericSlot] = nil
			end
		end
	end

	local function releaseShootRuntimeOverrides()
		-- Keep ownership locked until the match session is fully cleaned up.
		-- Releasing immediately after result can let MatchActorRuntimeController resume
		-- stale Run/Shoot targets and rotate/move the shooter after Win/Lose.
		local slotsToRelease = table.clone(shootRuntimeOverrideSlots)
		table.clear(shootRuntimeOverrideSlots)

		task.spawn(function()
			while self:_isSessionActive(payload.SessionId) do
				RunService.RenderStepped:Wait()
			end

			for slotNumber in pairs(slotsToRelease) do
				setShootRuntimeOverride(slotNumber, false)
			end
		end)
	end

	for slotNumber = 1, 4 do
		setShootRuntimeOverride(slotNumber, true)
	end

	if self._stopSupportMotion then
		self:_stopSupportMotion()
	end

	local stopFreezeGuard = startShootCinematicFreezeGuard(self, payload.SessionId, payload.ActorSlot, actorModel)


	local shootTier = getShootTier(self)
	local shotTravelDuration = self:_getEpicShotTravelDuration()

	local startPos = self:_getBallStartPosition(actorRoot)
	local selectedShotTarget, shotTargetPos = resolveShotTarget(payload, success, shootTier)
	local shotTargetId = selectedShotTarget and selectedShotTarget.Id or "Center"
	local ballEndPos = success and shotTargetPos or buildSaveInterceptPosition(startPos, shotTargetPos, shotTargetId)

	if (not success) and MatchKeeperConfig.UseKeeperSaveTargets and MatchShootTargetResolver.GetKeeperSaveTarget then
		local keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
		if keeperSaveTarget and typeof(keeperSaveTarget.Position) == "Vector3" then
			ballEndPos = keeperSaveTarget.Position
		end
	end

	local isPerfectShoot = success == true and shootTier == "Green"
	local useSpecialShoot = isPerfectShoot and hasSpecialShootAnimation(actorModel)
	
	local function triggerGoalNetImpact()
		if not self:_isSessionActive(payload.SessionId) then
			return
		end
		if goalNetImpactTriggered then
			return
		end
		goalNetImpactTriggered = true

		if success == true then
			if not successCrowdAudioPlayed then
				successCrowdAudioPlayed = true
				playMatchSound("Goal", { Volume = 1.0, Lifetime = 4 })
				-- ApplauseBig for ALL goals (not just special shoot)
				local applauseVolume = useSpecialShoot and 1.05 or 0.90
				playMatchSound("ApplauseBig", { Volume = applauseVolume, Lifetime = 8 })
			end

			-- Camera shake for normal goals (perfect shoot gets its own shake at impact)
			if not isPerfectShoot and MatchShootCinematicDirector.ShakeActiveCamera then
				MatchShootCinematicDirector.ShakeActiveCamera(
					GOAL_CAMERA_SHAKE_STRENGTH,
					GOAL_CAMERA_SHAKE_DURATION
				)
			end

			requestNpcSupporterGoalCheer(self, payload, "NetImpact")
		end
	end

	local stopGreenActionFx = nil
	if isPerfectShoot then
		stopGreenActionFx = MatchActionFxHelper.StartActorGreenFx(actorModel, {
			Duration = 1.45,
			CleanupDelay = 0.18,
		})
	end
	-- Shoot no longer activates legacy/generated actor trails.
	-- Green/perfect shot visuals are owned by the artist-authored ball template and CameraEffect UI.

	local shouldCatchSave = (not success) and shouldCatchSavedShot(shootTier, shotTargetId)
	local shouldPowerBreakthrough = shouldUsePowerBreakthrough(success, shootTier, shotTargetId)
	-- GoalHold includes center shots now (center was previously excluded but we need keeper to react)
	local shouldKeeperReactToGoal = success == true and not shouldPowerBreakthrough
	local shouldRunKeeperReaction = (not success) or shouldPowerBreakthrough or shouldKeeperReactToGoal
	local saveReboundPos = nil
	local holdPos = nil

	if not success and not shouldCatchSave then
		saveReboundPos = buildRandomSaveReboundPosition(
			startPos,
			ballEndPos,
			actorModel,
			table.concat({
				tostring(payload.SessionId),
				tostring(payload.StepIndex),
				tostring(payload.ActorSlot),
				tostring(shotTargetId),
			}, ":")
		)
	end

	-- Keep old shoot flow safe before the animation actually starts.
	-- Special embedded ball is only shown when the special animation begins.
	hideActorEmbeddedBall(self, actorModel)
	setOfficialBallAtPosition(self, startPos)
	setOfficialBallVisible(self, true)

	self:_setTimeScale(0.3)

	local shotReleased = false
	local stopEmbeddedBallVisibilityGuard = nil
	local activeSpecialImpactEvent = nil
	local activeSpecialMarkerConnection = nil
	local activeSpecialImpactFired = false
	local activeSpecialImpactParameter = nil

	local function cleanupSpecialImpactResources()
		if type(activeSpecialMarkerConnection) == "table" then
			for _, connection in ipairs(activeSpecialMarkerConnection) do
				if connection then
					connection:Disconnect()
				end
			end
		elseif activeSpecialMarkerConnection then
			activeSpecialMarkerConnection:Disconnect()
		end

		activeSpecialMarkerConnection = nil

		if activeSpecialImpactEvent then
			activeSpecialImpactEvent:Destroy()
			activeSpecialImpactEvent = nil
		end
	end

	local function fireSpecialImpactFromMarker(parameter)
		if activeSpecialImpactFired then
			return
		end

		activeSpecialImpactFired = true
		activeSpecialImpactParameter = parameter

		if activeSpecialImpactEvent then
			activeSpecialImpactEvent:Fire(parameter)
		end
	end

	local function stopSpecialEmbeddedBallGuard(shouldHide)
		if stopEmbeddedBallVisibilityGuard then
			stopEmbeddedBallVisibilityGuard(shouldHide)
			stopEmbeddedBallVisibilityGuard = nil
		elseif shouldHide ~= false then
			setActorEmbeddedBallVisualsHidden(actorModel, true)
		end
	end

	local keeperContactResolved = false

	local function handleKeeperCatchContact(contactPayload)
		if keeperContactResolved then
			return
		end

		keeperContactResolved = true
		playMatchSound("KeeperHold", { Volume = 1.0, Lifetime = 4 })

		if MatchShootCinematicDirector.ShakeActiveCamera then
			local shakeStrength = tonumber(MatchKeeperConfig.CatchShakeStrength) or 1.35
			local shakeDuration = tonumber(MatchKeeperConfig.CatchShakeDuration) or 0.35
			MatchShootCinematicDirector.ShakeActiveCamera(shakeStrength, shakeDuration)
		end

		if not self:_isSessionActive(payload.SessionId) or not self.MatchBallController then
			return
		end

		local contactCFrame = getContactCFrame(contactPayload, ballEndPos)
		local holdDuration = tonumber(MatchKeeperConfig.CatchBallHoldDuration) or 5.0

		holdKeeperContactBall(self, contactPayload, contactCFrame, holdDuration, {
			HoldEffects = false,
		})
	end

	local function handleKeeperPowerBreakthroughContact(contactPayload)
		if keeperContactResolved then
			return
		end

		keeperContactResolved = true
		playMatchSound("KeeperHold", { Volume = 1.15, Lifetime = 4 })

		if not shouldPowerBreakthrough then
			return
		end

		if not self:_isSessionActive(payload.SessionId) or not self.MatchBallController then
			return
		end

		-- Keep the ball target owned by the keeper presentation layer, especially when
		-- fallback fires before the animation marker. This prevents the center shot
		-- from being held at the goal/torso instead of the keeper's hands.
		if self.MatchKeeperPresentationController
			and self.MatchKeeperPresentationController.ResolvePowerBreakthroughContactPayload
		then
			local ok, resolvedPayload = pcall(function()
				return self.MatchKeeperPresentationController:ResolvePowerBreakthroughContactPayload(
					contactPayload,
					type(contactPayload) == "table" and contactPayload.ContactPosition or ballEndPos,
					shotTargetId
				)
			end)

			if ok and type(resolvedPayload) == "table" then
				contactPayload = resolvedPayload
			end
		end

		local contactCFrame = getContactCFrame(contactPayload, ballEndPos)
		local usePowerBreakthroughContactEffects = isPerfectShoot == true
		local baseHoldDuration = usePowerBreakthroughContactEffects
			and (tonumber(MatchKeeperConfig.PowerBreakthroughBallHoldDuration) or 1.00)
			or 0.03
		local carryExtraHold = tonumber(MatchKeeperConfig.PowerBreakthroughCarryExtraHold) or 0
		local configuredContinueDelay = tonumber(MatchKeeperConfig.PowerBreakthroughContinueDelay)
			or (baseHoldDuration + carryExtraHold)
		if not usePowerBreakthroughContactEffects then
			configuredContinueDelay = 0.03
			carryExtraHold = 0
		end
		local carryToTargetDuration = 0
		if MatchKeeperConfig.PowerBreakthroughRagdollEnabled == true then
			if MatchKeeperConfig.PowerBreakthroughCarryToShotTargetEnabled ~= false then
				carryToTargetDuration = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughCarryToShotTargetDuration) or 0, 0)
			elseif MatchKeeperConfig.PowerBreakthroughRagdollPreDriftEnabled ~= false then
				carryToTargetDuration = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollPreDriftDuration) or 0, 0)
			end
		end
		local afterRagdollReleaseDelay = tonumber(MatchKeeperConfig.PowerBreakthroughContinueAfterRagdollDelay) or 0.12
		local continueDelay = math.max(
			configuredContinueDelay,
			baseHoldDuration + carryExtraHold + carryToTargetDuration + afterRagdollReleaseDelay
		)
		local releasePadding = usePowerBreakthroughContactEffects
			and (tonumber(MatchKeeperConfig.PowerBreakthroughHoldReleasePadding) or 0.08)
			or 0
		local holdDuration = math.max(baseHoldDuration + carryExtraHold, continueDelay + releasePadding)
		local continueDuration = tonumber(MatchKeeperConfig.PowerBreakthroughContinueDuration) or 0.52
		local continueArcHeight = tonumber(MatchKeeperConfig.PowerBreakthroughContinueArcHeight) or 0.52
		local ballHoldPayload = contactPayload
		if usePowerBreakthroughContactEffects and type(contactPayload) == "table" then
			ballHoldPayload = {}
			for key, value in pairs(contactPayload) do
				ballHoldPayload[key] = value
			end
			ballHoldPayload.TargetInstance = nil
		end

		holdKeeperContactBall(self, ballHoldPayload, contactCFrame, holdDuration, {
			HoldEffects = usePowerBreakthroughContactEffects,
			SpinWhileHeld = usePowerBreakthroughContactEffects and MatchKeeperConfig.PowerBreakthroughBallSpinWhileHeld ~= false,
			SpinSpeed = tonumber(MatchKeeperConfig.PowerBreakthroughBallHoldSpinSpeed) or 18.0,
		})

		if usePowerBreakthroughContactEffects and self.MatchBallController.PlayImpactEffect then
			self.MatchBallController:PlayImpactEffect(contactCFrame.Position, {
				EmitCount = tonumber(MatchKeeperConfig.PowerBreakthroughContactImpactEmitCount) or 36,
				Lifetime = tonumber(MatchKeeperConfig.PowerBreakthroughContactImpactLifetime) or 0.50,
			})
		end

		if self.MatchKeeperPresentationController
			and self.MatchKeeperPresentationController.TriggerPowerBreakthroughImpactRagdoll
		then
			local impactForwardVector = ballEndPos - contactCFrame.Position
			if impactForwardVector.Magnitude <= 0.001 then
				impactForwardVector = nil
			end

			local function triggerContactRagdoll()
				if not self:_isSessionActive(payload.SessionId) then
					return
				end

				self.MatchKeeperPresentationController:TriggerPowerBreakthroughImpactRagdoll(contactPayload, {
					ForwardVector = impactForwardVector,
				})
			end

			local ragdollDelay = usePowerBreakthroughContactEffects
				and math.max(tonumber(MatchKeeperConfig.PowerBreakthroughPerfectRagdollDelay) or 0.12, 0)
				or 0
			if ragdollDelay > 0 then
				task.delay(ragdollDelay, triggerContactRagdoll)
			else
				triggerContactRagdoll()
			end
		end

		if MatchShootCinematicDirector.ShakeActiveCamera then
			MatchShootCinematicDirector.ShakeActiveCamera(
				usePowerBreakthroughContactEffects
						and (type(MatchKeeperConfig.PowerBreakthroughShakeStrength) == "number" and MatchKeeperConfig.PowerBreakthroughShakeStrength or 1.35)
					or 0.85,
				usePowerBreakthroughContactEffects
						and (type(MatchKeeperConfig.PowerBreakthroughShakeDuration) == "number" and MatchKeeperConfig.PowerBreakthroughShakeDuration or math.max(continueDelay, 1.0))
					or 0.18
			)
		end

		task.delay(math.max(continueDelay, 0.03), function()
			if not self:_isSessionActive(payload.SessionId) or not self.MatchBallController then
				return
			end

			local latestCFrame = contactCFrame
			if not usePowerBreakthroughContactEffects
				and type(contactPayload) == "table"
				and contactPayload.TargetInstance
				and self.MatchBallController._resolveWorldCFrame
			then
				local ok, resolvedCFrame = pcall(function()
					return self.MatchBallController:_resolveWorldCFrame(contactPayload.TargetInstance, contactCFrame)
				end)

				if ok and typeof(resolvedCFrame) == "CFrame" then
					latestCFrame = resolvedCFrame
				end
			end

			if self.MatchBallController.ContinueShotFromKeeper then
				self.MatchBallController:ContinueShotFromKeeper(latestCFrame, ballEndPos, shootTier, {
					IsSpecialShot = useSpecialShoot,
					EnableFlightEffects = isPerfectShoot,
					Duration = continueDuration,
					ArcHeight = continueArcHeight,
					DropAfterFinish = MatchKeeperConfig.GoalBallDropEnabled ~= false,
					DropDelay = MatchKeeperConfig.GoalBallDropDelay,
					DropDuration = MatchKeeperConfig.GoalBallDropDuration,
					DropDistance = MatchKeeperConfig.GoalBallDropDistance,
					DropBounceHeight = MatchKeeperConfig.GoalBallDropBounceHeight,
					RollAfterDrop = true,
					RollDirection = (ballEndPos - startPos),
					RollSpeed = isPerfectShoot and 12.0 or 8.0,
					RollDeceleration = 5.5,
					ImpactAtFinish = isPerfectShoot,
					ImpactEmitCount = 34,
					ImpactLifetime = 0.62,
					OnImpactAtFinish = function()
						triggerGoalNetImpact()
						if isPerfectShoot and MatchShootCinematicDirector.ShakeActiveCamera then
							local goalShakeStrength = type(MatchKeeperConfig.PowerBreakthroughGoalImpactShakeStrength) == "number"
								and MatchKeeperConfig.PowerBreakthroughGoalImpactShakeStrength
								or 2.8
							local goalShakeDuration = type(MatchKeeperConfig.PowerBreakthroughGoalImpactShakeDuration) == "number"
								and MatchKeeperConfig.PowerBreakthroughGoalImpactShakeDuration
								or 0.55

							MatchShootCinematicDirector.ShakeActiveCamera(
								goalShakeStrength,
								goalShakeDuration
							)
						end

						if isPerfectShoot then
							stopExcellentSpeedEffect(self)
						end
					end,
				})
			elseif self.MatchBallController.PlayEpicShot then
				self.MatchBallController:PlayEpicShot(latestCFrame.Position, ballEndPos, true, shootTier, {
					IsSpecialShot = useSpecialShoot,
					EnableFlightEffects = isPerfectShoot,
					DropAfterFinish = MatchKeeperConfig.GoalBallDropEnabled ~= false,
					DropDelay = MatchKeeperConfig.GoalBallDropDelay,
					DropDuration = MatchKeeperConfig.GoalBallDropDuration,
					DropDistance = MatchKeeperConfig.GoalBallDropDistance,
					DropBounceHeight = MatchKeeperConfig.GoalBallDropBounceHeight,
					RollAfterDrop = true,
					RollDirection = (ballEndPos - startPos),
					RollSpeed = isPerfectShoot and 12.0 or 8.0,
					RollDeceleration = 5.5,
					ImpactAtFinish = isPerfectShoot,
					ImpactEmitCount = 34,
					ImpactLifetime = 0.62,
					OnImpactAtFinish = function()
						triggerGoalNetImpact()
						if isPerfectShoot and MatchShootCinematicDirector.ShakeActiveCamera then
							local goalShakeStrength = type(MatchKeeperConfig.PowerBreakthroughGoalImpactShakeStrength) == "number"
								and MatchKeeperConfig.PowerBreakthroughGoalImpactShakeStrength
								or 2.8
							local goalShakeDuration = type(MatchKeeperConfig.PowerBreakthroughGoalImpactShakeDuration) == "number"
								and MatchKeeperConfig.PowerBreakthroughGoalImpactShakeDuration
								or 0.55

							MatchShootCinematicDirector.ShakeActiveCamera(
								goalShakeStrength,
								goalShakeDuration
							)
						end

						if isPerfectShoot then
							stopExcellentSpeedEffect(self)
						end
					end,
				})
			end
		end)
	end

	local function handleKeeperGoalHoldContact(contactPayload)
		if not self.MatchBallController or not self.MatchBallController.TriggerGoalHoldPhase then
			return
		end

		local function getWorldCFrameFromTarget(target, fallbackCFrame)
			if target and self.MatchBallController and self.MatchBallController._resolveWorldCFrame then
				local ok, resolved = pcall(function()
					return self.MatchBallController:_resolveWorldCFrame(target, fallbackCFrame)
				end)

				if ok and typeof(resolved) == "CFrame" then
					return resolved
				end
			end

			return fallbackCFrame
		end

		local function applyHandForwardOffset(contactCFrame)
			if typeof(contactCFrame) ~= "CFrame" then
				return nil
			end

			local isCenterHold = isCenterShotTarget(shotTargetId)
			local offset = isCenterHold
					and (tonumber(MatchKeeperConfig.GoalHoldCenterBallHandForwardOffset) or tonumber(MatchKeeperConfig.GoalHoldBallHandForwardOffset))
				or tonumber(MatchKeeperConfig.GoalHoldBallHandForwardOffset)
				or 0
			if offset <= 0 then
				return contactCFrame.Position
			end

			local forwardVector = nil
			if isCenterHold then
				forwardVector = contactCFrame.LookVector
			else
				local ballPos = self.MatchBallController:GetBallPosition()
				if typeof(ballPos) == "Vector3" then
					local toBall = ballPos - contactCFrame.Position
					if toBall.Magnitude > 0.05 then
						forwardVector = toBall.Unit
					end
				end
			end

			if not forwardVector then
				forwardVector = contactCFrame.LookVector
			end

			return contactCFrame.Position + (forwardVector * offset)
		end

		-- Prefer the keeper controller's resolved contact payload. It already accounts
		-- for grip attachments, center-hand midpoint, and the frozen keeper pose.
		local payloadContactCFrame = nil
		local handSnapFromPayload = false
		if type(contactPayload) == "table" then
			if contactPayload.TargetInstance then
				payloadContactCFrame = getWorldCFrameFromTarget(contactPayload.TargetInstance, contactPayload.ContactCFrame)
			elseif typeof(contactPayload.ContactCFrame) == "CFrame" then
				payloadContactCFrame = contactPayload.ContactCFrame
			elseif typeof(contactPayload.ContactPosition) == "Vector3" then
				payloadContactCFrame = CFrame.new(contactPayload.ContactPosition)
			end
			handSnapFromPayload = typeof(payloadContactCFrame) == "CFrame"
		end

		local handSnapPosition = applyHandForwardOffset(payloadContactCFrame)

		-- Fallback: find the keeper's catching hand position at this exact moment.
		-- User rule: dive left -> right hand catches, dive right -> left hand catches, center -> either.
		if not handSnapPosition and MatchActorResolver and MatchActorResolver.GetEnemyModelByStep then
			local keeperModel = MatchActorResolver.GetEnemyModelByStep(5)
			if keeperModel then
				local targetIdLower = string.lower(tostring(shotTargetId or ""))
				local isLeft = targetIdLower:find("left") ~= nil
				local isRight = targetIdLower:find("right") ~= nil

				local function findHand(side)
					-- Look for dedicated catch attachment first, fallback to Hand part
					return keeperModel:FindFirstChild(side .. "GripAttachment", true)
						or keeperModel:FindFirstChild(side .. "HandCatchAttachment", true)
						or keeperModel:FindFirstChild(side .. "BallCatchAttachment", true)
						or keeperModel:FindFirstChild(side .. "WristRigAttachment", true)
						or keeperModel:FindFirstChild(side .. "Hand", true)
				end

				local catchHand
				if isLeft then
					-- Shot goes left -> keeper dives left -> catching hand = Right
					catchHand = findHand("Right")
				elseif isRight then
					-- Shot goes right -> keeper dives right -> catching hand = Left
					catchHand = findHand("Left")
				else
					-- Center: pick whichever hand is closest to current ball position
					local ballPos = self.MatchBallController:GetBallPosition()
					local leftHand = findHand("Left")
					local rightHand = findHand("Right")
					if ballPos and leftHand and rightHand then
						local lPos = leftHand:IsA("Attachment") and leftHand.WorldPosition or leftHand.Position
						local rPos = rightHand:IsA("Attachment") and rightHand.WorldPosition or rightHand.Position
						catchHand = (lPos - ballPos).Magnitude < (rPos - ballPos).Magnitude and leftHand or rightHand
					else
						catchHand = leftHand or rightHand
					end
				end

				if catchHand then
					local contactCFrame = nil
					if catchHand:IsA("Attachment") then
						contactCFrame = catchHand.WorldCFrame
					elseif catchHand:IsA("BasePart") then
						contactCFrame = catchHand.CFrame
					end

					handSnapPosition = applyHandForwardOffset(contactCFrame)
				end
			end
		end

		-- Snap threshold: avoid a bad attachment causing a full-field teleport, but allow
		-- the normal keeper/ball gap so GoalHold reads as a hand catch.
		if handSnapPosition then
			local ballPos = self.MatchBallController:GetBallPosition()
			local maxSnapDistance = tonumber(MatchKeeperConfig.GoalHoldHandSnapMaxDistance) or 12.0
			if not handSnapFromPayload and ballPos and (handSnapPosition - ballPos).Magnitude > maxSnapDistance then
				handSnapPosition = nil
			end
		end

		self.MatchBallController:TriggerGoalHoldPhase(handSnapPosition)
	end

	local function handleKeeperSaveContact(contactPayload)
		-- V4 catch-lock: side SaveContact markers reuse the same ball ownership as catches.
		-- No parry/rebound while keeper save stability is being fixed.
		return handleKeeperCatchContact(contactPayload)
	end

	local function startKeeperContactFallback()
		if success and not shouldPowerBreakthrough then
			return
		end

		local powerFallbackTravelDelay = math.max(
			shotTravelDuration * (tonumber(MatchKeeperConfig.PowerBreakthroughFallbackTravelAlpha) or 1.08),
			shotTravelDuration + 0.05
		)
		local configuredPowerFallbackDelay = tonumber(MatchKeeperConfig.PowerBreakthroughFallbackDelay)
		local baseFallbackDelay = success
			and math.max(configuredPowerFallbackDelay or powerFallbackTravelDelay, powerFallbackTravelDelay)
			or (shouldCatchSave
				and (shotTravelDuration * (tonumber(MatchKeeperConfig.KeeperCatchLockFallbackTravelAlpha) or 0.96))
				or (shotTravelDuration + (tonumber(MatchKeeperConfig.KeeperContactFallbackPadding) or 0.35)))

		local fallbackDelay = math.max(baseFallbackDelay, 0.25)

		task.delay(fallbackDelay, function()
			if keeperContactResolved or not self:_isSessionActive(payload.SessionId) then
				return
			end

			if shouldPowerBreakthrough then
				local fallbackPosition = ballEndPos
				if MatchShootTargetResolver.GetKeeperSaveTarget then
					local keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
					if keeperSaveTarget and typeof(keeperSaveTarget.Position) == "Vector3" then
						fallbackPosition = keeperSaveTarget.Position
					end
				end

				handleKeeperPowerBreakthroughContact({
					ContactCFrame = CFrame.new(fallbackPosition),
					ContactPosition = fallbackPosition,
					ShotTargetId = shotTargetId,
					Reason = "power-breakthrough-fallback",
				})
			elseif shouldCatchSave then
				handleKeeperCatchContact({
					ContactCFrame = CFrame.new(ballEndPos),
					ContactPosition = ballEndPos,
					Reason = "shoot-fallback",
				})
			else
				handleKeeperSaveContact({
					ContactCFrame = CFrame.new(ballEndPos),
					ContactPosition = ballEndPos,
					Reason = "shoot-fallback",
				})
			end
		end)
	end

	local function releaseShotBall()
	if shotReleased then
		return
	end

	shotReleased = true
	cleanupSpecialImpactResources()

	if not self:_isSessionActive(payload.SessionId) then
		return
	end

	self:_setTimeScale(DEFAULT_TIME_SCALE)

	if self.MatchBallController then
		local releaseStartPos = startPos

		if useSpecialShoot then
			-- Smooth handover: place official ball at the last animated proxy CFrame
			-- before destroying the proxy. This avoids the official ball popping from
			-- its model pivot or appearing from below the foot.
			local releaseCFrame = getSpecialEmbeddedBallReleaseCFrame(self, actorModel)

			setOfficialBallVisible(self, false)

			if releaseCFrame and self.MatchBallController.SetBallDriverWorldCFrame then
				self.MatchBallController:SetBallDriverWorldCFrame(releaseCFrame)
				releaseStartPos = self.MatchBallController:GetBallPosition() or releaseCFrame.Position
			elseif releaseCFrame then
				releaseStartPos = releaseCFrame.Position
				setOfficialBallAtPosition(self, releaseStartPos)
			else
				releaseStartPos = getSpecialEmbeddedBallReleasePosition(self, actorModel) or startPos
				setOfficialBallAtPosition(self, releaseStartPos)
			end

			setOfficialBallVisible(self, true)
			RunService.RenderStepped:Wait()
			stopSpecialEmbeddedBallGuard(true)
		else
			hideActorEmbeddedBall(self, actorModel)
			setOfficialBallVisible(self, true)
			setOfficialBallAtPosition(self, releaseStartPos)
		end

		local keeperHandTarget = nil
		if ((not success) or shouldPowerBreakthrough or (success and isPerfectShoot)) and MatchActorResolver and MatchActorResolver.GetEnemyModelByStep then
			local keeperModel = MatchActorResolver.GetEnemyModelByStep(5)
			if keeperModel then
				local targetIdLower = string.lower(tostring(shotTargetId or ""))
				local isLeft = targetIdLower:find("left") ~= nil
				local isRight = targetIdLower:find("right") ~= nil
				
				local function findGrip(side)
					return keeperModel:FindFirstChild(side .. "GripAttachment", true)
						or keeperModel:FindFirstChild(side .. "WristRigAttachment", true)
						or keeperModel:FindFirstChild(side .. "HandCatchAttachment", true)
						or keeperModel:FindFirstChild(side .. "BallCatchAttachment", true)
						or keeperModel:FindFirstChild(side .. "Hand", true)
				end
				
				if isLeft then
					keeperHandTarget = findGrip("Left")
				elseif isRight then
					keeperHandTarget = findGrip("Right")
				else
					keeperHandTarget = findGrip("Left") or findGrip("Right")
				end
			end
		end

		local shotFlightEndPos = ballEndPos
		local shotFlightTargetInstance = keeperHandTarget
		local resolvedContactPayload = nil
		if shouldPowerBreakthrough then
			local fallbackContactPosition = ballEndPos
			if MatchShootTargetResolver.GetKeeperSaveTarget then
				local keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
				if keeperSaveTarget and typeof(keeperSaveTarget.Position) == "Vector3" then
					fallbackContactPosition = keeperSaveTarget.Position
				end
			end

			if self.MatchKeeperPresentationController
				and self.MatchKeeperPresentationController.ResolvePowerBreakthroughContactPayload
			then
				local ok, resolvedPayload = pcall(function()
					return self.MatchKeeperPresentationController:ResolvePowerBreakthroughContactPayload({
						ContactCFrame = CFrame.new(fallbackContactPosition),
						ContactPosition = fallbackContactPosition,
						ShotTargetId = shotTargetId,
						Reason = "power-breakthrough-shot-target",
					}, fallbackContactPosition, shotTargetId)
				end)

				if ok and type(resolvedPayload) == "table" then
					resolvedContactPayload = resolvedPayload
				end
			end

			if type(resolvedContactPayload) == "table" then
				shotFlightTargetInstance = resolvedContactPayload.TargetInstance or shotFlightTargetInstance
				if typeof(resolvedContactPayload.ContactPosition) == "Vector3" then
					shotFlightEndPos = resolvedContactPayload.ContactPosition
				elseif typeof(resolvedContactPayload.ContactCFrame) == "CFrame" then
					shotFlightEndPos = resolvedContactPayload.ContactCFrame.Position
				else
					shotFlightEndPos = fallbackContactPosition
				end
			else
				shotFlightEndPos = fallbackContactPosition
			end
		end

		if isPerfectShoot then
			playExcellentSpeedEffect(self, math.max(shotTravelDuration + 0.95, 1.45))
			if MatchShootCinematicDirector.PulsePerfectShootFocus then
				MatchShootCinematicDirector.PulsePerfectShootFocus(
					releaseStartPos,
					useSpecialShoot and 0.44 or 0.36,
					useSpecialShoot and 0.2 or 0.16
				)
			end
			if useSpecialShoot and MatchShootCinematicDirector.ShakeActiveCameraRoll then
				MatchShootCinematicDirector.ShakeActiveCameraRoll(3.1, 0.78, 5.4, 0.08, 0.22, 0.1)
			end
		end

		local shotTargetText = string.lower(tostring(shotTargetId or ""))
		local isSideShotTarget = shotTargetText:find("left") ~= nil or shotTargetText:find("right") ~= nil
		local goalImpactEmitCount = tonumber(MatchKeeperConfig.GoalImpactEmitCount) or 76
		local goalImpactLifetime = tonumber(MatchKeeperConfig.GoalImpactLifetime) or 0.82
		local goalImpactShakeStrength = tonumber(MatchKeeperConfig.GoalImpactShakeStrength) or 3.6
		local goalImpactShakeDuration = tonumber(MatchKeeperConfig.GoalImpactShakeDuration) or 0.72
		if isSideShotTarget then
			goalImpactEmitCount = tonumber(MatchKeeperConfig.GoalImpactSideEmitCount) or 42
			goalImpactLifetime = tonumber(MatchKeeperConfig.GoalImpactSideLifetime) or 0.62
			goalImpactShakeStrength = tonumber(MatchKeeperConfig.GoalImpactSideShakeStrength) or 1.85
			goalImpactShakeDuration = tonumber(MatchKeeperConfig.GoalImpactSideShakeDuration) or 0.42
		end

		holdPos = nil
		-- GoalHold applies to ALL successful goals including center perfect (PowerBreakthrough).
		-- Previously center perfect skipped this, causing instant ragdoll with no hold phase.
		if success and isPerfectShoot then
			if MatchShootTargetResolver.GetKeeperSaveTarget then
				local keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
				if keeperSaveTarget then
					local toShooter = (startPos - keeperSaveTarget.Position)
					local toShooterFlat = Vector3.new(toShooter.X, 0, toShooter.Z)
					local toShooterDir = toShooterFlat.Magnitude > 0.1 and toShooterFlat.Unit or Vector3.new(0,0,1)

					-- Strategy: find where the ball path PASSES the keeper's front plane.
					-- keeperSaveTarget is at the goal LINE (behind the keeper).
					-- We need holdPos at the keeper's actual Z-depth (in front of keeper body).
					local keeperWorldPos = nil
					if MatchActorResolver and MatchActorResolver.GetEnemyModelByStep then
						local km = MatchActorResolver.GetEnemyModelByStep(5)
						local hrp = km and km:FindFirstChild("HumanoidRootPart")
						keeperWorldPos = hrp and hrp.Position
					end
					if not keeperWorldPos and MatchSceneQuery and MatchSceneQuery.GetSpawnedEnemiesFolder then
						local folder = MatchSceneQuery.GetSpawnedEnemiesFolder(false)
						local km = folder and (folder:FindFirstChild("GoalKeeper") or folder:FindFirstChild("Keeper"))
						if not km and folder then
							for _, child in ipairs(folder:GetChildren()) do
								local role = child:GetAttribute("MatchEnemyRole") or child:GetAttribute("Role")
								if role == "GoalKeeper" or role == "Keeper" then
									km = child
									break
								end
							end
						end
						local hrp = km and km:FindFirstChild("HumanoidRootPart")
						keeperWorldPos = hrp and hrp.Position
					end

					if keeperWorldPos then
						-- Keeper front = keeper base + GoalForwardAdvance toward shooter
						local goalFwdAdv = tonumber(MatchKeeperConfig.GoalForwardAdvance) or 0.55
						local keeperFront = keeperWorldPos + toShooterDir * goalFwdAdv

						-- Project ball path (start → end) onto keeper's forward plane.
						-- Find parameter t where ball passes the keeper's "depth" along toShooterDir.
						local ballPath = ballEndPos - releaseStartPos
						local tDenom = ballPath:Dot(toShooterDir)
						local t = 0.72 -- fallback alpha
						if math.abs(tDenom) > 0.01 then
							local tNum = (keeperFront - releaseStartPos):Dot(toShooterDir)
							t = math.clamp(tNum / tDenom, 0.05, 0.95)
						end
						holdPos = releaseStartPos + ballPath * t
						-- Keep save target height so ball stops at the right vertical height
						if isCenterShotTarget(shotTargetId) then
							holdPos = Vector3.new(keeperWorldPos.X, keeperSaveTarget.Position.Y, holdPos.Z)
						else
							holdPos = Vector3.new(holdPos.X, keeperSaveTarget.Position.Y, holdPos.Z)
						end
					else
						-- Fallback if no keeper model: old method with large offset
						local forwardOffset = tonumber(MatchKeeperConfig.GoalHoldForwardOffset) or 1.75
						holdPos = keeperSaveTarget.Position + toShooterDir * forwardOffset
					end

				end
			end
		end


		if holdPos then
			local goalHoldExtraDuration = math.max(tonumber(MatchKeeperConfig.GoalHoldExtraHoldDuration) or 0, 0)
			local goalHoldDurationOverride = useSpecialShoot and 1.8 or isPerfectShoot and 1.2 or 0.8
			if isCenterShotTarget(shotTargetId) then
				goalHoldDurationOverride += 0.4
			end
			goalHoldDurationOverride += goalHoldExtraDuration

			self.MatchBallController:PlayGoalHoldShot(releaseStartPos, holdPos, ballEndPos, {
				TargetInstance = keeperHandTarget,
				WaitForKeeperContact = true,
				DurationOverride = shotTravelDuration > 0.1 and shotTravelDuration or nil,
				IsSpecialShot = useSpecialShoot,
				EnableFlightEffects = isPerfectShoot,
				IsCenter = isCenterShotTarget(shotTargetId),
				HoldDurationOverride = goalHoldDurationOverride,
				HandSnapBlendDuration = MatchKeeperConfig.GoalHoldHandSnapBlendDuration,
				HandRetargetMinDuration = MatchKeeperConfig.GoalHoldHandRetargetMinDuration,
				HandRetargetMaxDuration = MatchKeeperConfig.GoalHoldHandRetargetMaxDuration,
				DropAfterFinish = success and (MatchKeeperConfig.GoalBallDropEnabled ~= false),
				DropDelay = MatchKeeperConfig.GoalBallDropDelay,
				DropDuration = MatchKeeperConfig.GoalBallDropDuration,
				DropDistance = MatchKeeperConfig.GoalBallDropDistance,
				DropBounceHeight = MatchKeeperConfig.GoalBallDropBounceHeight,
				RollAfterDrop = success == true,
				RollDirection = (ballEndPos - startPos),
				RollSpeed = isPerfectShoot and 12.0 or 8.0,
				RollDeceleration = 5.5,
				ImpactAtFinish = isPerfectShoot,
				ImpactEmitCount = goalImpactEmitCount,
				ImpactLifetime = goalImpactLifetime,
				OnHoldStart = function()
					if MatchShootCinematicDirector.ShakeActiveCamera then
						-- Center gets heavier shake at hold start
						local centerShot = isCenterShotTarget(shotTargetId)
						local shakeStr = centerShot and 1.2 or 0.35
						local shakeDur = centerShot and 0.55 or 0.45
						MatchShootCinematicDirector.ShakeActiveCamera(shakeStr, shakeDur)
					end
					-- Perpanjang FX bola perfect shoot agar tetap menyala selama hold berlangsung
					if isPerfectShoot and self.MatchBallController and self.MatchBallController.ActivateActionSpecialEffects then
						self.MatchBallController:ActivateActionSpecialEffects(goalHoldDurationOverride + 0.2)
					end
				end,
				OnHoldRelease = function()
					if MatchShootCinematicDirector.ShakeActiveCamera then
						MatchShootCinematicDirector.ShakeActiveCamera(2.0, 0.65)
					end
					if self.MatchKeeperPresentationController and self.MatchKeeperPresentationController.DropKeeperFromGoalHold then
						local kModel = nil
						if MatchActorResolver and MatchActorResolver.GetEnemyModelByStep then
							kModel = MatchActorResolver.GetEnemyModelByStep(5)
						end
						if kModel then
							self.MatchKeeperPresentationController:DropKeeperFromGoalHold(kModel)
						end
					end
				end,
				OnImpactAtFinish = function(impactPosition)
					if success then
						triggerGoalNetImpact()
					end

					if isPerfectShoot then
						stopExcellentSpeedEffect(self)
					end

					if success and isPerfectShoot then
						if MatchShootCinematicDirector.ShakeActiveCamera then
							MatchShootCinematicDirector.ShakeActiveCamera(goalImpactShakeStrength, goalImpactShakeDuration)
						end
						triggerKeeperGoalImpactRagdoll(self, payload, impactPosition, shotTargetId)
					end
				end,
			})
		else
			self.MatchBallController:PlayEpicShot(releaseStartPos, shotFlightEndPos, success, shootTier, {
				IsSpecialShot = useSpecialShoot,
				EnableFlightEffects = isPerfectShoot,
				TargetInstance = shotFlightTargetInstance,
				DropAfterFinish = success and not shouldPowerBreakthrough and (MatchKeeperConfig.GoalBallDropEnabled ~= false),
				DropDelay = MatchKeeperConfig.GoalBallDropDelay,
				DropDuration = MatchKeeperConfig.GoalBallDropDuration,
				DropDistance = MatchKeeperConfig.GoalBallDropDistance,
				DropBounceHeight = MatchKeeperConfig.GoalBallDropBounceHeight,
				RollAfterDrop = success == true and not shouldPowerBreakthrough,
				RollDirection = (ballEndPos - startPos),
				RollSpeed = isPerfectShoot and 12.0 or 8.0,
				RollDeceleration = 5.5,
				ImpactAtFinish = isPerfectShoot and not shouldPowerBreakthrough,
				ImpactEmitCount = goalImpactEmitCount,
				ImpactLifetime = goalImpactLifetime,
				OnImpactAtFinish = function(impactPosition)
					if success then
						triggerGoalNetImpact()
					end

					if shouldPowerBreakthrough then
						local impactContactPayload = {}
						if type(resolvedContactPayload) == "table" then
							for key, value in pairs(resolvedContactPayload) do
								impactContactPayload[key] = value
							end
						end

						impactContactPayload.ContactCFrame = CFrame.new(impactPosition)
						impactContactPayload.ContactPosition = impactPosition
						impactContactPayload.ShotTargetId = shotTargetId
						impactContactPayload.Reason = "power-breakthrough-flight-impact"

						handleKeeperPowerBreakthroughContact(impactContactPayload)
						return
					end

					if isPerfectShoot then
						stopExcellentSpeedEffect(self)
					end

					if success and not shouldPowerBreakthrough and isPerfectShoot then
						if MatchShootCinematicDirector.ShakeActiveCamera then
							MatchShootCinematicDirector.ShakeActiveCamera(goalImpactShakeStrength, goalImpactShakeDuration)
						end
						triggerKeeperGoalImpactRagdoll(self, payload, impactPosition, shotTargetId)
					end
				end,
			})
		end
		if useSpecialShoot then
			playMatchSound("ShootSpecial", { Volume = 1.0, Lifetime = 4 })
			playMatchSound("BallFlying", { Volume = 0.85, Lifetime = 4 })
		else
			playMatchSound("WhooshKick", { Volume = 0.95, Lifetime = 3 })
		end

		if (not success) or shouldPowerBreakthrough then
			-- Catch/parry/breakthrough ball ownership is driven by keeper animation markers.
			-- Fallback keeps old behavior safe when artist markers are missing.
			startKeeperContactFallback()
		end
	end

	task.defer(function()
		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		if self.MatchKeeperPresentationController and shouldRunKeeperReaction then
			local keeperReactionTarget = success and (holdPos or shotTargetPos) or ballEndPos

			local keeperContactMinDelay = nil
			if (not success) and shouldCatchSave then
				keeperContactMinDelay = (shotTravelDuration * (tonumber(MatchKeeperConfig.KeeperCatchLockContactMinDelayAlpha) or 0.82))
					+ (tonumber(MatchKeeperConfig.KeeperCatchLockContactMinDelayPadding) or 0.03)
			end

			-- Compute GoalHold duration to match what PlayGoalHoldShot will use
			local isCenterShot = isCenterShotTarget(shotTargetId)
			local goalHoldDuration = 0.8 -- Yellow default
			if useSpecialShoot then
				goalHoldDuration = 1.8
			elseif isPerfectShoot then
				goalHoldDuration = 1.2
			end
			-- Center gets extra hold time for dramatic effect
			if isCenterShot then
				goalHoldDuration = goalHoldDuration + 0.4
			end
			goalHoldDuration += math.max(tonumber(MatchKeeperConfig.GoalHoldExtraHoldDuration) or 0, 0)

			self.MatchKeeperPresentationController:ReactToShot(
				success,
				keeperReactionTarget,
				shootTier,
				shotTargetId,
				{
					OnCatchContact = handleKeeperCatchContact,
					OnSaveContact = handleKeeperSaveContact,
					OnPowerBreakthroughContact = handleKeeperPowerBreakthroughContact,
					OnGoalHoldContact = handleKeeperGoalHoldContact,
					GoalHoldDuration = success and goalHoldDuration or nil,
					ContactMinDelaySeconds = keeperContactMinDelay,
					ShotTravelDuration = shotTravelDuration,
					PowerBreakthroughCarryTargetPosition = shouldPowerBreakthrough and ballEndPos or nil,
				}
			)
		end
	end)
end

	local activeShootTrack = nil
	local activeShootIsSpecial = false

	local function getBallPosition()
		return getOfficialBallPosition(self, startPos)
	end

local function playShoot()
		if not self:_isSessionActive(payload.SessionId) then
			return nil
		end

		activeSpecialImpactFired = false
		activeSpecialImpactParameter = nil
		cleanupSpecialImpactResources()

		activeSpecialImpactEvent = Instance.new("BindableEvent")

		if useSpecialShoot then
			playMatchSound("WhooshSpinSlow", { Volume = 0.85, Lifetime = 3 })

			setOfficialBallVisible(self, false)
			stopSpecialEmbeddedBallGuard(false)
			stopEmbeddedBallVisibilityGuard = startSpecialEmbeddedBallVisibilityGuard(self, payload.SessionId, actorModel)
		else
			hideActorEmbeddedBall(self, actorModel)
			setOfficialBallVisible(self, true)
		end

		local shootAnimationResult = playShootAnimation(self, actorModel, 1.0, {
			UseSpecial = useSpecialShoot,
			OnImpactMarker = fireSpecialImpactFromMarker,
			OnSpecialImpactMarker = fireSpecialImpactFromMarker,
		})

		activeShootTrack = shootAnimationResult and shootAnimationResult.Track or nil
		activeShootIsSpecial = shootAnimationResult and shootAnimationResult.IsSpecialShoot == true or false

		if activeShootTrack then
			activeSpecialMarkerConnection = shootAnimationResult.MarkerConnection

			if useSpecialShoot then
				setOfficialBallVisible(self, false)
				setActorEmbeddedBallVisualsHidden(actorModel, true)
			end

			if activeSpecialImpactEvent then
				shootAnimationResult.ImpactSignal = activeSpecialImpactEvent.Event
				shootAnimationResult.WaitForExternalImpact = shootAnimationResult.MarkerConnected == true
				shootAnimationResult.WasImpactFired = function()
					return activeSpecialImpactFired == true
				end
				shootAnimationResult.GetPendingImpactParameter = function()
					return activeSpecialImpactParameter
				end
			end
		else
			cleanupSpecialImpactResources()
			stopSpecialEmbeddedBallGuard(true)
			setOfficialBallVisible(self, true)
		end

		return shootAnimationResult
	end
	local stopShooterIdleGuard = nil
	local stopResultAnimationGuard = nil
	local resultAnimationPlayed = false
	-- successCrowdAudioPlayed declared at top of _handleShootResolved
	local shootCameraReleased = false

	local function playResultSequence(reason)
		if resultAnimationPlayed then
			return
		end

		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		resultAnimationPlayed = true
		if success == true then
			if not goalNetImpactTriggered then
				triggerGoalNetImpact()
			end
		else
			playMatchSound("Booing", { Volume = 0.75, Lifetime = 5 })
			playMatchSound("Whistle", { Volume = 0.75, Lifetime = 4 })
		end
		stopSpecialEmbeddedBallGuard(true)

		if self.MatchBattleCameraController then
			self.MatchBattleCameraController:OnShootEnd()
		end

		if stopShooterIdleGuard then
			stopShooterIdleGuard()
			stopShooterIdleGuard = nil
		end

		stopForcedPostKickIdleTrack(self)

		stopExcellentSpeedEffect(self)

		if stopFreezeGuard then
			stopFreezeGuard()
			stopFreezeGuard = nil
		end

		self:_stopAllFieldMovementAfterShot(payload.ActorSlot, actorModel)

		if self.FrozenRigModels then
			self.FrozenRigModels[actorModel] = nil
		end

		if self.AnimationStates and self.AnimationStates[actorModel] then
			self.AnimationStates[actorModel] = nil
		end

		stopShootAnimationTracks(actorModel, 0)
		stopNonIdleShooterTracks(actorModel, 0, false)

		RunService.RenderStepped:Wait()

		if stopResultAnimationGuard then
			stopResultAnimationGuard()
			stopResultAnimationGuard = nil
		end

		stopResultAnimationGuard = playShooterResultOneShot(self, payload.SessionId, actorModel, success)

		if success == true then
			if not goalNetImpactTriggered then
				triggerGoalNetImpact()
			end
		end

		self:_idleAllEnemiesAfterShot()
		self:_playCompanionResultAnimations(success, payload.ActorSlot)
	end

	local function returnShooterToIdleAfterKick()
		-- Cancel the old refresh guard. After impact we want natural follow-through,
		-- not a repeated forced idle every 0.05s.
		if stopShooterIdleGuard then
			stopShooterIdleGuard()
			stopShooterIdleGuard = nil
		end

		self.ShooterPostKickIdleToken = (self.ShooterPostKickIdleToken or 0) + 1
		local followThroughToken = self.ShooterPostKickIdleToken

		stopForcedPostKickIdleTrack(self)

		-- Let the kicking leg continue forward naturally after ball release.
		if activeShootTrack then
			pcall(function()
				activeShootTrack.Looped = false
				activeShootTrack:AdjustSpeed(activeShootIsSpecial and SPECIAL_SHOOT_PLAYBACK_SPEED or SHOOT_FOLLOW_THROUGH_PLAYBACK_SPEED)
			end)
		end

		local followThroughSeconds = activeShootIsSpecial and SPECIAL_SHOOT_FOLLOW_THROUGH_SECONDS or SHOOT_FOLLOW_THROUGH_SECONDS

		task.delay(followThroughSeconds, function()
			if not self:_isSessionActive(payload.SessionId) then
				return
			end

			if resultAnimationPlayed then
				return
			end

			if self.ShooterPostKickIdleToken ~= followThroughToken then
				return
			end

			-- Now the follow-through has had time to read visually.
			stopShootAnimationTracks(actorModel, POST_IMPACT_IDLE_FADE_TIME)
			stopNonIdleShooterTracks(actorModel, POST_IMPACT_IDLE_FADE_TIME, false)

			if resultAnimationPlayed then
				return
			end

			forceShooterIdleNow(self, actorModel)
		end)
	end

	local cinematicTravelDuration = shotTravelDuration
	if success and isPerfectShoot then
		local isCenterShot = isCenterShotTarget(shotTargetId)
		local goalHoldDuration = 0.8
		if useSpecialShoot then
			goalHoldDuration = 1.8
		elseif isPerfectShoot then
			goalHoldDuration = 1.2
		end
		if isCenterShot then
			goalHoldDuration = goalHoldDuration + 0.4
		end
		goalHoldDuration += math.max(tonumber(MatchKeeperConfig.GoalHoldExtraHoldDuration) or 0, 0)

		local config = MatchBallConfig and MatchBallConfig.GoalHoldShot or {}
		local holdAlpha = math.clamp(config.HoldAlpha or 0.72, 0.1, 0.95)
		local phase2Multiplier = config.Phase2SpeedMultiplier or 1.45
		
		local phase1Dur = shotTravelDuration * holdAlpha
		local phase3Dur = (shotTravelDuration * (1 - holdAlpha)) / phase2Multiplier
		cinematicTravelDuration = phase1Dur + goalHoldDuration + phase3Dur + 0.08
	end

	MatchShootCinematicDirector.PlayNormalShootCinematic({
		SessionId = payload.SessionId,
		ActorRoot = actorRoot,
		ActorModel = actorModel,
		StartPos = startPos,
		EndPos = shotTargetPos,
		BallEndPos = ballEndPos,
		ShotTargetId = shotTargetId,
		ShotTravelDuration = cinematicTravelDuration,
		CameraController = self.MatchBattleCameraController,
		ShakeStrength = isPerfectShoot and 1.95 or (success and 1.35 or 0.72),
		ShakeDuration = isPerfectShoot and 0.40 or (success and 0.30 or 0.22),
		ShakeFadeIn = isPerfectShoot and 0.05 or 0.04,
		ShakeFadeOut = isPerfectShoot and 0.26 or 0.18,
		FlightShakeStrength = isPerfectShoot and 0.14 or (success and 0.07 or 0.035),
		FlightShakeFrequency = isPerfectShoot and 18.0 or 14.0,
		GetBallPosition = getBallPosition,
		SessionAlive = function()
			return self:_isSessionActive(payload.SessionId)
		end,
		OnKickWindup = playShoot,
		IsSpecialShoot = useSpecialShoot,
		TimeScaleMultiplier = 3.33, -- Matches 0.3x TimeScale (1 / 0.3)
		OnImpact = function()
			releaseShotBall()
			returnShooterToIdleAfterKick()
		end,
		OnResultCameraReady = function()
			playResultSequence("behind-shooter-camera")
		end,
		PostResultBackHold = 2.15,
		KeepCameraLockedAfterFinish = true,
	})

	if success then
		-- The cinematic function is synchronous and returns after OnResultCameraReady has
		-- already started the Win animation. Do not force the shooter back to Idle here,
		-- otherwise the post-goal idle refresh will immediately suppress Win/Lose visuals.
		if self:_isSessionActive(payload.SessionId) then
			-- BallController now owns goal-finish drop via PlayEpicShot/ContinueShotFromKeeper.
			-- Do not snap the ball back to the goal target here, otherwise it can pop upward then drop twice.
			if not (self.MatchBallController and self.MatchBallController.DropBallToGround and MatchKeeperConfig.GoalBallDropEnabled ~= false) then
				self:_holdBallAtFinalPose(ballEndPos)
			end
			if isPerfectShoot and self._emitGoalParticles then
				self:_emitGoalParticles({
					GoldFireworks = useSpecialShoot,
				})
			end
		end
	elseif self.MatchBallController then
		-- Failed shot rebound is scheduled at impact time inside releaseShotBall().
		-- Keeping it there makes the ball block/rebound sync with the keeper save point.
	end

	task.wait(POST_SHOT_SETTLE_DELAY)
	playResultSequence("post-cinematic-fallback")

	task.wait(RESULT_UI_DELAY)

	-- Goal climax: extra hold so the GOAL! popup is savored before result appears
	if success and self:_isSessionActive(payload.SessionId) then
		task.wait(GOAL_CELEBRATION_EXTRA_HOLD)
	end

	if self:_isSessionActive(payload.SessionId) and self.MatchUIController then
		self.MatchUIController:ShowMatchResult(success, payload)
	end
	notifyShootPostActionReady("shoot result ui ready")

	if stopFreezeGuard then
		stopFreezeGuard()
	end

	task.wait(1.25)

	if stopShooterIdleGuard then
		stopShooterIdleGuard()
		stopShooterIdleGuard = nil
	end

	cleanupSpecialImpactResources()
	stopSpecialEmbeddedBallGuard(true)
	if stopGreenActionFx then
		stopGreenActionFx()
		stopGreenActionFx = nil
	end
	
	-- Release local actor runtime ownership after the shoot/result cinematic window.
	-- This is intentionally late so non-shooter companions cannot resume Run targets
	-- during ball follow / Win-Lose readability.
	releaseShootRuntimeOverrides()

	-- Keep shoot result camera locked behind the player until match cleanup/teleport.
	-- MatchPresentationCleanup calls MatchShootCinematicDirector.Stop() when the session ends.
	if self.ActiveShootSessionLock == sessionId then
		self.ActiveShootSessionLock = nil
	end
end
end
