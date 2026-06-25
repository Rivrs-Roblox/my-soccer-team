local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MatchKeeperConfig = require(script.Parent.Parent.Config.Match.MatchKeeperConfig)
local MatchGrounding = require(ReplicatedStorage.Shared.Helpers.Match.MatchGrounding)
local MatchSceneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchSceneQuery)
local MatchZoneQuery = require(ReplicatedStorage.Shared.Helpers.Match.MatchZoneQuery)
local RagdollModule = require(ReplicatedStorage.Shared.Modules.Ragdoll)

local ClientRoot = script.Parent.Parent
local MatchShootTargetResolver = require(ClientRoot.Helpers.Match.Presentation.MatchShootTargetResolver)

local DEFAULT_FORWARD = Vector3.new(0, 0, -1)

-- Keeper save polish is intentionally visual-only.
-- Do not delay or retime the shot ball here; MatchShootDirector keeps the old impact timing.
-- This controller only delays/poses the keeper so the save reads closer to the ball contact.
local DEFAULT_SAVE_REACTION_DELAY = 0.24
local DEFAULT_SAVE_CONTACT_HOLD = 0.10
local DEFAULT_SAVE_LOW_LIFT = 0.48
local DEFAULT_SAVE_MID_LIFT = 0.90
local DEFAULT_SAVE_HIGH_LIFT = 1.45
local DEFAULT_SAVE_CENTER_LIFT = 0.72

local MatchKeeperPresentationController = Knit.CreateController({
	Name = "MatchKeeperPresentationController",

	State = "Idle",
	StandbyConnection = nil,
	StandbyToken = 0,

	BaseCFrame = nil,
	BaseLookVector = nil,
	GroundIgnoreInstances = nil,
	FocusWorldPosition = nil,

	ActiveTween = nil,
	TweenValue = nil,
	TweenConnection = nil,

	ReactionId = 0,
	CurrentStepIndex = 1,
	ActiveSessionId = nil,

	CinematicPartStates = nil,
	PowerBreakthroughPushbackByReactionId = {},
	PowerBreakthroughBoundNamesByReactionId = {},
	ActivePowerBreakthroughRagdoll = nil,
	ActiveGoalImpactRagdoll = nil,
	KeeperImpactLock = nil,
	KeeperImpactToken = 0,
})

local function ShakeCamera(intensity, duration)
	pcall(function()
		local cameraController = Knit.GetController("MatchBattleCameraController")
		if cameraController and cameraController.Shake then
			cameraController:Shake(intensity or 1.5, duration or 0.35)
		end
	end)
end

local function ResetKeeperRuntimeState(model)
	if not model then
		return
	end

	model:SetAttribute("IsCinematicReacting", nil)
	model:SetAttribute("IsPowerBreakthroughRagdoll", nil)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = false
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			descendant.Enabled = true
		elseif descendant:IsA("BallSocketConstraint") and string.find(descendant.Name, "_Ragdoll") then
			descendant:Destroy()
		elseif descendant:IsA("BallSocketConstraint") and string.find(descendant.Name, "_GoalImpactConstraint") then
			descendant:Destroy()
		elseif descendant:IsA("Attachment") and string.find(descendant.Name, "_Att") then
			descendant:Destroy()
		elseif descendant:IsA("Attachment") and string.find(descendant.Name, "_GoalImpactAtt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 0
			if descendant.Name ~= "HumanoidRootPart" and descendant.Transparency >= 1 then
				descendant.Transparency = 0
			end
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		elseif descendant:IsA("Decal") then
			if descendant.Transparency >= 1 then
				descendant.Transparency = 0
			end
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = true
		end
	end
end

local function ApplyPivot(instance, cf)
	if not instance or not cf then
		return
	end

	if instance:IsA("Model") then
		instance:PivotTo(cf)
	elseif instance:IsA("BasePart") then
		instance.CFrame = cf
	end
end

local function ZeroModelVelocity(model)
	if not model then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function AnchorKeeperRoot(model, anchored)
	local root = model and model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		root.Anchored = anchored == true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

local function DisableKeeperPhysicalContact(model)
	if not model then
		return
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function GetInstanceCFrame(instance)
	if not instance then
		return nil
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	return nil
end

local function GetFlatUnit(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude <= 0.001 then
		return DEFAULT_FORWARD
	end
	return flat.Unit
end

local function BuildFlatFacingCFrame(position, lookVector)
	local flatLook = GetFlatUnit(lookVector)
	return CFrame.lookAt(position, position + flatLook)
end

local function GetModelHighestY(model)
	local highestY = -math.huge

	if not model then
		return highestY
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			local topY = descendant.Position.Y + (descendant.Size.Y * 0.5)
			if topY > highestY then
				highestY = topY
			end
		end
	end

	return highestY
end

local function GetGroundedCFrame(model, targetCFrame, extraIgnore)
	local groundedCFrame = MatchGrounding.GetGroundedCFrame(model, targetCFrame, {
		ExtraIgnoreInstances = extraIgnore,
		IgnoreMatchRuntimeRoot = true,
		FallbackY = targetCFrame.Position.Y,
	})

	return BuildFlatFacingCFrame(groundedCFrame.Position, targetCFrame.LookVector)
end

local function GetKeeperModel()
	local folder = MatchSceneQuery.GetSpawnedEnemiesFolder and MatchSceneQuery.GetSpawnedEnemiesFolder(false)
	if not folder then
		return nil
	end

	local directKeeper = folder:FindFirstChild("GoalKeeper") or folder:FindFirstChild("Keeper")
	if directKeeper then
		return directKeeper
	end

	for _, child in ipairs(folder:GetChildren()) do
		local role = child:GetAttribute("MatchEnemyRole") or child:GetAttribute("Role")
		if role == "GoalKeeper" or role == "Keeper" then
			return child
		end
	end

	return nil
end

function MatchKeeperPresentationController:SetFocusWorldPosition(worldPosition)
	self.FocusWorldPosition = worldPosition
end

function MatchKeeperPresentationController:ClearFocusWorldPosition()
	self.FocusWorldPosition = nil
end

function MatchKeeperPresentationController:_isKeeperImpactLocked()
	return self.KeeperImpactLock ~= nil
end

function MatchKeeperPresentationController:_beginKeeperImpactLock(reason)
	self.KeeperImpactToken = (tonumber(self.KeeperImpactToken) or 0) + 1
	self.KeeperImpactLock = tostring(reason or "Impact")
	return self.KeeperImpactToken
end

function MatchKeeperPresentationController:_clearKeeperImpactLock()
	self.KeeperImpactToken = (tonumber(self.KeeperImpactToken) or 0) + 1
	self.KeeperImpactLock = nil
end

function MatchKeeperPresentationController:_resolveLookVectorFromFocus(fromPosition)
	if self.FocusWorldPosition then
		local toFocus = self.FocusWorldPosition - fromPosition
		local flat = Vector3.new(toFocus.X, 0, toFocus.Z)
		if flat.Magnitude > 0.001 then
			return flat.Unit
		end
	end

	return self.BaseLookVector or DEFAULT_FORWARD
end

function MatchKeeperPresentationController:_clearTweenState()
	if self.TweenConnection then
		self.TweenConnection:Disconnect()
		self.TweenConnection = nil
	end

	if self.ActiveTween then
		self.ActiveTween:Cancel()
		self.ActiveTween = nil
	end

	if self.TweenValue then
		self.TweenValue:Destroy()
		self.TweenValue = nil
	end
end

function MatchKeeperPresentationController:_captureCinematicPartStates(model)
	self:_restoreCinematicPartStates()

	local states = {}
	if not model then
		self.CinematicPartStates = states
		return states
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			states[descendant] = {
				CanCollide = descendant.CanCollide,
				CanTouch = descendant.CanTouch,
				CanQuery = descendant.CanQuery,
			}
		end
	end

	self.CinematicPartStates = states
	return states
end

function MatchKeeperPresentationController:_restoreCinematicPartStates()
	local states = self.CinematicPartStates
	if not states then
		return
	end

	for part, state in pairs(states) do
		if part and part.Parent and state then
			part.CanCollide = state.CanCollide
			part.CanTouch = state.CanTouch
			part.CanQuery = state.CanQuery
		end
	end

	self.CinematicPartStates = nil
end

function MatchKeeperPresentationController:_setCinematicPartCollision(model, canCollide, canTouch)
	if not model then
		return
	end

	if not self.CinematicPartStates then
		self:_captureCinematicPartStates(model)
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = canCollide == true
			descendant.CanTouch = canTouch == true
			descendant.CanQuery = canCollide == true or canTouch == true
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function MatchKeeperPresentationController:_buildPowerBreakthroughPushbackCFrame(keeperModel, reactionData)
	local currentCFrame = GetInstanceCFrame(keeperModel)
		or (reactionData and reactionData.InterceptCFrame)
		or self.BaseCFrame

	if not currentCFrame then
		return reactionData and reactionData.LandedCFrame or nil
	end

	-- Preserve the keeper's contact-facing direction for the whole breakthrough.
	-- Do not use the pushback movement vector as the look vector; otherwise the
	-- keeper can visually turn around while being pushed backward.
	local lockedFacingVector = reactionData and reactionData.PowerBreakthroughLockedFacingVector or nil
	if typeof(lockedFacingVector) ~= "Vector3" or lockedFacingVector.Magnitude <= 0.001 then
		lockedFacingVector = currentCFrame.LookVector
	end
	lockedFacingVector = GetFlatUnit(lockedFacingVector)

	local movementForwardVector = reactionData and reactionData.ForwardVector or nil
	if typeof(movementForwardVector) ~= "Vector3" or movementForwardVector.Magnitude <= 0.001 then
		movementForwardVector = lockedFacingVector
	end
	movementForwardVector = GetFlatUnit(movementForwardVector)

	local sign = tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackSign) or -1
	local distance = tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackDistance) or 3.35
	local lift = tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackLift) or 0.04
	local targetPosition = currentCFrame.Position + (movementForwardVector * sign * distance) + Vector3.new(0, lift, 0)

	-- Do not raycast/ground using model extents during breakthrough pushback.
	-- The keeper is already grounded at contact; preserving current root height avoids
	-- goal-net raycast/bounds feedback that previously made the keeper fly upward.
	local stablePosition = Vector3.new(targetPosition.X, currentCFrame.Position.Y + lift, targetPosition.Z)

	local pushbackCFrame = BuildFlatFacingCFrame(stablePosition, lockedFacingVector)
	local backAngle = tonumber(MatchKeeperConfig.PowerBreakthroughControlledLeanBackAngle) or math.rad(10)

	return pushbackCFrame * CFrame.Angles(backAngle, 0, 0)
end

function MatchKeeperPresentationController:_stopPowerBreakthroughPushback(reactionId)
	if not self.PowerBreakthroughPushbackByReactionId then
		return
	end

	local state = self.PowerBreakthroughPushbackByReactionId[reactionId]
	if not state then
		return
	end

	if state.RenderStepName then
		pcall(function()
			RunService:UnbindFromRenderStep(state.RenderStepName)
		end)
	end

	self.PowerBreakthroughPushbackByReactionId[reactionId] = nil

	if self.PowerBreakthroughBoundNamesByReactionId then
		self.PowerBreakthroughBoundNamesByReactionId[reactionId] = nil
	end
end

function MatchKeeperPresentationController:_stopAllPowerBreakthroughPushbacks()
	if self.PowerBreakthroughPushbackByReactionId then
		local ids = {}
		for reactionId in pairs(self.PowerBreakthroughPushbackByReactionId) do
			table.insert(ids, reactionId)
		end

		for _, reactionId in ipairs(ids) do
			self:_stopPowerBreakthroughPushback(reactionId)
		end
	end

	self.PowerBreakthroughPushbackByReactionId = {}
	self.PowerBreakthroughBoundNamesByReactionId = {}
end

local function ShouldUsePowerBreakthroughRagdoll()
	return MatchKeeperConfig.PowerBreakthroughRagdollEnabled == true
end

local function ResolvePowerBreakthroughRagdollDirection(rootCFrame, forwardVector, baseLookVector)
	local zSign = 1
	if rootCFrame.Position.Z > 0 then
		zSign = -1
	end
	local forwardOntoPitch = Vector3.new(0, 0, zSign)

	return forwardOntoPitch, "half-field-z-direction"
end

local function ResolvePowerBreakthroughCarryTargetPosition(reactionData)
	if not reactionData then
		return nil
	end

	if typeof(reactionData.PowerBreakthroughCarryTargetPosition) == "Vector3" then
		return reactionData.PowerBreakthroughCarryTargetPosition, "shot-target"
	end

	if typeof(reactionData.KeeperSaveTargetPosition) == "Vector3" then
		return reactionData.KeeperSaveTargetPosition, "keeper-save-target"
	end

	local goalTarget = MatchZoneQuery.GetGoalTarget and MatchZoneQuery.GetGoalTarget() or nil
	local goalCFrame = goalTarget and GetInstanceCFrame(goalTarget) or nil
	if goalCFrame then
		return goalCFrame.Position, "goal-target"
	end

	return nil
end

local function BuildPowerBreakthroughCarryCFrame(rootCFrame, lockedFacingVector, reactionData)
	if MatchKeeperConfig.PowerBreakthroughCarryToShotTargetEnabled == false then
		return nil, 0, nil, "disabled"
	end

	local targetPosition, targetSource = ResolvePowerBreakthroughCarryTargetPosition(reactionData)
	if typeof(targetPosition) ~= "Vector3" then
		return nil, 0, nil, "missing-target"
	end

	local rootPosition = rootCFrame.Position
	local flatDelta = Vector3.new(targetPosition.X - rootPosition.X, 0, targetPosition.Z - rootPosition.Z)
	if flatDelta.Magnitude <= 0.08 then
		return nil, 0, nil, "target-too-close"
	end

	local direction = flatDelta.Unit
	local backoff = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughCarryTargetBackoff) or 0.55, 0)
	local maxDistance = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughCarryTargetMaxDistance) or 5.5, 0.25)
	local travelDistance = math.clamp(flatDelta.Magnitude - backoff, 0.15, maxDistance)
	local carryPosition = rootPosition + (direction * travelDistance)
	carryPosition = Vector3.new(carryPosition.X, rootPosition.Y, carryPosition.Z)

	local carryLeanAngle = tonumber(MatchKeeperConfig.PowerBreakthroughCarryLeanAngle) or math.rad(5)
	local carryCFrame = BuildFlatFacingCFrame(carryPosition, lockedFacingVector) * CFrame.Angles(carryLeanAngle, 0, 0)
	local carryDuration = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughCarryToShotTargetDuration) or 0.36, 0.03)

	return carryCFrame, carryDuration, direction, targetSource
end

