local Constants = require(script.Parent.MatchPresentationConstants)

local State = {}

function State.CreateControllerDefinition()
	return {
		Name = "MatchPresentationController",
		CurrentSessionId = nil,
		CurrentPlayerSpawnRootCFrame = nil,
		PlayerProxy = nil,
		RuntimeFolder = nil,
		AnimationStates = {},
		PlayerHiddenParts = {},
		PlayerHiddenGuiStates = {},
		CutsceneCollisionRecords = {},
		IntroVisualReadySessions = {},
		LocalCharacterHideGuardConnection = nil,
		IsApproachBusy = false,
		IsPostActionBusy = false,

		LastPreparedPreQteStepIndex = 0,
		LastCompletedPostActionStepIndex = 0,

		TimeScale = Constants.DEFAULT_TIME_SCALE,
		ActiveActorSlot = nil,
		ActiveEnemyRuntimeSlot = nil,
		CurrentPresentationStepIndex = 0,
		CurrentPresentationAction = nil,
		IdleEnemyMotionToken = 0,
		AllyPatrolMotionToken = 0,
		CutsceneCollisionGroupReady = false,
		SupportMotionToken = 0,
		FrozenRigModels = {},
		IsPreQteFrozen = false,
		HiddenEmbeddedBallParts = {},
		DefeatedEnemyRecoveryTokens = {},
		EnemyMotionLocks = {},
		QteFreezeToken = 0,
		EmbeddedBallGuardToken = 0,
		PostShotLockToken = 0,
		ShootCinematicFreezeToken = 0,
		IsShootCinematicFrozen = false,
		ActiveShootSessionLock = nil,
		ShooterResultAnimationToken = 0,
		ActiveShooterResultTrack = nil,
		ActiveShooterResultAnimationCleanup = nil,

		ActorLookAtToken = 0,
		ActorLookAtConnection = nil,
		ActorLookAtRecords = {},

		CurrentSessionWins = 0,
		CurrentSessionGoals = 0,

		MatchService = nil,
		MatchCompanionVisualController = nil,
		MatchBattleCameraController = nil,
		MatchBallController = nil,
		MatchKeeperPresentationController = nil,
		MatchSpawnLayoutController = nil,
		MatchUIController = nil,
		UIController = nil,
		MatchActorRuntimeController = nil,
	}
end

function State.Attach(MatchPresentationController, Context)
	local Services = Context.Services
	local RunService = Services.RunService
	local Workspace = Services.Workspace
	local PhysicsService = Services.PhysicsService

	local LocalPlayer = Context.LocalPlayer

	local MatchActorResolver = Context.MatchActorResolver
	local MatchGrounding = Context.MatchGrounding
	local MatchSceneQuery = Context.MatchSceneQuery
	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath
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

	local function buildPlayerProxySpawnRootCFrame(spawnPart, fallbackCFrame, proxyModel, serverRootCFrame)
		if typeof(serverRootCFrame) == "CFrame" then
			return serverRootCFrame
		end

		if spawnPart and spawnPart:IsA("BasePart") then
			local targetRootCFrame = CFrame.new(spawnPart.Position)
				* (spawnPart.CFrame - spawnPart.Position)

			if proxyModel and MatchGrounding then
				return MatchGrounding.GetGroundedCharacterRootCFrame(proxyModel, targetRootCFrame, {
					IgnoreMatchRuntimeRoot = true,
					IgnorePresentationRuntime = true,
					IgnoreSpawnedEnemies = true,
					FallbackY = spawnPart.Position.Y + MatchGrounding.GetCharacterRootGroundClearance(proxyModel),
				})
			end

			local groundedY = GetGroundedY(spawnPart.Position, nil)
			return CFrame.new(spawnPart.Position.X, groundedY, spawnPart.Position.Z)
				* (spawnPart.CFrame - spawnPart.Position)
		end

		return fallbackCFrame
	end

	local function applyPlayerProxyRootCFrame(proxyModel, targetRootCFrame)
		if not proxyModel or not targetRootCFrame then
			return
		end

		-- Server match teleport snaps HumanoidRootPart directly. Do the same for
		-- the local proxy so Model pivot offsets cannot spawn it above ground.
		ApplyPivot(proxyModel, targetRootCFrame)

		local root = GetRootPart(proxyModel)
		if root and root:IsA("BasePart") then
			root.CFrame = targetRootCFrame
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end

	function MatchPresentationController:_setTimeScale(scale)
		local numericScale = tonumber(scale) or DEFAULT_TIME_SCALE
		self.TimeScale = math.max(numericScale, 0.01)
	end

	function MatchPresentationController:_getScaledDeltaTime(deltaTime)
		return math.max(deltaTime or 0, 0) * (self.TimeScale or DEFAULT_TIME_SCALE)
	end

	function MatchPresentationController:_getScaledAnimationSpeed(speed)
		local baseSpeed = tonumber(speed) or 1

		-- Animation should stay visually normal.
		-- TimeScale only affects movement delta, not animation playback speed.
		return math.max(baseSpeed, 0.03)
	end

	function MatchPresentationController:_stopSupportMotion()
		self.SupportMotionToken = (self.SupportMotionToken or 0) + 1

		if self.ForwardRunnerTokens then
			for runnerSlot in pairs(self.ForwardRunnerTokens) do
				self.ForwardRunnerTokens[runnerSlot] = (self.ForwardRunnerTokens[runnerSlot] or 0) + 1
			end
		end

		if self.ActiveForwardRunners then
			table.clear(self.ActiveForwardRunners)
		end
	end

	function MatchPresentationController:_handleStepStarted(payload)
	if not payload then
		return
	end

	self.CurrentPresentationStepIndex = tonumber(payload.StepIndex) or self.CurrentPresentationStepIndex
	self.CurrentPresentationAction = payload.Action

	if payload.Action == "Shoot" then
		self:_stopSupportMotion()
		self.IdleEnemyMotionToken += 1

		if self._resetMatchActorLookAt then
			self:_resetMatchActorLookAt()
		end
	end
