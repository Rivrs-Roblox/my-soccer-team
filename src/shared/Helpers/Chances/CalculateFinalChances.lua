local MIDDLE_CURVE = 1.25
local AUTO_NORMALIZE_BASE = true
local CLAMP_POWER = true

type ChanceItem = {
	Key: any,
	BaseChance: number,
}

type FinalChanceItem = {
	BaseChance: number,
	FinalChance: number,
	Score: number?,
	Power: number?,
	RawChance: number?,
}

local function clamp(value: number, minValue: number, maxValue: number): number
	return math.max(minValue, math.min(maxValue, value))
end

return function(baseChances: { [any]: number }, chanceMultiplier: number?): { [any]: FinalChanceItem }
	chanceMultiplier = math.max(1, tonumber(chanceMultiplier) or 1)

	local items: { ChanceItem } = {}
	for key, chance in baseChances do
		local baseChance = math.max(0, tonumber(chance) or 0)
		if baseChance > 0 then
			table.insert(items, {
				Key = key,
				BaseChance = baseChance,
			})
		end
	end

	if #items == 0 then
		return {}
	end

	local totalBase = 0
	for _, item in items do
		totalBase += item.BaseChance
	end

	if AUTO_NORMALIZE_BASE and totalBase ~= 100 then
		for _, item in items do
			item.BaseChance = item.BaseChance / totalBase * 100
		end
	end

	local maxBase = -math.huge
	local minBase = math.huge
	for _, item in items do
		maxBase = math.max(maxBase, item.BaseChance)
		minBase = math.min(minBase, item.BaseChance)
	end

	if maxBase == minBase then
		local equalChances = {}
		for _, item in items do
			equalChances[item.Key] = {
				BaseChance = item.BaseChance,
				FinalChance = item.BaseChance,
			}
		end
		return equalChances
	end

	local rawItems = {}
	local totalRaw = 0
	for _, item in items do
		local baseChance = item.BaseChance
		local score = (maxBase - baseChance) / (maxBase - minBase)
		local power = (2 * score - 1) * MIDDLE_CURVE

		if baseChance == maxBase then
			power = -1
		end
		if baseChance == minBase then
			power = 1
		end
		if CLAMP_POWER then
			power = clamp(power, -1, 1)
		end

		local rawChance = baseChance * math.pow(chanceMultiplier, power)
		rawItems[item.Key] = {
			BaseChance = baseChance,
			Score = score,
			Power = power,
			RawChance = rawChance,
		}
		totalRaw += rawChance
	end

	local finalChances = {}
	for key, item in rawItems do
		finalChances[key] = {
			BaseChance = item.BaseChance,
			FinalChance = item.RawChance / totalRaw * 100,
			Score = item.Score,
			Power = item.Power,
			RawChance = item.RawChance,
		}
	end

	return finalChances
end
