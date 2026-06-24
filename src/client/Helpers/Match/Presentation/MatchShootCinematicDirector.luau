local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local MatchShootCinematicDirector = {}

-- // [ STATE ] // --

local activeToken = 0
local activeConnection = nil
local activeCameraController = nil
local activeCameraCFrame = nil
local activeShakeOffset = CFrame.identity
local activeFlightShakeOffset = CFrame.identity
local activeShakeSerial = 0
local activeDofSerial = 0
local activeDof = nil
local activeDofCreated = false
local activeDofOriginalState = nil

local CAMERA_OVERRIDE_NAME = "MatchShootCinematicCameraOverride"
local PERFECT_SHOOT_DOF_NAME = "MatchShootPerfectDepthOfField"

-- // [ TUNING ] // --

local READY_TWEEN = 0.18

-- Test value: camera holds in front before Shoot animation starts.
local FRONT_PRE_KICK_HOLD = 0.035 -- Keep shoot input responsive; no long post-QTE dead pause

-- Ball release timing after Shoot animation starts.
local KICK_TO_IMPACT_DELAY = 0.12 -- Fast visual ball release after QTE shoot input

local BALL_FOLLOW_ENTRY_TWEEN = 0.035
local BALL_FOLLOW_AFTER_IMPACT_DELAY = 0.015
local BALL_FOLLOW_LERP = 0.20
local MIN_BALL_FOLLOW_DURATION = 0.95

local RESULT_HOLD = 0.15
local RETURN_HOLD = 0.10

local RETURN_TO_SHOOTER_BACK_TWEEN = 0.45
local POST_GOAL_BACK_HOLD = 2.15

local DEFAULT_SHOT_TRAVEL_DURATION = 1.05

local SHAKE_DURATION = 0.22
local SHAKE_STRENGTH = 0.58
local SHAKE_FADE_IN = 0.045
local SHAKE_FADE_OUT = 0.18
local SPECIAL_ROLL_SHAKE_DEGREES = 5.5
local SPECIAL_ROLL_SHAKE_DURATION = 0.95
local SPECIAL_ROLL_SHAKE_FREQUENCY = 8.5
local SPECIAL_ROLL_SHAKE_SIDE_OFFSET = 0.20

-- // [ CAMERA LOCK ] // --

local function setCameraCFrame(camera, cframe)
	activeCameraCFrame = cframe

	if camera and camera.Parent then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = cframe * activeShakeOffset * activeFlightShakeOffset
	end
end

local function unbindCameraOverride()
	RunService:UnbindFromRenderStep(CAMERA_OVERRIDE_NAME)
	activeCameraCFrame = nil
	activeShakeOffset = CFrame.identity
	activeFlightShakeOffset = CFrame.identity
end

local function bindCameraOverride(camera, token)
	RunService:UnbindFromRenderStep(CAMERA_OVERRIDE_NAME)

	RunService:BindToRenderStep(
		CAMERA_OVERRIDE_NAME,
		Enum.RenderPriority.Camera.Value + 100,
		function()
			if activeToken ~= token or not camera or not camera.Parent then
				unbindCameraOverride()
				return
			end

			if activeCameraCFrame then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = activeCameraCFrame * activeShakeOffset * activeFlightShakeOffset
			end
		end
	)
end


local function resolveMatchUIController()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local knitModule = packages and packages:FindFirstChild("Knit")
	if not knitModule then
		return nil
	end

	local ok, Knit = pcall(require, knitModule)
	if not ok or not Knit or type(Knit.GetController) ~= "function" then
		return nil
	end

	local controllerOk, controller = pcall(function()
		return Knit.GetController("MatchUIController")
	end)

	if controllerOk then
		return controller
	end

	return nil
end

local function stopExcellentSpeedEffect()
	local uiController = resolveMatchUIController()
	if uiController and type(uiController.StopExcellentSpeedEffect) == "function" then
		pcall(function()
			uiController:StopExcellentSpeedEffect()
		end)
	end
end

local function disconnectActiveConnection()
	if activeConnection then
		activeConnection:Disconnect()
		activeConnection = nil
	end