function MatchKeeperPresentationController:_cleanupActiveGoalImpactRagdoll()
	local state = self.ActiveGoalImpactRagdoll
	if not state then
		return
	end

	self.ActiveGoalImpactRagdoll = nil

	if state.RenderStepName then
		pcall(function()
			RunService:UnbindFromRenderStep(state.RenderStepName)
		end)
	end

	if state.Ragdoll then
		pcall(function()
			state.Ragdoll:disableRagdoll()
		end)
	end

	if state.CreatedConstraints then
		for _, constraint in ipairs(state.CreatedConstraints) do
			if constraint and constraint.Parent then
				pcall(function()
					constraint:Destroy()
				end)
			end
		end
	end

	if state.CreatedAttachments then
		for _, attachment in ipairs(state.CreatedAttachments) do
			if attachment and attachment.Parent then
				pcall(function()
					attachment:Destroy()
				end)
			end
		end
	end

	if state.DisabledMotors then
		for _, motor in ipairs(state.DisabledMotors) do
			if motor and motor.Parent then
				pcall(function()
					motor.Enabled = true
				end)
			end
		end
	end

	if state.AnchorStates then
		for part, oldAnchored in pairs(state.AnchorStates) do
			if part and part.Parent and part:IsA("BasePart") then
				-- Selalu anchor dulu setelah ragdoll selesai biar tidak jatuh bebas
				part.Anchored = true
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	if state.PartStates then
		for part, oldState in pairs(state.PartStates) do
			if part and part.Parent and part:IsA("BasePart") and type(oldState) == "table" then
				part.CanCollide = oldState.CanCollide == true
				part.CanTouch = oldState.CanTouch == true
				part.CanQuery = oldState.CanQuery == true
				if type(oldState.CollisionGroup) == "string" then
					part.CollisionGroup = oldState.CollisionGroup
				end
				if type(oldState.Massless) == "boolean" then
					part.Massless = oldState.Massless
				end
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	local keeperModel = GetKeeperModel()
	if keeperModel then
		keeperModel:SetAttribute("IsPowerBreakthroughRagdoll", nil)

		-- Setelah motor6D kembali aktif, snap keeper ke base position agar
		-- tidak stuck di pose ragdoll yang acak (bisa hilang dari view)
		if self.BaseCFrame then
			ApplyPivot(keeperModel, self.BaseCFrame)
		end

		-- Anchor HumanoidRootPart agar tidak jatuh setelah cleanup
		local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			root.Anchored = true
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function MatchKeeperPresentationController:_cleanupActivePowerBreakthroughRagdoll()
	local state = self.ActivePowerBreakthroughRagdoll
	if not state then
		return
	end

	self.ActivePowerBreakthroughRagdoll = nil

	if state.RenderStepName then
		pcall(function()
			RunService:UnbindFromRenderStep(state.RenderStepName)
		end)
	end

	if state.HeartbeatConnection then
		state.HeartbeatConnection:Disconnect()
	end

	local ragdoll = state.Ragdoll
	if ragdoll then
		pcall(function()
			ragdoll:disableRagdoll()
		end)
	end

	if state.PartStates then
		for part, oldState in pairs(state.PartStates) do
			if part and part.Parent and part:IsA("BasePart") and type(oldState) == "table" then
				part.CanCollide = oldState.CanCollide == true
				part.CanTouch = oldState.CanTouch == true
				part.CanQuery = oldState.CanQuery == true
				if type(oldState.CollisionGroup) == "string" then
					part.CollisionGroup = oldState.CollisionGroup
				end
				if type(oldState.Massless) == "boolean" then
					part.Massless = oldState.Massless
				end
				if type(oldState.Anchored) == "boolean" then
					part.Anchored = oldState.Anchored
				end
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	if state.AnchorStates then
		for part, oldAnchored in pairs(state.AnchorStates) do
			if part and part.Parent and part:IsA("BasePart") then
				part.Anchored = oldAnchored == true
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end

	local keeperModel = GetKeeperModel()
	if keeperModel then
		keeperModel:SetAttribute("IsPowerBreakthroughRagdoll", nil)
	end
end

function MatchKeeperPresentationController:_triggerPowerBreakthroughRagdoll(keeperModel, reactionId, reactionData)
	if not ShouldUsePowerBreakthroughRagdoll() then
		return false
	end

	if not keeperModel or not keeperModel.Parent then
		return false
	end

	reactionId = tonumber(reactionId) or self.ReactionId
	if self.ReactionId ~= reactionId or self.State ~= "React" then
		return false
	end

	local activeState = self.ActivePowerBreakthroughRagdoll
	if activeState and activeState.ReactionId == reactionId then
		return true
	end

	self:_stopPowerBreakthroughPushback(reactionId)
	self:_cleanupActivePowerBreakthroughRagdoll()

	-- Impact ragdoll should be physics-led: no PivotTo fall, no forced grounded target.
	self:_restoreCinematicPartStates()
	self:_clearTweenState()

	local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
	local rootCFrame = (root and root:IsA("BasePart") and root.CFrame)
		or GetInstanceCFrame(keeperModel)
		or self.BaseCFrame
		or CFrame.new()

	local forwardVector = reactionData and reactionData.ForwardVector or rootCFrame.LookVector
	if typeof(forwardVector) ~= "Vector3" or forwardVector.Magnitude <= 0.001 then
		forwardVector = rootCFrame.LookVector
	end
	forwardVector = GetFlatUnit(forwardVector)

	local horizontalDirection, directionSource =
		ResolvePowerBreakthroughRagdollDirection(rootCFrame, forwardVector, self.BaseLookVector)
	local lockedFacingVector = reactionData and reactionData.PowerBreakthroughLockedFacingVector
		or rootCFrame.LookVector
	if typeof(lockedFacingVector) ~= "Vector3" or lockedFacingVector.Magnitude <= 0.001 then
		lockedFacingVector = rootCFrame.LookVector
	end
	lockedFacingVector = GetFlatUnit(lockedFacingVector)

	local anchorStates = {}
	local partStates = {}
	local ragdollCanCollide = MatchKeeperConfig.PowerBreakthroughRagdollCanCollide ~= false
	for _, descendant in ipairs(keeperModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			anchorStates[descendant] = descendant.Anchored
			partStates[descendant] = {
				Anchored = descendant.Anchored,
				CanCollide = descendant.CanCollide,
				CanTouch = descendant.CanTouch,
				CanQuery = descendant.CanQuery,
				CollisionGroup = descendant.CollisionGroup,
				Massless = descendant.Massless,
			}
			descendant.Anchored = false
			descendant.CanCollide = ragdollCanCollide
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local humanoid = keeperModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop(0.04)
				end)
			end
		end

		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end

	local ragdoll = nil
	if MatchKeeperConfig.PowerBreakthroughUsePhysicsRagdoll == true then
		ragdoll = RagdollModule.new(keeperModel, {
			CanCollide = ragdollCanCollide,
			CanTouch = false,
			CanQuery = false,
		})
		local ragdollOk = pcall(function()
			ragdoll:enableRagdoll()
		end)
		if not ragdollOk then
			for part, oldAnchored in pairs(anchorStates) do
				if part and part.Parent and part:IsA("BasePart") then
					part.Anchored = oldAnchored == true
				end
			end
			for part, oldState in pairs(partStates) do
				if part and part.Parent and part:IsA("BasePart") and type(oldState) == "table" then
					part.CanCollide = oldState.CanCollide == true
					part.CanTouch = oldState.CanTouch == true
					part.CanQuery = oldState.CanQuery == true
				end
			end
			return false
		end
	end

	local horizontalSpeed = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollHorizontalSpeed) or 28, 0)
	local sideSpeed = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollSideSpeed) or 0, 0)
	local upwardSpeed = tonumber(MatchKeeperConfig.PowerBreakthroughRagdollUpwardSpeed) or -1.25
	local angularSpeed = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollAngularSpeed) or 7, 0)
	local sideAxis = horizontalDirection:Cross(Vector3.yAxis)
	if sideAxis.Magnitude <= 0.001 then
		sideAxis = rootCFrame.RightVector
	end
	sideAxis = GetFlatUnit(sideAxis)
	local sideSign = ((reactionId % 2) == 0) and 1 or -1
	local impulseVelocity = (horizontalDirection * horizontalSpeed)
		+ (sideAxis * sideSpeed * sideSign)
		+ Vector3.new(0, upwardSpeed, 0)
	local angularAxis = GetFlatUnit(rootCFrame.RightVector + (sideAxis * 0.35 * sideSign))
	local angularVelocity = angularAxis * angularSpeed

	if MatchKeeperConfig.PowerBreakthroughRagdollApplyVelocity ~= false then
		for part in pairs(partStates) do
			if part and part.Parent and part:IsA("BasePart") then
				part.AssemblyLinearVelocity = impulseVelocity
				part.AssemblyAngularVelocity = angularVelocity
			end
		end
	end

	local renderStepName =
		string.format("KeeperPowerBreakthroughNaturalRagdoll_%d_%s", reactionId, tostring(os.clock()):gsub("%.", "_"))
	local ceilingHeight = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollCeilingHeight) or 1.25, 0.15)
	local maxPartLift = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughRagdollMaxPartLift) or 1.55, 0.5)
	local baseRootY = (root and root:IsA("BasePart") and root.Position.Y) or rootCFrame.Position.Y
	local fieldY = self.BaseCFrame and self.BaseCFrame.Position.Y or baseRootY
	local initialHighestY = GetModelHighestY(keeperModel)
	if initialHighestY == -math.huge then
		initialHighestY = baseRootY + 4.0
	end
	local ceilingY = baseRootY + ceilingHeight
	local rootMinY = fieldY + (tonumber(MatchKeeperConfig.PowerBreakthroughRagdollRootMinY) or -0.25)
	local rootMaxY = math.max(baseRootY, fieldY)
		+ (tonumber(MatchKeeperConfig.PowerBreakthroughRagdollRootMaxY) or 0.18)
	if rootMinY > rootMaxY then
		rootMinY, rootMaxY = rootMaxY, rootMinY
	end

	self.ActivePowerBreakthroughRagdoll = {
		ReactionId = reactionId,
		Ragdoll = ragdoll,
		AnchorStates = anchorStates,
		PartStates = partStates,
		RenderStepName = renderStepName,
	}

	pcall(function()
		RunService:UnbindFromRenderStep(renderStepName)
	end)

	local lastTime = os.clock()
	local wasGrounded = false
	local function enforceVerticalLane()
		if self.ReactionId ~= reactionId or self.State ~= "React" or not keeperModel.Parent then
			self:_cleanupActivePowerBreakthroughRagdoll()
			return
		end

		local now = os.clock()
		local dt = math.min(now - lastTime, 0.1)
		lastTime = now

		local rootPart = root
		if not rootPart or not rootPart.Parent or not rootPart:IsA("BasePart") then
			rootPart = keeperModel:FindFirstChild("HumanoidRootPart", true)
		end

		local isGrounded = false
		if rootPart and rootPart:IsA("BasePart") then
			if rootPart.Position.Y <= rootMinY + 0.35 then
				isGrounded = true
			end
		end

		if isGrounded and not wasGrounded then
			wasGrounded = true
			ShakeCamera(1.85, 0.4)

			-- The user requested the ground to be a "neutralizer".
			-- We kill all physics by anchoring the ragdoll exactly as it lands to prevent any bouncing into the crossbar.
			for part in pairs(partStates) do
				if part and part.Parent and part:IsA("BasePart") then
					part.Anchored = true
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end

		local drag = isGrounded and 8.0 or 1.2
		local gravity = isGrounded and 0 or 45

		for part in pairs(partStates) do
			if part and part.Parent and part:IsA("BasePart") then
				local velocity = part.AssemblyLinearVelocity
				local vx = velocity.X * math.exp(-drag * dt)
				local vz = velocity.Z * math.exp(-drag * dt)
				local vy = velocity.Y - (gravity * dt)
				if isGrounded and vy < 0 then
					vy = 0
				end

				-- Speed Cap: Keep horizontal speed <= 10 studs/s, and vertical speed <= 0
				local horiz = Vector2.new(vx, vz)
				if horiz.Magnitude > 10 then
					horiz = horiz.Unit * 10
				end

				part.AssemblyLinearVelocity = Vector3.new(horiz.X, vy, horiz.Y)
			end
		end

		-- Removed manual ApplyPivot clamping to prevent physics explosions on active ragdolls.
		-- The Roblox physics engine will naturally resolve ground collisions since CanCollide is enabled.
	end

	self.ActivePowerBreakthroughRagdoll.HeartbeatConnection = RunService.Heartbeat:Connect(enforceVerticalLane)
	RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value + 88, enforceVerticalLane)

	keeperModel:SetAttribute("IsPowerBreakthroughRagdoll", true)

	if MatchKeeperConfig.DebugKeeperFailedSave == true then
		print(
			string.format(
				"[KeeperFail] natural ragdoll reaction=%s source=%s speed=%.2f up=%.2f collidable=%s",
				tostring(reactionId),
				tostring(directionSource),
				horizontalSpeed,
				upwardSpeed,
				tostring(ragdollCanCollide)
			)
		)
	end

	return true
end

function MatchKeeperPresentationController:_beginPowerBreakthroughPushback(keeperModel, reactionId, reactionData)
	if not keeperModel or not keeperModel.Parent then
		return nil
	end

	reactionId = tonumber(reactionId) or self.ReactionId
	if not self.PowerBreakthroughPushbackByReactionId then
		self.PowerBreakthroughPushbackByReactionId = {}
	end
	if not self.PowerBreakthroughBoundNamesByReactionId then
		self.PowerBreakthroughBoundNamesByReactionId = {}
	end

	local existingState = self.PowerBreakthroughPushbackByReactionId[reactionId]
	if existingState then
		if reactionData and existingState.TargetCFrame then
			reactionData.LandedCFrame = existingState.TargetCFrame
		end
		return existingState
	end

	if MatchKeeperConfig.PowerBreakthroughDisableKeeperCollision ~= false then
		self:_setCinematicPartCollision(
			keeperModel,
			MatchKeeperConfig.PowerBreakthroughCollisionEnabled == true,
			MatchKeeperConfig.PowerBreakthroughTouchEnabled == true
		)
	end

	local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	local startCFrame = GetInstanceCFrame(keeperModel)
		or (reactionData and reactionData.InterceptCFrame)
		or self.BaseCFrame

	if reactionData and startCFrame then
		-- Lock facing once at contact. Movement goes backward, rotation stays facing the shooter/field.
		reactionData.PowerBreakthroughLockedFacingVector = GetFlatUnit(startCFrame.LookVector)
	end

	local pushbackCFrame = self:_buildPowerBreakthroughPushbackCFrame(keeperModel, reactionData or {})
	if not pushbackCFrame then
		return nil
	end

	local pushbackDuration = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackDuration) or 0.52, 0.05)
	local renderStepName =
		string.format("KeeperPowerBreakthroughPushback_%d_%s", reactionId, tostring(os.clock()):gsub("%.", "_"))
	local state = {
		StartedAt = os.clock(),
		Duration = pushbackDuration,
		StartCFrame = startCFrame or pushbackCFrame,
		TargetCFrame = pushbackCFrame,
		RenderStepName = renderStepName,
		Completed = false,
	}

	self.PowerBreakthroughPushbackByReactionId[reactionId] = state
	self.PowerBreakthroughBoundNamesByReactionId[reactionId] = renderStepName

	if reactionData then
		reactionData.LandedCFrame = pushbackCFrame
	end

	-- Do not use TweenService here. Keeper pushback has to win against any late
	-- presentation update that may also pivot the keeper this frame. Binding after
	-- normal RenderStepped loops makes this cinematic pose authoritative locally.
	pcall(function()
		RunService:UnbindFromRenderStep(renderStepName)
	end)

	RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value + 80, function()
		if self.ReactionId ~= reactionId or self.State ~= "React" or not keeperModel.Parent then
			self:_stopPowerBreakthroughPushback(reactionId)
			return
		end

		local currentRoot = keeperModel:FindFirstChild("HumanoidRootPart", true)
		if currentRoot and currentRoot:IsA("BasePart") then
			currentRoot.Anchored = true
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
		end

		local elapsed = os.clock() - state.StartedAt
		local alpha = math.clamp(elapsed / state.Duration, 0, 1)
		local easedAlpha = 1 - math.pow(1 - alpha, 2)

		local nextCFrame
		if alpha < 1 then
			nextCFrame = state.StartCFrame:Lerp(state.TargetCFrame, easedAlpha)
		else
			state.Completed = true
			nextCFrame = state.TargetCFrame
		end

		ApplyPivot(keeperModel, nextCFrame)
	end)

	if MatchKeeperConfig.DebugKeeperFailedSave == true then
		print(
			string.format(
				"[KeeperFail] forcedPushbackBind reaction=%s distance=%.2f duration=%.2f",
				tostring(reactionId),
				tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackDistance) or 3.35,
				pushbackDuration
			)
		)
	end

	return state
end

function MatchKeeperPresentationController:_playPivotTween(instance, targetCFrame, tweenInfo)
	if not instance or not targetCFrame then
		return nil
	end

	self:_clearTweenState()

	local startCFrame = GetInstanceCFrame(instance)
	if not startCFrame then
		ApplyPivot(instance, targetCFrame)
		return nil
	end

	local tweenValue = Instance.new("CFrameValue")
	tweenValue.Value = startCFrame
	tweenValue.Parent = instance

	self.TweenValue = tweenValue
	self.TweenConnection = tweenValue.Changed:Connect(function(nextCFrame)
		if instance.Parent then
			ApplyPivot(instance, nextCFrame)
		end
	end)

	local tween = TweenService:Create(tweenValue, tweenInfo, { Value = targetCFrame })
	self.ActiveTween = tween

	tween.Completed:Connect(function()
		if self.ActiveTween == tween then
			self:_clearTweenState()
		end
	end)

	tween:Play()
	return tween
end

