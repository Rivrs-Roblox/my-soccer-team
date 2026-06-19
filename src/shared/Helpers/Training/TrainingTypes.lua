local StatTypes = {}

StatTypes.Valid = {
	Shoot = true,
	Pass = true,
	Dribble = true,
	Stamina = true,
}

function StatTypes.Normalize(statType: string?): string?
	if type(statType) ~= "string" then
		return nil
	end

	local lowered = string.lower(statType)
	if lowered == "shoot" then
		return "Shoot"
	elseif lowered == "pass" then
		return "Pass"
	elseif lowered == "dribble" then
		return "Dribble"
	elseif lowered == "stamina" then
		return "Stamina"
	end

	return nil
end

function StatTypes.IsValid(statType: string?): boolean
	local normalized = StatTypes.Normalize(statType)
	return normalized ~= nil and StatTypes.Valid[normalized] == true
end

return StatTypes