end

local function getShakeScale(elapsed, duration, fadeInTime, fadeOutTime)
	if duration <= 0 then
		return 0
	end

	local remaining = duration - elapsed
	local scale = 1
	if fadeInTime > 0 and elapsed < fadeInTime then
		scale = math.clamp(elapsed / fadeInTime, 0, 1)
	elseif fadeOutTime > 0 and remaining < fadeOutTime then
		scale = math.clamp(remaining / fadeOutTime, 0, 1)
	end

	return math.clamp(scale, 0, 1)
end

local function buildShakeOffset(strength, scale)
	local currentStrength = math.max(strength or 0, 0) * math.clamp(scale or 0, 0, 1)
	if currentStrength <= 0 then
		return CFrame.identity
	end

	local offset = Vector3.new(
		(math.random() - 0.5) * 2 * currentStrength,
		(math.random() - 0.5) * 2 * currentStrength,
		(math.random() - 0.5) * 0.9 * currentStrength
	)

	local roll = math.rad((math.random() - 0.5) * 1.8) * currentStrength
	return CFrame.new(offset) * CFrame.Angles(0, 0, roll)
end

local function resetPerfectShootDepthOfField()
	activeDofSerial += 1

	if activeDof then
		if activeDofCreated then
			activeDof:Destroy()
		elseif activeDofOriginalState then
			activeDof.Enabled = activeDofOriginalState.Enabled
			activeDof.FocusDistance = activeDofOriginalState.FocusDistance
			activeDof.InFocusRadius = activeDofOriginalState.InFocusRadius
			activeDof.NearIntensity = activeDofOriginalState.NearIntensity
			activeDof.FarIntensity = activeDofOriginalState.FarIntensity
		end
	end

	activeDof = nil
	activeDofCreated = false
	activeDofOriginalState = nil
end

local function ensurePerfectShootDepthOfField()
	local existing = Lighting:FindFirstChild(PERFECT_SHOOT_DOF_NAME)
	if existing and existing:IsA("DepthOfFieldEffect") then
		activeDof = existing
		activeDofCreated = false
		activeDofOriginalState = {
			Enabled = existing.Enabled,
			FocusDistance = existing.FocusDistance,
			InFocusRadius = existing.InFocusRadius,
			NearIntensity = existing.NearIntensity,
			FarIntensity = existing.FarIntensity,
		}
		return existing
	end

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = PERFECT_SHOOT_DOF_NAME
	dof.Enabled = true
	dof.FocusDistance = 14
	dof.InFocusRadius = 18
	dof.NearIntensity = 0
	dof.FarIntensity = 0
	dof.Parent = Lighting

	activeDof = dof
	activeDofCreated = true
	activeDofOriginalState = nil
	return dof
end

-- // [ HELPERS ] // --

local function isAlive(context)
	if type(context.SessionAlive) == "function" then
		return context.SessionAlive() == true
	end

	return true
end

local function getRootPosition(context)
	local actorRoot = context.ActorRoot

	if actorRoot and actorRoot:IsA("BasePart") then
		return actorRoot.Position
	end

	return context.StartPos or Vector3.zero
end

local function getBallPosition(context)
	if type(context.GetBallPosition) == "function" then
		local ok, result = pcall(context.GetBallPosition)

		if ok and typeof(result) == "Vector3" then
			return result
		end
	end

	return context.StartPos or getRootPosition(context)
end

local function getFlatDirection(fromPosition, toPosition)
	local direction = Vector3.new(
		toPosition.X - fromPosition.X,
		0,
		toPosition.Z - fromPosition.Z
	)

	if direction.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return direction.Unit
end

local function getRightVector(forward)
	local right = forward:Cross(Vector3.yAxis)

	if right.Magnitude <= 0.001 then
		return Vector3.xAxis
	end

	return right.Unit
end