local function BuildConfigFallbackAnimation(requestedName, isLeft)
	local animationId = nil

	if requestedName == "Idle" then
		animationId = MatchKeeperConfig.IdleAnimId
	elseif requestedName == "Jump" then
		animationId = isLeft and MatchKeeperConfig.DiveLeftAnimId or MatchKeeperConfig.DiveRightAnimId
	elseif requestedName == "DefendLeft" then
		animationId = MatchKeeperConfig.DiveLeftAnimId
	elseif requestedName == "DefendRight" then
		animationId = MatchKeeperConfig.DiveRightAnimId
	elseif requestedName == "DefendFront" then
		animationId = MatchKeeperConfig.DefendFrontAnimId or MatchKeeperConfig.IdleAnimId
	elseif requestedName == "DefendUp" then
		animationId = MatchKeeperConfig.DefendUpAnimId or MatchKeeperConfig.IdleAnimId
	elseif requestedName == "Win" then
		animationId = MatchKeeperConfig.WinAnimId
	elseif requestedName == "Lose" then
		animationId = MatchKeeperConfig.LoseAnimId
	end

	if not animationId or animationId == "" then
		return nil
	end

	local anim = Instance.new("Animation")
	anim.Name = "ConfigFallback_" .. requestedName
	anim.AnimationId = animationId
	return anim
end

function MatchKeeperPresentationController:_playAnimation(model, requestedName, speed, options)
	if not model then
		return
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		local carrier = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController")

		if not carrier then
			carrier = Instance.new("AnimationController")
			carrier.Parent = model
		end

		animator = Instance.new("Animator")
		animator.Parent = carrier
	end

	local animFolder = model:FindFirstChild("Animations") or model:FindFirstChild("Animations", true)

	local candidates = { requestedName }
	if requestedName == "Run" then
		table.insert(candidates, "Jogging")
		table.insert(candidates, "Walk")
	elseif requestedName == "Jump" then
		table.insert(candidates, "Dive")
		table.insert(candidates, (options and options.IsLeft) and "DefendLeft" or "DefendRight")
	elseif requestedName == "DefendLeft" then
		table.insert(candidates, "DiveLeft")
		table.insert(candidates, "LeftDive")
		table.insert(candidates, "SaveLeft")
		table.insert(candidates, "Jump")
	elseif requestedName == "DefendRight" then
		table.insert(candidates, "DiveRight")
		table.insert(candidates, "RightDive")
		table.insert(candidates, "SaveRight")
		table.insert(candidates, "Jump")
	elseif requestedName == "DefendFront" then
		table.insert(candidates, "Defend")
		table.insert(candidates, "BlockFront")
		table.insert(candidates, "SaveFront")
		table.insert(candidates, "Idle")
	elseif requestedName == "DefendUp" then
		table.insert(candidates, "BlockUp")
		table.insert(candidates, "SaveUp")
		table.insert(candidates, "Jump")
	elseif requestedName == "Win" then
		table.insert(candidates, "Win1")
		table.insert(candidates, "Win2")
		table.insert(candidates, "Celebrate")
	elseif requestedName == "Lose" then
		table.insert(candidates, "Lose1")
		table.insert(candidates, "Lose2")
	end

	local animObj = nil
	local actualName = nil

	if animFolder then
		for _, candidate in ipairs(candidates) do
			local found = animFolder:FindFirstChild(candidate)
			if found and found:IsA("Animation") then
				animObj = found
				actualName = candidate
				break
			end
		end
	end

	if not animObj then
		animObj = BuildConfigFallbackAnimation(requestedName, options and options.IsLeft)
		actualName = requestedName
	end

	if not animObj then
		return
	end

	local currentTrack = nil
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Name == actualName then
			currentTrack = track
			break
		end
	end

	if not currentTrack then
		currentTrack = animator:LoadAnimation(animObj)
		currentTrack.Name = actualName
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track ~= currentTrack then
			track:Stop(0.12)
		end
	end

	currentTrack.Looped = (requestedName == "Idle" or requestedName == "Run")
	currentTrack:AdjustSpeed(speed or 1)

	if not currentTrack.IsPlaying then
		currentTrack:Play(0.12)
	end

	return currentTrack, actualName
end

local function FindFirstAttachmentByNames(root, names)
	if not root or type(names) ~= "table" then
		return nil
	end

	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, true)
		if found and found:IsA("Attachment") then
			return found
		end
	end

	return nil
end

local function ResolveGripContactAttachment(keeperModel, shotTargetId, contactMode, ballTargetPosition)
	if not keeperModel or MatchKeeperConfig.KeeperUseGripAttachmentsForCatch == false then
		return nil
	end

	local targetId = string.lower(tostring(shotTargetId or ""))
	local preferLeft = targetId:find("left") ~= nil
	local preferRight = targetId:find("right") ~= nil

	local leftGrip = FindFirstAttachmentByNames(keeperModel, {
		"LeftGripAttachment",
		"LeftWristRigAttachment",
		"LeftHandCatchAttachment",
		"LeftBallCatchAttachment",
	})

	local rightGrip = FindFirstAttachmentByNames(keeperModel, {
		"RightGripAttachment",
		"RightWristRigAttachment",
		"RightHandCatchAttachment",
		"RightBallCatchAttachment",
	})

	if preferLeft and leftGrip then
		return leftGrip
	end

	if preferRight and rightGrip then
		return rightGrip
	end

	if contactMode == "Parry" then
		return leftGrip or rightGrip
	end

	-- Center/front/up catch: choose the grip closest to the incoming ball.
	if leftGrip and rightGrip and typeof(ballTargetPosition) == "Vector3" then
		local leftDistance = (leftGrip.WorldPosition - ballTargetPosition).Magnitude
		local rightDistance = (rightGrip.WorldPosition - ballTargetPosition).Magnitude
		return leftDistance <= rightDistance and leftGrip or rightGrip
	end

	return rightGrip or leftGrip
end

local function ResolveGripContactWorldPosition(keeperModel, shotTargetId, contactMode, ballTargetPosition)
	local gripAttachment = ResolveGripContactAttachment(keeperModel, shotTargetId, contactMode, ballTargetPosition)
	if gripAttachment then
		return gripAttachment.WorldPosition
	end

	-- Keep this helper independent from ResolveKeeperContactTarget so it can be used
	-- before contact payload resolution is declared.
	local targetId = string.lower(tostring(shotTargetId or ""))
	local candidateNames
	if targetId:find("left") then
		candidateNames = { "LeftHand", "LeftLowerArm", "LeftUpperArm", "UpperTorso", "HumanoidRootPart" }
	elseif targetId:find("right") then
		candidateNames = { "RightHand", "RightLowerArm", "RightUpperArm", "UpperTorso", "HumanoidRootPart" }
	else
		candidateNames = { "RightHand", "LeftHand", "UpperTorso", "HumanoidRootPart" }
	end

	local bestPart = nil
	local bestDistance = math.huge
	for _, partName in ipairs(candidateNames) do
		local part = keeperModel:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			local distance = typeof(ballTargetPosition) == "Vector3" and (part.Position - ballTargetPosition).Magnitude
				or 0
			if distance < bestDistance then
				bestPart = part
				bestDistance = distance
			end
		end
	end

	return bestPart and bestPart.Position or nil
end

local function IsCenterShotTargetId(shotTargetId)
	local targetId = string.lower(tostring(shotTargetId or ""))

	return targetId == ""
		or targetId == "center"
		or targetId:find("center") ~= nil
		or (not targetId:find("left") and not targetId:find("right"))
end

local function ResolveCenterGripCFrameProvider(keeperModel, fallbackCFrame)
	if not keeperModel or MatchKeeperConfig.KeeperCenterCatchUseMovingMidpoint == false then
		return nil, nil
	end

	local leftGrip = FindFirstAttachmentByNames(keeperModel, {
		"LeftGripAttachment",
		"LeftWristRigAttachment",
		"LeftHandCatchAttachment",
		"LeftBallCatchAttachment",
	})

	local rightGrip = FindFirstAttachmentByNames(keeperModel, {
		"RightGripAttachment",
		"RightWristRigAttachment",
		"RightHandCatchAttachment",
		"RightBallCatchAttachment",
	})

	local leftTarget = leftGrip
	local rightTarget = rightGrip

	if not leftTarget then
		leftTarget = keeperModel:FindFirstChild("LeftHand", true) or keeperModel:FindFirstChild("LeftLowerArm", true)
	end

	if not rightTarget then
		rightTarget = keeperModel:FindFirstChild("RightHand", true) or keeperModel:FindFirstChild("RightLowerArm", true)
	end

	if not leftTarget or not rightTarget then
		return nil, nil
	end

	local function getWorldPosition(target)
		if target and target.Parent then
			if target:IsA("Attachment") then
				return target.WorldPosition
			end

			if target:IsA("BasePart") then
				return target.Position
			end
		end

		return nil
	end

	local function resolveCenterForwardVector()
		local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
		local rootCFrame = if root and root:IsA("BasePart") then root.CFrame else GetInstanceCFrame(keeperModel)

		if rootCFrame and fallbackCFrame then
			local toFallback = rootCFrame.Position - fallbackCFrame.Position
			local flatToFallback = Vector3.new(toFallback.X, 0, toFallback.Z)
			if flatToFallback.Magnitude > 0.001 then
				return flatToFallback.Unit
			end
		end

		if rootCFrame then
			return GetFlatUnit(rootCFrame.LookVector)
		end

		if fallbackCFrame then
			return GetFlatUnit(fallbackCFrame.LookVector)
		end

		return DEFAULT_FORWARD
	end

	local function resolveMidpointCFrame()
		local leftPosition = getWorldPosition(leftTarget)
		local rightPosition = getWorldPosition(rightTarget)

		if not leftPosition or not rightPosition then
			return fallbackCFrame
		end

		local midpoint = (leftPosition + rightPosition) * 0.5
		local forwardVector = resolveCenterForwardVector()
		local centerForwardOffset = math.max(tonumber(MatchKeeperConfig.GoalHoldCenterHandForwardOffset) or 0.65, 0)
		local centerLiftOffset = tonumber(MatchKeeperConfig.GoalHoldCenterHandLiftOffset) or 0
		local contactPosition = midpoint + (forwardVector * centerForwardOffset) + Vector3.new(0, centerLiftOffset, 0)

		return CFrame.lookAt(contactPosition, contactPosition + forwardVector)
	end

	return resolveMidpointCFrame, resolveMidpointCFrame()
end

local function ResolveCenterSafeContactCFrame(keeperModel, fallbackCFrame)
	if not keeperModel then
		return nil
	end

	local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
	local rootCFrame = (root and root:IsA("BasePart") and root.CFrame)
		or GetInstanceCFrame(keeperModel)
		or fallbackCFrame

	if not rootCFrame then
		return fallbackCFrame
	end

	local forwardVector = GetFlatUnit(rootCFrame.LookVector)
	local chestPart = keeperModel:FindFirstChild("UpperTorso", true)
		or keeperModel:FindFirstChild("Torso", true)
		or keeperModel:FindFirstChild("Head", true)

	local rootY = rootCFrame.Position.Y
	local minHeight = tonumber(MatchKeeperConfig.CenterContactMinHeight) or 1.20
	local maxHeight = tonumber(MatchKeeperConfig.CenterContactMaxHeight) or 1.75
	local fallbackHeight = tonumber(MatchKeeperConfig.CenterContactHeight) or 1.42
	local chestY = rootY + fallbackHeight

	if chestPart and chestPart:IsA("BasePart") then
		chestY = math.clamp(chestPart.Position.Y, rootY + minHeight, rootY + maxHeight)
	end

	local forwardOffset = tonumber(MatchKeeperConfig.CenterContactForwardOffset) or 0.62
	local position = Vector3.new(rootCFrame.Position.X, chestY, rootCFrame.Position.Z) + (forwardVector * forwardOffset)

	return CFrame.lookAt(position, position + forwardVector)
end

local function ResolveCenterSafeContactCFrameProvider(keeperModel, fallbackCFrame)
	local function resolveContactCFrame()
		return ResolveCenterSafeContactCFrame(keeperModel, fallbackCFrame)
	end

	local currentCFrame = resolveContactCFrame()
	if not currentCFrame then
		return nil, nil
	end

	return resolveContactCFrame, currentCFrame
end

local function BuildKeeperRootPositionForSaveTarget(
	keeperModel,
	baseCFrame,
	saveTargetPosition,
	shotTargetId,
	contactMode
)
	if not keeperModel or typeof(saveTargetPosition) ~= "Vector3" then
		return nil
	end

	local currentPivot = GetInstanceCFrame(keeperModel) or baseCFrame
	if not currentPivot then
		return nil
	end

	local contactWorldPosition =
		ResolveGripContactWorldPosition(keeperModel, shotTargetId, contactMode, saveTargetPosition)

	if not contactWorldPosition then
		return nil
	end

	-- Preserve the current hand/grip offset from the model pivot, then move the root
	-- so that the chosen hand actually reaches KeeperSaveTargets.<TargetId>.
	local contactOffsetFromPivot = contactWorldPosition - currentPivot.Position
	return saveTargetPosition - contactOffsetFromPivot
end

local function AlignKeeperGripToSaveTargetAtContact(keeperModel, reactionData, fallbackTargetPosition)
	if not keeperModel or not reactionData then
		return GetInstanceCFrame(keeperModel)
	end

	if MatchKeeperConfig.KeeperSaveTargetContactGripCorrectionEnabled == false then
		return GetInstanceCFrame(keeperModel)
	end

	local saveTargetPosition = reactionData.KeeperSaveTargetPosition
	if typeof(saveTargetPosition) ~= "Vector3" then
		saveTargetPosition = fallbackTargetPosition
	end

	if typeof(saveTargetPosition) ~= "Vector3" then
		return GetInstanceCFrame(keeperModel)
	end

	local currentPivot = GetInstanceCFrame(keeperModel)
	if not currentPivot then
		return nil
	end

	local contactWorldPosition = ResolveGripContactWorldPosition(
		keeperModel,
		reactionData.ShotTargetId,
		reactionData.ContactMode,
		saveTargetPosition
	)

	if not contactWorldPosition then
		return currentPivot
	end

	local correction = saveTargetPosition - contactWorldPosition
	local maxCorrection = tonumber(MatchKeeperConfig.KeeperSaveTargetContactMaxCorrection) or 7.5
	if correction.Magnitude > maxCorrection and correction.Magnitude > 0.001 then
		correction = correction.Unit * maxCorrection
	end

	local alpha = math.clamp(tonumber(MatchKeeperConfig.KeeperSaveTargetContactCorrectionAlpha) or 1.0, 0, 1)
	local correctedCFrame = currentPivot + (correction * alpha)

	ApplyPivot(keeperModel, correctedCFrame)

	return correctedCFrame
end

local function ResolveKeeperContactTarget(keeperModel, reactionData, ballTargetPosition)
	if not keeperModel then
		return nil, nil
	end

	if
		reactionData
		and (
			reactionData.ContactMode == "Catch"
			or reactionData.ContactMode == "Breakthrough"
			or reactionData.ContactMode == "GoalHold"
		)
		and IsCenterShotTargetId(reactionData.ShotTargetId)
	then
		local midpointProvider, midpointCFrame = ResolveCenterGripCFrameProvider(
			keeperModel,
			typeof(ballTargetPosition) == "Vector3" and CFrame.new(ballTargetPosition) or nil
		)

		if midpointProvider and midpointCFrame then
			return midpointProvider, midpointCFrame
		end

		local safeContactProvider, safeContactCFrame = ResolveCenterSafeContactCFrameProvider(
			keeperModel,
			typeof(ballTargetPosition) == "Vector3" and CFrame.new(ballTargetPosition) or nil
		)

		if safeContactCFrame then
			return safeContactProvider, safeContactCFrame
		end
	end

	local gripAttachment = ResolveGripContactAttachment(
		keeperModel,
		reactionData and reactionData.ShotTargetId,
		reactionData and reactionData.ContactMode,
		ballTargetPosition
	)

	if gripAttachment then
		return gripAttachment, gripAttachment.WorldCFrame
	end

	local preferredAttachmentNames = {
		"BallCatchAttachment",
		"KeeperCatchAttachment",
		"CatchAttachment",
		"BallHoldAttachment",
		"SaveContactAttachment",
	}

	local bestAttachment = nil
	local bestAttachmentDistance = math.huge

	for _, descendant in ipairs(keeperModel:GetDescendants()) do
		if descendant:IsA("Attachment") then
			for _, attachmentName in ipairs(preferredAttachmentNames) do
				if descendant.Name == attachmentName then
					local distance = (descendant.WorldPosition - ballTargetPosition).Magnitude
					if distance < bestAttachmentDistance then
						bestAttachment = descendant
						bestAttachmentDistance = distance
					end
				end
			end
		end
	end

	if bestAttachment then
		return bestAttachment, bestAttachment.WorldCFrame
	end

	local candidateNames
	if reactionData and reactionData.ContactMode == "Parry" then
		candidateNames = reactionData.IsLeft
				and { "LeftHand", "LeftLowerArm", "LeftUpperArm", "UpperTorso", "HumanoidRootPart" }
			or { "RightHand", "RightLowerArm", "RightUpperArm", "UpperTorso", "HumanoidRootPart" }
	else
		candidateNames = {
			"RightHand",
			"LeftHand",
			"RightLowerArm",
			"LeftLowerArm",
			"UpperTorso",
			"HumanoidRootPart",
		}
	end

	local bestPart = nil
	local bestDistance = math.huge

	for _, partName in ipairs(candidateNames) do
		local part = keeperModel:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			local distance = (part.Position - ballTargetPosition).Magnitude
			if distance < bestDistance then
				bestPart = part
				bestDistance = distance
			end
		end
	end

	if bestPart then
		return bestPart, bestPart.CFrame
	end

	local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		return root, root.CFrame
	end

	return keeperModel, keeperModel:GetPivot()
