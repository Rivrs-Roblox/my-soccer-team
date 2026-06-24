-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Knit packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Sound = require(ReplicatedStorage.Packages.Sound)

-- Helpers
local Helpers = ReplicatedStorage.Shared.Helpers
local TrainingRuntimeRegistry = require(Helpers.Training.TrainingRuntimeRegistry)
local OriginalCharacterMask = require(Helpers.Training.OriginalCharacterMask)
local TrainingZoneUtils = require(Helpers.Training.ZoneUtils)
local TrainingUpdate = require(Helpers.Training.Update)
local Settings = require(Helpers.Training.Settings)
local GetTableAmount = require(Helpers.Table.GetTableAmount)
local GetAngleDistance = require(Helpers.Math.GetAngleDistance)
local FormatNumber = require(Helpers.Numbers.FormatNumber)

-- Knit Services
local TrainingService
local TeleportService

-- Knit Controllers
local DataCacheController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local trainingOptionsGui = playerGui:WaitForChild("TrainingOptionsGui")

local TRAINING_BALL_TEMPLATE_NAME = "TrainingMatchBall"
local TRAINING_BALL_RELEASE_MARKER = "BallRelease"
local TRAINING_SHOOT_SOUND_NAME = "MISC_Shoot_Training"
local TRAINING_PASS_SOUND_NAME = "MISC_Pass_Training"
local DEFAULT_RELEASE_FALLBACK_SECONDS = 0.9
local FALLBACK_ACTION_FX_ATTACHMENT_NAME = "TrainingActionFxAttachment"
local FALLBACK_ACTION_FX_NAME = "TrainingActionFx"

local function DisconnectConnection(connection)
	if connection then
		connection:Disconnect()
	end
	return nil
end

local currentTrainingLevel = 1

local function ForEachBasePart(root: Instance?, callback)
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

local function IsEmbeddedBallPart(part: Instance?): boolean
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

local function ForEachEmbeddedBallPart(actorModel: Model?, callback)
	if not actorModel or type(callback) ~= "function" then
		return 0
	end

	local visited = {}
	local count = 0

	local function visitPart(part)
		if part and part:IsA("BasePart") and not visited[part] then
			visited[part] = true
			count += 1
			callback(part)
		end
	end

	local footballRoot = actorModel:FindFirstChild("Football", true)
	if footballRoot then
		if footballRoot:IsA("BasePart") then
			visitPart(footballRoot)
		end

		for _, descendant in ipairs(footballRoot:GetDescendants()) do
			if descendant:IsA("BasePart") then
				visitPart(descendant)
			end
		end
	end

	for _, descendant in ipairs(actorModel:GetDescendants()) do
		if descendant:IsA("BasePart") and IsEmbeddedBallPart(descendant) then
			visitPart(descendant)
		end
	end

	return count
end

local function GetEmbeddedBallPrimaryPart(actorModel: Model?): BasePart?
	local selectedPart = nil

	ForEachEmbeddedBallPart(actorModel, function(part)
		if selectedPart then
			return
		end

		local loweredName = string.lower(part.Name)
		if
			loweredName == "ball"
			or loweredName == "football"
			or loweredName == "soccerball"
			or loweredName == "matchball"
		then
			selectedPart = part
		end
	end)

	if not selectedPart then
		ForEachEmbeddedBallPart(actorModel, function(part)
			if not selectedPart then
				selectedPart = part
			end
		end)
	end

	return selectedPart
end

local function GetReplicatedCharacterSoundEmitterPart(targetPlayer: Player?): BasePart?
	local character = targetPlayer and targetPlayer.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	local rightFoot = character:FindFirstChild("RightFoot")
		or character:FindFirstChild("Right Leg")
		or character:FindFirstChild("RightLowerLeg")
	if rightFoot and rightFoot:IsA("BasePart") then
		return rightFoot
	end

	if character.PrimaryPart and character.PrimaryPart:IsA("BasePart") then
		return character.PrimaryPart
	end

	return character:FindFirstChildWhichIsA("BasePart", true)
end

local function SetEffectEnabled(root: Instance?, enabled: boolean)
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

local function EmitParticles(root: Instance?, emitCount: number?)
	if not root then
		return
	end

	local count = math.max(math.floor(tonumber(emitCount) or 20), 1)

	local function emitOne(instance)
		if instance:IsA("ParticleEmitter") then
			instance.Enabled = true
			instance:Emit(count)
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
end

local function FindFirstActorPart(actorModel: Model?, partNames): BasePart?
	if not actorModel then
		return nil
	end

	for _, partName in ipairs(partNames) do
		local part = actorModel:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	return nil
end

local function GetOrCreateFallbackActionEmitter(part: BasePart?, suffix: string, enabled: boolean): ParticleEmitter?
	if not part then
		return nil
	end

	local attachment = part:FindFirstChild(FALLBACK_ACTION_FX_ATTACHMENT_NAME)
	if not attachment and enabled == true then
		attachment = Instance.new("Attachment")
		attachment.Name = FALLBACK_ACTION_FX_ATTACHMENT_NAME
		attachment.Parent = part
	end

	if not attachment then
		return nil
	end

	local emitterName = FALLBACK_ACTION_FX_NAME .. suffix
	local emitter = attachment:FindFirstChild(emitterName)
	if not emitter and enabled == true then
		emitter = Instance.new("ParticleEmitter")
		emitter.Name = emitterName
		emitter.Enabled = false
		emitter.LightEmission = 0.85
		emitter.LightInfluence = 0
		emitter.Brightness = 2.5
		emitter.Rate = 28
		emitter.Lifetime = NumberRange.new(0.16, 0.38)
		emitter.Speed = NumberRange.new(1.5, 4.5)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-140, 140)
		emitter.SpreadAngle = Vector2.new(45, 45)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.35),
			NumberSequenceKeypoint.new(0.45, 0.70),
			NumberSequenceKeypoint.new(1.00, 0.00),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.05),
			NumberSequenceKeypoint.new(0.65, 0.15),
			NumberSequenceKeypoint.new(1.00, 1.00),
		})
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.30, Color3.fromRGB(255, 230, 90)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 145, 35)),
		})
		emitter.Parent = attachment
	end

	return emitter
end

local function SetFallbackActorActionFxEnabled(actorModel: Model?, enabled: boolean, emitCount: number?): number
	if not actorModel then
		return 0
	end

	local changedCount = 0
	local targets = {
		{
			Part = FindFirstActorPart(actorModel, { "RightFoot", "RightLowerLeg", "Right Leg", "RightFootHandle" }),
			Suffix = "Foot",
		},
		{
			Part = FindFirstActorPart(actorModel, { "LowerTorso", "Torso", "HumanoidRootPart" }),
			Suffix = "Torso",
		},
	}

	for _, target in ipairs(targets) do
		local emitter = GetOrCreateFallbackActionEmitter(target.Part, target.Suffix, enabled)
		if emitter then
			emitter.Enabled = enabled == true
			if enabled == true and emitCount and emitCount > 0 then
				emitter:Emit(emitCount)
			end
			changedCount += 1
		end
	end

	return changedCount
end

local function SetTrainingActorActionFxEnabled(actorModel: Model?, enabled: boolean, emitCount: number?): number
	if not actorModel then
		return 0
	end

	local changedCount = 0

	local function setFx(root: Instance?)
		if not root then
			return
		end

		SetEffectEnabled(root, enabled)
		if enabled == true and emitCount and emitCount > 0 then
			EmitParticles(root, emitCount)
		end
		changedCount += 1
	end

	local rightFoot = actorModel:FindFirstChild("RightFoot", true)
	if rightFoot then
		setFx(rightFoot:FindFirstChild("Fx1"))
	end

	local lowerTorso = actorModel:FindFirstChild("LowerTorso", true)
	local lowerTorsoEffects = lowerTorso and lowerTorso:FindFirstChild("Effects")
	if lowerTorsoEffects then
		setFx(lowerTorsoEffects:FindFirstChild("Fx1"))
		setFx(lowerTorsoEffects:FindFirstChild("Fx2"))
	end

	if changedCount <= 0 then
		changedCount += SetFallbackActorActionFxEnabled(actorModel, enabled, emitCount)
	elseif enabled ~= true then
		SetFallbackActorActionFxEnabled(actorModel, false)
	end

	return changedCount
end

local TrainingController = Knit.CreateController({
	Name = "TrainingController",
	VisualStates = {},
	PlayerTrainingProxies = {},
	PlayerProxyStates = {},
	PlayerProxyFolder = nil,
	TrainingBallFolder = nil,

	LastBallCycle = {},
	ActiveBallRuntime = {},

	LastPassBallCycle = {},
	ActivePassBallRuntime = {},

	LastDribbleCycle = {},
	ActiveDribbleBallRuntime = {},

	ActiveTrainingBallRuntime = {},
	TrainingBallReleaseBindings = {},
	ActiveTrainingDribbleTemplateFx = {},
	ActiveTrainingActorDribbleFx = {},
	TrainingActorReleaseFxTokens = {},
	TrainingActorKickFxTokens = {},
})

function TrainingController:_updateTrainingOptionsSelection()
	local center = trainingOptionsGui.Frame.BottomFrame.Center
	for level = 1, 3 do
		local frame = center:FindFirstChild(tostring(level))
		if frame then
			local arrow = frame:FindFirstChild("Arrow")
			if arrow then
				arrow.Visible = (level == currentTrainingLevel)
			end
		end
	end
end

function TrainingController:_setupTrainingOptionsUI(statType)
	currentTrainingLevel = 1
	self:_updateTrainingOptionsSelection()

	self.CurrentTrainingCosts = {}

	task.spawn(function()
		local DataService = Knit.GetService("DataService")
		local success, data = DataService:GetData():await()
		local areaId = data and data.Areas and data.Areas.Current or "Area01"

		local areaData = self.Template.Training[areaId]
		local statData = areaData and areaData[statType]
		if not statData then
			return
		end

		local center = trainingOptionsGui.Frame.BottomFrame.Center
		for level = 1, 3 do
			local frame = center:FindFirstChild(tostring(level))
			if frame then
				local button = frame:FindFirstChild("Button", true)
				if button then
					local top = button:FindFirstChild("Top", true)
					local bottom = button:FindFirstChild("Bottom", true)

					if top and top:FindFirstChild("RewardText", true) then
						top.RewardText.Text = "+" .. FormatNumber(statData[level].RewardPerTick) .. "/s"
					end

					if bottom and bottom:FindFirstChild("StaminaCostText", true) then
						bottom.Visible = true
						local cost = statData[level].StaminaCostPerTick
						self.CurrentTrainingCosts[level] = cost
						bottom.StaminaCostText.Text = FormatNumber(cost) .. "/s"

						local maxStamina = data and data.Stats and data.Stats.Stamina or 100
						if maxStamina < cost then
							bottom.StaminaCostText.TextColor3 = Color3.fromRGB(255, 0, 0)
						else
							bottom.StaminaCostText.TextColor3 = Color3.fromRGB(255, 255, 255)
						end
					end
				end
			end
		end
	end)
