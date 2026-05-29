local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoccerCharacters = require(ReplicatedStorage.Shared.Data.Template.SoccerCharacters)
local Accessories = require(ReplicatedStorage.Shared.Data.Template.Accessories)
local Colors = require(ReplicatedStorage.Shared.Data.Colors)

local function toHex(color: Color3)
	return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

return function(gachaData)
	local hoverDescription = ""
	if gachaData and gachaData.Items then
		for i, characterName in ipairs(gachaData.Items) do
			local rarity = "Common"
			
			if SoccerCharacters[characterName] then
				rarity = SoccerCharacters[characterName].Rarity
			elseif Accessories[characterName] then
				rarity = Accessories[characterName].Rarity
			end
			
			local color = Colors[rarity] or Color3.new(1, 1, 1)
			local colorHex = toHex(color)
			
			hoverDescription ..= string.format('<font color="%s">%s</font>', colorHex, characterName)
			
			if i < #gachaData.Items then
				hoverDescription ..= "\n"
			end
		end
	end
	return hoverDescription
end
