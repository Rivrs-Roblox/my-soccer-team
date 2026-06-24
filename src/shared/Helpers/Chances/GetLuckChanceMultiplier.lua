local FindValue = require(script.Parent.Parent.Table.FindValue)

return function(gamepasses: { any }?, luckMultipliers: { [string]: number }?): number
	local multiplier = 1

	if gamepasses and luckMultipliers then
		for passName, bonus in pairs(luckMultipliers) do
			if FindValue(gamepasses, passName) then
				multiplier += bonus
			end
		end
	end

	return math.max(1, multiplier)
end