end

function TrainingController:_stripScripts(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end
end

function TrainingController:_makeModelVisualOnly(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.Anchored = (descendant == root)
		end
	end
end

function TrainingController:_findAnimator(model: Model): Animator?
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if animator then
		return animator
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animationController = model:FindFirstChildOfClass("AnimationController")
	local parent = humanoid or animationController
	if not parent then
		return nil
	end

	animator = parent:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	animator = Instance.new("Animator")
	animator.Parent = parent
	return animator
end

function TrainingController:_applyRootCFrame(root: Instance, cf: CFrame)
	if root:IsA("Model") then
		root:PivotTo(cf)
	elseif root:IsA("BasePart") then
		root.CFrame = cf
	end
end

function TrainingController:_getRootCFrame(root: Instance): CFrame?
	if root:IsA("Model") then
		return root:GetPivot()
	elseif root:IsA("BasePart") then
		return root.CFrame
	end
	return nil
end

function TrainingController:_getMatchBallTemplate(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets and assets:FindFirstChild("MatchBallTemplate") then
		return assets.MatchBallTemplate
	end

	return ReplicatedStorage:FindFirstChild("MatchBallTemplate", true)
end

function TrainingController:_resolveTrainingBallDriverPart(instance: Instance?): BasePart?
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

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function TrainingController:_resolveTrainingBallVisualPart(instance: Instance?, driverPart: BasePart?): BasePart?
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

function TrainingController:_applyTrainingBallCFrame(runtime, targetCFrame: CFrame, spinAngle: number?)
	if not runtime or not runtime.Root or not targetCFrame then
		return
	end

	if runtime.Root:IsA("BasePart") then
		self:_applyRootCFrame(runtime.Root, targetCFrame * CFrame.Angles(spinAngle or 0, 0, 0))
		return
	end

	self:_applyRootCFrame(runtime.Root, targetCFrame)

	if runtime.VisualPart and runtime.VisualPart.Parent and runtime.DriverPart and runtime.DriverPart.Parent then
		runtime.VisualPart.CFrame = runtime.DriverPart.CFrame
			* (runtime.VisualLocalCFrame or CFrame.identity)
			* CFrame.Angles(spinAngle or 0, 0, 0)
	end
end

function TrainingController:_prepareTrainingBallInstance(instance: Instance)
	ForEachBasePart(instance, function(part)
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)

	SetEffectEnabled(instance, false)
end

function TrainingController:_findTrainingBallEffectGroup(runtime, groupName: string)
	if not runtime or not runtime.Root or type(groupName) ~= "string" or groupName == "" then
		return nil
	end

	runtime.EffectGroups = runtime.EffectGroups or {}
	local cached = runtime.EffectGroups[groupName]
	if cached and cached.Parent then
		return cached
	end

	for _, descendant in ipairs(runtime.Root:GetDescendants()) do
		if descendant.Name == groupName then
			runtime.EffectGroups[groupName] = descendant
			return descendant
		end
	end

	return nil
end

function TrainingController:_setTrainingBallFlightEffectsEnabled(runtime, enabled: boolean)
	if not runtime then
		return
	end

	local specialEffects = self:_findTrainingBallEffectGroup(runtime, "SpecialEffects")
	SetEffectEnabled(specialEffects, false)
	SetEffectEnabled(self:_findTrainingBallEffectGroup(runtime, "Trail"), false)
	SetEffectEnabled(self:_findTrainingBallEffectGroup(runtime, "HoldEffects"), false)

	if enabled ~= true then
		SetEffectEnabled(self:_findTrainingBallEffectGroup(runtime, "ExplodeEffects"), false)
	end
end

function TrainingController:_emitTrainingBallImpact(runtime)
	local explodeRoot = self:_findTrainingBallEffectGroup(runtime, "ExplodeEffects")
	if not explodeRoot then
		return
	end

	local function shrinkEmitter(instance)
		if instance:IsA("ParticleEmitter") then
			instance.Lifetime = NumberRange.new(0.18, 0.36)
			instance.Speed = NumberRange.new(3, 7)
			instance.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0.00, 0.25),
				NumberSequenceKeypoint.new(0.35, 0.55),
				NumberSequenceKeypoint.new(1.00, 0.00),
			})
		end
	end

	shrinkEmitter(explodeRoot)
	for _, descendant in ipairs(explodeRoot:GetDescendants()) do
		shrinkEmitter(descendant)
	end

	EmitParticles(explodeRoot, 8)

	task.delay(0.55, function()
		if runtime and runtime.Root and runtime.Root.Parent then
			SetEffectEnabled(explodeRoot, false)
		end
	end)
end

function TrainingController:_setTrainingBallPartsVisible(runtime, isVisible: boolean)
	if not runtime or not runtime.Root or not runtime.Root.Parent then
		return
	end

	ForEachBasePart(runtime.Root, function(part)
		if isVisible then
			part.Transparency = runtime.OriginalTransparency[part] or 0
			part.LocalTransparencyModifier = 0
		else
			part.Transparency = 1
			part.LocalTransparencyModifier = 1
		end

		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end)
end

function TrainingController:_setTrainingBallVisible(runtime, isVisible: boolean)
	if not runtime or not runtime.Root or not runtime.Root.Parent then
		return
	end

	if isVisible ~= true then
		self:_setTrainingBallFlightEffectsEnabled(runtime, false)
	end

	self:_setTrainingBallPartsVisible(runtime, isVisible)
end

function TrainingController:_getTrainingBallRuntime(player: Player, visualKey: string)
	if not self.TrainingBallFolder then
		return nil
	end

	local bag = self.ActiveTrainingBallRuntime[player]
	if not bag then
		bag = {}
		self.ActiveTrainingBallRuntime[player] = bag
	end

	local runtime = bag[visualKey]
	if runtime and runtime.Root and runtime.Root.Parent and runtime.DriverPart and runtime.DriverPart.Parent then
		return runtime
	end

	local template = self:_getMatchBallTemplate()
	if not template then
		warn("[TrainingController] Missing ReplicatedStorage.Assets.MatchBallTemplate for training ball visual.")
		return nil
	end

	local clone = template:Clone()
	clone.Name = TRAINING_BALL_TEMPLATE_NAME .. "_" .. tostring(player.UserId) .. "_" .. visualKey
	clone.Parent = self.TrainingBallFolder

	local driverPart = self:_resolveTrainingBallDriverPart(clone)
	if not driverPart then
		clone:Destroy()
		warn("[TrainingController] Failed to resolve MatchBallTemplate driver part.")
		return nil
	end

	if clone:IsA("Model") and not clone.PrimaryPart then
		clone.PrimaryPart = driverPart
	end

	self:_prepareTrainingBallInstance(clone)

	local originalTransparency = {}
	ForEachBasePart(clone, function(part)
		originalTransparency[part] = part.Transparency
	end)

	runtime = {
		Root = clone,
		DriverPart = driverPart,
		VisualPart = self:_resolveTrainingBallVisualPart(clone, driverPart),
		VisualLocalCFrame = CFrame.identity,
		OriginalTransparency = originalTransparency,
		MotionConnection = nil,
		Token = 0,
		EffectGroups = {},
		SpinAngle = 0,
	}

	if runtime.VisualPart and runtime.VisualPart.Parent then
		runtime.VisualLocalCFrame = driverPart.CFrame:ToObjectSpace(runtime.VisualPart.CFrame)
	end

	-- Hanya Mesh yang boleh berputar. Attachment (A0, A1 dll) dan FX folder di bawah Mesh
	-- harus dipindah ke DriverPart (Pivot) supaya tidak ikut spinning.
	-- A0/A1 dipakai oleh Trail sebagai anchor → kalau masih di Mesh, Trail akan ikut berputar.
	-- Saat reparenting Attachment, local CFrame-nya dikoreksi agar WorldPosition tidak berubah.
	if runtime.VisualPart and runtime.DriverPart and runtime.VisualPart ~= runtime.DriverPart then
		local visualToDriver = runtime.VisualLocalCFrame -- offset Mesh relative to Pivot
		for _, child in ipairs(runtime.VisualPart:GetChildren()) do
			local shouldMove = false
			if child:IsA("Attachment") then
				-- Pindahkan SEMUA attachment (termasuk A0/A1 yang kosong tapi dipakai Trail)
				shouldMove = true
			else
				local n = child.Name
				shouldMove = n == "Trail"
					or n == "SpecialEffects"
					or n == "Effects"
					or n == "HoldEffects"
					or n == "ExplodeEffects"
					or n == "Fx1"
					or n == "Fx2"
					or n == "Fx3"
			end

			if shouldMove then
				if child:IsA("Attachment") then
					-- Koreksi local CFrame agar WorldPosition tetap sama setelah parent berubah:
					-- WorldPos lama = Mesh.CFrame * child.CFrame
					-- WorldPos baru harus = Pivot.CFrame * newLocalCFrame
					-- newLocalCFrame = (Pivot:ToObjectSpace(Mesh)) * child.CFrame = visualToDriver * child.CFrame
					child.CFrame = visualToDriver * child.CFrame
				end
				child.Parent = runtime.DriverPart
			end
		end
	end

	bag[visualKey] = runtime
	self:_setTrainingBallVisible(runtime, false)
	return runtime
end

function TrainingController:_stopTrainingBallRuntime(runtime)
	if not runtime then
		return
	end

	runtime.MotionConnection = DisconnectConnection(runtime.MotionConnection)
	runtime.Token = (runtime.Token or 0) + 1
	self:_setTrainingBallFlightEffectsEnabled(runtime, false)
