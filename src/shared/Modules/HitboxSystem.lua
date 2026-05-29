local RunService = game:GetService("RunService")

-- local enemyParams = OverlapParams.new()
-- enemyParams.FilterType = Enum.RaycastFilterType.Include
-- enemyParams.FilterDescendantsInstances = { workspace.ActiveEnemies }

local HitboxSystem = {}
HitboxSystem.__index = HitboxSystem

function HitboxSystem.new(overlapParams: OverlapParams)
	local self = setmetatable({}, HitboxSystem)

	self.hitboxPool = {}
	self.activeHitboxes = {}
	self.hitResults = {}
	self.enemyParams = overlapParams

	return self
end

function HitboxSystem:AddFilterDescendantsInstances(instances: { Instance })
	if not self.enemyParams then
		self.enemyParams = OverlapParams.new()
		self.enemyParams.FilterType = Enum.RaycastFilterType.Include
		self.enemyParams.FilterDescendantsInstances = {}
	end

	local existingInstances = self.enemyParams.FilterDescendantsInstances or {}

	for _, instance in pairs(instances) do
		table.insert(existingInstances, instance)
	end

	self.enemyParams.FilterDescendantsInstances = existingInstances
end

function HitboxSystem:RemoveFilterDescendantsInstances(instances: { Instance })
	if not self.enemyParams then
		return
	end

	local existingInstances = self.enemyParams.FilterDescendantsInstances or {}
	local instanceSet = {}

	for _, instance in pairs(instances) do
		instanceSet[instance] = true
	end

	local newInstances = {}
	for _, instance in pairs(existingInstances) do
		if not instanceSet[instance] then
			table.insert(newInstances, instance)
		end
	end

	self.enemyParams.FilterDescendantsInstances = newInstances
end

function HitboxSystem:CreateAttackHitbox(attacker, weaponRange, attackDuration, onHitCallback)
	if not attacker or not attacker:FindFirstChild("HumanoidRootPart") then
		warn("[HITBOX SYSTEM] Attacker has no HumanoidRootPart")
		return nil
	end

	local attackerRootPart = attacker.HumanoidRootPart
	local hitboxId = tostring(tick()) .. "_" .. attacker.Name

	local forward = attackerRootPart.CFrame.LookVector
	local size = Vector3.new(weaponRange, weaponRange * 0.8, weaponRange)
	local pos = attackerRootPart.Position + forward * (weaponRange / 2)
	local cf = CFrame.new(pos, pos + forward)

	local hitboxData = {
		id = hitboxId,
		attacker = attacker,
		startTime = tick(),
		duration = attackDuration,
		onHitCallback = onHitCallback,
		size = size,
		cframe = cf,
		hitTargets = {},
		active = true,
	}

	self.activeHitboxes[hitboxId] = hitboxData

	self:StartHitboxDetection(hitboxId)

	return hitboxId
end

function HitboxSystem:StartHitboxDetection(hitboxId)
	local hitboxData = self.activeHitboxes[hitboxId]
	if not hitboxData then
		return
	end

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()

		if not hitboxData.active or currentTime - hitboxData.startTime > hitboxData.duration then
			self:DestroyHitbox(hitboxId)
			connection:Disconnect()
			return
		end

		if hitboxData.attacker and hitboxData.attacker:FindFirstChild("HumanoidRootPart") then
			local attackerRootPart = hitboxData.attacker.HumanoidRootPart
			local forwardDirection = attackerRootPart.CFrame.LookVector
			local weaponRange = hitboxData.size.X
			local hitboxPosition = attackerRootPart.Position + (forwardDirection * (weaponRange / 2))
			hitboxData.cframe = CFrame.new(hitboxPosition, hitboxPosition + forwardDirection)
		end

		self:DetectCollisions(hitboxId)
	end)
end

function HitboxSystem:DetectCollisions(hitboxId)
	local hitboxData = self.activeHitboxes[hitboxId]
	if not hitboxData or not hitboxData.active then
		return
	end

	local touchingParts = workspace:GetPartBoundsInBox(hitboxData.cframe, hitboxData.size, self.enemyParams)

	for _, part in ipairs(touchingParts) do
		local model = part:FindFirstAncestorWhichIsA("Model")
		if not model then
			continue
		end

		if model == hitboxData.attacker then -- don't hit self
			continue
		end

		if hitboxData.hitTargets[model] then -- already hit this target
			continue
		end

		hitboxData.hitTargets[model] = true

		local hitInfo = {
			target = model,
			attacker = hitboxData.attacker,
			hitPosition = part.Position,
			hitTime = tick(),
		}

		if hitboxData.onHitCallback then
			hitboxData.onHitCallback(hitInfo)
		end
	end
end

function HitboxSystem:DestroyHitbox(hitboxId)
	local hitboxData = self.activeHitboxes[hitboxId]
	if not hitboxData then
		return
	end

	hitboxData.active = false

	-- if hitboxData.part and hitboxData.part.Parent then
	-- 	self:ReturnHitboxToPool(hitboxData.part)
	-- end

	self.activeHitboxes[hitboxId] = nil
end

function HitboxSystem:CleanupAllHitboxes()
	for hitboxId, _ in pairs(self.activeHitboxes) do
		self:DestroyHitbox(hitboxId)
	end
end

function HitboxSystem:GetActiveHitboxes()
	return self.activeHitboxes
end

return HitboxSystem
