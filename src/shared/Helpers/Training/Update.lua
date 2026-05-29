local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Sound = require(ReplicatedStorage.Packages.Sound)

local Settings = require(script.Parent.Settings)
local TrainingRuntimeRegistry = require(script.Parent.TrainingRuntimeRegistry)

local DEFAULT_IDLE = "rbxassetid://507766388"
local DEFAULT_RUN = "rbxassetid://507767714"
local DEFAULT_DRIBBLE = "rbxassetid://105106002784990"
local DEFAULT_JUMP = "rbxassetid://507765000"
local DEFAULT_FALL = "rbxassetid://507767968"
local DEFAULT_SHOOT = "rbxassetid://90962989306225"

local function GetAnimationOffset(timeElapsed)
	local speed = Settings.GroundSpeed
	local maxHeight = Settings.GroundMaxHeight
	local forwardAngle = Settings.GroundForwardAngle
	local backwardAngle = Settings.GroundBackwardAngle

	local sinTime = math.sin(timeElapsed * speed)
	local newHeight = 0

	local newRotation
	if sinTime * maxHeight >= 0 then
		newRotation = sinTime * forwardAngle
	else
		newRotation = sinTime * backwardAngle
	end

	local animationLeft = true
	if newHeight > 0.15 then
		animationLeft = true
	else
		animationLeft = false
		newRotation = 0
		newHeight = 0
	end

	return {
		Rotation = CFrame.fromOrientation(newRotation, 0, 0),
		Height = newHeight,
		AnimationLeft = animationLeft,
	}
end

local function GetFollowPositionOffset(grid)
	local xOffset = ((grid.Column - (grid.TotalColumns + 1) / 2) * Settings.XSpacing)
	local zOffset = (
		Settings.PlayerSpacing
		+ -(-(grid.Row - (grid.TotalRows + 1) / 2) * Settings.ZSpacing - (grid.TotalRows / 2) * Settings.ZSpacing)
	)

	return CFrame.new(xOffset, 0, zOffset)
end

local function SafeLoadAnimation(animator, animationId, animationName, modelName)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()

	if not success or not track then
		warn(
			string.format(
				"[TrainingUpdate] Failed to load %s animation (%s) for %s. Error: %s",
				animationName,
				animationId,
				modelName,
				tostring(track)
			)
		)
		return nil
	end
	return track
end

local function BuildTrainingBallReleaseToken(ownerVisualState, trainingState)
	if not ownerVisualState or not trainingState then
		return nil
	end

	return table.concat({
		tostring(ownerVisualState.ServerStartTime or ""),
		tostring(trainingState.Mode or ""),
		tostring(trainingState.ActorIndex or ""),
		tostring(trainingState.CycleIndex or ""),
		tostring(trainingState.PhaseName or ""),
	}, ":")
end

local function IsEmbeddedBallPart(part)
	if not part or not part:IsA("BasePart") then
		return false
	end

	local loweredPartName = string.lower(part.Name)
	if loweredPartName == "football" or loweredPartName == "soccerball" or loweredPartName == "matchball" then
		return true
	end

	local current = part
	while current do
		local loweredName = string.lower(current.Name)
		if loweredName == "football" or loweredName == "ballroot" then
			return true
		end
		current = current.Parent
	end

	return loweredPartName == "ball"
end

local function CollectEmbeddedBallParts(model)
	local parts = {}
	local visited = {}

	if not model or typeof(model) ~= "Instance" then
		return parts
	end

	local function addPart(part)
		if part and part:IsA("BasePart") and not visited[part] then
			visited[part] = true
			table.insert(parts, part)
		end
	end

	local footballRoot = model:FindFirstChild("Football", true)
	if footballRoot then
		if footballRoot:IsA("BasePart") then
			addPart(footballRoot)
		end

		for _, descendant in ipairs(footballRoot:GetDescendants()) do
			if descendant:IsA("BasePart") then
				addPart(descendant)
			end
		end
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and IsEmbeddedBallPart(descendant) then
			addPart(descendant)
		end
	end

	return parts
end

local function GetEmbeddedBallParts(lastInfo, model)
	if not lastInfo then
		return {}
	end

	if lastInfo.EmbeddedBallModel ~= model then
		lastInfo.EmbeddedBallModel = model
		lastInfo.EmbeddedBallParts = CollectEmbeddedBallParts(model)
	end

	return lastInfo.EmbeddedBallParts or {}