end

local function ResolveSimpleTargetCFrame(target, fallbackCFrame)
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
				return ResolveSimpleTargetCFrame(resolved, fallbackCFrame)
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

local function BuildPowerBreakthroughBallTargetProvider(keeperModel, reactionData, baseTarget, fallbackCFrame)
	if not keeperModel or not reactionData or reactionData.ContactMode ~= "Breakthrough" then
		return baseTarget, fallbackCFrame
	end

	local forwardOffset = tonumber(MatchKeeperConfig.PowerBreakthroughBallForwardOffset) or 0.82
	local liftOffset = tonumber(MatchKeeperConfig.PowerBreakthroughBallLiftOffset) or 0.04
	local useExactGripTarget = MatchKeeperConfig.PowerBreakthroughUseExactGripTarget ~= false
	local fallback = fallbackCFrame or GetInstanceCFrame(keeperModel) or CFrame.new()

	local function resolveBallCFrame()
		local baseCFrame = ResolveSimpleTargetCFrame(baseTarget, fallback) or fallback
		local forwardVector = reactionData.PowerBreakthroughLockedFacingVector or reactionData.ForwardVector

		if typeof(forwardVector) ~= "Vector3" or forwardVector.Magnitude <= 0.001 then
			local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
			if root and root:IsA("BasePart") then
				forwardVector = root.CFrame.LookVector
			else
				forwardVector = baseCFrame.LookVector
			end
		end

		forwardVector = GetFlatUnit(forwardVector)

		-- Center breakthrough must read like a catch first: the ball sticks to the same
		-- moving hand/midpoint target used by real keeper saves. The old forward offset
		-- made the ball float in front of the torso instead of being held by the hands.
		if useExactGripTarget and IsCenterShotTargetId(reactionData.ShotTargetId) then
			local gripLiftOffset = tonumber(MatchKeeperConfig.PowerBreakthroughBallGripLiftOffset) or 0
			local gripPosition = baseCFrame.Position + Vector3.new(0, gripLiftOffset, 0)
			return CFrame.lookAt(gripPosition, gripPosition + forwardVector)
		end

		local position = baseCFrame.Position + (forwardVector * forwardOffset) + Vector3.new(0, liftOffset, 0)

		return CFrame.lookAt(position, position + forwardVector)
	end

	return resolveBallCFrame, resolveBallCFrame()
end

local function BuildKeeperContactPayload(keeperModel, reactionId, reactionData, ballTargetPosition, reason, parameter)
	local targetInstance, contactCFrame = ResolveKeeperContactTarget(keeperModel, reactionData, ballTargetPosition)
	targetInstance, contactCFrame =
		BuildPowerBreakthroughBallTargetProvider(keeperModel, reactionData, targetInstance, contactCFrame)

	return {
		KeeperModel = keeperModel,
		ReactionId = reactionId,
		ContactMode = reactionData and reactionData.ContactMode or nil,
		AnimationName = reactionData and reactionData.ReactionAnimation or nil,
		ShotTargetId = reactionData and reactionData.ShotTargetId or nil,
		TargetInstance = targetInstance,
		ContactCFrame = contactCFrame,
		ContactPosition = contactCFrame and contactCFrame.Position or ballTargetPosition,
		Reason = reason or "marker",
		Parameter = parameter,
	}
end

function MatchKeeperPresentationController:ResolvePowerBreakthroughContactPayload(
	contactPayload,
	ballTargetPosition,
	shotTargetId
)
	local keeperModel = type(contactPayload) == "table" and contactPayload.KeeperModel or nil
	if not keeperModel or not keeperModel.Parent then
		keeperModel = GetKeeperModel()
	end

	if not keeperModel then
		return contactPayload
	end

	local targetPosition = ballTargetPosition
	if typeof(targetPosition) ~= "Vector3" then
		targetPosition = type(contactPayload) == "table" and contactPayload.ContactPosition or nil
	end
	if typeof(targetPosition) ~= "Vector3" then
		local keeperCFrame = GetInstanceCFrame(keeperModel)
		targetPosition = keeperCFrame and keeperCFrame.Position or Vector3.zero
	end

	local reactionData = {
		ContactMode = "Breakthrough",
		ShotTargetId = shotTargetId or (type(contactPayload) == "table" and contactPayload.ShotTargetId),
		KeeperSaveTargetPosition = targetPosition,
	}

	local targetInstance, contactCFrame = ResolveKeeperContactTarget(keeperModel, reactionData, targetPosition)
	targetInstance, contactCFrame =
		BuildPowerBreakthroughBallTargetProvider(keeperModel, reactionData, targetInstance, contactCFrame)

	local resolvedPayload = {}
	if type(contactPayload) == "table" then
		for key, value in pairs(contactPayload) do
			resolvedPayload[key] = value
		end
	end

	resolvedPayload.KeeperModel = keeperModel
	resolvedPayload.ReactionId = self.State == "React" and self.ReactionId
		or (resolvedPayload.ReactionId or self.ReactionId)
	resolvedPayload.ContactMode = "Breakthrough"
	resolvedPayload.ShotTargetId = reactionData.ShotTargetId
	resolvedPayload.TargetInstance = targetInstance
	resolvedPayload.ContactCFrame = contactCFrame
	resolvedPayload.ContactPosition = contactCFrame and contactCFrame.Position or targetPosition

	return resolvedPayload
end

function MatchKeeperPresentationController:TriggerPowerBreakthroughImpactRagdoll(contactPayload, options)
	options = options or {}

	if not ShouldUsePowerBreakthroughRagdoll() then
		return false
	end

	local keeperModel = type(contactPayload) == "table" and contactPayload.KeeperModel or nil
	if not keeperModel or not keeperModel.Parent then
		keeperModel = GetKeeperModel()
	end

	if not keeperModel or not keeperModel.Parent then
		return false
	end

	local currentCFrame = GetInstanceCFrame(keeperModel) or self.BaseCFrame or CFrame.new()
	local forwardVector = options.ForwardVector
	if typeof(forwardVector) ~= "Vector3" or forwardVector.Magnitude <= 0.001 then
		forwardVector = self.BaseLookVector or currentCFrame.LookVector or DEFAULT_FORWARD
	end

	local reactionData = type(options.ReactionData) == "table" and options.ReactionData or {}
	reactionData.ForwardVector = reactionData.ForwardVector or GetFlatUnit(forwardVector)
	reactionData.PowerBreakthroughLockedFacingVector = reactionData.PowerBreakthroughLockedFacingVector
		or GetFlatUnit(currentCFrame.LookVector)
	reactionData.KeeperSaveTargetPosition = type(contactPayload) == "table" and contactPayload.ContactPosition or nil
	reactionData.PowerBreakthrough = true
	reactionData.ContactMode = "Breakthrough"

	local reactionId = self.State == "React" and self.ReactionId
		or tonumber(type(contactPayload) == "table" and contactPayload.ReactionId)
		or self.ReactionId

	if self.State ~= "React" then
		return false
	end

	return self:_triggerPowerBreakthroughRagdoll(keeperModel, reactionId, reactionData)
end

function MatchKeeperPresentationController:ForcePowerBreakthroughPushback(contactPayload, options)
	local keeperModel = type(contactPayload) == "table" and contactPayload.KeeperModel or nil
	if not keeperModel or not keeperModel.Parent then
		keeperModel = GetKeeperModel()
	end

	if not keeperModel then
		return nil
	end

	local reactionId = tonumber(type(contactPayload) == "table" and contactPayload.ReactionId) or self.ReactionId
	local currentCFrame = GetInstanceCFrame(keeperModel)
	local reactionData = type(options) == "table" and options.ReactionData or nil

	if not reactionData then
		reactionData = {
			InterceptCFrame = currentCFrame,
			ForwardVector = self.BaseLookVector or (currentCFrame and currentCFrame.LookVector) or DEFAULT_FORWARD,
			LandedCFrame = nil,
		}
	end

	if currentCFrame and not reactionData.InterceptCFrame then
		reactionData.InterceptCFrame = currentCFrame
	end
	if not reactionData.ForwardVector then
		reactionData.ForwardVector = self.BaseLookVector
			or (currentCFrame and currentCFrame.LookVector)
			or DEFAULT_FORWARD
	end

	local state = self:_beginPowerBreakthroughPushback(keeperModel, reactionId, reactionData)
	return state and state.TargetCFrame or nil
end

function MatchKeeperPresentationController:TriggerGoalImpactRagdoll(ballTargetPosition, shotTargetId, options)
	options = options or {}

	if MatchKeeperConfig.GoalImpactRagdollEnabled == false then
		return false
	end

	if self:_isKeeperImpactLocked() then
		return false
	end

	local keeperModel = GetKeeperModel()
	if not keeperModel or not keeperModel.Parent then
		return false
	end

	local currentCFrame = GetInstanceCFrame(keeperModel) or self.BaseCFrame
	if not currentCFrame then
		return false
	end

	self.ReactionId += 1
	local reactionId = self.ReactionId
	local impactToken = self:_beginKeeperImpactLock("GoalImpact")
	self.State = "GoalImpactRagdoll"

	if self.StandbyConnection then
		self.StandbyConnection:Disconnect()
		self.StandbyConnection = nil
	end

	self:_clearTweenState()
	self:_stopAllPowerBreakthroughPushbacks()
	self:_cleanupActivePowerBreakthroughRagdoll()
	self:_cleanupActiveGoalImpactRagdoll()
	self:_setCinematicPartCollision(keeperModel, false, false)

	local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
	local humanoid = keeperModel:FindFirstChildWhichIsA("Humanoid", true)

	local lockedFacingVector = GetFlatUnit(self.BaseLookVector or currentCFrame.LookVector)
	if lockedFacingVector.Magnitude <= 0.001 then
		lockedFacingVector = self.BaseLookVector or DEFAULT_FORWARD
	end

	local toImpact = nil
	if typeof(ballTargetPosition) == "Vector3" then
		local flatDelta = Vector3.new(
			ballTargetPosition.X - currentCFrame.Position.X,
			0,
			ballTargetPosition.Z - currentCFrame.Position.Z
		)
		if flatDelta.Magnitude > 0.001 then
			toImpact = flatDelta.Unit
		end
	end

	local rightVector = self.BaseCFrame and GetFlatUnit(self.BaseCFrame.RightVector)
		or lockedFacingVector:Cross(Vector3.yAxis)
	if rightVector.Magnitude <= 0.001 then
		rightVector = Vector3.xAxis
	else
		rightVector = rightVector.Unit
	end

	local sideSign = 0
	local targetId = string.lower(tostring(shotTargetId or ""))
	if targetId:find("left") then
		sideSign = -1
	elseif targetId:find("right") then
		sideSign = 1
	elseif toImpact then
		local sideDot = toImpact:Dot(rightVector)
		if math.abs(sideDot) > 0.05 then
			sideSign = sideDot < 0 and -1 or 1
		end
	end

	local holdDuration = math.max(tonumber(MatchKeeperConfig.GoalImpactRagdollHoldDuration) or 8.0, 0.5)
	local horizontalSpeed = math.max(tonumber(MatchKeeperConfig.GoalImpactRagdollHorizontalSpeed) or 8.0, 0)
	local sideSpeed = math.max(tonumber(MatchKeeperConfig.GoalImpactRagdollSideSpeed) or 2.5, 0)
	local upwardSpeed = tonumber(MatchKeeperConfig.GoalImpactRagdollUpwardSpeed) or 0
	local angularSpeed = math.max(tonumber(MatchKeeperConfig.GoalImpactRagdollAngularSpeed) or 2.0, 0)
	local isSideGoalImpact = sideSign ~= 0

	local forwardBlast = -lockedFacingVector
	if typeof(ballTargetPosition) == "Vector3" then
		local fromImpact = Vector3.new(
			currentCFrame.Position.X - ballTargetPosition.X,
			0,
			currentCFrame.Position.Z - ballTargetPosition.Z
		)
		if fromImpact.Magnitude > 0.001 then
			forwardBlast = fromImpact.Unit
		end
	end

	local sideBlast = sideSign ~= 0 and (rightVector * sideSign) or Vector3.zero
	local horizontalDirection = GetFlatUnit(forwardBlast + (sideBlast * 0.52))

	-- Center shot (sideSign==0): beri ledakan lebih kuat biar badan berserakan,
	-- bukan jatuh lurus ke bawah kek boneka. Tambah upward pop + spin random.
	local effectiveHorizontalSpeed = horizontalSpeed
	local effectiveUpwardSpeed = upwardSpeed
	local effectiveSideSpeed = sideSpeed
	local effectiveAngularSpeed = angularSpeed
	if sideSign == 0 then
		effectiveHorizontalSpeed = horizontalSpeed * 1.45
		effectiveUpwardSpeed = math.max(upwardSpeed, 5.5)
		effectiveAngularSpeed = angularSpeed * 2.2
	else
		local sideHorizontalScale =
			math.clamp(tonumber(MatchKeeperConfig.GoalImpactSideHorizontalSpeedScale) or 0.62, 0, 1)
		local sideSideScale = math.clamp(tonumber(MatchKeeperConfig.GoalImpactSideSideSpeedScale) or 0.58, 0, 1)
		local sideAngularScale = math.clamp(tonumber(MatchKeeperConfig.GoalImpactSideAngularSpeedScale) or 0.58, 0, 1)
		local sideMaxUpwardSpeed = math.max(tonumber(MatchKeeperConfig.GoalImpactSideMaxUpwardSpeed) or 0.35, 0)

		effectiveHorizontalSpeed = horizontalSpeed * sideHorizontalScale
		effectiveSideSpeed = sideSpeed * sideSideScale
		effectiveUpwardSpeed = math.clamp(upwardSpeed, 0, sideMaxUpwardSpeed)
		effectiveAngularSpeed = angularSpeed * sideAngularScale
	end

	local impulseVelocity = (horizontalDirection * effectiveHorizontalSpeed)
		+ (sideBlast * effectiveSideSpeed)
		+ Vector3.new(0, effectiveUpwardSpeed, 0)

	-- Spin axis: untuk center beri rotasi lebih dramatis ke depan
	local angularAxis = sideSign == 0 and GetFlatUnit(rightVector) or GetFlatUnit(rightVector + (sideBlast * 0.45))
	local angularVelocity = angularAxis * effectiveAngularSpeed

	-- baseRootY digunakan untuk deteksi landing di RenderStep
	local baseRootY = (root and root:IsA("BasePart") and root.Position.Y) or currentCFrame.Position.Y

	local anchorStates = {}
	local partStates = {}
	for _, descendant in ipairs(keeperModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			anchorStates[descendant] = descendant.Anchored
			partStates[descendant] = {
				CanCollide = descendant.CanCollide,
				CanTouch = descendant.CanTouch,
				CanQuery = descendant.CanQuery,
				CollisionGroup = descendant.CollisionGroup,
				Massless = descendant.Massless,
			}
			descendant.Anchored = false
			if descendant.Name == "HumanoidRootPart" then
				descendant.CanCollide = false
			else
				descendant.CanCollide = true
			end
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end

	if root and root:IsA("BasePart") then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop(0.04)
				end)
			end
		end

		pcall(function()
			humanoid.AutoRotate = false
			humanoid.PlatformStand = true
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end

	local disabledMotors = {}
	local createdAttachments = {}
	local createdConstraints = {}

	-- Selalu pakai BallSocketConstraint ragdoll (Motor6D disable + constraints).
	-- GoalImpactUsePhysicsRagdoll = true menyebabkan Motor6D tidak pernah di-disable
	-- dan RagdollModule bisa nil/error → keeper tidak jatuh sama sekali.
	for _, descendant in ipairs(keeperModel:GetDescendants()) do
		if descendant:IsA("Motor6D") and descendant.Enabled and descendant.Part0 and descendant.Part1 then
			pcall(function()
				descendant.Enabled = false
				table.insert(disabledMotors, descendant)

				local att0 = Instance.new("Attachment")
				att0.Name = descendant.Name .. "_GoalImpactAtt0"
				att0.CFrame = descendant.C0
				att0.Parent = descendant.Part0

				local att1 = Instance.new("Attachment")
				att1.Name = descendant.Name .. "_GoalImpactAtt1"
				att1.CFrame = descendant.C1
				att1.Parent = descendant.Part1

				local ball = Instance.new("BallSocketConstraint")
				ball.Name = descendant.Name .. "_GoalImpactConstraint"
				ball.Attachment0 = att0
				ball.Attachment1 = att1
				ball.LimitsEnabled = true
				ball.TwistLimitsEnabled = true
				ball.UpperAngle = 90
				ball.TwistUpperAngle = 90
				ball.TwistLowerAngle = -90
				ball.Parent = descendant.Part0

				table.insert(createdAttachments, att0)
				table.insert(createdAttachments, att1)
				table.insert(createdConstraints, ball)
			end)
		end
	end

	local ragdoll = nil

	for part in pairs(anchorStates) do
		if part and part.Parent and part:IsA("BasePart") then
			part.Anchored = false
			-- Kasih semua bagian tubuh impuls ledakan yang sama arahnya
			-- Center tetap dramatis, side tidak dipaksa punya pop Y supaya tidak mental ke atas mistar.
			local blastY = math.max(impulseVelocity.Y, 4.5)
			if isSideGoalImpact then
				blastY = math.clamp(
					impulseVelocity.Y,
					-0.35,
					math.max(tonumber(MatchKeeperConfig.GoalImpactSideMaxUpwardSpeed) or 0.35, 0)
				)
			end
			part.AssemblyLinearVelocity = Vector3.new(impulseVelocity.X, blastY, impulseVelocity.Z)
			part.AssemblyAngularVelocity = angularVelocity
		end
	end

	local renderStepName =
		string.format("KeeperGoalImpactRagdoll_%d_%s", reactionId, tostring(os.clock()):gsub("%.", "_"))
	local startedAt = os.clock()
	local lastTime = os.clock()
	self.ActiveGoalImpactRagdoll = {
		ReactionId = reactionId,
		Ragdoll = ragdoll,
		AnchorStates = anchorStates,
		PartStates = partStates,
		RenderStepName = renderStepName,
		DisabledMotors = disabledMotors,
		CreatedAttachments = createdAttachments,
		CreatedConstraints = createdConstraints,
	}

	keeperModel:SetAttribute("IsCinematicReacting", true)
	keeperModel:SetAttribute("IsPowerBreakthroughRagdoll", true)

	pcall(function()
		RunService:UnbindFromRenderStep(renderStepName)
	end)

	-- Biarkan Roblox physics engine yang handle gravity dan drag secara native.
	-- RenderStep ini hanya bertugas: monitor waktu, trigger shake saat landing,
	-- dan pastikan tidak ada part yang re-anchored oleh sistem lain.
	local wasGrounded = false
	local groundedAt: number? = nil
	local landingNeutralizeDuration =
		math.max(tonumber(MatchKeeperConfig.GoalImpactSideLandingNeutralizeDuration) or 0.30, 0)
	local function neutralizeSideGoalImpactVelocity()
		for part in pairs(partStates) do
			if part and part.Parent and part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
	RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value + 90, function()
		if
			self.ReactionId ~= reactionId
			or self.KeeperImpactToken ~= impactToken
			or self.State ~= "GoalImpactRagdoll"
			or not keeperModel.Parent
		then
			self:_cleanupActiveGoalImpactRagdoll()
			return
		end

		local now = os.clock()
		local dt = math.min(now - lastTime, 0.1)
		lastTime = now

		-- Pastikan tidak ada part yang diam-diam di-Anchor oleh sistem lain
		for part in pairs(partStates) do
			if part and part.Parent and part:IsA("BasePart") then
				if part.Anchored then
					part.Anchored = false
				end
			end
		end

		-- Deteksi landing berdasarkan torso/UpperTorso yang sudah jatuh ke dekat lantai
		if not wasGrounded then
			local torso = keeperModel:FindFirstChild("UpperTorso") or keeperModel:FindFirstChild("Torso") or root
			if torso and torso:IsA("BasePart") then
				local groundY = baseRootY - 1.2
				if torso.Position.Y <= groundY then
					wasGrounded = true
					groundedAt = now
					if isSideGoalImpact then
						neutralizeSideGoalImpactVelocity()
						ShakeCamera(
							tonumber(MatchKeeperConfig.GoalImpactSideLandingShakeStrength) or 0.85,
							tonumber(MatchKeeperConfig.GoalImpactSideLandingShakeDuration) or 0.18
						)
					else
						ShakeCamera(1.85, 0.4)
					end
				end
			end
		end

		if isSideGoalImpact and groundedAt and now - groundedAt <= landingNeutralizeDuration then
			neutralizeSideGoalImpactVelocity()
		end

		-- Setelah holdDuration, cleanup otomatis
		if os.clock() - startedAt >= holdDuration then
			self:_cleanupActiveGoalImpactRagdoll()
		end
	end)

	return true
