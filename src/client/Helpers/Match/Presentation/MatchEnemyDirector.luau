return function(MatchPresentationController, Context)
	local RunService = Context.Services.RunService

	local MatchActorResolver = Context.MatchActorResolver
	local MatchSceneQuery = Context.MatchSceneQuery
	local MatchZoneQuery = Context.MatchZoneQuery
	local MatchMotionMath = Context.MatchMotionMath

	local Constants = Context.Constants
	local Utils = Context.Utils

	local THRESHOLDS = Constants.THRESHOLDS

	local GOALKEEPER_RUNTIME_SLOT = Constants.GOALKEEPER_RUNTIME_SLOT

	local DEFEATED_ENEMY_RECOVERY_SPEED = Constants.DEFEATED_ENEMY_RECOVERY_SPEED
	local DEFEATED_ENEMY_RECOVERY_DISTANCE = Constants.DEFEATED_ENEMY_RECOVERY_DISTANCE
	local DEFEATED_ENEMY_COVER_FRONT_DISTANCE = Constants.DEFEATED_ENEMY_COVER_FRONT_DISTANCE
	local DEFEATED_ENEMY_MIN_RECOVERY_FORWARD = Constants.DEFEATED_ENEMY_MIN_RECOVERY_FORWARD

	-- Beaten enemy tuning:
	-- Movement is slowed/limited, but locomotion animation remains normal speed.
	local BEATEN_ENEMY_SPEED_FACTOR = Constants.BEATEN_ENEMY_SPEED_FACTOR or 0.62
	local BEATEN_ENEMY_MAX_SPEED = Constants.BEATEN_ENEMY_MAX_SPEED or 10.25
	local BEATEN_ENEMY_MIN_GAP = Constants.BEATEN_ENEMY_MIN_GAP or 11.5
	local BEATEN_ENEMY_SIDE_RECOVERY = Constants.BEATEN_ENEMY_SIDE_RECOVERY or 7.25
	local BEATEN_ENEMY_CARRIER_LEASH_DISTANCE = Constants.BEATEN_ENEMY_CARRIER_LEASH_DISTANCE or 9.25

	local ALLY_PATROL_SWAY_DISTANCE = Constants.ALLY_PATROL_SWAY_DISTANCE
	local ALLY_PATROL_OSCILLATION_SPEED = Constants.ALLY_PATROL_OSCILLATION_SPEED
	local ENEMY_PATROL_SWAY_DISTANCE = Constants.ENEMY_PATROL_SWAY_DISTANCE
	local ENEMY_PATROL_OSCILLATION_SPEED = Constants.ENEMY_PATROL_OSCILLATION_SPEED

	local SHADOW_FOLLOW_DISTANCE = Constants.SHADOW_FOLLOW_DISTANCE
	local SHADOW_LATE_UPDATE_SPEED = Constants.SHADOW_LATE_UPDATE_SPEED
	local SHADOW_LATERAL_OFFSET = Constants.SHADOW_LATERAL_OFFSET

	local POST_PHASE_ADVANCE_SPEED = Constants.POST_PHASE_ADVANCE_SPEED

	local TURNOVER_CARRY_SPEED = 11.4
	local TURNOVER_CARRY_MOMENTUM_DISTANCE = 3.8
	local TURNOVER_CARRY_MOMENTUM_SCALE = 0.42
	local TURNOVER_CARRY_TURN_SMOOTH_SPEED = 3.8


	local GetRootPart = Utils.GetRootPart
	local ApplyPivot = Utils.ApplyPivot
	local GetGroundedPosition = Utils.GetGroundedPosition
	local GetFlatDistance = Utils.GetFlatDistance
	local StepFlatTowards = Utils.StepFlatTowards
	local BuildStableSeed = Utils.BuildStableSeed
	local GetFlatUnitFromLook = Utils.GetFlatUnitFromLook
	local GetBallFocusPosition = Utils.GetBallFocusPosition

	local ResolveStrafeAnimation = Utils.ResolveStrafeAnimation
	if type(ResolveStrafeAnimation) ~= "function" then
		ResolveStrafeAnimation = function(_currentPos, _nextPos, _lookTarget, fallbackAnimation)
			return fallbackAnimation or "Run"
		end
	end

	-- Defensive zone direction helpers.
	-- EnemyDirector calls these during patrol/shadow. Keep local fallback so it does not depend on
	-- MatchApproachDirector attach order.
	if type(MatchPresentationController._getZoneForward) ~= "function" then
		function MatchPresentationController:_getZoneForward(stepIndex, fallbackPosition)
			local numericStep = math.clamp(tonumber(stepIndex) or 1, 1, 5)
			local currentMarker = MatchZoneQuery.GetCarrierPoint(numericStep)
				or MatchZoneQuery.GetZoneArea(numericStep)

			local nextStep = math.clamp(numericStep + 1, 1, 5)
			local nextMarker = MatchZoneQuery.GetCarrierPoint(nextStep)
				or MatchZoneQuery.GetZoneArea(nextStep)
				or MatchZoneQuery.GetGoalTarget()

			if currentMarker and nextMarker then
				local forward = MatchMotionMath.GetFlatDirection(currentMarker.Position, nextMarker.Position)
				if forward.Magnitude > 0.001 then
					return forward.Unit
				end
			end

			local goalTarget = MatchZoneQuery.GetGoalTarget()
			if fallbackPosition and goalTarget then
				local forward = MatchMotionMath.GetFlatDirection(fallbackPosition, goalTarget.Position)
				if forward.Magnitude > 0.001 then
					return forward.Unit
				end
			end

			return Vector3.new(0, 0, -1)
		end
	end

	if type(MatchPresentationController._getZoneLateral) ~= "function" then
		function MatchPresentationController:_getZoneLateral(stepIndex, fallbackPosition)
			local forward = self:_getZoneForward(stepIndex, fallbackPosition)
			local lateral = forward:Cross(Vector3.new(0, 1, 0))

			if lateral.Magnitude <= 0.001 then
				return Vector3.new(1, 0, 0)
			end

			return lateral.Unit
		end
	end

