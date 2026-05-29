local MatchRegionSampler = {}

function MatchRegionSampler.SampleRandomPoints(regionCenter: Vector3, count: number, radius: number, minSpacing: number, seed: number): {Vector3}
	local rng = Random.new(seed)
	local points = {}
	local attempts = 0
	local maxAttempts = count * 10
	
	while #points < count and attempts < maxAttempts do
		attempts += 1
		
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(0, radius)
		
		local testPoint = regionCenter + Vector3.new(
			math.cos(angle) * distance,
			0,
			math.sin(angle) * distance
		)
		
		local isValid = true
		for _, p in ipairs(points) do
			if (p - testPoint).Magnitude < minSpacing then
				isValid = false
				break
			end
		end
		
		if isValid then
			table.insert(points, testPoint)
		end
	end
	
	return points
end

return MatchRegionSampler