end

function TrainingController:_resetTrainingBallVisuals(player: Player)
	local bag = self.ActiveTrainingBallRuntime[player]
	if not bag then
		return
	end

	for _, runtime in pairs(bag) do
		self:_stopTrainingBallRuntime(runtime)
		self:_setTrainingBallVisible(runtime, false)
	end
end

function TrainingController:_destroyTrainingBallVisuals(player: Player)
	local bag = self.ActiveTrainingBallRuntime[player]
	if not bag then
		return
	end

	for _, runtime in pairs(bag) do
		self:_stopTrainingBallRuntime(runtime)

		if runtime.Root and runtime.Root.Parent then
			runtime.Root:Destroy()
		end
	end

	self.ActiveTrainingBallRuntime[player] = nil
end

function TrainingController:_playTrainingBallFlight(
	player: Player,
	visualKey: string,
	startCFrame: CFrame,
	endPosition: Vector3,
	duration: number,
	arcHeight: number?,
	curveMagnitude: number?,
	impactEffectEnabled: boolean?,
	onImpact,
	onHidden
)
	local runtime = self:_getTrainingBallRuntime(player, visualKey)
	if not runtime then
		return
	end

	self:_stopTrainingBallRuntime(runtime)
	self:_setTrainingBallVisible(runtime, true)
	self:_setTrainingBallFlightEffectsEnabled(runtime, true)

	local root = runtime.Root
	local startPosition = startCFrame.Position
	local flatDirection = Vector3.new(endPosition.X - startPosition.X, 0, endPosition.Z - startPosition.Z)
	local fallbackLook = flatDirection.Magnitude > 0.001 and flatDirection.Unit or startCFrame.LookVector
	local flightDuration = math.max(tonumber(duration) or 0.35, 0.08)
	local height = math.max(tonumber(arcHeight) or 0, 0)
	local curve = tonumber(curveMagnitude) or 0
	local startedAt = os.clock()
	local motionToken = runtime.Token
	local lastPosition = startPosition
	local sideDirection = Vector3.zero

	if curve ~= 0 and flatDirection.Magnitude > 0.001 then
		sideDirection = flatDirection.Unit:Cross(Vector3.yAxis)
		if sideDirection.Magnitude > 0.001 then
			sideDirection = sideDirection.Unit
		else
			sideDirection = Vector3.zero
		end
	end

	runtime.SpinAngle = runtime.SpinAngle or 0
	self:_applyTrainingBallCFrame(
		runtime,
		CFrame.lookAt(startPosition, startPosition + fallbackLook),
		runtime.SpinAngle
	)

	local function getArcPosition(alpha: number): Vector3
		local easedAlpha = 1 - math.pow(1 - alpha, 2)
		local position = startPosition:Lerp(endPosition, easedAlpha)

		if height > 0 then
			position += Vector3.new(0, math.sin(alpha * math.pi) * height, 0)
		end

		if curve ~= 0 and sideDirection.Magnitude > 0.001 then
			position += sideDirection * math.pow(math.sin(alpha * math.pi), 0.75) * curve
		end

		return position
	end

	runtime.MotionConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if runtime.Token ~= motionToken or not root or not root.Parent then
			runtime.MotionConnection = DisconnectConnection(runtime.MotionConnection)
			return
		end

		local alpha = math.clamp((os.clock() - startedAt) / flightDuration, 0, 1)
		local position = getArcPosition(alpha)
		local nextPosition = getArcPosition(math.min(alpha + ((deltaTime or 1 / 60) / flightDuration), 1))
		local lookDirection = nextPosition - position
		lookDirection = lookDirection.Magnitude > 0.001 and lookDirection.Unit or fallbackLook

		local distanceDelta = (position - lastPosition).Magnitude
		lastPosition = position

		runtime.SpinAngle = ((runtime.SpinAngle or 0) + distanceDelta * 4.8) % (math.pi * 2)
		self:_applyTrainingBallCFrame(runtime, CFrame.lookAt(position, position + lookDirection), runtime.SpinAngle)

		if alpha >= 1 then
			runtime.MotionConnection = DisconnectConnection(runtime.MotionConnection)
			if impactEffectEnabled == true then
				self:_emitTrainingBallImpact(runtime)
			end

			if type(onImpact) == "function" then
				onImpact(endPosition)
			end

			local hideDelay = impactEffectEnabled == true and 0.22 or 0.03
			local effectLinger = impactEffectEnabled == true and 0.5 or 0.35
			task.delay(hideDelay, function()
				if runtime.Token == motionToken and root and root.Parent then
					self:_setTrainingBallPartsVisible(runtime, false)

					task.delay(effectLinger, function()
						if runtime.Token == motionToken and root and root.Parent then
							self:_setTrainingBallFlightEffectsEnabled(runtime, false)
							if type(onHidden) == "function" then
								onHidden()
							end
						end
					end)
				end
			end)
		end
	end)
end

function TrainingController:_setActorEmbeddedBallHidden(actorModel: Model?, hidden: boolean)
	local hiddenFlag = hidden == true
	ForEachEmbeddedBallPart(actorModel, function(part)
		part.Transparency = hiddenFlag and 1 or 0
		part.LocalTransparencyModifier = hiddenFlag and 1 or 0
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = hiddenFlag ~= true
	end)
end

function TrainingController:_getActorModelAndInfo(player: Player, actorIndex: number): (Model?, table?)
	if actorIndex == 1 then
		return self.PlayerTrainingProxies[player], self.PlayerProxyStates[player]
	end

	local companions = self.SoccerCharactersController.SoccerCharactersInSession[player]
	local grid = companions and companions[actorIndex - 1]
	if not grid then
		return nil, nil
	end

	local model = grid.Model
	if typeof(model) ~= "Instance" then
		return nil, grid.LastInformation
	end

	return model, grid.LastInformation
end

function TrainingController:_isActorDribbleFxActive(player: Player, actorIndex: number): boolean
	local playerFx = self.ActiveTrainingActorDribbleFx[player]
	return playerFx ~= nil and playerFx[actorIndex] == true
end

function TrainingController:_isActorReleaseFxActive(player: Player, actorIndex: number): boolean
	local playerTokens = self.TrainingActorReleaseFxTokens[player]
	return playerTokens ~= nil and playerTokens[actorIndex] ~= nil
end

function TrainingController:_setActorDribbleFxEnabled(
	player: Player,
	actorIndex: number,
	actorModel: Model?,
	enabled: boolean
)
	if not player or not actorIndex then
		return
	end

	local playerFx = self.ActiveTrainingActorDribbleFx[player]
	if enabled == true then
		if not actorModel then
			return
		end

		if not playerFx then
			playerFx = {}
			self.ActiveTrainingActorDribbleFx[player] = playerFx
		end

		if playerFx[actorIndex] ~= true then
			playerFx[actorIndex] = true
			SetTrainingActorActionFxEnabled(actorModel, true, 4)
		end
		return
	end

	if not playerFx or playerFx[actorIndex] ~= true then
		return
	end

	playerFx[actorIndex] = nil
	if not self:_isActorReleaseFxActive(player, actorIndex) then
		SetTrainingActorActionFxEnabled(actorModel, false)
	end
end

function TrainingController:_emitTrainingActorReleaseFx(
	player: Player,
	actorIndex: number,
	duration: number,
	emitCount: number?,
	visualState
)
	local playerTokens = self.TrainingActorReleaseFxTokens[player]
	if not playerTokens then
		playerTokens = {}
		self.TrainingActorReleaseFxTokens[player] = playerTokens
	end

	local actorModel = self:_getActorModelAndInfo(player, actorIndex)
	local token = (playerTokens[actorIndex] or 0) + 1
	playerTokens[actorIndex] = token
	SetTrainingActorActionFxEnabled(actorModel, true, emitCount or 10)

	local level = visualState and visualState.Level or 1
	task.delay(math.max(tonumber(duration) or 0.65, 0.05) / level, function()
		local currentTokens = self.TrainingActorReleaseFxTokens[player]
		if not currentTokens or currentTokens[actorIndex] ~= token then
			return
		end

		currentTokens[actorIndex] = nil
		if next(currentTokens) == nil then
			self.TrainingActorReleaseFxTokens[player] = nil
		end

		if not self:_isActorDribbleFxActive(player, actorIndex) then
			SetTrainingActorActionFxEnabled(actorModel, false)
		end
	end)
end

function TrainingController:_pulseActorKickFx(
	player: Player,
	actorIndex: number,
	actorModel: Model?,
	kickToken: string?,
	duration: number?,
	emitCount: number?,
	visualState
)
	if not player or not actorIndex or not actorModel or not kickToken then
		return
	end

	local playerTokens = self.TrainingActorKickFxTokens[player]
	if not playerTokens then
		playerTokens = {}
		self.TrainingActorKickFxTokens[player] = playerTokens
	end

	if playerTokens[actorIndex] == kickToken then
		return
	end

	playerTokens[actorIndex] = kickToken
	self:_emitTrainingActorReleaseFx(player, actorIndex, duration or 0.65, emitCount or 10, visualState)
end

function TrainingController:_shouldEnableDribbleActorFx(actorState): boolean
	if not actorState or actorState.Mode ~= "DribbleTraining" then
		return false
	end

	if actorState.ActorIndex ~= actorState.RunnerIndex then
		return false
	end

	if actorState.PhaseName ~= "NodeRun" then
		return false
	end

	local activeNodeIndex = tonumber(actorState.ActiveNodeIndex) or 0
	return activeNodeIndex >= 1 and activeNodeIndex < 5
end

function TrainingController:_clearActorDribbleFx(player: Player)
	local playerFx = self.ActiveTrainingActorDribbleFx[player]
	if not playerFx then
		return
	end

	local actorIndexes = {}
	for actorIndex in pairs(playerFx) do
		table.insert(actorIndexes, actorIndex)
	end

	for _, actorIndex in ipairs(actorIndexes) do
		local actorModel = self:_getActorModelAndInfo(player, actorIndex)
		self:_setActorDribbleFxEnabled(player, actorIndex, actorModel, false)
	end
end

