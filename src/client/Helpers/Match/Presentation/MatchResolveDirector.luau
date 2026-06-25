return function(MatchPresentationController, Context)
	local RunService = Context.Services.RunService
	local LocalPlayer = Context.LocalPlayer

	local MatchActorResolver = Context.MatchActorResolver
	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath
	local MatchBallConfig = Context.MatchBallConfig
	local MatchActionFxHelper = require(script.Parent.MatchActionFxHelper)
	local MatchAudioHelper = require(script.Parent.MatchAudioHelper)

	local Constants = Context.Constants
	local Utils = Context.Utils

	local DEFAULT_TIME_SCALE = Constants.DEFAULT_TIME_SCALE

	local RECEIVER_CATCH_UP_SPEED = Constants.RECEIVER_CATCH_UP_SPEED
	local RECEIVER_NEXT_QTE_BUFFER = Constants.RECEIVER_NEXT_QTE_BUFFER
	local PASS_RECEIVE_LANE_OFFSET = Constants.PASS_RECEIVE_LANE_OFFSET


	local PASS_DEFENDER_PRESS_AFTER_REACTION_SPEED = Constants.PASS_DEFENDER_PRESS_AFTER_REACTION_SPEED or 17.0

	local PASS_FACE_BEFORE_KICK_SECONDS = 0.14
	local PASS_KICK_START_SETTLE_SECONDS = 0.02

	local GREEN_ACTION_FX_DURATION = 1.45

	local function isGreenActionPayload(payload)
		return MatchActionFxHelper.IsGreenPayload(payload)
	end

	local function getQteTier(payload)
		if type(payload) ~= "table" then
			return nil
		end

		return payload.QteTier or payload.Tier or payload.ResultTier
	end

	local function isYellowActionPayload(payload)
		local tierName = string.upper(tostring(getQteTier(payload) or ""))
		return tierName == "YELLOW" or tierName == "SUCCESS"
	end

	local function playActionSound(key, options)
		return MatchAudioHelper.PlayKey(key, options or {})
	end

	local function activateGreenActionFx(self, payload, actorModel, duration)
		if not isGreenActionPayload(payload) then
			return nil
		end

		if self.MatchBallController and self.MatchBallController.ActivateActionSpecialEffects then
			self.MatchBallController:ActivateActionSpecialEffects(duration or GREEN_ACTION_FX_DURATION)
		end

		return MatchActionFxHelper.StartActorGreenFx(actorModel, {
			Duration = duration or GREEN_ACTION_FX_DURATION,
			CleanupDelay = 0.18,
		})
	end

	local function playActionCameraBoost(self, actionName, fromPosition, toPosition, tier)
		local cameraController = self.MatchBattleCameraController
		if not cameraController then
			return
		end

		local methodName = actionName == "Pass" and "OnPassActionBoost" or "OnDribbleActionBoost"
		local method = cameraController[methodName]
		if type(method) ~= "function" then
			methodName = actionName == "Pass" and "OnPerfectPassBoost" or "OnPerfectDribbleBoost"
			method = cameraController[methodName]
		end
		if type(method) ~= "function" then
			return
		end

		local ok, err = pcall(method, cameraController, fromPosition, toPosition, tier)
		if not ok then
			warn(string.format(
				"[MatchPresentationFlow] %s %s camera boost failed: %s",
				tostring(tier or "Green"),
				tostring(actionName),
				tostring(err)
			))
		end
	end

	-- Natural pass receive tuning.
	-- The pass arc is still resolved to the intended receive point, but the ball only
	-- attaches when the receiver is actually close. If the receiver is late or has
	-- overrun the target, the ball becomes a short loose/rolling ball first.
	local PASS_RECEIVE_CATCH_DISTANCE = 1.85
	local PASS_RECEIVE_OVERRUN_BUFFER = 2.25
	local LOOSE_PASS_NORMAL_ROLL_DISTANCE = 3.25
	local LOOSE_PASS_AHEAD_RECEIVER_DISTANCE = 4.25
	local LOOSE_PASS_ROLL_DURATION = 0.42
	local LOOSE_PASS_CHASE_MAX_SECONDS = 1.45
	local LOOSE_PASS_CHASE_TARGET_REFRESH_SECONDS = 0.08
	local LOOSE_PASS_MIN_CHASE_SPEED = 22.0
	local LOOSE_PASS_MAX_CHASE_SPEED = 34.0

	-- Return-through-ball carry continuation tuning.
	-- If the receiver has already passed the intended CarryPoint, do not make him
	-- turn back. Keep his run facing the goal and push the next target forward.
	local RETURN_RECEIVER_CARRY_SPEED = 34.0
	local RETURN_RECEIVER_BACKTRACK_TOLERANCE = 0.85
	local RETURN_RECEIVER_FORWARD_LEAD_DISTANCE = 10.0

	-- Enemy starts pressing as soon as the pass is kicked.
	-- The current beaten defender falls back. The next relevant defender presses the receiver lane.
	local PASS_DEFENDER_EARLY_PRESS_START_DELAY = 0.0
	local PASS_DEFENDER_EARLY_PRESS_DURATION_SCALE = 1.55
	local PASS_DEFENDER_EARLY_PRESS_STOP_GAP = Constants.PASS_DEFENDER_EARLY_PRESS_STOP_GAP or 4.0
	local PASS_DEFENDER_EARLY_PRESS_INTERCEPT_LEAD = Constants.PASS_DEFENDER_EARLY_PRESS_INTERCEPT_LEAD or 3.25
	local PASS_DEFENDER_EARLY_PRESS_MIN_SPEED = 22.0
	local PASS_DEFENDER_EARLY_PRESS_MAX_SPEED = 30.0
	local PASS_DEFENDER_PREDICTED_TARGET_SWITCH_DISTANCE = 8.0
	local PASS_DEFENDER_RECEIVER_MIN_GAP = Constants.PASS_DEFENDER_RECEIVER_MIN_GAP or 5.5
	local PASS_DEFENDER_FRONT_OFFSET = Constants.PASS_DEFENDER_FRONT_OFFSET or 6.5
	local PASS_DEFENDER_SIDE_CLEARANCE = Constants.PASS_DEFENDER_SIDE_CLEARANCE or 2.5

	-- QTE1 and QTE2 need stronger through-pass lead.
	-- QTE3 already feels good, keep it controlled.

	-- Keep pass mostly forward. Small lateral bias only for diagonal football feel.

	local DRIBBLE_DODGE_FORWARD_DISTANCE_SUCCESS = 4.65
	local DRIBBLE_DODGE_FORWARD_DISTANCE_FAIL = 2.20
	local DRIBBLE_DODGE_SIDE_DISTANCE_SUCCESS = 2.25
	local DRIBBLE_DODGE_SIDE_DISTANCE_FAIL = 0.85
	local DRIBBLE_RESOLVE_MAX_SECONDS = 0.92
	local DRIBBLE_SUCCESS_SETTLE_SECONDS = 0
	local DRIBBLE_TRICK_FALLBACK_DURATION = 1.25
	local DRIBBLE_TRICK_MIN_DURATION = 0.85
	local DRIBBLE_TRICK_MAX_DURATION = 1.65
	local DRIBBLE_TRICK_ANIMATION_NAMES = {
		"Dribble - Chop",
		"Dribble - Elastico",
		"Dribble - Rainbow Flick",
		"Dribble - Roulette",
		"Dribble - Step Over",
	}
	-- Fallback AnimationIds used when a character's Animations folder does not
	-- contain the named dribble tricks (e.g. LocalMatchPlayerProxy).
	local DRIBBLE_TRICK_FALLBACK_ANIMATION_IDS = {
		"rbxassetid://74829085391407",
		"rbxassetid://76410808210220",
		"rbxassetid://86301950548899",
		"rbxassetid://115066455423404",
		"rbxassetid://127808204094011",
	}
	local DRIBBLE_FAIL_FRONT_STEAL_OFFSET = 1.35
	local DRIBBLE_FAIL_BEHIND_PROGRESS = -0.15
	local DRIBBLE_FAIL_CHASE_MIN_SPEED = 26.0
	local DRIBBLE_FAIL_CHASE_MAX_SPEED = 38.0
	local DRIBBLE_FAIL_FRONT_SETTLE_SECONDS = 1.35
	local DRIBBLE_FAIL_FRONT_SETTLE_MIN_SPEED = 34.0
	local DRIBBLE_FAIL_FRONT_SETTLE_MAX_SPEED = 76.0
	local DRIBBLE_FAIL_CONTACT_DISTANCE = 0.78

	local PASS_FAILURE_MIN_FORWARD_DISTANCE = 11.5
	local PASS_FAILURE_DEFENDER_MIN_SPEED = 30.0
	local PASS_FAILURE_DEFENDER_MAX_SPEED = 85.0
	local PASS_FAILURE_DEFENDER_INTERCEPT_LEAD_SECONDS = 0.16
	local PASS_FAILURE_DEFENDER_SETTLE_SECONDS = 1.05
	local PASS_FAILURE_INTERCEPT_DISTANCE = 0.78
	local PASS_FAILURE_PASSER_CHASE_SECONDS = 0.42
	local PASS_FAILURE_TEAM_CHASE_SECONDS = 0.42
	local PASS_FAILURE_CHASE_STEP_DISTANCE = 4.35
	local PASS_FAILURE_CHASE_MIN_SPEED = 18.0
	local PASS_FAILURE_CHASE_MAX_SPEED = 34.0

	-- Player2 branch staging:
	-- Player2 must not outrun the Zone04 defender intercept, while Player4
	-- should reach the authored receive lane before the QTE4 pass opens.
	local PLAYER2_BRANCH_CARRIER_SPEED = 24.0
	local PLAYER2_BRANCH_RECEIVER_REPOSITION_SPEED = 40.0

	local GetRootPart = Utils.GetRootPart
	local ApplyPivot = Utils.ApplyPivot
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local StepFlatTowards = Utils.StepFlatTowards
	local ComputeBallTravelDuration = Utils.ComputeBallTravelDuration
	local BuildStableSeed = Utils.BuildStableSeed
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook
	local IsEmbeddedBallVisual = Utils.IsEmbeddedBallVisual

	local function getAnimationFolder(model)
		return model and (model:FindFirstChild("Animations") or model:FindFirstChild("Animations", true)) or nil
	end

	local function selectDribbleTrickAnimation(payload, actorModel)
		local modelName = actorModel and tostring(actorModel.Name) or "(nil model)"
		
		local fallbackSeed = BuildStableSeed(
			payload and payload.SessionId,
			payload and (payload.StepIndex or payload.Step),
			payload and (payload.ActorSlot or payload.FromSlot),
			997
		)
		local fallbackId = DRIBBLE_TRICK_FALLBACK_ANIMATION_IDS[
			(fallbackSeed % #DRIBBLE_TRICK_FALLBACK_ANIMATION_IDS) + 1
		]
		print("[DribbleTrick DEBUG] Always using direct AnimationId for trick on:", modelName, "- ID:", fallbackId)
		return fallbackId
	end

	local function findEmbeddedBallVisualPart(actorModel)
		if not actorModel then
			return nil
		end

		local fallbackPart = nil
		for _, descendant in ipairs(actorModel:GetDescendants()) do
			if descendant:IsA("BasePart") and IsEmbeddedBallVisual(descendant) then
				if string.lower(descendant.Name) == "ball" then
					return descendant
				end
				fallbackPart = fallbackPart or descendant
			end
		end
		return fallbackPart
	end

	local DRIBBLE_TRICK_PROXY_NAME = "DribbleTrickEmbeddedBallProxy"
	local DRIBBLE_TRICK_PROXY_RENDER_BIND = "MatchDribbleTrickEmbeddedBallVisuals"

	local function destroyDribbleTrickEmbeddedBallProxy(self)
		RunService:UnbindFromRenderStep(DRIBBLE_TRICK_PROXY_RENDER_BIND)

		if self.DribbleTrickEmbeddedBallProxy and self.DribbleTrickEmbeddedBallProxy.Parent then
			self.DribbleTrickEmbeddedBallProxy:Destroy()
		end

		self.DribbleTrickEmbeddedBallProxy = nil
		self.DribbleTrickEmbeddedBallSourcePart = nil
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

	local function createDribbleTrickEmbeddedBallProxy(self, sourcePart)
		destroyDribbleTrickEmbeddedBallProxy(self)

		if not sourcePart or not sourcePart:IsA("BasePart") then
			return nil
		end

		local proxyPart = sourcePart:Clone()
		proxyPart.Name = DRIBBLE_TRICK_PROXY_NAME
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

		proxyPart.Parent = workspace.CurrentCamera or workspace

		self.DribbleTrickEmbeddedBallProxy = proxyPart
		self.DribbleTrickEmbeddedBallSourcePart = sourcePart

		return proxyPart
	end

	-- // [ PASS BLOCK / TURNOVER ] // --

	function MatchPresentationController:_buildPassBlockContactPoint(enemyModel, enemyRoot, fromPosition)
		if not enemyRoot then
			return fromPosition
		end

		local groundedEnemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		local toBallDir = MatchMotionMath.GetFlatDirection(groundedEnemyPos, fromPosition)

		if toBallDir.Magnitude <= 0.001 then
			toBallDir = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
		end

		return groundedEnemyPos
			+ (toBallDir * 0.55)
			+ Vector3.new(0, 2.65, 0)
	end

	function MatchPresentationController:_handoffBallToEnemy(payload, enemyModel, travelDuration, travelArcHeight)
		if not enemyModel or not self.MatchBallController then
			return
		end

		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return
		end

		local ballPos = self.MatchBallController:GetBallPosition()
		if not ballPos then
			self.MatchBallController:AttachToActor(enemyModel, MatchBallConfig.ReceiveOffset)
			self:_beginBallFollow(enemyModel)
			return
		end

		local endPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		endPos = Vector3.new(
			endPos.X,
			endPos.Y + (MatchBallConfig.PassLandingHeight or 0.22),
			endPos.Z
		)

		local duration = math.max(travelDuration or 0.08, 0.04)
		local arcHeight = math.max(travelArcHeight or 0.12, 0.05)

		self.MatchBallController:PlayArc(ballPos, endPos, duration, arcHeight)
		self:_waitForSessionSeconds(payload.SessionId, duration * 0.92)

		self.MatchBallController:AttachToActor(enemyModel, MatchBallConfig.ReceiveOffset)
		self:_beginBallFollow(enemyModel)
	end

	function MatchPresentationController:_getResolveAttackDirection(currentCFrame, fallbackLookPosition)
		if not currentCFrame then
			return Vector3.new(0, 0, -1)
		end

		local currentPos = currentCFrame.Position
		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local attackDirection = goalTarget
			and MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
			or nil

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = fallbackLookPosition
				and MatchMotionMath.GetFlatDirection(currentPos, fallbackLookPosition)
				or nil
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook(currentCFrame.LookVector)
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			return Vector3.new(0, 0, -1)
		end

		local flatDirection = Vector3.new(attackDirection.X, 0, attackDirection.Z)
		if flatDirection.Magnitude <= 0.001 then
			return Vector3.new(0, 0, -1)
		end

		return flatDirection.Unit
	end

	function MatchPresentationController:_isEnemyBehindCarrier(actorPosition, enemyPosition, attackDirection)
		if not actorPosition or not enemyPosition or not attackDirection then
			return false
		end

		local enemyDelta = Vector3.new(
			enemyPosition.X - actorPosition.X,
			0,
			enemyPosition.Z - actorPosition.Z
		)

		return enemyDelta:Dot(attackDirection) < DRIBBLE_FAIL_BEHIND_PROGRESS
	end

	function MatchPresentationController:_buildDribbleFailEnemyTarget(actorPosition, enemyModel, attackDirection)
		if not actorPosition or not attackDirection then
			return actorPosition
		end

		return GetGroundedPosition(
			actorPosition + (attackDirection * DRIBBLE_FAIL_FRONT_STEAL_OFFSET),
			enemyModel
		)
	end

	function MatchPresentationController:_settleDribbleFailureFrontSteal(payload, actorModel, enemyModel, actorPosition, attackDirection)
		if not payload or not enemyModel or not actorPosition or not attackDirection then
			return nil
		end

		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return nil
		end

		if actorModel and self._beginBallFollow then
			self:_beginBallFollow(actorModel)
		end

		local actorSlot = tonumber(payload.ActorSlot or payload.FromSlot or self.ActiveActorSlot)
		local currentEnemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		local actorGroundPos = GetGroundedPosition(actorPosition, actorModel)
		local targetPos = self:_buildDribbleFailEnemyTarget(actorGroundPos, enemyModel, attackDirection)
		local startedAt = os.clock()
		local deadline = startedAt + DRIBBLE_FAIL_FRONT_SETTLE_SECONDS

		while self:_isSessionActive(payload.SessionId)
			and enemyModel.Parent
		do
			local liveActorCFrame = actorSlot and self:_getActorCurrentCFrame(actorSlot, actorModel) or nil
			actorGroundPos = GetGroundedPosition(liveActorCFrame and liveActorCFrame.Position or actorPosition, actorModel)
			targetPos = self:_buildDribbleFailEnemyTarget(actorGroundPos, enemyModel, attackDirection)

			if GetFlatDistance(currentEnemyPos, targetPos) <= DRIBBLE_FAIL_CONTACT_DISTANCE
				and not self:_isEnemyBehindCarrier(actorGroundPos, currentEnemyPos, attackDirection)
			then
				break
			end

			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
			local remainingTime = math.max(deadline - os.clock(), 0.05)
			local chaseDistance = GetFlatDistance(currentEnemyPos, targetPos)
			local moveSpeed = math.clamp(
				chaseDistance / remainingTime,
				DRIBBLE_FAIL_FRONT_SETTLE_MIN_SPEED,
				DRIBBLE_FAIL_FRONT_SETTLE_MAX_SPEED
			)
			local nextPos = select(1, StepFlatTowards(
				currentEnemyPos,
				targetPos,
				moveSpeed,
				scaledDeltaTime
			))

			currentEnemyPos = GetGroundedPosition(nextPos, enemyModel)
			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentEnemyPos, actorGroundPos))
			self:_playMotionAnimation(enemyModel, "Run", moveSpeed >= 48 and 1.22 or 1.12)
		end

		currentEnemyPos = GetGroundedPosition(currentEnemyPos, enemyModel)
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentEnemyPos, actorGroundPos))
		if self.MatchBallController and self.MatchBallController.StopFollow then
			self.MatchBallController:StopFollow()
		end
		return currentEnemyPos
	end

	-- // [ DRIBBLE RESOLVE ] // --

	function MatchPresentationController:_buildDribbleResolveTargets(payload, actorModel, enemyModel, currentCFrame, enemyRoot, success)
		local currentPos = currentCFrame.Position
		local goalTarget = MatchZoneQuery.GetGoalTarget()

		local attackDirection = goalTarget
			and MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
			or GetFlatUnitFromLook(currentCFrame.LookVector)

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook(currentCFrame.LookVector)
		end

		local lateral = attackDirection:Cross(Vector3.new(0, 1, 0))
		if lateral.Magnitude <= 0.001 then
			lateral = Vector3.new(1, 0, 0)
		else
			lateral = lateral.Unit
		end

		local enemyCurrentCFrame = enemyRoot and enemyRoot.CFrame or nil
		local sideSign = 1

		if enemyRoot then
			local enemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
			local enemySide = Vector3.new(
				enemyPos.X - currentPos.X,
				0,
				enemyPos.Z - currentPos.Z
			):Dot(lateral)

			sideSign = enemySide > 0 and -1 or 1
		else
			local stableSeed = BuildStableSeed(
				payload and payload.SessionId,
				payload and payload.StepIndex,
				payload and payload.ActorSlot,
				617
			)

			sideSign = (stableSeed % 2 == 0) and 1 or -1
		end

		local forwardDistance = success and DRIBBLE_DODGE_FORWARD_DISTANCE_SUCCESS or DRIBBLE_DODGE_FORWARD_DISTANCE_FAIL
		local sideDistance = success and DRIBBLE_DODGE_SIDE_DISTANCE_SUCCESS or DRIBBLE_DODGE_SIDE_DISTANCE_FAIL

		local rawTarget = currentPos
			+ (attackDirection.Unit * forwardDistance)
			+ (lateral * sideSign * sideDistance)

		local nextMarker = MatchZoneQuery.GetCarrierPoint((payload.StepIndex or 0) + 1)
			or MatchZoneQuery.GetExitPoint(payload.StepIndex)

		if nextMarker then
			local toNext = MatchMotionMath.GetFlatDirection(currentPos, nextMarker.Position)

			if toNext.Magnitude > 0.001 then
				local nextProgress = Vector3.new(
					nextMarker.Position.X - currentPos.X,
					0,
					nextMarker.Position.Z - currentPos.Z
				):Dot(toNext.Unit)

				local targetProgress = Vector3.new(
					rawTarget.X - currentPos.X,
					0,
					rawTarget.Z - currentPos.Z
				):Dot(toNext.Unit)

				if nextProgress > 3 and targetProgress > nextProgress - 1.5 then
					rawTarget = currentPos
						+ (toNext.Unit * math.max(nextProgress - 1.5, success and 2.8 or 1.5))
						+ (lateral * sideSign * sideDistance)
				end
			end
		end

		local actorTargetPos = GetGroundedPosition(rawTarget, actorModel)
		local actorLookPos = goalTarget and goalTarget.Position or (actorTargetPos + attackDirection.Unit)
		actorLookPos = Vector3.new(actorLookPos.X, actorTargetPos.Y, actorLookPos.Z)

		local enemyEndPos = nil
		if enemyRoot and enemyCurrentCFrame then
			local enemyResolveOffset = self:_getCombinedSpawnOffset(
				payload.SessionId,
				payload.StepIndex,
				payload.EnemyStep,
				0.55,
				0.75,
				0.90,
				653
			)

			local enemySeed = success
				and (currentPos - (attackDirection.Unit * 1.15) - (lateral * sideSign * 0.75))
				or (currentPos + (attackDirection.Unit * 1.15))

			enemyEndPos = GetGroundedPosition(enemySeed + enemyResolveOffset, enemyModel)
		end

		return {
			ActorTargetPos = actorTargetPos,
			ActorLookPos = actorLookPos,
			EnemyStartCFrame = enemyCurrentCFrame,
			EnemyTargetPos = enemyEndPos,
		}
	end

	function MatchPresentationController:_handleDribbleResolved(payload, actorModel, enemyModel, actorRoot, enemyRoot, success)
		if actorModel then
			self:_setEmbeddedBallVisualsHidden(actorModel, true)
		end

		if enemyModel then
			self:_setEmbeddedBallVisualsHidden(enemyModel, true)
		end

		self:_hideNonCarrierEmbeddedBalls(payload.ActorSlot or self.ActiveActorSlot)

		local isGreenDribble = isGreenActionPayload(payload)
		local shouldBoostDribbleCamera = isGreenDribble or isYellowActionPayload(payload)
		activateGreenActionFx(self, payload, actorModel, GREEN_ACTION_FX_DURATION)
		playActionSound(isGreenDribble and "FastMove2" or "FastMove", {
			Volume = isGreenDribble and 0.85 or 0.65,
			Lifetime = 3,
		})

		local currentCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel) or actorRoot.CFrame
		local targets = self:_buildDribbleResolveTargets(payload, actorModel, enemyModel, currentCFrame, enemyRoot, success)
		local failAttackDirection = nil
		local enemyStartedBehindCarrier = false
		local dribbleTrickName = success and selectDribbleTrickAnimation(payload, actorModel) or nil
		local dribbleTrickTrack = nil
		local dribbleTrickDuration = nil
		local dribbleTrickMoveSpeed = nil
		local embeddedBallPart = nil
		local usingEmbeddedBall = false

		if dribbleTrickName then
			-- If dribbleTrickName is a raw AnimationId (fallback path), load directly via Animator.
			-- Otherwise use the normal named-animation lookup.
			local isFallbackId = type(dribbleTrickName) == "string"
				and dribbleTrickName:sub(1, 13) == "rbxassetid://"

			if isFallbackId then
				print("[DribbleTrick DEBUG] Loading fallback AnimationId directly:", dribbleTrickName)
				local animator = actorModel and (
					actorModel:FindFirstChildOfClass("Animator")
					or actorModel:FindFirstChild("Animator", true)
				)
				if animator then
					local tempAnim = Instance.new("Animation")
					tempAnim.AnimationId = dribbleTrickName
					local ok, track = pcall(function()
						return animator:LoadAnimation(tempAnim)
					end)
					tempAnim:Destroy()
					if ok and track then
						track:Play(0, 1, 1.0)
						dribbleTrickTrack = track
						print("[DribbleTrick DEBUG] Fallback track loaded & played! Length:", track.Length)
					else
						warn("[DribbleTrick DEBUG] Fallback LoadAnimation failed:", tostring(track))
						dribbleTrickName = nil
					end
				else
					warn("[DribbleTrick DEBUG] No Animator found on actorModel - cannot load fallback")
					dribbleTrickName = nil
				end
			else
				print("[DribbleTrick DEBUG] Calling _playMotionAnimation with:", dribbleTrickName)
				dribbleTrickTrack = self:_playMotionAnimation(actorModel, dribbleTrickName, 1.0)
				if not dribbleTrickTrack then
					warn("[DribbleTrick DEBUG] _playMotionAnimation returned nil for:", dribbleTrickName)
					dribbleTrickName = nil
				end
			end

			if dribbleTrickTrack then
				local trackLength = tonumber(dribbleTrickTrack.Length) or 0
				print("[DribbleTrick DEBUG] Track OK! Length:", trackLength, "| IsPlaying:", dribbleTrickTrack.IsPlaying)
				local dribbleTrickDuration = math.clamp(
					trackLength > 0 and trackLength or DRIBBLE_TRICK_FALLBACK_DURATION,
					DRIBBLE_TRICK_MIN_DURATION,
					DRIBBLE_TRICK_MAX_DURATION
				)
				local trickDistance = GetFlatDistance(currentCFrame.Position, targets.ActorTargetPos)
				local dribbleTrickMoveSpeed = math.max(trickDistance / math.max(dribbleTrickDuration, 0.05), 1)

				embeddedBallPart = findEmbeddedBallVisualPart(actorModel)
				print("[DribbleTrick DEBUG] embeddedBallPart:", tostring(embeddedBallPart), "| MatchBallController:", tostring(self.MatchBallController))
				usingEmbeddedBall = embeddedBallPart ~= nil
					and self.MatchBallController ~= nil
					and self.MatchBallController.SetBallVisible ~= nil
				print("[DribbleTrick DEBUG] usingEmbeddedBall:", usingEmbeddedBall)

				if usingEmbeddedBall then
					if self.MatchBallController.StopFollow then
						self.MatchBallController:StopFollow()
					end
					self.MatchBallController:SetBallVisible(false)
					self:_setActiveEmbeddedBallVisualModel(actorModel)
					
					local sourcePart = embeddedBallPart
					local proxyPart = createDribbleTrickEmbeddedBallProxy(self, sourcePart)
					
					local visibilityToken = (self.DribbleTrickToken or 0) + 1
					self.DribbleTrickToken = visibilityToken

					RunService:UnbindFromRenderStep(DRIBBLE_TRICK_PROXY_RENDER_BIND)
					RunService:BindToRenderStep(
						DRIBBLE_TRICK_PROXY_RENDER_BIND,
						Enum.RenderPriority.Last.Value + 1000,
						function()
							if not self:_isSessionActive(payload.SessionId)
								or self.DribbleTrickToken ~= visibilityToken
								or not actorModel
								or not actorModel.Parent
								or not sourcePart
								or not sourcePart.Parent
								or not proxyPart
								or not proxyPart.Parent
							then
								destroyDribbleTrickEmbeddedBallProxy(self)
								return
							end

							proxyPart.CFrame = sourcePart.CFrame
							proxyPart.Size = sourcePart.Size
							proxyPart.Color = sourcePart.Color
							proxyPart.Material = sourcePart.Material
							proxyPart.Transparency = 0
							proxyPart.LocalTransparencyModifier = 0
						end
					)
					
					print("[DribbleTrick DEBUG] Runtime ball hidden, embedded ball proxy activated on:", actorModel.Name)
				end
			end
		end

		if success and shouldBoostDribbleCamera then
			playActionCameraBoost(self, "Dribble", currentCFrame.Position, targets.ActorTargetPos, getQteTier(payload))
		end

		if not success then
			failAttackDirection = self:_getResolveAttackDirection(currentCFrame, targets.ActorLookPos)

			if enemyRoot and failAttackDirection then
				local actorStartPos = GetGroundedPosition(currentCFrame.Position, actorModel)
				local enemyStartPos = targets.EnemyStartCFrame
					and GetGroundedPosition(targets.EnemyStartCFrame.Position, enemyModel)
					or GetGroundedPosition(enemyRoot.Position, enemyModel)

				enemyStartedBehindCarrier = self:_isEnemyBehindCarrier(
					actorStartPos,
					enemyStartPos,
					failAttackDirection
				)
			end
		end

		if success then
			self:_moveCompanionsForward(payload, payload.ActorSlot)

			local isPlayer2BranchDribble = tonumber(payload.StepIndex or payload.Step) == 2
				and payload.Action == "Dribble"
				and tonumber(payload.ActorSlot or payload.FromSlot) == 2

			if tonumber(payload.StepIndex or payload.Step) == 2 and not isPlayer2BranchDribble then
				self:_rememberZone3RunnerAfterStep2(payload, nil)

				if self._startStep2NonReceiverArea3Sprint then
					self:_startStep2NonReceiverArea3Sprint(payload, nil, currentCFrame)
				end
			elseif isPlayer2BranchDribble and self._stopSupportMotion then
				self:_stopSupportMotion()
			end
		end

		local failEnemyTargetResolver = nil
		local failEnemySpeedResolver = nil
		if not success and failAttackDirection then
			failEnemyTargetResolver = function(currentActorPos)
				return self:_buildDribbleFailEnemyTarget(currentActorPos, enemyModel, failAttackDirection)
			end

			failEnemySpeedResolver = function(_currentActorPos, enemyState, liveEnemyTargetPos)
				local targetPos = liveEnemyTargetPos or enemyState.Position
				local chaseDistance = GetFlatDistance(enemyState.Position, targetPos)
				local speed = math.max(DRIBBLE_FAIL_CHASE_MIN_SPEED, chaseDistance * 5.8)

				if enemyStartedBehindCarrier then
					speed = math.max(speed, DRIBBLE_FAIL_CHASE_MAX_SPEED * 0.82)
				end

				return math.clamp(speed, DRIBBLE_FAIL_CHASE_MIN_SPEED, DRIBBLE_FAIL_CHASE_MAX_SPEED)
			end
		end

		local dribbleTrickDuration = nil
		local dribbleTrickMoveSpeed = nil
		if dribbleTrickTrack then
			local trackLength = tonumber(dribbleTrickTrack.Length) or 0
			dribbleTrickDuration = math.clamp(
				trackLength > 0 and trackLength or DRIBBLE_TRICK_FALLBACK_DURATION,
				DRIBBLE_TRICK_MIN_DURATION,
				DRIBBLE_TRICK_MAX_DURATION
			)

			local attackDir = self:_getResolveAttackDirection(currentCFrame, targets.ActorLookPos)
			if attackDir and attackDir.Magnitude > 0.001 then
				local addedDistance = dribbleTrickDuration * 3
				targets.ActorTargetPos = targets.ActorTargetPos + (attackDir.Unit * addedDistance)
			end

			local trickDistance = GetFlatDistance(currentCFrame.Position, targets.ActorTargetPos)
			dribbleTrickMoveSpeed = math.max(trickDistance / math.max(dribbleTrickDuration, 0.05), 1)
		end

		local finalActorPos, finalEnemyPos = self:_runMovementSequence(payload, {
			SpeedGroupName = "Resolve",
			SpeedActionName = "Dribble",
			ActorModel = actorModel,
			EnemyModel = enemyModel,
			ActorStartCFrame = currentCFrame,
			ActorTargetPos = targets.ActorTargetPos,
			ActorLookPos = targets.ActorLookPos,
			EnemyStartPos = targets.EnemyStartCFrame and targets.EnemyStartCFrame.Position or currentCFrame.Position,
			EnemyTargetPos = targets.EnemyTargetPos,
			EnemyTargetPosResolver = failEnemyTargetResolver,
			EnemyLookPosResolver = function(currentActorPos)
				return currentActorPos
			end,
			HoldEnemyUntilActorReady = false,
			FollowBall = not usingEmbeddedBall,
			ActorRunAnimation = "Run",
			ActorRunSpeed = success and 1.08 or nil,
			ActorMoveSpeed = dribbleTrickMoveSpeed,
			EnemyRunAnimation = "Run",
			EnemyRunSpeed = (not success and enemyStartedBehindCarrier) and 1.18 or nil,
			ActorSprintAfterBeat = success and dribbleTrickName == nil,
			EnemyAdaptiveSprint = false,
			EnemySpeedResolver = failEnemySpeedResolver,
			BreakOnActorReached = success,
			MaxDuration = dribbleTrickDuration and (dribbleTrickDuration + 0.15)
				or (success and DRIBBLE_RESOLVE_MAX_SECONDS or (enemyStartedBehindCarrier and 1.28 or 1.02)),
		})

		if usingEmbeddedBall then
			local handoffPart = embeddedBallPart and embeddedBallPart.Parent and embeddedBallPart
				or findEmbeddedBallVisualPart(actorModel)
			if handoffPart and self.MatchBallController.SetBallDriverWorldCFrame then
				self.MatchBallController:SetBallDriverWorldCFrame(handoffPart.CFrame)
			end

			destroyDribbleTrickEmbeddedBallProxy(self)
			self:_clearActiveEmbeddedBallVisualModel(actorModel)

			self.MatchBallController:SetBallVisible(true)
			self:_beginBallFollow(actorModel)
		end

		finalActorPos = GetGroundedPosition(finalActorPos, actorModel)
		finalEnemyPos = GetGroundedPosition(finalEnemyPos, enemyModel)

		self:_setKeeperFocusWorldPosition(finalActorPos)

		self:_alignActorToLook(
			payload.ActorSlot,
			actorModel,
			finalActorPos,
			targets.ActorLookPos,
			success and "Run" or "Idle",
			success and 1.0 or nil
		)

		if enemyModel and enemyRoot then
			local enemyLookTarget = success and targets.ActorLookPos or finalActorPos
			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(finalEnemyPos, enemyLookTarget))
		end

		if success then
			-- Keep the carrier in locomotion after beating the defender.
			-- Replaying the Dribble clip here creates a visible idle/stun gap before the next run.
			self:_playMotionAnimation(actorModel, "Run", 1.08)

			if enemyModel then
				self:_sendDefeatedEnemyBackwards(payload, enemyModel)
			end

			self:_continueCarrierAfterDribbleSuccess(
				payload,
				payload.ActorSlot or self.ActiveActorSlot,
				actorModel,
				finalActorPos,
				targets.ActorLookPos
			)

			if DRIBBLE_SUCCESS_SETTLE_SECONDS > 0 then
				self:_waitForSessionSeconds(payload.SessionId, DRIBBLE_SUCCESS_SETTLE_SECONDS)
			end
			return
		end

		if enemyModel and failAttackDirection then
			finalEnemyPos = self:_settleDribbleFailureFrontSteal(
				payload,
				actorModel,
				enemyModel,
				finalActorPos,
				failAttackDirection
			) or finalEnemyPos
		end

		if actorModel then
			self:_playRigAnimation(actorModel, "Lose", 1.0)
		end

		self:_waitForSessionSeconds(payload.SessionId, 0.03)
		self:_handoffBallToEnemy(payload, enemyModel, 0.05, 0.08)

		self:_runEnemyCarryAwayAfterTurnover(
			payload,
			enemyModel,
			currentCFrame,
			10
		)

		self:_waitForSessionSeconds(payload.SessionId, 0.18)
	end

	-- // [ PASS POSITIONING ] // --

	function MatchPresentationController:_getPassStartPosition(actorModel, actorRoot, targetPosition)
		local passOffset = MatchBallConfig.PassOffset
			or MatchBallConfig.ReceiveOffset
			or CFrame.identity

		local baseCFrame = actorRoot and actorRoot.CFrame
			or (actorModel and actorModel:IsA("Model") and actorModel:GetPivot())
			or nil

		if not baseCFrame then
			return Vector3.zero
		end

		local footPosition = (baseCFrame * passOffset).Position
		local startGrounded = GetGroundedPosition(footPosition, actorModel)
		footPosition = Vector3.new(footPosition.X, startGrounded.Y + 0.44, footPosition.Z)

		if self.MatchBallController and self.MatchBallController.GetBallPosition then
			local liveBallPosition = self.MatchBallController:GetBallPosition()

			if liveBallPosition then
				local maxAllowedDistance = 0.5
				local verticalDelta = math.abs(liveBallPosition.Y - footPosition.Y)

				if (liveBallPosition - footPosition).Magnitude <= maxAllowedDistance
					and verticalDelta <= 1.85
				then
					return liveBallPosition
				end
			end
		end

		return footPosition
	end

	function MatchPresentationController:_getPassReceivePosition(targetModel, targetRoot, targetCFrame, fallbackPosition)
		local receiveOffset = MatchBallConfig.ReceiveOffset or CFrame.identity
		local receiveCFrame = targetCFrame
			or (targetRoot and targetRoot.CFrame)
			or (targetModel and targetModel:IsA("Model") and targetModel:GetPivot())
			or nil

		if receiveCFrame then
			local pos = (receiveCFrame * receiveOffset).Position
			local grounded = GetGroundedPosition(pos, targetModel)
			return Vector3.new(pos.X, grounded.Y + 0.44, pos.Z)
		end

		return fallbackPosition or Vector3.zero
	end

	function MatchPresentationController:_faceActorTowardPassTarget(payload, actorModel, actorRoot, targetPosition)
		if not payload or not actorModel or not targetPosition then
			return self:_getActorCurrentCFrame(payload and payload.ActorSlot, actorModel), nil
		end

		local currentCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
			or (actorRoot and actorRoot.CFrame)
			or (actorModel:IsA("Model") and actorModel:GetPivot())

		if not currentCFrame then
			return nil, nil
		end

		local actorPosition = GetGroundedPosition(currentCFrame.Position, actorModel)
		local flatTarget = Vector3.new(targetPosition.X, actorPosition.Y, targetPosition.Z)

		if GetFlatDistance(actorPosition, flatTarget) <= 0.05 then
			return currentCFrame, self:_getPassStartPosition(actorModel, actorRoot, targetPosition)
		end

		local facingCFrame = MatchMotionMath.BuildFlatLookAtCFrame(actorPosition, flatTarget)

		if actorModel then
			self:_setEmbeddedBallVisualsHidden(actorModel, true)
		end

		self:_applyActorCFrame(payload.ActorSlot, actorModel, facingCFrame, {
			ExpectedAnimation = "Pass",
			FacingMode = "Idle",
			LookAtPosition = flatTarget,
			MoveSpeed = 0,
		})

		if self.MatchBallController and self.MatchBallController.AttachToActor then
			self.MatchBallController:AttachToActor(
				actorModel,
				MatchBallConfig.PassOffset or MatchBallConfig.ReceiveOffset
			)
		end

		self:_playRigAnimation(actorModel, "Pass", 1.0, 0.05)
		self:_waitForSessionSeconds(payload.SessionId, PASS_FACE_BEFORE_KICK_SECONDS)

		local updatedCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel) or facingCFrame
		local updatedStartPosition = self:_getPassStartPosition(actorModel, actorRoot, targetPosition)

		return updatedCFrame, updatedStartPosition
	end

	-- // [ PASS FLIGHT ] // --

	function MatchPresentationController:_getSuccessPassArcHeight(startPosition, endPosition)
		if not startPosition or not endPosition then
			return 1.15
		end

		local flatDistance = GetFlatDistance(startPosition, endPosition)
		local verticalDistance = math.abs((endPosition.Y or 0) - (startPosition.Y or 0))
		local flightConfig = MatchBallConfig.PassFlight or {}

		local minArc = tonumber(flightConfig.MinArcHeight) or 0.45
		local maxArc = 10.0
		local scale = tonumber(flightConfig.ArcDistanceScale) or 0.12

		local arcHeight = minArc + (flatDistance * scale) + (verticalDistance * 0.06)

		if flatDistance <= 8 then
			arcHeight = math.max(arcHeight, 1.75)
		elseif flatDistance <= 16 then
			arcHeight = math.max(arcHeight, 2.15)
		else
			arcHeight = math.max(arcHeight, 2.45)
		end

		return math.clamp(arcHeight, minArc, maxArc)
	end

	function MatchPresentationController:_getSuccessPassDuration(startPosition, endPosition)
		local rawDuration = ComputeBallTravelDuration(startPosition, endPosition)
		local flatDistance = GetFlatDistance(startPosition, endPosition)

		if flatDistance <= 8.0 then
			return math.clamp(rawDuration * 1.45, 0.95, 1.20)
		end

		if flatDistance <= 16.0 then
			return math.clamp(rawDuration * 1.30, 1.05, 1.30)
		end

		return math.clamp(rawDuration * 1.15, 1.10, 1.40)
	end

	function MatchPresentationController:_hideBallVisualsForPassKick(actorModel, targetModel, enemyModel)
		if actorModel then
			self:_setEmbeddedBallVisualsHidden(actorModel, true)
		end

		if targetModel then
			self:_setEmbeddedBallVisualsHidden(targetModel, true)
		end

		if enemyModel then
			self:_setEmbeddedBallVisualsHidden(enemyModel, true)
		end

		for slotNumber = 1, 4 do
			local slotModel = self:_getControlledActorModel(slotNumber)
			if slotModel then
				self:_setEmbeddedBallVisualsHidden(slotModel, true)
			end
		end
	end

	function MatchPresentationController:_playPassArcFromLiveBall(payload, startPosition, endPosition, duration, arcHeight)
		if not self.MatchBallController then
			return
		end

		if self.MatchBallController.StopFollow then
			self.MatchBallController:StopFollow()
		end

		if self.MatchBallController.SetBallWorldPosition and startPosition then
			self.MatchBallController:SetBallWorldPosition(startPosition)
		end

		local flatDistance = GetFlatDistance(startPosition, endPosition)
		local lateralCurve = 0

		if flatDistance <= 16.0 then
			local goalTarget = MatchZoneQuery.GetGoalTarget()
			local forwardDir = goalTarget and (goalTarget.Position - startPosition) or Vector3.new(0, 0, -1)

			if forwardDir.Magnitude > 0.001 then
				forwardDir = Vector3.new(forwardDir.X, 0, forwardDir.Z).Unit

				local toTarget = Vector3.new(
					endPosition.X - startPosition.X,
					0,
					endPosition.Z - startPosition.Z
				)

				if toTarget.Magnitude > 0.001 then
					toTarget = toTarget.Unit

					local lateralDir = toTarget:Cross(Vector3.new(0, 1, 0))
					local curveSign = lateralDir:Dot(forwardDir) >= 0 and 1 or -1
					local configuredCurve = MatchBallConfig.PassFlight
						and MatchBallConfig.PassFlight.LateralCurveAmount
						or 2.85

					lateralCurve = configuredCurve * curveSign
				end
			end
		else
			local stableSeed = math.floor((startPosition.X + startPosition.Z) * 10)
			lateralCurve = (stableSeed % 2 == 0) and 0.55 or -0.55
		end

		local flightOptions = {
			MinFlightHeight = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.EndHeight or 0.32,
			MinArcHeight = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.MinArcHeight or 0.45,
			TrailLinger = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.TrailLinger or 0.22,
			LateralCurve = lateralCurve,
			SpecialEffects = isGreenActionPayload(payload),
			EffectsDuration = math.max(duration or 0.75, 0.25) + 0.35,
		}

		if self.MatchBallController.PlayPassArc then
			self.MatchBallController:PlayPassArc(startPosition, endPosition, duration, arcHeight, flightOptions)
		else
			self.MatchBallController:PlayArc(startPosition, endPosition, duration, arcHeight, flightOptions)
		end
	end

	function MatchPresentationController:_keepFailedPassLandingForward(actorModel, targetModel, actorCFrame, startPosition, landingPosition)
		if not startPosition or not landingPosition then
			return landingPosition, nil
		end

		local attackDirection = self:_getResolveAttackDirection(actorCFrame, landingPosition)
		local groundedStart = GetGroundedPosition(startPosition, actorModel)
		local groundedLanding = GetGroundedPosition(landingPosition, targetModel)
		local landingDelta = Vector3.new(
			groundedLanding.X - groundedStart.X,
			0,
			groundedLanding.Z - groundedStart.Z
		)
		local forwardProgress = landingDelta:Dot(attackDirection)

		if forwardProgress >= PASS_FAILURE_MIN_FORWARD_DISTANCE then
			return landingPosition, attackDirection
		end

		local correctedGround = GetGroundedPosition(
			groundedStart + (attackDirection * PASS_FAILURE_MIN_FORWARD_DISTANCE),
			targetModel
		)
		local landingHeight = MatchBallConfig.PassLandingHeight or 0.44

		return Vector3.new(correctedGround.X, correctedGround.Y + landingHeight, correctedGround.Z), attackDirection
	end

	function MatchPresentationController:_settlePasserAfterKick(payload, actorModel, actorRoot, currentCFrame, lookAtPosition, chaseDuration)
		if not payload or not actorModel then
			return
		end

		local liveCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
			or currentCFrame
			or (actorRoot and actorRoot.CFrame)
			or (actorModel:IsA("Model") and actorModel:GetPivot())

		if not liveCFrame then
			self:_playMotionAnimation(actorModel, "Idle", 1.0)
			return
		end

		local actorPosition = GetGroundedPosition(liveCFrame.Position, actorModel)
		local chaseLookPosition = lookAtPosition
			and Vector3.new(lookAtPosition.X, actorPosition.Y, lookAtPosition.Z)
			or (actorPosition + GetFlatUnitFromLook(liveCFrame.LookVector))
		local chaseDirection = MatchMotionMath.GetFlatDirection(actorPosition, chaseLookPosition)

		if chaseDirection.Magnitude <= 0.001 then
			self:_applyActorCFrame(payload.ActorSlot, actorModel, MatchMotionMath.BuildFlatLookAtCFrame(actorPosition, chaseLookPosition), {
				ExpectedAnimation = "Idle",
				FacingMode = "Idle",
				LookAtPosition = chaseLookPosition,
				MoveSpeed = 0,
			})

			self:_playMotionAnimation(actorModel, "Idle", 1.0)
			return
		end

		local targetDistance = math.min(GetFlatDistance(actorPosition, chaseLookPosition), PASS_FAILURE_CHASE_STEP_DISTANCE)
		local targetPos = GetGroundedPosition(actorPosition + (chaseDirection.Unit * targetDistance), actorModel)
		local duration = math.max(tonumber(chaseDuration) or PASS_FAILURE_PASSER_CHASE_SECONDS, 0.12)

		task.spawn(function()
			local startedAt = os.clock()
			local currentPos = actorPosition

			self:_playMotionAnimation(actorModel, "Run", 1.08)

			while self:_isSessionActive(payload.SessionId)
				and actorModel.Parent
				and os.clock() - startedAt < duration
			do
				local liveActorCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
				if liveActorCFrame then
					currentPos = GetGroundedPosition(liveActorCFrame.Position, actorModel)
				end

				if GetFlatDistance(currentPos, targetPos) <= 0.28 then
					break
				end

				local deltaTime = RunService.RenderStepped:Wait()
				local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
				local remainingTime = math.max(duration - (os.clock() - startedAt), 0.05)
				local moveSpeed = math.clamp(
					GetFlatDistance(currentPos, targetPos) / remainingTime,
					PASS_FAILURE_CHASE_MIN_SPEED,
					PASS_FAILURE_CHASE_MAX_SPEED
				)
				local nextPos = select(1, StepFlatTowards(currentPos, targetPos, moveSpeed, scaledDeltaTime))

				currentPos = GetGroundedPosition(nextPos, actorModel)
				self:_applyActorCFrame(payload.ActorSlot, actorModel, MatchMotionMath.BuildFlatLookAtCFrame(currentPos, chaseLookPosition), {
					ExpectedAnimation = "Run",
					FacingMode = "LookAtPosition",
					LookAtPosition = chaseLookPosition,
					MoveSpeed = moveSpeed,
				})
				self:_playMotionAnimation(actorModel, "Run", moveSpeed >= 28 and 1.16 or 1.08)
			end

			if self:_isSessionActive(payload.SessionId) and actorModel.Parent then
				local finalCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel)
				local finalPos = GetGroundedPosition(finalCFrame and finalCFrame.Position or currentPos, actorModel)

				self:_applyActorCFrame(payload.ActorSlot, actorModel, MatchMotionMath.BuildFlatLookAtCFrame(finalPos, chaseLookPosition), {
					ExpectedAnimation = "Idle",
					FacingMode = "Idle",
					LookAtPosition = chaseLookPosition,
					MoveSpeed = 0,
				})
				self:_playMotionAnimation(actorModel, "Idle", 1.0)
			end
		end)
	end

	function MatchPresentationController:_startFailedPassDefenderIntercept(payload, enemyModel, landingPosition, lookAtPosition, passDuration)
		if not payload or not enemyModel or not landingPosition then
			return
		end

		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return
		end

		task.spawn(function()
			local startedAt = os.clock()
			local activeDuration = math.max(
				(tonumber(passDuration) or 0.7) - PASS_FAILURE_DEFENDER_INTERCEPT_LEAD_SECONDS,
				0.22
			)
			local targetPos = GetGroundedPosition(landingPosition, enemyModel)
			local startPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
			local landingDirection = MatchMotionMath.GetFlatDirection(startPos, targetPos)

			if landingDirection.Magnitude <= 0.001 and lookAtPosition then
				landingDirection = MatchMotionMath.GetFlatDirection(lookAtPosition, targetPos)
			end

			if landingDirection.Magnitude <= 0.001 then
				landingDirection = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
			end

			if landingDirection.Magnitude <= 0.001 then
				landingDirection = Vector3.new(0, 0, -1)
			end

			local function getLandingLookTarget(currentPos)
				if GetFlatDistance(currentPos, targetPos) > 0.18 then
					return targetPos
				end

				return targetPos + landingDirection.Unit
			end

			while self:_isSessionActive(payload.SessionId)
				and enemyModel.Parent
				and not self.IsPreQteFrozen
				and os.clock() - startedAt <= activeDuration
			do
				local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)

				if GetFlatDistance(currentPos, targetPos) <= PASS_FAILURE_INTERCEPT_DISTANCE then
					break
				end

				local deltaTime = RunService.RenderStepped:Wait()
				local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
				local remainingTime = math.max(activeDuration - (os.clock() - startedAt), 0.05)
				local distance = GetFlatDistance(currentPos, targetPos)
				local moveSpeed = math.clamp(
					distance / remainingTime,
					PASS_FAILURE_DEFENDER_MIN_SPEED,
					PASS_FAILURE_DEFENDER_MAX_SPEED
				)
				local nextPos = select(1, StepFlatTowards(currentPos, targetPos, moveSpeed, scaledDeltaTime))

				nextPos = GetGroundedPosition(nextPos, enemyModel)
				ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, getLandingLookTarget(nextPos)))
				self:_playMotionAnimation(enemyModel, "Run", moveSpeed >= 48 and 1.24 or 1.12)
			end

			if not self:_isSessionActive(payload.SessionId) or not enemyModel.Parent then
				return
			end

			local finalPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(finalPos, getLandingLookTarget(finalPos)))
			self:_playMotionAnimation(enemyModel, "Idle", 1.0)
		end)
	end

	function MatchPresentationController:_finishFailedPassInterception(payload, enemyModel, landingPosition, lookAtPosition)
		if not payload or not enemyModel or not landingPosition then
			return
		end

		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return
		end

		local targetPos = GetGroundedPosition(landingPosition, enemyModel)
		local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		local startedAt = os.clock()
		local deadline = startedAt + PASS_FAILURE_DEFENDER_SETTLE_SECONDS
		local landingDirection = MatchMotionMath.GetFlatDirection(currentPos, targetPos)

		if landingDirection.Magnitude <= 0.001 and lookAtPosition then
			landingDirection = MatchMotionMath.GetFlatDirection(lookAtPosition, targetPos)
		end

		if landingDirection.Magnitude <= 0.001 then
			landingDirection = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
		end

		if landingDirection.Magnitude <= 0.001 then
			landingDirection = Vector3.new(0, 0, -1)
		end

		local function getLandingLookTarget(position)
			if GetFlatDistance(position, targetPos) > 0.18 then
				return targetPos
			end

			return targetPos + landingDirection.Unit
		end

		while self:_isSessionActive(payload.SessionId)
			and enemyModel.Parent
			and GetFlatDistance(currentPos, targetPos) > PASS_FAILURE_INTERCEPT_DISTANCE
		do
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
			local remainingTime = math.max(deadline - os.clock(), 0.05)
			local moveSpeed = math.clamp(
				GetFlatDistance(currentPos, targetPos) / remainingTime,
				PASS_FAILURE_DEFENDER_MIN_SPEED,
				PASS_FAILURE_DEFENDER_MAX_SPEED
			)
			local nextPos = select(1, StepFlatTowards(currentPos, targetPos, moveSpeed, scaledDeltaTime))

			currentPos = GetGroundedPosition(nextPos, enemyModel)
			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentPos, getLandingLookTarget(currentPos)))
			self:_playMotionAnimation(enemyModel, "Run", moveSpeed >= 48 and 1.22 or 1.12)
		end

		currentPos = GetGroundedPosition(currentPos, enemyModel)
		ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentPos, getLandingLookTarget(currentPos)))

		if self.MatchBallController then
			self.MatchBallController:AttachToActor(enemyModel, MatchBallConfig.ReceiveOffset)
			self:_beginBallFollow(enemyModel)
		end
	end

	-- // [ PASS RECEIVER / DEFENDER MOTION ] // --

	function MatchPresentationController:_movePassReceiverToCFrame(payload, targetSlot, targetModel, targetCFrame, passDuration)
		if not payload or not targetModel or not targetCFrame then
			return false
		end

		local numericTargetSlot = tonumber(targetSlot)
		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local receiverForwardLook = targetCFrame.Position + targetCFrame.LookVector
		local lookAtPosition = goalTarget
			and Vector3.new(goalTarget.Position.X, targetCFrame.Position.Y, goalTarget.Position.Z)
			or receiverForwardLook

		if self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.SetLocalMatchActorTarget
			and numericTargetSlot
			and numericTargetSlot > 1
		then
			local ok = self.MatchActorRuntimeController:SetLocalMatchActorTarget(
				LocalPlayer,
				numericTargetSlot,
				targetCFrame,
				{
					ExpectedAnimation = "Run",
					MoveSpeed = RECEIVER_CATCH_UP_SPEED,
					LookAtPosition = lookAtPosition,
					FacingMode = "LookAtPosition",
					KeepAnimationWhenReached = true,
				}
			)

			if ok then
				return true
			end
		end

		task.spawn(function()
			if not self:_isSessionActive(payload.SessionId) or not targetModel.Parent then
				return
			end

			local currentCFrame = self:_getActorCurrentCFrame(targetSlot, targetModel)
				or (targetModel:IsA("Model") and targetModel:GetPivot())

			if not currentCFrame then
				return
			end

			local currentPosition = GetGroundedPosition(currentCFrame.Position, targetModel)
			local targetPosition = GetGroundedPosition(targetCFrame.Position, targetModel)
			local moveDuration = math.max((tonumber(passDuration) or 0.45) * 0.88, 0.12)
			local distance = GetFlatDistance(currentPosition, targetPosition)
			local moveSpeed = math.max(RECEIVER_CATCH_UP_SPEED, distance / moveDuration)
			local startedAt = os.clock()

			self:_playMotionAnimation(targetModel, "Run", 1.0)

			while self:_isSessionActive(payload.SessionId)
				and targetModel.Parent
				and not self.IsPreQteFrozen
				and os.clock() - startedAt < moveDuration
				and GetFlatDistance(currentPosition, targetPosition) > 0.35
			do
				local deltaTime = RunService.RenderStepped:Wait()
				local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

				local nextPosition = select(1, StepFlatTowards(
					currentPosition,
					targetPosition,
					moveSpeed,
					scaledDeltaTime
				))

				nextPosition = GetGroundedPosition(nextPosition, targetModel)

				self:_applyActorCFrame(
					targetSlot,
					targetModel,
					MatchMotionMath.BuildFlatLookAtCFrame(nextPosition, lookAtPosition)
				)

				self:_playMotionAnimation(targetModel, "Run", 1.0)
				currentPosition = nextPosition
			end

			if not self:_isSessionActive(payload.SessionId)
				or not targetModel.Parent
				or self.IsPreQteFrozen
			then
				return
			end

			self:_applyActorCFrame(targetSlot, targetModel, targetCFrame)
			self:_playMotionAnimation(targetModel, "Run", 1.0)
		end)

		return false
	end


	function MatchPresentationController:_getPassReceiverGroundPosition(receiverSlot, receiverModel, fallbackPosition)
		if not receiverModel then
			return fallbackPosition
		end

		local receiverCFrame = self:_getActorCurrentCFrame(receiverSlot, receiverModel)
			or (receiverModel:IsA("Model") and receiverModel:GetPivot())
			or nil

		if receiverCFrame then
			return GetGroundedPosition(receiverCFrame.Position, receiverModel)
		end

		return fallbackPosition
	end

	function MatchPresentationController:_buildLoosePassRollTarget(payload, receiverSlot, receiverModel, startPosition, landingPosition)
		local receiverPos = self:_getPassReceiverGroundPosition(receiverSlot, receiverModel, landingPosition)
		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local attackDirection = goalTarget and MatchMotionMath.GetFlatDirection(startPosition, goalTarget.Position) or nil

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = MatchMotionMath.GetFlatDirection(startPosition, landingPosition)
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook((receiverModel and receiverModel:GetPivot().LookVector) or Vector3.new(0, 0, -1))
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = Vector3.new(0, 0, -1)
		end

		attackDirection = Vector3.new(attackDirection.X, 0, attackDirection.Z)
		if attackDirection.Magnitude <= 0.001 then
			attackDirection = Vector3.new(0, 0, -1)
		else
			attackDirection = attackDirection.Unit
		end

		local anchorPos = GetGroundedPosition(startPosition, nil)
		local receiverProgress = Vector3.new(receiverPos.X - anchorPos.X, 0, receiverPos.Z - anchorPos.Z):Dot(attackDirection)
		local landingProgress = Vector3.new(landingPosition.X - anchorPos.X, 0, landingPosition.Z - anchorPos.Z):Dot(attackDirection)

		local looseTargetPos
		local receiveMode

		if receiverProgress > landingProgress + PASS_RECEIVE_OVERRUN_BUFFER then
			-- Receiver already passed the intended landing point. Do not make him turn back;
			-- push the loose ball into his forward path instead.
			looseTargetPos = receiverPos + (attackDirection * LOOSE_PASS_AHEAD_RECEIVER_DISTANCE)
			receiveMode = "overrun-roll-ahead"
		else
			-- Receiver is late or roughly aligned. Let the ball land and roll forward,
			-- then the receiver sprints onto it.
			looseTargetPos = landingPosition + (attackDirection * LOOSE_PASS_NORMAL_ROLL_DISTANCE)
			receiveMode = "late-roll-forward"
		end

		looseTargetPos = GetGroundedPosition(looseTargetPos, receiverModel)
		local landingHeight = MatchBallConfig.PassLandingHeight or 0.32

		return Vector3.new(looseTargetPos.X, looseTargetPos.Y + landingHeight, looseTargetPos.Z), attackDirection, receiveMode
	end

	function MatchPresentationController:_applyLoosePassReceiverChaseTarget(payload, receiverSlot, receiverModel, targetPosition, attackDirection)
		if not payload or not receiverModel or not targetPosition then
			return
		end

		local numericReceiverSlot = tonumber(receiverSlot)
		local receiverPos = self:_getPassReceiverGroundPosition(receiverSlot, receiverModel, targetPosition)
		local groundedTarget = GetGroundedPosition(targetPosition, receiverModel)
		local lookDirection = attackDirection

		if not lookDirection or lookDirection.Magnitude <= 0.001 then
			local goalTarget = MatchZoneQuery.GetGoalTarget()
			lookDirection = goalTarget and MatchMotionMath.GetFlatDirection(groundedTarget, goalTarget.Position) or nil
		end

		if not lookDirection or lookDirection.Magnitude <= 0.001 then
			lookDirection = MatchMotionMath.GetFlatDirection(receiverPos, groundedTarget)
		end

		if not lookDirection or lookDirection.Magnitude <= 0.001 then
			lookDirection = Vector3.new(0, 0, -1)
		end

		local lookTarget = groundedTarget + lookDirection.Unit
		local distance = GetFlatDistance(receiverPos, groundedTarget)
		local chaseSpeed = math.clamp(distance * 3.25, LOOSE_PASS_MIN_CHASE_SPEED, LOOSE_PASS_MAX_CHASE_SPEED)

		if self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.SetLocalMatchActorTarget
			and numericReceiverSlot
			and numericReceiverSlot > 1
		then
			local ok = self.MatchActorRuntimeController:SetLocalMatchActorTarget(
				LocalPlayer,
				numericReceiverSlot,
				MatchMotionMath.BuildFlatLookAtCFrame(groundedTarget, lookTarget),
				{
					ExpectedAnimation = "Run",
					MoveSpeed = chaseSpeed,
					LookAtPosition = lookTarget,
					FacingMode = "LookAtPosition",
					KeepAnimationWhenReached = true,
				}
			)

			if ok then
				return
			end
		end

		-- Fallback for non-runtime actors.
		local currentCFrame = self:_getActorCurrentCFrame(receiverSlot, receiverModel)
			or (receiverModel:IsA("Model") and receiverModel:GetPivot())
		if not currentCFrame then
			return
		end

		local currentPos = GetGroundedPosition(currentCFrame.Position, receiverModel)
		local nextPos = select(1, StepFlatTowards(currentPos, groundedTarget, chaseSpeed, 1 / 60))
		nextPos = GetGroundedPosition(nextPos, receiverModel)
		self:_applyActorCFrame(receiverSlot, receiverModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, lookTarget))
		self:_playMotionAnimation(receiverModel, "Run", 1.0)
	end

	function MatchPresentationController:_settleSuccessfulPassReceive(payload, targetSlot, targetModel, startPosition, landingPosition)
		if not payload or not targetModel or not self.MatchBallController then
			return false
		end

		local ballPosition = self.MatchBallController.GetBallPosition and self.MatchBallController:GetBallPosition() or landingPosition
		ballPosition = ballPosition or landingPosition
		local receiverPosition = self:_getPassReceiverGroundPosition(targetSlot, targetModel, landingPosition)

		if receiverPosition and ballPosition and GetFlatDistance(receiverPosition, ballPosition) <= PASS_RECEIVE_CATCH_DISTANCE then
			self.MatchBallController:AttachToActor(targetModel, MatchBallConfig.ReceiveOffset)
			if self._beginBallFollow then
				self:_beginBallFollow(targetModel)
			end
			return true
		end

		local looseTargetPos, attackDirection, receiveMode = self:_buildLoosePassRollTarget(
			payload,
			targetSlot,
			targetModel,
			startPosition or landingPosition,
			ballPosition or landingPosition
		)

		if self.MatchBallController.PlayLoosePassRoll then
			self.MatchBallController:PlayLoosePassRoll(ballPosition or landingPosition, looseTargetPos, LOOSE_PASS_ROLL_DURATION, {
				BounceHeight = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.LooseBounceHeight or 0.32,
				TrailLinger = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.TrailLinger or 0.18,
				SpecialEffects = isGreenActionPayload(payload),
				EffectsDuration = LOOSE_PASS_ROLL_DURATION + 0.45,
			})
		else
			self.MatchBallController:PlayArc(ballPosition or landingPosition, looseTargetPos, LOOSE_PASS_ROLL_DURATION, 0.28)
		end

		local chaseStartedAt = os.clock()
		local nextTargetRefreshAt = 0

		while self:_isSessionActive(payload.SessionId)
			and targetModel.Parent
			and not self.IsPreQteFrozen
			and os.clock() - chaseStartedAt <= LOOSE_PASS_CHASE_MAX_SECONDS
		do
			local liveBallPosition = self.MatchBallController.GetBallPosition and self.MatchBallController:GetBallPosition() or looseTargetPos
			liveBallPosition = liveBallPosition or looseTargetPos
			local liveReceiverPosition = self:_getPassReceiverGroundPosition(targetSlot, targetModel, liveBallPosition)

			if liveReceiverPosition and liveBallPosition and GetFlatDistance(liveReceiverPosition, liveBallPosition) <= PASS_RECEIVE_CATCH_DISTANCE then
				self.MatchBallController:AttachToActor(targetModel, MatchBallConfig.ReceiveOffset)
				if self._beginBallFollow then
					self:_beginBallFollow(targetModel)
				end
				return true
			end

			if os.clock() >= nextTargetRefreshAt then
				self:_applyLoosePassReceiverChaseTarget(payload, targetSlot, targetModel, liveBallPosition, attackDirection)
				nextTargetRefreshAt = os.clock() + LOOSE_PASS_CHASE_TARGET_REFRESH_SECONDS
			end

			RunService.RenderStepped:Wait()
		end

		-- Safety fallback: do not block the match forever. This should rarely run;
		-- receiver was already sprinting at loose-ball speed for the timeout window.
		if self:_isSessionActive(payload.SessionId) and targetModel.Parent then
			self.MatchBallController:AttachToActor(targetModel, MatchBallConfig.ReceiveOffset)
			if self._beginBallFollow then
				self:_beginBallFollow(targetModel)
			end
			return true
		end

		return false
	end


	function MatchPresentationController:_resolveNextPassPressEnemyModel(payload, currentEnemyModel)
		if not payload then
			return nil
		end

		local currentStepIndex = tonumber(payload.StepIndex) or 1
		if currentStepIndex >= 4 then
			return currentEnemyModel
		end

		if not self._getActiveEnemyModelForPayload then
			return nil
		end

		local nextPayload = table.clone(payload)
		nextPayload.StepIndex = currentStepIndex + 1
		nextPayload.EnemyStep = (tonumber(payload.EnemyStep) or currentStepIndex) + 1
		nextPayload.ActorSlot = payload.TargetSlot or payload.ActorSlot

		local ok, nextEnemyModel = pcall(function()
			return self:_getActiveEnemyModelForPayload(nextPayload)
		end)

		if ok and nextEnemyModel and nextEnemyModel ~= currentEnemyModel then
			return nextEnemyModel
		end

		return nil
	end

	function MatchPresentationController:_buildPassDefenderInterceptTarget(currentEnemyPos, pressTargetPos, attackDirection, enemyModel)
		if not currentEnemyPos or not pressTargetPos then
			return pressTargetPos
		end

		local groundedTarget = GetGroundedPosition(pressTargetPos, enemyModel)
		local forward = attackDirection
		if not forward or forward.Magnitude <= 0.001 then
			return groundedTarget
		end

		forward = Vector3.new(forward.X, 0, forward.Z)
		if forward.Magnitude <= 0.001 then
			return groundedTarget
		end
		forward = forward.Unit

		local lateral = Vector3.new(-forward.Z, 0, forward.X)
		local enemyOffset = Vector3.new(currentEnemyPos.X - groundedTarget.X, 0, currentEnemyPos.Z - groundedTarget.Z)
		local sideSign = enemyOffset:Dot(lateral) >= 0 and 1 or -1

		local interceptTarget = groundedTarget
			+ (forward * PASS_DEFENDER_FRONT_OFFSET)
			+ (lateral * sideSign * PASS_DEFENDER_SIDE_CLEARANCE)

		local receiverGap = GetFlatDistance(interceptTarget, groundedTarget)
		if receiverGap < PASS_DEFENDER_RECEIVER_MIN_GAP then
			local awayFromReceiver = MatchMotionMath.GetFlatDirection(groundedTarget, interceptTarget)
			if awayFromReceiver.Magnitude <= 0.001 then
				awayFromReceiver = forward
			end
			interceptTarget = groundedTarget + (awayFromReceiver * PASS_DEFENDER_RECEIVER_MIN_GAP)
		end

		return GetGroundedPosition(interceptTarget, enemyModel)
	end

	function MatchPresentationController:_startPassDefenderEarlyPress(payload, enemyModel, targetModel, receiveCFrame, passDuration)
		if not payload or not enemyModel or not targetModel then
			return
		end

		local enemyRoot = GetRootPart(enemyModel)
		local targetRoot = GetRootPart(targetModel)

		if not enemyRoot or not targetRoot then
			return
		end

		local sessionId = payload.SessionId
		local activeDuration = math.max((tonumber(passDuration) or 0.6) * PASS_DEFENDER_EARLY_PRESS_DURATION_SCALE, 0.45)
		local fullDuration = tonumber(passDuration) or 0.6
		local startDelay = PASS_DEFENDER_EARLY_PRESS_START_DELAY
		local predictedReceivePos = receiveCFrame and receiveCFrame.Position or targetRoot.Position

		task.spawn(function()
			if startDelay > 0 then
				self:_waitForSessionSeconds(sessionId, startDelay)
			end

			if not self:_isSessionActive(sessionId)
				or not enemyModel.Parent
				or not targetModel.Parent
			then
				return
			end


			self.DefeatedEnemyRecoveryTokens = self.DefeatedEnemyRecoveryTokens or {}
			self.DefeatedEnemyRecoveryTokens[enemyModel] = nil

			if self._acquireEnemyMotionLock and not self:_acquireEnemyMotionLock(enemyModel, "PassPress") then
				return
			end

			self.PassPressTokens = self.PassPressTokens or {}
			self.PassPressTokens[enemyModel] = (self.PassPressTokens[enemyModel] or 0) + 1
			local myPressToken = self.PassPressTokens[enemyModel]

			local startedAt = os.clock()

			while self:_isSessionActive(sessionId)
				and enemyModel.Parent
				and targetModel.Parent
				and not self.IsPreQteFrozen
				and (os.clock() - startedAt) <= fullDuration
				and self.PassPressTokens[enemyModel] == myPressToken
					and not (self._isEnemyMotionLockedByOther and self:_isEnemyMotionLockedByOther(enemyModel, "PassPress"))
			do
				local elapsed = os.clock() - startedAt
				local deltaTime = RunService.RenderStepped:Wait()
				local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

				local currentEnemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
				local liveTargetPos = GetGroundedPosition(targetRoot.Position, targetModel)
				local pressTargetPos = GetGroundedPosition(predictedReceivePos, targetModel)

				if GetFlatDistance(liveTargetPos, pressTargetPos) <= PASS_DEFENDER_PREDICTED_TARGET_SWITCH_DISTANCE then
					pressTargetPos = liveTargetPos
				end

				local distanceToPressTarget = GetFlatDistance(currentEnemyPos, pressTargetPos)
				local nextPos = currentEnemyPos
				local shouldRun = false

				if elapsed <= activeDuration then
					local goalTarget = MatchZoneQuery.GetGoalTarget()
					local attackDirection = goalTarget
						and MatchMotionMath.GetFlatDirection(pressTargetPos, goalTarget.Position)
						or GetFlatUnitFromLook(targetRoot.CFrame.LookVector)

					if attackDirection.Magnitude <= 0.001 then
						attackDirection = GetFlatUnitFromLook(targetRoot.CFrame.LookVector)
					end

					local interceptTarget = self:_buildPassDefenderInterceptTarget(
						currentEnemyPos,
						pressTargetPos,
						attackDirection,
						enemyModel
					)

					local distanceToInterceptTarget = GetFlatDistance(currentEnemyPos, interceptTarget)
					local adaptivePressSpeed = math.clamp(
						distanceToInterceptTarget * 1.55,
						PASS_DEFENDER_EARLY_PRESS_MIN_SPEED,
						PASS_DEFENDER_EARLY_PRESS_MAX_SPEED
					)

					local configuredPressSpeed = tonumber(PASS_DEFENDER_PRESS_AFTER_REACTION_SPEED) or 17.0
					local pressSpeed = math.max(configuredPressSpeed, adaptivePressSpeed)

					if distanceToPressTarget <= PASS_DEFENDER_EARLY_PRESS_STOP_GAP then
						pressSpeed = math.min(pressSpeed, 10.5)
					end

					if distanceToPressTarget > PASS_DEFENDER_RECEIVER_MIN_GAP then
						nextPos = select(1, StepFlatTowards(
							currentEnemyPos,
							interceptTarget,
							pressSpeed,
							scaledDeltaTime
						))
						shouldRun = true
					end
				end

				nextPos = GetGroundedPosition(nextPos, enemyModel)

				ApplyPivot(
					enemyModel,
					MatchMotionMath.BuildFlatLookAtCFrame(nextPos, pressTargetPos)
				)

				self:_playMotionAnimation(enemyModel, shouldRun and "Run" or "Idle", 1.0)
			end

			if self.PassPressTokens and self.PassPressTokens[enemyModel] == myPressToken then
				self.PassPressTokens[enemyModel] = nil
				if self._releaseEnemyMotionLock then
					self:_releaseEnemyMotionLock(enemyModel, "PassPress")
				end
			end

			if not self:_isSessionActive(sessionId) or not enemyModel.Parent then
				return
			end

			local finalEnemyPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
			local finalTargetPos = targetRoot and GetGroundedPosition(targetRoot.Position, targetModel) or finalEnemyPos

			ApplyPivot(
				enemyModel,
				MatchMotionMath.BuildFlatLookAtCFrame(finalEnemyPos, finalTargetPos)
			)

			self:_playMotionAnimation(enemyModel, "Run", 1.0)
		end)
	end

	-- // [ FORWARD FLOW HELPERS ] // --

	function MatchPresentationController:_normalizeForwardPassPayload(payload)
		if not payload then
			return payload
		end

		local stepIndex = tonumber(payload.StepIndex) or tonumber(payload.Step) or 1
		payload.StepIndex = stepIndex
		payload.Step = tonumber(payload.Step) or stepIndex

		if payload.Action == "Pass" then
			payload.TargetSlot = tonumber(payload.TargetSlot) or tonumber(payload.ToSlot)

			if payload.Player2Branch == true or payload.PassMode == "Player2BranchPass" then
				payload.ActorSlot = tonumber(payload.ActorSlot or payload.FromSlot) or 2
				payload.FromSlot = payload.ActorSlot
				payload.TargetSlot = 4
				payload.ToSlot = 4
				payload.TargetReceiveStep = 5
				payload.UseZone3RunnerTarget = nil
				payload.UseZone3RunnerSlot = nil
				return payload
			end

			if stepIndex == 4 or payload.UseZone3RunnerTarget then
				local runnerSlot = nil
				if self._resolveZone3RunnerSlot then
					runnerSlot = self:_resolveZone3RunnerSlot(payload)
				end

				runnerSlot = tonumber(runnerSlot) or tonumber(self.Zone3RunnerSlot) or tonumber(payload.Zone3RunnerSlot) or 3

				if runnerSlot ~= tonumber(payload.ActorSlot or payload.FromSlot) then
					payload.TargetSlot = runnerSlot
					payload.ToSlot = runnerSlot
					payload.TargetReceiveStep = 5
					payload.PassMode = "ReturnThroughBall"
					payload.UseZone3RunnerTarget = true
				end
			else
				payload.TargetReceiveStep = tonumber(payload.TargetReceiveStep) or math.clamp(stepIndex + 1, 2, 5)
				payload.PassMode = payload.PassMode or "ForwardLane"
			end
		end

		return payload
	end

	function MatchPresentationController:_rememberZone3RunnerAfterStep2(payload, receiverSlot)
		if not payload or tonumber(payload.StepIndex or payload.Step) ~= 2 then
			return nil
		end

		local runnerSlot = 3
		if self._rememberZone3RunnerSlot then
			runnerSlot = self:_rememberZone3RunnerSlot(payload)
		else
			self.Zone3RunnerSlot = runnerSlot
		end

		return runnerSlot
	end

	function MatchPresentationController:_cancelDribbleContinuation(_reason)
		self.DribbleContinuationToken = (self.DribbleContinuationToken or 0) + 1
		self.DribbleContinuationOwnerSlot = nil
		self.DribbleContinuationSessionId = nil
	end

	function MatchPresentationController:_continueCarrierAfterDribbleSuccess(payload, carrierSlot, carrierModel, finalActorPos, fallbackLookPos)
		if not payload or not carrierModel or not self:_isSessionActive(payload.SessionId) then
			return
		end

		local numericCarrierSlot = tonumber(carrierSlot) or tonumber(payload.ActorSlot) or tonumber(self.ActiveActorSlot) or 1
		local currentCFrame = self:_getActorCurrentCFrame(numericCarrierSlot, carrierModel) or carrierModel:GetPivot()
		local currentPos = GetGroundedPosition(finalActorPos or currentCFrame.Position, carrierModel)

		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local moveDirection = nil

		if goalTarget then
			moveDirection = MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
		end

		if not moveDirection or moveDirection.Magnitude <= 0.001 then
			moveDirection = fallbackLookPos and MatchMotionMath.GetFlatDirection(currentPos, fallbackLookPos) or nil
		end

		if not moveDirection or moveDirection.Magnitude <= 0.001 then
			moveDirection = GetFlatUnitFromLook(currentCFrame.LookVector)
		end

		if not moveDirection or moveDirection.Magnitude <= 0.001 then
			return
		end

		local stepIndex = tonumber(payload.StepIndex) or tonumber(payload.Step) or 1
		local leadDistance = stepIndex >= 4 and 12.0 or 9.5
		local specialTarget = nil

		local isPlayer2BranchDribble = stepIndex == 2 and numericCarrierSlot == 2 and payload.Action == "Dribble"
		if isPlayer2BranchDribble then
			specialTarget = MatchZoneQuery.GetPlayer2BranchTarget and MatchZoneQuery.GetPlayer2BranchTarget()
				or MatchZoneQuery.GetZoneMarker(4, "Player2Target")
				or MatchZoneQuery.GetZoneMarker(2, "Player2Target")
		end

		local continueTargetPos = nil
		if specialTarget then
			continueTargetPos = GetGroundedPosition(specialTarget.Position, carrierModel)
		else
			continueTargetPos = GetGroundedPosition(currentPos + (moveDirection.Unit * leadDistance), carrierModel)
		end

		local targetDirection = MatchMotionMath.GetFlatDirection(currentPos, continueTargetPos)
		if targetDirection.Magnitude <= 0.001 then
			targetDirection = moveDirection.Unit
		end

		local lookTarget = continueTargetPos + targetDirection.Unit

		if self.MatchBallController and self.MatchBallController.AttachToActor then
			self.MatchBallController:AttachToActor(carrierModel, MatchBallConfig.ReceiveOffset)
		end

		if self._beginBallFollow then
			self:_beginBallFollow(carrierModel)
		end

		if isPlayer2BranchDribble then
			if self._stopSupportMotion then
				self:_stopSupportMotion()
			end

			local player4Target = MatchZoneQuery.GetPlayer4BranchTarget and MatchZoneQuery.GetPlayer4BranchTarget()
			local player4Model = self:_getControlledActorModel(4)
			if player4Target and player4Model then
				local player4TargetPos = GetGroundedPosition(player4Target.Position, player4Model)
				local player4Current = self:_getActorCurrentCFrame(4, player4Model) or player4Model:GetPivot()
				local player4Direction = MatchMotionMath.GetFlatDirection(player4Current.Position, player4TargetPos)
				if player4Direction.Magnitude <= 0.001 then
					player4Direction = targetDirection.Magnitude > 0.001 and targetDirection.Unit or GetFlatUnitFromLook(player4Current.LookVector)
				end
				local player4LookTarget = player4TargetPos + player4Direction.Unit
				self:_applyActorCFrame(
					4,
					player4Model,
					MatchMotionMath.BuildFlatLookAtCFrame(player4TargetPos, player4LookTarget),
					{
						ExpectedAnimation = "Run",
						MoveSpeed = PLAYER2_BRANCH_RECEIVER_REPOSITION_SPEED,
						LookAtPosition = player4LookTarget,
						FacingMode = "LookAtPosition",
						KeepAnimationWhenReached = true,
					}
				)
			end
		end

		-- This bridge owns the carrier only until the next approach/QTE takes over.
		-- Without this token, the dribble bridge and next approach both ApplyPivot the carrier,
		-- which creates the visible vibration after the first successful dribble.
		self.DribbleContinuationToken = (self.DribbleContinuationToken or 0) + 1
		local continuationToken = self.DribbleContinuationToken
		self.DribbleContinuationOwnerSlot = numericCarrierSlot
		self.DribbleContinuationSessionId = tostring(payload.SessionId)

		-- Companion actors are runtime-driven, so setting a short forward target is smooth.
		-- The main player/proxy is direct-driven; never ApplyPivot him to the next marker,
		-- because that causes the visible flash/snap after dribble success.
		if self:_isCompanionSlot(numericCarrierSlot) then
			local branchMoveSpeed = isPlayer2BranchDribble
				and PLAYER2_BRANCH_CARRIER_SPEED
				or 34.0

			self:_applyActorCFrame(
				numericCarrierSlot,
				carrierModel,
				MatchMotionMath.BuildFlatLookAtCFrame(continueTargetPos, lookTarget),
				{
					ExpectedAnimation = "Run",
					MoveSpeed = branchMoveSpeed,
					LookAtPosition = lookTarget,
					FacingMode = "LookAtPosition",
					KeepAnimationWhenReached = true,
				}
			)
			return
		end

		-- Start Run on the same frame, before the RenderStepped continuation loop.
		self:_playMotionAnimation(carrierModel, "Run", 1.08)

		task.spawn(function()
			local startedAt = os.clock()
			local maxDuration = 1.05
			local moveSpeed = 34.0

			while self:_isSessionActive(payload.SessionId)
				and carrierModel.Parent
				and self.DribbleContinuationToken == continuationToken
				and not self.IsPreQteFrozen
				and not self.IsApproachBusy
				and os.clock() - startedAt <= maxDuration
			do
				local dt = RunService.RenderStepped:Wait()
				
				if self.DribbleContinuationToken ~= continuationToken or self.IsApproachBusy or self.IsPreQteFrozen then
					break
				end
				
				local scaledDt = self:_getScaledDeltaTime(dt)
				local liveCFrame = carrierModel:GetPivot()
				local livePos = GetGroundedPosition(liveCFrame.Position, carrierModel)
				local nextPos, reached = StepFlatTowards(livePos, continueTargetPos, moveSpeed, scaledDt)

				nextPos = GetGroundedPosition(nextPos, carrierModel)
				local nextLookTarget = nextPos + targetDirection.Unit

				self:_applyActorCFrame(numericCarrierSlot, carrierModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, nextLookTarget))
				self:_playMotionAnimation(carrierModel, "Run", 1.0)

				if reached or GetFlatDistance(nextPos, continueTargetPos) <= 0.35 then
					break
				end
			end

			if self.DribbleContinuationToken == continuationToken then
				self.DribbleContinuationOwnerSlot = nil
				self.DribbleContinuationSessionId = nil
			end
		end)
	end

	function MatchPresentationController:_continueReturnReceiverToCarryPoint(payload, receiverSlot, receiverModel)
		if not payload or not receiverModel or not self:_isSessionActive(payload.SessionId) then
			return
		end

		local stepIndex = tonumber(payload.StepIndex) or tonumber(payload.Step) or 1
		local isReturnThroughBall = payload.PassMode == "ReturnThroughBall"
			or payload.UseZone3RunnerTarget
			or stepIndex >= 4

		if not isReturnThroughBall then
			return
		end

		local numericReceiverSlot = tonumber(receiverSlot)
		if not numericReceiverSlot then
			return
		end

		local currentCFrame = self:_getActorCurrentCFrame(numericReceiverSlot, receiverModel) or receiverModel:GetPivot()
		local currentPos = GetGroundedPosition(currentCFrame.Position, receiverModel)

		local goalTarget = MatchZoneQuery.GetGoalTarget()
		local attackDirection = nil

		if goalTarget then
			attackDirection = MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook(currentCFrame.LookVector)
		end

		if not attackDirection or attackDirection.Magnitude <= 0.001 then
			attackDirection = Vector3.new(0, 0, -1)
		end

		attackDirection = Vector3.new(attackDirection.X, 0, attackDirection.Z)
		if attackDirection.Magnitude <= 0.001 then
			attackDirection = Vector3.new(0, 0, -1)
		else
			attackDirection = attackDirection.Unit
		end

		local carryMarker = MatchZoneQuery.GetCarryPoint and MatchZoneQuery.GetCarryPoint(3, 2)
		local carryPos = carryMarker and GetGroundedPosition(carryMarker.Position, receiverModel) or nil
		local targetPos = nil
		local targetMode = "forward-carry"

		if carryPos then
			local carryDelta = Vector3.new(
				carryPos.X - currentPos.X,
				0,
				carryPos.Z - currentPos.Z
			)

			local carryAheadDistance = carryDelta:Dot(attackDirection)

			if carryAheadDistance > RETURN_RECEIVER_BACKTRACK_TOLERANCE then
				-- CarryPoint is still in front, so using the marker is safe.
				targetPos = carryPos
				targetMode = "marker-carry"
			else
				-- Receiver already passed the marker or is nearly level with it.
				-- Never make the player rotate back toward ReceivePoint/CarryPoint; continue the run
				-- in the goal direction so the next QTE feels like a through-ball continuation.
				targetPos = currentPos + (attackDirection * RETURN_RECEIVER_FORWARD_LEAD_DISTANCE)
				targetMode = "skip-backtrack-forward"
			end
		else
			targetPos = currentPos + (attackDirection * RETURN_RECEIVER_FORWARD_LEAD_DISTANCE)
		end

		targetPos = GetGroundedPosition(targetPos, receiverModel)
		local lookTarget = targetPos + attackDirection

		self:_applyActorCFrame(
			numericReceiverSlot,
			receiverModel,
			MatchMotionMath.BuildFlatLookAtCFrame(targetPos, lookTarget),
			{
				ExpectedAnimation = "Run",
				MoveSpeed = RETURN_RECEIVER_CARRY_SPEED,
				LookAtPosition = lookTarget,
				FacingMode = "LookAtPosition",
				KeepAnimationWhenReached = true,
			}
		)

	end

	function MatchPresentationController:_runTeamChaseAndLoseAfterTurnover(payload, enemyModel, chaseWorldPosition, chaseSlots)
		if not payload or not enemyModel then
			return
		end

		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return
		end

		local teamSlots = chaseSlots or {1, 2, 3, 4}
		local teamActors = {}
		local seenSlots = {}

		for _, slot in ipairs(teamSlots) do
			local numericSlot = tonumber(slot)
			if not numericSlot or seenSlots[numericSlot] then
				continue
			end
			seenSlots[numericSlot] = true

			local model = self:_getControlledActorModel(slot)
				or MatchActorResolver.GetActorModelBySlot(slot, self.PlayerProxy)
			local root = model and GetRootPart(model)
			if model and root then
				local liveCFrame = self:_getActorCurrentCFrame(numericSlot, model) or root.CFrame
				local currentPos = GetGroundedPosition(liveCFrame.Position, model)
				local chasePoint = GetGroundedPosition(chaseWorldPosition or enemyRoot.Position, model)
				local chaseDirection = MatchMotionMath.GetFlatDirection(currentPos, chasePoint)
				local targetPos = currentPos

				if chaseDirection.Magnitude > 0.001 then
					local targetDistance = math.min(GetFlatDistance(currentPos, chasePoint), PASS_FAILURE_CHASE_STEP_DISTANCE)
					targetPos = GetGroundedPosition(currentPos + (chaseDirection.Unit * targetDistance), model)
				end

				table.insert(teamActors, {
					Slot = numericSlot,
					Model = model,
					Root = root,
					Position = currentPos,
					TargetPos = targetPos,
					LookPosition = chasePoint,
					Reached = GetFlatDistance(currentPos, targetPos) <= 0.25,
				})
			end
		end

		if #teamActors == 0 then
			return
		end

		local startedAt = os.clock()

		for _, actor in ipairs(teamActors) do
			self:_playMotionAnimation(actor.Model, "Run", 1.12)
		end

		while self:_isSessionActive(payload.SessionId)
			and enemyModel.Parent
			and os.clock() - startedAt < PASS_FAILURE_TEAM_CHASE_SECONDS
		do
			local allReached = true
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

			for _, actor in ipairs(teamActors) do
				if actor.Model.Parent and not actor.Reached then
					local liveCFrame = self:_getActorCurrentCFrame(actor.Slot, actor.Model)
					if liveCFrame then
						actor.Position = GetGroundedPosition(liveCFrame.Position, actor.Model)
					end

					if GetFlatDistance(actor.Position, actor.TargetPos) <= 0.25 then
						actor.Reached = true
					else
						allReached = false

						local remainingTime = math.max(PASS_FAILURE_TEAM_CHASE_SECONDS - (os.clock() - startedAt), 0.05)
						local moveSpeed = math.clamp(
							GetFlatDistance(actor.Position, actor.TargetPos) / remainingTime,
							PASS_FAILURE_CHASE_MIN_SPEED,
							PASS_FAILURE_CHASE_MAX_SPEED
						)
						local nextPos = select(1, StepFlatTowards(
							actor.Position,
							actor.TargetPos,
							moveSpeed,
							scaledDeltaTime
						))

						actor.Position = GetGroundedPosition(nextPos, actor.Model)
						local facingCFrame = MatchMotionMath.BuildFlatLookAtCFrame(actor.Position, actor.LookPosition)

						ApplyPivot(actor.Model, facingCFrame)
						self:_applyActorCFrame(actor.Slot, actor.Model, facingCFrame, {
							ExpectedAnimation = "Run",
							FacingMode = "LookAtPosition",
							LookAtPosition = actor.LookPosition,
							MoveSpeed = moveSpeed,
						})
						self:_playMotionAnimation(actor.Model, "Run", moveSpeed >= 28 and 1.18 or 1.1)
					end
				end
			end

			if allReached then
				break
			end
		end

		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		for _, actor in ipairs(teamActors) do
			if actor.Model.Parent then
				local liveCFrame = self:_getActorCurrentCFrame(actor.Slot, actor.Model)
				local actorPos = GetGroundedPosition(liveCFrame and liveCFrame.Position or actor.Position, actor.Model)
				local facingCFrame = MatchMotionMath.BuildFlatLookAtCFrame(actorPos, actor.LookPosition)

				ApplyPivot(actor.Model, facingCFrame)
				self:_applyActorCFrame(actor.Slot, actor.Model, facingCFrame, {
					ExpectedAnimation = "Idle",
					FacingMode = "Idle",
					LookAtPosition = actor.LookPosition,
					MoveSpeed = 0,
				})
				self:_playRigAnimation(actor.Model, "Lose", 1.0)
			end
		end
	end

	-- // [ PASS RESOLVE ] // --

	function MatchPresentationController:_handlePassResolved(payload, actorModel, enemyModel, actorRoot, enemyRoot, success)
		payload = self:_normalizeForwardPassPayload(payload)
		local isGreenPass = isGreenActionPayload(payload)
		local shouldBoostPassCamera = isGreenPass or isYellowActionPayload(payload)
		activateGreenActionFx(self, payload, actorModel, GREEN_ACTION_FX_DURATION)
		playActionSound(isGreenPass and "BallFlying" or "WhooshKick", {
			Volume = isGreenPass and 0.85 or 0.75,
			Lifetime = 3,
		})

		local targetModel = self:_getControlledActorModel(payload.TargetSlot)
			or MatchActorResolver.GetActorModelBySlot(payload.TargetSlot, self.PlayerProxy)

		local targetRoot = GetRootPart(targetModel)
		local targetCFrame = nil

		if self.MatchActorRuntimeController
			and self.MatchActorRuntimeController.GetLocalMatchActorCFrame
			and tonumber(payload.TargetSlot or 0) > 1
		then
			targetCFrame = self.MatchActorRuntimeController:GetLocalMatchActorCFrame(
				LocalPlayer,
				tonumber(payload.TargetSlot)
			)
		end

		local currentCFrame = self:_getActorCurrentCFrame(payload.ActorSlot, actorModel) or actorRoot.CFrame
		local startPos = self:_getPassStartPosition(actorModel, actorRoot)

		local endPos = nil
		local passDuration = nil
		local passArcHeight = nil
		local failedPassAttackDirection = nil

		if success then
			local adjustedReceiveCFrame = self:_buildForwardReceiveCFrame(
				payload,
				actorModel,
				targetModel,
				currentCFrame,
				targetCFrame or (targetRoot and targetRoot.CFrame)
			)

			if adjustedReceiveCFrame and targetModel then
				targetCFrame = adjustedReceiveCFrame
			end

			local landingSeed = (targetCFrame and targetCFrame.Position)
				or (targetRoot and targetRoot.Position)
				or startPos

			endPos = self:_getPassReceivePosition(targetModel, targetRoot, targetCFrame, landingSeed)

			self:_hideBallVisualsForPassKick(actorModel, targetModel, enemyModel)

			local lookAtPosition = Vector3.new(endPos.X, currentCFrame.Position.Y, endPos.Z)
			local updatedCFrame, updatedStartPosition = self:_faceActorTowardPassTarget(
				payload,
				actorModel,
				actorRoot,
				lookAtPosition
			)

			currentCFrame = updatedCFrame or currentCFrame
			startPos = updatedStartPosition or startPos

			endPos = self:_getPassReceivePosition(targetModel, targetRoot, targetCFrame, endPos)
			passDuration = self:_getSuccessPassDuration(startPos, endPos)
			passArcHeight = self:_getSuccessPassArcHeight(startPos, endPos)

			if shouldBoostPassCamera then
				playActionCameraBoost(self, "Pass", startPos, endPos, getQteTier(payload))
			end

			if targetCFrame and targetModel then
				self:_movePassReceiverToCFrame(payload, payload.TargetSlot, targetModel, targetCFrame, passDuration)
			end

			self:_moveOtherLaneRunnerForward(payload, payload.TargetSlot, currentCFrame)

			local startedStep3OverlapSprint = false

			if self.MatchBallController then
				self:_hideBallVisualsForPassKick(actorModel, targetModel, enemyModel)
				self:_waitForSessionSeconds(payload.SessionId, PASS_KICK_START_SETTLE_SECONDS)

				startPos = self:_getPassStartPosition(actorModel, actorRoot, endPos) or startPos
				passDuration = self:_getSuccessPassDuration(startPos, endPos)
				passArcHeight = self:_getSuccessPassArcHeight(startPos, endPos)

				if enemyModel then
					self:_sendDefeatedEnemyBackwards(payload, enemyModel)
				end

				local pressEnemyModel = self:_resolveNextPassPressEnemyModel(payload, enemyModel)
				if pressEnemyModel and pressEnemyModel ~= enemyModel and targetModel then
					self:_startPassDefenderEarlyPress(payload, pressEnemyModel, targetModel, targetCFrame, passDuration)
				elseif tonumber(payload.StepIndex) >= 3 and enemyModel and targetModel then
					self:_startPassDefenderEarlyPress(payload, enemyModel, targetModel, targetCFrame, passDuration)
				end

				self:_playPassArcFromLiveBall(payload, startPos, endPos, passDuration, passArcHeight)

				if tonumber(payload.StepIndex or payload.Step) == 3 and self._startStep3PasserOverlapSprint then
					startedStep3OverlapSprint = self:_startStep3PasserOverlapSprint(payload, payload.ActorSlot or payload.FromSlot, currentCFrame) ~= nil
				end
			end

			if not startedStep3OverlapSprint
				and tonumber(payload.StepIndex or payload.Step) == 3
				and self._startStep3PasserOverlapSprint
			then
				self:_startStep3PasserOverlapSprint(payload, payload.ActorSlot or payload.FromSlot, currentCFrame)
			end
		else
			local adjustedReceiveCFrame = self:_buildForwardReceiveCFrame(
				payload,
				actorModel,
				targetModel,
				currentCFrame,
				targetCFrame or (targetRoot and targetRoot.CFrame)
			)

			if adjustedReceiveCFrame and targetModel then
				targetCFrame = adjustedReceiveCFrame
			end

			local landingSeed = (targetCFrame and targetCFrame.Position)
				or (targetRoot and targetRoot.Position)
				or startPos

			endPos = self:_getPassReceivePosition(targetModel, targetRoot, targetCFrame, landingSeed)
			endPos, failedPassAttackDirection = self:_keepFailedPassLandingForward(
				actorModel,
				targetModel,
				currentCFrame,
				startPos,
				endPos
			)
			passDuration = self:_getSuccessPassDuration(startPos, endPos)
			passArcHeight = self:_getSuccessPassArcHeight(startPos, endPos)

			local lookAtPosition = Vector3.new(endPos.X, currentCFrame.Position.Y, endPos.Z)
			local updatedCFrame, updatedStartPosition = self:_faceActorTowardPassTarget(
				payload,
				actorModel,
				actorRoot,
				lookAtPosition
			)

			currentCFrame = updatedCFrame or currentCFrame

			if updatedStartPosition then
				startPos = updatedStartPosition
				endPos, failedPassAttackDirection = self:_keepFailedPassLandingForward(
					actorModel,
					targetModel,
					currentCFrame,
					startPos,
					endPos
				)
				passDuration = self:_getSuccessPassDuration(startPos, endPos)
				passArcHeight = self:_getSuccessPassArcHeight(startPos, endPos)
			end

			if self.MatchBallController then
				self:_hideBallVisualsForPassKick(actorModel, targetModel, enemyModel)
				self:_waitForSessionSeconds(payload.SessionId, PASS_KICK_START_SETTLE_SECONDS)

				startPos = self:_getPassStartPosition(actorModel, actorRoot, endPos) or startPos
				endPos, failedPassAttackDirection = self:_keepFailedPassLandingForward(
					actorModel,
					targetModel,
					currentCFrame,
					startPos,
					endPos
				)
				passDuration = self:_getSuccessPassDuration(startPos, endPos)
				passArcHeight = self:_getSuccessPassArcHeight(startPos, endPos)
				self:_playPassArcFromLiveBall(payload, startPos, endPos, passDuration, passArcHeight)
				self:_settlePasserAfterKick(
					payload,
					actorModel,
					actorRoot,
					currentCFrame,
					endPos,
					math.min((passDuration or PASS_FAILURE_PASSER_CHASE_SECONDS) * 0.72, PASS_FAILURE_PASSER_CHASE_SECONDS)
				)


				local failedReceiveCFrame = targetCFrame
				if failedPassAttackDirection and targetModel then
					local failedReceiveGround = GetGroundedPosition(endPos, targetModel)
					failedReceiveCFrame = MatchMotionMath.BuildFlatLookAtCFrame(
						failedReceiveGround,
						failedReceiveGround + failedPassAttackDirection
					)
				end

				if failedReceiveCFrame and targetModel then
					self:_movePassReceiverToCFrame(payload, payload.TargetSlot, targetModel, failedReceiveCFrame, passDuration * 1.08)
				end

				self:_startFailedPassDefenderIntercept(payload, enemyModel, endPos, startPos, passDuration)
			end
		end

		if success then
			self.ActiveActorSlot = tonumber(payload.TargetSlot) or self.ActiveActorSlot
			self.CurrentPresentationStepIndex = tonumber(payload.StepIndex) or self.CurrentPresentationStepIndex

			self:_moveCompanionsForward(payload, payload.TargetSlot)

			if tonumber(payload.StepIndex or payload.Step) == 2 then
				self:_rememberZone3RunnerAfterStep2(payload, payload.TargetSlot)

				if self._startStep2NonReceiverArea3Sprint then
					self:_startStep2NonReceiverArea3Sprint(payload, payload.TargetSlot, currentCFrame)
				end
			end
		end

		self:_waitForSessionSeconds(payload.SessionId, (passDuration or 0.4) + 0.03)

		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		if success then
			self:_hideBallVisualsForPassKick(actorModel, targetModel, enemyModel)

			if targetModel and self.MatchBallController then
				self:_settleSuccessfulPassReceive(
					payload,
					payload.TargetSlot,
					targetModel,
					startPos,
					endPos
				)
			end

			self:_hideNonCarrierEmbeddedBalls(self.ActiveActorSlot)

			self:_continueReturnReceiverToCarryPoint(payload, payload.TargetSlot, targetModel)

			self:_waitForSessionSeconds(payload.SessionId, 0.04)
			return
		end

		self:_finishFailedPassInterception(payload, enemyModel, endPos, startPos)

		self:_runTeamChaseAndLoseAfterTurnover(payload, enemyModel, endPos, {
			payload.ActorSlot,
			payload.TargetSlot,
		})

		self:_runEnemyCarryAwayAfterTurnover(
			payload,
			enemyModel,
			currentCFrame,
			10
		)

		self:_waitForSessionSeconds(payload.SessionId, 0.18)
	end

	-- // [ STEP RESOLVE ENTRY ] // --

	function MatchPresentationController:_waitForCurrentStepPreQtePrepared(payload)
		local requiredStep = tonumber(payload and payload.StepIndex) or 0

		while self:_isSessionActive(payload.SessionId) do
			local preparedStep = tonumber(self.LastPreparedPreQteStepIndex) or 0

			if (not self.IsApproachBusy) and preparedStep >= requiredStep then
				break
			end

			RunService.RenderStepped:Wait()
		end
	end

	function MatchPresentationController:_handleStepResolved(payload)
		self:_waitForCurrentStepPreQtePrepared(payload)

		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		self:_resumeActorsAfterPreQte()
		self:_setTimeScale(DEFAULT_TIME_SCALE)

		if payload.Succeeded then
			self.CurrentSessionWins = (self.CurrentSessionWins or 0) + (payload.AwardedWins or 0)
			self.CurrentSessionGoals = (self.CurrentSessionGoals or 0) + (payload.AwardedGoals or 0)
		end

		payload.AwardedWins = self.CurrentSessionWins
		payload.AwardedGoals = self.CurrentSessionGoals

		while self.IsApproachBusy and self:_isSessionActive(payload.SessionId) do
			RunService.RenderStepped:Wait()
		end

		if not self:_isSessionActive(payload.SessionId) then
			return
		end

		self.IsPostActionBusy = true

		local readyFired = false
		local function finishPostAction(reason)
			if readyFired then
				return
			end
			readyFired = true

			self.LastCompletedPostActionStepIndex = math.max(
				tonumber(self.LastCompletedPostActionStepIndex) or 0,
				tonumber(payload.StepIndex) or 0
			)

			self:_notifyPresentationReady(payload.StepIndex, "PostAction")
			self.IsPostActionBusy = false
		end

		local actorModel = self:_getControlledActorModel(payload.ActorSlot)
		local enemyModel = self:_getActiveEnemyModelForPayload(payload)
		local actorRoot = GetRootPart(actorModel)
		local enemyRoot = GetRootPart(enemyModel)

		if not actorRoot then
			warn(string.format(
				"[MatchPresentationFlow] missing actorRoot during post-action session=%s step=%s action=%s slot=%s; acking PostAction to avoid watchdog",
				tostring(payload.SessionId),
				tostring(payload.StepIndex),
				tostring(payload.Action),
				tostring(payload.ActorSlot)
			))
			finishPostAction("post-action ready fired missing actorRoot")
			return
		end

		if payload.Action == "Shoot" then
			task.spawn(function()
				local ok, err = xpcall(function()
					self:_handleShootResolved(payload, actorModel, enemyModel, actorRoot, payload.Succeeded, function(reason)
						finishPostAction(reason or "shoot post-action ready fired")
					end)
				end, debug.traceback)

				if not ok then
					warn(string.format(
						"[MatchPresentationFlow] post-action presentation error session=%s step=%s action=%s: %s",
						tostring(payload.SessionId),
						tostring(payload.StepIndex),
						tostring(payload.Action),
						tostring(err)
					))
					finishPostAction("post-action ready fired after shoot error")
					return
				end

				finishPostAction("post-action ready fired after shoot completion")
			end)
		else
			local ok, err = xpcall(function()
				if payload.Action == "Dribble" then
					self:_handleDribbleResolved(payload, actorModel, enemyModel, actorRoot, enemyRoot, payload.Succeeded)
				elseif payload.Action == "Pass" then
					self:_handlePassResolved(payload, actorModel, enemyModel, actorRoot, enemyRoot, payload.Succeeded)
				else
					warn(string.format(
						"[MatchPresentationFlow] unknown post-action action=%s session=%s step=%s; acking PostAction",
						tostring(payload.Action),
						tostring(payload.SessionId),
						tostring(payload.StepIndex)
					))
				end
			end, debug.traceback)

			if not ok then
				warn(string.format(
					"[MatchPresentationFlow] post-action presentation error session=%s step=%s action=%s: %s",
					tostring(payload.SessionId),
					tostring(payload.StepIndex),
					tostring(payload.Action),
					tostring(err)
				))
			end

			finishPostAction(ok and "post-action ready fired" or "post-action ready fired after error")
		end

		if self:_isSessionActive(payload.SessionId)
			and not self.IsPreQteFrozen
			and payload.Action ~= "Shoot"
		then
			self:_animateIdleEnemies(payload.SessionId)
			self:_animateIdleAllies(payload.SessionId)
		end
	end

	-- // [ DAY 2C: STRICT FORWARD PASS RECEIVE ] // --

end
