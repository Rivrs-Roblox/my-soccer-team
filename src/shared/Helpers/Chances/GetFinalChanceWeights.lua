local CalculateFinalChances = require(script.Parent.CalculateFinalChances)

return function(chances: { [any]: number }, chanceMultiplier: number?): ({ [any]: number }, { [any]: any })
	local finalChanceItems = CalculateFinalChances(chances, chanceMultiplier)
	local weights = {}
	for key, chanceInfo in finalChanceItems do
		weights[key] = chanceInfo.FinalChance
	end

	return weights, finalChanceItems
end
