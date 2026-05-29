--[=[
	ShootVisual
	Visual shoot modular:
	- shoot one-shot
	- blend ke idle lebih smooth
	- world ball move ke target
	- world ball hide/reset
	- trail lebih besar / meriah
	- burst particle saat bola sampai target

	Tidak mengubah logic reward/tick.
]=]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ShootVisual = {}
ShootVisual.__index = ShootVisual

local SHOOT_ANIMATION_ID = "rbxassetid://90962989306225"
local IDLE_ANIMATION_ID = "rbxassetid://97024548119401"

-- timing
local SHOOT_DURATION = 0.2
local BALL_TRAVEL_DURATION = 0.75
local BALL_RESET_DURATION = 0.5
local GOAL_BURST_HOLD = 0.25

-- smoothing
local SHOOT_FADE_IN = 0.2
local SHOOT_FADE_OUT = 0.10
local IDLE_FADE_IN = 0.12

-- trail: lebih besar dan meriah
local TRAIL_LIFETIME = 0.45
local TRAIL_MIN_LENGTH = 0.08
local TRAIL_FACE_CAMERA = true

local function FindFirstDescendantByName(root: Instance, targetName: string): Instance?
	if root.Name == targetName then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == targetName then
			return descendant
		end
	end

	return nil
end

local function FindFirstBasePart(root: Instance): BasePart?
	if root:IsA("BasePart") then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function StopTrack(track: AnimationTrack?, fadeTime: number?)
	if not track then
		return
	end

	pcall(function()
		track:Stop(fadeTime or 0.08)
	end)

	pcall(function()
		track:Destroy()
	end)
end

local function WaitWithCancel(duration: number, isCancelled: () -> boolean): boolean
	local elapsed = 0
	while elapsed < duration do
		if isCancelled() then
			return false
		end

		elapsed += task.wait(0.02)
	end

	return not isCancelled()
end

local function GetAnimatorFromCharacter(character: Model?): Animator?
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	local newAnimator = Instance.new("Animator")
	newAnimator.Parent = humanoid
	return newAnimator
end

local function EnsureBallTrail(ball: BasePart): Trail?
	local att0 = ball:FindFirstChild("TrainingTrailAttachment0")
	local att1 = ball:FindFirstChild("TrainingTrailAttachment1")

	if not att0 then
		att0 = Instance.new("Attachment")
		att0.Name = "TrainingTrailAttachment0"
		att0.Position = Vector3.new(0, 0.28, 0)
		att0.Parent = ball
	end

	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "TrainingTrailAttachment1"
		att1.Position = Vector3.new(0, -0.28, 0)
		att1.Parent = ball
	end

	local trail = ball:FindFirstChild("TrainingTrail")
	if not trail then
		trail = Instance.new("Trail")
		trail.Name = "TrainingTrail"
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = TRAIL_LIFETIME
		trail.MinLength = TRAIL_MIN_LENGTH
		trail.FaceCamera = TRAIL_FACE_CAMERA
		trail.Enabled = false

		-- lebih terang dan tebal
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 245, 140)),
			ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 170, 60)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 80, 30)),
		})

		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.05),
			NumberSequenceKeypoint.new(0.35, 0.18),
			NumberSequenceKeypoint.new(1.00, 1.00),
		})

		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.25),
			NumberSequenceKeypoint.new(0.30, 0.95),
			NumberSequenceKeypoint.new(0.70, 0.45),
			NumberSequenceKeypoint.new(1.00, 0.08),
		})

		trail.Parent = ball
	end

	return trail
end

local function CreateGoalBurstEmitter(parent: Instance): ParticleEmitter
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

	-- texture optional; kosong pun tetap jalan sebagai circle default engine effect feel
	emitter.Parent = parent
	return emitter
end

