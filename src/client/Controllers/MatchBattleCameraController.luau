local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)
local MatchCameraConfig = require(script.Parent.Parent.Config.Match.MatchCameraConfig)

local LocalPlayer = Players.LocalPlayer

local MatchService = nil
local MatchBallController = nil

local SIDE_SIGN = 1

local MatchBattleCameraController = Knit.CreateController({
	Name = "MatchBattleCameraController",

	ActiveSessionId = nil,
	CurrentStepIndex = 1,

	LastCameraType = nil,
	LastCameraSubject = nil,

	ShakeToken = 0,
	BallTrackingToken = 0,
	ActionBoostToken = 0,

	IsShooting = false,
	IsPushIn = false,
	ShootSlowMotionAlpha = 0,
	ShootLockPosition = nil,

	RenderStepConnection = nil,
	ActionBoostState = nil,
	ActionBoostFovBase = nil,

	-- Hard camera lock used by shoot cinematic / QTE freeze.
	-- When true, this controller must not write CurrentCamera.CFrame.
	ExternalCameraLocked = false,

	QteCameraPaused = false,
	QteSoftFollowActive = false,
})

-- // [ HELPERS ] // --

local function getGoalLookPosition(): Vector3?
	local goalTarget = MatchZoneQuery.GetGoalTarget()
	if goalTarget then
		return goalTarget.Position
	end

	local saveTarget = MatchZoneQuery.GetSaveTarget()
	if saveTarget then
		return saveTarget.Position
	end

	local keeperEngage = MatchZoneQuery.GetKeeperEngagePoint()
	if keeperEngage then
		return keeperEngage.Position
	end

	return nil
end

local function getTrackedBallPosition(): Vector3?
	if not MatchBallController or not MatchBallController.BallInstance then
		return nil
	end

	local ballInstance = MatchBallController.BallInstance

	if ballInstance:IsA("Model") then
		return ballInstance:GetPivot().Position
	end

	if ballInstance:IsA("BasePart") then
		return ballInstance.Position
	end

	return nil
end

local function isVector3(value): boolean
	return typeof(value) == "Vector3"
end

local function getFlatUnitDirection(fromPosition: Vector3?, toPosition: Vector3?): Vector3?
	if not isVector3(fromPosition) or not isVector3(toPosition) then
		return nil
	end

	local delta = Vector3.new(toPosition.X - fromPosition.X, 0, toPosition.Z - fromPosition.Z)
	if delta.Magnitude <= 0.001 then
		return nil
	end

	return delta.Unit
end

local function getFlatCameraForward(cframe: CFrame): Vector3
	local lookVector = cframe.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)

	if flatLook.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return flatLook.Unit
end

local function buildAttackDirection(origin: Vector3?, lookTarget: Vector3?): Vector3
	if origin and lookTarget then
		local flatTarget = Vector3.new(lookTarget.X, origin.Y, lookTarget.Z)
		local direction = flatTarget - origin

		if direction.Magnitude > 0.001 then
			return direction.Unit
		end
	end

	return Vector3.new(0, 0, -1)
end

local function buildFollowCFrame(subjectPosition: Vector3, lookPosition: Vector3?, config): CFrame
	local resolvedLookPosition = lookPosition or (subjectPosition + Vector3.new(0, 0, -10))
	local forward = buildAttackDirection(subjectPosition, resolvedLookPosition)

	local right = forward:Cross(Vector3.yAxis)
	if right.Magnitude <= 0.001 then
		right = Vector3.xAxis
	else
		right = right.Unit
	end

	local effectiveSideOffset = (config.SideOffset or 0) * SIDE_SIGN

	local cameraPosition =
		subjectPosition
		- (forward * config.BehindDistance)
		+ (right * effectiveSideOffset)
		+ Vector3.new(0, config.Height, 0)

	local lookAtPosition =
		subjectPosition
		+ (forward * (config.ForwardLook or 20))
		+ Vector3.new(0, config.LookHeight or 4, 0)

	return CFrame.lookAt(cameraPosition, lookAtPosition)
end

-- // [ CAMERA TARGET ] // --