end

	function MatchPresentationController:_ensureCutsceneCollisionGroup()
		if self.CutsceneCollisionGroupReady then
			return true
		end

		local ok = pcall(function()
			PhysicsService:RegisterCollisionGroup(CUTSCENE_ACTOR_COLLISION_GROUP)
		end)

		-- Ignore "already registered" style failure.
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(
				CUTSCENE_ACTOR_COLLISION_GROUP,
				CUTSCENE_ACTOR_COLLISION_GROUP,
				false
			)
		end)

		self.CutsceneCollisionGroupReady = true
		return ok or true
	end

	function MatchPresentationController:_applyCollisionGroupToInstance(instance)
		if not instance then
			return
		end

		self:_ensureCutsceneCollisionGroup()

		local function applyPart(part)
			if part and part:IsA("BasePart") then
				self.CutsceneCollisionRecords = self.CutsceneCollisionRecords or {}
				if self.CutsceneCollisionRecords[part] == nil then
					self.CutsceneCollisionRecords[part] = {
						CollisionGroup = part.CollisionGroup,
						CanCollide = part.CanCollide,
						CanTouch = part.CanTouch,
						CanQuery = part.CanQuery,
						Massless = part.Massless,
					}
				end

				part.CollisionGroup = CUTSCENE_ACTOR_COLLISION_GROUP
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Massless = true

				-- Cutscene actors are PivotTo-driven. Clearing residual physics velocity
				-- prevents rare bounce when two rigs overlap before collision refresh finishes.
				pcall(function()
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end

		if instance:IsA("BasePart") then
			applyPart(instance)
			return
		end

		applyPart(instance)

		for _, descendant in ipairs(instance:GetDescendants()) do
			applyPart(descendant)
		end
	end

	function MatchPresentationController:_refreshCutsceneCollisionGroups()
		self:_ensureCutsceneCollisionGroup()

		local localCharacter = LocalPlayer.Character
		if localCharacter then
			self:_applyCollisionGroupToInstance(localCharacter)
		end

		if self.PlayerProxy then
			self:_applyCollisionGroupToInstance(self.PlayerProxy)
		end

		for slotNumber = 2, 4 do
			local actorModel = self:_getControlledActorModel(slotNumber)
			if actorModel then
				self:_applyCollisionGroupToInstance(actorModel)
			end
		end

		local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
		if enemiesFolder then
			for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
				self:_applyCollisionGroupToInstance(enemyModel)
			end
		end
	end

	function MatchPresentationController:_isSessionActive(sessionId)
		return self.CurrentSessionId ~= nil and self.CurrentSessionId == tostring(sessionId)
	end

	function MatchPresentationController:_destroyStalePlayerProxies(keepInstance)
		local runtimeFolder = self.RuntimeFolder
		if not runtimeFolder or not runtimeFolder.Parent then
			runtimeFolder = Workspace:FindFirstChild(PRESENTATION_FOLDER_NAME)
		end

		if not runtimeFolder then
			return 0
		end

		local destroyedCount = 0
		for _, child in ipairs(runtimeFolder:GetChildren()) do
			if child ~= keepInstance and child.Name == PLAYER_PROXY_NAME then
				child:Destroy()
				destroyedCount += 1
			end
		end

		return destroyedCount
	end

	function MatchPresentationController:_clearIntroVisualReady(sessionId)
		if sessionId == nil then
			table.clear(self.IntroVisualReadySessions)
			return
		end

		self.IntroVisualReadySessions[tostring(sessionId)] = nil
	end

	function MatchPresentationController:_markIntroVisualReady(sessionId)
		local key = tostring(sessionId or self.CurrentSessionId or "")
		if key == "" then
			return false
		end

		self.IntroVisualReadySessions[key] = true
		return true
	end

	function MatchPresentationController:IsIntroVisualReady(sessionId)
		return self.IntroVisualReadySessions[tostring(sessionId or "")] == true
	end

	function MatchPresentationController:WaitForIntroVisualReady(sessionId, timeoutSeconds)
		local key = tostring(sessionId or "")
		if key == "" then
			return false
		end

		if self:IsIntroVisualReady(key) then
			return true
		end

		local deadline = os.clock() + math.max(tonumber(timeoutSeconds) or 1.25, 0)
		while os.clock() < deadline do
			if self:IsIntroVisualReady(key) then
				return true
			end

			RunService.RenderStepped:Wait()
		end

		return self:IsIntroVisualReady(key)
	end

	function MatchPresentationController:_ensureRuntimeFolder()
		if self.RuntimeFolder and self.RuntimeFolder.Parent then
			self:_destroyStalePlayerProxies(self.PlayerProxy)
			return self.RuntimeFolder
		end

		local existingFolder = Workspace:FindFirstChild(PRESENTATION_FOLDER_NAME)
		if existingFolder and existingFolder:IsA("Folder") then
			self.RuntimeFolder = existingFolder
			self:_destroyStalePlayerProxies(self.PlayerProxy)
			return existingFolder
		end

		local folder = Instance.new("Folder")
		folder.Name = PRESENTATION_FOLDER_NAME
		folder.Parent = Workspace
		self.RuntimeFolder = folder
		return folder
	end

	function MatchPresentationController:_setCharacterHidden(hidden)
		local character = LocalPlayer.Character
		if not character then
			return
		end

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if hidden then
					if self.PlayerHiddenParts[descendant] == nil then
						self.PlayerHiddenParts[descendant] = descendant.LocalTransparencyModifier
					end
					descendant.LocalTransparencyModifier = 1
				else
					descendant.LocalTransparencyModifier = self.PlayerHiddenParts[descendant] or 0
				end
			elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") or descendant:IsA("Highlight") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") or descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
				if hidden then
					if self.PlayerHiddenGuiStates[descendant] == nil then
						self.PlayerHiddenGuiStates[descendant] = descendant.Enabled
					end
					descendant.Enabled = false
				else
					local previousEnabled = self.PlayerHiddenGuiStates[descendant]
					if previousEnabled ~= nil then
						descendant.Enabled = previousEnabled
					end
				end
			end
		end

		if not hidden then
			table.clear(self.PlayerHiddenParts)
			table.clear(self.PlayerHiddenGuiStates)
		end
	end

	function MatchPresentationController:_startLocalCharacterHideGuard()
		if self.LocalCharacterHideGuardConnection then
			return
		end

		self:_setCharacterHidden(true)
		self.LocalCharacterHideGuardConnection = RunService.RenderStepped:Connect(function()
			self:_setCharacterHidden(true)
		end)
	end

	function MatchPresentationController:_stopLocalCharacterHideGuard()
		if self.LocalCharacterHideGuardConnection then
			self.LocalCharacterHideGuardConnection:Disconnect()
			self.LocalCharacterHideGuardConnection = nil
		end
	end

	function MatchPresentationController:PrepareLocalCharacterForMatchTransition()
		self:_startLocalCharacterHideGuard()
	end

	function MatchPresentationController:CancelLocalCharacterMatchTransition()
		self:_stopLocalCharacterHideGuard()
		-- Destroy proxy jika ada — ini bisa terjadi jika PrepareLocalCharacterForMatchTransition
		-- sudah dipanggil (membuat proxy) tapi match di-cancel sebelum MatchSessionStarted.
		-- Tanpa ini, character tetap hidden dan proxy terus ada di workspace.
		if self.PlayerProxy and self.PlayerProxy.Parent then
			self:_destroyPlayerProxy()
		else
			self:_setCharacterHidden(false)
		end
	end

	function MatchPresentationController:_sanitizePlayerProxyOverhead(proxyModel)
		if not proxyModel then
			return
		end

		local humanoid = proxyModel:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			humanoid.NameDisplayDistance = 0
			humanoid.HealthDisplayDistance = 0
		end

		for _, descendant in ipairs(proxyModel:GetDescendants()) do
			if descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
				descendant:Destroy()
			end
		end
	end

	local function SetPlayerProxyHidden(proxyModel, hidden)
		if not proxyModel then
			return
		end

		for _, descendant in ipairs(proxyModel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
	end

	local function StabilizePlayerProxyPhysics(proxyModel)
		if not proxyModel then
			return
		end

		local humanoid = proxyModel:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = false
			humanoid.PlatformStand = false
			pcall(function()
				humanoid:Move(Vector3.zero, false)
			end)
		end

		for _, descendant in ipairs(proxyModel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Massless = true

				if descendant.Name == "HumanoidRootPart" then
					descendant.Anchored = true
				end

				pcall(function()
					descendant.AssemblyLinearVelocity = Vector3.zero
					descendant.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end
	end

	function MatchPresentationController:_stabilizePlayerProxy()
		StabilizePlayerProxyPhysics(self.PlayerProxy)
	end

	function MatchPresentationController:_ensurePlayerProxy()
		if self.PlayerProxy and self.PlayerProxy.Parent then
			self:_destroyStalePlayerProxies(self.PlayerProxy)
			self:_sanitizePlayerProxyOverhead(self.PlayerProxy)
			StabilizePlayerProxyPhysics(self.PlayerProxy)
			ForceModelVisible(self.PlayerProxy)
			return self.PlayerProxy
		end

		self:_destroyStalePlayerProxies(nil)

		local character = LocalPlayer.Character
		if not character then
			return nil
		end

		local previousArchivable = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = previousArchivable

		for _, descendant in ipairs(clone:GetDescendants()) do
			if descendant:IsA("BaseScript") then
				descendant:Destroy()
			end

			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = 0
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Massless = true
				pcall(function()
					descendant.AssemblyLinearVelocity = Vector3.zero
					descendant.AssemblyAngularVelocity = Vector3.zero
				end)

				if descendant.Name == "HumanoidRootPart" then
					descendant.Anchored = true
					descendant.Transparency = 1
				else
					descendant.Anchored = false

					if descendant.Transparency >= 1 then
						descendant.Transparency = 0
					end
				end
			end
		end

		self:_sanitizePlayerProxyOverhead(clone)

		clone.Name = PLAYER_PROXY_NAME

		local spawnPart = MatchSceneQuery.GetPlayerSpawn()

		local finalProxyRootCFrame =
			buildPlayerProxySpawnRootCFrame(spawnPart, character:GetPivot(), clone, self.CurrentPlayerSpawnRootCFrame)

		SetPlayerProxyHidden(clone, true)
		applyPlayerProxyRootCFrame(clone, finalProxyRootCFrame)
		StabilizePlayerProxyPhysics(clone)
		clone.Parent = self:_ensureRuntimeFolder()
		SetPlayerProxyHidden(clone, true)
		applyPlayerProxyRootCFrame(clone, finalProxyRootCFrame)
		StabilizePlayerProxyPhysics(clone)

		self.PlayerProxy = clone
		self:_startLocalCharacterHideGuard()

		return clone
	end

	function MatchPresentationController:_resetPlayerProxyToSpawn()
		local proxy = self.PlayerProxy
		if not proxy or not proxy.Parent then
			return false
		end

		local spawnPart = MatchSceneQuery.GetPlayerSpawn()
		if not spawnPart and typeof(self.CurrentPlayerSpawnRootCFrame) ~= "CFrame" then
			return false
		end

		local spawnRootCFrame =
			buildPlayerProxySpawnRootCFrame(spawnPart, proxy:GetPivot(), proxy, self.CurrentPlayerSpawnRootCFrame)

		SetPlayerProxyHidden(proxy, true)
		StabilizePlayerProxyPhysics(proxy)
		applyPlayerProxyRootCFrame(proxy, spawnRootCFrame)
		StabilizePlayerProxyPhysics(proxy)
		SetPlayerProxyHidden(proxy, true)
		return true
	end

	function MatchPresentationController:_destroyPlayerProxy()
		self:_stopLocalCharacterHideGuard()
		if self.PlayerProxy then
			self.PlayerProxy:Destroy()
			self.PlayerProxy = nil
		end

		self:_destroyStalePlayerProxies(nil)
		self:_setCharacterHidden(false)
	end

	function MatchPresentationController:_setEmbeddedBallVisualsHidden(model, hidden)
		if not model then
			return
		end

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") and IsEmbeddedBallVisual(descendant) then
				if hidden then
					if self.HiddenEmbeddedBallParts[descendant] == nil then
						self.HiddenEmbeddedBallParts[descendant] = {
							Transparency = descendant.Transparency,
							LocalTransparencyModifier = descendant.LocalTransparencyModifier,
							CanCollide = descendant.CanCollide,
							CanTouch = descendant.CanTouch,
							CanQuery = descendant.CanQuery,
						}
					end

					descendant.Transparency = 1
					descendant.LocalTransparencyModifier = 1
					descendant.CanCollide = false
					descendant.CanTouch = false
					descendant.CanQuery = false
				else
					local original = self.HiddenEmbeddedBallParts[descendant]
					if original then
						descendant.Transparency = original.Transparency
						descendant.LocalTransparencyModifier = original.LocalTransparencyModifier
						descendant.CanCollide = original.CanCollide
						descendant.CanTouch = original.CanTouch
						descendant.CanQuery = original.CanQuery
						self.HiddenEmbeddedBallParts[descendant] = nil
					end
				end
			end
		end
	end

	function MatchPresentationController:_hideNonCarrierEmbeddedBalls(carrierSlot)
		-- Keep exactly one match ball: the official ball owned by self.MatchBallController.
		-- Any embedded ball inside player/companion/enemy rigs is always hidden during match.
		-- Previous logic allowed the active companion's embedded ball to remain visible,
		-- which caused double-ball visuals when self.MatchBallController also attached its ball.
		for slotNumber = 1, 4 do
			local actorModel = self:_getControlledActorModel(slotNumber)
			if actorModel then
				self:_setEmbeddedBallVisualsHidden(actorModel, true)
			end
		end

		local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
		if enemiesFolder then
			for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
				self:_setEmbeddedBallVisualsHidden(enemyModel, true)
			end
		end
	end

	function MatchPresentationController:_startEmbeddedBallVisualGuard(sessionId)
		-- Embedded soccer balls can be re-enabled by rig animation swaps or late runtime spawns.
		-- During match presentation, the official MatchBallController ball is the only visible ball.
		self.EmbeddedBallGuardToken = (self.EmbeddedBallGuardToken or 0) + 1

		local guardToken = self.EmbeddedBallGuardToken
		local targetSessionId = tostring(sessionId or self.CurrentSessionId or "")

		task.spawn(function()
			local accumulatedTime = 0

			while self:_isSessionActive(targetSessionId)
				and self.EmbeddedBallGuardToken == guardToken
			do
				local deltaTime = RunService.RenderStepped:Wait()
				accumulatedTime += deltaTime or 0

				if accumulatedTime >= 0.08 then
					accumulatedTime = 0
					self:_hideNonCarrierEmbeddedBalls(self.ActiveActorSlot)
				end

				for part, _ in pairs(self.HiddenEmbeddedBallParts) do
					if part and part.Parent then
						part.Transparency = 1
						part.LocalTransparencyModifier = 1
					end
				end
			end
		end)
	end

	function MatchPresentationController:_restoreEmbeddedBallVisuals()
		for part, original in pairs(self.HiddenEmbeddedBallParts) do
			if part and part.Parent and original then
				part.Transparency = original.Transparency
				part.LocalTransparencyModifier = original.LocalTransparencyModifier
				part.CanCollide = original.CanCollide
				part.CanTouch = original.CanTouch
				part.CanQuery = original.CanQuery
			end
		end

		table.clear(self.HiddenEmbeddedBallParts)
	end

	function MatchPresentationController:_getControlledActorModel(slotNumber)
		if tonumber(slotNumber) == 1 then
			return self:_ensurePlayerProxy()
		end

		if self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.GetLocalMatchActorModel
		then
			local runtimeModel = self.MatchActorRuntimeController:GetLocalMatchActorModel(
				LocalPlayer,
				tonumber(slotNumber)
			)

			if runtimeModel and runtimeModel.Parent then
				return runtimeModel
			end
		end

		if self.MatchCompanionVisualController
			and self.MatchCompanionVisualController.GetOwnedCompanionModels
		then
			local ownedCompanions = self.MatchCompanionVisualController:GetOwnedCompanionModels(LocalPlayer)
			local fallbackIndex = math.max((tonumber(slotNumber) or 2) - 1, 1)
			local fallbackModel = ownedCompanions[fallbackIndex]

			if fallbackModel and fallbackModel.Parent then
				return fallbackModel
			end
		end

		return MatchActorResolver.GetActorModelBySlot(slotNumber, self.PlayerProxy)
	end

	function MatchPresentationController:_isCompanionSlot(slotNumber)
		return tonumber(slotNumber or 1) ~= 1
	end

	function MatchPresentationController:_isDirectDrivenActor(slotNumber)
		return not self:_isCompanionSlot(slotNumber)
	end

	function MatchPresentationController:_getActorCurrentCFrame(slotNumber, actorModel)
		if self:_isCompanionSlot(slotNumber)
			and self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.GetLocalMatchActorCFrame
		then
			local anchorCFrame = self.MatchActorRuntimeController:GetLocalMatchActorCFrame(
				LocalPlayer,
				tonumber(slotNumber)
			)
			if anchorCFrame then
				return anchorCFrame
			end
		end

		if not self:_isCompanionSlot(slotNumber) then
			local root = GetRootPart(actorModel)
			if root and root:IsA("BasePart") then
				return root.CFrame
			end
		end

		if actorModel and actorModel:IsA("Model") then
			return actorModel:GetPivot()
		end

		local root = GetRootPart(actorModel)
		return root and root.CFrame or nil
	end

	function MatchPresentationController:_applyActorCFrame(slotNumber, actorModel, targetCFrame, options)
		if not targetCFrame then
			return false
		end

		if self:_isCompanionSlot(slotNumber)
			and self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.SetLocalMatchActorTarget
		then
			local ok = self.MatchActorRuntimeController:SetLocalMatchActorTarget(
				LocalPlayer,
				tonumber(slotNumber),
				targetCFrame,
				options or {}
			)

			if ok then
				return true
			end
		end

		if not self:_isCompanionSlot(slotNumber) then
			applyPlayerProxyRootCFrame(actorModel, targetCFrame)
			return false
		end

		ApplyPivot(actorModel, targetCFrame)
		return false
	end

	function MatchPresentationController:_hasActorReachedRuntimeTarget(slotNumber)
		if not self:_isCompanionSlot(slotNumber) then
			return true
		end

		if self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.HasLocalMatchActorReachedTarget
		then
			return self.MatchActorRuntimeController:HasLocalMatchActorReachedTarget(
				LocalPlayer,
				tonumber(slotNumber)
			) == true
		end

		return true
	end

	function MatchPresentationController:_hasActorSettledAtTarget(slotNumber, actorModel, actorTargetPos)
		local currentCFrame = self:_getActorCurrentCFrame(slotNumber, actorModel)
		if not currentCFrame or not actorTargetPos then
			return false
		end

		local withinDistance = GetFlatDistance(currentCFrame.Position, actorTargetPos)
			<= (THRESHOLDS.ActorArrive + PRE_QTE_READY_EXTRA_EPSILON)

		if not withinDistance then
			return false
		end

		if self:_isCompanionSlot(slotNumber) then
			return self:_hasActorReachedRuntimeTarget(slotNumber)
		end

		return true
	end

	function MatchPresentationController:_waitForSessionSeconds(sessionId, duration)
		local deadline = os.clock() + math.max(duration or 0, 0)

		while self:_isSessionActive(sessionId) and os.clock() < deadline do
			RunService.RenderStepped:Wait()
		end
	end

	function MatchPresentationController:_waitForPreviousVisualStep(payload)
		local currentStepIndex = tonumber(payload and payload.StepIndex) or 1
		if currentStepIndex <= 1 then
			return
		end

		local isPlayer2BranchQte4 = payload
			and currentStepIndex == 4
			and (
				payload.Player2Branch == true
				or payload.PassMode == "Player2BranchPass"
				or payload.SkipReason == "Player2DribbleQte2"
			)

		-- Player2 branch skips QTE3 server-side, so no client post-action step 3
		-- will complete. Waiting for step 3 here stalls QTE4 until the watchdog fires.
		local requiredCompletedStep = isPlayer2BranchQte4 and 2 or (currentStepIndex - 1)

		while self:_isSessionActive(payload.SessionId) do
			local completedStep = tonumber(self.LastCompletedPostActionStepIndex) or 0
			local approachBusy = self.IsApproachBusy == true
			local postActionBusy = self.IsPostActionBusy == true

			if (not approachBusy) and (not postActionBusy) and completedStep >= requiredCompletedStep then
				break
			end

			RunService.RenderStepped:Wait()
		end
	end

	function MatchPresentationController:_waitForPreviousStepPostAction(payload)
		local currentStepIndex = tonumber(payload and payload.StepIndex) or 1
		if currentStepIndex <= 1 then
			return
		end

		local requiredCompletedStep = currentStepIndex - 1

		while self:_isSessionActive(payload.SessionId) do
			local completedStep = tonumber(self.LastCompletedPostActionStepIndex) or 0

			if (not self.IsPostActionBusy) and completedStep >= requiredCompletedStep then
				break
			end

			RunService.RenderStepped:Wait()
		end
	end

	function MatchPresentationController:_notifyPresentationReady(stepIndex, phase)
		if not self.MatchService or not self.CurrentSessionId then
			return
		end

		local sessionId = self.CurrentSessionId
		task.spawn(function()
			if not self:_isSessionActive(sessionId) then
				return
			end

			pcall(function()
				self.MatchService:NotifyPresentationReady(sessionId, stepIndex, phase)
			end)
		end)
	end

	function MatchPresentationController:_getSpeedConfig(groupName, actionName)
		local group = ACTION_SPEEDS[groupName]
		return (group and group[actionName]) or (group and group.Default) or { Actor = 10, Enemy = 10 }
	end

	function MatchPresentationController:_buildActorMotionOptions(lookAtPosition, expectedAnimation, moveSpeed)
		return {
			ExpectedAnimation = expectedAnimation,
			FacingMode = "Idle",
			LookAtPosition = lookAtPosition,
			MoveSpeed = moveSpeed,
		}
	end

	function MatchPresentationController:_alignActorToLook(slotNumber, actorModel, worldPos, lookAtPosition, expectedAnimation, moveSpeed)
		self:_applyActorCFrame(
			slotNumber,
			actorModel,
			MatchMotionMath.BuildFlatLookAtCFrame(worldPos, lookAtPosition),
			self:_buildActorMotionOptions(lookAtPosition, expectedAnimation, moveSpeed)
		)
	end

	function MatchPresentationController:_getCombinedSpawnOffset(sessionId, stepIndex, slotNumber, controllerScale, extraX, extraZ, salt)
		local controllerOffset = Vector3.zero
		if self.MatchSpawnLayoutController and self.MatchSpawnLayoutController.GetRandomOffset then
			controllerOffset = self.MatchSpawnLayoutController:GetRandomOffset(stepIndex, slotNumber) or Vector3.zero
		end

		local stableOffset = BuildStableOffset(sessionId, stepIndex, slotNumber, extraX, extraZ, salt)

		return Vector3.new(
			(controllerOffset.X * controllerScale) + stableOffset.X,
			0,
			(controllerOffset.Z * controllerScale) + stableOffset.Z
		)
	end

	function MatchPresentationController:_setKeeperFocusWorldPosition(worldPosition)
		if self.MatchKeeperPresentationController
			and self.MatchKeeperPresentationController.SetFocusWorldPosition
			and worldPosition
		then
			self.MatchKeeperPresentationController:SetFocusWorldPosition(worldPosition)
		end
	end

	function MatchPresentationController:_clearKeeperFocusWorldPosition()
		if self.MatchKeeperPresentationController
			and self.MatchKeeperPresentationController.ClearFocusWorldPosition
		then
			self.MatchKeeperPresentationController:ClearFocusWorldPosition()
		end
	end
end

return State