function TrainingController:_clearTrainingActorFx(player: Player)
	local actorIndexes = {}

	local playerFx = self.ActiveTrainingActorDribbleFx[player]
	if playerFx then
		for actorIndex in pairs(playerFx) do
			actorIndexes[actorIndex] = true
		end
	end

	local playerTokens = self.TrainingActorReleaseFxTokens[player]
	if playerTokens then
		for actorIndex in pairs(playerTokens) do
			actorIndexes[actorIndex] = true
		end
	end

	for actorIndex in pairs(actorIndexes) do
		local actorModel = self:_getActorModelAndInfo(player, actorIndex)
		SetTrainingActorActionFxEnabled(actorModel, false)
	end

	self.ActiveTrainingActorDribbleFx[player] = nil
	self.TrainingActorReleaseFxTokens[player] = nil
	self.TrainingActorKickFxTokens[player] = nil
end

function TrainingController:_updateDribbleTrainingActorFx(player: Player, visualState, totalCount: number)
	if not TrainingRuntimeRegistry.SupportsWorldBallDribble(visualState) then
		self:_clearActorDribbleFx(player)
		return
	end

	local activeActorIndexes = {}

	for actorIndex = 1, totalCount do
		local actorState = TrainingRuntimeRegistry.GetActorState(actorIndex, totalCount, visualState)
		local shouldEnable = self:_shouldEnableDribbleActorFx(actorState)

		if shouldEnable then
			activeActorIndexes[actorIndex] = true
		end

		local actorModel = self:_getActorModelAndInfo(player, actorIndex)
		self:_setActorDribbleFxEnabled(player, actorIndex, actorModel, shouldEnable)
	end

	local playerFx = self.ActiveTrainingActorDribbleFx[player]
	if not playerFx then
		return
	end

	local inactiveActorIndexes = {}
	for actorIndex in pairs(playerFx) do
		if activeActorIndexes[actorIndex] ~= true then
			table.insert(inactiveActorIndexes, actorIndex)
		end
	end

	for _, actorIndex in ipairs(inactiveActorIndexes) do
		local actorModel = self:_getActorModelAndInfo(player, actorIndex)
		self:_setActorDribbleFxEnabled(player, actorIndex, actorModel, false)
	end
end

function TrainingController:_clearDribbleTemplateFx(player: Player)
	local state = self.ActiveTrainingDribbleTemplateFx[player]
	if state and state.ActorModel then
		self:_setActorEmbeddedBallHidden(state.ActorModel, false)
	end

	local bag = self.ActiveTrainingBallRuntime[player]
	local runtime = bag and bag.Dribble
	if runtime then
		self:_stopTrainingBallRuntime(runtime)
		self:_setTrainingBallVisible(runtime, false)
	end

	self.ActiveTrainingDribbleTemplateFx[player] = nil
end

function TrainingController:_updateDribbleTemplateFx(player: Player, visualState, cycleData, totalCount: number)
	if not TrainingRuntimeRegistry.SupportsWorldBallDribble(visualState) then
		self:_clearDribbleTemplateFx(player)
		return
	end

	if not cycleData or cycleData.PhaseName ~= "NodeRun" then
		self:_clearDribbleTemplateFx(player)
		return
	end

	local runnerIndex = cycleData.RunnerIndex
	if not runnerIndex then
		self:_clearDribbleTemplateFx(player)
		return
	end

	local actorModel = self:_getActorModelAndInfo(player, runnerIndex)
	local embeddedPart = GetEmbeddedBallPrimaryPart(actorModel)
	if not actorModel or not actorModel.Parent or not embeddedPart then
		self:_clearDribbleTemplateFx(player)
		return
	end

	local runtime = self:_getTrainingBallRuntime(player, "Dribble")
	if not runtime then
		return
	end

	local state = self.ActiveTrainingDribbleTemplateFx[player]
	local token = tostring(cycleData.CycleIndex or "")
	if not state or state.Runtime ~= runtime or state.Token ~= token or state.ActorModel ~= actorModel then
		if state and state.ActorModel and state.ActorModel ~= actorModel then
			self:_setActorEmbeddedBallHidden(state.ActorModel, false)
		end

		self.ActiveTrainingDribbleTemplateFx[player] = {
			Runtime = runtime,
			Token = token,
			ActorModel = actorModel,
		}
		self:_stopTrainingBallRuntime(runtime)
		self:_setTrainingBallVisible(runtime, true)
		self:_setTrainingBallFlightEffectsEnabled(runtime, true)
	end

	self:_setActorEmbeddedBallHidden(actorModel, true)

	runtime.SpinAngle = ((runtime.SpinAngle or 0) + 0.35) % (math.pi * 2)
	-- Gunakan posisi saja (bukan full CFrame) supaya model tidak ikut merotasi
	-- mengikuti orientasi embedded ball part. Hanya Mesh yang boleh berputar via spinAngle.
	-- (Pass/shoot juga hanya pakai CFrame.lookAt dari posisi, bukan CFrame bagian character)
	self:_applyTrainingBallCFrame(runtime, CFrame.new(embeddedPart.Position), runtime.SpinAngle)
end

function TrainingController:_buildTrainingBallReleaseToken(visualState, actorState)
	if not visualState or not actorState then
		return nil
	end

	return table.concat({
		tostring(visualState.ServerStartTime or ""),
		tostring(actorState.Mode or ""),
		tostring(actorState.ActorIndex or ""),
		tostring(actorState.CycleIndex or ""),
		tostring(actorState.PhaseName or ""),
	}, ":")
end

function TrainingController:_isTrainingBallReleased(visualState, releaseToken: string?): boolean
	local releasedTokens = visualState and visualState._TrainingBallReleasedTokens
	return releaseToken ~= nil and releasedTokens ~= nil and releasedTokens[releaseToken] == true
end

function TrainingController:_markTrainingBallReleased(visualState, releaseToken: string?)
	if not visualState or not releaseToken then
		return
	end

	visualState._TrainingBallReleasedTokens = visualState._TrainingBallReleasedTokens or {}
	visualState._TrainingBallReleasedTokens[releaseToken] = true
end

function TrainingController:_getReleaseFallbackDelay(track, actorState, visualState): number
	local level = visualState and visualState.Level or 1

	if track and typeof(track) == "Instance" and track.Length and track.Length > 0.05 then
		return math.clamp(track.Length * 0.92, 0.35, 1.2) / level
	end

	if actorState and actorState.PhaseDuration and actorState.PhaseElapsed then
		local remaining = math.max(actorState.PhaseDuration - actorState.PhaseElapsed, 0.15)
		return math.clamp(remaining * 0.85, 0.35, 1.2) / level
	end

	return DEFAULT_RELEASE_FALLBACK_SECONDS / level
end

function TrainingController:_getShootTargetPosition(cycleData, actorState, releaseCFrame: CFrame): Vector3
	local layout = (cycleData and cycleData.Layout) or (actorState and actorState.Layout)
	local targetPart = layout and layout.GoalTargetPart

	if targetPart and targetPart:IsA("BasePart") then
		return targetPart.Position
	end

	if actorState and typeof(actorState.LookAtPosition) == "Vector3" then
		return actorState.LookAtPosition
	end

	return releaseCFrame.Position + releaseCFrame.LookVector * 28
end

function TrainingController:_getPassTargetIndex(phaseName: string, actorIndex: number, actorState): number?
	if actorState and actorState.ActiveFromIndex == actorIndex and tonumber(actorState.ActiveToIndex) ~= nil then
		return tonumber(actorState.ActiveToIndex)
	end

	if phaseName == "ForwardPass" then
		if actorIndex == 2 then
			return 4
		elseif actorIndex == 3 then
			return 1
		end
	elseif phaseName == "BackwardPass" then
		if actorIndex == 4 then
			return 2
		elseif actorIndex == 1 then
			return 3
		end
	end

	return nil
end

function TrainingController:_getPassSettlePhaseName(phaseName: string): string?
	if phaseName == "ForwardPass" then
		return "ForwardSettle"
	elseif phaseName == "BackwardPass" then
		return "BackwardSettle"
	end

	return nil
end

function TrainingController:_getPassTargetPosition(
	player: Player,
	cycleData,
	actorState,
	releaseCFrame: CFrame
): Vector3?
	local targetIndex = self:_getPassTargetIndex(actorState.PhaseName, actorState.ActorIndex, actorState)
	if not targetIndex then
		return nil
	end

	local targetModel = self:_getActorModelAndInfo(player, targetIndex)
	local targetEmbeddedPart = GetEmbeddedBallPrimaryPart(targetModel)
	if targetEmbeddedPart then
		return targetEmbeddedPart.Position
	end

	local layout = (cycleData and cycleData.Layout) or actorState.Layout
	local targetPivotData = layout and layout.Pivots and layout.Pivots[targetIndex]
	if targetPivotData then
		if targetPivotData.BallArea and targetPivotData.BallArea:IsA("BasePart") then
			return targetPivotData.BallArea.Position + Vector3.new(0, 1.2, 0)
		end

		if targetPivotData.Pivot and targetPivotData.Pivot:IsA("BasePart") then
			return targetPivotData.Pivot.Position + Vector3.new(0, 1.2, 0)
		end
	end

	return releaseCFrame.Position + releaseCFrame.LookVector * 14
end

function TrainingController:_hidePassLaneEmbeddedBalls(player: Player, actorState)
	local sourceModel = self:_getActorModelAndInfo(player, actorState.ActorIndex)
	self:_setActorEmbeddedBallHidden(sourceModel, true)

	local targetIndex = self:_getPassTargetIndex(actorState.PhaseName, actorState.ActorIndex, actorState)
	if targetIndex then
		local targetModel = self:_getActorModelAndInfo(player, targetIndex)
		self:_setActorEmbeddedBallHidden(targetModel, true)
	end
end

function TrainingController:_buildPassReceiveToken(visualState, actorState): string?
	local targetIndex = self:_getPassTargetIndex(actorState.PhaseName, actorState.ActorIndex, actorState)
	local settlePhaseName = self:_getPassSettlePhaseName(actorState.PhaseName)

	if not targetIndex or not settlePhaseName then
		return nil
	end

	return self:_buildTrainingBallReleaseToken(visualState, {
		Mode = "PassTraining",
		ActorIndex = targetIndex,
		CycleIndex = actorState.CycleIndex,
		PhaseName = settlePhaseName,
	})
end