function MatchPresentationController:_getEnemyRuntimeSlotFromModel(enemyModel)
	if not enemyModel then
		return nil
	end

	local attributeSlot = tonumber(enemyModel:GetAttribute("MatchEnemySlot"))
	if attributeSlot then
		return attributeSlot
	end

	local name = enemyModel.Name

	if name == "Enemy01" then
		return 1
	elseif name == "Enemy02" then
		return 2
	elseif name == "Enemy03" then
		return 3
	elseif name == "Enemy04" then
		return 4
	elseif name == "GoalKeeper" or name == "Keeper" then
		return GOALKEEPER_RUNTIME_SLOT
	end

	return nil
end

function MatchPresentationController:_getEnemyStepIndexFromModel(enemyModel)
	local runtimeSlot = self:_getEnemyRuntimeSlotFromModel(enemyModel)

	if runtimeSlot == GOALKEEPER_RUNTIME_SLOT then
		return 5
	end

	return runtimeSlot
end

function MatchPresentationController:_getActiveEnemyRuntimeSlotForPayload(payload)
	local enemyStep = tonumber(payload and payload.EnemyStep)
		or tonumber(payload and payload.StepIndex)
		or 1

	if enemyStep == 5 then
		return GOALKEEPER_RUNTIME_SLOT
	end

	return math.clamp(enemyStep, 1, 4)
end

function MatchPresentationController:_getEnemyModelByRuntimeSlot(runtimeSlot: number): Model?
	local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
	if not enemiesFolder then
		return nil
	end

	local numericSlot = tonumber(runtimeSlot) or 1

	if numericSlot == GOALKEEPER_RUNTIME_SLOT then
		return enemiesFolder:FindFirstChild("GoalKeeper") or enemiesFolder:FindFirstChild("Keeper")
	end

	local enemyName = string.format("Enemy%02d", numericSlot)
	local enemyModel = enemiesFolder:FindFirstChild(enemyName)

	if enemyModel and enemyModel:IsA("Model") then
		return enemyModel
	end

	return nil
end

function MatchPresentationController:_getActiveEnemyModelForPayload(payload): Model?
	local runtimeSlot = self:_getActiveEnemyRuntimeSlotForPayload(payload)
	local enemyModel = self:_getEnemyModelByRuntimeSlot(runtimeSlot)

	if enemyModel then
		return enemyModel
	end

	return MatchActorResolver.GetEnemyModelByStep(payload and payload.EnemyStep)
end

function MatchPresentationController:_forEachEnemyModel(callback)
	if type(callback) ~= "function" then
		return
	end

	local visited = {}

	local function visit(model)
		if model and model:IsA("Model") and model.Parent and not visited[model] then
			visited[model] = true
			callback(model)
		end
	end

	local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
	if enemiesFolder then
		for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
			visit(enemyModel)
		end
	end

	for runtimeSlot = 1, GOALKEEPER_RUNTIME_SLOT do
		visit(self:_getEnemyModelByRuntimeSlot(runtimeSlot))
	end
end

