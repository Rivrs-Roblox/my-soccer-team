--!strict

--[[
	MatchActorLookAtDirector

	Client-only procedural upper-body/head look-at for match actors.

	Current approach:
	- Uses Motor6D.C0 offset instead of Motor6D.Transform.
	- This is more stable against Roblox Animator overwriting Transform.
	- Lower body / HumanoidRootPart is never rotated.
	- Keeper is excluded by default.
	- Look-at is released automatically on Shoot step.

	Responsibilities:
	- Register visible match actors.
	- Calculate target direction per actor from each actor's own root facing.
	- Apply upper-body/head yaw/pitch through original C0 offset.
	- Reset all changed joints on cleanup.

	Non-responsibilities:
	- No QTE result logic.
	- No movement/path logic.
	- No keeper save/dive logic.
	- No server authority.
]]

local RunService = game:GetService("RunService")

local ClientRoot = script.Parent.Parent.Parent.Parent
local MatchActorLookConfig = require(ClientRoot.Config.Match.MatchActorLookConfig)

return function(controller, context)
	type ActorRole = "Carrier" | "Companion" | "Enemy" | "Keeper" | "Unknown"

	type ActorRecord = {
		Model: Model,
		Role: ActorRole,
		SlotId: any?,

		RootPart: BasePart?,
		WaistMotor: Motor6D?,
		NeckMotor: Motor6D?,

		BaseWaistC0: CFrame?,
		BaseNeckC0: CFrame?,

		UpperYaw: number,
		HeadYaw: number,
		UpperPitch: number,
		HeadPitch: number,

		LastYawSign: number,
	}

	local function debugPrint(...)
	end

	local function clamp(value: number, minValue: number, maxValue: number): number
		return math.max(minValue, math.min(maxValue, value))
	end

	local function expAlpha(speed: number, dt: number): number
		return 1 - math.exp(-math.max(0, speed) * math.max(0, dt))
	end

	local function isBasePart(instance: Instance?): boolean
		return instance ~= nil and instance:IsA("BasePart")
	end

	local function isKeeperModel(model: Model): boolean
		local modelName = string.lower(model.Name)
		return string.find(modelName, "keeper") ~= nil
			or string.find(modelName, "goalkeeper") ~= nil
		end

	local function findRootPart(model: Model): BasePart?
		local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
		if isBasePart(humanoidRootPart) then
			return humanoidRootPart :: BasePart
		end

		if model.PrimaryPart and isBasePart(model.PrimaryPart) then
			return model.PrimaryPart
		end

		local rootPart = model:FindFirstChild("RootPart")
		if isBasePart(rootPart) then
			return rootPart :: BasePart
		end

		return nil
	end

	local function findDirectMotor(parent: Instance?, motorName: string): Motor6D?
		if not parent then
			return nil
		end

		local motor = parent:FindFirstChild(motorName)
		if motor and motor:IsA("Motor6D") then
			return motor
		end

		return nil
	end

	local function nameInList(name: string, list: { string }): boolean
		for _, allowedName in ipairs(list) do
			if name == allowedName then
				return true
			end
		end

		return false
	end

	local function findMotorByNames(model: Model, allowedNames: { string }): Motor6D?
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("Motor6D") and nameInList(descendant.Name, allowedNames) then
				return descendant
			end
		end

		return nil
	end

	local function findWaistMotor(model: Model): Motor6D?
		local lowerTorso = model:FindFirstChild(MatchActorLookConfig.R15.LowerTorsoName)
		local upperTorso = model:FindFirstChild(MatchActorLookConfig.R15.UpperTorsoName)

		local directFromLower = findDirectMotor(lowerTorso, MatchActorLookConfig.R15.WaistMotorName)
		if directFromLower then
			return directFromLower
		end

		local directFromUpper = findDirectMotor(upperTorso, MatchActorLookConfig.R15.WaistMotorName)
		if directFromUpper then
			return directFromUpper
		end

		if MatchActorLookConfig.Fallback.SearchDescendants then
			return findMotorByNames(model, MatchActorLookConfig.Fallback.AllowedWaistMotorNames)
		end

		return nil
	end

	local function findNeckMotor(model: Model): Motor6D?
		local upperTorso = model:FindFirstChild(MatchActorLookConfig.R15.UpperTorsoName)
		local head = model:FindFirstChild(MatchActorLookConfig.R15.HeadName)

		local directFromUpper = findDirectMotor(upperTorso, MatchActorLookConfig.R15.NeckMotorName)
		if directFromUpper then
			return directFromUpper
		end

		local directFromHead = findDirectMotor(head, MatchActorLookConfig.R15.NeckMotorName)
		if directFromHead then
			return directFromHead
		end

		if MatchActorLookConfig.Fallback.SearchDescendants then
			return findMotorByNames(model, MatchActorLookConfig.Fallback.AllowedNeckMotorNames)
		end

		return nil
	end

	local function resolveActorModel(actorData: any): Model?
		if typeof(actorData) == "Instance" and actorData:IsA("Model") then
			return actorData
		end

		if typeof(actorData) ~= "table" then
			return nil
		end

		local model = actorData.Model or actorData.Character or actorData.Instance
		if typeof(model) == "Instance" and model:IsA("Model") then
			return model
		end

		return nil
	end

	local function resolveRole(actorData: any, model: Model): ActorRole
		if isKeeperModel(model) then
			return "Keeper"
		end

		if typeof(actorData) == "table" then
			if actorData.IsKeeper == true then
				return "Keeper"
			end

			if actorData.IsCarrier == true then
				return "Carrier"
			end

			if actorData.IsEnemy == true then
				return "Enemy"
			end

			local rawRole = actorData.Role or actorData.SlotRole
			if typeof(rawRole) == "string" then
				local normalized = string.lower(rawRole)

				if string.find(normalized, "keeper") then
					return "Keeper"
				end

				if string.find(normalized, "carrier") or string.find(normalized, "player") then
					return "Carrier"
				end

				if string.find(normalized, "enemy")
					or string.find(normalized, "opponent")
					or string.find(normalized, "defender")
				then
					return "Enemy"
				end

				if string.find(normalized, "companion")
					or string.find(normalized, "ally")
					or string.find(normalized, "support")
				then
					return "Companion"
				end
			end
		end

		local modelName = string.lower(model.Name)

		if string.find(modelName, "enemy")
			or string.find(modelName, "defender")
			or string.find(modelName, "opponent")
		then
			return "Enemy"
		end

		if string.find(modelName, "player") or string.find(modelName, "carrier") then
			return "Carrier"
		end

		return "Companion"
	end

	local function getRoleStrength(role: ActorRole): number
		if role == "Carrier" then
			return MatchActorLookConfig.Targeting.CarrierLookStrength
		end

		if role == "Enemy" then
			return MatchActorLookConfig.Targeting.EnemyLookStrength
		end

		if role == "Keeper" then
			return MatchActorLookConfig.Targeting.KeeperLookStrength
		end

		if role == "Companion" then
			return MatchActorLookConfig.Targeting.CompanionLookStrength
		end

		return 0.75
	end

	local function shouldExcludeRole(role: ActorRole): boolean
		return MatchActorLookConfig.ExcludeKeeper and role == "Keeper"
	end

	local function resolveTargetPosition(target: any): Vector3?
		if target == nil then
			return nil
		end

		if typeof(target) == "Vector3" then
			return target
		end

		if typeof(target) == "CFrame" then
			return (target :: CFrame).Position
		end

		if typeof(target) == "Instance" then
			local instance = target :: Instance

			if instance:IsA("BasePart") then
				return instance.Position
			end

			if instance:IsA("Attachment") then
				return instance.WorldPosition
			end

			if instance:IsA("Model") then
				local root = findRootPart(instance)
				if root then
					return root.Position
				end

				if instance.PrimaryPart then
					return instance.PrimaryPart.Position
				end
			end
		end

		return nil
	end

	local function createActorRecord(actorData: any): ActorRecord?
		local model = resolveActorModel(actorData)
		if not model then
			return nil
		end

		local role = resolveRole(actorData, model)
		if shouldExcludeRole(role) then
			debugPrint("skip excluded", model.Name, role)
			return nil
		end

		local rootPart = findRootPart(model)
		local waistMotor = findWaistMotor(model)
		local neckMotor = findNeckMotor(model)

		if not rootPart then
			debugPrint("skip actor without root", model.Name)
			return nil
		end

		if not waistMotor and not neckMotor then
			controller._matchActorLookSkipLogged = controller._matchActorLookSkipLogged or {}

			if not controller._matchActorLookSkipLogged[model] then
				controller._matchActorLookSkipLogged[model] = true
				debugPrint("skip actor without waist/neck motors", model.Name)
			end

			return nil
		end

		local record: ActorRecord = {
			Model = model,
			Role = role,
			SlotId = if typeof(actorData) == "table" then actorData.SlotId else nil,

			RootPart = rootPart,
			WaistMotor = waistMotor,
			NeckMotor = neckMotor,

			BaseWaistC0 = if waistMotor then waistMotor.C0 else nil,
			BaseNeckC0 = if neckMotor then neckMotor.C0 else nil,

			UpperYaw = 0,
			HeadYaw = 0,
			UpperPitch = 0,
			HeadPitch = 0,

			LastYawSign = 1,
		}

		return record
	end

	local function resetRecord(record: ActorRecord)
		record.UpperYaw = 0
		record.HeadYaw = 0
		record.UpperPitch = 0
		record.HeadPitch = 0

		if record.WaistMotor then
			record.WaistMotor.Transform = CFrame.identity

			if record.BaseWaistC0 then
				record.WaistMotor.C0 = record.BaseWaistC0
			end
		end

		if record.NeckMotor then
			record.NeckMotor.Transform = CFrame.identity

			if record.BaseNeckC0 then
				record.NeckMotor.C0 = record.BaseNeckC0
			end
		end
	end

	local function refreshRecord(record: ActorRecord): boolean
		if not record.Model.Parent then
			return false
		end

		if not record.RootPart or not record.RootPart.Parent then
			record.RootPart = findRootPart(record.Model)
		end

		if not record.WaistMotor or not record.WaistMotor.Parent then
			record.WaistMotor = findWaistMotor(record.Model)
			record.BaseWaistC0 = if record.WaistMotor then record.WaistMotor.C0 else nil
		end

		if not record.NeckMotor or not record.NeckMotor.Parent then
			record.NeckMotor = findNeckMotor(record.Model)
			record.BaseNeckC0 = if record.NeckMotor then record.NeckMotor.C0 else nil
		end

		return record.RootPart ~= nil and (record.WaistMotor ~= nil or record.NeckMotor ~= nil)
	end

	local function buildYawPitchOffset(yaw: number, pitch: number): CFrame
		local yawSign = tonumber(MatchActorLookConfig.YawSign) or 1

		-- C0 offset order:
		-- yaw first, then pitch. This feels more stable for R15 blocky rigs.
		return CFrame.Angles(0, yaw * yawSign, 0) * CFrame.Angles(pitch, 0, 0)
	end

	local function applyRecordC0(record: ActorRecord)
		if record.WaistMotor and record.BaseWaistC0 then
			record.WaistMotor.Transform = CFrame.identity
			record.WaistMotor.C0 = record.BaseWaistC0 * buildYawPitchOffset(record.UpperYaw, record.UpperPitch)
		end

		if record.NeckMotor and record.BaseNeckC0 then
			record.NeckMotor.Transform = CFrame.identity
			record.NeckMotor.C0 = record.BaseNeckC0 * buildYawPitchOffset(record.HeadYaw, record.HeadPitch)
		end
	end

	local function returnToNeutral(record: ActorRecord, dt: number)
		local alpha = expAlpha(MatchActorLookConfig.ReturnToNeutralSpeed, dt)

		record.UpperYaw += (0 - record.UpperYaw) * alpha
		record.HeadYaw += (0 - record.HeadYaw) * alpha
		record.UpperPitch += (0 - record.UpperPitch) * alpha
		record.HeadPitch += (0 - record.HeadPitch) * alpha

		applyRecordC0(record)
	end

	local function calculateRootRelativeAngles(
		record: ActorRecord,
		targetPosition: Vector3,
		strength: number,
		maxYaw: number,
		maxPitch: number
	): (number, number)
		local rootPart = record.RootPart
		if not rootPart then
			return 0, 0
		end

		local toTarget = targetPosition - rootPart.Position
		local flatToTarget = Vector3.new(toTarget.X, 0, toTarget.Z)

		if flatToTarget.Magnitude <= 0.001 then
			return 0, 0
		end

		local flatForward = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
		local flatRight = Vector3.new(rootPart.CFrame.RightVector.X, 0, rootPart.CFrame.RightVector.Z)

		if flatForward.Magnitude <= 0.001 or flatRight.Magnitude <= 0.001 then
			return 0, 0
		end

		local forward = flatForward.Unit
		local right = flatRight.Unit
		local direction = flatToTarget.Unit

		local rightDot = right:Dot(direction)
		local forwardDot = forward:Dot(direction)

		local rawYaw = math.atan2(rightDot, forwardDot)

		-- When target is almost exactly behind, atan2 can flip left/right.
		-- Keep previous side to avoid random snapping.
		if math.abs(rightDot) < 0.04 and forwardDot < -0.85 then
			rawYaw = math.abs(rawYaw) * record.LastYawSign
		else
			if rightDot > 0.04 then
				record.LastYawSign = 1
			elseif rightDot < -0.04 then
				record.LastYawSign = -1
			end
		end

		local horizontalDistance = math.max(0.001, flatToTarget.Magnitude)
		local rawPitch = math.atan2(toTarget.Y, horizontalDistance)

		local yaw = clamp(rawYaw * strength, -maxYaw, maxYaw)
		local pitch = clamp(rawPitch * strength, -maxPitch, maxPitch)

		return yaw, pitch
	end

	local function updateActor(record: ActorRecord, targetPosition: Vector3?, dt: number)
		local rootPart = record.RootPart
		if not rootPart then
			return
		end

		local currentAction = tostring(controller.CurrentPresentationAction or "")
		local currentStepIndex = tonumber(controller.CurrentPresentationStepIndex) or 0

		if currentAction == "Shoot" or currentStepIndex >= 5 then
			returnToNeutral(record, dt)
			return
		end

		local strength = getRoleStrength(record.Role)

		if not targetPosition or strength <= 0 then
			returnToNeutral(record, dt)
			return
		end

		local offset = targetPosition - rootPart.Position
		local distance = offset.Magnitude

		if distance < MatchActorLookConfig.MinTargetDistance then
			returnToNeutral(record, dt)
			return
		end

		local maxUpperYaw = math.rad(MatchActorLookConfig.MaxUpperBodyYawDegrees)
		local maxHeadYaw = math.rad(MatchActorLookConfig.MaxHeadYawDegrees)
		local maxUpperPitch = math.rad(MatchActorLookConfig.MaxUpperBodyPitchDegrees)
		local maxHeadPitch = math.rad(MatchActorLookConfig.MaxHeadPitchDegrees)

		local maxTotalYaw = maxUpperYaw + maxHeadYaw
		local maxTotalPitch = maxUpperPitch + maxHeadPitch

		local totalYaw, totalPitch = calculateRootRelativeAngles(
			record,
			targetPosition,
			strength,
			maxTotalYaw,
			maxTotalPitch
		)

		local targetUpperYaw = clamp(
			totalYaw * MatchActorLookConfig.UpperBodyYawWeight,
			-maxUpperYaw,
			maxUpperYaw
		)

		local targetHeadYaw = clamp(
			totalYaw - targetUpperYaw,
			-maxHeadYaw,
			maxHeadYaw
		)

		local targetUpperPitch = clamp(
			totalPitch * MatchActorLookConfig.UpperBodyPitchWeight,
			-maxUpperPitch,
			maxUpperPitch
		)

		local targetHeadPitch = clamp(
			totalPitch - targetUpperPitch,
			-maxHeadPitch,
			maxHeadPitch
		)

		local alpha = expAlpha(MatchActorLookConfig.SmoothSpeed, dt)

		record.UpperYaw += (targetUpperYaw - record.UpperYaw) * alpha
		record.HeadYaw += (targetHeadYaw - record.HeadYaw) * alpha
		record.UpperPitch += (targetUpperPitch - record.UpperPitch) * alpha
		record.HeadPitch += (targetHeadPitch - record.HeadPitch) * alpha

		applyRecordC0(record)
	end

	local function resetAll()
		if controller._matchActorLookRecords then
			for _, record in ipairs(controller._matchActorLookRecords) do
				resetRecord(record)
			end
		end
	end

	local function stopLookAt()
		if controller._matchActorLookConnection then
			controller._matchActorLookConnection:Disconnect()
			controller._matchActorLookConnection = nil
		end

		resetAll()

		if controller._matchActorLookRecords then
			table.clear(controller._matchActorLookRecords)
		end

		controller._matchActorLookFirstTargetLogged = nil

		debugPrint("stopped")
	end

	local function connectLookAtLoop(callback)
		local runServiceAny = RunService :: any

		if runServiceAny.PreSimulation then
			return runServiceAny.PreSimulation:Connect(callback)
		end

		return RunService.RenderStepped:Connect(callback)
	end

	local function hasActorRecord(model: Model): boolean
		if not controller._matchActorLookRecords then
			return false
		end

		for _, record in ipairs(controller._matchActorLookRecords) do
			if record.Model == model then
				return true
			end
		end

		return false
	end

	local function registerActorModel(model: Model?, role: ActorRole, slotId: any?)
		if not model or not model.Parent then
			return
		end

		if hasActorRecord(model) then
			return
		end

		local forcedRole = role
		if isKeeperModel(model) then
			forcedRole = "Keeper"
		end

		local record = createActorRecord({
			Model = model,
			Role = forcedRole,
			SlotId = slotId,
			IsCarrier = forcedRole == "Carrier",
			IsEnemy = forcedRole == "Enemy",
			IsKeeper = forcedRole == "Keeper",
		})

		if not record then
			return
		end

		table.insert(controller._matchActorLookRecords, record)

		debugPrint(
			"registered actor",
			model.Name,
			"role=" .. tostring(record.Role),
			"slot=" .. tostring(slotId),
			"waist=" .. tostring(record.WaistMotor ~= nil),
			"neck=" .. tostring(record.NeckMotor ~= nil)
		)
	end

	local function registerCompanionsFromVisualController()
		local companionController = controller.MatchCompanionVisualController
		if not companionController or not companionController.GetOwnedCompanionModels then
			return
		end

		local localPlayer = context.LocalPlayer
		if not localPlayer then
			return
		end

		local ok, companions = pcall(function()
			return companionController:GetOwnedCompanionModels(localPlayer)
		end)

		if not ok or type(companions) ~= "table" then
			return
		end

		for index, companionModel in ipairs(companions) do
			if typeof(companionModel) == "Instance" and companionModel:IsA("Model") then
				local slotNumber = index + 1
				local role: ActorRole = "Companion"

				if tonumber(controller.ActiveActorSlot) == slotNumber then
					role = "Carrier"
				end

				registerActorModel(companionModel, role, slotNumber)
			end
		end
	end

	local function registerControlledActors()
		controller._matchActorLookRecords = controller._matchActorLookRecords or {}

		if controller._getControlledActorModel then
			for slotNumber = 1, 4 do
				local ok, actorModel = pcall(function()
					return controller:_getControlledActorModel(slotNumber)
				end)

				if ok and actorModel and actorModel.Parent then
					local role: ActorRole = "Companion"

					if tonumber(controller.ActiveActorSlot) == slotNumber then
						role = "Carrier"
					elseif slotNumber == 1 then
						role = "Carrier"
					end

					registerActorModel(actorModel, role, slotNumber)
				end
			end
		end

		registerCompanionsFromVisualController()

		local matchSceneQuery = context.MatchSceneQuery
		local enemiesFolder = matchSceneQuery
			and matchSceneQuery.GetSpawnedEnemiesFolder
			and matchSceneQuery.GetSpawnedEnemiesFolder(false)

		if enemiesFolder then
			for _, enemyModel in ipairs(enemiesFolder:GetChildren()) do
				if enemyModel:IsA("Model") then
					registerActorModel(enemyModel, "Enemy", nil)
				end
			end
		end
	end

	local function getActiveCarrierTarget(): Vector3?
		local activeSlot = tonumber(controller.ActiveActorSlot) or 1

		if controller._getControlledActorModel then
			local ok, activeModel = pcall(function()
				return controller:_getControlledActorModel(activeSlot)
			end)

			if ok and activeModel then
				local rootPart = findRootPart(activeModel)
				if rootPart then
					return rootPart.Position + Vector3.new(0, 2.2, 0)
				end
			end
		end

		return nil
	end

	local function getBallTarget(): Vector3?
		if controller.MatchBallController and controller.MatchBallController.GetBallPosition then
			local ok, ballPosition = pcall(function()
				return controller.MatchBallController:GetBallPosition()
			end)

			if ok and typeof(ballPosition) == "Vector3" then
				return ballPosition + Vector3.new(0, 1.4, 0)
			end
		end

		if context.Utils and context.Utils.GetLiveBallPosition then
			local ok, ballPosition = pcall(function()
				return context.Utils.GetLiveBallPosition(controller)
			end)

			if ok and typeof(ballPosition) == "Vector3" then
				return ballPosition + Vector3.new(0, 1.4, 0)
			end
		end

		return nil
	end

	local function resolveTargetForRecord(record: ActorRecord): Vector3?
		local currentAction = tostring(controller.CurrentPresentationAction or "")
		local currentStepIndex = tonumber(controller.CurrentPresentationStepIndex) or 0

		if currentAction == "Shoot" or currentStepIndex >= 5 then
			return nil
		end

		-- Carrier should not stare at its own ball too much.
		-- It should mostly keep the running direction / animation readable.
		if record.Role == "Carrier" then
			return nil
		end

		local ballTarget = getBallTarget()
		if ballTarget then
			return ballTarget
		end

		return getActiveCarrierTarget()
	end

	local function startLookAt()
		if not MatchActorLookConfig.Enabled then
			return
		end

		stopLookAt()

		controller._matchActorLookRecords = controller._matchActorLookRecords or {}
		table.clear(controller._matchActorLookRecords)

		controller._matchActorLookSkipLogged = {}
		controller._matchActorLookFirstTargetLogged = nil

		local refreshAccumulator = 0

		registerControlledActors()

		controller._matchActorLookConnection = connectLookAtLoop(function(dt)
			refreshAccumulator += dt

			if refreshAccumulator >= 0.2 then
				refreshAccumulator = 0
				registerControlledActors()
			end

			for index = #controller._matchActorLookRecords, 1, -1 do
				local record = controller._matchActorLookRecords[index]

				if not refreshRecord(record) then
					resetRecord(record)
					table.remove(controller._matchActorLookRecords, index)
					continue
				end

				if record.SlotId ~= nil then
					local slotNumber = tonumber(record.SlotId)
					if slotNumber and tonumber(controller.ActiveActorSlot) == slotNumber then
						record.Role = "Carrier"
					elseif slotNumber and slotNumber >= 1 and slotNumber <= 4 then
						record.Role = "Companion"
					end
				end

				if isKeeperModel(record.Model) then
					record.Role = "Keeper"
				end

				local targetPosition = resolveTargetForRecord(record)
				updateActor(record, targetPosition, dt)
			end
		end)

		debugPrint("started actors", #controller._matchActorLookRecords)
	end

	function controller:_startMatchActorLookAt()
		startLookAt()
	end

	function controller:_stopMatchActorLookAt()
		stopLookAt()
	end

	function controller:_resetMatchActorLookAt()
		resetAll()
	end
end