function TrainingController:_markPassReceiverVisible(visualState, receiveToken: string?)
	if not visualState or not receiveToken then
		return
	end

	visualState._TrainingPassReceiveTokens = visualState._TrainingPassReceiveTokens or {}
	visualState._TrainingPassReceiveTokens[receiveToken] = true
end

function TrainingController:_releaseTrainingBallFromActor(
	player: Player,
	visualState,
	cycleData,
	actorState,
	actorModel: Model?,
	visualKey: string,
	releaseToken: string
)
	if self:_isTrainingBallReleased(visualState, releaseToken) then
		return
	end

	self:_markTrainingBallReleased(visualState, releaseToken)
	self:_setActorEmbeddedBallHidden(actorModel, true)

	local embeddedPart = GetEmbeddedBallPrimaryPart(actorModel)
	local releaseCFrame = (embeddedPart and embeddedPart.CFrame)
		or (actorModel and actorModel:GetPivot())
		or CFrame.new()

	if actorState.Mode == "ShootTraining" then
		if player == Players.LocalPlayer then
			local soundParent = GetReplicatedCharacterSoundEmitterPart(player)
			if soundParent then
				Sound:PlayServerSound(TRAINING_SHOOT_SOUND_NAME, soundParent)
			end
		end

		local endPosition = self:_getShootTargetPosition(cycleData, actorState, releaseCFrame)
		local duration = (self.TrainingConfig.Visuals and self.TrainingConfig.Visuals.BallTweenTime) or 0.45
		duration = duration / (visualState.Level or 1)

		self:_playTrainingBallFlight(player, visualKey, releaseCFrame, endPosition, duration, 4, 6.5, true, function()
			self:_emitGoalFx(cycleData)
		end)
	elseif actorState.Mode == "PassTraining" then
		if player == Players.LocalPlayer then
			local soundParent = GetReplicatedCharacterSoundEmitterPart(player)
			if soundParent then
				Sound:PlayServerSound(TRAINING_PASS_SOUND_NAME, soundParent)
			end
		end

		self:_hidePassLaneEmbeddedBalls(player, actorState)

		local endPosition = self:_getPassTargetPosition(player, cycleData, actorState, releaseCFrame)
		if not endPosition then
			return
		end

		local configuredDuration = (self.TrainingConfig.Thresholds and self.TrainingConfig.Thresholds.PassBallTweenTime)
			or 0.34
		local duration = math.max(configuredDuration, 0.46)
		duration = duration / (visualState.Level or 1)

		local receiveToken = self:_buildPassReceiveToken(visualState, actorState)
		self:_playTrainingBallFlight(
			player,
			visualKey,
			releaseCFrame,
			endPosition,
			duration,
			0.9,
			0,
			false,
			nil,
			function()
				self:_markPassReceiverVisible(visualState, receiveToken)
			end
		)
	end
end

function TrainingController:_clearTrainingBallReleaseBinding(player: Player, actorIndex: number)
	local playerBindings = self.TrainingBallReleaseBindings[player]
	local binding = playerBindings and playerBindings[actorIndex]
	if not binding then
		return
	end

	binding.Connection = DisconnectConnection(binding.Connection)
	playerBindings[actorIndex] = nil
end

function TrainingController:_clearTrainingBallReleaseBindings(player: Player)
	local playerBindings = self.TrainingBallReleaseBindings[player]
	if not playerBindings then
		return
	end

	for actorIndex in pairs(playerBindings) do
		self:_clearTrainingBallReleaseBinding(player, actorIndex)
	end

	self.TrainingBallReleaseBindings[player] = nil
end

function TrainingController:_bindTrainingBallRelease(
	player: Player,
	visualState,
	cycleData,
	actorState,
	actorModel: Model?,
	track,
	visualKey: string,
	activeBindingTokens
)
	local releaseToken = self:_buildTrainingBallReleaseToken(visualState, actorState)
	if not releaseToken or self:_isTrainingBallReleased(visualState, releaseToken) then
		return
	end

	activeBindingTokens[actorState.ActorIndex] = releaseToken

	local playerBindings = self.TrainingBallReleaseBindings[player]
	if not playerBindings then
		playerBindings = {}
		self.TrainingBallReleaseBindings[player] = playerBindings
	end

	local existingBinding = playerBindings[actorState.ActorIndex]
	if existingBinding and existingBinding.Token == releaseToken and existingBinding.Track == track then
		return
	end

	self:_clearTrainingBallReleaseBinding(player, actorState.ActorIndex)

	local binding = {
		Token = releaseToken,
		Track = track,
		Released = false,
		Connection = nil,
	}

	local function releaseOnce()
		if binding.Released then
			return
		end

		local currentVisualState = self.VisualStates[player]
		local currentBindings = self.TrainingBallReleaseBindings[player]
		local currentBinding = currentBindings and currentBindings[actorState.ActorIndex]

		if currentVisualState ~= visualState or currentBinding ~= binding then
			return
		end

		binding.Released = true
		self:_releaseTrainingBallFromActor(
			player,
			visualState,
			cycleData,
			actorState,
			actorModel,
			visualKey,
			releaseToken
		)
	end

	if track and typeof(track) == "Instance" then
		local ok, markerSignal = pcall(function()
			return track:GetMarkerReachedSignal(TRAINING_BALL_RELEASE_MARKER)
		end)

		if ok and markerSignal then
			binding.Connection = markerSignal:Connect(releaseOnce)
		end
	end

	playerBindings[actorState.ActorIndex] = binding

	task.delay(self:_getReleaseFallbackDelay(track, actorState, visualState), function()
		releaseOnce()
	end)
end

function TrainingController:_pruneTrainingBallReleaseBindings(player: Player, activeBindingTokens)
	local playerBindings = self.TrainingBallReleaseBindings[player]
	if not playerBindings then
		return
	end

	for actorIndex, binding in pairs(playerBindings) do
		if activeBindingTokens[actorIndex] ~= binding.Token then
			self:_clearTrainingBallReleaseBinding(player, actorIndex)
		end
	end
end

function TrainingController:_updateTrainingBallReleaseBindings(
	player: Player,
	visualState,
	cycleData,
	totalCount: number
)
	if not cycleData then
		self:_clearTrainingBallReleaseBindings(player)
		return
	end

	local isShootTraining = TrainingRuntimeRegistry.SupportsWorldBallShot(visualState)
	local isPassTraining = TrainingRuntimeRegistry.SupportsWorldBallPass(visualState)

	if not isShootTraining and not isPassTraining then
		self:_clearTrainingBallReleaseBindings(player)
		if not TrainingRuntimeRegistry.SupportsWorldBallDribble(visualState) then
			self:_resetTrainingBallVisuals(player)
		end
		return
	end

	local activeBindingTokens = {}

	for actorIndex = 1, totalCount do
		local actorState = TrainingRuntimeRegistry.GetActorState(actorIndex, totalCount, visualState)
		if not actorState then
			continue
		end

		local shouldBind = false
		local visualKey = "Shoot"

		if isShootTraining then
			shouldBind = actorState.PhaseName == "Shooting" and actorState.ExpectedAnimation == "Shoot"
			visualKey = "Shoot"
		elseif isPassTraining then
			shouldBind = (actorState.PhaseName == "ForwardPass" or actorState.PhaseName == "BackwardPass")
				and actorState.ExpectedAnimation == "Shoot"
			visualKey = "Pass_" .. tostring(actorIndex)
		end

		if not shouldBind then
			continue
		end

		local actorModel, actorInfo = self:_getActorModelAndInfo(player, actorIndex)
		if not actorModel or not actorModel.Parent then
			continue
		end

		local track = actorInfo
			and (
				(actorInfo.ActiveTrainingAnimation == "Shoot" and actorInfo.ActiveTrainingAnimationTrack)
				or (actorInfo.Animations and actorInfo.Animations.Shoot)
			)

		self:_bindTrainingBallRelease(
			player,
			visualState,
			cycleData,
			actorState,
			actorModel,
			track,
			visualKey,
			activeBindingTokens
		)
	end

	self:_pruneTrainingBallReleaseBindings(player, activeBindingTokens)
end

function TrainingController:_ensureBallTrail(ball: BasePart): Trail?
	local trail = ball:FindFirstChild("TrainingTrail")
	if trail and trail:IsA("Trail") then
		trail.Enabled = false
		return trail
	end

	return nil
end

function TrainingController:_getOrCreateGoalEmitter(parent: Instance): ParticleEmitter
	local existing = parent:FindFirstChild("GoalBurstEmitter")
	if existing and existing:IsA("ParticleEmitter") then
		return existing
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "GoalBurstEmitter"
	emitter.Enabled = false
	emitter.LightEmission = 0.85
	emitter.LightInfluence = 0
	emitter.Brightness = 3
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.35, 0.7)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.SpreadAngle = Vector2.new(140, 140)

	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.7),
		NumberSequenceKeypoint.new(0.30, 1.0),
		NumberSequenceKeypoint.new(1.00, 0.0),
	})

	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.0),
		NumberSequenceKeypoint.new(0.65, 0.15),
		NumberSequenceKeypoint.new(1.00, 1.0),
	})

	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 240, 110)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(255, 140, 60)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 70, 40)),
	})

	emitter.Parent = parent
	return emitter
end

--|| Training Visual Methods ||--

function TrainingController:_ensurePlayerProxy(player: Player): Model?
	local existing = self.PlayerTrainingProxies[player]
	if existing and existing.Parent then
		return existing
	end

	local character = player.Character
	if not character then
		return nil
	end

	local previousArchivable = character.Archivable
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = previousArchivable

	self:_stripScripts(clone)
	self:_makeModelVisualOnly(clone)

	-- Stop all animations from the original character that might have carried over to the clone
	local animator = clone:FindFirstChildWhichIsA("Animator", true)
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end

	clone.Name = player.Name .. "_0"
	clone.Parent = self.PlayerProxyFolder

	self.PlayerTrainingProxies[player] = clone
	self.PlayerProxyStates[player] = {
		Position = nil,
		Animations = nil,
		CurrentAnimation = nil,
	}

	return clone
end

function TrainingController:_destroyPlayerProxy(player: Player)
	local proxy = self.PlayerTrainingProxies[player]
	if proxy then
		proxy:Destroy()
		self.PlayerTrainingProxies[player] = nil
	end

	self.PlayerProxyStates[player] = nil
end

