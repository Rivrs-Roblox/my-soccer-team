return function(chance: number): string
	chance = tonumber(chance) or 0

	local roundedWhole = math.floor(chance + 0.5)
	if math.abs(chance - roundedWhole) < 0.005 then
		return `{roundedWhole}%`
	end

	if chance >= 10 then
		return string.format("%.1f%%", chance)
	end

	return string.format("%.2f%%", chance)
end
