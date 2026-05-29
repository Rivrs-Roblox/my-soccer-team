local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)
local MatchBallConfig = require(script.Parent.Parent.Config.Match.MatchBallConfig)

local MATCH_RUNTIME_FOLDER_NAME = "Runtime"
local MATCH_BALL_RUNTIME_NAME = "LocalMatchBall"

local MatchBallController = Knit.CreateController({
	Name = "MatchBallController",

	BallInstance = nil,
	BallDriverPart = nil,
	BallVisualPart = nil,
	BallVisualLocalCFrame = nil,
	SpecialEffectsRoot = nil,
	EffectGroupRoots = nil,
	BallHomeCFrame = nil,
	BallOriginalTransparency = {},
	HiddenWorldBallParts = {},
	SpinAngle = 0,

	ActiveMotionToken = 0,
	MotionConnection = nil,

	SessionVersion = 0,
	StepVersion = 0,
	CurrentStepIndex = 0,
	CurrentFollowActor = nil,
	LastFollowLookVector = nil,
	ActionSpecialEffectsUntil = 0,
})

local function DisconnectConnection(connection)
	if connection then
		connection:Disconnect()
	end
	return nil
end

local function ForEachBasePart(root, callback)
	if not root or type(callback) ~= "function" then
		return
	end

	if root:IsA("BasePart") then
		callback(root)
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			callback(descendant)
		end
	end
end

local function IsWorldBallCandidate(part: BasePart): boolean
	if not part or not part:IsA("BasePart") then
		return false
	end

	if part.Name == MATCH_BALL_RUNTIME_NAME or part:FindFirstAncestor(MATCH_BALL_RUNTIME_NAME) then
		return false
	end

	local loweredName = string.lower(part.Name)
	local parentName = part.Parent and string.lower(part.Parent.Name) or ""

	return loweredName == "football"
		or loweredName == "ball"
		or loweredName == "matchball"
		or loweredName == "soccerball"
		or parentName == "football"
		or parentName == "ball"
		or parentName == "ballarea"
end

local function GetRootPart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		local hrp = instance:FindFirstChild("HumanoidRootPart", true)
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end

		if instance.PrimaryPart and instance.PrimaryPart:IsA("BasePart") then
			return instance.PrimaryPart
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	if instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function ApplyPivot(instance, targetCFrame)
	if not instance or not targetCFrame then
		return
	end

	if instance:IsA("Model") then
		instance:PivotTo(targetCFrame)
	elseif instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
	end
end

local function PlayBallBounceSound(parent)
	local ok, sound = pcall(function()
		return Sound:PlaySound("BallBounce", parent)
	end)

	if ok and sound then
		return
	end

	pcall(function()
		Sound:PlaySound("Shoot", parent)
	end)
end

local function BuildLookCFrame(position: Vector3, lookTarget: Vector3, fallbackLookVector: Vector3?): CFrame
	local delta = lookTarget - position
	if delta.Magnitude <= 0.001 then
		local fallback = fallbackLookVector or Vector3.new(0, 0, -1)
		return CFrame.lookAt(position, position + fallback)
	end

	return CFrame.lookAt(position, lookTarget)
end