local function tweenCamera(camera, targetCFrame, duration, token, easingStyle, easingDirection)
	if not camera or not targetCFrame or activeToken ~= token then
		return false
	end

	local tweenDuration = math.max(tonumber(duration) or 0, 0)

	if tweenDuration <= 0 then
		setCameraCFrame(camera, targetCFrame)
		return activeToken == token
	end

	local cfValue = Instance.new("CFrameValue")
	cfValue.Value = activeCameraCFrame or camera.CFrame

	local connection = cfValue:GetPropertyChangedSignal("Value"):Connect(function()
		if activeToken == token and camera and camera.Parent then
			setCameraCFrame(camera, cfValue.Value)
		end
	end)

	local tween = TweenService:Create(
		cfValue,
		TweenInfo.new(
			tweenDuration,
			easingStyle or Enum.EasingStyle.Sine,
			easingDirection or Enum.EasingDirection.Out
		),
		{
			Value = targetCFrame,
		}
	)

	tween:Play()
	tween.Completed:Wait()

	connection:Disconnect()
	cfValue:Destroy()

	if activeToken == token and camera and camera.Parent then
		setCameraCFrame(camera, targetCFrame)
		return true
	end

	return false
end

local function holdCamera(camera, targetCFrame, duration, token)
	local startedAt = os.clock()

	while activeToken == token
		and camera
		and camera.Parent
		and os.clock() - startedAt < duration
	do
		setCameraCFrame(camera, targetCFrame)
		RunService.RenderStepped:Wait()
	end
end

local function buildCameraFrames(context)
	local actorPosition = getRootPosition(context)
	local startPos = context.StartPos or actorPosition
	local endPos = context.EndPos or (startPos + Vector3.new(0, 0, -35))
	local isSpecialShoot = context.IsSpecialShoot == true

	local forward = getFlatDirection(actorPosition, endPos)
	local right = getRightVector(forward)

	local frontPosition
	local frontLook
	local releasePosition
	local releaseLook

	if isSpecialShoot then
		-- Special/salto shoot needs a wider 35-45 degree side angle.
		-- This keeps the animated ball readable before BallRelease and avoids a straight-back view hiding the ball behind the body.
		frontPosition = actorPosition
			- (forward * 10.5)
			+ (right * 8.5)
			+ Vector3.new(0, 4.8, 0)

		frontLook = actorPosition
			+ (forward * 2.4)
			+ Vector3.new(0, 2.2, 0)

		releasePosition = actorPosition
			- (forward * 13.5)
			+ (right * 10.0)
			+ Vector3.new(0, 5.6, 0)

		releaseLook = actorPosition
			+ (forward * 5.5)
			+ Vector3.new(0, 2.3, 0)
	else
		-- Normal shoot keeps the low foot angle that was already working well.
		frontPosition = actorPosition
			+ (forward * 5.2)
			+ (right * 6.5)
			+ Vector3.new(0, 0.25, 0)

		frontLook = actorPosition + Vector3.new(0, 1.2, 0)

		releasePosition = actorPosition
			- (forward * 7.0)
			+ (right * 1.5)
			+ Vector3.new(0, 2.8, 0)

		releaseLook = startPos + (forward * 6.0) + Vector3.new(0, 0.8, 0)
	end

	return {
		Forward = forward,
		Right = right,
		IsSpecialShoot = isSpecialShoot,
		Front = CFrame.lookAt(frontPosition, frontLook),
		Back = CFrame.lookAt(releasePosition, releaseLook),
		EndPos = endPos,
	}
end

local function lerpNumber(fromValue, toValue, alpha)
	return fromValue + ((toValue - fromValue) * math.clamp(alpha, 0, 1))
end

