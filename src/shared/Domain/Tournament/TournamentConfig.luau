--!strict
-- TournamentConfig.luau
-- Pure configuration for cup bracket, team pools, and simulated live-match context.

local TournamentConfig = {}

TournamentConfig.Debug = false

TournamentConfig.PlayerTeam = table.freeze({
	TeamId = "Player",
	DisplayName = "FC Rivrs",
	AssetFolderName = "Player",
	IsPlayer = true,
})

TournamentConfig.RoundOrder = table.freeze({
	{
		RoundId = "RoundOf16",
		RoundName = "Round of 16",
		ShortName = "R16",
		MatchCount = 8,
	},
	{
		RoundId = "QuarterFinal",
		RoundName = "Quarter Finals",
		ShortName = "QF",
		MatchCount = 4,
	},
	{
		RoundId = "SemiFinal",
		RoundName = "Semi Finals",
		ShortName = "SF",
		MatchCount = 2,
	},
	{
		RoundId = "Final",
		RoundName = "Final",
		ShortName = "Final",
		MatchCount = 1,
	},
})

TournamentConfig.LiveMatch = table.freeze({
	MinMinute = 85,
	MaxMinute = 90,
	DrawScores = table.freeze({
		{ Home = 0, Away = 0 },
		{ Home = 1, Away = 1 },
		{ Home = 2, Away = 2 },
	}),
	WinScore = table.freeze({ Home = 2, Away = 1 }),
	LoseScore = table.freeze({ Home = 1, Away = 2 }),
})

local function Team(teamNumber: number, displayName: string, areaId: string)
	local teamId = string.format("Team%02d", teamNumber)
	return table.freeze({
		TeamId = teamId,
		DisplayName = displayName,
		AssetFolderName = teamId,
		AreaId = areaId,
		IsPlayer = false,
	})
end