function MatchPresentationController:_animateIdleEnemies(sessionId)
	self.IdleEnemyMotionToken += 1
	local motionToken = self.IdleEnemyMotionToken

	task.spawn(function()
		while self:_isSessionActive(sessionId) and motionToken == self.IdleEnemyMotionToken do
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

			if self.IsPreQteFrozen or self.IsShootCinematicFrozen then
				continue
			end

			local enemiesFolder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
			if not enemiesFolder then
				continue
			end

			local currentStepIndex = tonumber(self.CurrentPresentationStepIndex) or 0
			local activeEnemyRuntimeSlot = tonumber(self.ActiveEnemyRuntimeSlot)

			for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
				if not enemyModel or not enemyModel.Parent then
					continue
				end

				local enemyRuntimeSlot = self:_getEnemyRuntimeSlotFromModel(enemyModel)
				local enemyStepIndex = self:_getEnemyStepIndexFromModel(enemyModel)
				local isKeeper = enemyRuntimeSlot == GOALKEEPER_RUNTIME_SLOT
					or enemyModel.Name == "GoalKeeper"
					or enemyModel.Name == "Keeper"

				if isKeeper or not enemyStepIndex then
					continue
				end

				if self.PassPressTokens and self.PassPressTokens[enemyModel] then
					continue
				end
				
				-- Enemy yang sudah dilewati tidak boleh ikut idle advance / chase bola lagi.
				-- Recovery task punya ownership sendiri supaya tidak jadi 3v1 chasing.
				if self.DefeatedEnemyRecoveryTokens and self.DefeatedEnemyRecoveryTokens[enemyModel] then
					continue
				end

				-- Active enemy dikontrol oleh approach pipeline.
				if enemyRuntimeSlot == activeEnemyRuntimeSlot and currentStepIndex == enemyStepIndex then
					continue
				end

				local enemyRoot = GetRootPart(enemyModel)
				if not enemyRoot then
					continue
				end

				local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
				local phaseIndex = self:_getEnemyPhaseForRuntimeSlot(enemyRuntimeSlot)

				if self:_hasPhasePassed(phaseIndex) then
					local nextPos, lookTarget, isMoving = self:_stepSupportAdvance(
						enemyModel,
						currentPos,
						phaseIndex,
						POST_PHASE_ADVANCE_SPEED,
						scaledDeltaTime
					)

					local ballLookTarget = GetBallFocusPosition(self, lookTarget or currentPos)
					ApplyPivot(
						enemyModel,
						MatchMotionMath.BuildFlatLookAtCFrame(nextPos, ballLookTarget)
					)

					self:_playMotionAnimation(
						enemyModel,
						"Run",
						1.0
					)

					continue
				end

				local shouldGuard = enemyStepIndex > currentStepIndex

				if currentStepIndex == 3 and enemyStepIndex == 3 and enemyRuntimeSlot ~= activeEnemyRuntimeSlot then
					shouldGuard = true
				end

				if not shouldGuard then
					local idleLookTarget = GetBallFocusPosition(self, currentPos + enemyRoot.CFrame.LookVector)
					ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentPos, idleLookTarget))
					self:_playMotionAnimation(enemyModel, "Idle", 1.0)
					continue
				end

				local targetPos, lookPos = self:_buildShadowMarkPosition(
					enemyStepIndex,
					enemyModel,
					tonumber(self.ActiveActorSlot),
					sessionId,
					enemyRuntimeSlot or enemyStepIndex,
					os.clock(),
					currentPos
				)

				if targetPos then
					local nextPos = select(1, StepFlatTowards(
						currentPos,
						targetPos,
						SHADOW_LATE_UPDATE_SPEED,
						scaledDeltaTime
					))

					nextPos = GetGroundedPosition(nextPos, enemyModel)

					local isMoving = GetFlatDistance(currentPos, targetPos) > 0.18
					local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, nextPos)

					local moveFallback = moveDirection.Magnitude > 0.001
						and (nextPos + moveDirection)
						or (lookPos or targetPos or currentPos)
					local finalLook = GetBallFocusPosition(self, moveFallback)

					ApplyPivot(
						enemyModel,
						MatchMotionMath.BuildFlatLookAtCFrame(nextPos, finalLook)
					)

					self:_playMotionAnimation(
						enemyModel,
						"Run",
						1.0
					)
				else
					self:_playMotionAnimation(enemyModel, "Idle", 1.0)
				end
			end
		end
	end)
end

function MatchPresentationController:_getShadowAnchorPosition(stepIndex, actorSlot, fallbackPosition, enemyRuntimeSlot)
	local guardSlot = self:_getEnemyGuardActorSlot(enemyRuntimeSlot)

	-- Explicit marking first.
	-- Enemy02 -> Slot2
	-- Enemy03/Left -> Slot4
	-- Enemy04/Right -> Slot3
	if guardSlot then
		local guardedPosition = self:_getActorWorldPositionBySlot(guardSlot, nil)
		if guardedPosition then
			return guardedPosition
		end
	end

	-- Enemy01 has no off-ball target. It should guard its own zone, not patrol.
	if tonumber(enemyRuntimeSlot) == 1 then
		local enemyApproachPoint = nil

		if MatchZoneQuery.GetEnemyApproachPointBySlot then
			enemyApproachPoint = MatchZoneQuery.GetEnemyApproachPointBySlot(1)
		end

		enemyApproachPoint = enemyApproachPoint
			or MatchZoneQuery.GetEnemyApproachPoint(1)
			or MatchZoneQuery.GetCarrierPoint(1)
			or MatchZoneQuery.GetZoneArea(1)

		if enemyApproachPoint then
			return GetGroundedPosition(enemyApproachPoint.Position, nil)
		end
	end

	local zoneArea = MatchZoneQuery.GetZoneArea(stepIndex)
	local zoneCenter = zoneArea and zoneArea.Position or fallbackPosition
	local bestPosition = nil
	local bestDistance = math.huge

	for slotNumber = 2, 4 do
		if slotNumber ~= tonumber(actorSlot) then
			local actorModel = self:_getControlledActorModel(slotNumber)
			local actorRoot = GetRootPart(actorModel)

			if actorRoot then
				local actorPos = GetGroundedPosition(actorRoot.Position, actorModel)
				local distance = zoneCenter and GetFlatDistance(actorPos, zoneCenter) or 0

				if distance < bestDistance then
					bestDistance = distance
					bestPosition = actorPos
				end
			end
		end
	end

	if bestPosition then
		return bestPosition
	end

	local fallbackPart = MatchZoneQuery.GetCarrierPoint(stepIndex)
		or MatchZoneQuery.GetEnemyApproachPoint(stepIndex)
		or zoneArea

	if fallbackPart then
		return GetGroundedPosition(fallbackPart.Position, nil)
	end

	return fallbackPosition