function MatchBattleCameraController:_getFollowCFrame(ballPosition: Vector3?): CFrame?
	local config = self.IsPushIn and MatchCameraConfig.ShootPushIn or MatchCameraConfig.Follow

	if self.IsShooting and self.ShootLockPosition then
		local lockPos = self.ShootLockPosition
		local lookPosition = getGoalLookPosition()
		local subjectPosition = Vector3.new(lockPos.X, 0, lockPos.Z)

		return buildFollowCFrame(subjectPosition, lookPosition, config)
	end

	local trackedBall = ballPosition or getTrackedBallPosition()
	if not trackedBall then
		return nil
	end

	local lookPosition = getGoalLookPosition()
	local subjectPosition = Vector3.new(trackedBall.X, 0, trackedBall.Z)

	return buildFollowCFrame(subjectPosition, lookPosition, config)
end

-- // [ CAMERA CONTROL ] // --

function MatchBattleCameraController:_ensureCameraScriptable()
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	if self.LastCameraType == nil then
		self.LastCameraType = camera.CameraType
	end

	if self.LastCameraSubject == nil then
		self.LastCameraSubject = camera.CameraSubject
	end

	camera.CameraType = Enum.CameraType.Scriptable
	return camera
end

local function normalizeBoostTier(tier: any): string
	local tierName = string.upper(tostring(tier or "Green"))
	if tierName == "PERFECT" or tierName == "EXCELLENT" then
		return "Green"
	end
	if tierName == "YELLOW" or tierName == "SUCCESS" then
		return "Yellow"
	end
	return "Green"
end

function MatchBattleCameraController:_getPerfectActionBoostConfig(kind: string, tier: any?)
	local rootConfig = MatchCameraConfig.PerfectActionBoost
	if type(rootConfig) ~= "table" or rootConfig.Enabled == false then
		return nil
	end

	local config = rootConfig[kind]
	if type(config) ~= "table" or config.Enabled == false then
		return nil
	end

	local tierConfig = config[normalizeBoostTier(tier)]
	if type(tierConfig) == "table" and tierConfig.Enabled ~= false then
		return tierConfig
	end

	return config
end

function MatchBattleCameraController:_restoreActionBoostFov(camera: Camera?)
	if self.ActionBoostFovBase == nil then
		return
	end

	local targetCamera = camera or Workspace.CurrentCamera
	if targetCamera then
		targetCamera.FieldOfView = self.ActionBoostFovBase
	end

	self.ActionBoostFovBase = nil
end

function MatchBattleCameraController:_clearActionBoost(restoreFov: boolean?)
	self.ActionBoostToken += 1
	self.ActionBoostState = nil

	if restoreFov then
		self:_restoreActionBoostFov()
	end
end

function MatchBattleCameraController:_applyActionBoost(camera: Camera, targetCFrame: CFrame): CFrame
	local boostState = self.ActionBoostState
	if not boostState then
		return targetCFrame
	end

	if boostState.Token ~= self.ActionBoostToken then
		self.ActionBoostState = nil
		return targetCFrame
	end

	local duration = math.max(tonumber(boostState.Duration) or 0, 0.01)
	local elapsed = os.clock() - (tonumber(boostState.StartedAt) or os.clock())
	local alpha = math.clamp(elapsed / duration, 0, 1)

	if alpha >= 1 then
		self:_clearActionBoost(true)
		return targetCFrame
	end

	if self.ActionBoostFovBase == nil then
		self.ActionBoostFovBase = camera.FieldOfView
	end

	local pulse = math.sin(alpha * math.pi)
	local fovKick = tonumber(boostState.FovKick) or 0
	if fovKick ~= 0 then
		camera.FieldOfView = self.ActionBoostFovBase + (fovKick * pulse)
	end

	local direction = boostState.Direction or getFlatCameraForward(targetCFrame)
	local sideSign = tonumber(boostState.SideSign) or 1
	local lookAhead = tonumber(boostState.LookAhead) or 0

	local position = targetCFrame.Position
		+ (targetCFrame.LookVector * (tonumber(boostState.DollyForward) or 0) * pulse)
		+ (direction * (tonumber(boostState.LeadDistance) or 0) * pulse)
		+ (targetCFrame.RightVector * sideSign * (tonumber(boostState.SideSway) or 0) * pulse)
		+ (targetCFrame.UpVector * (tonumber(boostState.Lift) or 0) * pulse)

	local lookTarget = targetCFrame.Position + (targetCFrame.LookVector * (tonumber(boostState.BaseLookDistance) or 60))
	local toPosition = boostState.ToPosition

	if isVector3(toPosition) then
		local targetLook = toPosition
			+ Vector3.new(0, tonumber(boostState.LookHeight) or 3, 0)
			+ (direction * lookAhead * pulse)

		lookTarget = lookTarget:Lerp(
			targetLook,
			math.clamp((tonumber(boostState.LookBlend) or 0) * pulse, 0, 1)
		)
	elseif lookAhead ~= 0 then
		lookTarget += direction * lookAhead * pulse
	end

	if (lookTarget - position).Magnitude <= 0.05 then
		return targetCFrame
	end

	return CFrame.lookAt(position, lookTarget)