end

local function SetEmbeddedBallVisible(lastInfo, model, isVisible)
	local targetTransparency = isVisible and 0 or 1

	for _, part in ipairs(GetEmbeddedBallParts(lastInfo, model)) do
		if part and part.Parent then
			part.Transparency = targetTransparency
			part.LocalTransparencyModifier = targetTransparency
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = isVisible == true

			local oldDribbleTrail = part:FindFirstChild("TrainingDribbleTrail")
			if oldDribbleTrail and oldDribbleTrail:IsA("Trail") then
				oldDribbleTrail.Enabled = false
			end
		end
	end
end

local function ShouldShowEmbeddedTrainingBall(ownerVisualState, trainingState)
	if not ownerVisualState or not trainingState then
		return false
	end

	if trainingState.Mode == "DribbleTraining" then
		return trainingState.ActorIndex == trainingState.RunnerIndex
			and (trainingState.PhaseName == "StartHold" or trainingState.PhaseName == "NodeRun")
	end

	if trainingState.Mode == "ShootTraining" then
		if trainingState.ActorIndex ~= trainingState.ShooterIndex then
			return false
		end

		if trainingState.PhaseName == "ReadyToShoot" then
			return true
		end

		if trainingState.PhaseName ~= "Shooting" then
			return false
		end
	elseif trainingState.Mode == "PassTraining" then
		if trainingState.PhaseName == "ForwardSettle" then
			if trainingState.ActorIndex ~= 1 and trainingState.ActorIndex ~= 4 then
				return false
			end
		elseif trainingState.PhaseName == "BackwardSettle" then
			if trainingState.ActorIndex ~= 2 and trainingState.ActorIndex ~= 3 then
				return false
			end
		elseif trainingState.ExpectedAnimation ~= "Shoot" then
			return false
		end
	else
		return false
	end

	local releaseToken = BuildTrainingBallReleaseToken(ownerVisualState, trainingState)

	if trainingState.Mode == "PassTraining" and trainingState.ExpectedAnimation ~= "Shoot" then
		local receiveTokens = ownerVisualState._TrainingPassReceiveTokens
		return releaseToken ~= nil and receiveTokens ~= nil and receiveTokens[releaseToken] == true
	end

	local releasedTokens = ownerVisualState._TrainingBallReleasedTokens
	return not (releaseToken and releasedTokens and releasedTokens[releaseToken] == true)
end

local function EnsureAnimations(lastInfo, animator, model)
	if lastInfo.Animations and lastInfo.Animations.Animator == animator and lastInfo.Animations.Shoot then
		return
	end

	local modelName = model.Name
	lastInfo.Animations = {
		Animator = animator,
	}

	lastInfo.Animations.Idle = SafeLoadAnimation(animator, DEFAULT_IDLE, "Idle", modelName)
	lastInfo.Animations.Run = SafeLoadAnimation(animator, DEFAULT_RUN, "Run", modelName)
	lastInfo.Animations.Jump = SafeLoadAnimation(animator, DEFAULT_JUMP, "Jump", modelName)
	lastInfo.Animations.Fall = SafeLoadAnimation(animator, DEFAULT_FALL, "Fall", modelName)

	local animationsFolder = model:WaitForChild("Animations")
	local shootTrainingObject = animationsFolder:FindFirstChild("Shoot - Training", true)
	if shootTrainingObject and shootTrainingObject:IsA("Animation") and shootTrainingObject.AnimationId ~= "" then
		lastInfo.Animations.Shoot =
			SafeLoadAnimation(animator, shootTrainingObject.AnimationId, "CustomTrainingShoot", modelName)
	end

	if not lastInfo.Animations.Shoot then
		local shootObject = animationsFolder:FindFirstChild("Shoot", true)
		if shootObject and shootObject:IsA("Animation") and shootObject.AnimationId ~= "" then
			lastInfo.Animations.Shoot = SafeLoadAnimation(animator, shootObject.AnimationId, "CustomShoot", modelName)
		end
	end

	if not lastInfo.Animations.Shoot then
		lastInfo.Animations.Shoot = SafeLoadAnimation(animator, DEFAULT_SHOOT, "DefaultShoot", modelName)
	end

	local dribbleObject = animationsFolder:FindFirstChild("Run", true)
	if dribbleObject and dribbleObject:IsA("Animation") and dribbleObject.AnimationId ~= "" then
		lastInfo.Animations.Dribble = SafeLoadAnimation(animator, dribbleObject.AnimationId, "CustomDribble", modelName)
	end

	if not lastInfo.Animations.Dribble then
		lastInfo.Animations.Dribble = SafeLoadAnimation(animator, DEFAULT_DRIBBLE, "DefaultDribble", modelName)
	end