end

function MatchPresentationController:_buildShadowMarkPosition(stepIndex, enemyModel, actorSlot, sessionId, enemyRuntimeSlot, currentTime, fallbackPosition)
	local anchorPos = self:_getShadowAnchorPosition(stepIndex, actorSlot, fallbackPosition, enemyRuntimeSlot)
	if not anchorPos then
		return fallbackPosition, fallbackPosition
	end

	local forward = self:_getZoneForward(stepIndex, anchorPos)
	local lateral = self:_getZoneLateral(stepIndex, anchorPos)
	local runtimeSlot = tonumber(enemyRuntimeSlot) or 0

	local sideSign = 0
	if runtimeSlot == 3 then
		sideSign = -1
	elseif runtimeSlot == 4 then
		sideSign = 1
	end

	-- Enemy menjaga jarak dari companion, bukan nempel.
	local targetPos = anchorPos
		+ (forward * SHADOW_FOLLOW_DISTANCE)
		+ (lateral * sideSign * SHADOW_LATERAL_OFFSET)

	local zoneArea = MatchZoneQuery.GetZoneArea(stepIndex)
	if zoneArea then
		local localPos = zoneArea.CFrame:PointToObjectSpace(targetPos)
		local clampedLocal = Vector3.new(
			math.clamp(localPos.X, -(zoneArea.Size.X * 0.42), zoneArea.Size.X * 0.42),
			localPos.Y,
			math.clamp(localPos.Z, -(zoneArea.Size.Z * 0.42), zoneArea.Size.Z * 0.42)
		)

		targetPos = zoneArea.CFrame:PointToWorldSpace(clampedLocal)
	end

	targetPos = GetGroundedPosition(targetPos, enemyModel)

	return targetPos, anchorPos
end

function MatchPresentationController:_getEnemyPhaseForRuntimeSlot(enemyRuntimeSlot)
	local numericSlot = tonumber(enemyRuntimeSlot) or 1

	if numericSlot == 2 then
		return 2
	end

	-- Enemy03/Enemy04 adalah defender late-step.
	-- Mereka boleh adjust maju setelah QTE2, tapi tetap dibatasi agar tidak nyalip QTE berikutnya.
	if numericSlot == 3 or numericSlot == 4 then
		return 2
	end

	-- Enemy01 tidak ikut maju jauh setelah phase awal.
	return nil
end

function MatchPresentationController:_getEnemyGuardActorSlot(enemyRuntimeSlot)
	local runtimeSlot = tonumber(enemyRuntimeSlot)
	if runtimeSlot and runtimeSlot >= 2 and runtimeSlot <= 4 then
		return runtimeSlot
	end

	return nil
end

