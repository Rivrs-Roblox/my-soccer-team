--!strict
-- MatchEnemyAreaConfig.luau
-- Visual enemy asset config only. Difficulty lives in MatchAreaConfig.

local TournamentConfig = require(script.Parent.Parent.Parent.Domain.Tournament.TournamentConfig)

local function BuildEnemySlots()
	return table.freeze({
		[1] = table.freeze({
			ModelName = "Enemy01",
			PivotName = "Enemy01",
			Role = "Defender",
			RandomRadius = 4,
			SpawnSide = "Center",
		}),

		[2] = table.freeze({
			ModelName = "Enemy02",
			PivotName = "Enemy02",
			Role = "Defender",
			RandomRadius = 4,
			SpawnSide = "Center",
		}),

		[3] = table.freeze({
			ModelName = "Enemy03",
			PivotName = "Enemy03",
			Role = "Defender",
			RandomRadius = 2,
			SpawnSide = "Left",
			ApproachMarkerName = "EnemyApproachPoint",
		}),

		[4] = table.freeze({
			ModelName = "Enemy04",
			FallbackModelName = "Enemy03",
			PivotName = "Enemy04",
			Role = "Defender",
			RandomRadius = 2,
			SpawnSide = "Right",
			ApproachMarkerName = "EnemyApproachPoint",
		}),

		[5] = table.freeze({
			ModelName = "Keeper",
			FallbackModelName = "GoalKeeper",
			PivotName = "GoalKeeper",
			Role = "GoalKeeper",
			RandomRadius = 0,
			SpawnSide = "Center",
		}),
	})
end

local function BuildArea(areaId: string)
	local areaConfig = TournamentConfig.GetAreaConfig(areaId)
	return table.freeze({
		AssetFolderName = tostring(areaConfig.AssetFolderName or areaId),
		TeamId = tostring(areaConfig.CupId or (areaId .. "EnemyTeam")),
		ZoneName = tostring(areaConfig.ZoneName or areaId),
		Teams = areaConfig.Teams,
		Slots = BuildEnemySlots(),
	})
end

local MatchEnemyAreaConfig = table.freeze({
	Area01 = BuildArea("Area01"),
	Area02 = BuildArea("Area02"),
	Area03 = BuildArea("Area03"),
	Area04 = BuildArea("Area04"),
	Area05 = BuildArea("Area05"),
})

return MatchEnemyAreaConfig