function ShootVisual.new(player: Player, sessionData)
	local self = setmetatable({}, ShootVisual)

	self.Player = player
	self.SessionData = sessionData
	self.Zone = sessionData and sessionData.Zone or nil
	self.Character = sessionData and sessionData.Character or player.Character
	self.Animator = GetAnimatorFromCharacter(self.Character)

	self.IsRunning = false
	self.Thread = nil
	self.ActiveTween = nil

	self.ShootTrack = nil
	self.IdleTrack = nil

	self.WorldBall = nil
	self.WorldBallStartCFrame = nil
	self.WorldBallStartTransparency = 0
	self.TargetPart = nil
	self.BallTrail = nil

	return self
end

function ShootVisual:_isCancelled(): boolean
	return not self.IsRunning
end

function ShootVisual:_loadTrack(animationId: string, looped: boolean): AnimationTrack?
	if not self.Animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local ok, track = pcall(function()
		return self.Animator:LoadAnimation(animation)
	end)

	animation:Destroy()

	if not ok or not track then
		warn("[ShootVisual] Failed to load animation:", animationId)
		return nil
	end

	track.Looped = looped
	return track
end

function ShootVisual:_resolveWorldBall(): BasePart?
	if not self.Zone then
		return nil
	end

	local ballArea = self.Zone:FindFirstChild("BallArea")
	if not ballArea then
		return nil
	end

	local football = ballArea:FindFirstChild("Football")
	if not football then
		return nil
	end

	local namedMesh = football:FindFirstChild("Mesh")
	if namedMesh and namedMesh:IsA("BasePart") then
		return namedMesh
	end

	return FindFirstBasePart(football)
end

function ShootVisual:_resolveTargetPart(): BasePart?
	if not self.Zone then
		return nil
	end

	local directTarget = self.Zone:FindFirstChild("BallTarget")
	if directTarget and directTarget:IsA("BasePart") then
		return directTarget
	end

	local assets = self.Zone:FindFirstChild("Assets")
	if assets then
		local assetTarget = assets:FindFirstChild("BallTarget")
		if assetTarget and assetTarget:IsA("BasePart") then
			return assetTarget
		end
	end

	local shootFolder = self.Zone.Parent
	if shootFolder then
		local shootGoal = shootFolder:FindFirstChild("ShootGoal")
		if shootGoal then
			local pivot = FindFirstDescendantByName(shootGoal, "Pivot")
			if pivot and pivot:IsA("BasePart") then
				return pivot
			end

			local basePart = FindFirstBasePart(shootGoal)
			if basePart then
				return basePart
			end
		end
	end

	return nil
end

function ShootVisual:_captureBallReferences()
	self.WorldBall = self:_resolveWorldBall()
	self.TargetPart = self:_resolveTargetPart()

	if self.WorldBall then
		self.WorldBallStartCFrame = self.WorldBall.CFrame
		self.WorldBallStartTransparency = self.WorldBall.Transparency
		self.BallTrail = EnsureBallTrail(self.WorldBall)
	end
end

function ShootVisual:_restoreWorldBall()
	if not self.WorldBall then
		return
	end

	if self.ActiveTween then
		pcall(function()
			self.ActiveTween:Cancel()
		end)
		self.ActiveTween = nil
	end

	if self.BallTrail then
		self.BallTrail.Enabled = false
	end

	if self.WorldBallStartCFrame then
		self.WorldBall.CFrame = self.WorldBallStartCFrame
	end

	self.WorldBall.Transparency = self.WorldBallStartTransparency or 0
end

function ShootVisual:_playShootOnce()
	StopTrack(self.ShootTrack, SHOOT_FADE_OUT)
	self.ShootTrack = self:_loadTrack(SHOOT_ANIMATION_ID, false)

	if self.ShootTrack then
		self.ShootTrack:Play(SHOOT_FADE_IN)
	end
end

function ShootVisual:_playIdleLoop()
	if self.IdleTrack then
		return
	end

	self.IdleTrack = self:_loadTrack(IDLE_ANIMATION_ID, true)
	if self.IdleTrack then
		self.IdleTrack:Play(IDLE_FADE_IN)
	end
