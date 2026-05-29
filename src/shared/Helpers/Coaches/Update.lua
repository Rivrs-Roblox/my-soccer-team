local Players = game:GetService("Players")

local Settings = require(script.Parent.Settings)
local TrainingRuntimeRegistry = require(script.Parent.Parent.Training.TrainingRuntimeRegistry)
local ZoneUtils = require(script.Parent.Parent.Training.ZoneUtils)

local DEFAULT_IDLE = "rbxassetid://507766388"
local DEFAULT_RUN = "rbxassetid://507767714"
local DEFAULT_JUMP = "rbxassetid://507765000"
local DEFAULT_FALL = "rbxassetid://507767968"
local TRAINING_1 = "rbxassetid://96222316307137"
local TRAINING_2 = "rbxassetid://79421168737236"
local TRAINING_3 = "rbxassetid://122384469518064"

local function GetPositionOffset(Grid, Info)
	local TotalOffset
	local XOffset
	local ZOffset
	if Info.Farming == true then
		XOffset = 0
	else
		XOffset = ((Grid.Column - (Grid.TotalColumns + 1) / 2) * Settings.XSpacing)
		ZOffset = (
			Settings.PlayerSpacing
			+ -(-(Grid.Row - (Grid.TotalRows + 1) / 2) * Settings.ZSpacing - (Grid.TotalRows / 2) * Settings.ZSpacing)
		)
	end
	TotalOffset = CFrame.new(XOffset, 0, ZOffset)
	return TotalOffset
end