end

local function PlayExpectedAnimation(lastInfo, expectedAnim, model)
	local currentAnim = lastInfo.CurrentAnimation
	local animations = lastInfo.Animations

	if currentAnim == expectedAnim then
		local track = animations[currentAnim]
		if track then
			lastInfo.ActiveTrainingAnimation = expectedAnim
			lastInfo.ActiveTrainingAnimationTrack = track

			if expectedAnim == "Shoot" then
				-- If shoot finished, replay it
				if not track.IsPlaying then
					track:Play(0.1)
					local rootPart = model
						and (
							model.PrimaryPart
							or model:FindFirstChild("HumanoidRootPart")
							or model:FindFirstChildWhichIsA("BasePart")
						)
					if rootPart then
						Sound:PlaySound("Shoot", rootPart)
					end
				end
			end
			return
		end
	end

	if currentAnim and animations[currentAnim] then
		animations[currentAnim]:Stop(0.1)
	end

	if animations[expectedAnim] then
		local track = animations[expectedAnim]
		track:Play(0.1)
		lastInfo.CurrentAnimation = expectedAnim
		lastInfo.ActiveTrainingAnimation = expectedAnim
		lastInfo.ActiveTrainingAnimationTrack = track

		if expectedAnim == "Shoot" then
			local rootPart = model
				and (
					model.PrimaryPart
					or model:FindFirstChild("HumanoidRootPart")
					or model:FindFirstChildWhichIsA("BasePart")
				)
			if rootPart then
				Sound:PlaySound("Shoot", rootPart)
			end
		end
	else
		lastInfo.ActiveTrainingAnimation = nil
		lastInfo.ActiveTrainingAnimationTrack = nil

		if expectedAnim == "Shoot" then
			warn("[TrainingUpdate] Failed to play Shoot animation: track not found in lastInfo.Animations")
		end
	end
end

local function FindAnimator(model: Model): Animator?
	if not model or model == "" then
		return nil
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if animator then
		return animator
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animationController = model:FindFirstChildOfClass("AnimationController")
	local parent = humanoid or animationController

	if parent then
		animator = parent:FindFirstChildOfClass("Animator") or Instance.new("Animator", parent)
	else
		-- If no humanoid/animController, try to find animator in any child
		animator = model:FindFirstChildOfClass("Animator")
	end

	return animator
end

local DRIBBLE_NODE_SWITCH_DISTANCE = 0.90

local function GetStableTrainingTargetPart(lastInfo, trainingState, currentPosition: Vector3): BasePart?
	if not trainingState or not trainingState.TargetPart then
		lastInfo.StickyTrainingTarget = nil
		return nil
	end

	if trainingState.Mode ~= "DribbleTraining" or trainingState.PhaseName ~= "NodeRun" then
		lastInfo.StickyTrainingTarget = nil
		return trainingState.TargetPart
	end

	local nextTarget = trainingState.TargetPart
	local stickyTarget = lastInfo.StickyTrainingTarget

	if stickyTarget and stickyTarget.Parent and stickyTarget ~= nextTarget then
		local flatCurrent = Vector3.new(currentPosition.X, 0, currentPosition.Z)
		local flatSticky = Vector3.new(stickyTarget.Position.X, 0, stickyTarget.Position.Z)

		if (flatCurrent - flatSticky).Magnitude > DRIBBLE_NODE_SWITCH_DISTANCE then
			return stickyTarget
		end
	end

	lastInfo.StickyTrainingTarget = nextTarget
	return nextTarget
end

local function GetCompanionMoveSpeed(player: Player, fallback: number, trainingState): number
	if trainingState then
		return math.max(fallback, 16)
	end

	local character = player.Character
	if not character then
		return fallback
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.WalkSpeed > 0 then
		return humanoid.WalkSpeed
	end

	return fallback
end

