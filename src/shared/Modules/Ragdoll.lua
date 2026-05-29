local StarterPlayer = game:GetService("StarterPlayer")
-- RagdollModule.lua
local RagdollModule = {}
RagdollModule.__index = RagdollModule

-- Daftar joint R15 (part0, part1, motorName)
local RAGDOLL_JOINTS = {
	{ "UpperTorso", "LowerTorso", "Waist" },
	{ "UpperTorso", "RightUpperArm", "RightShoulder" },
	{ "UpperTorso", "LeftUpperArm", "LeftShoulder" },
	{ "LowerTorso", "RightUpperLeg", "RightHip" },
	{ "LowerTorso", "LeftUpperLeg", "LeftHip" },
	{ "RightUpperArm", "RightLowerArm", "RightElbow" },
	{ "LeftUpperArm", "LeftLowerArm", "LeftElbow" },
	{ "RightUpperLeg", "RightLowerLeg", "RightKnee" },
	{ "LeftUpperLeg", "LeftLowerLeg", "LeftKnee" },
}

-- Util aman: cek instance masih valid
local function isAlive(inst: Instance?)
	return typeof(inst) == "Instance" and inst.Parent ~= nil
end

function RagdollModule.new(character: Model, options)
	local self = setmetatable({}, RagdollModule)
	self.character = character
	self.options = type(options) == "table" and options or {}
	self.constraints = {} -- BallSocketConstraint list
	self.attachments = {} -- Attachment list (kalau mau dibersihkan manual)
	self.jointProperties = {} -- per-motor backup { motor -> {C0,C1,Parent,Enabled} }
	self.collideBackup = {} -- per-part backup CanCollide { [BasePart] = boolean }
	self.movementBackup = nil -- backup humanoid movement states
	self.isRagdolled = false -- guard idempotent
	return self
end

-- === Movement Backup/Restore ===
function RagdollModule:disableMovement()
	local humanoid: Humanoid? = self.character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- backup hanya sekali
		if not self.movementBackup then
			self.movementBackup = {
				WalkSpeed = humanoid.WalkSpeed,
				JumpPower = humanoid.JumpPower,
				AutoRotate = humanoid.AutoRotate,
				PlatformStand = humanoid.PlatformStand,
			}
		end

		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		-- Opsional: aktifkan Physics agar motor humanoid tidak override
		-- pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
	end
end

function RagdollModule:enableMovement()
	local humanoid: Humanoid? = self.character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local b = self.movementBackup
		if b then
			humanoid.WalkSpeed = b.WalkSpeed
			humanoid.JumpPower = b.JumpPower
			humanoid.AutoRotate = b.AutoRotate
			humanoid.PlatformStand = b.PlatformStand
		else
			-- fallback default kalau belum sempat backup
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
			humanoid.JumpPower = StarterPlayer.CharacterJumpPower
		end
		-- Opsional: bantu recovery
		-- pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
end

-- === Ragdoll Constraints Setup/Cleanup ===
function RagdollModule:setupRagdollPhysics()
	for _, jointInfo in ipairs(RAGDOLL_JOINTS) do
		local part0: BasePart? = self.character:FindFirstChild(jointInfo[1]) :: BasePart
		local part1: BasePart? = self.character:FindFirstChild(jointInfo[2]) :: BasePart
		local motorName = jointInfo[3]

		if isAlive(part0) and isAlive(part1) then
			-- Simpan dan matikan Motor6D
			local motor: Motor6D? = part1:FindFirstChild(motorName) :: Motor6D
			if motor and motor:IsA("Motor6D") then
				self.jointProperties[motor] = {
					C0 = motor.C0,
					C1 = motor.C1,
					Parent = motor.Parent,
					Enabled = motor.Enabled,
				}
				motor.Enabled = false
			end

			-- Backup CanCollide lalu set true (biar fisiknya realistis saat jatuh, kecuali dilarang config)
			if self.collideBackup[part0] == nil then
				self.collideBackup[part0] = part0.CanCollide
			end
			if self.collideBackup[part1] == nil then
				self.collideBackup[part1] = part1.CanCollide
			end

			local forceCollide = self.options.CanCollide
			if forceCollide == nil then forceCollide = true end

			if forceCollide then
				part0.CanCollide = true
				part1.CanCollide = true
			else
				part0.CanCollide = false
				part1.CanCollide = false
			end

			-- Buat attachments
			local att0 = Instance.new("Attachment")
			att0.Name = motorName .. "_Att0"
			att0.Parent = part0

			local att1 = Instance.new("Attachment")
			att1.Name = motorName .. "_Att1"
			att1.Parent = part1

			-- Cocokkan posisi joint dengan Motor6D (kalau ada)
			if motor then
				att0.CFrame = motor.C0
				att1.CFrame = motor.C1
			end

			table.insert(self.attachments, att0)
			table.insert(self.attachments, att1)

			-- Buat BallSocketConstraint
			local ball = Instance.new("BallSocketConstraint")
			ball.Name = motorName .. "_Ragdoll"
			ball.Attachment0 = att0
			ball.Attachment1 = att1
			ball.LimitsEnabled = true
			ball.TwistLimitsEnabled = true
			ball.UpperAngle = 90
			ball.TwistUpperAngle = 90
			ball.TwistLowerAngle = -90
			ball.Parent = part0 -- parent di part0 biar rapih

			table.insert(self.constraints, ball)
		end
	end
end

function RagdollModule:removeRagdollPhysics()
	-- Hapus constraints + attachments yang dibuat
	for _, c in ipairs(self.constraints) do
		if isAlive(c) then
			-- Simpan pointer untuk attachment (nanti dihancurkan di loop attachments juga aman)
			c.Attachment0 = nil
			c.Attachment1 = nil
			c:Destroy()
		end
	end
	self.constraints = {}

	for _, a in ipairs(self.attachments) do
		if isAlive(a) then
			a:Destroy()
		end
	end
	self.attachments = {}

	-- Pulihkan semua Motor6D yang sebelumnya dimatikan
	for motor, props in pairs(self.jointProperties) do
		if isAlive(motor) then
			motor.C0 = props.C0
			motor.C1 = props.C1
			-- Pastikan parent valid sebelum set
			if isAlive(props.Parent) then
				motor.Parent = props.Parent
			end
			motor.Enabled = true
		end
	end
	self.jointProperties = {}

	-- Pulihkan CanCollide parts yang diubah
	for part, oldCanCollide in pairs(self.collideBackup) do
		if isAlive(part) then
			part.CanCollide = oldCanCollide
		end
	end
	self.collideBackup = {}
end

-- === Public API ===
function RagdollModule:enableRagdoll()
	if self.isRagdolled then
		return
	end
	self.isRagdolled = true
	self:disableMovement()
	self:setupRagdollPhysics()
end

function RagdollModule:disableRagdoll()
	if not self.isRagdolled then
		return
	end
	self.isRagdolled = false
	self:removeRagdollPhysics()
	self:enableMovement()
end

return RagdollModule