-- World Ball Logic
function TrainingController:_getZoneBallRoot(zone: BasePart): Instance?
	local ballArea = zone:FindFirstChild("BallArea")
	if not ballArea then
		return nil
	end

	local football = ballArea:FindFirstChild("Football")
	if not football then
		return nil
	end

	local mesh = football:FindFirstChild("Mesh")
	if mesh and mesh:IsA("BasePart") then
		return mesh
	end

	if football:IsA("BasePart") or football:IsA("Model") then
		return football
	end

	return TrainingZoneUtils.FindFirstBasePart(football)
end

function TrainingController:_getBallRuntime(player: Player, cycleData)
	if not cycleData or not cycleData.Layout or not cycleData.Layout.Zone then
		return nil
	end

	local zone = cycleData.Layout.Zone
	local root = self:_getZoneBallRoot(zone)
	if not root or not root.Parent then
		return nil
	end

	local movingPart = TrainingZoneUtils.FindFirstBasePart(root)
	if not movingPart then
		return nil
	end

	local runtime = self.ActiveBallRuntime[player]
	if runtime and runtime.Root == root and root.Parent then
		return runtime
	end

	local originalCFrame = self:_getRootCFrame(root)
	if not originalCFrame then
		return nil
	end

	runtime = {
		Root = root,
		MovingPart = movingPart,
		OriginalCFrame = originalCFrame,
		Tween = nil,
		Driver = nil,
		Trail = self:_ensureBallTrail(movingPart),
	}

	self.ActiveBallRuntime[player] = runtime
	return runtime
end

function TrainingController:_stopBallRuntime(runtime)
	if not runtime then
		return
	end

	if runtime.Tween then
		pcall(function()
			runtime.Tween:Cancel()
		end)
		runtime.Tween = nil
	end

	if runtime.Driver then
		runtime.Driver:Destroy()
		runtime.Driver = nil
	end

	if runtime.Trail then
		runtime.Trail.Enabled = true
	end
end

function TrainingController:_resetWorldBall(player: Player)
	local runtime = self.ActiveBallRuntime[player]
	if not runtime then
		return
	end

	self:_stopBallRuntime(runtime)

	if runtime.Root and runtime.Root.Parent and runtime.OriginalCFrame then
		self:_applyRootCFrame(runtime.Root, runtime.OriginalCFrame)

		for _, descendant in ipairs(runtime.Root:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = 0
			end
		end
	end

	self.ActiveBallRuntime[player] = nil
end

function TrainingController:_emitGoalFx(cycleData)
	if not cycleData or not cycleData.Layout then
		return
	end

	local targetPart = cycleData.Layout.GoalTargetPart
	if not targetPart then
		return
	end

	local emitter = self:_getOrCreateGoalEmitter(targetPart)
	pcall(function()
		emitter:Emit(20)
	end)
end

function TrainingController:_playWorldBallShot(player: Player, cycleData)
	local runtime = self:_getBallRuntime(player, cycleData)
	if not runtime then
		return
	end

	self:_stopBallRuntime(runtime)

	local root = runtime.Root
	local startCFrame = runtime.OriginalCFrame
	local targetPart = cycleData.Layout.GoalTargetPart
	if not root or not root.Parent or not startCFrame or not targetPart then
		return
	end

	if runtime.Trail then
		runtime.Trail.Enabled = true
	end

	local direction = targetPart.Position - startCFrame.Position
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, -1)
	end

	local endCFrame = CFrame.lookAt(targetPart.Position, targetPart.Position + direction.Unit)

	local driver = Instance.new("CFrameValue")
	driver.Value = startCFrame
	runtime.Driver = driver

	driver:GetPropertyChangedSignal("Value"):Connect(function()
		if root and root.Parent then
			self:_applyRootCFrame(root, driver.Value)
		end
	end)

	local tween = TweenService:Create(
		driver,
		TweenInfo.new(self.TrainingConfig.Visuals.BallTweenTime, Enum.EasingStyle.Linear),
		{ Value = endCFrame }
	)
	runtime.Tween = tween

	tween.Completed:Connect(function()
		self:_stopBallRuntime(runtime)
		self:_emitGoalFx(cycleData)

		if root and root.Parent and runtime.OriginalCFrame then
			self:_applyRootCFrame(root, runtime.OriginalCFrame)
		end
	end)

	tween:Play()
end

-- Pass Ball Logic
function TrainingController:_getPassBallRuntime(player: Player, laneId: string, root: Instance?)
	if not root or not root.Parent then
		return nil
	end

	local bag = self.ActivePassBallRuntime[player]
	if not bag then
		bag = {}
		self.ActivePassBallRuntime[player] = bag
	end

	local movingPart = TrainingZoneUtils.FindFirstBasePart(root)
	if not movingPart then
		return nil
	end

	local runtime = bag[laneId]
	if runtime and runtime.Root == root and runtime.Root.Parent then
		return runtime
	end

	local originalCFrame = self:_getRootCFrame(root)
	if not originalCFrame then
		return nil
	end

	runtime = {
		Root = root,
		MovingPart = movingPart,
		OriginalCFrame = originalCFrame,
		Tween = nil,
		Driver = nil,
		Trail = self:_ensureBallTrail(movingPart),
	}

	bag[laneId] = runtime
	return runtime
end

function TrainingController:_stopPassBallRuntime(runtime)
	if not runtime then
		return
	end

	if runtime.Tween then
		pcall(function()
			runtime.Tween:Cancel()
		end)
		runtime.Tween = nil
	end

	if runtime.Driver then
		runtime.Driver:Destroy()
		runtime.Driver = nil
	end

	if runtime.Trail then
		runtime.Trail.Enabled = true
	end
end

function TrainingController:_resetPassBalls(player: Player)
	local bag = self.ActivePassBallRuntime[player]
	if not bag then
		return
	end

	for _, runtime in pairs(bag) do
		self:_stopPassBallRuntime(runtime)

		if runtime.Root and runtime.Root.Parent and runtime.OriginalCFrame then
			self:_applyRootCFrame(runtime.Root, runtime.OriginalCFrame)

			for _, descendant in ipairs(runtime.Root:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.LocalTransparencyModifier = 0
				end
			end
		end
	end

	self.ActivePassBallRuntime[player] = nil
	self.LastPassBallCycle[player] = nil
end

function TrainingController:_playPassBallTween(
	player: Player,
	laneId: string,
	providerPivotData,
	targetPivotData,
	tweenTime: number
)
	if not providerPivotData or not providerPivotData.BallRoot then
		return
	end

	if not targetPivotData or not targetPivotData.BallArea or not targetPivotData.BallArea:IsA("BasePart") then
		return
	end

	local runtime = self:_getPassBallRuntime(player, laneId, providerPivotData.BallRoot)
	if not runtime then
		return
	end

	self:_stopPassBallRuntime(runtime)

	local root = runtime.Root
	if not root or not root.Parent then
		return
	end

	local startCFrame = self:_getRootCFrame(root)
	if not startCFrame then
		return
	end

	if runtime.Trail then
		runtime.Trail.Enabled = false
	end

	local providerArea = providerPivotData.BallArea
	local heightOffset = 0

	if providerArea and providerArea:IsA("BasePart") then
		heightOffset = startCFrame.Position.Y - providerArea.Position.Y
	end

	local targetPosition = targetPivotData.BallArea.Position + Vector3.new(0, heightOffset, 0)

	local direction = targetPosition - startCFrame.Position
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, -1)
	end

	local endCFrame = CFrame.lookAt(targetPosition, targetPosition + direction.Unit)

	local driver = Instance.new("CFrameValue")
	driver.Value = startCFrame
	runtime.Driver = driver

	driver:GetPropertyChangedSignal("Value"):Connect(function()
		if root and root.Parent then
			self:_applyRootCFrame(root, driver.Value)
		end
	end)

	local tween = TweenService:Create(driver, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { Value = endCFrame })
	runtime.Tween = tween

	tween.Completed:Connect(function()
		self:_stopPassBallRuntime(runtime)

		if root and root.Parent then
			self:_applyRootCFrame(root, endCFrame)
		end
	end)

	tween:Play()
end

function TrainingController:_updatePassTrainingBalls(player: Player, cycleData)
	if not cycleData or not cycleData.Layout or not cycleData.Layout.Lanes then
		self:_resetPassBalls(player)
		return
	end

	local phaseName = cycleData.PhaseName
	if phaseName ~= "ForwardPass" and phaseName ~= "BackwardPass" then
		return
	end

	if cycleData.PhaseProgress < (Settings.Pass.ImpactProgress or 0.45) then
		return
	end

	local cycleStore = self.LastPassBallCycle[player]
	if not cycleStore then
		cycleStore = {}
		self.LastPassBallCycle[player] = cycleStore
	end

	for _, lane in ipairs(cycleData.Layout.Lanes) do
		local laneToken = cycleData.Token .. ":" .. lane.Id
		if cycleStore[lane.Id] == laneToken then
			continue
		end

		local carrierPivotData = cycleData.Layout.Pivots[lane.CarrierIndex]
		if not carrierPivotData or not carrierPivotData.BallRoot then
			continue
		end

		local targetPivotData = nil

		if phaseName == "ForwardPass" then
			targetPivotData = cycleData.Layout.Pivots[lane.ForwardToIndex]
		else
			targetPivotData = cycleData.Layout.Pivots[lane.BackwardToIndex]
		end

		if not targetPivotData then
			continue
		end

		self:_playPassBallTween(
			player,
			lane.Id,
			carrierPivotData,
			targetPivotData,
			self.TrainingConfig.Thresholds.PassBallTweenTime
		)

		cycleStore[lane.Id] = laneToken
	end
end

-- Dribble Ball Logic
function TrainingController:_getDribbleZoneBallRoot(zone: Instance): Instance?
	if not zone then
		return nil
	end

	local ballArea = zone:FindFirstChild("BallArea", true)
	if not ballArea then
		return nil
	end

	local football = ballArea:FindFirstChild("Football")
	if not football then
		return nil
	end

	local mesh = football:FindFirstChild("Mesh")
	if mesh and mesh:IsA("BasePart") then
		return mesh
	end

	if football:IsA("BasePart") or football:IsA("Model") then
		return football
	end

	return TrainingZoneUtils.FindFirstBasePart(football)
end