local function buildGoalLockedBallFollowCFrame(context, frames)
	local ballPosition = getBallPosition(context)
	local endPos = context.EndPos or frames.EndPos or (ballPosition + (frames.Forward * 30))

	local flatDistanceToEnd = Vector3.new(endPos.X - ballPosition.X, 0, endPos.Z - ballPosition.Z).Magnitude
	local nearKeeperAlpha = 1 - math.clamp(flatDistanceToEnd / 26.0, 0, 1)
	local effectiveBallPos = ballPosition

	if flatDistanceToEnd < 18.0 then
		local flatForward = Vector3.new(frames.Forward.X, 0, frames.Forward.Z)
		if flatForward.Magnitude <= 0.001 then
			flatForward = Vector3.new(0, 0, -1)
		else
			flatForward = flatForward.Unit
		end

		local minimumFramingDistance = lerpNumber(22.0, 30.0, nearKeeperAlpha)
		effectiveBallPos = endPos - (flatForward * minimumFramingDistance)
		effectiveBallPos = Vector3.new(effectiveBallPos.X, ballPosition.Y, effectiveBallPos.Z)
	end

	local followBackDistance = lerpNumber(15.0, 22.0, nearKeeperAlpha)
	local followSideOffset = frames.IsSpecialShoot and lerpNumber(3.4, 2.2, nearKeeperAlpha) or lerpNumber(0.6, 1.6, nearKeeperAlpha)
	local followHeight = lerpNumber(3.2, 5.2, nearKeeperAlpha)
	local lookHeight = lerpNumber(1.8, 2.9, nearKeeperAlpha)

	local cameraPosition =
		effectiveBallPos
		- (frames.Forward * followBackDistance)
		+ (frames.Right * followSideOffset)
		+ Vector3.new(0, followHeight, 0)

	local goalLook =
		endPos
		+ Vector3.new(0, lookHeight, 0)

	return CFrame.lookAt(cameraPosition, goalLook)
end
local function buildShooterBackGoalFacingCFrame(context, frames)
	local actorPosition = getRootPosition(context)
	local endPos = context.EndPos or frames.EndPos or (actorPosition + frames.Forward * 35)

	local forward = getFlatDirection(actorPosition, endPos)
	local right = getRightVector(forward)

	local cameraPosition =
		actorPosition
		- (forward * 15.5)
		+ (right * 2.2)
		+ Vector3.new(0, 4.8, 0)

	local lookTarget =
		endPos
		+ Vector3.new(0, 2.0, 0)

	return CFrame.lookAt(cameraPosition, lookTarget)
end

local function finishCinematic(keepCameraLocked)
	disconnectActiveConnection()

	-- When the result celebration needs to be readable, keep the camera override
	-- bound at the final behind-shooter frame. The caller must release it with Stop(),
	-- usually from match cleanup / teleport out.
	if keepCameraLocked == true then
		return
	end

	unbindCameraOverride()

	if activeCameraController and activeCameraController.ResumeQteCamera then
		activeCameraController:ResumeQteCamera()
	end

	activeCameraController = nil
end
local function createImpactGate(token, kickStartedAt, customDelay, onImpact, impactOptions)
	local gate = {
		Fired = false,
		Connection = nil,
		ExternalConnection = nil,
	}

	impactOptions = type(impactOptions) == "table" and impactOptions or {}

	local targetDelay = customDelay or KICK_TO_IMPACT_DELAY
	local track = impactOptions.Track
	local markerName = impactOptions.ImpactMarkerName
	local impactSignal = impactOptions.ImpactSignal
	local waitForExternalImpact = impactOptions.WaitForExternalImpact == true
	local wasImpactFired = impactOptions.WasImpactFired
	local getPendingImpactParameter = impactOptions.GetPendingImpactParameter

	if waitForExternalImpact then
		-- Marker-owned releases must not be clamped to the generic impact delay.
		-- The delay is only an emergency fallback when the animation marker is missing.
		targetDelay = math.max(tonumber(impactOptions.ExpectedImpactDelay) or targetDelay, 0.18)
	else
		local maxImpactDelay = tonumber(impactOptions.MaxImpactDelay) or 0.58
		if maxImpactDelay > 0 then
			targetDelay = math.min(targetDelay, maxImpactDelay)
		end
	end

	function gate:Disconnect()
		if self.Connection then
			self.Connection:Disconnect()
			self.Connection = nil
		end

		if self.ExternalConnection then
			self.ExternalConnection:Disconnect()
			self.ExternalConnection = nil
		end
	end

	function gate:Fire(reason, parameter)
		if self.Fired then
			return
		end

		self.Fired = true
		self:Disconnect()

		if type(onImpact) == "function" then
			onImpact(reason, parameter)
		end
	end

	if impactSignal then
		local ok = pcall(function()
			gate.ExternalConnection = impactSignal:Connect(function(parameter)
				if activeToken == token then
					gate:Fire("marker", parameter)
				end
			end)
		end)

		if not ok then
			gate.ExternalConnection = nil
		end
	elseif track and markerName and markerName ~= "" then
		local ok, signal = pcall(function()
			return track:GetMarkerReachedSignal(markerName)
		end)

		if ok and signal then
			gate.Connection = signal:Connect(function(parameter)
				if activeToken == token then
					gate:Fire("marker", parameter)
				end
			end)
		end
	end

	function gate:Wait()
		while activeToken == token and not self.Fired do
			if type(wasImpactFired) == "function" and wasImpactFired() == true then
				local parameter = nil
				if type(getPendingImpactParameter) == "function" then
					parameter = getPendingImpactParameter()
				end

				self:Fire("marker", parameter)
				break
			end

			local elapsed = os.clock() - kickStartedAt

			if elapsed >= targetDelay then
				self:Fire(waitForExternalImpact and "emergency-fallback" or "fallback", nil)
				break
			end

			RunService.RenderStepped:Wait()
		end

		if not self.Fired and activeToken == token then
			self:Fire("forced", nil)
		end

		self:Disconnect()
	end

	return gate
