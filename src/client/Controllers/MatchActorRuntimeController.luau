local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LocalPlayer = Players.LocalPlayer

local MatchGrounding = require(ReplicatedStorage.Shared.Helpers.Match.MatchGrounding)
local MatchAnimationHelper = require(script.Parent.Parent.Helpers.Match.MatchAnimationHelper)

local LOCAL_MATCH_DEFAULT_MOVE_SPEED = 10
local LOCAL_MATCH_REACHED_EPSILON = 0.45
local INVALID_POSITION_LIMIT = 100000

local MatchCompanionVisualController = nil

local MatchActorRuntimeController = Knit.CreateController({
	Name = "MatchActorRuntimeController",

	LocalMatchStates = {},
	LocalMatchUpdateConnection = nil,
	LocalMatchAnimationStates = {},
	LocalPlayer = LocalPlayer,
})

-- // [ PRIVATE HELPERS ] // --

local function isFiniteNumber(value: number): boolean
	return value == value and value > -INVALID_POSITION_LIMIT and value < INVALID_POSITION_LIMIT
end

local function isValidVector3(value): boolean
	return typeof(value) == "Vector3"
		and isFiniteNumber(value.X)
		and isFiniteNumber(value.Y)
		and isFiniteNumber(value.Z)
end

local function isValidCFrame(value): boolean
	return typeof(value) == "CFrame" and isValidVector3(value.Position)
end

local function safePivotTo(model: Model, targetCFrame: CFrame): boolean
	if not model or not model.Parent or not isValidCFrame(targetCFrame) then
		return false
	end

	local ok = pcall(function()
		model:PivotTo(targetCFrame)
	end)

	return ok
end

local function getModelRootPart(model: Model): BasePart?
	if not model then
		return nil
	end

	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function getFlatUnit(vector: Vector3): Vector3
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return flat.Unit
end

local function buildFlatFacingCFrame(position: Vector3, lookVector: Vector3): CFrame
	local flatLook = getFlatUnit(lookVector)
	return CFrame.lookAt(position, position + flatLook)
end

local function isLocomotionAnimation(animationName: string?): boolean
	return animationName == "Run"
		or animationName == "Dribble"
		or animationName == "StrafeLeft"
		or animationName == "StrafeRight"
		or animationName == "WalkLeft"
		or animationName == "WalkRight"
end

local function hasAnyEntry(map)
	for _ in pairs(map) do
		return true
	end

	return false
end

local function resolveSlotLookVector(
	slotState,
	currentPos: Vector3,
	nextPos: Vector3,
	targetCFrame: CFrame,
	reached: boolean
): Vector3
	local facingMode = slotState.FacingMode or "MoveDirection"
	local lookAtPosition = slotState.LookAtPosition

	if (facingMode == "LookAtPosition" or facingMode == "Idle") and isValidVector3(lookAtPosition) then
		local toLook = Vector3.new(lookAtPosition.X - nextPos.X, 0, lookAtPosition.Z - nextPos.Z)

		if toLook.Magnitude > 0.001 then
			return toLook
		end
	end

	if reached then
		return targetCFrame.LookVector
	end

	local moveLook = targetCFrame.Position - currentPos
	if moveLook.Magnitude > 0.001 then
		return moveLook
	end

	return targetCFrame.LookVector
end

local function stepFlatTowards(currentPos: Vector3, targetPos: Vector3, studsPerSecond: number, deltaTime: number)
	local delta = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)
	local distance = delta.Magnitude

	if distance <= 0.001 then
		return targetPos, true
	end

	local step = math.min(math.max(studsPerSecond, 1) * math.max(deltaTime, 0), distance)
	local nextFlat = currentPos + (delta.Unit * step)
	local nextPos = Vector3.new(nextFlat.X, targetPos.Y, nextFlat.Z)

	local reached = distance <= math.max(LOCAL_MATCH_REACHED_EPSILON, step)
	if reached then
		nextPos = targetPos
	end

	return nextPos, reached
end

local function getAnimationFallbackName(animationName: string?): string
	if animationName == "StrafeLeft" or animationName == "StrafeRight" then
		return "Run"
	end

	if animationName == nil or animationName == "" then
		return "Idle"
	end

	return animationName
end

-- // [ GROUNDING ] // --