local function ComputeOrientation(
	positionLerp: CFrame,
	infoTarget: BasePart?,
	trainingState,
	movementTargetPart: BasePart?
)
	if trainingState then
		local moveTarget = movementTargetPart or trainingState.TargetPart
		if trainingState.FacingMode == "Move" and moveTarget then
			local from = Vector3.new(positionLerp.Position.X, 0, positionLerp.Position.Z)
			local to = Vector3.new(moveTarget.Position.X, 0, moveTarget.Position.Z)

			if (to - from).Magnitude > 0.001 then
				local orientation = CFrame.lookAt(from, to)
				return orientation - orientation.Position
			end
		end

		if trainingState.LookAtPosition then
			local from = Vector3.new(positionLerp.Position.X, 0, positionLerp.Position.Z)
			local to = Vector3.new(trainingState.LookAtPosition.X, 0, trainingState.LookAtPosition.Z)

			if (to - from).Magnitude > 0.001 then
				local orientation = CFrame.lookAt(from, to)
				return orientation - orientation.Position
			end
		end
	end

	if infoTarget then
		local connectedAxis = math.atan2(infoTarget.CFrame.LookVector.X, infoTarget.CFrame.LookVector.Z)
		connectedAxis = connectedAxis + math.rad(180)
		return CFrame.fromOrientation(0, connectedAxis, 0)
	end

	return CFrame.new()
end