local function SetEffectEnabled(root, enabled: boolean)
	if not root then
		return
	end

	local enabledFlag = enabled == true

	local function setOne(instance)
		if instance:IsA("Trail") or instance:IsA("ParticleEmitter") or instance:IsA("Beam") then
			instance.Enabled = enabledFlag
		elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			instance.Enabled = enabledFlag
		end
	end

	setOne(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		setOne(descendant)
	end
end

local function EmitEffectGroup(root, emitCount: number?)
	if not root then
		return 0
	end

	local emitted = 0
	local count = math.max(math.floor(tonumber(emitCount) or 24), 1)

	local function emitOne(instance)
		if instance:IsA("ParticleEmitter") then
			instance.Enabled = true
			instance:Emit(count)
			emitted += 1
		elseif instance:IsA("Trail") or instance:IsA("Beam") then
			instance.Enabled = true
		elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
			instance.Enabled = true
		end
	end

	emitOne(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		emitOne(descendant)
	end

	return emitted
end

function MatchBallController:GetBallPosition(): Vector3?
	if self.BallDriverPart and self.BallDriverPart.Parent then
		return self.BallDriverPart.Position
	end

	if self.BallInstance and self.BallInstance.Parent then
		return self.BallInstance:GetPivot().Position
	end

	return nil
end

function MatchBallController:_getBattleZoneRoot()
	local map = Workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("BattleZone") or nil
end

function MatchBallController:_getRuntimeFolder()
	local battleZoneRoot = self:_getBattleZoneRoot()
	if not battleZoneRoot then
		return nil
	end

	local runtimeFolder = battleZoneRoot:FindFirstChild(MATCH_RUNTIME_FOLDER_NAME)
	if runtimeFolder then
		return runtimeFolder
	end

	runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = MATCH_RUNTIME_FOLDER_NAME
	runtimeFolder.Parent = battleZoneRoot
	return runtimeFolder
end

function MatchBallController:_getBallHomeMarker()
	local battleZoneRoot = self:_getBattleZoneRoot()
	if not battleZoneRoot then
		return nil
	end

	return battleZoneRoot:FindFirstChild("BallArea")
end

function MatchBallController:_setWorldBallVisualsHidden(hidden: boolean)
	local battleZoneRoot = self:_getBattleZoneRoot()
	if not battleZoneRoot then
		return
	end

	if hidden then
		for _, descendant in ipairs(battleZoneRoot:GetDescendants()) do
			if descendant:IsA("BasePart") and IsWorldBallCandidate(descendant) then
				if self.BallInstance and descendant:IsDescendantOf(self.BallInstance) then
					continue
				end

				if self.HiddenWorldBallParts[descendant] == nil then
					self.HiddenWorldBallParts[descendant] = {
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
			end
		end
		return
	end

	for part, original in pairs(self.HiddenWorldBallParts) do
		if part and part.Parent and original then
			part.Transparency = original.Transparency
			part.LocalTransparencyModifier = original.LocalTransparencyModifier

			-- Keep authored battle balls harmless after match cleanup.
			-- Restoring collision here can make the ball physically wedge into actors or props.
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	table.clear(self.HiddenWorldBallParts)
end

function MatchBallController:_cleanupDuplicateGeneratedBalls(activeInstance)
	local runtimeFolder = self:_getRuntimeFolder()
	if not runtimeFolder then
		return
	end

	for _, child in ipairs(runtimeFolder:GetChildren()) do
		if child.Name == MATCH_BALL_RUNTIME_NAME and child ~= activeInstance then
			child:Destroy()
		end
	end
end

function MatchBallController:_buildSpinningCFrame(position: Vector3, lookTarget: Vector3, fallbackLookVector: Vector3?, spinDelta: number?): CFrame
	self.SpinAngle = (self.SpinAngle + (spinDelta or 0)) % (math.pi * 2)

	-- Return only the root trajectory CFrame. The visual mesh spin is applied separately in _applyVisualSpin().
	-- This keeps artist-authored SpecialEffects stable instead of rotating the whole effect rig.
	return BuildLookCFrame(position, lookTarget, fallbackLookVector)
end

function MatchBallController:_cacheBallHomeCFrame()
	local homeMarker = self:_getBallHomeMarker()
	if homeMarker and homeMarker:IsA("BasePart") then
		self.BallHomeCFrame = homeMarker.CFrame
	elseif self.BallInstance and self.BallInstance.Parent then
		self.BallHomeCFrame = self.BallInstance:GetPivot()
	end
end

function MatchBallController:_getBallTemplate()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets and assets:FindFirstChild("MatchBallTemplate") then
		return assets.MatchBallTemplate
	end

	return ReplicatedStorage:FindFirstChild("MatchBallTemplate", true)
end

function MatchBallController:_resolveDriverPart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	local explicitPivot = instance:FindFirstChild("Pivot", true)
	if explicitPivot and explicitPivot:IsA("BasePart") then
		return explicitPivot
	end

	if explicitPivot and explicitPivot:IsA("Model") then
		if explicitPivot.PrimaryPart and explicitPivot.PrimaryPart:IsA("BasePart") then
			return explicitPivot.PrimaryPart
		end

		local pivotPart = explicitPivot:FindFirstChildWhichIsA("BasePart", true)
		if pivotPart then
			return pivotPart
		end
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart and instance.PrimaryPart:IsA("BasePart") then
			return instance.PrimaryPart
		end

		local football = instance:FindFirstChild("Football", true)
		if football and football:IsA("BasePart") then
			return football
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function MatchBallController:_resolveVisualMeshPart(instance, driverPart)
	if not instance then
		return driverPart
	end

	local meshPart = instance:FindFirstChild("Mesh", true)
	if meshPart and meshPart:IsA("BasePart") then
		return meshPart
	end

	local ballPart = instance:FindFirstChild("Ball", true)
	if ballPart and ballPart:IsA("BasePart") then
		return ballPart
	end

	return driverPart
end

function MatchBallController:_resolveSpecialEffectsRoot(instance)
	if not instance then
		return nil
	end

	return instance:FindFirstChild("SpecialEffects", true)
end

function MatchBallController:_resolveEffectGroup(instance, groupName: string)
	if not instance or type(groupName) ~= "string" or groupName == "" then
		return nil
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant.Name == groupName then
			-- Do not treat the artist-authored ball mesh trail as a runtime special-shot group.
			-- It may live at MatchBallTemplate/Pivot/Mesh/Trail and should keep its authored state.
			if groupName == "Trail" and descendant:IsA("Trail") then
				local parentName = string.lower(tostring(descendant.Parent and descendant.Parent.Name or ""))
				if parentName == "mesh" then
					continue
				end
			end

			return descendant
		end
	end

	return nil
end

function MatchBallController:_cacheEffectGroups(instance)
	self.EffectGroupRoots = {
		Trail = self:_resolveEffectGroup(instance, "Trail"),
		SpecialEffects = self:_resolveEffectGroup(instance, "SpecialEffects"),
		HoldEffects = self:_resolveEffectGroup(instance, "HoldEffects"),
		ExplodeEffects = self:_resolveEffectGroup(instance, "ExplodeEffects"),
	}
	self.SpecialEffectsRoot = self.EffectGroupRoots.SpecialEffects
end

function MatchBallController:_getEffectGroup(groupName: string)
	if not self.BallInstance then
		return nil
	end

	if type(self.EffectGroupRoots) ~= "table" then
		self:_cacheEffectGroups(self.BallInstance)
	end

	local cached = self.EffectGroupRoots and self.EffectGroupRoots[groupName]
	if cached and cached.Parent then
		return cached
	end

	local resolved = self:_resolveEffectGroup(self.BallInstance, groupName)
	self.EffectGroupRoots = self.EffectGroupRoots or {}
	self.EffectGroupRoots[groupName] = resolved
	return resolved
end

function MatchBallController:_setEffectGroupEnabled(groupName: string, enabled: boolean)
	SetEffectEnabled(self:_getEffectGroup(groupName), enabled == true)
end

function MatchBallController:_emitEffectGroup(groupName: string, emitCount: number?)
	return EmitEffectGroup(self:_getEffectGroup(groupName), emitCount)
end

function MatchBallController:_disableAllTemplateShotEffects()
	self:_setEffectGroupEnabled("Trail", false)
	self:_setEffectGroupEnabled("SpecialEffects", false)
	self:_setEffectGroupEnabled("HoldEffects", false)
	self:_setEffectGroupEnabled("ExplodeEffects", false)
end

function MatchBallController:_cacheOriginalTransparency()
	self.BallOriginalTransparency = {}

	if not self.BallInstance then
		return
	end

	ForEachBasePart(self.BallInstance, function(part)
		self.BallOriginalTransparency[part] = part.Transparency
	end)
end

function MatchBallController:_setBallVisible(isVisible: boolean)
	if not self.BallInstance or not self.BallInstance.Parent then
		return
	end

	if isVisible ~= true then
		self:_setTemplateSpecialEffectsEnabled(false)
	end

	ForEachBasePart(self.BallInstance, function(part)
		if isVisible then
			part.Transparency = self.BallOriginalTransparency[part] or 0
			part.LocalTransparencyModifier = 0
		else
			part.Transparency = 1
			part.LocalTransparencyModifier = 1
		end
	end)
end

function MatchBallController:_prepareBallInstance(instance)
	ForEachBasePart(instance, function(part)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)

	-- Force-disable any non-SpecialEffects trails initially so they do not show the ugly white streak.
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Trail") then
			local inSpecialEffects = descendant:FindFirstAncestor("SpecialEffects") ~= nil
			if not inSpecialEffects then
				descendant.Enabled = false
			end
		end
	end
end

function MatchBallController:_setTemplateSpecialEffectsEnabled(enabled: boolean)
	self:_setEffectGroupEnabled("SpecialEffects", enabled == true)
end

function MatchBallController:_setShotFlightEffectsEnabled(enabled: boolean)
	self:_setEffectGroupEnabled("Trail", false) -- Force off the ugly white trail group
	self:_setEffectGroupEnabled("SpecialEffects", enabled == true)
end

function MatchBallController:SetHoldEffectEnabled(enabled: boolean)
	self:_spawnBallIfNeeded()
	self:_setEffectGroupEnabled("HoldEffects", enabled == true)
	if enabled == true then
		self:_emitEffectGroup("HoldEffects", MatchBallConfig.HoldEffectEmitCount or 18)
	end
end

function MatchBallController:PlayImpactEffect(_worldPosition: Vector3?, options)
	options = options or {}
	self:_spawnBallIfNeeded()

	local emitCount = tonumber(options.EmitCount or options.ImpactEmitCount) or (MatchBallConfig.GoalFx and MatchBallConfig.GoalFx.EmitCount) or 24
	self:_setEffectGroupEnabled("ExplodeEffects", true)
	self:_emitEffectGroup("ExplodeEffects", emitCount)

	local lifetime = math.max(tonumber(options.Lifetime or options.ImpactLifetime) or 0.62, 0.05)
	task.delay(lifetime, function()
		if self.BallInstance and self.BallInstance.Parent then
			self:_setEffectGroupEnabled("ExplodeEffects", false)
		end
	end)
end

function MatchBallController:_shouldKeepActionSpecialEffects(): boolean
	return type(self.ActionSpecialEffectsUntil) == "number" and os.clock() < self.ActionSpecialEffectsUntil
end

function MatchBallController:ActivateActionSpecialEffects(duration: number?)
	local activeDuration = math.max(tonumber(duration) or 1.25, 0.05)
	self.ActionSpecialEffectsUntil = math.max(tonumber(self.ActionSpecialEffectsUntil) or 0, os.clock() + activeDuration)

	self:_spawnBallIfNeeded()
	self:_setTemplateSpecialEffectsEnabled(true)

	local expireAt = self.ActionSpecialEffectsUntil
	task.delay(activeDuration + 0.03, function()
		if self.ActionSpecialEffectsUntil == expireAt and not self:_shouldKeepActionSpecialEffects() then
			self:_setTemplateSpecialEffectsEnabled(false)
		end
	end)
end

function MatchBallController:DeactivateActionSpecialEffects()
	self.ActionSpecialEffectsUntil = 0
	self:_setTemplateSpecialEffectsEnabled(false)
end

function MatchBallController:_applyVisualSpin()
	local driverPart = self.BallDriverPart
	local visualPart = self.BallVisualPart

	if not driverPart or not driverPart.Parent or not visualPart or not visualPart.Parent then
		return
	end

	if visualPart == driverPart then
		return
	end

	local localCFrame = self.BallVisualLocalCFrame or CFrame.identity
	visualPart.CFrame = driverPart.CFrame * localCFrame * CFrame.Angles(self.SpinAngle, 0, 0)
end

function MatchBallController:_applyWholeBallSpinIfNeeded(targetCFrame: CFrame, spinWhileHeld: boolean?): CFrame
	-- Some artist templates use the Mesh itself as the runtime driver. In that hierarchy
	-- mesh-only spin is impossible, so we rotate the whole ball while it is being held.
	-- This keeps the breakthrough contact visually strong instead of looking like a static prop.
	if spinWhileHeld == true and self.BallVisualPart and self.BallDriverPart and self.BallVisualPart == self.BallDriverPart then
		return targetCFrame * CFrame.Angles(self.SpinAngle, 0, 0)
	end

	return targetCFrame
end

function MatchBallController:_spawnBallIfNeeded()
	if self.BallInstance and self.BallInstance.Parent and self.BallDriverPart and self.BallDriverPart.Parent then
		self:_setWorldBallVisualsHidden(true)
		self:_cleanupDuplicateGeneratedBalls(self.BallInstance)
		return self.BallDriverPart
	end

	local template = self:_getBallTemplate()
	local runtimeFolder = self:_getRuntimeFolder()

	if not template or not runtimeFolder then
		warn("[MatchBallController] Missing MatchBallTemplate or Runtime folder.")
		return nil
	end

	local clone = template:Clone()
	clone.Name = MATCH_BALL_RUNTIME_NAME
	clone.Parent = runtimeFolder
	self:_cleanupDuplicateGeneratedBalls(clone)
	self:_setWorldBallVisualsHidden(true)

	local driverPart = self:_resolveDriverPart(clone)
	if not driverPart then
		clone:Destroy()
		warn("[MatchBallController] Failed to resolve ball driver part.")
		return nil
	end

	if clone:IsA("Model") and not clone.PrimaryPart then
		clone.PrimaryPart = driverPart
	end

	self.BallInstance = clone
	self.BallDriverPart = driverPart
	self.BallVisualPart = self:_resolveVisualMeshPart(clone, driverPart)
	self:_cacheEffectGroups(clone)

	self:_prepareBallInstance(clone)

	if self.BallVisualPart and self.BallVisualPart.Parent then
		self.BallVisualLocalCFrame = driverPart.CFrame:ToObjectSpace(self.BallVisualPart.CFrame)
	else
		self.BallVisualLocalCFrame = CFrame.identity
	end

	self:_cacheOriginalTransparency()
	self:_cacheBallHomeCFrame()
	self:_setBallVisible(true)
	self:_setTemplateSpecialEffectsEnabled(false)

	return self.BallDriverPart
end

function MatchBallController:_setTrailEnabled(_enabled: boolean)
	-- Manual script-created trails were removed. Special shot visuals are controlled by MatchBallTemplate/Pivot/SpecialEffects.
end

function MatchBallController:_resetTrail()
	-- Kept as a compatibility method for older pass/shoot code paths.
	self:_setTemplateSpecialEffectsEnabled(false)
end

function MatchBallController:_moveBallCFrame(targetCFrame: CFrame)
	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart or not targetCFrame then
		return
	end

	driverPart.AssemblyLinearVelocity = Vector3.zero
	driverPart.AssemblyAngularVelocity = Vector3.zero
	ApplyPivot(self.BallInstance, targetCFrame)
	self:_applyVisualSpin()
end

function MatchBallController:_stopMotion()
	self.ActiveMotionToken += 1
	self.MotionConnection = DisconnectConnection(self.MotionConnection)
end

function MatchBallController:_isMotionScopeCurrent(sessionVersion: number?, stepVersion: number?, motionToken: number?): boolean
	if motionToken ~= nil and motionToken ~= self.ActiveMotionToken then
		return false
	end

	if sessionVersion ~= nil and sessionVersion ~= self.SessionVersion then
		return false
	end

	if stepVersion ~= nil and stepVersion ~= self.StepVersion then
		return false
	end

	return true
end

function MatchBallController:_beginMotion(stepCallback)
	self:_stopMotion()

	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion

	self.MotionConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			self:_setTemplateSpecialEffectsEnabled(false)
			return
		end

		local keepRunning = stepCallback(deltaTime, motionToken, sessionVersion, stepVersion)
		if keepRunning == false and self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
		end
	end)

	return motionToken, sessionVersion, stepVersion
end

function MatchBallController:_resetBallPresentationState()
	self:_stopMotion()

	if self.BallInstance and self.BallInstance.Parent then
		self:_cleanupDuplicateGeneratedBalls(self.BallInstance)
		self:_setWorldBallVisualsHidden(true)
	end

	self.CurrentFollowActor = nil
	self.LastFollowLookVector = nil
	self:_setTrailEnabled(false)
	self:_resetTrail()
	self:_setEffectGroupEnabled("HoldEffects", false)
end

function MatchBallController:_playParabola(startPos: Vector3, endPos: Vector3, duration: number, arcHeight: number, options)
	self:_spawnBallIfNeeded()
	self:_setBallVisible(true)
	self:_resetTrail()
	local useActionEffects = options and (options.SpecialEffects == true or options.IsGreenAction == true or options.ActionSpecialEffects == true)
	if useActionEffects then
		self:ActivateActionSpecialEffects((options and options.EffectsDuration) or ((duration or 0.75) + 0.35))
	else
		self:_setTemplateSpecialEffectsEnabled(self:_shouldKeepActionSpecialEffects())
	end
	self.CurrentFollowActor = nil

	local travelDuration = math.max(duration or 0.75, 0.25)
	local height = math.max(arcHeight or 1.5, 0.35)
	local startedAt = os.clock()
	local fallbackLook = (endPos - startPos).Magnitude > 0.001 and (endPos - startPos).Unit or Vector3.new(0, 0, -1)
	local lastPosition = startPos

	self:_moveBallCFrame(self:_buildSpinningCFrame(startPos, startPos + fallbackLook, fallbackLook, 0))

	local motionToken
	motionToken = self:_beginMotion(function()
		local alpha = math.clamp((os.clock() - startedAt) / travelDuration, 0, 1)

		local flatPos = startPos:Lerp(endPos, alpha)
		local parabolaY = 4 * height * alpha * (1 - alpha)

		local lateralCurve = options and options.LateralCurve or 0
		if math.abs(lateralCurve) > 0.001 then
			local toTarget = Vector3.new(endPos.X - startPos.X, 0, endPos.Z - startPos.Z)
			if toTarget.Magnitude > 0.001 then
				local lateralDir = toTarget.Unit:Cross(Vector3.new(0, 1, 0))
				local curveAmount = 4 * lateralCurve * alpha * (1 - alpha)
				flatPos += lateralDir * curveAmount
			end
		end

		local currentPos = Vector3.new(flatPos.X, flatPos.Y + parabolaY, flatPos.Z)
		local nextAlpha = math.clamp(alpha + 0.03, 0, 1)
		local nextFlat = startPos:Lerp(endPos, nextAlpha)
		local nextParabolaY = 4 * height * nextAlpha * (1 - nextAlpha)

		if math.abs(lateralCurve) > 0.001 then
			local toTarget = Vector3.new(endPos.X - startPos.X, 0, endPos.Z - startPos.Z)
			if toTarget.Magnitude > 0.001 then
				local lateralDir = toTarget.Unit:Cross(Vector3.new(0, 1, 0))
				local curveAmount = 4 * lateralCurve * nextAlpha * (1 - nextAlpha)
				nextFlat += lateralDir * curveAmount
			end
		end

		local nextPos = Vector3.new(nextFlat.X, nextFlat.Y + nextParabolaY, nextFlat.Z)
		local spinDelta = (currentPos - lastPosition).Magnitude * 1.85
		lastPosition = currentPos
		self:_moveBallCFrame(self:_buildSpinningCFrame(currentPos, nextPos, fallbackLook, spinDelta))

		if alpha >= 1 then
			self:_moveBallCFrame(self:_buildSpinningCFrame(endPos, endPos + fallbackLook, fallbackLook, 0))

			if options and options.ResetToHome then
				task.delay(options.ResetDelay or 0.25, function()
					if motionToken == self.ActiveMotionToken then
						self:ResetToHome(true)
					end
				end)
			end

			return false
		end

		return true
	end)

	return motionToken
end

function MatchBallController:BeginMatchSession(options)
	options = options or {}
	self.SessionVersion += 1
	self.SpinAngle = 0
	self.StepVersion = 0
	self.CurrentStepIndex = 0
	self.ActionSpecialEffectsUntil = 0

	self:_spawnBallIfNeeded()
	self:_cacheBallHomeCFrame()
	self:_resetBallPresentationState()

	if self.BallHomeCFrame then
		self:_moveBallCFrame(self.BallHomeCFrame)
	end

	self:_setBallVisible(options.StartHidden ~= true)
	self:_setWorldBallVisualsHidden(true)
	self:_setTemplateSpecialEffectsEnabled(false)
end

function MatchBallController:EndMatchSession(options)
	options = options or {}
	self.ActionSpecialEffectsUntil = 0

	self:StopFollow()

	local endingSessionVersion = self.SessionVersion
	local function resetBallAndRestoreWorld()
		if self.SessionVersion ~= endingSessionVersion then
			return
		end

		if not self.BallInstance then
			return
		end

		self:ClearTrail()

		local ballArea = self:_getBallHomeMarker()
		if ballArea and ballArea:IsA("BasePart") then
			self:SetBallWorldPosition(ballArea.Position)
		elseif self.BallHomeCFrame then
			self:SetBallWorldPosition(self.BallHomeCFrame.Position)
		end

		self:_setWorldBallVisualsHidden(false)
	end

	if options.ResetMode == "DeferredSilent" then
		task.delay(options.ResetDelay or 0.35, resetBallAndRestoreWorld)
		return
	end

	resetBallAndRestoreWorld()
end

function MatchBallController:BeginPresentationStep(stepIndex: number)
	local numericStep = tonumber(stepIndex) or 0
	if self.CurrentStepIndex == numericStep then
		return
	end

	self.CurrentStepIndex = numericStep
	self.StepVersion += 1
	self.ActionSpecialEffectsUntil = 0
	self:_resetBallPresentationState()
end

function MatchBallController:ResetToHome(hideBeforeReset: boolean?)
	self:_spawnBallIfNeeded()
	self:_cacheBallHomeCFrame()

	if not self.BallHomeCFrame then
		return
	end

	self:_stopMotion()
	self.CurrentFollowActor = nil
	self:_setTemplateSpecialEffectsEnabled(false)

	if hideBeforeReset then
		self:_setBallVisible(false)
	end

	self:_moveBallCFrame(self.BallHomeCFrame)

	if hideBeforeReset then
		task.wait(0.06)
		self:_setBallVisible(true)
	end
end

function MatchBallController:AttachToActor(actorModel, offsetCFrame)
	local actorRoot = GetRootPart(actorModel)
	if not actorRoot then
		return
	end

	self:_spawnBallIfNeeded()
	self:_cleanupDuplicateGeneratedBalls(self.BallInstance)
	self:_setWorldBallVisualsHidden(true)
	self:_stopMotion()
	self:_setBallVisible(true)
	self:_setTemplateSpecialEffectsEnabled(self:_shouldKeepActionSpecialEffects())
	self.CurrentFollowActor = actorModel
	self.LastFollowLookVector = actorRoot.CFrame.LookVector

	self:_moveBallCFrame(actorRoot.CFrame * (offsetCFrame or CFrame.identity))
end

function MatchBallController:FollowActor(actorModel)
	local actorRoot = GetRootPart(actorModel)
	if not actorRoot then
		return
	end

	self:_spawnBallIfNeeded()
	self:_cleanupDuplicateGeneratedBalls(self.BallInstance)
	self:_setWorldBallVisualsHidden(true)
	self:_setBallVisible(true)
	self:_setTemplateSpecialEffectsEnabled(self:_shouldKeepActionSpecialEffects())

	local config = MatchBallConfig.Dribble or {}
	local forward = config.Forward or 1.65
	local sideAmplitude = math.min(config.Side or 0.72, 0.48)
	local height = config.Height or -2.48
	local waveSpeedSide = config.WaveSpeedSide or 4.4
	local waveSpeedHeight = config.WaveSpeedHeight or 6.2
	local waveBob = math.min(config.WaveBob or 0.08, 0.06)
	local followLerpSpeed = math.max(config.FollowLerpSpeed or 7.5, 10.5)
	local snapDistance = config.SnapDistance or 0.95
	local lookBlendSpeed = config.LookBlendSpeed or 6.0

	local startedAt = os.clock()
	local previousActorPosition = actorRoot.Position
	local currentLookVector = self.LastFollowLookVector or actorRoot.CFrame.LookVector
	local initialFollowFrame = CFrame.lookAt(actorRoot.Position, actorRoot.Position + currentLookVector)
	local initialTargetPosition = actorRoot.Position + (initialFollowFrame.LookVector * forward) + Vector3.new(0, height, 0)

	local forceSnap = (self.CurrentFollowActor ~= actorModel)
	self.CurrentFollowActor = actorModel

	local currentPosition = self:GetBallPosition() or initialTargetPosition
	if forceSnap then
		currentPosition = initialTargetPosition
	end

	local previousBallPosition = currentPosition

	self:_beginMotion(function(deltaTime, motionToken, sessionVersion, stepVersion)
		if not actorRoot.Parent then
			self.CurrentFollowActor = nil
			return false
		end

		if self.CurrentFollowActor ~= actorModel then
			return false
		end

		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			return false
		end

		local actorPosition = actorRoot.Position
		local flatDelta = Vector3.new(actorPosition.X - previousActorPosition.X, 0, actorPosition.Z - previousActorPosition.Z)

		if flatDelta.Magnitude > 0.05 then
			local blendAlpha = math.clamp((deltaTime or (1 / 60)) * lookBlendSpeed, 0, 1)
			currentLookVector = currentLookVector:Lerp(flatDelta.Unit, blendAlpha)
		else
			local rootLook = Vector3.new(actorRoot.CFrame.LookVector.X, 0, actorRoot.CFrame.LookVector.Z)
			if rootLook.Magnitude > 0.001 then
				local blendAlpha = math.clamp((deltaTime or (1 / 60)) * lookBlendSpeed, 0, 1)
				currentLookVector = currentLookVector:Lerp(rootLook.Unit, blendAlpha)
			end
		end

		self.LastFollowLookVector = currentLookVector
		previousActorPosition = actorPosition

		local followFrame = CFrame.lookAt(actorPosition, actorPosition + currentLookVector)
		local elapsed = os.clock() - startedAt
		local sideWave = math.sin(elapsed * waveSpeedSide) * sideAmplitude
		local bobOffset = math.abs(math.sin(elapsed * waveSpeedHeight)) * waveBob
		local liveTargetPosition = actorPosition
			+ (followFrame.LookVector * forward)
			+ (followFrame.RightVector * sideWave)
			+ Vector3.new(0, height + bobOffset, 0)

		local lagDistance = (currentPosition - liveTargetPosition).Magnitude
		if forceSnap or lagDistance >= snapDistance then
			currentPosition = liveTargetPosition
			forceSnap = false
		else
			local alpha = math.clamp((deltaTime or (1 / 60)) * followLerpSpeed, 0, 1)
			currentPosition = currentPosition:Lerp(liveTargetPosition, alpha)
		end

		local spinDelta = (currentPosition - previousBallPosition).Magnitude * 2.35
		previousBallPosition = currentPosition
		self:_moveBallCFrame(self:_buildSpinningCFrame(currentPosition, currentPosition + currentLookVector, currentLookVector, spinDelta))
		return true
	end)
end

function MatchBallController:PlayLoosePassRoll(startPos: Vector3, endPos: Vector3, duration: number?, options)
	options = options or {}

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		warn("[MatchBallController] PlayLoosePassRoll failed: ball driver part is missing.")
		return nil
	end

	self:_stopMotion()
	self:_setBallVisible(true)
	local rollDuration = math.max(tonumber(duration) or 0.42, 0.12)
	if options and (options.SpecialEffects == true or options.IsGreenAction == true or options.ActionSpecialEffects == true) then
		self:ActivateActionSpecialEffects((options and options.EffectsDuration) or (rollDuration + 0.35))
	else
		self:_setTemplateSpecialEffectsEnabled(self:_shouldKeepActionSpecialEffects())
	end
	self.CurrentFollowActor = nil
	local bounceHeight = math.max(tonumber(options.BounceHeight) or 0.28, 0)
	local trailLinger = math.max(tonumber(options.TrailLinger) or 0.18, 0)
	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion
	local startedAt = os.clock()
	local flatDirection = Vector3.new(endPos.X - startPos.X, 0, endPos.Z - startPos.Z)
	local fallbackLook = flatDirection.Magnitude > 0.001 and flatDirection.Unit or Vector3.new(0, 0, -1)
	local lastPosition = startPos

	self:_moveBallCFrame(self:_buildSpinningCFrame(startPos, startPos + fallbackLook, fallbackLook, 0))

	self.MotionConnection = RunService.RenderStepped:Connect(function()
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			return
		end

		local alpha = math.clamp((os.clock() - startedAt) / rollDuration, 0, 1)
		local easedAlpha = 1 - math.pow(1 - alpha, 2)
		local flatPos = startPos:Lerp(endPos, easedAlpha)
		local bounce = math.sin(math.clamp(alpha * math.pi * 1.35, 0, math.pi)) * bounceHeight * math.max(1 - alpha, 0)
		local currentPosition = Vector3.new(flatPos.X, flatPos.Y + bounce, flatPos.Z)
		local lookDirection = Vector3.new(endPos.X - currentPosition.X, 0, endPos.Z - currentPosition.Z)
		lookDirection = lookDirection.Magnitude <= 0.001 and fallbackLook or lookDirection.Unit

		local spinDelta = (currentPosition - lastPosition).Magnitude * 3.05
		lastPosition = currentPosition
		self:_moveBallCFrame(self:_buildSpinningCFrame(currentPosition, currentPosition + lookDirection, fallbackLook, spinDelta))

		if alpha >= 1 then
			self:_moveBallCFrame(self:_buildSpinningCFrame(endPos, endPos + fallbackLook, fallbackLook, 0))
			self.MotionConnection = DisconnectConnection(self.MotionConnection)

			task.delay(trailLinger, function()
				if self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
					self:_disableAllTemplateShotEffects()
				end
			end)
		end
	end)

	return motionToken
end

function MatchBallController:PlayPassArc(startPos: Vector3, endPos: Vector3, duration: number, arcHeight: number, options)
	options = options or {}

	if options.MinFlightHeight == nil then
		options.MinFlightHeight = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.EndHeight or 0.32
	end

	if options.MinArcHeight == nil then
		options.MinArcHeight = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.MinArcHeight or 0.45
	end

	if options.TrailLinger == nil then
		options.TrailLinger = MatchBallConfig.PassFlight and MatchBallConfig.PassFlight.TrailLinger or 0.22
	end

	return self:_playParabola(startPos, endPos, duration, arcHeight, options)
end

function MatchBallController:PlayArc(startPos, endPos, duration, arcHeight, options)
	self:_playParabola(startPos, endPos, duration, arcHeight, options)
end

function MatchBallController:PlayEpicShot(startPosition: Vector3, endPosition: Vector3, success: boolean, shootTier: string?, options)
	options = options or {}

	local isSpecialShot = options.IsSpecialShot == true or options.SpecialTrail == true or options.SpecialAura == true
	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		warn("[MatchBallController] PlayEpicShot failed: ball driver part is missing.")
		return
	end

	self:_stopMotion()

	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion
	local epicShotConfig = MatchBallConfig and MatchBallConfig.EpicShot or {}
	local phase1Duration = tonumber(epicShotConfig.DurationPhase1) or 0.4
	local phase2Duration = tonumber(epicShotConfig.DurationPhase2) or 0.2
	local phase1Height = tonumber(options.HeightPhase1) or tonumber(epicShotConfig.HeightPhase1) or 1.2
	local phase2Height = tonumber(options.HeightPhase2) or tonumber(epicShotConfig.HeightPhase2) or 0.1
	local totalDuration = math.max(phase1Duration + phase2Duration, 0.1)

	local overrideDuration = tonumber(options.DurationOverride or options.TotalDuration or options.Duration)
	if overrideDuration and overrideDuration > 0 then
		totalDuration = math.max(overrideDuration, 0.1)
		phase1Duration = totalDuration * 0.58
		phase2Duration = totalDuration - phase1Duration
	end
	local startTime = os.clock()
	local fallbackLook = (endPosition - startPosition).Magnitude > 0.001 and (endPosition - startPosition).Unit or Vector3.new(0, 0, -1)
	local lastPosition = startPosition
	local stableSeed = math.floor((startPosition.X + startPosition.Z) * 10)
	local curveSign = (stableSeed % 2 == 0) and 1 or -1
	local tier = shootTier or "Yellow"
	local curveMagnitude = tier == "Green" and 4.15 or (tier == "Yellow" and 2.50 or 0.70)
	local lateralCurve = curveMagnitude * curveSign

	local enableFlightEffects = options.EnableFlightEffects == true or isSpecialShot

	self.CurrentFollowActor = nil
	self:_setBallVisible(true)
	self:_disableAllTemplateShotEffects()
	self:_setShotFlightEffectsEnabled(enableFlightEffects)
	self:_moveBallCFrame(self:_buildSpinningCFrame(startPosition, startPosition + fallbackLook, fallbackLook, 0))

	self.MotionConnection = RunService.RenderStepped:Connect(function()
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			self:_setTemplateSpecialEffectsEnabled(false)
			return
		end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / totalDuration, 0, 1)
		local easedAlpha = alpha < 0.5 and (2 * alpha * alpha) or (1 - math.pow(-2 * alpha + 2, 2) / 2)
		
		local activeEndPosition = endPosition
		if options.TargetInstance then
			local ok, resolvedCFrame = pcall(function()
				return self:_resolveWorldCFrame(options.TargetInstance)
			end)
			if ok and resolvedCFrame then
				-- Dynamically curve into the actual hand position at the end of the shot
				local targetBlend = math.pow(easedAlpha, 2.5)
				activeEndPosition = endPosition:Lerp(resolvedCFrame.Position, targetBlend)
			end
		end

		local currentPosition = startPosition:Lerp(activeEndPosition, easedAlpha)
		local toTarget = Vector3.new(activeEndPosition.X - startPosition.X, 0, activeEndPosition.Z - startPosition.Z)

		if toTarget.Magnitude > 0.001 then
			local lateralDir = toTarget.Unit:Cross(Vector3.new(0, 1, 0))
			local curveAmount = 4 * lateralCurve * easedAlpha * (1 - easedAlpha)
			currentPosition += lateralDir * curveAmount
		end

		local arcHeight
		if elapsed <= phase1Duration then
			local phaseAlpha = math.clamp(elapsed / math.max(phase1Duration, 0.01), 0, 1)
			arcHeight = math.sin(phaseAlpha * math.pi) * phase1Height
		else
			local phaseAlpha = math.clamp((elapsed - phase1Duration) / math.max(phase2Duration, 0.01), 0, 1)
			arcHeight = math.sin((1 - phaseAlpha) * math.pi * 0.5) * phase2Height
		end

		currentPosition += Vector3.new(0, arcHeight, 0)

		local lookDirection = endPosition - currentPosition
		lookDirection = lookDirection.Magnitude <= 0.01 and fallbackLook or lookDirection.Unit

		local spinDelta = (currentPosition - lastPosition).Magnitude * 2.75
		lastPosition = currentPosition
		self:_moveBallCFrame(self:_buildSpinningCFrame(currentPosition, currentPosition + lookDirection, fallbackLook, spinDelta))

		if alpha >= 1 then
			local finalEndPosition = activeEndPosition
			self:_moveBallCFrame(self:_buildSpinningCFrame(finalEndPosition, finalEndPosition + fallbackLook, fallbackLook, 0))
			self.MotionConnection = DisconnectConnection(self.MotionConnection)

			if options.ImpactAtFinish == true then
				self:PlayImpactEffect(finalEndPosition, {
					EmitCount = options.ImpactEmitCount,
					Lifetime = options.ImpactLifetime,
				})
			end

			if type(options.OnImpactAtFinish) == "function" then
				task.defer(function()
					if self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
						options.OnImpactAtFinish(finalEndPosition)
					end
				end)
			end

			local shouldDropAfterFinish = options.DropAfterFinish == true
			task.delay(isSpecialShot and 0.62 or 0.22, function()
				if self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
					self:_setTemplateSpecialEffectsEnabled(false)
				end
			end)

			if shouldDropAfterFinish then
				local function startGoalDrop()
					-- Dropping is a continuation of this shot finish, not a competing shot motion.
					-- Check session/step only so a disconnected finish connection cannot leave the ball pinned to the target.
					if sessionVersion ~= self.SessionVersion or stepVersion ~= self.StepVersion then
						return
					end

					local currentPosition = self:GetBallPosition() or finalEndPosition
					self:DropBallToGround(currentPosition, {
						Duration = options.DropDuration,
						DropDistance = options.DropDistance,
						BounceHeight = options.DropBounceHeight,
					})
				end

				local dropDelay = math.max(tonumber(options.DropDelay) or 0.04, 0)
				if dropDelay <= 0 then
					task.defer(startGoalDrop)
				else
					task.delay(dropDelay, startGoalDrop)
				end
			end
		end
	end)
end


function MatchBallController:_resolveWorldCFrame(target, fallbackCFrame: CFrame?): CFrame?
	if type(target) == "function" then
		local ok, resolved = pcall(target)
		if ok then
			if typeof(resolved) == "CFrame" then
				return resolved
			end

			if typeof(resolved) == "Vector3" then
				return CFrame.new(resolved)
			end

			if typeof(resolved) == "Instance" then
				return self:_resolveWorldCFrame(resolved, fallbackCFrame)
			end
		end

		return fallbackCFrame
	end

	if typeof(target) == "CFrame" then
		return target
	end

	if typeof(target) == "Vector3" then
		return CFrame.new(target)
	end

	if typeof(target) ~= "Instance" then
		return fallbackCFrame
	end

	if target:IsA("Attachment") then
		return target.WorldCFrame
	end

	if target:IsA("BasePart") then
		return target.CFrame
	end

	if target:IsA("Model") then
		return target:GetPivot()
	end

	local basePart = target:FindFirstChildWhichIsA("BasePart", true)
	if basePart then
		return basePart.CFrame
	end

	return fallbackCFrame
end

function MatchBallController:HoldAtWorldCFrame(worldCFrame: CFrame, duration: number?, options)
	options = options or {}

	if not worldCFrame then
		return nil
	end

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		warn("[MatchBallController] HoldAtWorldCFrame failed: ball driver part is missing.")
		return nil
	end

	self:_stopMotion()
	self.CurrentFollowActor = nil
	self:_setBallVisible(true)
	self:_disableAllTemplateShotEffects()
	self:_setEffectGroupEnabled("HoldEffects", options.HoldEffects == true)
	if options.HoldEffects == true then
		self:_emitEffectGroup("HoldEffects", MatchBallConfig.HoldEffectEmitCount or 18)
	end

	local spinWhileHeld = options.SpinWhileHeld == true
	local spinSpeed = tonumber(options.SpinSpeed) or 0
	local function applyHoldCFrame(deltaTime)
		if spinWhileHeld then
			self.SpinAngle = (self.SpinAngle + (spinSpeed * (deltaTime or 0.016))) % (math.pi * 2)
		end

		self:_moveBallCFrame(self:_applyWholeBallSpinIfNeeded(worldCFrame, spinWhileHeld))
	end

	applyHoldCFrame(0)

	local holdDuration = tonumber(duration) or tonumber(options.Duration) or 0
	if holdDuration <= 0 then
		return self.ActiveMotionToken
	end

	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion
	local startedAt = os.clock()

	self.MotionConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			return
		end

		applyHoldCFrame(deltaTime)

		if os.clock() - startedAt >= holdDuration then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
		end
	end)

	return motionToken