end
local function followBallGoalLocked(camera, context, frames, duration, token)
	local followDuration = math.max(duration or MIN_BALL_FOLLOW_DURATION, MIN_BALL_FOLLOW_DURATION)
	local startedAt = os.clock()
	local flightShakeStrength = math.max(tonumber(context.FlightShakeStrength) or 0.08, 0)
	local flightShakeFrequency = math.max(tonumber(context.FlightShakeFrequency) or 22.0, 1.0)

	disconnectActiveConnection()

	activeConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if activeToken ~= token or not camera or not camera.Parent or not isAlive(context) then
			activeFlightShakeOffset = CFrame.identity
			disconnectActiveConnection()
			return
		end

		local elapsed = os.clock() - startedAt
		if flightShakeStrength > 0 then
			local travelAlpha = math.clamp(elapsed / math.max(followDuration, 0.01), 0, 1)
			local easeOut = 1 - math.pow(travelAlpha, 1.75)
			local pulse = math.sin(elapsed * flightShakeFrequency)
			local randomX = (math.random() - 0.5) * flightShakeStrength * 0.65
			local randomY = (math.random() - 0.5) * flightShakeStrength * 0.45
			activeFlightShakeOffset = CFrame.new(
				(randomX + pulse * flightShakeStrength * 0.45) * easeOut,
				randomY * easeOut,
				0
			)
		else
			activeFlightShakeOffset = CFrame.identity
		end

		local targetCFrame = buildGoalLockedBallFollowCFrame(context, frames)
		local alpha = 1 - math.pow(1 - BALL_FOLLOW_LERP, (deltaTime or 0.016) * 60)
		local currentCFrame = activeCameraCFrame or camera.CFrame

		setCameraCFrame(
			camera,
			currentCFrame:Lerp(targetCFrame, math.clamp(alpha, 0, 1))
		)
	end)

	while activeToken == token
		and camera
		and camera.Parent
		and isAlive(context)
		and os.clock() - startedAt < followDuration
	do
		RunService.RenderStepped:Wait()
	end

	activeFlightShakeOffset = CFrame.identity
	disconnectActiveConnection()
end

local function shakeCamera(camera, token, baseCFrame, strength, duration, fadeInTime, fadeOutTime)
	local shakeStrength = tonumber(strength) or SHAKE_STRENGTH
	local shakeDuration = tonumber(duration) or SHAKE_DURATION
	local shakeFadeIn = math.max(tonumber(fadeInTime) or SHAKE_FADE_IN, 0)
	local shakeFadeOut = math.max(tonumber(fadeOutTime) or SHAKE_FADE_OUT, 0)
	local startedAt = os.clock()

	while activeToken == token and camera and camera.Parent and os.clock() - startedAt < shakeDuration do
		local elapsed = os.clock() - startedAt
		local scale = getShakeScale(elapsed, shakeDuration, shakeFadeIn, shakeFadeOut)
		setCameraCFrame(camera, baseCFrame * buildShakeOffset(shakeStrength, scale))
		RunService.RenderStepped:Wait()
	end

	if activeToken == token and camera and camera.Parent then
		setCameraCFrame(camera, baseCFrame)
	end
