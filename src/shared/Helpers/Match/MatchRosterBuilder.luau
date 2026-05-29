local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetStats = require(ReplicatedStorage.Shared.Helpers.SoccerCharacters.GetStats)

local MatchRosterBuilder = {}

local DEFAULT_MULTIPLIERS = {
	Shoot = 1,
	Pass = 1,
	Dribble = 1,
}

local function CloneMultipliers(source)
	return {
		Shoot = source and source.Shoot or 1,
		Pass = source and source.Pass or 1,
		Dribble = source and source.Dribble or 1,
	}
end

local function GetOwnedCharacter(ownedCharacters, ownedId)
	if ownedId == nil then
		return nil
	end

	return ownedCharacters[ownedId] or ownedCharacters[tostring(ownedId)] or ownedCharacters[tonumber(ownedId)]
end

function MatchRosterBuilder.Build(player: Player, playerData: { [string]: any }, soccerCharacterTemplate: { [string]: any })
	local roster = {
		[1] = {
			Slot = 1,
			ActorType = "MainPlayer",
			DisplayName = player.Name,
			TemplateName = nil,
			Level = 1,
			Multipliers = CloneMultipliers(DEFAULT_MULTIPLIERS),
		},
	}

	local inventory = playerData.Inventory or {}
	local ownedCharacters = inventory.SoccerCharacters or {}
	local equippedCharacters = inventory.EquippedSoccerCharacters or {}

	for slot = 2, 4 do
		local equippedIndex = slot - 1
		local ownedId = equippedCharacters[equippedIndex]
		local ownedEntry = GetOwnedCharacter(ownedCharacters, ownedId)

		if ownedEntry and ownedEntry.Name then
			roster[slot] = {
				Slot = slot,
				ActorType = "Companion",
				DisplayName = ownedEntry.Name,
				TemplateName = ownedEntry.Name,
				OwnedId = ownedId,
				Level = ownedEntry.Level or 1,
				Multipliers = GetStats(ownedEntry, inventory.Accessories),
			}
		else
			roster[slot] = {
				Slot = slot,
				ActorType = "Companion",
				DisplayName = "Empty",
				TemplateName = nil,
				OwnedId = nil,
				Level = 0,
				Multipliers = CloneMultipliers(DEFAULT_MULTIPLIERS),
			}
		end
	end

	return roster
end

return MatchRosterBuilder