function TrainingController:_getDribbleBallRuntime(player: Player, cycleData)
	if not cycleData or not cycleData.Layout or not cycleData.Layout.Zone then
		return nil
	end

	local zone = cycleData.Layout.Zone
	local root = self:_getDribbleZoneBallRoot(zone)
	if not root or not root.Parent then
		return nil
	end

	local runtime = self.ActiveDribbleBallRuntime[player]
	if runtime and runtime.Root == root and runtime.Root.Parent then
		return runtime
	end

	local originalCFrame = self:_getRootCFrame(root)
	if not originalCFrame then
		return nil
	end

	local homeCFrame = originalCFrame
	local startPoint = cycleData.Layout.StartPoint
	local node01 = cycleData.Layout.Nodes and cycleData.Layout.Nodes[1]
	local ballArea = cycleData.Layout.BallArea

	if startPoint and startPoint:IsA("BasePart") then
		local heightOffset = 0
		if ballArea and ballArea:IsA("BasePart") then
			heightOffset = originalCFrame.Position.Y - ballArea.Position.Y
		end

		local homePosition = startPoint.Position + Vector3.new(0, heightOffset, 0)

		local lookDirection = Vector3.new(0, 0, -1)
		if node01 and node01:IsA("BasePart") then
			local rawDirection = node01.Position - startPoint.Position
			if rawDirection.Magnitude > 0.001 then
				lookDirection = rawDirection.Unit
			end
		end

		homeCFrame = CFrame.lookAt(homePosition, homePosition + lookDirection)
	end

	local trail = nil
	if root:IsA("Instance") then
		trail = root:FindFirstChild("Trail", true)
		if trail and not trail:IsA("Trail") then
			trail = nil
		end
	end

	runtime = {
		Root = root,
		OriginalCFrame = originalCFrame,
		HomeCFrame = homeCFrame,
		Trail = trail,
	}

	if runtime.Trail then
		runtime.Trail.Enabled = false
	end

	if root and root.Parent then
		for _, descendant in ipairs(root.Parent:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.Transparency = 0
			end
		end
	end

	self.ActiveDribbleBallRuntime[player] = runtime
	return runtime
end

function TrainingController:_resetDribbleBall(player: Player)
	local runtime = self.ActiveDribbleBallRuntime[player]
	if not runtime then
		return
	end

	if runtime.Trail then
		runtime.Trail.Enabled = false
	end

	if runtime.Root and runtime.Root.Parent and runtime.OriginalCFrame then
		self:_applyRootCFrame(runtime.Root, runtime.OriginalCFrame)

		for _, descendant in ipairs(runtime.Root.Parent:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.Transparency = 0
			end
		end
	end

	self.ActiveDribbleBallRuntime[player] = nil
	self.LastDribbleCycle[player] = nil
end

function TrainingController:_getDribbleCarrierData(player: Player, cycleData)
	if not cycleData then
		return nil
	end

	local runnerIndex = cycleData.RunnerIndex
	if not runnerIndex then
		return nil
	end

	if runnerIndex == 1 then
		local proxy = self.PlayerTrainingProxies[player]
		if proxy and proxy.Parent then
			return {
				Type = "Player",
				Model = proxy,
				CFrame = proxy:GetPivot(),
			}
		end

		return nil
	end

	-- NPC carrier logic
	local companions = self.SoccerCharactersController.SoccerCharactersInSession[player]
	if companions then
		local grid = companions[runnerIndex - 1]
		local model = grid and grid.Model
		if model and typeof(model) == "Instance" and model.Parent then
			return {
				Type = "Companion",
				Model = model,
				CFrame = model:GetPivot(),
			}
		end
	end

	return nil
end

function TrainingController:_updateDribbleTrainingBall(player: Player, cycleData)
	local runtime = self:_getDribbleBallRuntime(player, cycleData)
	if not runtime then
		return
	end

	local root = runtime.Root
	if not root or not root.Parent then
		return
	end

	if self.LastDribbleCycle[player] ~= cycleData.CycleIndex then
		self.LastDribbleCycle[player] = cycleData.CycleIndex

		if runtime.Trail then
			runtime.Trail.Enabled = false
		end

		self:_applyRootCFrame(root, runtime.HomeCFrame)
	end

	if cycleData.PhaseName ~= "NodeRun" then
		if runtime.Trail then
			runtime.Trail.Enabled = false
		end

		self:_applyRootCFrame(root, runtime.HomeCFrame)
		return
	end

	local targetCFrame = runtime.HomeCFrame
	local carrierData = self:_getDribbleCarrierData(player, cycleData)

	if carrierData and carrierData.CFrame then
		local now = Workspace:GetServerTimeNow()
		local sideWave = math.sin(now * 10)
		local bobWave = math.abs(math.sin(now * 14))

		local forwardOffset = 2
		local sideOffset = 0.16
		local downOffset = 1.7
		local bobHeight = 0.07

		local targetPosition = carrierData.CFrame.Position
			+ (carrierData.CFrame.LookVector * forwardOffset)
			+ (carrierData.CFrame.RightVector * (sideWave * sideOffset))
			+ Vector3.new(0, -downOffset + (bobWave * bobHeight), 0)

		targetCFrame = CFrame.lookAt(targetPosition, targetPosition + carrierData.CFrame.LookVector)
	end

	if runtime.Trail then
		runtime.Trail.Enabled = false
	end

	local currentCFrame = self:_getRootCFrame(root) or targetCFrame
	local finalCFrame = currentCFrame:Lerp(targetCFrame, 0.42)
	self:_applyRootCFrame(root, finalCFrame)
end

function TrainingController:_cleanupTrainingVisuals(player: Player)
	self:_clearTrainingActorFx(player)
	self:_clearDribbleTemplateFx(player)
	self:_destroyPlayerProxy(player)
	self:_clearTrainingBallReleaseBindings(player)
	self:_destroyTrainingBallVisuals(player)
	self.LastBallCycle[player] = nil
	self.LastPassBallCycle[player] = nil
	self.LastDribbleCycle[player] = nil

	if player and player.Character then
		OriginalCharacterMask.SetHidden(player.Character, false)
		self:_setActorEmbeddedBallHidden(player.Character, true)
	end
end

function TrainingController:SetVisualState(player: Player, stateData)
	if not player then
		return
	end

	if stateData == nil then
		self.VisualStates[player] = nil
		self:_cleanupTrainingVisuals(player)
		return
	end

	if self.VisualStates[player] ~= nil then
		self:_clearTrainingBallReleaseBindings(player)
		self:_clearTrainingActorFx(player)
		self:_clearDribbleTemplateFx(player)
		self:_resetTrainingBallVisuals(player)
	end

	stateData._TrainingBallReleasedTokens = {}
	stateData._TrainingPassReceiveTokens = {}
	self.VisualStates[player] = stateData
end

function TrainingController:_updateTrainingBalls()
	for player, visualState in pairs(self.VisualStates) do
		if not player or not player.Parent then
			self:_cleanupTrainingVisuals(player)
			continue
		end

		local companions = self.SoccerCharactersController.SoccerCharactersInSession[player]
		local totalCount = GetTableAmount(companions or {}) + 1

		local cycleData = TrainingRuntimeRegistry.GetCycleData(totalCount, visualState)
		if not cycleData then
			self:_clearTrainingBallReleaseBindings(player)
			self:_clearTrainingActorFx(player)
			self:_clearDribbleTemplateFx(player)
			self:_resetTrainingBallVisuals(player)
			continue
		end

		self:_clearTrainingActorFx(player)
		self:_updateDribbleTemplateFx(player, visualState, cycleData, totalCount)
		self:_updateTrainingBallReleaseBindings(player, visualState, cycleData, totalCount)
	end
end

--|| Knit Lifecycle ||--

function TrainingController:KnitInit()
	TrainingService = Knit.GetService("TrainingService")
	TeleportService = Knit.GetService("TeleportService")
	DataCacheController = Knit.GetController("DataCacheController")
	self.SoccerCharactersController = Knit.GetController("SoccerCharactersController")

	self.TrainingConfig = DataCacheController:GetFile("TrainingConfig")
	self.Template = DataCacheController:GetFile("Template")

	local rootFolder = Instance.new("Folder")
	rootFolder.Name = "TrainingVisuals"
	rootFolder.Parent = workspace

	self.PlayerProxyFolder = Instance.new("Folder")
	self.PlayerProxyFolder.Name = "PlayerProxies"
	self.PlayerProxyFolder.Parent = rootFolder

	self.TrainingBallFolder = Instance.new("Folder")
	self.TrainingBallFolder.Name = "TemplateBalls"
	self.TrainingBallFolder.Parent = rootFolder
end

function TrainingController:KnitStart()
	local center = trainingOptionsGui.Frame.BottomFrame.Center
	for level = 1, 3 do
		local frame = center:FindFirstChild(tostring(level))
		if frame then
			local button = frame:FindFirstChild("Button")
			if button then
				button.Activated:Connect(function()
					TrainingService:RequestSetTrainingLevel(level):andThen(function(success, err)
						if success then
							currentTrainingLevel = level
							self:_updateTrainingOptionsSelection()
						else
							if err then
								local NotificationController = Knit.GetController("NotificationController")
								if NotificationController then
									NotificationController:Notify({ tag = "Training", text = err, type = "ERROR" })
								end
							end
						end
					end)
				end)
			end
		end
	end

	TrainingService.TrainingTempStaminaChanged:Connect(function(tempStamina, maxStamina)
		if trainingOptionsGui and trainingOptionsGui.Enabled then
			local bar = trainingOptionsGui:FindFirstChild("StaminaBar", true)
			if bar then
				local textLabel = bar:FindFirstChild("StaminaAmountText", true)
				if textLabel then
					textLabel.Text = FormatNumber(math.floor(tempStamina))
				end

				local ratio = maxStamina > 0 and math.clamp(tempStamina / maxStamina, 0, 1) or 0
				local bar1 = bar:FindFirstChild("Bar1")
				local bar2 = bar:FindFirstChild("Bar2")

				local rot1 = math.clamp(-180 + (1 - ratio) * 360, -180, 0)
				local rot2 = math.clamp(0 + (0.5 - ratio) * 360, 0, 180)

				local grad1 = bar1 and bar1:FindFirstChildWhichIsA("UIGradient", true)
				local grad2 = bar2 and bar2:FindFirstChildWhichIsA("UIGradient", true)

				if grad1 and grad2 then
					local diff1 = math.abs(rot1 - grad1.Rotation)
					local diff2 = math.abs(rot2 - grad2.Rotation)
					local totalDiff = diff1 + diff2

					if totalDiff > 0.01 then
						local dur1 = 0.3
						local dur2 = 0.3
						local delay1 = 0
						local delay2 = 0

						if diff1 > 0.01 and diff2 > 0.01 then
							dur1 = 0.3 * (diff1 / totalDiff)
							dur2 = 0.3 * (diff2 / totalDiff)
							local isDecreasing = tempStamina < (self.LastTempStamina or tempStamina)

							if isDecreasing then
								delay2 = dur1
							else
								delay1 = dur2
							end
						end

						local ti1 = TweenInfo.new(dur1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, delay1)
						local ti2 = TweenInfo.new(dur2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, delay2)

						TweenService:Create(grad1, ti1, {Rotation = rot1}):Play()
						TweenService:Create(grad2, ti2, {Rotation = rot2}):Play()
					end
					
					self.LastTempStamina = tempStamina
				end

				if self.CurrentTrainingCosts then
					local center = trainingOptionsGui.Frame.BottomFrame.Center
					for level = 1, 3 do
						local cost = self.CurrentTrainingCosts[level]
						if cost then
							local frame = center:FindFirstChild(tostring(level))
							if frame then
								local button = frame:FindFirstChild("Button", true)
								if button then
									local bottom = button:FindFirstChild("Bottom", true)
									if bottom and bottom:FindFirstChild("StaminaCostText", true) then
										if maxStamina < cost then
											bottom.StaminaCostText.TextColor3 = Color3.fromRGB(255, 0, 0)
										else
											bottom.StaminaCostText.TextColor3 = Color3.fromRGB(255, 255, 255)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		TrainingService:RequestStopTraining()
	end)

	TrainingService.TrainingVisualStateChanged:Connect(
		function(targetPlayer, isTraining, statType, zoneKey, serverStartTime, isAuto, level)
			if targetPlayer == player then
				trainingOptionsGui.Enabled = isTraining
				if isTraining then
					self.CurrentStatType = statType
					self:_setupTrainingOptionsUI(statType)
				else
					self.CurrentStatType = nil
				end
			end

			if isTraining then
				local runtime = TrainingRuntimeRegistry.GetRuntimeByStatType(statType)
				if runtime then
					self:SetVisualState(targetPlayer, {
						Mode = runtime.Mode or (tostring(statType) .. "Training"),
						StatType = statType,
						ZoneKey = zoneKey,
						ServerStartTime = serverStartTime,
						OriginalServerStartTime = serverStartTime,
						IsAuto = isAuto,
						Level = level or 1,
						IsResting = false,
					})
				end
			else
				self:SetVisualState(targetPlayer, nil)
			end
		end
	)

	TrainingService.TrainingRestingStateChanged:Connect(function(isResting)
		local visualState = self.VisualStates[player]
		if visualState then
			visualState.IsResting = isResting
		end
	end)

	TrainingService.TrainingLevelChanged:Connect(function(targetPlayer, level)
		local visualState = self.VisualStates[targetPlayer]
		if visualState then
			visualState.Level = level
		end

		if targetPlayer == player then
			currentTrainingLevel = level
			self:_updateTrainingOptionsSelection()
		end
	end)

	TeleportService.PlayerTeleported:Connect(function(player)
		self:SetVisualState(player, nil)
	end)

	RunService:BindToRenderStep("TrainingVisuals", Enum.RenderPriority.Last.Value, function(delta)
		local proxySessions = {}

		for player, visualState in pairs(self.VisualStates) do
			if player and visualState and TrainingRuntimeRegistry.IsRuntimeVisualState(visualState) then
				local shouldPauseTime = true

				if visualState.IsResting then
					if visualState.Mode == "DribbleTraining" then
						local now = Workspace:GetServerTimeNow()
						local elapsed = now - visualState.ServerStartTime
						local cycleDuration = Settings.Dribble.StartHoldDuration + (5 * Settings.Dribble.NodeDuration)
						local cycleIndex = math.floor(elapsed / cycleDuration)
						local phaseTime = elapsed % cycleDuration
						local holdBoundary = 0.01
						local decisionBoundary = Settings.Dribble.StartHoldDuration

						if not visualState.RestingCycleIndex then
							visualState.RestingCycleIndex = cycleIndex
							if phaseTime > decisionBoundary then
								visualState.PauseCycleIndex = cycleIndex + 1
							else
								visualState.PauseCycleIndex = cycleIndex
							end
						end

						if cycleIndex >= visualState.PauseCycleIndex and phaseTime >= holdBoundary then
							shouldPauseTime = true
							if not visualState.FrozenLocalTime then
								visualState.FrozenLocalTime = (visualState.PauseCycleIndex * cycleDuration)
									+ holdBoundary
								visualState.PauseRealTime = Workspace:GetServerTimeNow()
							end
						else
							shouldPauseTime = false
						end
					elseif visualState.Mode == "ShootTraining" then
						local s = Settings.Shoot
						local intervalDuration = s.MoveToShootDuration + s.ReadyToShootDuration + s.ShootDuration

						local now = Workspace:GetServerTimeNow()
						local elapsed = now - visualState.ServerStartTime
						local cycleIndex = math.floor(elapsed / intervalDuration)
						local cycleElapsed = elapsed % intervalDuration
						local holdBoundary = s.MoveToShootDuration + 0.01
						local decisionBoundary = s.MoveToShootDuration + s.ReadyToShootDuration

						if not visualState.RestingCycleIndex then
							visualState.RestingCycleIndex = cycleIndex
							if cycleElapsed > decisionBoundary then
								visualState.PauseCycleIndex = cycleIndex + 1
							else
								visualState.PauseCycleIndex = cycleIndex
							end
						end

						if cycleIndex >= visualState.PauseCycleIndex and cycleElapsed >= holdBoundary then
							shouldPauseTime = true
							if not visualState.FrozenLocalTime then
								visualState.FrozenLocalTime = (visualState.PauseCycleIndex * intervalDuration)
									+ holdBoundary
								visualState.PauseRealTime = Workspace:GetServerTimeNow()
							end
						else
							shouldPauseTime = false
						end
					elseif visualState.Mode == "PassTraining" then
						local s = Settings.Pass
						local cycleDuration = s.PassDuration + s.SettleDuration + s.PassDuration + s.SettleDuration

						local now = Workspace:GetServerTimeNow()
						local startDelay = s.StartDelay or 0
						local elapsed = now - visualState.ServerStartTime
						local effectiveElapsed = math.max(0, elapsed - startDelay)
						local cycleIndex = math.floor(effectiveElapsed / cycleDuration)
						local cycleElapsed = effectiveElapsed % cycleDuration

						local halfCycle = s.PassDuration + s.SettleDuration
						local holdBoundary

						if cycleElapsed < halfCycle then
							holdBoundary = s.PassDuration + 0.01
						else
							holdBoundary = halfCycle + s.PassDuration + 0.01
						end

						if not visualState.RestingCycleIndex then
							visualState.RestingCycleIndex = cycleIndex
							visualState.PauseCycleIndex = cycleIndex
							visualState.TargetHoldBoundary = holdBoundary
						end

						if elapsed < startDelay then
							shouldPauseTime = true
							if not visualState.FrozenLocalTime then
								visualState.FrozenLocalTime = elapsed
								visualState.PauseRealTime = Workspace:GetServerTimeNow()
							end
						else
							local targetBoundary = visualState.TargetHoldBoundary or holdBoundary

							if cycleIndex >= visualState.PauseCycleIndex and cycleElapsed >= targetBoundary then
								shouldPauseTime = true
								if not visualState.FrozenLocalTime then
									visualState.FrozenLocalTime = (visualState.PauseCycleIndex * cycleDuration)
										+ targetBoundary
										+ startDelay
									visualState.PauseRealTime = Workspace:GetServerTimeNow()
								end
							else
								shouldPauseTime = false
							end
						end
					end

					if shouldPauseTime and visualState.ServerStartTime then
						if visualState.FrozenLocalTime then
							visualState.ServerStartTime = Workspace:GetServerTimeNow() - visualState.FrozenLocalTime
						else
							visualState.ServerStartTime += delta
						end
					else
						-- Time is unpaused and flowing
						local extraSpeed = (visualState.Level or 1) - 1
						if extraSpeed > 0 and visualState.ServerStartTime then
							-- Accelerate time by shifting ServerStartTime backward
							visualState.ServerStartTime -= delta * extraSpeed
						end
					end
				else
					visualState.RestingCycleIndex = nil
					visualState.PauseCycleIndex = nil
					visualState.FrozenLocalTime = nil
					visualState.PauseRealTime = nil
					visualState.TargetHoldBoundary = nil
				end

				local proxy = self:_ensurePlayerProxy(player)
				if not proxy then
					continue
				end

				if player.Character then
					OriginalCharacterMask.SetHidden(player.Character, true)
				end

				local proxyState = self.PlayerProxyStates[player]
				if not proxyState.Information then
					proxyState.Information = { Arrived = false }
				end
				proxyState.Information.Target = player.Character and player.Character.PrimaryPart or workspace.Terrain

				-- Construct a temporary 'session' for the player proxy
				proxySessions[player] = {
					[0] = { -- actorIndex 1
						Data = { Name = "PlayerProxy" },
						Information = proxyState.Information,
						LastInformation = self.PlayerProxyStates[player],
						Model = proxy,
					},
				}
			end
		end

		if next(proxySessions) then
			TrainingUpdate(
				delta,
				{
					GetTableAmount = function()
						local companions = self.SoccerCharactersController.SoccerCharactersInSession[player]
						local count = GetTableAmount(companions or {})
						return count
					end,
					GetAngleDistance = GetAngleDistance,
					GetModel = function()
						return nil
					end, -- Proxy models are already ensured above
					EquipAccessory = function() end, -- Proxies are clones of current char, already have accessories
				},
				proxySessions,
				{}, -- soccerCharactersModule (not needed)
				self.PlayerProxyFolder,
				{}, -- raycastExcludeModels
				self.VisualStates,
				{} -- accessoriesByPlayer (not needed for proxies)
			)
		end

		self:_updateTrainingBalls()
	end)
end

return TrainingController