TournamentConfig.Areas = table.freeze({
	Area01 = table.freeze({
		AreaId = "Area01",
		CupId = "BrazilZoneCup",
		CupName = "Brazil Zone Cup",
		ZoneName = "Brazil Zone",
		AssetFolderName = "Area01",
		Teams = table.freeze({
			Team(1, "Rio Vortex FC", "Area01"),
			Team(2, "Samba Strikers", "Area01"),
			Team(3, "Amazonia Blaze", "Area01"),
			Team(4, "Favela Titans", "Area01"),
			Team(5, "Crimson Canaries", "Area01"),
			Team(6, "Solar Cobra FC", "Area01"),
			Team(7, "Thunder Toucans", "Area01"),
			Team(8, "Bahia Cyclones", "Area01"),
			Team(9, "Neon Jaguars", "Area01"),
			Team(10, "Carnival Reapers", "Area01"),
			Team(11, "Golden Macaws", "Area01"),
			Team(12, "Palmeiras Nova", "Area01"),
			Team(13, "Shadow Capybaras", "Area01"),
			Team(14, "Tropico United", "Area01"),
			Team(15, "Verde Inferno FC", "Area01"),
		}),
	}),

	Area02 = table.freeze({
		AreaId = "Area02",
		CupId = "JapanZoneCup",
		CupName = "Japan Zone Cup",
		ZoneName = "Japan Zone",
		AssetFolderName = "Area02",
		Teams = table.freeze({
			Team(1, "Sakura Blades", "Area02"),
			Team(2, "Neo Kyoto FC", "Area02"),
			Team(3, "Shogun Eleven", "Area02"),
			Team(4, "Crimson Kitsune", "Area02"),
			Team(5, "Tokyo Voltage", "Area02"),
			Team(6, "Oni Tempest", "Area02"),
			Team(7, "Yokai Strikers", "Area02"),
			Team(8, "Rising Sun FC", "Area02"),
			Team(9, "Hokkaido Wolves", "Area02"),
			Team(10, "Ronin Eclipse", "Area02"),
			Team(11, "Fuji Storm", "Area02"),
			Team(12, "Kurohana United", "Area02"),
			Team(13, "Cyber Samurai FC", "Area02"),
			Team(14, "Osaka Comets", "Area02"),
			Team(15, "Dragon Pulse", "Area02"),
		}),
	}),

	Area03 = table.freeze({
		AreaId = "Area03",
		CupId = "UsaZoneCup",
		CupName = "USA Zone Cup",
		ZoneName = "USA Zone",
		AssetFolderName = "Area03",
		Teams = table.freeze({
			Team(1, "Liberty Hawks", "Area03"),
			Team(2, "Nevada Outlaws", "Area03"),
			Team(3, "Steel Phoenix FC", "Area03"),
			Team(4, "Miami Cyclone", "Area03"),
			Team(5, "California Waves", "Area03"),
			Team(6, "Texas Vipers", "Area03"),
			Team(7, "Titan Rockets", "Area03"),
			Team(8, "Golden Frontier FC", "Area03"),
			Team(9, "New York Blizzard", "Area03"),
			Team(10, "Crimson Patriots", "Area03"),
			Team(11, "Chicago Rampage", "Area03"),
			Team(12, "Vegas Mirage", "Area03"),
			Team(13, "Pacific Rhinos", "Area03"),
			Team(14, "Astro Kings", "Area03"),
			Team(15, "Thunder Canyon FC", "Area03"),
		}),
	}),

	Area04 = table.freeze({
		AreaId = "Area04",
		CupId = "ItalyZoneCup",
		CupName = "Italy Zone Cup",
		ZoneName = "Italy Zone",
		AssetFolderName = "Area04",
		Teams = table.freeze({
			Team(1, "Verona Vipers", "Area04"),
			Team(2, "Roman Eclipse", "Area04"),
			Team(3, "Venice Tide FC", "Area04"),
			Team(4, "Milano Royale", "Area04"),
			Team(5, "Inferno Lazio", "Area04"),
			Team(6, "Tuscan Wolves", "Area04"),
			Team(7, "Gladiator XI", "Area04"),
			Team(8, "Napoli Tempesta", "Area04"),
			Team(9, "Crimson Venezia", "Area04"),
			Team(10, "Torino Phantom", "Area04"),
			Team(11, "Aurelio Strikers", "Area04"),
			Team(12, "Black Basilica FC", "Area04"),
			Team(13, "Fiora Titans", "Area04"),
			Team(14, "Cobalt Roma", "Area04"),
			Team(15, "Sicilian Storm", "Area04"),
		}),
	}),

	Area05 = table.freeze({
		AreaId = "Area05",
		CupId = "EnglandZoneCup",
		CupName = "England Zone Cup",
		ZoneName = "England Zone",
		AssetFolderName = "Area05",
		Teams = table.freeze({
			Team(1, "Iron Crown FC", "Area05"),
			Team(2, "London Ravens", "Area05"),
			Team(3, "Albion Knights", "Area05"),
			Team(4, "Manchester Fury", "Area05"),
			Team(5, "Stormbridge United", "Area05"),
			Team(6, "Crimson Lions", "Area05"),
			Team(7, "Bristol Guardians", "Area05"),
			Team(8, "Royal Howlers", "Area05"),
			Team(9, "Eastchester FC", "Area05"),
			Team(10, "Blackmoor Rovers", "Area05"),
			Team(11, "Winchester Wolves", "Area05"),
			Team(12, "Silver Thames FC", "Area05"),
			Team(13, "Oxford Phantoms", "Area05"),
			Team(14, "Northvale Athletic", "Area05"),
			Team(15, "Emerald Fortress FC", "Area05"),
		}),
	}),
})

function TournamentConfig.GetAreaConfig(areaId: string?)
	local resolvedAreaId = tostring(areaId or "")
	local areaConfig = TournamentConfig.Areas[resolvedAreaId]
	if areaConfig then
		return areaConfig
	end

	return TournamentConfig.Areas.Area01
end

function TournamentConfig.GetRoundByIndex(roundIndex: number)
	return TournamentConfig.RoundOrder[math.clamp(tonumber(roundIndex) or 1, 1, #TournamentConfig.RoundOrder)]
end

function TournamentConfig.GetRoundById(roundId: string?)
	local targetRoundId = tostring(roundId or "")
	for _, roundDefinition in ipairs(TournamentConfig.RoundOrder) do
		if roundDefinition.RoundId == targetRoundId then
			return roundDefinition
		end
	end
	return TournamentConfig.RoundOrder[1]
end

return table.freeze(TournamentConfig)