end

function MatchBattleCameraController:_canWriteCamera(): boolean
	if self.ExternalCameraLocked then
		return false
	end

	if self.QteCameraPaused then
		return false
	end

	return self.ActiveSessionId ~= nil
end

function MatchBattleCameraController:_writeCamera(camera: Camera, targetCFrame: CFrame, alpha: number?)
	if not camera or not camera.Parent then
		return
	end

	if not self:_canWriteCamera() then
		return
	end

	local finalAlpha = math.clamp(alpha or 1, 0, 1)
	local boostedTargetCFrame = self:_applyActionBoost(camera, targetCFrame)

	if finalAlpha >= 1 then
		camera.CFrame = boostedTargetCFrame
	else
		camera.CFrame = camera.CFrame:Lerp(boostedTargetCFrame, finalAlpha)
	end
end

function MatchBattleCameraController:_startBallTracking()
	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	self.BallTrackingToken += 1
	local myToken = self.BallTrackingToken

	if self.RenderStepConnection then
		self.RenderStepConnection:Disconnect()
		self.RenderStepConnection = nil
	end

	self.RenderStepConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not self:_canWriteCamera() then
			return
		end

		if self.BallTrackingToken ~= myToken then
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Scriptable then
			return
		end

		local ballPosition = getTrackedBallPosition()
		local targetCFrame = self:_getFollowCFrame(ballPosition)
		if not targetCFrame then
			return
		end

		local baseFramerate = 60
		local lerpSpeed = MatchCameraConfig.TrackingLerpSpeed or 0.10

		if self.IsShooting and self.ShootSlowMotionAlpha > 0 then
			lerpSpeed = math.min(
				0.15 * (1 + self.ShootSlowMotionAlpha * (MatchCameraConfig.ShootSlowMoLerpMultiplier or 1)),
				1
			)
		elseif self.QteSoftFollowActive then
			lerpSpeed = MatchCameraConfig.QteTrackingLerpSpeed or 0.055
		end

		local adjustedAlpha = 1 - math.pow(1 - lerpSpeed, (deltaTime or 0.016) * baseFramerate)
		self:_writeCamera(camera, targetCFrame, adjustedAlpha)
	end)
end

function MatchBattleCameraController:_stopBallTracking()
	self.BallTrackingToken += 1

	if self.RenderStepConnection then
		self.RenderStepConnection:Disconnect()
		self.RenderStepConnection = nil
	end
end

function MatchBattleCameraController:_setExternalCameraLocked(isLocked: boolean)
	self.ExternalCameraLocked = isLocked == true

	if self.ExternalCameraLocked then
		self.ShakeToken += 1
		self.QteSoftFollowActive = false
		self:_clearActionBoost(true)
		self:_stopBallTracking()
	end
end

-- // [ PUBLIC API ] // --