end

local function ConnectKeeperContactMarker(track, markerName, fireContact)
	if not track or type(markerName) ~= "string" or markerName == "" then
		return nil
	end

	local ok, signal = pcall(function()
		return track:GetMarkerReachedSignal(markerName)
	end)

	if not ok or not signal then
		return nil
	end

	return signal:Connect(function(parameter)
		fireContact("marker", parameter)
	end)
end

function MatchKeeperPresentationController:_resolveBaseMarker()
	return MatchShootTargetResolver.GetKeeperPoint()
		or MatchZoneQuery.GetSaveTarget()
		or MatchZoneQuery.GetGoalTarget()
		or MatchZoneQuery.GetKeeperEngagePoint()
end

function MatchKeeperPresentationController:_buildBaseState(keeperModel)
	local baseMarker = self:_resolveBaseMarker()
	local rawBaseCFrame = baseMarker and baseMarker.CFrame or keeperModel:GetPivot()

	local baseLookVector = GetFlatUnit(rawBaseCFrame.LookVector)
	local flatBaseCFrame = BuildFlatFacingCFrame(rawBaseCFrame.Position, baseLookVector)
	local groundedBaseCFrame = GetGroundedCFrame(keeperModel, flatBaseCFrame)

	self.GroundIgnoreInstances = nil
	self.BaseLookVector = baseLookVector
	self.BaseCFrame = groundedBaseCFrame
end

function MatchKeeperPresentationController:_buildCenterFacingCFrame(keeperModel, worldPosition, lookVector)
	local flat = BuildFlatFacingCFrame(worldPosition, lookVector)
	return GetGroundedCFrame(keeperModel, flat)
end

function MatchKeeperPresentationController:_buildReadyCFrame(keeperModel)
	local lookVector = self:_resolveLookVectorFromFocus(self.BaseCFrame.Position)
	local readyPos = self.BaseCFrame.Position + (GetFlatUnit(lookVector) * MatchKeeperConfig.ReadyAdvance)
	return self:_buildCenterFacingCFrame(keeperModel, readyPos, lookVector)
end

function MatchKeeperPresentationController:_clampKeeperCFrame(cf, reason)
	if not cf or not self.BaseCFrame then
		return cf
	end

	local basePosition = self.BaseCFrame.Position
	local position = cf.Position
	local maxLift = math.max(tonumber(MatchKeeperConfig.KeeperSafetyMaxRootLift) or 2.4, 0.4)
	local maxDistance = math.max(tonumber(MatchKeeperConfig.KeeperSafetyMaxDistanceFromBase) or 18, 4)

	local flatDelta = Vector3.new(position.X - basePosition.X, 0, position.Z - basePosition.Z)
	if flatDelta.Magnitude > maxDistance then
		flatDelta = flatDelta.Unit * maxDistance
	end

	local minY = basePosition.Y - 0.35
	local maxY = basePosition.Y + maxLift
	local clampedPosition =
		Vector3.new(basePosition.X + flatDelta.X, math.clamp(position.Y, minY, maxY), basePosition.Z + flatDelta.Z)

	if (clampedPosition - position).Magnitude > 0.05 and MatchKeeperConfig.DebugKeeperSaveTarget == true then
		warn(
			string.format(
				"[KeeperSafety] clamped %s from %s to %s",
				tostring(reason or "cframe"),
				tostring(position),
				tostring(clampedPosition)
			)
		)
	end

	return CFrame.new(clampedPosition) * (cf - cf.Position)
end

function MatchKeeperPresentationController:_buildCenterSaveKnockdownCFrame(keeperModel, reactionData)
	local startCFrame = GetInstanceCFrame(keeperModel)
		or (reactionData and reactionData.InterceptCFrame)
		or self.BaseCFrame

	if not startCFrame or not self.BaseCFrame then
		return reactionData and reactionData.LandedCFrame or startCFrame
	end

	local forwardVector = reactionData and reactionData.ForwardVector or self.BaseLookVector or startCFrame.LookVector
	if typeof(forwardVector) ~= "Vector3" or forwardVector.Magnitude <= 0.001 then
		forwardVector = startCFrame.LookVector
	end
	forwardVector = GetFlatUnit(forwardVector)

	local backDistance = math.max(tonumber(MatchKeeperConfig.CenterSaveKnockdownBackDistance) or 1.25, 0)
	local lift = tonumber(MatchKeeperConfig.CenterSaveKnockdownLift) or 0.08
	local targetPosition = Vector3.new(
		startCFrame.Position.X,
		self.BaseCFrame.Position.Y + lift,
		startCFrame.Position.Z
	) - (forwardVector * backDistance)

	local flat = BuildFlatFacingCFrame(targetPosition, forwardVector)
	local backAngle = tonumber(MatchKeeperConfig.CenterSaveKnockdownBackAngle) or math.rad(76)
	local sideAngle = tonumber(MatchKeeperConfig.CenterSaveKnockdownSideAngle) or math.rad(6)

	return self:_clampKeeperCFrame(flat * CFrame.Angles(backAngle, 0, sideAngle), "center-save-knockdown")
end

function MatchKeeperPresentationController:_emitGoalParticlesByCode(worldPosition)
	local fxPart = Instance.new("Part")
	fxPart.Name = "KeeperGoalFxBurst"
	fxPart.Anchored = true
	fxPart.CanCollide = false
	fxPart.CanTouch = false
	fxPart.CanQuery = false
	fxPart.Transparency = 1
	fxPart.Size = Vector3.new(0.5, 0.5, 0.5)
	fxPart.CFrame = CFrame.new(worldPosition)
	fxPart.Parent = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = fxPart

	local emitter = Instance.new("ParticleEmitter")
	emitter.Parent = attachment
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.55, 0.9)
	emitter.Speed = NumberRange.new(9, 14)
	emitter.SpreadAngle = Vector2.new(40, 40)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})

	emitter:Emit(MatchKeeperConfig.GoalFxEmitCount or 28)
	Debris:AddItem(fxPart, 1.5)
end

local function ResolveTargetSideFromId(shotTargetId)
	local targetId = string.lower(tostring(shotTargetId or ""))

	if targetId:find("left") then
		return -1
	end

	if targetId:find("right") then
		return 1
	end

	return 0
end

local function ResolveReactionAnimationFromSide(sideSign, ballHeightOffset, isCenter)
	if sideSign < 0 then
		return "DefendLeft"
	end

	if sideSign > 0 then
		return "DefendRight"
	end

	if isCenter and MatchKeeperConfig.ForceCenterSaveDefendFront ~= false then
		return "DefendFront"
	end

	if ballHeightOffset >= (MatchKeeperConfig.SaveHighCenterThreshold or 2.05) then
		return "DefendUp"
	end

	return isCenter and "DefendFront" or "DefendFront"
end

local function ResolveSaveLift(shotTargetId, ballHeightOffset, isCenter, scaleCompensation)
	local liftScale = math.clamp(tonumber(scaleCompensation) or 1, 0.70, 1.0)
	local targetId = string.lower(tostring(shotTargetId or ""))

	if isCenter then
		local centerLift = tonumber(MatchKeeperConfig.SaveCenterContactLift)
			or tonumber(MatchKeeperConfig.SaveCenterLift)
			or DEFAULT_SAVE_CENTER_LIFT

		return (centerLift + (ballHeightOffset * 0.18)) * liftScale
	end

	if targetId:find("low") then
		local lowLift = tonumber(MatchKeeperConfig.SaveLowLift) or DEFAULT_SAVE_LOW_LIFT
		return (lowLift + (ballHeightOffset * 0.10)) * liftScale
	end

	if targetId:find("high") then
		local highLift = tonumber(MatchKeeperConfig.SaveHighLift) or DEFAULT_SAVE_HIGH_LIFT
		return (highLift + (ballHeightOffset * 0.22)) * liftScale
	end

	local midLift = tonumber(MatchKeeperConfig.SaveMidLift) or DEFAULT_SAVE_MID_LIFT
	return (midLift + (ballHeightOffset * 0.16)) * liftScale
end

local function ResolveKeeperVisualScale(model)
	if model and typeof(model) == "Instance" and model:IsA("Model") and model.GetScale then
		local ok, resolvedScale = pcall(function()
			return model:GetScale()
		end)

		if ok and type(resolvedScale) == "number" and resolvedScale > 0 then
			return resolvedScale
		end
	end

	local configuredScale = tonumber(MatchKeeperConfig.KeeperVisualScale)
	if configuredScale and configuredScale > 0 then
		return configuredScale
	end

	return 1
end

local function ResolveScaleCompensation(keeperScale)
	if MatchKeeperConfig.KeeperScaleCompensationEnabled == false then
		return 1
	end

	local scale = tonumber(keeperScale) or 1
	if scale <= 0 then
		return 1
	end

	return 1 / scale
end

local function IsCenterShotTarget(shotTargetId)
	local targetId = string.lower(tostring(shotTargetId or ""))

	return targetId == ""
		or targetId == "center"
		or targetId:find("center") ~= nil
		or (not targetId:find("left") and not targetId:find("right"))
end

local function IsPowerBreakthroughEligible(isGoal, shootTier, shotTargetId, reactionAnimation)
	if MatchKeeperConfig.PowerBreakthroughEnabled == false then
		return false
	end

	if isGoal ~= true then
		return false
	end

	local tierMap = MatchKeeperConfig.PowerBreakthroughTiers or { Green = true }
	if tierMap[tostring(shootTier or "")] ~= true then
		return false
	end

	if not IsCenterShotTarget(shotTargetId) then
		return false
	end

	return reactionAnimation == "DefendFront" or reactionAnimation == "DefendUp"
end