function MatchPresentationController:_buildVerticalLanePatrolPosition(stepIndex, model, sessionId, slotKey, currentTime, fallbackPosition)
	local numericSlot = tonumber(slotKey) or 1
	local basePosition = fallbackPosition

	if numericSlot >= 2 and numericSlot <= 4 and MatchSceneQuery.GetCompanionPivot then
		local companionPivot = MatchSceneQuery.GetCompanionPivot(numericSlot)
		if companionPivot then
			basePosition = companionPivot.Position
		end
	end

	if numericSlot <= 1 then
		local enemyApproachPoint = nil

		if MatchZoneQuery.GetEnemyApproachPointBySlot then
			enemyApproachPoint = MatchZoneQuery.GetEnemyApproachPointBySlot(numericSlot)
		end

		enemyApproachPoint = enemyApproachPoint
			or MatchZoneQuery.GetEnemyApproachPoint(stepIndex)
			or MatchZoneQuery.GetCarrierPoint(stepIndex)
			or MatchZoneQuery.GetZoneArea(stepIndex)

		if enemyApproachPoint then
			basePosition = enemyApproachPoint.Position
		end
	end

	basePosition = GetGroundedPosition(basePosition, model)

	local lateral = self:_getZoneLateral(stepIndex, basePosition)
	local phaseSeed = (numericSlot * 1.31) + ((tonumber(stepIndex) or 0) * 0.73)

	local swayDistance = numericSlot >= 2 and ALLY_PATROL_SWAY_DISTANCE or ENEMY_PATROL_SWAY_DISTANCE
	local oscillationSpeed = numericSlot >= 2 and ALLY_PATROL_OSCILLATION_SPEED or ENEMY_PATROL_OSCILLATION_SPEED
	local sway = math.sin((currentTime * oscillationSpeed) + phaseSeed) * swayDistance

	local targetPos = basePosition + (lateral * sway)

	local zoneArea = MatchZoneQuery.GetZoneArea(stepIndex)
	if zoneArea then
		local localPos = zoneArea.CFrame:PointToObjectSpace(targetPos)
		local clampedLocal = Vector3.new(
			math.clamp(localPos.X, -(zoneArea.Size.X * 0.42), zoneArea.Size.X * 0.42),
			localPos.Y,
			math.clamp(localPos.Z, -(zoneArea.Size.Z * 0.42), zoneArea.Size.Z * 0.42)
		)

		targetPos = zoneArea.CFrame:PointToWorldSpace(clampedLocal)
	end

	return GetGroundedPosition(targetPos, model)
end

function MatchPresentationController:_getActiveCarrierWorldPosition(payload, fallbackPosition)
	local activeCarrierSlot = tonumber(self.ActiveActorSlot)
		or tonumber(payload and payload.TargetSlot)
		or tonumber(payload and payload.ActorSlot)

	local carrierModel = activeCarrierSlot and self:_getControlledActorModel(activeCarrierSlot)
	local carrierRoot = GetRootPart(carrierModel)

	if carrierRoot then
		return GetGroundedPosition(carrierRoot.Position, carrierModel)
	end

	return fallbackPosition
end

function MatchPresentationController:_buildDefeatedBackpedalTarget(enemyModel, currentPos, attackDirection)
	local runtimeSlot = tonumber(self:_getEnemyRuntimeSlotFromModel(enemyModel)) or 1
	local sideSign = 0
	if runtimeSlot == 3 then
		sideSign = -1
	elseif runtimeSlot == 4 then
		sideSign = 1
	end

	local lateral = Vector3.new(-attackDirection.Z, 0, attackDirection.X)
	if lateral.Magnitude <= 0.001 then
		lateral = Vector3.new(1, 0, 0)
	else
		lateral = lateral.Unit
	end

	return GetGroundedPosition(
		currentPos
			+ (attackDirection * DEFEATED_ENEMY_RECOVERY_DISTANCE)
			+ (lateral * sideSign * BEATEN_ENEMY_SIDE_RECOVERY),
		enemyModel
	)
end


function MatchPresentationController:_buildBeatenEnemyLeashTarget(payload, enemyModel, currentPos, attackDirection, leashSeed)
	if not payload or not enemyModel or not currentPos then
		return nil, nil
	end

	local activeCarrierPos = self:_getActiveCarrierWorldPosition(payload, nil)
	if not activeCarrierPos then
		return nil, nil
	end

	local flatAttackDirection = attackDirection
	if typeof(flatAttackDirection) ~= "Vector3" or flatAttackDirection.Magnitude <= 0.001 then
		local goalTarget = MatchZoneQuery.GetGoalTarget()
		if goalTarget then
			flatAttackDirection = MatchMotionMath.GetFlatDirection(activeCarrierPos, goalTarget.Position)
		end
	end

	if typeof(flatAttackDirection) ~= "Vector3" or flatAttackDirection.Magnitude <= 0.001 then
		flatAttackDirection = Vector3.new(0, 0, -1)
	else
		flatAttackDirection = Vector3.new(flatAttackDirection.X, 0, flatAttackDirection.Z).Unit
	end

	local lateral = Vector3.new(-flatAttackDirection.Z, 0, flatAttackDirection.X)
	if lateral.Magnitude <= 0.001 then
		lateral = Vector3.new(1, 0, 0)
	else
		lateral = lateral.Unit
	end

	local runtimeSlot = tonumber(self:_getEnemyRuntimeSlotFromModel(enemyModel)) or tonumber(payload.EnemyStep) or 1
	local sideSign = 0
	if runtimeSlot == 3 then
		sideSign = -1
	elseif runtimeSlot == 4 then
		sideSign = 1
	else
		local seedNumber = tonumber(leashSeed) or 0
		sideSign = (seedNumber % 2 == 0) and 1 or -1
	end

	local jitter = 0
	if type(BuildStableSeed) == "function" then
		jitter = ((BuildStableSeed(payload.SessionId, payload.StepIndex, runtimeSlot, 919) % 100) / 100 - 0.5) * 1.6
	end

	local behindDistance = math.max(BEATEN_ENEMY_MIN_GAP, BEATEN_ENEMY_CARRIER_LEASH_DISTANCE + 1.5)
	local sideDistance = math.max(BEATEN_ENEMY_SIDE_RECOVERY + jitter, 2.5)

	-- Keep defeated defenders behind the live carrier. They fake-chase and recover shape,
	-- but never close the carrier again immediately after a successful dribble.
	local leashTarget = activeCarrierPos
		- (flatAttackDirection * behindDistance)
		+ (lateral * sideSign * sideDistance)

	local enemyToCarrier = MatchMotionMath.GetFlatDirection(currentPos, activeCarrierPos)
	if enemyToCarrier.Magnitude > 0.001 then
		local distanceToCarrier = GetFlatDistance(currentPos, activeCarrierPos)
		if distanceToCarrier < BEATEN_ENEMY_MIN_GAP then
			leashTarget = currentPos - (enemyToCarrier.Unit * (BEATEN_ENEMY_MIN_GAP - distanceToCarrier + 1.0))
		end
	end

	return GetGroundedPosition(leashTarget, enemyModel), activeCarrierPos
