local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local Settings = require(script.Parent.Settings)

local DEFAULT_IDLE = "rbxassetid://507766388"
local DEFAULT_RUN = "rbxassetid://507767714"
local DEFAULT_JUMP = "rbxassetid://507765000"
local DEFAULT_FALL = "rbxassetid://507767968"

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

local function UpdateSoccerCharacters(
	Delta,
	Functions,
	SoccerCharactersInSession,
	SoccerCharactersModule,
	SoccerCharacterInstances,
	RaycastExcludeModels,
	AccessoriesByPlayer
)
	local SoccerCharactersToMove = { ["SoccerCharacters"] = {}, ["CFrames"] = {} }

	for i, v in pairs(SoccerCharactersInSession) do
		local player = if typeof(i) == "number" then Players:GetPlayerByUserId(i) else i
		if not player or not player:IsA("Player") then
			continue
		end

		local accessoriesInventory = AccessoriesByPlayer[player] or {}

		if Functions.GetTableAmount(v) > 0 then
			for i2, v2 in pairs(v) do
				--// References
				local Grid = v2
				local Data = v2.Data
				local Info = Grid.Information
				local LastInfo = Grid.LastInformation

				local PlayerChar = player.Character
				local Humanoid = PlayerChar and PlayerChar:FindFirstChildOfClass("Humanoid")
				if not Humanoid then
					continue
				end

				--// Create soccer character models
				if
					not SoccerCharacterInstances:FindFirstChild(player.Name .. "_" .. tostring(i2))
					or type(Grid.Model) == "string"
				then
					local SoccerCharacterModel = Functions.GetModel(Data)
					if SoccerCharacterModel == nil then
						continue
					end
					Grid.Model = SoccerCharacterModel

					SoccerCharacterModel:SetAttribute("Owner", i.Name)
					SoccerCharacterModel:SetAttribute("SoccerCharacter", Grid.Model.Name)
					SoccerCharacterModel:SetAttribute("Level", Data.Level or 1)

					local TempPositionOffset = GetPositionOffset(Grid, Info)
					TempPositionOffset = CFrame.new((Info.Target.CFrame * TempPositionOffset).Position)
					TempPositionOffset = TempPositionOffset - Vector3.new(0, TempPositionOffset.Position.Y, 0)

					SoccerCharacterModel.Name = i.Name .. "_" .. tostring(i2)
					SoccerCharacterModel:PivotTo(TempPositionOffset)

					SoccerCharacterModel.Parent = SoccerCharacterInstances
					Functions.EquipAccessory(SoccerCharacterModel, Data, accessoriesInventory)

					table.insert(RaycastExcludeModels, SoccerCharacterModel)
				end

				table.insert(SoccerCharactersToMove.SoccerCharacters, Grid.Model)

				if Grid.Model == "" then
					continue
				end

				if Grid.Model:GetAttribute("IsCinematicReacting") == true then
					continue
				end

				local CharHumanoid = Grid.Model:FindFirstChildOfClass("Humanoid")

				--// Positions
				local PositionOffset = GetPositionOffset(Grid, Info)
				local HorizontalTarget = (Info.Target.CFrame * PositionOffset).Position

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
					end

					local ExpectedAnim = "Idle"
					if Humanoid then
						local State = Humanoid:GetState()

						-- Synchronize jumping/falling from player
						if State == Enum.HumanoidStateType.Jumping then
							ExpectedAnim = "Jump"
							if CharHumanoid then
								CharHumanoid.Jump = true
							end
						elseif State == Enum.HumanoidStateType.Freefall then
							ExpectedAnim = "Fall"
						else
							-- Check if character should be running based on player movement or distance to target
							local isPlayerMoving = Humanoid.MoveDirection.Magnitude > 0.1

							if isPlayerMoving or distanceToTarget > 1.5 then
								ExpectedAnim = "Run"
							end
						end
					end

					local CurrentAnim = LastInfo.CurrentAnimation

					if CurrentAnim ~= ExpectedAnim then
						if LastInfo.Animations[CurrentAnim] then
							LastInfo.Animations[CurrentAnim]:Stop()
						end
						LastInfo.Animations[ExpectedAnim]:Play()
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

					if distanceToTarget > 1.5 then
						-- Moving...
						CharHumanoid:MoveTo(AdjustedTargetPosition)
						Info.Arrived = false
					else
						-- Arrived or very close
						if not Info.Arrived then
							CharHumanoid:Move(Vector3.new(0, 0, 0)) -- Explicitly stop
							Info.Arrived = true
						end

						-- Match player rotation smoothly when arrived
						if HumanoidRootPart then
							local currentCFrame = HumanoidRootPart.CFrame
							local playerRotation = Info.Target.CFrame - Info.Target.CFrame.Position

							-- Character base rotation adjustment
							local Offset = -(Grid.Model:GetAttribute("Rotation") or 0)
							local targetRotation = playerRotation
								* CFrame.Angles(
									math.rad(Grid.Model:GetAttribute("XRotation") or 0),
									math.rad(Offset or 90),
									0
								)

							-- Only interpolate if there is a noticeable rotation difference to prevent constant micro-jitters
							local targetCFrame = CFrame.new(currentCFrame.Position) * targetRotation
							if currentCFrame.LookVector:Dot(targetCFrame.LookVector) < 0.999 then
								HumanoidRootPart.CFrame = currentCFrame:Lerp(targetCFrame, 0.4)
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

return UpdateSoccerCharacters