function MatchBattleCameraController:_startPerfectActionBoost(kind: string, fromPosition: Vector3?, toPosition: Vector3?, tier: any?)
	if self.ExternalCameraLocked or self.QteCameraPaused or not self.ActiveSessionId then
		return
	end

	local config = self:_getPerfectActionBoostConfig(kind, tier)
	if not config then
		return
	end

	local duration = tonumber(config.Duration) or 0
	if duration <= 0 then
		return
	end

	local camera = self:_ensureCameraScriptable()
	if not camera then
		return
	end

	local resolvedFrom = isVector3(fromPosition) and fromPosition or getTrackedBallPosition()
	local resolvedTo = isVector3(toPosition) and toPosition or getGoalLookPosition()
	local direction = getFlatUnitDirection(resolvedFrom, resolvedTo) or getFlatCameraForward(camera.CFrame)
	local sideSign = direction:Dot(camera.CFrame.RightVector) >= 0 and 1 or -1

	self.ActionBoostToken += 1
	self.ActionBoostFovBase = self.ActionBoostFovBase or camera.FieldOfView
	self.ActionBoostState = {
		Token = self.ActionBoostToken,
		Kind = kind,
		Tier = normalizeBoostTier(tier),
		StartedAt = os.clock(),
		Duration = duration,
		Direction = direction,
		ToPosition = resolvedTo,
		SideSign = sideSign,
		FovKick = tonumber(config.FovKick) or 0,
		DollyForward = tonumber(config.DollyForward) or 0,
		LeadDistance = tonumber(config.LeadDistance) or 0,
		SideSway = tonumber(config.SideSway) or 0,
		Lift = tonumber(config.Lift) or 0,
		LookAhead = tonumber(config.LookAhead) or 0,
		LookBlend = tonumber(config.LookBlend) or 0,
		LookHeight = tonumber(config.LookHeight) or 3,
		BaseLookDistance = tonumber(config.BaseLookDistance) or 60,
	}

	if not self.RenderStepConnection then
		self:_startBallTracking()
	end
end

function MatchBattleCameraController:OnPerfectPassBoost(startPosition: Vector3?, endPosition: Vector3?)
	self:_startPerfectActionBoost("Pass", startPosition, endPosition)
end

function MatchBattleCameraController:OnPerfectDribbleBoost(actorPosition: Vector3?, targetPosition: Vector3?)
	self:_startPerfectActionBoost("Dribble", actorPosition, targetPosition)
end

function MatchBattleCameraController:OnPassActionBoost(startPosition: Vector3?, endPosition: Vector3?, tier: any?)
	self:_startPerfectActionBoost("Pass", startPosition, endPosition, tier)
end

function MatchBattleCameraController:OnDribbleActionBoost(actorPosition: Vector3?, targetPosition: Vector3?, tier: any?)
	self:_startPerfectActionBoost("Dribble", actorPosition, targetPosition, tier)
end

function MatchBattleCameraController:Shake(intensity, duration)
	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	local camera = self:_ensureCameraScriptable()
	if not camera then
		return
	end

	self.ShakeToken += 1
	local myToken = self.ShakeToken

	local baseCFrame = self:_getFollowCFrame() or camera.CFrame
	local shakeIntensity = intensity or MatchCameraConfig.GoalShake.Intensity
	local shakeDuration = duration or MatchCameraConfig.GoalShake.Duration

	task.spawn(function()
		local startedAt = os.clock()

		while self:_canWriteCamera() and self.ShakeToken == myToken do
			local elapsed = os.clock() - startedAt
			local alpha = math.clamp(elapsed / math.max(shakeDuration, 0.01), 0, 1)

			if alpha >= 1 then
				break
			end

			local decay = 1 - alpha
			local currentIntensity = shakeIntensity * decay

			local offsetX = (math.random() - 0.5) * 2 * currentIntensity
			local offsetY = (math.random() - 0.5) * currentIntensity

			self:_writeCamera(camera, baseCFrame * CFrame.new(offsetX, offsetY, 0), 1)
			task.wait()
		end

		if self:_canWriteCamera() and self.ShakeToken == myToken then
			self:_writeCamera(camera, baseCFrame, 1)
		end
	end)
end

function MatchBattleCameraController:OnShootAnticipation()
	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	self:_clearActionBoost(true)
	self.IsPushIn = true
end

function MatchBattleCameraController:OnShootCommit(isPerfect, shooterPosition: Vector3?)
	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	self:_clearActionBoost(true)
	self.IsPushIn = false
	self.IsShooting = true
	self.ShootLockPosition = shooterPosition or getTrackedBallPosition()

	if isPerfect then
		self.ShootSlowMotionAlpha = 0.3
	end
end

function MatchBattleCameraController:OnShootEnd()
	self.IsShooting = false
	self.IsPushIn = false
	self.ShootSlowMotionAlpha = 0
	self.ShootLockPosition = nil
end

function MatchBattleCameraController:PauseQteCamera()
	self.QteCameraPaused = true
	self.QteSoftFollowActive = false

	self:_setExternalCameraLocked(true)