end

function MatchBallController:HoldAtMovingTarget(target, duration: number?, options)
	options = options or {}
	return self:BlendToMovingTarget(target, 0, {
		WorldCFrame = options.WorldCFrame,
		FallbackCFrame = options.FallbackCFrame,
		OffsetCFrame = options.OffsetCFrame,
		HoldDuration = duration or options.Duration or 0.55,
		HoldEffects = options.HoldEffects == true,
		SpinWhileHeld = options.SpinWhileHeld,
		SpinSpeed = options.SpinSpeed,
	})
end

function MatchBallController:BlendToWorldCFrame(worldCFrame: CFrame, blendDuration: number?, options)
	options = options or {}

	if not worldCFrame then
		return nil
	end

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		warn("[MatchBallController] BlendToWorldCFrame failed: ball driver part is missing.")
		return nil
	end

	self:_stopMotion()
	self.CurrentFollowActor = nil
	self:_setBallVisible(true)
	self:_disableAllTemplateShotEffects()
	self:_setEffectGroupEnabled("HoldEffects", options.HoldEffects == true)
	if options.HoldEffects == true then
		self:_emitEffectGroup("HoldEffects", MatchBallConfig.HoldEffectEmitCount or 18)
	end

	local startCFrame = driverPart.CFrame
	local blendTime = math.max(tonumber(blendDuration) or 0.08, 0)
	local holdDuration = math.max(tonumber(options.HoldDuration) or tonumber(options.Duration) or 0, 0)
	local spinWhileHeld = options.SpinWhileHeld == true
	local spinSpeed = tonumber(options.SpinSpeed) or 0
	local totalDuration = blendTime + holdDuration

	if totalDuration <= 0 then
		self:_moveBallCFrame(worldCFrame)
		return self.ActiveMotionToken
	end

	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion
	local startedAt = os.clock()

	self.MotionConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			return
		end

		local elapsed = os.clock() - startedAt
		local targetCFrame = worldCFrame

		if elapsed < blendTime and blendTime > 0 then
			local alpha = math.clamp(elapsed / blendTime, 0, 1)
			alpha = 1 - math.pow(1 - alpha, 2)
			targetCFrame = startCFrame:Lerp(worldCFrame, alpha)
		elseif spinWhileHeld then
			self.SpinAngle = (self.SpinAngle + (spinSpeed * (deltaTime or 0.016))) % (math.pi * 2)
		end

		self:_moveBallCFrame(self:_applyWholeBallSpinIfNeeded(targetCFrame, spinWhileHeld))

		if elapsed >= totalDuration then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
		end
	end)

	return motionToken