function MatchActorRuntimeController:_groundActorCFrame(actorModel: Model, targetCFrame: CFrame): CFrame
	if not actorModel or not isValidCFrame(targetCFrame) then
		return targetCFrame
	end

	local groundedCFrame = MatchGrounding.GetGroundedCFrame(actorModel, targetCFrame, {
		IgnoreMatchRuntimeRoot = true,
		FallbackY = targetCFrame.Position.Y,
	})

	return buildFlatFacingCFrame(groundedCFrame.Position, targetCFrame.LookVector)
end

-- // [ STATE ] // --

function MatchActorRuntimeController:_getOrCreateLocalMatchState(ownerPlayer: Player)
	local state = self.LocalMatchStates[ownerPlayer]
	if state then
		return state
	end

	state = {
		Owner = ownerPlayer,
		Slots = {},
		Started = false,
		Paused = false,
		TimeScale = 1,
	}

	self.LocalMatchStates[ownerPlayer] = state
	return state
end

function MatchActorRuntimeController:_clearLocalMatchState(ownerPlayer: Player)
	self.LocalMatchStates[ownerPlayer] = nil
end

function MatchActorRuntimeController:_registerLocalMatchSlot(ownerPlayer: Player, slotNumber: number, model: Model)
	if not ownerPlayer or not model then
		return nil
	end

	local state = self:_getOrCreateLocalMatchState(ownerPlayer)
	local root = getModelRootPart(model)
	if not root then
		return nil
	end

	local slotState = state.Slots[slotNumber]
	if slotState then
		slotState.Model = model
		slotState.Root = root
		slotState.OwnerState = state
		return slotState
	end

	slotState = {
		SlotNumber = slotNumber,
		OwnerState = state,
		Model = model,
		Root = root,
		OriginalCFrame = model:GetPivot(),
		OriginalAnchored = root.Anchored,
		CurrentCFrame = model:GetPivot(),
		TargetCFrame = model:GetPivot(),
		MoveSpeed = LOCAL_MATCH_DEFAULT_MOVE_SPEED,
		ExpectedAnimation = "Idle",
		KeepAnimationWhenReached = false,
		LookAtPosition = nil,
		FacingMode = "MoveDirection",
		HasReachedTarget = true,
	}

	state.Slots[slotNumber] = slotState
	return slotState
end

-- // [ ANIMATION ] // --

function MatchActorRuntimeController:_playSlotAnimation(slotState, requestedAnimation)
	if not slotState or not slotState.Model then
		return
	end

	local ownerState = slotState.OwnerState
	if ownerState and ownerState.AnimationFrozen then
		return
	end

	local animationName = requestedAnimation or "Idle"
	local speed = 1
	local ownerState = slotState.OwnerState
	local timeScale = ownerState and tonumber(ownerState.AnimationScale or ownerState.TimeScale) or 1

	if isLocomotionAnimation(animationName) then
		-- Tactical movement normally keeps locomotion readable; QTE can scale this down.
		speed = MatchAnimationHelper.ComputeRunSpeed(slotState.MoveSpeed)
	end
	speed *= math.max(timeScale, 0.03)

	local animationState =
		MatchAnimationHelper.Play(self.LocalMatchAnimationStates, slotState.Model, animationName, { speed = speed })

	if not animationState and animationName ~= "Run" then
		local fallbackName = getAnimationFallbackName(animationName)
		animationState = MatchAnimationHelper.Play(
			self.LocalMatchAnimationStates,
			slotState.Model,
			fallbackName,
			{ speed = isLocomotionAnimation(fallbackName) and speed or 1 }
		)
	end

	if not animationState and animationName ~= "Idle" then
		animationState =
			MatchAnimationHelper.Play(self.LocalMatchAnimationStates, slotState.Model, "Idle", { speed = 1 })
	end

	local state = self.LocalMatchStates[LocalPlayer]
	if state and state.Paused and animationState and animationState.Track then
		animationState.Track:AdjustSpeed(0)
	end
end

-- // [ UPDATE LOOP ] // --