end

function MatchPresentationController:_sendDefeatedEnemyBackwards(payload, enemyModel)
	if not payload or not enemyModel then
		return
	end

	local goalTarget = MatchZoneQuery.GetGoalTarget()
	if not goalTarget then
		return
	end

	local enemyRuntimeSlot = self:_getEnemyRuntimeSlotFromModel(enemyModel)

	self.DefeatedEnemyRecoveryTokens[enemyModel] = (self.DefeatedEnemyRecoveryTokens[enemyModel] or 0) + 1
	local recoveryToken = self.DefeatedEnemyRecoveryTokens[enemyModel]

	task.spawn(function()
		local enemyRoot = GetRootPart(enemyModel)
		if not enemyRoot then
			return
		end

		local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		local attackDirection = MatchMotionMath.GetFlatDirection(currentPos, goalTarget.Position)

		if attackDirection.Magnitude <= 0.001 then
			attackDirection = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
		end

		local targetPos = nil
		local coverSlot = self:_getEnemyGuardActorSlot(enemyRuntimeSlot)
		local activeCarrierSlot = tonumber(self.ActiveActorSlot)
			or tonumber(payload.TargetSlot)
			or tonumber(payload.ActorSlot)

		if coverSlot == activeCarrierSlot then
			coverSlot = nil
		end

		if not coverSlot then
			local bestSlot = nil
			local bestDistance = math.huge

			for slotNumber = 2, 4 do
				if slotNumber ~= activeCarrierSlot then
					local actorPos = self:_getActorWorldPositionBySlot(slotNumber, nil)
					if actorPos then
						local distance = GetFlatDistance(currentPos, actorPos)
						if distance < bestDistance then
							bestDistance = distance
							bestSlot = slotNumber
						end
					end
				end
			end

			coverSlot = bestSlot
		end

		local coverPosition = coverSlot and self:_getActorWorldPositionBySlot(coverSlot, nil)
		if coverPosition then
			targetPos = coverPosition + (attackDirection * DEFEATED_ENEMY_COVER_FRONT_DISTANCE)
		else
			targetPos = currentPos + (attackDirection * DEFEATED_ENEMY_RECOVERY_DISTANCE)
		end

		local progress = Vector3.new(
			targetPos.X - currentPos.X,
			0,
			targetPos.Z - currentPos.Z
		):Dot(attackDirection)

		if progress < DEFEATED_ENEMY_MIN_RECOVERY_FORWARD then
			targetPos = currentPos + (attackDirection * DEFEATED_ENEMY_MIN_RECOVERY_FORWARD)
		end

		local leashSeed = 0
		if type(BuildStableSeed) == "function" then
			leashSeed = BuildStableSeed(
				payload.SessionId,
				payload.StepIndex,
				enemyRuntimeSlot,
				781
			)
		end

		local leashTarget = self:_buildBeatenEnemyLeashTarget(payload, enemyModel, currentPos, attackDirection, leashSeed)
		if leashTarget then
			targetPos = leashTarget
		end

		targetPos = GetGroundedPosition(targetPos, enemyModel)
		local recoverySpeed = math.min(DEFEATED_ENEMY_RECOVERY_SPEED * BEATEN_ENEMY_SPEED_FACTOR, BEATEN_ENEMY_MAX_SPEED)

		self:_playMotionAnimation(enemyModel, "Run", 1.0)

		while self:_isSessionActive(payload.SessionId)
			and enemyModel.Parent
			and not self.IsPreQteFrozen
			and not self.IsShootCinematicFrozen
			and self.DefeatedEnemyRecoveryTokens[enemyModel] == recoveryToken
		do
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)

			currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)

			local liveLeashTarget, carrierPos = self:_buildBeatenEnemyLeashTarget(
				payload,
				enemyModel,
				currentPos,
				attackDirection,
				leashSeed
			)

			if liveLeashTarget then
				targetPos = liveLeashTarget
			end

			local liveSpeed = recoverySpeed
			if carrierPos and GetFlatDistance(currentPos, carrierPos) <= BEATEN_ENEMY_CARRIER_LEASH_DISTANCE then
				liveSpeed = math.min(recoverySpeed * 0.72, BEATEN_ENEMY_MAX_SPEED * 0.72)
			end

			local nextPos, reached = StepFlatTowards(
				currentPos,
				targetPos,
				liveSpeed,
				scaledDeltaTime
			)

			nextPos = GetGroundedPosition(nextPos, enemyModel)

			local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, nextPos)
			local moveFallback = moveDirection.Magnitude > 0.001
				and (nextPos + moveDirection)
				or targetPos

			ApplyPivot(
				enemyModel,
				MatchMotionMath.BuildFlatLookAtCFrame(nextPos, GetBallFocusPosition(self, moveFallback))
			)

			self:_playMotionAnimation(enemyModel, ResolveStrafeAnimation(currentPos, nextPos, moveFallback, "Run"), 1.0)

			currentPos = nextPos

			if reached or GetFlatDistance(currentPos, targetPos) <= THRESHOLDS.EnemyArrive then
				break
			end
		end

		if self.IsPreQteFrozen or self.IsShootCinematicFrozen then
			return
		end

		if not self:_isSessionActive(payload.SessionId) or not enemyModel.Parent then
			return
		end

		local finalPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
		local finalLookTarget = self:_getActiveCarrierWorldPosition(payload, coverPosition or finalPos) or goalTarget.Position

		ApplyPivot(
			enemyModel,
			MatchMotionMath.BuildFlatLookAtCFrame(finalPos, finalLookTarget)
		)

		self:_playMotionAnimation(enemyModel, "Idle", 1.0)
	end)