end

function MatchBallController:BlendToMovingTarget(target, blendDuration: number?, options)
	options = options or {}

	local initialCFrame = self:_resolveWorldCFrame(target, options.WorldCFrame or options.FallbackCFrame)
	if not initialCFrame then
		return nil
	end

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		warn("[MatchBallController] BlendToMovingTarget failed: ball driver part is missing.")
		return nil
	end

	self:_stopMotion()
	self.CurrentFollowActor = nil
	self:_setBallVisible(true)
	self:_disableAllTemplateShotEffects()
	self:_setEffectGroupEnabled("HoldEffects", options.HoldEffects == true)
	if options.HoldEffects == true then
		self:_emitEffectGroup("HoldEffects", MatchBallConfig.HoldEffectEmitCount or 18)
	end

	local offsetCFrame = options.OffsetCFrame or CFrame.identity
	local blendTime = math.max(tonumber(blendDuration) or tonumber(options.BlendDuration) or 0.08, 0)
	local holdDuration = math.max(tonumber(options.HoldDuration) or tonumber(options.Duration) or 0.55, 0.05)
	local totalDuration = blendTime + holdDuration
	local spinWhileHeld = options.SpinWhileHeld == true
	local spinSpeed = tonumber(options.SpinSpeed) or 0
	local startCFrame = driverPart.CFrame
	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion
	local startedAt = os.clock()

	self:_moveBallCFrame(startCFrame)

	self.MotionConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			return
		end

		local elapsed = os.clock() - startedAt
		local targetCFrame = self:_resolveWorldCFrame(target, initialCFrame) or initialCFrame
		targetCFrame = targetCFrame * offsetCFrame

		if elapsed < blendTime and blendTime > 0 then
			local alpha = math.clamp(elapsed / blendTime, 0, 1)
			alpha = 1 - math.pow(1 - alpha, 2)
			self:_moveBallCFrame(startCFrame:Lerp(targetCFrame, alpha))
		else
			if spinWhileHeld then
				self.SpinAngle = (self.SpinAngle + (spinSpeed * (deltaTime or 0.016))) % (math.pi * 2)
			end

			self:_moveBallCFrame(self:_applyWholeBallSpinIfNeeded(targetCFrame, spinWhileHeld))
		end

		if elapsed >= totalDuration then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
		end
	end)

	return motionToken
