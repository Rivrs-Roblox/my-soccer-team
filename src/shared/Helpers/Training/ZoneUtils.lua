local ZoneUtils = {}
local zoneCache = {}

function ZoneUtils.FindZoneByKey(zoneKey: string): BasePart?
	if not zoneKey or zoneKey == "" then
		return nil
	end

	local cached = zoneCache[zoneKey]
	if cached and cached.Parent then
		return cached
	end

	local map = game:GetService("Workspace"):FindFirstChild("Map")
	if not map then
		return nil
	end

	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetFullName() == zoneKey then
			zoneCache[zoneKey] = descendant
			return descendant
		end
	end

	return nil
end

function ZoneUtils.FindFirstBasePart(root: Instance): BasePart?
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

function ZoneUtils.GetShootZoneBall(zone: BasePart): BasePart?
	local ballArea = zone:FindFirstChild("BallArea")
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

	return ZoneUtils.FindFirstBasePart(football)
end

function ZoneUtils.GetShootZoneTarget(zone: BasePart): BasePart?
	local direct = zone:FindFirstChild("BallTarget")
	if direct and direct:IsA("BasePart") then
		return direct
	end

	local assets = zone:FindFirstChild("Assets")
	if assets then
		local assetTarget = assets:FindFirstChild("BallTarget")
		if assetTarget and assetTarget:IsA("BasePart") then
			return assetTarget
		end
	end

	local parentFolder = zone.Parent
	if parentFolder then
		local shootGoal = parentFolder:FindFirstChild("ShootGoal")
		if shootGoal then
			local pivot = shootGoal:FindFirstChild("Pivot", true)
			if pivot and pivot:IsA("BasePart") then
				return pivot
			end

			return ZoneUtils.FindFirstBasePart(shootGoal)
		end
	end

	return nil
end

function ZoneUtils.GetShootStandCFrame(zone: BasePart): CFrame
	local ball = ZoneUtils.GetShootZoneBall(zone)
	local target = ZoneUtils.GetShootZoneTarget(zone)

	if not ball then
		return zone.CFrame * CFrame.new(0, 2, 0)
	end

	local ballPosition = ball.Position
	local targetPosition = target and target.Position or (ballPosition + zone.CFrame.LookVector * 12)

	local forward = targetPosition - ballPosition
	if forward.Magnitude <= 0.001 then
		forward = zone.CFrame.LookVector
	end
	forward = forward.Unit

	local standPosition = ballPosition - (forward * 2.2) + Vector3.new(0, 2, 0)
	return CFrame.lookAt(standPosition, ballPosition)
end

function ZoneUtils.GetCoachPoint(zone: Instance): BasePart?
	local points = zone:FindFirstChild("CompanionPoints") or zone:FindFirstChild("RuntimePoints")
	if points then
		local coach = points:FindFirstChild("Coach")
		if coach and coach:IsA("BasePart") then
			return coach
		end
	end

	local directCoach = zone:FindFirstChild("Coach", true)
	if directCoach and directCoach:IsA("BasePart") then
		return directCoach
	end

	return nil
end

return ZoneUtils