end

function MatchPresentationController:_getTurnoverCarryDirection(actorReferenceCFrame, enemyFacingLook)
	local goalTarget = MatchZoneQuery.GetGoalTarget()
	local preferredDirection = nil

	if goalTarget then
		local attackDirection = MatchMotionMath.GetFlatDirection(
			actorReferenceCFrame.Position,
			goalTarget.Position
		)

		if attackDirection.Magnitude > 0.001 then
			preferredDirection = -attackDirection
		end
	end

	if not preferredDirection then
		preferredDirection = -GetFlatUnitFromLook(actorReferenceCFrame.LookVector)
	end

	if not preferredDirection or preferredDirection.Magnitude <= 0.001 then
		preferredDirection = Vector3.new(0, 0, -1)
	end

	local currentFacing = enemyFacingLook and GetFlatUnitFromLook(enemyFacingLook) or nil
	if currentFacing and currentFacing.Magnitude > 0.001 then
		return currentFacing, preferredDirection
	end

	return preferredDirection, preferredDirection
end

function MatchPresentationController:_runEnemyCarryAwayAfterTurnover(payload, enemyModel, actorReferenceCFrame, carryDistance)
	if not enemyModel or not actorReferenceCFrame then
		return
	end

	local enemyRoot = GetRootPart(enemyModel)
	if not enemyRoot then
		return
	end

	local currentPos = GetGroundedPosition(enemyRoot.Position, enemyModel)
	local carryDirection, preferredDirection = self:_getTurnoverCarryDirection(
		actorReferenceCFrame,
		enemyRoot.CFrame.LookVector
	)
	local totalDistance = math.max(carryDistance or 10, 2)
	local momentumDistance = math.min(
		math.max(totalDistance * TURNOVER_CARRY_MOMENTUM_SCALE, 0),
		TURNOVER_CARRY_MOMENTUM_DISTANCE
	)
	local remainingDistance = math.max(totalDistance - momentumDistance, 0)
	local smoothedLookDirection = carryDirection
	if not smoothedLookDirection or smoothedLookDirection.Magnitude <= 0.001 then
		smoothedLookDirection = GetFlatUnitFromLook(enemyRoot.CFrame.LookVector)
	end
	if not smoothedLookDirection or smoothedLookDirection.Magnitude <= 0.001 then
		smoothedLookDirection = preferredDirection
	end

	local function runCarrySegment(targetPos, desiredFinalDirection)
		while self:_isSessionActive(payload.SessionId) do
			local deltaTime = RunService.RenderStepped:Wait()
			local scaledDeltaTime = self:_getScaledDeltaTime(deltaTime)
			local reached = false

			currentPos, reached = StepFlatTowards(
				currentPos,
				targetPos,
				TURNOVER_CARRY_SPEED,
				scaledDeltaTime
			)

			currentPos = GetGroundedPosition(currentPos, enemyModel)

			local moveDirection = MatchMotionMath.GetFlatDirection(currentPos, targetPos)
			local desiredLookDirection = desiredFinalDirection
			if not desiredLookDirection or desiredLookDirection.Magnitude <= 0.001 then
				desiredLookDirection = moveDirection
			end
			if desiredLookDirection and desiredLookDirection.Magnitude > 0.001 then
				local turnAlpha = 1 - math.exp(-TURNOVER_CARRY_TURN_SMOOTH_SPEED * math.max(scaledDeltaTime, 0))
				local blendedLook = smoothedLookDirection:Lerp(desiredLookDirection.Unit, turnAlpha)
				if blendedLook.Magnitude > 0.001 then
					smoothedLookDirection = blendedLook.Unit
				end
			end

			local lookTarget = currentPos + smoothedLookDirection
			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(currentPos, lookTarget))

			if reached then
				break
			end
		end
	end

	local momentumTargetPos = GetGroundedPosition(
		currentPos + (carryDirection * math.max(momentumDistance, 0.5)),
		enemyModel
	)

	ApplyPivot(
		enemyModel,
		MatchMotionMath.BuildFlatLookAtCFrame(currentPos, currentPos + smoothedLookDirection)
	)

	self:_playRigAnimation(enemyModel, "Run", 1.0)
	runCarrySegment(momentumTargetPos, carryDirection)

	if self:_isSessionActive(payload.SessionId) and remainingDistance > 0.35 then
		local followDirection = preferredDirection
		if carryDirection and preferredDirection and carryDirection:Dot(preferredDirection) > 0.25 then
			local blendedDirection = carryDirection:Lerp(preferredDirection, 0.55)
			if blendedDirection.Magnitude > 0.001 then
				followDirection = blendedDirection.Unit
			end
		end

		local finalTargetPos = GetGroundedPosition(
			currentPos + (followDirection * remainingDistance),
			enemyModel
		)

		runCarrySegment(finalTargetPos, preferredDirection)
	end

	self:_playRigAnimation(enemyModel, "Idle", 1.0)