local function UpdateCoaches(
	Delta,
	Functions,
	CoachesInSession,
	CoachesModule,
	CoachInstances,
	RaycastExcludeModels,
	CoachesController,
	visualStates
)
	for i, v in pairs(CoachesInSession) do
		local player = if typeof(i) == "number" then Players:GetPlayerByUserId(i) else i
		if not player or not player:IsA("Player") then
			continue
		end

		local visualState = visualStates and visualStates[player]

		if Functions.GetTableAmount(v) > 0 then
			for i2, v2 in pairs(v) do
				--// References
				local Grid = v2
				local Data = v2.CoachData or v2.PetData
				local Info = Grid.Information
				local LastInfo = Grid.LastInformation

				if Data == "None" then
					continue
				end

				local PlayerChar = player.Character
				local Humanoid = PlayerChar and PlayerChar:FindFirstChildOfClass("Humanoid")
				if not Humanoid then
					continue
				end

				--// Create coach models
				local currentModel = Grid.Model
				local coachAttribute = (typeof(currentModel) == "Instance") and currentModel:GetAttribute("Coach")
				local shouldCreateModel = (
					not currentModel
					or currentModel == ""
					or type(currentModel) == "string"
					or not (typeof(currentModel) == "Instance" and currentModel.Parent)
					or coachAttribute ~= Data.Name
					or not CoachInstances:FindFirstChild(player.Name .. "_" .. tostring(i2))
				)

				if shouldCreateModel then
					-- Destroy old model if it exists
					local existingModel = CoachInstances:FindFirstChild(player.Name .. "_" .. tostring(i2))
					if existingModel then
						existingModel:Destroy()
					end

					local CoachModel = Functions.GetCoachModel(Data)
					if CoachModel == nil then
						continue
					end
					CoachModel = CoachModel:Clone() :: Model
					Grid.Model = CoachModel

					CoachModel:SetAttribute("Owner", player.Name)
					CoachModel:SetAttribute("Coach", Data.Name)

					local InitialHorizontalTarget
					if visualState and TrainingRuntimeRegistry.IsRuntimeVisualState(visualState) then
						local runtime = TrainingRuntimeRegistry.GetRuntimeByStatType(visualState.StatType)
						if runtime then
							local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
							if zone then
								if type(runtime.GetLayout) ~= "function" then
									warn(
										"[CoachesSpawning] runtime.GetLayout is nil or not a function for statType:",
										visualState.StatType
									)
								end
								local layout = runtime.GetLayout(zone, 4)
								if layout and layout.Coach then
									InitialHorizontalTarget = layout.Coach.Position
								end
							end
						end
					end

					local TempPositionOffset
					if InitialHorizontalTarget then
						TempPositionOffset = CFrame.new(InitialHorizontalTarget)
					else
						local offset = GetPositionOffset(Grid, Info)
						TempPositionOffset = CFrame.new((Info.Target.CFrame * offset).Position)
					end
					TempPositionOffset = TempPositionOffset - Vector3.new(0, TempPositionOffset.Position.Y, 0)

					CoachModel.Name = player.Name .. "_" .. tostring(i2)
					CoachModel:PivotTo(TempPositionOffset)

					CoachModel.Parent = CoachInstances

					-- Reset animations for the new model
					LastInfo.Animations = nil
					LastInfo.CurrentAnimation = nil

					table.insert(RaycastExcludeModels, CoachModel)
				end

				if Grid.Model == "" then
					continue
				end

				local CharHumanoid = Grid.Model:FindFirstChildOfClass("Humanoid")

				--// Positions
				local HorizontalTarget
				if visualState and TrainingRuntimeRegistry.IsRuntimeVisualState(visualState) then
					local runtime = TrainingRuntimeRegistry.GetRuntimeByStatType(visualState.StatType)
					if runtime then
						local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
						if zone then
							if type(runtime.GetLayout) ~= "function" then
								warn(
									"[CoachesUpdate] runtime.GetLayout is nil or not a function for statType:",
									visualState.StatType,
									"runtime:",
									runtime
								)
								for k, v in pairs(runtime) do
									print("  runtime key:", k, "type:", type(v))
								end
							end
							local layout = runtime.GetLayout(zone, 4)
							if layout and layout.Coach then
								HorizontalTarget = layout.Coach.Position
							end
						end
					end
				end

				if not HorizontalTarget then
					local PositionOffset = GetPositionOffset(Grid, Info)
					HorizontalTarget = (Info.Target.CFrame * PositionOffset).Position
				end

				-- Raycast down to find the actual ground at this position
				local RayOrigin = HorizontalTarget + Vector3.new(0, 5, 0) -- Start a bit above player to handle elevation
				local RayDirection = Vector3.new(0, -20, 0)
				local RayParams = RaycastParams.new()
				RayParams.FilterDescendantsInstances = RaycastExcludeModels
				RayParams.FilterType = Enum.RaycastFilterType.Exclude

				local RayResult = workspace:Raycast(RayOrigin, RayDirection, RayParams)
				local AdjustedTargetPosition
				if RayResult then
					AdjustedTargetPosition = RayResult.Position
				else
					-- Fallback if no ground found (e.g. above void)
					AdjustedTargetPosition = HorizontalTarget - Vector3.new(0, 3.2, 0)
				end

				-- Horizontal distance for animation/arrival check
				local distanceToTarget = (
					Vector3.new(AdjustedTargetPosition.X, 0, AdjustedTargetPosition.Z)
					- Vector3.new(Grid.Model:GetPivot().Position.X, 0, Grid.Model:GetPivot().Position.Z)
				).Magnitude

				--// Handle Animations
				local Animator = if LastInfo.Animations then LastInfo.Animations.Animator else nil
				if not Animator then
					Animator = Grid.Model:FindFirstChildWhichIsA("Animator", true)
					if not Animator then
						local Parent = CharHumanoid or Grid.Model:FindFirstChildOfClass("AnimationController")
						if Parent then
							Animator = Parent:FindFirstChildOfClass("Animator") or Instance.new("Animator", Parent)
						end
					end
				end

				if Animator then
					if not LastInfo.Animations or (LastInfo.Animations.Animator ~= Animator) then
						LastInfo.Animations = {
							Animator = Animator,
						}
						local IdleAnim = Instance.new("Animation")
						IdleAnim.AnimationId = DEFAULT_IDLE
						LastInfo.Animations.Idle = Animator:LoadAnimation(IdleAnim)

						local RunAnim = Instance.new("Animation")
						RunAnim.AnimationId = DEFAULT_RUN
						LastInfo.Animations.Run = Animator:LoadAnimation(RunAnim)

						local JumpAnim = Instance.new("Animation")
						JumpAnim.AnimationId = DEFAULT_JUMP
						LastInfo.Animations.Jump = Animator:LoadAnimation(JumpAnim)

						local FallAnim = Instance.new("Animation")
						FallAnim.AnimationId = DEFAULT_FALL
						LastInfo.Animations.Fall = Animator:LoadAnimation(FallAnim)

						local Training1Anim = Instance.new("Animation")
						Training1Anim.AnimationId = TRAINING_1
						LastInfo.Animations.Training1 = Animator:LoadAnimation(Training1Anim)

						local Training2Anim = Instance.new("Animation")
						Training2Anim.AnimationId = TRAINING_2
						LastInfo.Animations.Training2 = Animator:LoadAnimation(Training2Anim)

						local Training3Anim = Instance.new("Animation")
						Training3Anim.AnimationId = TRAINING_3
						LastInfo.Animations.Training3 = Animator:LoadAnimation(Training3Anim)
					end

					local ExpectedAnim = "Idle"
					if Humanoid then
						local State = Humanoid:GetState()

						local isTraining = visualState
							and TrainingRuntimeRegistry.IsRuntimeVisualState(visualState)
							and Info.Arrived

						-- Priority: Training > Jumping/Falling > Running > Idle
						if isTraining then
							if not LastInfo.SelectedTrainingAnim then
								LastInfo.SelectedTrainingAnim = "Training" .. tostring(math.random(1, 3))
							end
							ExpectedAnim = LastInfo.SelectedTrainingAnim
						elseif State == Enum.HumanoidStateType.Jumping then
							ExpectedAnim = "Jump"
							if CharHumanoid then
								CharHumanoid.Jump = true
							end
							LastInfo.SelectedTrainingAnim = nil
						elseif State == Enum.HumanoidStateType.Freefall then
							ExpectedAnim = "Fall"
							LastInfo.SelectedTrainingAnim = nil
						else
							-- Check if character should be running based on player movement or distance to target
							local isPlayerMoving = Humanoid.MoveDirection.Magnitude > 0.1

							if isPlayerMoving or distanceToTarget > 1.5 then
								ExpectedAnim = "Run"
							else
								ExpectedAnim = "Idle"
								LastInfo.SelectedTrainingAnim = nil
							end
						end
					end

					local CurrentAnim = LastInfo.CurrentAnimation

					local isTrainingAnim = (
						ExpectedAnim == "Training1"
						or ExpectedAnim == "Training2"
						or ExpectedAnim == "Training3"
					)
					if CurrentAnim == ExpectedAnim and isTrainingAnim then
						local track = LastInfo.Animations and LastInfo.Animations[ExpectedAnim]
						if track and not track.IsPlaying then
							ExpectedAnim = "Training" .. tostring(math.random(1, 3))
							LastInfo.SelectedTrainingAnim = ExpectedAnim
							if ExpectedAnim == CurrentAnim then
								track:Play()
							end
						end
					end

					if CurrentAnim ~= ExpectedAnim then
						local animations = LastInfo.Animations
						if animations then
							if CurrentAnim and animations[CurrentAnim] then
								animations[CurrentAnim]:Stop()
							end
							if animations[ExpectedAnim] then
								animations[ExpectedAnim]:Play()
							end
						end
						LastInfo.CurrentAnimation = ExpectedAnim
					end
				end

				--// Positions
				if CharHumanoid then
					local HumanoidRootPart = Grid.Model:FindFirstChild("HumanoidRootPart")

					-- Sync properties
					CharHumanoid.WalkSpeed = Humanoid.WalkSpeed
					CharHumanoid.JumpHeight = Humanoid.JumpHeight
					CharHumanoid.JumpPower = Humanoid.JumpPower
					CharHumanoid.UseJumpPower = Humanoid.UseJumpPower

					local isAutoInitialSnap = visualState
						and visualState.IsAuto == true
						and (workspace:GetServerTimeNow() - (visualState.ServerStartTime or 0)) < 0.2

					if distanceToTarget > 1.5 then
						if isAutoInitialSnap or distanceToTarget > 50 then
							-- Instant teleport for auto training start or too far away
							Grid.Model:PivotTo(
								CFrame.new(AdjustedTargetPosition)
									* (HumanoidRootPart and HumanoidRootPart.CFrame.Rotation or CFrame.new().Rotation)
							)
							Info.Arrived = true
						else
							-- Moving naturally...
							CharHumanoid:MoveTo(AdjustedTargetPosition)
							Info.Arrived = false
						end
					else
						-- Arrived or very close
						if not Info.Arrived then
							CharHumanoid:Move(Vector3.new(0, 0, 0)) -- Explicitly stop
							Info.Arrived = true
						end

						-- Match rotation smoothly when arrived
						if HumanoidRootPart then
							local currentCFrame = HumanoidRootPart.CFrame
							local targetBaseCFrame

							-- Determine which orientation to follow
							local trainingLayout = nil
							if visualState and TrainingRuntimeRegistry.IsRuntimeVisualState(visualState) then
								local runtime = TrainingRuntimeRegistry.GetRuntimeByStatType(visualState.StatType)
								if runtime then
									local zone = ZoneUtils.FindZoneByKey(visualState.ZoneKey)
									if zone then
										trainingLayout = runtime.GetLayout(zone, 4)
									end
								end
							end

							if trainingLayout and trainingLayout.Coach then
								targetBaseCFrame = trainingLayout.Coach.CFrame
							else
								targetBaseCFrame = Info.Target.CFrame
							end

							-- Flatten rotation to prevent tilting down/up
							local lookVector = targetBaseCFrame.LookVector
							local flatLookVector = Vector3.new(lookVector.X, 0, lookVector.Z)
							if flatLookVector.Magnitude < 0.001 then
								flatLookVector = Vector3.new(0, 0, -1)
							end
							local flatRotation = CFrame.lookAt(Vector3.new(), flatLookVector)

							-- Character base rotation adjustment (from attributes)
							local offsetDegrees = -(Grid.Model:GetAttribute("Rotation") or 0)
							local xDegrees = Grid.Model:GetAttribute("XRotation") or 0

							local targetRotation = flatRotation
								* CFrame.Angles(math.rad(xDegrees), math.rad(offsetDegrees or 90), 0)

							-- Only interpolate if there is a noticeable rotation difference to prevent constant micro-jitters
							local targetCFrame = CFrame.new(currentCFrame.Position) * targetRotation
							if currentCFrame.LookVector:Dot(targetCFrame.LookVector) < 0.9999 then
								HumanoidRootPart.CFrame = currentCFrame:Lerp(targetCFrame, 0.2)
							end
						end
					end

					LastInfo.Distance = distanceToTarget
				end

				--// Update all the last variables
				LastInfo.Position = CFrame.new(AdjustedTargetPosition)
			end
		end
	end
end

return UpdateCoaches
