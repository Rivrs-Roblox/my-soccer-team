local FormatNumber = require(script.Parent.FormatNumber)

return function(multiplier: number)
	if multiplier < 1 then
		return 0
	end

	local res = math.round((multiplier - 1) * 100)
	return FormatNumber(res)
end