end

-- // [ PUBLIC API ] // --

function MatchShootCinematicDirector.ShakeActiveCamera(strength: number?, duration: number?, fadeInTime: number?, fadeOutTime: number?)
	local camera = Workspace.CurrentCamera
	if not camera or not camera.Parent then
		return
	end

	local token = activeToken
	local shakeStrength = tonumber(strength) or SHAKE_STRENGTH
	local shakeDuration = tonumber(duration) or SHAKE_DURATION
	local shakeFadeIn = math.max(tonumber(fadeInTime) or SHAKE_FADE_IN, 0)
	local shakeFadeOut = math.max(tonumber(fadeOutTime) or SHAKE_FADE_OUT, 0)
	activeShakeSerial += 1
	local shakeSerial = activeShakeSerial

	task.spawn(function()
		local startedAt = os.clock()
		while activeToken == token
			and activeShakeSerial == shakeSerial
			and camera
			and camera.Parent
			and os.clock() - startedAt < shakeDuration
		do
			local elapsed = os.clock() - startedAt
			local scale = getShakeScale(elapsed, shakeDuration, shakeFadeIn, shakeFadeOut)

			activeShakeOffset = buildShakeOffset(shakeStrength, scale)
			if activeCameraCFrame and camera and camera.Parent then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = activeCameraCFrame * activeShakeOffset * activeFlightShakeOffset
			end
			RunService.RenderStepped:Wait()
		end

		if activeToken == token and activeShakeSerial == shakeSerial then
			activeShakeOffset = CFrame.identity
		end
		if activeToken == token and activeShakeSerial == shakeSerial and camera and camera.Parent and activeCameraCFrame then
			setCameraCFrame(camera, activeCameraCFrame)
		end
	end)
end

function MatchShootCinematicDirector.ShakeActiveCameraRoll(
	rollDegrees: number?,
	duration: number?,
	frequency: number?,
	fadeInTime: number?,
	fadeOutTime: number?,
	sideOffset: number?
)
	local camera = Workspace.CurrentCamera
	if not camera or not camera.Parent then
		return
	end

	local token = activeToken
	local maxRollRadians = math.rad(math.max(tonumber(rollDegrees) or SPECIAL_ROLL_SHAKE_DEGREES, 0))
	local shakeDuration = math.max(tonumber(duration) or SPECIAL_ROLL_SHAKE_DURATION, 0)
	local shakeFrequency = math.max(tonumber(frequency) or SPECIAL_ROLL_SHAKE_FREQUENCY, 0.1)
	local shakeFadeIn = math.max(tonumber(fadeInTime) or 0.08, 0)
	local shakeFadeOut = math.max(tonumber(fadeOutTime) or 0.20, 0)
	local sideAmplitude = math.max(tonumber(sideOffset) or SPECIAL_ROLL_SHAKE_SIDE_OFFSET, 0)

	if maxRollRadians <= 0 or shakeDuration <= 0 then
		return
	end

	activeShakeSerial += 1
	local shakeSerial = activeShakeSerial

	task.spawn(function()
		local startedAt = os.clock()
		while activeToken == token
			and activeShakeSerial == shakeSerial
			and camera
			and camera.Parent
			and os.clock() - startedAt < shakeDuration
		do
			local elapsed = os.clock() - startedAt
			local scale = getShakeScale(elapsed, shakeDuration, shakeFadeIn, shakeFadeOut)
			local wave = math.sin(elapsed * shakeFrequency * math.pi * 2)
			local roll = wave * maxRollRadians * scale
			local side = wave * sideAmplitude * scale

			activeShakeOffset = CFrame.new(side, 0, 0) * CFrame.Angles(0, 0, roll)
			if activeCameraCFrame and camera and camera.Parent then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = activeCameraCFrame * activeShakeOffset * activeFlightShakeOffset
			end
			RunService.RenderStepped:Wait()
		end

		if activeToken == token and activeShakeSerial == shakeSerial then
			activeShakeOffset = CFrame.identity
		end
		if activeToken == token and activeShakeSerial == shakeSerial and camera and camera.Parent and activeCameraCFrame then
			setCameraCFrame(camera, activeCameraCFrame)
		end
	end)
