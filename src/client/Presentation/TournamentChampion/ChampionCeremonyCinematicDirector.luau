--!strict
-- ChampionCeremonyCinematicDirector.luau
-- Presentation-only camera, blur, fade, and celebration particles for champion ceremony.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local VfxConfig = require(script.Parent.ChampionCeremonyVfxConfig)
local UIJuice = require(script.Parent.Parent.Parent.Helpers.UIJuice)

local ChampionCeremonyCinematicDirector = {}
ChampionCeremonyCinematicDirector.__index = ChampionCeremonyCinematicDirector

local BLUR_NAME = "ChampionCeremonyBlur"
local DOF_NAME = "ChampionCeremonyDepthOfField"
local PARTICLE_FOLDER_NAME = "ChampionCeremonyParticles"
local FADE_NAME = "CinematicFade"
local TITLE_POP_DELAY_SECONDS = 0.25
local TITLE_VISIBLE_SECONDS = 1.35
local TITLE_OUT_SECONDS = 0.16

local function GetPivot(instance: Instance?): CFrame?
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	if instance:IsA("Attachment") then
		return instance.WorldCFrame
	end

	local model = instance:FindFirstChildWhichIsA("Model")
	if model then
		return model:GetPivot()
	end

	local part = instance:FindFirstChildWhichIsA("BasePart", true)
	if part then
		return part.CFrame
	end

	return nil
end

local function FindMarker(stage: Instance, names: { string }): Instance?
	for _, name in ipairs(names) do
		local marker = stage:FindFirstChild(name, true)
		if marker and (marker:IsA("BasePart") or marker:IsA("Attachment")) then
			return marker
		end
	end
	return nil
end

