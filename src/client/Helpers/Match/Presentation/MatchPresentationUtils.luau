local MatchCharacterVisualRestore = require(script.Parent.MatchCharacterVisualRestore)

return function(Context)
	local Workspace = Context.Services.Workspace
	local MatchZoneQuery = Context.MatchZoneQuery
	local Constants = Context.Constants
	local MatchGrounding = Context.MatchGrounding

	local Utils = {}
	local reusableGroundingExtraIgnoreInstances = {}
	local reusableGroundingOptions = {
		ExtraIgnoreInstances = reusableGroundingExtraIgnoreInstances,
		IgnoreMatchRuntimeRoot = true,
		IgnoreSpawnedEnemies = true,
		FallbackY = 0,
	}

	local EMBEDDED_BALL_NAMES = {
		ball = true,
		football = true,
		soccerball = true,
		matchball = true,
		dribbleball = true,
	}

	function Utils.GetRootPart(instance)
		if not instance then
			return nil
		end

		if instance:IsA("Model") then
			local hrp = instance:FindFirstChild("HumanoidRootPart", true)
			if hrp then
				return hrp
			end

			return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
		end

		if instance:IsA("BasePart") then
			return instance
		end

		return nil
	end

	function Utils.ApplyPivot(instance, cf)
		if not instance or not cf then
			return
		end

		if instance:IsA("Model") then
			instance:PivotTo(cf)
		elseif instance:IsA("BasePart") then
			instance.CFrame = cf
		end
	end

	function Utils.ForceModelVisible(model)
		if not model then
			return
		end

		-- Keep this restore character-safe. Do not blindly unhide helper parts,
		-- embedded ball meshes, or trophy props when match presentation cleans up.
		MatchCharacterVisualRestore.RestoreCharacterVisuals(model)
		MatchCharacterVisualRestore.HideTrophyVisuals(model)
	end

	function Utils.IsEmbeddedBallVisual(instance)
		local current = instance

		while current do
			local loweredName = string.lower(current.Name)

			if EMBEDDED_BALL_NAMES[loweredName] then
				return true
			end

			current = current.Parent
		end

		return false
	end

	function Utils.GetSafeGroundOffset(character: Model?): number
		return MatchGrounding.GetCharacterRootGroundClearance(character)
	end

	function Utils.GetGroundedY(worldPos: Vector3, model: Model?): number
		reusableGroundingExtraIgnoreInstances[1] = Workspace:FindFirstChild(Constants.PRESENTATION_FOLDER_NAME)
		reusableGroundingOptions.FallbackY = worldPos.Y
		return MatchGrounding.GetGroundedY(worldPos, model, reusableGroundingOptions)
	end

	function Utils.GetGroundedPosition(worldPos: Vector3, model: Model?): Vector3
		return Vector3.new(worldPos.X, Utils.GetGroundedY(worldPos, model), worldPos.Z)
	end

	function Utils.GetFlatDistance(a: Vector3, b: Vector3): number
		local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		return delta.Magnitude
	end

	function Utils.StepFlatTowards(currentPos: Vector3, targetPos: Vector3, studsPerSecond: number, deltaTime: number)
		local delta = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)
		local distance = delta.Magnitude

		if distance <= 0.001 then
			return targetPos, true
		end

		local step = math.min(math.max(studsPerSecond, 1) * math.max(deltaTime, 0), distance)
		local nextFlat = currentPos + (delta.Unit * step)
		local nextPos = Vector3.new(nextFlat.X, targetPos.Y, nextFlat.Z)

		local reached = distance <= math.max(Constants.THRESHOLDS.ActorArrive, step)
		if reached then
			nextPos = targetPos
		end

		return nextPos, reached
	end

	function Utils.MoveTowardsFlat(startPos: Vector3, targetPos: Vector3, maxDistance: number): Vector3
		local delta = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)
		if delta.Magnitude <= 0.001 then
			return startPos
		end

		local flatTravel = math.min(delta.Magnitude, maxDistance)
		local flatPos = startPos + (delta.Unit * flatTravel)
		return Vector3.new(flatPos.X, startPos.Y, flatPos.Z)
	end

	function Utils.ComputeBallTravelDuration(startPos: Vector3, endPos: Vector3): number
		local distance = Utils.GetFlatDistance(startPos, endPos)
		local rawDuration = distance / math.max(Constants.BALL_TRAVEL.PassStudsPerSecond, 1)
		return math.clamp(rawDuration, Constants.BALL_TRAVEL.PassMinDuration, Constants.BALL_TRAVEL.PassMaxDuration)
	end

	function Utils.BuildStableShootTarget(goalTargetPart, success: boolean, shootTier: string?): Vector3
		local base = goalTargetPart and goalTargetPart.Position or Vector3.zero
		local spreadX, spreadY

		local tier = shootTier or "Yellow"
		local side = (math.random() > 0.5) and 1 or -1
		local vertical = (math.random() > 0.5) and 1 or -1

		if tier == "Green" then
			-- Extreme corner: tight to the post, high/low
			spreadX = (math.random(115, 128) / 10) * side
			spreadY = vertical == 1 and (math.random(30, 45) / 10) or -(math.random(20, 35) / 10)
		elseif tier == "Yellow" then
			-- Mid corner: noticeable curve but not at the post
			spreadX = (math.random(75, 100) / 10) * side
			spreadY = vertical == 1 and (math.random(15, 28) / 10) or -(math.random(12, 22) / 10)
		else -- "Red"
			-- Mostly straight, center-ish, low curve
			spreadX = (math.random(10, 45) / 10) * side
			spreadY = (math.random(-8, 12) / 10)
		end

		if not success then
			-- Keep save targets slightly more reachable vertically
			if spreadY > 3.6 then
				spreadY = math.random(28, 36) / 10
			elseif spreadY < -2.0 then
				spreadY = -(math.random(10, 20) / 10)
			end
		end
		local targetPos = base + Vector3.new(spreadX, spreadY, 0)
		local groundY = Utils.GetGroundedY(targetPos, nil)
		if targetPos.Y < groundY + 0.6 then
			targetPos = Vector3.new(targetPos.X, groundY + 0.6, targetPos.Z)
		end

		return targetPos
	end

	function Utils.GetActorAdaptiveSpeed(baseSpeed: number, currentPos: Vector3, targetPos: Vector3, allowSprint: boolean): number
		if not allowSprint then
			return baseSpeed
		end

		local remainingDistance = Utils.GetFlatDistance(currentPos, targetPos)
		if remainingDistance >= Constants.MOVEMENT_TUNING.ActorSprintFarThreshold then
			return baseSpeed * Constants.MOVEMENT_TUNING.ActorSprintFarMultiplier
		end

		return baseSpeed
	end

	function Utils.GetEnemyAdaptiveSpeed(baseSpeed: number, currentPos: Vector3, targetPos: Vector3?, allowAdaptiveSprint: boolean): number
		if not allowAdaptiveSprint or not targetPos then
			return baseSpeed
		end

		local remainingDistance = Utils.GetFlatDistance(currentPos, targetPos)
		local tuning = Constants.MOVEMENT_TUNING
		local speed = baseSpeed

		if remainingDistance >= tuning.EnemySprintFarThreshold then
			speed = baseSpeed * tuning.EnemySprintFarMultiplier
		elseif remainingDistance >= tuning.EnemySprintMidThreshold then
			speed = baseSpeed * tuning.EnemySprintMidMultiplier
		elseif remainingDistance <= (tuning.EnemyPressureSlowdownDistance or 4.8) then
			speed = baseSpeed * (tuning.EnemyPressureCloseMultiplier or 0.92)
		end

		return math.min(speed, tuning.EnemyPressureMaxSpeed or speed)
	end

	function Utils.BuildStableSeed(sessionId, stepIndex, slotNumber, salt)
		local seed = (tonumber(stepIndex) or 0) * 92821
		seed += (tonumber(slotNumber) or 0) * 68917
		seed += (tonumber(salt) or 0)

		local text = tostring(sessionId or "")
		for i = 1, #text do
			seed = (seed * 33 + string.byte(text, i)) % 2147483647
		end

		if seed <= 0 then
			seed = 1
		end

		return seed
	end

	function Utils.BuildStableOffset(sessionId, stepIndex, slotNumber, maxX, maxZ, salt)
		local rng = Random.new(Utils.BuildStableSeed(sessionId, stepIndex, slotNumber, salt))
		return Vector3.new(
			rng:NextNumber(-maxX, maxX),
			0,
			rng:NextNumber(-maxZ, maxZ)
		)
	end

	function Utils.GetFlatUnitFromLook(lookVector: Vector3): Vector3
		local flat = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flat.Magnitude <= 0.001 then
			return Vector3.new(0, 0, -1)
		end
		return flat.Unit
	end


	function Utils.GetLiveBallPosition(controller): Vector3?
		if not controller then
			return nil
		end

		local matchBallController = controller.MatchBallController
		if matchBallController and matchBallController.GetBallPosition then
			local ok, ballPosition = pcall(function()
				return matchBallController:GetBallPosition()
			end)

			if ok and typeof(ballPosition) == "Vector3" then
				return ballPosition
			end
		end

		return nil
	end

	function Utils.GetBallFocusPosition(controller, fallbackPosition: Vector3?): Vector3?
		local ballPosition = Utils.GetLiveBallPosition(controller)
		if ballPosition then
			return ballPosition
		end

		if controller then
			local activeSlot = tonumber(controller.ActiveActorSlot)
			if activeSlot and controller._getControlledActorModel then
				local activeModel = controller:_getControlledActorModel(activeSlot)
				local activeRoot = Utils.GetRootPart(activeModel)
				if activeRoot then
					return activeRoot.Position
				end
			end
		end

		return fallbackPosition
	end

	function Utils.GetGoalFocusPosition(worldPosition: Vector3, fallbackPosition: Vector3?): Vector3?
		if MatchZoneQuery and MatchZoneQuery.GetGoalTarget then
			local goalTarget = MatchZoneQuery.GetGoalTarget()
			if goalTarget then
				return Vector3.new(goalTarget.Position.X, worldPosition.Y, goalTarget.Position.Z)
			end
		end

		return fallbackPosition
	end

	function Utils.ResolveSupportLookPosition(controller, worldPosition: Vector3, forwardLookAtPosition: Vector3?, options): Vector3?
		local forwardLook = Utils.GetGoalFocusPosition(
			worldPosition,
			forwardLookAtPosition or (worldPosition + Vector3.new(0, 0, -1))
		)

		if options and options.ForceForward then
			return forwardLook
		end

		local ballPosition = Utils.GetLiveBallPosition(controller)
		if not ballPosition or not forwardLook then
			return forwardLook
		end

		local attackDelta = Vector3.new(forwardLook.X - worldPosition.X, 0, forwardLook.Z - worldPosition.Z)
		if attackDelta.Magnitude <= 0.001 then
			return ballPosition
		end

		local toBall = Vector3.new(ballPosition.X - worldPosition.X, 0, ballPosition.Z - worldPosition.Z)
		local ballProgress = toBall:Dot(attackDelta.Unit)
		local behindBuffer = Constants.SUPPORT_FACE_BALL_BEHIND_BUFFER or 0.75

		-- If the ball is still behind this support actor, he opens his body to the ball.
		-- Once the ball has passed him / he is sprinting into a through pass, face goal-side.
		if ballProgress < -behindBuffer then
			return ballPosition
		end

		return forwardLook
	end

	function Utils.BuildBallFacingCFrame(controller, worldPosition: Vector3, fallbackLookAtPosition: Vector3?): CFrame
		local lookAtPosition = Utils.GetBallFocusPosition(controller, fallbackLookAtPosition or (worldPosition + Vector3.new(0, 0, -1)))
		return CFrame.lookAt(worldPosition, Vector3.new(lookAtPosition.X, worldPosition.Y, lookAtPosition.Z))
	end

	function Utils.ClampTargetAhead(currentPos: Vector3, candidatePos: Vector3, forwardVector: Vector3, minForwardDistance: number): Vector3
		local flatForward = Utils.GetFlatUnitFromLook(forwardVector)
		local delta = Vector3.new(candidatePos.X - currentPos.X, 0, candidatePos.Z - currentPos.Z)
		local forwardAmount = delta:Dot(flatForward)

		if forwardAmount >= minForwardDistance then
			return candidatePos
		end

		local lateral = delta - (flatForward * forwardAmount)
		local corrected = currentPos + (flatForward * minForwardDistance) + lateral
		return Vector3.new(corrected.X, candidatePos.Y, corrected.Z)
	end


	function Utils.GetAttackDirectionFromPosition(worldPosition: Vector3, fallbackLookVector: Vector3?): Vector3
		local goalTarget = MatchZoneQuery and MatchZoneQuery.GetGoalTarget and MatchZoneQuery.GetGoalTarget()
		if goalTarget then
			local goalDirection = Vector3.new(
				goalTarget.Position.X - worldPosition.X,
				0,
				goalTarget.Position.Z - worldPosition.Z
			)

			if goalDirection.Magnitude > 0.001 then
				return goalDirection.Unit
			end
		end

		return Utils.GetFlatUnitFromLook(fallbackLookVector or Vector3.new(0, 0, -1))
	end

	function Utils.GetLateralFromForward(forwardDirection: Vector3): Vector3
		local lateral = forwardDirection:Cross(Vector3.new(0, 1, 0))
		if lateral.Magnitude <= 0.001 then
			return Vector3.new(1, 0, 0)
		end

		return lateral.Unit
	end

	function Utils.ResolveStrafeAnimation(currentPos: Vector3, nextPos: Vector3, lookTarget: Vector3?, fallbackAnimation: string?): string
		local defaultAnimation = fallbackAnimation or "Run"
		if not currentPos or not nextPos or not lookTarget then
			return defaultAnimation
		end

		local moveDirection = Vector3.new(nextPos.X - currentPos.X, 0, nextPos.Z - currentPos.Z)
		if moveDirection.Magnitude <= 0.08 then
			return defaultAnimation
		end

		local facingDirection = Vector3.new(lookTarget.X - nextPos.X, 0, lookTarget.Z - nextPos.Z)
		if facingDirection.Magnitude <= 0.08 then
			return defaultAnimation
		end

		moveDirection = moveDirection.Unit
		facingDirection = facingDirection.Unit

		local lateralDirection = Utils.GetLateralFromForward(facingDirection)
		local sideAmount = moveDirection:Dot(lateralDirection)
		local forwardAmount = math.abs(moveDirection:Dot(facingDirection))

		-- Use Walk - Left / Walk - Right only when the actor is mostly moving sideways
		-- while the root keeps facing the ball/goal. Forward movement still uses Run.
		if math.abs(sideAmount) >= 0.38 and math.abs(sideAmount) > (forwardAmount * 0.72) then
			return sideAmount >= 0 and "StrafeRight" or "StrafeLeft"
		end

		return defaultAnimation
	end

	function Utils.ResolveForwardAttackLookPosition(worldPosition: Vector3, fallbackLookVector: Vector3?): Vector3
		local attackDirection = Utils.GetAttackDirectionFromPosition(worldPosition, fallbackLookVector)
		local goalTarget = MatchZoneQuery and MatchZoneQuery.GetGoalTarget and MatchZoneQuery.GetGoalTarget()

		if goalTarget then
			return Vector3.new(goalTarget.Position.X, worldPosition.Y, goalTarget.Position.Z)
		end

		return worldPosition + attackDirection
	end

	return Utils
end