end

function ShootVisual:_stopIdleLoop()
	StopTrack(self.IdleTrack, 0.08)
	self.IdleTrack = nil
end

function ShootVisual:_transitionShootToIdleSmooth()
	-- blend idle sedikit sebelum shoot habis
	local preIdleDelay = math.max(0.02, SHOOT_DURATION - 0.10)

	if not WaitWithCancel(preIdleDelay, function()
		return self:_isCancelled()
	end) then
		return false
	end

	self:_playIdleLoop()

	local remain = SHOOT_DURATION - preIdleDelay
	if remain > 0 then
		if not WaitWithCancel(remain, function()
			return self:_isCancelled()
		end) then
			return false
		end
	end

	return true
end

function ShootVisual:_playGoalBurst()
	if not self.TargetPart then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "GoalBurstAttachment"
	attachment.Parent = self.TargetPart

	local emitter = CreateGoalBurstEmitter(attachment)
	emitter:Emit(28)

	Debris:AddItem(attachment, 1.2)
end

function ShootVisual:_moveWorldBallToGoal()
	if not self.WorldBall or not self.TargetPart then
		return
	end

	self.WorldBall.Transparency = 0

	if self.BallTrail then
		self.BallTrail.Enabled = true
	end

	local tween = TweenService:Create(
		self.WorldBall,
		TweenInfo.new(BALL_TRAVEL_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			CFrame = self.TargetPart.CFrame,
		}
	)

	self.ActiveTween = tween
	tween:Play()

	local finished = false
	local connection
	connection = tween.Completed:Connect(function()
		finished = true
	end)

	while not finished do
		if self:_isCancelled() then
			tween:Cancel()
			break
		end
		task.wait(0.02)
	end

	if connection then
		connection:Disconnect()
	end

	if self.BallTrail then
		self.BallTrail.Enabled = false
	end

	self.ActiveTween = nil

	if not self:_isCancelled() then
		self:_playGoalBurst()
	end
end

function ShootVisual:_runLoop()
	self:_captureBallReferences()

	if not self.WorldBall then
		warn("[ShootVisual] World ball not found for zone:", self.Zone and self.Zone:GetFullName())
		return
	end

	if not self.TargetPart then
		warn("[ShootVisual] Ball target not found for zone:", self.Zone and self.Zone:GetFullName())
		return
	end

	while self.IsRunning do
		self:_stopIdleLoop()
		self:_playShootOnce()

		if not self:_transitionShootToIdleSmooth() then
			break
		end

		self:_moveWorldBallToGoal()

		if self:_isCancelled() then
			break
		end

		-- beri hold kecil setelah burst supaya lebih terasa
		if not WaitWithCancel(GOAL_BURST_HOLD, function()
			return self:_isCancelled()
		end) then
			break
		end

		self.WorldBall.Transparency = 1

		if not WaitWithCancel(BALL_RESET_DURATION, function()
			return self:_isCancelled()
		end) then
			break
		end

		if self.WorldBallStartCFrame then
			self.WorldBall.CFrame = self.WorldBallStartCFrame
		end
		self.WorldBall.Transparency = self.WorldBallStartTransparency or 0
	end

	self:_restoreWorldBall()
end

function ShootVisual:Start()
	if self.IsRunning then
		return
	end

	self.IsRunning = true
	self.Thread = task.spawn(function()
		self:_runLoop()
	end)
end

function ShootVisual:Stop()
	if not self.IsRunning then
		return
	end

	self.IsRunning = false

	if self.ActiveTween then
		pcall(function()
			self.ActiveTween:Cancel()
		end)
		self.ActiveTween = nil
	end

	if self.BallTrail then
		self.BallTrail.Enabled = false
	end

	self:_stopIdleLoop()
	StopTrack(self.ShootTrack, 0.08)
	self.ShootTrack = nil

	self:_restoreWorldBall()
end

return ShootVisual