function MatchActorRuntimeController:_ensureLocalMatchUpdateLoop()
	if self.LocalMatchUpdateConnection then
		return
	end

	self.LocalMatchUpdateConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local hasActiveState = false

		for ownerPlayer, state in pairs(self.LocalMatchStates) do
			if not ownerPlayer or not ownerPlayer.Parent then
				self.LocalMatchStates[ownerPlayer] = nil
				continue
			end

			hasActiveState = true

			if state.Paused then
				continue
			end

			for _, slotState in pairs(state.Slots) do
				local model = slotState.Model
				local root = slotState.Root

				if not model or not model.Parent or not root or not root.Parent then
					continue
				end

				if slotState.ControlOverride == true then
					continue
				end

				local currentCFrame = slotState.CurrentCFrame or model:GetPivot()
				local targetCFrame = slotState.TargetCFrame or currentCFrame

				if not isValidCFrame(currentCFrame) or not isValidCFrame(targetCFrame) then
					continue
				end

				local currentPos = currentCFrame.Position
				local targetPos = targetCFrame.Position

				local timeScale = math.max(tonumber(state.TimeScale) or 1, 0)
				local nextPos, reached = stepFlatTowards(
					currentPos,
					targetPos,
					slotState.MoveSpeed or LOCAL_MATCH_DEFAULT_MOVE_SPEED,
					deltaTime * timeScale
				)

				local moveLook = resolveSlotLookVector(slotState, currentPos, nextPos, targetCFrame, reached)
				local nextCFrame = buildFlatFacingCFrame(nextPos, moveLook)
				local groundedCFrame = self:_groundActorCFrame(model, nextCFrame)

				if not safePivotTo(model, groundedCFrame) then
					continue
				end

				slotState.CurrentCFrame = groundedCFrame
				slotState.HasReachedTarget = reached

				local requestedAnimation = slotState.ExpectedAnimation or "Idle"

				if slotState.SlotNumber == 5 then
					requestedAnimation = "Idle"
				elseif not reached then
					if not isLocomotionAnimation(requestedAnimation) then
						requestedAnimation = "Run"
					end
				elseif isLocomotionAnimation(requestedAnimation) and not slotState.KeepAnimationWhenReached then
					requestedAnimation = "Idle"
				end

				self:_playSlotAnimation(slotState, requestedAnimation)

				if reached then
					local finalLook = resolveSlotLookVector(slotState, currentPos, targetPos, targetCFrame, true)
					local finalFacingCFrame = buildFlatFacingCFrame(targetCFrame.Position, finalLook)
					local groundedTarget = self:_groundActorCFrame(model, finalFacingCFrame)

					if safePivotTo(model, groundedTarget) then
						slotState.CurrentCFrame = groundedTarget
					end
				end
			end
		end

		if not hasActiveState and self.LocalMatchUpdateConnection then
			self.LocalMatchUpdateConnection:Disconnect()
			self.LocalMatchUpdateConnection = nil
		end
	end)
end

-- // [ PUBLIC API ] // --

function MatchActorRuntimeController:IsLocalMatchActive(player: Player): boolean
	if not player then
		return false
	end

	local state = self.LocalMatchStates[player]
	return state ~= nil and state.Started == true
end

function MatchActorRuntimeController:HasLocalMatchActorReachedTarget(ownerPlayer: Player, slotNumber)
	local state = ownerPlayer and self.LocalMatchStates[ownerPlayer]
	if not state then
		return false
	end

	local slotState = state.Slots[tonumber(slotNumber)]
	if not slotState then
		return false
	end

	return slotState.HasReachedTarget == true
end

function MatchActorRuntimeController:GetLocalMatchActorCFrame(ownerPlayer: Player, slotNumber)
	local state = ownerPlayer and self.LocalMatchStates[ownerPlayer]
	if not state then
		return nil
	end

	local slotState = state.Slots[tonumber(slotNumber)]
	if not slotState then
		return nil
	end

	return slotState.CurrentCFrame or (slotState.Model and slotState.Model:GetPivot()) or nil
end

function MatchActorRuntimeController:GetLocalMatchActorModel(ownerPlayer: Player, slotNumber)
	local state = ownerPlayer and self.LocalMatchStates[ownerPlayer]
	if not state then
		return nil
	end

	local slotState = state.Slots[tonumber(slotNumber)]
	if not slotState then
		return nil
	end

	if slotState.Model and slotState.Model.Parent then
		return slotState.Model
	end

	return nil
end

