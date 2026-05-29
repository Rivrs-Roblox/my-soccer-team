local MatchMotionMath = {}

function MatchMotionMath.EvaluateQuadraticBezier(p0: Vector3, p1: Vector3, p2: Vector3, alpha: number): Vector3
	local a = p0:Lerp(p1, alpha)
	local b = p1:Lerp(p2, alpha)
	return a:Lerp(b, alpha)
end

function MatchMotionMath.BuildFlatLookAtCFrame(position: Vector3, worldPosition: Vector3?, fallbackLook: Vector3?): CFrame
	local resolvedFallback = fallbackLook
	if not resolvedFallback or resolvedFallback.Magnitude <= 0.001 then
		resolvedFallback = Vector3.new(0, 0, -1)
	else
		resolvedFallback = resolvedFallback.Unit
	end

	if not worldPosition then
		return CFrame.lookAt(position, position + resolvedFallback)
	end

	local flattenedTarget = Vector3.new(worldPosition.X, position.Y, worldPosition.Z)
	local lookVector = flattenedTarget - position

	if lookVector.Magnitude <= 0.001 then
		return CFrame.lookAt(position, position + resolvedFallback)
	end

	return CFrame.lookAt(position, position + lookVector.Unit)
end

function MatchMotionMath.GetFlatDirection(fromPosition: Vector3, toPosition: Vector3): Vector3
	local direction = toPosition - fromPosition
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)

	if flatDirection.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return flatDirection.Unit
end

return MatchMotionMath