function MatchKeeperPresentationController:_buildReactionData(
	keeperModel,
	isGoal,
	ballTargetPosition,
	shootTier,
	shotTargetId
)
	local keeperPos = self.BaseCFrame.Position
	local rightVector = GetFlatUnit(self.BaseCFrame.RightVector)
	local focusForward = self:_resolveLookVectorFromFocus(keeperPos)
	local forwardVector = GetFlatUnit(focusForward)

	local keeperSaveTarget = nil
	if MatchKeeperConfig.UseKeeperSaveTargets ~= false and MatchShootTargetResolver.GetKeeperSaveTarget then
		keeperSaveTarget = MatchShootTargetResolver.GetKeeperSaveTarget(shotTargetId)
	end

	local keeperLandingTarget = nil
	if MatchKeeperConfig.UseKeeperLandingTargets ~= false and MatchShootTargetResolver.GetKeeperLandingTarget then
		keeperLandingTarget = MatchShootTargetResolver.GetKeeperLandingTarget(shotTargetId)
	end

	local isPerfectGoal = isGoal and (tostring(shootTier or "") == "Green")
	local keeperSaveTargetPosition = (isPerfectGoal and ballTargetPosition)
		or (keeperSaveTarget and keeperSaveTarget.Position)
		or ballTargetPosition
	local toBall = keeperSaveTargetPosition - keeperPos
	local rightDot = toBall:Dot(rightVector)
	local lateralAbs = math.abs(rightDot)
	local forwardDot = math.max(toBall:Dot(forwardVector), 0)

	local targetSideFromId = ResolveTargetSideFromId(shotTargetId)
	local rawSideSign = targetSideFromId

	if rawSideSign == 0 and lateralAbs > (MatchKeeperConfig.SaveCenterWidth or 1.15) then
		rawSideSign = rightDot < 0 and -1 or 1
	end

	local isCenter = rawSideSign == 0
	local lateralSignMultiplier = tonumber(MatchKeeperConfig.DiveLateralSign) or 1
	local moveSideSign = rawSideSign * lateralSignMultiplier

	-- Movement side and animation side are intentionally separated.
	-- In this project the keeper rig faces the opposite side of the attacker, so the
	-- physical/root movement can be correct while the left/right animation looks flipped.
	-- Keep DiveLateralSign for root movement, and use DiveAnimationLateralSign only
	-- for choosing DefendLeft/DefendRight animation tracks.
	local animationLateralSignMultiplier = tonumber(MatchKeeperConfig.DiveAnimationLateralSign) or 1
	local animationSideSign = moveSideSign * animationLateralSignMultiplier

	local ballHeightOffset = math.clamp(toBall.Y, 0, 4.5)
	local reactionAnimation = ResolveReactionAnimationFromSide(animationSideSign, ballHeightOffset, isCenter)
	local rollAngle = 0
	local diveAirPos = keeperPos

	local tier = shootTier or "Yellow"
	local reactionDataDelay = 0
	local keeperScale = ResolveKeeperVisualScale(keeperModel)
	local scaleCompensation = ResolveScaleCompensation(keeperScale)
	local saveTargetLateralScale = tonumber(MatchKeeperConfig.KeeperSaveTargetLateralRootScale) or 0.92
	local saveTargetForwardScale = tonumber(MatchKeeperConfig.KeeperSaveTargetForwardRootScale) or 0.82
	local saveTargetLiftScale = tonumber(MatchKeeperConfig.KeeperSaveTargetLiftScale) or 0.92

	if not isGoal then
		-- Failed shots are visual saves. The shot ball timing is owned by MatchShootDirector.
		-- This controller only moves the keeper model. For scaled keeper rigs, do not move
		-- the root directly to the raw ball block point; the larger arms/body already add reach.
		local liftAmount = ResolveSaveLift(shotTargetId, ballHeightOffset, isCenter, scaleCompensation)

		if isCenter then
			reactionAnimation = "DefendFront"
			rollAngle = 0
		else
			reactionAnimation = ResolveReactionAnimationFromSide(animationSideSign, ballHeightOffset, false)

			local rollScale = math.clamp(scaleCompensation, 0.62, 1.0)
			local rollSideSign = moveSideSign * (tonumber(MatchKeeperConfig.SideSaveRollLateralSign) or 1)
			rollAngle = rollSideSign < 0 and ((MatchKeeperConfig.SaveRollAngle or math.pi / 2.35) * rollScale)
				or -((MatchKeeperConfig.SaveRollAngle or math.pi / 2.35) * rollScale)
		end

		local lateralReach = 0
		if not isCenter then
			local lateralScale = (keeperSaveTarget and saveTargetLateralScale)
				or tonumber(MatchKeeperConfig.SaveRootLateralScale)
				or 0.78
			local lateralMin = tonumber(MatchKeeperConfig.SaveRootLateralMin) or 0.65
			local lateralMax = tonumber(MatchKeeperConfig.SaveRootLateralMax) or 4.85

			lateralReach = math.clamp(lateralAbs * lateralScale * scaleCompensation, lateralMin, lateralMax)
				* moveSideSign
		end

		local forwardScale = (keeperSaveTarget and saveTargetForwardScale)
			or tonumber(MatchKeeperConfig.SaveRootForwardScale)
			or 0.72
		local forwardMin = tonumber(MatchKeeperConfig.SaveForwardMin) or 0.85
		local forwardMax = tonumber(MatchKeeperConfig.SaveForwardMax) or 2.95

		local forwardReach = math.clamp(forwardDot * forwardScale * scaleCompensation, forwardMin, forwardMax)

		diveAirPos = keeperPos
			+ (rightVector * lateralReach)
			+ (forwardVector * forwardReach)
			+ Vector3.new(0, liftAmount * saveTargetLiftScale, 0)

		if keeperSaveTarget and MatchKeeperConfig.KeeperSaveTargetGripRootEnabled ~= false then
			local contactModeGuess = (reactionAnimation == "DefendFront" or reactionAnimation == "DefendUp") and "Catch"
				or "Parry"
			local gripRootPosition = BuildKeeperRootPositionForSaveTarget(
				keeperModel,
				self.BaseCFrame,
				keeperSaveTargetPosition,
				shotTargetId,
				contactModeGuess
			)

			if gripRootPosition then
				local maxDistance = tonumber(MatchKeeperConfig.KeeperSaveTargetRootMaxDistance) or 14.0
				local rootDelta = gripRootPosition - keeperPos
				if rootDelta.Magnitude > maxDistance then
					gripRootPosition = keeperPos + rootDelta.Unit * maxDistance
				end

				local minY = keeperPos.Y + (tonumber(MatchKeeperConfig.KeeperSaveTargetRootMinLift) or 0.0)
				local configuredMaxLift = tonumber(MatchKeeperConfig.KeeperSaveTargetRootMaxLift) or 5.0
				if isCenter then
					configuredMaxLift =
						math.min(configuredMaxLift, tonumber(MatchKeeperConfig.CenterSaveRootMaxLift) or 1.10)
				end
				local maxY = keeperPos.Y + configuredMaxLift
				local alpha = math.clamp(tonumber(MatchKeeperConfig.KeeperSaveTargetGripRootAlpha) or 1.0, 0, 1)
				local blendedRootPosition = diveAirPos:Lerp(gripRootPosition, alpha)

				diveAirPos = Vector3.new(
					blendedRootPosition.X,
					math.clamp(blendedRootPosition.Y, minY, maxY),
					blendedRootPosition.Z
				)
			end
		end

		reactionDataDelay = tonumber(MatchKeeperConfig.SaveReactionDelay) or DEFAULT_SAVE_REACTION_DELAY
	else
		if isCenter then
			reactionAnimation = "DefendFront"

			local liftAmount = ((MatchKeeperConfig.GoalLift or 1.05) + (ballHeightOffset * 0.20))
				* math.clamp(scaleCompensation, 0.70, 1.0)

			diveAirPos = keeperPos
				+ (forwardVector * ((MatchKeeperConfig.GoalForwardAdvance or 0.65) * scaleCompensation))
				+ Vector3.new(0, liftAmount, 0)

			rollAngle = 0
		else
			local scaleByTier = MatchKeeperConfig.GoalRootLateralScale or {}
			local reachScale = scaleByTier[tier]
			if not reachScale then
				reachScale = tier == "Green" and 0.50 or tier == "Yellow" and 0.62 or 0.74
			end

			local minLateral = MatchKeeperConfig.GoalSameSideMin or 0.45
			local maxLateral = MatchKeeperConfig.GoalSameSideMax or 2.45
			local finalLateral = math.clamp(lateralAbs * reachScale * scaleCompensation, minLateral, maxLateral)
				* moveSideSign

			local liftAmount = ((MatchKeeperConfig.GoalLift or 1.05) + (ballHeightOffset * 0.20))
				* math.clamp(scaleCompensation, 0.70, 1.0)

			diveAirPos = keeperPos
				+ (rightVector * finalLateral)
				+ (forwardVector * ((MatchKeeperConfig.GoalForwardAdvance or 0.65) * scaleCompensation))
				+ Vector3.new(0, liftAmount, 0)

			-- GoalHold: if KeeperSaveTarget exists and it's a goal hold, blend toward gripRootPosition so hand reaches holdPos
			if keeperSaveTarget and isGoal and tostring(shootTier or "") == "Green" and MatchKeeperConfig.KeeperSaveTargetGripRootEnabled ~= false then
				local gripRootPosition = BuildKeeperRootPositionForSaveTarget(
					keeperModel,
					self.BaseCFrame,
					keeperSaveTargetPosition,
					shotTargetId,
					"Parry"
				)
				if gripRootPosition then
					local maxDistance = tonumber(MatchKeeperConfig.KeeperSaveTargetRootMaxDistance) or 14.0
					local rootDelta = gripRootPosition - keeperPos
					if rootDelta.Magnitude > maxDistance then
						gripRootPosition = keeperPos + rootDelta.Unit * maxDistance
					end

					local minY = keeperPos.Y + (tonumber(MatchKeeperConfig.KeeperSaveTargetRootMinLift) or 0.0)
					local maxY = keeperPos.Y + (tonumber(MatchKeeperConfig.KeeperSaveTargetRootMaxLift) or 5.0)
					local alpha = 1.0
					local blendedRootPosition = diveAirPos:Lerp(gripRootPosition, alpha)

					diveAirPos = Vector3.new(
						blendedRootPosition.X,
						math.clamp(blendedRootPosition.Y, minY, maxY),
						blendedRootPosition.Z
					)
				end
			end

			local rollScale = math.clamp(scaleCompensation, 0.62, 1.0)
			local goalRollSideSign = moveSideSign * (tonumber(MatchKeeperConfig.GoalDiveRollLateralSign) or 1)
			rollAngle = goalRollSideSign < 0 and ((MatchKeeperConfig.GoalRollAngle or math.pi / 2.65) * rollScale)
				or -((MatchKeeperConfig.GoalRollAngle or math.pi / 2.65) * rollScale)
		end

		local tierDelayScale = tier == "Green" and 1.0 or tier == "Yellow" and 0.65 or 0.35
		-- GoalHold: keeper must dive immediately (no delay) so it arrives at InterceptCFrame
		-- in sync with the ball. WrongGuessDelay is for wrong-guess saves only, not goal holds.
		reactionDataDelay = 0
	end

	local isPowerBreakthrough = IsPowerBreakthroughEligible(isGoal, tier, shotTargetId, reactionAnimation)
	if isPowerBreakthrough then
		local breakthroughLift = math.max(tonumber(MatchKeeperConfig.PowerBreakthroughInterceptLift) or 0.05, 0)
		diveAirPos = Vector3.new(diveAirPos.X, keeperPos.Y + breakthroughLift, diveAirPos.Z)
	end

	local diveAirFlat = BuildFlatFacingCFrame(diveAirPos, forwardVector)
	local interceptCFrame = diveAirFlat * CFrame.Angles(0, 0, rollAngle)

	local landedPosition = Vector3.new(diveAirPos.X, keeperPos.Y, diveAirPos.Z)
	if keeperLandingTarget and not isGoal and not isPowerBreakthrough then
		landedPosition = keeperLandingTarget.Position
	end

	if isPowerBreakthrough then
		local knockbackDistance = tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackDistance) or 2.45
		local knockbackLift = tonumber(MatchKeeperConfig.PowerBreakthroughKnockbackLift) or 0.18
		landedPosition = landedPosition - (forwardVector * knockbackDistance) + Vector3.new(0, knockbackLift, 0)
	elseif not isCenter and not isGoal then
		local landedLift = tonumber(MatchKeeperConfig.SideSaveLandedLift) or 0.70
		landedPosition = landedPosition + Vector3.new(0, landedLift, 0)
	end

	local landedFlat = self:_buildCenterFacingCFrame(keeperModel, landedPosition, forwardVector)

	local landedCFrame
	if isPowerBreakthrough then
		-- Fake knockdown: keep the keeper down instead of snapping into Lose/Idle.
		local fallBackAngle = tonumber(MatchKeeperConfig.PowerBreakthroughFallBackAngle) or math.rad(30)
		local fallSideAngle = tonumber(MatchKeeperConfig.PowerBreakthroughFallSideAngle) or math.rad(8)
		local sideSign = moveSideSign ~= 0 and moveSideSign or 1
		landedCFrame = landedFlat * CFrame.Angles(fallBackAngle, 0, rollAngle * 0.35 + (fallSideAngle * sideSign))
	else
		local landedRollScale = tonumber(MatchKeeperConfig.SaveLandedRollScale) or 1.0
		landedCFrame = landedFlat * CFrame.Angles(0, 0, rollAngle * landedRollScale)
	end

	local recoverCFrame = self:_buildCenterFacingCFrame(
		keeperModel,
		self.BaseCFrame.Position,
		self:_resolveLookVectorFromFocus(self.BaseCFrame.Position)
	)

	if MatchKeeperConfig.DebugReaction == true then
		print(
			"[KEEPER REACT]",
			"shotTargetId=",
			shotTargetId,
			"targetSideFromId=",
			targetSideFromId,
			"rightDot=",
			rightDot,
			"rawSideSign=",
			rawSideSign,
			"DiveLateralSign=",
			MatchKeeperConfig.DiveLateralSign,
			"moveSideSign=",
			moveSideSign,
			"animationSideSign=",
			animationSideSign,
			"DiveAnimationLateralSign=",
			MatchKeeperConfig.DiveAnimationLateralSign,
			"keeperSaveTarget=",
			keeperSaveTarget and keeperSaveTarget.Name or "fallback",
			"keeperLandingTarget=",
			keeperLandingTarget and keeperLandingTarget.Name or "fallback",
			"animation=",
			reactionAnimation,
			"isGoal=",
			isGoal,
			"scale=",
			keeperScale,
			"scaleComp=",
			scaleCompensation
		)
	end

	interceptCFrame = self:_clampKeeperCFrame(interceptCFrame, "intercept")
	landedCFrame = self:_clampKeeperCFrame(landedCFrame, "landed")
	recoverCFrame = self:_clampKeeperCFrame(recoverCFrame, "recover")

	-- Knockdown/ragdoll hanya saat goal masuk lewat tengah (keeper kalah).
	-- Kalau keeper save center (isGoal = false), keeper menang → tidak boleh ragdoll.
	local centerSaveKnockdown = isGoal and isCenter and MatchKeeperConfig.CenterSaveGroundedKnockdownEnabled == true

	return {
		InterceptCFrame = interceptCFrame,
		LandedCFrame = landedCFrame,
		RecoverCFrame = recoverCFrame,
		ResultAnimation = "Idle",
		DelayBeforeDive = reactionDataDelay,
		EmitGoalFx = isGoal == true and tostring(shootTier or "") == "Green",
		-- IsLeft is for animation fallback/candidate handling. ShotIsLeft keeps the real
		-- movement side for systems that need the physical shot/save side.
		IsLeft = animationSideSign < 0,
		ShotIsLeft = moveSideSign < 0,
		AnimationSideSign = animationSideSign,
		MovementSideSign = moveSideSign,
		KeepSavePose = (not isGoal) and (MatchKeeperConfig.KeepSavePoseUntilCleanup ~= false),
		CenterSaveKnockdown = centerSaveKnockdown,
		KeeperSaveTarget = keeperSaveTarget,
		KeeperSaveTargetPosition = keeperSaveTargetPosition,
		KeeperLandingTarget = keeperLandingTarget,
		IsGoal = isGoal,
		SaveContactHold = isPowerBreakthrough
				and (tonumber(MatchKeeperConfig.PowerBreakthroughKeeperHoldAfterContact) or 0.16)
			or ((not isGoal) and (tonumber(MatchKeeperConfig.SaveContactHold) or DEFAULT_SAVE_CONTACT_HOLD) or 0),
		ReactionAnimation = reactionAnimation,
		TargetSideFromId = targetSideFromId,
		MoveSideSign = moveSideSign,
		ForwardVector = forwardVector,
		PowerBreakthrough = isPowerBreakthrough,
		ContactMode = isPowerBreakthrough and "Breakthrough"
			or ((not isGoal) and "Catch"
			or (isGoal and tostring(shootTier or "") == "Green" and "GoalHold" or nil)),
		ContactMarkerName = isPowerBreakthrough
				and (MatchKeeperConfig.PowerBreakthroughContactMarkerName or MatchKeeperConfig.CatchContactMarkerName or "CatchContact")
			or (
				tostring(shootTier or "") == "Green"
					and (isCenter and (MatchKeeperConfig.CatchContactMarkerName or "CatchContact") or (MatchKeeperConfig.SaveContactMarkerName or "SaveContact"))
				or nil
			),
	}
end