function MatchActorRuntimeController:SetLocalMatchActorTarget(ownerPlayer: Player, slotNumber, targetCFrame, options)
	if not ownerPlayer or not isValidCFrame(targetCFrame) then
		return false
	end

	local state = self:_getOrCreateLocalMatchState(ownerPlayer)
	local slotState = state.Slots[tonumber(slotNumber)]
	if not slotState or not slotState.Model or not slotState.Model.Parent then
		return false
	end

	local currentCFrame = slotState.CurrentCFrame or slotState.Model:GetPivot()

	if state.Paused then
		local groundedCurrent = self:_groundActorCFrame(slotState.Model, currentCFrame)
		slotState.CurrentCFrame = groundedCurrent
		slotState.TargetCFrame = groundedCurrent
		slotState.MoveSpeed = 0
		slotState.ExpectedAnimation = "Idle"
		slotState.KeepAnimationWhenReached = false
		slotState.LookAtPosition = nil
		slotState.FacingMode = "MoveDirection"
		slotState.HasReachedTarget = true
		safePivotTo(slotState.Model, groundedCurrent)
		return true
	end

	slotState.TargetCFrame = self:_groundActorCFrame(slotState.Model, targetCFrame)
	slotState.MoveSpeed = (options and options.MoveSpeed) or LOCAL_MATCH_DEFAULT_MOVE_SPEED
	slotState.ExpectedAnimation = (options and options.ExpectedAnimation) or "Idle"
	slotState.KeepAnimationWhenReached = (options and options.KeepAnimationWhenReached) == true
	slotState.LookAtPosition = options and options.LookAtPosition or nil
	slotState.FacingMode = options and options.FacingMode or "MoveDirection"
	slotState.HasReachedTarget = false

	return true
end

function MatchActorRuntimeController:BeginLocalMatchIsolation(player: Player, companionPivotOrder)
	if not player or not MatchCompanionVisualController then
		return false
	end

	local ownedCompanions = MatchCompanionVisualController:GetOwnedCompanionModels(player)
	local resolvedPivotOrder = MatchCompanionVisualController:ResolveMatchCompanionPivotOrder(companionPivotOrder)
	local state = self:_getOrCreateLocalMatchState(player)

	state.Started = true
	state.Paused = false
	state.TimeScale = 1

	for index, companionModel in ipairs(ownedCompanions) do
		local targetSlotNumber = resolvedPivotOrder[index] or (index + 1)
		local fallbackCFrame = companionModel:GetPivot()
		local targetCFrame =
			MatchCompanionVisualController:GetMatchCompanionPivotCFrame(targetSlotNumber, fallbackCFrame)
		local slotState = self:_registerLocalMatchSlot(player, targetSlotNumber, companionModel)

		if slotState and slotState.Root then
			slotState.Root.Anchored = true
			slotState.TargetCFrame = self:_groundActorCFrame(companionModel, targetCFrame)
			slotState.CurrentCFrame = slotState.TargetCFrame
			slotState.MoveSpeed = LOCAL_MATCH_DEFAULT_MOVE_SPEED
			slotState.ExpectedAnimation = "Idle"
			slotState.KeepAnimationWhenReached = false
			slotState.LookAtPosition = nil
			slotState.FacingMode = "MoveDirection"
			slotState.HasReachedTarget = true

			safePivotTo(companionModel, slotState.TargetCFrame)
			MatchCompanionVisualController:SyncCompanionGridStateToCFrame(player, index, slotState.TargetCFrame)
			MatchCompanionVisualController:SetOwnerVisualHidden(player, false, false)
			self:_playSlotAnimation(slotState, "Idle")
		end
	end

	self:_ensureLocalMatchUpdateLoop()
	MatchCompanionVisualController:SetOwnerVisualHidden(player, false, false)

	return true
end

function MatchActorRuntimeController:EndLocalMatchIsolation(player: Player)
	if not player or not MatchCompanionVisualController then
		return false
	end

	local state = self.LocalMatchStates[player]
	if not state then
		MatchCompanionVisualController:RestoreCompanionsBehindOwner(player)
		MatchCompanionVisualController:SetOwnerVisualHidden(player, false, false)
		return false
	end

	for _, slotState in pairs(state.Slots) do
		local model = slotState.Model
		local root = slotState.Root

		if model and model.Parent and slotState.OriginalCFrame then
			safePivotTo(model, slotState.OriginalCFrame)
			MatchAnimationHelper.ResetModel(self.LocalMatchAnimationStates, model)
		end

		if root and root.Parent then
			root.Anchored = slotState.OriginalAnchored == true
		end
	end

	self:_clearLocalMatchState(player)
	if not hasAnyEntry(self.LocalMatchStates) and self.LocalMatchUpdateConnection then
		self.LocalMatchUpdateConnection:Disconnect()
		self.LocalMatchUpdateConnection = nil
	end

	MatchCompanionVisualController:RestoreCompanionsBehindOwner(player)
	MatchCompanionVisualController:SetOwnerVisualHidden(player, false, false)

	return true
