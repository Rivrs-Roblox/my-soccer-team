local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Template = require(ReplicatedStorage.Shared.Data.Template)

return function(charData, accessoryInventory)
	local templateData = Template.SoccerCharacters[charData.Name]
	if not templateData then
		return { Shoot = 0, Dribble = 0, Pass = 0 }
	end

	local levelBonus = charData.Level - 1
	local shoot = (templateData.Multipliers.Shoot or 0) + (levelBonus * (Template.MergeBonus and Template.MergeBonus.ShootBonus or 0))
	local dribble = (templateData.Multipliers.Dribble or 0) + (levelBonus * (Template.MergeBonus and Template.MergeBonus.DribbleBonus or 0))
	local pass = (templateData.Multipliers.Pass or 0) + (levelBonus * (Template.MergeBonus and Template.MergeBonus.PassBonus or 0))

	if charData.Accessories and accessoryInventory then
		for _, accessoryId in pairs(charData.Accessories) do
			if accessoryId then
				local inventoryItem = accessoryInventory[tostring(accessoryId)]
				if inventoryItem then
					local accessoryTemplate = Template.Accessories[inventoryItem.Name]
					if accessoryTemplate and accessoryTemplate.Additions then
						shoot += (accessoryTemplate.Additions.Shoot or 0)
						dribble += (accessoryTemplate.Additions.Dribble or 0)
						pass += (accessoryTemplate.Additions.Pass or 0)
					end
				end
			end
		end
	end

	return {
		Shoot = tonumber(string.format("%.1f", shoot)),
		Dribble = tonumber(string.format("%.1f", dribble)),
		Pass = tonumber(string.format("%.1f", pass)),
	}
end