end

local function ShouldIgnoreDropRaycastHit(instance)
	if not instance then
		return true
	end

	if instance:IsA("Terrain") then
		return false
	end

	if not instance:IsA("BasePart") then
		return true
	end

	if instance.CanCollide == false or instance.CanQuery == false then
		return true
	end

	if instance.Transparency >= 0.95 and not instance:IsDescendantOf(Workspace.Terrain) then
		return true
	end

	local current = instance
	while current do
		local loweredName = string.lower(tostring(current.Name or ""))
		if loweredName:find("target")
			or loweredName:find("marker")
			or loweredName:find("keeper")
			or loweredName:find("goal")
			or loweredName:find("goalvfx")
			or loweredName:find("helper")
			or loweredName:find("ballarea")
			or loweredName:find("runtime")
		then
			return true
		end

		current = current.Parent
	end

	return false
end

local function ResolveGroundBallPosition(self, startPosition: Vector3, options)
	options = options or {}

	local dropDistance = math.max(tonumber(options.DropDistance) or 5.0, tonumber(options.MinDropDistance) or 32.0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local exclude = {}
	if self.BallInstance then
		table.insert(exclude, self.BallInstance)
	end

	local origin = startPosition + Vector3.new(0, 1.0, 0)
	local direction = Vector3.new(0, -(dropDistance + 8.0), 0)
	local radius = tonumber(options.BallRadius) or 0.35

	for _ = 1, 8 do
		rayParams.FilterDescendantsInstances = exclude
		local result = Workspace:Raycast(origin, direction, rayParams)
		if not result then
			break
		end

		if not ShouldIgnoreDropRaycastHit(result.Instance) then
			return result.Position + Vector3.new(0, radius, 0)
		end

		table.insert(exclude, result.Instance)
	end

	return startPosition - Vector3.new(0, dropDistance, 0)
end

function MatchBallController:DropBallToGround(startPosition: Vector3?, options)
	options = options or {}

	local resolvedStart = startPosition
	if typeof(resolvedStart) ~= "Vector3" then
		resolvedStart = self:GetBallPosition()
	end

	if typeof(resolvedStart) ~= "Vector3" then
		return nil
	end

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart then
		return nil
	end

	self:_stopMotion()
	self.CurrentFollowActor = nil
	self:_setBallVisible(true)
	self:_disableAllTemplateShotEffects()

	local endPosition = ResolveGroundBallPosition(self, resolvedStart, options)
	local duration = math.max(tonumber(options.Duration) or 0.34, 0.08)
	local bounceHeight = math.max(tonumber(options.BounceHeight) or 0.22, 0)
	local fallbackLook = Vector3.new(0, 0, -1)
	local startedAt = os.clock()
	local lastPosition = resolvedStart
	local motionToken = self.ActiveMotionToken
	local sessionVersion = self.SessionVersion
	local stepVersion = self.StepVersion

	self:_moveBallCFrame(self:_buildSpinningCFrame(resolvedStart, resolvedStart + fallbackLook, fallbackLook, 0))

	self.MotionConnection = RunService.RenderStepped:Connect(function()
		if not self:_isMotionScopeCurrent(sessionVersion, stepVersion, motionToken) then
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
			return
		end

		local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
		local eased = 1 - math.pow(1 - alpha, 2)
		local pos = resolvedStart:Lerp(endPosition, eased)
		local bounce = math.sin(math.clamp(alpha * math.pi, 0, math.pi)) * bounceHeight * math.max(1 - alpha, 0)
		pos += Vector3.new(0, bounce, 0)

		local spinDelta = (pos - lastPosition).Magnitude * 2.2
		lastPosition = pos
		self:_moveBallCFrame(self:_buildSpinningCFrame(pos, pos + fallbackLook, fallbackLook, spinDelta))

		if alpha >= 1 then
			self:_moveBallCFrame(self:_buildSpinningCFrame(endPosition, endPosition + fallbackLook, fallbackLook, 0))
			PlayBallBounceSound(driverPart)
			self.MotionConnection = DisconnectConnection(self.MotionConnection)
		end
	end)

	return motionToken
end

function MatchBallController:ParryToGround(startCFrame: CFrame, endPosition: Vector3, duration: number?, arcHeight: number?)
	if not startCFrame or typeof(endPosition) ~= "Vector3" then
		return nil
	end

	local startPosition = startCFrame.Position
	local currentBallPosition = self:GetBallPosition()
	if currentBallPosition then
		local maxSnapDistance = 4.75
		if (currentBallPosition - startPosition).Magnitude > maxSnapDistance then
			startPosition = currentBallPosition
		end
	end

	self:_setTemplateSpecialEffectsEnabled(false)
	return self:PlayArc(startPosition, endPosition, duration or 0.55, arcHeight or 0.6)
end

function MatchBallController:ContinueShotFromKeeper(startCFrame: CFrame, endPosition: Vector3, shootTier: string?, options)
	options = options or {}

	if not startCFrame or typeof(endPosition) ~= "Vector3" then
		return nil
	end

	local startPosition = startCFrame.Position
	local continueDuration = tonumber(options.Duration) or tonumber(options.DurationOverride) or 0.48
	local arcHeight = tonumber(options.ArcHeight) or 0.52

	return self:PlayEpicShot(startPosition, endPosition, true, shootTier or "Green", {
		IsSpecialShot = options.IsSpecialShot == true,
		EnableFlightEffects = options.EnableFlightEffects == true,
		DurationOverride = continueDuration,
		HeightPhase1 = arcHeight,
		HeightPhase2 = math.max(arcHeight * 0.25, 0.08),
		DropAfterFinish = options.DropAfterFinish ~= false,
		DropDelay = options.DropDelay,
		DropDuration = options.DropDuration,
		DropDistance = options.DropDistance,
		DropBounceHeight = options.DropBounceHeight,
		ImpactAtFinish = options.ImpactAtFinish == true,
		ImpactEmitCount = options.ImpactEmitCount,
		ImpactLifetime = options.ImpactLifetime,
		OnImpactAtFinish = options.OnImpactAtFinish,
	})
end

function MatchBallController:StopFollow()
	self.CurrentFollowActor = nil
	self:_stopMotion()
	self:_disableAllTemplateShotEffects()
end

function MatchBallController:ClearTrail()
	self:_disableAllTemplateShotEffects()
end

function MatchBallController:EnableTrail()
	-- Manual trails removed. Template SpecialEffects are enabled only through PlayEpicShot({ IsSpecialShot = true }).
end

function MatchBallController:SetBallWorldPosition(worldPosition)
	if not self.BallInstance or not worldPosition then
		return
	end

	local pivot = self.BallInstance:GetPivot()
	local rotation = pivot - pivot.Position
	self:_moveBallCFrame(CFrame.new(worldPosition) * rotation)
end

function MatchBallController:SetBallDriverWorldCFrame(targetDriverCFrame: CFrame)
	if not targetDriverCFrame then
		return
	end

	local driverPart = self:_spawnBallIfNeeded()
	if not driverPart or not self.BallInstance then
		return
	end

	local currentPivot = self.BallInstance:GetPivot()
	local pivotToDriver = currentPivot:ToObjectSpace(driverPart.CFrame)
	local desiredPivot = targetDriverCFrame * pivotToDriver:Inverse()

	driverPart.AssemblyLinearVelocity = Vector3.zero
	driverPart.AssemblyAngularVelocity = Vector3.zero
	ApplyPivot(self.BallInstance, desiredPivot)
	self:_applyVisualSpin()
end

function MatchBallController:KnitStart()
end

return MatchBallController