local function EaseOutCubic(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return 1 - math.pow(1 - alpha, 3)
end

local function EaseInOutSine(alpha: number): number
	alpha = math.clamp(alpha, 0, 1)
	return -(math.cos(math.pi * alpha) - 1) * 0.5
end

local function GetFocusCFrame(stage: Instance, mainClone: Model?): CFrame
	if mainClone then
		local head = mainClone:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then
			return head.CFrame + Vector3.new(0, 0.5, 0)
		end

		local root = mainClone:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			return root.CFrame + Vector3.new(0, 2.8, 0)
		end

		local mainPivot = GetPivot(mainClone)
		if mainPivot then
			return mainPivot + Vector3.new(0, 2.8, 0)
		end
	end

	local stagePivot = GetPivot(stage)
	if stagePivot then
		return stagePivot + Vector3.new(0, 4.2, 0)
	end

	return CFrame.new(0, 4.2, 0)
end

local function GetTeamCenter(stage: Instance, runtimeFolder: Instance?, mainClone: Model?): Vector3
	local minBound: Vector3? = nil
	local maxBound: Vector3? = nil

	local function includePart(part: BasePart)
		if part.Name == "HumanoidRootPart" then
			return
		end
		local position = part.Position
		if not minBound then
			minBound = position
			maxBound = position
			return
		end
		minBound = Vector3.new(
			math.min((minBound :: Vector3).X, position.X),
			math.min((minBound :: Vector3).Y, position.Y),
			math.min((minBound :: Vector3).Z, position.Z)
		)
		maxBound = Vector3.new(
			math.max((maxBound :: Vector3).X, position.X),
			math.max((maxBound :: Vector3).Y, position.Y),
			math.max((maxBound :: Vector3).Z, position.Z)
		)
	end

	if runtimeFolder then
		for _, descendant in ipairs(runtimeFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				includePart(descendant)
			end
		end
	end

	if minBound and maxBound then
		return ((minBound :: Vector3) + (maxBound :: Vector3)) * 0.5 + Vector3.new(0, 1.8, 0)
	end

	local focus = GetFocusCFrame(stage, mainClone)
	return focus.Position
end

local function GetTrophyFocusPosition(mainClone: Model?, fallback: Vector3): Vector3
	if not mainClone then
		return fallback
	end

	local trophy = mainClone:FindFirstChild("ChampionTrophy", true)
	local trophyCFrame = GetPivot(trophy)
	if trophyCFrame then
		return trophyCFrame.Position + Vector3.new(0, 0.55, 0)
	end

	local hand = mainClone:FindFirstChild("RightHand", true)
	if hand and hand:IsA("BasePart") then
		return hand.Position + Vector3.new(0, 0.65, 0)
	end

	return fallback
end

local function CreateFade(gui: ScreenGui): Frame
	local fade = gui:FindFirstChild(FADE_NAME)
	if not (fade and fade:IsA("Frame")) then
		fade = Instance.new("Frame")
		fade.Name = FADE_NAME
		fade.AnchorPoint = Vector2.new(0.5, 0.5)
		fade.Position = UDim2.fromScale(0.5, 0.5)
		fade.Size = UDim2.fromScale(1, 1)
		fade.BorderSizePixel = 0
		fade.BackgroundColor3 = Color3.new(0, 0, 0)
		fade.ZIndex = 1000
		fade.Parent = gui
	end
	fade.Visible = true
	fade.BackgroundTransparency = 0
	return fade :: Frame
end

local function CreateEmitterAnchor(parent: Instance, cframe: CFrame): BasePart
	local part = Instance.new("Part")
	part.Name = "ChampionParticleAnchor"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function ConfigureConfetti(parent: Instance, burst: number, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ChampionConfetti"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 232, 90)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(88, 200, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 88, 126)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.4, 0.42),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.75, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(3.8, 5.3)
	emitter.Speed = NumberRange.new(7, 17)
	emitter.Acceleration = Vector3.new(0, -14, 0)
	emitter.Drag = 3
	emitter.Rate = rate
	emitter.SpreadAngle = Vector2.new(65, 65)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.LightEmission = 0.35
	emitter.Enabled = true
	emitter.Parent = parent
	emitter:Emit(burst)
	return emitter
end

local function ConfigureGoldDust(parent: Instance, burst: number, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ChampionGoldDust"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 218, 90), Color3.fromRGB(255, 255, 210))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.55, 0.2),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(0.65, 0.24),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(2.4, 4.2)
	emitter.Speed = NumberRange.new(3, 9)
	emitter.Acceleration = Vector3.new(0, -4, 0)
	emitter.Drag = 1.6
	emitter.Rate = rate
	emitter.SpreadAngle = Vector2.new(130, 70)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-80, 80)
	emitter.LightEmission = 0.85
	emitter.Enabled = true
	emitter.Parent = parent
	emitter:Emit(burst)
	return emitter
end

local function ConfigureTrophySparkle(parent: Instance, burst: number, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ChampionTrophySparkle"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 244, 150), Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.72),
		NumberSequenceKeypoint.new(0.5, 0.36),
		NumberSequenceKeypoint.new(1, 0.0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.55, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.0, 1.8)
	emitter.Speed = NumberRange.new(2, 6)
	emitter.Acceleration = Vector3.new(0, 3, 0)
	emitter.Drag = 0.7
	emitter.Rate = rate
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-100, 100)
	emitter.LightEmission = 1
	emitter.Enabled = true
	emitter.Parent = parent
	emitter:Emit(burst)
	return emitter
end

function ChampionCeremonyCinematicDirector.new()
	local self = setmetatable({}, ChampionCeremonyCinematicDirector)
	self._tweens = {}
	self._connections = {}
	self._objects = {}
	self._blur = nil
	self._createdBlur = false
	self._originalBlurSize = nil
	self._dof = nil
	self._createdDof = false
	self._originalDofState = nil
	self._originalFov = nil
	self._running = false
	return self
end

function ChampionCeremonyCinematicDirector:_trackTween(tween: Tween)
	table.insert(self._tweens, tween)
	tween:Play()
	return tween
end

function ChampionCeremonyCinematicDirector:_ensureBlur(): BlurEffect
	local existing = Lighting:FindFirstChild(BLUR_NAME)
	if existing and existing:IsA("BlurEffect") then
		self._createdBlur = false
		self._originalBlurSize = existing.Size
		self._blur = existing
		return existing
	end

	local blur = Instance.new("BlurEffect")
	blur.Name = BLUR_NAME
	blur.Size = 0
	blur.Parent = Lighting
	self._createdBlur = true
	self._originalBlurSize = 0
	self._blur = blur
	return blur
end

function ChampionCeremonyCinematicDirector:_ensureDepthOfField(): DepthOfFieldEffect
	local existing = Lighting:FindFirstChild(DOF_NAME)
	if existing and existing:IsA("DepthOfFieldEffect") then
		self._createdDof = false
		self._originalDofState = {
			Enabled = existing.Enabled,
			FocusDistance = existing.FocusDistance,
			InFocusRadius = existing.InFocusRadius,
			NearIntensity = existing.NearIntensity,
			FarIntensity = existing.FarIntensity,
		}
		self._dof = existing
		return existing
	end

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = DOF_NAME
	dof.Enabled = true
	dof.FocusDistance = 16
	dof.InFocusRadius = 18
	dof.NearIntensity = 0
	dof.FarIntensity = 0
	dof.Parent = Lighting
	self._createdDof = true
	self._originalDofState = nil
	self._dof = dof
	return dof
end

local function ApplyDepthOfField(
	dof: DepthOfFieldEffect?,
	cameraPosition: Vector3,
	focusPosition: Vector3,
	inFocusRadius: number,
	nearIntensity: number,
	farIntensity: number
)
	if not dof then
		return
	end

	dof.Enabled = farIntensity > 0.015 or nearIntensity > 0.015
	dof.FocusDistance = math.clamp((cameraPosition - focusPosition).Magnitude, 4, 220)
	dof.InFocusRadius = math.clamp(inFocusRadius, 2.5, 45)
	dof.NearIntensity = math.clamp(nearIntensity, 0, 1)
	dof.FarIntensity = math.clamp(farIntensity, 0, 1)
end

function ChampionCeremonyCinematicDirector:_playBlurAndFade(gui: ScreenGui, title: TextLabel?)
	local fade = CreateFade(gui)
	table.insert(self._objects, fade)

	local blur = self:_ensureBlur()
	blur.Size = 34

	if title then
		title.Visible = true
		title.TextTransparency = 1
		title.TextStrokeTransparency = 1
		title.Size = UDim2.fromScale(0.84, 0.13)
		UIJuice.SetScale(title, 0.78)
	end

	self:_trackTween(TweenService:Create(
		fade,
		TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	))

	self:_trackTween(TweenService:Create(
		blur,
		TweenInfo.new(1.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = 0 }
	))

	if title then
		task.delay(TITLE_POP_DELAY_SECONDS, function()
			if not self._running or not title.Parent then
				return
			end
			UIJuice.PopIn(title, {
				StartScale = 0.66,
				OvershootScale = 1.10,
				Duration = 0.20,
				SettleDuration = 0.22,
			})
			self:_trackTween(TweenService:Create(
				title,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					TextTransparency = 0,
					TextStrokeTransparency = 0.22,
				}
			))
		end)

		task.delay(TITLE_POP_DELAY_SECONDS + TITLE_VISIBLE_SECONDS, function()
			if not self._running or not title.Parent then
				return
			end

			UIJuice.PopOut(title, {
				Duration = TITLE_OUT_SECONDS,
				EndScale = 0.86,
			})
			self:_trackTween(TweenService:Create(
				title,
				TweenInfo.new(TITLE_OUT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				}
			))
		end)
	end
end

function ChampionCeremonyCinematicDirector:_playCamera(
	stage: Instance,
	runtimeFolder: Instance?,
	mainClone: Model?,
	durationSeconds: number?
)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	self._originalFov = camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable

	local focusCFrame = GetFocusCFrame(stage, mainClone)
	local teamCenter = GetTeamCenter(stage, runtimeFolder, mainClone)
	local lookAtClose = focusCFrame.Position + Vector3.new(0, 0.15, 0)
	local lookAtWide = teamCenter + Vector3.new(0, 1.4, 0)
	local lookAtFinal = focusCFrame.Position + Vector3.new(0, 0.95, 0)

	local marker = FindMarker(stage, {
		"ChampionCamera",
		"ChampionCameraPoint",
		"CameraPoint",
		"CameraPosition",
		"CameraPivot",
		"Camera",
	})

	local forward = focusCFrame.LookVector
	if forward.Magnitude < 0.1 then
		forward = Vector3.new(0, 0, -1)
	end
	forward = forward.Unit
	local side = forward:Cross(Vector3.yAxis)
	if side.Magnitude < 0.1 then
		side = Vector3.xAxis
	else
		side = side.Unit
	end

	local closePosition = focusCFrame.Position + forward * 8.2 + Vector3.new(0, 4.0, 0) - side * 0.35
	local frontalWidePosition = teamCenter + forward * 36 + Vector3.new(0, 12.5, 0) + side * 1.2
	local widePosition = frontalWidePosition
	local finalPosition = focusCFrame.Position + forward * 16.0 + Vector3.new(0, 4.7, 0)

	if marker then
		local markerCFrame = GetPivot(marker)
		if markerCFrame then
			-- Keep artist marker as the mid-shot direction, then end straight on the main player.
			local markerWidePosition = markerCFrame.Position + markerCFrame.LookVector * -10 + Vector3.new(0, 2.5, 0)
			widePosition = frontalWidePosition:Lerp(markerWidePosition, 0.22)
			closePosition = focusCFrame.Position + (widePosition - focusCFrame.Position).Unit * 8.0 + Vector3.new(0, 2.4, 0)
		end
	end

	local trophyLookFallback = focusCFrame.Position + Vector3.new(0, 3.7, 0)
	local closeVector = closePosition - lookAtClose
	if closeVector.Magnitude < 0.1 then
		closeVector = forward * 8.0 + Vector3.new(0, 2.4, 0)
	end
	local closeDirection = closeVector.Unit
	local closeDistance = closeVector.Magnitude
	local midDollyStartPosition = lookAtClose + closeDirection * (closeDistance + 8.4) + Vector3.new(0, 0.7, 0)
	local dollyClosePosition = lookAtClose + closeDirection * math.max(closeDistance - 1.2, 5.8)
	local initialTrophyLookAt = GetTrophyFocusPosition(mainClone, trophyLookFallback)
	local initialMidLookAt = lookAtClose:Lerp(initialTrophyLookAt, 0.55)

	camera.CFrame = CFrame.lookAt(midDollyStartPosition, initialMidLookAt)
	camera.FieldOfView = 42
	local dof = self:_ensureDepthOfField()
	ApplyDepthOfField(dof, midDollyStartPosition, initialMidLookAt, 8.5, 0.03, 0.2)

	local startTime = os.clock()
	local ceremonyDuration = math.max(tonumber(durationSeconds) or 20, 8)
	local duration = math.clamp(ceremonyDuration - 1.2, 8, 18.8)
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if not self._running then
			connection:Disconnect()
			return
		end

		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local position: Vector3
		local lookAt: Vector3
		local fov: number
		local dofRadius: number
		local dofNear: number
		local dofFar: number

		if alpha < 0.23 then
			local segmentAlpha = EaseInOutSine(alpha / 0.23)
			local trophyLookAt = GetTrophyFocusPosition(mainClone, trophyLookFallback)
			local midLookAt = lookAtClose:Lerp(trophyLookAt, 0.55)
			local closeDollyLookAt = trophyLookAt:Lerp(lookAtClose, 0.25)
			position = midDollyStartPosition:Lerp(dollyClosePosition, segmentAlpha)
			lookAt = midLookAt:Lerp(closeDollyLookAt, segmentAlpha)
			fov = 42 + (54 - 42) * segmentAlpha
			dofRadius = 8.5 + (4.2 - 8.5) * segmentAlpha
			dofNear = 0.03 + 0.06 * segmentAlpha
			dofFar = 0.2 + 0.42 * segmentAlpha
		elseif alpha < 0.34 then
			local followAlpha = EaseInOutSine((alpha - 0.23) / 0.11)
			local trophyLookAt = GetTrophyFocusPosition(mainClone, trophyLookFallback)
			local followLookAt = trophyLookAt:Lerp(lookAtClose, 0.18)
			local followPosition = trophyLookAt + closeDirection * math.max(closeDistance - 1.2, 5.8)
			local liftDrift = Vector3.new(0, math.sin(followAlpha * math.pi) * 0.35, 0)
			position = dollyClosePosition:Lerp(followPosition, 0.72) + liftDrift
			lookAt = followLookAt
			fov = 54 - 2 * followAlpha
			dofRadius = 4.0
			dofNear = 0.1
			dofFar = 0.66
		elseif alpha < 0.58 then
			local segmentAlpha = EaseOutCubic((alpha - 0.34) / 0.24)
			local trophyLookAt = GetTrophyFocusPosition(mainClone, trophyLookFallback)
			local followLookAt = trophyLookAt:Lerp(lookAtClose, 0.18)
			local followPosition = trophyLookAt + closeDirection * math.max(closeDistance - 1.2, 5.8)
			local zoomOutStartPosition = dollyClosePosition:Lerp(followPosition, 0.72)
			position = zoomOutStartPosition:Lerp(widePosition, segmentAlpha)
			lookAt = followLookAt:Lerp(lookAtWide, segmentAlpha)
			fov = 52 + (64 - 52) * segmentAlpha
			dofRadius = 5 + (20 - 5) * segmentAlpha
			dofNear = 0.09 * (1 - segmentAlpha)
			dofFar = 0.12 + 0.5 * (1 - segmentAlpha)
		elseif alpha < 0.74 then
			local holdAlpha = EaseInOutSine((alpha - 0.58) / 0.16)
			local drift = side * math.sin(holdAlpha * math.pi) * 0.8 + Vector3.new(0, math.sin(holdAlpha * math.pi * 2) * 0.7, 0)
			position = widePosition + drift
			lookAt = lookAtWide:Lerp(lookAtFinal, holdAlpha * 0.35)
			fov = 64 - 4 * holdAlpha
			dofRadius = 24
			dofNear = 0.02 * (1 - holdAlpha)
			dofFar = 0.08 * (1 - holdAlpha)
		else
			local segmentAlpha = EaseInOutSine((alpha - 0.74) / 0.26)
			position = widePosition:Lerp(finalPosition, segmentAlpha)
			lookAt = lookAtWide:Lerp(lookAtFinal, segmentAlpha)
			fov = 60 + (46 - 60) * segmentAlpha
			dofRadius = 22 + (9 - 22) * segmentAlpha
			dofNear = 0.02 + 0.03 * segmentAlpha
			dofFar = 0.06 + 0.22 * segmentAlpha
		end

		camera.CFrame = CFrame.lookAt(position, lookAt)
		camera.FieldOfView = fov
		ApplyDepthOfField(dof, position, lookAt, dofRadius, dofNear, dofFar)

		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
	table.insert(self._connections, connection)
end

function ChampionCeremonyCinematicDirector:_playParticles(stage: Instance, runtimeFolder: Instance?, mainClone: Model?, areaId: any)
	local intensity = VfxConfig.GetIntensity(areaId)
	local focusCFrame = GetFocusCFrame(stage, mainClone)
	local teamCenter = GetTeamCenter(stage, runtimeFolder, mainClone)
	local radius = intensity.AnchorRadius or 17
	local height = intensity.AnchorHeight or 12
	local lifetime = intensity.EmitterLifetime or 5.8

	local folder = Instance.new("Folder")
	folder.Name = PARTICLE_FOLDER_NAME
	folder.Parent = stage
	table.insert(self._objects, folder)

	local left = CreateEmitterAnchor(folder, CFrame.new(teamCenter + Vector3.new(-radius, height, -2)))
	local right = CreateEmitterAnchor(folder, CFrame.new(teamCenter + Vector3.new(radius, height, -2)))
	local center = CreateEmitterAnchor(folder, CFrame.new(teamCenter + Vector3.new(0, height + 2, 0)))
	local trophy = CreateEmitterAnchor(folder, CFrame.new(focusCFrame.Position + Vector3.new(0, 3.8, 0)))

	ConfigureConfetti(left, math.floor((intensity.ConfettiBurst or 120) * 0.5), math.floor((intensity.ConfettiRate or 32) * 0.55))
	ConfigureConfetti(right, math.floor((intensity.ConfettiBurst or 120) * 0.5), math.floor((intensity.ConfettiRate or 32) * 0.55))
	ConfigureGoldDust(center, intensity.GoldDustBurst or 60, intensity.GoldDustRate or 18)
	ConfigureTrophySparkle(trophy, intensity.SparkleBurst or 44, intensity.SparkleRate or 18)

	task.delay(1.35, function()
		if not self._running or not folder.Parent then
			return
		end
		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant:Emit(math.max(10, math.floor((descendant.Rate :: number) * 1.6)))
			end
		end
	end)

	task.delay(lifetime, function()
		if not folder.Parent then
			return
		end
		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
	end)
end

function ChampionCeremonyCinematicDirector:Play(args: {
	Stage: Instance,
	RuntimeFolder: Instance?,
	MainClone: Model?,
	Gui: ScreenGui?,
	Title: TextLabel?,
	AreaId: any?,
	DurationSeconds: number?,
})
	self:Cleanup()
	self._running = true

	local stage = args.Stage
	local gui = args.Gui
	local title = args.Title

	if gui then
		self:_playBlurAndFade(gui, title)
	else
		local blur = self:_ensureBlur()
		blur.Size = 34
		self:_trackTween(TweenService:Create(
			blur,
			TweenInfo.new(1.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = 0 }
		))
	end

	self:_playCamera(stage, args.RuntimeFolder, args.MainClone, args.DurationSeconds)
	self:_playParticles(stage, args.RuntimeFolder, args.MainClone, args.AreaId)
end

function ChampionCeremonyCinematicDirector:Cleanup()
	self._running = false

	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for _, tween in ipairs(self._tweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(self._tweens)

	for _, object in ipairs(self._objects) do
		if object and object.Parent then
			object:Destroy()
		end
	end
	table.clear(self._objects)

	if self._blur then
		if self._createdBlur then
			self._blur:Destroy()
		else
			self._blur.Size = self._originalBlurSize or 0
		end
	end
	self._blur = nil
	self._createdBlur = false
	self._originalBlurSize = nil

	if self._dof then
		if self._createdDof then
			self._dof:Destroy()
		elseif self._originalDofState then
			self._dof.Enabled = self._originalDofState.Enabled
			self._dof.FocusDistance = self._originalDofState.FocusDistance
			self._dof.InFocusRadius = self._originalDofState.InFocusRadius
			self._dof.NearIntensity = self._originalDofState.NearIntensity
			self._dof.FarIntensity = self._originalDofState.FarIntensity
		end
	end
	self._dof = nil
	self._createdDof = false
	self._originalDofState = nil

	local camera = Workspace.CurrentCamera
	if camera and self._originalFov then
		camera.FieldOfView = self._originalFov
	end
	self._originalFov = nil
end

function ChampionCeremonyCinematicDirector:Destroy()
	self:Cleanup()
end

return ChampionCeremonyCinematicDirector