end

function MatchShootCinematicDirector.PulsePerfectShootFocus(focusPosition: Vector3?, duration: number?, farIntensity: number?)
	local camera = Workspace.CurrentCamera
	if not camera or not camera.Parent then
		return
	end

	resetPerfectShootDepthOfField()

	local dof = ensurePerfectShootDepthOfField()
	local token = activeToken
	activeDofSerial += 1
	local dofSerial = activeDofSerial
	local pulseDuration = math.max(tonumber(duration) or 0.42, 0.12)
	local maxFarIntensity = math.clamp(tonumber(farIntensity) or 0.2, 0, 0.32)
	local maxNearIntensity = math.min(maxFarIntensity * 0.28, 0.06)
	local focus = camera.CFrame.Position + camera.CFrame.LookVector * 14
	if typeof(focusPosition) == "Vector3" then
		focus = focusPosition
	end

	task.spawn(function()
		local startedAt = os.clock()

		while activeToken == token
			and activeDofSerial == dofSerial
			and dof
			and dof.Parent
			and camera
			and camera.Parent
			and os.clock() - startedAt < pulseDuration
		do
			local elapsed = os.clock() - startedAt
			local alpha = math.clamp(elapsed / pulseDuration, 0, 1)
			local pulse = math.sin(alpha * math.pi)
			local focusDistance = (camera.CFrame.Position - focus).Magnitude

			dof.Enabled = pulse > 0.02
			dof.FocusDistance = math.clamp(focusDistance, 5, 180)
			dof.InFocusRadius = 16 - (7 * pulse)
			dof.NearIntensity = maxNearIntensity * pulse
			dof.FarIntensity = maxFarIntensity * pulse

			RunService.RenderStepped:Wait()
		end

		if activeToken == token and activeDofSerial == dofSerial then
			resetPerfectShootDepthOfField()
		end
	end)
end

function MatchShootCinematicDirector.Stop()
	activeToken += 1
	activeShakeSerial += 1

	disconnectActiveConnection()
	unbindCameraOverride()
	resetPerfectShootDepthOfField()
	stopExcellentSpeedEffect()

	if activeCameraController and activeCameraController.ResumeQteCamera then
		activeCameraController:ResumeQteCamera()
	end

	activeCameraController = nil
end