local function UpdateSoccerCharacters(
	delta,
	functions,
	soccerCharactersInSession,
	soccerCharactersModule,
	soccerCharacterInstances,
	raycastExcludeModels,
	visualStates,
	accessoriesByPlayer
)
	local soccerCharactersToMove = { SoccerCharacters = {}, CFrames = {} }

	for owner, grids in pairs(soccerCharactersInSession) do
		local player = if typeof(owner) == "number" then Players:GetPlayerByUserId(owner) else owner
		if not player or not player:IsA("Player") then
			continue
		end

		local companionCount = functions.GetTableAmount(grids)
		if companionCount <= 0 then
			continue
		end

		for gridIndex, grid in pairs(grids) do
			local data = grid.Data
			local info = grid.Information
			local lastInfo = grid.LastInformation
			local isProxy = data.Name == "PlayerProxy"
			local soccerCharacterInfo = soccerCharactersModule[data.Name] or (isProxy and { Speed = 16 })

			local modelName = player.Name .. "_" .. tostring(gridIndex)

			if not soccerCharacterInfo then
				continue
			end

			local existingModel = soccerCharacterInstances:FindFirstChild(modelName)
			if existingModel and type(grid.Model) == "string" then
				grid.Model = existingModel
			end

			if not existingModel or type(grid.Model) == "string" then
				local soccerCharacterModel = functions.GetModel(data)
				if soccerCharacterModel == nil then
					if not isProxy and type(grid.Model) == "string" then
						continue
					end
				else
					grid.Model = soccerCharacterModel

					soccerCharacterModel:SetAttribute("Owner", player.Name)
					soccerCharacterModel:SetAttribute("SoccerCharacter", soccerCharacterModel.Name)
					soccerCharacterModel:SetAttribute("CompanionSlot", gridIndex + 1)

					soccerCharacterModel.Name = modelName
					soccerCharacterModel.Parent = soccerCharacterInstances

					local tempPositionOffset = GetFollowPositionOffset(grid)
					tempPositionOffset = CFrame.new((info.Target.CFrame * tempPositionOffset).Position)
					tempPositionOffset = tempPositionOffset - Vector3.new(0, tempPositionOffset.Position.Y, 0)

					soccerCharacterModel:PivotTo(tempPositionOffset)

					local accessoriesInventory = accessoriesByPlayer and accessoriesByPlayer[player] or {}
					functions.EquipAccessory(soccerCharacterModel, data, accessoriesInventory)

					table.insert(raycastExcludeModels, soccerCharacterModel)
				end
			end

			table.insert(soccerCharactersToMove.SoccerCharacters, grid.Model)

			if grid.Model == "" then
				continue
			end

			for _, part in ipairs(grid.Model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
				end
			end

			local animator = FindAnimator(grid.Model)
			if animator then
				EnsureAnimations(lastInfo, animator, grid.Model)
			else
				warn("[TrainingUpdate] No animator found for", grid.Model and grid.Model.Name or "Unknown Model")
			end

			local ownerVisualState = visualStates and visualStates[player]
			local trainingState = nil
			local actorIndex = gridIndex + 1

			if ownerVisualState then
				if ownerVisualState.ActorStates and ownerVisualState.ActorStates[actorIndex] then
					trainingState = ownerVisualState.ActorStates[actorIndex]
				else
					trainingState =
						TrainingRuntimeRegistry.GetActorState(actorIndex, companionCount + 1, ownerVisualState)
				end
			end

			local shouldSnap = ownerVisualState
				and ownerVisualState.SnapUntil
				and Workspace:GetServerTimeNow() <= ownerVisualState.SnapUntil

			local expectedAnim = "Idle"
			do
				local playerHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if playerHumanoid then
					local state = playerHumanoid:GetState()
					if state == Enum.HumanoidStateType.Jumping then
						expectedAnim = "Jump"
					elseif state == Enum.HumanoidStateType.Freefall then
						expectedAnim = "Fall"
					elseif info.Arrived == false then
						expectedAnim = "Run"
					end
				end

				if trainingState then
					if trainingState.ExpectedAnimation == "Shoot" then
						if lastInfo.Animations.Shoot then
							expectedAnim = "Shoot"
						else
							warn("[TrainingUpdate] Expected Shoot animation but track is missing for", grid.Model.Name)
						end
					elseif trainingState.ExpectedAnimation == "Dribble" then
						if lastInfo.Animations.Dribble then
							expectedAnim = "Dribble"
						else
							expectedAnim = "Run"
						end
					elseif trainingState.ExpectedAnimation == "Run" then
						expectedAnim = "Run"
					elseif trainingState.ExpectedAnimation == "Idle" then
						expectedAnim = "Idle"
					end
				end
			end

			if expectedAnim == "Idle" and info.Arrived == false then
				local distance = lastInfo.Distance or 0
				if distance > 0.5 then
					expectedAnim = "Run"
				end
			end

			if animator then
				PlayExpectedAnimation(lastInfo, expectedAnim, grid.Model)
			end

			SetEmbeddedBallVisible(lastInfo, grid.Model, ShouldShowEmbeddedTrainingBall(ownerVisualState, trainingState))

			local animationTime = grid.TimeElapsed or 0
			local animationInfo = GetAnimationOffset(animationTime)
			local animationPositionLerp = lastInfo.AnimationPosition or CFrame.new()
			local animationRotationLerp = lastInfo.AnimationRotation or CFrame.new()

			if not trainingState then
				if animationInfo.AnimationLeft == true or info.Arrived == false then
					grid.TimeElapsed = (grid.TimeElapsed or 0) + delta
				else
					grid.TimeElapsed = 0
				end

				if
					info.Arrived == false
					or animationInfo.AnimationLeft == true
					or (animationInfo.Height == 0 and (lastInfo.AnimationHeight or 0) ~= 0)
				then
					local animationHeightDistance = (Vector3.new(0, animationInfo.Height, 0) - Vector3.new(
						0,
						lastInfo.AnimationHeight or 0,
						0
					)).Magnitude
					local animationSpeed = math.clamp((100 / math.max(animationHeightDistance, 0.001)) * delta, 0, 1)
					animationPositionLerp = (lastInfo.AnimationPosition or CFrame.new()):Lerp(
						CFrame.new(0, animationInfo.Height, 0),
						animationSpeed
					)
					animationRotationLerp = (lastInfo.AnimationRotation or CFrame.new()):Lerp(
						animationInfo.Rotation,
						animationSpeed
					)
				end
			else
				grid.TimeElapsed = 0
				animationPositionLerp = CFrame.new()
				animationRotationLerp = CFrame.new()
				animationInfo.Height = 0
			end

			if lastInfo.Position == nil then
				local pivot = grid.Model:GetPivot()
				local _, ry, _ = pivot:ToOrientation()
				lastInfo.Position = CFrame.new(pivot.Position.X, 0, pivot.Position.Z)
				lastInfo.Orientation = CFrame.fromOrientation(0, ry, 0)
			end

			local targetPosition
			local targetHeight
			local effectiveTrainingTarget = nil

			if trainingState and trainingState.TargetPart then
				local currentStickyPosition
				if lastInfo.Position then
					currentStickyPosition = lastInfo.Position.Position
				else
					currentStickyPosition = grid.Model:GetPivot().Position
				end

				effectiveTrainingTarget = GetStableTrainingTargetPart(lastInfo, trainingState, currentStickyPosition)
			end

			if effectiveTrainingTarget then
				targetPosition = effectiveTrainingTarget.Position
				targetHeight = effectiveTrainingTarget.Position.Y
			else
				local followOffset = GetFollowPositionOffset(grid)
				targetPosition = (info.Target.CFrame * followOffset).Position
				targetHeight = info.Target.Position.Y - 3.2
			end

			local flatTarget = CFrame.new(targetPosition.X, 0, targetPosition.Z)

			local positionLerp
			local verticalLerp
			local distanceCheck

			local directMatchControl = trainingState and trainingState.DirectMatchControl == true

			local isAutoInitialSnap = false
			if ownerVisualState and ownerVisualState.IsAuto == true then
				if lastInfo.LastVisualStateStartTime ~= ownerVisualState.ServerStartTime then
					lastInfo.LastVisualStateStartTime = ownerVisualState.ServerStartTime
					lastInfo.HasAutoSnapped = false
				end
				if not lastInfo.HasAutoSnapped then
					isAutoInitialSnap = true
				end
			end

			if shouldSnap or directMatchControl or isAutoInitialSnap then
				positionLerp = flatTarget
				verticalLerp = CFrame.new(0, targetHeight, 0)
				distanceCheck = 0
				info.Arrived = true
				if isAutoInitialSnap then
					lastInfo.HasAutoSnapped = true
				end
			else
				local positionDistance = (flatTarget.Position - lastInfo.Position.Position).Magnitude
				local moveSpeed = GetCompanionMoveSpeed(player, soccerCharacterInfo.Speed or 16, trainingState)
				local positionSpeed = math.clamp((moveSpeed / math.max(positionDistance, 0.001)) * delta, 0, 1)
				positionLerp = lastInfo.Position:Lerp(flatTarget, positionSpeed)

				distanceCheck = (Vector3.new(positionLerp.Position.X, 0, positionLerp.Position.Z) - flatTarget.Position).Magnitude

				info.Arrived = distanceCheck <= 0.5

				if lastInfo.Raycast == nil then
					lastInfo.Raycast = CFrame.new(0, positionLerp.Position.Y, 0)
				end

				local verticalDistance = math.abs(targetHeight - lastInfo.Raycast.Position.Y)
				local verticalSpeed =
					math.clamp((Settings.RaycastSpeed / math.max(verticalDistance, 0.001)) * delta, 0, 1)
				verticalLerp = lastInfo.Raycast:Lerp(CFrame.new(0, targetHeight, 0), verticalSpeed)
			end

			local orientation = ComputeOrientation(positionLerp, info.Target, trainingState, effectiveTrainingTarget)
			local orientationDistance = functions.GetAngleDistance(orientation, lastInfo.Orientation or CFrame.new())
			local orientationSpeed = math.clamp((250 / math.max(orientationDistance, 0.001)) * delta, 0, 1)
			local orientationLerp = (lastInfo.Orientation or CFrame.new()):Lerp(orientation, orientationSpeed)

			local _, yOrientationLerp, _ = orientationLerp:ToOrientation()
			local xAnimationLerp, _, _ = animationRotationLerp:ToOrientation()
			local finalOrientation = CFrame.fromOrientation(xAnimationLerp, yOrientationLerp, 0)

			local currentInstance = soccerCharacterInstances:FindFirstChild(modelName)
			local offset = 0
			local xRotation = 0

			if currentInstance then
				offset = -(currentInstance:GetAttribute("Rotation") or 0)
				xRotation = currentInstance:GetAttribute("XRotation") or 0
			end

			local final = (positionLerp * verticalLerp * animationPositionLerp * finalOrientation)
				* CFrame.Angles(math.rad(xRotation), math.rad(offset or 90), 0)

			table.insert(soccerCharactersToMove.CFrames, final)

			lastInfo.Position = positionLerp
			lastInfo.Raycast = verticalLerp
			lastInfo.Distance = distanceCheck
			lastInfo.AnimationPosition = animationPositionLerp
			lastInfo.AnimationRotation = animationRotationLerp
			lastInfo.AnimationHeight = animationInfo.Height
			lastInfo.Orientation = orientationLerp
		end
	end

	for index, model in ipairs(soccerCharactersToMove.SoccerCharacters) do
		model:PivotTo(soccerCharactersToMove.CFrames[index])
	end
end

return UpdateSoccerCharacters