end

function MatchPresentationController:_startEnemy04ShadowRunner(payload, runnerSlot)
	if not payload or tonumber(payload.StepIndex) ~= 3 then
		return
	end

	local numericRunnerSlot = tonumber(runnerSlot)
	if not numericRunnerSlot then
		return
	end

	local enemyModel = self:_getEnemyModelByRuntimeSlot(4)
	local runnerModel = self:_getControlledActorModel(numericRunnerSlot)
	local goalTarget = MatchZoneQuery.GetGoalTarget()

	if not enemyModel or not runnerModel or not goalTarget then
		return
	end

	local enemyRoot = GetRootPart(enemyModel)
	if not enemyRoot then
		return
	end

	self.QteLiveShadowEnemySlot = nil
	self.Qte3ShadowEnemyToken = (self.Qte3ShadowEnemyToken or 0) + 1
	local shadowToken = self.Qte3ShadowEnemyToken

	task.spawn(function()
		local maxDuration = 1.55
		local startedAt = os.clock()
		local shadowSpeed = math.max(SHADOW_LATE_UPDATE_SPEED or 9.5, 13.5)

		while self:_isSessionActive(payload.SessionId)
			and enemyModel.Parent
			and runnerModel.Parent
			and self.Qte3ShadowEnemyToken == shadowToken
			and not self.IsPreQteFrozen
			and os.clock() - startedAt <= maxDuration
		do
			local dt = RunService.RenderStepped:Wait()
			local scaledDt = self:_getScaledDeltaTime(dt)

			local currentEnemyRoot = GetRootPart(enemyModel)
			local runnerRoot = GetRootPart(runnerModel)
			if not currentEnemyRoot or not runnerRoot then
				break
			end

			local enemyPos = GetGroundedPosition(currentEnemyRoot.Position, enemyModel)
			local runnerPos = GetGroundedPosition(runnerRoot.Position, runnerModel)
			local attackDirection = MatchMotionMath.GetFlatDirection(runnerPos, goalTarget.Position)
			if attackDirection.Magnitude <= 0.001 then
				attackDirection = GetFlatUnitFromLook(currentEnemyRoot.CFrame.LookVector)
			end

			local lateral = attackDirection:Cross(Vector3.new(0, 1, 0))
			if lateral.Magnitude <= 0.001 then
				lateral = Vector3.new(1, 0, 0)
			else
				lateral = lateral.Unit
			end

			local sideSign = numericRunnerSlot == 4 and 1 or -1
			local shadowTarget = runnerPos
				- (attackDirection * math.max(SHADOW_FOLLOW_DISTANCE or 8.0, 7.0))
				+ (lateral * sideSign * math.max(SHADOW_LATERAL_OFFSET or 1.5, 1.5))

			shadowTarget = GetGroundedPosition(shadowTarget, enemyModel)
			local nextPos = select(1, StepFlatTowards(enemyPos, shadowTarget, shadowSpeed, scaledDt))
			nextPos = GetGroundedPosition(nextPos, enemyModel)

			ApplyPivot(enemyModel, MatchMotionMath.BuildFlatLookAtCFrame(nextPos, runnerPos))
			self:_playMotionAnimation(enemyModel, "Run", 1.0)
		end
	end)
end

end