end

function MatchBattleCameraController:ResumeQteCamera()
	self.QteCameraPaused = false
	self.QteSoftFollowActive = false

	self:_setExternalCameraLocked(false)

	if not self.ActiveSessionId then
		return
	end

	local camera = self:_ensureCameraScriptable()
	if not camera then
		return
	end

	self:_startBallTracking()
end

function MatchBattleCameraController:ApplyStepPreviewCamera(stepIndex: number)
	self.CurrentStepIndex = tonumber(stepIndex) or self.CurrentStepIndex or 1
	self.ShakeToken += 1
	self:_clearActionBoost(true)
	self.IsShooting = false
	self.IsPushIn = false
	self.ShootSlowMotionAlpha = 0
	self.ShootLockPosition = nil

	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	local camera = self:_ensureCameraScriptable()
	if not camera then
		return
	end

	local targetCFrame = self:_getFollowCFrame()
	if targetCFrame and not self.RenderStepConnection then
		self:_writeCamera(camera, targetCFrame, 1)
	end

	self:_startBallTracking()
end

function MatchBattleCameraController:ApplyBattleWide()
	if self.ExternalCameraLocked or self.QteCameraPaused then
		return
	end

	self:_startBallTracking()
end

function MatchBattleCameraController:ApplyMatchIntroCamera()
	self:ApplyStepPreviewCamera(self.CurrentStepIndex or 1)
end

function MatchBattleCameraController:ApplyHolderFocus(_actorTarget, _lookTarget)
end

function MatchBattleCameraController:TrackActionWide(_actorTarget, _enemyTarget, _targetOrPosition)
end

function MatchBattleCameraController:TrackDribbleAction(_actorTarget, _lookTarget)
end

function MatchBattleCameraController:TrackPassAction(_actorTarget, _lookTarget)
end

-- // [ RESTORE / LIFECYCLE ] // --

function MatchBattleCameraController:_restoreCamera()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	self.ShakeToken += 1
	self:_stopBallTracking()

	self.ExternalCameraLocked = false
	self.QteCameraPaused = false
	self.QteSoftFollowActive = false
	self:_clearActionBoost(true)

	self.IsShooting = false
	self.IsPushIn = false
	self.ShootSlowMotionAlpha = 0
	self.ShootLockPosition = nil

	camera.CameraType = self.LastCameraType or Enum.CameraType.Custom

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		camera.CameraSubject = humanoid
	elseif self.LastCameraSubject then
		camera.CameraSubject = self.LastCameraSubject
	end

	self.LastCameraType = nil
	self.LastCameraSubject = nil
	self.ActiveSessionId = nil
	self.CurrentStepIndex = 1
end

function MatchBattleCameraController:KnitStart()
	MatchService = Knit.GetService("MatchService")
	MatchBallController = Knit.GetController("MatchBallController")

	MatchService.MatchSessionStarted:Connect(function(payload)
		self.ActiveSessionId = tostring(payload and payload.SessionId or "")
		self.CurrentStepIndex = 1
		self:ApplyStepPreviewCamera(1)
	end)

	MatchService.MatchApproachStarted:Connect(function(stepPayload)
		if self.ActiveSessionId ~= tostring(stepPayload and stepPayload.SessionId or "") then
			return
		end

		self.CurrentStepIndex = tonumber(stepPayload and stepPayload.StepIndex or 1) or self.CurrentStepIndex
	end)

	MatchService.MatchStepStarted:Connect(function(stepPayload)
		if self.ActiveSessionId ~= tostring(stepPayload and stepPayload.SessionId or "") then
			return
		end

		self.CurrentStepIndex = tonumber(stepPayload and stepPayload.StepIndex or 1) or self.CurrentStepIndex
	end)

	MatchService.MatchSessionEnded:Connect(function(_, sessionId)
		local endedSessionId = tostring(sessionId or "")
		if endedSessionId ~= "" and self.ActiveSessionId ~= nil and tostring(self.ActiveSessionId) ~= endedSessionId then
			return
		end

		self.ActiveSessionId = nil
		self:_restoreCamera()
	end)

	LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
		local camera = Workspace.CurrentCamera

		if camera and humanoid and camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraSubject = humanoid
		end
	end)
end

return MatchBattleCameraController