end

function MatchActorRuntimeController:PauseLocalMatch(player: Player)
	if not player then
		return false
	end

	local state = self.LocalMatchStates[player]
	if not state then
		return false
	end

	state.Paused = true

	for _, slotState in pairs(state.Slots) do
		if slotState.Model and slotState.Model.Parent then
			local groundedCurrent = self:_groundActorCFrame(slotState.Model, slotState.Model:GetPivot())

			-- Preserve locomotion intent while QTE is frozen. Forcing Idle here creates
			-- a visible idle frame after Dribble/Pass QTE resolves.
			slotState.PausedExpectedAnimation = slotState.ExpectedAnimation
			slotState.PausedFacingMode = slotState.FacingMode
			slotState.PausedLookAtPosition = slotState.LookAtPosition

			slotState.CurrentCFrame = groundedCurrent
			slotState.TargetCFrame = groundedCurrent
			slotState.MoveSpeed = 0
			slotState.KeepAnimationWhenReached = true
			slotState.HasReachedTarget = true
			safePivotTo(slotState.Model, groundedCurrent)

			local animator = slotState.Model:FindFirstChildWhichIsA("Animator", true)
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(0)
				end
			end
		end
	end

	return true
end

function MatchActorRuntimeController:ResumeLocalMatch(player: Player)
	if not player then
		return false
	end

	local state = self.LocalMatchStates[player]
	if not state then
		return false
	end

	state.Paused = false

	for _, slotState in pairs(state.Slots) do
		if slotState.Model and slotState.Model.Parent then
			local groundedCurrent = self:_groundActorCFrame(slotState.Model, slotState.Model:GetPivot())
			local preservedAnimation = slotState.PausedExpectedAnimation or slotState.ExpectedAnimation or "Run"

			slotState.CurrentCFrame = groundedCurrent
			slotState.TargetCFrame = groundedCurrent
			slotState.MoveSpeed = 0
			slotState.ExpectedAnimation = preservedAnimation
			slotState.FacingMode = slotState.PausedFacingMode or slotState.FacingMode or "MoveDirection"
			slotState.LookAtPosition = slotState.PausedLookAtPosition
			slotState.KeepAnimationWhenReached = true
			slotState.HasReachedTarget = true

			slotState.PausedExpectedAnimation = nil
			slotState.PausedFacingMode = nil
			slotState.PausedLookAtPosition = nil

			local animator = slotState.Model:FindFirstChildWhichIsA("Animator", true)
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(1)
				end
			end
		end
	end

	return true
end

function MatchActorRuntimeController:SetLocalMatchTimeScale(player: Player, scale: number, animationScale: number?)
	if not player then
		return false
	end

	local state = self.LocalMatchStates[player]
	if not state then
		return false
	end

	state.TimeScale = math.max(tonumber(scale) or 1, 0.01)
	state.AnimationScale = animationScale and math.max(tonumber(animationScale) or 1, 0.01) or nil

	for _, slotState in pairs(state.Slots) do
		if slotState.Model and slotState.Model.Parent then
			self:_playSlotAnimation(slotState, slotState.ExpectedAnimation or "Idle")
		end
	end

	return true
end

function MatchActorRuntimeController:SetLocalMatchAnimationFrozen(player: Player, frozen: boolean)
	if not player then
		return false
	end

	local state = self.LocalMatchStates[player]
	if not state then
		return false
	end

	state.AnimationFrozen = frozen
	return true
end

function MatchActorRuntimeController:IsPaused(player: Player)
	local state = self.LocalMatchStates[player]
	return state and state.Paused == true
end

function MatchActorRuntimeController:SetSlotControlOverride(ownerPlayer: Player, slotNumber: number, locked: boolean)
	local state = self.LocalMatchStates[ownerPlayer]
	if not state then
		return
	end

	local slotState = state.Slots[tonumber(slotNumber)]
	if slotState then
		slotState.ControlOverride = locked
	end
end

-- // [ KNIT LIFECYCLE ] // --

function MatchActorRuntimeController:KnitInit()
	self.LocalMatchStates = {}
	self.LocalMatchAnimationStates = {}
	self.LocalMatchUpdateConnection = nil
end

function MatchActorRuntimeController:KnitStart()
	MatchCompanionVisualController = Knit.GetController("MatchCompanionVisualController")
end

return MatchActorRuntimeController