function MatchShootCinematicDirector.PlayNormalShootCinematic(context)
	context = context or {}

	MatchShootCinematicDirector.Stop()

	activeToken += 1
	local token = activeToken

	activeCameraController = context.CameraController

	local camera = Workspace.CurrentCamera
	if not camera then
		if type(context.OnImpact) == "function" then
			context.OnImpact()
		end

		return
	end

	if activeCameraController and activeCameraController.PauseQteCamera then
		activeCameraController:PauseQteCamera()
	end

	camera.CameraType = Enum.CameraType.Scriptable
	bindCameraOverride(camera, token)

	local frames = buildCameraFrames(context)
	local shotTravelDuration = math.max(
		tonumber(context.ShotTravelDuration) or DEFAULT_SHOT_TRAVEL_DURATION,
		0.35
	)

	-- Phase 2: Foot Focus
	tweenCamera(
		camera,
		frames.Front,
		READY_TWEEN,
		token,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	holdCamera(camera, frames.Front, FRONT_PRE_KICK_HOLD, token)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	-- Phase 2: Wind-up (Trigger AFTER camera is in position)
	local windupPlayed = false
	local kickWindupResult = nil
	if type(context.OnKickWindup) == "function" and activeToken == token and not windupPlayed then
		windupPlayed = true
		kickWindupResult = context.OnKickWindup()
	end

	local kickStartedAt = os.clock()
	local impactDelay = KICK_TO_IMPACT_DELAY * (context.TimeScaleMultiplier or 1.0)

	local maxImpactDelay = tonumber(context.MaxImpactDelay) or 0.58
	local impactIsMarkerOwned = type(kickWindupResult) == "table" and kickWindupResult.WaitForExternalImpact == true
	if type(kickWindupResult) == "table" and tonumber(kickWindupResult.ExpectedImpactDelay) then
		impactDelay = math.max(tonumber(kickWindupResult.ExpectedImpactDelay), 0.05)
		if not impactIsMarkerOwned then
			kickWindupResult.MaxImpactDelay = maxImpactDelay
		end
	end
	if not impactIsMarkerOwned then
		impactDelay = math.min(impactDelay, maxImpactDelay)
	end

	local impactGate = createImpactGate(token, kickStartedAt, impactDelay, function(reason, parameter)
		if type(context.OnImpact) == "function" then
			context.OnImpact(reason, parameter)
		end

		-- Remove holdCamera here as it fights with the smooth back-pan tween started above
	end, kickWindupResult)

	-- Keep normal shoot timing unchanged. For special shoot, move the camera to the
	-- wider rear frame early, then wait for the marker-owned BallRelease.
	local isSpecialImpact = context.IsSpecialShoot == true
		or (type(kickWindupResult) == "table" and kickWindupResult.IsSpecialShoot == true)

	local swingDuration = isSpecialImpact and 0.55 or 0.42
	local windupDuration = isSpecialImpact
		and 0.18
		or math.max(impactDelay - (swingDuration * 0.72), 0.06)

	task.wait(windupDuration)

	-- Dynamically tween the camera to the Back position while the leg continues the kick.
	task.spawn(function()
		tweenCamera(
			camera,
			frames.Back,
			swingDuration,
			token,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut
		)
	end)

	-- Phase 3: Kick Impact
	impactGate:Wait()

	if activeToken ~= token or not isAlive(context) then
		return
	end

	-- Phase 4: Ball Follow Start
	task.wait(BALL_FOLLOW_AFTER_IMPACT_DELAY)

	tweenCamera(
		camera,
		buildGoalLockedBallFollowCFrame(context, frames),
		BALL_FOLLOW_ENTRY_TWEEN,
		token,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	-- Phase 5: Ball Follow Travel
	followBallGoalLocked(camera, context, frames, shotTravelDuration, token)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	local resultCFrame = activeCameraCFrame or camera.CFrame

	holdCamera(camera, resultCFrame, RESULT_HOLD, token)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	shakeCamera(
		camera,
		token,
		resultCFrame,
		tonumber(context.ShakeStrength) or SHAKE_STRENGTH,
		tonumber(context.ShakeDuration) or SHAKE_DURATION,
		tonumber(context.ShakeFadeIn) or SHAKE_FADE_IN,
		tonumber(context.ShakeFadeOut) or SHAKE_FADE_OUT
	)

	task.wait(RETURN_HOLD)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	-- Phase 6: Return
	local postGoalCFrame = buildShooterBackGoalFacingCFrame(context, frames)

	tweenCamera(
		camera,
		postGoalCFrame,
		RETURN_TO_SHOOTER_BACK_TWEEN,
		token,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)

	if activeToken ~= token or not isAlive(context) then
		return
	end

	if type(context.OnResultCameraReady) == "function" then
		context.OnResultCameraReady(postGoalCFrame)
	end

	local postResultBackHold = math.max(tonumber(context.PostResultBackHold) or POST_GOAL_BACK_HOLD, 0)
	holdCamera(camera, postGoalCFrame, postResultBackHold, token)

	if type(context.OnFinished) == "function" and activeToken == token and isAlive(context) then
		context.OnFinished()
	end

	if activeToken == token then
		finishCinematic(context.KeepCameraLockedAfterFinish == true)
	end
end

return MatchShootCinematicDirector