function MatchKeeperPresentationController:_runReactionSequence(
	keeperModel,
	reactionId,
	reactionData,
	ballTargetPosition,
	contactOptions
)
	task.spawn(function()
		if reactionData.DelayBeforeDive > 0 then
			task.wait(reactionData.DelayBeforeDive)
			if self.ReactionId ~= reactionId or self.State ~= "React" then
				return
			end
		end

		if MatchKeeperConfig.DebugKeeperSaveTarget then
			print(
				string.format(
					"[KEEPER DEBUG] Phase: Intercepting | shotTargetId=%s | mode=%s | saveTarget=%s | landingTarget=%s",
					tostring(reactionData.ShotTargetId),
					tostring(reactionData.ContactMode),
					reactionData.KeeperSaveTarget and reactionData.KeeperSaveTarget.Name or "none",
					reactionData.KeeperLandingTarget and reactionData.KeeperLandingTarget.Name or "none"
				)
			)
		end

		local contactFired = false
		local markerFired = false
		local markerConnection = nil
		local reactionTrack = nil
		local poseFrozen = false

		local function freezeReactionAtContactPose()
			if not reactionTrack then
				return
			end
			if MatchKeeperConfig.FreezeSaveAnimationAtContact == false then
				return
			end
			if poseFrozen then
				return
			end
			poseFrozen = true

			pcall(function()
				reactionTrack.Looped = false
				local minTimePosition = tonumber(MatchKeeperConfig.SaveAnimationFreezeMinTimePosition)
				if minTimePosition and reactionTrack.Length and reactionTrack.Length > 0 then
					local safeMax = math.max(reactionTrack.Length - 0.03, 0)
					local safeMin = math.min(minTimePosition, safeMax)
					reactionTrack.TimePosition = math.clamp(math.max(reactionTrack.TimePosition, safeMin), 0, safeMax)
				end
				reactionTrack:AdjustSpeed(0)
			end)
		end

		local function setKeeperAnchored(anchored)
			AnchorKeeperRoot(keeperModel, anchored)
		end

		local externalMinDelay = tonumber(contactOptions and contactOptions.ContactMinDelaySeconds) or 0
		local shotTravelDuration = tonumber(contactOptions and contactOptions.ShotTravelDuration) or externalMinDelay
		local diveDuration = tonumber(MatchKeeperConfig.DiveDuration) or 0.34
		local animSpeed = 1
		local defaultDiveDuration = tonumber(MatchKeeperConfig.DiveDuration) or 0.34

		-- Sync dive duration to shot travel so keeper arrives at InterceptCFrame exactly when ball arrives.
		if (reactionData.ContactMode or reactionData.IsGoal) and shotTravelDuration > 0.1 then
			diveDuration = math.max(shotTravelDuration - reactionData.DelayBeforeDive, 0.1)
			animSpeed = defaultDiveDuration / diveDuration
		end

		if MatchKeeperConfig.DebugReaction == true and reactionData.ContactMode == "GoalHold" then
			local holdAlpha = 0.72 -- must match MatchBallConfig.GoalHoldShot.HoldAlpha
			local fallbackAlpha = tonumber(MatchKeeperConfig.GoalHoldFallbackFreezeAlpha) or 0.72
			print(string.format(
				"[GoalHold SYNC] shotTravel=%.3fs | diveDuration=%.3fs | freezeAt=%.3fs | ballArrivesAt=%.3fs | gap=%.3fs",
				shotTravelDuration, diveDuration,
				diveDuration * fallbackAlpha,
				shotTravelDuration * holdAlpha,
				(diveDuration * fallbackAlpha) - (shotTravelDuration * holdAlpha)
			))
		end

		reactionTrack = self:_playAnimation(keeperModel, reactionData.ReactionAnimation or "Jump", animSpeed, {
			IsLeft = reactionData.IsLeft,
		})

		markerConnection = ConnectKeeperContactMarker(reactionTrack, reactionData.ContactMarkerName, function()
			markerFired = true
			-- For Breakthrough AND GoalHold: freeze immediately when animation marker fires
			if reactionData.PowerBreakthrough and ShouldUsePowerBreakthroughRagdoll() then
				freezeReactionAtContactPose()
			elseif reactionData.ContactMode == "GoalHold" then
				-- GoalHold: freeze the animation mid-air as soon as hands reach the ball
				freezeReactionAtContactPose()
			end
		end)

		-- PHASE 1: INTERCEPT
		-- Anchor here so physics gravity does not pull the keeper down while we tween
		keeperModel:SetAttribute("IsCinematicReacting", true)
		DisableKeeperPhysicalContact(keeperModel)
		setKeeperAnchored(true)
		self:_playPivotTween(
			keeperModel,
			reactionData.InterceptCFrame,
			TweenInfo.new(diveDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		)

		local interceptStartedAt = os.clock()

		-- Wait for contact condition
		if reactionData.ContactMode == "GoalHold" then
			-- PBS-style: wait until marker fires OR fallback alpha, then freeze mid-air and hold
			local goalHoldFrozen = false
			local goalHoldFreezeAt = nil
			local goalHoldFallbackAlpha = math.clamp(
				tonumber(MatchKeeperConfig.GoalHoldFallbackFreezeAlpha) or 0.72,
				0.30, 0.98
			)
			local goalHoldDuration = math.max(
				tonumber(contactOptions and contactOptions.GoalHoldDuration) or 5.0,
				5.0
			)

			while self.ReactionId == reactionId and self.State == "React" do
				local elapsed = os.clock() - interceptStartedAt

				-- Trigger freeze when marker fires OR at fallback alpha of diveDuration
				local shouldFreeze = markerFired or (elapsed >= diveDuration * goalHoldFallbackAlpha)
				if shouldFreeze and not goalHoldFrozen then
					goalHoldFrozen = true
					goalHoldFreezeAt = os.clock()

					-- Stop tween so keeper stays mid-air at current CFrame
					self:_clearTweenState()

					-- Freeze animation (AdjustSpeed = 0) — PBS: PauseGoalieAnimation()
					freezeReactionAtContactPose()

					-- Fire OnGoalHoldContact → triggers ball Phase 2 (HoldEffects + shake)
					if not contactFired then
						contactFired = true
						local contactPoseCFrame = GetInstanceCFrame(keeperModel)
						local goalHoldPayload = BuildKeeperContactPayload(
							keeperModel,
							reactionId,
							reactionData,
							ballTargetPosition,
							markerFired and "marker" or "fallback",
							nil
						)
						goalHoldPayload.KeeperContactCFrame = contactPoseCFrame
						goalHoldPayload.KeeperSaveTargetPosition = reactionData.KeeperSaveTargetPosition

						if contactOptions and contactOptions.OnGoalHoldContact then
							task.spawn(function()
								contactOptions.OnGoalHoldContact(goalHoldPayload)
							end)
						end
					end
				end

				-- After freeze: wait for goalHoldDuration, then break to proceed to phase 3
				if goalHoldFrozen and goalHoldFreezeAt then
					if os.clock() - goalHoldFreezeAt >= goalHoldDuration or (self.CurrentKeeperState and self.CurrentKeeperState.KeeperDropped) then
						break
					end
				end

				RunService.RenderStepped:Wait()
			end

			-- After GoalHold: DO NOT proceed to landing/recovery.
			-- The ball's OnHoldRelease fires triggerKeeperGoalImpactRagdoll which overrides everything.
			-- We just need to clean up.
			if markerConnection then
				markerConnection:Disconnect()
				markerConnection = nil
			end
			return
		elseif reactionData.ContactMode then
			while self.ReactionId == reactionId and self.State == "React" do
				local elapsed = os.clock() - interceptStartedAt
				if reactionData.PowerBreakthrough and ShouldUsePowerBreakthroughRagdoll() and not markerFired then
					local freezeAlpha =
						math.clamp(tonumber(MatchKeeperConfig.PowerBreakthroughFallbackFreezeAlpha) or 0.82, 0.35, 0.98)
					if elapsed >= diveDuration * freezeAlpha then
						freezeReactionAtContactPose()
					end
				end

				-- Lock exactly when the synchronized dive finishes (ball arrives)
				if elapsed >= diveDuration then
					break
				end
				RunService.RenderStepped:Wait()
			end
		else
			-- IsGoal (no ContactMode): just wait diveDuration
			task.wait(diveDuration)
		end

		self:_clearTweenState()

		if self.ReactionId ~= reactionId or self.State ~= "React" then
			if markerConnection then
				markerConnection:Disconnect()
			end
			return
		end

		if markerConnection then
			markerConnection:Disconnect()
			markerConnection = nil
		end

		-- PHASE 2: CONTACT LOCKED
		if reactionData.ContactMode and not contactFired then
			contactFired = true
			if MatchKeeperConfig.DebugKeeperSaveTarget then
				print(
					string.format(
						"[KEEPER DEBUG] Phase: ContactLocked | Reason: %s",
						markerFired and "Marker" or "Fallback"
					)
				)
			end

			-- Shake camera when ball reaches target/keeper contact
			local shakeIntensity = 1.35
			local shakeDuration = 0.35
			if reactionData.PowerBreakthrough then
				shakeIntensity = 2.45
				shakeDuration = 0.45
			end
			ShakeCamera(shakeIntensity, shakeDuration)

			local activeBreakthroughRagdoll = reactionData.PowerBreakthrough
				and self.ActivePowerBreakthroughRagdoll
				and self.ActivePowerBreakthroughRagdoll.ReactionId == reactionId
			local contactPoseCFrame = GetInstanceCFrame(keeperModel)
			if
				not reactionData.PowerBreakthrough
				and not activeBreakthroughRagdoll
				and MatchKeeperConfig.KeeperSaveTargetContactGripCorrectionEnabled ~= false
			then
				contactPoseCFrame = AlignKeeperGripToSaveTargetAtContact(keeperModel, reactionData, ballTargetPosition)
			end

			if reactionData.ContactMode == "Catch" or reactionData.ContactMode == "Parry" or reactionData.ContactMode == "GoalHold" then
				freezeReactionAtContactPose()
			end

			if reactionData.ContactMode == "Parry" and MatchKeeperConfig.ParryHoldAtContactPose ~= false then
				reactionData.LandedCFrame = contactPoseCFrame or reactionData.InterceptCFrame
			end

			local payload = BuildKeeperContactPayload(
				keeperModel,
				reactionId,
				reactionData,
				ballTargetPosition,
				markerFired and "marker" or "fallback",
				nil
			)
			payload.KeeperContactCFrame = contactPoseCFrame
			payload.KeeperSaveTargetPosition = reactionData.KeeperSaveTargetPosition

			if
				activeBreakthroughRagdoll
				or (reactionData.ContactMode == "Breakthrough" and ShouldUsePowerBreakthroughRagdoll())
			then
				-- The shot-flight impact already handed ownership to the ball and ragdoll.
			elseif
				reactionData.ContactMode == "Breakthrough"
				and contactOptions
				and contactOptions.OnPowerBreakthroughContact
			then
				contactOptions.OnPowerBreakthroughContact(payload)
				-- Non-ragdoll fallback keeps the old controlled pushback.
				if not ShouldUsePowerBreakthroughRagdoll() then
					self:_beginPowerBreakthroughPushback(keeperModel, reactionId, reactionData)
				end
			elseif reactionData.ContactMode == "Catch" and contactOptions and contactOptions.OnCatchContact then
				contactOptions.OnCatchContact(payload)
			elseif reactionData.ContactMode == "Parry" and contactOptions and contactOptions.OnSaveContact then
				contactOptions.OnSaveContact(payload)
			elseif reactionData.ContactMode == "GoalHold" and contactOptions and contactOptions.OnGoalHoldContact then
				contactOptions.OnGoalHoldContact(payload)
			end
		end

		if reactionData.SaveContactHold and reactionData.SaveContactHold > 0 then
			task.wait(reactionData.SaveContactHold)
			if self.ReactionId ~= reactionId or self.State ~= "React" then
				return
			end
		end

		-- PHASE 3: LANDING / POWER PUSHBACK
		-- PowerBreakthrough can use either the old controlled pushback or the keeper-only ragdoll test mode.
		if reactionData.PowerBreakthrough then
			if ShouldUsePowerBreakthroughRagdoll() then
				if MatchKeeperConfig.DebugKeeperSaveTarget then
					print("[KEEPER DEBUG] Phase: PowerBreakthroughRagdoll")
				end

				local activeRagdoll = self.ActivePowerBreakthroughRagdoll
				if not activeRagdoll or activeRagdoll.ReactionId ~= reactionId then
					local waitStartedAt = os.clock()
					while
						self.ReactionId == reactionId
						and self.State == "React"
						and keeperModel.Parent ~= nil
						and os.clock() - waitStartedAt < 0.35
					do
						activeRagdoll = self.ActivePowerBreakthroughRagdoll
						if activeRagdoll and activeRagdoll.ReactionId == reactionId then
							break
						end
						RunService.RenderStepped:Wait()
					end
				end

				if self.ReactionId ~= reactionId or self.State ~= "React" then
					return
				end
			else
				if MatchKeeperConfig.DebugKeeperSaveTarget then
					print("[KEEPER DEBUG] Phase: PowerBreakthroughPushback")
				end

				local pushbackState = self:_beginPowerBreakthroughPushback(keeperModel, reactionId, reactionData)
				local remainingDuration = 0
				if pushbackState then
					remainingDuration = math.max(
						(pushbackState.Duration or 0) - (os.clock() - (pushbackState.StartedAt or os.clock())),
						0
					)
				end

				if remainingDuration > 0 then
					task.wait(remainingDuration)
				end

				if self.ReactionId ~= reactionId or self.State ~= "React" then
					return
				end
			end
		elseif reactionData.LandedCFrame and not reactionData.KeepSavePose then
			if MatchKeeperConfig.DebugKeeperSaveTarget then
				print("[KEEPER DEBUG] Phase: Landing")
			end

			local fallDuration = tonumber(MatchKeeperConfig.FallDuration) or 0.22
			self:_playPivotTween(
				keeperModel,
				reactionData.LandedCFrame,
				TweenInfo.new(fallDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			)

			task.wait(fallDuration)
			if self.ReactionId ~= reactionId or self.State ~= "React" then
				return
			end
			ShakeCamera(0.65, 0.2)
		end

		if reactionData.EmitGoalFx then
			self:_emitGoalParticlesByCode(ballTargetPosition)
		end

		-- PHASE 4: HOLD UNTIL CLEANUP
		if reactionData.PowerBreakthrough then
			if MatchKeeperConfig.DebugKeeperSaveTarget then
				print("[KEEPER DEBUG] Phase: HoldUntilCleanup (Breakthrough)")
			end
			if reactionTrack then
				pcall(function()
					reactionTrack.Looped = false
					reactionTrack:AdjustSpeed(0)
				end)
			end

			local knockdownHold =
				math.max(tonumber(MatchKeeperConfig.PowerBreakthroughKnockdownHoldDuration) or 4.0, 0.1)
			local holdStartedAt = os.clock()

			if ShouldUsePowerBreakthroughRagdoll() then
				setKeeperAnchored(false)
			else
				setKeeperAnchored(true)
				ApplyPivot(keeperModel, reactionData.LandedCFrame or reactionData.InterceptCFrame)
			end

			while
				self.ReactionId == reactionId
				and self.State == "React"
				and keeperModel.Parent ~= nil
				and os.clock() - holdStartedAt < knockdownHold
			do
				if not ShouldUsePowerBreakthroughRagdoll() then
					ZeroModelVelocity(keeperModel)
					setKeeperAnchored(true)
				end
				RunService.RenderStepped:Wait()
			end
			if not ShouldUsePowerBreakthroughRagdoll() then
				setKeeperAnchored(false)
				self:_restoreCinematicPartStates()
			end
			return
		end

		if reactionData.CenterSaveKnockdown then
			if MatchKeeperConfig.DebugKeeperSaveTarget then
				print("[KEEPER DEBUG] Phase: CenterSaveGroundedKnockdown")
			end

			if reactionTrack then
				pcall(function()
					reactionTrack.Looped = false
					reactionTrack:AdjustSpeed(0)
				end)
			end

			if MatchKeeperConfig.CenterSaveGroundedKnockdownUseRagdoll ~= false then
				-- Physical ragdoll collapse
				local anchorStates = {}
				local partStates = {}
				local ragdollCanCollide = MatchKeeperConfig.PowerBreakthroughRagdollCanCollide ~= false
				for _, descendant in ipairs(keeperModel:GetDescendants()) do
					if descendant:IsA("BasePart") then
						anchorStates[descendant] = descendant.Anchored
						partStates[descendant] = {
							Anchored = descendant.Anchored,
							CanCollide = descendant.CanCollide,
							CanTouch = descendant.CanTouch,
							CanQuery = descendant.CanQuery,
							CollisionGroup = descendant.CollisionGroup,
							Massless = descendant.Massless,
						}
						descendant.Anchored = false
						descendant.CanCollide = ragdollCanCollide
						descendant.CanTouch = false
						descendant.CanQuery = false
						descendant.AssemblyLinearVelocity = Vector3.zero
						descendant.AssemblyAngularVelocity = Vector3.zero
					end
				end

				local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
				local rootCFrame = (root and root:IsA("BasePart") and root.CFrame)
					or GetInstanceCFrame(keeperModel)
					or self.BaseCFrame
					or CFrame.new()

				local humanoid = keeperModel:FindFirstChildOfClass("Humanoid")
				if humanoid then
					pcall(function()
						humanoid.AutoRotate = false
						humanoid.PlatformStand = true
						humanoid:ChangeState(Enum.HumanoidStateType.Physics)
					end)
				end

				local ragdoll = nil
				ragdoll = RagdollModule.new(keeperModel, {
					CanCollide = ragdollCanCollide,
					CanTouch = false,
					CanQuery = false,
				})
				local ragdollOk = pcall(function()
					ragdoll:enableRagdoll()
				end)

				-- Apply a small backward pushback to make the keeper fall backward nicely
				local forwardVector = reactionData and reactionData.ForwardVector or rootCFrame.LookVector
				local backwardDir = -GetFlatUnit(forwardVector)
				local pushbackSpeed = tonumber(MatchKeeperConfig.CenterSaveKnockdownBackDistance) or 1.25
				local impulseVelocity = backwardDir * (pushbackSpeed * 3) + Vector3.new(0, -1.5, 0)

				for part in pairs(partStates) do
					if part and part.Parent and part:IsA("BasePart") then
						part.AssemblyLinearVelocity = impulseVelocity
					end
				end

				local renderStepName = string.format(
					"KeeperCenterSaveKnockdownRagdoll_%d_%s",
					reactionId,
					tostring(os.clock()):gsub("%.", "_")
				)
				self.ActivePowerBreakthroughRagdoll = {
					ReactionId = reactionId,
					Ragdoll = ragdoll,
					AnchorStates = anchorStates,
					PartStates = partStates,
					RenderStepName = renderStepName,
				}

				pcall(function()
					RunService:UnbindFromRenderStep(renderStepName)
				end)

				local holdStartedAt = os.clock()
				local rootMinY = (self.BaseCFrame and self.BaseCFrame.Position.Y or 3.5) - 0.04
				RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Last.Value + 90, function()
					if self.ReactionId ~= reactionId or self.State ~= "React" or not keeperModel.Parent then
						self:_cleanupActivePowerBreakthroughRagdoll()
						return
					end

					local currentRoot = keeperModel:FindFirstChild("HumanoidRootPart", true)
					local isGrounded = false
					if currentRoot and currentRoot:IsA("BasePart") then
						if currentRoot.Position.Y <= rootMinY + 0.35 then
							isGrounded = true
						end
					end

					for part in pairs(partStates) do
						if part and part.Parent and part:IsA("BasePart") then
							if isGrounded then
								-- Kill physics permanently on the ground
								part.Anchored = true
								part.AssemblyLinearVelocity = Vector3.zero
								part.AssemblyAngularVelocity = Vector3.zero
							else
								-- Keep unanchored while falling
								if part.Anchored then
									part.Anchored = false
								end

								-- Speed Cap: Keep horizontal speed <= 10 studs/s, and vertical speed <= 0
								local vel = part.AssemblyLinearVelocity
								local vx = vel.X
								local vy = math.min(vel.Y, 0)
								local vz = vel.Z

								local horiz = Vector2.new(vx, vz)
								if horiz.Magnitude > 10 then
									horiz = horiz.Unit * 10
								end
								part.AssemblyLinearVelocity = Vector3.new(horiz.X, vy, horiz.Y)
							end
						end
					end
				end)

				local maxHold = tonumber(MatchKeeperConfig.SavePoseHoldDuration) or 6.0
				while self.ReactionId == reactionId and self.State == "React" and keeperModel.Parent ~= nil do
					RunService.RenderStepped:Wait()
					if
						MatchKeeperConfig.KeeperSafePoseHoldUntilCleanup ~= true
						and os.clock() - holdStartedAt >= maxHold
					then
						break
					end
				end

				self:_cleanupActivePowerBreakthroughRagdoll()
			else
				-- Statically tween to knockdown position (legacy mode)
				local knockdownCFrame = self:_buildCenterSaveKnockdownCFrame(keeperModel, reactionData)
				local knockdownDuration =
					math.max(tonumber(MatchKeeperConfig.CenterSaveKnockdownDuration) or 0.18, 0.03)
				DisableKeeperPhysicalContact(keeperModel)
				setKeeperAnchored(true)
				if knockdownCFrame then
					self:_playPivotTween(
						keeperModel,
						knockdownCFrame,
						TweenInfo.new(knockdownDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					)
					task.wait(knockdownDuration)
					self:_clearTweenState()
					ApplyPivot(keeperModel, knockdownCFrame)
				end

				local holdStartedAt = os.clock()
				while self.ReactionId == reactionId and self.State == "React" and keeperModel.Parent ~= nil do
					ZeroModelVelocity(keeperModel)
					RunService.RenderStepped:Wait()

					local maxHold = tonumber(MatchKeeperConfig.SavePoseHoldDuration) or 6.0
					if
						MatchKeeperConfig.KeeperSafePoseHoldUntilCleanup ~= true
						and os.clock() - holdStartedAt >= maxHold
					then
						break
					end
				end
			end
			return
		end

		if reactionData.KeepSavePose then
			if MatchKeeperConfig.DebugKeeperSaveTarget then
				print("[KEEPER DEBUG] Phase: HoldUntilCleanup (Save Pose)")
			end
			if reactionTrack and MatchKeeperConfig.SaveFreezeAnimationAtLanded ~= false then
				pcall(function()
					reactionTrack.Looped = false
					reactionTrack:AdjustSpeed(0)
				end)
			end

			local savePoseHold = math.max(tonumber(MatchKeeperConfig.SavePoseHoldDuration) or 5.0, 0.1)
			local holdStartedAt = os.clock()

			DisableKeeperPhysicalContact(keeperModel)
			setKeeperAnchored(true)
			ApplyPivot(keeperModel, reactionData.InterceptCFrame)

			while self.ReactionId == reactionId and self.State == "React" and keeperModel.Parent ~= nil do
				ZeroModelVelocity(keeperModel)
				RunService.RenderStepped:Wait()

				if
					MatchKeeperConfig.KeeperSafePoseHoldUntilCleanup ~= true
					and os.clock() - holdStartedAt >= savePoseHold
				then
					break
				end
			end
			-- Do not unanchor here. Save pose really means "until cleanup"; releasing
			-- the root after a timeout lets humanoid physics collide with goal/net parts
			-- and can launch or drop the keeper before MatchSessionEnded cleanup.
			return
		end

		task.wait(MatchKeeperConfig.ResultPoseDuration * 0.45)
		if self.ReactionId ~= reactionId or self.State ~= "React" then
			return
		end

		self:_playAnimation(keeperModel, "Idle", 1)
		self:_playPivotTween(
			keeperModel,
			reactionData.RecoverCFrame,
			TweenInfo.new(MatchKeeperConfig.RecoverDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		)

		task.wait(MatchKeeperConfig.RecoverDuration + 0.03)
		if self.ReactionId ~= reactionId or self.State ~= "React" then
			return
		end

		if reactionData.ResultAnimation then
			self:_playAnimation(keeperModel, reactionData.ResultAnimation, 1, {
				IsLeft = reactionData.IsLeft,
			})
		end
		task.wait(MatchKeeperConfig.ResultPoseDuration)

		if self.ReactionId ~= reactionId or self.State ~= "React" then
			return
		end

		self:_playAnimation(keeperModel, "Idle", 1)
	end)
end

-- BeginStandby: keeper diam di base position, facing update real-time ke arah bola.
-- Tidak ada movement/patrol — advance distance selalu 0 sehingga loop lama adalah dead code.
function MatchKeeperPresentationController:BeginStandby()
	if self:_isKeeperImpactLocked() then
		return
	end

	self:StopAll()
	self.State = "Standby"

	-- Version token untuk membatalkan spawn lama saat BeginStandby dipanggil ulang
	self.StandbyToken = (self.StandbyToken or 0) + 1
	local myToken = self.StandbyToken

	task.spawn(function()
		local keeperModel = nil

		for _ = 1, 40 do
			if self.StandbyToken ~= myToken then
				return
			end
			keeperModel = GetKeeperModel()
			if keeperModel then
				break
			end
			task.wait(0.25)
		end

		if self.StandbyToken ~= myToken then
			return
		end
		if not keeperModel or self.State ~= "Standby" then
			return
		end

		self:_buildBaseState(keeperModel)
		if not self.BaseCFrame or not self.BaseLookVector then
			return
		end

		ResetKeeperRuntimeState(keeperModel)
		DisableKeeperPhysicalContact(keeperModel)
		ApplyPivot(keeperModel, self.BaseCFrame)
		local root = keeperModel:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.Anchored = true
		end
		self:_playAnimation(keeperModel, "Idle", 1)

		-- Cache ball controller sekali sebelum loop agar tidak overhead tiap frame
		local cachedBallController = nil
		pcall(function()
			local bc = Knit.GetController("MatchBallController")
			if bc and bc.GetBallPosition then
				cachedBallController = bc
			end
		end)

		local standbyFrameCount = 0
		local baseStateRefreshCount = 0
		self.StandbyConnection = RunService.RenderStepped:Connect(function()
			if self.StandbyToken ~= myToken then
				if self.StandbyConnection then
					self.StandbyConnection:Disconnect()
					self.StandbyConnection = nil
				end
				return
			end

			if self.State ~= "Standby" or self:_isKeeperImpactLocked() then
				return
			end
			if not keeperModel.Parent then
				self:StopAll()
				return
			end

			-- Refresh base state tiap 30 frame agar posisi tidak stale setelah ragdoll cleanup
			baseStateRefreshCount += 1
			if baseStateRefreshCount >= 30 then
				baseStateRefreshCount = 0
				self:_buildBaseState(keeperModel)
			end

			if not self.BaseCFrame then
				return
			end

			-- Update facing ke posisi bola secara real-time
			if cachedBallController then
				local ballPos = cachedBallController:GetBallPosition()
				if typeof(ballPos) == "Vector3" then
					self.FocusWorldPosition = ballPos
				end
			end

			-- Keeper diam di base, hanya rotate menghadap bola
			local keeperPos = self.BaseCFrame.Position
			local faceLook = self:_resolveLookVectorFromFocus(keeperPos)
			local targetCFrame = self:_buildCenterFacingCFrame(keeperModel, keeperPos, faceLook)
			ApplyPivot(keeperModel, targetCFrame)

			-- Re-affirm Idle tiap ~6 frame agar sistem lain tidak bisa paksa Run animation
			standbyFrameCount += 1
			if standbyFrameCount >= 6 then
				standbyFrameCount = 0
				self:_playAnimation(keeperModel, "Idle", 1)
			end
		end)
	end)
end

function MatchKeeperPresentationController:SetReady()
	if self:_isKeeperImpactLocked() then
		return
	end

	self.State = "Ready"

	if self.StandbyConnection then
		self.StandbyConnection:Disconnect()
		self.StandbyConnection = nil
	end

	local keeperModel = GetKeeperModel()
	if not keeperModel then
		return
	end
	ResetKeeperRuntimeState(keeperModel)
	DisableKeeperPhysicalContact(keeperModel)

	if not self.BaseCFrame or not self.BaseLookVector then
		self:_buildBaseState(keeperModel)
	end

	if not self.BaseCFrame or not self.BaseLookVector then
		return
	end

	local readyCFrame = self:_buildReadyCFrame(keeperModel)

	DisableKeeperPhysicalContact(keeperModel)
	self:_playAnimation(keeperModel, "Idle", 1)

	self:_playPivotTween(
		keeperModel,
		readyCFrame,
		TweenInfo.new(MatchKeeperConfig.ReadyTweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	)
end

function MatchKeeperPresentationController:ReactToShot(
	isGoal,
	ballTargetPosition,
	shootTier,
	shotTargetId,
	contactOptions
)
	if self:_isKeeperImpactLocked() then
		return
	end

	self.State = "React"
	self.ReactionId += 1
	self.CurrentKeeperState = {
		KeeperDropped = false,
	}

	if self.StandbyConnection then
		self.StandbyConnection:Disconnect()
		self.StandbyConnection = nil
	end

	local keeperModel = GetKeeperModel()
	if not keeperModel then
		warn("[KeeperPatrol] ReactToShot ignored: keeper model missing")
		return
	end
	ResetKeeperRuntimeState(keeperModel)
	DisableKeeperPhysicalContact(keeperModel)

	if not self.BaseCFrame or not self.BaseLookVector then
		self:_buildBaseState(keeperModel)
	end

	if not self.BaseCFrame or not self.BaseLookVector then
		return
	end

	local reactionData = self:_buildReactionData(keeperModel, isGoal, ballTargetPosition, shootTier, shotTargetId)
	reactionData.ShotTargetId = shotTargetId

	if reactionData.PowerBreakthrough and type(contactOptions) == "table" then
		local carryTargetPosition = contactOptions.PowerBreakthroughCarryTargetPosition
		if typeof(carryTargetPosition) == "Vector3" then
			reactionData.PowerBreakthroughCarryTargetPosition = carryTargetPosition
		end
	end

	self:_runReactionSequence(keeperModel, self.ReactionId, reactionData, ballTargetPosition, contactOptions)
end

function MatchKeeperPresentationController:StopAll()
	self:_clearKeeperImpactLock()
	self.State = "Idle"
	self.ReactionId += 1
	self.CurrentKeeperState = nil
	-- Invalidate any in-flight BeginStandby task.spawn by bumping the token
	self.StandbyToken = (self.StandbyToken or 0) + 1
	local returnCFrame = self.BaseCFrame

	if self.StandbyConnection then
		self.StandbyConnection:Disconnect()
		self.StandbyConnection = nil
	end

	self:_clearTweenState()
	self:_stopAllPowerBreakthroughPushbacks()
	self:_cleanupActivePowerBreakthroughRagdoll()
	self:_cleanupActiveGoalImpactRagdoll()
	self:_restoreCinematicPartStates()
	self.PowerBreakthroughPushbackByReactionId = {}
	self.PowerBreakthroughBoundNamesByReactionId = {}

	self.BaseCFrame = nil
	self.BaseLookVector = nil
	self.GroundIgnoreInstances = nil
	self.FocusWorldPosition = nil

	local keeperModel = GetKeeperModel()
	if keeperModel then
		ResetKeeperRuntimeState(keeperModel)
		DisableKeeperPhysicalContact(keeperModel)
		if returnCFrame then
			ApplyPivot(keeperModel, returnCFrame)
		end
		local root = keeperModel:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.Anchored = true
		end
	end
end

function MatchKeeperPresentationController:KnitStart()
	local MatchService = Knit.GetService("MatchService")

	MatchService.MatchSessionStarted:Connect(function(payload)
		self.ActiveSessionId = tostring(payload and payload.SessionId or "")
		self.CurrentStepIndex = 1
		self:StopAll()

		task.delay(0.35, function()
			if self.ActiveSessionId ~= tostring(payload and payload.SessionId or "") then
				return
			end
			self:BeginStandby()
		end)
	end)

	MatchService.MatchApproachStarted:Connect(function(stepPayload)
		self.CurrentStepIndex = tonumber(stepPayload and stepPayload.StepIndex or 1) or self.CurrentStepIndex
	end)

	MatchService.MatchStepStarted:Connect(function(stepPayload)
		self.CurrentStepIndex = tonumber(stepPayload and stepPayload.StepIndex or 1) or self.CurrentStepIndex
		if self.State == "Idle" and self.ActiveSessionId ~= nil then
			self:BeginStandby()
		end
	end)

	MatchService.MatchSessionEnded:Connect(function(_, sessionId)
		local endedSessionId = tostring(sessionId or "")
		if endedSessionId == "" and self.ActiveSessionId ~= nil then
			return
		end
		if
			endedSessionId ~= ""
			and self.ActiveSessionId ~= nil
			and tostring(self.ActiveSessionId) ~= endedSessionId
		then
			return
		end
		self.ActiveSessionId = nil
		self.CurrentStepIndex = 1
		self:StopAll()
	end)
end
function MatchKeeperPresentationController:DropKeeperFromGoalHold(keeperModel)
	local keeperState = self.CurrentKeeperState
	if keeperState then
		keeperState.KeeperDropped = true
	end
	
	-- Unanchor
	if keeperModel then
		local root = keeperModel:FindFirstChild("HumanoidRootPart", true)
		if root and root:IsA("BasePart") then
			root.Anchored = false
			root.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
		end
	end
end

return MatchKeeperPresentationController
